/** Check if any vector's abolute value is bigger than a number. */
export function biggerThan(vector: Vector, n: number): boolean {
  return Math.abs(vector.X) > n || Math.abs(vector.Y) > n;
}

export function make(n: number): Vector {
  return Vector(n, n);
}

/** Return a director vector from 2 positions. */
export function director(fromPos: Vector, toPos: Vector): Vector {
  return Vector(toPos.X - fromPos.X, toPos.Y - fromPos.Y).Normalized();
}

/** Return n multiplied director vector from entities positions. */
export function fromToEntity(
  fromEntity: Entity,
  toEntity: Entity,
  n: number,
): Vector {
  return director(toEntity.Position, fromEntity.Position).mul(n);
}

/** Returns multiplicator (1-0) from distance limit (distance-limit). */
export function distanceMult(v1: Vector, v2: Vector, limit: number): number {
  let n = 1 - v1.Distance(v2) / limit;
  if (n < 0) return 0;
  else return n;
}
