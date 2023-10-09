import { PowerOwnerData } from "../power/PowerOwnerData";

export class PlayerData extends PowerOwnerData {
  // Control powers
  controlsChanged = false;
  unpressingPowerTimes = 0;
  mineralBar = 0;
  isHemalurgyPower: boolean[] = [];
  // MetalPiece
  hasMetalPieceTears = false;
  // General
  stats = {
    changed: false,
    realFireDelay: 0,
  };
}
