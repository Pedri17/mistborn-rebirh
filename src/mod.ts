import { ISCFeature, upgradeMod } from "isaacscript-common";

const modVanilla = RegisterMod("MistbornRebirthTS", 1);
const features = [
  ISCFeature.DISABLE_INPUTS,
  ISCFeature.DEBUG_DISPLAY,
  ISCFeature.SAVE_DATA_MANAGER,
] as const;
export const mod = upgradeMod(modVanilla, features);
