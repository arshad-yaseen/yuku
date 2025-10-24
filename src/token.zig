pub const TokenType = enum {
    Identifier,
    NumericLiteral,
    StringLiteral,
    BooleanLiteral,
    NullLiteral,

    Var,
    Function,
    Return,
    If,
    Else,

    Plus,
    Minus,
    Star,
    Slash,
    Assign,

    Equal,
    NotEqual,
    LessThan,
    GreaterThan,

    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,
    Semicolon,
    Comma,

    EOF,
    Invalid,
};

pub const Span = struct {
    start: usize,
    end: usize,
};

pub const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    span: Span
};
