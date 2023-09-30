import { EntityType } from "isaac-typescript-definitions";
import { ModCallbackCustom } from "isaacscript-common";
import { mod } from "../mod";
import * as allomancyIronSteel from "../powers/allomancyIronSteel";

export function init(): void {
  mod.AddCallbackCustom(
    ModCallbackCustom.POST_GRID_ENTITY_COLLISION,
    allomancyIronSteel.selecterGridCollision,
    undefined,
    undefined,
    EntityType.PLAYER,
  );
  mod.AddCallbackCustom(
    ModCallbackCustom.POST_GRID_ENTITY_COLLISION,
    allomancyIronSteel.enemySelectedGridCollision,
  );
}
