import * as postInitPlayer from "./callbacks/postInitPlayer";
import * as postRender from "./callbacks/postRender";
import * as inputActionPlayer from "./callbacksCustom/inputActionPlayer";

// import { allomancy } from "./items/allomancy"
let MessageVar = {
  opacity: 1,
  quantity: 0,
  test: "hola",
};

main();

function main() {
  inputActionPlayer.init();
  postInitPlayer.init();
  postRender.init();
}
