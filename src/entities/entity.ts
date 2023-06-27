import {
  EntityType,
  FamiliarVariant,
  PickupVariant,
  TearFlag,
  TearVariant,
} from "isaac-typescript-definitions";
import { getPlayerIndex } from "isaacscript-common";
import { entityData } from "../classes/entityData";
import { npcData } from "../classes/npcData";
import { playerData } from "../classes/playerData";
import { selecterData } from "../classes/selecterData";
import { playersData } from "./player";

export const npcsData: Record<PtrHash, npcData> = {};
export const entitiesData: Record<PtrHash, entityData> = {};

// GET DATA

export function getData(ent: Entity): entityData {
  const ID = GetPtrHash(ent);
  if (entitiesData[ID] === undefined) {
    entitiesData[ID] = new entityData();
  }
  return entitiesData[ID]!;
}

export function getSelecterData(ent: Entity): selecterData {
  if (ent.ToPlayer() !== undefined) {
    const pID = getPlayerIndex(ent.ToPlayer()!);
    if (playersData[pID] === undefined) {
      playersData[pID] = new playerData();
    }
    return playersData[pID]!;
  } else if (ent.ToNPC() !== undefined) {
    const npcID = GetPtrHash(ent.ToNPC()!);
    if (npcsData[npcID] === undefined) {
      npcsData[npcID] = new npcData();
    }
    return npcsData[npcID]!;
  } else {
    error("getSelecterData: error invalid type");
  }
}

export function getPlayerData(ent: Entity): playerData {
  if (ent.ToPlayer() !== undefined) {
    const pID = getPlayerIndex(ent.ToPlayer()!);
    if (playersData[pID] === undefined) {
      playersData[pID] = new playerData();
    }
    return playersData[pID]!;
  } else {
    error("getPlayerData: is not a player");
  }
}

export function getNpcData(ent: Entity): npcData {
  if (ent.ToNPC() !== undefined) {
    const npcID = GetPtrHash(ent.ToNPC()!);
    if (npcsData[npcID] === undefined) {
      npcsData[npcID] = new npcData();
    }
    return npcsData[npcID]!;
  } else {
    error("getNpcData: is not a npc");
  }
}

// IS

export function isExisting(ent: Entity | undefined): boolean {
  return ent !== undefined && ent.Exists();
}

export function isMetalic(ent: Entity): boolean {
  if (ent.Type === EntityType.PICKUP) {
    if (
      // !! falta aquí el tipo throwedCoin y mineralBottle
      ent.Variant === PickupVariant.COIN ||
      ent.Variant === PickupVariant.KEY ||
      ent.Variant === PickupVariant.LOCKED_CHEST ||
      ent.Variant === PickupVariant.LIL_BATTERY ||
      ent.Variant === PickupVariant.CHEST ||
      ent.Variant === PickupVariant.MIMIC_CHEST ||
      ent.Variant === PickupVariant.OLD_CHEST ||
      ent.Variant === PickupVariant.SPIKED_CHEST ||
      ent.Variant === PickupVariant.ETERNAL_CHEST ||
      ent.Variant === PickupVariant.HAUNTED_CHEST
    ) {
      return true;
    }
  } else if (ent.Type === EntityType.TEAR) {
    // !! falta comprobar la tear metálica
    // ((data.isMetalPiece
    //    //Not select bosses
    //    && (ent:ToTear().StickTarget==nil || (ent:ToTear().StickTarget~=nil && not ent:ToTear().StickTarget:IsBoss()))
    //    //Not select sub ludovico coins
    //    && not data.isSubLudovicoTear)
    if (
      ent.ToTear()!.HasTearFlags(TearFlag.CONFUSION) ||
      ent.ToTear()!.HasTearFlags(TearFlag.ATTRACTOR) ||
      ent.ToTear()!.HasTearFlags(TearFlag.GREED_COIN) ||
      ent.ToTear()!.HasTearFlags(TearFlag.MIDAS) ||
      ent.ToTear()!.HasTearFlags(TearFlag.MAGNETIZE)
    ) {
      return true;
    } else if (
      ent.Variant == TearVariant.METALLIC ||
      ent.Variant == TearVariant.COIN
    ) {
      return true;
    }
  } else if (ent.Type == EntityType.FAMILIAR) {
    if (ent.Variant == FamiliarVariant.SAMSONS_CHAINS) {
      return true;
    }
  } else if (ent.Type == EntityType.KNIFE) {
    //!! interacción con Knife
    //&& data.isThrowable)
    return true;
    //!! faltan los proyectiles enemigos (metal pieces)
    //|| (ent.Type == EntityType.PROJECTILE && data.isMetalPiece))
  } else if (ent.ToNPC() !== undefined) {
    if (getNpcData(ent).coinAtached !== undefined) {
      return true;
    }
  }
  return false;
}
