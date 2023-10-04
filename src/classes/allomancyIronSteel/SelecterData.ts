import { VectorZero } from "isaacscript-common";
import { FocusSelection } from "../../enums/FocusSelection";
import { Power } from "../../enums/Power";
import { EntityData } from "./EntityData";

export class SelecterData extends EntityData {
  usingPower?: Power = undefined;
  selectedEntities: PtrHash[] = [];
  focusSelection: FocusSelection = FocusSelection.BASE;
  lastMetalPiece?: Entity = undefined;
  lastShot = {
    frame: 0,
    direction: VectorZero,
  };
}
