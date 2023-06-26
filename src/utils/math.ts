// Return limit if base is higher, base otherwise
export function upperBound(n: number, max: number): number {
  if (n > max) {
    return max;
  }
  return n;
}
