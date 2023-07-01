import { ProjectileVariant, TearVariant } from "isaac-typescript-definitions";

export const BulletVariantCustom = {
  metalPiece: Isaac.GetEntityVariantByName("Metalic piece") as
    | ProjectileVariant
    | TearVariant,
} as const;
