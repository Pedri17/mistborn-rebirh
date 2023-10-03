import { PlayerVariant } from "isaac-typescript-definitions";
import {
  CallbackCustom,
  ModCallbackCustom,
  ModFeature,
  addCollectible,
} from "isaacscript-common";
import { CollectibleTypeCustom } from "../customVariantType/CollectibleTypeCustom";
import { CostumeCustom } from "../customVariantType/CostumeCustom";
import { PlayerTypeCustom } from "../customVariantType/PlayerTypeCustom";

const preconf = {
  ref: {
    coop_baby: "gfx/characters/TheAllomancer/ghost_coop_allomancer.png",
  },
} as const;

export class TheAllomancer extends ModFeature {
  @CallbackCustom(
    ModCallbackCustom.POST_PLAYER_INIT_FIRST,
    PlayerVariant.PLAYER,
    PlayerTypeCustom.TheAllomancer,
  )
  onInit(pyr: EntityPlayer): void {
    addCollectible(
      pyr,
      CollectibleTypeCustom.ironAllomancy,
      CollectibleTypeCustom.steelAllomancy,
    );
    pyr.AddNullCostume(CostumeCustom.playerAllomancer);
  }

  @CallbackCustom(
    ModCallbackCustom.POST_PLAYER_INIT_FIRST,
    PlayerVariant.COOP_BABY,
    PlayerTypeCustom.TheAllomancer,
  )
  onCoopBabyInit(pyr: EntityPlayer): void {
    pyr.GetSprite().ReplaceSpritesheet(0, preconf.ref.coop_baby);
    pyr.GetSprite().LoadGraphics();
  }
}
