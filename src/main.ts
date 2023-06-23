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
  //prueba

}

function postPlayerInit() {
  Isaac.ConsoleOutput("Callback fired: POST_PLAYER_INIT");
  Isaac.ConsoleOutput(MessageVar.test);
  Isaac.ConsoleOutput("\n");
  MessageVar.test = "adios";
  Isaac.ConsoleOutput(MessageVar.test);
  Isaac.ConsoleOutput("\n");
}
