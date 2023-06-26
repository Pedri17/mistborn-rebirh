import { ButtonAction } from "isaac-typescript-definitions";

export const action = {
  CHANGE_MODE: ButtonAction.DROP,
};

export const powerAction: Record<number, ButtonAction> = {
  [1]: ButtonAction.ITEM,
  [2]: ButtonAction.PILL_CARD,
  [3]: ButtonAction.BOMB,
};
