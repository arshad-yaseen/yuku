class Valid {
  readonly field: number = 1;
  static readonly staticField = 1;
  readonly [key: string]: unknown;
}

class OnMethods {
  readonly method() {}
  readonly bodyless(): void;
  readonly get getter() {}
  readonly set setter(value) {}
  readonly constructor() {}
}
