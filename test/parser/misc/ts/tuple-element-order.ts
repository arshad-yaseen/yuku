type Valid = [x: A, y?: B, z?: C];
type ValidUnnamed = [A, B?, C?];
type ValidRestAfterOptional = [x?: A, ...rest: B[]];
type ValidRestAfterRequired = [...rest: A[], y: B];
type ValidVariadic = [A, ...T, C];
type ValidVariadicAfterOptional = [A?, ...T];
type ValidOptionalAfterRest = [...A[], B?];

type RequiredAfterOptional = [x?: A, y: B];
type RequiredAfterOptionalUnnamed = [A?, B];
type RequiredAfterOptionalTrailing = [A?, B, C];
type RequiredAfterVariadic = [A?, ...T, C];
type RequiredAfterOptionalNested = [[x?: A, y: B]];
type RequiredAfterOptionalInUnion = [A?, B] | [C?, D];
