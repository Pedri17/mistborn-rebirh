import { ModCallback } from "isaac-typescript-definitions";
import { initModFeatures } from "isaacscript-common";
import { TheAllomancer } from "./characters/theAlomancer";
import * as debug from "./debug";
import { MetalPiece } from "./entities/metalPiece";
import { initGlobal } from "./global";
import { mod } from "./mod";
import { AllomancyIronSteel } from "./powers/allomancyIronSteel";
import { Powers } from "./powers/power";

const MOD_FEATURES = [
  Powers,
  AllomancyIronSteel,
  MetalPiece,
  TheAllomancer,
] as const;

main();

function main() {
  initModFeatures(mod, MOD_FEATURES);

  debug.init();
  mod.AddCallback(ModCallback.POST_TEAR_UPDATE, testTears);
  mod.AddCallback(ModCallback.POST_PICKUP_UPDATE, testPickups);

  // INIT FEATURES
  initGlobal();

  // Register custom entities
}

function testTears(_tear: EntityTear) {}

// test
function testPickups(_pickup: EntityPickup) {
  // debug.setVariable("animation", pickup.GetSprite().GetAnimation(), pickup);
}
