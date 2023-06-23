local Bottle = {}

local Pos = require("mod/tool/position")
local Room = require("mod/tool/room")
local Sound = require("mod/tool/sound")
local Conf = require("mod/data/config")
local Type = require("mod/data/type")
local Fnc = require("mod/functions")

local Debug = require("mod/game/debug")

Bottle.Init = function(mod)
    Bottle.onRocksSpawned = 0
    
    mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, Bottle.PickupUpdate, Type.pickup.mineralBottle)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, Bottle.LevelEnter)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, Bottle.RoomEnter)
end

--VARIABLES
Bottle.MINERAL_TAKING_BOTTLE = 0.2
Bottle.ROCK_APPEAR = 0.005
Bottle.ANCHORAGE_POS = {
    [GridEntityType.GRID_ROCK] = {
        [0] = Vector(-7, -4),
        [1] = Vector(-9, 5),
        [2] = Vector(-6, -4),
        [1000] = Vector(-8, -6),
        [1001] = Vector(-6, -5),
        [1002] = Vector(-4, -3),
        [1003] = Vector(-6, -8),
        [1004] = Vector(-6, -13),
        [1005] = Vector(0, -8),
        [1006] = Vector(-5, -8),
        [1007] = Vector(-6, -8),
    },
    [GridEntityType.GRID_ROCK_BOMB] = Vector(-6, 3),
    [GridEntityType.GRID_ROCK_ALT] = Vector(0, -14),
    [GridEntityType.GRID_ROCK_ALT2] = Vector(0,0)
}

--CALLBACK FUNCTIONS
function Bottle:LevelEnter()
    Bottle.onRocksSpawned = 0
end

function Bottle:RoomEnter()
    if Fnc.somePlayerIsType(Type.player.allomancer) then
        if Game():GetLevel():GetCurrentRoomDesc().VisitedCount == 1 then
            local initRocks = Room.getGridRockEntities()

            for _, grid in pairs(initRocks) do
                local posibility = math.random()

                if posibility < Bottle.ROCK_APPEAR/(Bottle.onRocksSpawned+1) then

                    Bottle.onRocksSpawned = Bottle.onRocksSpawned+1
                    local spawnPos = grid.Position
                    if Bottle.ANCHORAGE_POS[grid:GetType()][grid:GetVariant()] ~= nil then
                        spawnPos = spawnPos + Bottle.ANCHORAGE_POS[grid:GetType()][grid:GetVariant()]
                    else
                        spawnPos = spawnPos + Bottle.ANCHORAGE_POS[grid:GetType()]
                    end
                    local thisBottle = Isaac.Spawn(EntityType.ENTITY_PICKUP, Type.pickup.mineralBottle, 1, spawnPos, Vector(0,0), nil)
                    Bottle.toAnchorage(thisBottle)
                end
            end
        else
            for _, thisBottle in pairs(Isaac.GetRoomEntities()) do
                if Fnc.entity.is.bottle(thisBottle) and Bottle.isGridSpawnerRock(Game():GetRoom():GetGridEntityFromPos(thisBottle.Position)) then
                    Bottle.toAnchorage(thisBottle)
                end
            end
        end
    end
end

function Bottle:PickupUpdate(pickup)
    local data = pickup:GetData()

    --Spawn
    if pickup.FrameCount == 1 and pickup:GetSprite():IsPlaying("Appear") then
        Sound.play(Sound.SPAWN_BOTTLE,1,0,false,1)
    end

    --To anchorage
    if data.isAnchorage then
        pickup:GetSprite():Play("Stucked")

        if data.gridEntityTouched ~= nil then
            if data.gridEntityTouched.State ~= 1 then
                data.isAnchorage = false
                pickup:GetSprite():Play("Idle",true)
                pickup.Friction = Conf.USUAL_PICKUP_FRICTION
                pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
            else
                pickup.Friction = 0
                pickup.Velocity = Vector(0,0)
                if Bottle.ANCHORAGE_POS[data.gridEntityTouched:GetType()][data.gridEntityTouched:GetVariant()] ~= nil then
                    pickup.Position = data.gridEntityTouched.Position + Bottle.ANCHORAGE_POS[data.gridEntityTouched:GetType()][data.gridEntityTouched:GetVariant()]
                else
                    pickup.Position = data.gridEntityTouched.Position + Bottle.ANCHORAGE_POS[data.gridEntityTouched:GetType()]
                end
                pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
            end
        end
    end

    for pID=0, Game():GetNumPlayers()-1, 1 do
        local player = Isaac.GetPlayer(pID)
        local pData = player:GetData()

        --Take bottle
        if pickup:GetSprite():IsPlaying("Idle") then
            if Fnc.entity.entityCollision(player,pickup) then
                pickup:GetSprite():Play("Collect", true)
                Sound.play(Sound.TAKE_BOTTLE,1,0,false,1.2)
                pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                if pData.mineralBar ~= nil then
                    pData.mineralBar = pData.mineralBar+Conf.allomancy.MAX_BAR*Bottle.MINERAL_TAKING_BOTTLE
                    if pData.mineralBar > Conf.allomancy.MAX_BAR then
                        pData.mineralBar = Conf.allomancy.MAX_BAR
                    end
                end
                pickup.Velocity = Vector(0,0)
            end
        else
            if pickup:GetSprite():IsFinished("Collect") then
                pickup:Remove()
            end
        end
    end

end

--FUNCTIONS
Bottle.toAnchorage = function(bottle) --(EntityPickup) Transform bottle pickup to anchorage.
    bottle:GetData().gridEntityTouched = Game():GetRoom():GetGridEntityFromPos(bottle.Position)
    bottle:GetData().isAnchorage = true
    bottle:GetData().inWall = false
    bottle:GetSprite():Play("Stucked")
    bottle.Friction = 100
end

Bottle.isGridSpawnerRock = function(gridEntity) --(GridEntity)->[Bool] Return if gridEntity is a destroyable rock.
    return gridEntity ~= nil and
            (gridEntity:GetType() == GridEntityType.GRID_ROCK or
            gridEntity:GetType() == GridEntityType.GRID_ROCK_BOMB or
            gridEntity:GetType() == GridEntityType.GRID_ROCK_ALT or
            gridEntity:GetType() == GridEntityType.GRID_ROCK_ALT2)
end

return Bottle