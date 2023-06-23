import { ModCallback } from "isaac-typescript-definitions";
import { mod } from "./mod";

// import { allomancy } from "./items/allomancy"
let MessageVar = {
  opacity: 1,
  quantity:  0,
  test: "hola"
}

main();

function main() {

  // Register a callback function that corresponds to when a new player is initialized.
  mod.AddCallback(ModCallback.POST_PLAYER_INIT, postPlayerInit);
  // allomancy();
  // bueno carallo bueno
}

function postPlayerInit() {
  Isaac.DebugString("Callback fired: POST_PLAYER_INIT");
  Isaac.DebugString(MessageVar.test);
  Isaac.DebugString("\n");
  MessageVar.test = "adios";
  Isaac.DebugString(MessageVar.test);
  Isaac.DebugString("\n");
}
