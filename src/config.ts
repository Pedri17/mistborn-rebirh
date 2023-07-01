import { ButtonAction } from "isaac-typescript-definitions";

export const action = {
  CHANGE_MODE: ButtonAction.DROP,
};

export const powerAction: Record<number, ButtonAction> = {
  [0]: ButtonAction.ITEM,
  [1]: ButtonAction.PILL_CARD,
  [2]: ButtonAction.BOMB,
};
