class Valid<T> {
  constructor(value: T) {}
  method<U>(value: U) {}
  static constructor<U>() {}
  ["constructor"]<U>() {}
}

class OnConstructor {
  constructor<T>() {}
}

class OnQuotedConstructor {
  "constructor"<T>() {}
}

class OnSingleQuotedConstructor {
  'constructor'<T>() {}
}

declare class OnAmbientConstructor {
  constructor<T>();
}

abstract class OnAbstractConstructor {
  constructor<T>() {}
}
