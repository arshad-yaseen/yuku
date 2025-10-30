const std = @import("std");
const Token = @import("token.zig").Token;
const Span = @import("token.zig").Span;
const TokenType = @import("token.zig").TokenType;
const Lexer = @import("lexer.zig").Lexer;
const AstNode = @import("ast.zig").AstNode;
const Program = @import("ast.zig").Program;
const VariableDeclaration = @import("ast.zig").VariableDeclaration;
const VariableKind = @import("ast.zig").VariableKind;
const Identifier = @import("ast.zig").Identifier;
const Expression = @import("ast.zig").Expression;

const ParseErrorType = enum {
    LexicalError,
    UnexpectedToken,
    ExpectedToken,
    UnexpectedEof,
    InvalidSyntax,
    DuplicateDeclaration,
    InvalidAssignmentTarget,
};

const ParseError = struct {
    type: ParseErrorType,
    message: []const u8,
    span: Span,
    help: ?[][]const u8,
    severity: Severity,

    const Severity = enum { @"error", warning, info };
};

pub const Parser = struct {
    panic_mode: bool,
    source: []const u8,
    lexer: Lexer,
    current_token: Token,
    /// expects arena allocator
    allocator: std.mem.Allocator,
    errors: std.ArrayList(ParseError),

    pub fn init(allocator: std.mem.Allocator, source: []const u8) !Parser {
        var lexer = try Lexer.init(allocator, source);

        return Parser{ .lexer = lexer, .current_token = try lexer.nextToken(), .source = source, .allocator = allocator, .panic_mode = false, .errors = .empty };
    }

    pub fn parse(self: *Parser) !AstNode {
        var body: std.ArrayList(AstNode) = .empty;

        while (self.current_token.type != .EOF) {
            const stmt = try self.parseStatement();
            try body.append(self.allocator, stmt);
        }

        return AstNode{ .program = Program{
            .body = try body.toOwnedSlice(self.allocator),
        } };
    }

    fn parseStatement(self: *Parser) !AstNode {
        return switch (self.current_token.type) {
            .Var, .Const, .Let => try self.parseVariableDeclaration(),
            else => unreachable,
        };
    }

    fn parseVariableDeclaration(self: *Parser) !AstNode {
        const kind: VariableKind = switch (self.current_token.type) {
            .Var => .var_,
            .Let => .let,
            .Const => .const_,
            else => unreachable,
        };

        _ = try self.advance();

        const id = try self.expectIdentifier();

        var initializer: ?Expression = null;
        if (self.current_token.type == .Assign) {
            _ = try self.advance();
            initializer = try self.parseExpression();
        }

        _ = try self.expect(.Semicolon);

        return AstNode{
            .variable_declaration = VariableDeclaration{
                .kind = kind,
                .id = Identifier{ .name = id },
                .init = initializer,
            },
        };
    }

    fn parseExpression(self: *Parser) !Expression {
        return switch (self.current_token.type) {
            .Identifier => {
                const name = self.current_token.lexeme;
                _ = try self.advance();
                return Expression{ .identifier = Identifier{ .name = name } };
            },
            else => {
                return error.InvalidSyntax;
            },
        };
    }

    fn advance(self: *Parser) !Token {
        const token = self.current_token;
        self.current_token = try self.lexer.nextToken();
        return token;
    }

    fn expect(self: *Parser, expected: TokenType) !Token {
        if (self.current_token.type == expected) {
            return try self.advance();
        }
        return error.ExpectedToken;
    }

    fn expectIdentifier(self: *Parser) ![]const u8 {
        if (self.current_token.type == .Identifier) {
            const name = self.current_token.lexeme;
            _ = try self.advance();
            return name;
        }
        return error.ExpectedToken;
    }
};
