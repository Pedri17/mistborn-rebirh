local Fnc = {}

local Array = require("mod/tool/array")
local Math = require("mod/tool/math")
local Pos = require("mod/tool/position")
local Room = require("mod/tool/room")
local Sound = require("mod/tool/sound")
local Vect = require("mod/tool/vector")
local Enum = require("mod/data/enum")
local Conf = require("mod/data/config")
local Type = require("mod/data/type")

Fnc.somePlayerIsType = function(playerType)
    for pID=0, Game():GetNumPlayers()-1, 1 do
        local player = Isaac.GetPlayer(pID)
        if player:GetPlayerType()==playerType then return true end
    end
    return false
end

Fnc.hasSomePower = function(entity)
    local eData = entity:GetData()
    return eData.AllomanticPowers ~= nil and eData.AllomanticPowers[1] ~= -1
end

Fnc.hasPhysicalPower = function(entity)
    return Fnc.hasPower(entity, Enum.power.IRON) or Fnc.hasPower(entity, Enum.power.STEEL)
end

Fnc.hasPower = function(entity, power) --(Player, String)->[Bool] Return if player has a specific power.
    local is = false
    if entity:GetData().AllomanticPowers ~= nil then
        for i=1,3,1 do
            if entity:GetData().AllomanticPowers[i].has == power then
                is = true
            end
        end
    end
    return is
end

Fnc.spendMinerals = function(data, time, mult) --(EntityData, num, num) Make entity spend minerals.
    if time ~= nil then
        local tiempo = Isaac.GetFrameCount()
        local tiempoEmpujando = tiempo - time
        data.usePowerFrame = Isaac.GetFrameCount()

        if tiempoEmpujando ~= 0 then
            data.mineralBar = data.mineralBar-(tiempoEmpujando*mult)
            data.movingTime=tiempo
        end
    end
end

Fnc.fireTearVelocity = function(player) --(Player)->[Velocity] Returns tear velocity from player shot
    local speed = player.ShotSpeed*10
    local dir =player:GetHeadDirection()
    local vectorDir = Vect.fromDirection(dir)
    local vel = vectorDir*speed
    vel = vel+(player:GetTearMovementInheritance(vectorDir))

    return vel
end

Fnc.spawnMark = function(position)
    local sel = math.random(0,1)
    return Isaac.Spawn(EntityType.ENTITY_PICKUP, Type.pickup.floorMark, sel, position-Vector(8,8), Vector(0,0), nil)
end

Fnc.entity = {
    is = {
        metalicEntity = function(entity) --(Entity)->[Bool] Return if entity is metalic.
            local data = entity:GetData()
            return ((entity.Type == EntityType.ENTITY_PICKUP)
                        and ((entity.Variant == Type.pickup.throwedCoin)
                        or entity.Variant == PickupVariant.PICKUP_COIN
                        or entity.Variant == PickupVariant.PICKUP_KEY
                        or entity.Variant == PickupVariant.PICKUP_LOCKEDCHEST
                        or entity.Variant == PickupVariant.PICKUP_LIL_BATTERY
                        or entity.Variant == PickupVariant.PICKUP_CHEST
                        or entity.Variant == PickupVariant.PICKUP_MIMICCHEST
                        or entity.Variant == PickupVariant.PICKUP_OLDCHEST
                        or entity.Variant == PickupVariant.PICKUP_SPIKEDCHEST
                        or entity.Variant == PickupVariant.PICKUP_ETERNALCHEST
                        or entity.Variant == PickupVariant.PICKUP_HAUNTEDCHEST
                        or entity.Variant == Type.pickup.mineralBottle))
                    or ((entity.Type == EntityType.ENTITY_TEAR)
                        and ((data.isMetalPiece
                            --Not select bosses
                            and (entity:ToTear().StickTarget==nil or (entity:ToTear().StickTarget~=nil and not entity:ToTear().StickTarget:IsBoss()))
                            --Not select sub ludovico coins
                            and not data.isSubLudovicoTear)
                        or (entity:ToTear():HasTearFlags(TearFlags.TEAR_CONFUSION))
                        or (entity:ToTear():HasTearFlags(TearFlags.TEAR_ATTRACTOR))
                        or (entity:ToTear():HasTearFlags(TearFlags.TEAR_GREED_COIN))
                        or (entity:ToTear():HasTearFlags(TearFlags.TEAR_MIDAS))
                        or (entity:ToTear():HasTearFlags(TearFlags.TEAR_MAGNETIZE))
                        or (entity.Variant==TearVariant.METALLIC)
                        or (entity.Variant==TearVariant.COIN)))
                    or ((entity.Type == EntityType.ENTITY_FAMILIAR) 
                        and (entity.Variant == FamiliarVariant.SAMSONS_CHAINS))
                    or (entity.Type == EntityType.ENTITY_KNIFE
                        and data.isThrowable)
                    or (data.coinAtached ~= nil and data.coinAtached)
                    or (entity.Type == EntityType.ENTITY_PROJECTILE and data.isMetalPiece)
        end,

        metalPiecePickup = function(entity) --(Entity)->[Bool] Return if entity is a metalicPiece pickup.
            return entity.Type == EntityType.ENTITY_PICKUP and (entity.Variant==Type.pickup.throwedCoin or entity:GetData().isMetalPiece)
        end,

        metalPieceBullet = function(entity) --(Entity)->[Bool] Return if entity is a metalicPiece tear
            return (entity.Type == EntityType.ENTITY_TEAR and entity.Variant == Type.tear.metalPiece) 
                or (entity.Type==EntityType.ENTITY_PROJECTILE and entity:GetData().isMetalPiece)
        end,

        bottle = function(entity) --(Entity)->[Bool] Return if entity is a bottle.
            return entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == Type.pickup.mineralBottle
        end,

        tracer = function(entity) --(Entity)->[Bool] Return if entity is a tracer
            return entity.Type == EntityType.ENTITY_EFFECT and entity:GetData().isTracer
        end,
    },

    collideGrid = function(entity)
        if not entity:GetData().gridTouched and (entity:CollidesWithGrid() or Pos.isWall(entity.Position) or 
        (not Pos.isNoneCollision(entity.Position) and (entity.Type ~= EntityType.ENTITY_PLAYER or (entity.Type == EntityType.ENTITY_PLAYER and not entity:ToPlayer().CanFly)))) then
            entity:GetData().gridTouched = true
            if (Vect.biggerThan(entity.Velocity,10)) then
                entity.Velocity =(entity.Velocity)*-0.1
            end
            Sound.play(Sound.ENTITY_CRASH, math.abs(Vect.getHigher(entity.Velocity)/15), 0, false, 1)
        end
    end,

    entityCollision = function(e1,e2) --(Entity, Entity)->[Bool] Returns if entities are colliding.
        return (e1.Position - e2.Position):Length() < e1.Size + e2.Size
    end,

    isNear = function(findEntity, fromEntity, radius) --(Entity, Entity, Num)->[Bool] Returns if findEntity is near fromEntity in a radius.
        local nearEntities = Isaac.FindInRadius(fromEntity.Position, radius, Fnc.ent.typeToPartition(findEntity))
        for _, e in pairs(nearEntities) do
            if Fnc.ent.equal(e, findEntity) then
                return true
            end
        end
        return false
    end,

    isExisting = function(entity) --(Entity)->[Bool] Returns if entity is not nil and exists.
        return entity~=nil and entity:Exists()
    end,

    typeToPartition = function(entity) --(Entity)->[EntityPartition] Returns entity partition from entity type.
        local eType = entity.Type
        if eType==EntityType.ENTITY_FAMILIAR then return EntityPartition.FAMILIAR
        elseif eType==EntityType.ENTITY_PROJECTILE then return EntityPartition.BULLET
        elseif eType==EntityType.ENTITY_TEAR then return EntityPartition.TEAR
        elseif entity:IsEnemy() then return EntityPartition.ENEMY
        elseif eType==EntityType.ENTITY_PICKUP then return EntityPartition.PICKUP
        elseif eType==EntityType.ENTITY_PLAYER then return EntityPartition.PLAYER
        elseif eType==EntityType.ENTITY_EFFECT then return EntityPartition.EFFECT
        else return 0xffffffff end
    end,

    equal = function(e1, e2) --(Entity, Entity)->[Bool] Returns if are the same entity.
        if e1 ~= nil and e2 ~= nil then
            return GetPtrHash(e1) == GetPtrHash(e2)
        else
            return nil
        end
    end
}

Fnc.tracer = {
    MAX_TIME_TO_USE_LAST_SHOT_DIRECTION = 30,
    MAX_RADIUS = 100,

    deselectEntities = function(entity) --(Entity) Deselect all selected entities from entity.
        local data = entity:GetData()

        if data.selectedEntities ~= nil then
            for _, selEntity in pairs(data.selectedEntities) do
                selEntity:GetData().selected = false
            end
            data.selectedEntities = {}
            data.focusSelection = 0
        else
            data.selectedEntities = {}
        end
    end,

    deselectEntity = function(entity) --(Entity) Deselect a specific entity where is selected (from Entity).
        local data = entity:GetData()
        for index, selEntity in pairs(data.from:GetData().selectedEntities) do
            if GetPtrHash(entity) == GetPtrHash(selEntity) then
                selEntity:GetData().selected = false
                table.remove(data.from:GetData().selectedEntities, index)
            end
        end
    end,

    deselectEntityIndex = function(fromEntity, index) --(Entity, Num) Deselect entity from a specific table (fromEntity table) with its index.
        local selEntities = fromEntity:GetData().selectedEntities
        if selEntities[index] ~= nil then
            selEntities[index]:GetData().selected = false
            table.remove(selEntities, index)
        end
    end,

    selectEntity = function(fromEntity, entity) --(Entity, Entity) Select entity to fromEntity table.
        entity:GetData().from = fromEntity
        entity:GetData().selected = true
        entity:GetData().gridTouched = false
        if fromEntity:GetData().selectedEntities ~= nil then table.insert(fromEntity:GetData().selectedEntities, entity) end
    end,

    throw = function(entity, ...) --(Entity) Throw tracer from entity (direction just ready to players).
        local args = {...}
        local data = entity:GetData()

        Fnc.tracer.deselectEntities(entity)
        data.gridTouched = false
        data.movingTime = Isaac.GetFrameCount()

        --Select direction
        local direction
        if entity.Type == EntityType.ENTITY_PLAYER then
            if  Vect.someMin(Vect.absolute(entity:GetShootingJoystick()), 0.3) then
                direction = entity:GetShootingJoystick()
            elseif data.shotFrame ~= nil and Isaac.GetFrameCount()-data.shotFrame <= Fnc.tracer.MAX_TIME_TO_USE_LAST_SHOT_DIRECTION then
                direction = data.lastDirectionShooting
            elseif not Vect.isZero(entity:GetMovementInput()) then
                direction = entity:GetMovementInput()
            elseif not Vect.isZero(data.lastDirectionShooting) then
                direction = data.lastDirectionShooting
            else
                direction = Vector(0,0)
            end
            direction = (Vect.baseOne(direction))
        elseif args[1] ~= nil then
            direction = Vect.baseOne(args[1])
        end

        --Throw tracer
        local pointer = entity.Position
        local someSelect = false
        while not Pos.isWall(pointer) do
            --Select entities
            local foundEntities = Isaac.FindInRadius(pointer, Math.upperBound(5+entity.Position:Distance(pointer)/4, Fnc.tracer.MAX_RADIUS), 0xFFFFFFFF)
            for _, sEntity in pairs(foundEntities) do
                if Fnc.entity.is.metalicEntity(sEntity) and not Array.containsEntity(entity:GetData().selectedEntities,sEntity) then

                    --Ensure focus selection
                    if data.focusSelection == 0 then
                        if sEntity.Type==EntityType.ENTITY_TEAR then
                            --If find a enemy focus it deselecting other entities
                            if sEntity:ToTear().StickTarget ~= nil then
                                Fnc.tracer.focusEnemy(sEntity, entity)
                            else
                                Fnc.tracer.focusTear(sEntity, entity)
                            end
                        end
                        Fnc.tracer.selectEntity(entity, sEntity)

                    --If focus just add other enemies
                    elseif data.focusSelection == 2 and sEntity.Type==EntityType.ENTITY_TEAR and sEntity:ToTear().StickTarget ~= nil then
                        Fnc.tracer.selectEntity(entity, sEntity)
                    elseif data.focusSelection == 1 and sEntity.Type==EntityType.ENTITY_TEAR then
                        if sEntity:ToTear().StickTarget ~= nil then
                            Fnc.tracer.focusEnemy(sEntity, entity)
                        end
                        Fnc.tracer.selectEntity(entity, sEntity)
                    end
                    someSelect = true
                end
            end
            --Move pointer
            pointer = pointer + direction*5
        end
        --Not selected any entity
        if not someSelect then
            --If not select any entity select this entity
            if entity.Type==EntityType.ENTITY_PLAYER and entity:GetData().controlsChanged then
                --Ludovico interaction
                if (Fnc.entity.isExisting(entity:GetData().LudovicoTear) and entity:GetData().LudovicoTear:GetData().isMetalPiece) then
                    Fnc.tracer.selectEntity(entity, entity:GetData().LudovicoTear)
                elseif Fnc.entity.isExisting(entity:GetData().mainKnife) and Fnc.entity.isExisting(entity:GetData().mainKnife:GetData().knifeTear) then
                    Fnc.tracer.selectEntity(entity, entity:GetData().mainKnife:GetData().knifeTear)
                end
            end
            if Fnc.entity.isExisting(entity:GetData().lastCoin) then
                Fnc.tracer.selectEntity(entity, entity:GetData().lastCoin)
            end 
        end

        return someSelect
    end,

    focusEnemy = function(sEntity, fromEntity) --(Entity, Entity) Focus enemies on tracer selection (deselects other entities).
        local data = fromEntity:GetData()
        sEntity:ToTear().StickTarget:GetData().gridTouched = false
        data.focusSelection = 2
        for id, selEntity in pairs(fromEntity:GetData().selectedEntities) do
            if not (selEntity.Type==EntityType.ENTITY_TEAR and selEntity:ToTear().StickTarget ~= nil) then
                Fnc.tracer.deselectEntityIndex(fromEntity, id)
            end
        end
    end,

    focusTear = function(sEntity, fromEntity) --(Entity, Entity) Focus tears on tracer selection (deselects other entities).
        local data = fromEntity:GetData()

        data.focusSelection = 1
        for id, selEntity in pairs(fromEntity:GetData().selectedEntities) do
            if not (selEntity.Type==EntityType.ENTITY_TEAR) then
                Fnc.tracer.deselectEntityIndex(fromEntity, id)
            end
        end
    end
}

Fnc.metalPiece = {
    collideGrid = function(entity) --(MetalPiece) Detects collisions and manages it.
        local tearData = entity:GetData()
        if not tearData.collision and (entity:CollidesWithGrid() or Pos.isWall(entity.Position) or (entity.Type==EntityType.ENTITY_TEAR and (entity:ToTear():HasTearFlags(TearFlags.TEAR_LUDOVICO)) and Room.touchLimit(entity.Position)))
        --Ludovico interaction: just consider collision when is fast
        and ((entity.Type==EntityType.ENTITY_TEAR and (not entity:ToTear():HasTearFlags(TearFlags.TEAR_LUDOVICO) or (entity:ToTear():HasTearFlags(TearFlags.TEAR_LUDOVICO) and Vect.biggerThan(entity.Velocity, Conf.allomancy.velocity.MIN_TEAR_TO_HOOK)))) 
            or (entity.Type==EntityType.ENTITY_PROJECTILE)) then

            entity.Visible = false
            Sound.play(Sound.COIN_HIT, math.abs(Vect.getHigher(entity.Velocity))/40, 0, false, 1)
            if (Vect.toDirection(entity.Velocity) == Direction.RIGHT or Vect.toDirection(entity.Velocity) == Direction.LEFT)
                and (Room.posPerOne(entity.Position).Y < 0.95 and Room.posPerOne(entity.Position).Y > 0.05)
                then

                if entity.Type==EntityType.ENTITY_TEAR then
                    tearData.anchoragePosition = Vector(entity.Position.X,entity.Position.Y+(Math.round(entity:ToTear().Height)))
                elseif entity.Type==EntityType.ENTITY_PROJECTILE then
                    tearData.anchoragePosition = Vector(entity.Position.X,entity.Position.Y+(Math.round(entity:ToProjectile().Height)))
                end
            else
                tearData.anchoragePosition = entity.Position
            end

            --Deselect enemy if tear is sticked
            if entity.Type==EntityType.ENTITY_TEAR and entity:ToTear().StickTarget ~= nil then
                if entity:ToTear().StickTarget:GetData().selected then
                    Fnc.tracer.deselectEntity(entity:ToTear().StickTarget)
                end
            end

            tearData.collisionVelocity = entity.Velocity
            tearData.collision = true
            MR:BulletRemove(entity)
        end
    end,

    laserPosition = function(laser, metalPiece) --(Laser, MetalPiece) Change laser position to metalPiece position.
        local add = Vector(0,15)
        if metalPiece.Type == EntityType.ENTITY_TEAR then
            add = add + Vector(0,metalPiece:ToTear().Height)
        end
        laser.Position = metalPiece.Position+add
    end,

    findNearestPickup = function(position, pickupsArray, ...) --(Position, {PickupVariant}, {FromEntity}, {Pathfinder})->[Entity] Returns nearest pickup 
        local args = {...}
        local nearestPickup = nil
        local nearestPosition = nil
        for _, pickup in pairs(pickupsArray) do
            if (args[1]==nil or (pickup:GetData().pieceVariant == args[1]))
            and (args[2]==nil or Fnc.entity.equal(pickup.SpawnerEntity, args[2])) 
            and (args[3]==nil or args[3]:HasPathToPos(position, false)) 
            and (pickup:GetData().isAnchorage or Pos.isNoneCollision(pickup.Position)) then
                if nearestPickup == nil or Vect.toDistance(position, pickup.Position) < nearestPosition then
                    nearestPosition = Vect.toDistance(position, pickup.Position)
                    nearestPickup = pickup
                end
            end
        end
        return nearestPickup
    end

}

return Fnc