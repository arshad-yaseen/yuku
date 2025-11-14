const std = @import("std");

pub const Mask = struct {
    pub const IsNumericLiteral: u32 = 1 << 12;
    pub const IsBinaryOperator: u32 = 1 << 13;

    pub const PrecShift: u32 = 7;
    pub const PrecOverlap: u32 = 31;
};

pub const TokenType = enum(u32) {
    NumericLiteral = 1 | Mask.IsNumericLiteral,
    HexLiteral = 2 | Mask.IsNumericLiteral,
    OctalLiteral = 3 | Mask.IsNumericLiteral,
    BinaryLiteral = 4 | Mask.IsNumericLiteral,
    BigIntLiteral = 5 | Mask.IsNumericLiteral,

    StringLiteral = 6,
    RegexLiteral = 7,

    NoSubstitutionTemplate = 8,
    TemplateHead = 9,
    TemplateMiddle = 10,
    TemplateTail = 11,

    True = 12,
    False = 13,
    NullLiteral = 14,

    Plus = 15 | (11 << Mask.PrecShift) | Mask.IsBinaryOperator, // +
    Minus = 16 | Mask.IsBinaryOperator, // -
    Star = 17 | (12 << Mask.PrecShift) | Mask.IsBinaryOperator, // *
    Slash = 18 | Mask.IsBinaryOperator, // /
    Percent = 19 | Mask.IsBinaryOperator, // %
    Exponent = 20 | Mask.IsBinaryOperator, // **

    Assign = 21, // =
    PlusAssign = 22, // +=
    MinusAssign = 23, // -=
    StarAssign = 24, // *=
    SlashAssign = 25, // /=
    PercentAssign = 26, // %=
    ExponentAssign = 27, // **=

    Increment = 28, // ++
    Decrement = 29, // --

    Equal = 30 | Mask.IsBinaryOperator, // ==
    NotEqual = 31 | Mask.IsBinaryOperator, // !=
    StrictEqual = 32 | Mask.IsBinaryOperator, // ===
    StrictNotEqual = 33 | Mask.IsBinaryOperator, // !==
    LessThan = 34 | Mask.IsBinaryOperator, // <
    GreaterThan = 35 | Mask.IsBinaryOperator, // >
    LessThanEqual = 36 | Mask.IsBinaryOperator, // <=
    GreaterThanEqual = 37 | Mask.IsBinaryOperator, // >=

    LogicalAnd = 38, // &&
    LogicalOr = 39, // ||
    LogicalNot = 40, // !

    BitwiseAnd = 41 | Mask.IsBinaryOperator, // &
    BitwiseOr = 42 | Mask.IsBinaryOperator, // |
    BitwiseXor = 43 | Mask.IsBinaryOperator, // ^
    BitwiseNot = 44, // ~
    LeftShift = 45 | Mask.IsBinaryOperator, // <<
    RightShift = 46 | Mask.IsBinaryOperator, // >>
    UnsignedRightShift = 47 | Mask.IsBinaryOperator, // >>>

    BitwiseAndAssign = 48, // &=
    BitwiseOrAssign = 49, // |=
    BitwiseXorAssign = 50, // ^=
    LeftShiftAssign = 51, // <<=
    RightShiftAssign = 52, // >>=
    UnsignedRightShiftAssign = 53, // >>>=

    NullishCoalescing = 54, // ??
    NullishAssign = 55, // ??=
    LogicalAndAssign = 56, // &&=
    LogicalOrAssign = 57, // ||=
    OptionalChaining = 58, // ?.

    LeftParen = 59, // (
    RightParen = 60, // )
    LeftBrace = 61, // {
    RightBrace = 62, // }
    LeftBracket = 63, // [
    RightBracket = 64, // ]
    Semicolon = 65, // ;
    Comma = 66, // ,
    Dot = 67, // .
    Spread = 68, // ...
    Arrow = 69, // =>
    Question = 70, // ?
    Colon = 71, // :

    If = 72,
    Else = 73,
    Switch = 74,
    Case = 75,
    Default = 76,
    For = 77,
    While = 78,
    Do = 79,
    Break = 80,
    Continue = 81,

    Function = 82,
    Return = 83,
    Async = 84,
    Await = 85,
    Yield = 86,

    Var = 87,
    Let = 88,
    Const = 89,
    Using = 90,

    Class = 91,
    Extends = 92,
    Super = 93,
    Static = 94,
    Enum = 95,
    Public = 96,
    Private = 97,
    Protected = 98,
    Interface = 99,
    Implements = 100,

    Import = 101,
    Export = 102,
    From = 103,
    As = 104,

    Try = 105,
    Catch = 106,
    Finally = 107,
    Throw = 108,

    New = 109,
    This = 110,
    Typeof = 111,
    Instanceof = 112 | Mask.IsBinaryOperator,
    In = 113 | Mask.IsBinaryOperator,
    Of = 114,
    Delete = 115,
    Void = 116,
    With = 117,
    Debugger = 118,

    Identifier = 119,
    PrivateIdentifier = 120,

    EOF = 121, // end of file

    pub fn precedence(self: TokenType) u32 {
        return (@intFromEnum(self) >> Mask.PrecShift) & Mask.PrecOverlap;
    }

    pub fn is(self: TokenType, mask: u32) bool {
        return (@intFromEnum(self) & mask) != 0;
    }

    pub fn isNumericLiteral(self: TokenType) bool {
        return self.is(Mask.IsNumericLiteral);
    }

    pub fn isBinaryOperator(self: TokenType) bool {
        return self.is(Mask.IsBinaryOperator);
    }
};

pub const Span = struct {
    start: usize,
    end: usize,
};

pub const Token = struct {
    lexeme: []const u8,
    span: Span,
    type: TokenType,

    pub inline fn eof(pos: usize) Token {
        return Token{ .lexeme = "", .span = .{ .start = pos, .end = pos }, .type = .EOF };
    }
};

pub const CommentType = enum {
    SingleLine, // // comment
    MultiLine, // /* comment */
};

pub const Comment = struct {
    content: []const u8,
    span: Span,
    type: CommentType,
};
