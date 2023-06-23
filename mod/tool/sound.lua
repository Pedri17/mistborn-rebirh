local sound = {}

sound = {
    SPAWN_BOTTLE = Isaac.GetSoundIdByName("glassFall"),
    TAKE_BOTTLE = Isaac.GetSoundIdByName("drink"),
    COIN_HIT = Isaac.GetSoundIdByName("coinHit"),
    COIN_THROW = Isaac.GetSoundIdByName("coinThrow"),
    ENTITY_CRASH = Isaac.GetSoundIdByName("entityCrash")
}

sound.play = function(soundID, volume, delay, loop, pitch) -- (Sound, Num, Num, Bool, Num) Play a sound.
    local soundEntity = Isaac.Spawn(30, 1, 1, Vector(50000,50000), Vector(0,0), nil)
    soundEntity.Visible = false
    soundEntity:ToNPC():PlaySound(soundID, volume, delay, loop, pitch)
    soundEntity:Remove()
end

return sound