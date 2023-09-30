export class EntityData {
  selected = {
    is: false,
    from: undefined as Entity | undefined,
  };

  gridTouched = false;
  stickedMetalPiece?: Entity = undefined;
  hitFrame = 0;
}
