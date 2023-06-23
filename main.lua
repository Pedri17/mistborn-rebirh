MR = RegisterMod("MistbornRebirth",1)

-------------------------
--      FILES
-------------------------

local json = require("json")

local Array = require("mod/tool/array")
local Math = require("mod/tool/math")
local Pos = require("mod/tool/position")
local Room = require("mod/tool/room")
local Sound = require("mod/tool/sound")
local Str = require("mod/tool/string")
local Vect = require("mod/tool/vector")
local Enum = require("mod/data/enum")
local Conf = require("mod/data/config")
local Type = require("mod/data/type")
local Fnc = require("mod/functions")

local Hud = require("mod/game/hud")
local Debug = require("mod/game/debug")
local Player = require("mod/game/entities/player")
local Bottle = require("mod/game/entities/bottle")
local MetalPiece = require("mod/game/entities/metalPiece")
local Mark = require("mod/game/entities/mark")
local EnemyAllomancer = require("mod/game/entities/enemyAllomancer")

-------------------------
--      INIT
-------------------------
Hud.Init(MR)
Debug.Init(MR)
Player.Init(MR)
Bottle.Init(MR)
MetalPiece.Init(MR)
Mark.Init(MR)
EnemyAllomancer.Init(MR)

-------------------------
--      VARIABLES
-------------------------

MR.marks = { --0=not, 1=normal, 2=hard
    [0] = 0, --Paper
    [1] = 0, --Heart
    [2] = 0, --Cross
    [3] = 0, --Inverted Cross
    [4] = 0, --Star
    [5] = 0, --Polaroid
    [6] = 0, --Negative
    [7] = 0, --Brimstone
    [8] = 0, --Greed
    [9] = 0, --Hush
    [10] = 0, --Knife
    [11] = 0, --DadsNote
}

------------------------------------
--           FUNCTIONS
-------------------------------------

local saveInfo = function() --Save mod data
    local info = {}
    info.marks = MR.marks
    info.bottlesSpawned = Bottle.onRocksSpawned
    info.players = {}
    for i=1, Game():GetNumPlayers(), 1 do
        local pData = Isaac.GetPlayer(i):GetData()
        local pTable = {
            id = i,
            mineralBar = pData.mineralBar,
            controlsChanged = pData.controlsChanged
        }
        table.insert(info.players, i, pTable)
    end
    MR:SaveData(json.encode(info))

end

local loadInfo = function() --Load mod data
    local info = json.decode(MR:LoadData())
    if info.marks ~= nil then MR.marks = info.marks end
    if info.bottlesSpawned ~= nil then Bottle.onRocksSpawned = info.bottlesSpawned end
    for i=1, Game():GetNumPlayers(), 1 do
        local pData = Isaac.GetPlayer(i):GetData()
        if info.players[i] ~= nil then
            if info.players[i].mineralBar ~= nil then pData.mineralBar = info.players[i].mineralBar end
            if info.players[i].controlsChanged ~= nil then pData.controlsChanged = info.players[i].controlsChanged else pData.controlsChanged = false end
        end
    end
end

local putMark = function(markId) -- (MarkID) Put mark on marks table considering the difficulty  
    if Game().Difficulty == 0 and MR.marks[markId] < 1 then
        MR.marks[markId] = 1
    elseif Game().Difficulty == 1 and MR.marks[markId] < 2 then
        MR.marks[markId] = 2
    end
end

--GAME
function MR:StartGame(continued)
    if continued then
        loadInfo()
    end
end

function MR:GameExit(notEnd)
    saveInfo()
end

function MR:GameEnd(isOver) 
    if not isOver then
        if Game().Difficulty == 2 and MR.marks[Enum.markId.GREED] < 1 then
            MR.marks[Enum.markId.GREED] = 1
        elseif Game().Difficulty == 3 and MR.marks[Enum.markId.GREED] < 2 then
            MR.marks[Enum.markId.GREED] = 2
        end
    end
end

function MR:RoomClear(rng, spawnPos)
    local room = Game():GetRoom()

    --Mark bossrush
    if room:GetType()==RoomType.ROOM_BOSSRUSH and Fnc.somePlayerIsType(Type.player.allomancer) then
        putMark(Enum.markId.STAR)
    end
end

function MR:NpcDeath(enemy)
    --Marks
    if Fnc.somePlayerIsType(Type.player.allomancer) then
        if enemy.Type == EntityType.ENTITY_MOMS_HEART then --MOM
            putMark(Enum.markId.HEART)
        elseif enemy.Type == EntityType.ENTITY_ISAAC then
            if enemy.Variant == 0 then --ISAAC
                putMark(Enum.markId.CROSS)
            elseif enemy.Variant == 1 then --???
                putMark(Enum.markId.POLAROID)
            end
        elseif enemy.Type == EntityType.ENTITY_SATAN then --Satan
            putMark(Enum.markId.INVERTED_CROSS)
        elseif enemy.Type == EntityType.ENTITY_THE_LAMB then --Lamb
            putMark(Enum.markId.NEGATIVE)
        elseif enemy.Type == EntityType.ENTITY_MEGA_SATAN_2 then --Mega satan
            putMark(Enum.markId.BRIMSTONE)
        elseif enemy.Type == EntityType.ENTITY_HUSH then --Hush
            putMark(Enum.markId.HUSH)
        elseif enemy.Type == EntityType.ENTITY_DELIRIUM then --Delirium
            putMark(Enum.markId.PAPER)
        elseif enemy.Type == EntityType.ENTITY_MOTHER then --Mega satan
            putMark(Enum.markId.KNIFE)
        elseif enemy.Type == EntityType.ENTITY_BEAST then --The beast
            putMark(Enum.markId.DADS_NOTE)
        end
    end
end

function MR:PickupUpdate(pickup)
    local data = pickup:GetData()
    local sprite = pickup:GetSprite()

    --Selected pickups
    if data.selected then
        --Damage if it goes too fast
        if Vect.biggerThan(pickup.Velocity,Conf.allomancy.velocity.MIN_TO_PICKUP_DAMAGE) then
            for _, collider in pairs(Isaac.GetRoomEntities()) do

                if not Fnc.entity.equal(data.from, collider) and Fnc.entity.entityCollision(collider, pickup) then
                    if (data.from.Type==EntityType.ENTITY_PLAYER and collider:IsEnemy()) or (data.from.Type~=EntityType.ENTITY_PLAYER) then
                        local dmg
                        if data.from.Type==EntityType.ENTITY_PLAYER then
                            dmg = data.from.Damage*2*Conf.allomancy.FAST_CRASH_DMG_MULT
                        else
                            dmg = 1
                        end


                        if collider:GetData().hitFrame == nil or (Game():GetFrameCount()-collider:GetData().hitFrame > Conf.allomancy.time.BETWEEN_HIT_DAMAGE) then
                            collider:TakeDamage(dmg,0,EntityRef(data.from),60)
                            collider:GetData().hitFrame = Game():GetFrameCount()
                        end
                    end
                end
            end
        end
    end

    --Magneto interaction
    if  pickup.Variant == Type.pickup.mineralBottle or pickup.Variant == Type.pickup.throwedCoin then
        for pID=0, Game():GetNumPlayers()-1, 1 do
            local player = Isaac.GetPlayer(pID)

            if player:HasCollectible(53) then
                pickup:AddVelocity(Vect.fromToEntity(player, pickup, 0.08))

                if pickup.Variant == Type.pickup.mineralBottle then
                    pickup.GridCollisionClass = GridCollisionClass.COLLISION_WALL
                end
            end
        end
    end
end

function MR:EnemyCollision(enemy, hitEntity)
    --SI VA MUY RÁPIDO HACE DAÑO A OTROS
    local fromTear = enemy:GetData().stickTear
    local fromEntity = nil

    if fromTear ~= nil then
        fromEntity = enemy:GetData().stickTear:GetData().from
    end

    if fromEntity ~= nil
        and enemy:IsEnemy()
        and fromTear ~= nil 
        and Vect.biggerThan(enemy.Velocity,Conf.allomancy.velocity.MIN_DOUBLE_HIT)
    then
        if hitEntity:IsEnemy() and hitEntity.Index ~= enemy.Index then

            if (enemy:GetData().hitFrame == nil) or (Game():GetFrameCount()-enemy:GetData().hitFrame > Conf.allomancy.time.BETWEEN_DOUBLE_HIT) then

                hitEntity:AddVelocity((Vect.rotateNinety(enemy.Velocity)))
                hitEntity:TakeDamage(fromTear:GetData().BaseDamage*Conf.allomancy.FAST_CRASH_DMG_MULT,0,EntityRef(fromEntity),60)
                enemy:TakeDamage(fromTear:GetData().BaseDamage*Conf.allomancy.FAST_CRASH_DMG_MULT,0,EntityRef(fromEntity),120)
                enemy:GetData().hitFrame = Game():GetFrameCount()
                hitEntity:GetData().hitFrame = Game():GetFrameCount()

            end
            fromTear.StickTarget = nil
        end
    end
end

MR:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, MR.StartGame)
MR:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, MR.PickupUpdate)
MR:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, MR.GameExit)
MR:AddCallback(ModCallbacks.MC_POST_GAME_END, MR.GameEnd)
MR:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, MR.RoomClear)
MR:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, MR.EnemyCollision)
MR:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, MR.NpcDeath)