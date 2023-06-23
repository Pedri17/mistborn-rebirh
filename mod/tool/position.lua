local pos = {}
    
pos.isWall = function(pos) --(Vector)->[Bool] Return if wall is in this position.
    return Game():GetRoom():GetGridCollisionAtPos(pos) == GridCollisionClass.COLLISION_WALL
end

pos.isDoor = function(pos) --(Vector)->[Bool] Return if door is in this position.
    return Game():GetRoom():GetGridEntityFromPos(pos):ToDoor() ~= nil
end

pos.isObject = function(pos) --(Vector)->[Bool] Return if object is in this position.
    return Game():GetRoom():GetGridCollisionAtPos(pos) == GridCollisionClass.COLLISION_OBJECT
end

pos.isNoneCollision = function(pos) --(Vector)->[Bool] Return if none collision is in this position.
    return Game():GetRoom():GetGridCollisionAtPos(pos) == GridCollisionClass.COLLISION_NONE
end

pos.isGrid = function (pos) --(Vector)->[Bool] Return if grid is in this position.
    return Game():GetRoom():GetGridEntityFromPos(pos) ~= nil
end

return pos
