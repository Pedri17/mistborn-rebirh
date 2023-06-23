local EnemyAllomancer = {}

local Pos = require("mod/tool/position")
local Str = require("mod/tool/string")
local Vect = require("mod/tool/vector")
local Enum = require("mod/data/enum")
local Type = require("mod/data/type")
local Fnc = require("mod/functions")
local Debug = require("mod/game/debug")

local MetalPiece = require("mod/game/entities/metalPiece")
local Physical = require("mod/game/items/physical")

function EnemyAllomancer.Init(mod)
    mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, EnemyAllomancer.EnemyAllomancerStart, Type.enemy.allomancer)
    mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, EnemyAllomancer.EnemyAllomancerUpdate, Type.enemy.allomancer)
end

--CALLBACK FUNCTIONS
function EnemyAllomancer:EnemyAllomancerStart(enemy)
    local eData = enemy:GetData()
    local stage = Game():GetLevel():GetStage()
    local room = Game():GetRoom()

    eData.selectedEntities = {}
    enemy:GetData().EnemyPowers = {}

    eData.modEnemy = true

    eData.numPlates = 3
    eData.allomancyCD = 0
    eData.usingPowerTime = 0
    eData.tryFind = 0
    eData.postShot = -1

    enemy.CollisionDamage = 0
    enemy.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
    
    --Add extra hp
    if stage >= 1 and stage <= 13 then
        eData.extraHP = (stage-1)*5
    end
    
    --Give variant powers
    enemy:GetData().EnemyPowers[enemy.Variant] = true

    --Close doors
    for i=0, 7, 1 do
        if room:GetDoor(i) ~= nil then
            room:GetDoor(i):Close(true)
        end
    end

end

function EnemyAllomancer:EnemyAllomancerUpdate(enemy)
    local room = Game():GetRoom()
    local sprite = enemy:GetSprite()
    local eData = enemy:GetData()
    local target = enemy:GetPlayerTarget()
    local pf = enemy.Pathfinder
    local debug = true

    if debug then
        Debug.setVariable(enemy, "AllomancyCD", eData.allomancyCD)
        Debug.setVariable(enemy, "TryFindCD", eData.tryFind)
        Debug.setVariable(enemy, "PostShot", eData.postShot)
        Debug.setVariable(enemy, "TimeUsingPower", eData.usingPowerTime)
        Debug.setVariable(enemy, "State", Str.enum.npcState[enemy.State])
    end

    --Extra hp (I don't know how to set variable max HP)
    if enemy.HitPoints<enemy.MaxHitPoints and eData.extraHP > 0 then
        local toMaxHP = enemy.MaxHitPoints-enemy.HitPoints
        if eData.extraHP >= toMaxHP then
            enemy:AddHealth(toMaxHP)
            eData.extraHP = eData.extraHP-toMaxHP
        else
            enemy:AddHealth(eData.extraHP)
            eData.extraHP = 0
        end
    end

    --Post init (vulnerable)
    if enemy.FrameCount > 5 and enemy.CollisionDamage ~= 1 then
        enemy.CollisionDamage = 1
        enemy.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
    end

    local params = ProjectileParams()
    local distancia = Vect.toDistance(enemy.Position, target.Position)
    if eData.moveTarget == nil then eData.moveTarget = target end
    eData.nearPickup = Fnc.metalPiece.findNearestPickup(enemy.Position, MetalPiece.MetalPiecesAlive, Enum.pieceVariant.PLATE, enemy, pf)
    eData.lastPosition = enemy.Position

    --Update cd
    if enemy.ProjectileCooldown>0 then enemy.ProjectileCooldown = enemy.ProjectileCooldown-1 end
    if eData.allomancyCD > 0 then eData.allomancyCD = eData.allomancyCD-1 end
    if eData.tryFind > 0 then eData.tryFind = eData.tryFind-1 end
    if eData.postShot >= 0 then eData.postShot = eData.postShot+1 end
    if eData.usingPowerTime > 0 then eData.usingPowerTime = eData.usingPowerTime-1 end

    --State animations
    if enemy.State == NpcState.STATE_MOVE then
        local dir = Vect.toDirection(enemy.Velocity)
        if not sprite:IsPlaying("Walk"..Str.enum.direction[dir]) then
            sprite:Play("Walk"..Str.enum.direction[dir], true)
        end

        sprite:PlayOverlay("Head"..Str.enum.direction[dir], true)
    elseif enemy.State == NpcState.STATE_IDLE then
        sprite:Play("WalkDown", true)
        sprite:PlayOverlay("HeadDown", true)
        enemy.Velocity = Vector(0,0)
    end

    --IA
    if enemy.FrameCount < 30 then
        eData.iaState = Enum.iaState.APPEAR
    elseif not pf:HasPathToPos(target.Position, false) then
        eData.iaState = Enum.iaState.IDLE
        enemy.State = NpcState.STATE_IDLE
    elseif Fnc.entity.isExisting(eData.nearPickup) and (eData.numPlates <= 0 or Vect.toDistance(eData.nearPickup.Position, enemy.Position) < 75) then --Take coin
        enemy.State = NpcState.STATE_MOVE
        eData.iaState = Enum.iaState.TAKE_COIN
        eData.moveTarget = eData.nearPickup
        if Vect.toDistance(eData.nearPickup.Position, enemy.Position) < 75 then
            enemy:AddVelocity(Vect.fromToEntity(enemy, eData.nearPickup, -1))
             --Take near anchorage
            if eData.nearPickup:GetData().isAnchorage and eData.allomancyCD <= 0 and MetalPiece.hasPhysicalPower(enemy) then
                if Fnc.tracer.throw(enemy, Vect.fromToEntity(eData.nearPickup, enemy, 1)) then
                    if EnemyAllomancer.hasPower(enemy, Enum.power.IRON) then
                        eData.usePower = Enum.power.IRON
                        eData.usingPowerTime = 120
                    elseif EnemyAllomancer.hasPower(enemy, Enum.power.STEEL) then
                        eData.usePower = Enum.power.STEEL
                        eData.usingPowerTime = 120
                    end
                    eData.allomancyCD = 20
                    eData.tryFind = 90
                end
            end
        else
            pf:FindGridPath(eData.nearPickup.Position, 1.2, 2, true)
        end
    else --Usual move
        eData.moveTarget = target
        enemy.State = NpcState.STATE_MOVE
        if distancia >= 180 then
            
            eData.iaState = Enum.iaState.APPROACHING
            pf:FindGridPath(target.Position, 1.2, 2, true)

        elseif distancia < 180 then

            eData.iaState = Enum.iaState.RECEDE
            pf:EvadeTarget(target.Position)
            enemy:AddVelocity(Vect.fromToEntity(enemy, target, 1))
            
        end
    end

    --Use pull/push to move
    if eData.allomancyCD<=0 and enemy.State == NpcState.STATE_MOVE and eData.tryFind <= 0 and MetalPiece.hasPhysicalPower(enemy) then
        eData.tryFind = 15
        local evade
        --Opposite direction when is on recede state
        if eData.iaState == Enum.iaState.RECEDE then evade = -1 else evade=1 end

        --If find a metalic entity behind him use steel to find entity
        if EnemyAllomancer.hasPower(enemy, Enum.power.STEEL) and Fnc.tracer.throw(enemy, Vect.fromToEntity(enemy, eData.moveTarget, 1*evade)) then
            eData.usePower = Enum.power.STEEL
            eData.usingPowerTime = 30
            eData.allomancyCD = 20
            eData.tryFind = 90
        end

         --If find a metalic entity in front of him use iron to find entity
        if EnemyAllomancer.hasPower(enemy, Enum.power.IRON) and Fnc.tracer.throw(enemy, Vect.fromToEntity(enemy, eData.moveTarget, -1*evade)) then
            eData.usePower = Enum.power.IRON
            eData.usingPowerTime = 30
            eData.allomancyCD = 20
            eData.tryFind = 90
        end
    end

    --Shot
    if enemy.State == NpcState.STATE_MOVE and distancia < 300 
    and enemy.ProjectileCooldown == 0
    and eData.numPlates > 0
    and eData.iaState ~= Enum.iaState.SHOT
    and room:CheckLine(enemy.Position, target.Position, 0, 0, false, false) then

        eData.iaState = Enum.iaState.SHOT
        eData.numPlates = eData.numPlates-1
        enemy.State = NpcState.STATE_ATTACK
        enemy:FireProjectiles(enemy.Position, Vect.fromToEntity(target, enemy, 14), 0, params)
        enemy.ProjectileCooldown = 80
        eData.postShot = 0

    end

    --Post shot
    if eData.postShot == 5 then

        sprite:PlayOverlay("Head"..Str.enum.direction[Vect.toDirection(Vect.fromToEntity(target, enemy, 1))], true)
        if eData.allomancyCD <= 0 and EnemyAllomancer.hasPower(enemy, Enum.power.STEEL) then

            local fromEntity
            if Fnc.entity.isExisting(eData.lastPlate) then
                fromEntity = eData.lastPlate
            else
                fromEntity = target
            end

            if Fnc.tracer.throw(enemy, Vect.fromToEntity(fromEntity, enemy, 1)) then
                eData.usePower = Enum.power.STEEL
                eData.usingPowerTime = math.random(5,25)
                eData.tryFind = 30
                eData.allomancyCD = 50
            end
        end
    end

    --Later post shot (2sec)
    if eData.postShot == 60 then
        if eData.allomancyCD <= 0 and EnemyAllomancer.hasPower(enemy, Enum.power.IRON) then

            local fromEntity
            if Fnc.entity.isExisting(eData.lastPlate) then
                fromEntity = eData.lastPlate
            elseif Fnc.entity.isExisting(eData.nearPickup) then
                fromEntity = eData.nearPickup
            else
                fromEntity = target
            end

            if Fnc.tracer.throw(enemy, Vect.fromToEntity(fromEntity, enemy, -1)) then
                eData.usePower = Enum.power.IRON
                eData.usingPowerTime = 30
                eData.tryFind = 30
                Debug.addMessage(enemy, "usar poder")
            end
            eData.allomancyCD = 60
        end
    end

    --Use power
    if eData.usingPowerTime > 0 then

        if eData.gridTouched then
            eData.usingPowerTime = 0
        else
            if eData.usePower == Enum.power.STEEL then
                eData.pulling = false; eData.pushing = true
            elseif eData.usePower == Enum.power.IRON then
                eData.pulling = true; eData.pushing = false 
            end
            Physical.use(enemy)
        end

        if enemy:CollidesWithGrid() then
            eData.usingPowerTime = 0
        end
    else
        if eData.selectedEntities ~= nil and #eData.selectedEntities > 0 then
            Fnc.tracer.deselectEntities(enemy)
        end
    end

    --Take coin
    for index, pickup in  pairs(MetalPiece.MetalPiecesAlive) do
        if Fnc.entity.isExisting(pickup) then
            MetalPiece.touchPickup(enemy, pickup)
        else
            table.remove(MetalPiece.MetalPiecesAlive, index)
        end
    end

    --Selected entities
    if eData.selectedEntities ~= nil then
        for index, selEntity in pairs(eData.selectedEntities) do

            if not selEntity:Exists() then
                Fnc.tracer.deselectEntityIndex(enemy, index)
            end

            if (not (Fnc.entity.is.metalPiecePickup(selEntity) 
            and selEntity:GetData().isAnchorage) 
            and (not Fnc.entity.is.metalPieceBullet(selEntity)) 
            and (not Fnc.entity.is.bottle(selEntity) and selEntity:GetData().isAnchorage)) then
                if not Pos.isNoneCollision(selEntity.Position) then
                    selEntity.Position = Game():GetRoom():FindFreeTilePosition(selEntity.Position,25)
                end
            end

        end
    end

    if enemy:HasMortalDamage() and eData.bottleSpawned == nil then
        eData.bottleSpawned = Isaac.Spawn(EntityType.ENTITY_PICKUP, Type.pickup.mineralBottle, 1, enemy:GetData().lastPosition, Vector(0,0), nil)
    end

end

--FUNCTIONS
EnemyAllomancer.hasPower = function(enemy, power)
    local eData = enemy:GetData()
    return eData.EnemyPowers ~= nil and eData.EnemyPowers[power] ~= nil and eData.EnemyPowers[power]
end

EnemyAllomancer.hasPhysicalPower = function(enemy)
    return MetalPiece.hasPower(enemy, Enum.power.IRON) or  MetalPiece.hasPower(enemy, Enum.power.STEEL)
end

return EnemyAllomancer