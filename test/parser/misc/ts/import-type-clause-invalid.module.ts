import type defaultOnly from "a";
import type { named } from "b";
import type * as namespaceOnly from "c";

import type defaultAndEmpty, {} from "d";
import type defaultAndNamed, { alsoNamed } from "e";
import type defaultAndNamespace, * as ns from "f";

import valueDefault, { value } from "g";
import valueDefaultToo, * as valueNs from "h";
