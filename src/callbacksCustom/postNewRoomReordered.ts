import { RoomType } from "isaac-typescript-definitions";
import { ModCallbackCustom } from "isaacscript-common";
import * as metalPiece from "../entities/metalPiece";
import { mod } from "../mod";
import * as allomancyIronSteel from "../powers/allomancyIronSteel";

export function init(): void {
  mod.AddCallbackCustom(ModCallbackCustom.POST_NEW_ROOM_REORDERED, main);
}

function main(_roomType: RoomType) {
  allomancyIronSteel.roomEnter();
  metalPiece.getWastedCoins();
}
