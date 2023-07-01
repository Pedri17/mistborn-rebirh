import * as postFireTear from "./callbacks/postFireTear";
import * as postInitPlayer from "./callbacks/postInitPlayer";
import * as postRender from "./callbacks/postRender";
import * as inputActionPlayer from "./callbacksCustom/inputActionPlayer";
import * as postPlayerCollectibleAdded from "./callbacksCustom/postPlayerCollectibleAdded";
import * as postProjectileKill from "./callbacksCustom/postProjectileKill";
import * as postTearKill from "./callbacksCustom/postTearKill";
import { PickupVariantCustom } from "./customVariantType/PickupVariantCustom";
import * as debug from "./debug";
import * as metalPiece from "./entities/metalPiece";
import { mod } from "./mod";
import * as allomancyIronSteel from "./powers/allomancyIronSteel";
import * as power from "./powers/power";

main();

function main() {
  debug.init();
  // CALLBACKS
  postPlayerCollectibleAdded.init();
  inputActionPlayer.init();
  postInitPlayer.init();
  postRender.init();
  postFireTear.init();
  postProjectileKill.init();
  postTearKill.init();

  // INIT FEATURES
  power.init();
  allomancyIronSteel.init();
  metalPiece.init();

  // Register custom entities
  mod.registerCustomPickup(
    PickupVariantCustom.metalPiece,
    1,
    metalPiece.takeCoin,
  );
}
