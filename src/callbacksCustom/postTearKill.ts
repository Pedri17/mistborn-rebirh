import { TearVariant } from "isaac-typescript-definitions";
import { ModCallbackCustom } from "isaacscript-common";
import { BulletVariantCustom } from "../customVariantType/BulletVariantCustom";
import * as metalPiece from "../entities/metalPiece";
import { mod } from "../mod";
import * as allomancyIronSteel from "../powers/allomancyIronSteel";

export function init(): void {
  mod.AddCallbackCustom(
    ModCallbackCustom.POST_TEAR_KILL,
    removeMetalPieceTear,
    BulletVariantCustom.metalPiece as TearVariant,
  );
}

function removeMetalPieceTear(tear: EntityTear) {
  metalPiece.remove(tear);
  allomancyIronSteel.bulletRemove(tear);
}
