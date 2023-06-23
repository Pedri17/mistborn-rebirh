local debug = {}

local Str = require("mod/tool/string")

debug.Init = function(mod)
    if debug.active == nil then debug.active = true end
    if debug.counter == nil then debug.counter = 0 end
    if debug.Messages == nil then debug.Messages = {} end
    if debug.Variables == nil then debug.Variables = {} end
    if debug.EntitiesWithMessages == nil then debug.EntitiesWithMessages = {} end
    if debug.EntitiesMessages == nil then debug.EntityMessages = {} end

    mod:AddCallback(ModCallbacks.MC_POST_RENDER, debug.onRender)
end

function debug:onRender()
    if debug.active then
        local f = Font()
        f:Load("font/pftempestasevencondensed.fnt")

        --Screen variables
        for i=1, debug.config.numVar+1, 1 do
            if debug.Variables[i] ~= nil and debug.Variables[i].ressult ~= nil then
                local mesVar = ""
                local pos = Vector(32, 20)

                if debug.Variables[i].name ~= "" then
                    mesVar = debug.Variables[i].name..": "
                end

                local r=1; local g=1; local b=1

                if type(debug.Variables[i].ressult)=="boolean" then
                    if debug.Variables[i].ressult then
                        r=0; g=1; b=0
                    else
                        r=1; g=0; b=0
                    end
                    mesVar = mesVar..Str.bool(debug.Variables[i].ressult)
                else
                    mesVar = mesVar..debug.Variables[i].ressult
                end
                f:DrawStringScaled(mesVar, pos.X, pos.Y+(f:GetLineHeight()/2*(i-1))-(i*2), 0.5, 0.5,KColor(r,g,b,1),0,true)
            end
        end

        --Entity variables
        for index, entity in pairs(debug.EntitiesWithMessages) do

            if not entity:Exists() then
                table.remove(debug.EntitiesWithMessages, index)
            else
                local data = entity:GetData()
                local pos = Game():GetRoom():WorldToScreenPosition(entity.Position)

                for i=1, #data.DebugVariables, 1 do
                    if data.DebugVariables[i] ~= nil and data.DebugVariables[i].ressult ~= nil then
                        local mesVar = ""

                        if data.DebugVariables[i].name ~= "" then
                            mesVar = data.DebugVariables[i].name..": "
                        end

                        local r=1; local g=1; local b=1

                        if type(data.DebugVariables[i].ressult)=="boolean" then
                            if data.DebugVariables[i].ressult then
                                r=0; g=1; b=0
                            else
                                r=1; g=0; b=0
                            end

                            mesVar = mesVar..Str.bool(data.DebugVariables[i].ressult)
                        else
                            mesVar = mesVar..data.DebugVariables[i].ressult
                        end
                        f:DrawStringScaled(mesVar, pos.X - f:GetStringWidth(mesVar)/4, (pos.Y+((f:GetLineHeight()/2*(i-1)))-(i*2)), 0.5, 0.5,KColor(r,g,b,1),0,false)
                    end
                end
            end
        end

        --Mensajes por pantalla
        for i=1, debug.config.numMess+1, 1 do
            local pos = Vector(5, 255-(f:GetLineHeight()/2*(i-1)-(i*2)))
            local mesVar = ""
            local opacity = debug.messageVars.opacity-((1/debug.config.numMess)*(i-1))
            if debug.Messages[i] ~= nil and debug.messageVars.quantity > 0 and i==1 then
                mesVar = ("x"..debug.messageVars.quantity..": "..debug.Messages[i])
            else
                mesVar = debug.Messages[i]
            end
            if debug.Messages[i] ~= nil then f:DrawStringScaled(mesVar, pos.X, pos.Y, 0.5, 0.5, KColor(255,255,255,opacity),0,false) end
        end

        if debug.messageVars.opacity > 0 then
            debug.messageVars.opacity = debug.messageVars.opacity-0.001
        end

        --Mensajes a entidades
        for i=1, #debug.EntityMessages, 1 do
            local opacity = 1

            if debug.EntityMessages[i] ~= nil and debug.EntityMessages[i].displacement < 100 then
                opacity = opacity - debug.EntityMessages[i].displacement/100
            else
                opacity = 0
                if debug.EntityMessages[i] ~= nil then
                    table.remove(debug.EntityMessages, i)
                end
            end

            if debug.EntityMessages[i] ~= nil then
                f:DrawString(debug.EntityMessages[i].message, debug.EntityMessages[i].position.X-f:GetStringWidth(debug.EntityMessages[i].message)/2, debug.EntityMessages[i].position.Y-debug.EntityMessages[i].displacement,KColor(1,1,1,opacity,0,0,0),0,true)
                debug.EntityMessages[i].displacement = (Isaac.GetFrameCount()-debug.EntityMessages[i].initFrame)/3
            end
        end
    end
end

debug.config = {
    numVar = 16,
    numMess = 16,
    entityNumMess = 6
}

debug.messageVars = {
    opacity = 1,
    quantity = 0,
}

debug.logOutput = function(m)
    if m ~= nil then
        Isaac.DebugString(m)
    end
end

debug.output = function (m)
    Isaac.ConsoleOutput(m.."\n")
end

debug.outputVector = function (m,v)
    Isaac.ConsoleOutput(m.."X: "..v.X.." Y: "..v.Y.."\n")
end

debug.setVariable = function(entity, varName, value) --Value, name, entity
    local varArray = debug.Variables
    if entity ~= nil and entity ~= 0 then
        varArray = entity:GetData().DebugVariables
        if varArray == nil then
            entity:GetData().DebugVariables = {}
            table.insert(debug.EntitiesWithMessages, entity)
            varArray = entity:GetData().DebugVariables
        end
    end

    local position = #varArray+1
    for id, var in pairs(varArray) do
        if var.name == varName then
            position = id
        end
    end
    varArray[position]={
        name = varName,
        ressult = value
    }
end

debug.addMessage = function(entity, text)
    --To screen
    if entity == nil or entity == 0 then
        if debug.Messages[1] == text then
            debug.messageVars.quantity = debug.messageVars.quantity+1
        else
            debug.messageVars.quantity = 0
        end

        table.insert(debug.Messages, 1, text)
        debug.messageVars.opacity = 1
        if #debug.Messages > debug.config.numMess then
            table.remove(debug.Messages,debug.config.numMess+1)
        end
    else --To entity
        local newID = #debug.EntityMessages+1
        local newPosition = Game():GetRoom():WorldToScreenPosition(entity.Position)
        local newFrame = Isaac.GetFrameCount()

        debug.EntityMessages[newID] = {
            message = text,
            position = newPosition,
            initFrame = newFrame,
            displacement = 0,
            entity = entity
        }
    end
end

return debug