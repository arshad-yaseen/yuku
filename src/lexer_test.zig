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

    lexer = Lexer.init("-");
    const token2 = try lexer.nextToken();
    try expectToken(token2, TokenType.Minus, "-");

    lexer = Lexer.init("*");
    const token3 = try lexer.nextToken();
    try expectToken(token3, TokenType.Star, "*");

    lexer = Lexer.init("/");
    const token4 = try lexer.nextToken();
    try expectToken(token4, TokenType.Slash, "/");
}

test "single character tokens - parentheses and braces" {
    var lexer = Lexer.init("(");
    const token1 = try lexer.nextToken();
    try expectToken(token1, TokenType.LeftParen, "(");

    lexer = Lexer.init(")");
    const token2 = try lexer.nextToken();
    try expectToken(token2, TokenType.RightParen, ")");

    lexer = Lexer.init("{");
    const token3 = try lexer.nextToken();
    try expectToken(token3, TokenType.LeftBrace, "{");

    lexer = Lexer.init("}");
    const token4 = try lexer.nextToken();
    try expectToken(token4, TokenType.RightBrace, "}");
}

test "single character tokens - punctuation" {
    var lexer = Lexer.init(";");
    const token1 = try lexer.nextToken();
    try expectToken(token1, TokenType.Semicolon, ";");

    lexer = Lexer.init(",");
    const token2 = try lexer.nextToken();
    try expectToken(token2, TokenType.Comma, ",");

    lexer = Lexer.init("=");
    const token3 = try lexer.nextToken();
    try expectToken(token3, TokenType.Assign, "=");

    lexer = Lexer.init("<");
    const token4 = try lexer.nextToken();
    try expectToken(token4, TokenType.LessThan, "<");

    lexer = Lexer.init(">");
    const token5 = try lexer.nextToken();
    try expectToken(token5, TokenType.GreaterThan, ">");
}

test "numeric literals - integers" {
    var lexer = Lexer.init("0");
    const token1 = try lexer.nextToken();
    try expectToken(token1, TokenType.NumericLiteral, "0");

    lexer = Lexer.init("42");
    const token2 = try lexer.nextToken();
    try expectToken(token2, TokenType.NumericLiteral, "42");

    lexer = Lexer.init("12345");
    const token3 = try lexer.nextToken();
    try expectToken(token3, TokenType.NumericLiteral, "12345");

    lexer = Lexer.init("999999999");
    const token4 = try lexer.nextToken();
    try expectToken(token4, TokenType.NumericLiteral, "999999999");
}

test "numeric literals - decimals" {
    var lexer = Lexer.init("3.14");
    const token1 = try lexer.nextToken();
    try expectToken(token1, TokenType.NumericLiteral, "3.14");

    lexer = Lexer.init("0.5");
    const token2 = try lexer.nextToken();
    try expectToken(token2, TokenType.NumericLiteral, "0.5");

    lexer = Lexer.init("123.456");
    const token3 = try lexer.nextToken();
    try expectToken(token3, TokenType.NumericLiteral, "123.456");

    lexer = Lexer.init("10.10");
    const token4 = try lexer.nextToken();
    try expectToken(token4, TokenType.NumericLiteral, "10.10");
}

test "numeric literals - edge cases with dots" {
    var lexer = Lexer.init("42.");
    const token1 = try lexer.nextToken();
    try expectToken(token1, TokenType.NumericLiteral, "42");
    const token2 = try lexer.nextToken();
    try expectTokenType(token2, TokenType.Invalid);

    lexer = Lexer.init("5..");
    const token3 = try lexer.nextToken();
    try expectToken(token3, TokenType.NumericLiteral, "5");
}

test "whitespace handling - spaces" {
    var lexer = Lexer.init("   42");
    const token = try lexer.nextToken();
    try expectToken(token, TokenType.NumericLiteral, "42");
    try std.testing.expectEqual(@as(usize, 3), token.span.start);
}

test "whitespace handling - tabs and spaces mixed" {
    var lexer = Lexer.init("  \t  +");
    const token = try lexer.nextToken();
    try expectToken(token, TokenType.Plus, "+");
}

test "whitespace handling - carriage return" {
    var lexer = Lexer.init("\r\r42");
    const token = try lexer.nextToken();
    try expectToken(token, TokenType.NumericLiteral, "42");
}

test "whitespace between tokens" {
    var lexer = Lexer.init("42   +   10");
    const token1 = try lexer.nextToken();
    try expectToken(token1, TokenType.NumericLiteral, "42");

    const token2 = try lexer.nextToken();
    try expectToken(token2, TokenType.Plus, "+");

    const token3 = try lexer.nextToken();
    try expectToken(token3, TokenType.NumericLiteral, "10");
}

test "simple arithmetic expression" {
    var lexer = Lexer.init("1+2");
    const token1 = try lexer.nextToken();
    try expectToken(token1, TokenType.NumericLiteral, "1");

    const token2 = try lexer.nextToken();
    try expectToken(token2, TokenType.Plus, "+");

    const token3 = try lexer.nextToken();
    try expectToken(token3, TokenType.NumericLiteral, "2");

    const eof = try lexer.nextToken();
    try expectTokenType(eof, TokenType.EOF);
}

test "complex arithmetic expression" {
    var lexer = Lexer.init("10 + 20 * 30 - 5 / 2");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "10");
    try expectToken(try lexer.nextToken(), TokenType.Plus, "+");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "20");
    try expectToken(try lexer.nextToken(), TokenType.Star, "*");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "30");
    try expectToken(try lexer.nextToken(), TokenType.Minus, "-");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "5");
    try expectToken(try lexer.nextToken(), TokenType.Slash, "/");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "2");
    try expectTokenType(try lexer.nextToken(), TokenType.EOF);
}

test "expression with parentheses" {
    var lexer = Lexer.init("(10 + 5) * 2");
    try expectToken(try lexer.nextToken(), TokenType.LeftParen, "(");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "10");
    try expectToken(try lexer.nextToken(), TokenType.Plus, "+");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "5");
    try expectToken(try lexer.nextToken(), TokenType.RightParen, ")");
    try expectToken(try lexer.nextToken(), TokenType.Star, "*");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "2");
    try expectTokenType(try lexer.nextToken(), TokenType.EOF);
}

test "comparison operators" {
    var lexer = Lexer.init("5 < 10 > 3");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "5");
    try expectToken(try lexer.nextToken(), TokenType.LessThan, "<");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "10");
    try expectToken(try lexer.nextToken(), TokenType.GreaterThan, ">");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "3");
}

test "assignment expression" {
    var lexer = Lexer.init("x = 42");
    try expectTokenType(try lexer.nextToken(), TokenType.Invalid);
    try expectToken(try lexer.nextToken(), TokenType.Assign, "=");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "42");
}

test "block with braces and semicolons" {
    var lexer = Lexer.init("{ 1; 2; }");
    try expectToken(try lexer.nextToken(), TokenType.LeftBrace, "{");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "1");
    try expectToken(try lexer.nextToken(), TokenType.Semicolon, ";");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "2");
    try expectToken(try lexer.nextToken(), TokenType.Semicolon, ";");
    try expectToken(try lexer.nextToken(), TokenType.RightBrace, "}");
}

test "comma separated values" {
    var lexer = Lexer.init("1, 2, 3");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "1");
    try expectToken(try lexer.nextToken(), TokenType.Comma, ",");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "2");
    try expectToken(try lexer.nextToken(), TokenType.Comma, ",");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "3");
}

test "empty input" {
    var lexer = Lexer.init("");
    const token = try lexer.nextToken();
    try expectTokenType(token, TokenType.EOF);
}

test "only whitespace" {
    var lexer = Lexer.init("   \t  \r  ");
    const token = try lexer.nextToken();
    try expectTokenType(token, TokenType.EOF);
}

test "multiple EOF calls" {
    var lexer = Lexer.init("42");
    _ = try lexer.nextToken();

    const eof1 = try lexer.nextToken();
    try expectTokenType(eof1, TokenType.EOF);

    const eof2 = try lexer.nextToken();
    try expectTokenType(eof2, TokenType.EOF);
}

test "invalid character - letter" {
    var lexer = Lexer.init("a");
    const token = try lexer.nextToken();
    try expectTokenType(token, TokenType.Invalid);
}

test "invalid character - special symbols" {
    var lexer = Lexer.init("@");
    const token1 = try lexer.nextToken();
    try expectTokenType(token1, TokenType.Invalid);

    lexer = Lexer.init("#");
    const token2 = try lexer.nextToken();
    try expectTokenType(token2, TokenType.Invalid);

    lexer = Lexer.init("$");
    const token3 = try lexer.nextToken();
    try expectTokenType(token3, TokenType.Invalid);
}

test "decimal numbers with operators" {
    var lexer = Lexer.init("3.14 + 2.71");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "3.14");
    try expectToken(try lexer.nextToken(), TokenType.Plus, "+");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "2.71");
}

test "zero variations" {
    var lexer = Lexer.init("0");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "0");

    lexer = Lexer.init("0.0");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "0.0");

    lexer = Lexer.init("00");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "00");
}

test "number followed by invalid character" {
    var lexer = Lexer.init("42x");
    const token1 = try lexer.nextToken();
    try expectToken(token1, TokenType.NumericLiteral, "42");

    const token2 = try lexer.nextToken();
    try expectTokenType(token2, TokenType.Invalid);
}

test "complex nested expression" {
    var lexer = Lexer.init("((1 + 2) * (3 - 4)) / 5");
    try expectToken(try lexer.nextToken(), TokenType.LeftParen, "(");
    try expectToken(try lexer.nextToken(), TokenType.LeftParen, "(");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "1");
    try expectToken(try lexer.nextToken(), TokenType.Plus, "+");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "2");
    try expectToken(try lexer.nextToken(), TokenType.RightParen, ")");
    try expectToken(try lexer.nextToken(), TokenType.Star, "*");
    try expectToken(try lexer.nextToken(), TokenType.LeftParen, "(");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "3");
    try expectToken(try lexer.nextToken(), TokenType.Minus, "-");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "4");
    try expectToken(try lexer.nextToken(), TokenType.RightParen, ")");
    try expectToken(try lexer.nextToken(), TokenType.RightParen, ")");
    try expectToken(try lexer.nextToken(), TokenType.Slash, "/");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "5");
}

test "all operators in sequence" {
    var lexer = Lexer.init("+-*/<>=");
    try expectToken(try lexer.nextToken(), TokenType.Plus, "+");
    try expectToken(try lexer.nextToken(), TokenType.Minus, "-");
    try expectToken(try lexer.nextToken(), TokenType.Star, "*");
    try expectToken(try lexer.nextToken(), TokenType.Slash, "/");
    try expectToken(try lexer.nextToken(), TokenType.LessThan, "<");
    try expectToken(try lexer.nextToken(), TokenType.GreaterThan, ">");
    try expectToken(try lexer.nextToken(), TokenType.Assign, "=");
}

test "span tracking - single token" {
    var lexer = Lexer.init("42");
    const token = try lexer.nextToken();
    try std.testing.expectEqual(@as(usize, 0), token.span.start);
    try std.testing.expectEqual(@as(usize, 2), token.span.end);
}

test "span tracking - multiple tokens" {
    var lexer = Lexer.init("1 + 2");

    const token1 = try lexer.nextToken();
    try std.testing.expectEqual(@as(usize, 0), token1.span.start);
    try std.testing.expectEqual(@as(usize, 1), token1.span.end);

    const token2 = try lexer.nextToken();
    try std.testing.expectEqual(@as(usize, 2), token2.span.start);
    try std.testing.expectEqual(@as(usize, 3), token2.span.end);

    const token3 = try lexer.nextToken();
    try std.testing.expectEqual(@as(usize, 4), token3.span.start);
    try std.testing.expectEqual(@as(usize, 5), token3.span.end);
}

test "span tracking - decimal number" {
    var lexer = Lexer.init("3.14");
    const token = try lexer.nextToken();
    try std.testing.expectEqual(@as(usize, 0), token.span.start);
    try std.testing.expectEqual(@as(usize, 4), token.span.end);
}

test "multiple dots in sequence" {
    var lexer = Lexer.init("2.3.1");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "2.3");
    try expectTokenType(try lexer.nextToken(), TokenType.Invalid);
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "1");
    try expectTokenType(try lexer.nextToken(), TokenType.EOF);
}

test "version-like number sequence" {
    var lexer = Lexer.init("1.2.3.4");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "1.2");
    try expectTokenType(try lexer.nextToken(), TokenType.Invalid);
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "3.4");
    try expectTokenType(try lexer.nextToken(), TokenType.EOF);
}

test "multiple decimals in expression" {
    var lexer = Lexer.init("1.1.1 + 2.2");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "1.1");
    try expectTokenType(try lexer.nextToken(), TokenType.Invalid);
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "1");
    try expectToken(try lexer.nextToken(), TokenType.Plus, "+");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "2.2");
    try expectTokenType(try lexer.nextToken(), TokenType.EOF);
}

test "number with trailing dot then operator" {
    var lexer = Lexer.init("42. + 10");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "42");
    try expectTokenType(try lexer.nextToken(), TokenType.Invalid);
    try expectToken(try lexer.nextToken(), TokenType.Plus, "+");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "10");
}

test "dot not followed by digit" {
    var lexer = Lexer.init("5. 10");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "5");
    try expectTokenType(try lexer.nextToken(), TokenType.Invalid);
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "10");
}

test "consecutive invalid characters" {
    var lexer = Lexer.init("@@##");
    try expectTokenType(try lexer.nextToken(), TokenType.Invalid);
    try expectTokenType(try lexer.nextToken(), TokenType.Invalid);
    try expectTokenType(try lexer.nextToken(), TokenType.Invalid);
    try expectTokenType(try lexer.nextToken(), TokenType.Invalid);
}

test "invalid characters mixed with valid tokens" {
    var lexer = Lexer.init("1 @ 2 # 3");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "1");
    try expectTokenType(try lexer.nextToken(), TokenType.Invalid);
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "2");
    try expectTokenType(try lexer.nextToken(), TokenType.Invalid);
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "3");
}

test "realistic JavaScript-like expression" {
    var lexer = Lexer.init("(100 - 50) / (2 + 3) * 10");
    try expectToken(try lexer.nextToken(), TokenType.LeftParen, "(");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "100");
    try expectToken(try lexer.nextToken(), TokenType.Minus, "-");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "50");
    try expectToken(try lexer.nextToken(), TokenType.RightParen, ")");
    try expectToken(try lexer.nextToken(), TokenType.Slash, "/");
    try expectToken(try lexer.nextToken(), TokenType.LeftParen, "(");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "2");
    try expectToken(try lexer.nextToken(), TokenType.Plus, "+");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "3");
    try expectToken(try lexer.nextToken(), TokenType.RightParen, ")");
    try expectToken(try lexer.nextToken(), TokenType.Star, "*");
    try expectToken(try lexer.nextToken(), TokenType.NumericLiteral, "10");
    try expectTokenType(try lexer.nextToken(), TokenType.EOF);
}
