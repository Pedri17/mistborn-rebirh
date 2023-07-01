import { ButtonAction, InputHook } from "isaac-typescript-definitions";
import { ModCallbackCustom } from "isaacscript-common";
import { mod } from "../mod";
import * as power from "../powers/power";

export function init(): void {
  mod.AddCallbackCustom(
    ModCallbackCustom.INPUT_ACTION_PLAYER,
    main,
    undefined,
    undefined,
    InputHook.IS_ACTION_TRIGGERED,
    undefined,
  );
}

function main(
  player: EntityPlayer,
  inputHook: InputHook,
  buttonAction: ButtonAction,
): boolean | undefined {
  return power.blockInputs(player, inputHook, buttonAction);
}
