import {
  CacheFlag,
  EntityCollisionClass,
  EntityType,
  ModCallback,
  ProjectileVariant,
  TearFlag,
  TearVariant,
} from "isaac-typescript-definitions";
import {
  Callback,
  CallbackCustom,
  DefaultMap,
  ModCallbackCustom,
  ModFeature,
  VectorZero,
  addPlayerStat,
  defaultMapGetHash,
  defaultMapGetPlayer,
  game,
  getEntities,
  getPlayers,
  getTearsStat,
  spawn,
  vectorEquals,
} from "isaacscript-common";
import { BulletData } from "../classes/metalPiece/BulletData";
import { PickupData } from "../classes/metalPiece/PickupData";
import { PlayerData } from "../classes/metalPiece/PlayerData";
import { BulletVariantCustom } from "../customVariantType/BulletVariantCustom";
import { MetalPieceSubtype } from "../customVariantType/MetalPieceSubtype";
import { PickupVariantCustom } from "../customVariantType/PickupVariantCustom";
import { g } from "../global";
import { mod } from "../mod";
import * as entity from "../utils/entity";
import * as pos from "../utils/position";
import * as vect from "../utils/vector";

const preconf = {
  STICKED_TIME: 90,
  FRICTION_PICKUP: 0.3,
  COIN_DMG_MULT: 2,
  FIRE_DELAY_MULT: 2,

  velocity: {
    MIN_TEAR_TO_HOOK: 20,
  },

  ref: {
    spriteSheet: {
      metalPieceCoin: [
        "gfx/effects/metalPiece/coin/spritesheet/metalPiece_coin_0.png",
        "gfx/effects/metalPiece/coin/spritesheet/metalPiece_coin_1.png",
        "gfx/effects/metalPiece/coin/spritesheet/metalPiece_coin_2.png",
        "gfx/effects/metalPiece/coin/spritesheet/metalPiece_coin_3.png",
        "gfx/effects/metalPiece/coin/spritesheet/metalPiece_coin_4.png",
        "gfx/effects/metalPiece/coin/spritesheet/metalPiece_coin_5.png",
        "gfx/effects/metalPiece/coin/spritesheet/metalPiece_coin_6.png",
        "gfx/effects/metalPiece/coin/spritesheet/metalPiece_coin_7.png",
      ],
    },
  },
};

// SAVE DATA

const v = {
  level: {
    coinsWasted: 0,
  },
  room: {
    bullet: new DefaultMap<PtrHash, BulletData>(() => new BulletData()),
    pickup: new DefaultMap<PtrHash, PickupData>(() => new PickupData()),
    player: new DefaultMap<PtrHash, PlayerData>(() => new PlayerData()),
  },
};

/** Returns the spawned metal piece pickup from a dead bullet if it is spawned. */
export function getSpawnedMetalPiece(
  fromBullet: EntityTear | EntityProjectile,
): EntityPickup | undefined {
  return defaultMapGetHash(v.room.bullet, fromBullet).spawnedMetalPiece;
}

// GETTERS

/** Returns if a metal piece pickup is a anchorage. */
export function isAnchorage(metalPiece: EntityPickup): PickupData["anchorage"] {
  return defaultMapGetHash(v.room.pickup, metalPiece).anchorage;
}

/** The player takes a coin and reduce tear delay. */
export function takeCoin(this: void, pyr: EntityPlayer): void {
  if (v.level.coinsWasted > 0) {
    pyr.AddCoins(1);
    v.level.coinsWasted--;
    reduceTearDelay(pyr);
  } else {
    error("A coin was taken when there's not any coin wasted.");
  }
}

export function unpinAnchorage(metalPiece: EntityPickup, fromEntity: Entity) {
  metalPiece.Friction = preconf.FRICTION_PICKUP;
  const mpData = defaultMapGetHash(v.room.pickup, metalPiece);
  mpData.anchorage.is = false;
  let animation;

  if (metalPiece.SubType == MetalPieceSubtype.COIN) {
    const sprAn = metalPiece.GetSprite().GetAnimation();
    animation = "Idle" + sprAn.substring(sprAn.length);
  } else {
    animation = "Idle";
  }

  metalPiece.GetSprite().Play(animation, true);
  metalPiece.Position = Game()
    .GetRoom()
    .FindFreeTilePosition(metalPiece.Position, 25);
  metalPiece.Velocity = vect
    .director(metalPiece.Position, fromEntity.Position)
    .Normalized()
    .mul(3);
}

// REGISTER PICKUP
// !! Ver si se está ejecutando o si da problemas
mod.registerCustomPickup(PickupVariantCustom.metalPiece, 0, takeCoin);

// GENERAL

/** Reduce tear delay from a player. */
function reduceTearDelay(pyr: EntityPlayer) {
  if (pyr.FireDelay > -1) {
    pyr.FireDelay = Math.max(pyr.FireDelay - pyr.MaxFireDelay / 2, 0);
  }
}

/** Remove from metalPiece tear or projectile. */
function remove(bullet: EntityTear | EntityProjectile): void {
  const bData = defaultMapGetHash(v.room.bullet, bullet);

  // Spawn metal piece pickup.
  if (
    !bData.isPicked &&
    bullet.Variant === BulletVariantCustom.metalPiece &&
    bData.spawnedMetalPiece === undefined
  ) {
    const tear = bullet.ToTear();

    let anchorageWallAnim: string;
    const anchorageAnim = "Anchorage";
    const sizeAnim: number = getSizeAnimation(bullet);

    // Set pickup subtype
    // TODO: make bullet subtype
    if (bullet.SubType === MetalPieceSubtype.COIN) {
      anchorageWallAnim = "AnchorageWall";
    } else if (bullet.SubType === MetalPieceSubtype.KNIFE) {
      anchorageWallAnim = "Anchorage";
    } else if (bullet.SubType === MetalPieceSubtype.PLATE) {
      anchorageWallAnim = "AnchorageWall";
    } else {
      error("Not expected pickup subtype");
    }

    // To anchorage
    if (
      ((tear !== undefined && !tear.HasTearFlags(TearFlag.BOUNCE)) ||
        bullet.Type === EntityType.PROJECTILE) &&
      bData.collided.is &&
      // Min velocity to hook.
      vect.biggerThan(
        bData.collided.velocity,
        preconf.velocity.MIN_TEAR_TO_HOOK,
      )
    ) {
      // Spawn coin pickup
      bData.spawnedMetalPiece = spawn(
        EntityType.PICKUP,
        PickupVariantCustom.metalPiece,
        bullet.SubType,
        bData.anchoragePosition,
      ).ToPickup();
      const spwMetalPiece = bData.spawnedMetalPiece;
      if (spwMetalPiece !== undefined) {
        const mpData = defaultMapGetHash(v.room.pickup, spwMetalPiece);

        // Set anchorage characteristics
        spwMetalPiece.Friction = 100;
        mpData.anchorage.is = true;

        // !! Comprobar si es necesario a mayores comprobar si la posición está fuera.

        // To wall anchorage.
        if (pos.isWall(spwMetalPiece.Position)) {
          mpData.anchorage.inWall = true;
          spwMetalPiece.GetSprite().Play(anchorageWallAnim, true);
          spwMetalPiece.SpriteRotation =
            bData.collided.velocity.GetAngleDegrees();
        } else {
          // To grid anchorage.
          mpData.anchorage.inWall = false;
          mpData.anchorage.gridEntityAtached = game
            .GetRoom()
            .GetGridEntityFromPos(spwMetalPiece.Position);
          spwMetalPiece.GetSprite().Play(anchorageAnim, true);
        }
      }
    } else {
      // Just usual metal piece tears.
      bData.spawnedMetalPiece = spawn(
        EntityType.PICKUP,
        PickupVariantCustom.metalPiece,
        bullet.SubType,
        game.GetRoom().FindFreeTilePosition(bullet.Position, 25),
        bullet.Velocity,
      ).ToPickup();
      if (bData.spawnedMetalPiece !== undefined) {
        bData.spawnedMetalPiece.SpriteRotation = bullet.SpriteRotation;
      }
    }

    // Post spawn pickup.
    if (bData.spawnedMetalPiece !== undefined) {
      const spwMetalPiece = bData.spawnedMetalPiece;

      // Ensure that you cant take this tear.
      bData.isPicked = true;

      // Collision classes.
      if (bullet.Type === EntityType.TEAR) {
        spwMetalPiece.EntityCollisionClass = EntityCollisionClass.ENEMIES;
      } else {
        spwMetalPiece.EntityCollisionClass = EntityCollisionClass.ALL;
      }

      // Change size.
      changeSizeSprite(spwMetalPiece, getSizeAnimation(bullet));

      // TODO: laser interaction
      // TODO: knife interaction

      // Adjust scale
      if (tear !== undefined && bullet.SubType === MetalPieceSubtype.COIN) {
        if (sizeAnim === 0 || sizeAnim === 1) {
          spwMetalPiece.SpriteScale = vect.make(tear.Scale * 2);
        } else {
          spwMetalPiece.SpriteScale = vect.make(tear.Scale);
        }
      }

      // Set tear characteristics to pickup.
      spwMetalPiece.SetColor(bullet.GetColor(), 0, 1, false, false);
      const cData = defaultMapGetHash(v.room.pickup, spwMetalPiece);
      cData.baseDamage = bData.baseDamage;
      spwMetalPiece.SpawnerEntity = bullet.SpawnerEntity;
      spwMetalPiece.SubType = bullet.SubType;
    }

    // TODO: Other ludovico interaction
  }
}

/** Remove wasted coins from the room and get them. */
function getWastedCoins(): void {
  const firstPyr = getPlayers(true)[0];
  if (v.level.coinsWasted > 0) {
    if (firstPyr !== undefined) {
      firstPyr.AddCoins(v.level.coinsWasted);
      v.level.coinsWasted = 0;
    }
  }
  for (const pickup of getEntities(
    EntityType.PICKUP,
    PickupVariantCustom.metalPiece,
    MetalPieceSubtype.COIN,
  )) {
    pickup.Remove();
  }
}

//SPRITES

/** Returns size animation number based on 8 sprites (0-7). */
function getSizeAnimation(bullet: EntityTear | EntityProjectile): number {
  let scale: number;
  const tear = bullet.ToTear();
  if (tear !== undefined) {
    scale = tear.Scale;
  } else {
    scale = (bullet.SpriteScale.X + bullet.SpriteScale.Y) / 2;
  }

  if (scale <= 2 / 4) {
    return 0;
  }
  for (let i = 2; i < 7; i++) {
    if (scale > i / 4 && scale <= (i + 1) / 4) {
      return i - 1;
    }
  }
  return 7;
}

function changeSizeSprite(metalPiece: Entity, size: number) {
  const sprite = metalPiece.GetSprite();
  const img = preconf.ref.spriteSheet.metalPieceCoin[size];
  if (img !== undefined) {
    sprite.ReplaceSpritesheet(0, img);
    sprite.LoadGraphics();
  }
  if (size === 0 || size === 1) {
    metalPiece.SpriteScale = metalPiece.SpriteScale.mul(2);
  }
}

export class MetalPiece extends ModFeature {
  /** Callback: postFireTear */
  @Callback(ModCallback.POST_FIRE_TEAR)
  fireTear(tear: EntityTear): void {
    const pyr = tear.SpawnerEntity?.ToPlayer();
    if (pyr !== undefined) {
      const gpData = defaultMapGetPlayer(g.run.player, pyr);
      if (
        gpData.hasMetalPieceTears &&
        gpData.controlsChanged &&
        pyr.GetNumCoins() > 0
      ) {
        // TODO: knife synergy
        this.initCoinTear(tear);
      }
    }
  }

  /** Init the MetalPiece variant on tears, change variant and set baseDamage. */
  initTearVariant(tear: EntityTear) {
    const tData = defaultMapGetHash(v.room.bullet, tear);

    if (tear.Variant !== BulletVariantCustom.metalPiece) {
      tear.ChangeVariant(BulletVariantCustom.metalPiece as TearVariant);
      // TODO: Ludovico interaction

      tData.baseDamage = tear.CollisionDamage * preconf.COIN_DMG_MULT;
    }
  }

  /** Waste a coin to init a coin tear (is necessary that the player has coins). */
  initCoinTear(tear: EntityTear) {
    const pyr = tear.SpawnerEntity?.ToPlayer();

    if (tear.Variant !== BulletVariantCustom.metalPiece && pyr !== undefined) {
      // Start tear coins
      this.initTearVariant(tear);
      tear.SubType = MetalPieceSubtype.COIN;

      v.level.coinsWasted++;
      pyr.AddCoins(-1);

      changeSizeSprite(tear, getSizeAnimation(tear));

      // Set as sticky tear.
      tear.AddTearFlags(TearFlag.BOOGER);

      // Change rotation to tear velocity.
      if (!vectorEquals(VectorZero, tear.Velocity)) {
        tear.SpriteRotation = tear.Velocity.GetAngleDegrees();
      }

      // !! Falta shield tear interaction.
      if (tear.HasTearFlags(TearFlag.SHIELDED)) {
        // tear.GetSprite().ReplaceSpritesheet(0, preconf.ref.SHIELD_COIN_TEAR);
        tear.GetSprite().LoadGraphics();
      }
    }
  }

  @CallbackCustom(
    ModCallbackCustom.POST_TEAR_UPDATE_FILTER,
    BulletVariantCustom.metalPiece as TearVariant,
  )
  coinTearUpdate(tear: EntityTear): void {
    if (tear.SpawnerEntity !== undefined) {
      const tData = defaultMapGetHash(v.room.bullet, tear);

      // TODO: Pinking shears interaction and ludovico interaction.

      // Change rotation to velocity direction.
      if (!vectorEquals(tear.Velocity, VectorZero)) {
        tear.SpriteRotation = tear.Velocity.GetAngleDegrees();
      }

      // Take coin tear on contact.
      if (
        !tData.isPicked &&
        tear.FrameCount > 10 &&
        !vectorEquals(tear.Velocity, VectorZero)
      ) {
        for (const thisPyr of getPlayers()) {
          if (entity.areColliding(tear, thisPyr)) {
            tData.isPicked = true;
            reduceTearDelay(thisPyr);
            takeCoin(thisPyr);
            tear.Remove();
          }
        }
      }

      // TODO: long ludovico interaction implementation.

      // Sticked to a entity.
      if (tear.StickTarget !== undefined) {
        // TODO: interaccion tearFlag.BOGGER, que no se baje el daño.
        tear.CollisionDamage = 0;
        tData.timerStick++;
      } else if (tear.CollisionDamage < tData.baseDamage) {
        tear.CollisionDamage = tData.baseDamage;
      }

      // Spawn coin when get max sticked time.
      if (tData.timerStick > preconf.STICKED_TIME) {
        tear.Remove();
      }
    }
  }

  @CallbackCustom(ModCallbackCustom.POST_PLAYER_UPDATE_REORDERED)
  playerCoinTearOwnerUpdate(pyr: EntityPlayer): void {
    const gpData = defaultMapGetPlayer(g.run.player, pyr);

    // Change stat on coin tears.
    if (gpData.hasMetalPieceTears) {
      if (
        !gpData.stats.changed &&
        gpData.controlsChanged &&
        pyr.GetNumCoins() > 0
      ) {
        gpData.stats.changed = true;
        gpData.stats.realFireDelay = pyr.MaxFireDelay;

        // Add tear stat, newTearStat-baseTearStat.
        const addTearStat =
          getTearsStat(gpData.stats.realFireDelay * preconf.FIRE_DELAY_MULT) -
          getTearsStat(pyr.MaxFireDelay);
        addPlayerStat(pyr, CacheFlag.FIRE_DELAY, addTearStat);
      } else if (
        gpData.stats.changed &&
        !(gpData.controlsChanged && pyr.GetNumCoins() > 0)
      ) {
        gpData.stats.changed = false;
        if (pyr.MaxFireDelay > gpData.stats.realFireDelay) {
          const addTearStat =
            getTearsStat(gpData.stats.realFireDelay) -
            getTearsStat(pyr.MaxFireDelay);
          addPlayerStat(pyr, CacheFlag.FIRE_DELAY, addTearStat);
        }
      }
    }
  }

  @CallbackCustom(
    ModCallbackCustom.POST_PICKUP_UPDATE_FILTER,
    PickupVariantCustom.metalPiece,
  )
  metalPiecePickupUpdate(pickup: EntityPickup): void {
    const data = defaultMapGetHash(v.room.pickup, pickup);

    // To anchorage.
    if (data.anchorage.is) {
      // If anchorage's grid is destroyed it becomes a pickup.
      const gridEnt = data.anchorage.gridEntityAtached;
      if (
        !data.anchorage.inWall &&
        (gridEnt === undefined ||
          (gridEnt.ToDoor() !== undefined && gridEnt.State !== 2) ||
          (gridEnt.ToDoor() === undefined && gridEnt.State !== 1))
      ) {
        data.anchorage.is = false;
        pickup.GetSprite().Play("Idle", true);
        pickup.Friction = preconf.FRICTION_PICKUP;
      } else {
        // To non anchorage metal pieces.
        if (pickup.SubType === MetalPieceSubtype.PLATE) {
          pickup.EntityCollisionClass = EntityCollisionClass.ALL;
        }
        // Change rotation.
        if (!vectorEquals(pickup.Velocity, VectorZero)) {
          pickup.SpriteRotation = pickup.Velocity.GetAngleDegrees();
        }
      }
    } else {
      // To no anchorage pickup
      // Change rotation.
      if (!vectorEquals(pickup.Velocity, VectorZero)) {
        pickup.SpriteRotation = pickup.Velocity.GetAngleDegrees();
      }
    }
    // TODO: magneto interaction
  }

  @CallbackCustom(
    ModCallbackCustom.POST_TEAR_KILL,
    BulletVariantCustom.metalPiece as TearVariant,
  )
  removeTear(tear: EntityTear): void {
    remove(tear);
  }

  @CallbackCustom(
    ModCallbackCustom.POST_PROJECTILE_KILL,
    BulletVariantCustom.metalPiece as ProjectileVariant,
  )
  removeProjectile(projectile: EntityProjectile): void {
    remove(projectile);
  }

  @CallbackCustom(ModCallbackCustom.POST_GAME_END_FILTER)
  getWastedCoinsGameEnd() {
    getWastedCoins();
  }

  @CallbackCustom(ModCallbackCustom.POST_NEW_ROOM_REORDERED)
  getWastedCoinsNewRoom() {
    getWastedCoins();
  }
}
