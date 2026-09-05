// legacy (experimentalDecorators) parameter decorators on binding patterns,
// with type annotations and defaults, so walk-order checks exercise the
// decorators-first field order on ObjectPattern, ArrayPattern,
// AssignmentPattern, and BindingRestElement
class C {
  constructor(
    @dec { a }: { a: number },
    @dec [b]: string[],
    @dec { c }: { c: boolean } = { c: true },
    @dec [d]: number[] = [0],
    @dec e: string = "x",
  ) {}
}

// a rest element carries its decorators too, and unlike every other pattern
// its span grows to cover them
class D {
  constructor(@dec ...args: unknown[]) {}
  method(@dec ...args) {}
  multiple(@first @second ...args: string[]) {}
  destructured(@dec ...[a, b]) {}
  after(@dec a, @dec2 ...rest: number[]) {}
}
