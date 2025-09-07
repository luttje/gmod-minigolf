Minigolf.Config = Minigolf.Config or {}
Minigolf.Config._Config = Minigolf.Config._Config or {}

--- Colors aliases
Minigolf.Colors = Minigolf.Colors or {}

---
---@param key string
---@param value any
function Minigolf.Config.Set(key, value)
	Minigolf.Config._Config[key] = value
end

---
---@param key string
---@param color Color
function Minigolf.Colors.Set(key, color)
	Minigolf.Config.Set("Color" .. key, color)
end

---
---@param key string
---@param default any
---@return any
function Minigolf.Config.Get(key, default)
	return Minigolf.Config._Config[key] or default
end

---
---@param key string
---@param defaultColor? Color
---@return Color
function Minigolf.Colors.Get(key, defaultColor)
	return Minigolf.Config.Get("Color" .. key, defaultColor or Color(255, 255, 255))
end
