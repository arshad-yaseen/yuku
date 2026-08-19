enum Numeric {
  [1] = 1,
}

enum BigIntKey {
  [1n] = 1,
}

enum Reference {
  [foo] = 1,
}

enum StringKey {
  ["foo"] = 1,
}

enum TemplateKey {
  [`foo`] = 1,
}

const enum ConstEnum {
  [foo] = 1,
}

declare enum AmbientEnum {
  [foo] = 1,
}

enum Named {
  A,
  B = 1,
  "quoted" = 2,
  `templated` = 3,
}
