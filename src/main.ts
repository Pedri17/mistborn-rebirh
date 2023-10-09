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

  // INIT FEATURES
  initGlobal();

  // Register custom entities
}
