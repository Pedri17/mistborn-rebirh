import { getPlayerIndex } from "isaacscript-common";
import { playersData } from "./player";
import { EntityType, FamiliarVariant, PickupVariant, TearFlag, TearVariant } from "isaac-typescript-definitions";
import { playerData } from "../classes/playerData";
import { npcData } from "../classes/npcData";

export const npcsData: Record<PtrHash, npcData> = {};

export function getPlayerData(ent: Entity): playerData {
  if (ent.ToPlayer() !== undefined) {
    const pID = getPlayerIndex(ent.ToPlayer()!);
    if(playersData[pID] === undefined){
      playersData[pID] = new playerData();
    }
    return playersData[pID]!;
  } else {
    error("getPlayerData: is not a player");
  }
}

export function getNpcData(ent: Entity): npcData {
 if(ent.ToNPC() !== undefined){
    const npcID = GetPtrHash(ent.ToNPC()!);
    if(npcsData[npcID] === undefined){
      npcsData[npcID] = new npcData();
    }
    return npcsData[npcID]!;
  } else {
    error("getNpcData: is not an NPC");
  }
}

export function isMetalic(ent: Entity): boolean{
  return ((ent.Type === EntityType.PICKUP)
  // !! falta aquí el tipo throwedCoin
  // !! falta aquí el tipo mineralBottle
  && ((ent.Variant === PickupVariant.COIN)
  || ent.Variant === PickupVariant.KEY
  || ent.Variant === PickupVariant.LOCKED_CHEST
  || ent.Variant === PickupVariant.LIL_BATTERY
  || ent.Variant === PickupVariant.CHEST
  || ent.Variant === PickupVariant.MIMIC_CHEST
  || ent.Variant === PickupVariant.OLD_CHEST
  || ent.Variant === PickupVariant.SPIKED_CHEST
  || ent.Variant === PickupVariant.ETERNAL_CHEST
  || ent.Variant === PickupVariant.HAUNTED_CHEST))
|| ((ent.Type === EntityType.TEAR) &&
  // !! falta comprobar la tear metálica
  // ((data.isMetalPiece
  //    //Not select bosses
  //    && (ent:ToTear().StickTarget==nil || (ent:ToTear().StickTarget~=nil && not ent:ToTear().StickTarget:IsBoss()))
  //    //Not select sub ludovico coins
  //    && not data.isSubLudovicoTear)
    (ent.ToTear()!.HasTearFlags(TearFlag.CONFUSION))
  || (ent.ToTear()!.HasTearFlags(TearFlag.ATTRACTOR))
  || (ent.ToTear()!.HasTearFlags(TearFlag.GREED_COIN))
  || (ent.ToTear()!.HasTearFlags(TearFlag.MIDAS))
  || (ent.ToTear()!.HasTearFlags(TearFlag.MAGNETIZE))
  || (ent.Variant==TearVariant.METALLIC)
  || (ent.Variant==TearVariant.COIN))
|| ((ent.Type == EntityType.FAMILIAR)
  && (ent.Variant == FamiliarVariant.SAMSONS_CHAINS))
|| (ent.Type == EntityType.KNIFE
  //!! interacción con Knife
  //&& data.isThrowable)
|| (data.coinAtached ~= nil && data.coinAtached)
|| (ent.Type == EntityType.ENTITY_PROJECTILE && data.isMetalPiece)

  )
}
