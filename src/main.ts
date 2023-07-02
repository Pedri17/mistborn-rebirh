import { ModCallback } from "isaac-typescript-definitions";
import * as postFireTear from "./callbacks/postFireTear";
import * as postInitPlayer from "./callbacks/postInitPlayer";
import * as postRender from "./callbacks/postRender";
import * as inputActionPlayer from "./callbacksCustom/inputActionPlayer";
import * as postPlayerCollectibleAdded from "./callbacksCustom/postPlayerCollectibleAdded";
import * as postProjectileKill from "./callbacksCustom/postProjectileKill";
import * as postTearKill from "./callbacksCustom/postTearKill";
import * as postTearUpdateFilter from "./callbacksCustom/postTearUpdateFilter";
import { PickupVariantCustom } from "./customVariantType/PickupVariantCustom";
import * as debug from "./debug";
import * as metalPiece from "./entities/metalPiece";
import { mod } from "./mod";
import * as allomancyIronSteel from "./powers/allomancyIronSteel";
import * as power from "./powers/power";

main();

function main() {
  debug.init();
  mod.AddCallback(ModCallback.POST_TEAR_UPDATE, testTears);
  mod.AddCallback(ModCallback.POST_PICKUP_UPDATE, testPickups);
  // CALLBACKS
  postPlayerCollectibleAdded.init();
  inputActionPlayer.init();
  postInitPlayer.init();
  postRender.init();
  postFireTear.init();
  postProjectileKill.init();
  postTearKill.init();
  postTearUpdateFilter.init();

  // INIT FEATURES
  power.init();
  allomancyIronSteel.init();
  metalPiece.init();

  // Register custom entities
  mod.registerCustomPickup(
    PickupVariantCustom.metalPiece,
    0,
    metalPiece.takeCoin,
  );
}

function testTears(tear: EntityTear) {
  debug.setVariable("Variant", tear.Variant, tear);
  debug.setVariable("Subtype", tear.SubType, tear);
}

// test
function testPickups(pickup: EntityPickup) {
  debug.setVariable("animation", pickup.GetSprite().GetAnimation(), pickup);
}
