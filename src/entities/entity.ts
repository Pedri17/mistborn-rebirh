import {
  EntityType,
  FamiliarVariant,
  PickupVariant,
  TearFlag,
  TearVariant,
} from "isaac-typescript-definitions";
import { getNpcData } from "../variables";

// IS
export function isEqual(
  ent1: Entity | undefined,
  ent2: Entity | undefined,
): boolean {
  if (ent1 === undefined || ent2 === undefined) return ent1 === ent2;
  return GetPtrHash(ent1!) === GetPtrHash(ent2!);
}

export function isExisting(ent: Entity | undefined): boolean {
  return ent !== undefined && ent.Exists();
}

export function isMetalic(ent: Entity): boolean {
  if (ent.Type === EntityType.PICKUP) {
    if (
      // !! falta aquí el tipo throwedCoin y mineralBottle
      ent.Variant === PickupVariant.COIN ||
      ent.Variant === PickupVariant.KEY ||
      ent.Variant === PickupVariant.LOCKED_CHEST ||
      ent.Variant === PickupVariant.LIL_BATTERY ||
      ent.Variant === PickupVariant.CHEST ||
      ent.Variant === PickupVariant.MIMIC_CHEST ||
      ent.Variant === PickupVariant.OLD_CHEST ||
      ent.Variant === PickupVariant.SPIKED_CHEST ||
      ent.Variant === PickupVariant.ETERNAL_CHEST ||
      ent.Variant === PickupVariant.HAUNTED_CHEST
    ) {
      return true;
    }
  } else if (ent.Type === EntityType.TEAR) {
    // !! falta comprobar la tear metálica
    // ((data.isMetalPiece
    //    //Not select bosses
    //    && (ent:ToTear().StickTarget==nil || (ent:ToTear().StickTarget~=nil && not ent:ToTear().StickTarget:IsBoss()))
    //    //Not select sub ludovico coins
    //    && not data.isSubLudovicoTear)
    if (
      ent.ToTear()!.HasTearFlags(TearFlag.CONFUSION) ||
      ent.ToTear()!.HasTearFlags(TearFlag.ATTRACTOR) ||
      ent.ToTear()!.HasTearFlags(TearFlag.GREED_COIN) ||
      ent.ToTear()!.HasTearFlags(TearFlag.MIDAS) ||
      ent.ToTear()!.HasTearFlags(TearFlag.MAGNETIZE)
    ) {
      return true;
    } else if (
      ent.Variant == TearVariant.METALLIC ||
      ent.Variant == TearVariant.COIN
    ) {
      return true;
    }
  } else if (ent.Type == EntityType.FAMILIAR) {
    if (ent.Variant == FamiliarVariant.SAMSONS_CHAINS) {
      return true;
    }
  } else if (ent.Type == EntityType.KNIFE) {
    //!! interacción con Knife
    //&& data.isThrowable)
    return true;
    //!! faltan los proyectiles enemigos (metal pieces)
    //|| (ent.Type == EntityType.PROJECTILE && data.isMetalPiece))
  } else if (ent.ToNPC() !== undefined) {
    if (getNpcData(ent.ToNPC()!).coinAtached !== undefined) {
      return true;
    }
  }
  return false;
}
