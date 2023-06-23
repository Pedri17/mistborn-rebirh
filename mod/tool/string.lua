local str = {}

local enum = require("mod/data/enum")

str.enum = {
    power = {
        [-1] = "None",
        [enum.power.IRON] = "Iron",
        [enum.power.STEEL] = "Steel",
        [enum.power.PEWTER] = "Pewter",
        [enum.power.ZINC] = "Zinc",
        [enum.power.BRASS] = "Brass",
        [enum.power.CADMIUM] = "Cadmium",
        [enum.power.BENDALLOY] = "Bendalloy",
    },

    direction = {
        [Direction.LEFT] = "Left",
        [Direction.RIGHT] = "Right",
        [Direction.UP] = "Up",
        [Direction.DOWN] = "Down",
    },

    npcState = {
        [NpcState.STATE_INIT] = "Init",
        [NpcState.STATE_APPEAR] = "Appear",
        [NpcState.STATE_APPEAR_CUSTOM] = "Custom appear",
        [NpcState.STATE_IDLE] = "Idle",
        [NpcState.STATE_MOVE] = "Move",
        [NpcState.STATE_SUICIDE] = "Suicide",
        [NpcState.STATE_JUMP] = "Jump",
        [NpcState.STATE_STOMP] = "Stomp",
        [NpcState.STATE_ATTACK] = "Atack",
        [NpcState.STATE_ATTACK2] = "Atack2",
        [NpcState.STATE_ATTACK3] = "Atack3",
        [NpcState.STATE_ATTACK4] = "Atack4",
        [NpcState.STATE_ATTACK5] = "Atack5",
        [NpcState.STATE_SUMMON] = "Summon",
        [NpcState.STATE_SUMMON2] = "Summon 2",
        [NpcState.STATE_SUMMON3] = "Summon 3",
        [NpcState.STATE_SPECIAL] = "Special",
        [NpcState.STATE_UNIQUE_DEATH] = "Death",
        [NpcState.STATE_DEATH] = "Death",
    }
}

str.vector = function(v) --(Vector)->[String] Return vector values on a string.
    return v.X..", "..v.Y
end

str.bool = function(var) --(Bool)->[String] Return boolean as string (true/false).
    if var then return "True" else return "False" end
end

return str