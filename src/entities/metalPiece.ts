import {
  EntityCollisionClass,
  EntityType,
  TearFlag,
  TearVariant,
} from "isaac-typescript-definitions";
import {
  DefaultMap,
  VectorZero,
  defaultMapGetHash,
  game,
  log,
  spawn,
  vectorEquals,
} from "isaacscript-common";
import { BulletData } from "../classes/metalPiece/BulletData";
import { NpcData } from "../classes/metalPiece/NpcData";
import { PickupData } from "../classes/metalPiece/PickupData";
import { BulletVariantCustom } from "../customVariantType/BulletVariantCustom";
import { MetalPieceSubtype } from "../customVariantType/MetalPieceSubtype";
import { PickupVariantCustom } from "../customVariantType/PickupVariantCustom";
import { mod } from "../mod";
import * as allomancyIronSteel from "../powers/allomancyIronSteel";
import * as power from "../powers/power";
import * as pos from "../utils/position";
import * as vect from "../utils/vector";
import * as entity from "./entity";

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
  velocity: {
    MIN_TEAR_TO_HOOK: 20,
  },
};

// SAVE DATA

const v = {
  room: {
    bullet: new DefaultMap<PtrHash, BulletData>(() => new BulletData()),
    pickup: new DefaultMap<PtrHash, PickupData>(() => new PickupData()),
    npc: new DefaultMap<PtrHash, NpcData>(() => new NpcData()),
    coinsWasted: 0,
  },
};

export function init(): void {
  mod.saveDataManager("metalPiece", v);
}

/** Callback: postFireTear */
export function fireTear(tear: EntityTear): void {
  const pyr = tear.SpawnerEntity?.ToPlayer();
  if (pyr !== undefined) {
    if (
      power.hasAnyPower(pyr) &&
      power.hasControlsChanged(pyr) &&
      pyr.GetNumCoins() > 0
    ) {
      // TODO: knife synergy
      initCoinTear(tear);
      allomancyIronSteel.setLastMetalPiece(pyr, tear);
    }
  }
}

export function takeCoin(this: void, pyr: EntityPlayer): void {
  if (v.room.coinsWasted > 0) {
    pyr.AddCoins(1);
    v.room.coinsWasted--;
  }
}

/** CallbackCustom: post postTearKill and postProjectileKill */
export function remove(bullet: EntityTear | EntityProjectile): void {
  const bData = defaultMapGetHash(v.room.bullet, bullet);

  // Spawn Coin
  if (
    bullet.Variant === BulletVariantCustom.metalPiece &&
    bData.spawnedCoin === undefined
  ) {
    let anchorageWallAnim: string;
    let anchorageAnim: string;
    let spawnAnim: string;
    let sizeAnim: number = getSizeAnimation(bullet);

    // Set pickup subtype
    // TODO: make bullet subtype
    if (bullet.SubType === MetalPieceSubtype.COIN) {
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
    const tear = bullet.ToTear();
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
      bData.spawnedCoin = spawn(
        EntityType.PICKUP,
        PickupVariantCustom.metalPiece,
        bullet.SubType,
        bData.anchoragePosition,
      ).ToPickup();
      const coin = bData.spawnedCoin;
      if (coin !== undefined) {
        const cData = defaultMapGetHash(v.room.pickup, coin);

        // Set anchorage characteristics
        coin.Friction = 100;
        cData.anchorage.is = true;

        // !! Comprobar si es necesario a mayores comprobar si la posición está fuera de la
        // habitación.

        // To wall anchorage.
        if (pos.isWall(coin.Position)) {
          cData.anchorage.inWall = true;
          coin.GetSprite().Play(anchorageWallAnim, true);
          coin.SpriteRotation = bData.collided.velocity.GetAngleDegrees();
        }
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
      if (bData.spawnedCoin !== undefined) {
        bData.spawnedCoin.SpriteRotation = bullet.SpriteRotation;
        // bData.spawnedCoin.GetSprite().Play(spawnAnim, true);
      }
    }

    // Post spawn tear
    if (bData.spawnedCoin !== undefined) {
      const coin = bData.spawnedCoin;

      // Ensure that you cant take this tear.
      bData.isPicked = true;

      // Collision classes
      if (bullet.Type === EntityType.TEAR) {
        coin.EntityCollisionClass = EntityCollisionClass.ENEMIES;
      } else {
        coin.EntityCollisionClass = EntityCollisionClass.ALL;
      }

      // If tear coin is selected then select pickup coin.
      allomancyIronSteel.passSelection(bullet, coin);

      // If is the last shot coin then select pickup as it.
      if (
        bullet.SpawnerEntity !== undefined &&
        entity.isEqual(
          bullet,
          allomancyIronSteel.getLastMetalPiece(bullet.SpawnerEntity),
        )
      ) {
        allomancyIronSteel.setLastMetalPiece(bullet.SpawnerEntity, coin);
      }

      // TODO: laser interaction
      // TODO: knife interaction

      // Adjust scale
      if (
        bullet.Type === EntityType.TEAR &&
        bullet.SubType === MetalPieceSubtype.COIN
      ) {
        if (sizeAnim === 0 || sizeAnim === 1) {
          coin.SpriteScale = vect.make(bullet.ToTear()!.Scale * 2);
        } else {
          coin.SpriteScale = vect.make(bullet.ToTear()!.Scale);
        }
      }

      // Set tear characteristics to pickup.
      coin.SetColor(bullet.GetColor(), 0, 1, false, false);
      const cData = defaultMapGetHash(v.room.pickup, coin);
      cData.baseDamage = bData.baseDamage;
      coin.SpawnerEntity = bullet.SpawnerEntity;
      coin.SubType = bullet.SubType;
    }

    // TODO: Other ludovico interaction
  }
}

/** Waste a coin to init a coin tear (is necessary that the player has coins). */
function initCoinTear(tear: EntityTear) {
  const pyr = tear.SpawnerEntity?.ToPlayer();

  if (tear.Variant !== BulletVariantCustom.metalPiece && pyr !== undefined) {
    // Start tear coins
    initTearVariant(tear);
    // tData.subType = MetalPieceSubtype.COIN;
    tear.SubType = MetalPieceSubtype.COIN;
    v.room.coinsWasted++;
    pyr.AddCoins(-1);

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
  const tData = defaultMapGetHash(v.room.bullet, tear);

  if (tear.Variant !== BulletVariantCustom.metalPiece) {
    tear.Variant = BulletVariantCustom.metalPiece as TearVariant;
    // TODO: Ludovico interaction
    if (
      tear.Variant !== BulletVariantCustom.metalPiece &&
      tear.GetSprite().GetFilename() !== ref.TEAR_COIN
    ) {
      tear.ChangeVariant(BulletVariantCustom.metalPiece as TearVariant);
    }

    tData.anchoragePosition = tear.Position;
    tData.baseDamage = tear.CollisionDamage * preconf.COIN_DMG_MULT;
  }
}

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
