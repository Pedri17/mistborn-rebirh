local MR = RegisterMod("MistbornRebirth",1)
local json = require("json")

------------------------------------
--           FUNCTIONS
-------------------------------------

--Configurable
MR.control = {
    action = {
        [1] = ButtonAction.ACTION_ITEM,
        [2] = ButtonAction.ACTION_PILLCARD,
        [3] = ButtonAction.ACTION_BOMB,
        CHANGE_MODE = ButtonAction.ACTION_DROP
    },

    oneTap = function(player) --(Player) Trigger once when press a button
        local pData = player:GetData()
        local controller = player.ControllerIndex

        if MR.allomancy.physical.has(player) then
            if Input.IsActionTriggered(MR.control.action.CHANGE_MODE, controller) then
                if pData.controlsChanged then pData.controlsChanged = false else pData.controlsChanged = true end
                player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
                player:EvaluateItems()
            end

            if pData.controlsChanged and (MR.allomancy.pressedPower(MR.enum.power.IRON, player) or MR.allomancy.pressedPower(MR.enum.power.STEEL, player)) then
                MR.tracer.throw(player)
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
}

--!!
MR.type = {
    item = { --Item variant
        steelLerasiumAlloy = Isaac.GetItemIdByName("Steel-Lerasium alloy"),
        ironLerasiumAlloy = Isaac.GetItemIdByName("Iron-Lerasium alloy"),
    },

    tear = { --Tear variant
        metalPiece = Isaac.GetEntityVariantByName("Metalic piece")
    },

    pickup = { --Pickup variant
        throwedCoin = Isaac.GetEntityVariantByName("Throwed coin"),
        mineralBottle = Isaac.GetEntityVariantByName("Bottle"),
        floorMark = Isaac.GetEntityVariantByName("Iron Floor mark"),
    },

    costume = { --Costume variant
        playerAllomancer = Isaac.GetCostumeIdByPath("gfx/characters/character_allomancer.anm2")
    },

    player = { --Player variant
        allomancer = Isaac.GetPlayerTypeByName("The Allomancer")
    },

    enemy = { --Entity type
        allomancer = Isaac.GetEntityTypeByName("Iron Enemy Allomancer")
    }
}

MR.hud = {
    esc = false,
    escFrame = 0,

    pos = {
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
        },
    },

    ref = {
        BUTTON_ANM = "gfx/ui/ui_button_allomancy_icons.anm2",
        ALLOMANCY_ANM = "gfx/ui/ui_allomancy_icons.anm2",
        STOMACH_ANM = "gfx/ui/ui_stomach.anm2",
        COMPLETION_NOTE_ANM = "gfx/ui/completion_widget.anm2",
        COMPLETION_NOTE_PAUSE_PNG = "gfx/ui/completion_widget_pause.png",
    },

    changeAlomanticIconSprite = function(pos, player) --(Num, Player) Change player's allomantic sprites
        local powers = player:GetData().AllomanticPowers
        local icon = player:GetData().AllomancyIcon
        local stringPowers = player:GetData().SortedPowers

        if stringPowers ~= nil then
            for index, element in pairs(stringPowers) do
                if index == pos then
                    if powers[element] == true then
                        icon:Play(MR.str.enum.power[element].."A", true);
                    else
                        icon:Play(MR.str.enum.power[element].."B", true);
                    end
                end
            end
        end
    end,

    changeNoteMarks = function(note) --(NoteMarksTable) Change mark's note sprite
        for i, mark in pairs(MR.data.marks) do
            note:SetLayerFrame(i, mark)
        end
    end,

    percToPos = function(vectorPercentage) --(Vector) Adjust percentage to screen position
        local screen = Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())
        local offset = Vector((1.7777778*(Options.HUDOffset/40)),Options.HUDOffset/40)
        local mulOffset = Vector(MR.math.boolToSymbol(vectorPercentage.X<0.5), MR.math.boolToSymbol(vectorPercentage.Y<0.5))
        return ((vectorPercentage+offset*mulOffset)*screen)
    end,
}

--!!
MR.enum = {
    markId = {
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
    },

    power = {
        IRON = 0,
        STEEL = 1,
        PEWTER = 2,
        ZINC = 3,
        BRASS = 4,
        CADMIUM = 5,
        BENDALLOY = 6,
    },

    iaState = {
        APPEAR = 0,
        IDLE = 1,
        APPROACHING = 2,
        RECEDE = 3,
        TAKE_COIN = 4,
        SHOT = 5
    },

    pieceVariant = {
        COIN = 0,
        KNIFE = 1,
        PLATE = 2
    }
}

--Tools
MR.math = {
    round = function(n) --(Float)->[Int] --Round float to int
        if n-math.floor(n) >= 0.5 then return math.ceil(n) else return math.floor(n) end
    end,

    reduceIfHigher = function(n, limit, reduction) --(Num, Num, Num)->[Num] Return n-reduction if n is higher than limit.
        if n>limit then return n-reduction else return n end
    end,

    upperBound = function(n, max) --(Num, Num)->[Num] Return limit if base is higher, base otherwise.
        if n > max then
            return max
        end
        return n
    end,

    lowerBound = function(n, min) --(Num, Num)->[Num] Return limit if base is lower, base otherwise.
        if n < min then
            return min
        end
        return n
    end,

    angleTo360 = function(angle) --(Angle)->[Angle] Return angle from 0 to 360.
        if angle < 0 then
            angle = 360+angle
        end
        while angle > 360 do
            angle = angle-360
        end
        return angle
    end,

    randomInterval = function(a, b) --(Float, Float)->[Float] Returns random number on (a,b), a/b can be float.
        local decimals = 8
        local A = MR.math.round(a*10^decimals)
        local B = MR.math.round(b*10^decimals)

        if A<B then
            return math.random(A,B)/10^decimals
        else
            return math.random(B,A)/10^decimals
        end
    end,

    boolToSymbol = function(bool) --(Boolean)->[1/-1] Transforms boolean to positive/negative number.
        if bool then return 1 else return -1 end
    end
}

MR.vect = {
    make = function(n) --(Num)->[Vector] Returns n vector.
        return Vector(n,n)
    end,

    equal = function(v1, v2) --(Vector)->[Bool] Return if both vectors are equal.
        return v1.X==v2.X and v1.Y==v2.Y
    end,

    baseOne = function(v) --(Vector)->[Vector] Returns a vector that has one as highest value and the other as a multiple of this.
        local x = v.X; local y = v.Y; local xNeg; local yNeg

        if x<0 then xNeg = -1 else xNeg = 1 end
        if y<0 then yNeg = -1 else yNeg = 1 end

        x = math.abs(x)
        y = math.abs(y)

        if x>y then
            y = y/x
            x = x/x
        else
            x = x/y
            y = y/y
        end

        return Vector(x*xNeg,y*yNeg)
    end,

    director = function (fromPos,toPos) --(Vector, Vector)->(Vector) Returns a base one director vector.
        return MR.vect.baseOne(Vector(toPos.X-fromPos.X,toPos.Y-fromPos.Y))
    end,

    isZero = function(v) --(Vector)->[Bool] Returns if vector is zero.
        return v.X == 0.0 and v.Y == 0.0
    end,

    fromDirection = function(direction) --(Direction)->[Vector] Returns a base one vector from a Direction.
        if direction == Direction.RIGHT then return Vector(1,0)
        elseif direction == Direction.LEFT then return Vector(-1,0)
        elseif direction == Direction.UP then return Vector(0,-1)
        elseif direction == Direction.DOWN then return Vector(0,1)
        else return Vector(0,0) end
    end,

    someMin = function(vector, min) --(Vector, Num)->[Bool] Returns if some vector's value is higher than a min value.
        return vector.X > min or vector.Y > min
    end,

    absolute = function(vector) --(Vector)->[Vector] Returns vector with positive values.
        return Vector(math.abs(vector.X),math.abs(vector.Y))
    end,

    round = function(vector) --(Vector)->[Vector] Returns rounded value's vector
        return Vector(MR.math.round(vector.X),MR.math.round(vector.Y))
    end,

    facingSameDirection = function(directionVector, velocityVector, angle) --(Vector, Vector, Angle)->[Bool] Returns if velocityVector is on directionVector's angle interval.
        local mainAngle = MR.math.angleTo360(directionVector:GetAngleDegrees())
        local vel = MR.math.angleTo360((velocityVector):GetAngleDegrees())
        local a = mainAngle-(angle/2)
        local b = mainAngle+(angle/2)
        return vel >= a and vel <= b
    end,

    distanceMult = function(v1, v2, limit) --(Vector, Vector, Num)->[Num] Returns multiplicator (1-0) from distance limit (distance-limit).
        local n = 1-(v1:Distance(v2)/limit)
        if n < 0 then return 0 else return n end
    end,

    toDistance = function(v1, v2)
        return (math.abs(v2.X-v1.X)+math.abs(v2.Y-v1.Y))
    end,

    smallerThan = function(vector,num) --(Vector, Num)->[Bool] Returns if both values are smaller than num.
        return (math.abs(vector.X) < num and math.abs(vector.Y) < num)
    end,

    biggerThan = function(vel,num) --(Vector, Num)->[Bool] Returns if any value is bigger than num.
        return (math.abs(vel.X) > num or math.abs(vel.Y) > num)
    end,

    fromToEntity = function(fromEntity, toEntity, n) --(Entity, Entity, Num)->[Vector] Return n multiplied director vector from entities positions.
        return (MR.vect.director(toEntity.Position, fromEntity.Position))*n
    end,

    rotateNinety = function(vector) --(Vector)->[Vector] Rotate vector 90 degrees.
        return Vector(vector.Y,-vector.X)
    end,

    toInt = function(vector) --(Vector)->[Num] Returns number from vector.
        return math.sqrt((vector.X)^2+(vector.Y)^2)
    end,

    capVelocity = function(velocity, cap) --(Vector, Num)->[Vector] Returns vector with cap as higher value.
        if MR.vect.biggerThan(velocity,cap) then
            return MR.vect.baseOne(velocity)*cap
        else
            return velocity
        end
    end,

    toDirection = function(vector) --(Vector)->[Direction] Returns a direction from a vector
        local mayor = vector.X
        if math.abs(vector.Y)>math.abs(mayor) then
            mayor = vector.Y
        end

        if mayor == vector.X then
            if mayor >= 0 then return Direction.RIGHT else return Direction.LEFT end
        else
            if mayor >= 0 then return Direction.DOWN else return Direction.UP end
        end

    end,

    getHigher = function(vector)
        if math.abs(vector.X) > math.abs(vector.Y) then return vector.X else return vector.Y end
    end
}

MR.array = {
    getSize = function(table) --(Table)->[Num] Returns number of items on table.
        local count = 0
        if table ~= nil then
            for _, _ in pairs(table) do
                count = count + 1
            end
        end
        return count
    end,

    containsEntity = function(table, entity) --(Table, Entity)->[Bool] Return if entity is on table.
        for _, thisEntity in pairs(table) do
            if GetPtrHash(thisEntity) == GetPtrHash(entity) then
                return true
            end
        end
        return false
    end,

    containsVector = function(table, vector) --(Table, Vector->[Bool] Return if vector is on table.
        for _, thisVector in pairs(table) do
            if thisVector.X == vector.X and thisVector.Y == vector.Y then
                return true
            end
        end
        return false
    end
}

MR.str = {
    enum = {
        power = {
            [MR.enum.power.IRON] = "Iron",
            [MR.enum.power.STEEL] = "Steel",
            [MR.enum.power.PEWTER] = "Pewter",
            [MR.enum.power.ZINC] = "Zinc",
            [MR.enum.power.BRASS] = "Brass",
            [MR.enum.power.CADMIUM] = "Cadmium",
            [MR.enum.power.BENDALLOY] = "Bendalloy",
        },

        direction = {
            [Direction.LEFT] = "Left",
            [Direction.RIGHT] = "Right",
            [Direction.UP] = "Up",
            [Direction.DOWN] = "Down",
        }
    },

    vector = function(v) --(Vector)->[String] Return vector values on a string.
        return v.X..", "..v.Y
    end,

    bool = function(var) --(Bool)->[String] Return boolean as string (true/false).
        if var then return "True" else return "False" end
    end,
}

MR.pos = {
    isWall = function(pos) --(Vector)->[Bool] Return if wall is in this position.
        return Game():GetRoom():GetGridCollisionAtPos(pos) == GridCollisionClass.COLLISION_WALL
    end,

    isDoor = function(pos) --(Vector)->[Bool] Return if door is in this position.
        return Game():GetRoom():GetGridEntityFromPos(pos):ToDoor() ~= nil
    end,

    isObject = function(pos) --(Vector)->[Bool] Return if object is in this position.
        return Game():GetRoom():GetGridCollisionAtPos(pos) == GridCollisionClass.COLLISION_OBJECT
    end,

    isNoneCollision = function(pos) --(Vector)->[Bool] Return if none collision is in this position.
        return Game():GetRoom():GetGridCollisionAtPos(pos) == GridCollisionClass.COLLISION_NONE
    end,

    isGrid = function (pos) --(Vector)->[Bool] Return if grid is in this position.
        return Game():GetRoom():GetGridEntityFromPos(pos) ~= nil
    end,
}

MR.room = {
    bottleRocksSpawned = 0,
    savedEntities = {},

    limitPos = function() -- ->[Vector] Return room limit position.
        return Game():GetRoom():GetBottomRightPos()-Game():GetRoom():GetTopLeftPos()-Vector(20,20)
    end,

    clampedPos = function(pos) --(Position)->[Vector] Return clamped position.
        return Game():GetRoom():GetClampedPosition(pos,10)-Game():GetRoom():GetTopLeftPos()-Vector(10,10)
    end,

    posPerOne = function (pos) --(Position)->[Vector] Return base one room positon (0-1,0-1).
        return (MR.room.clampedPos(pos))*Vector(1/MR.room.limitPos().X, 1/MR.room.limitPos().Y)
    end,

    wallDirection = function(pos) --(Vector)->[Direction] Return wall direction from position taking room shape on consideration.

        --L
        if Game():GetRoom():GetRoomShape() == RoomShape.ROOMSHAPE_LTR then

            if math.abs(0.5-MR.room.posPerOne(pos).X) >= math.abs(0.5-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).X < 0.5 then
                return Direction.LEFT
            elseif math.abs(0.5-MR.room.posPerOne(pos).X) < math.abs(0.5-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).Y >= 0.5 then
                return Direction.DOWN
            elseif MR.room.posPerOne(pos).Y >= 0.5 and MR.room.posPerOne(pos).X >= 0.5 then
                if math.abs(0.75-MR.room.posPerOne(pos).X) >= math.abs(0.75-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).X >= 0.75 then
                    return Direction.RIGHT
                elseif math.abs(0.75-MR.room.posPerOne(pos).X) < math.abs(0.75-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).Y < 0.75 then
                    return Direction.UP
                end
            elseif MR.room.posPerOne(pos).Y < 0.5 and MR.room.posPerOne(pos).X < 0.5 then
                if math.abs(0.25-MR.room.posPerOne(pos).X) >= math.abs(0.25-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).X >= 0.25 then
                    return Direction.RIGHT
                elseif math.abs(0.25-MR.room.posPerOne(pos).X) < math.abs(0.25-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).Y < 0.25 then
                    return Direction.UP
                end
            end

        -- _|
        elseif Game():GetRoom():GetRoomShape() == RoomShape.ROOMSHAPE_LTL then

            if math.abs(0.5-MR.room.posPerOne(pos).X) >= math.abs(0.5-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).X >= 0.5 then
                return Direction.RIGHT
            elseif math.abs(0.5-MR.room.posPerOne(pos).X) < math.abs(0.5-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).Y >= 0.5 then
                return Direction.DOWN
            elseif MR.room.posPerOne(pos).Y >= 0.5 and MR.room.posPerOne(pos).X < 0.5 then
                if math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).X,0.5,0.5)) >= math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).Y,0.5,0.5)) and MR.room.posPerOne(pos).X < 0.25 then
                    return Direction.LEFT
                elseif math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).X,0.5,0.5)) < math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).Y,0.5,0.5)) and MR.room.posPerOne(pos).Y < 0.75 then
                    return Direction.UP
                end
            elseif MR.room.posPerOne(pos).Y < 0.5 and MR.room.posPerOne(pos).X >= 0.5 then
                if math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).X,0.5,0.5)) >= math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).Y,0.5,0.5)) and MR.room.posPerOne(pos).X < 0.75 then
                    return Direction.LEFT
                elseif math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).X,0.5,0.5)) < math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).Y,0.5,0.5)) and MR.room.posPerOne(pos).Y < 0.25 then
                    return Direction.UP
                end
            end

        -- -|
        elseif Game():GetRoom():GetRoomShape() == RoomShape.ROOMSHAPE_LBL then

            if math.abs(0.5-MR.room.posPerOne(pos).X) >= math.abs(0.5-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).X >= 0.5 then
                return Direction.RIGHT
            elseif math.abs(0.5-MR.room.posPerOne(pos).X) < math.abs(0.5-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).Y < 0.5 then
                return Direction.UP
            elseif MR.room.posPerOne(pos).Y >= 0.5 and MR.room.posPerOne(pos).X >= 0.5 then
                if math.abs(0.75-MR.room.posPerOne(pos).X) >= math.abs(0.75-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).X < 0.75 then
                    return Direction.LEFT
                elseif math.abs(0.75-MR.room.posPerOne(pos).X) < math.abs(0.75-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).Y >= 0.75 then
                    return Direction.DOWN
                end
            elseif MR.room.posPerOne(pos).Y < 0.5 and MR.room.posPerOne(pos).X < 0.5 then
                if math.abs(0.25-MR.room.posPerOne(pos).X) >= math.abs(0.25-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).X < 0.25 then
                    return Direction.LEFT
                elseif math.abs(0.25-MR.room.posPerOne(pos).X) < math.abs(0.25-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).Y >= 0.25 then
                    return Direction.DOWN
                end
            end

        -- |-
        elseif Game():GetRoom():GetRoomShape() == RoomShape.ROOMSHAPE_LBR then

            if math.abs(0.5-MR.room.posPerOne(pos).X) >= math.abs(0.5-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).X < 0.5 then
                return Direction.LEFT
            elseif math.abs(0.5-MR.room.posPerOne(pos).X) < math.abs(0.5-MR.room.posPerOne(pos).Y) and MR.room.posPerOne(pos).Y < 0.5 then
                return Direction.UP
            elseif MR.room.posPerOne(pos).Y >= 0.5 and MR.room.posPerOne(pos).X < 0.5 then
                if math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).X,0.5,0.5)) >= math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).Y,0.5,0.5)) and MR.room.posPerOne(pos).X >= 0.25 then
                    return Direction.RIGHT
                elseif math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).X,0.5,0.5)) < math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).Y,0.5,0.5)) and MR.room.posPerOne(pos).Y >= 0.75 then
                    return Direction.DOWN
                end
            elseif MR.room.posPerOne(pos).Y < 0.5 and MR.room.posPerOne(pos).X >= 0.5 then
                if math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).X,0.5,0.5)) >= math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).Y,0.5,0.5)) and MR.room.posPerOne(pos).X >= 0.75 then
                    return Direction.RIGHT
                elseif math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).X,0.5,0.5)) < math.abs(0.25-MR.math.reduceIfHigher(MR.room.posPerOne(pos).Y,0.5,0.5)) and MR.room.posPerOne(pos).Y >= 0.25 then
                    return Direction.DOWN
                end
            end

        else
            if math.abs(0.5-MR.room.posPerOne(pos).X) >= math.abs(0.5-MR.room.posPerOne(pos).Y) then
                if MR.room.posPerOne(pos).X >= 0.5 then
                    return Direction.RIGHT
                else
                    return Direction.LEFT
                end
            else
                if MR.room.posPerOne(pos).Y >= 0.5 then
                    return Direction.DOWN
                else
                    return Direction.UP
                end
            end
        end
    end,

    getGridRockEntities = function() -- ->[Table GridEntity] Return rock grid entities on this room.
        local thisRoom = Game():GetRoom()
        local i = thisRoom:GetBottomRightPos()-Vector(1,1)
        local GridEntities = {}
        local GridPos = {}

        while (i.Y > (thisRoom:GetTopLeftPos()+Vector(1,1)).Y) do

            while i.X > (thisRoom:GetTopLeftPos()+Vector(1,1)).X do
                i.X = i.X-5

                if MR.pos.isGrid(i) then
                    local grid = thisRoom:GetGridEntityFromPos(i)
                    if grid ~= nil and MR.bottle.isGridSpawnerRock(grid) and not MR.array.containsVector(GridPos, grid.Position) then
                        table.insert(GridPos, grid.Position)
                        table.insert(GridEntities, grid)
                    end
                end
            end
            i.X = (thisRoom:GetBottomRightPos()-Vector(1,1)).X
            i.Y = i.Y-5
        end
        return GridEntities
    end,

    touchLimit = function(pos) -- (Position)->[Bool] Return if position is touching a room limit.
        local roomShape = Game():GetRoom():GetRoomShape()
        local rp = MR.room.posPerOne(pos)
        if roomShape==RoomShape.ROOMSHAPE_LTL then
            if rp.X < 0.5 then
                return MR.room.posPerOne(pos).X == 0 or MR.room.posPerOne(pos).Y == 0.5 or MR.room.posPerOne(pos).Y == 1
            else
                if rp.Y < 0.5 then
                    return MR.room.posPerOne(pos).X == 0.5 or MR.room.posPerOne(pos).X == 1 or MR.room.posPerOne(pos).Y == 0
                else
                    return MR.room.posPerOne(pos).X == 1 or MR.room.posPerOne(pos).Y == 1
                end
            end
        elseif roomShape==RoomShape.ROOMSHAPE_LTL then
            if rp.X > 0.5 then
                return MR.room.posPerOne(pos).X == 1 or MR.room.posPerOne(pos).Y == 0.5 or MR.room.posPerOne(pos).Y == 1
            else
                if rp.Y < 0.5 then
                    return MR.room.posPerOne(pos).X == 0.5 or MR.room.posPerOne(pos).X == 1 or MR.room.posPerOne(pos).Y == 0
                else
                    return MR.room.posPerOne(pos).X == 0 or MR.room.posPerOne(pos).Y == 1
                end
            end
        elseif roomShape==RoomShape.ROOMSHAPE_LTL then
            if rp.X < 0.5 then
                return MR.room.posPerOne(pos).X == 0 or MR.room.posPerOne(pos).Y == 0.5 or MR.room.posPerOne(pos).Y == 0
            else
                if rp.Y > 0.5 then
                    return MR.room.posPerOne(pos).X == 0.5 or MR.room.posPerOne(pos).X == 1 or MR.room.posPerOne(pos).Y == 1
                else
                    return MR.room.posPerOne(pos).X == 1 or MR.room.posPerOne(pos).Y == 0
                end
            end
        elseif roomShape==RoomShape.ROOMSHAPE_LTL then
            if rp.X > 0.5 then
                return MR.room.posPerOne(pos).X == 1 or MR.room.posPerOne(pos).Y == 0.5 or MR.room.posPerOne(pos).Y == 0
            else
                if rp.Y > 0.5 then
                    return MR.room.posPerOne(pos).X == 0.5 or MR.room.posPerOne(pos).X == 0 or MR.room.posPerOne(pos).Y == 1
                else
                    return MR.room.posPerOne(pos).X == 0 or MR.room.posPerOne(pos).Y == 0
                end
            end
        else
            return MR.room.posPerOne(pos).X == 0 or MR.room.posPerOne(pos).X == 1 or MR.room.posPerOne(pos).Y == 0 or MR.room.posPerOne(pos).Y == 1
        end
    end,
}

MR.debug = {

    start = function ()
        if MR.debug.active == nil then MR.debug.active = true end
        if MR.debug.counter == nil then MR.debug.counter = 0 end
        if MR.debug.Messages == nil then MR.debug.Messages = {} end
        if MR.debug.Variables == nil then MR.debug.Variables = {} end
        if MR.debug.EntitiesWithMessages == nil then MR.debug.EntitiesWithMessages = {} end
        if MR.debug.EntitiesMessages == nil then MR.debug.EntityMessages = {} end
    end,

    config = {
        numVar = 5,
        numMess = 3,
        entityNumMess = 3
    },

    messageVars = {
        opacity = 1,
        quantity = 0,
    },

    logOutput = function(m)
        if m ~= nil then
            Isaac.DebugString(m)
        end
    end,

    output = function (m)
        Isaac.ConsoleOutput(m.."\n")
    end,

    outputVector = function (m,v)
        Isaac.ConsoleOutput(m.."X: "..v.X.." Y: "..v.Y.."\n")
    end,

    setVariable = function(varName, value, ...) --Value, name, entity
        local arg = {...}
        local entity = nil

        MR.debug.start()

        if arg[1]~=nil then
            entity = arg[1]
        end

        local varArray = MR.debug.Variables
        if entity ~= nil then
            varArray = entity:GetData().DebugVariables
            if varArray == nil then
                entity:GetData().DebugVariables = {}
                table.insert(MR.debug.EntitiesWithMessages, entity)
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
    end,

    addMessage = function(text, ...)
        local arg = {...}

        MR.debug.start()

        --To screen
        if arg[1] == nil then
            if MR.debug.Messages[1] == text then
                MR.debug.messageVars.quantity = MR.debug.messageVars.quantity+1
            else
                MR.debug.messageVars.quantity = 0
            end

            table.insert(MR.debug.Messages, 1, text)
            MR.debug.messageVars.opacity = 1
            if #MR.debug.Messages > MR.debug.config.numMess then
                table.remove(MR.debug.Messages,MR.debug.config.numMess+1)
            end
        --To entity
        else
            local entity = arg[1]
            local newID = #MR.debug.EntityMessages+1
            local newPosition = Game():GetRoom():WorldToScreenPosition(entity.Position)
            local newFrame = Isaac.GetFrameCount()

            MR.debug.EntityMessages[newID] = {
                message = text,
                position = newPosition,
                initFrame = newFrame,
                displacement = 0,
                entity = entity
            }
        end
    end
}

MR.data = {

    saveInfo = function() --Save mod data
        local info = {}
        info.marks = MR.data.marks
        info.bottlesSpawned = MR.room.bottleRocksSpawned
        info.players = {}
        for i=1, Game():GetNumPlayers(), 1 do
            local pData = Isaac.GetPlayer(i):GetData()
            local pTable = {
                id = i,
                mineralBar = pData.mineralBar,
                controlsChanged = pData.controlsChanged
            }
            table.insert(info.players, i, pTable)
        end
        MR:SaveData(json.encode(info))
    end,

    loadInfo = function() --Load mod data
        local info = json.decode(MR:LoadData())
        if info.marks ~= nil then MR.data.marks = info.marks end
        if info.bottlesSpawned ~= nil then MR.room.bottleRocksSpawned = info.bottlesSpawned end
        for i=1, Game():GetNumPlayers(), 1 do
            local pData = Isaac.GetPlayer(i):GetData()
            if info.players[i] ~= nil then
                if info.players[i].mineralBar ~= nil then pData.mineralBar = info.players[i].mineralBar end
                if info.players[i].controlsChanged ~= nil then pData.controlsChanged = info.players[i].controlsChanged end
            end
        end
    end,

    putMark = function(markId) -- (MarkID) Put mark on marks table considering the difficulty
        if Game().Difficulty == 0 and MR.data.marks[markId] < 1 then
            MR.data.marks[markId] = 1
        elseif Game().Difficulty == 1 and MR.data.marks[markId] < 2 then
            MR.data.marks[markId] = 2
        end
    end,

    marks = { --0=not, 1=normal, 2=hard
        [0] = 0, --Paper
        [1] = 0, --Heart
        [2] = 0, --Cross
        [3] = 0, --Inverted Cross
        [4] = 0, --Star
        [5] = 0, --Polaroid
        [6] = 0, --Negative
        [7] = 0, --Brimstone
        [8] = 0, --Greed
        [9] = 0, --Hush
        [10] = 0, --Knife
        [11] = 0, --DadsNote
    },
}

MR.sound = {
    SPAWN_BOTTLE = Isaac.GetSoundIdByName("glassFall"),
    TAKE_BOTTLE = Isaac.GetSoundIdByName("drink"),
    COIN_HIT = Isaac.GetSoundIdByName("coinHit"),
    COIN_THROW = Isaac.GetSoundIdByName("coinThrow"),
    ENTITY_CRASH = Isaac.GetSoundIdByName("entityCrash"),

    play = function(soundID, volume, delay, loop, pitch) -- (Sound, Num, Num, Bool, Num) Play a sound.
        local soundEntity = Isaac.Spawn(30, 1, 1, Vector(50000,50000), Vector(0,0), nil)
        soundEntity.Visible = false
        soundEntity:ToNPC():PlaySound(soundID, volume, delay, loop, pitch)
        soundEntity:Remove()
    end,
}

--Objects
MR.entity = {
    is = {
        metalicEntity = function(entity) --(Entity)->[Bool] Return if entity is metalic.
            local data = entity:GetData()
            return ((entity.Type == EntityType.ENTITY_PICKUP)
                        and ((entity.Variant == MR.type.pickup.throwedCoin)
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
                        or entity.Variant == MR.type.pickup.mineralBottle))
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
            return entity.Type == EntityType.ENTITY_PICKUP and (entity.Variant==MR.type.pickup.throwedCoin or entity:GetData().isMetalPiece)
        end,

        metalPieceBullet = function(entity) --(Entity)->[Bool] Return if entity is a metalicPiece tear
            return (entity.Type == EntityType.ENTITY_TEAR and entity.Variant == MR.type.tear.metalPiece)
                or (entity.Type==EntityType.ENTITY_PROJECTILE and entity:GetData().isMetalPiece)
        end,

        bottle = function(entity) --(Entity)->[Bool] Return if entity is a bottle.
            return entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == MR.type.pickup.mineralBottle
        end,

        tracer = function(entity) --(Entity)->[Bool] Return if entity is a tracer
            return entity.Type == EntityType.ENTITY_EFFECT and entity:GetData().isTracer
        end,
    },

    collideGrid = function(entity)
        if not entity:GetData().gridTouched and (entity:CollidesWithGrid() or MR.pos.isWall(entity.Position) or
        (not MR.pos.isNoneCollision(entity.Position) and (entity.Type ~= EntityType.ENTITY_PLAYER or (entity.Type == EntityType.ENTITY_PLAYER and not entity:ToPlayer().CanFly)))) then
            entity:GetData().gridTouched = true
            if (MR.vect.biggerThan(entity.Velocity,10)) then
                entity.Velocity =(entity.Velocity)*-0.1
            end
            MR.sound.play(MR.sound.ENTITY_CRASH, math.abs(MR.vect.getHigher(entity.Velocity)/15), 0, false, 1)
        end
    end,

    entityCollision = function(e1,e2) --(Entity, Entity)->[Bool] Returns if entities are colliding.
        return (e1.Position - e2.Position):Length() < e1.Size + e2.Size
    end,

    isNear = function(findEntity, fromEntity, radius) --(Entity, Entity, Num)->[Bool] Returns if findEntity is near fromEntity in a radius.
        local nearEntities = Isaac.FindInRadius(fromEntity.Position, radius, MR.entity.typeToPartition(findEntity))
        for _, e in pairs(nearEntities) do
            if MR.entity.equal(e, findEntity) then
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

MR.player = {
    allomancer = {
        GHOST_COOP = "gfx/characters/TheAllomancer/ghost_coop_allomancer.png",
    },

    fireTearVelocity = function(player) --(Player)->[Velocity] Returns tear velocity from player shot
        local speed = player.ShotSpeed*10
        local dir =player:GetHeadDirection()
        local vectorDir = MR.vect.fromDirection(dir)
        local vel = vectorDir*speed
        vel = vel+(player:GetTearMovementInheritance(vectorDir))

        return vel
    end,

    someIsType = function(playerType) --(PlayerType)->[Bool] Returns if player is a specific type.
        for pID=0, Game():GetNumPlayers()-1, 1 do
            local player = Isaac.GetPlayer(pID)
            if player:GetPlayerType()==playerType then return true end
        end
        return false
    end,
}

MR.metalPiece = {
    pickupsAlive = {},

    ref = {
        BOMB_COIN_TEAR = "gfx/effects/coin/pickup_coinBomb.anm2",
        PARTICLE_COIN = "gfx/effects/coin/particle_coin.anm2",
        TEAR_KNIFE = "gfx/effects/knife/tear_knife.anm2",
        TEAR_COIN = "gfx/effects/coin/object_coin.anm2",
        SHIELD_COIN_TEAR = "gfx/effects/coin/coinTear_Shield.png",
        PLATE_TEAR = "gfx/effects/plate/object_plate.anm2"
    },

    knife = {
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
            local angle = MR.math.angleTo360((vel):GetAngleDegrees())
            if angle >= 165 and angle <= 195 and not knife:GetSprite().FlipY then
                knife:GetSprite().FlipY = true
            end
            if not (angle >= 165 and angle <= 195) and knife:GetSprite().FlipY then
                knife:GetSprite().FlipY = false
            end
        end,
    },

    coin = {
        STICKED_TIME = 90,
        FRICTION_PICKUP = 0.3,
        COIN_DMG_MULT = 2,

        CoinTears = {},
        wasted = 0,

        init = function(tear) --(tearEntity) Inits coinVariant.
            local tear = tear:ToTear()
            local tearData = tear:GetData()

            if not tearData.isMetalPiece then
                --Start tear coins
                MR.metalPiece.initAnyVariant(tear)
                tearData.pieceVariant = MR.enum.pieceVariant.COIN

                MR.metalPiece.coin.wasted = MR.metalPiece.coin.wasted + 1
                tear.SpawnerEntity:ToPlayer():AddCoins(-1)

                --Shield tear interaction
                if tear:HasTearFlags(TearFlags.TEAR_SHIELDED) then
                    tear:GetSprite():ReplaceSpritesheet(0,  MR.metalPiece.ref.SHIELD_COIN_TEAR)
                    tear:GetSprite():LoadGraphics()
                end

                --Change rotation to velocity direction
                if not MR.vect.isZero(tear.Velocity) then
                    tear.SpriteRotation = (tear.Velocity):GetAngleDegrees()
                end

                local sizeAnim = MR.metalPiece.getSizeAnimation(tear)

                tear:GetSprite():Play("Appear"..sizeAnim)
                if sizeAnim == 0 or sizeAnim == 1 then
                    tear.SpriteScale = tear.SpriteScale*2
                end
            end
        end,

        fire = function(player, ...) --(Player)->[Tear] Player fire a coin tear.
            local args = {...}
            local vel = MR.player.fireTearVelocity(player)
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
                        local direction = MR.vect.fromDirection(player:GetHeadDirection())
                        local frontAngle = MR.math.angleTo360(direction:GetAngleDegrees())
                        local a = frontAngle - (angle/2)
                        local b = frontAngle + (angle/2)

                        rAngle = MR.math.randomInterval(a,b)
                    end

                    local vel = MR.math.randomInterval(minVel, maxVel)
                    local direction = Vector.FromAngle(rAngle)
                    local newTear = Isaac.Spawn(EntityType.ENTITY_TEAR, MR.type.tear.metalPiece, 1, entity.Position, direction*vel, player)
                    MR.metalPiece.coin.init(newTear)
                end
            end
        end,

    },

    plate = {
        init = function(bullet) --(Bullet) Inits metalPiece bullet
            local data = bullet:GetData()

            if not data.isMetalPiece then
                data.BaseDamage = bullet.Damage
                data.isMetalPiece = true
                data.pieceVariant = MR.enum.pieceVariant.PLATE
                data.anchoragePosition = bullet.Position
                data.collision = false
                data.timerStick = 0
                table.insert(MR.metalPiece.coin.CoinTears, bullet)

                --Change rotation to velocity direction
                if not MR.vect.isZero(bullet.Velocity) then
                    bullet.SpriteRotation = (bullet.Velocity):GetAngleDegrees()
                end
                if bullet.Type == EntityType.ENTITY_PROJECTILE then
                    bullet.Damage = 1
                    bullet:AddProjectileFlags(ProjectileFlags.HIT_ENEMIES)
                    bullet.Variant = ProjectileVariant.PROJECTILE_RING
                    bullet:GetSprite():Load(MR.metalPiece.ref.PLATE_TEAR, true)
                    bullet:GetSprite():Play("Appear")
                end
            end
        end
    },

    initAnyVariant = function(tear) --(TearEntity) Init any metalPiece variant.
        local tearData = tear:GetData()

        if not tearData.isMetalPiece then
            tearData.isMetalPiece = true
            --Ludovico interaction: Don't change variant, change anm
            if tear.SpawnerEntity ~= nil and tear.SpawnerEntity:GetData().controlsChanged
                and (tear:HasTearFlags(TearFlags.TEAR_LUDOVICO) or tear.SpawnerEntity:ToPlayer():HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE)
                    or MR.metalPiece.hasLudovicoLaser(tear.SpawnerEntity:ToPlayer())) then
                if tear:GetSprite():GetFilename() ~= MR.metalPiece.ref.TEAR_COIN then
                    tear:GetSprite():Load(MR.metalPiece.ref.TEAR_COIN, true)
                    tear:GetSprite():Play("Idle"..MR.metalPiece.getSizeAnimation(tear), true)
                    tear.SpriteScale = MR.vect.make(tear.Scale)
                end
            else
                if tear.Variant ~= MR.type.tear.metalPiece and tear:GetSprite():GetFilename() ~= MR.metalPiece.ref.TEAR_COIN then
                    tear:ChangeVariant(MR.type.tear.metalPiece)
                end
            end

            tearData.anchoragePosition = tear.Position
            tearData.collision = false
            table.insert(MR.metalPiece.coin.CoinTears, tear)

            tearData.timerStick = 0
            tearData.BaseDamage = tear.CollisionDamage*MR.metalPiece.coin.COIN_DMG_MULT
        end
    end,

    take = function(metalPiece, entity) --(MetalPiece, player) Player take metalPiece if he touch it.
        local eData = metalPiece:GetData()

        if metalPiece:Exists() and not eData.picked
            and (eData.pieceVariant == MR.enum.pieceVariant.KNIFE and entity.Type==EntityType.ENTITY_PLAYER and MR.entity.equal(metalPiece.SpawnerEntity, entity))
            or (eData.pieceVariant == MR.enum.pieceVariant.PLATE and MR.entity.equal(metalPiece.SpawnerEntity, entity))
            or (eData.pieceVariant == MR.enum.pieceVariant.COIN and entity.Type==EntityType.ENTITY_PLAYER) then

            eData.picked = true
            if eData.pieceVariant == MR.enum.pieceVariant.KNIFE then --To knife
                eData.fromKnife:Reset()
                eData.fromKnife.SpawnerEntity:GetData().shotKnives =eData.fromKnife.SpawnerEntity:GetData().shotKnives - 1
                metalPiece:Remove()
            elseif eData.pieceVariant == MR.enum.pieceVariant.PLATE then --To plate
                entity:GetData().numPlates = entity:GetData().numPlates+1
                metalPiece:Remove()
                if metalPiece.SpawnerEntity:ToNPC()~=nil then
                    --Reduce projectile cd
                    if metalPiece.SpawnerEntity:ToNPC().ProjectileCooldown > 0 then
                        metalPiece.SpawnerEntity:ToNPC().ProjectileCooldown = MR.math.round(metalPiece.SpawnerEntity:ToNPC().ProjectileCooldown/2)
                    end
                end
            elseif eData.pieceVariant == MR.enum.pieceVariant.COIN then --To coin
                metalPiece:Remove()
                entity:GetData().reduceFireDelay = true
                entity:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
                entity:EvaluateItems()
                if MR.metalPiece.coin.wasted > 0 then
                    entity:AddCoins(1)
                    MR.metalPiece.coin.wasted = MR.metalPiece.coin.wasted-1
                end
            end
        end
    end,

    takeAllFloor = function(player) --(Player) Player take all coins on the room.

        if MR.metalPiece.coin.wasted ~= 0 then
            if MR.metalPiece.coin.wasted < 0 then
                MR.debug.addMessage("En la anterior sala se ha duplicado alguna moneda, informar del error")
            end
            player:AddCoins(MR.metalPiece.coin.wasted)
        end
        MR.metalPiece.coin.wasted = 0

        for _, entity in pairs(Isaac.GetRoomEntities()) do
            if entity.Type == EntityType.ENTITY_PICKUP
            and entity.Variant == MR.type.pickup.throwedCoin
            then
                entity:Remove()
            end
        end
    end,

    collideGrid = function(entity) --(MetalPiece) Detects collisions and manages it.
        local tearData = entity:GetData()
        if not tearData.collision and (entity:CollidesWithGrid() or MR.pos.isWall(entity.Position) or (entity.Type==EntityType.ENTITY_TEAR and (entity:ToTear():HasTearFlags(TearFlags.TEAR_LUDOVICO)) and MR.room.touchLimit(entity.Position)))
        --Ludovico interaction: just consider collision when is fast
        and ((entity.Type==EntityType.ENTITY_TEAR and (not entity:ToTear():HasTearFlags(TearFlags.TEAR_LUDOVICO) or (entity:ToTear():HasTearFlags(TearFlags.TEAR_LUDOVICO) and MR.vect.biggerThan(entity.Velocity, MR.allomancy.physical.velocity.MIN_TEAR_TO_HOOK))))
            or (entity.Type==EntityType.ENTITY_PROJECTILE)) then

            entity.Visible = false
            MR.sound.play(MR.sound.COIN_HIT, math.abs(MR.vect.getHigher(entity.Velocity))/40, 0, false, 1)
            if (MR.vect.toDirection(entity.Velocity) == Direction.RIGHT or MR.vect.toDirection(entity.Velocity) == Direction.LEFT)
                and (MR.room.posPerOne(entity.Position).Y < 0.95 and MR.room.posPerOne(entity.Position).Y > 0.05)
                then

                if entity.Type==EntityType.ENTITY_TEAR then
                    tearData.anchoragePosition = Vector(entity.Position.X,entity.Position.Y+(MR.math.round(entity:ToTear().Height)))
                elseif entity.Type==EntityType.ENTITY_PROJECTILE then
                    tearData.anchoragePosition = Vector(entity.Position.X,entity.Position.Y+(MR.math.round(entity:ToProjectile().Height)))
                end
            else
                tearData.anchoragePosition = entity.Position
            end

            --Deselect enemy if tear is sticked
            if entity.Type==EntityType.ENTITY_TEAR and entity:ToTear().StickTarget ~= nil then
                if entity:ToTear().StickTarget:GetData().selected then
                    MR.tracer.deselectEntity(entity:ToTear().StickTarget)
                end
            end

            tearData.collisionVelocity = entity.Velocity
            tearData.collision = true
            MR.BulletRemove(0, entity)
        end
    end,

    collideHitPlayer = function(projectile, player) -- (Projectile, Player) Player takes damage if is hit by the projectile
        local projectile = projectile:ToProjectile()
        if MR.entity.isExisting(projectile) and projectile.Type==EntityType.ENTITY_PROJECTILE and MR.entity.entityCollision(projectile, player) then
            projectile:Remove()
            player:TakeDamage(projectile.Damage, 0, EntityRef(projectile.SpawnerEntity), 10)
        end
    end,

    changeToStick = function(tear) --(Tear) Change tearFlag to bogger.
        if tear.Type == EntityType.ENTITY_TEAR then
            if not tear:HasTearFlags(TearFlags.TEAR_BOOGER) and
                --Ludovico interaction
                not tear:HasTearFlags(TearFlags.TEAR_LUDOVICO) then

                tear:AddTearFlags(TearFlags.TEAR_BOOGER)
                tear:ClearTearFlags(TearFlags.TEAR_PIERCING)
            end
        end
    end,

    changeToPiercing = function(tear) --(Tear) Change tearFlag to piercing.
        if tear.Type == EntityType.ENTITY_TEAR then
            if not tear:HasTearFlags(TearFlags.TEAR_PIERCING) then
                tear:ClearTearFlags(TearFlags.TEAR_BOOGER)
                tear:AddTearFlags(TearFlags.TEAR_PIERCING)
            end
        end
    end,

    laserPosition = function(laser, metalPiece) --(Laser, MetalPiece) Change laser position to metalPiece position.
        local add = Vector(0,15)
        if metalPiece.Type == EntityType.ENTITY_TEAR then
            add = add + Vector(0,metalPiece:ToTear().Height)
        end
        laser.Position = metalPiece.Position+add
    end,

    hasLudovicoLaser = function(player) --(Tear)->[Bool] Returns if player has the ludovico laser.
        return (player:HasWeaponType(WeaponType.WEAPON_LASER) or player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE)) and player:GetActiveWeaponEntity() ~= nil and player:GetActiveWeaponEntity():ToLaser():IsCircleLaser()
    end,

    isLudovicoMainTear = function(tear) --(Tear)->[Bool] Returns if this tear is the main ludovico tear.
        local player = tear.SpawnerEntity:ToPlayer()
        local nearTears = Isaac.FindInRadius(tear.Position, 200, EntityPartition.TEAR)
        for _, nTear in pairs(nearTears) do
            if GetPtrHash(nTear.SpawnerEntity) == GetPtrHash(player) and nTear:ToTear():HasTearFlags(TearFlags.TEAR_LUDOVICO) and nTear:ToTear().Scale > tear.Scale then
                return false
            end
        end
        return true
    end,

    getSizeAnimation = function(bullet) --(TearEntity)->[Int] Returns size animation number.
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
    end,

    touchPickup = function(entity, pickup) --(Entity, Pickup) Take pickup if touched by the entity

        --Pinking shears interaction
        local collider
        if entity.Type == EntityType.ENTITY_PLAYER and entity:GetData().cuttedBody ~= nil and entity:GetData().cuttedBody:Exists() then
            collider = entity:GetData().cuttedBody
        else
            collider = entity
        end

        --Collision
        if MR.entity.entityCollision(pickup, collider) then
            MR.metalPiece.take(pickup, entity)
        end
    end,

    findNearestPickup = function(position, ...) --(Position, {PickupVariant}, {FromEntity}, {Pathfinder})->[Entity] Returns nearest pickup
        local args = {...}
        local nearestPickup = nil
        local nearestPosition = nil
        for _, pickup in pairs(MR.metalPiece.pickupsAlive) do
            --MR.debug.setVariable("NP", false, pickup)
            if (args[1]==nil or (pickup:GetData().pieceVariant == args[1]))
            and (args[2]==nil or MR.entity.equal(pickup.SpawnerEntity, args[2]))
            and (args[3]==nil or args[3]:HasPathToPos(position, false))
            and (pickup:GetData().isAnchorage or MR.pos.isNoneCollision(pickup.Position)) then
                if nearestPickup == nil or MR.vect.toDistance(position, pickup.Position) < nearestPosition then
                    nearestPosition = MR.vect.toDistance(position, pickup.Position)
                    nearestPickup = pickup
                end
            end
        end
        --if nearestPickup ~= nil then MR.debug.setVariable("NP", true, nearestPickup) end
        return nearestPickup
    end,

}

MR.bottle = {
    MINERAL_TAKING_BOTTLE = 0.2,
    ROCK_APPEAR = 0.005,
    ANCHORAGE_POS = {
        [GridEntityType.GRID_ROCK] = {
            [0] = Vector(-7, -4),
            [1] = Vector(-9, 5),
            [2] = Vector(-6, -4),
            [1000] = Vector(-8, -6),
            [1001] = Vector(-6, -5),
            [1002] = Vector(-4, -3),
            [1003] = Vector(-6, -8),
            [1004] = Vector(-6, -13),
            [1005] = Vector(0, -8),
            [1006] = Vector(-5, -8),
            [1007] = Vector(-6, -8),
        },

        [GridEntityType.GRID_ROCK_BOMB] = Vector(-6, 3),
        [GridEntityType.GRID_ROCK_ALT] = Vector(0, -14),
        [GridEntityType.GRID_ROCK_ALT2] = Vector(0,0)
    },

    toAnchorage = function(bottle) --(EntityPickup) Transform bottle pickup to anchorage.
        bottle:GetData().gridEntityTouched = Game():GetRoom():GetGridEntityFromPos(bottle.Position)
        bottle:GetData().isAnchorage = true
        bottle:GetData().inWall = false
        bottle:GetSprite():Play("Stucked")
        bottle.Friction = 100
    end,

    isGridSpawnerRock = function(gridEntity) --(GridEntity)->[Bool] Return if gridEntity is a destroyable rock.
        return gridEntity ~= nil and
                (gridEntity:GetType() == GridEntityType.GRID_ROCK or
                gridEntity:GetType() == GridEntityType.GRID_ROCK_BOMB or
                gridEntity:GetType() == GridEntityType.GRID_ROCK_ALT or
                gridEntity:GetType() == GridEntityType.GRID_ROCK_ALT2)
    end
}

MR.enemy = {
    mark = {
        ref = {
            [0] = "gfx/effects/mark/Iron.png",
            [1] = "gfx/effects/mark/Steel.png",
        },

        spawn = function(position) --(Position)->[EntityMark] Spawns a random type mark on a specific position.

            local sel = math.random(0,1)
            return Isaac.Spawn(EntityType.ENTITY_PICKUP, MR.type.pickup.floorMark, sel, position-Vector(8,8), Vector(0,0), nil)

        end,
    }
}

--Powers
MR.allomancy = {
    ALLOMANCY_BAR_MAX = 2500,

    physical = {
        FAST_CRASH_DMG_MULT = 1,
        PUSHED_COIN_DMG_MULT = 1.5,

        use = function(entity) --(Entity) Make entity push/pull selected entities.
            local data = entity:GetData()

            MR.entity.collideGrid(entity)
            if data.selectedEntities ~= nil and (entity.Type ~= EntityType.ENTITY_PLAYER or (entity.Type == EntityType.ENTITY_PLAYER and data.mineralBar>0)) then
                for index, selEntity in pairs(data.selectedEntities) do
                    local pushEntity = selEntity

                    --To tear coins
                    if selEntity.Type == EntityType.ENTITY_TEAR and selEntity.Variant == MR.type.tear.metalPiece and selEntity.Visible then
                        MR.metalPiece.collideGrid(selEntity)

                        if selEntity:ToTear().StickTarget ~= nil then
                            if MR.entity.equal(selEntity:ToTear().StickTarget, entity) then
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
                    if not pushEntity:GetData().gridTouched and (pushEntity:CollidesWithGrid()) and not MR.entity.is.metalPieceBullet(pushEntity) then

                        pushEntity:GetData().gridTouched = true

                        if pushEntity:IsEnemy() then
                            --If is enemy and collision in grid drop coin and if it's at high speed get a hit
                            if MR.vect.biggerThan(pushEntity.Velocity,MR.allomancy.physical.velocity.MIN_TO_GRID_SMASH) then
                                if pushEntity:GetData().hitFrame == nil or (Game():GetFrameCount()-pushEntity:GetData().hitFrame > MR.allomancy.physical.time.BETWEEN_GRID_SMASH) then
                                    MR.sound.play(MR.sound.ENTITY_CRASH, math.abs(MR.vect.getHigher(pushEntity.Velocity)/10), 0, false, 1)
                                    pushEntity:AddVelocity((pushEntity.Velocity)*-5)
                                    pushEntity:TakeDamage(pushEntity:GetData().stickTear:GetData().BaseDamage*MR.allomancy.physical.FAST_CRASH_DMG_MULT,0,EntityRef(entity),60)
                                    pushEntity:GetData().hitFrame = Game():GetFrameCount()
                                end
                            end
                            pushEntity:GetData().stickTear.StickTarget = nil
                        end
                    end

                    --Deslect if touch entity
                    if MR.entity.entityCollision(pushEntity,entity)
                    and not ((MR.entity.is.metalPiecePickup(pushEntity) or MR.entity.is.metalPieceBullet(pushEntity))) then
                        MR.tracer.deselectEntityIndex(entity, index)
                    end

                    local toPushEntity = pushEntity
                    local opposite = false

                    --Opposite if cant move entity
                        --Anchorage
                    if pushEntity:GetData().isAnchorage or
                        --Pulling entity that collides with grid
                    (pushEntity:GetData().gridTouched) or
                        --Stopped entity
                    (pushEntity:IsEnemy() and MR.vect.isZero(pushEntity.Velocity)) then

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
                    local velocity = MR.allomancy.physical.pushVelocity(entity, pushEntity, opposite, fromEntity)
                    if entity.Type ~= EntityType.ENTITY_PLAYER then
                        velocity = 30*velocity
                    end

                    --Add push/pull velocity
                    toPushEntity:AddVelocity(velocity)

                    --Limit velocity to some entities
                    if toPushEntity.Type == EntityType.ENTITY_PLAYER or toPushEntity:GetData().modEnemy then
                        toPushEntity.Velocity = MR.vect.capVelocity(toPushEntity.Velocity, 20)
                    end

                    --If has a sticked tear change tear position to enemy position
                    if pushEntity:GetData().stickTear ~= nil then
                        pushEntity:GetData().stickTear.Position = pushEntity.Position+pushEntity:GetData().stickTear:ToTear().StickDiff
                    end

                    --If is on a laser change laser position to entity position
                    if pushEntity:GetData().onLaser ~= nil then
                        MR.metalPiece.laserPosition(pushEntity:GetData().onLaser, pushEntity)
                    end

                    --Unpin coins
                    if (pushEntity:GetData().isAnchorage and MR.entity.is.metalPiecePickup(pushEntity)) and opposite and entity:GetData().gridTouched then
                        selEntity.Friction = MR.metalPiece.coin.FRICTION_PICKUP
                        selEntity:GetData().isAnchorage = false
                        local animation
                        --Other metalPieces interactions
                        if selEntity:GetData().pieceVariant == MR.enum.pieceVariant.COIN then
                            local anim = selEntity:GetSprite():GetAnimation()
                            animation = "Idle"..anim:sub(anim:len())
                        else
                            animation = "Idle"
                        end

                        selEntity:GetSprite():Play(animation,true)
                        selEntity.Position = Game():GetRoom():FindFreeTilePosition(selEntity.Position,25)
                        selEntity.Velocity = ((MR.vect.baseOne(MR.vect.director(selEntity.Position, entity.Position)))*3)
                    end

                    --If player touch grid, deselect entity
                    if data.gridTouched and selEntity:GetData().gridTouched then
                        MR.tracer.deselectEntityIndex(entity, index)
                    end

                    --Spend minerals to players
                    if entity.Type == EntityType.ENTITY_PLAYER then MR.allomancy.spendMinerals(data, data.movingTime, 1) end
                end
            end
        end,

        isUsingPower = function(player) --(Player)->[Bool] Return if player is using some physical power.
            return player:GetData().pushing or player:GetData().pulling
        end,

        has = function(entity) --(Player)->[Bool] Return if player has a physical power.
            if entity:GetData().AllomanticPowers ~= nil then
                return entity:GetData().AllomanticPowers[MR.enum.power.STEEL] ~= nil or entity:GetData().AllomanticPowers[MR.enum.power.IRON] ~= nil
            end
        end,

        pushVelocity = function(entity, pushEntity, opposite, ...) --(Entity, Entity, Bool, {Entity})->[Vector velocity] Return push/pull velocity, {entity} to change fromEntity position.
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
                        n = MR.allomancy.physical.velocity.push.ENEMY*1+(MR.allomancy.physical.velocity.AIMING_PUSH_ENTITY_VEL-MR.vect.toInt(pushEntity.Velocity))
                    else
                        n = MR.allomancy.physical.velocity.push.ENEMY
                    end
                --Knife exception
                elseif toPushEntity:GetData().pieceVariant == MR.enum.pieceVariant.KNIFE then
                    if toPushEntity.Type == EntityType.ENTITY_TEAR then
                        n = MR.allomancy.physical.velocity.push.KNIFE_TEAR
                    elseif toPushEntity.Type == EntityType.ENTITY_PICKUP then
                        n = MR.allomancy.physical.velocity.push.KNIFE_PICKUP
                    end
                else
                    n = MR.allomancy.physical.velocity.push[toPushEntity.Type]
                end

                return MR.vect.fromToEntity(pushEntity, fromEntity, oppositeMultiplicator*(n/100)*(MR.vect.distanceMult(fromEntity.Position,pushEntity.Position, 600)+baseMultiplicator))
            else
                return Vector(0,0)
            end
        end,

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
        },

        time = {
            BETWEEN_HIT_DAMAGE = 15,
            BETWEEN_DOUBLE_HIT = 30,
            BETWEEN_GRID_SMASH = 30
        },
    },

    hasPower = function(entity, power) --(Player, String)->[Bool] Return if player has a specific power.
        if entity:GetData().AllomanticPowers ~= nil then
            return entity:GetData().AllomanticPowers[power] ~= nil
        end
    end,

    powersToStrings = function(powers) --(Table)->[Table] Return a string table from power's table.

        local resultado = {}
        local is = {
                steel = false,
                iron = false,
                pewter = false,
                zinc = false,
                brass = false,
                cadmium = false,
                bendalloy = false
        }

        for index, element in pairs(powers) do

            if powers[MR.enum.power.STEEL] ~= nil and not is.steel  then
                table.insert(resultado, MR.enum.power.STEEL)
                is.steel = true
            elseif powers[MR.enum.power.IRON] ~= nil and not is.iron then
                table.insert(resultado,MR.enum.power.IRON)
                is.iron = true
            elseif powers[MR.enum.power.PEWTER] ~= nil and not is.pewter then
                table.insert(resultado,MR.enum.power.PEWTER)
                is.pewter = true
            elseif powers[MR.enum.power.BENDALLOY] ~= nil and not is.bendalloy then
                table.insert(resultado,MR.enum.power.BENDALLOY)
                is.bendalloy = true
            elseif powers[MR.enum.power.ZINC] ~= nil and not is.zinc then
                table.insert(resultado,MR.enum.power.ZINC)
                is.zinc = true
            elseif powers[MR.enum.power.BRASS] ~= nil and not is.brass then
                table.insert(resultado,MR.enum.power.BRASS)
                is.brass = true
            elseif powers[MR.enum.power.CADMIUM] ~= nil and not is.cadmium then
                table.insert(resultado,MR.enum.power.CADMIUM)
                is.cadmium = true
            end
        end
        return resultado
    end,

    pressingPower = function(power, player) --(String, Player)->[Bool] Return if player is pressing the specific power button.
        local pData = player:GetData()
        for i=1, 3, 1 do
            if pData.SortedPowers[i] == power then
                return Input.IsActionPressed(MR.control.action[i], player.ControllerIndex)
            end
        end
        return false
    end,

    pressedPower = function(power, player)  --(String, Player)->[Bool] Return if player has pressed the specific power button.
        local pData = player:GetData()
        for i=1, 3, 1 do
            if pData.SortedPowers[i] == power then
                return Input.IsActionTriggered(MR.control.action[i], player.ControllerIndex)
            end
        end
        return false
    end,

    spendMinerals = function(data, time, mult) --(EntityData, num, num) Make entity spend minerals.
        if time ~= nil then
            local tiempo = Isaac.GetFrameCount()
            local tiempoEmpujando = tiempo - time
            data.usePowerFrame = Isaac.GetFrameCount()

            if tiempoEmpujando ~= 0 then
                data.mineralBar = data.mineralBar-(tiempoEmpujando*mult)
                data.movingTime=tiempo
            end
        end
    end,
}

MR.tracer = {
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

        MR.tracer.deselectEntities(entity)
        data.gridTouched = false
        data.movingTime = Isaac.GetFrameCount()

        --Select direction
        local direction
        if entity.Type == EntityType.ENTITY_PLAYER then
            if  MR.vect.someMin(MR.vect.absolute(entity:GetShootingJoystick()), 0.3) then
                direction = entity:GetShootingJoystick()
            elseif data.shotFrame ~= nil and Isaac.GetFrameCount()-data.shotFrame <= MR.tracer.MAX_TIME_TO_USE_LAST_SHOT_DIRECTION then
                direction = data.lastDirectionShooting
            elseif not MR.vect.isZero(entity:GetMovementInput()) then
                direction = entity:GetMovementInput()
            elseif not MR.vect.isZero(data.lastDirectionShooting) then
                direction = data.lastDirectionShooting
            else
                direction = Vector(0,0)
            end
            direction = (MR.vect.baseOne(direction))
        elseif args[1] ~= nil then
            direction = MR.vect.baseOne(args[1])
        end

        --Throw tracer
        local pointer = entity.Position
        local someSelect = false
        while not MR.pos.isWall(pointer) do
            --Select entities
            local foundEntities = Isaac.FindInRadius(pointer, MR.math.upperBound(5+entity.Position:Distance(pointer)/4, MR.tracer.MAX_RADIUS), 0xFFFFFFFF)
            for _, sEntity in pairs(foundEntities) do
                if MR.entity.is.metalicEntity(sEntity) and not MR.array.containsEntity(entity:GetData().selectedEntities,sEntity) then

                    --Ensure focus selection
                    if data.focusSelection == 0 then
                        if sEntity.Type==EntityType.ENTITY_TEAR then
                            --If find a enemy focus it deselecting other entities
                            if sEntity:ToTear().StickTarget ~= nil then
                                MR.tracer.focusEnemy(sEntity, entity)
                            else
                                MR.tracer.focusTear(sEntity, entity)
                            end
                        end
                        MR.tracer.selectEntity(entity, sEntity)

                    --If focus just add other enemies
                    elseif data.focusSelection == 2 and sEntity.Type==EntityType.ENTITY_TEAR and sEntity:ToTear().StickTarget ~= nil then
                        MR.tracer.selectEntity(entity, sEntity)
                    elseif data.focusSelection == 1 and sEntity.Type==EntityType.ENTITY_TEAR then
                        if sEntity:ToTear().StickTarget ~= nil then
                            MR.tracer.focusEnemy(sEntity, entity)
                        end
                        MR.tracer.selectEntity(entity, sEntity)
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
                if (MR.entity.isExisting(entity:GetData().LudovicoTear) and entity:GetData().LudovicoTear:GetData().isMetalPiece) then
                    MR.tracer.selectEntity(entity, entity:GetData().LudovicoTear)
                elseif MR.entity.isExisting(entity:GetData().mainKnife) and MR.entity.isExisting(entity:GetData().mainKnife:GetData().knifeTear) then
                    MR.tracer.selectEntity(entity, entity:GetData().mainKnife:GetData().knifeTear)
                end
            end
            if MR.entity.isExisting(entity:GetData().lastCoin) then
                MR.tracer.selectEntity(entity, entity:GetData().lastCoin)
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
                MR.tracer.deselectEntityIndex(fromEntity, id)
            end
        end
    end,

    focusTear = function(sEntity, fromEntity) --(Entity, Entity) Focus tears on tracer selection (deselects other entities).
        local data = fromEntity:GetData()

        data.focusSelection = 1
        for id, selEntity in pairs(fromEntity:GetData().selectedEntities) do
            if not (selEntity.Type==EntityType.ENTITY_TEAR) then
                MR.tracer.deselectEntityIndex(fromEntity, id)
            end
        end
    end
}

--PLAYER
function MR:PlayerStart(player)

    local pData = player:GetData()

    if pData.AllomanticPowers == nil then pData.AllomanticPowers = {} end
    if pData.mineralBar == nil then pData.mineralBar = MR.allomancy.ALLOMANCY_BAR_MAX end
    if pData.realFireDelay == nil then pData.realFireDelay = player.MaxFireDelay end
    if pData.selectedEntities == nil then pData.selectedEntities = {} end
    if pData.lastDirectionShooting == nil then pData.lastDirectionShooting = Vector(0,0) end
    if pData.multiShotNum == nil then pData.multiShotNum = 1 end

    if player.ControllerIndex == 1 then
        MR.metalPiece.coin.wasted = 0
    end
end

function MR:PlayerUpdate(player)
    local pData = player:GetData()
    local sprite = player:GetSprite()

    --DETECCIONES GENERALES

    MR.entity.collideGrid(player)
    if pData.mineralBar == nil then pData.mineralBar = MR.allomancy.ALLOMANCY_BAR_MAX end

    --Evaluate cache
    if (player:GetNumCoins()>0 and not pData.statsChanged) or (player:GetNumCoins() < 1 and pData.statsChanged) or not player:HasWeaponType(WeaponType.WEAPON_TEARS) then
        player:AddCacheFlags(CacheFlag.CACHE_FIREDELAY)
        player:EvaluateItems()
    end

    --Init coop ghost
    if player:IsCoopGhost() and player:GetPlayerType()==MR.type.player.allomancer then
        sprite:ReplaceSpritesheet(0, MR.player.allomancer.GHOST_COOP)
        sprite:LoadGraphics()
    end

    --Pillar por primera vez hierro
    if player:HasCollectible(MR.type.item.ironLerasiumAlloy) and pData.AllomanticPowers[MR.enum.power.IRON] == nil then
        pData.AllomanticPowers[MR.enum.power.IRON] = true
        pData.SortedPowers = MR.allomancy.powersToStrings(pData.AllomanticPowers)
    end
    --Pillar por primera vez acero
    if player:HasCollectible(MR.type.item.steelLerasiumAlloy) and pData.AllomanticPowers[MR.enum.power.STEEL] == nil then
        pData.AllomanticPowers[MR.enum.power.STEEL] = true
        pData.SortedPowers = MR.allomancy.powersToStrings(pData.AllomanticPowers)
    end

    --Selected entities
    if pData.selectedEntities ~= nil then
        for index, selEntity in pairs(pData.selectedEntities) do

            if not selEntity:Exists() then
                MR.tracer.deselectEntityIndex(player, index)
            end

            if (not (MR.entity.is.metalPiecePickup(selEntity) and selEntity:GetData().isAnchorage) and (not MR.entity.is.metalPieceBullet(selEntity)) and (not MR.entity.is.bottle(selEntity) and selEntity:GetData().isAnchorage)) then
                if not MR.pos.isNoneCollision(selEntity.Position) then
                    selEntity.Position = Game():GetRoom():FindFreeTilePosition(selEntity.Position,25)
                end
            end

        end
    end

    --Player crash
    if MR.vect.biggerThan(player.Velocity,MR.allomancy.physical.velocity.MIN_TO_PLAYER_HIT) and MR.allomancy.physical.has(player) and Game():GetNumPlayers() > 1 then
        for pID=0, Game():GetNumPlayers()-1, 1 do
            local p2 = Isaac.GetPlayer(pID)
            if GetPtrHash(player) ~= GetPtrHash(p2) and MR.entity.entityCollision(player, p2) then
                p2:AddVelocity((MR.vect.rotateNinety(player.Velocity))*0.25)
            end
        end
    end
end

function MR:CacheUpdate(player, cacheFlag)
    local pData = player:GetData()
    if cacheFlag & CacheFlag.CACHE_FIREDELAY == CacheFlag.CACHE_FIREDELAY then

        if pData.statsChanged then
            local add = player.MaxFireDelay-(pData.realFireDelay)
            pData.realFireDelay = pData.realFireDelay + add

            if player:HasWeaponType(WeaponType.WEAPON_TEARS) or player:HasWeaponType(WeaponType.WEAPON_LASER) then
                player.MaxFireDelay = pData.realFireDelay*2
            elseif player:HasWeaponType(WeaponType.WEAPON_MONSTROS_LUNGS) then
                player.MaxFireDelay = pData.realFireDelay*(1+MR.math.upperBound(player:GetNumCoins(),14)/14)
            elseif player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) then
                player.MaxFireDelay = pData.realFireDelay*(1+(MR.math.upperBound(player:GetNumCoins(),8)/8))
            end
        else
            pData.realFireDelay = player.MaxFireDelay
        end

        if pData.controlsChanged and player:GetNumCoins()>0 and not pData.statsChanged then
            pData.statsChanged = true
            if player:HasWeaponType(WeaponType.WEAPON_TEARS) or player:HasWeaponType(WeaponType.WEAPON_LASER) then
                player.MaxFireDelay = pData.realFireDelay*2
            elseif player:HasWeaponType(WeaponType.WEAPON_MONSTROS_LUNGS) then
                player.MaxFireDelay = pData.realFireDelay*(1+MR.math.upperBound(player:GetNumCoins(),14)/14)
            elseif player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) then
                player.MaxFireDelay = pData.realFireDelay*(1+(MR.math.upperBound(player:GetNumCoins(),8)/8))
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
                player.FireDelay = MR.math.lowerBound(player.FireDelay-player.MaxFireDelay/(2*player:GetData().multiShotNum), 0)
            end
        end
    end
end

--GAME
function MR:StartGame(continued)
    if continued then
        MR.data.loadInfo()
    end
end

function MR:GameExit(notEnd)
    for pID=0, Game():GetNumPlayers()-1, 1 do
        local player = Isaac.GetPlayer(pID)
        if notEnd then
            MR.metalPiece.takeAllFloor(player)
        else
            MR.metalPiece.coin.wasted = 0
        end
    end
    MR.data.saveInfo()
end

function MR:GameEnd(isOver)
    if not isOver then
        if Game().Difficulty == 2 and MR.data.marks[MR.enum.markId.GREED] < 1 then
            MR.data.marks[MR.enum.markId.GREED] = 1
        elseif Game().Difficulty == 3 and MR.data.marks[MR.enum.markId.GREED] < 2 then
            MR.data.marks[MR.enum.markId.GREED] = 2
        end
    end
end

function MR:GameRender(shader)

    for pID=0, Game():GetNumPlayers()-1, 1 do
        local player = Isaac.GetPlayer(pID)
        local pData = player:GetData()
        local playerPowers = MR.array.getSize(pData.AllomanticPowers)

        --HUD
        if playerPowers > 0 then

            pData.AllomancyIcon = Sprite();
            pData.AllomancyIcon:Load(MR.hud.ref.ALLOMANCY_ANM, true);

            local buttonIcon = Sprite();
            buttonIcon:Load(MR.hud.ref.BUTTON_ANM, true);

            local stomachIcon = Sprite();
            stomachIcon:Load(MR.hud.ref.STOMACH_ANM, true)

            local frame = MR.math.round(pData.mineralBar/(MR.allomancy.ALLOMANCY_BAR_MAX/17))

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

            stomachIcon:Render(MR.hud.percToPos(MR.hud.pos.STOMACH[pID]), Vector(0,0), Vector(0,0));

            local div = 1
            if pID ~= 0 then
                div = 2
            end

            if playerPowers > 0 then
                buttonIcon:Play("LT", true)
                buttonIcon:Render(MR.hud.percToPos(MR.hud.pos.ALLOMANCY[pID])+Vector(0,15/div), Vector(0,0), Vector(0,0));
                MR.hud.changeAlomanticIconSprite(1,player)
                pData.AllomancyIcon:Render(MR.hud.percToPos(MR.hud.pos.ALLOMANCY[pID]), Vector(0,0), Vector(0,0));
            end

            if playerPowers > 1 then
                buttonIcon:Play("RB", true)
                buttonIcon:Render(MR.hud.percToPos(MR.hud.pos.ALLOMANCY[pID])+Vector(15/div,15/div), Vector(0,0), Vector(0,0));
                MR.hud.changeAlomanticIconSprite(2,player)
                pData.AllomancyIcon:Render(MR.hud.percToPos(MR.hud.pos.ALLOMANCY[pID])+Vector(15/div,0), Vector(0,0), Vector(0,0));
            end

            if playerPowers > 2 then
                buttonIcon:Play("LB", true)
                buttonIcon:Render(MR.hud.percToPos(MR.hud.pos.ALLOMANCY[pID])+Vector(30/div,15/div), Vector(0,0), Vector(0,0));
                MR.hud.changeAlomanticIconSprite(3,player)
                pData.AllomancyIcon:Render(MR.hud.percToPos(MR.hud.pos.ALLOMANCY[pID])+Vector(30/div,0), Vector(0,0), Vector(0,0));
            end
        end

        --CONTROLS
        MR.control.oneTap(player)

        --Touch metalPiece pickups
        for index, pickup in  pairs(MR.metalPiece.pickupsAlive) do
            if pickup:Exists() then
                MR.metalPiece.touchPickup(player, pickup)
            else
                table.remove(MR.metalPiece.pickupsAlive, index)
            end
        end

        --Bullet touch grid or projectile touch player
        for index, tear in pairs(MR.metalPiece.coin.CoinTears) do
            if tear:Exists() then
                MR.metalPiece.collideGrid(tear)
                MR.metalPiece.collideHitPlayer(tear, player)
            else
                table.remove(MR.metalPiece.coin.CoinTears,index)
            end
        end
    end

    --COMPLETION NOTE
    if MR.player.someIsType(MR.type.player.allomancer) then
        if shader and Isaac.GetFrameCount()-MR.hud.escFrame > 15 then
            local noteMark = Sprite()
            if not noteMark:IsLoaded() then
                noteMark:Load(MR.hud.ref.COMPLETION_NOTE_ANM, true)
                noteMark:ReplaceSpritesheet(0,MR.hud.ref.COMPLETION_NOTE_PAUSE_PNG)
                noteMark:LoadGraphics()
                noteMark:Play("Idle", true)
            end
            MR.hud.changeNoteMarks(noteMark)
            noteMark:Render(Isaac.WorldToRenderPosition(Vector(211,151)),Vector(0, 0), Vector(0, 0))
            noteMark:Update()
        end
    end

    --DEBUG
    if MR.debug.active then

        --Screen variables
        for i=1, MR.debug.config.numVar+1, 1 do
            if MR.debug.Variables[i] ~= nil and MR.debug.Variables[i].ressult ~= nil then
                local mesVar = ""
                if MR.debug.Variables[i].name ~= "" then
                    mesVar = MR.debug.Variables[i].name..": "
                end

                local r=1; local g=1; local b=1

                if type(MR.debug.Variables[i].ressult)=="boolean" then
                    if MR.debug.Variables[i].ressult then
                        r=0; g=1; b=0
                    else
                        r=1; g=0; b=0
                    end
                    mesVar = mesVar..MR.str.bool(MR.debug.Variables[i].ressult)
                else
                    mesVar = mesVar..MR.debug.Variables[i].ressult
                end
                Isaac.RenderText(mesVar, 32, 28+(11*(i-1)), r, g, b, 1)
            end
        end

        --Entity variables
        local f = Font()
        f:Load("font/pftempestasevencondensed.fnt")
        for index, entity in pairs(MR.debug.EntitiesWithMessages) do

            if not entity:Exists() then
                table.remove(MR.debug.EntitiesWithMessages, index)
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

                            mesVar = mesVar..MR.str.bool(data.DebugVariables[i].ressult)
                        else
                            mesVar = mesVar..data.DebugVariables[i].ressult
                        end
                        f:DrawString(mesVar, pos.X-f:GetStringWidth(mesVar)/2, pos.Y+(f:GetLineHeight()*(i-1)),KColor(r,g,b,1),0,true)
                    end
                end
            end
        end

        --Mensajes por pantalla
        for i=1, MR.debug.config.numMess+1, 1 do
            if MR.debug.messageVars.quantity > 0 and i==1 then
                if MR.debug.Messages[i] ~= nil then
                    Isaac.RenderText("x"..MR.debug.messageVars.quantity..": "..MR.debug.Messages[i], 5, 255-(11*(i-1)), 1, 1, 1, MR.debug.messageVars.opacity-((1/MR.debug.config.numMess)*(i-1)))
                end
            else
                if MR.debug.Messages[i] ~= nil then
                    Isaac.RenderText(MR.debug.Messages[i], 5, 255-(11*(i-1)), 1, 1, 1, MR.debug.messageVars.opacity-((1/MR.debug.config.numMess)*(i-1)))
                end
            end
        end

        if MR.debug.messageVars.opacity > 0 then
            MR.debug.messageVars.opacity = MR.debug.messageVars.opacity-0.003
        end

        --Mensajes a entidades
        for i=1, #MR.debug.EntityMessages, 1 do
            local opacity = 1

            if MR.debug.EntityMessages[i] ~= nil and MR.debug.EntityMessages[i].displacement < 100 then
                opacity = opacity - MR.debug.EntityMessages[i].displacement/100
            else
                opacity = 0
                if MR.debug.EntityMessages[i] ~= nil then
                    table.remove(MR.debug.EntityMessages, i)
                end
            end

            if MR.debug.EntityMessages[i] ~= nil then
                f:DrawString(MR.debug.EntityMessages[i].message, MR.debug.EntityMessages[i].position.X-f:GetStringWidth(MR.debug.EntityMessages[i].message)/2, MR.debug.EntityMessages[i].position.Y-MR.debug.EntityMessages[i].displacement,KColor(1,1,1,opacity,0,0,0),0,true)
                MR.debug.EntityMessages[i].displacement = (Isaac.GetFrameCount()-MR.debug.EntityMessages[i].initFrame)/3
            end
        end
    end
end

function MR:Shaderhook(nm) --thanks tem!

    if (nm == "PostitStartMenu") then
        local cid = Game():GetPlayer(0).ControllerIndex
        if Game():IsPaused() and Isaac.GetFrameCount()-MR.hud.escFrame > 10 and Input.IsActionTriggered(ButtonAction.ACTION_PAUSE,cid) or Input.IsButtonTriggered(Keyboard.KEY_ESCAPE,cid) or (Input.IsActionTriggered(ButtonAction.ACTION_MENUBACK,cid) and Game():IsPaused()) then
            if Input.IsActionTriggered(ButtonAction.ACTION_PAUSE,cid) or Input.IsButtonTriggered(Keyboard.KEY_ESCAPE,cid) then
                MR.hud.esc = not MR.hud.esc
                MR.hud.escFrame = Isaac.GetFrameCount()
            else
                MR.hud.esc = true
                MR.hud.escFrame = Isaac.GetFrameCount()
            end
        elseif (not Game():IsPaused()) or Input.IsActionPressed(ButtonAction.ACTION_MENUCONFIRM,cid) or Input.IsButtonPressed(Keyboard.KEY_ENTER,cid) then
            MR.hud.esc = false
        end

        if MR.hud.esc and (Game():GetRoom():GetFrameCount() > 1) then
            MR:GameRender(true)
        end
    end
end

--LEVEL/ROOM
function MR:LevelEnter()
    MR.room.savedEntities = {}
    MR.room.bottleRocksSpawned = 0
end

function MR:RoomEnter()

    MR.debug.EntitiesWithMessages = {}
    MR.metalPiece.coin.CoinTears = {}

    for pID=0, Game():GetNumPlayers()-1, 1 do
        local player = Isaac.GetPlayer(pID)

        MR.tracer.deselectEntities(player)
        MR.metalPiece.takeAllFloor(player)
        player:GetData().shotKnives = 0
        player:GetData().invisibleKnives = 0
    end

    if MR.player.someIsType(MR.type.player.allomancer) then

        if Game():GetLevel():GetCurrentRoomDesc().VisitedCount == 1 then

            local initRocks = MR.room.getGridRockEntities()

            for _, grid in pairs(initRocks) do
                local posibility = math.random()

                if posibility < MR.bottle.ROCK_APPEAR/(MR.room.bottleRocksSpawned+1) then

                    MR.room.bottleRocksSpawned = MR.room.bottleRocksSpawned+1
                    local spawnPos = grid.Position
                    if MR.bottle.ANCHORAGE_POS[grid:GetType()][grid:GetVariant()] ~= nil then
                        spawnPos = spawnPos + MR.bottle.ANCHORAGE_POS[grid:GetType()][grid:GetVariant()]
                    else
                        spawnPos = spawnPos + MR.bottle.ANCHORAGE_POS[grid:GetType()]
                    end
                    local bottle = Isaac.Spawn(EntityType.ENTITY_PICKUP, MR.type.pickup.mineralBottle, 1, spawnPos, Vector(0,0), nil)
                    MR.bottle.toAnchorage(bottle)
                end
            end
        else
            for _, bottle in pairs(Isaac.GetRoomEntities()) do
                if MR.entity.is.bottle(bottle) and MR.bottle.isGridSpawnerRock(Game():GetRoom():GetGridEntityFromPos(bottle.Position)) then
                    MR.bottle.toAnchorage(bottle)
                end
            end

        end
    end
end

function MR:RoomClear(rng, spawnPos)
    local room = Game():GetRoom()
    local pos = rng:RandomFloat()
    local canGo = false
    local minMineral
    local n

    if MR.player.someIsType(MR.type.player.allomancer) then
        --Get minMineral on players
        for pID=0, Game():GetNumPlayers()-1, 1 do
            local player = Isaac.GetPlayer(pID)
            if MR.allomancy.physical.has(player) then
                if minMineral == nil or minMineral > player:GetData().mineralBar then minMineral = player:GetData().mineralBar end
            end
        end

        --If there's not a minMineral set pos to 1%
        if minMineral ~= nil then
            local per = minMineral/MR.allomancy.ALLOMANCY_BAR_MAX
            n = (1-per)/3
        else
            n = 0.01
        end

        --Get random pos
        if pos < n or Isaac.GetPlayer(0):GetData().spawnMark then
            local randPos = room:GetRandomPosition(50)
            local try = 0
            while (not (MR.pos.isNoneCollision(randPos) or MR.pos.isNoneCollision(randPos+Vector(0,20)) or MR.pos.isNoneCollision(randPos+Vector(0,-20)) or MR.pos.isNoneCollision(randPos+Vector(20,0)) or MR.pos.isNoneCollision(randPos+Vector(-20,0)))
            or not room:CheckLine(Isaac.GetPlayer(0).Position, randPos, 0, 50, false, false)
            or #Isaac.FindInRadius(randPos, 50, EntityPartition.PLAYER)>=1)
            and try < 1000 do
                try = try+1
                randPos = room:GetRandomPosition(50)
            end

            --If found a point
            if try < 1000 then
                MR.enemy.mark.spawn(randPos)
                Isaac.GetPlayer(0):GetData().spawnMark = false
            else
                Isaac.GetPlayer(0):GetData().spawnMark = true
            end
        end
    end

    --Mark bossrush
    if room:GetType()==RoomType.ROOM_BOSSRUSH and MR.player.someIsType(MR.type.player.allomancer) then
        MR.data.putMark(MR.enum.markId.STAR)
    end
end

--CONTROLS
function MR:ControlsUpdate(entity, hook, action)

    if entity ~= nil then

        local player = entity:ToPlayer()
        local pData = player:GetData()

        --SI TIENES CUALQUIERA DE LOS ITEMS METÁLICOS
        if player and MR.allomancy.physical.has(player) and pData.controlsChanged then
            --CONTROLES DE PRESIÓN
            if MR.allomancy.pressingPower(MR.enum.power.IRON, player) or MR.allomancy.pressingPower(MR.enum.power.STEEL, player) then
                MR.allomancy.physical.use(player)

                if MR.allomancy.pressingPower(MR.enum.power.IRON, player) then pData.pulling = true else pData.pulling = false end
                if MR.allomancy.pressingPower(MR.enum.power.STEEL, player) then pData.pushing = true else pData.pushing = false end

            else
                if #pData.selectedEntities > 0 then
                    MR.tracer.deselectEntities(entity)
                end
            end
        end
    end
end

function MR:ControlsBlockInputs(entity, inputHook, buttonAction)
    if entity ~= nil and entity.Type == EntityType.ENTITY_PLAYER then
        local player = entity:ToPlayer()
        local pData = player:GetData()
        local controller = player.ControllerIndex
        if pData.controlsChanged then
            if Input.IsActionTriggered(MR.control.action[1],controller) or Input.IsActionTriggered(MR.control.action[2],controller) or Input.IsActionTriggered(MR.control.action[3],controller) then
                return false
            end
        end
    end
end

--TEAR
function MR:TearStart(tear)
    if tear.SpawnerEntity:ToPlayer() ~= nil then
        local player = tear.SpawnerEntity:ToPlayer()
        local pData = player:GetData()
        local tearData = tear:GetData()

        --Ludovico interaction
        if player:HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE) or (pData.LudovicoLaser~=nil and pData.LudovicoLaser:Exists()) then
            --Change to tear
            if pData.controlsChanged and player:GetNumCoins()>0 then
                MR.metalPiece.coin.init(tear)
            end
            --Set on data
            if (pData.LudovicoTear == nil or not pData.LudovicoTear:Exists()) or MR.metalPiece.isLudovicoMainTear(tear) then
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

function MR:TearFire(tear)

    local tearData = tear:GetData()
    local player = tear.SpawnerEntity:ToPlayer()
    local pData = player:GetData()

    --LÁGRIMAS DE MONEDA
    if MR.allomancy.physical.has(player) and pData.controlsChanged then

        --Usual tear coins
        if player:GetNumCoins() > 0 and pData.fireNotCoin == nil then
        --Monstruo's lung exception
        --and ((not player:HasWeaponType(WeaponType.WEAPON_MONSTROS_LUNGS)
        --and MR.vect.facingSameDirection(MR.player.fireTearVelocity(player), tear.Velocity, 120))
        --or player:HasWeaponType(WeaponType.WEAPON_MONSTROS_LUNGS)) then

            MR.metalPiece.coin.init(tear)
            pData.lastCoin = tear

        --Special tear coins
        elseif pData.fireNotCoin ~= nil then
            MR.metalPiece.initAnyVariant(tear)
            pData.fireNotCoin = nil
        end
    end
end

function MR:ProjectileStart(projectile)
    local prData = projectile:GetData()
    if projectile.SpawnerEntity~=nil and projectile.SpawnerEntity.Type == MR.type.enemy.allomancer then
        MR.metalPiece.plate.init(projectile)
        projectile.SpawnerEntity:GetData().lastPlate = projectile
    end
end

function MR:BulletUpdate(bullet) --Tears and projectiles
    local bData = bullet:GetData()

    if bullet.SpawnerEntity ~= nil then
        local entity = bullet.SpawnerEntity
        local player = bullet.SpawnerEntity:ToPlayer()
        local eData = entity:GetData()


        --To metal piece
        if bData.isMetalPiece then

            --To Coins
            if player~=nil and bData.pieceVariant == MR.enum.pieceVariant.COIN and bullet.Type == EntityType.ENTITY_TEAR then

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

                    if MR.entity.entityCollision(bullet, collider) and bullet.FrameCount > 10 and bullet.Height < -8 and not MR.vect.isZero(bullet.Velocity)
                        --Ludovico interaction: dont take ludovico bullet coins
                        and not bullet:HasTearFlags(TearFlags.TEAR_LUDOVICO) then

                        MR.metalPiece.take(bullet, player)
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
                        bullet.CollisionDamage = bData.BaseDamage*MR.metalPiece.coin.COIN_DMG_MULT
                    else
                        bullet.CollisionDamage = bData.BaseDamage
                    end
                end

                --Spawn coin when get max sticked time
                if bullet:GetData().timerStick ~= nil and bullet:GetData().timerStick > MR.metalPiece.coin.STICKED_TIME then
                    bullet:Remove()
                end

                local anim = bullet:GetSprite():GetAnimation()

                if anim:sub(0, anim:len()-1)=="Appear" and bullet:GetSprite():IsFinished("Appear"..anim:sub(anim:len())) then
                    bullet:GetSprite():Play("Idle"..anim:sub(anim:len()))
                end
            elseif bData.pieceVariant == MR.enum.pieceVariant.KNIFE then --To knife tears
                MR.metalPiece.knife.flip(bullet)

                if not bullet.SpawnerEntity:GetData().controlsChanged then
                    bullet:Remove()
                end
            end

            --Variant
                --Ludovico interaction: extra ludovico tears
            if player ~= nil and bullet.Type == EntityType.ENTITY_TEAR then

                if bullet:HasTearFlags(TearFlags.TEAR_LUDOVICO) then
                    if bullet:GetSprite():GetFilename() ~= MR.metalPiece.ref.TEAR_COIN then
                        bullet:GetSprite():Load(MR.metalPiece.ref.TEAR_COIN, true)
                        bullet:GetSprite():Play("Idle"..MR.metalPiece.getSizeAnimation(bullet:ToTear()), true)
                    end

                    if not MR.vect.equal(bullet.SpriteScale, MR.vect.make(bullet:ToTear().Scale)) then
                        bullet:GetSprite().Scale = MR.vect.make(bullet:ToTear().Scale)
                        local anim = bullet:GetSprite():GetAnimation()
                        local size = MR.metalPiece.getSizeAnimation(bullet:ToTear())
                        if anim:sub(anim:len()) ~= size then
                            bullet:GetSprite():Play(anim:sub(0, anim:len()-1)..size)
                        end
                    end

                    --Ludovico interaction: Kill standart tear when can shot tear or kill metalPiece tear when change controls
                    if bullet:Exists() then


                        --To coin tear
                        if (not bData.isMetalPiece and eData.controlsChanged and player:GetNumCoins()>0) then
                            if eData.LudovicoTear ~= nil and not eData.LudovicoTear:GetData().isMetalPiece then
                                MR.metalPiece.coin.init(eData.LudovicoTear)
                            else
                                MR.metalPiece.coin.init(bullet)
                            end
                        end
                        --Kill coin tear, respawn ludovico tear
                        if bData.isMetalPiece and not eData.controlsChanged then
                            bullet:Kill()
                        end
                    end

                elseif bullet.Variant ~= MR.type.tear.metalPiece and bullet:GetSprite():GetFilename() ~= MR.metalPiece.ref.TEAR_COIN then
                    bullet:ChangeVariant(MR.type.tear.metalPiece)
                end
            end

            --Change sticky/piercing
            if bData.selected then
                MR.metalPiece.changeToPiercing(bullet)
            else
                MR.metalPiece.changeToStick(bullet)
            end

            --Change rotation to velocity direction
            if not MR.vect.isZero(bullet.Velocity) then
                bullet.SpriteRotation = (bullet.Velocity):GetAngleDegrees()
            end

            --Tractor beam interaction
            if bullet.Type == EntityType.ENTITY_TEAR then
                if bullet:HasTearFlags(TearFlags.TEAR_TRACTOR_BEAM) or bData.isTractorBeam then
                    if bData.isTractorBeam ~= true then
                        bData.isTractorBeam = true
                    end

                    if MR.array.containsEntity(bullet.SpawnerEntity:GetData().selectedEntities, bullet) and bullet.SpawnerEntity:GetData().pulling then
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
                and (bullet.Variant == MR.type.tear.metalPiece) then

                bullet:GetSprite():Load(MR.metalPiece.ref.PARTICLE_COIN, true)
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
            if (bullet.SpawnerEntity.Type == EntityType.ENTITY_PLAYER and MR.allomancy.physical.has(bullet.SpawnerEntity) and bullet:HasTearFlags(TearFlags.TEAR_SPLIT) and bullet.Variant ~= MR.type.tear.metalPiece) then
                bullet.Velocity = MR.vect.capVelocity(bullet.Velocity, 20)
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
                if not MR.entity.equal(tear, bullet) and MR.entity.equal(entity, tear.SpawnerEntity) and tear.FrameCount==bullet.FrameCount then
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
        if bData.pieceVariant == MR.enum.pieceVariant.KNIFE then
            variant = 2
            anchorageWallAnim = "Anchorage"
            anchorageAnim = "Anchorage"
            spawnAnim = "Idle"
        elseif bData.pieceVariant == MR.enum.pieceVariant.PLATE then --Plate tear
            variant = 3
            anchorageWallAnim = "AnchorageWall"
            anchorageAnim = "Anchorage"
            spawnAnim = "Appear"
        elseif bData.pieceVariant == MR.enum.pieceVariant.COIN then --Usual coin tear
            local sizeAnim = MR.metalPiece.getSizeAnimation(bullet)
            variant = 1
            anchorageWallAnim = "AnchorageWall"..sizeAnim
            anchorageAnim = "Anchorage"..sizeAnim
            spawnAnim = "Appear"..sizeAnim
        end

        --To anchorage
          --To not bounce tears (Rubber Cement interaction)
        if ((bullet.Type == EntityType.ENTITY_TEAR and not bullet:ToTear():HasTearFlags(TearFlags.TEAR_BOUNCE)) or (bullet.Type == EntityType.ENTITY_PROJECTILE))
            --Min velocity
            and bData.collision and MR.vect.biggerThan(bData.collisionVelocity,MR.allomancy.physical.velocity.MIN_TEAR_TO_HOOK) then

            bData.Coin = Isaac.Spawn(EntityType.ENTITY_PICKUP, MR.type.pickup.throwedCoin, variant, bData.anchoragePosition, Vector(0,0), nil)
            local coin = bData.Coin

            --Set anchorage characteristics
            coin.Friction = 100
            coin:GetData().isAnchorage = true

            --To wall anchorage
            if MR.pos.isWall(coin.Position) or (MR.room.touchLimit(bullet.Position)) then
                coin:GetData().inWall = true
                coin:GetSprite():Play(anchorageWallAnim,true)

                --Turn to wall direction
                    --To Knife
                if bData.pieceVariant == MR.enum.pieceVariant.KNIFE then
                    coin.SpriteRotation = (bData.collisionVelocity):GetAngleDegrees()
                    MR.metalPiece.knife.flip(coin, bData.collisionVelocity)

                    --To else
                else
                    if MR.room.wallDirection(coin.Position) == Direction.LEFT then
                        coin:GetSprite().FlipX = true
                    elseif MR.room.wallDirection(coin.Position) == Direction.UP then
                        coin.SpriteRotation = 270
                    elseif MR.room.wallDirection(coin.Position) == Direction.DOWN then
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
            bData.Coin = Isaac.Spawn(EntityType.ENTITY_PICKUP, MR.type.pickup.throwedCoin, variant, Game():GetRoom():FindFreeTilePosition(bullet.Position,25), bullet.Velocity, nil)
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
                MR.tracer.selectEntity(bData.from, coin)
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
                coin:GetData().pieceVariant = MR.enum.pieceVariant.KNIFE
            end

            --Set pickup coin characteristics to tear coin characteristics
            coin:SetColor(bullet:GetColor(),0,1,false,false)
            if bullet.Type == EntityType.ENTITY_TEAR and bData.pieceVariant == MR.enum.pieceVariant.COIN then
                if sizeAnim == 0 or sizeAnim == 1 then
                    coin.SpriteScale = MR.vect.make(bullet:ToTear().Scale*2)
                else
                    coin.SpriteScale = MR.vect.make(bullet:ToTear().Scale)
                end
            end

            --If is the last shot coin
            if bullet.SpawnerEntity ~= nil and MR.entity.equal(bullet.SpawnerEntity:GetData().lastCoin, bullet) then
                bullet.SpawnerEntity:GetData().lastCoin = coin
            end

            coin:GetData().gridTouched = false
            coin:GetData().BaseDamage = bData.BaseDamage
            coin:GetData().pieceVariant = bData.pieceVariant
            coin.SpawnerEntity = bullet.SpawnerEntity
            table.insert(MR.metalPiece.pickupsAlive, coin)
        end

        --Ludovico interaction: remove tear when collide
        if bullet.Type == EntityType.ENTITY_TEAR and bullet:Exists() and bullet:ToTear():HasTearFlags(TearFlags.TEAR_LUDOVICO) then
            bullet:Remove()
        end
    end

end

--ENEMY
function MR:EnemyAllomancerStart(enemy)
    local eData = enemy:GetData()
    local stage = Game():GetLevel():GetStage()
    local room = Game():GetRoom()

    eData.selectedEntities = {}
    enemy:GetData().AllomanticPowers = {}

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
    enemy:GetData().AllomanticPowers[enemy.Variant] = true

    --Close doors
    for i=0, 7, 1 do
        if room:GetDoor(i) ~= nil then
            room:GetDoor(i):Close(true)
        end
    end

end

function MR:EnemyAllomancerUpdate(enemy)
    local room = Game():GetRoom()
    local sprite = enemy:GetSprite()
    local eData = enemy:GetData()
    local target = enemy:GetPlayerTarget()
    local pf = enemy.Pathfinder

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
    local distancia = MR.vect.toDistance(enemy.Position, target.Position)
    if eData.moveTarget == nil then eData.moveTarget = target end
    eData.nearPickup = MR.metalPiece.findNearestPickup(enemy.Position, MR.enum.pieceVariant.PLATE, enemy, pf)
    eData.lastPosition = enemy.Position

    --Update cd
    if enemy.ProjectileCooldown>0 then enemy.ProjectileCooldown = enemy.ProjectileCooldown-1 end
    if eData.allomancyCD > 0 then eData.allomancyCD = eData.allomancyCD-1 end
    if eData.tryFind > 0 then eData.tryFind = eData.tryFind-1 end
    if eData.postShot >= 0 then eData.postShot = eData.postShot+1 end
    if eData.usingPowerTime > 0 then eData.usingPowerTime = eData.usingPowerTime-1 end


    --State animations
    if enemy.State == NpcState.STATE_MOVE then
        local dir = MR.vect.toDirection(enemy.Velocity)
        if not sprite:IsPlaying("Walk"..MR.str.enum.direction[dir]) then
            sprite:Play("Walk"..MR.str.enum.direction[dir], true)
        end

        sprite:PlayOverlay("Head"..MR.str.enum.direction[dir], true)
    elseif enemy.State == NpcState.STATE_IDLE then
        sprite:Play("WalkDown", true)
        sprite:PlayOverlay("HeadDown", true)
        enemy.Velocity = Vector(0,0)
    end

    --IA
    if enemy.FrameCount < 30 then
        eData.iaState = MR.enum.iaState.APPEAR
    elseif not pf:HasPathToPos(target.Position, false) then
        eData.iaState = MR.enum.iaState.IDLE
        enemy.State = NpcState.STATE_IDLE
    elseif MR.entity.isExisting(eData.nearPickup) and (eData.numPlates <= 0 or MR.vect.toDistance(eData.nearPickup.Position, enemy.Position) < 75) then --Take coin
        enemy.State = NpcState.STATE_MOVE
        eData.iaState = MR.enum.iaState.TAKE_COIN
        eData.moveTarget = eData.nearPickup
        if MR.vect.toDistance(eData.nearPickup.Position, enemy.Position) < 75 then
            enemy:AddVelocity(MR.vect.fromToEntity(enemy, eData.nearPickup, -1))
             --Take near anchorage
            if eData.nearPickup:GetData().isAnchorage and eData.allomancyCD <= 0 and MR.allomancy.physical.has(enemy) then
                if MR.tracer.throw(enemy, MR.vect.fromToEntity(eData.nearPickup, enemy, 1)) then
                    if MR.allomancy.hasPower(enemy, MR.enum.power.IRON) then
                        eData.usePower = MR.enum.power.IRON
                        eData.usingPowerTime = 120
                    elseif MR.allomancy.hasPower(enemy, MR.enum.power.STEEL) then
                        eData.usePower = MR.enum.power.STEEL
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

            eData.iaState = MR.enum.iaState.APPROACHING
            pf:FindGridPath(target.Position, 1.2, 2, true)

        elseif distancia < 180 then

            eData.iaState = MR.enum.iaState.RECEDE
            pf:EvadeTarget(target.Position)
            enemy:AddVelocity(MR.vect.fromToEntity(enemy, target, 1))

        end
    end

    --Use pull/push to move
    if eData.allomancyCD<=0 and enemy.State == NpcState.STATE_MOVE and eData.tryFind <= 0 and MR.allomancy.physical.has(enemy) then
        eData.tryFind = 15
        local evade
        --Opposite direction when is on recede state
        if eData.iaState == MR.enum.iaState.RECEDE then evade = -1 else evade=1 end

        --If find a metalic entity behind him use steel to find entity
        if MR.allomancy.hasPower(enemy, MR.enum.power.STEEL) and MR.tracer.throw(enemy, MR.vect.fromToEntity(enemy, eData.moveTarget, 1*evade)) then
            eData.usePower = MR.enum.power.STEEL
            eData.usingPowerTime = 30
            eData.allomancyCD = 20
            eData.tryFind = 90
        end

         --If find a metalic entity in front of him use iron to find entity
        if MR.allomancy.hasPower(enemy, MR.enum.power.IRON) and MR.tracer.throw(enemy, MR.vect.fromToEntity(enemy, eData.moveTarget, -1*evade)) then
            eData.usePower = MR.enum.power.IRON
            eData.usingPowerTime = 30
            eData.allomancyCD = 20
            eData.tryFind = 90
        end
    end

    --Shot
    if enemy.State == NpcState.STATE_MOVE and distancia < 300
    and enemy.ProjectileCooldown == 0
    and eData.numPlates > 0
    and eData.iaState ~= MR.enum.iaState.SHOT
    and room:CheckLine(enemy.Position, target.Position, 0, 0, false, false) then

        eData.iaState = MR.enum.iaState.SHOT
        eData.numPlates = eData.numPlates-1
        enemy.State = NpcState.STATE_ATTACK
        enemy:FireProjectiles(enemy.Position, MR.vect.fromToEntity(target, enemy, 14), 0, params)
        enemy.ProjectileCooldown = 80
        eData.postShot = 0

    end

    --Post shot
    if eData.postShot == 5 then

        sprite:PlayOverlay("Head"..MR.str.enum.direction[MR.vect.toDirection(MR.vect.fromToEntity(target, enemy, 1))], true)
        if eData.allomancyCD <= 0 and MR.allomancy.hasPower(enemy, MR.enum.power.STEEL) then

            local fromEntity
            if MR.entity.isExisting(eData.lastPlate) then
                fromEntity = eData.lastPlate
            else
                fromEntity = target
            end

            if MR.tracer.throw(enemy, MR.vect.fromToEntity(fromEntity, enemy, 1)) then
                eData.usePower = MR.enum.power.STEEL
                eData.usingPowerTime = math.random(5,25)
                eData.tryFind = 30
                eData.allomancyCD = 50
            end
        end
    end

    --Later post shot (2sec)
    if eData.postShot == 60 then
        if eData.allomancyCD <= 0 and MR.allomancy.hasPower(enemy, MR.enum.power.IRON) then

            local fromEntity
            if MR.entity.isExisting(eData.lastPlate) then
                fromEntity = eData.lastPlate
            elseif MR.entity.isExisting(eData.nearPickup) then
                fromEntity = eData.nearPickup
            else
                fromEntity = target
            end

            if MR.tracer.throw(enemy, MR.vect.fromToEntity(fromEntity, enemy, 1)) then
                eData.usePower = MR.enum.power.IRON
                eData.usingPowerTime = 30
                eData.tryFind = 30
            end
            eData.allomancyCD = 60
        end
    end

    --Use power
    if eData.usingPowerTime > 0 then

        if MR.allomancy.physical.has(enemy) then
            if eData.gridTouched then
                eData.usingPowerTime = 0
            else
                if eData.usePower == MR.enum.power.STEEL then
                    eData.pulling = false; eData.pushing = true
                elseif eData.usePower == MR.enum.power.IRON then
                    eData.pulling = true; eData.pushing = false
                end
                MR.allomancy.physical.use(enemy)
            end
        end

        if enemy:CollidesWithGrid() then
            eData.usingPowerTime = 0
        end
    else
        if eData.selectedEntities ~= nil and #eData.selectedEntities > 0 then
            MR.tracer.deselectEntities(enemy)
        end
    end

    --Take coin
    for index, pickup in  pairs(MR.metalPiece.pickupsAlive) do
        if pickup:Exists() then
            MR.metalPiece.touchPickup(enemy, pickup)
        else
            table.remove(MR.metalPiece.pickupsAlive, index)
        end
    end

    --Selected entities
    if eData.selectedEntities ~= nil then
        for index, selEntity in pairs(eData.selectedEntities) do

            if not selEntity:Exists() then
                MR.tracer.deselectEntityIndex(enemy, index)
            end

            if (not (MR.entity.is.metalPiecePickup(selEntity)
            and selEntity:GetData().isAnchorage)
            and (not MR.entity.is.metalPieceBullet(selEntity))
            and (not MR.entity.is.bottle(selEntity) and selEntity:GetData().isAnchorage)) then
                if not MR.pos.isNoneCollision(selEntity.Position) then
                    selEntity.Position = Game():GetRoom():FindFreeTilePosition(selEntity.Position,25)
                end
            end

        end
    end

    if enemy:HasMortalDamage() and eData.bottleSpawned == nil then
        eData.bottleSpawned = Isaac.Spawn(EntityType.ENTITY_PICKUP, MR.type.pickup.mineralBottle, 1, enemy:GetData().lastPosition, Vector(0,0), nil)
    end

end

function MR:NpcDeath(enemy)
    --Marks
    if MR.player.someIsType(MR.type.player.allomancer) then
        if enemy.Type == EntityType.ENTITY_MOMS_HEART then --MOM
            MR.data.putMark(MR.enum.markId.HEART)
        elseif enemy.Type == EntityType.ENTITY_ISAAC then
            if enemy.Variant == 0 then --ISAAC
                MR.data.putMark(MR.enum.markId.CROSS)
            elseif enemy.Variant == 1 then --???
                MR.data.putMark(MR.enum.markId.POLAROID)
            end
        elseif enemy.Type == EntityType.ENTITY_SATAN then --Satan
            MR.data.putMark(MR.enum.markId.INVERTED_CROSS)
        elseif enemy.Type == EntityType.ENTITY_THE_LAMB then --Lamb
            MR.data.putMark(MR.enum.markId.NEGATIVE)
        elseif enemy.Type == EntityType.ENTITY_MEGA_SATAN_2 then --Mega satan
            MR.data.putMark(MR.enum.markId.BRIMSTONE)
        elseif enemy.Type == EntityType.ENTITY_HUSH then --Hush
            MR.data.putMark(MR.enum.markId.HUSH)
        elseif enemy.Type == EntityType.ENTITY_DELIRIUM then --Delirium
            MR.data.putMark(MR.enum.markId.PAPER)
        elseif enemy.Type == EntityType.ENTITY_MOTHER then --Mega satan
            MR.data.putMark(MR.enum.markId.KNIFE)
        elseif enemy.Type == EntityType.ENTITY_BEAST then --The beast
            MR.data.putMark(MR.enum.markId.DADS_NOTE)
        end
    end
end

--PICKUP
function MR:PickupStart(pickup)
    if pickup.Variant == MR.type.pickup.floorMark then
        pickup:GetSprite():ReplaceSpritesheet(0, MR.enemy.mark.ref[pickup.SubType])
        pickup:GetSprite():LoadGraphics()
        pickup.DepthOffset = -200
        pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        pickup.GridCollisionClass = GridCollisionClass.COLLISION_NONE
    end
end

function MR:PickupUpdate(pickup)
    local data = pickup:GetData()
    local sprite = pickup:GetSprite()

    --Selected pickups
    if data.selected then
        --Damage if it goes too fast
        if MR.vect.biggerThan(pickup.Velocity,MR.allomancy.physical.velocity.MIN_TO_PICKUP_DAMAGE) then
            for _, collider in pairs(Isaac.GetRoomEntities()) do

                if not MR.entity.equal(data.from, collider) and MR.entity.entityCollision(collider, pickup) then
                    if (data.from.Type==EntityType.ENTITY_PLAYER and collider:IsEnemy()) or (data.from.Type~=EntityType.ENTITY_PLAYER) then
                        local dmg
                        if data.from.Type==EntityType.ENTITY_PLAYER then
                            dmg = data.from.Damage*2*MR.allomancy.physical.FAST_CRASH_DMG_MULT
                        else
                            dmg = 1
                        end


                        if collider:GetData().hitFrame == nil or (Game():GetFrameCount()-collider:GetData().hitFrame > MR.allomancy.physical.time.BETWEEN_HIT_DAMAGE) then
                            collider:TakeDamage(dmg,0,EntityRef(data.from),60)
                            collider:GetData().hitFrame = Game():GetFrameCount()
                        end
                    end
                end
            end
        end
    end

    --To coin pickup variant
    if pickup.Variant == MR.type.pickup.throwedCoin then

        if data.isAnchorage == true then
            --If anchorage's grid is destroyed it becomes a pickup
            if data.inWall == false and (data.gridEntityTouched ~= nil and ((data.gridEntityTouched:ToDoor()~=nil and data.gridEntityTouched.State ~= 2)
                    or (data.gridEntityTouched:ToDoor()==nil and data.gridEntityTouched.State ~= 1))
                or data.gridEntityTouched == nil) then

                data.isAnchorage = false
                pickup:GetSprite():Play("Idle"..pickup:GetSprite():GetAnimation():sub(pickup:GetSprite():GetAnimation():len()),true)
                pickup.Friction = MR.metalPiece.coin.FRICTION_PICKUP
            else
                if data.pieceVariant == MR.enum.pieceVariant.PLATE then pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES end
                pickup.Velocity = MR.vect.make(0)
                pickup.Friction = 0
            end
        else
            if data.pieceVariant == MR.enum.pieceVariant.PLATE then pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL end
            --If is not anchorage change rotation
            if not MR.vect.isZero(pickup.Velocity) then
                pickup.SpriteRotation = (pickup.Velocity):GetAngleDegrees()
            end

        end

        --Take coin
        for pID=0, Game():GetNumPlayers()-1, 1 do
            local player = Isaac.GetPlayer(pID)
            MR.metalPiece.touchPickup(player, pickup)
        end

        --Knife pickup
        if data.pieceVariant == MR.enum.pieceVariant.KNIFE then
            --Damage enemies that touch knife pickup
            if not data.isAnchorage then
                for _, collider in pairs(Isaac.GetRoomEntities()) do
                    if collider:IsEnemy() and MR.entity.entityCollision(collider,pickup) then
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
                    pickup.Friction = MR.metalPiece.coin.FRICTION_PICKUP
                end
                pickup.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
                pickup:AddVelocity((MR.vect.baseOne(MR.vect.director(player.Position, pickup.Position)))*-10)
            else
                if pickup.GridCollisionClass ~= EntityGridCollisionClass.GRIDCOLL_NOPITS then
                    pickup.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_NOPITS
                end
            end
        end
    end

    --To bottle pickup
    if pickup.Variant == MR.type.pickup.mineralBottle then

        --Spawn
        if pickup.FrameCount == 1 and pickup:GetSprite():IsPlaying("Appear") then
            MR.sound.play(MR.sound.SPAWN_BOTTLE,1,0,false,1)
        end

        --To anchorage
        if data.isAnchorage then
            pickup:GetSprite():Play("Stucked")

            if data.gridEntityTouched ~= nil then
                if data.gridEntityTouched.State ~= 1 then
                    data.isAnchorage = false
                    pickup:GetSprite():Play("Idle",true)
                    pickup.Friction = MR.metalPiece.coin.FRICTION_PICKUP
                    pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
                else
                    pickup.Friction = 0
                    pickup.Velocity = Vector(0,0)
                    if MR.bottle.ANCHORAGE_POS[data.gridEntityTouched:GetType()][data.gridEntityTouched:GetVariant()] ~= nil then
                        pickup.Position = data.gridEntityTouched.Position + MR.bottle.ANCHORAGE_POS[data.gridEntityTouched:GetType()][data.gridEntityTouched:GetVariant()]
                    else
                        pickup.Position = data.gridEntityTouched.Position + MR.bottle.ANCHORAGE_POS[data.gridEntityTouched:GetType()]
                    end
                    pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
                end
            end
        end

        for pID=0, Game():GetNumPlayers()-1, 1 do
            local player = Isaac.GetPlayer(pID)
            local pData = player:GetData()

            --Take bottle
            if pickup:GetSprite():IsPlaying("Idle") then
                if MR.entity.entityCollision(player,pickup) then
                    pickup:GetSprite():Play("Collect", true)
                    MR.sound.play(MR.sound.TAKE_BOTTLE,1,0,false,1.2)
                    pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
                    if pData.mineralBar ~= nil then
                        pData.mineralBar = pData.mineralBar+MR.allomancy.ALLOMANCY_BAR_MAX*MR.bottle.MINERAL_TAKING_BOTTLE
                        if pData.mineralBar > MR.allomancy.ALLOMANCY_BAR_MAX then
                            pData.mineralBar = MR.allomancy.ALLOMANCY_BAR_MAX
                        end
                    end
                    pickup.Velocity = Vector(0,0)
                end
            else
                if pickup:GetSprite():IsFinished("Collect") then
                    pickup:Remove()
                end
            end
        end
    end

    --Magneto interaction
    if  pickup.Variant == MR.type.pickup.mineralBottle or pickup.Variant == MR.type.pickup.throwedCoin then
        for pID=0, Game():GetNumPlayers()-1, 1 do
            local player = Isaac.GetPlayer(pID)

            if player:HasCollectible(53) then
                pickup:AddVelocity(MR.vect.fromToEntity(player, pickup, 0.08))

                if pickup.Variant == MR.type.pickup.mineralBottle then
                    pickup.GridCollisionClass = GridCollisionClass.COLLISION_WALL
                end
            end
        end
    end

    --To floor mark pickup
    if pickup.Variant == MR.type.pickup.floorMark then
        pickup.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

        if data.randomFrame == nil then data.randomFrame = math.random(60,120) end

        if sprite:GetFrame() > data.randomFrame then
            data.randomFrame = math.random(60,120)
            sprite:Play("Idle")
            sprite:SetFrame(0)
        end

        for pID=0, Game():GetNumPlayers()-1, 1 do
            local player = Isaac.GetPlayer(pID)

            if MR.entity.entityCollision(player, pickup) then
                local enemy = Isaac.Spawn(610, pickup.SubType, 1, pickup.Position, MR.vect.make(0), nil)
                pickup:Remove()
            end
        end
    end
end

--BOMB
function MR:BombStart(bomb)
    for pID=0, Game():GetNumPlayers()-1, 1 do
        local player = Isaac.GetPlayer(pID)
        local pData = player:GetData()

        if bomb.SpawnerEntity ~= nil and GetPtrHash(player) == GetPtrHash(bomb.SpawnerEntity) and player:HasWeaponType(WeaponType.WEAPON_BOMBS) then

            if MR.vect.biggerThan(bomb.Velocity, 4) then
                bomb:GetData().fetusBomb = true
                if MR.allomancy.physical.has(player) and pData.controlsChanged and player:GetNumCoins() > 0 then
                    bomb:GetData().coinAtached = true
                    MR.metalPiece.coin.wasted = MR.metalPiece.coin.wasted + 1
                    player:AddCoins(-1)
                end
            end
        end
    end
end

function MR:BombUpdate(bomb)
    if bomb:GetData().coinAtached ~= nil and bomb:GetData().coinAtached then
        if bomb.FrameCount == 1 then
            bomb:GetSprite():Load(MR.metalPiece.ref.BOMB_COIN_TEAR, true); bomb:GetSprite():Play("Pulse", true);
        end
        if bomb:GetSprite():IsPlaying("Explode") then
            local coin = Isaac.Spawn(EntityType.ENTITY_PICKUP, MR.type.pickup.throwedCoin, 1, bomb.Position, bomb.Velocity, nil)
            bomb:GetData().coinAtached = false
            coin:GetData().isAnchorage = false
            coin:GetData().inWall = false
            coin:GetData().pieceVariant = MR.enum.pieceVariant.COIN
            coin:GetSprite():Play("Appear3", true)
            coin:AddVelocity(bomb.Velocity)
            coin.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
            if bomb:GetData().selected and  bomb:GetData().from ~= nil then
                MR.tracer.selectEntity(bomb:GetData().from, coin)
            end
            coin:GetData().gridTouched = false
        end
    end
end

--ROCKET
function MR:RocketUpdate(rocket)
    for pID=0, Game():GetNumPlayers()-1, 1 do
        local player = Isaac.GetPlayer(pID)
        if GetPtrHash(rocket.SpawnerEntity) == GetPtrHash(player) then
            if player:HasWeaponType(WeaponType.WEAPON_ROCKETS) then
                if not rocket:Exists() then
                    if player:GetData().controlsChanged then
                        MR.metalPiece.coin.randomShooting(player, 360, rocket, 5, 3, 5)
                    end
                end
            end
        end
    end
end

--LASER
function MR:LaserStart(laser)
    if laser.SpawnerEntity.Type == EntityType.ENTITY_PLAYER then
        local player = laser.SpawnerEntity:ToPlayer()
        local pData = player:GetData()
        laser:GetData().shotFrame = Isaac.GetFrameCount()

        --Interactions
        if MR.allomancy.physical.has(player) and pData.controlsChanged then

            if player:GetNumCoins() > 0 then
                if player:HasWeaponType(WeaponType.WEAPON_TECH_X) then
                    laser:GetData().Coin = MR.metalPiece.coin.fire(player, laser.Velocity)
                    laser:GetData().Coin:GetData().onLaser = laser
                elseif player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) and not laser:IsCircleLaser() then
                    --MegaBrimstone interaction
                    if laser.Variant == 11 then
                        MR.metalPiece.coin.randomShooting(player, 17, player, 12, 10, 18)
                    else --Usual brimstone interaction
                        MR.metalPiece.coin.randomShooting(player, 15, player, 8, 8, 16)
                    end
                elseif player:HasWeaponType(WeaponType.WEAPON_LASER) and not laser:IsCircleLaser() then
                    if player:HasCollectible(229) then --Monstruo's lung interaction
                        if pData.laserMonstruosLungFrame == nil then pData.laserMonstruosLungFrame=0 end
                        if Isaac.GetFrameCount() - pData.laserMonstruosLungFrame > 30 then
                            MR.metalPiece.coin.randomShooting(player, 20, player, 16, 10, 18)
                            pData.laserMonstruosLungFrame = Isaac.GetFrameCount()
                        end
                    else --Usual laser interaction
                        laser:GetData().Coin = MR.metalPiece.coin.fire(player)
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

function MR:LaserUpdate(laser)
    if laser.SpawnerEntity ~= nil and laser.SpawnerEntity.Type == EntityType.ENTITY_PLAYER then
        local player = laser.SpawnerEntity:ToPlayer()
        local laserData = laser:GetData()

        --Laser on entity
        if laser.SpawnerEntity.Type == EntityType.ENTITY_PLAYER and laser.Parent ~= nil and laser.Parent.Type ~= EntityType.ENTITY_PLAYER then
            if laser.Parent.Type == EntityType.ENTITY_KNIFE and MR.allomancy.physical.has(player) then
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
        if not laser.Visible and laserData.Coin ~= nil and  laserData.Coin:GetData().pieceVariant == MR.enum.pieceVariant.KNIFE then
            laser.Visible = true
        end

        --When is on tear
        if laser.SpawnerEntity.Type == EntityType.ENTITY_PLAYER and laserData.Coin ~= nil and laserData.Coin:Exists() then
            local liveTime = Isaac.GetFrameCount() - laserData.shotFrame
            MR.metalPiece.laserPosition(laser, laserData.Coin)

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
        if MR.metalPiece.hasLudovicoLaser(player) then
            if player:GetData().controlsChanged then
                if not MR.entity.isExisting(laserData.Coin) and player:GetNumCoins()>0 then
                    laserData.Coin = Isaac.Spawn(EntityType.ENTITY_TEAR, TearVariant.BLUE, 1, laser.Position, laser.Velocity, player)
                    local tear = laserData.Coin:ToTear()
                    tear:AddTearFlags(TearFlags.TEAR_LUDOVICO)
                    --tear:ChangeVariant(TearVariant.BLUE)
                    tear.Scale = tear.Scale*2
                    if tear:GetSprite():GetFilename() ~= MR.metalPiece.ref.TEAR_COIN then
                        tear:GetSprite():Load(MR.metalPiece.ref.TEAR_COIN, true)
                        tear:GetSprite():Play("Idle"..MR.metalPiece.getSizeAnimation(tear), true)
                        tear.SpriteScale = MR.vect.make(tear.Scale)
                    end
                    tear.GridCollisionClass = GridCollisionClass.COLLISION_NONE
                    player:GetData().LudovicoTear = tear

                elseif (MR.entity.isExisting(laserData.Coin)) then
                    laserData.Coin:AddVelocity(laser.Velocity/2)
                end
            elseif MR.entity.isExisting(laserData.Coin) then
                laserData.Coin:Remove()
            end
        end
    end
end

--FAMILIAR
function MR:FamiliarStart(familiar)
    if familiar.Variant == FamiliarVariant.ISAACS_BODY then
        familiar.Player:GetData().cuttedBody = familiar
    end
end

function MR:FamiliarBodyUpdate(familiar)
    if MR.allomancy.physical.has(familiar.Player) then
        local aroundPickups = Isaac.FindInRadius(familiar.Position, 120, EntityPartition.PICKUP)
        if aroundPickups ~= nil then
            for _, pickup in pairs(aroundPickups) do
                if pickup.Variant == MR.type.pickup.throwedCoin and pickup:Exists() and (familiar:GetData().targetPickup == nil or not familiar:GetData().targetPickup:Exists()) then
                    if not pickup:GetData().isAnchorage then
                        familiar:GetData().targetPickup = pickup
                    end
                end
            end
        end
        if familiar:GetData().targetPickup ~= nil and familiar:GetData().targetPickup:Exists() then
            familiar:FollowPosition(familiar:GetData().targetPickup.Position)
            familiar:AddVelocity((MR.vect.director(familiar.Position,familiar:GetData().targetPickup.Position))*5)
        else
            familiar:FollowParent()
        end
    end
end

--KNIFE
function MR:KnifeUpdate(knife)
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
            if extraKnife.Type == EntityType.ENTITY_KNIFE and MR.entity.equal(player, extraKnife.SpawnerEntity) then
                totalKnives = totalKnives+1
            end
        end
        if pData.numKnives < totalKnives then
            pData.numKnives = totalKnives
        end
    end

    --Set knife throwable
    if knife.Visible and not MR.entity.isNear(knife, player, 40) then
        knifeData.isThrowable = true
    else
        knifeData.isThrowable = false
    end

    --Set main knife
    if not MR.entity.isExisting(pData.mainKnife) then
        pData.mainKnife = knife
    end
    local mainKnife = pData.mainKnife

    --Spawn knife tear
    if knifeData.selected then
        local selPlayer = knifeData.from:ToPlayer()

        --If is selected spawn knife tear
        if knifeData.isThrowable then
            if knife.Visible and ((not MR.entity.isExisting(knife.knifeTear))
                or (not pData.shotMain and MR.entity.equal(knife, mainKnife) and MR.metalPiece.knife.getNum(player)>pData.shotKnives)) then

                --set if shot main knife
                if MR.entity.equal(knife, mainKnife) then pData.shotMain = true end
                --set shot notCoin tear
                selPlayer:GetData().fireNotCoin = "knife"
                --shot tear
                knifeData.knifeTear = selPlayer:FireTear(knife.Position, MR.vect.fromToEntity(knife, player, 10), true, false, true, player, 1)
                local tear = knifeData.knifeTear
                local tearData = tear:GetData()
                tear.Height = -12
                --Rotation
                tear.SpriteRotation = (knifeData.knifeTear.Velocity):GetAngleDegrees()
                MR.metalPiece.knife.flip(tear)
                --Visuals
                tear:GetSprite():Load(MR.metalPiece.ref.TEAR_KNIFE, true)
                tear:GetSprite():Play("Spawn", true)
                --Data
                tearData.fromKnife = mainKnife
                tearData.isMetalPiece = true
                tearData.pieceVariant = MR.enum.pieceVariant.KNIFE
                --Tear flags
                tear:AddTearFlags(TearFlags.TEAR_PIERCING)
                --Select tear deselect knife
                MR.tracer.selectEntity(selPlayer, tear)
                MR.tracer.deselectEntity(knife)
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
            MR.tracer.deselectEntity(knife)
        end
    end

    --To extra knives
    if not MR.entity.equal(knife, mainKnife) then
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
        if knife.Visible and pData.shotKnives >= MR.metalPiece.knife.getNum(player) then
            knife.Visible = false
            pData.invisibleKnives = pData.invisibleKnives+1
        elseif not knife.Visible and pData.shotKnives < MR.metalPiece.knife.getNum(player) then
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
    if pData.controlsChanged and not knife.Visible and not MR.entity.entityCollision(knife, player) and knife:HasTearFlags(TearFlags.TEAR_LUDOVICO) then
        knife.Position = player.Position + player:GetShootingInput()*30
    end
end

--COLLISIONS
function MR:PlayerCollision(player, collider, low)
    if  collider:IsEnemy() and MR.vect.biggerThan(player.Velocity,MR.allomancy.physical.velocity.MIN_TO_PLAYER_HIT) and MR.allomancy.physical.has(player) then
        local dmg = player.Damage*2*MR.allomancy.physical.FAST_CRASH_DMG_MULT

        if collider:GetData().hitFrame == nil or (Game():GetFrameCount()-collider:GetData().hitFrame > MR.allomancy.physical.time.BETWEEN_GRID_SMASH) then
            collider:TakeDamage(dmg,0,EntityRef(player),60)
            collider:GetData().hitFrame = Game():GetFrameCount()
        end

        if collider:HasMortalDamage() then
            collider.CollisionDamage = 0
        end
    end
end

function MR:EnemyCollision(enemy, hitEntity)
    --SI VA MUY RÁPIDO HACE DAÑO A OTROS
    local fromTear = enemy:GetData().stickTear
    local fromEntity = nil

    if fromTear ~= nil then
        fromEntity = enemy:GetData().stickTear:GetData().from
    end

    if fromEntity ~= nil
        and enemy:IsEnemy()
        and fromTear ~= nil
        and MR.vect.biggerThan(enemy.Velocity,MR.allomancy.physical.velocity.MIN_DOUBLE_HIT)
    then
        if hitEntity:IsEnemy() and hitEntity.Index ~= enemy.Index then

            if (enemy:GetData().hitFrame == nil) or (Game():GetFrameCount()-enemy:GetData().hitFrame > MR.allomancy.physical.time.BETWEEN_DOUBLE_HIT) then

                hitEntity:AddVelocity((MR.vect.rotateNinety(enemy.Velocity)))
                hitEntity:TakeDamage(fromTear:GetData().BaseDamage*MR.allomancy.physical.FAST_CRASH_DMG_MULT,0,EntityRef(fromEntity),60)
                enemy:TakeDamage(fromTear:GetData().BaseDamage*MR.allomancy.physical.FAST_CRASH_DMG_MULT,0,EntityRef(fromEntity),120)
                enemy:GetData().hitFrame = Game():GetFrameCount()
                hitEntity:GetData().hitFrame = Game():GetFrameCount()

            end
            fromTear.StickTarget = nil
        end
    end
end

function MR:TearCollision(tear, collider)
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
            collider:GetSprite():Load(MR.metalPiece.ref.BOMB_COIN_TEAR, true); collider:GetSprite():Play("Pulse", true);
            MR.tracer.selectEntity(tearData.from, collider)
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

MR:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, MR.TearFire)
MR:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, MR.PlayerStart)
MR:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, MR.TearStart)
MR:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, MR.BombStart)
MR:AddCallback(ModCallbacks.MC_POST_LASER_INIT, MR.LaserStart)
MR:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, MR.FamiliarStart)
MR:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, MR.StartGame)
MR:AddCallback(ModCallbacks.MC_POST_NPC_INIT, MR.EnemyAllomancerStart, MR.type.enemy.allomancer)
MR:AddCallback(ModCallbacks.MC_POST_PROJECTILE_INIT, MR.ProjectileStart)
MR:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, MR.PickupStart)

MR:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE,MR.PlayerUpdate)
MR:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, MR.BulletUpdate)
MR:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, MR.PickupUpdate)
MR:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, MR.BombUpdate)
MR:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, MR.LaserUpdate)
MR:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, MR.RocketUpdate, EffectVariant.ROCKET)
MR:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, MR.KnifeUpdate)
MR:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, MR.FamiliarBodyUpdate, FamiliarVariant.ISAACS_BODY)
MR:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, MR.CacheUpdate)
MR:AddCallback(ModCallbacks.MC_NPC_UPDATE, MR.EnemyAllomancerUpdate, MR.type.enemy.allomancer)
MR:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, MR.BulletUpdate)

MR:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, MR.GameExit)
MR:AddCallback(ModCallbacks.MC_POST_GAME_END, MR.GameEnd)
MR:AddCallback(ModCallbacks.MC_POST_RENDER, MR.GameRender)
MR:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, MR.LevelEnter)
MR:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, MR.RoomEnter)
MR:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, MR.RoomClear)

MR:AddCallback(ModCallbacks.MC_INPUT_ACTION, MR.ControlsBlockInputs, InputHook.IS_ACTION_TRIGGERED)
MR:AddCallback(ModCallbacks.MC_INPUT_ACTION, MR.ControlsUpdate)

MR:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, MR.PlayerCollision)
MR:AddCallback(ModCallbacks.MC_PRE_NPC_COLLISION, MR.EnemyCollision)
MR:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION, MR.TearCollision)

MR:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, MR.BulletRemove, EntityType.ENTITY_TEAR)
MR:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, MR.BulletRemove, EntityType.ENTITY_PROJECTILE)
MR:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, MR.NpcDeath)

MR:AddCallback( ModCallbacks.MC_GET_SHADER_PARAMS, MR.Shaderhook)