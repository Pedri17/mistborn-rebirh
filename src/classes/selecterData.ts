import { FocusSelection } from "../enums/FocusSelection";
import { entityData } from "./entityData";

// Entity that can select entities
export class selecterData extends entityData {
  // iron/steel variables
  selectedEntities: PtrHash[] = [];
  focusSelection: FocusSelection = FocusSelection.BASE;
  lastCoin: Entity | undefined = undefined;
}
