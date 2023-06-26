import { ModCallback } from "isaac-typescript-definitions";
import { mod } from "../mod";
import * as power from "../powers/power";

export function init() {
  mod.AddCallback(ModCallback.POST_PLAYER_INIT, main);
}

function main(player: EntityPlayer) {
  power.initPlayerWithPowers(player);
}
