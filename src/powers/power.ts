import {
  ButtonAction,
  CollectibleType,
  InputHook,
  ModCallback,
} from "isaac-typescript-definitions";
import {
  Callback,
  CallbackCustom,
  DefaultMap,
  ModCallbackCustom,
  ModFeature,
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
import { CollectibleTypeCustom } from "../customVariantType/CollectibleTypeCustom";
import { collectibleTypeCustomToPower } from "../enums/CollectibleTypeCustomToPower";
import { Power } from "../enums/Power";
import { PowerUseType } from "../enums/PowerUseType";
import { g } from "../global";
import * as allomancyIronSteel from "./allomancyIronSteel";

const preconf = {
  ALLOMANCY_BAR_MAX: 5000,
  mineralWaste: new Map<Power, Map<PowerUseType, number>>([
    [
      Power.AL_STEEL,
      new Map<PowerUseType, number>([[PowerUseType.CONTINUOUS, 5]]),
    ],
    [
      Power.AL_IRON,
      new Map<PowerUseType, number>([[PowerUseType.CONTINUOUS, 5]]),
    ],
  ]),
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

// BOOLEAN POWER RELATED
/**
 * Check if a entity has a metallic power.
 *
 * @param ent Entity that have the power, it can be a player, npc or any other powerOwnerEntity
 *            (Entity that has powerOwnerData).
 * @returns boolean.
 */
function hasAnyPower(ent: Entity): boolean {
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

/**
 * Check if a entity has a specific metallic power.
 *
 * @param ent Entity that have the power, it can be a player, npc or any other powerOwnerEntity
 *            (Entity that has powerOwnerData).
 * @param power Power that has this entity.
 * @returns boolean.
 */
function hasPower(ent: Entity, power: Power): boolean {
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
 * Use a active power.
 *
 * @param ent Entity that uses the power, it can be a player, npc or any other powerOwnerEntity
 *            (Entity that has powerOwnerData).
 * @param power Power from Power enum that is used.
 * @param use PowerUseType. Determines type of power use, it can be ONCE, CONTINUOUS and END and
 *            determines the moment of the press.
 */
function usePower(ent: Entity, power: Power, use: PowerUseType) {
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

  let isUsingPower = false;

  if (power === Power.AL_IRON || power === Power.AL_STEEL) {
    isUsingPower = allomancyIronSteel.usePower(ent, power, use);
  }

  if (isUsingPower) {
    if (pyr !== undefined) spendMinerals(pyr, power, use);
    if (use !== PowerUseType.END) data.usingPower = power;
  }

  if (use === PowerUseType.END) data.usingPower = undefined;
}

/**
 * Adds a power to the entity.
 *
 * @param ent Entity that will have the power, it can be a player, npc or any other powerOwnerEntity
 *            (Entity that has powerOwnerData).
 * @param power Power from Power enum that is added.
 */
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
function spendMinerals(
  pyr: EntityPlayer,
  power: Power,
  useType: PowerUseType,
): boolean {
  const data = g.run.player.getAndSetDefault(getPlayerIndex(pyr));
  const waste = preconf.mineralWaste.get(power)?.get(useType);
  if (waste !== undefined && data.mineralBar - waste >= 0) {
    data.mineralBar -= waste;
    return true;
  }
  return false;
}

// HELPER FUNCTIONS
/**
 * Returns on screen position vector from a percentage vector.
 *
 * @param vectPercentage Vector (0-1,0-1).
 * @returns screen position vector.
 */
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
export class Powers extends ModFeature {
  v = v;

  /** Renders the UI. */
  @Callback(ModCallback.POST_RENDER)
  renderUI(): void {
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

        if (pData.usingPower !== undefined) {
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
        let newColor = Color(
          symbolIcon.Color.R,
          symbolIcon.Color.G,
          symbolIcon.Color.B,
          opacity,
        );

        symbolIcon.Color = newColor;
        stomachIcon.Color = newColor;
        buttonIcon.Color = newColor;

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

  /** Controls to use the powers. It is executed 60 times per second. */
  @Callback(ModCallback.POST_RENDER)
  controlIputs(): void {
    for (const pyr of getPlayers(true)) {
      const controller = pyr.ControllerIndex;
      const pData = defaultMapGetPlayer(g.run.player, pyr);

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
              if (isActionTriggered(controller, powerAction)) {
                // Has a power on this slot.
                usePower(pyr, power, PowerUseType.ONCE);
              }

              if (isActionPressed(controller, powerAction)) {
                // Has a power on this slot.
                usePower(pyr, power, PowerUseType.CONTINUOUS);
                pData.unpressingPowerTimes = 0;
              } else if (pData.usingPower !== undefined) {
                pData.unpressingPowerTimes++;
              }

              if (
                pData.usingPower !== undefined &&
                pData.unpressingPowerTimes >= 6
              ) {
                usePower(pyr, power, PowerUseType.END);
              }
            }
          }
        }
      }
    }
  }

  /** Blocks controls when is changed mode. */
  @CallbackCustom(
    ModCallbackCustom.INPUT_ACTION_PLAYER,
    undefined,
    undefined,
    InputHook.IS_ACTION_TRIGGERED,
    undefined,
  )
  blockInputs(
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

  /** It add a power when the player takes a collectible */
  @CallbackCustom(ModCallbackCustom.POST_PLAYER_COLLECTIBLE_ADDED)
  getCollectiblePower(pyr: EntityPlayer, colType: CollectibleType): void {
    if (
      colType == CollectibleTypeCustom.ironAllomancy ||
      CollectibleTypeCustom.steelAllomancy
    ) {
      if (collectibleTypeCustomToPower.has(colType)) {
        const power = collectibleTypeCustomToPower.get(colType);
        if (power !== undefined) {
          addPower(pyr, power);
        } else {
          error("Trying to add a not implemented power.");
        }
      }
    }
  }
}
