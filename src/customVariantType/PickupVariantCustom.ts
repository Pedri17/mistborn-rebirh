import { PickupVariant } from "isaac-typescript-definitions";

export const PickupVariantCustom = {
  metalPiece: Isaac.GetEntityVariantByName("Throwed coin") as PickupVariant,
  mineralBottle: Isaac.GetEntityVariantByName("Bottle") as PickupVariant,
  floorMark: Isaac.GetEntityVariantByName("Iron Floor mark") as PickupVariant,
} as const;
