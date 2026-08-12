// a union or intersection member can be a function or constructor type written
// without the parens typescript wants: '(', 'new', 'abstract new', and a type
// parameter list all reach the primary type parser here. typescript parses
// these too (it only flags the missing parens as a grammar error), and a
// dropped alias here breaks .d.ts bundlers that re-parse generated
// declarations.

type A = B | () => void;
type UnionTail = Handler | () => void;
type UnionLeading = | () => void;
type UnionMany = A | () => void | B;
type Intersection = Handler & () => void;
type IntersectionLeading = & () => void;
type MixedChain = A & () => void | B & (c: string) => void;

// 'new' and 'abstract new' head a constructor type in the same positions
type CtorTail = Handler | new () => Handler;
type CtorAbstract = Handler | abstract new () => Handler;
type CtorParams = Handler | new (value: string) => Handler;
type CtorIntersection = Handler & new () => Handler;
type CtorLeading = | new () => Handler;
type CtorReturnUnion = Handler | new () => A | B;
type CtorInObjectType = { make: Handler | new () => Handler };
type CtorInTuple = [Handler | new () => Handler, number];
type CtorInConditional = T extends Handler | new () => Handler ? 1 : 0;

// so does a type parameter list, with no '(' to key off at all
type GenericTail = Handler | <Value>(value: Value) => Value;
type GenericConstrained = Handler | <Value extends object>(value: Value) => Value;
type GenericIntersection = Handler & <Value>(value: Value) => Value;
type GenericLeading = | <Value>(value: Value) => Value;
type GenericCtor = Handler | new <Value>(value: Value) => Handler;
type GenericInTypeArgument = Promise<Handler | <Value>(value: Value) => Value>;
type GenericInObjectType = { map: Handler | <Value>(value: Value) => Value };

// 'abstract' with no 'new' after it is still an ordinary type name
type AbstractName = Handler | abstract;
type AbstractNameWithArgs = Handler | abstract<Other>;
type AbstractNameAlone = abstract;

// every parameter head that decides "function type" instead of "parenthesized"
type ThisParam = Handler | (this: Window, event: Event) => void;
type RestParam = Handler | (...args: number[]) => void;
type OptionalParam = Handler | (value?: string) => void;
type TypedParam = Handler | (value: string) => void;
type BareParam = Handler | (value) => void;
type TwoParams = Handler | (a, b) => void;
type ObjectPatternParam = Handler | ({ value }: { value: number }) => void;
type ArrayPatternParam = Handler | ([first]: [number]) => void;

// the return type keeps consuming, so the trailing union belongs to it
type ReturnUnion = Handler | () => A | B;
type ReturnPredicate = Handler | (value: unknown) => value is string;
type ReturnAsserts = Handler | (value: unknown) => asserts value is string;

// nested type positions reach the same chain
type InObjectType = { onEvent: Handler | () => void };
type InTuple = [Handler | () => void, number];
type InTypeArgument = Promise<Handler | () => void>;
type InArrayElement = (Handler | () => void)[];
type InConditional = T extends Handler | () => void ? 1 : 0;
type InTypeOperator = keyof (Handler | () => void);
declare function accepts(callback: Handler | () => void): void;
declare const holder: { value: Handler | () => void };

// '(' that is genuinely a parenthesized type must stay one
type ParenAlias = (Handler);
type ParenUnionMember = Handler | (Other);
type ParenNestedUnion = Handler | (A | B);
type ParenArray = (A | B)[];
type ParenIndexed = (typeof holder)["value"];
type ParenFunction = Handler | (() => void);
type ParenFunctionArray = Handler | (() => void)[];
type ParenConstructor = Handler | (new () => Handler);
type ParenConstructorArray = Handler | (new () => Handler)[];
type ParenGenericFunction = Handler | (<Value>(value: Value) => Value);
type ParenThisType = Handler | (this);
type ParenTupleType = Handler | ([number, string]);
type ParenObjectType = Handler | ({ value: number });
type ParenKeyof = Handler | (keyof Other);

declare type Handler = { tag: "handler" };
declare type Other = { tag: "other" };
declare type B = { tag: "b" };
declare type T = unknown;
