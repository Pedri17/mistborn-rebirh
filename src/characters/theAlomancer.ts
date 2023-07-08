import { addCollectible } from "isaacscript-common";
import { CollectibleTypeCustom } from "../customVariantType/CollectibleTypeCustom";
import { CostumeCustom } from "../customVariantType/CostumeCustom";

const preconf = {
  ref: {
    coop_baby: "gfx/characters/TheAllomancer/ghost_coop_allomancer.png",
  },
} as const;

export function onInit(pyr: EntityPlayer): void {
  addCollectible(
    pyr,
    CollectibleTypeCustom.ironAllomancy,
    CollectibleTypeCustom.steelAllomancy,
  );
  pyr.AddNullCostume(CostumeCustom.playerAllomancer);
}

export function onCoopBabyInit(pyr: EntityPlayer): void {
  pyr.GetSprite().ReplaceSpritesheet(0, preconf.ref.coop_baby);
  pyr.GetSprite().LoadGraphics();
}
