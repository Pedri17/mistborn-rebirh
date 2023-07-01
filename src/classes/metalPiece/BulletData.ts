import { VectorZero } from "isaacscript-common";

export class BulletData {
  baseDamage = 0;
  anchoragePosition: Vector = VectorZero;
  isPicked = false;
  timerStick = 0;
  spawnedCoin?: EntityPickup = undefined;

  collided = {
    is: false,
    velocity: VectorZero,
  };
}
