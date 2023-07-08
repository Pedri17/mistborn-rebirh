import {
  ButtonAction,
  Direction,
  EntityType,
} from "isaac-typescript-definitions";
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
  vectorToDirection,
} from "isaacscript-common";
import { EntityData } from "../classes/allomancyIronSteel/EntityData";
import { SelecterData } from "../classes/allomancyIronSteel/SelecterData";
import { BulletVariantCustom } from "../customVariantType/BulletVariantCustom";
import * as Debug from "../debug";
import * as entity from "../entities/entity";
import * as metalPiece from "../entities/metalPiece";
import { FocusSelection } from "../enums/FocusSelection";
import { Power } from "../enums/Power";
import { PowerUseType } from "../enums/PowerUseType";
import { mod } from "../mod";
import * as pos from "../utils/position";

const preconf = {
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

// ACTIVE POWER.

export function usePower(ent: Entity, power: Power, use?: PowerUseType): void {
  if (power === Power.AL_IRON || power === Power.AL_STEEL) {
    switch (use) {
      case PowerUseType.ONCE: {
        throwTracer(ent);
        break;
      }
      case PowerUseType.CONTINUOUS: {
        activePower(ent, power);
        break;
      }
      case PowerUseType.END: {
        deselectAllEntities(ent);
        break;
      }
      case undefined: {
        error("PowerUseType undefined");
      }
    }
  }
}

/**
 * Use iron or steel allomancy power, it can be used by a player or a npc.
 *
 * @param _ent EntityNPC | EntityPlayer. Entity that use the power.
 * @param ent
 * @param _power Iron or Steel power to push or pull.
 * @param _dir Optional. Direction for non player entities.
 */
function activePower(ent: Entity, _power: Power, _dir?: Vector) {
  const data = defaultMapGetHash(v.room.selecter, ent);
  if (data.selectedEntities.length > 0) {
    for (const selEntPtr of data.selectedEntities) {
      let selEnt = getEntityFromPtrHash(selEntPtr);
      let pushEntity = selEnt;

      // To tear coins.
      const tear = selEnt?.ToTear();
      if (
        tear !== undefined &&
        tear.Variant === BulletVariantCustom.metalPiece
      ) {
        // todo.
      }
    }
  }
}

export function bulletRemove(bullet: EntityTear | EntityProjectile): void {
  const data = defaultMapGetHash(v.room.entity, bullet);
  const coin = metalPiece.getSpawnedCoin(bullet);

  if (bullet.SpawnerEntity !== undefined) {
    const pData = defaultMapGetHash(v.room.selecter, bullet.SpawnerEntity);

    if (coin !== undefined) {
      // If tear coin is selected then select pickup coin.
      if (data.selected.is && data.selected.from !== undefined) {
        selectEntity(data.selected.from, coin);
      }
      // If is the last shot coin then select pickup as it.
      if (!entity.isEqual(bullet, pData.lastMetalPiece)) {
        pData.lastMetalPiece = coin;
      }
    }
  }
}

/** Callback: POST_TEAR_INIT_LATE (metalPiece) */
export function initMetalPieceTear(tear: EntityTear): void {
  const pyr = tear.SpawnerEntity?.ToPlayer();
  if (pyr !== undefined) {
    defaultMapGetHash(v.room.selecter, pyr).lastMetalPiece = tear;
    Debug.addMessage("lastMetalPiece", tear);
  }
}

/** Callback: POST_GRID_ENTITY_COLLISION. Only to: Tear (metalPiece variant) */
export function metalPieceGridCollision(_gEnt: GridEntity, ent: Entity): void {
  const tear = ent.ToTear();
  const projectile = ent.ToProjectile();
  const data = defaultMapGetHash(v.room.entity, ent);
  data.gridTouched = true;
  if (
    (vectorToDirection(ent.Velocity) === Direction.RIGHT ||
      vectorToDirection(ent.Velocity) === Direction.LEFT) &&
    pos.roomPosPerOne(ent.Position).Y < 0.95 &&
    pos.roomPosPerOne(ent.Position).Y > 0.05
  ) {
    if (tear !== undefined) {
      // data = Vector(entity.Position.X,entity.Position.Y+(MR.math.round(entity:ToTear().Height)))
    }
  }
}

/** Callback: POST_GRID_ENTITY_COLLISION. Only to: Player, Allomancer enemy. */
export function selecterGridCollision(_gEnt: GridEntity, ent: Entity): void {
  const data = defaultMapGetHash(v.room.selecter, ent);
  if (data.usingPower === Power.AL_IRON || data.usingPower === Power.AL_STEEL) {
    // !! Ver si es neccesario usar el gridTouched.
    if (doesVectorHaveLength(ent.Velocity, 10)) {
      log(`Velocidad mayor de 10, ${ent.Velocity}`);
      ent.Velocity = ent.Velocity.mul(-0.01);
    }
  }
}

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
      Math.min(
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

export function deselectEntity(sEnt: Entity): void {
  const baseEnt = sEnt;
  const basePtr = GetPtrHash(sEnt);

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

export function selectEntity(fromEnt: Entity, ent: Entity): void {
  const fData = defaultMapGetHash(v.room.selecter, fromEnt);
  const eData = defaultMapGetHash(v.room.entity, ent);
  eData.selected.from = fromEnt;
  eData.selected.is = true;
  eData.gridTouched = false;
  fData.selectedEntities.push(GetPtrHash(ent));
  Debug.setVariable("Seleccionado", true, ent);
}

// FOCUS.

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

// CALLBACKS.

/** Callback: postNewRoomReordered */
export function roomEnter(): void {
  for (const pyr of getPlayers(true)) {
    deselectAllEntities(pyr);
  }
}

/** Callback: postRender */
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
