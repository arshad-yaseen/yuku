const std = @import("std");
const ast = @import("../../ast.zig");
const Precedence = @import("../../token.zig").Precedence;
const TokenTag = @import("../../token.zig").TokenTag;
const RawToken = @import("../../token.zig").Token;
const Parser = @import("../../parser.zig").Parser;
const Error = @import("../../parser.zig").Error;
const dialect = @import("dialect");

const literals = @import("../literals.zig");
const expressions = @import("../expressions.zig");
const ts = @import("../ts/types.zig");

/// context for JSX element parsing, determines post-parse behavior
const JsxElementContext = enum {
    /// top-level JSX expression, needs to advance past final '>'
    top_level,
    /// child of another JSX element, parent's parseJsxChildren handles continuation
    child,
    /// attribute value, restores jsx_tag mode
    attribute,
};

const DialectHost = struct {
    pub const NodeIndex = ast.NodeIndex;
    pub const NodeData = ast.NodeData;
    pub const NodeTag = std.meta.Tag(ast.NodeData);
    pub const IndexRange = ast.IndexRange;
    pub const Value = ast.String;
    pub const Span = ast.Span;
    pub const Token = TokenTag;
    pub const ErrorType = Error;

    pub fn currentToken(parser: *const Parser) TokenTag {
        return parser.current_token.tag;
    }

    pub fn currentSpan(parser: *const Parser) ast.Span {
        return parser.current_token.span;
    }
    pub fn data(parser: *const Parser, node: ast.NodeIndex) ast.NodeData {
        return parser.tree.data(node);
    }
    pub fn extra(parser: *const Parser, range: ast.IndexRange) []const ast.NodeIndex {
        return parser.tree.extra(range);
    }
    pub fn string(parser: *const Parser, value: ast.String) []const u8 {
        return parser.tree.string(value);
    }
    pub fn source(parser: *const Parser) []const u8 {
        return parser.source;
    }
    pub fn sourceText(parser: *const Parser, span: ast.Span) []const u8 {
        return parser.spanText(span);
    }
    pub fn allocator(parser: *Parser) std.mem.Allocator {
        return parser.allocator();
    }
    pub fn addString(parser: *Parser, value: []const u8) Error!ast.String {
        return parser.tree.addString(value);
    }
    pub fn addExtra(parser: *Parser, nodes: []const ast.NodeIndex) Error!ast.IndexRange {
        return parser.tree.addExtra(nodes);
    }
    pub fn addNode(parser: *Parser, data_: ast.NodeData, span: ast.Span) Error!ast.NodeIndex {
        return parser.tree.addNode(data_, span);
    }
    pub fn addDialectNode(parser: *Parser, record: dialect.Record, span: ast.Span) Error!ast.NodeIndex {
        return parser.addDialectNode(record, span);
    }
    pub fn reportWithHelp(parser: *Parser, span: ast.Span, message: []const u8, help: []const u8) Error!void {
        return parser.report(span, message, .{ .help = help });
    }
    pub fn currentReturnContext(parser: *const Parser) bool {
        return parser.context.@"return";
    }
    pub fn resumeAfterRawSpan(
        parser: *Parser,
        end: u32,
        comptime context: JsxElementContext,
    ) Error!bool {
        if (end > parser.source.len) return false;
        parser.lexer.rewindTo(end);
        parser.current_token = RawToken.eof(end);
        parser.prev_token_end = end;
        switch (context) {
            .child => parser.setLexerMode(.normal),
            .top_level => {
                parser.setLexerMode(.normal);
                return (try parser.advance()) != null;
            },
            .attribute => {
                parser.setLexerMode(.jsx_tag);
                return (try parser.advance()) != null;
            },
        }
        return true;
    }

    pub fn nodeSpan(parser: *const Parser, node: ast.NodeIndex) ast.Span {
        return parser.tree.span(node);
    }

    pub fn sourceSlice(parser: *const Parser, start: u32, end: u32) ast.String {
        return parser.tree.sourceSlice(start, end);
    }

    pub fn addTextNode(parser: *Parser, value: ast.String, span: ast.Span) Error!ast.NodeIndex {
        return parser.tree.addNode(.{ .jsx_text = .{ .value = value } }, span);
    }

    pub fn parseChild(parser: *Parser) Error!?ast.NodeIndex {
        return parseJsxChildFromLeftBrace(parser);
    }

    pub fn parseBlockWithTemporaryReturn(parser: *Parser, allow_return: bool) Error!?ast.NodeIndex {
        return parser.parseDialectBlockWithTemporaryReturn(allow_return);
    }

    pub fn finishElement(parser: *Parser, opening: ast.NodeIndex, comptime context: JsxElementContext) Error!?ast.NodeIndex {
        return finishJsxElement(parser, opening, context);
    }

    pub fn parseTagExpressionContainer(parser: *Parser) Error!?ast.NodeIndex {
        return parseJsxExpressionContainer(parser);
    }

    pub fn namesEqual(parser: *const Parser, left: ast.NodeIndex, right: ast.NodeIndex) bool {
        const left_span = parser.tree.span(left);
        const right_span = parser.tree.span(right);
        return std.mem.eql(u8, parser.spanText(left_span), parser.spanText(right_span));
    }

    pub fn advance(parser: *Parser) Error!bool {
        return (try parser.advance()) != null;
    }

    pub fn report(parser: *Parser, span: ast.Span, message: []const u8) Error!void {
        return parser.report(span, message, .{});
    }

    pub fn addRecord(parser: *Parser, record: anytype) Error!u32 {
        return parser.tree.addDialectRecord(record) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => unreachable,
        };
    }

    pub fn addOverlay(parser: *Parser, host: ast.NodeIndex, record_index: u32) Error!void {
        parser.tree.addDialectOverlay(@intFromEnum(host), record_index) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => unreachable,
        };
    }
};

inline fn enterJsxTag(parser: *Parser) void {
    parser.setLexerMode(.jsx_tag);
}

inline fn exitJsxTag(parser: *Parser) void {
    parser.setLexerMode(.normal);
}

// https://facebook.github.io/jsx/#prod-JSXElement
pub fn parseJsxExpression(parser: *Parser) Error!?ast.NodeIndex {
    std.debug.assert(parser.current_token.tag == .less_than);
    return parseJsxElement(parser, .top_level);
}

fn parseJsxElement(parser: *Parser, comptime context: JsxElementContext) Error!?ast.NodeIndex {
    // peek in jsx_tag mode so a fragment's '>' is not glued to the character after it,
    // as in `<>=</>`
    enterJsxTag(parser);
    const next = parser.peekAhead();
    exitJsxTag(parser);

    // fragment: <>...</>
    if (next.tag == .greater_than) {
        return parseJsxFragment(parser);
    }

    const opening = try parseJsxOpeningElement(parser, context) orelse return null;
    const opening_data = parser.tree.data(opening).jsx_opening_element;

    if (comptime dialect.enabled and @hasDecl(dialect, "jsx_element_after_open")) {
        switch (try dialect.jsx_element_after_open(DialectHost, parser, opening, context)) {
            .handled => |node| return node,
            .unhandled => {},
        }
    }
    if (comptime dialect.enabled and @hasDecl(dialect, "validate_jsx_element_name")) {
        switch (try dialect.validate_jsx_element_name(DialectHost, parser, opening_data.name)) {
            .handled => {},
            .unhandled => {},
        }
    }

    return finishJsxElement(parser, opening, context);
}

inline fn finishJsxElement(parser: *Parser, opening: ast.NodeIndex, comptime context: JsxElementContext) Error!?ast.NodeIndex {
    const opening_data = parser.tree.data(opening).jsx_opening_element;
    const opening_end = parser.tree.span(opening).end;
    const start = parser.tree.span(opening).start;

    // self-closing element: <elem />
    if (opening_data.self_closing) {
        return try parser.tree.addNode(.{
            .jsx_element = .{
                .opening_element = opening,
                .children = ast.IndexRange.empty,
                .closing_element = .null,
            },
        }, .{ .start = start, .end = opening_end });
    }

    // element with children: <elem>...</elem>
    const children = try parseJsxChildren(parser, opening_end) orelse return null;

    const closing = try parseJsxClosingElement(
        parser,
        opening_data.name,
        context,
    ) orelse return null;

    return try parser.tree.addNode(.{
        .jsx_element = .{
            .opening_element = opening,
            .children = children,
            .closing_element = closing,
        },
    }, .{ .start = start, .end = parser.tree.span(closing).end });
}

// https://facebook.github.io/jsx/#prod-JSXFragment
fn parseJsxFragment(parser: *Parser) Error!?ast.NodeIndex {
    const start = parser.current_token.span.start;

    // parse <>
    enterJsxTag(parser);
    try parser.advance() orelse return null; // consume '<'
    if (parser.current_token.tag != .greater_than) {
        try parser.reportExpected(
            parser.current_token.span,
            "Expected '>' to close JSX opening fragment",
            .{ .help = "Add '>' to complete the fragment opening tag" },
        );
        return null;
    }
    const opening_end = parser.current_token.span.end;
    const opening = try parser.tree.addNode(
        .{ .jsx_opening_fragment = .{} },
        .{ .start = start, .end = opening_end },
    );

    // parse children (don't advance past '>', parseJsxChildren scans from there)
    const children = try parseJsxChildren(parser, opening_end) orelse return null;

    // parse </>
    const closing_start = parser.current_token.span.start;

    enterJsxTag(parser);

    try parser.advance() orelse return null; // consume '<'

    if (!try parser.expect(
        .slash,
        "Expected '/' in JSX closing fragment",
        "Add '/' to close the fragment",
    )) return null;

    const closing_end = parser.current_token.span.end;

    // leave jsx_tag before consuming '>' so the token after the fragment is plain javascript
    exitJsxTag(parser);

    if (!try parser.expect(
        .greater_than,
        "Expected '>' to close JSX closing fragment",
        "Add '>' to complete the fragment closing tag",
    )) return null;

    const closing = try parser.tree.addNode(
        .{ .jsx_closing_fragment = .{} },
        .{ .start = closing_start, .end = closing_end },
    );

    return try parser.tree.addNode(.{
        .jsx_fragment = .{
            .opening_fragment = opening,
            .children = children,
            .closing_fragment = closing,
        },
    }, .{ .start = start, .end = closing_end });
}

// https://facebook.github.io/jsx/#prod-JSXSelfClosingElement
// https://facebook.github.io/jsx/#prod-JSXOpeningElement
fn parseJsxOpeningElement(
    parser: *Parser,
    comptime context: JsxElementContext,
) Error!?ast.NodeIndex {
    std.debug.assert(parser.current_token.tag == .less_than);
    const start = parser.current_token.span.start;

    enterJsxTag(parser);
    try parser.advance() orelse return null; // consume '<'

    const name = try parseJsxElementName(parser) orelse return null;

    const is_ts_generic = parser.tree.isTs() and ts.isAngleOpen(parser.current_token.tag);
    const type_arguments = if (is_ts_generic) blk: {
        exitJsxTag(parser);
        const args = try ts.parseTypeArguments(parser);
        enterJsxTag(parser);
        try parser.reScanCurrent() orelse return null;
        break :blk args;
    } else .null;

    const attributes = try parseJsxAttributes(parser) orelse return null;

    const self_closing = parser.current_token.tag == .slash;
    if (self_closing) {
        try parser.advance() orelse return null; // consume '/'
    }

    if (parser.current_token.tag != .greater_than) {
        try parser.reportExpected(
            parser.current_token.span,
            "Expected '>' to close JSX opening element",
            .{ .help = "Add '>' to close the JSX tag" },
        );
        return null;
    }
    const end = parser.current_token.span.end;

    // mode and advance handling depends on context and self-closing status:
    // - self-closing attribute: switch to jsx_tag (resume attribute parsing), advance past '>'
    // - self-closing top-level: switch to normal (expression complete), advance past '>'
    // - self-closing child: switch to normal (resume children parsing), don't advance
    //   (parseJsxChildren continues)
    // - non-self-closing: stay in current mode (will switch in parseJsxChildren), don't advance
    if (self_closing) {
        if (context == .attribute) {
            enterJsxTag(parser);
            try parser.advance() orelse return null;
        } else {
            exitJsxTag(parser);
            if (context == .top_level) {
                try parser.advance() orelse return null;
            }
        }
    }

    return try parser.tree.addNode(.{
        .jsx_opening_element = .{
            .name = name,
            .attributes = attributes,
            .self_closing = self_closing,
            .type_arguments = type_arguments,
        },
    }, .{ .start = start, .end = end });
}

// https://facebook.github.io/jsx/#prod-JSXClosingElement
fn parseJsxClosingElement(
    parser: *Parser,
    opening_name: ast.NodeIndex,
    comptime context: JsxElementContext,
) Error!?ast.NodeIndex {
    if (parser.current_token.tag != .less_than) {
        try parser.reportExpected(
            parser.current_token.span,
            "Expected '</' to close the JSX element",
            .{ .help = "Add a closing tag to match the opening element" },
        );
        return null;
    }
    const start = parser.current_token.span.start;

    enterJsxTag(parser);

    try parser.advance() orelse return null; // consume '<'

    const slash_ok = try parser.expect(
        .slash,
        "Expected '/' in JSX closing element",
        "Add '/' after '<' to close the element",
    );
    if (!slash_ok) return null;

    const name = try parseJsxElementName(parser) orelse return null;

    if (parser.current_token.tag != .greater_than) {
        try parser.reportExpected(
            parser.current_token.span,
            "Expected '>' to close JSX closing element",
            .{ .help = "Add '>' to complete the closing tag" },
        );
        return null;
    }
    const end = parser.current_token.span.end;

    // a .child closing tag leaves the `>` in place so the parent `parseJsxChildren` loop
    // can rescan the following jsx text without a stray identifier scan.
    switch (context) {
        .child => exitJsxTag(parser),
        .top_level => {
            exitJsxTag(parser);
            try parser.advance() orelse return null;
        },
        .attribute => {
            enterJsxTag(parser);
            try parser.advance() orelse return null;
        },
    }

    if (!jsxNamesMatch(parser, opening_name, name)) {
        const opening_span = parser.tree.span(opening_name);
        const closing_span = parser.tree.span(name);

        try parser.report(closing_span, try parser.fmt(
            "Expected closing tag for '<{s}>' but found '</{s}>'",
            .{ parser.spanText(opening_span), parser.spanText(closing_span) },
        ), .{
            .help = "JSX opening and closing tags must have matching names",
            .labels = try parser.labels(&.{parser.label(opening_span, "opening tag")}),
        });

        return null;
    }

    return try parser.tree.addNode(
        .{ .jsx_closing_element = .{ .name = name } },
        .{ .start = start, .end = end },
    );
}

fn jsxNamesMatch(parser: *const Parser, a: ast.NodeIndex, b: ast.NodeIndex) bool {
    if (comptime dialect.enabled and @hasDecl(dialect, "jsx_names_match")) {
        switch (dialect.jsx_names_match(DialectHost, parser, a, b)) {
            .handled => |value| return value,
            .unhandled => {},
        }
    }
    const span_a = parser.tree.span(a);
    const span_b = parser.tree.span(b);

    const len_a = span_a.end - span_a.start;
    const len_b = span_b.end - span_b.start;

    if (len_a != len_b) return false;

    const text_a = parser.spanText(span_a);
    const text_b = parser.spanText(span_b);

    return std.mem.eql(u8, text_a, text_b);
}

// https://facebook.github.io/jsx/#prod-JSXChildren
fn parseJsxChildren(parser: *Parser, gt_end: u32) Error!?ast.IndexRange {
    const checkpoint = parser.scratch_b.begin();
    defer parser.scratch_b.reset(checkpoint);

    // switch to normal mode for children
    exitJsxTag(parser);

    var scan_from = gt_end;

    while (true) {
        // scan text content until '<' or '{'
        const text_token = parser.lexer.reScanJsxText(scan_from);

        if (text_token.len() > 0) {
            var text_value = parser.tree.sourceSlice(text_token.span.start, text_token.span.end);
            if (comptime dialect.enabled and @hasDecl(dialect, "jsx_text_value")) {
                switch (try dialect.jsx_text_value(DialectHost, parser, text_token.span)) {
                    .handled => |value| text_value = value,
                    .unhandled => {},
                }
            }
            const text_node = try parser.tree.addNode(.{
                .jsx_text = .{
                    .value = text_value,
                },
            }, text_token.span);

            try parser.scratch_b.append(parser.allocator(), text_node);
        }

        // advance past jsx_text to get the delimiter token ('<' or '{')
        try parser.advanceWithRescannedToken(text_token) orelse return null;

        switch (parser.current_token.tag) {
            .less_than => {
                // check if it's a closing tag
                const next = parser.peekAhead();
                if (next.tag == .slash) break;

                // nested element
                const child = try parseJsxElement(parser, .child) orelse return null;
                scan_from = parser.tree.span(child).end;
                try parser.scratch_b.append(parser.allocator(), child);
            },
            .left_brace => {
                const child = try parseJsxChildFromLeftBrace(parser) orelse return null;
                scan_from = parser.tree.span(child).end;
                try parser.scratch_b.append(parser.allocator(), child);
            },
            .at => {
                if (comptime dialect.enabled and @hasDecl(dialect, "jsx_child_at_code_block")) {
                    switch (try dialect.jsx_child_at_code_block(DialectHost, parser)) {
                        .handled => |node| {
                            const child = node orelse return null;
                            scan_from = parser.tree.span(child).end;
                            try parser.scratch_b.append(parser.allocator(), child);
                            continue;
                        },
                        .unhandled => {},
                    }
                }
                if (comptime dialect.enabled and @hasDecl(dialect, "jsx_child_at_control_flow")) {
                    switch (try dialect.jsx_child_at_control_flow(DialectHost, parser)) {
                        .handled => |node| {
                            const child = node orelse return null;
                            scan_from = parser.tree.span(child).end;
                            try parser.scratch_b.append(parser.allocator(), child);
                            continue;
                        },
                        .unhandled => {},
                    }
                }
                break;
            },
            .greater_than, .right_brace => {
                try parser.report(
                    parser.current_token.span,
                    if (parser.current_token.tag == .greater_than)
                        "Unexpected '>' in JSX text"
                    else
                        "Unexpected '}' in JSX text",
                    .{ .help = "Escape it with an HTML entity or wrap it in an" ++
                        " expression container like {'>'}." },
                );
                scan_from = parser.current_token.span.end;
            },
            else => break,
        }
    }

    return try parser.flushToExtras(&parser.scratch_b, checkpoint);
}

fn parseJsxChildFromLeftBrace(parser: *Parser) Error!?ast.NodeIndex {
    std.debug.assert(parser.current_token.tag == .left_brace);
    const start = parser.current_token.span.start;

    // already in normal mode from parseJsxChildren
    try parser.advance() orelse return null; // consume '{'

    if (parser.current_token.tag == .spread) {
        try parser.advance() orelse return null; // consume '...'

        const expression = try expressions.parseExpression(parser, Precedence.Assignment, .{}) orelse
            return null;
        const end = try expectJsxChildRightBrace(parser, "JSX spread") orelse return null;

        return try parser.tree.addNode(
            .{ .jsx_spread_child = .{ .expression = expression } },
            .{ .start = start, .end = end },
        );
    }

    // empty expression: {}
    if (parser.current_token.tag == .right_brace) {
        const end = parser.current_token.span.end;
        const empty = try parser.tree.addNode(
            .{ .jsx_empty_expression = .{} },
            .{ .start = start + 1, .end = end - 1 },
        );
        return try parser.tree.addNode(
            .{ .jsx_expression_container = .{ .expression = empty } },
            .{ .start = start, .end = end },
        );
    }

    const expression = try expressions.parseExpression(parser, Precedence.Assignment, .{}) orelse
        return null;
    const end = try expectJsxChildRightBrace(parser, "JSX expression") orelse return null;

    return try parser.tree.addNode(
        .{ .jsx_expression_container = .{ .expression = expression } },
        .{ .start = start, .end = end },
    );
}

fn expectJsxChildRightBrace(parser: *Parser, comptime what: []const u8) Error!?u32 {
    if (parser.current_token.tag != .right_brace) {
        try parser.reportExpected(
            parser.current_token.span,
            "Expected '}' to close " ++ what,
            .{ .help = "Add '}' to close the expression" },
        );
        return null;
    }
    return parser.current_token.span.end;
}

// https://facebook.github.io/jsx/#prod-JSXAttributes
fn parseJsxAttributes(parser: *Parser) Error!?ast.IndexRange {
    const checkpoint = parser.scratch_a.begin();
    defer parser.scratch_a.reset(checkpoint);

    while (parser.current_token.tag == .jsx_identifier or parser.current_token.tag == .left_brace) {
        const attr = try parseJsxAttribute(parser) orelse return null;
        try parser.scratch_a.append(parser.allocator(), attr);
    }

    return try parser.flushToExtras(&parser.scratch_a, checkpoint);
}

// https://facebook.github.io/jsx/#prod-JSXAttribute
fn parseJsxAttribute(parser: *Parser) Error!?ast.NodeIndex {
    // spread attribute: {...expr}
    if (parser.current_token.tag == .left_brace) {
        return parseJsxSpreadAttribute(parser);
    }

    // regular attribute: name or name=value
    const name = try parseJsxAttributeName(parser) orelse return null;
    const name_start = parser.tree.span(name).start;

    if (parser.current_token.tag != .assign) {
        // boolean attribute: <elem disabled />
        return try parser.tree.addNode(.{
            .jsx_attribute = .{ .name = name, .value = .null },
        }, .{ .start = name_start, .end = parser.tree.span(name).end });
    }

    try parser.advance() orelse return null; // consume '='
    const value = try parseJsxAttributeValue(parser) orelse return null;

    return try parser.tree.addNode(.{
        .jsx_attribute = .{ .name = name, .value = value },
    }, .{ .start = name_start, .end = parser.tree.span(value).end });
}

// https://facebook.github.io/jsx/#prod-JSXAttributeName
fn parseJsxAttributeName(parser: *Parser) Error!?ast.NodeIndex {
    const start = parser.current_token.span.start;
    var name = try parser.tree.addNode(.{
        .jsx_identifier = .{
            .name = try parser.identifierName(parser.current_token),
        },
    }, parser.current_token.span);

    try parser.advance() orelse return null;

    // check for namespaced name: ns:name
    if (parser.current_token.tag == .colon) {
        try parser.advance() orelse return null; // consume ':'

        if (parser.current_token.tag != .jsx_identifier) {
            try parser.reportExpected(
                parser.current_token.span,
                "Expected identifier after ':' in namespaced attribute",
                .{ .help = "Namespaced attributes must have the form 'namespace:name'" },
            );
            return null;
        }

        const local = try parser.tree.addNode(.{
            .jsx_identifier = .{
                .name = try parser.identifierName(parser.current_token),
            },
        }, parser.current_token.span);
        const end = parser.current_token.span.end;

        try parser.advance() orelse return null;

        name = try parser.tree.addNode(.{
            .jsx_namespaced_name = .{ .namespace = name, .name = local },
        }, .{ .start = start, .end = end });
    }

    return name;
}

// https://facebook.github.io/jsx/#prod-JSXAttributeValue
fn parseJsxAttributeValue(parser: *Parser) Error!?ast.NodeIndex {
    switch (parser.current_token.tag) {
        // string literal: "value" or 'value'
        .string_literal => return literals.parseStringLiteral(parser),

        // expression: {expr}
        .left_brace => {
            const container = try parseJsxExpressionContainer(parser) orelse return null;

            // validate non-empty
            const expr = parser.tree.data(container).jsx_expression_container.expression;
            if (parser.tree.data(expr) == .jsx_empty_expression) {
                try parser.report(
                    parser.tree.span(container),
                    "JSX attribute value cannot be an empty expression",
                    .{ .help = "Replace {} with a valid expression or remove the braces" ++
                        " to use a string literal" },
                );
                return null;
            }

            return container;
        },

        // nested JSX element: <elem />
        .less_than => return parseJsxElement(parser, .attribute),

        else => {
            try parser.reportExpected(
                parser.current_token.span,
                "Expected string literal or JSX expression for attribute value",
                .{ .help = "JSX attribute values must be either a string literal" ++
                    " (e.g. \"value\") or an expression in braces (e.g. {expression})" },
            );
            return null;
        },
    }
}

// parses an attribute-value {expr}, restoring jsx_tag mode after '}'
fn parseJsxExpressionContainer(parser: *Parser) Error!?ast.NodeIndex {
    std.debug.assert(parser.current_token.tag == .left_brace);
    const start = parser.current_token.span.start;

    // switch to normal mode for JS expression parsing
    exitJsxTag(parser);

    try parser.advance() orelse return null; // consume '{'

    // empty expression: {}
    if (parser.current_token.tag == .right_brace) {
        const end = parser.current_token.span.end;
        enterJsxTag(parser);
        try parser.advance() orelse return null;

        const empty = try parser.tree.addNode(
            .{ .jsx_empty_expression = .{} },
            .{ .start = start + 1, .end = end - 1 },
        );
        return try parser.tree.addNode(
            .{ .jsx_expression_container = .{ .expression = empty } },
            .{ .start = start, .end = end },
        );
    }

    const expression = try expressions.parseExpression(parser, Precedence.Assignment, .{}) orelse
        return null;
    const end = parser.current_token.span.end;

    // restore mode before consuming '}'
    enterJsxTag(parser);

    const brace_ok = try parser.expect(
        .right_brace,
        "Expected '}' to close JSX expression",
        "Add '}' to close the expression",
    );
    if (!brace_ok) return null;

    return try parser.tree.addNode(
        .{ .jsx_expression_container = .{ .expression = expression } },
        .{ .start = start, .end = end },
    );
}

// parses {...expr} as spread attribute
fn parseJsxSpreadAttribute(parser: *Parser) Error!?ast.NodeIndex {
    std.debug.assert(parser.current_token.tag == .left_brace);
    const start = parser.current_token.span.start;

    exitJsxTag(parser);

    try parser.advance() orelse return null; // consume '{'

    const spread_ok = try parser.expect(
        .spread,
        "Expected '...' after '{' in JSX spread",
        "Add '...' to spread the expression",
    );
    if (!spread_ok) return null;

    const expression = try expressions.parseExpression(parser, Precedence.Assignment, .{}) orelse
        return null;
    const end = parser.current_token.span.end;

    enterJsxTag(parser);

    const brace_ok = try parser.expect(
        .right_brace,
        "Expected '}' to close JSX spread",
        "Add '}' to close the spread expression",
    );
    if (!brace_ok) return null;

    return try parser.tree.addNode(
        .{ .jsx_spread_attribute = .{ .argument = expression } },
        .{ .start = start, .end = end },
    );
}

// https://facebook.github.io/jsx/#prod-JSXElementName
fn parseJsxElementName(parser: *Parser) Error!?ast.NodeIndex {
    if (comptime dialect.enabled and @hasDecl(dialect, "jsx_element_name")) {
        switch (try dialect.jsx_element_name(DialectHost, parser)) {
            .handled => |node| return node,
            .unhandled => {},
        }
    }
    return parseJsxElementNameContinuation(parser);
}

inline fn parseJsxElementNameContinuation(parser: *Parser) Error!?ast.NodeIndex {
    if (parser.current_token.tag != .jsx_identifier) {
        try parser.reportExpected(
            parser.current_token.span,
            "Expected JSX element name",
            .{ .help = "JSX element names must start with a valid identifier" },
        );
        return null;
    }

    const start = parser.current_token.span.start;
    var name = try parser.tree.addNode(.{
        .jsx_identifier = .{
            .name = try parser.identifierName(parser.current_token),
        },
    }, parser.current_token.span);

    try parser.advance() orelse return null;

    // member expression: Foo.Bar.Baz
    var is_member = false;
    while (parser.current_token.tag == .dot) {
        try parser.advance() orelse return null; // consume '.'

        if (parser.current_token.tag != .jsx_identifier) {
            try parser.reportExpected(
                parser.current_token.span,
                "Expected identifier after '.' in JSX member expression",
                .{ .help = "Member expressions in JSX must have the form 'object.property'" },
            );
            return null;
        }

        is_member = true;
        const property = try parser.tree.addNode(.{
            .jsx_identifier = .{
                .name = try parser.identifierName(parser.current_token),
            },
        }, parser.current_token.span);
        const end = parser.current_token.span.end;

        try parser.advance() orelse return null;

        name = try parser.tree.addNode(.{
            .jsx_member_expression = .{ .object = name, .property = property },
        }, .{ .start = start, .end = end });
    }

    // namespaced name: ns:name (not allowed after member expression)
    if (parser.current_token.tag == .colon and !is_member) {
        try parser.advance() orelse return null; // consume ':'

        if (parser.current_token.tag != .jsx_identifier) {
            try parser.reportExpected(
                parser.current_token.span,
                "Expected identifier after ':' in namespaced element name",
                .{ .help = "Namespaced element names must have the form 'namespace:name'" },
            );
            return null;
        }

        const local = try parser.tree.addNode(.{
            .jsx_identifier = .{
                .name = try parser.identifierName(parser.current_token),
            },
        }, parser.current_token.span);
        const end = parser.current_token.span.end;

        try parser.advance() orelse return null;

        name = try parser.tree.addNode(.{
            .jsx_namespaced_name = .{ .namespace = name, .name = local },
        }, .{ .start = start, .end = end });
    }

    return name;
}
