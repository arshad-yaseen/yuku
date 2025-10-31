const std = @import("std");

const token = @import("token.zig");
const lexer = @import("lexer.zig");
const ast = @import("ast.zig");

const ParseError = error{
    LexicalError,
    UnexpectedToken,
    ExpectedToken,
    UnexpectedEof,
    InvalidSyntax,
    DuplicateDeclaration,
    InvalidAssignmentTarget,
    OutOfMemory,
};

const ParseErrorData = struct {
    message: []const u8,
    span: token.Span,
    help: []const u8,
    severity: Severity,

    const Severity = enum { @"error", warning, info };
};

pub const Parser = struct {
    panic_mode: bool,
    source: []const u8,
    lexer: lexer.Lexer,
    current_token: token.Token,
    /// expects arena allocator
    allocator: std.mem.Allocator,
    errors: std.ArrayList(ParseErrorData),

    pub fn init(allocator: std.mem.Allocator, source: []const u8) !Parser {
        const lexer_instance = try lexer.Lexer.init(allocator, source);

        return Parser{ .lexer = lexer_instance, .current_token = undefined, .source = source, .allocator = allocator, .panic_mode = false, .errors = .empty };
    }

    pub fn parse(self: *Parser) !*ast.Node {
        // let's start tokenizing
        self.current_token = try self.lexer.nextToken();

        const start = self.current_token.span.start;
        var body: std.ArrayList(*ast.Node) = .empty;

        while (self.current_token.type != .EOF) {
            const stmt = try self.parseStatement();
            try body.append(self.allocator, stmt);
        }

        const end = self.current_token.span.end;

        return self.createNode(.{ .program = .{ .body = try body.toOwnedSlice(self.allocator), .span = .{ .start = start, .end = end } } });
    }

    fn parseStatement(self: *Parser) !*ast.Node {
        return switch (self.current_token.type) {
            .Var, .Const, .Let => try self.parseVariableDeclaration(),
            else => {
                return error.InvalidSyntax;
            },
        };
    }

    fn parseExpression(self: *Parser) !*ast.Node {
        return switch (self.current_token.type) {
            .Identifier => {
                const name = self.current_token.lexeme;
                const span = self.current_token.span;

                try self.advance();

                return self.createNode(.{ .identifier = .{ .name = name, .span = span } });
            },
            else => {
                return error.InvalidSyntax;
            },
        };
    }

    fn parseVariableDeclaration(self: *Parser) !*ast.Node {
        const start = self.current_token.span.start;

        const kind: ast.VariableDeclaration.VariableKind = switch (self.current_token.type) {
            .Var => .@"var",
            .Let => .let,
            .Const => .@"const",
            else => unreachable,
        };

        try self.advance();

        var declarators: std.ArrayList(*ast.Node) = .empty;

        try declarators.append(self.allocator, try self.parseVariableDeclarator());

        // declarators separated by commas
        while (self.current_token.type == .Comma) {
            try self.advance(); // consume comma
            try declarators.append(self.allocator, try self.parseVariableDeclarator());
        }

        // expect semicolon at the end
        if (self.current_token.type != .Semicolon) {
            return error.ExpectedToken;
        }

        const end = self.current_token.span.end;
        try self.advance(); // consume semicolon

        return self.createNode(.{
            .variable_declaration = .{
                .kind = kind,
                .declarations = try declarators.toOwnedSlice(self.allocator),
                .span = .{ .start = start, .end = end }
            }
        });
    }

    fn parseVariableDeclarator(self: *Parser) !*ast.Node {
        const start = self.current_token.span.start;

        if (self.current_token.type != .Identifier) {
            return error.ExpectedToken;
        }

        const id_name = self.current_token.lexeme;
        const id_span = self.current_token.span;

        try self.advance(); // consume identifier

        const id = try self.createNode(.{ .identifier = .{ .name = id_name, .span = id_span } });

        // optional initializer
        var initializer: ?*ast.Node = null;
        if (self.current_token.type == .Assign) {
            try self.advance(); // consume =
            initializer = try self.parseExpression();
        }

        const end = if (initializer) |i| i.getSpan().end else id_span.end;

        return self.createNode(.{
            .variable_declarator = .{
                .id = id,
                .init = initializer,
                .span = .{ .start = start, .end = end }
            }
        });
    }

    inline fn advance(self: *Parser) ParseError!void {
        self.current_token = self.lexer.nextToken() catch |err| {
            try self.errors.append(self.allocator, .{ .message = lexer.getLexicalErrorMessage(err), .help = lexer.getLexicalErrorHelp(err), .severity = .@"error", .span = .{
                .start = self.current_token.span.end,
                .end = self.lexer.position,
            } });

            return error.LexicalError;
        };
    }

    inline fn createNode(self: *Parser, node: ast.Node) !*ast.Node {
        const ptr = try self.allocator.create(ast.Node);
        ptr.* = node;
        return ptr;
    }
};
