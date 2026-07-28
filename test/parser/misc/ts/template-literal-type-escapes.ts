// escapes inside a template literal type head belong to the template text, so
// the head must parse as a type; only genuinely bad escapes stay diagnostics.

type Backtick = `\`${string}\``;
type Unicode = `\u0041${string}`;
type CodePoint = `\u{41}${string}`;
type Hex = `\x41${string}`;
type Newline = `\n${string}`;
type Dollar = `\${${string}}`;
type Middle = `${string}\`${number}\``;
type Mixed = `a${string}\u0041${number}b`;
type Plain = `\`plain\``;

type Nested<T> = T extends `\`${infer U}\`` ? U : never;

interface Keyed {
  [key: `\`${string}`]: number;
}

declare function fn(): `\`${bigint}\``;

let value: `\`${string}\`` = `\`x\``;

// negative space: invalid escapes are still reported, exactly as in an
// untagged template literal expression
type BadOctal = `\8${string}`;
type BadHex = `\x${string}`;
type BadCodePoint = `\u{}${string}`;
