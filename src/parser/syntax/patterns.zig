const std = @import("std");
const Parser = @import("../parser.zig").Parser;
const Error = @import("../parser.zig").Error;
const dialect = @import("dialect");
const ast = @import("../ast.zig");
const TokenTag = @import("../token.zig").TokenTag;
const Precedence = @import("../token.zig").Precedence;

const array = @import("array.zig");
const object = @import("object.zig");
const literals = @import("literals.zig");
const expressions = @import("expressions.zig");
const ts = @import("ts/types.zig");

const DialectHost = struct {
    pub const NodeIndex = ast.NodeIndex;
    pub const Token = TokenTag;
    pub const ErrorType = Error;

    pub fn currentToken(parser: *const Parser) TokenTag {
        return parser.current_token.tag;
    }

    pub fn currentSpan(parser: *const Parser) ast.Span {
        return parser.current_token.span;
    }

    pub fn advance(parser: *Parser) Error!bool {
        return (try parser.advance()) != null;
    }

    pub fn extendNodeStart(parser: *Parser, node: ast.NodeIndex, start: u32) void {
        parser.tree.setSpan(node, .{ .start = start, .end = parser.tree.span(node).end });
    }

    pub fn parseOrdinaryBinding(parser: *Parser) Error!?ast.NodeIndex {
        return parseBindingPatternContinuation(parser);
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

pub inline fn parseBindingPattern(parser: *Parser) Error!?ast.NodeIndex {
    if (comptime dialect.enabled and @hasDecl(dialect, "binding_pattern")) {
        switch (try dialect.binding_pattern(DialectHost, parser)) {
            .handled => |node| return node,
            .unhandled => {},
        }
    }
    return parseBindingPatternContinuation(parser);
}

inline fn parseBindingPatternContinuation(parser: *Parser) Error!?ast.NodeIndex {
    if (parser.current_token.tag.isIdentifierLike()) {
        return literals.parseBindingIdentifier(parser);
    }

    return switch (parser.current_token.tag) {
        .left_bracket => parseArrayPattern(parser),
        .left_brace => parseObjectPattern(parser),
        else => {
            try parser.report(
                parser.current_token.span,
                try parser.fmt(
                    "Unexpected token '{s}' in binding pattern",
                    .{parser.describeToken(parser.current_token)},
                ),
                .{ .help = "Expected an identifier, array pattern ([a, b])," ++
                    " or object pattern ({a, b})." },
            );
            return null;
        },
    };
}

fn parseArrayPattern(parser: *Parser) Error!?ast.NodeIndex {
    std.debug.assert(parser.current_token.tag == .left_bracket);
    const cover = try array.parseCover(parser) orelse return null;
    return try array.coverToPattern(parser, cover, .binding);
}

fn parseObjectPattern(parser: *Parser) Error!?ast.NodeIndex {
    std.debug.assert(parser.current_token.tag == .left_brace);
    const cover = try object.parseCover(parser) orelse return null;
    return try object.coverToPattern(parser, cover, .binding);
}

pub fn parseAssignmentPattern(parser: *Parser, left: ast.NodeIndex) Error!?ast.NodeIndex {
    std.debug.assert(left != .null);
    const start = parser.tree.span(left).start;

    if (parser.current_token.tag != .assign) return left;

    try parser.advance() orelse return null;

    const right = try expressions.parseExpression(parser, Precedence.Assignment, .{}) orelse
        return null;

    return try parser.tree.addNode(
        .{ .assignment_pattern = .{ .left = left, .right = right } },
        .{ .start = start, .end = parser.tree.span(right).end },
    );
}

pub fn parseBindingRestElement(parser: *Parser) Error!?ast.NodeIndex {
    std.debug.assert(parser.current_token.tag == .spread);
    const start = parser.current_token.span.start;
    try parser.advance() orelse return null; // consume ...

    const argument = try parseBindingPattern(parser) orelse return null;
    var end = parser.tree.span(argument).end;

    // `function f(...rest: Type[]) { ... }`
    var type_annotation: ast.NodeIndex = .null;
    if (parser.tree.isTs() and parser.current_token.tag == .colon) {
        type_annotation = try ts.parseTypeAnnotation(parser) orelse return null;
        end = parser.tree.span(type_annotation).end;
    }

    return try parser.tree.addNode(
        .{ .binding_rest_element = .{ .argument = argument, .type_annotation = type_annotation } },
        .{ .start = start, .end = end },
    );
}

pub fn isDestructuringPattern(parser: *Parser, index: ast.NodeIndex) bool {
    return switch (parser.tree.data(index)) {
        .array_pattern, .object_pattern => true,
        .assignment_pattern => |pattern| isDestructuringPattern(parser, pattern.left),
        else => false,
    };
}
