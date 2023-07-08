import { DefaultMap, PlayerIndex } from "isaacscript-common";
import { PlayerData } from "./classes/global/PlayerData";
import { mod } from "./mod";

export const g = {
  run: {
    player: new DefaultMap<PlayerIndex, PlayerData>(() => new PlayerData()),
  },
};

export function initGlobal(): void {
  mod.saveDataManagerRegisterClass(PlayerData);
  mod.saveDataManager("global", g);
}
