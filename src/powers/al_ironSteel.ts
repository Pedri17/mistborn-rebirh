import { EntityType } from "isaac-typescript-definitions";
import {
  VectorZero,
  doesVectorHaveLength,
  vectorEquals,
} from "isaacscript-common";
import * as entity from "../entities/entity";
import { Power } from "../enums/Power";
import * as math from "../utils/math";
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

function use(power: Power) {}

function throwTracer(ent: Entity, dir?: Vector) {
  let data = entity.getData(ent);

  data.selectedEntities = [];
  data.gridTouched = false;

  // Select direction
  let direction;
  if (ent.ToPlayer() !== undefined) {
    const pyr = ent.ToPlayer()!;
    //!! comprobar si me pasé con el threeshold para usar el joystick
    if (doesVectorHaveLength(pyr.GetShootingJoystick(), 0.3)) {
      direction = pyr.GetShootingJoystick();
    } else if (
      Isaac.GetFrameCount() - data.lastShot.frame <=
      preconf.tracer.MAX_TIME_TO_USE_LAST_SHOT_DIRECTION
    ) {
      direction = data.lastShot.direction;
    } else if (!vectorEquals(pyr.GetMovementInput(), VectorZero)) {
      direction = pyr.GetMovementInput();
    } else if (!vectorEquals(data.lastShot.direction, VectorZero)) {
      direction = data.lastShot.direction;
    } else {
      direction = VectorZero;
    }
  } else if (dir !== undefined) {
    direction = dir.Normalize();
  }

  // Throw tracer
  let pointer = ent.Position;

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
    for(const sEntity of foundEntities){
      if()
    }
  }
}

// CALLBACKS

//POST_GRID_ENTITY_COLLISION (player)
export function touchGrid(grEntity: GridEntity, ent: Entity) {
  const pyr = ent.ToPlayer();
  let pData = entity.getData(ent);

  //!! falta ver cómo se pone a false el grid touched
  pData.gridTouched = true;
}
