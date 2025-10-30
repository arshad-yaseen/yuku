const std = @import("std");

pub const NodeType = enum {
    Program,

    Directive,

    VariableDeclaration,
    ExpressionStatement,

    Identifier,
    Literal,

    VariableDeclarator,
};

pub const Program = struct {
    type: NodeType = .Program,
    body: []ProgramBody,
};

pub const ProgramBody = union(NodeType) {
    Directive: Directive,
    // statements
    VariableDeclaration: VariableDeclaration,
    ExpressionStatement: ExpressionStatement,
};

pub const Expression = union(NodeType) {
    Identifier: Identifier,
    Literal: Literal,
};

pub const Directive = struct {
    expression: Literal,
    directive: []const u8,
};

pub const VariableKind = enum {
    @"var",
    let,
    @"const",
};

pub const VariableDeclaration = struct {
    type: NodeType = .VariableDeclaration,
    kind: VariableKind,
    declarations: []VariableDeclarator,
};

pub const VariableDeclarator = struct {
    type: NodeType = .VariableDeclarator,
    id: Expression,
    init: ?Expression = null,
};

pub const ExpressionStatement = struct {
    type: NodeType = .ExpressionStatement,
    expression: Expression,
};

pub const Identifier = struct {
    type: NodeType = .Identifier,
    name: []const u8,
};

pub const Literal = struct {
    type: NodeType = .Literal,
    value: LiteralValue,
};

pub const LiteralValue = union(enum) {
    string: []const u8,
    number: f64,
    boolean: bool,
    null: void,
};
