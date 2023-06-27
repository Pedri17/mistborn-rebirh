import { Power } from "../enums/Power";
import { selecterData } from "./selecterData";

export class npcData extends selecterData {
  // Power variables
  powers: Record<number, Power | undefined> = {};

  // MONEDA METALICA
  coinAtached: boolean = false;
}
