local MetalPiece = {}

local Array = require("mod/tool/array")
local Math = require("mod/tool/math")
local Pos = require("mod/tool/position")
local Room = require("mod/tool/room")
local Vect = require("mod/tool/vector")
local Enum = require("mod/data/enum")
local Conf = require("mod/data/config")
local Type = require("mod/data/type")
local Fnc = require("mod/functions")

function MetalPiece.Init(mod)
    MetalPiece.coinsWasted = 0
    MetalPiece.CoinTears = {}
    MetalPiece.MetalPiecesAlive = {}

    mod:AddCallback(ModCallbacks.MC_POST_RENDER, MetalPiece.GameRender)
    mod:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, MetalPiece.TearStart)
    mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, MetalPiece.TearFire)
    mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, MetalPiece.BulletUpdate)
    mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, MetalPiece.BulletUpdate)
    mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, MR.BulletRemove, EntityType.ENTITY_TEAR)
    mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, MR.BulletRemove, EntityType.ENTITY_PROJECTILE)
    mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, MetalPiece.PickupUpdate)
    mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, MetalPiece.BombStart)
    mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, MetalPiece.BombUpdate)
    mod:AddCallback(ModCallbacks.MC_POST_LASER_INIT, MetalPiece.LaserStart)
    mod:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, MetalPiece.LaserUpdate)
    mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, MetalPiece.RocketUpdate, EffectVariant.ROCKET)
    mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, MetalPiece.ProjectileStart)
    mod:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, MetalPiece.KnifeUpdate)
    mod:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, MetalPiece.TearCollision)
    mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, MetalPiece.FamiliarStart)
    mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, MetalPiece.FamiliarBodyUpdate, FamiliarVariant.ISAACS_BODY)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, MetalPiece.GameExit)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MetalPiece.RoomEnter)
end

--VARIABLES
MetalPiece.pickupsAlive = {}

--CALLBACK FUNCTIONS
function MetalPiece:GameExit(notEnd)
    for pID=0, Game():GetNumPlayers()-1, 1 do
        local player = Isaac.GetPlayer(pID)
        if notEnd then
            MetalPiece.takeAllFloor(player)
        else
            MetalPiece.coinsWasted = 0
        end
    end
end

function MetalPiece:RoomEnter()

    MetalPiece.CoinTears = {}
    for pID=0, Game():GetNumPlayers()-1, 1 do
        local player = Isaac.GetPlayer(pID)

        Fnc.tracer.deselectEntities(player)
        MetalPiece.takeAllFloor(player)
        player:GetData().shotKnives = 0
        player:GetData().invisibleKnives = 0
    end
end

function MetalPiece:GameRender()

    if MetalPiece.MetalPiecesAlive == nil then MetalPiece.MetalPiecesAlive = {} end
    if MetalPiece.CoinTears == nil then MetalPiece.CoinTears = {} end

    for pID=0, Game():GetNumPlayers()-1, 1 do
        local player = Isaac.GetPlayer(pID)
        local pData = player:GetData()

        --Touch metalPiece pickups
        for index, pickup in  pairs(MetalPiece.MetalPiecesAlive) do
            if pickup:Exists() then
                MetalPiece.touchPickup(player, pickup)
            else
                table.remove(MetalPiece.MetalPiecesAlive, index)
            end
        end

        --Bullet touch grid or projectile touch player
        for index, tear in pairs(MetalPiece.CoinTears) do
            if tear:Exists() then
                Fnc.metalPiece.collideGrid(tear)
                MetalPiece.collideHitPlayer(tear, player)
            else
                table.remove(MetalPiece.CoinTears,index)
            end
        end
    end
end

function MetalPiece:TearStart(tear)
    if tear.SpawnerEntity:ToPlayer() ~= nil then
        local player = tear.SpawnerEntity:ToPlayer()
        local pData = player:GetData()
        local tearData = tear:GetData()

        if Fnc.hasPhysicalPower(player) then
            --Ludovico interaction
            if player:HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE) or (pData.LudovicoLaser~=nil and pData.LudovicoLaser:Exists()) then
                --Change to tear
                if pData.controlsChanged and player:GetNumCoins()>0 then
                    MetalPiece.coin.init(tear)
                end
                --Set on data
                if (pData.LudovicoTear == nil or not pData.LudovicoTear:Exists()) or MetalPiece.isLudovicoMainTear(tear) then
                    if pData.LudovicoTear ~= nil and pData.LudovicoTear:Exists() and pData.LudovicoTear:ToTear().Scale < tear.Scale then
                        pData.LudovicoTear:GetData().isSubLudovicoTear = true
                        pData.subLudovicoTear = pData.LudovicoTear
                    end
                    tearData.isSubLudovicoTear = false
                    pData.LudovicoTear = tear
                else
                    tearData.isSubLudovicoTear = true
                    pData.subLudovicoTear = tear
                end
            end
        end
    end
end

function MetalPiece:TearFire(tear)
    local tearData = tear:GetData()
    local player = tear.SpawnerEntity:ToPlayer()
    local pData = player:GetData()

    --LÁGRIMAS DE MONEDA
    if Fnc.hasPhysicalPower(player) and pData.controlsChanged then

        --Usual tear coins
        if player:GetNumCoins() > 0 and pData.fireNotCoin == nil then

            MetalPiece.coin.init(tear)
            pData.lastCoin = tear

        --Special tear coins
        elseif pData.fireNotCoin ~= nil then
            MetalPiece.initAnyVariant(tear)
            pData.fireNotCoin = nil
        end
    end
end

function MetalPiece:ProjectileStart(projectile)
    local prData = projectile:GetData()
    if projectile.SpawnerEntity~=nil and projectile.SpawnerEntity.Type == Type.enemy.allomancer then
        MetalPiece.plate.init(projectile)
        projectile.SpawnerEntity:GetData().lastPlate = projectile
    end
end

function MetalPiece:BulletUpdate(bullet) --Tears and projectiles
    local bData = bullet:GetData()

    if bullet.SpawnerEntity ~= nil then
        local entity = bullet.SpawnerEntity
        local player = bullet.SpawnerEntity:ToPlayer()
        local eData = entity:GetData()


        --To metal piece
        if bData.isMetalPiece then

            --To Coins
            if player~=nil and bData.pieceVariant == Enum.pieceVariant.COIN and bullet.Type == EntityType.ENTITY_TEAR then

                --Take coin tear
                for pID=0, Game():GetNumPlayers()-1, 1 do
                    local player = Isaac.GetPlayer(pID)

                    --Pinking shears interaction
                    local collider
                    if player:GetData().cuttedBody ~= nil and player:GetData().cuttedBody:Exists() then
                        collider = player:GetData().cuttedBody
                    else
                        collider = player
                    end

                    if Fnc.entity.entityCollision(bullet, collider) and bullet.FrameCount > 10 and bullet.Height < -8 and not Vect.isZero(bullet.Velocity)
                        --Ludovico interaction: dont take ludovico bullet coins
                        and not bullet:HasTearFlags(TearFlags.TEAR_LUDOVICO) then

                        MetalPiece.take(bullet, player)
                    end
                end

                --Stick to entity
                if bullet.StickTarget ~= nil then
                    bullet.CollisionDamage = 0
                    bData.timerStick = bData.timerStick+1

                    if bullet.StickTarget:GetData().gridTouched ~= true then
                        bullet.StickTarget:GetData().gridTouched = false
                    end
                else --Change damage
                    if bData.selected then
                        bullet.CollisionDamage = bData.BaseDamage*MetalPiece.coin.COIN_DMG_MULT
                    else
                        bullet.CollisionDamage = bData.BaseDamage
                    end
                end

                --Spawn coin when get max sticked time
                if bullet:GetData().timerStick ~= nil and bullet:GetData().timerStick > MetalPiece.coin.STICKED_TIME then
                    bullet:Remove()
                end

                local anim = bullet:GetSprite():GetAnimation()

                if anim:sub(0, anim:len()-1)=="Appear" and bullet:GetSprite():IsFinished("Appear"..anim:sub(anim:len())) then
                    bullet:GetSprite():Play("Idle"..anim:sub(anim:len()))
                end
            elseif bData.pieceVariant == Enum.pieceVariant.KNIFE then --To knife tears
                MetalPiece.knife.flip(bullet)

                if not bullet.SpawnerEntity:GetData().controlsChanged then
                    bullet:Remove()
                end
            end

            --Variant
                --Ludovico interaction: extra ludovico tears
            if player ~= nil and bullet.Type == EntityType.ENTITY_TEAR then
                
                if bullet:HasTearFlags(TearFlags.TEAR_LUDOVICO) then
                    if bullet:GetSprite():GetFilename() ~= MetalPiece.ref.TEAR_COIN then
                        bullet:GetSprite():Load(MetalPiece.ref.TEAR_COIN, true)
                        bullet:GetSprite():Play("Idle"..MetalPiece.getSizeAnimation(bullet:ToTear()), true)
                    end

                    if not Vect.equal(bullet.SpriteScale, Vect.make(bullet:ToTear().Scale)) then
                        bullet:GetSprite().Scale = Vect.make(bullet:ToTear().Scale)
                        local anim = bullet:GetSprite():GetAnimation()
                        local size = MetalPiece.getSizeAnimation(bullet:ToTear())
                        if anim:sub(anim:len()) ~= size then
                            bullet:GetSprite():Play(anim:sub(0, anim:len()-1)..size)
                        end
                    end

                    --Ludovico interaction: Kill standart tear when can shot tear or kill metalPiece tear when change controls
                    if bullet:Exists() then

                        
                        --To coin tear
                        if (not bData.isMetalPiece and eData.controlsChanged and player:GetNumCoins()>0) then
                            if eData.LudovicoTear ~= nil and not eData.LudovicoTear:GetData().isMetalPiece then
                                MetalPiece.coin.init(eData.LudovicoTear)
                            else
                                MetalPiece.coin.init(bullet)
                            end
                        end
                        --Kill coin tear, respawn ludovico tear
                        if bData.isMetalPiece and not eData.controlsChanged then
                            bullet:Kill()
                        end
                    end

                elseif bullet.Variant ~= Type.tear.metalPiece and bullet:GetSprite():GetFilename() ~= MetalPiece.ref.TEAR_COIN then
                    bullet:ChangeVariant(Type.tear.metalPiece)
                end
            end

            --Change sticky/piercing
            if bData.selected then
                MetalPiece.changeToPiercing(bullet)
            else
                MetalPiece.changeToStick(bullet)
            end

            --Change rotation to velocity direction
            if not Vect.isZero(bullet.Velocity) then
                bullet.SpriteRotation = (bullet.Velocity):GetAngleDegrees()
            end

            --Tractor beam interaction
            if bullet.Type == EntityType.ENTITY_TEAR then
                if bullet:HasTearFlags(TearFlags.TEAR_TRACTOR_BEAM) or bData.isTractorBeam then
                    if bData.isTractorBeam ~= true then
                        bData.isTractorBeam = true
                    end

                    if Array.containsEntity(bullet.SpawnerEntity:GetData().selectedEntities, bullet) and bullet.SpawnerEntity:GetData().pulling then
                        bullet:ClearTearFlags(TearFlags.TEAR_TRACTOR_BEAM)
                        local dir = bullet.SpawnerEntity:ToPlayer():GetHeadDirection()
                        local tractor = bullet.SpawnerEntity:ToPlayer():GetTractorBeam()
                        if dir==Direction.LEFT or dir==Direction.RIGHT then
                            bullet.Position = Vector(bullet.Position.X, tractor.Position.Y)
                        else
                            bullet.Position = Vector(tractor.Position.X, bullet.Position.Y)
                        end
                    else
                        bullet:AddTearFlags(TearFlags.TEAR_TRACTOR_BEAM)
                    end
                else
                    bData.isTractorBeam = false
                end
            end
        end

        --To real tears
        if player ~= nil and bullet.Type == EntityType.ENTITY_TEAR then

            --Cricket's body interaction
            if (player:HasCollectible(224))
                and not ((bullet:HasTearFlags(TearFlags.TEAR_QUADSPLIT)))
                and (bullet.Variant == Type.tear.metalPiece) then

                bullet:GetSprite():Load(MetalPiece.ref.PARTICLE_COIN, true)
                local random = math.random(0,3)
                if random == 0 then
                    random = 1
                elseif random == 1 then
                    random = 3
                elseif random == 2 then
                    random = 5
                elseif random == 3 then
                    random = 7
                end

                bullet:GetSprite():Play("Gib0"..random,true)
            end

            --Parasite interaction
            if (bullet.SpawnerEntity.Type == EntityType.ENTITY_PLAYER and Fnc.hasPhysicalPower(bullet.SpawnerEntity) and bullet:HasTearFlags(TearFlags.TEAR_SPLIT) and bullet.Variant ~= Type.tear.metalPiece) then
                bullet.Velocity = Vect.capVelocity(bullet.Velocity, 20)
            end

            --Return to ludovico coin
            if bullet:HasTearFlags(TearFlags.TEAR_LUDOVICO) and eData.controlsChanged and entity.Type == EntityType.ENTITY_PLAYER and entity:ToPlayer():GetNumCoins() > 0 and not bData.isMetalPiece then
                bullet:Kill()
            end
        end

        --Multishot number
        if bullet.Type==EntityType.ENTITY_TEAR and bullet.FrameCount == 1 then
            local nTears = 1
            for _, tear in pairs(Isaac.GetRoomEntities()) do
                if not Fnc.entity.equal(tear, bullet) and Fnc.entity.equal(entity, tear.SpawnerEntity) and tear.FrameCount==bullet.FrameCount then
                    nTears = nTears+1
                end
            end
            eData.multiShotNum = nTears
        end
    end
end

function MR:BulletRemove(bullet) --Spawn metalPiece pickup from tear or projectile
    local bData = bullet:GetData()
    local ThisRoom = Game():GetRoom()

    --Spawn coin
    if bData.isMetalPiece and not bData.picked and bData.Coin==nil then

        local variant
        local anchorageWallAnim
        local anchorageAnim
        local spawnAnim

        --Knife tear
        if bData.pieceVariant == Enum.pieceVariant.KNIFE then
            variant = 2
            anchorageWallAnim = "Anchorage"
            anchorageAnim = "Anchorage"
            spawnAnim = "Idle"
        elseif bData.pieceVariant == Enum.pieceVariant.PLATE then --Plate tear
            variant = 3
            anchorageWallAnim = "AnchorageWall"
            anchorageAnim = "Anchorage"
            spawnAnim = "Appear"
        elseif bData.pieceVariant == Enum.pieceVariant.COIN then --Usual coin tear
            local sizeAnim = MetalPiece.getSizeAnimation(bullet)
            variant = 1
            anchorageWallAnim = "AnchorageWall"..sizeAnim
            anchorageAnim = "Anchorage"..sizeAnim
            spawnAnim = "Appear"..sizeAnim
        end

        --To anchorage
          --To not bounce tears (Rubber Cement interaction)
        if ((bullet.Type == EntityType.ENTITY_TEAR and not bullet:ToTear():HasTearFlags(TearFlags.TEAR_BOUNCE)) or (bullet.Type == EntityType.ENTITY_PROJECTILE))
            --Min velocity
            and bData.collision and Vect.biggerThan(bData.collisionVelocity,Conf.allomancy.velocity.MIN_TEAR_TO_HOOK) then

            bData.Coin = Isaac.Spawn(EntityType.ENTITY_PICKUP, Type.pickup.throwedCoin, variant, bData.anchoragePosition, Vector(0,0), nil)
            local coin = bData.Coin

            --Set anchorage characteristics
            coin.Friction = 100
            coin:GetData().isAnchorage = true

            --To wall anchorage
            if Pos.isWall(coin.Position) or (Room.touchLimit(bullet.Position)) then
                coin:GetData().inWall = true
                coin:GetSprite():Play(anchorageWallAnim,true)

                --Turn to wall direction
                    --To Knife
                if bData.pieceVariant == Enum.pieceVariant.KNIFE then
                    coin.SpriteRotation = (bData.collisionVelocity):GetAngleDegrees()
                    MetalPiece.knife.flip(coin, bData.collisionVelocity)

                    --To else
                else
                    if Room.wallDirection(coin.Position) == Direction.LEFT then
                        coin:GetSprite().FlipX = true
                    elseif Room.wallDirection(coin.Position) == Direction.UP then
                        coin.SpriteRotation = 270
                    elseif Room.wallDirection(coin.Position) == Direction.DOWN then
                        coin.SpriteRotation = 270
                        bData.Coin:GetSprite().FlipY = true
                    end
                end
            --To grid anchorage
            else
                coin:GetData().gridEntityTouched = ThisRoom:GetGridEntityFromPos(coin.Position)
                coin:GetData().inWall = false
                coin:GetSprite():Play(anchorageAnim,true)

                coin.SpriteRotation = (bData.collisionVelocity):GetAngleDegrees()
            end

        --Just usual tear coin
        else
            bData.Coin = Isaac.Spawn(EntityType.ENTITY_PICKUP, Type.pickup.throwedCoin, variant, Game():GetRoom():FindFreeTilePosition(bullet.Position,25), bullet.Velocity, nil)
            bData.Coin.SpriteRotation = bullet.SpriteRotation
            bData.Coin:GetSprite():Play(spawnAnim,true)
            
        end

        --Post spawn tear
        if bData.Coin ~= nil then
            local coin = bData.Coin

            --Ensure you cant take this tear
            bData.picked = true

            --Colision classes
            if bullet.Type == EntityType.ENTITY_TEAR then
                bData.Coin.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
            else
                bData.Coin.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            end

            --If tear coin selected select pickup coin
            if bData.selected then
                Fnc.tracer.selectEntity(bData.from, coin)
                coin:GetData().from = bData.from
            end

            --If tear coin is on a laser set this laser to pickup coin
            if bData.onLaser ~= nil then
                coin:GetData().onLaser = bData.onLaser
                bData.onLaser:GetData().Coin = coin
            end

            --If is from a knife
            if bData.fromKnife ~= nil then
                bData.fromKnife:GetData().knifeTear = coin
                coin:GetData().fromKnife = bData.fromKnife
                coin:GetData().fromExtraKnife = bullet:GetData().fromExtraKnife
                coin:GetData().pieceVariant = Enum.pieceVariant.KNIFE
            end

            --Set pickup coin characteristics to tear coin characteristics
            coin:SetColor(bullet:GetColor(),0,1,false,false)
            if bullet.Type == EntityType.ENTITY_TEAR and bData.pieceVariant == Enum.pieceVariant.COIN then
                if sizeAnim == 0 or sizeAnim == 1 then
                    coin.SpriteScale = Vect.make(bullet:ToTear().Scale*2)
                else
                    coin.SpriteScale = Vect.make(bullet:ToTear().Scale)
                end
            end

            --If is the last shot coin
            if bullet.SpawnerEntity ~= nil and Fnc.entity.equal(bullet.SpawnerEntity:GetData().lastCoin, bullet) then
                bullet.SpawnerEntity:GetData().lastCoin = coin
            end

            coin:GetData().gridTouched = false
            coin:GetData().BaseDamage = bData.BaseDamage
            coin:GetData().pieceVariant = bData.pieceVariant
            coin.SpawnerEntity = bullet.SpawnerEntity
            table.insert(MetalPiece.MetalPiecesAlive, coin)
        end

        --Ludovico interaction: remove tear when collide
        if bullet.Type == EntityType.ENTITY_TEAR and bullet:Exists() and bullet:ToTear():HasTearFlags(TearFlags.TEAR_LUDOVICO) then
            bullet:Remove()
        end
    end

end

function MetalPiece:PickupUpdate(pickup)
    local data = pickup:GetData()

    --To coin pickup variant
    if pickup.Variant == Type.pickup.throwedCoin then

        if data.isAnchorage == true then
            --If anchorage's grid is destroyed it becomes a pickup
            if data.inWall == false and (data.gridEntityTouched ~= nil and ((data.gridEntityTouched:ToDoor()~=nil and data.gridEntityTouched.State ~= 2)
                    or (data.gridEntityTouched:ToDoor()==nil and data.gridEntityTouched.State ~= 1))
                or data.gridEntityTouched == nil) then

                data.isAnchorage = false
                pickup:GetSprite():Play("Idle"..pickup:GetSprite():GetAnimation():sub(pickup:GetSprite():GetAnimation():len()),true)
                pickup.Friction = MetalPiece.coin.FRICTION_PICKUP
            else
                if data.pieceVariant == Enum.pieceVariant.PLATE then pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES end
                pickup.Velocity = Vect.make(0)
                pickup.Friction = 0
            end
        else
            if data.pieceVariant == Enum.pieceVariant.PLATE then pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL end
            --If is not anchorage change rotation
            if not Vect.isZero(pickup.Velocity) then
                pickup.SpriteRotation = (pickup.Velocity):GetAngleDegrees()
            end
        end

        --Take coin
        for pID=0, Game():GetNumPlayers()-1, 1 do
            local player = Isaac.GetPlayer(pID)
            MetalPiece.touchPickup(player, pickup)
        end

        --Knife pickup
        if data.pieceVariant == Enum.pieceVariant.KNIFE then
            --Damage enemies that touch knife pickup
            if not data.isAnchorage then
                for _, collider in pairs(Isaac.GetRoomEntities()) do
                    if collider:IsEnemy() and Fnc.entity.entityCollision(collider,pickup) then
                        collider:TakeDamage(data.fromKnife.CollisionDamage,0,EntityRef(data.from),60)
                    end
                end
            end

            --Recover knife when player has not controls changed
            local player = data.fromKnife.SpawnerEntity:ToPlayer()
            if not player:GetData().controlsChanged then
                --Anchorage to pickup
                if data.isAnchorage then
                    data.isAnchorage = false
                    pickup:GetSprite():Play("Idle",true)
                    pickup.Friction = MetalPiece.coin.FRICTION_PICKUP
                end
                pickup.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
                pickup:AddVelocity((Vect.baseOne(Vect.director(player.Position, pickup.Position)))*-10)
            else
                if pickup.GridCollisionClass ~= EntityGridCollisionClass.GRIDCOLL_NOPITS then
                    pickup.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
                end
            end
        end
    end
end

function MetalPiece:BombStart(bomb)
    for pID=0, Game():GetNumPlayers()-1, 1 do
        local player = Isaac.GetPlayer(pID)
        local pData = player:GetData()

        if bomb.SpawnerEntity ~= nil and GetPtrHash(player) == GetPtrHash(bomb.SpawnerEntity) and player:HasWeaponType(WeaponType.WEAPON_BOMBS) then
            if Vect.biggerThan(bomb.Velocity, 4) then
                bomb:GetData().fetusBomb = true
                if Fnc.hasPhysicalPower(player) and pData.controlsChanged and player:GetNumCoins() > 0 then
                    bomb:GetData().coinAtached = true
                    MetalPiece.coinsWasted = MetalPiece.coinsWasted + 1
                    player:AddCoins(-1)
                end
            end
        end
    end
end

function MetalPiece:BombUpdate(bomb)
    if bomb:GetData().coinAtached ~= nil and bomb:GetData().coinAtached then
        if bomb.FrameCount == 1 then
            bomb:GetSprite():Load(MetalPiece.ref.BOMB_COIN_TEAR, true); bomb:GetSprite():Play("Pulse", true);
        end
        if bomb:GetSprite():IsPlaying("Explode") then
            local coin = Isaac.Spawn(EntityType.ENTITY_PICKUP, Type.pickup.throwedCoin, 1, bomb.Position, bomb.Velocity, nil)
            bomb:GetData().coinAtached = false
            coin:GetData().isAnchorage = false
            coin:GetData().inWall = false
            coin:GetData().pieceVariant = Enum.pieceVariant.COIN
            coin:GetSprite():Play("Appear3", true)
            coin:AddVelocity(bomb.Velocity)
            coin.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
            if bomb:GetData().selected and  bomb:GetData().from ~= nil then
                Fnc.tracer.selectEntity(bomb:GetData().from, coin)
            end
            coin:GetData().gridTouched = false
        end
    end
end

function MetalPiece:RocketUpdate(rocket)
    for pID=0, Game():GetNumPlayers()-1, 1 do
        local player = Isaac.GetPlayer(pID)
        if GetPtrHash(rocket.SpawnerEntity) == GetPtrHash(player) then
            if player:HasWeaponType(WeaponType.WEAPON_ROCKETS) then
                if not rocket:Exists() then
                    if player:GetData().controlsChanged then
                        MetalPiece.coin.randomShooting(player, 360, rocket, 5, 3, 5)
                    end
                end
            end
        end
    end
end

function MetalPiece:LaserStart(laser)
    if laser.SpawnerEntity.Type == EntityType.ENTITY_PLAYER then
        local player = laser.SpawnerEntity:ToPlayer()
        local pData = player:GetData()
        laser:GetData().shotFrame = Isaac.GetFrameCount()

        --Interactions
        if Fnc.hasPhysicalPower(player) and pData.controlsChanged then

            if player:GetNumCoins() > 0 then
                if player:HasWeaponType(WeaponType.WEAPON_TECH_X) then
                    laser:GetData().Coin = MetalPiece.coin.fire(player, laser.Velocity)
                    laser:GetData().Coin:GetData().onLaser = laser
                elseif player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) and not laser:IsCircleLaser() then
                    --MegaBrimstone interaction
                    if laser.Variant == 11 then
                        MetalPiece.coin.randomShooting(player, 17, player, 12, 10, 18)
                    else --Usual brimstone interaction
                        MetalPiece.coin.randomShooting(player, 15, player, 8, 8, 16)
                    end
                elseif player:HasWeaponType(WeaponType.WEAPON_LASER) and not laser:IsCircleLaser() then
                    if player:HasCollectible(229) then --Monstruo's lung interaction
                        if pData.laserMonstruosLungFrame == nil then pData.laserMonstruosLungFrame=0 end
                        if Isaac.GetFrameCount() - pData.laserMonstruosLungFrame > 30 then
                            MetalPiece.coin.randomShooting(player, 20, player, 16, 10, 18)
                            pData.laserMonstruosLungFrame = Isaac.GetFrameCount()
                        end
                    else --Usual laser interaction
                        laser:GetData().Coin = MetalPiece.coin.fire(player)
                    end
                end
            end

            if player:HasWeaponType(WeaponType.WEAPON_KNIFE) then
                laser.Visible = false
            end
        end

        --Save ludovico laser
        if laser.Variant == LaserSubType.LASER_SUBTYPE_RING_LUDOVICO then
            pData.LudovicoLaser = laser
        end
    end
end

function MetalPiece:LaserUpdate(laser)
    if laser.SpawnerEntity ~= nil and laser.SpawnerEntity.Type == EntityType.ENTITY_PLAYER then
        local player = laser.SpawnerEntity:ToPlayer()
        local laserData = laser:GetData()

        --Laser on entity
        if laser.SpawnerEntity.Type == EntityType.ENTITY_PLAYER and laser.Parent ~= nil and laser.Parent.Type ~= EntityType.ENTITY_PLAYER then
            if laser.Parent.Type == EntityType.ENTITY_KNIFE and Fnc.hasPhysicalPower(player) then
                if laser.Visible and not laser.Parent.Visible then
                    laser.Visible = false
                    laser:Remove()
                end
                if not laser.Visible and laser.Parent.Visible then
                    laser.Visible = true
                end
            end
            laser.Parent:GetData().onLaser = laser
        end

        --Set invisible
        if not laser.Visible and laserData.Coin ~= nil and  laserData.Coin:GetData().pieceVariant == Enum.pieceVariant.KNIFE then
            laser.Visible = true
        end

        --When is on tear
        if laser.SpawnerEntity.Type == EntityType.ENTITY_PLAYER and laserData.Coin ~= nil and laserData.Coin:Exists() then
            local liveTime = Isaac.GetFrameCount() - laserData.shotFrame
            Fnc.metalPiece.laserPosition(laser, laserData.Coin)

            --Remove
            if (laser.Timeout == 0) and ((laserData.shotFrame ~= nil and liveTime > 150) or not laserData.Coin:Exists())  then
                laser:SetTimeout(5)
            end

            if player:HasWeaponType(WeaponType.WEAPON_TECH_X) and laser:GetData().Particle==nil then
                laserData.Particle = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.LASER_IMPACT, 5, laserData.Coin.Position, laserData.Coin.Velocity, laser)
                laserData.Particle:ToEffect():FollowParent(laser)
                laserData.Particle:ToEffect().LifeSpan = 1000
            end
        end

        --Ludovico Interaction
        if MetalPiece.hasLudovicoLaser(player) then
            if player:GetData().controlsChanged then
                if not Fnc.entity.isExisting(laserData.Coin) and player:GetNumCoins()>0 then
                    laserData.Coin = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLUE, 1, laser.Position, laser.Velocity, player)
                    local tear = laserData.Coin:ToTear()
                    tear:AddTearFlags(TearFlags.TEAR_LUDOVICO)
                    --tear:ChangeVariant(TearVariant.BLUE)
                    tear.Scale = tear.Scale*2
                    if tear:GetSprite():GetFilename() ~= MetalPiece.ref.TEAR_COIN then
                        tear:GetSprite():Load(MetalPiece.ref.TEAR_COIN, true)
                        tear:GetSprite():Play("Idle"..MetalPiece.getSizeAnimation(tear), true)
                        tear.SpriteScale = Vect.make(tear.Scale)
                    end
                    tear.GridCollisionClass = GridCollisionClass.COLLISION_NONE
                    player:GetData().LudovicoTear = tear

                elseif (Fnc.entity.isExisting(laserData.Coin)) then
                    laserData.Coin:AddVelocity(laser.Velocity/2)
                end
            elseif Fnc.entity.isExisting(laserData.Coin) then
                laserData.Coin:Remove()
            end
        end
    end
end

function MetalPiece:KnifeUpdate(knife)
    local player = knife.SpawnerEntity:ToPlayer()
    local pData = player:GetData()
    local knifeData = knife:GetData()

    --Spawn knife post init
    if knife.FrameCount == 1 then
        if pData.numKnives == nil then
            pData.numKnives = 0
        end
        local totalKnives = 0
        for _, extraKnife in pairs(Isaac.GetRoomEntities()) do
            if extraKnife.Type == EntityType.ENTITY_KNIFE and Fnc.entity.equal(player, extraKnife.SpawnerEntity) then
                totalKnives = totalKnives+1
            end
        end
        if pData.numKnives < totalKnives then
            pData.numKnives = totalKnives
        end
    end

    --Set knife throwable
    if knife.Visible and not Fnc.entity.isNear(knife, player, 40) then
        knifeData.isThrowable = true
    else
        knifeData.isThrowable = false
    end

    --Set main knife
    if not Fnc.entity.isExisting(pData.mainKnife) then
        pData.mainKnife = knife
    end
    local mainKnife = pData.mainKnife

    --Spawn knife tear
    if knifeData.selected then
        local selPlayer = knifeData.from:ToPlayer()

        --If is selected spawn knife tear
        if knifeData.isThrowable then
            if knife.Visible and ((not Fnc.entity.isExisting(knife.knifeTear))
                or (not pData.shotMain and Fnc.entity.equal(knife, mainKnife) and MetalPiece.knife.getNum(player)>pData.shotKnives)) then

                --set if shot main knife
                if Fnc.entity.equal(knife, mainKnife) then pData.shotMain = true end
                --set shot notCoin tear
                selPlayer:GetData().fireNotCoin = "knife"
                --shot tear
                knifeData.knifeTear = selPlayer:FireTear(knife.Position, Vect.fromToEntity(knife, player, 10), true, false, true, player, 1)
                local tear = knifeData.knifeTear
                local tearData = tear:GetData()
                tear.Height = -12
                --Rotation
                tear.SpriteRotation = (knifeData.knifeTear.Velocity):GetAngleDegrees()
                MetalPiece.knife.flip(tear)
                --Visuals
                tear:GetSprite():Load(MetalPiece.ref.TEAR_KNIFE, true)
                tear:GetSprite():Play("Spawn", true)
                --Data
                tearData.fromKnife = mainKnife
                tearData.isMetalPiece = true
                tearData.pieceVariant = Enum.pieceVariant.KNIFE
                --Tear flags
                tear:AddTearFlags(TearFlags.TEAR_PIERCING)
                --Select tear deselect knife
                Fnc.tracer.selectEntity(selPlayer, tear)
                Fnc.tracer.deselectEntity(knife)
                --Count shot knives
                pData.shotKnives = pData.shotKnives + 1
                --Tech X interaction
                if knifeData.onLaser ~= nil then
                    local newLaser = player:FireTechXLaser(knifeData.onLaser.Position, knifeData.onLaser.Velocity, knifeData.onLaser.Radius, player, 1)
                    newLaser:GetData().Coin = tear
                    tearData.onLaser = newLaser
                end
            end
        else
            Fnc.tracer.deselectEntity(knife)
        end
    end

    --To extra knives
    if not Fnc.entity.equal(knife, mainKnife) then
        if pData.shotKnives > 0 and pData.shotKnives-pData.invisibleKnives > 0 and knife.Visible then
            knife:GetSprite().Color = Color(knife:GetSprite().Color.R, knife:GetSprite().Color.G, knife:GetSprite().Color.B, 0)
            knife.Visible = false
            pData.invisibleKnives = pData.invisibleKnives+1
        end

        --Make permanent extra knives visible
        if not knife.Visible and pData.shotKnives - pData.invisibleKnives < 0 then
            knife:GetSprite().Color = Color(knife:GetSprite().Color.R, knife:GetSprite().Color.G, knife:GetSprite().Color.B, 1)
            knife.Visible = true
            pData.invisibleKnives = pData.invisibleKnives-1
        end

        if not knife.Visible and pData.invisibleKnives==0 then
            knife:GetSprite().Color = Color(knife:GetSprite().Color.R, knife:GetSprite().Color.G, knife:GetSprite().Color.B, 1)
            knife.Visible = true
        end
    else --To main knife
        --Enable main knife shot
        if not knife:IsFlying() then
            pData.shotMain = false
        end

        --Make main knife visible/invisible
        if knife.Visible and pData.shotKnives >= MetalPiece.knife.getNum(player) then
            knife.Visible = false
            pData.invisibleKnives = pData.invisibleKnives+1
        elseif not knife.Visible and pData.shotKnives < MetalPiece.knife.getNum(player) then
            if pData.invisibleKnives > 0 then
                pData.invisibleKnives = pData.invisibleKnives-1
            end
            knife.Visible = true
        end

    end

    --When a knife dissapears
    if not knife:Exists() then
        if not knife.Visible then
            pData.invisibleKnives = pData.invisibleKnives-1
        end
    end

    --Ludovico interaction: Go to player's position when is invisible
    if pData.controlsChanged and not knife.Visible and not Fnc.entity.entityCollision(knife, player) and knife:HasTearFlags(TearFlags.TEAR_LUDOVICO) then
        knife.Position = player.Position + player:GetShootingInput()*30
    end
end

function MetalPiece:TearCollision(tear, collider)
    local tearData = tear:GetData()

    if tear:GetData().isMetalPiece then

        --Fireplace bug interaction
        if (tearData.selected and collider.Type == EntityType.ENTITY_FIREPLACE) then
            collider:TakeDamage(1,0,EntityRef(tearData.from),60)
            tear:Remove()
        end

        --Bomb interaction
        if (tearData.selected and collider.Type == EntityType.ENTITY_BOMBDROP) then
            collider:GetData().coinAtached = true
            collider:GetSprite():Load(MetalPiece.ref.BOMB_COIN_TEAR, true); collider:GetSprite():Play("Pulse", true);
            Fnc.tracer.selectEntity(tearData.from, collider)
            tearData.isMetalPiece = false
            tear:Kill()
        end

        --Shield tear interaction
        if tear:HasTearFlags(TearFlags.TEAR_SHIELDED) and collider.Type == EntityType.ENTITY_PROJECTILE then
            tear:Remove()
            collider:Kill()
        end

        --Boss interaction
        if collider:IsBoss() and tear:HasTearFlags(TearFlags.TEAR_BOOGER) then
            tear.Velocity = tear.Velocity*0.5
            collider:TakeDamage(tearData.BaseDamage, 0, EntityRef(tearData.from), 0)
            tear:Remove()
        end

        --Ludovico interaction: bogger coin
        if tear:HasTearFlags(TearFlags.TEAR_LUDOVICO) and collider:IsEnemy() then
            if tear:HasTearFlags(TearFlags.TEAR_BOOGER) then
                tear:ClearTearFlags(TearFlags.TEAR_LUDOVICO)
            elseif tearData.selected then
                collider:AddVelocity(tear.Velocity*2)
            end
        end
    end
end

function MetalPiece:FamiliarStart(familiar)
    if familiar.Variant == FamiliarVariant.ISAACS_BODY then
        familiar.Player:GetData().cuttedBody = familiar
    end
end

function MetalPiece:FamiliarBodyUpdate(familiar)
    if Fnc.hasPhysicalPower(familiar.Player) then
        local aroundPickups = Isaac.FindInRadius(familiar.Position, 120, EntityPartition.PICKUP)
        if aroundPickups ~= nil then
            for _, pickup in pairs(aroundPickups) do
                if pickup.Variant == Type.pickup.throwedCoin and pickup:Exists() and (familiar:GetData().targetPickup == nil or not familiar:GetData().targetPickup:Exists()) then
                    if not pickup:GetData().isAnchorage then
                        familiar:GetData().targetPickup = pickup
                    end
                end
            end
        end
        if familiar:GetData().targetPickup ~= nil and familiar:GetData().targetPickup:Exists() then
            familiar:FollowPosition(familiar:GetData().targetPickup.Position)
            familiar:AddVelocity((Vect.director(familiar.Position,familiar:GetData().targetPickup.Position))*5)
        else
            familiar:FollowParent()
        end
    end
end

--FUNCTIONS
MetalPiece.ref = {
    BOMB_COIN_TEAR = "gfx/effects/coin/pickup_coinBomb.anm2",
    PARTICLE_COIN = "gfx/effects/coin/particle_coin.anm2",
    TEAR_KNIFE = "gfx/effects/knife/tear_knife.anm2",
    TEAR_COIN = "gfx/effects/coin/object_coin.anm2",
    SHIELD_COIN_TEAR = "gfx/effects/coin/coinTear_Shield.png",
    PLATE_TEAR = "gfx/effects/plate/object_plate.anm2"
}

MetalPiece.knife = {
    getNum = function(player) --(Player)->[Int] Return number of entity's knives.
        local res = 0
        if player:GetData().numKnives ~= nil then
            res = res + player:GetData().numKnives
        end
        return res
    end,

    flip = function(knife, ...) --(Tear, {Velocity}) Flip entity when is facing left.
        local arg = {...}
        local vel
        if arg[1] ~= nil then
            vel = arg[1]
        else
            vel = knife.Velocity
        end
        local angle = Math.angleTo360((vel):GetAngleDegrees())
        if angle >= 165 and angle <= 195 and not knife:GetSprite().FlipY then
            knife:GetSprite().FlipY = true
        end
        if not (angle >= 165 and angle <= 195) and knife:GetSprite().FlipY then
            knife:GetSprite().FlipY = false
        end
    end,
}

MetalPiece.coin = {
    STICKED_TIME = 90,
    FRICTION_PICKUP = 0.3,
    COIN_DMG_MULT = 2,

    init = function(tear) --(tearEntity) Inits coinVariant.
        local tear = tear:ToTear()
        local tearData = tear:GetData()

        if not tearData.isMetalPiece then
            --Start tear coins
            MetalPiece.initAnyVariant(tear)
            tearData.pieceVariant = Enum.pieceVariant.COIN

            MetalPiece.coinsWasted = MetalPiece.coinsWasted + 1
            tear.SpawnerEntity:ToPlayer():AddCoins(-1)

            --Shield tear interaction
            if tear:HasTearFlags(TearFlags.TEAR_SHIELDED) then
                tear:GetSprite():ReplaceSpritesheet(0,  MetalPiece.ref.SHIELD_COIN_TEAR)
                tear:GetSprite():LoadGraphics()
            end

            --Change rotation to velocity direction
            if not Vect.isZero(tear.Velocity) then
                tear.SpriteRotation = (tear.Velocity):GetAngleDegrees()
            end

            local sizeAnim = MetalPiece.getSizeAnimation(tear)

            tear:GetSprite():Play("Appear"..sizeAnim)
            if sizeAnim == 0 or sizeAnim == 1 then
                tear.SpriteScale = tear.SpriteScale*2
            end
        end
    end,

    fire = function(player, ...) --(Player)->[Tear] Player fire a coin tear.
        local args = {...}
        local vel = Fnc.fireTearVelocity(player)
        if args[1]~=nil then vel = args[1] end
        local tear = player:FireTear(player.Position, vel, true, false, true, player, 1)
        return tear
    end,

    randomShooting = function(player, angle, entity, n, minVel, maxVel) --(Player, Angle, Entity, Num, Num, Num) Shot n tears on random directions between angle interval from entity.
        for i=0, n-1, 1 do
            if player:GetNumCoins() > 0 then
                local rAngle
                if angle == 360 or angle == 0 then
                    rAngle = math.random(0,360)
                else
                    local direction = Vect.fromDirection(player:GetHeadDirection())
                    local frontAngle = Math.angleTo360(direction:GetAngleDegrees())
                    local a = frontAngle - (angle/2)
                    local b = frontAngle + (angle/2)

                    rAngle = Math.randomInterval(a,b)
                end

                local vel = Math.randomInterval(minVel, maxVel)
                local direction = Vector.FromAngle(rAngle)
                local newTear = Isaac.Spawn(EntityType.ENTITY_TEAR, Type.tear.metalPiece, 1, entity.Position, direction*vel, player)
                MetalPiece.coin.init(newTear)
            end
        end
    end,

}

MetalPiece.plate = {
    init = function(bullet) --(Bullet) Inits metalPiece bullet
        local data = bullet:GetData()

        if not data.isMetalPiece then
            data.BaseDamage = bullet.Damage
            data.isMetalPiece = true
            data.pieceVariant = Enum.pieceVariant.PLATE
            data.anchoragePosition = bullet.Position
            data.collision = false
            data.timerStick = 0
            table.insert(MetalPiece.CoinTears, bullet)

            --Change rotation to velocity direction
            if not Vect.isZero(bullet.Velocity) then
                bullet.SpriteRotation = (bullet.Velocity):GetAngleDegrees()
            end
            if bullet.Type == EntityType.ENTITY_PROJECTILE then
                bullet.Damage = 1
                bullet:AddProjectileFlags(ProjectileFlags.HIT_ENEMIES)
                bullet.Variant = ProjectileVariant.PROJECTILE_RING
                bullet:GetSprite():Load(MetalPiece.ref.PLATE_TEAR, true)
                bullet:GetSprite():Play("Appear")
            end
        end
    end
}

MetalPiece.initAnyVariant = function(tear) --(TearEntity) Init any metalPiece variant.
    local tearData = tear:GetData()

    if not tearData.isMetalPiece then
        tearData.isMetalPiece = true
        --Ludovico interaction: Don't change variant, change anm
        if tear.SpawnerEntity ~= nil and tear.SpawnerEntity:GetData().controlsChanged
            and (tear:HasTearFlags(TearFlags.TEAR_LUDOVICO) or tear.SpawnerEntity:ToPlayer():HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE) 
                or MetalPiece.hasLudovicoLaser(tear.SpawnerEntity:ToPlayer())) then
            if tear:GetSprite():GetFilename() ~= MetalPiece.ref.TEAR_COIN then
                tear:GetSprite():Load(MetalPiece.ref.TEAR_COIN, true)
                tear:GetSprite():Play("Idle"..MetalPiece.getSizeAnimation(tear), true)
                tear.SpriteScale = Vect.make(tear.Scale)
            end
        else
            if tear.Variant ~= Type.tear.metalPiece and tear:GetSprite():GetFilename() ~= MetalPiece.ref.TEAR_COIN then
                tear:ChangeVariant(Type.tear.metalPiece)
            end
        end

        tearData.anchoragePosition = tear.Position
        tearData.collision = false
        table.insert(MetalPiece.CoinTears, tear)

        tearData.timerStick = 0
        tearData.BaseDamage = tear.CollisionDamage*MetalPiece.coin.COIN_DMG_MULT
    end
end

MetalPiece.take = function(metalPiece, entity) --(MetalPiece, player) Player take metalPiece if he touch it.
    local eData = metalPiece:GetData()

    if metalPiece:Exists() and not eData.picked 
        and (eData.pieceVariant == Enum.pieceVariant.KNIFE and entity.Type==EntityType.ENTITY_PLAYER and Fnc.entity.equal(metalPiece.SpawnerEntity, entity))
        or (eData.pieceVariant == Enum.pieceVariant.PLATE and Fnc.entity.equal(metalPiece.SpawnerEntity, entity))
        or (eData.pieceVariant == Enum.pieceVariant.COIN and entity.Type==EntityType.ENTITY_PLAYER) then
        
        eData.picked = true
        if eData.pieceVariant == Enum.pieceVariant.KNIFE then --To knife
            eData.fromKnife:Reset()
            eData.fromKnife.SpawnerEntity:GetData().shotKnives =eData.fromKnife.SpawnerEntity:GetData().shotKnives - 1
            metalPiece:Remove()
        elseif eData.pieceVariant == Enum.pieceVariant.PLATE then --To plate
            entity:GetData().numPlates = entity:GetData().numPlates+1
            metalPiece:Remove()
            if metalPiece.SpawnerEntity:ToNPC()~=nil then
                --Reduce projectile cd 
                if metalPiece.SpawnerEntity:ToNPC().ProjectileCooldown > 0 then
                    metalPiece.SpawnerEntity:ToNPC().ProjectileCooldown = Math.round(metalPiece.SpawnerEntity:ToNPC().ProjectileCooldown/2)
                end
            end
        elseif eData.pieceVariant == Enum.pieceVariant.COIN then --To coin
            metalPiece:Remove()
            entity:GetData().reduceFireDelay = true
            entity:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
            entity:EvaluateItems()
            if MetalPiece.coinsWasted > 0 then
                entity:AddCoins(1)
                MetalPiece.coinsWasted = MetalPiece.coinsWasted-1
            end
        end
    end
end

MetalPiece.takeAllFloor = function(player) --(Player) Player take all coins on the room.

    if MetalPiece.coinsWasted ~= 0 then
        if MetalPiece.coinsWasted < 0 then
            Debug.addMessage("En la anterior sala se ha duplicado alguna moneda, informar del error")
        end
        player:AddCoins(MetalPiece.coinsWasted)
    end
    MetalPiece.coinsWasted = 0

    for _, entity in pairs(Isaac.GetRoomEntities()) do
        if entity.Type == EntityType.ENTITY_PICKUP
        and entity.Variant == Type.pickup.throwedCoin
        then
            entity:Remove()
        end
    end
end

MetalPiece.collideHitPlayer = function(projectile, player) -- (Projectile, Player) Player takes damage if is hit by the projectile
    local projectile = projectile:ToProjectile()
    if Fnc.entity.isExisting(projectile) and projectile.Type==EntityType.ENTITY_PROJECTILE and Fnc.entity.entityCollision(projectile, player) then
        projectile:Remove()
        player:TakeDamage(projectile.Damage, 0, EntityRef(projectile.SpawnerEntity), 10)
    end
end

MetalPiece.changeToStick = function(tear) --(Tear) Change tearFlag to bogger.
    if tear.Type == EntityType.ENTITY_TEAR then
        if not tear:HasTearFlags(TearFlags.TEAR_BOOGER) and 
            --Ludovico interaction
            not tear:HasTearFlags(TearFlags.TEAR_LUDOVICO) then

            tear:AddTearFlags(TearFlags.TEAR_BOOGER)
            tear:ClearTearFlags(TearFlags.TEAR_PIERCING)
        end
    end
end

MetalPiece.changeToPiercing = function(tear) --(Tear) Change tearFlag to piercing.
    if tear.Type == EntityType.ENTITY_TEAR then
        if not tear:HasTearFlags(TearFlags.TEAR_PIERCING) then
            tear:ClearTearFlags(TearFlags.TEAR_BOOGER)
            tear:AddTearFlags(TearFlags.TEAR_PIERCING)
        end
    end
end

MetalPiece.hasLudovicoLaser = function(player) --(Tear)->[Bool] Returns if player has the ludovico laser.
    return (player:HasWeaponType(WeaponType.WEAPON_LASER) or player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE)) and player:GetActiveWeaponEntity() ~= nil and player:GetActiveWeaponEntity():ToLaser():IsCircleLaser()
end

MetalPiece.isLudovicoMainTear = function(tear) --(Tear)->[Bool] Returns if this tear is the main ludovico tear.
    local player = tear.SpawnerEntity:ToPlayer()
    local nearTears = Isaac.FindInRadius(tear.Position, 200, EntityPartition.TEAR)
    for _, nTear in pairs(nearTears) do
        if GetPtrHash(nTear.SpawnerEntity) == GetPtrHash(player) and nTear:ToTear():HasTearFlags(TearFlags.TEAR_LUDOVICO) and nTear:ToTear().Scale > tear.Scale then
            return false
        end
    end
    return true
end

MetalPiece.getSizeAnimation = function(bullet) --(TearEntity)->[Int] Returns size animation number.
    --Based on 8 sprites
    local scale
    if bullet.Type==EntityType.ENTITY_TEAR then 
        scale = bullet:ToTear().Scale
    else
        scale = (bullet.SpriteScale.X+bullet.SpriteScale.Y)/2
    end
    if scale ~= nil then
        if scale <= 2/4 then return 0 end
        for i=2, 7, 1 do
            if scale > i/4 and scale <=(i+1)/4 then return i-1 end
        end
        if scale > 8/4 then return 7 end
    else
        return nil
    end
end

MetalPiece.touchPickup = function(entity, pickup) --(Entity, Pickup) Take pickup if touched by the entity
    --Pinking shears interaction
    local collider
    if entity.Type == EntityType.ENTITY_PLAYER and entity:GetData().cuttedBody ~= nil and entity:GetData().cuttedBody:Exists() then
        collider = entity:GetData().cuttedBody
    else
        collider = entity
    end

    --Collision
    if Fnc.entity.entityCollision(pickup, collider) then
        MetalPiece.take(pickup, entity)
    end
end

return MetalPiece