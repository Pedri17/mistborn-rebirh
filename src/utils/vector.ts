/**
 * Check if any vector's abolute value is bigger than a number.
 */
export function biggerThan(vector: Vector, n: number) {
  return Math.abs(vector.X) > n || Math.abs(vector.Y) > n;
}

export function make(n: number) {
  return Vector(n, n);
}
