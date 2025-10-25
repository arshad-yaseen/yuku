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

fn expectTokenSpan(token: Token, expected_start: usize, expected_end: usize) !void {
    try std.testing.expectEqual(expected_start, token.span.start);
    try std.testing.expectEqual(expected_end, token.span.end);
}

test "arithmetic: plus operator" {
    var lexer = Lexer.init("+");
    const token = try lexer.nextToken();
    try expectToken(token, .Plus, "+");
    try expectTokenSpan(token, 0, 1);
}

test "arithmetic: minus operator" {
    var lexer = Lexer.init("-");
    const token = try lexer.nextToken();
    try expectToken(token, .Minus, "-");
}

test "arithmetic: star operator" {
    var lexer = Lexer.init("*");
    const token = try lexer.nextToken();
    try expectToken(token, .Star, "*");
}

test "arithmetic: slash operator" {
    var lexer = Lexer.init("/");
    const token = try lexer.nextToken();
    try expectToken(token, .Slash, "/");
}

test "arithmetic: percent operator" {
    var lexer = Lexer.init("%");
    const token = try lexer.nextToken();
    try expectToken(token, .Percent, "%");
}

test "arithmetic: exponent operator" {
    var lexer = Lexer.init("**");
    const token = try lexer.nextToken();
    try expectToken(token, .Exponent, "**");
}

test "arithmetic: multiple operators in sequence" {
    var lexer = Lexer.init("+ - * / %");
    try expectTokenType(try lexer.nextToken(), .Plus);
    try expectTokenType(try lexer.nextToken(), .Minus);
    try expectTokenType(try lexer.nextToken(), .Star);
    try expectTokenType(try lexer.nextToken(), .Slash);
    try expectTokenType(try lexer.nextToken(), .Percent);
    try expectTokenType(try lexer.nextToken(), .EOF);
}

test "assignment: simple assign" {
    var lexer = Lexer.init("=");
    try expectToken(try lexer.nextToken(), .Assign, "=");
}

test "assignment: plus assign" {
    var lexer = Lexer.init("+=");
    try expectToken(try lexer.nextToken(), .PlusAssign, "+=");
}

test "assignment: minus assign" {
    var lexer = Lexer.init("-=");
    try expectToken(try lexer.nextToken(), .MinusAssign, "-=");
}

test "assignment: star assign" {
    var lexer = Lexer.init("*=");
    try expectToken(try lexer.nextToken(), .StarAssign, "*=");
}

test "assignment: slash assign" {
    var lexer = Lexer.init("/=");
    try expectToken(try lexer.nextToken(), .SlashAssign, "/=");
}

test "assignment: percent assign" {
    var lexer = Lexer.init("%=");
    try expectToken(try lexer.nextToken(), .PercentAssign, "%=");
}

test "assignment: exponent assign" {
    var lexer = Lexer.init("**=");
    try expectToken(try lexer.nextToken(), .ExponentAssign, "**=");
}

test "assignment: all compound assignments" {
    var lexer = Lexer.init("+= -= *= /= %= **=");
    try expectTokenType(try lexer.nextToken(), .PlusAssign);
    try expectTokenType(try lexer.nextToken(), .MinusAssign);
    try expectTokenType(try lexer.nextToken(), .StarAssign);
    try expectTokenType(try lexer.nextToken(), .SlashAssign);
    try expectTokenType(try lexer.nextToken(), .PercentAssign);
    try expectTokenType(try lexer.nextToken(), .ExponentAssign);
}

test "increment/decrement: increment" {
    var lexer = Lexer.init("++");
    try expectToken(try lexer.nextToken(), .Increment, "++");
}

test "increment/decrement: decrement" {
    var lexer = Lexer.init("--");
    try expectToken(try lexer.nextToken(), .Decrement, "--");
}

test "increment/decrement: pre and post increment" {
    var lexer = Lexer.init("++x x++");
    try expectTokenType(try lexer.nextToken(), .Increment);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Increment);
}

test "increment/decrement: mixed with arithmetic" {
    var lexer = Lexer.init("++ + -- -");
    try expectTokenType(try lexer.nextToken(), .Increment);
    try expectTokenType(try lexer.nextToken(), .Plus);
    try expectTokenType(try lexer.nextToken(), .Decrement);
    try expectTokenType(try lexer.nextToken(), .Minus);
}

test "comparison: equal" {
    var lexer = Lexer.init("==");
    try expectToken(try lexer.nextToken(), .Equal, "==");
}

test "comparison: not equal" {
    var lexer = Lexer.init("!=");
    try expectToken(try lexer.nextToken(), .NotEqual, "!=");
}

test "comparison: strict equal" {
    var lexer = Lexer.init("===");
    try expectToken(try lexer.nextToken(), .StrictEqual, "===");
}

test "comparison: strict not equal" {
    var lexer = Lexer.init("!==");
    try expectToken(try lexer.nextToken(), .StrictNotEqual, "!==");
}

test "comparison: less than" {
    var lexer = Lexer.init("<");
    try expectToken(try lexer.nextToken(), .LessThan, "<");
}

test "comparison: greater than" {
    var lexer = Lexer.init(">");
    try expectToken(try lexer.nextToken(), .GreaterThan, ">");
}

test "comparison: less than equal" {
    var lexer = Lexer.init("<=");
    try expectToken(try lexer.nextToken(), .LessThanEqual, "<=");
}

test "comparison: greater than equal" {
    var lexer = Lexer.init(">=");
    try expectToken(try lexer.nextToken(), .GreaterThanEqual, ">=");
}

test "comparison: all operators" {
    var lexer = Lexer.init("== != === !== < > <= >=");
    try expectTokenType(try lexer.nextToken(), .Equal);
    try expectTokenType(try lexer.nextToken(), .NotEqual);
    try expectTokenType(try lexer.nextToken(), .StrictEqual);
    try expectTokenType(try lexer.nextToken(), .StrictNotEqual);
    try expectTokenType(try lexer.nextToken(), .LessThan);
    try expectTokenType(try lexer.nextToken(), .GreaterThan);
    try expectTokenType(try lexer.nextToken(), .LessThanEqual);
    try expectTokenType(try lexer.nextToken(), .GreaterThanEqual);
}

test "comparison: edge case - single equals vs double" {
    var lexer = Lexer.init("= ==");
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .Equal);
}

test "comparison: edge case - exclamation vs not equal" {
    var lexer = Lexer.init("! !=");
    try expectTokenType(try lexer.nextToken(), .LogicalNot);
    try expectTokenType(try lexer.nextToken(), .NotEqual);
}

test "logical: and operator" {
    var lexer = Lexer.init("&&");
    try expectToken(try lexer.nextToken(), .LogicalAnd, "&&");
}

test "logical: or operator" {
    var lexer = Lexer.init("||");
    try expectToken(try lexer.nextToken(), .LogicalOr, "||");
}

test "logical: not operator" {
    var lexer = Lexer.init("!");
    try expectToken(try lexer.nextToken(), .LogicalNot, "!");
}

test "logical: all logical operators" {
    var lexer = Lexer.init("&& || !");
    try expectTokenType(try lexer.nextToken(), .LogicalAnd);
    try expectTokenType(try lexer.nextToken(), .LogicalOr);
    try expectTokenType(try lexer.nextToken(), .LogicalNot);
}

test "logical: logical and assign" {
    var lexer = Lexer.init("&&=");
    try expectToken(try lexer.nextToken(), .LogicalAndAssign, "&&=");
}

test "logical: logical or assign" {
    var lexer = Lexer.init("||=");
    try expectToken(try lexer.nextToken(), .LogicalOrAssign, "||=");
}

test "bitwise: and operator" {
    var lexer = Lexer.init("&");
    try expectToken(try lexer.nextToken(), .BitwiseAnd, "&");
}

test "bitwise: or operator" {
    var lexer = Lexer.init("|");
    try expectToken(try lexer.nextToken(), .BitwiseOr, "|");
}

test "bitwise: xor operator" {
    var lexer = Lexer.init("^");
    try expectToken(try lexer.nextToken(), .BitwiseXor, "^");
}

test "bitwise: not operator" {
    var lexer = Lexer.init("~");
    try expectToken(try lexer.nextToken(), .BitwiseNot, "~");
}

test "bitwise: left shift" {
    var lexer = Lexer.init("<<");
    try expectToken(try lexer.nextToken(), .LeftShift, "<<");
}

test "bitwise: right shift" {
    var lexer = Lexer.init(">>");
    try expectToken(try lexer.nextToken(), .RightShift, ">>");
}

test "bitwise: unsigned right shift" {
    var lexer = Lexer.init(">>>");
    try expectToken(try lexer.nextToken(), .UnsignedRightShift, ">>>");
}

test "bitwise: and assign" {
    var lexer = Lexer.init("&=");
    try expectToken(try lexer.nextToken(), .BitwiseAndAssign, "&=");
}

test "bitwise: or assign" {
    var lexer = Lexer.init("|=");
    try expectToken(try lexer.nextToken(), .BitwiseOrAssign, "|=");
}

test "bitwise: xor assign" {
    var lexer = Lexer.init("^=");
    try expectToken(try lexer.nextToken(), .BitwiseXorAssign, "^=");
}

test "bitwise: left shift assign" {
    var lexer = Lexer.init("<<=");
    try expectToken(try lexer.nextToken(), .LeftShiftAssign, "<<=");
}

test "bitwise: right shift assign" {
    var lexer = Lexer.init(">>=");
    try expectToken(try lexer.nextToken(), .RightShiftAssign, ">>=");
}

test "bitwise: unsigned right shift assign" {
    var lexer = Lexer.init(">>>=");
    try expectToken(try lexer.nextToken(), .UnsignedRightShiftAssign, ">>>=");
}

test "bitwise: all bitwise operators" {
    var lexer = Lexer.init("& | ^ ~ << >> >>>");
    try expectTokenType(try lexer.nextToken(), .BitwiseAnd);
    try expectTokenType(try lexer.nextToken(), .BitwiseOr);
    try expectTokenType(try lexer.nextToken(), .BitwiseXor);
    try expectTokenType(try lexer.nextToken(), .BitwiseNot);
    try expectTokenType(try lexer.nextToken(), .LeftShift);
    try expectTokenType(try lexer.nextToken(), .RightShift);
    try expectTokenType(try lexer.nextToken(), .UnsignedRightShift);
}

test "bitwise: edge case - single vs double ampersand" {
    var lexer = Lexer.init("& &&");
    try expectTokenType(try lexer.nextToken(), .BitwiseAnd);
    try expectTokenType(try lexer.nextToken(), .LogicalAnd);
}

test "bitwise: edge case - single vs double pipe" {
    var lexer = Lexer.init("| ||");
    try expectTokenType(try lexer.nextToken(), .BitwiseOr);
    try expectTokenType(try lexer.nextToken(), .LogicalOr);
}

test "bitwise: edge case - shift operators progression" {
    var lexer = Lexer.init("< << <<= > >> >>= >>> >>>=");
    try expectTokenType(try lexer.nextToken(), .LessThan);
    try expectTokenType(try lexer.nextToken(), .LeftShift);
    try expectTokenType(try lexer.nextToken(), .LeftShiftAssign);
    try expectTokenType(try lexer.nextToken(), .GreaterThan);
    try expectTokenType(try lexer.nextToken(), .RightShift);
    try expectTokenType(try lexer.nextToken(), .RightShiftAssign);
    try expectTokenType(try lexer.nextToken(), .UnsignedRightShift);
    try expectTokenType(try lexer.nextToken(), .UnsignedRightShiftAssign);
}

test "modern: nullish coalescing" {
    var lexer = Lexer.init("??");
    try expectToken(try lexer.nextToken(), .NullishCoalescing, "??");
}

test "modern: nullish assign" {
    var lexer = Lexer.init("??=");
    try expectToken(try lexer.nextToken(), .NullishAssign, "??=");
}

test "modern: optional chaining" {
    var lexer = Lexer.init("?.");
    try expectToken(try lexer.nextToken(), .OptionalChaining, "?.");
}

test "modern: question mark vs nullish" {
    var lexer = Lexer.init("? ??");
    try expectTokenType(try lexer.nextToken(), .Question);
    try expectTokenType(try lexer.nextToken(), .NullishCoalescing);
}

test "modern: optional chaining in expression" {
    var lexer = Lexer.init("obj?.prop");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .OptionalChaining);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "modern: all modern operators" {
    var lexer = Lexer.init("?? ??= ?. &&= ||=");
    try expectTokenType(try lexer.nextToken(), .NullishCoalescing);
    try expectTokenType(try lexer.nextToken(), .NullishAssign);
    try expectTokenType(try lexer.nextToken(), .OptionalChaining);
    try expectTokenType(try lexer.nextToken(), .LogicalAndAssign);
    try expectTokenType(try lexer.nextToken(), .LogicalOrAssign);
}

test "delimiters: parentheses" {
    var lexer = Lexer.init("()");
    try expectToken(try lexer.nextToken(), .LeftParen, "(");
    try expectToken(try lexer.nextToken(), .RightParen, ")");
}

test "delimiters: braces" {
    var lexer = Lexer.init("{}");
    try expectToken(try lexer.nextToken(), .LeftBrace, "{");
    try expectToken(try lexer.nextToken(), .RightBrace, "}");
}

test "delimiters: brackets" {
    var lexer = Lexer.init("[]");
    try expectToken(try lexer.nextToken(), .LeftBracket, "[");
    try expectToken(try lexer.nextToken(), .RightBracket, "]");
}

test "delimiters: semicolon" {
    var lexer = Lexer.init(";");
    try expectToken(try lexer.nextToken(), .Semicolon, ";");
}

test "delimiters: comma" {
    var lexer = Lexer.init(",");
    try expectToken(try lexer.nextToken(), .Comma, ",");
}

test "delimiters: colon" {
    var lexer = Lexer.init(":");
    try expectToken(try lexer.nextToken(), .Colon, ":");
}

test "delimiters: dot" {
    var lexer = Lexer.init(".");
    try expectToken(try lexer.nextToken(), .Dot, ".");
}

test "delimiters: spread operator" {
    var lexer = Lexer.init("...");
    try expectToken(try lexer.nextToken(), .Spread, "...");
}

test "delimiters: arrow function" {
    var lexer = Lexer.init("=>");
    try expectToken(try lexer.nextToken(), .Arrow, "=>");
}

test "delimiters: question mark" {
    var lexer = Lexer.init("?");
    try expectToken(try lexer.nextToken(), .Question, "?");
}

test "delimiters: all delimiters" {
    var lexer = Lexer.init("( ) { } [ ] ; , : . ... =>");
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .LeftBracket);
    try expectTokenType(try lexer.nextToken(), .RightBracket);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .Comma);
    try expectTokenType(try lexer.nextToken(), .Colon);
    try expectTokenType(try lexer.nextToken(), .Dot);
    try expectTokenType(try lexer.nextToken(), .Spread);
    try expectTokenType(try lexer.nextToken(), .Arrow);
}

test "delimiters: edge case - dot vs spread" {
    var lexer = Lexer.init(". .. ...");
    try expectTokenType(try lexer.nextToken(), .Dot);
    try expectTokenType(try lexer.nextToken(), .Dot);
    try expectTokenType(try lexer.nextToken(), .Dot);
    try expectTokenType(try lexer.nextToken(), .Spread);
}

test "delimiters: edge case - nested delimiters" {
    var lexer = Lexer.init("({[()]})");
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .LeftBracket);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .RightBracket);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .RightParen);
}

test "number: simple integer" {
    var lexer = Lexer.init("123");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "123");
}

test "number: zero" {
    var lexer = Lexer.init("0");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "0");
}

test "number: decimal number" {
    var lexer = Lexer.init("3.14");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "3.14");
}

test "number: decimal with leading zero" {
    var lexer = Lexer.init("0.5");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "0.5");
}

test "number: decimal with trailing digits" {
    var lexer = Lexer.init("123.456");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "123.456");
}

test "number: scientific notation lowercase e" {
    var lexer = Lexer.init("1e5");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "1e5");
}

test "number: scientific notation uppercase E" {
    var lexer = Lexer.init("1E5");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "1E5");
}

test "number: scientific notation with plus sign" {
    var lexer = Lexer.init("1e+5");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "1e+5");
}

test "number: scientific notation with minus sign" {
    var lexer = Lexer.init("1e-5");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "1e-5");
}

test "number: decimal with scientific notation" {
    var lexer = Lexer.init("3.14e2");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "3.14e2");
}

test "number: large scientific notation" {
    var lexer = Lexer.init("1.23e+100");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "1.23e+100");
}

test "number: hex literal lowercase x" {
    var lexer = Lexer.init("0xFF");
    try expectToken(try lexer.nextToken(), .HexLiteral, "0xFF");
}

test "number: hex literal uppercase X" {
    var lexer = Lexer.init("0XFF");
    try expectToken(try lexer.nextToken(), .HexLiteral, "0XFF");
}

test "number: hex literal with lowercase letters" {
    var lexer = Lexer.init("0xabcdef");
    try expectToken(try lexer.nextToken(), .HexLiteral, "0xabcdef");
}

test "number: hex literal with uppercase letters" {
    var lexer = Lexer.init("0xABCDEF");
    try expectToken(try lexer.nextToken(), .HexLiteral, "0xABCDEF");
}

test "number: hex literal mixed case" {
    var lexer = Lexer.init("0xAbCdEf");
    try expectToken(try lexer.nextToken(), .HexLiteral, "0xAbCdEf");
}

test "number: octal literal lowercase o" {
    var lexer = Lexer.init("0o777");
    try expectToken(try lexer.nextToken(), .OctalLiteral, "0o777");
}

test "number: octal literal uppercase O" {
    var lexer = Lexer.init("0O777");
    try expectToken(try lexer.nextToken(), .OctalLiteral, "0O777");
}

test "number: octal literal all valid digits" {
    var lexer = Lexer.init("0o01234567");
    try expectToken(try lexer.nextToken(), .OctalLiteral, "0o01234567");
}

test "number: binary literal lowercase b" {
    var lexer = Lexer.init("0b1010");
    try expectToken(try lexer.nextToken(), .BinaryLiteral, "0b1010");
}

test "number: binary literal uppercase B" {
    var lexer = Lexer.init("0B1010");
    try expectToken(try lexer.nextToken(), .BinaryLiteral, "0B1010");
}

test "number: binary literal ones and zeros" {
    var lexer = Lexer.init("0b11110000");
    try expectToken(try lexer.nextToken(), .BinaryLiteral, "0b11110000");
}

test "number: bigint literal" {
    var lexer = Lexer.init("123n");
    try expectToken(try lexer.nextToken(), .BigIntLiteral, "123n");
}

test "number: bigint with hex" {
    var lexer = Lexer.init("0xFFn");
    try expectToken(try lexer.nextToken(), .BigIntLiteral, "0xFFn");
}

test "number: bigint with octal" {
    var lexer = Lexer.init("0o777n");
    try expectToken(try lexer.nextToken(), .BigIntLiteral, "0o777n");
}

test "number: bigint with binary" {
    var lexer = Lexer.init("0b1010n");
    try expectToken(try lexer.nextToken(), .BigIntLiteral, "0b1010n");
}

test "number: edge case - dot must be followed by digit for decimal" {
    var lexer = Lexer.init("1.");
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .Dot);
}

test "number: edge case - leading decimal point" {
    var lexer = Lexer.init(".5");
    try expectToken(try lexer.nextToken(), .NumericLiteral, ".5");
}

test "number: edge case - multiple numbers" {
    var lexer = Lexer.init("1 2 3");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "1");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "2");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "3");
}

test "number: edge case - number followed by identifier" {
    var lexer = Lexer.init("123abc");
    const token = try lexer.nextToken();
    try expectToken(token, .NumericLiteral, "123");
    const token2 = try lexer.nextToken();
    try expectToken(token2, .Identifier, "abc");
}

test "number: numeric separator with underscore" {
    var lexer = Lexer.init("1_000_000");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "1_000_000");
}

test "number: numeric separator in decimal" {
    var lexer = Lexer.init("3.14_159");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "3.14_159");
}

test "number: edge case - zero followed by valid digits" {
    var lexer = Lexer.init("0123");
    try expectToken(try lexer.nextToken(), .NumericLiteral, "0123");
}

test "string: double quote empty" {
    var lexer = Lexer.init("\"\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"\"");
}

test "string: single quote empty" {
    var lexer = Lexer.init("''");
    try expectToken(try lexer.nextToken(), .StringLiteral, "''");
}

test "string: double quote simple" {
    var lexer = Lexer.init("\"hello\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"hello\"");
}

test "string: single quote simple" {
    var lexer = Lexer.init("'hello'");
    try expectToken(try lexer.nextToken(), .StringLiteral, "'hello'");
}

test "string: with spaces" {
    var lexer = Lexer.init("\"hello world\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"hello world\"");
}

test "string: with special characters" {
    var lexer = Lexer.init("\"hello!@#$%^&*()\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"hello!@#$%^&*()\"");
}

test "string: escaped quote double" {
    var lexer = Lexer.init("\"hello\\\"world\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"hello\\\"world\"");
}

test "string: escaped quote single" {
    var lexer = Lexer.init("'hello\\'world'");
    try expectToken(try lexer.nextToken(), .StringLiteral, "'hello\\'world'");
}

test "string: escaped backslash" {
    var lexer = Lexer.init("\"hello\\\\world\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"hello\\\\world\"");
}

test "string: escaped n (newline)" {
    var lexer = Lexer.init("\"hello\\nworld\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"hello\\nworld\"");
}

test "string: escaped t (tab)" {
    var lexer = Lexer.init("\"hello\\tworld\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"hello\\tworld\"");
}

test "string: escaped r (carriage return)" {
    var lexer = Lexer.init("\"hello\\rworld\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"hello\\rworld\"");
}

test "string: multiple escape sequences" {
    var lexer = Lexer.init("\"\\n\\t\\r\\\\\\\"\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"\\n\\t\\r\\\\\\\"\"");
}

test "string: unicode escape" {
    var lexer = Lexer.init("\"\\u0041\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"\\u0041\"");
}

test "string: hex escape" {
    var lexer = Lexer.init("\"\\x41\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"\\x41\"");
}

test "string: single quote inside double quotes" {
    var lexer = Lexer.init("\"it's\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"it's\"");
}

test "string: double quote inside single quotes" {
    var lexer = Lexer.init("'say \"hi\"'");
    try expectToken(try lexer.nextToken(), .StringLiteral, "'say \"hi\"'");
}

test "string: multiple strings" {
    var lexer = Lexer.init("\"hello\" \"world\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"hello\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"world\"");
}

test "string: edge case - unclosed double quote" {
    var lexer = Lexer.init("\"hello");
    try expectTokenType(try lexer.nextToken(), .Invalid);
}

test "string: edge case - unclosed single quote" {
    var lexer = Lexer.init("'hello");
    try expectTokenType(try lexer.nextToken(), .Invalid);
}

test "string: edge case - newline breaks string" {
    var lexer = Lexer.init("\"hello\nworld\"");
    try expectTokenType(try lexer.nextToken(), .Invalid);
}

test "string: escaped line continuation with newline" {
    var lexer = Lexer.init("\"hello\\\nworld\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"hello\\\nworld\"");
}

test "string: escaped line continuation with carriage return" {
    var lexer = Lexer.init("\"hello\\\rworld\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"hello\\\rworld\"");
}

test "string: empty after escaped character at end" {
    var lexer = Lexer.init("\"hello\\");
    try expectTokenType(try lexer.nextToken(), .Invalid);
}

test "string: numbers inside string" {
    var lexer = Lexer.init("\"12345\"");
    try expectToken(try lexer.nextToken(), .StringLiteral, "\"12345\"");
}

test "template: simple no substitution" {
    var lexer = Lexer.init("`hello`");
    try expectToken(try lexer.nextToken(), .NoSubstitutionTemplate, "`hello`");
}

test "template: empty" {
    var lexer = Lexer.init("``");
    try expectToken(try lexer.nextToken(), .NoSubstitutionTemplate, "``");
}

test "template: with spaces" {
    var lexer = Lexer.init("`hello world`");
    try expectToken(try lexer.nextToken(), .NoSubstitutionTemplate, "`hello world`");
}

test "template: with newline" {
    var lexer = Lexer.init("`hello\nworld`");
    try expectToken(try lexer.nextToken(), .NoSubstitutionTemplate, "`hello\nworld`");
}

test "template: with special characters" {
    var lexer = Lexer.init("`!@#$%^&*()`");
    try expectToken(try lexer.nextToken(), .NoSubstitutionTemplate, "`!@#$%^&*()`");
}

test "template: head with substitution" {
    var lexer = Lexer.init("`hello ${");
    try expectToken(try lexer.nextToken(), .TemplateHead, "`hello ${");
}

test "template: simple substitution" {
    var lexer = Lexer.init("`hello ${name}`");
    try expectTokenType(try lexer.nextToken(), .TemplateHead);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .TemplateTail);
}

test "template: multiple substitutions" {
    var lexer = Lexer.init("`${a} and ${b}`");
    try expectTokenType(try lexer.nextToken(), .TemplateHead);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .TemplateMiddle);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .TemplateTail);
}

test "template: nested template" {
    var lexer = Lexer.init("`outer ${`inner`}`");
    try expectTokenType(try lexer.nextToken(), .TemplateHead);
    try expectTokenType(try lexer.nextToken(), .NoSubstitutionTemplate);
    try expectTokenType(try lexer.nextToken(), .TemplateTail);
}

test "template: with expression" {
    var lexer = Lexer.init("`result: ${1 + 2}`");
    try expectTokenType(try lexer.nextToken(), .TemplateHead);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .Plus);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .TemplateTail);
}

test "template: escaped backtick" {
    var lexer = Lexer.init("`hello \\` world`");
    try expectToken(try lexer.nextToken(), .NoSubstitutionTemplate, "`hello \\` world`");
}

test "template: escaped dollar brace" {
    var lexer = Lexer.init("`hello \\${name}`");
    try expectToken(try lexer.nextToken(), .NoSubstitutionTemplate, "`hello \\${name}`");
}

test "template: edge case - unclosed template" {
    var lexer = Lexer.init("`hello");
    try expectTokenType(try lexer.nextToken(), .Invalid);
}

test "template: edge case - unclosed substitution" {
    var lexer = Lexer.init("`hello ${name");
    try expectTokenType(try lexer.nextToken(), .TemplateHead);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "template: empty substitution" {
    var lexer = Lexer.init("`hello ${}`");
    try expectTokenType(try lexer.nextToken(), .TemplateHead);
    try expectTokenType(try lexer.nextToken(), .TemplateTail);
}

test "template: whitespace in substitution" {
    var lexer = Lexer.init("`${  x  }`");
    try expectTokenType(try lexer.nextToken(), .TemplateHead);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .TemplateTail);
}

test "template: complex nested expression" {
    var lexer = Lexer.init("`a ${b ? `c ${d}` : e} f`");
    try expectTokenType(try lexer.nextToken(), .TemplateHead);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Question);
    try expectTokenType(try lexer.nextToken(), .TemplateHead);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .TemplateTail);
    try expectTokenType(try lexer.nextToken(), .Colon);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .TemplateTail);
}

test "regex: simple pattern" {
    var lexer = Lexer.init("/test/");
    try expectToken(try lexer.nextToken(), .RegexLiteral, "/test/");
}

test "regex: with flags" {
    var lexer = Lexer.init("/test/gi");
    try expectToken(try lexer.nextToken(), .RegexLiteral, "/test/gi");
}

test "regex: all common flags" {
    var lexer = Lexer.init("/test/gimsuvy");
    try expectToken(try lexer.nextToken(), .RegexLiteral, "/test/gimsuvy");
}

test "regex: with character class" {
    var lexer = Lexer.init("/[a-z]/");
    try expectToken(try lexer.nextToken(), .RegexLiteral, "/[a-z]/");
}

test "regex: with escaped slash" {
    var lexer = Lexer.init("/\\/path\\/to/");
    try expectToken(try lexer.nextToken(), .RegexLiteral, "/\\/path\\/to/");
}

test "regex: with escaped bracket" {
    var lexer = Lexer.init("/\\[\\]/");
    try expectToken(try lexer.nextToken(), .RegexLiteral, "/\\[\\]/");
}

test "regex: complex pattern" {
    var lexer = Lexer.init("/^[a-zA-Z0-9]+$/");
    try expectToken(try lexer.nextToken(), .RegexLiteral, "/^[a-zA-Z0-9]+$/");
}

test "regex: with quantifiers" {
    var lexer = Lexer.init("/a+b*c?d{2,5}/");
    try expectToken(try lexer.nextToken(), .RegexLiteral, "/a+b*c?d{2,5}/");
}

test "regex: with groups" {
    var lexer = Lexer.init("/(hello)(world)/");
    try expectToken(try lexer.nextToken(), .RegexLiteral, "/(hello)(world)/");
}

test "regex: with lookahead" {
    var lexer = Lexer.init("/(?=test)/");
    try expectToken(try lexer.nextToken(), .RegexLiteral, "/(?=test)/");
}

test "regex: with character class containing slash" {
    var lexer = Lexer.init("/[a\\/b]/");
    try expectToken(try lexer.nextToken(), .RegexLiteral, "/[a\\/b]/");
}

test "regex: empty pattern" {
    var lexer = Lexer.init("//");
    try expectToken(try lexer.nextToken(), .RegexLiteral, "//");
}

test "regex: vs division operator context" {
    var lexer = Lexer.init("x / y");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Slash);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "regex: edge case - unclosed" {
    var lexer = Lexer.init("/test");
    try expectTokenType(try lexer.nextToken(), .Slash);
}

test "regex: with unicode" {
    var lexer = Lexer.init("/\\u0041/");
    try expectToken(try lexer.nextToken(), .RegexLiteral, "/\\u0041/");
}

test "regex: multiline with newline characters" {
    var lexer = Lexer.init("/test\\npattern/");
    try expectToken(try lexer.nextToken(), .RegexLiteral, "/test\\npattern/");
}

test "identifier: simple lowercase" {
    var lexer = Lexer.init("hello");
    try expectToken(try lexer.nextToken(), .Identifier, "hello");
}

test "identifier: simple uppercase" {
    var lexer = Lexer.init("HELLO");
    try expectToken(try lexer.nextToken(), .Identifier, "HELLO");
}

test "identifier: mixed case" {
    var lexer = Lexer.init("HelloWorld");
    try expectToken(try lexer.nextToken(), .Identifier, "HelloWorld");
}

test "identifier: camelCase" {
    var lexer = Lexer.init("camelCase");
    try expectToken(try lexer.nextToken(), .Identifier, "camelCase");
}

test "identifier: with underscore" {
    var lexer = Lexer.init("_private");
    try expectToken(try lexer.nextToken(), .Identifier, "_private");
}

test "identifier: with dollar sign" {
    var lexer = Lexer.init("$jQuery");
    try expectToken(try lexer.nextToken(), .Identifier, "$jQuery");
}

test "identifier: only underscore" {
    var lexer = Lexer.init("_");
    try expectToken(try lexer.nextToken(), .Identifier, "_");
}

test "identifier: only dollar" {
    var lexer = Lexer.init("$");
    try expectToken(try lexer.nextToken(), .Identifier, "$");
}

test "identifier: multiple underscores" {
    var lexer = Lexer.init("__proto__");
    try expectToken(try lexer.nextToken(), .Identifier, "__proto__");
}

test "identifier: multiple dollar signs" {
    var lexer = Lexer.init("$$");
    try expectToken(try lexer.nextToken(), .Identifier, "$$");
}

test "identifier: with numbers" {
    var lexer = Lexer.init("var123");
    try expectToken(try lexer.nextToken(), .Identifier, "var123");
}

test "identifier: ending with number" {
    var lexer = Lexer.init("value1");
    try expectToken(try lexer.nextToken(), .Identifier, "value1");
}

test "identifier: mixed with underscore and dollar" {
    var lexer = Lexer.init("_$test$_");
    try expectToken(try lexer.nextToken(), .Identifier, "_$test$_");
}

test "identifier: all alphanumeric mix" {
    var lexer = Lexer.init("test_123_$abc");
    try expectToken(try lexer.nextToken(), .Identifier, "test_123_$abc");
}

test "identifier: edge case - cannot start with number" {
    var lexer = Lexer.init("123abc");
    const token = try lexer.nextToken();
    try expectTokenType(token, .NumericLiteral);
}

test "private identifier: simple" {
    var lexer = Lexer.init("#private");
    try expectToken(try lexer.nextToken(), .PrivateIdentifier, "#private");
}

test "private identifier: with underscore" {
    var lexer = Lexer.init("#_private");
    try expectToken(try lexer.nextToken(), .PrivateIdentifier, "#_private");
}

test "private identifier: with dollar" {
    var lexer = Lexer.init("#$private");
    try expectToken(try lexer.nextToken(), .PrivateIdentifier, "#$private");
}

test "private identifier: with numbers" {
    var lexer = Lexer.init("#private123");
    try expectToken(try lexer.nextToken(), .PrivateIdentifier, "#private123");
}

test "private identifier: only hash and letter" {
    var lexer = Lexer.init("#a");
    try expectToken(try lexer.nextToken(), .PrivateIdentifier, "#a");
}

test "private identifier: edge case - hash alone" {
    var lexer = Lexer.init("#");
    try expectTokenType(try lexer.nextToken(), .Invalid);
}

test "private identifier: edge case - hash with number" {
    var lexer = Lexer.init("#123");
    try expectTokenType(try lexer.nextToken(), .Invalid);
}

test "private identifier: edge case - hash with special char" {
    var lexer = Lexer.init("#@test");
    try expectTokenType(try lexer.nextToken(), .Invalid);
}

test "private identifier: multiple in class" {
    var lexer = Lexer.init("#field1 #field2");
    try expectToken(try lexer.nextToken(), .PrivateIdentifier, "#field1");
    try expectToken(try lexer.nextToken(), .PrivateIdentifier, "#field2");
}

test "keyword: if" {
    var lexer = Lexer.init("if");
    try expectToken(try lexer.nextToken(), .If, "if");
}

test "keyword: else" {
    var lexer = Lexer.init("else");
    try expectToken(try lexer.nextToken(), .Else, "else");
}

test "keyword: for" {
    var lexer = Lexer.init("for");
    try expectToken(try lexer.nextToken(), .For, "for");
}

test "keyword: while" {
    var lexer = Lexer.init("while");
    try expectToken(try lexer.nextToken(), .While, "while");
}

test "keyword: do" {
    var lexer = Lexer.init("do");
    try expectToken(try lexer.nextToken(), .Do, "do");
}

test "keyword: break" {
    var lexer = Lexer.init("break");
    try expectToken(try lexer.nextToken(), .Break, "break");
}

test "keyword: continue" {
    var lexer = Lexer.init("continue");
    try expectToken(try lexer.nextToken(), .Continue, "continue");
}

test "keyword: return" {
    var lexer = Lexer.init("return");
    try expectToken(try lexer.nextToken(), .Return, "return");
}

test "keyword: function" {
    var lexer = Lexer.init("function");
    try expectToken(try lexer.nextToken(), .Function, "function");
}

test "keyword: const" {
    var lexer = Lexer.init("const");
    try expectToken(try lexer.nextToken(), .Const, "const");
}

test "keyword: let" {
    var lexer = Lexer.init("let");
    try expectToken(try lexer.nextToken(), .Let, "let");
}

test "keyword: var" {
    var lexer = Lexer.init("var");
    try expectToken(try lexer.nextToken(), .Var, "var");
}

test "keyword: class" {
    var lexer = Lexer.init("class");
    try expectToken(try lexer.nextToken(), .Class, "class");
}

test "keyword: extends" {
    var lexer = Lexer.init("extends");
    try expectToken(try lexer.nextToken(), .Extends, "extends");
}

test "keyword: super" {
    var lexer = Lexer.init("super");
    try expectToken(try lexer.nextToken(), .Super, "super");
}

test "keyword: static" {
    var lexer = Lexer.init("static");
    try expectToken(try lexer.nextToken(), .Static, "static");
}

test "keyword: this" {
    var lexer = Lexer.init("this");
    try expectToken(try lexer.nextToken(), .This, "this");
}

test "keyword: new" {
    var lexer = Lexer.init("new");
    try expectToken(try lexer.nextToken(), .New, "new");
}

test "keyword: import" {
    var lexer = Lexer.init("import");
    try expectToken(try lexer.nextToken(), .Import, "import");
}

test "keyword: export" {
    var lexer = Lexer.init("export");
    try expectToken(try lexer.nextToken(), .Export, "export");
}

test "keyword: from" {
    var lexer = Lexer.init("from");
    try expectToken(try lexer.nextToken(), .From, "from");
}

test "keyword: as" {
    var lexer = Lexer.init("as");
    try expectToken(try lexer.nextToken(), .As, "as");
}

test "keyword: try" {
    var lexer = Lexer.init("try");
    try expectToken(try lexer.nextToken(), .Try, "try");
}

test "keyword: catch" {
    var lexer = Lexer.init("catch");
    try expectToken(try lexer.nextToken(), .Catch, "catch");
}

test "keyword: finally" {
    var lexer = Lexer.init("finally");
    try expectToken(try lexer.nextToken(), .Finally, "finally");
}

test "keyword: throw" {
    var lexer = Lexer.init("throw");
    try expectToken(try lexer.nextToken(), .Throw, "throw");
}

test "keyword: switch" {
    var lexer = Lexer.init("switch");
    try expectToken(try lexer.nextToken(), .Switch, "switch");
}

test "keyword: case" {
    var lexer = Lexer.init("case");
    try expectToken(try lexer.nextToken(), .Case, "case");
}

test "keyword: default" {
    var lexer = Lexer.init("default");
    try expectToken(try lexer.nextToken(), .Default, "default");
}

test "keyword: async" {
    var lexer = Lexer.init("async");
    try expectToken(try lexer.nextToken(), .Async, "async");
}

test "keyword: await" {
    var lexer = Lexer.init("await");
    try expectToken(try lexer.nextToken(), .Await, "await");
}

test "keyword: yield" {
    var lexer = Lexer.init("yield");
    try expectToken(try lexer.nextToken(), .Yield, "yield");
}

test "keyword: typeof" {
    var lexer = Lexer.init("typeof");
    try expectToken(try lexer.nextToken(), .Typeof, "typeof");
}

test "keyword: instanceof" {
    var lexer = Lexer.init("instanceof");
    try expectToken(try lexer.nextToken(), .Instanceof, "instanceof");
}

test "keyword: in" {
    var lexer = Lexer.init("in");
    try expectToken(try lexer.nextToken(), .In, "in");
}

test "keyword: of" {
    var lexer = Lexer.init("of");
    try expectToken(try lexer.nextToken(), .Of, "of");
}

test "keyword: delete" {
    var lexer = Lexer.init("delete");
    try expectToken(try lexer.nextToken(), .Delete, "delete");
}

test "keyword: void" {
    var lexer = Lexer.init("void");
    try expectToken(try lexer.nextToken(), .Void, "void");
}

test "keyword: with" {
    var lexer = Lexer.init("with");
    try expectToken(try lexer.nextToken(), .With, "with");
}

test "keyword: debugger" {
    var lexer = Lexer.init("debugger");
    try expectToken(try lexer.nextToken(), .Debugger, "debugger");
}

test "keyword: enum" {
    var lexer = Lexer.init("enum");
    try expectToken(try lexer.nextToken(), .Enum, "enum");
}

test "keyword: interface" {
    var lexer = Lexer.init("interface");
    try expectToken(try lexer.nextToken(), .Interface, "interface");
}

test "keyword: implements" {
    var lexer = Lexer.init("implements");
    try expectToken(try lexer.nextToken(), .Implements, "implements");
}

test "keyword: public" {
    var lexer = Lexer.init("public");
    try expectToken(try lexer.nextToken(), .Public, "public");
}

test "keyword: private" {
    var lexer = Lexer.init("private");
    try expectToken(try lexer.nextToken(), .Private, "private");
}

test "keyword: protected" {
    var lexer = Lexer.init("protected");
    try expectToken(try lexer.nextToken(), .Protected, "protected");
}

test "keyword: true" {
    var lexer = Lexer.init("true");
    try expectToken(try lexer.nextToken(), .True, "true");
}

test "keyword: false" {
    var lexer = Lexer.init("false");
    try expectToken(try lexer.nextToken(), .False, "false");
}

test "keyword: null" {
    var lexer = Lexer.init("null");
    try expectToken(try lexer.nextToken(), .NullLiteral, "null");
}

test "keyword: edge case - keyword as part of identifier" {
    var lexer = Lexer.init("ifx");
    try expectToken(try lexer.nextToken(), .Identifier, "ifx");
}

test "keyword: edge case - identifier similar to keyword" {
    var lexer = Lexer.init("_if if_");
    try expectToken(try lexer.nextToken(), .Identifier, "_if");
    try expectToken(try lexer.nextToken(), .Identifier, "if_");
}

test "whitespace: spaces" {
    var lexer = Lexer.init("   x");
    try expectToken(try lexer.nextToken(), .Identifier, "x");
}

test "whitespace: tabs" {
    var lexer = Lexer.init("\t\tx");
    try expectToken(try lexer.nextToken(), .Identifier, "x");
}

test "whitespace: newlines" {
    var lexer = Lexer.init("\n\nx");
    try expectToken(try lexer.nextToken(), .Identifier, "x");
}

test "whitespace: carriage return" {
    var lexer = Lexer.init("\r\rx");
    try expectToken(try lexer.nextToken(), .Identifier, "x");
}

test "whitespace: mixed whitespace" {
    var lexer = Lexer.init(" \t\n\r x");
    try expectToken(try lexer.nextToken(), .Identifier, "x");
}

test "whitespace: between tokens" {
    var lexer = Lexer.init("x   +   y");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Plus);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "whitespace: no whitespace between tokens" {
    var lexer = Lexer.init("x+y");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Plus);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "eof: empty input" {
    var lexer = Lexer.init("");
    try expectTokenType(try lexer.nextToken(), .EOF);
}

test "eof: after single token" {
    var lexer = Lexer.init("x");
    _ = try lexer.nextToken();
    try expectTokenType(try lexer.nextToken(), .EOF);
}

test "eof: multiple eof calls" {
    var lexer = Lexer.init("");
    try expectTokenType(try lexer.nextToken(), .EOF);
    try expectTokenType(try lexer.nextToken(), .EOF);
    try expectTokenType(try lexer.nextToken(), .EOF);
}

test "eof: after whitespace only" {
    var lexer = Lexer.init("   ");
    try expectTokenType(try lexer.nextToken(), .EOF);
}

test "expression: simple addition" {
    var lexer = Lexer.init("1 + 2");
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .Plus);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
}

test "expression: variable assignment" {
    var lexer = Lexer.init("x = 5");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
}

test "expression: function call" {
    var lexer = Lexer.init("func()");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .RightParen);
}

test "expression: function call with args" {
    var lexer = Lexer.init("func(a, b)");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Comma);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightParen);
}

test "expression: array literal" {
    var lexer = Lexer.init("[1, 2, 3]");
    try expectTokenType(try lexer.nextToken(), .LeftBracket);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .Comma);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .Comma);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .RightBracket);
}

test "expression: object literal" {
    var lexer = Lexer.init("{a: 1}");
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Colon);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "expression: property access" {
    var lexer = Lexer.init("obj.prop");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Dot);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "expression: array access" {
    var lexer = Lexer.init("arr[0]");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftBracket);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .RightBracket);
}

test "expression: ternary operator" {
    var lexer = Lexer.init("x ? y : z");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Question);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Colon);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "expression: arrow function" {
    var lexer = Lexer.init("x => x + 1");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Arrow);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Plus);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
}

test "expression: spread in array" {
    var lexer = Lexer.init("[...arr]");
    try expectTokenType(try lexer.nextToken(), .LeftBracket);
    try expectTokenType(try lexer.nextToken(), .Spread);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightBracket);
}

test "expression: destructuring" {
    var lexer = Lexer.init("{a, b} = obj");
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Comma);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "expression: chained calls" {
    var lexer = Lexer.init("obj.method().prop");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Dot);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .Dot);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "expression: optional chaining" {
    var lexer = Lexer.init("obj?.prop");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .OptionalChaining);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "expression: nullish coalescing" {
    var lexer = Lexer.init("x ?? y");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .NullishCoalescing);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "expression: complex arithmetic" {
    var lexer = Lexer.init("(a + b) * c / d - e");
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Plus);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .Star);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Slash);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Minus);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "statement: variable declaration" {
    var lexer = Lexer.init("const x = 5;");
    try expectTokenType(try lexer.nextToken(), .Const);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
}

test "statement: if statement" {
    var lexer = Lexer.init("if (x) { }");
    try expectTokenType(try lexer.nextToken(), .If);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "statement: if else statement" {
    var lexer = Lexer.init("if (x) { } else { }");
    try expectTokenType(try lexer.nextToken(), .If);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .Else);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "statement: for loop" {
    var lexer = Lexer.init("for (let i = 0; i < 10; i++) { }");
    try expectTokenType(try lexer.nextToken(), .For);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Let);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LessThan);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Increment);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "statement: for of loop" {
    var lexer = Lexer.init("for (const x of arr) { }");
    try expectTokenType(try lexer.nextToken(), .For);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Const);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Of);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "statement: for in loop" {
    var lexer = Lexer.init("for (const key in obj) { }");
    try expectTokenType(try lexer.nextToken(), .For);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Const);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .In);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "statement: while loop" {
    var lexer = Lexer.init("while (x) { }");
    try expectTokenType(try lexer.nextToken(), .While);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "statement: do while loop" {
    var lexer = Lexer.init("do { } while (x);");
    try expectTokenType(try lexer.nextToken(), .Do);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .While);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
}

test "statement: switch statement" {
    var lexer = Lexer.init("switch (x) { case 1: break; default: }");
    try expectTokenType(try lexer.nextToken(), .Switch);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .Case);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .Colon);
    try expectTokenType(try lexer.nextToken(), .Break);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .Default);
    try expectTokenType(try lexer.nextToken(), .Colon);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "statement: try catch finally" {
    var lexer = Lexer.init("try { } catch (e) { } finally { }");
    try expectTokenType(try lexer.nextToken(), .Try);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .Catch);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .Finally);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "statement: function declaration" {
    var lexer = Lexer.init("function test() { }");
    try expectTokenType(try lexer.nextToken(), .Function);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "statement: async function" {
    var lexer = Lexer.init("async function test() { }");
    try expectTokenType(try lexer.nextToken(), .Async);
    try expectTokenType(try lexer.nextToken(), .Function);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "statement: class declaration" {
    var lexer = Lexer.init("class Test { }");
    try expectTokenType(try lexer.nextToken(), .Class);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "statement: class with extends" {
    var lexer = Lexer.init("class Test extends Base { }");
    try expectTokenType(try lexer.nextToken(), .Class);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Extends);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "statement: import statement" {
    var lexer = Lexer.init("import x from 'module';");
    try expectTokenType(try lexer.nextToken(), .Import);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .From);
    try expectTokenType(try lexer.nextToken(), .StringLiteral);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
}

test "statement: export statement" {
    var lexer = Lexer.init("export default x;");
    try expectTokenType(try lexer.nextToken(), .Export);
    try expectTokenType(try lexer.nextToken(), .Default);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
}

test "real world: simple function" {
    const code =
        \\function add(a, b) {
        \\  return a + b;
        \\}
    ;
    var lexer = Lexer.init(code);
    try expectTokenType(try lexer.nextToken(), .Function);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Comma);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .Return);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Plus);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "real world: arrow function" {
    const code = "const add = (a, b) => a + b;";
    var lexer = Lexer.init(code);
    try expectTokenType(try lexer.nextToken(), .Const);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Comma);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .Arrow);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Plus);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
}

test "real world: class with methods" {
    const code =
        \\class Person {
        \\  constructor(name) {
        \\    this.name = name;
        \\  }
        \\  greet() {
        \\    return `Hello, ${this.name}`;
        \\  }
        \\}
    ;
    var lexer = Lexer.init(code);
    try expectTokenType(try lexer.nextToken(), .Class);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .This);
    try expectTokenType(try lexer.nextToken(), .Dot);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .Return);
    try expectTokenType(try lexer.nextToken(), .TemplateHead);
    try expectTokenType(try lexer.nextToken(), .This);
    try expectTokenType(try lexer.nextToken(), .Dot);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .TemplateTail);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "real world: async await" {
    const code =
        \\async function fetchData() {
        \\  const data = await fetch(url);
        \\  return data;
        \\}
    ;
    var lexer = Lexer.init(code);
    try expectTokenType(try lexer.nextToken(), .Async);
    try expectTokenType(try lexer.nextToken(), .Function);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .Const);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .Await);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .Return);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "real world: destructuring assignment" {
    const code = "const {a, b: c, ...rest} = obj;";
    var lexer = Lexer.init(code);
    try expectTokenType(try lexer.nextToken(), .Const);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Comma);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Colon);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Comma);
    try expectTokenType(try lexer.nextToken(), .Spread);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
}

test "real world: complex expression with optional chaining" {
    const code = "const name = user?.profile?.name ?? 'Anonymous';";
    var lexer = Lexer.init(code);
    try expectTokenType(try lexer.nextToken(), .Const);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .OptionalChaining);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .OptionalChaining);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .NullishCoalescing);
    try expectTokenType(try lexer.nextToken(), .StringLiteral);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
}

test "real world: private fields in class" {
    const code =
        \\class Counter {
        \\  #count = 0;
        \\  increment() {
        \\    this.#count++;
        \\  }
        \\}
    ;
    var lexer = Lexer.init(code);
    try expectTokenType(try lexer.nextToken(), .Class);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .PrivateIdentifier);
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .This);
    try expectTokenType(try lexer.nextToken(), .Dot);
    try expectTokenType(try lexer.nextToken(), .PrivateIdentifier);
    try expectTokenType(try lexer.nextToken(), .Increment);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "real world: generator function" {
    const code =
        \\function* generator() {
        \\  yield 1;
        \\  yield 2;
        \\}
    ;
    var lexer = Lexer.init(code);
    try expectTokenType(try lexer.nextToken(), .Function);
    try expectTokenType(try lexer.nextToken(), .Star);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .Yield);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .Yield);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "real world: regex validation" {
    const code = "const pattern = /^[a-zA-Z0-9]+@[a-zA-Z0-9]+\\.[a-z]{2,}$/;";
    var lexer = Lexer.init(code);
    try expectTokenType(try lexer.nextToken(), .Const);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .RegexLiteral);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
}

test "real world: object with computed properties" {
    const code = "const obj = { [key]: value, method() {} };";
    var lexer = Lexer.init(code);
    try expectTokenType(try lexer.nextToken(), .Const);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .LeftBracket);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightBracket);
    try expectTokenType(try lexer.nextToken(), .Colon);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Comma);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
}

test "edge: mixed operators without spaces" {
    var lexer = Lexer.init("++x+++y");
    try expectTokenType(try lexer.nextToken(), .Increment);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Increment);
    try expectTokenType(try lexer.nextToken(), .Plus);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "edge: shift operators ambiguity" {
    var lexer = Lexer.init("x>>>y");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .UnsignedRightShift);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "edge: comparison chain" {
    var lexer = Lexer.init("a<b<c");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LessThan);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LessThan);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "edge: assignment vs comparison" {
    var lexer = Lexer.init("x=y==z");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Equal);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "edge: dot vs spread vs decimal" {
    var lexer = Lexer.init(".1 ... 1.2");
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .Spread);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
}

test "edge: question mark variations" {
    var lexer = Lexer.init("? ?? ?. ??=");
    try expectTokenType(try lexer.nextToken(), .Question);
    try expectTokenType(try lexer.nextToken(), .NullishCoalescing);
    try expectTokenType(try lexer.nextToken(), .OptionalChaining);
    try expectTokenType(try lexer.nextToken(), .NullishAssign);
}

test "edge: arrow vs greater equal" {
    var lexer = Lexer.init("=> >=");
    try expectTokenType(try lexer.nextToken(), .Arrow);
    try expectTokenType(try lexer.nextToken(), .GreaterThanEqual);
}

test "edge: exponent vs star patterns" {
    var lexer = Lexer.init("* ** **=");
    try expectTokenType(try lexer.nextToken(), .Star);
    try expectTokenType(try lexer.nextToken(), .Exponent);
    try expectTokenType(try lexer.nextToken(), .ExponentAssign);
}

test "edge: logical vs bitwise operators" {
    var lexer = Lexer.init("& && &= &&=");
    try expectTokenType(try lexer.nextToken(), .BitwiseAnd);
    try expectTokenType(try lexer.nextToken(), .LogicalAnd);
    try expectTokenType(try lexer.nextToken(), .BitwiseAndAssign);
    try expectTokenType(try lexer.nextToken(), .LogicalAndAssign);
}

test "edge: very long identifier" {
    const long_id = "a" ** 1000;
    var lexer = Lexer.init(long_id);
    const token = try lexer.nextToken();
    try expectTokenType(token, .Identifier);
    try std.testing.expectEqual(1000, token.lexeme.len);
}

test "edge: very long number" {
    const long_num = "1234567890" ** 50;
    var lexer = Lexer.init(long_num);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
}

test "edge: unicode identifier" {
    var lexer = Lexer.init("café");
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "edge: emoji in code" {
    var lexer = Lexer.init("const 😀 = 1");
    try expectTokenType(try lexer.nextToken(), .Const);
    try expectTokenType(try lexer.nextToken(), .Invalid);
}

test "edge: null bytes" {
    var lexer = Lexer.init("x\x00y");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Invalid);
}

test "edge: all delimiters in sequence" {
    var lexer = Lexer.init("(){}[];,:");
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .LeftBracket);
    try expectTokenType(try lexer.nextToken(), .RightBracket);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .Comma);
    try expectTokenType(try lexer.nextToken(), .Colon);
}

test "edge: deeply nested structures" {
    var lexer = Lexer.init("[[[[[[]]]]]]");
    var i: usize = 0;
    while (i < 6) : (i += 1) {
        try expectTokenType(try lexer.nextToken(), .LeftBracket);
    }
    i = 0;
    while (i < 6) : (i += 1) {
        try expectTokenType(try lexer.nextToken(), .RightBracket);
    }
}

test "edge: maximum numeric value patterns" {
    var lexer = Lexer.init("9007199254740991");
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
}

test "edge: scientific notation edge cases" {
    var lexer = Lexer.init("1e1000 1e-1000");
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
}

test "edge: bigint edge cases" {
    var lexer = Lexer.init("0n 9999999999999999999999999999n");
    try expectTokenType(try lexer.nextToken(), .BigIntLiteral);
    try expectTokenType(try lexer.nextToken(), .BigIntLiteral);
}

test "edge: hex with all digits" {
    var lexer = Lexer.init("0x0123456789ABCDEFabcdef");
    try expectTokenType(try lexer.nextToken(), .HexLiteral);
}

test "edge: octal with all digits" {
    var lexer = Lexer.init("0o01234567");
    try expectTokenType(try lexer.nextToken(), .OctalLiteral);
}

test "edge: binary long sequence" {
    var lexer = Lexer.init("0b11111111000000001111111100000000");
    try expectTokenType(try lexer.nextToken(), .BinaryLiteral);
}

test "edge: string with all escapes" {
    var lexer = Lexer.init("\"\\n\\r\\t\\\\\\\"\\'\\/\\b\\f\"");
    try expectTokenType(try lexer.nextToken(), .StringLiteral);
}

test "edge: template with many substitutions" {
    var lexer = Lexer.init("`${a}${b}${c}${d}${e}`");
    try expectTokenType(try lexer.nextToken(), .TemplateHead);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .TemplateMiddle);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .TemplateMiddle);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .TemplateMiddle);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .TemplateMiddle);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .TemplateTail);
}

test "edge: regex with complex escapes" {
    var lexer = Lexer.init("/\\w+\\s+\\d+\\b/gi");
    try expectTokenType(try lexer.nextToken(), .RegexLiteral);
}

test "edge: all assignment operators" {
    var lexer = Lexer.init("= += -= *= /= %= **= &= |= ^= <<= >>= >>>= &&= ||= ??=");
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .PlusAssign);
    try expectTokenType(try lexer.nextToken(), .MinusAssign);
    try expectTokenType(try lexer.nextToken(), .StarAssign);
    try expectTokenType(try lexer.nextToken(), .SlashAssign);
    try expectTokenType(try lexer.nextToken(), .PercentAssign);
    try expectTokenType(try lexer.nextToken(), .ExponentAssign);
    try expectTokenType(try lexer.nextToken(), .BitwiseAndAssign);
    try expectTokenType(try lexer.nextToken(), .BitwiseOrAssign);
    try expectTokenType(try lexer.nextToken(), .BitwiseXorAssign);
    try expectTokenType(try lexer.nextToken(), .LeftShiftAssign);
    try expectTokenType(try lexer.nextToken(), .RightShiftAssign);
    try expectTokenType(try lexer.nextToken(), .UnsignedRightShiftAssign);
    try expectTokenType(try lexer.nextToken(), .LogicalAndAssign);
    try expectTokenType(try lexer.nextToken(), .LogicalOrAssign);
    try expectTokenType(try lexer.nextToken(), .NullishAssign);
}

test "edge: minus vs decrement vs arrow" {
    var lexer = Lexer.init("- -- -= ->");
    try expectTokenType(try lexer.nextToken(), .Minus);
    try expectTokenType(try lexer.nextToken(), .Decrement);
    try expectTokenType(try lexer.nextToken(), .MinusAssign);
    try expectTokenType(try lexer.nextToken(), .Minus);
    try expectTokenType(try lexer.nextToken(), .GreaterThan);
}

test "edge: all keywords in sequence" {
    const keywords = "if else for while do break continue return function const let var class extends super static this new import export from as try catch finally throw switch case default async await yield typeof instanceof in of delete void with debugger enum interface implements public private protected true false null";
    var lexer = Lexer.init(keywords);

    const expected = [_]TokenType{
        .If, .Else, .For, .While, .Do, .Break, .Continue, .Return,
        .Function, .Const, .Let, .Var, .Class, .Extends, .Super, .Static,
        .This, .New, .Import, .Export, .From, .As, .Try, .Catch,
        .Finally, .Throw, .Switch, .Case, .Default, .Async, .Await, .Yield,
        .Typeof, .Instanceof, .In, .Of, .Delete, .Void, .With, .Debugger,
        .Enum, .Interface, .Implements, .Public, .Private, .Protected,
        .True, .False, .NullLiteral
    };

    for (expected) |token_type| {
        try expectTokenType(try lexer.nextToken(), token_type);
    }
}

test "edge: span tracking accuracy" {
    var lexer = Lexer.init("hello world");
    const token1 = try lexer.nextToken();
    try expectTokenSpan(token1, 0, 5);
    const token2 = try lexer.nextToken();
    try expectTokenSpan(token2, 6, 11);
}

test "edge: span tracking with complex tokens" {
    var lexer = Lexer.init("x === y");
    const token1 = try lexer.nextToken();
    try expectTokenSpan(token1, 0, 1);
    const token2 = try lexer.nextToken();
    try expectTokenSpan(token2, 2, 5);
    const token3 = try lexer.nextToken();
    try expectTokenSpan(token3, 6, 7);
}

test "edge: consecutive strings" {
    var lexer = Lexer.init("\"a\"\"b\"\"c\"");
    try expectTokenType(try lexer.nextToken(), .StringLiteral);
    try expectTokenType(try lexer.nextToken(), .StringLiteral);
    try expectTokenType(try lexer.nextToken(), .StringLiteral);
}

test "edge: consecutive numbers" {
    var lexer = Lexer.init("123 456 789");
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
}

test "edge: template literal edge - consecutive templates" {
    var lexer = Lexer.init("`a``b``c`");
    try expectTokenType(try lexer.nextToken(), .NoSubstitutionTemplate);
    try expectTokenType(try lexer.nextToken(), .NoSubstitutionTemplate);
    try expectTokenType(try lexer.nextToken(), .NoSubstitutionTemplate);
}

test "edge: regex character class with special chars" {
    var lexer = Lexer.init("/[\\]\\-\\^]/");
    try expectTokenType(try lexer.nextToken(), .RegexLiteral);
}

test "edge: number with multiple separators" {
    var lexer = Lexer.init("1_2_3_4_5");
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
}

test "edge: private identifier boundary" {
    var lexer = Lexer.init("#field.method");
    try expectTokenType(try lexer.nextToken(), .PrivateIdentifier);
    try expectTokenType(try lexer.nextToken(), .Dot);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "comprehensive: JSX-like syntax (treated as regular tokens)" {
    var lexer = Lexer.init("<Component prop={value} />");
    try expectTokenType(try lexer.nextToken(), .LessThan);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Assign);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .Slash);
    try expectTokenType(try lexer.nextToken(), .GreaterThan);
}

test "comprehensive: complex ternary nesting" {
    var lexer = Lexer.init("a ? b ? c : d : e");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Question);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Question);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Colon);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Colon);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "comprehensive: bitwise operations complex" {
    var lexer = Lexer.init("(x & 0xFF) | (y << 8)");
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .BitwiseAnd);
    try expectTokenType(try lexer.nextToken(), .HexLiteral);
    try expectTokenType(try lexer.nextToken(), .RightParen);
    try expectTokenType(try lexer.nextToken(), .BitwiseOr);
    try expectTokenType(try lexer.nextToken(), .LeftParen);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftShift);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .RightParen);
}

test "comprehensive: all number formats together" {
    var lexer = Lexer.init("42 3.14 1e5 0xFF 0o77 0b11 123n");
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .NumericLiteral);
    try expectTokenType(try lexer.nextToken(), .HexLiteral);
    try expectTokenType(try lexer.nextToken(), .OctalLiteral);
    try expectTokenType(try lexer.nextToken(), .BinaryLiteral);
    try expectTokenType(try lexer.nextToken(), .BigIntLiteral);
}

test "comprehensive: mixed quotes in code" {
    var lexer = Lexer.init("\"double\" 'single' `template`");
    try expectTokenType(try lexer.nextToken(), .StringLiteral);
    try expectTokenType(try lexer.nextToken(), .StringLiteral);
    try expectTokenType(try lexer.nextToken(), .NoSubstitutionTemplate);
}

test "comprehensive: operator precedence scenario" {
    var lexer = Lexer.init("a + b * c ** d / e - f");
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Plus);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Star);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Exponent);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Slash);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Minus);
    try expectTokenType(try lexer.nextToken(), .Identifier);
}

test "comprehensive: realistic module import/export" {
    const code = "import { a, b as c } from 'module'; export default class X {}";
    var lexer = Lexer.init(code);
    try expectTokenType(try lexer.nextToken(), .Import);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .Comma);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .As);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
    try expectTokenType(try lexer.nextToken(), .From);
    try expectTokenType(try lexer.nextToken(), .StringLiteral);
    try expectTokenType(try lexer.nextToken(), .Semicolon);
    try expectTokenType(try lexer.nextToken(), .Export);
    try expectTokenType(try lexer.nextToken(), .Default);
    try expectTokenType(try lexer.nextToken(), .Class);
    try expectTokenType(try lexer.nextToken(), .Identifier);
    try expectTokenType(try lexer.nextToken(), .LeftBrace);
    try expectTokenType(try lexer.nextToken(), .RightBrace);
}

test "stress: empty input variations" {
    var lexer1 = Lexer.init("");
    try expectTokenType(try lexer1.nextToken(), .EOF);

    var lexer2 = Lexer.init("   ");
    try expectTokenType(try lexer2.nextToken(), .EOF);

    var lexer3 = Lexer.init("\n\n\n");
    try expectTokenType(try lexer3.nextToken(), .EOF);
}

test "stress: single character input for all operators" {
    const single_chars = "+ - * / % < > = ! & | ^ ~ ( ) { } [ ] ; , : . ?";
    var lexer = Lexer.init(single_chars);

    const expected = [_]TokenType{
        .Plus, .Minus, .Star, .Slash, .Percent, .LessThan, .GreaterThan,
        .Assign, .LogicalNot, .BitwiseAnd, .BitwiseOr, .BitwiseXor, .BitwiseNot,
        .LeftParen, .RightParen, .LeftBrace, .RightBrace, .LeftBracket, .RightBracket,
        .Semicolon, .Comma, .Colon, .Dot, .Question
    };

    for (expected) |token_type| {
        try expectTokenType(try lexer.nextToken(), token_type);
    }
}
