import { addCollectible } from "isaacscript-common";
import { CollectibleTypeCustom } from "../customVariantType/CollectibleTypeCustom";
import { CostumeCustom } from "../customVariantType/CostumeCustom";

export function onInit(pyr: EntityPlayer): void {
  addCollectible(
    pyr,
    CollectibleTypeCustom.ironAllomancy,
    CollectibleTypeCustom.steelAllomancy,
  );
  pyr.AddNullCostume(CostumeCustom.playerAllomancer);
}
