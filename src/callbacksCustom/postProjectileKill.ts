import { ModCallbackCustom } from "isaacscript-common";
import * as metalPiece from "../entities/metalPiece";
import { mod } from "../mod";

export function init(): void {
  mod.AddCallbackCustom(
    ModCallbackCustom.POST_PROJECTILE_KILL,
    metalPiece.remove,
  );
}
