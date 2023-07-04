import { ModCallback } from "isaac-typescript-definitions";
import * as postFireTear from "./callbacks/postFireTear";
import * as postInitPlayer from "./callbacks/postInitPlayer";
import * as postRender from "./callbacks/postRender";
import * as inputActionPlayer from "./callbacksCustom/inputActionPlayer";
import * as postGameEndFilter from "./callbacksCustom/postGameEndFilter";
import * as postGridEntityCollision from "./callbacksCustom/postGridEntityCollision";
import * as postNewRoomReordered from "./callbacksCustom/postNewRoomReordered";
import * as postPickupUpdateFilter from "./callbacksCustom/postPickupUpdateFilter";
import * as postPlayerCollectibleAdded from "./callbacksCustom/postPlayerCollectibleAdded";
import * as postPlayerInitFirst from "./callbacksCustom/postPlayerInitFirst";
import * as postPlayerUpdateReordered from "./callbacksCustom/postPlayerUpdateReordered";
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
  // CALLBACKS see how to organise in a future.
  postPlayerCollectibleAdded.init();
  inputActionPlayer.init();
  postInitPlayer.init();
  postRender.init();
  postFireTear.init();
  postProjectileKill.init();
  postTearKill.init();
  postTearUpdateFilter.init();
  postPlayerUpdateReordered.init();
  postNewRoomReordered.init();
  postGameEndFilter.init();
  postGridEntityCollision.init();
  postPickupUpdateFilter.init();
  postPlayerInitFirst.init();

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

function testTears(_tear: EntityTear) {}

// test
function testPickups(_pickup: EntityPickup) {
  // debug.setVariable("animation", pickup.GetSprite().GetAnimation(), pickup);
}
