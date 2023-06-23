local hud = {}

local Array = require("mod/tool/array")
local Math = require("mod/tool/math")
local Str = require("mod/tool/string")
local Conf = require("mod/data/config")
local Type = require("mod/data/type")

local Debug = require("mod/game/debug")
local Fnc = require("mod/functions")

hud.Init = function(mod)
    hud.esc = false
    hud.escFrame = 0
    mod:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, hud.Shaderhook)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, hud.OnRender)
end

function hud:OnRender(shader)

    for pID=0, Game():GetNumPlayers()-1, 1 do
        local player = Isaac.GetPlayer(pID)
        local pData = player:GetData()

        --HUD
        if Fnc.hasSomePower(player) then

            pData.AllomancyIcon = Sprite();
            pData.AllomancyIcon:Load(hud.ref.ALLOMANCY_ANM, true);

            local buttonIcon = Sprite();
            buttonIcon:Load(hud.ref.BUTTON_ANM, true);

            local stomachIcon = Sprite();
            stomachIcon:Load(hud.ref.STOMACH_ANM, true)

            local frame = Math.round(pData.mineralBar/(Conf.allomancy.MAX_BAR/17))

            stomachIcon:Play("Idle")
            if pData.usePowerFrame ~= nil then
                if Isaac.GetFrameCount() - pData.usePowerFrame < 3 then
                    stomachIcon:Play("Burning")
                end
            end

            stomachIcon:SetFrame(frame)

            if not pData.controlsChanged then
                pData.AllomancyIcon.Color = Color(pData.AllomancyIcon.Color.R,pData.AllomancyIcon.Color.G,pData.AllomancyIcon.Color.B, 0.3, 0, 0, 0, 0)
                buttonIcon.Color = Color(buttonIcon.Color.R,buttonIcon.Color.G,buttonIcon.Color.B, 0.3, 0, 0, 0, 0)
                stomachIcon.Color = Color(stomachIcon.Color.R,stomachIcon.Color.G,stomachIcon.Color.B, 0.3, 0, 0, 0, 0)
            else
                pData.AllomancyIcon.Color = Color(pData.AllomancyIcon.Color.R,pData.AllomancyIcon.Color.G,pData.AllomancyIcon.Color.B, 1, 0, 0, 0, 0)
                buttonIcon.Color = Color(buttonIcon.Color.R,buttonIcon.Color.G,buttonIcon.Color.B, 1, 0, 0, 0, 0)
                stomachIcon.Color = Color(stomachIcon.Color.R,stomachIcon.Color.G,stomachIcon.Color.B, 1, 0, 0, 0, 0)
            end

            if pID ~= 0 then
                local scale = 0.5
                stomachIcon.Scale = Vector(scale, scale)
                buttonIcon.Scale = Vector(scale, scale)
                pData.AllomancyIcon.Scale = Vector(scale, scale)
            end

            stomachIcon:Render(hud.percToPos(hud.pos.STOMACH[pID]), Vector(0,0), Vector(0,0));

            local div = 1
            if pID ~= 0 then
                div = 2
            end

            if pData.AllomanticPowers[1].has ~= -1 then
                buttonIcon:Play("LT", true)
                buttonIcon:Render(hud.percToPos(hud.pos.ALLOMANCY[pID])+Vector(0,15/div), Vector(0,0), Vector(0,0));
                hud.changeAlomanticIconSprite(1,player)
                pData.AllomancyIcon:Render(hud.percToPos(hud.pos.ALLOMANCY[pID]), Vector(0,0), Vector(0,0));
            end

            if pData.AllomanticPowers[2].has ~= -1 then
                buttonIcon:Play("RB", true)
                buttonIcon:Render(hud.percToPos(hud.pos.ALLOMANCY[pID])+Vector(15/div,15/div), Vector(0,0), Vector(0,0));
                hud.changeAlomanticIconSprite(2,player)
                pData.AllomancyIcon:Render(hud.percToPos(hud.pos.ALLOMANCY[pID])+Vector(15/div,0), Vector(0,0), Vector(0,0));
            end

            if pData.AllomanticPowers[3].has ~= -1 then
                buttonIcon:Play("LB", true)
                buttonIcon:Render(hud.percToPos(hud.pos.ALLOMANCY[pID])+Vector(30/div,15/div), Vector(0,0), Vector(0,0));
                hud.changeAlomanticIconSprite(3,player)
                pData.AllomancyIcon:Render(hud.percToPos(hud.pos.ALLOMANCY[pID])+Vector(30/div,0), Vector(0,0), Vector(0,0));
            end
        end

        --COMPLETION NOTE
        if Fnc.somePlayerIsType(Type.player.allomancer) then
            if Input.IsActionPressed(ButtonAction.ACTION_MAP, player.ControllerIndex) then
                local noteMark = Sprite()
                if not noteMark:IsLoaded() then
                    noteMark:Load(hud.ref.COMPLETION_NOTE_ANM, true)
                    noteMark:ReplaceSpritesheet(0,hud.ref.COMPLETION_NOTE_PAUSE_PNG)
                    noteMark:LoadGraphics()
                    noteMark.Scale = Vector(0.5,0.5)
                    noteMark:Play("Idle", true)
                end
                hud.changeNoteMarks(noteMark)
                noteMark:Render(Isaac.WorldToRenderPosition(Vector(20,120)),Vector(0, 0), Vector(0, 0))
                noteMark:Update()
            end
        end
    end
end

function hud:Shaderhook(nm) --thanks tem!

    if (nm == "PostitStartMenu") then
        local cid = Game():GetPlayer(0).ControllerIndex
        if Game():IsPaused() and Isaac.GetFrameCount()-hud.escFrame > 10 and Input.IsActionTriggered(ButtonAction.ACTION_PAUSE,cid) or Input.IsButtonTriggered(Keyboard.KEY_ESCAPE,cid) or (Input.IsActionTriggered(ButtonAction.ACTION_MENUBACK,cid) and Game():IsPaused()) then
            if Input.IsActionTriggered(ButtonAction.ACTION_PAUSE,cid) or Input.IsButtonTriggered(Keyboard.KEY_ESCAPE,cid) then
                hud.esc = not hud.esc
                hud.escFrame = Isaac.GetFrameCount()
            else
                hud.esc = true
                hud.escFrame = Isaac.GetFrameCount()
            end
        elseif (not Game():IsPaused()) or Input.IsActionPressed(ButtonAction.ACTION_MENUCONFIRM,cid) or Input.IsButtonPressed(Keyboard.KEY_ENTER,cid) then
            hud.esc = false
        end

        if hud.esc and (Game():GetRoom():GetFrameCount() > 1) then
            hud:OnRender(true)
        end
    end
end

hud.pos = {
    STOMACH = {
        [0]=Vector(0.27,0.054),
        [1]=Vector(0.853, 0.054),
        [2]=Vector(0.208,0.924),
        [3]=Vector(0.853,0.924),
    },

    ALLOMANCY = {
        [0]=Vector(0.31, 0.032),
        [1]=Vector(0.838, 0.09),
        [2]=Vector(0.194, 0.96),
        [3]=Vector(0.838, 0.96),
    }
}

hud.ref = {
    BUTTON_ANM = "gfx/ui/ui_button_allomancy_icons.anm2",
    ALLOMANCY_ANM = "gfx/ui/ui_allomancy_icons.anm2",
    STOMACH_ANM = "gfx/ui/ui_stomach.anm2",
    COMPLETION_NOTE_ANM = "gfx/ui/completion_widget.anm2",
    COMPLETION_NOTE_PAUSE_PNG = "gfx/ui/completion_widget_pause.png",
}

hud.changeAlomanticIconSprite = function(pos, player) --(Num, Player) Change player's allomantic sprites
    local powers = player:GetData().AllomanticPowers
    local icon = player:GetData().AllomancyIcon

    if powers ~= nil and powers[pos].has ~= -1 then
        if powers[pos].hemalurgy then
            icon:Play(Str.enum.power[powers[pos].has].."B", true);
        else
            icon:Play(Str.enum.power[powers[pos].has].."A", true);
        end
    end
end

hud.changeNoteMarks = function(note) --(NoteMarksTable) Change mark's note sprite
    for i, mark in pairs(MR.marks) do
        note:SetLayerFrame(i, mark)
    end
end

hud.percToPos = function(vectorPercentage) --(Vector) Adjust percentage to screen position
    local screen = Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())
    local offset = Vector((1.7777778*(Options.HUDOffset/40)),Options.HUDOffset/40)
    local mulOffset = Vector(Math.boolToSymbol(vectorPercentage.X<0.5), Math.boolToSymbol(vectorPercentage.Y<0.5))
    return ((vectorPercentage+offset*mulOffset)*screen)
end

return hud