local Mark = {}

local Pos = require("mod/tool/position")
local Vect = require("mod/tool/vector")
local Conf = require("mod/data/config")
local Type = require("mod/data/type")
local Fnc = require("mod/functions")

function Mark.Init(mod)
    mod:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, Mark.PickupStart, Type.pickup.floorMark)
    mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, Mark.PickupUpdate)
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, Mark.RoomClear)
end

--VARIABLES
Mark.ref = {
    [0] = "gfx/effects/mark/Iron.png",
    [1] = "gfx/effects/mark/Steel.png",
}

--CALLBACK FUNCTIONS
function Mark:RoomClear(rng, spawnPos)
    local room = Game():GetRoom()

    if Fnc.somePlayerIsType(Type.player.allomancer) then
        local pos = rng:RandomFloat()
        local minMineral
        local n

        --Get minMineral on players
        for pID=0, Game():GetNumPlayers()-1, 1 do
            local player = Isaac.GetPlayer(pID)
            if Fnc.hasSomePower(player) then
                if minMineral == nil or minMineral > player:GetData().mineralBar then minMineral = player:GetData().mineralBar end
            end
        end

        --If there's not a minMineral set pos to 1%
        if minMineral ~= nil then
            local per = minMineral/Conf.allomancy.MAX_BAR
            n = (1-per)/3
        else
            n = 0.01
        end

        --Get random pos
        if pos < n or Isaac.GetPlayer(0):GetData().spawnMark then
            local randPos = room:GetRandomPosition(50)
            local try = 0
            while (not (Pos.isNoneCollision(randPos) or Pos.isNoneCollision(randPos+Vector(0,20)) or Pos.isNoneCollision(randPos+Vector(0,-20)) or Pos.isNoneCollision(randPos+Vector(20,0)) or Pos.isNoneCollision(randPos+Vector(-20,0)))
            or not room:CheckLine(Isaac.GetPlayer(0).Position, randPos, 0, 50, false, false)
            or #Isaac.FindInRadius(randPos, 50, EntityPartition.PLAYER)>=1)
            and try < 1000 do
                try = try+1
                randPos = room:GetRandomPosition(50)
            end

            --If found a point
            if try < 1000 then
                Fnc.spawnMark(randPos)
                Isaac.GetPlayer(0):GetData().spawnMark = false
            else
                Isaac.GetPlayer(0):GetData().spawnMark = true
            end
        end
    end
end

function Mark:PickupStart(pickup)
    pickup:GetSprite():ReplaceSpritesheet(0, Mark.ref[pickup.SubType])
    pickup:GetSprite():LoadGraphics()
    pickup.DepthOffset = -200
    pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    pickup.GridCollisionClass = GridCollisionClass.COLLISION_NONE
end

function Mark:PickupUpdate(pickup)
    local data = pickup:GetData()
    local sprite = pickup:GetSprite()

    --To floor mark pickup
    if pickup.Variant == Type.pickup.floorMark then
        pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

        if data.randomFrame == nil then data.randomFrame = math.random(60,120) end

        if sprite:GetFrame() > data.randomFrame then
            data.randomFrame = math.random(60,120)
            sprite:Play("Idle")
            sprite:SetFrame(0)
        end

        for pID=0, Game():GetNumPlayers()-1, 1 do
            local player = Isaac.GetPlayer(pID)

            if Fnc.entity.entityCollision(player, pickup) then
                local enemy = Isaac.Spawn(610, pickup.SubType, 1, pickup.Position, Vect.make(0), nil)
                pickup:Remove()
            end
        end
    end
end

return Mark