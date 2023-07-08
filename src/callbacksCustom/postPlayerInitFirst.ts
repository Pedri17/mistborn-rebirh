import { PlayerVariant } from "isaac-typescript-definitions";
import { ModCallbackCustom } from "isaacscript-common";
import * as theAllomancer from "../characters/theAlomancer";
import { PlayerTypeCustom } from "../customVariantType/PlayerTypeCustom";
import { mod } from "../mod";

export function init(): void {
  mod.AddCallbackCustom(
    ModCallbackCustom.POST_PLAYER_INIT_FIRST,
    theAllomancer.onInit,
    PlayerVariant.PLAYER,
    PlayerTypeCustom.TheAllomancer,
  );
  mod.AddCallbackCustom(
    ModCallbackCustom.POST_PLAYER_INIT_FIRST,
    theAllomancer.onCoopBabyInit,
    PlayerVariant.COOP_BABY,
    PlayerTypeCustom.TheAllomancer,
  );
}
