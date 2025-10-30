const std = @import("std");

const Token = @import("token.zig").Token;
const Span = @import("token.zig").Span;
const TokenType = @import("token.zig").TokenType;
const Lexer = @import("lexer.zig").Lexer;
const Node = @import("ast.zig").Node;

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
    help: []const u8,
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

    pub fn parse(self: *Parser) !*Node {
        var body: std.ArrayList(*Node) = .empty;

        while (self.current_token.type != .EOF) {
            const stmt = try self.parseStatement();
            try body.append(self.allocator, stmt);
        }

        return self.createNode(.{ .program = .{ .body = try body.toOwnedSlice(self.allocator) } });
    }

    fn parseStatement(self: *Parser) !*Node {
        return switch (self.current_token.type) {
            .Var, .Const, .Let => try self.parseVariableDeclaration(),
            else => {
                return error.InvalidSyntax;
            },
        };
    }

    fn parseExpression(self: *Parser) !*Node {
        return switch (self.current_token.type) {
            .Identifier => {
                const name = self.current_token.lexeme;

                _ = try self.advance();

                return self.createNode(.{ .identifier = .{ .name = name } });
            },
            else => {
                return error.InvalidSyntax;
            },
        };
    }

    fn parseVariableDeclaration(self: *Parser) !*Node {
        _ = try self.advance();
        return self.createNode(.{ .identifier = .{ .name = "cool" } });
    }

    inline fn advance(self: *Parser) !Token {
        const token = self.current_token;
        self.current_token = self.lexer.nextToken() catch |err| {
            const message: []const u8 = switch (err) {
                error.InvalidHexEscape => "Invalid hex escape sequence",
                error.UnterminatedString => "Unterminated string literal",
                error.UnterminatedRegex => "Unterminated regular expression",
                error.NonTerminatedTemplateLiteral => "Unterminated template literal",
                error.UnterminatedRegexLiteral => "Unterminated regex literal",
                error.InvalidRegexLineTerminator => "Invalid line terminator in regex",
                error.InvalidRegex => "Invalid regular expression",
                error.InvalidIdentifierStart => "Invalid identifier start character",
                error.UnterminatedMultiLineComment => "Unterminated multi-line comment",
                error.InvalidUnicodeEscape => "Invalid unicode escape sequence",
                error.InvalidOctalEscape => "Invalid octal escape sequence",
                error.OctalEscapeInStrict => "Octal escape sequences not allowed in strict mode",
            };

            const help: []const u8 = switch (err) {
                error.InvalidHexEscape => "Hex escapes must be in format \\xHH where HH are valid hex digits",
                error.UnterminatedString => "Add closing quote to complete the string literal",
                error.UnterminatedRegex => "Add closing delimiter to complete the regular expression",
                error.NonTerminatedTemplateLiteral => "Add closing backtick (`) to complete the template literal",
                error.UnterminatedRegexLiteral => "Add closing delimiter (/) to complete the regex literal",
                error.InvalidRegexLineTerminator => "Line terminators are not allowed inside regex literals",
                error.InvalidRegex => "Check regex syntax for invalid patterns or modifiers",
                error.InvalidIdentifierStart => "Identifiers must start with a letter, underscore, or dollar sign",
                error.UnterminatedMultiLineComment => "Add closing */ to complete the multi-line comment",
                error.InvalidUnicodeEscape => "Unicode escapes must be in format \\uHHHH or \\u{H+}",
                error.InvalidOctalEscape => "Octal escapes must be in format \\0-7 or \\00-77 or \\000-377",
                error.OctalEscapeInStrict => "Use \\x or \\u escape sequences instead in strict mode",
            };

            try self.errors.append(self.allocator, .{ .type = .LexicalError, .message = message, .help = help, .severity = "error", .span = .{ .start = self.current_token.span } });
        };
        return token;
    }

    inline fn expect(self: *Parser, expected: TokenType) !Token {
        if (self.current_token.type == expected) {
            return try self.advance();
        }

        return error.ExpectedToken;
    }

    inline fn createNode(self: *Parser, node: Node) !*Node {
        const ptr = try self.allocator.create(Node);
        ptr.* = node;
        return ptr;
    }
};
