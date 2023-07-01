import { VectorZero } from "isaacscript-common";
import { FocusSelection } from "../../enums/FocusSelection";

export class SelecterData {
  selectedEntities: PtrHash[] = [];
  focusSelection: FocusSelection = FocusSelection.BASE;
  lastMetalPiece?: Entity | undefined = undefined;
  lastShot = {
    frame: 0,
    direction: VectorZero,
  };
}
