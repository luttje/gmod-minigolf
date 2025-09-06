AddCSLuaFile()

DEFINE_BASECLASS("base_anim")

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Minigolf Track Designer"
ENT.Category = "Minigolf"
ENT.Spawnable = true
ENT.AdminOnly = true

ENT.MATERIALS = {
  RED_CARPET = "props/carpetfloor001a",
  GREEN_CARPET = "props/carpetfloor003a",
  WOOD_BORDER = "wood/woodfloor008a",
  HOLE_INTERIOR = "halflife/black"
}

if (CLIENT) then
  ENT.MATERIALS = {
    RED_CARPET = CreateMaterial(
      "minigolf_red_carpet_unlit",
      "UnlitGeneric",
      {
        ["$basetexture"] = ENT.MATERIALS.RED_CARPET,
        ["$vertexcolor"] = 1,
      }
    ),
    GREEN_CARPET = CreateMaterial(
      "minigolf_green_carpet_unlit",
      "UnlitGeneric",
      {
        ["$basetexture"] = ENT.MATERIALS.GREEN_CARPET,
        ["$vertexcolor"] = 1,
      }
    ),
    WOOD_BORDER = CreateMaterial(
      "minigolf_wood_border_unlit",
      "UnlitGeneric",
      {
        ["$basetexture"] = ENT.MATERIALS.WOOD_BORDER,
        ["$vertexcolor"] = 1,
      }
    ),
    HOLE_INTERIOR = CreateMaterial(
      "minigolf_hole_interior_unlit",
      "UnlitGeneric",
      {
        ["$basetexture"] = ENT.MATERIALS.HOLE_INTERIOR,
        ["$vertexcolor"] = 1,
      }
    )
  }
end

-- Default dimensions
ENT.TRACK_WIDTH = 128
ENT.TRACK_LENGTH = 256
ENT.BORDER_HEIGHT = 16
ENT.BORDER_WIDTH = 8

-- Part type registry
ENT.PART_TYPES = {}
ENT.PART_TYPE_LIST = {}

-- Registration function for part types
function ENT:RegisterPartType(id, config)
  self.PART_TYPES[id] = config
  table.insert(self.PART_TYPE_LIST, id)
end

-- Register default part types
ENT:RegisterPartType("start", {
  name = "Start Part",
  material = ENT.MATERIALS.RED_CARPET,
  blockVertexManipulation = true, -- Prevent vertex editing for start parts
  boxes = {
    -- Main track floor - split into red and green sections
    {
      type = "floor",
      material = ENT.MATERIALS.RED_CARPET,
      min = Vector(-ENT.TRACK_WIDTH / 2, -ENT.TRACK_LENGTH / 2, 0),
      max = Vector(ENT.TRACK_WIDTH / 2, 0, 2)
    },
    {
      type = "floor",
      material = ENT.MATERIALS.GREEN_CARPET,
      min = Vector(-ENT.TRACK_WIDTH / 2, 0, 0),
      max = Vector(ENT.TRACK_WIDTH / 2, ENT.TRACK_LENGTH / 2, 2)
    }
  },
  entities = {
    {
      type = "minigolf_hole_start",
      offset = Vector(0, -ENT.TRACK_LENGTH / 4, 8),
      keyvalues = {
        hole = "Hole %d",
        course = "Designer Course",
        par = "3",
        order = "%d"
      }
    }
  }
})

ENT:RegisterPartType("continuous", {
  name = "Continuous Part",
  material = ENT.MATERIALS.GREEN_CARPET,
  boxes = {
    -- Single green floor
    {
      type = "floor",
      material = ENT.MATERIALS.GREEN_CARPET,
      min = Vector(-ENT.TRACK_WIDTH / 2, -ENT.TRACK_LENGTH / 2, 0),
      max = Vector(ENT.TRACK_WIDTH / 2, ENT.TRACK_LENGTH / 2, 2)
    }
  },
  entities = {}
})

ENT:RegisterPartType("end", {
  name = "End Part",
  material = ENT.MATERIALS.GREEN_CARPET,
  boxes = {
    -- Green floor with hole cutout (simplified as single box for now)
    {
      type = "floor",
      material = ENT.MATERIALS.GREEN_CARPET,
      min = Vector(-ENT.TRACK_WIDTH / 2, -ENT.TRACK_LENGTH / 2, 0),
      max = Vector(ENT.TRACK_WIDTH / 2, ENT.TRACK_LENGTH / 2, 2)
    }
  },
  entities = {
    {
      type = "minigolf_hole_end",
      offset = Vector(0, ENT.TRACK_LENGTH / 2, -16),
      keyvalues = {}
    }
  }
})

-- Helper function to get part type config
function ENT:GetPartTypeConfig(partTypeId)
  return self.PART_TYPES[partTypeId]
end

-- Helper function to get all part type IDs
function ENT:GetPartTypeList()
  return self.PART_TYPE_LIST
end

function ENT:CanTool(player, trace, toolName, tool, button)
  return false
end

function ENT:CanProperty(player, property)
  return false
end

hook.Add("PhysgunPickup", "MinigolfTrackDesigner.PreventPhysgunPickup", function(player, entity)
  if entity:GetClass() == "minigolf_track_designer" then
    return false
  end
end)
