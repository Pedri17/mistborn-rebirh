import { ISCFeature, upgradeMod } from "isaacscript-common";

const modVanilla = RegisterMod("MistbornRebirthTS", 1);
const features = [
  ISCFeature.SAVE_DATA_MANAGER,
  ISCFeature.PICKUP_INDEX_CREATION,
  ISCFeature.CUSTOM_PICKUPS,
] as const;
export const mod = upgradeMod(modVanilla, features);
