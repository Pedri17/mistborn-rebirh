import { ModCallbackCustom } from "isaacscript-common";
import { TearVariantCustom } from "../customVariantType/BulletVariantCustom";
import * as metalPiece from "../entities/metalPiece";
import { mod } from "../mod";

export function init() {
  mod.AddCallbackCustom(
    ModCallbackCustom.POST_TEAR_KILL,
    metalPiece.remove,
    TearVariantCustom.metalPiece,
  );
}
