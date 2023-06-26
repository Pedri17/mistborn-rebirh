import { VectorZero } from "isaacscript-common";
import { Power } from "../enums/Power";

export class playerData {
  // Power variables
  controlsChanged: boolean = false;
  mineralBar: number = 0;
  powers: Record<number, Power | undefined> = {
    [1]: Power.AL_IRON,
    [2]: undefined,
    [3]: undefined,
  };
  lastShot = {
    frame: 0,
    direction: VectorZero,
  };

  // iron/steel variables
  selectedEntities: Entity[] = [];
  gridTouched: boolean = false;
}
