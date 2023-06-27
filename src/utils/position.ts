import { GridCollisionClass } from "isaac-typescript-definitions";
import { game } from "isaacscript-common";

export function isWall(pos: Vector) {
  return game.GetRoom().GetGridCollisionAtPos(pos) === GridCollisionClass.WALL;
}

export function isDoor(pos: Vector) {
  return game.GetRoom().GetGridEntityFromPos(pos)?.ToDoor() !== undefined;
}

export function isObject(pos: Vector) {
  return (
    game.GetRoom().GetGridCollisionAtPos(pos) === GridCollisionClass.OBJECT
  );
}

export function isNoneCollision(pos: Vector) {
  return game.GetRoom().GetGridCollisionAtPos(pos) === GridCollisionClass.NONE;
}

export function isGrid(pos: Vector) {
  return game.GetRoom().GetGridCollisionAtPos(pos) !== undefined;
}
