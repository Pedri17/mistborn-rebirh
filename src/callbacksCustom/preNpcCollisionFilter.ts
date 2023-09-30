import { ModCallbackCustom } from "isaacscript-common";
import { mod } from "../mod";
import { enemySelectedEntityCollision } from "../powers/allomancyIronSteel";

export function init(): void {
  mod.AddCallbackCustom(ModCallbackCustom.PRE_NPC_COLLISION_FILTER, main);
}

function main(
  ent: Entity,
  collider: Entity,
  low: boolean,
): boolean | undefined {
  return enemySelectedEntityCollision(ent, collider, low);
}
