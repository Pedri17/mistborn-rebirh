local physical = {}

local Sound = include("mod/tool/sound")
local Vect = include("mod/tool/vector")
local Enum = include("mod/data/enum")
local Conf = include("mod/data/config")
local Type = include("mod/data/type")
local Fnc = include("mod/functions")

physical.velocity = {
    push = {
        [EntityType.ENTITY_PLAYER] = 7,
        [EntityType.ENTITY_PICKUP] = 20,
        [EntityType.ENTITY_TEAR] = 20,
        [EntityType.ENTITY_BOMB] = 8,
        [EntityType.ENTITY_FAMILIAR] = 8,
        [EntityType.ENTITY_KNIFE] = 0,
        [EntityType.ENTITY_PROJECTILE] = 20,
        ENEMY = 70,
        KNIFE_TEAR = 10,
        KNIFE_PICKUP = 12
    },
    AIMING_PUSH_ENTITY_VEL = 25,
    MIN_TEAR_TO_HOOK = 20,
    MIN_TO_PICKUP_DAMAGE = 15,
    MIN_DOUBLE_HIT = 10,
    MIN_TO_GRID_SMASH = 10,
    MIN_TEAR_TO_HOOK_AT_FLOOR = 10,
    MIN_TO_PLAYER_HIT = 8
}

physical.time = {
    BETWEEN_HIT_DAMAGE = 15,
    BETWEEN_DOUBLE_HIT = 30,
    BETWEEN_GRID_SMASH = 30
}

physical.use = function(entity) --(Entity) Make entity push/pull selected entities.
    local data = entity:GetData()

    Fnc.entity.collideGrid(entity)
    if data.selectedEntities ~= nil and (entity.Type ~= EntityType.ENTITY_PLAYER or (entity.Type == EntityType.ENTITY_PLAYER and data.mineralBar>0)) then
        for index, selEntity in pairs(data.selectedEntities) do
            local pushEntity = selEntity

            --To tear coins
            if selEntity.Type == EntityType.ENTITY_TEAR and selEntity.Variant == Type.tear.metalPiece and selEntity.Visible then
                Fnc.metalPiece.collideGrid(selEntity)

                if selEntity:ToTear().StickTarget ~= nil then
                    if Fnc.entity.equal(selEntity:ToTear().StickTarget, entity) then
                        selEntity:ToTear().StickTarget = nil
                        pushEntity = selEntity
                    else
                        --If is sticked save tear in target and change push entity
                        pushEntity = selEntity:ToTear().StickTarget
                        selEntity:ToTear().StickTarget:GetData().stickTear = selEntity:ToTear()
                    end
                end
            end

            --Entity collision
            if not pushEntity:GetData().gridTouched and (pushEntity:CollidesWithGrid()) and not Fnc.entity.is.metalPieceBullet(pushEntity) then

                pushEntity:GetData().gridTouched = true

                if pushEntity:IsEnemy() then
                    --If is enemy and collision in grid drop coin and if it's at high speed get a hit
                    if Vect.biggerThan(pushEntity.Velocity,Conf.allomancy.velocity.MIN_TO_GRID_SMASH) then
                        if pushEntity:GetData().hitFrame == nil or (Game():GetFrameCount()-pushEntity:GetData().hitFrame > Conf.allomancy.time.BETWEEN_GRID_SMASH) then
                            Sound.play(Sound.ENTITY_CRASH, math.abs(Vect.getHigher(pushEntity.Velocity)/10), 0, false, 1)
                            pushEntity:AddVelocity((pushEntity.Velocity)*-5)
                            pushEntity:TakeDamage(pushEntity:GetData().stickTear:GetData().BaseDamage*Conf.allomancy.FAST_CRASH_DMG_MULT,0,EntityRef(entity),60)
                            pushEntity:GetData().hitFrame = Game():GetFrameCount()
                        end
                    end
                    pushEntity:GetData().stickTear.StickTarget = nil
                end
            end

            --Deslect if touch entity
            if Fnc.entity.entityCollision(pushEntity,entity) 
            and not ((Fnc.entity.is.metalPiecePickup(pushEntity) or Fnc.entity.is.metalPieceBullet(pushEntity))) then
                Fnc.tracer.deselectEntityIndex(entity, index)
            end

            local toPushEntity = pushEntity
            local opposite = false

            --Opposite if cant move entity
                --Anchorage
            if pushEntity:GetData().isAnchorage or
                --Pulling entity that collides with grid
            (pushEntity:GetData().gridTouched) or
                --Stopped entity
            (pushEntity:IsEnemy() and Vect.isZero(pushEntity.Velocity)) then

                toPushEntity.Velocity = Vector(0,0)
                toPushEntity = entity
                opposite = true
            end

            --Pinking shears interaction
            local fromEntity
            if entity:GetData().cuttedBody ~= nil and entity:GetData().cuttedBody:Exists() and entity:GetData().pulling then
                fromEntity = entity:GetData().cuttedBody
            else
                fromEntity = nil
            end

            --Compensate controls input update rate
            local velocity = physical.pushVelocity(entity, pushEntity, opposite, fromEntity)
            if entity.Type ~= EntityType.ENTITY_PLAYER then
                velocity = 30*velocity
            end

            --Add push/pull velocity
            toPushEntity:AddVelocity(velocity)

            --Limit velocity to some entities
            if toPushEntity.Type == EntityType.ENTITY_PLAYER or toPushEntity:GetData().modEnemy then
                toPushEntity.Velocity = Vect.capVelocity(toPushEntity.Velocity, 20)
            end

            --If has a sticked tear change tear position to enemy position
            if pushEntity:GetData().stickTear ~= nil then
                pushEntity:GetData().stickTear.Position = pushEntity.Position+pushEntity:GetData().stickTear:ToTear().StickDiff
            end

            --If is on a laser change laser position to entity position
            if pushEntity:GetData().onLaser ~= nil then
                Fnc.metalPiece.laserPosition(pushEntity:GetData().onLaser, pushEntity)
            end

            --Unpin coins
            if (pushEntity:GetData().isAnchorage and Fnc.entity.is.metalPiecePickup(pushEntity)) and opposite and entity:GetData().gridTouched then
                selEntity.Friction = Conf.STANDART_PICKUP_FRICTION
                selEntity:GetData().isAnchorage = false
                local animation
                --Other metalPieces interactions
                if selEntity:GetData().pieceVariant == Enum.pieceVariant.COIN then
                    local anim = selEntity:GetSprite():GetAnimation()
                    animation = "Idle"..anim:sub(anim:len())
                else
                    animation = "Idle"
                end

                selEntity:GetSprite():Play(animation,true)
                selEntity.Position = Game():GetRoom():FindFreeTilePosition(selEntity.Position,25)
                selEntity.Velocity = ((Vect.baseOne(Vect.director(selEntity.Position, entity.Position)))*3)
            end

            --If player touch grid, deselect entity
            if data.gridTouched and selEntity:GetData().gridTouched then
                Fnc.tracer.deselectEntityIndex(entity, index)
            end

            --Spend minerals to players
            if entity.Type == EntityType.ENTITY_PLAYER then Fnc.spendMinerals(data, data.movingTime, 1) end
        end
    end
end

physical.isUsingPower = function(player) --(Player)->[Bool] Return if player is using some physical power.
    return player:GetData().pushing or player:GetData().pulling
end

physical.pushVelocity = function(entity, pushEntity, opposite, ...) --(Entity, Entity, Bool, {Entity})->[Vector velocity] Return push/pull velocity, {entity} to change fromEntity position.
    local args = {...}
    local data = entity:GetData()

    --Extra entity to push/pull from it
    local fromEntity
    if args[1]~=nil then
        fromEntity = args[1]
    else
        fromEntity = entity
    end

    --Ensure that player is pulling or pushing
    if data.pulling or data.pushing then
        local baseMultiplicator
        local oppositeMultiplicator

        if data.pulling then
            baseMultiplicator = -1.5
        elseif data.pushing then
            baseMultiplicator = 0.5
        end

        local toPushEntity = pushEntity
        local n

        if opposite then
            oppositeMultiplicator = -2
            toPushEntity = entity
        else
            oppositeMultiplicator = 1
        end

        --Enemy exception
        if toPushEntity:IsEnemy() or toPushEntity:GetData().modEnemy then
            if data.pushing then
                n = Conf.allomancy.velocity.push.ENEMY*1+(Conf.allomancy.velocity.AIMING_PUSH_ENTITY_VEL-Vect.toInt(pushEntity.Velocity))
            else
                n = Conf.allomancy.velocity.push.ENEMY
            end
        --Knife exception
        elseif toPushEntity:GetData().pieceVariant == Enum.pieceVariant.KNIFE then
            if toPushEntity.Type == EntityType.ENTITY_TEAR then
                n = Conf.allomancy.velocity.push.KNIFE_TEAR
            elseif toPushEntity.Type == EntityType.ENTITY_PICKUP then
                n = Conf.allomancy.velocity.push.KNIFE_PICKUP
            end
        else
            n = Conf.allomancy.velocity.push[toPushEntity.Type]
        end

        return Vect.fromToEntity(pushEntity, fromEntity, oppositeMultiplicator*(n/100)*(Vect.distanceMult(fromEntity.Position,pushEntity.Position, 600)+baseMultiplicator))
    else
        return Vector(0,0)
    end
end

return physical

