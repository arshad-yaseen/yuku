# JavaScript Operator Precedence

## 18: Grouping
**Associativity:** n/a
- **Grouping** → `(x)`

## 17: Access and Call
**Associativity:** left-to-right / n/a
- **Member access** → `x.y`
- **Optional chaining** → `x?.y`
- **Computed member access** → `x[y]`
- **new with argument list** → `new x(y)`
- **Function call** → `x(y)`
- **Import** → `import(x)`

## 16: New
**Associativity:** n/a
- **new without argument list** → `new x`

## 15: Postfix Operators
**Associativity:** n/a
- **Postfix increment** → `x++`
- **Postfix decrement** → `x--`

## 14: Prefix Operators
**Associativity:** n/a
- **Prefix increment** → `++x`
- **Prefix decrement** → `--x`
- **Logical NOT** → `!x`
- **Bitwise NOT** → `~x`
- **Unary plus** → `+x`
- **Unary negation** → `-x`
- **typeof** → `typeof x`
- **void** → `void x`
- **delete** → `delete x`
- **await** → `await x`

## 13: Exponentiation
**Associativity:** right-to-left
- **Exponentiation** → `x ** y`

## 12: Multiplicative Operators
**Associativity:** left-to-right
- **Multiplication** → `x * y`
- **Division** → `x / y`
- **Remainder** → `x % y`

## 11: Additive Operators
**Associativity:** left-to-right
- **Addition** → `x + y`
- **Subtraction** → `x - y`

## 10: Bitwise Shift
**Associativity:** left-to-right
- **Left shift** → `x << y`
- **Right shift** → `x >> y`
- **Unsigned right shift** → `x >>> y`

## 9: Relational Operators
**Associativity:** left-to-right
- **Less than** → `x < y`
- **Less than or equal** → `x <= y`
- **Greater than** → `x > y`
- **Greater than or equal** → `x >= y`
- **in** → `x in y`
- **instanceof** → `x instanceof y`

## 8: Equality Operators
**Associativity:** left-to-right
- **Equality** → `x == y`
- **Inequality** → `x != y`
- **Strict equality** → `x === y`
- **Strict inequality** → `x !== y`

## 7: Bitwise AND
**Associativity:** left-to-right
- **Bitwise AND** → `x & y`

## 6: Bitwise XOR
**Associativity:** left-to-right
- **Bitwise XOR** → `x ^ y`

## 5: Bitwise OR
**Associativity:** left-to-right
- **Bitwise OR** → `x | y`

## 4: Logical AND
**Associativity:** left-to-right
- **Logical AND** → `x && y`

## 3: Logical OR, Nullish Coalescing
**Associativity:** left-to-right
- **Logical OR** → `x || y`
- **Nullish coalescing operator** → `x ?? y`

## 2: Assignment and Miscellaneous
**Associativity:** right-to-left / n/a
- **Assignment** → `x = y`
- **Addition assignment** → `x += y`
- **Subtraction assignment** → `x -= y`
- **Exponentiation assignment** → `x **= y`
- **Multiplication assignment** → `x *= y`
- **Division assignment** → `x /= y`
- **Remainder assignment** → `x %= y`
- **Left shift assignment** → `x <<= y`
- **Right shift assignment** → `x >>= y`
- **Unsigned right shift assignment** → `x >>>= y`
- **Bitwise AND assignment** → `x &= y`
- **Bitwise XOR assignment** → `x ^= y`
- **Bitwise OR assignment** → `x |= y`
- **Logical AND assignment** → `x &&= y`
- **Logical OR assignment** → `x ||= y`
- **Nullish coalescing assignment** → `x ??= y`
- **Conditional (ternary) operator** → `x ? y : z`
- **Arrow** → `x => y`
- **yield** → `yield x`
- **yield*** → `yield* x`
- **Spread** → `...x`

## 1: Comma
**Associativity:** left-to-right
- **Comma operator** → `x, y`
