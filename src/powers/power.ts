import {
  ButtonAction,
  CollectibleType,
  InputHook,
} from "isaac-typescript-definitions";
import {
  DefaultMap,
  PlayerIndex,
  addCollectible,
  defaultMapGetHash,
  defaultMapGetPlayer,
  getPlayerIndex,
  getPlayers,
  isActionPressed,
  isActionTriggered,
  log,
} from "isaacscript-common";
import { PlayerData } from "../classes/power/PlayerData";
import { PowerOwnerData } from "../classes/power/PowerOwnerData";
import * as config from "../config";
import { CollectibleTypeCustom } from "../customVariantType/CollectibleTypeCustom";
import * as dbg from "../debug";
import { CollectibleTypeCustomToPower } from "../enums/CollectibleTypeCustomToPower";
import { Power } from "../enums/Power";
import { mod } from "../mod";
import * as allomancyIronSteel from "./allomancyIronSteel";

// SAVE DATA

const v = {
  run: {
    player: new DefaultMap<PlayerIndex, PlayerData>(() => new PlayerData()),
  },
  room: {
    npc: new DefaultMap<PtrHash, PowerOwnerData>(() => new PowerOwnerData()),
  },
};

export function init(): void {
  mod.saveDataManagerRegisterClass(PlayerData, PowerOwnerData);
  mod.saveDataManager("powers", v);
}

export function hasControlsChanged(pyr: EntityPlayer): boolean {
  return defaultMapGetPlayer(v.run.player, pyr).controlsChanged;
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const preconf = {
  ALLOMANCY_BAR_MAX: 2500,
};

// BOOLEAN
export function hasAnyPower(ent: Entity): boolean {
  let data: PowerOwnerData;
  const pyr = ent.ToPlayer();
  if (ent.ToNPC() !== undefined) {
    data = defaultMapGetHash(v.room.npc, ent);
  } else if (pyr !== undefined) {
    data = defaultMapGetPlayer(v.run.player, pyr);
  } else {
    error("Error: entity type not expected.");
  }
  return (
    data.powers[0] !== undefined ||
    data.powers[1] !== undefined ||
    data.powers[2] !== undefined
  );
}

export function hasPower(ent: Entity, power: Power): boolean {
  let data: PowerOwnerData;
  const pyr = ent.ToPlayer();
  if (ent.ToNPC() !== undefined) {
    data = defaultMapGetHash(v.room.npc, ent);
  } else if (pyr !== undefined) {
    data = defaultMapGetPlayer(v.run.player, pyr);
  } else {
    error("Error: entity type not expected.");
  }
  return (
    data.powers[0] === power ||
    data.powers[1] === power ||
    data.powers[2] === power
  );
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
  const data = v.run.player.getAndSetDefault(getPlayerIndex(pyr));
  if (data.mineralBar - quantity >= 0) {
    data.mineralBar -= quantity;
    return true;
  }
  return false;
}

/** Add a power to entityData, later limit player powers. */
export function addPower(ent: Entity, power: Power): void {
  const pyr = ent.ToPlayer();
  let data: PowerOwnerData;
  if (ent.ToNPC() !== undefined) {
    data = defaultMapGetHash(v.room.npc, ent);
  } else if (pyr !== undefined) {
    data = defaultMapGetPlayer(v.run.player, pyr);
  } else {
    error("Error: entity type not expected.");
  }
  data.powers.push(power);
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
  const pData = defaultMapGetPlayer(v.run.player, pyr);
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
  for (const pyr of getPlayers(true)) {
    const controller = pyr.ControllerIndex;
    const pData = defaultMapGetPlayer(v.run.player, pyr);
    dbg.setVariable("Control", pData.controlsChanged, pyr);

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
          const powerAction = config.powerAction[j];
          const power = pData.powers[j];
          if (powerAction !== undefined && pData.powers[j] !== undefined) {
            if (
              isActionPressed(controller, powerAction) &&
              power !== undefined
            ) {
              // Has a power on this slot.
              usePower(pyr, power, false);
            } else {
              // Is not pressing any button.
              allomancyIronSteel.deselectAllEntities(pyr);
            }
            if (
              isActionTriggered(controller, powerAction) &&
              power !== undefined
            ) {
              // Has a power on this slot.
              usePower(pyr, power, true);
              dbg.addMessage("Triggered");
            }
          }
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
    const power = CollectibleTypeCustomToPower.get(colType);
    if (power !== undefined) {
      addPower(pyr, power);
    } else {
      error("Trying to add a not implemented power.");
    }
  }
}
