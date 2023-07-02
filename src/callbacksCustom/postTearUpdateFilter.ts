import { TearVariant } from "isaac-typescript-definitions";
import { ModCallbackCustom } from "isaacscript-common";
import { BulletVariantCustom } from "../customVariantType/BulletVariantCustom";
import * as metalPiece from "../entities/metalPiece";
import { mod } from "../mod";

export function init(): void {
  mod.AddCallbackCustom(
    ModCallbackCustom.POST_TEAR_UPDATE_FILTER,
    main,
    BulletVariantCustom.metalPiece as TearVariant,
  );
}

// !! Temporal.
function main(tear: EntityTear) {
  metalPiece.metalPieceBulletUpdate(tear);
}
