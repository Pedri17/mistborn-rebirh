import {
  ButtonAction,
  EntityType,
  InputHook,
} from "isaac-typescript-definitions";
import {
  getPlayerIndex,
  isActionPressed,
  isActionTriggered,
  log,
} from "isaacscript-common";
import { playerData } from "../classes/playerData";
import * as config from "../config";
import * as entity from "../entities/entity";
import { playersData } from "../entities/player";
import { Power } from "../enums/Power";
import { mod } from "../mod";

const preconf = {
  ALLOMANCY_BAR_MAX: 2500,
  IRON_STEEL: {
    FAST_CRASH_DMG_MULT: 1,
    PUSHED_COIN_DMG_MULT: 1.5,
    velocity: {
      push: {
        [EntityType.PLAYER]: 7,
        [EntityType.PICKUP]: 20,
        [EntityType.TEAR]: 20,
        [EntityType.BOMB]: 8,
        [EntityType.FAMILIAR]: 8,
        [EntityType.KNIFE]: 0,
        [EntityType.PROJECTILE]: 20,
        ENEMY: 70,
        KNIFE_TEAR: 10,
        KNIFE_PICKUP: 12,
      },
      AIMING_PUSH_ENTITY_VEL: 25,
      MIN_TEAR_TO_HOOK: 20,
      MIN_TO_PICKUP_DAMAGE: 15,
      MIN_DOUBLE_HIT: 10,
      MIN_TO_GRID_SMASH: 10,
      MIN_TEAR_TO_HOOK_AT_FLOOR: 10,
      MIN_TO_PLAYER_HIT: 8,
    },
    time: {
      BETWEEN_HIT_DAMAGE: 15,
      BETWEEN_DOUBLE_HIT: 30,
      BETWEEN_GRID_SMASH: 30,
    },
  },
};

function hasAnyPower(ent: Entity) {
  let data = entity.getData(ent);
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

// entity has
function hasPower(ent: Entity, num: number) {
  const pyr = ent.ToPlayer();
  let pData = entity.getData(ent);
  if (pyr !== undefined) {
    return pData.powers[num] !== undefined;
  } else {
    error("hasPower: not configured for non player entities");
  }
}

function usePower(ent: Entity, power: Power) {
  log(`${ent} is using ${power}`);
}

// CALLBACKS

export function initPlayerWithPowers(pyr: EntityPlayer) {
  // Starting values on every player
  // TODO: falta que se carguen si se continúa la run y guardarlos al salir o que tengan valores iniciales ciertos personajes
  const pID = getPlayerIndex(pyr);

  if (playersData[pID] === undefined) {
    playersData[pID] = new playerData();
    log("Player " + pID + " get initial power values.");
  }

  //!! temporal para debug
  mod.togglePlayerDisplay(true);
  mod.setPlayerDisplay((pyr) => {
    return `CC: ${playersData[getPlayerIndex(pyr)]!.controlsChanged}`;
  });
}

// Controls to use the powers
export function blockInputs(
  pyr: EntityPlayer,
  inputHook: InputHook,
  buttonAction: ButtonAction,
): boolean | undefined {
  const pID = getPlayerIndex(pyr);
  let pData = entity.getData(pyr);
  if (inputHook === InputHook.IS_ACTION_TRIGGERED) {
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
  }
  return undefined;
}

export function controlIputs() {
  //!! después hacer con for para los cuatro jugadores
  const pyr = Isaac.GetPlayer();
  const controller = pyr.ControllerIndex;
  let pData = entity.getData(pyr);
  if (isActionTriggered(controller, config.action.CHANGE_MODE)) {
    if (!pData.controlsChanged) {
      pData.controlsChanged = true;
    } else {
      pData.controlsChanged = false;
    }
  }

  if (pData.controlsChanged && hasAnyPower(pyr)) {
    for (let i = 1; i < 4; i++) {
      if (
        isActionPressed(controller, config.powerAction[i]!) &&
        pData.powers[i] !== undefined
      ) {
        // Has a power on this slot
        usePower(pyr, pData.powers[i]!);
      }
    }
  }
}
