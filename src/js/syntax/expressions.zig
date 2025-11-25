const std = @import("std");
const token = @import("../token.zig");
const ast = @import("../ast.zig");
const Parser = @import("../parser.zig").Parser;

const literals = @import("literals.zig");

pub fn parseExpression(parser: *Parser, prec: u5) ?*ast.Expression {
    var left: *ast.Expression = parseExpressionPrefix(parser) orelse return null;

    while (parser.current_token.type != .EOF) {
        const lbp = parser.current_token.leftBindingPower();

        if (prec > lbp or lbp == 0) break;

        left = parseExpressionInfix(parser, lbp, left) orelse return null;
    }

    return left;
}

fn parseExpressionInfix(parser: *Parser, prec: u5, left: *ast.Expression) ?*ast.Expression {
    const current_token = parser.current_token;

    // (x++, x--)
    if (current_token.type == .Increment or current_token.type == .Decrement) {
        return parseUpdateExpression(parser, false, left);
    }

    if (current_token.type.isBinaryOperator()) {
        return parseBinaryExpression(parser, prec, left);
    }

    if (current_token.type.isLogicalOperator()) {
        return parseLogicalExpression(parser, prec, left);
    }

    if (current_token.type.isAssignmentOperator()) {
        return parseAssignmentExpression(parser, prec, left);
    }

    // TODO: haha we need to remove this after we implement all expressions
    parser.err(
        current_token.span.start,
        current_token.span.end,
        parser.formatMessage("Unexpected token '{s}' in expression", .{current_token.lexeme}),
        "This operator or syntax is not yet supported by the parser",
    );

    return null;
}

fn parseExpressionPrefix(parser: *Parser) ?*ast.Expression {
    // (++x, --x)
    if (parser.current_token.type == .Increment or parser.current_token.type == .Decrement) {
        return parseUpdateExpression(parser, true, undefined);
    }

    if (parser.current_token.type.isUnaryOperator()) {
        return parseUnaryExpression(parser);
    }

    return parsePrimaryExpression(parser);
}

fn parsePrimaryExpression(parser: *Parser) ?*ast.Expression {
    return switch (parser.current_token.type) {
        .Identifier => literals.parseIdentifierReference(parser),
        .PrivateIdentifier => literals.parsePrivateIdentifier(parser),
        .StringLiteral => literals.parseStringLiteral(parser),
        .True, .False => literals.parseBooleanLiteral(parser),
        .NullLiteral => literals.parseNullLiteral(parser),
        .NumericLiteral, .HexLiteral, .OctalLiteral, .BinaryLiteral => literals.parseNumericLiteral(parser),
        .BigIntLiteral => literals.parseBigIntLiteral(parser),
        .Slash => literals.parseRegExpLiteral(parser),
        .TemplateHead => literals.parseTemplateLiteral(parser),
        .NoSubstitutionTemplate => literals.parseNoSubstitutionTemplateLiteral(parser),
        .LeftBracket => parseArrayExpression(parser),
        .LeftBrace => parseObjectExpression(parser),
        else => {
            const bad_token = parser.current_token;
            parser.err(
                bad_token.span.start,
                bad_token.span.end,
                "Unexpected token in expression position",
                "Expected an expression like a variable name, number, string, or other literal value",
            );
            return null;
        },
    };
}

fn parseUnaryExpression(parser: *Parser) ?*ast.Expression {
    const operator_token = parser.current_token;
    const operator = ast.UnaryOperator.fromToken(operator_token.type);
    const start = operator_token.span.start;

    parser.advance();

    const argument = parseExpression(parser, 14) orelse return null;

    // https://tc39.es/ecma262/#sec-delete-operator-static-semantics-early-errors
    // TODO: uncomment it when we implement MemberExpression
    // TODO: also add parentheses check when we implement ParenthesizedExpression, recursively check for member-expression inside parentheses, for example
    // delete (((foo))) is also an early error
    // if (parser.strict_mode and operator == .Delete and argument.* != .member_expression) {
    //     const argument_span = argument.getSpan();
    //     parser.err(argument_span.start, argument_span.end, "Delete of an unqualified identifier in strict mode", "In strict mode, 'delete' can only be applied to property references, not to variable references");
    // }

    const unary_expression = ast.UnaryExpression{
        .span = .{
            .start = start,
            .end = argument.getSpan().end,
        },
        .operator = operator,
        .argument = argument,
    };

    return parser.createNode(ast.Expression, .{ .unary_expression = unary_expression });
}

fn parseUpdateExpression(parser: *Parser, is_prefix: bool, left: ?*ast.Expression) ?*ast.Expression {
    const operator_token = parser.current_token;

    const operator = ast.UpdateOperator.fromToken(operator_token.type);

    const start = if (is_prefix) operator_token.span.start else left.?.getSpan().start;

    parser.advance();

    var argument: *ast.Expression = undefined;
    var end: u32 = undefined;

    if (is_prefix) {
        // ++x, --x
        argument = parseExpression(parser, 14) orelse return null;
        const arg_span = argument.getSpan();
        end = arg_span.end;

        if (!isValidAssignmentTarget(parser, argument)) {
            parser.err(
                arg_span.start,
                arg_span.end,
                "Invalid left-hand side expression in prefix operation",
                "Prefix increment/decrement requires a variable or property, not an expression result",
            );
            return null;
        }
    } else {
        // x++, x--
        argument = left orelse unreachable;

        end = operator_token.span.end;

        if (!isValidAssignmentTarget(parser, argument)) {
            const arg_span = argument.getSpan();
            parser.err(
                arg_span.start,
                arg_span.end,
                "Invalid left-hand side expression in postfix operation",
                "Postfix increment/decrement requires a variable or property, not an expression result",
            );
            return null;
        }
    }

    const update_expression = ast.UpdateExpression{
        .span = .{
            .start = start,
            .end = end,
        },
        .operator = operator,
        .prefix = is_prefix,
        .argument = argument,
    };

    return parser.createNode(ast.Expression, .{ .update_expression = update_expression });
}

fn parseBinaryExpression(parser: *Parser, prec: u5, left: *ast.Expression) ?*ast.Expression {
    const operator_token = parser.current_token;
    const operator = ast.BinaryOperator.fromToken(operator_token.type);

    parser.advance();

    // ** is right assosiative
    const next_prec = if (operator == .Exponent) prec else prec + 1;

    const right = parseExpression(parser, next_prec) orelse return null;

    const binary_expression = ast.BinaryExpression{
        .span = .{
            .start = left.getSpan().start,
            .end = right.getSpan().end,
        },
        .operator = operator,
        .left = left,
        .right = right,
    };

    return parser.createNode(ast.Expression, .{ .binary_expression = binary_expression });
}

fn parseLogicalExpression(parser: *Parser, prec: u5, left: *ast.Expression) ?*ast.Expression {
    const operator_token = parser.current_token;

    const operator = ast.LogicalOperator.fromToken(operator_token.type);

    parser.advance();

    const right = parseExpression(parser, prec + 1) orelse return null;

    const logical_expression = ast.LogicalExpression{
        .span = .{
            .start = left.getSpan().start,
            .end = right.getSpan().end,
        },
        .operator = operator,
        .left = left,
        .right = right,
    };

    return parser.createNode(ast.Expression, .{ .logical_expression = logical_expression });
}

fn parseAssignmentExpression(parser: *Parser, prec: u5, left: *ast.Expression) ?*ast.Expression {
    const operator_token = parser.current_token;
    const operator = ast.AssignmentOperator.fromToken(operator_token.type);

    if (!isValidAssignmentTarget(parser, left)) {
        const left_span = left.getSpan();
        parser.err(
            left_span.start,
            left_span.end,
            "Invalid left-hand side in assignment",
            "The left side of an assignment must be a variable or property access",
        );
        return null;
    }

    // for logical assignment operators (&&=, ||=, ??=), check for simple assignment target
    const is_logical_assign = operator == .LogicalAndAssign or operator == .LogicalOrAssign or operator == .NullishAssign;

    if (is_logical_assign and !isSimpleAssignmentTarget(parser, left)) {
        const left_span = left.getSpan();
        parser.err(
            left_span.start,
            left_span.end,
            "Invalid left-hand side in logical assignment",
            "Logical assignment operators (&&=, ||=, ??=) require a simple reference (variable or property access)",
        );
        return null;
    }

    parser.advance();

    // assignment is right-associative, so parse with same precedence
    const right = parseExpression(parser, prec) orelse return null;

    const target = parseAssignmentTarget(parser, left) orelse return null;

    const assignment_expression = ast.AssignmentExpression{
        .span = .{
            .start = left.getSpan().start,
            .end = right.getSpan().end,
        },
        .operator = operator,
        .left = target,
        .right = right,
    };

    return parser.createNode(ast.Expression, .{ .assignment_expression = assignment_expression });
}

fn parseAssignmentTarget(parser: *Parser, expr: *ast.Expression) ?*ast.AssignmentTarget {
    if (!isValidAssignmentTarget(parser, expr)) {
        return null;
    }

    const target = ast.AssignmentTarget{ .simple_assignment_target = expr };
    return parser.createNode(ast.AssignmentTarget, target);
}

// validators

pub inline fn isValidAssignmentTarget(parser: *Parser, expr: *ast.Expression) bool {
    _ = parser;
    return switch (expr.*) {
        .identifier_reference => true,
        // TODO: uncomment when add member_expression
        // .member_expression => true,

        else => false,
    };
}

pub inline fn isSimpleAssignmentTarget(parser: *Parser, expr: *ast.Expression) bool {
    _ = parser;
    return switch (expr.*) {
        .identifier_reference => true,
        // TODO: uncomment when add member_expression
        // .member_expression => true,

        else => false,
    };
}

// ArrayExpression: [elem1, elem2, ...spread, , ]
fn parseArrayExpression(parser: *Parser) ?*ast.Expression {
    const start = parser.current_token.span.start;
    parser.advance(); // consume '['

    var elements = std.ArrayList(?*ast.ArrayExpressionElement).empty;

    while (parser.current_token.type != .RightBracket and parser.current_token.type != .EOF) {
        if (parser.current_token.type == .Comma) {
            // elision (empty slot): [1, , 3]
            parser.append(&elements, null);
            parser.advance();
            continue;
        }

        const elem = parseArrayElement(parser) orelse return null;
        parser.append(&elements, elem);

        if (parser.current_token.type == .Comma) {
            parser.advance();
        } else {
            break;
        }
    }

    if (parser.current_token.type != .RightBracket) {
        parser.err(
            start,
            parser.current_token.span.end,
            "Expected ']' to close array expression",
            "Add ']' to close the array literal",
        );
        return null;
    }

    const end = parser.current_token.span.end;
    parser.advance();

    const array_expr = ast.ArrayExpression{
        .elements = parser.dupe(?*ast.ArrayExpressionElement, elements.items),
        .span = .{ .start = start, .end = end },
    };

    return parser.createNode(ast.Expression, .{ .array_expression = array_expr });
}

fn parseArrayElement(parser: *Parser) ?*ast.ArrayExpressionElement {
    if (parser.current_token.type == .Spread) {
        const spread = parseSpreadElement(parser) orelse return null;
        return parser.createNode(ast.ArrayExpressionElement, .{ .spread_element = spread });
    }

    const expr = parseExpression(parser, 0) orelse return null;
    return parser.createNode(ast.ArrayExpressionElement, .{ .expression = expr });
}

fn parseSpreadElement(parser: *Parser) ?*ast.SpreadElement {
    const start = parser.current_token.span.start;
    parser.advance(); // consume '...'

    const argument = parseExpression(parser, 0) orelse return null;
    const end = argument.getSpan().end;

    const spread = ast.SpreadElement{
        .argument = argument,
        .span = .{ .start = start, .end = end },
    };

    return parser.createNode(ast.SpreadElement, spread);
}

// ObjectExpression: { key: value, shorthand, ...spread }
fn parseObjectExpression(parser: *Parser) ?*ast.Expression {
    const start = parser.current_token.span.start;
    parser.advance(); // consume '{'

    var properties = std.ArrayList(*ast.ObjectExpressionProperty).empty;

    while (parser.current_token.type != .RightBrace and parser.current_token.type != .EOF) {
        const prop = parseObjectProperty(parser) orelse return null;
        parser.append(&properties, prop);

        if (parser.current_token.type == .Comma) {
            parser.advance();
        } else {
            break;
        }
    }

    if (parser.current_token.type != .RightBrace) {
        parser.err(
            start,
            parser.current_token.span.end,
            "Expected '}' to close object expression",
            "Add '}' to close the object literal",
        );
        return null;
    }

    const end = parser.current_token.span.end;
    parser.advance();

    const obj_expr = ast.ObjectExpression{
        .properties = parser.dupe(*ast.ObjectExpressionProperty, properties.items),
        .span = .{ .start = start, .end = end },
    };

    return parser.createNode(ast.Expression, .{ .object_expression = obj_expr });
}

fn parseObjectProperty(parser: *Parser) ?*ast.ObjectExpressionProperty {
    // spread property: { ...obj }
    if (parser.current_token.type == .Spread) {
        const spread = parseSpreadElement(parser) orelse return null;
        return parser.createNode(ast.ObjectExpressionProperty, .{ .spread_element = spread });
    }

    const start = parser.current_token.span.start;
    var computed = false;
    var key: *ast.PropertyKey = undefined;
    var shorthand_identifier_token: ?token.Token = null;

    // computed property: { [expr]: value }
    if (parser.current_token.type == .LeftBracket) {
        computed = true;
        parser.advance();

        const key_expr = parseExpression(parser, 0) orelse return null;
        key = parser.createNode(ast.PropertyKey, .{ .expression = key_expr });

        if (parser.current_token.type != .RightBracket) {
            parser.err(
                key_expr.getSpan().start,
                parser.current_token.span.end,
                "Expected ']' after computed property key",
                "Add ']' to close the computed property name",
            );
            return null;
        }
        parser.advance();
    } else if (parser.current_token.type.isIdentifierLike()) {
        // identifier key: { foo: value } or shorthand { foo }
        shorthand_identifier_token = parser.current_token;

        const id_name = ast.IdentifierName{
            .name = parser.current_token.lexeme,
            .span = parser.current_token.span,
        };

        key = parser.createNode(ast.PropertyKey, .{ .identifier_name = id_name });

        parser.advance();
    } else if (parser.current_token.type.isNumericLiteral()) {
        // numeric key: { 0: value }
        const num_lit = literals.parseNumericLiteral(parser) orelse return null;
        key = parser.createNode(ast.PropertyKey, .{ .expression = num_lit });
    } else if (parser.current_token.type == .StringLiteral) {
        // string key: { "foo": value }
        const str_lit = literals.parseStringLiteral(parser) orelse return null;
        key = parser.createNode(ast.PropertyKey, .{ .expression = str_lit });
    } else {
        parser.err(
            parser.current_token.span.start,
            parser.current_token.span.end,
            "Expected property key",
            "Use an identifier, string, number, or computed property [expression]",
        );
        return null;
    }

    // check for shorthand: { foo } or shorthand with value: { foo = default }
    const is_shorthand = !computed and
        shorthand_identifier_token != null and
        (parser.current_token.type == .Comma or parser.current_token.type == .RightBrace);

    var value: *ast.Expression = undefined;

    if (is_shorthand) {
        // shorthand property: { foo }
        const id_token = shorthand_identifier_token.?;
        const id_ref = ast.IdentifierReference{
            .name = id_token.lexeme,
            .span = id_token.span,
        };
        value = parser.createNode(ast.Expression, .{ .identifier_reference = id_ref });
    } else {
        // regular property: { key: value }
        if (parser.current_token.type != .Colon) {
            const key_span = key.getSpan();
            parser.err(
                key_span.start,
                parser.current_token.span.end,
                "Expected ':' after property key",
                "Add ':' followed by a value, or use shorthand syntax for identifiers",
            );
            return null;
        }
        parser.advance(); // consume ':'

        value = parseExpression(parser, 0) orelse return null;
    }

    const end = value.getSpan().end;

    const prop = ast.ObjectProperty{
        .key = key,
        .value = value,
        .shorthand = is_shorthand,
        .computed = computed,
        .span = .{ .start = start, .end = end },
    };

    const prop_ptr = parser.createNode(ast.ObjectProperty, prop);
    return parser.createNode(ast.ObjectExpressionProperty, .{ .property = prop_ptr });

    // TODO: handle method, and set/get property kinds, currently only handling 'init' and not handling the method.
    // Since we need to implement the FunctionExpression/ArrowFunctionExpression first.
}
