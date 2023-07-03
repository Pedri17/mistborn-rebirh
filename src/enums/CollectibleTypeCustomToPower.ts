import { CollectibleType } from "isaac-typescript-definitions";
import { CollectibleTypeCustom } from "../customVariantType/CollectibleTypeCustom";
import { Power } from "./Power";

const map = new Map<CollectibleType, Power>();

map.set(CollectibleTypeCustom.ironAllomancy, Power.AL_IRON);
map.set(CollectibleTypeCustom.steelAllomancy, Power.AL_STEEL);

export const collectibleTypeCustomToPower = map;
