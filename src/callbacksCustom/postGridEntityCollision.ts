import { EntityType } from "isaac-typescript-definitions";
import { ModCallbackCustom } from "isaacscript-common";
import { mod } from "../mod";
import * as al_ironSteel from "../powers/al_ironSteel";

export function init() {
  mod.AddCallbackCustom(
    ModCallbackCustom.POST_GRID_ENTITY_COLLISION,
    main,
    undefined,
    undefined,
    EntityType.PLAYER,
  );
}

function main(grEntity: GridEntity, ent: Entity) {
  al_ironSteel.touchGrid(grEntity, ent);
}
