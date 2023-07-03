import { ButtonAction, EntityType } from "isaac-typescript-definitions";
import {
  DefaultMap,
  VectorOne,
  VectorZero,
  arrayRemoveAll,
  defaultMapGetHash,
  doesVectorHaveLength,
  emptyArray,
  game,
  getEntityFromPtrHash,
  getPlayers,
  isActionTriggered,
  log,
  vectorEquals,
} from "isaacscript-common";
import { EntityData } from "../classes/allomancyIronSteel/EntityData";
import { SelecterData } from "../classes/allomancyIronSteel/SelecterData";
import * as Debug from "../debug";
import * as entity from "../entities/entity";
import { FocusSelection } from "../enums/FocusSelection";
import { Power } from "../enums/Power";
import { mod } from "../mod";
import * as math from "../utils/math";
import * as pos from "../utils/position";
import * as util from "../utils/util";
// import { addPower } from "./power";

export const preconf = {
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
  tracer: {
    MAX_TIME_TO_USE_LAST_SHOT_DIRECTION: 30,
    MAX_RADIUS: 100,
  },
};

// SAVE DATA

const v = {
  room: {
    selecter: new DefaultMap<PtrHash, SelecterData>(() => new SelecterData()),
    entity: new DefaultMap<PtrHash, EntityData>(() => new EntityData()),
  },
};

export function init(): void {
  mod.saveDataManagerRegisterClass(SelecterData, EntityData);
  mod.saveDataManager("allomancyIronSteel", v);
}

export function setLastMetalPiece(ent: Entity, metalPiece: Entity): void {
  defaultMapGetHash(v.room.selecter, ent).lastMetalPiece = metalPiece;
}

export function getLastMetalPiece(ent: Entity): Entity | undefined {
  return defaultMapGetHash(v.room.selecter, ent).lastMetalPiece;
}

/**
 * Use iron or steel allomancy power, it can be used by a player or a npc.
 *
 * @param _ent EntityNPC | EntityPlayer. Entity that use the power.
 * @param _power Iron or Steel power to push or pull.
 * @param _dir Optional. Direction for non player entities.
 */
export function use(_ent: Entity, _power: Power, _dir?: Vector): void {}

export function throwTracer(ent: Entity, dir?: Vector): void {
  const eData = defaultMapGetHash(v.room.entity, ent);
  const sData = defaultMapGetHash(v.room.selecter, ent);

  const pyr = ent.ToPlayer();

  deselectAllEntities(ent);
  eData.gridTouched = false;

  // Select direction
  let direction: Vector;
  if (pyr !== undefined) {
    // !! Comprobar si me pasé con el threeshold para usar el joystick.
    if (doesVectorHaveLength(pyr.GetShootingJoystick(), 0.3)) {
      direction = pyr.GetShootingJoystick();
    } else if (
      Isaac.GetFrameCount() - sData.lastShot.frame <=
      preconf.tracer.MAX_TIME_TO_USE_LAST_SHOT_DIRECTION
    ) {
      direction = sData.lastShot.direction;
    } else if (!vectorEquals(pyr.GetMovementInput(), VectorZero)) {
      direction = pyr.GetMovementInput();
    } else if (!vectorEquals(sData.lastShot.direction, VectorZero)) {
      direction = sData.lastShot.direction;
    } else {
      direction = VectorOne;
    }
  } else if (dir !== undefined) {
    direction = dir.Normalized();
  } else {
    direction = VectorOne;
  }

  // Throw tracer
  let pointer = ent.Position;
  let someSelect = false;

  while (!pos.isWall(pointer)) {
    // Select entities
    const foundEntities = Isaac.FindInRadius(
      pointer,
      math.upperBound(
        5 + ent.Position.Distance(pointer) / 4,
        preconf.tracer.MAX_RADIUS,
      ),
      undefined,
    );
    if (foundEntities.length > 0) {
      for (const sEntity of foundEntities) {
        const sTear = sEntity.ToTear();

        if (
          entity.isMetalic(sEntity) &&
          !sData.selectedEntities.includes(GetPtrHash(sEntity))
        ) {
          // Ensure focus selection
          if (sData.focusSelection === FocusSelection.BASE) {
            // Select any entity, if tear or enemy focus on it.
            if (sTear !== undefined) {
              // If find a enemy focus it deselecting other entities.
              if (sTear.StickTarget !== undefined) {
                focusEnemy(sTear, ent);
              } else {
                focusTears(ent);
              }
            }
            selectEntity(ent, sEntity);
            someSelect = true;
          } else if (
            sData.focusSelection === FocusSelection.JUST_ENEMIES &&
            sTear !== undefined &&
            sTear.StickTarget !== undefined
          ) {
            // Just select enemies
            selectEntity(ent, sEntity);
            someSelect = true;
          } else if (
            sData.focusSelection === FocusSelection.TEAR_OR_ENEMIES &&
            sEntity.Type === EntityType.TEAR
          ) {
            // Select tears (can focus enemies).
            if (sTear !== undefined && sTear.StickTarget !== undefined) {
              focusEnemy(sTear, ent);
            }
            selectEntity(ent, sEntity);
            someSelect = true;
          }
        }
      }
    }
    // Move pointer
    pointer = pointer.add(direction.mul(5));
  }

  // Not selected any entity.
  if (!someSelect) {
    // !! No está la gestión de la interacción con ludovico y mom's knife If not selected any
    // select.
    if (sData.lastMetalPiece !== undefined && sData.lastMetalPiece.Exists()) {
      selectEntity(ent, sData.lastMetalPiece);
    }
  }
}

export function roomEnter(): void {
  for (const pyr of getPlayers(true)) {
    deselectAllEntities(pyr);
  }
}
// SELECTION

export function deselectAllEntities(fromEnt: Entity): void {
  const data = defaultMapGetHash(v.room.selecter, fromEnt);
  if (data.selectedEntities.length > 0) {
    for (const sEntityPtr of data.selectedEntities) {
      const sEntity = getEntityFromPtrHash(sEntityPtr);
      if (sEntity !== undefined) {
        defaultMapGetHash(v.room.entity, sEntity).selected.is = false;
      }
    }

    emptyArray(data.selectedEntities);
    data.focusSelection = FocusSelection.BASE;
  }
}

export function deselectEntity(sEnt: Entity | PtrHash): void {
  let baseEnt: Entity | undefined;
  let basePtr: PtrHash | undefined;

  if (util.isType<Entity>(sEnt)) {
    baseEnt = sEnt;
    basePtr = GetPtrHash(sEnt);
  } else if (getEntityFromPtrHash(sEnt) !== undefined) {
    baseEnt = getEntityFromPtrHash(sEnt);
    basePtr = sEnt;
  } else {
    log("deslectEntity: entity to deselect not exists");
  }

  if (baseEnt !== undefined && basePtr !== undefined) {
    const data = defaultMapGetHash(v.room.entity, baseEnt);
    if (data.selected.from !== undefined) {
      const selEntities = defaultMapGetHash(
        v.room.selecter,
        data.selected.from,
      ).selectedEntities;

      if (selEntities.includes(basePtr)) {
        data.selected.is = false;
        arrayRemoveAll(selEntities, basePtr);
      }
    }
  }
}

export function selectEntity(fromEnt: Entity, ent: Entity): void {
  const fData = defaultMapGetHash(v.room.selecter, fromEnt);
  const eData = defaultMapGetHash(v.room.entity, ent);
  eData.selected.from = fromEnt;
  eData.selected.is = true;
  eData.gridTouched = false;
  fData.selectedEntities.push(GetPtrHash(ent));
  Debug.setVariable("Seleccionado", true, ent);
}

/**
 * Pass a selected state from a entity to another one.
 *
 * @param selectedEntity Entity that need to be selected.
 * @param toSelectEntity Entity that will be selected.
 * @returns If it was possible to pass the selected state.
 */
export function passSelection(
  selectedEntity: Entity,
  toSelectEntity: Entity,
): boolean {
  const sData = defaultMapGetHash(v.room.entity, selectedEntity);
  if (sData.selected.is && sData.selected.from !== undefined) {
    selectEntity(sData.selected.from, toSelectEntity);
    return true;
  }
  return false;
}

export function isSelected(ent: Entity): boolean {
  return defaultMapGetHash(v.room.entity, ent).selected.is;
}

// FOCUS

function focusEnemy(sEnt: EntityTear, fromEnt: Entity) {
  const data = defaultMapGetHash(v.room.selecter, fromEnt);
  if (sEnt.StickTarget !== undefined) {
    defaultMapGetHash(v.room.entity, sEnt.StickTarget).gridTouched = false;
  }

  data.focusSelection = FocusSelection.JUST_ENEMIES;
  // Deselect every non enemy entity.
  for (const selHash of data.selectedEntities) {
    const selEntity = getEntityFromPtrHash(selHash);
    if (selEntity !== undefined) {
      if (!(selEntity.ToTear()?.StickTarget !== undefined)) {
        deselectEntity(selEntity);
      }
    } else {
      arrayRemoveAll(data.selectedEntities, selHash);
    }
  }
}

function focusTears(fromEnt: Entity) {
  const data = defaultMapGetHash(v.room.selecter, fromEnt);
  data.focusSelection = FocusSelection.TEAR_OR_ENEMIES;
  // Deselect every non tear entity.
  for (const selHash of data.selectedEntities) {
    const selEntity = getEntityFromPtrHash(selHash);
    if (selEntity !== undefined) {
      if (!(selEntity.ToTear() !== undefined)) {
        deselectEntity(selEntity);
      }
    } else {
      arrayRemoveAll(data.selectedEntities, selHash);
    }
  }
}

// CALLBACKS

/** POST_GRID_ENTITY_COLLISION (player). */
export function touchGrid(_grEntity: GridEntity, ent: Entity): void {
  const pyr = ent.ToPlayer();
  if (pyr !== undefined) {
    const eData = defaultMapGetHash(v.room.entity, pyr);
    eData.gridTouched = true;
  }

  // !! Falta ver cómo se pone a false el grid touched.
}

export function checkLastShotDirection(): void {
  for (const pyr of getPlayers(true)) {
    const controller = pyr.ControllerIndex;
    const pData = defaultMapGetHash(v.room.selecter, pyr);

    // Players that have any power. Get last direction shoot and that frame.
    if (
      isActionTriggered(
        controller,
        ButtonAction.SHOOT_LEFT,
        ButtonAction.SHOOT_RIGHT,
        ButtonAction.SHOOT_UP,
        ButtonAction.SHOOT_DOWN,
      )
    ) {
      pData.lastShot.frame = game.GetFrameCount();
      if (vectorEquals(VectorZero, pyr.GetShootingInput())) {
        pData.lastShot.direction = pyr.GetShootingInput();
      }
    }
  }
}
