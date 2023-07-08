import { TearVariant } from "isaac-typescript-definitions";
import { ModCallbackCustom } from "isaacscript-common";
import { BulletVariantCustom } from "../customVariantType/BulletVariantCustom";
import { mod } from "../mod";
import * as allomancyIronSteel from "../powers/allomancyIronSteel";

export function init(): void {
  mod.AddCallbackCustom(
    ModCallbackCustom.POST_TEAR_INIT_LATE,
    allomancyIronSteel.initMetalPieceTear,
    BulletVariantCustom.metalPiece as TearVariant,
  );
}
