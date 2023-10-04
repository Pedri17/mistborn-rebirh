import {
  FamiliarVariant,
  PickupVariant,
  ProjectileVariant,
  TearFlag,
  TearVariant,
} from "isaac-typescript-definitions";
import { BulletVariantCustom } from "../customVariantType/BulletVariantCustom";

// IS
export function isEqual(
  ent1: Entity | undefined,
  ent2: Entity | undefined,
): boolean {
  if (ent1 === undefined || ent2 === undefined) {
    return ent1 === ent2;
  }
  return GetPtrHash(ent1) === GetPtrHash(ent2);
}

export function isMetalic(ent: Entity): boolean {
  const pickup = ent.ToPickup();
  const tear = ent.ToTear();
  const familiar = ent.ToFamiliar();
  const knife = ent.ToKnife();
  const projectile = ent.ToProjectile();

  if (pickup !== undefined) {
    if (
      // !! Falta aquí el tipo throwedCoin y mineralBottle.
      pickup.Variant === PickupVariant.COIN ||
      pickup.Variant === PickupVariant.KEY ||
      pickup.Variant === PickupVariant.LOCKED_CHEST ||
      pickup.Variant === PickupVariant.LIL_BATTERY ||
      pickup.Variant === PickupVariant.CHEST ||
      pickup.Variant === PickupVariant.MIMIC_CHEST ||
      pickup.Variant === PickupVariant.OLD_CHEST ||
      pickup.Variant === PickupVariant.SPIKED_CHEST ||
      pickup.Variant === PickupVariant.ETERNAL_CHEST ||
      pickup.Variant === PickupVariant.HAUNTED_CHEST
    ) {
      return true;
    }
  } else if (tear !== undefined) {
    // !! Falta comprobar la tear metálica, si afecta a bosses y ludovico.
    if (
      tear.HasTearFlags(TearFlag.CONFUSION) ||
      tear.HasTearFlags(TearFlag.ATTRACTOR) ||
      tear.HasTearFlags(TearFlag.GREED_COIN) ||
      tear.HasTearFlags(TearFlag.MIDAS) ||
      tear.HasTearFlags(TearFlag.MAGNETIZE)
    ) {
      return true;
    }
    if (
      tear.Variant === TearVariant.METALLIC ||
      tear.Variant === TearVariant.COIN ||
      tear.Variant === BulletVariantCustom.metalPiece
    ) {
      return true;
    }
  } else if (familiar !== undefined) {
    if (familiar.Variant === FamiliarVariant.SAMSONS_CHAINS) {
      return true;
    }
  } else if (knife !== undefined) {
    // !! Interacción con Knife & data.isThrowable.
    return true;
  } else if (projectile !== undefined) {
    if (
      projectile.Variant === BulletVariantCustom.metalPiece ||
      projectile.Variant === ProjectileVariant.COIN ||
      projectile.Variant === ProjectileVariant.RING
    ) {
      return true;
    }
  }
  return false;
}
// !! También falta comprobar la bomba.

export function areColliding(ent1: Entity, ent2: Entity): boolean {
  return ent1.Position.sub(ent2.Position).Length() < ent1.Size + ent2.Size;
}
