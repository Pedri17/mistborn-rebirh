import { PowerOwnerData } from "./PowerOwnerData";

export class PlayerData extends PowerOwnerData {
  controlsChanged = false;
  mineralBar = 0;
  stats = {
    changed: false,
    realFireDelay: 0,
  };
}
