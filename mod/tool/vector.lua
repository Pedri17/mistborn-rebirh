local vector = {}

vector.make = function(n) --(Num)->[Vector] Returns n vector.
    return Vector(n,n)
end

vector.equal = function(v1, v2) --(Vector)->[Bool] Return if both vectors are equal.
    return v1.X==v2.X and v1.Y==v2.Y
end

vector.baseOne = function(v) --(Vector)->[Vector] Returns a vector that has one as highest value and the other as a multiple of this.
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
end

vector.director = function (fromPos,toPos) --(Vector, Vector)->(Vector) Returns a base one director vector.
    return vector.baseOne(Vector(toPos.X-fromPos.X,toPos.Y-fromPos.Y))
end

vector.isZero = function(v) --(Vector)->[Bool] Returns if vector is zero.
    return v.X == 0.0 and v.Y == 0.0
end

vector.fromDirection = function(direction) --(Direction)->[Vector] Returns a base one vector from a Direction.
    if direction == Direction.RIGHT then return Vector(1,0)
    elseif direction == Direction.LEFT then return Vector(-1,0)
    elseif direction == Direction.UP then return Vector(0,-1)
    elseif direction == Direction.DOWN then return Vector(0,1)
    else return Vector(0,0) end
end

vector.someMin = function(vector, min) --(Vector, Num)->[Bool] Returns if some vector's value is higher than a min value.
    return vector.X > min or vector.Y > min
end

vector.absolute = function(vector) --(Vector)->[Vector] Returns vector with positive values.
    return Vector(math.abs(vector.X),math.abs(vector.Y))
end

vector.round = function(vector) --(Vector)->[Vector] Returns rounded value's vector
    return Vector(mth.round(vector.X),mth.round(vector.Y))
end

vector.facingSameDirection = function(directionVector, velocityVector, angle) --(Vector, Vector, Angle)->[Bool] Returns if velocityVector is on directionVector's angle interval.
    local mainAngle = mth.angleTo360(directionVector:GetAngleDegrees())
    local vel = mth.angleTo360((velocityVector):GetAngleDegrees())
    local a = mainAngle-(angle/2)
    local b = mainAngle+(angle/2)
    return vel >= a and vel <= b
end

vector.distanceMult = function(v1, v2, limit) --(Vector, Vector, Num)->[Num] Returns multiplicator (1-0) from distance limit (distance-limit).
    local n = 1-(v1:Distance(v2)/limit)
    if n < 0 then return 0 else return n end
end

vector.toDistance = function(v1, v2)
    return (math.abs(v2.X-v1.X)+math.abs(v2.Y-v1.Y))
end

vector.smallerThan = function(vector,num) --(Vector, Num)->[Bool] Returns if both values are smaller than num.
    returfn (math.abs(vector.X) < num and math.abs(vector.Y) < num)
end

vector.biggerThan = function(vel,num) --(Vector, Num)->[Bool] Returns if any value is bigger than num.
    return (math.abs(vel.X) > num or math.abs(vel.Y) > num)
end

vector.fromToEntity = function(fromEntity, toEntity, n) --(Entity, Entity, Num)->[Vector] Return n multiplied director vector from entities positions.
    return (vector.director(toEntity.Position, fromEntity.Position))*n
end

vector.rotateNinety = function(vector) --(Vector)->[Vector] Rotate vector 90 degrees.
    return Vector(vector.Y,-vector.X)
end

vector.toInt = function(vector) --(Vector)->[Num] Returns number from vector.
    return math.sqrt((vector.X)^2+(vector.Y)^2)
end

vector.capVelocity = function(velocity, cap) --(Vector, Num)->[Vector] Returns vector with cap as higher value.
    if vector.biggerThan(velocity,cap) then
        return vector.baseOne(velocity)*cap
    else
        return velocity
    end
end

vector.toDirection = function(vector) --(Vector)->[Direction] Returns a direction from a vector
    local mayor = vector.X
    if math.abs(vector.Y)>math.abs(mayor) then
        mayor = vector.Y
    end

    if mayor == vector.X then
        if mayor >= 0 then return Direction.RIGHT else return Direction.LEFT end
    else
        if mayor >= 0 then return Direction.DOWN else return Direction.UP end
    end

end

vector.getHigher = function(vector) 
    if math.abs(vector.X) > math.abs(vector.Y) then return vector.X else return vector.Y end
end

return vector