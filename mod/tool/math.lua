local mth = {}

function mth.round(n) --(Float)->[Int] --Round float to int
    if n-math.floor(n) >= 0.5 then return math.ceil(n) else return math.floor(n) end
end

function mth.reduceIfHigher(n, limit, reduction) --(Num, Num, Num)->[Num] Return n-reduction if n is higher than limit.
    if n>limit then return n-reduction else return n end
end

function mth.upperBound(n, max) --(Num, Num)->[Num] Return limit if base is higher, base otherwise.
    if n > max then
        return max
    end
    return n
end

function mth.lowerBound(n, min) --(Num, Num)->[Num] Return limit if base is lower, base otherwise.
    if n < min then
        return min
    end
    return n
end

function mth.angleTo360(angle) --(Angle)->[Angle] Return angle from 0 to 360.
    if angle < 0 then
        angle = 360+angle
    end
    while angle > 360 do
        angle = angle-360
    end
    return angle
end

function mth.randomInterval(a, b) --(Float, Float)->[Float] Returns random number on (a,b), a/b can be float.
    local decimals = 8
    local A = mth.round(a*10^decimals)
    local B = mth.round(b*10^decimals)

    if A<B then
        return math.random(A,B)/10^decimals
    else
        return math.random(B,A)/10^decimals
    end
end

function mth.boolToSymbol(bool) --(Boolean)->[1/-1] Transforms boolean to positive/negative number.
    if bool then return 1 else return -1 end
end

return mth