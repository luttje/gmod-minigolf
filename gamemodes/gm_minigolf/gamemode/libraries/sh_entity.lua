local entityMeta = FindMetaTable("Entity")

Minigolf.Entity = {}

--- Calculates if the given entity is within distance of another entity.
---@param entity Entity
---@param otherEntity Entity
---@param distance number The distance in units
---@return boolean
function Minigolf.Entity.IsInDistanceOf(entity, otherEntity, distance)
  return entity:GetPos():DistToSqr(otherEntity:GetPos()) < (distance*distance)
end

entityMeta.IsInDistanceOf = Minigolf.Entity.IsInDistanceOf