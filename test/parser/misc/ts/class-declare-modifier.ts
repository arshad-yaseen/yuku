class Valid {
  declare field: number;
  declare static staticField: number;
  declare readonly readonlyField: number;
}

class OnMethods {
  declare method() {}
  declare bodyless(): void;
  declare get getter() {}
  declare set setter(value) {}
  declare get bodylessGetter(): number;
  declare set bodylessSetter(value: number);
  declare constructor() {}
}
