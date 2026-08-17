interface Valid {
  readonly property: number;
  readonly [key: string]: unknown;
}

interface OnSignatures {
  readonly method();
  readonly generic<T>(value: T): T;
  readonly get getter(): number;
  readonly set setter(value: number);
  readonly new (): Valid;
}

type ValidLiteral = {
  readonly property: number;
  readonly [key: string]: unknown;
};

type LiteralOnSignatures = {
  readonly method(): void;
};
