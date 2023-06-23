local array = {}

array.getSize = function(table) --(Table)->[Num] Returns number of items on table.
    local count = 0
    if table ~= nil then
        for _, _ in pairs(table) do
            count = count + 1
        end
    end
    return count
end

array.containsEntity = function(table, entity) --(Table, Entity)->[Bool] Return if entity is on table.
    for _, thisEntity in pairs(table) do
        if GetPtrHash(thisEntity) == GetPtrHash(entity) then
            return true
        end
    end
    return false
end

array.containsVector = function(table, vector) --(Table, Vector->[Bool] Return if vector is on table.
    for _, thisVector in pairs(table) do
        if thisVector.X == vector.X and thisVector.Y == vector.Y then
            return true
        end
    end
    return false
end

return array
