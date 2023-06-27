import { ButtonAction, InputHook } from "isaac-typescript-definitions";
import {
  game,
  getPlayerIndex,
  isActionPressed,
  isActionTriggered,
} from "isaacscript-common";
import * as config from "../config";
import * as entity from "../entities/entity";
import { playersData } from "../entities/player";
import { Power } from "../enums/Power";
import { mod } from "../mod";
import * as allomancyIronSteel from "./allomancyIronSteel";

const preconf = {
  ALLOMANCY_BAR_MAX: 2500,
};

// BOOLEAN
// TODO: expected to players, change for npcs
function hasAnyPower(ent: Entity) {
  let data = entity.getPlayerData(ent);
  if (data !== undefined) {
    return (
      data.powers[1] !== undefined ||
      data.powers[2] !== undefined ||
      data.powers[3] !== undefined
    );
  } else {
    error("hasAnyPower: enity has not any data");
  }
}

function hasPower(ent: Entity, power: Power) {
  const pyr = ent.ToPlayer();
  let pData = entity.getPlayerData(ent);
  if (pyr !== undefined) {
    return (
      pData.powers[1] === power ||
      pData.powers[2] === power ||
      pData.powers[3] === power
    );
  } else {
    error("hasPower: not configured for non player entities");
  }
}

// ACTIVE

function usePower(ent: Entity, power: Power, once?: boolean) {
  if (power === Power.AL_IRON || power === Power.AL_STEEL) {
    if (once) {
      allomancyIronSteel.throwTracer(ent);
    } else {
      allomancyIronSteel.use(ent, power);
    }
  }
}

// spend minerals bar, expected be executed 60 times/sec
function spendMinerals(ent: Entity, quantity: number): boolean {
  let data = entity.getPlayerData(ent);
  if (data.mineralBar > 0) {
    data.mineralBar -= quantity;
    return true;
  } else {
    return false;
  }
}

// CALLBACKS

// postInitPlayer: set initial values to any player
export function initPlayerWithPowers(pyr: EntityPlayer) {
  // Starting values on every player
  // TODO: falta que se carguen si se continúa la run y guardarlos al salir o que tengan valores iniciales ciertos personajes

  //!! temporal para debug
  mod.togglePlayerDisplay(true);
  mod.setPlayerDisplay((pyr) => {
    return `CC: ${playersData[getPlayerIndex(pyr)]!.controlsChanged}`;
  });
}

// inputActionPlayer: Block controls when is changed mode
export function blockInputs(
  pyr: EntityPlayer,
  inputHook: InputHook,
  buttonAction: ButtonAction,
): boolean | undefined {
  const pID = getPlayerIndex(pyr);
  let pData = entity.getPlayerData(pyr);
  // block buttons
  if (pData.controlsChanged) {
    if (
      buttonAction === config.powerAction[1] ||
      buttonAction === config.powerAction[2] ||
      buttonAction === config.powerAction[3]
    ) {
      return false;
    }
  }
  return undefined;
}

// postRender callback (60 times/sec): Controls to use the powers
export function controlIputs() {
  for (let i = 0; i < game.GetNumPlayers(); i++) {
    const pyr = Isaac.GetPlayer();
    const controller = pyr.ControllerIndex;
    let pData = entity.getPlayerData(pyr);

    // players that have any power
    if (hasAnyPower(pyr)) {
      if (isActionTriggered(controller, config.action.CHANGE_MODE)) {
        if (!pData.controlsChanged) {
          pData.controlsChanged = true;
        } else {
          pData.controlsChanged = false;
        }
      }

      if (pData.controlsChanged) {
        for (let i = 1; i < 4; i++) {
          if (
            isActionPressed(controller, config.powerAction[i]!) &&
            pData.powers[i] !== undefined
          ) {
            // Has a power on this slot
            usePower(pyr, pData.powers[i]!, true);
          }
          if (
            isActionTriggered(controller, config.powerAction[i]!) &&
            pData.powers[i] !== undefined
          ) {
            // Has a power on this slot
            usePower(pyr, pData.powers[i]!, false);
          }
        }
      }

      // get last direction shoot and that frame
      if (
        // !! probar con isMoveActionTriggered
        isActionTriggered(
          controller,
          ButtonAction.SHOOT_LEFT,
          ButtonAction.SHOOT_RIGHT,
          ButtonAction.SHOOT_UP,
          ButtonAction.SHOOT_DOWN,
        )
        //isMoveActionTriggered(controller)
      ) {
        pData.lastShot.frame = Isaac.GetFrameCount();
        if (pyr.GetShootingInput() !== undefined) {
          pData.lastShot.direction = pyr.GetShootingInput();
        }
      }
    }
  }
}
