import { ModCallbackCustom } from "isaacscript-common";
import * as metalPiece from "../entities/metalPiece";
import { mod } from "../mod";

export function init(): void {
  mod.AddCallbackCustom(ModCallbackCustom.POST_PLAYER_UPDATE_REORDERED, main);
}

function main(pyr: EntityPlayer) {
  metalPiece.playerCoinTearOwnerUpdate(pyr);
}
