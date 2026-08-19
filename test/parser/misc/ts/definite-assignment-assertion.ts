let annotated!: number;
var alsoAnnotated!: string;

let bare!;
var bareVar!;
let withInitializer! = 1;
let annotatedWithInitializer!: number = 1;
const constWithInitializer! = 1;

class Fields {
  annotated!: number;
  accessor annotatedAuto!: number;

  bare!;
  withInitializer! = 1;
  annotatedWithInitializer!: number = 1;
  accessor autoBare!;
  accessor autoWithInitializer! = 1;
}
