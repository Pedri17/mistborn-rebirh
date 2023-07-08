import { ProjectileVariant } from "isaac-typescript-definitions";
import { ModCallbackCustom } from "isaacscript-common";
import { BulletVariantCustom } from "../customVariantType/BulletVariantCustom";
import * as metalPiece from "../entities/metalPiece";
import { mod } from "../mod";
import * as allomancyIronSteel from "../powers/allomancyIronSteel";

export function init(): void {
  mod.AddCallbackCustom(
    ModCallbackCustom.POST_PROJECTILE_KILL,
    removeMetalPieceProjectile,
    BulletVariantCustom.metalPiece as ProjectileVariant,
  );
}

function removeMetalPieceProjectile(bullet: EntityProjectile) {
  metalPiece.remove(bullet);
  allomancyIronSteel.bulletRemove(bullet);
}
