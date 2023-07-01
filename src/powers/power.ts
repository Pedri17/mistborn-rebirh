import {
  ButtonAction,
  CollectibleType,
  InputHook,
} from "isaac-typescript-definitions";
import {
  DefaultMap,
  PlayerIndex,
  VectorZero,
  addCollectible,
  game,
  isActionPressed,
  isActionTriggered,
  log,
  vectorEquals,
} from "isaacscript-common";
import * as config from "../config";
import { CollectibleTypeCustom } from "../customVariantType/CollectibleTypeCustom";
import * as dbg from "../debug";
import { CollectibleTypeCustomToPower } from "../enums/CollectibleTypeCustomToPower";
import { Power } from "../enums/Power";
import { getPlayerData, getPowerOwnerData } from "../variables";
import * as allomancyIronSteel from "./allomancyIronSteel";

// SAVE DATA
class PowerOwnerData {
  powers: Power[] = [];
}

class PlayerData extends PowerOwnerData {
  controlsChanged = false;
  mineralBar = 0;
}

let vi = {
  run: {
    playersData: new DefaultMap<PlayerIndex, PlayerData>(
      () => new PlayerData(),
    ),
  },
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const preconf = {
  ALLOMANCY_BAR_MAX: 2500,
};

// BOOLEAN
// TODO: expected to players, change for npcs
export function hasAnyPower(ent: Entity): boolean {
  const data = getPowerOwnerData(ent);
  return (
    data.powers[0] !== undefined ||
    data.powers[1] !== undefined ||
    data.powers[2] !== undefined
  );
}

export function hasPower(ent: Entity, power: Power): boolean {
  const pyr = ent.ToPlayer();
  const pData = getPowerOwnerData(ent);
  if (pyr !== undefined) {
    return (
      pData.powers[0] === power ||
      pData.powers[1] === power ||
      pData.powers[2] === power
    );
  }
  error("hasPower: not configured for non player entities");
}

// ACTIVE

/**
 * Use any active power.
 *
 * @param ent Entity that uses the power, it can be a player, npc or any other powerOwnerEntity
 *            (Entity that has powerOwnerData).
 * @param power Power from Power enum that is used.
 * @param once Determines if use once's power activation (from isActionTriggered for example) or a
 *             continue activation (like isActionPressed), some powers needs both options to be used
 *             and others just need one of them.
 */
function usePower(ent: Entity, power: Power, once?: boolean) {
  if (power === Power.AL_IRON || power === Power.AL_STEEL) {
    if (once === true) {
      allomancyIronSteel.throwTracer(ent);
    } else {
      allomancyIronSteel.use(ent, power);
    }
  }
}

/**
 * Spend minerals bar, expected to be executed 60 times/sec on postRender callback.
 *
 * @param pyr Entity that spend minerals.
 * @param quantity Quantity of minerals wasted per execution (quantity*60 per sec).
 *
 * @returns Boolean if there's enough mineral to waste. In false case there's not mineral change.
 */
// eslint-disable-next-line @typescript-eslint/no-unused-vars
function spendMinerals(pyr: EntityPlayer, quantity: number): boolean {
  const data = getPlayerData(pyr);
  if (data.mineralBar - quantity >= 0) {
    data.mineralBar -= quantity;
    return true;
  }
  return false;
}

/** Add a power to entityData, later limit player powers. */
export function addPower(ent: Entity, power: Power): void {
  log(`${ent} has get ${power} power`);
  getPowerOwnerData(ent).powers.push(power);
}

// CALLBACKS

/** Callback: postInitPlayer. */
export function initPlayerWithPowers(pyr: EntityPlayer): void {
  // Starting values on every player.
  log(`ID: ${CollectibleTypeCustom.steelAllomancy}`);
  addCollectible(pyr, CollectibleTypeCustom.steelAllomancy);
  addCollectible(pyr, CollectibleTypeCustom.ironAllomancy);
  pyr.AddCoins(5);
}

/** CallbackCustom: inputActionPlayer. Block controls when is changed mode. */
export function blockInputs(
  pyr: EntityPlayer,
  _inputHook: InputHook,
  buttonAction: ButtonAction,
): boolean | undefined {
  const pData = getPlayerData(pyr);
  // block buttons
  if (pData.controlsChanged) {
    if (
      buttonAction === config.powerAction[0] ||
      buttonAction === config.powerAction[1] ||
      buttonAction === config.powerAction[2]
    ) {
      return false;
    }
  }
  return undefined;
}

/** Callback: postRender. Controls to use the powers. It is executed 60 times per second. */
export function controlIputs(): void {
  for (let i = 0; i < game.GetNumPlayers(); i++) {
    const pyr = Isaac.GetPlayer(i);
    const controller = pyr.ControllerIndex;
    const pData = getPlayerData(pyr);
    dbg.setVariable("Piquete", pData.controlsChanged, pyr);

    // Players that have any power.
    if (hasAnyPower(pyr)) {
      if (isActionTriggered(controller, config.action.CHANGE_MODE)) {
        if (!pData.controlsChanged) {
          pData.controlsChanged = true;
        } else {
          pData.controlsChanged = false;
        }
      }

      if (pData.controlsChanged) {
        for (let j = 0; j < 3; j++) {
          if (
            config.powerAction[j] !== undefined &&
            pData.powers[j] !== undefined
          ) {
            if (
              isActionPressed(controller, config.powerAction[j]!) &&
              pData.powers[j] !== undefined
            ) {
              // Has a power on this slot.
              usePower(pyr, pData.powers[j]!, false);
            } else {
              // Is not pressing any button.
              allomancyIronSteel.deselectAllEntities(pyr);
            }
            if (
              isActionTriggered(controller, config.powerAction[j]!) &&
              pData.powers[i] !== undefined
            ) {
              // Has a power on this slot.
              usePower(pyr, pData.powers[i]!, true);
              dbg.addMessage("Triggered");
            }
          }
        }
      }

      // Get last direction shoot and that frame.
      if (
        isActionTriggered(
          controller,
          ButtonAction.SHOOT_LEFT,
          ButtonAction.SHOOT_RIGHT,
          ButtonAction.SHOOT_UP,
          ButtonAction.SHOOT_DOWN,
        )
        // isMoveActionTriggered(controller)
      ) {
        pData.lastShot.frame = Isaac.GetFrameCount();
        if (vectorEquals(VectorZero, pyr.GetShootingInput())) {
          pData.lastShot.direction = pyr.GetShootingInput();
        }
      }
    }
  }
}

/** CallbackCustom: postPlayerCollectibleAdded */
export function getCollectiblePower(
  pyr: EntityPlayer,
  colType: CollectibleType,
): void {
  if (CollectibleTypeCustomToPower.has(colType)) {
    addPower(pyr, CollectibleTypeCustomToPower.get(colType)!);
  }
}
