import {
  EntityCollisionClass,
  EntityType,
  TearFlag,
} from "isaac-typescript-definitions";
import { VectorZero, game, log, spawn, vectorEquals } from "isaacscript-common";
import { MetalPieceSubtype } from "../customVariantType/MetalPieceSubtype";
import { PickupVariantCustom } from "../customVariantType/PickupVariantCustom";
import { TearVariantCustom } from "../customVariantType/TearVariantCustom";
import * as allomancyIronSteel from "../powers/allomancyIronSteel";
import * as power from "../powers/power";
import * as pos from "../utils/position";
import * as vect from "../utils/vector";
import {
  getBulletData,
  getPickupData,
  getPlayerData,
  getPowerOwnerData,
  getTearData,
  v,
} from "../variables";
import * as entity from "./entity";
import { isExisting } from "./entity";

const ref = {
  BOMB_COIN_TEAR: "gfx/effects/coin/pickup_coinBomb.anm2",
  PARTICLE_COIN: "gfx/effects/coin/particle_coin.anm2",
  TEAR_KNIFE: "gfx/effects/knife/tear_knife.anm2",
  TEAR_COIN: "gfx/effects/coin/object_coin.anm2",
  SHIELD_COIN_TEAR: "gfx/effects/coin/coinTear_Shield.png",
  PLATE_TEAR: "gfx/effects/plate/object_plate.anm2",
};

const preconf = {
  STICKED_TIME: 90,
  FRICTION_PICKUP: 0.3,
  COIN_DMG_MULT: 2,
};

/** Callback: postFireTear */
export function fireTear(tear: EntityTear): void {
  if (
    tear.SpawnerEntity !== undefined &&
    tear.SpawnerEntity.ToPlayer() !== undefined
  ) {
    let pyr = tear.SpawnerEntity.ToPlayer()!;
    let pData = getPlayerData(pyr);
    let tData = getTearData(tear);

    if (
      power.hasAnyPower(pyr) &&
      pData.controlsChanged &&
      pyr.GetNumCoins() > 0
    ) {
      // TODO: knife synergy
      initCoinTear(tear);
      pData.lastCoin = tear;
    }
  }
}

export function takeCoin(this: void, pyr: EntityPlayer) {
  if (v.room.roomData.coinsWasted > 0) {
    pyr.AddCoins(1);
    v.room.roomData.coinsWasted--;
  }
}

/** CallbackCustom: post postTearKill and postProjectileKill */
export function remove(bullet: EntityTear | EntityProjectile) {
  let bData = getBulletData(bullet);

  // Spawn Coin
  if (bData.isMetalPiece && bData.spawnedCoin === undefined) {
    let anchorageWallAnim;
    let anchorageAnim;
    let spawnAnim;
    let sizeAnim;

    // Set pickup subtype
    // TODO: make bullet subtype
    if (bullet.SubType === MetalPieceSubtype.COIN) {
      sizeAnim = getSizeAnimation(bullet);
      anchorageWallAnim = `AnchorageWall${sizeAnim}`;
      anchorageAnim = `Anchorage${sizeAnim}`;
      spawnAnim = `Appear${sizeAnim}`;
    } else if (bullet.SubType === MetalPieceSubtype.KNIFE) {
      anchorageWallAnim = "Anchorage";
      anchorageAnim = "Anchorage";
      spawnAnim = "Idle";
    } else if (bullet.SubType === MetalPieceSubtype.PLATE) {
      anchorageWallAnim = "AnchorageWall";
      anchorageAnim = "Anchorage";
      spawnAnim = "Appear";
    } else {
      error("Not expected pickup subtype");
    }

    // To anchorage
    if (
      ((bullet.Type === EntityType.TEAR &&
        !bullet.ToTear()?.HasTearFlags(TearFlag.BOUNCE)) ||
        bullet.Type === EntityType.PROJECTILE) &&
      bData.collision &&
      // Min velocity to hook
      vect.biggerThan(
        bData.collisionVelocity,
        allomancyIronSteel.preconf.velocity.MIN_TEAR_TO_HOOK,
      )
    ) {
      // Spawn coin pickup
      log("To anchorage");
      bData.spawnedCoin = spawn(
        EntityType.PICKUP,
        PickupVariantCustom.metalPiece,
        bullet.SubType,
        bData.anchoragePosition,
      ).ToPickup();
      let coin = bData.spawnedCoin!;
      let cData = getPickupData(coin);

      // Set anchorage characteristics
      coin.Friction = 100;
      cData.isAnchorage = true;

      // !! Comprobar si es necesario a mayores comprobar si la posición está fuera de la
      // habitación.

      // To wall anchorage.
      if (pos.isWall(coin.Position)) {
        cData.isInWall = true;
        coin.GetSprite().Play(anchorageWallAnim, true);
        coin.SpriteRotation = bData.collisionVelocity.GetAngleDegrees();
      }
    } else {
      // Just usual tear coins.
      log("To just usual tears, do spawn");
      bData.spawnedCoin = spawn(
        EntityType.PICKUP,
        PickupVariantCustom.metalPiece,
        bullet.SubType,
        game.GetRoom().FindFreeTilePosition(bullet.Position, 25),
        bullet.Velocity,
      ).ToPickup();
      log("spawn finished");
      bData.spawnedCoin!.SpriteRotation = bullet.SpriteRotation;
      // bData.spawnedCoin.GetSprite().Play(spawnAnim, true);
    }

    // Post spawn tear
    if (bData.spawnedCoin !== undefined) {
      let coin = bData.spawnedCoin;

      // Ensure that you cant take this tear.
      bData.isPicked = true;

      // Collision classes
      if (bullet.Type === EntityType.TEAR) {
        coin.EntityCollisionClass = EntityCollisionClass.ENEMIES;
      } else {
        coin.EntityCollisionClass = EntityCollisionClass.ALL;
      }

      // If tear coin is selected then select pickup coin.
      if (bData.isSelected) {
        if (isExisting(bData.fromSelected)) {
          allomancyIronSteel.selectEntity(bData.fromSelected!, coin);
        }
      }

      // If is the last shot coin then select pickup as it.
      if (
        bullet.SpawnerEntity !== undefined &&
        entity.isEqual(bullet, getPowerOwnerData(bullet.SpawnerEntity).lastCoin)
      ) {
        getPowerOwnerData(bullet.SpawnerEntity).lastCoin = coin;
      }

      // TODO: laser interaction
      // TODO: knife interaction

      // Set tear characteristics to pickup.
      coin.SetColor(bullet.GetColor(), 0, 1, false, false);
      if (
        bullet.Type === EntityType.TEAR &&
        bData.subType === MetalPieceSubtype.COIN
      ) {
        if (sizeAnim === 0 || sizeAnim === 1) {
          coin.SpriteScale = vect.make(bullet.ToTear()!.Scale * 2);
        } else {
          coin.SpriteScale = vect.make(bullet.ToTear()!.Scale);
        }
      }

      let cData = getPickupData(coin);
      cData.gridTouched = false;
      cData.baseDamage = bData.baseDamage;
      coin.SpawnerEntity = bullet.SpawnerEntity;
      coin.SubType = bData.subType;
    }

    // TODO: Other ludovico interaction
  }
}

/** Waste a coin to init a coin tear (is necessary that the player has coins). */
function initCoinTear(tear: EntityTear) {
  let tData = getTearData(tear);

  if (
    !tData.isMetalPiece &&
    tear.SpawnerEntity !== undefined &&
    tear.SpawnerEntity.ToPlayer() !== undefined
  ) {
    // Start tear coins
    initTearVariant(tear);
    // tData.subType = MetalPieceSubtype.COIN;
    tear.SubType = MetalPieceSubtype.COIN;
    v.room.roomData.coinsWasted + 1;
    tear.SpawnerEntity.ToPlayer()!.AddCoins(-1);

    // Shield tear interaction
    if (tear.HasTearFlags(TearFlag.SHIELDED)) {
      tear.GetSprite().ReplaceSpritesheet(0, ref.SHIELD_COIN_TEAR);
      tear.GetSprite().LoadGraphics();
    }

    // Change rotation to tear velocity
    if (vectorEquals(VectorZero, tear.Velocity)) {
      tear.SpriteRotation = tear.Velocity.GetAngleDegrees();
    }

    const sizeAnim = getSizeAnimation(tear);

    tear.GetSprite().Play(`Appear${sizeAnim}`, true);
    // Adjust smaller sizes
    if (sizeAnim === 0 || sizeAnim === 1) {
      tear.SpriteScale = tear.SpriteScale.mul(2);
    }
  }
}

/** Init the MetalPiece variant on tears, change variant and set baseDamage. */
function initTearVariant(tear: EntityTear) {
  let tData = getTearData(tear);

  if (!tData.isMetalPiece) {
    tData.isMetalPiece = true;
    // TODO: Ludovico interaction
    if (
      tear.Variant !== TearVariantCustom.metalPiece &&
      tear.GetSprite().GetFilename() !== ref.TEAR_COIN
    ) {
      tear.ChangeVariant(TearVariantCustom.metalPiece);
    }

    tData.anchoragePosition = tear.Position;
    tData.baseDamage = tear.CollisionDamage * preconf.COIN_DMG_MULT;
  }
}

/** Returns size animation number based on 8 sprites (0-7). */
function getSizeAnimation(bullet: EntityTear | EntityProjectile) {
  let scale;
  if (bullet.Type === EntityType.TEAR) {
    scale = bullet.ToTear()!.Scale;
  } else {
    scale = (bullet.SpriteScale.X + bullet.SpriteScale.Y) / 2;
  }

  if (scale !== undefined) {
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
  return undefined;
}
