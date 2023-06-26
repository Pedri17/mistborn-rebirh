import { Power } from "../enums/Power";

export class npcData {
  // Power variables
  powers: Record<number, Power | undefined> = {};

  // iron/steel variables
  selectedEntities: Entity[] = [];
  gridTouched: boolean = false;

  // MONEDA METALICA
  coinAtached: boolean = false;
}
