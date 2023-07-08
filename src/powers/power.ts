import {
  ButtonAction,
  CollectibleType,
  InputHook,
} from "isaac-typescript-definitions";
import {
  DefaultMap,
  VectorZero,
  defaultMapGetHash,
  defaultMapGetPlayer,
  getPlayerIndex,
  getPlayers,
  isActionPressed,
  isActionTriggered,
} from "isaacscript-common";
import { PowerOwnerData } from "../classes/power/PowerOwnerData";
import * as config from "../config";
import * as dbg from "../debug";
import { collectibleTypeCustomToPower } from "../enums/CollectibleTypeCustomToPower";
import { Power } from "../enums/Power";
import { PowerUseType } from "../enums/PowerUseType";
import { g } from "../global";
import { mod } from "../mod";
import * as allomancyIronSteel from "./allomancyIronSteel";

const preconf = {
  ALLOMANCY_BAR_MAX: 2500,
  ui: {
    pos: {
      STOMACH: [
        Vector(0.27, 0.054),
        Vector(0.853, 0.054),
        Vector(0.208, 0.924),
        Vector(0.853, 0.924),
      ],
      SYMBOLS: [
        Vector(0.31, 0.032),
        Vector(0.838, 0.09),
        Vector(0.194, 0.96),
        Vector(0.838, 0.96),
      ],
    },
    ref: {
      BUTTON_ANM: "gfx/ui/ui_button_allomancy_icons.anm2",
      SYMBOL_ANM: "gfx/ui/ui_allomancy_icons.anm2",
      STOMACH_ANM: "gfx/ui/ui_stomach.anm2",
    },
  },
};

// SAVE DATA

const v = {
  room: {
    npc: new DefaultMap<PtrHash, PowerOwnerData>(() => new PowerOwnerData()),
  },
};

export function init(): void {
  mod.saveDataManagerRegisterClass(PowerOwnerData);
  mod.saveDataManager("powers", v);
}

// BOOLEAN POWER
export function hasAnyPower(ent: Entity): boolean {
  let data: PowerOwnerData;
  const pyr = ent.ToPlayer();
  if (ent.ToNPC() !== undefined) {
    data = defaultMapGetHash(v.room.npc, ent);
  } else if (pyr !== undefined) {
    data = defaultMapGetPlayer(g.run.player, pyr);
  } else {
    error("Error: entity type not expected.");
  }
  return data.powers.length > 0;
}

export function hasPower(ent: Entity, power: Power): boolean {
  let data: PowerOwnerData;
  const pyr = ent.ToPlayer();
  if (ent.ToNPC() !== undefined) {
    data = defaultMapGetHash(v.room.npc, ent);
  } else if (pyr !== undefined) {
    data = defaultMapGetPlayer(g.run.player, pyr);
  } else {
    error("Error: entity type not expected.");
  }
  return data.powers.includes(power);
}

// ACTIVE POWER

/**
 * Use any active power.
 *
 * @param ent Entity that uses the power, it can be a player, npc or any other powerOwnerEntity
 *            (Entity that has powerOwnerData).
 * @param power Power from Power enum that is used.
 * @param once Determines if use once's power activation (from isActionTriggered for example) or a
 *             continue activation (like isActionPressed), some powers needs both options to be used
 *             and others just need one of them.
 * @param use
 */
function usePower(ent: Entity, power: Power, use?: PowerUseType) {
  let data: PowerOwnerData;
  const pyr = ent.ToPlayer();
  if (ent.ToNPC() !== undefined) {
    data = defaultMapGetHash(v.room.npc, ent);
  } else if (pyr !== undefined) {
    data = defaultMapGetPlayer(g.run.player, pyr);
  } else {
    error("Error: entity type not expected.");
  }

  // Set power on use.
  if (use === PowerUseType.END) {
    data.usingPower = undefined;
  } else {
    data.usingPower = power;
  }

  if (power === Power.AL_IRON || power === Power.AL_STEEL) {
    allomancyIronSteel.usePower(ent, power, use);
  }
}

/** Add a power to entityData, later limit player powers. */
function addPower(ent: Entity, power: Power) {
  const pyr = ent.ToPlayer();
  if (ent.ToNPC() !== undefined) {
    const data = defaultMapGetHash(v.room.npc, ent);
    data.powers.push(power);
  } else if (pyr !== undefined) {
    const data = defaultMapGetPlayer(g.run.player, pyr);
    if (data.powers.length < 1) {
      data.mineralBar = preconf.ALLOMANCY_BAR_MAX;
    }
    data.powers.push(power);
    data.isHemalurgyPower[data.powers.length - 1] = false;

    // Special things to do at add certain powers.
    if (power === Power.AL_STEEL || power === Power.AL_IRON) {
      data.hasMetalPieceTears = true;
    }
  } else {
    error("Error: entity type not expected.");
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
  const data = g.run.player.getAndSetDefault(getPlayerIndex(pyr));
  if (data.mineralBar - quantity >= 0) {
    data.mineralBar -= quantity;
    return true;
  }
  return false;
}

// UI
export function renderUI(): void {
  for (let i = 0; i < getPlayers().length; i++) {
    const pyr = Isaac.GetPlayer(i);
    const pData = defaultMapGetPlayer(g.run.player, pyr);
    if (pData.powers.length > 0) {
      const symbolIcon = Sprite();
      symbolIcon.Load(preconf.ui.ref.SYMBOL_ANM, true);

      const buttonIcon = Sprite();
      buttonIcon.Load(preconf.ui.ref.BUTTON_ANM, true);

      const stomachIcon = Sprite();
      stomachIcon.Load(preconf.ui.ref.STOMACH_ANM, true);

      // Stomach icon.
      const stomachFrame = Math.round(
        pData.mineralBar / (preconf.ALLOMANCY_BAR_MAX / 17),
      );

      if (isUsingPower(pyr)) {
        stomachIcon.Play("Burning", false);
      } else {
        stomachIcon.Play("Idle", false);
      }
      stomachIcon.SetFrame(stomachFrame);

      // ControlsChanged active.
      let opacity: number;
      if (!pData.controlsChanged) {
        opacity = 0.3;
      } else {
        opacity = 1;
      }
      symbolIcon.Color = Color(
        symbolIcon.Color.R,
        symbolIcon.Color.G,
        symbolIcon.Color.B,
        opacity,
      );
      stomachIcon.Color = Color(
        stomachIcon.Color.R,
        stomachIcon.Color.G,
        stomachIcon.Color.B,
        opacity,
      );
      buttonIcon.Color = Color(
        buttonIcon.Color.R,
        buttonIcon.Color.G,
        buttonIcon.Color.B,
        opacity,
      );

      if (i !== 0) {
        const scale = 0.5;
        stomachIcon.Scale = Vector(scale, scale);
        buttonIcon.Scale = Vector(scale, scale);
        symbolIcon.Scale = Vector(scale, scale);
      }

      stomachIcon.Render(
        percToPos(preconf.ui.pos.STOMACH[i]),
        VectorZero,
        VectorZero,
      );

      let div = 1;
      if (i !== 0) {
        div = 2;
      }

      for (let j = 0; j < pData.powers.length; j++) {
        let name = "";
        let offset = 0;
        switch (j) {
          case 0: {
            name = "LT";
            offset = 0;
            break;
          }
          case 1: {
            name = "RB";
            offset = 15;
            break;
          }
          case 2: {
            name = "LB";
            offset = 30;
            break;
          }
        }
        buttonIcon.Play(name, true);
        buttonIcon.Render(
          percToPos(preconf.ui.pos.SYMBOLS[i]).add(
            Vector(offset / div, 15 / div),
          ),
          Vector(0, 0),
          Vector(0, 0),
        );

        if (pData.isHemalurgyPower[j] ?? false) {
          symbolIcon.Play("hemalurgy", true);
        } else {
          symbolIcon.Play("usual", true);
        }

        symbolIcon.SetFrame(pData.powers[j] as number);
        symbolIcon.Render(
          percToPos(preconf.ui.pos.SYMBOLS[i]).add(Vector(offset / div, 0)),
          Vector(0, 0),
          Vector(0, 0),
        );
      }
    }
  }
}

function percToPos(vectPercentage: Vector | undefined) {
  if (vectPercentage !== undefined) {
    const screen = Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight());
    // !! Ver al final si quiero o no offset.
    const offset = Vector(1.7777778 * (0 / 40), 0 / 40);
    const mulOffset = Vector(
      vectPercentage.X < 0.5 ? 1 : -1,
      vectPercentage.Y < 0.5 ? 1 : -1,
    );

    return vectPercentage.add(offset.mul(mulOffset)).mul(screen);
  }
  error("Vector to get percentage is undefined");
}

// CALLBACKS

/** Callback: postInitPlayer. */
export function initPlayerWithPowers(_pyr: EntityPlayer): void {}

/** CallbackCustom: inputActionPlayer. Block controls when is changed mode. */
export function blockInputs(
  pyr: EntityPlayer,
  _inputHook: InputHook,
  buttonAction: ButtonAction,
): boolean | undefined {
  const pData = defaultMapGetPlayer(g.run.player, pyr);
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
    const pData = defaultMapGetPlayer(g.run.player, pyr);
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
          if (powerAction !== undefined && power !== undefined) {
            if (isActionPressed(controller, powerAction)) {
              // Has a power on this slot.
              usePower(pyr, power, PowerUseType.CONTINUOUS);
            } else {
              // Is not pressing any button.
              usePower(pyr, power, PowerUseType.END);
            }
            if (isActionTriggered(controller, powerAction)) {
              // Has a power on this slot.
              usePower(pyr, power, PowerUseType.ONCE);
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
  if (collectibleTypeCustomToPower.has(colType)) {
    const power = collectibleTypeCustomToPower.get(colType);
    if (power !== undefined) {
      addPower(pyr, power);
    } else {
      error("Trying to add a not implemented power.");
    }
  }
}

function isUsingPower(pyr: EntityPlayer) {
  const pData = defaultMapGetPlayer(g.run.player, pyr);
  if (
    pData.powers.length > 0 &&
    pData.controlsChanged &&
    pData.mineralBar > 0
  ) {
    for (let i = 0; i < pData.powers.length; i++) {
      const powerAction = config.powerAction[i];
      const power = pData.powers[i];
      if (powerAction !== undefined && power !== undefined) {
        if (isActionTriggered(pyr.ControllerIndex, powerAction)) {
          return true;
        }
      }
      i++;
    }
  }
  return false;
}
