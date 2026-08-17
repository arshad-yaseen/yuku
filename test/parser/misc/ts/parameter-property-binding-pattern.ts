class Valid {
  constructor(
    public named: number,
    private readonly annotated: string,
    protected optional?: boolean,
    override withDefault = 1,
  ) {}
}

class ArrayPatterns {
  constructor(public []) {}
}

class ObjectPatterns {
  constructor(private {}) {}
}

class PatternWithDefault {
  constructor(readonly [a, b] = []) {}
}

class NestedPattern {
  constructor(protected { a: { b } }: Record<string, unknown>) {}
}

class PlainParameterPatterns {
  constructor([a, b], { c }) {}
}
