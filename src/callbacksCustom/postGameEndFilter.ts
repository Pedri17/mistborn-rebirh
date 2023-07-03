import { ModCallbackCustom } from "isaacscript-common";
import * as metalPiece from "../entities/metalPiece";
import { mod } from "../mod";

export function init(): void {
  mod.AddCallbackCustom(ModCallbackCustom.POST_GAME_END_FILTER, main);
}

function main(_isGameOver: boolean) {
  metalPiece.getWastedCoins();
}
