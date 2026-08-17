abstract class Valid {
  abstract method(): void;
  abstract get getter(): number;
  abstract set setter(value: number);
  abstract property: number;
  abstract accessor auto: number;
}

abstract class WithImplementation {
  abstract method() {}
  abstract get getter() {}
  abstract set setter(value) {}
  abstract *generator() {}
  abstract async asyncMethod() {}
}

abstract class AbstractConstructor {
  abstract constructor();
}

abstract class AbstractConstructorWithBody {
  abstract constructor() {}
}

abstract class WithInitializer {
  abstract property = 3;
  abstract annotated: number = 3;
  abstract accessor auto = 3;
}
