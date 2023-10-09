// IS
export function isEqual(
  ent1: Entity | undefined,
  ent2: Entity | undefined,
): boolean {
  if (ent1 === undefined || ent2 === undefined) {
    return ent1 === ent2;
  }
  return GetPtrHash(ent1) === GetPtrHash(ent2);
}

export function areColliding(ent1: Entity, ent2: Entity): boolean {
  return ent1.Position.sub(ent2.Position).Length() < ent1.Size + ent2.Size;
}
