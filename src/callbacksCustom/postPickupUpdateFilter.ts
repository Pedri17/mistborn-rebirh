import { ModCallbackCustom } from "isaacscript-common";
import { PickupVariantCustom } from "../customVariantType/PickupVariantCustom";
import { metalPiecePickupUpdate } from "../entities/metalPiece";
import { mod } from "../mod";

export function init(): void {
  mod.AddCallbackCustom(
    ModCallbackCustom.POST_PICKUP_UPDATE_FILTER,
    main,
    PickupVariantCustom.metalPiece,
  );
}

function main(pickup: EntityPickup) {
  metalPiecePickupUpdate(pickup);
}
