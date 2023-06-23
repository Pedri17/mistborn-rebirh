local plyr = {}

local Math = require("mod/tool/math")
local Pos = require("mod/tool/position")
local Vect = require("mod/tool/vector")
local Enum = require("mod/data/enum")
local Conf = require("mod/data/config")
local Type = require("mod/data/type")
local Fnc = require("mod/functions")
local Str = require("mod/tool/string")
local Array = require("mod/tool/array")

local Debug = require("mod/game/debug")
local Physical = require("mod/game/items/physical")

plyr.Init = function(mod)
    mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, plyr.PlayerStart)
    mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, plyr.PlayerUpdate)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, plyr.CacheUpdate)
    mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, plyr.ControlsUpdate)
    mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, plyr.ControlsBlockInputs, InputHook.IS_ACTION_TRIGGERED)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, plyr.GameRender)
    mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, plyr.PlayerCollision)
end

--VARIABLES
plyr.powerItem = {
    [Enum.power.IRON] = Type.item.ironLerasiumAlloy,
    [Enum.power.STEEL] = Type.item.steelLerasiumAlloy,
}

--CALLBACK FUNCTIONS
function plyr:PlayerStart(player)
    local pData = player:GetData()

    if pData.mineralBar == nil then pData.mineralBar = Conf.allomancy.MAX_BAR end
    if pData.realFireDelay == nil then pData.realFireDelay = player.MaxFireDelay end
    if pData.selectedEntities == nil then pData.selectedEntities = {} end
    if pData.lastDirectionShooting == nil then pData.lastDirectionShooting = Vector(0,0) end
    if pData.multiShotNum == nil then pData.multiShotNum = 1 end
end

function plyr:PlayerUpdate(player)
    local pData = player:GetData()
    local sprite = player:GetSprite()

    if pData.AllomanticPowers ~= nil then
        Debug.setVariable(nil, "P1", Str.enum.power[pData.AllomanticPowers[1].has])
        Debug.setVariable(nil, "P2", Str.enum.power[pData.AllomanticPowers[2].has])
        Debug.setVariable(nil, "P3", Str.enum.power[pData.AllomanticPowers[3].has])
    end

    --DETECCIONES GENERALES
    Fnc.entity.collideGrid(player)
    if pData.mineralBar == nil then pData.mineralBar = Conf.allomancy.MAX_BAR end

    --Evaluate cache
    if (player:GetNumCoins()>0 and not pData.statsChanged) or (player:GetNumCoins() < 1 and pData.statsChanged) or not player:HasWeaponType(WeaponType.WEAPON_TEARS) then
        player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
        player:EvaluateItems()
    end

    --Init coop ghost
    if player:IsCoopGhost() and player:GetPlayerType()==Type.player.allomancer then
        sprite:ReplaceSpritesheet(0, plyr.allomancer.GHOST_COOP)
        sprite:LoadGraphics()
    end

    --Take a power item
    plyr.takePowerItem(player)

    --Selected entities
    if pData.selectedEntities ~= nil then
        for index, selEntity in pairs(pData.selectedEntities) do

            if not selEntity:Exists() then
                Fnc.tracer.deselectEntityIndex(player, index)
            end

            if (not (Fnc.entity.is.metalPiecePickup(selEntity) and selEntity:GetData().isAnchorage) and (not Fnc.entity.is.metalPieceBullet(selEntity)) and (not Fnc.entity.is.bottle(selEntity) and selEntity:GetData().isAnchorage)) then
                if not Pos.isNoneCollision(selEntity.Position) then
                    selEntity.Position = Game():GetRoom():FindFreeTilePosition(selEntity.Position,25)
                end
            end

        end
    end

    --Player crash
    if Vect.biggerThan(player.Velocity,Conf.allomancy.velocity.MIN_TO_PLAYER_HIT) and Fnc.hasPhysicalPower(player) and Game():GetNumPlayers() > 1 then
        for pID=0, Game():GetNumPlayers()-1, 1 do
            local p2 = Isaac.GetPlayer(pID)
            if GetPtrHash(player) ~= GetPtrHash(p2) and Fnc.entity.entityCollision(player, p2) then
                p2:AddVelocity((Vect.rotateNinety(player.Velocity))*0.25)
            end
        end
    end
end

function plyr:CacheUpdate(player, cacheFlag)
    local pData = player:GetData()
    if cacheFlag & CacheFlag.CACHE_FIREDELAY == CacheFlag.CACHE_FIREDELAY then

        if pData.statsChanged then
            local add = player.MaxFireDelay-(pData.realFireDelay)
            pData.realFireDelay = pData.realFireDelay + add

            if player:HasWeaponType(WeaponType.WEAPON_TEARS) or player:HasWeaponType(WeaponType.WEAPON_LASER) then
                player.MaxFireDelay = pData.realFireDelay*2
            elseif player:HasWeaponType(WeaponType.WEAPON_MONSTROS_LUNGS) then
                player.MaxFireDelay = pData.realFireDelay*(1+Math.upperBound(player:GetNumCoins(),14)/14)
            elseif player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) then
                player.MaxFireDelay = pData.realFireDelay*(1+(Math.upperBound(player:GetNumCoins(),8)/8))
            end
        else
            pData.realFireDelay = player.MaxFireDelay
        end

        if pData.controlsChanged and player:GetNumCoins()>0 and not pData.statsChanged then
            pData.statsChanged = true
            if player:HasWeaponType(WeaponType.WEAPON_TEARS) or player:HasWeaponType(WeaponType.WEAPON_LASER) then
                player.MaxFireDelay = pData.realFireDelay*2
            elseif player:HasWeaponType(WeaponType.WEAPON_MONSTROS_LUNGS) then
                player.MaxFireDelay = pData.realFireDelay*(1+Math.upperBound(player:GetNumCoins(),14)/14)
            elseif player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) then
                player.MaxFireDelay = pData.realFireDelay*(1+(Math.upperBound(player:GetNumCoins(),8)/8))
            else
                pData.statsChanged = false
            end
        end

        if ((not pData.controlsChanged or player:GetNumCoins()<1) or
            not (player:HasWeaponType(WeaponType.WEAPON_TEARS) 
                or player:HasWeaponType(WeaponType.WEAPON_LASER)
                or player:HasWeaponType(WeaponType.WEAPON_MONSTROS_LUNGS)
                or player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE)))
        and pData.statsChanged then
            player.MaxFireDelay = pData.realFireDelay
            pData.statsChanged = false
        end

        --Reduce delay when take a coin
        if pData.reduceFireDelay then
            pData.reduceFireDelay = false
            if player.FireDelay > -1 then
                player.FireDelay = Math.lowerBound(player.FireDelay-player.MaxFireDelay/(2*player:GetData().multiShotNum), 0)
            end
        end
    end
end

function plyr:ControlsUpdate(entity, hook, action)
    if entity ~= nil then
        local player = entity:ToPlayer()
        local pData = player:GetData()
        --SI TIENES CUALQUIERA DE LOS ITEMS METÁLICOS
        if player and pData.controlsChanged and Fnc.hasSomePower(player) then
            --CONTROLES DE PRESIÓN
            if plyr.pressingPower(Enum.power.IRON, player) or plyr.pressingPower(Enum.power.STEEL, player) then
                Physical.use(player)

                if plyr.pressingPower(Enum.power.IRON, player) then pData.pulling = true else pData.pulling = false end
                if plyr.pressingPower(Enum.power.STEEL, player) then pData.pushing = true else pData.pushing = false end
            else
                if #pData.selectedEntities > 0 then
                    Fnc.tracer.deselectEntities(entity)
                end
            end
        end
    end
end

function plyr:ControlsBlockInputs(entity, inputHook, buttonAction)
    if entity ~= nil and entity.Type == EntityType.ENTITY_PLAYER then
        local player = entity:ToPlayer()
        local pData = player:GetData()
        local controller = player.ControllerIndex
        if pData.controlsChanged then
            if Input.IsActionTriggered(Conf.action[1],controller) or Input.IsActionTriggered(Conf.action[2],controller) or Input.IsActionTriggered(Conf.action[3],controller) then
                return false
            end
        end
    end
end

function plyr:GameRender()
    for pID=0, Game():GetNumPlayers()-1, 1 do
        local player = Isaac.GetPlayer(pID)
        local pData = player:GetData()

        --CONTROLS
        plyr.controlOneTap(player)
    end
end

function plyr:PlayerCollision(player, collider, low)
    if collider:IsEnemy() and Vect.biggerThan(player.Velocity,Conf.allomancy.velocity.MIN_TO_PLAYER_HIT) and Fnc.hasPhysicalPower(player) then
        local dmg = player.Damage*2*Conf.allomancy.FAST_CRASH_DMG_MULT

        if collider:GetData().hitFrame == nil or (Game():GetFrameCount()-collider:GetData().hitFrame > Conf.allomancy.time.BETWEEN_GRID_SMASH) then
            collider:TakeDamage(dmg,0,EntityRef(player),60)
            collider:GetData().hitFrame = Game():GetFrameCount()
        end

        if collider:HasMortalDamage() then
            collider.CollisionDamage = 0
        end
    end
end

--FUNCTIONS
function plyr.takePowerItem(player)
    for i=0,Array.getSize(Enum.power)-1,1 do
        if plyr.powerItem[i] ~= nil and not Fnc.hasPower(player, i) and player:HasCollectible(plyr.powerItem[i]) then
            plyr.addPower(player, i)
        end
    end
end

plyr.pressingPower = function(power, player) --(String, Player)->[Bool] Return if player is pressing the specific power button.
    local pData = player:GetData()
    for i=1, 3, 1 do
        if pData.AllomanticPowers[i].has == power then
            return Input.IsActionPressed(Conf.action[i], player.ControllerIndex)
        end
    end
    return false
end

plyr.pressedPower = function(power, player)  --(String, Player)->[Bool] Return if player has pressed the specific power button.
    local pData = player:GetData()
    for i=1, 3, 1 do
        if pData.AllomanticPowers[i].has == power then
            return Input.IsActionTriggered(Conf.action[i], player.ControllerIndex)
        end
    end
    return false
end

plyr.addPower = function(entity, power, hemalurgy)
    local eData = entity:GetData()

    if eData.AllomanticPowers == nil then
        eData.AllomanticPowers = {
            [1] = {has = -1, taken = -1, hemalurgy = false},
            [2] = {has = -1, taken = -1, hemalurgy = false},
            [3] = {has = -1, taken = -1, hemalurgy = false}
        }
    end

    local lastPower
    local lastTaken
    local isFree = false
    local i=1
    while i<4 and not isFree do
        if eData.AllomanticPowers[i].has == -1 then
            isFree = true
            lastPower = i
        elseif lastPower == nil or eData.AllomanticPowers[i].taken > lastTaken then
            lastPower = i
            lastTaken = eData.AllomanticPowers[i].taken
        end
        i = i+1
    end

    eData.AllomanticPowers[lastPower].has = power
    eData.AllomanticPowers[lastPower].hemalurgy = hemalurgy
    eData.AllomanticPowers[lastPower].taken = 0

    for j=1,3,1 do
        if j ~= lastPower then
            if eData.AllomanticPowers[j].taken ~= -1 then
                eData.AllomanticPowers[j].taken = eData.AllomanticPowers[j].taken+1
            end
        end
    end

    --Reorder powers
    for k=1,3,1 do
        for j=1,3,1 do
            if k~=j then
                if eData.AllomanticPowers[k].has ~= -1 and eData.AllomanticPowers[j].has ~= -1 and eData.AllomanticPowers[k].has < eData.AllomanticPowers[j].has then
                    local tPower = eData.AllomanticPowers[k].has
                    local tHemalurgy = eData.AllomanticPowers[k].hemalurgy
                    local tTaken = eData.AllomanticPowers[k].taken

                    eData.AllomanticPowers[k].has = eData.AllomanticPowers[j].has
                    eData.AllomanticPowers[k].hemalurgy = eData.AllomanticPowers[j].hemalurgy
                    eData.AllomanticPowers[k].taken = eData.AllomanticPowers[j].taken

                    eData.AllomanticPowers[j].has = tPower
                    eData.AllomanticPowers[j].hemalurgy = tHemalurgy
                    eData.AllomanticPowers[j].taken = tTaken
                end
            end
        end
    end

end

plyr.controlOneTap = function(player) --(Player) Trigger once when press a button
    local pData = player:GetData()
    local controller = player.ControllerIndex

    if Fnc.hasPhysicalPower(player) then
        if Input.IsActionTriggered(Conf.action.CHANGE_MODE, controller) then
            if pData.controlsChanged then pData.controlsChanged = false else pData.controlsChanged = true end
            player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
            player:EvaluateItems()
        end

        if pData.controlsChanged and (plyr.pressedPower(Enum.power.IRON, player) or plyr.pressedPower(Enum.power.STEEL, player)) then
            Fnc.tracer.throw(player)
        end

        if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTLEFT, controller)
        or Input.IsActionTriggered(ButtonAction.ACTION_SHOOTRIGHT, controller)
        or Input.IsActionTriggered(ButtonAction.ACTION_SHOOTUP, controller)
        or Input.IsActionTriggered(ButtonAction.ACTION_SHOOTDOWN, controller) then

            player:GetData().shotFrame = Isaac.GetFrameCount()
            if player:GetShootingInput() ~= nil then player:GetData().lastDirectionShooting = player:GetShootingInput() end
        end
    end
end

return plyr