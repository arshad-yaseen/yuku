const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("token.zig").Token;
const TokenType = @import("token.zig").TokenType;

fn expectToken(token: Token, expected_type: TokenType, expected_lexeme: []const u8) !void {
    try std.testing.expectEqual(expected_type, token.type);
    try std.testing.expectEqualStrings(expected_lexeme, token.lexeme);
}

fn expectTokenType(token: Token, expected_type: TokenType) !void {
    try std.testing.expectEqual(expected_type, token.type);
}

test "single character tokens - arithmetic operators" {
    var lexer = Lexer.init("+");
    const token1 = try lexer.nextToken();
    try expectToken(token1, TokenType.Plus, "+");
    try std.testing.expectEqual(@as(usize, 0), token1.span.start);
    try std.testing.expectEqual(@as(usize, 1), token1.span.end);
}
