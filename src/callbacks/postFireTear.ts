import { ModCallback } from "isaac-typescript-definitions";
import * as metalPiece from "../entities/metalPiece";
import { mod } from "../mod";

export function init() {
  mod.AddCallback(ModCallback.POST_FIRE_TEAR, main);
}

function main(tear: EntityTear) {
  metalPiece.fireTear(tear);
}
