import { CollectibleType } from "isaac-typescript-definitions";
import { CollectibleTypeCustom } from "../customVariantType/CollectibleTypeCustom";
import { Power } from "./Power";

let map: Map<CollectibleType, Power> = new Map();

map.set(CollectibleTypeCustom.ironAllomancy, Power.AL_IRON);
map.set(CollectibleTypeCustom.steelAllomancy, Power.AL_STEEL);

export const CollectibleTypeCustomToPower = map;
