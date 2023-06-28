import * as postInitPlayer from "./callbacks/postInitPlayer";
import * as postRender from "./callbacks/postRender";
import * as inputActionPlayer from "./callbacksCustom/inputActionPlayer";
import * as debug from "./debug";

// import { allomancy } from "./items/allomancy"
let MessageVar = {
  opacity: 1,
  quantity: 0,
  test: "hola",
};

main();

function main() {
  debug.init();
  inputActionPlayer.init();
  postInitPlayer.init();
  postRender.init();
}
