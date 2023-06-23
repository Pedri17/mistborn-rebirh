local room = {}

local pos = require("mod/tool/position")
local array = require("mod/tool/array")

room.limitPos = function() -- ->[Vector] Return room limit position.
    return Game():GetRoom():GetBottomRightPos()-Game():GetRoom():GetTopLeftPos()-Vector(20,20)
end

room.clampedPos = function(pos) --(Position)->[Vector] Return clamped position.
    return Game():GetRoom():GetClampedPosition(pos,10)-Game():GetRoom():GetTopLeftPos()-Vector(10,10)
end

room.posPerOne = function (pos) --(Position)->[Vector] Return base one room positon (0-1,0-1).
    return (room.clampedPos(pos))*Vector(1/room.limitPos().X, 1/room.limitPos().Y)
end

room.wallDirection = function(pos) --(Vector)->[Direction] Return wall direction from position taking room shape on consideration.

    --L
    if Game():GetRoom():GetRoomShape() == RoomShape.ROOMSHAPE_LTR then

        if math.abs(0.5-room.posPerOne(pos).X) >= math.abs(0.5-room.posPerOne(pos).Y) and room.posPerOne(pos).X < 0.5 then
            return Direction.LEFT
        elseif math.abs(0.5-room.posPerOne(pos).X) < math.abs(0.5-room.posPerOne(pos).Y) and room.posPerOne(pos).Y >= 0.5 then
            return Direction.DOWN
        elseif room.posPerOne(pos).Y >= 0.5 and room.posPerOne(pos).X >= 0.5 then
            if math.abs(0.75-room.posPerOne(pos).X) >= math.abs(0.75-room.posPerOne(pos).Y) and room.posPerOne(pos).X >= 0.75 then
                return Direction.RIGHT
            elseif math.abs(0.75-room.posPerOne(pos).X) < math.abs(0.75-room.posPerOne(pos).Y) and room.posPerOne(pos).Y < 0.75 then
                return Direction.UP
            end
        elseif room.posPerOne(pos).Y < 0.5 and room.posPerOne(pos).X < 0.5 then
            if math.abs(0.25-room.posPerOne(pos).X) >= math.abs(0.25-room.posPerOne(pos).Y) and room.posPerOne(pos).X >= 0.25 then
                return Direction.RIGHT
            elseif math.abs(0.25-room.posPerOne(pos).X) < math.abs(0.25-room.posPerOne(pos).Y) and room.posPerOne(pos).Y < 0.25 then
                return Direction.UP
            end
        end

    -- _|
    elseif Game():GetRoom():GetRoomShape() == RoomShape.ROOMSHAPE_LTL then

        if math.abs(0.5-room.posPerOne(pos).X) >= math.abs(0.5-room.posPerOne(pos).Y) and room.posPerOne(pos).X >= 0.5 then
            return Direction.RIGHT
        elseif math.abs(0.5-room.posPerOne(pos).X) < math.abs(0.5-room.posPerOne(pos).Y) and room.posPerOne(pos).Y >= 0.5 then
            return Direction.DOWN
        elseif room.posPerOne(pos).Y >= 0.5 and room.posPerOne(pos).X < 0.5 then
            if math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).X,0.5,0.5)) >= math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).Y,0.5,0.5)) and room.posPerOne(pos).X < 0.25 then
                return Direction.LEFT
            elseif math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).X,0.5,0.5)) < math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).Y,0.5,0.5)) and room.posPerOne(pos).Y < 0.75 then
                return Direction.UP
            end
        elseif room.posPerOne(pos).Y < 0.5 and room.posPerOne(pos).X >= 0.5 then
            if math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).X,0.5,0.5)) >= math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).Y,0.5,0.5)) and room.posPerOne(pos).X < 0.75 then
                return Direction.LEFT
            elseif math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).X,0.5,0.5)) < math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).Y,0.5,0.5)) and room.posPerOne(pos).Y < 0.25 then
                return Direction.UP
            end
        end

    -- -|
    elseif Game():GetRoom():GetRoomShape() == RoomShape.ROOMSHAPE_LBL then

        if math.abs(0.5-room.posPerOne(pos).X) >= math.abs(0.5-room.posPerOne(pos).Y) and room.posPerOne(pos).X >= 0.5 then
            return Direction.RIGHT
        elseif math.abs(0.5-room.posPerOne(pos).X) < math.abs(0.5-room.posPerOne(pos).Y) and room.posPerOne(pos).Y < 0.5 then
            return Direction.UP
        elseif room.posPerOne(pos).Y >= 0.5 and room.posPerOne(pos).X >= 0.5 then
            if math.abs(0.75-room.posPerOne(pos).X) >= math.abs(0.75-room.posPerOne(pos).Y) and room.posPerOne(pos).X < 0.75 then
                return Direction.LEFT
            elseif math.abs(0.75-room.posPerOne(pos).X) < math.abs(0.75-room.posPerOne(pos).Y) and room.posPerOne(pos).Y >= 0.75 then
                return Direction.DOWN
            end
        elseif room.posPerOne(pos).Y < 0.5 and room.posPerOne(pos).X < 0.5 then
            if math.abs(0.25-room.posPerOne(pos).X) >= math.abs(0.25-room.posPerOne(pos).Y) and room.posPerOne(pos).X < 0.25 then
                return Direction.LEFT
            elseif math.abs(0.25-room.posPerOne(pos).X) < math.abs(0.25-room.posPerOne(pos).Y) and room.posPerOne(pos).Y >= 0.25 then
                return Direction.DOWN
            end
        end

    -- |-
    elseif Game():GetRoom():GetRoomShape() == RoomShape.ROOMSHAPE_LBR then

        if math.abs(0.5-room.posPerOne(pos).X) >= math.abs(0.5-room.posPerOne(pos).Y) and room.posPerOne(pos).X < 0.5 then
            return Direction.LEFT
        elseif math.abs(0.5-room.posPerOne(pos).X) < math.abs(0.5-room.posPerOne(pos).Y) and room.posPerOne(pos).Y < 0.5 then
            return Direction.UP
        elseif room.posPerOne(pos).Y >= 0.5 and room.posPerOne(pos).X < 0.5 then
            if math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).X,0.5,0.5)) >= math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).Y,0.5,0.5)) and room.posPerOne(pos).X >= 0.25 then
                return Direction.RIGHT
            elseif math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).X,0.5,0.5)) < math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).Y,0.5,0.5)) and room.posPerOne(pos).Y >= 0.75 then
                return Direction.DOWN
            end
        elseif room.posPerOne(pos).Y < 0.5 and room.posPerOne(pos).X >= 0.5 then
            if math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).X,0.5,0.5)) >= math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).Y,0.5,0.5)) and room.posPerOne(pos).X >= 0.75 then
                return Direction.RIGHT
            elseif math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).X,0.5,0.5)) < math.abs(0.25-mth.reduceIfHigher(room.posPerOne(pos).Y,0.5,0.5)) and room.posPerOne(pos).Y >= 0.25 then
                return Direction.DOWN
            end
        end

    else
        if math.abs(0.5-room.posPerOne(pos).X) >= math.abs(0.5-room.posPerOne(pos).Y) then
            if room.posPerOne(pos).X >= 0.5 then
                return Direction.RIGHT
            else
                return Direction.LEFT
            end
        else
            if room.posPerOne(pos).Y >= 0.5 then
                return Direction.DOWN
            else
                return Direction.UP
            end
        end
    end
end

room.getGridRockEntities = function() -- ->[Table GridEntity] Return rock grid entities on this room.
    local thisRoom = Game():GetRoom()
    local i = thisRoom:GetBottomRightPos()-Vector(1,1)
    local GridEntities = {}
    local GridPos = {}

    while (i.Y > (thisRoom:GetTopLeftPos()+Vector(1,1)).Y) do

        while i.X > (thisRoom:GetTopLeftPos()+Vector(1,1)).X do
            i.X = i.X-5

            if pos.isGrid(i) then
                local grid = thisRoom:GetGridEntityFromPos(i)
                if grid ~= nil and room.isGridSpawnerRock(grid) and not array.containsVector(GridPos, grid.Position) then
                    table.insert(GridPos, grid.Position)
                    table.insert(GridEntities, grid)
                end
            end
        end
        i.X = (thisRoom:GetBottomRightPos()-Vector(1,1)).X
        i.Y = i.Y-5
    end
    return GridEntities
end

room.touchLimit = function(pos) -- (Position)->[Bool] Return if position is touching a room limit.
    local roomShape = Game():GetRoom():GetRoomShape()
    local rp = room.posPerOne(pos)
    if roomShape==RoomShape.ROOMSHAPE_LTL then
        if rp.X < 0.5 then
            return room.posPerOne(pos).X == 0 or room.posPerOne(pos).Y == 0.5 or room.posPerOne(pos).Y == 1
        else
            if rp.Y < 0.5 then
                return room.posPerOne(pos).X == 0.5 or room.posPerOne(pos).X == 1 or room.posPerOne(pos).Y == 0
            else
                return room.posPerOne(pos).X == 1 or room.posPerOne(pos).Y == 1
            end
        end
    elseif roomShape==RoomShape.ROOMSHAPE_LTL then
        if rp.X > 0.5 then
            return room.posPerOne(pos).X == 1 or room.posPerOne(pos).Y == 0.5 or room.posPerOne(pos).Y == 1
        else
            if rp.Y < 0.5 then
                return room.posPerOne(pos).X == 0.5 or room.posPerOne(pos).X == 1 or room.posPerOne(pos).Y == 0
            else
                return room.posPerOne(pos).X == 0 or room.posPerOne(pos).Y == 1
            end
        end
    elseif roomShape==RoomShape.ROOMSHAPE_LTL then
        if rp.X < 0.5 then
            return room.posPerOne(pos).X == 0 or room.posPerOne(pos).Y == 0.5 or room.posPerOne(pos).Y == 0
        else
            if rp.Y > 0.5 then
                return room.posPerOne(pos).X == 0.5 or room.posPerOne(pos).X == 1 or room.posPerOne(pos).Y == 1
            else
                return room.posPerOne(pos).X == 1 or room.posPerOne(pos).Y == 0
            end
        end
    elseif roomShape==RoomShape.ROOMSHAPE_LTL then
        if rp.X > 0.5 then
            return room.posPerOne(pos).X == 1 or room.posPerOne(pos).Y == 0.5 or room.posPerOne(pos).Y == 0
        else
            if rp.Y > 0.5 then
                return room.posPerOne(pos).X == 0.5 or room.posPerOne(pos).X == 0 or room.posPerOne(pos).Y == 1
            else
                return room.posPerOne(pos).X == 0 or room.posPerOne(pos).Y == 0
            end
        end
    else
        return room.posPerOne(pos).X == 0 or room.posPerOne(pos).X == 1 or room.posPerOne(pos).Y == 0 or room.posPerOne(pos).Y == 1
    end
end

room.isGridSpawnerRock = function(gridEntity) --(GridEntity)->[Bool] Return if gridEntity is a destroyable rock.
    return gridEntity ~= nil and
            (gridEntity:GetType() == GridEntityType.GRID_ROCK or
            gridEntity:GetType() == GridEntityType.GRID_ROCK_BOMB or
            gridEntity:GetType() == GridEntityType.GRID_ROCK_ALT or
            gridEntity:GetType() == GridEntityType.GRID_ROCK_ALT2)
end

return room
