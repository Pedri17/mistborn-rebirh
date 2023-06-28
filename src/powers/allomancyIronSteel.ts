import { EntityType } from "isaac-typescript-definitions";
import {
  VectorOne,
  VectorZero,
  arrayRemoveAll,
  doesVectorHaveLength,
  emptyArray,
  getEntityFromPtrHash,
  log,
  vectorEquals,
} from "isaacscript-common";
import * as Debug from "../debug";
import * as entity from "../entities/entity";
import { FocusSelection } from "../enums/FocusSelection";
import { Power } from "../enums/Power";
import * as math from "../utils/math";
import * as pos from "../utils/position";
import * as util from "../utils/util";

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
  tracer: {
    MAX_TIME_TO_USE_LAST_SHOT_DIRECTION: 30,
    MAX_RADIUS: 100,
  },
};

export function use(ent: Entity, power: Power, dir?: Vector) {
  //log("using power");
}

export function throwTracer(ent: Entity, dir?: Vector) {
  let data = entity.getSelecterData(ent);

  deselectAllEntities(ent);
  data.gridTouched = false;

  // Select direction
  let direction: Vector;
  if (ent.ToPlayer() !== undefined) {
    const pyr = ent.ToPlayer()!;
    let pData = entity.getPlayerData(ent);
    //!! comprobar si me pasé con el threeshold para usar el joystick
    if (doesVectorHaveLength(pyr.GetShootingJoystick(), 0.3)) {
      direction = pyr.GetShootingJoystick();
      log(`pilla el joystick ${pyr.GetShootingJoystick()}`);
    } else if (
      Isaac.GetFrameCount() - pData.lastShot.frame <=
      preconf.tracer.MAX_TIME_TO_USE_LAST_SHOT_DIRECTION
    ) {
      direction = pData.lastShot.direction;
    } else if (!vectorEquals(pyr.GetMovementInput(), VectorZero)) {
      direction = pyr.GetMovementInput();
    } else if (!vectorEquals(pData.lastShot.direction, VectorZero)) {
      direction = pData.lastShot.direction;
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
    let foundEntities = Isaac.FindInRadius(
      pointer,
      math.upperBound(
        5 + ent.Position.Distance(pointer) / 4,
        preconf.tracer.MAX_RADIUS,
      ),
      undefined,
    );
    if (foundEntities.length > 0) {
      for (const sEntity of foundEntities) {
        if (
          entity.isMetalic(sEntity) &&
          !data.selectedEntities.includes(GetPtrHash(sEntity))
        ) {
          log(`Se encontro la entidad metalica ${sEntity}`);
          // Ensure focus selection
          if (data.focusSelection === FocusSelection.BASE) {
            // Select any entity, if tear or enemy focus on it
            if (sEntity.Type === EntityType.TEAR) {
              // If find a enemy focus it deselecting other entities
              if (sEntity.ToTear()!.StickTarget !== undefined) {
                focusEnemy(sEntity.ToTear()!, ent);
              } else {
                focusTear(sEntity.ToTear()!, ent);
              }
            }
            selectEntity(ent, sEntity);
            someSelect = true;
          } else if (
            data.focusSelection == FocusSelection.JUST_ENEMIES &&
            sEntity.Type === EntityType.TEAR &&
            sEntity.ToTear()!.StickTarget !== undefined
          ) {
            // Just select enemies
            selectEntity(ent, sEntity);
            someSelect = true;
          } else if (
            data.focusSelection === FocusSelection.TEAR_OR_ENEMIES &&
            sEntity.Type === EntityType.TEAR
          ) {
            // Select tears (can focus enemies)
            if (sEntity.ToTear()!.StickTarget !== undefined) {
              focusEnemy(sEntity.ToTear()!, ent);
            }
            selectEntity(ent, sEntity);
            someSelect = true;
          }
        }
      }
    }
    //Move pointer
    pointer = pointer.add(direction.mul(5));
  }

  // Not selected any entity
  if (!someSelect) {
    // !! No está la gestión de la interacción con ludovico y mom's knife
    // If not selected any select this entity
    if (entity.isExisting(data.lastCoin)) {
      selectEntity(ent, data.lastCoin!);
    }
  }
}

// SELECTION

function deselectAllEntities(fromEnt: Entity) {
  let data = entity.getSelecterData(fromEnt);
  if (data.selectedEntities.length > 0) {
    for (const sEntityPtr of data.selectedEntities) {
      let sEntity = getEntityFromPtrHash(sEntityPtr);
      if (sEntity !== undefined) {
        entity.getData(sEntity).isSelected = false;
      }
    }

    emptyArray(data.selectedEntities);
    data.focusSelection = FocusSelection.BASE;
  }
}

function deselectEntity(sEnt: Entity | PtrHash) {
  let baseEnt: Entity | undefined = undefined;
  let basePtr: PtrHash | undefined = undefined;

  if (util.isType<Entity>(sEnt)) {
    baseEnt = sEnt;
    basePtr = GetPtrHash(sEnt);
  } else if (getEntityFromPtrHash(sEnt) !== undefined) {
    baseEnt = getEntityFromPtrHash(sEnt)!;
    basePtr = sEnt;
  } else {
    log("deslectEntity: entity to deselect not exists");
  }

  if (baseEnt !== undefined && basePtr !== undefined) {
    let data = entity.getData(baseEnt);
    if (
      data.fromSelected !== undefined &&
      getEntityFromPtrHash(data.fromSelected) !== undefined
    ) {
      const selEntities = entity.getSelecterData(
        getEntityFromPtrHash(data.fromSelected)!,
      ).selectedEntities;

      if (selEntities.includes(basePtr)) {
        data.isSelected = false;
        arrayRemoveAll(selEntities, basePtr);
      }
    }
  }
}

function selectEntity(fromEnt: Entity, ent: Entity) {
  let data = entity.getData(ent);
  let fData = entity.getSelecterData(fromEnt);
  data.fromSelected = GetPtrHash(fromEnt);
  data.isSelected = true;
  data.gridTouched = false;
  fData.selectedEntities.push(GetPtrHash(ent));
  Debug.addMessage("Seleccionado", ent);
}

// FOCUS

function focusEnemy(sEnt: EntityTear, fromEnt: Entity) {
  let data = entity.getSelecterData(fromEnt);
  entity.getData(sEnt.StickTarget).gridTouched = false;
  data.focusSelection = FocusSelection.JUST_ENEMIES;
  // Deselect every non enemy entity
  for (const selHash of data.selectedEntities) {
    const selEntity = getEntityFromPtrHash(selHash);
    if (selEntity !== undefined) {
      if (
        !(
          selEntity.ToTear() !== undefined &&
          selEntity.ToTear()!.StickTarget !== undefined
        )
      ) {
        deselectEntity(selEntity);
      }
    } else {
      arrayRemoveAll(data.selectedEntities, selHash);
    }
  }
}

function focusTear(sEnt: EntityTear, fromEnt: Entity) {
  let data = entity.getSelecterData(fromEnt);
  data.focusSelection = FocusSelection.TEAR_OR_ENEMIES;
  // Deselect every non tear entity
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

//POST_GRID_ENTITY_COLLISION (player)
// !! ver si era también para npcs
export function touchGrid(grEntity: GridEntity, ent: Entity) {
  const pyr = ent.ToPlayer();
  let pData = entity.getPlayerData(ent);

  //!! falta ver cómo se pone a false el grid touched
  pData.gridTouched = true;
}
