import { ButtonAction } from "isaac-typescript-definitions";

export const action = {
  CHANGE_MODE: ButtonAction.DROP,
};

export const powerAction: ButtonAction[] = [
  ButtonAction.ITEM,
  ButtonAction.PILL_CARD,
  ButtonAction.BOMB,
];

export const ui = {
  HUDOffset: 10,
} as const;
