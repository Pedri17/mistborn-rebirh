local config = {}

--Buttons configuration
config.action = {
    [1] = ButtonAction.ACTION_ITEM, --First power
    [2] = ButtonAction.ACTION_PILLCARD, --Second power
    [3] = ButtonAction.ACTION_BOMB, --Third power
    CHANGE_MODE = ButtonAction.ACTION_DROP --Change mode
}

config.STANDART_PICKUP_FRICTION = 0.3

config.allomancy = {
    MAX_BAR = 2500,
    FAST_CRASH_DMG_MULT = 1.5,
    PUSHED_COIN_DMG_MULT = 1.5,

    time = {
        BETWEEN_HIT_DAMAGE = 15,
        BETWEEN_DOUBLE_HIT = 30,
        BETWEEN_GRID_SMASH = 30
    },

    velocity = {
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
}

return config