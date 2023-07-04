import { PowerOwnerData } from "./PowerOwnerData";

export class PlayerData extends PowerOwnerData {
  controlsChanged = false;
  mineralBar = 0;
  isHemalurgyPower: boolean[] = [];
  stats = {
    changed: false,
    realFireDelay: 0,
  };
}
