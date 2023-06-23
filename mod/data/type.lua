local type = {}

type.item = { --Item variant
    steelLerasiumAlloy = Isaac.GetItemIdByName("Steel-Lerasium alloy"),
    ironLerasiumAlloy = Isaac.GetItemIdByName("Iron-Lerasium alloy"),
}

type.tear = { --Tear variant
    metalPiece = Isaac.GetEntityVariantByName("Metalic piece")
}

type.pickup = { --Pickup variant
    throwedCoin = Isaac.GetEntityVariantByName("Throwed coin"),
    mineralBottle = Isaac.GetEntityVariantByName("Bottle"),
    floorMark = Isaac.GetEntityVariantByName("Iron Floor mark"),
}

type.costume = { --Costume variant
    playerAllomancer = Isaac.GetCostumeIdByPath("gfx/characters/character_allomancer.anm2")
}

type.player = { --Player variant
    allomancer = Isaac.GetPlayerTypeByName("The Allomancer")
}

type.enemy = { --Entity type
    allomancer = Isaac.GetEntityTypeByName("Iron Enemy Allomancer")
}

return type