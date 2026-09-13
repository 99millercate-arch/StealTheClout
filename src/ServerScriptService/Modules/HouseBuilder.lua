-- Builds the coin-bought house around a plot, one stage at a time (GameConfig.BUILDING order).
-- Stage parts live in plot.House.<StageKey> so a stage can be added or torn down on its own.
-- The plot's BuildLevel attribute (replicated) says how many stages are built.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules").GameConfig)

local HouseBuilder = {}

local WALL_HEIGHT = 10
local WALL_THICKNESS = 1
local DOOR_WIDTH = 8
local DOOR_HEIGHT = 8
local ROOF_BORDER = 5 -- roof is a ring so the sky stays open above the pads (camera-friendly)

-- Cycled by plot index so the street doesn't look copy-pasted
local PALETTES = {
	{ Wall = Color3.fromRGB(196, 92, 84), Trim = Color3.fromRGB(255, 120, 200), Roof = Color3.fromRGB(70, 40, 40) },
	{ Wall = Color3.fromRGB(88, 128, 190), Trim = Color3.fromRGB(0, 230, 255), Roof = Color3.fromRGB(35, 45, 70) },
	{ Wall = Color3.fromRGB(120, 170, 100), Trim = Color3.fromRGB(150, 255, 90), Roof = Color3.fromRGB(40, 60, 35) },
	{ Wall = Color3.fromRGB(214, 170, 90), Trim = Color3.fromRGB(255, 220, 0), Roof = Color3.fromRGB(80, 55, 25) },
	{ Wall = Color3.fromRGB(150, 110, 190), Trim = Color3.fromRGB(230, 120, 255), Roof = Color3.fromRGB(50, 35, 70) },
	{ Wall = Color3.fromRGB(230, 230, 235), Trim = Color3.fromRGB(255, 80, 80), Roof = Color3.fromRGB(60, 60, 65) },
}

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.CastShadow = props.CastShadow ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Name = props.Name or "Part"
	p.Size = props.Size
	p.CFrame = props.CFrame or CFrame.new(props.Position)
	p.Color = props.Color or Color3.fromRGB(200, 200, 200)
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Transparency = props.Transparency or 0
	if props.Shape then
		p.Shape = props.Shape
	end
	p.Parent = props.Parent
	return p
end

-- Geometry shared by every stage
local function frameFor(plot)
	local platform = plot.Platform
	local size = GameConfig.PLOT_SIZE
	return {
		origin = platform.Position,
		size = size,
		floorTop = platform.Position.Y + size.Y / 2,
		frontZ = -size.Z / 2 + WALL_THICKNESS / 2, -- front = -Z, facing the street
		palette = PALETTES[(plot:GetAttribute("PlotIndex") - 1) % #PALETTES + 1],
	}
end

local stageBuilders = {}

function stageBuilders.Walls(plot, folder)
	local f = frameFor(plot)
	local wallY = f.floorTop + WALL_HEIGHT / 2

	local function wall(name, wallSize, offset)
		part({
			Name = name,
			Size = wallSize,
			Position = Vector3.new(f.origin.X + offset.X, wallY, f.origin.Z + offset.Z),
			Color = f.palette.Wall,
			Material = Enum.Material.Brick,
			Parent = folder,
		})
	end

	wall("BackWall", Vector3.new(f.size.X, WALL_HEIGHT, WALL_THICKNESS), Vector3.new(0, 0, f.size.Z / 2 - WALL_THICKNESS / 2))
	wall("LeftWall", Vector3.new(WALL_THICKNESS, WALL_HEIGHT, f.size.Z), Vector3.new(-f.size.X / 2 + WALL_THICKNESS / 2, 0, 0))
	wall("RightWall", Vector3.new(WALL_THICKNESS, WALL_HEIGHT, f.size.Z), Vector3.new(f.size.X / 2 - WALL_THICKNESS / 2, 0, 0))

	-- Front wall leaves a gap for the door stage
	local sideWidth = (f.size.X - DOOR_WIDTH) / 2
	wall("FrontLeft", Vector3.new(sideWidth, WALL_HEIGHT, WALL_THICKNESS), Vector3.new(-(DOOR_WIDTH / 2 + sideWidth / 2), 0, f.frontZ))
	wall("FrontRight", Vector3.new(sideWidth, WALL_HEIGHT, WALL_THICKNESS), Vector3.new(DOOR_WIDTH / 2 + sideWidth / 2, 0, f.frontZ))
	part({
		Name = "Lintel",
		Size = Vector3.new(DOOR_WIDTH, WALL_HEIGHT - DOOR_HEIGHT, WALL_THICKNESS),
		Position = Vector3.new(f.origin.X, f.floorTop + DOOR_HEIGHT + (WALL_HEIGHT - DOOR_HEIGHT) / 2, f.origin.Z + f.frontZ),
		Color = f.palette.Wall,
		Material = Enum.Material.Brick,
		Parent = folder,
	})

	-- Rug under the pads
	part({
		Name = "Rug",
		Size = Vector3.new(GameConfig.PAD_SPACING + GameConfig.PAD_SIZE.X + 4, 0.1, GameConfig.PAD_SPACING + GameConfig.PAD_SIZE.Z + 4),
		Position = Vector3.new(f.origin.X, f.floorTop + 0.05, f.origin.Z),
		Color = f.palette.Roof,
		Material = Enum.Material.Fabric,
		CanCollide = false,
		Parent = folder,
	})
end

function stageBuilders.Door(plot, folder)
	local f = frameFor(plot)
	local wood = Color3.fromRGB(120, 80, 45)

	for _, sideSign in ipairs({ -1, 1 }) do
		part({
			Name = "DoorPost",
			Size = Vector3.new(0.8, DOOR_HEIGHT, WALL_THICKNESS + 0.4),
			Position = Vector3.new(f.origin.X + sideSign * (DOOR_WIDTH / 2 + 0.4), f.floorTop + DOOR_HEIGHT / 2, f.origin.Z + f.frontZ),
			Color = wood,
			Material = Enum.Material.WoodPlanks,
			Parent = folder,
		})
	end
	part({
		Name = "DoorHeader",
		Size = Vector3.new(DOOR_WIDTH + 1.6, 0.8, WALL_THICKNESS + 0.4),
		Position = Vector3.new(f.origin.X, f.floorTop + DOOR_HEIGHT + 0.4, f.origin.Z + f.frontZ),
		Color = wood,
		Material = Enum.Material.WoodPlanks,
		Parent = folder,
	})

	-- Invisible marker the shield barrier snaps to (see ProtectionService)
	local doorway = part({
		Name = "Doorway",
		Size = Vector3.new(DOOR_WIDTH, DOOR_HEIGHT, 0.5),
		Position = Vector3.new(f.origin.X, f.floorTop + DOOR_HEIGHT / 2, f.origin.Z + f.frontZ),
		Transparency = 1,
		CanCollide = false,
		CastShadow = false,
		Parent = folder,
	})
	doorway.CanQuery = false
end

function stageBuilders.Roof(plot, folder)
	local f = frameFor(plot)
	local roofY = f.floorTop + WALL_HEIGHT + 0.7

	local function roof(name, roofSize, offset)
		part({
			Name = name,
			Size = roofSize,
			Position = Vector3.new(f.origin.X + offset.X, roofY, f.origin.Z + offset.Z),
			Color = f.palette.Roof,
			Material = Enum.Material.Slate,
			Parent = folder,
		})
	end
	roof("RoofBack", Vector3.new(f.size.X + 2, 0.6, ROOF_BORDER), Vector3.new(0, 0, f.size.Z / 2 - ROOF_BORDER / 2 + 1))
	roof("RoofFront", Vector3.new(f.size.X + 2, 0.6, ROOF_BORDER), Vector3.new(0, 0, -f.size.Z / 2 + ROOF_BORDER / 2 - 1))
	roof("RoofLeft", Vector3.new(ROOF_BORDER, 0.6, f.size.Z + 2), Vector3.new(-f.size.X / 2 + ROOF_BORDER / 2 - 1, 0, 0))
	roof("RoofRight", Vector3.new(ROOF_BORDER, 0.6, f.size.Z + 2), Vector3.new(f.size.X / 2 - ROOF_BORDER / 2 + 1, 0, 0))
end

function stageBuilders.Trim(plot, folder)
	local f = frameFor(plot)
	local trimY = f.floorTop + WALL_HEIGHT + 0.2

	local function trim(name, trimSize, offset)
		part({
			Name = name,
			Size = trimSize,
			Position = Vector3.new(f.origin.X + offset.X, trimY, f.origin.Z + offset.Z),
			Color = f.palette.Trim,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = folder,
		})
	end
	trim("TrimBack", Vector3.new(f.size.X, 0.4, WALL_THICKNESS + 0.2), Vector3.new(0, 0, f.size.Z / 2 - WALL_THICKNESS / 2))
	trim("TrimFront", Vector3.new(f.size.X, 0.4, WALL_THICKNESS + 0.2), Vector3.new(0, 0, f.frontZ))
	trim("TrimLeft", Vector3.new(WALL_THICKNESS + 0.2, 0.4, f.size.Z), Vector3.new(-f.size.X / 2 + WALL_THICKNESS / 2, 0, 0))
	trim("TrimRight", Vector3.new(WALL_THICKNESS + 0.2, 0.4, f.size.Z), Vector3.new(f.size.X / 2 - WALL_THICKNESS / 2, 0, 0))

	-- A glowing light inside so the finished house stands out at night
	local light = Instance.new("PointLight")
	light.Color = f.palette.Trim
	light.Range = 24
	light.Brightness = 1
	light.Parent = folder:FindFirstChild("TrimFront")
end

-- Public API -------------------------------------------------------------------------------

function HouseBuilder.GetLevel(plot)
	return plot:GetAttribute("BuildLevel") or 0
end

-- Returns the stage config for `level` (1-based) or nil
function HouseBuilder.Stage(level)
	return GameConfig.BUILDING[level]
end

-- Returns the stage config for `key` if this plot has built it, else nil. Handy for perks:
--   local roof = HouseBuilder.PerkFor(plot, "Roof"); cap *= roof and roof.StorageMultiplier or 1
function HouseBuilder.PerkFor(plot, key)
	local level = HouseBuilder.GetLevel(plot)
	for index, stage in ipairs(GameConfig.BUILDING) do
		if stage.Key == key then
			return index <= level and stage or nil
		end
	end
	return nil
end

-- Builds (or tears down) stages so exactly `level` stages exist
function HouseBuilder.SetLevel(plot, level)
	level = math.clamp(level, 0, #GameConfig.BUILDING)

	local house = plot:FindFirstChild("House")
	if not house then
		house = Instance.new("Model")
		house.Name = "House"
		house.Parent = plot
	end

	for index, stage in ipairs(GameConfig.BUILDING) do
		local folder = house:FindFirstChild(stage.Key)
		if index <= level and not folder then
			folder = Instance.new("Model")
			folder.Name = stage.Key
			stageBuilders[stage.Key](plot, folder)
			folder.Parent = house
		elseif index > level and folder then
			folder:Destroy()
		end
	end

	plot:SetAttribute("BuildLevel", level)
end

function HouseBuilder.Clear(plot)
	HouseBuilder.SetLevel(plot, 0)
end

return HouseBuilder
