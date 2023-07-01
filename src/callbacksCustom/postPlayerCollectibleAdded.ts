import { ModCallbackCustom } from "isaacscript-common";
import { CollectibleTypeCustom } from "../customVariantType/CollectibleTypeCustom";
import { mod } from "../mod";
import * as power from "../powers/power";

export function init(): void {
  mod.AddCallbackCustom(
    ModCallbackCustom.POST_PLAYER_COLLECTIBLE_ADDED,
    power.getCollectiblePower,
    CollectibleTypeCustom.ironAllomancy,
  );
  mod.AddCallbackCustom(
    ModCallbackCustom.POST_PLAYER_COLLECTIBLE_ADDED,
    power.getCollectiblePower,
    CollectibleTypeCustom.steelAllomancy,
  );
}
