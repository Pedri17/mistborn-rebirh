import { getPlayerIndex } from "isaacscript-common";
import { playersData } from "./player";

export function getData(entity: Entity) {
  if (entity.ToPlayer() !== undefined) {
    return playersData[getPlayerIndex(entity.ToPlayer()!)]!;
  } else {
    error("getData: not configured to this entity type");
  }
}
