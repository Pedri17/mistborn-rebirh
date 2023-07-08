import { ModCallback } from "isaac-typescript-definitions";
import { mod } from "../mod";
import * as allomancyIronSteel from "../powers/allomancyIronSteel";
import * as power from "../powers/power";

export function init(): void {
  mod.AddCallback(ModCallback.POST_RENDER, main);
}

function main() {
  power.controlIputs();
  allomancyIronSteel.checkLastShotDirection();
  power.renderUI();
}
