import { ModCallback } from "isaac-typescript-definitions";
import { mod } from "../mod";
import * as power from "../powers/power";

export function init() {
  mod.AddCallback(ModCallback.POST_RENDER, main);
}

function main() {
  power.controlIputs();
}
