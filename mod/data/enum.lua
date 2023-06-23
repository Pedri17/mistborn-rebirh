local enum = {}

enum.markId = {
    PAPER = 0,
    HEART = 1,
    CROSS = 2,
    INVERTED_CROSS = 3,
    STAR = 4,
    POLAROID = 5,
    NEGATIVE = 6,
    BRIMSTONE = 7,
    GREED = 8,
    HUSH = 9,
    KNIFE = 10,
    DADS_NOTE = 11
}

enum.power = {
    STEEL = 0,
    IRON = 1,
    PEWTER = 2,
    ZINC = 3,
    BRASS = 4,
    CADMIUM = 5,
    BENDALLOY = 6,
}

enum.iaState = {
    APPEAR = 0,
    IDLE = 1,
    APPROACHING = 2,
    RECEDE = 3,
    TAKE_COIN = 4,
    SHOT = 5
}

enum.pieceVariant = {
    COIN = 0,
    KNIFE = 1,
    PLATE = 2
}

return enum