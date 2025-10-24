pub const TokenType = enum {
    NumericLiteral,     // 123, 3.14, 1e5
    HexLiteral,         // 0xFF, 0x123
    OctalLiteral,       // 0o777, 0O123
    BinaryLiteral,      // 0b1010, 0B1111
    BigIntLiteral,      // 123n, 0xFFn

    StringLiteral,      // "hello", 'world'
    TemplateLiteral,    // `hello ${name}`
    RegexLiteral,       // /pattern/flags

    BooleanLiteral,     // true, false
    NullLiteral,        // null
    UndefinedLiteral,   // undefined

    Plus,               // +
    Minus,              // -
    Star,               // *
    Slash,              // /
    Percent,            // %
    Exponent,           // **

    Assign,             // =
    PlusAssign,         // +=
    MinusAssign,        // -=
    StarAssign,         // *=
    SlashAssign,        // /=
    PercentAssign,      // %=
    ExponentAssign,     // **=

    Increment,          // ++
    Decrement,          // --

    Equal,              // ==
    NotEqual,           // !=
    StrictEqual,        // ===
    StrictNotEqual,     // !==
    LessThan,           // <
    GreaterThan,        // >
    LessThanEqual,      // <=
    GreaterThanEqual,   // >=

    LogicalAnd,         // &&
    LogicalOr,          // ||
    LogicalNot,         // !

    BitwiseAnd,         // &
    BitwiseOr,          // |
    BitwiseXor,         // ^
    BitwiseNot,         // ~
    LeftShift,          // <<
    RightShift,         // >>
    UnsignedRightShift, // >>>

    BitwiseAndAssign,   // &=
    BitwiseOrAssign,    // |=
    BitwiseXorAssign,   // ^=
    LeftShiftAssign,    // <<=
    RightShiftAssign,   // >>=
    UnsignedRightShiftAssign, // >>>=

    NullishCoalescing,  // ??
    NullishAssign,      // ??=
    LogicalAndAssign,   // &&=
    LogicalOrAssign,    // ||=
    OptionalChaining,   // ?.

    LeftParen,          // (
    RightParen,         // )
    LeftBrace,          // {
    RightBrace,         // }
    LeftBracket,        // [
    RightBracket,       // ]
    Semicolon,          // ;
    Comma,              // ,
    Dot,                // .
    Spread,             // ...
    Arrow,              // =>
    Question,           // ?
    Colon,              // :

    If, Else, Switch, Case, Default,
    For, While, Do, Break, Continue,

    Function, Return, Async, Await,

    Var, Let, Const,

    Class, Extends, Super, Static,

    Import, Export, From,

    Try, Catch, Finally, Throw,

    New, This, Typeof, Instanceof, In, Of,
    Delete, Void, With, Debugger,

    Identifier,         // variableName, $$, _, $$variable
    PrivateIdentifier,  // #privateField
    Comment,            // // or /* */
    Whitespace,         // spaces, tabs
    Newline,            // \n
    EOF,                // End of file
    Invalid,            // Error token
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
