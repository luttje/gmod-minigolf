local entityMeta = FindMetaTable("Entity")

Minigolf.Entity = Minigolf.Entity or {}

--- Calculates if the given entity is within distance of another entity.
---@param entity Entity
---@param otherEntity Entity
---@param distance number The distance in units
---@return boolean
function Minigolf.Entity.IsInDistanceOf(entity, otherEntity, distance)
	return entity:GetPos():DistToSqr(otherEntity:GetPos()) < (distance * distance)
end

entityMeta.IsInDistanceOf = Minigolf.Entity.IsInDistanceOf

--- Sets Minigolf data for the given entity.
---@param entity Entity
---@param key string The key to set the data to
---@param value any The value to set the data to
---@return any
function Minigolf.Entity.SetData(entity, key, value)
	if (not entity._Minigolf) then
		entity._Minigolf = {}
	end

	entity._Minigolf[key] = value

	return entity._Minigolf[key]
end

--- Get Minigolf data for the given entity.
---@param entity Entity
---@param key string The key to get the data from
---@param default any|nil A default value to set if nil was found
---@return any
function Minigolf.Entity.GetData(entity, key, default)
	if (entity._Minigolf and entity._Minigolf[key] ~= nil) then
		return entity._Minigolf[key]
	end

	entity._Minigolf = entity._Minigolf or {}
	entity._Minigolf[key] = default

	return default
end

entityMeta.SetMinigolfData = Minigolf.Entity.SetData
entityMeta.GetMinigolfData = Minigolf.Entity.GetData
