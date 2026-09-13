-- Builds the whole world at server start: ground, roads, plaza, the egg shop kiosk, the spawn,
-- and every plot's floor, pads, step and sign. The house itself is bought in-game (HouseBuilder). Nothing here needs to exist in
-- the place file - delete this script's output and it rebuilds identically next run.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules").GameConfig)

local ROAD_WIDTH = 10
local SIGN_WIDTH = 10

-- Helpers ---------------------------------------------------------------------------

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.CastShadow = props.CastShadow ~= false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Name = props.Name or "Part"
	p.Size = props.Size
	p.CFrame = props.CFrame or CFrame.new(props.Position or Vector3.zero)
	p.Color = props.Color or Color3.fromRGB(200, 200, 200)
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Transparency = props.Transparency or 0
	if props.Shape then
		p.Shape = props.Shape
	end
	p.Parent = props.Parent
	return p
end

local function createNameplate(parent, text)
	local sign = part({
		Name = "NameplatePart",
		Size = Vector3.new(SIGN_WIDTH, 2, 0.4),
		Color = Color3.fromRGB(30, 30, 35),
		Material = Enum.Material.Metal,
		Parent = parent,
	})

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign

	local label = Instance.new("TextLabel")
	label.Name = "Nameplate"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 220, 0)
	label.Parent = gui

	return sign
end

-- Ground, roads, plaza ---------------------------------------------------------------

local function createGround()
	part({
		Name = "Ground",
		Size = Vector3.new(400, 1, 400),
		Position = Vector3.new(0, 0, 40),
		Color = Color3.fromRGB(60, 130, 60),
		Material = Enum.Material.Grass,
		Parent = workspace,
	})
end

local function createRoads(decor)
	local rows = math.ceil(GameConfig.NUM_PLOTS / GameConfig.PLOTS_PER_ROW)
	local firstRowZ = 20
	local lastRowZ = (rows - 1) * GameConfig.PLOT_SPACING + 20
	local halfWidth = (GameConfig.PLOTS_PER_ROW - 1) / 2 * GameConfig.PLOT_SPACING + GameConfig.PLOT_SIZE.X / 2 + 8

	-- Main avenue from the spawn straight through the block
	part({
		Name = "Avenue",
		Size = Vector3.new(ROAD_WIDTH, 0.2, lastRowZ + 60),
		Position = Vector3.new(0, 0.6, (lastRowZ - 40) / 2 + 10),
		Color = Color3.fromRGB(90, 90, 95),
		Material = Enum.Material.Cobblestone,
		Parent = decor,
	})

	-- A street in front of every row of houses
	for row = 0, rows - 1 do
		local z = firstRowZ + row * GameConfig.PLOT_SPACING - GameConfig.PLOT_SIZE.Z / 2 - 5
		part({
			Name = "Street" .. row,
			Size = Vector3.new(halfWidth * 2, 0.2, ROAD_WIDTH),
			Position = Vector3.new(0, 0.6, z),
			Color = Color3.fromRGB(90, 90, 95),
			Material = Enum.Material.Cobblestone,
			Parent = decor,
		})
	end

	-- Plaza around the shop
	part({
		Name = "Plaza",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, 44, 44),
		CFrame = CFrame.new(0, 0.65, -22) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(150, 140, 125),
		Material = Enum.Material.Slate,
		Parent = decor,
	})
end

-- Decor: lamps and trees ----------------------------------------------------------------

local function createLamp(position, decor)
	local lamp = Instance.new("Model")
	lamp.Name = "Lamp"

	part({
		Name = "Post",
		Size = Vector3.new(0.6, 9, 0.6),
		Position = position + Vector3.new(0, 5, 0),
		Color = Color3.fromRGB(40, 40, 45),
		Material = Enum.Material.Metal,
		Parent = lamp,
	})
	local bulb = part({
		Name = "Bulb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.6, 1.6, 1.6),
		Position = position + Vector3.new(0, 10, 0),
		Color = Color3.fromRGB(255, 230, 150),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = lamp,
	})
	local light = Instance.new("PointLight")
	light.Brightness = 1.5
	light.Range = 22
	light.Color = Color3.fromRGB(255, 225, 160)
	light.Parent = bulb

	lamp.Parent = decor
end

local function createTree(position, scale, decor)
	local tree = Instance.new("Model")
	tree.Name = "Tree"

	part({
		Name = "Trunk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(6 * scale, 1.4 * scale, 1.4 * scale),
		CFrame = CFrame.new(position + Vector3.new(0, 3 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(95, 65, 40),
		Material = Enum.Material.Wood,
		Parent = tree,
	})
	part({
		Name = "Leaves",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(7, 7, 7) * scale,
		Position = position + Vector3.new(0, 8 * scale, 0),
		Color = Color3.fromRGB(50, 140, 60),
		Material = Enum.Material.Grass,
		CanCollide = false,
		Parent = tree,
	})

	tree.Parent = decor
end

local function createDecor()
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = workspace

	createRoads(decor)

	local rows = math.ceil(GameConfig.NUM_PLOTS / GameConfig.PLOTS_PER_ROW)
	for row = 0, rows - 1 do
		local streetZ = 20 + row * GameConfig.PLOT_SPACING - GameConfig.PLOT_SIZE.Z / 2 - 5
		for column = 0, GameConfig.PLOTS_PER_ROW - 2 do
			-- Lamps on the street between neighbouring houses
			local x = (column - (GameConfig.PLOTS_PER_ROW - 1) / 2 + 0.5) * GameConfig.PLOT_SPACING
			createLamp(Vector3.new(x, 0.5, streetZ + ROAD_WIDTH / 2 + 1.5), decor)
		end
	end

	-- Ring of lamps and trees around the plaza
	for i = 0, 7 do
		local angle = i * math.pi / 4
		local radius = 24
		local pos = Vector3.new(math.cos(angle) * radius, 0.5, -22 + math.sin(angle) * radius)
		if i % 2 == 0 then
			createLamp(pos, decor)
		else
			createTree(pos, 1.2, decor)
		end
	end

	-- Trees along the block edges
	local edgeX = (GameConfig.PLOTS_PER_ROW - 1) / 2 * GameConfig.PLOT_SPACING + GameConfig.PLOT_SIZE.X / 2 + 14
	for row = 0, rows - 1 do
		local z = 20 + row * GameConfig.PLOT_SPACING
		createTree(Vector3.new(-edgeX, 0.5, z), 1.4, decor)
		createTree(Vector3.new(edgeX, 0.5, z), 1.4, decor)
		createTree(Vector3.new(-edgeX, 0.5, z + 18), 0.9, decor)
		createTree(Vector3.new(edgeX, 0.5, z + 18), 0.9, decor)
	end
end

-- Plots ---------------------------------------------------------------------------------

-- The free bits every plot starts with: a front step and a sign on a post. The house itself
-- is bought stage by stage (see HouseBuilder / GameConfig.BUILDING).
local function buildFrontYard(plot, platform)
	local size = GameConfig.PLOT_SIZE
	local origin = platform.Position
	local floorTop = origin.Y + size.Y / 2

	part({
		Name = "Step",
		Size = Vector3.new(12, 0.5, 4),
		Position = Vector3.new(origin.X, floorTop - 0.25, origin.Z - size.Z / 2 - 2),
		Color = Color3.fromRGB(170, 170, 175),
		Material = Enum.Material.Concrete,
		Parent = plot,
	})

	-- Sign hangs off a post beside the front path, facing the street
	local signZ = origin.Z - size.Z / 2 - 5
	local postX = origin.X + 6
	part({
		Name = "SignPost",
		Size = Vector3.new(0.5, 9, 0.5),
		Position = Vector3.new(postX, floorTop + 4.5, signZ),
		Color = Color3.fromRGB(40, 40, 45),
		Material = Enum.Material.Metal,
		Parent = plot,
	})
	local sign = createNameplate(plot, "Empty Plot")
	-- High enough that it never blocks the path to the door
	sign.CFrame = CFrame.new(postX - SIGN_WIDTH / 2 - 0.25, floorTop + 8, signZ)
end

local function buildPlot(index, plotsFolder)
	local column = (index - 1) % GameConfig.PLOTS_PER_ROW
	local row = math.floor((index - 1) / GameConfig.PLOTS_PER_ROW)
	local originX = (column - (GameConfig.PLOTS_PER_ROW - 1) / 2) * GameConfig.PLOT_SPACING
	local originZ = row * GameConfig.PLOT_SPACING + 20

	local plot = Instance.new("Model")
	plot.Name = "Plot" .. index
	plot:SetAttribute("PlotIndex", index)
	plot:SetAttribute("OwnerUserId", 0)
	plot:SetAttribute("ShieldUntil", 0)
	plot:SetAttribute("ShieldCooldownUntil", 0)

	local platform = part({
		Name = "Platform",
		Size = GameConfig.PLOT_SIZE,
		Position = Vector3.new(originX, 1, originZ),
		Color = Color3.fromRGB(110, 105, 100),
		Material = Enum.Material.WoodPlanks,
		Parent = plot,
	})

	plot:SetAttribute("BuildLevel", 0)
	buildFrontYard(plot, platform)

	local pads = Instance.new("Folder")
	pads.Name = "Pads"
	pads.Parent = plot

	local padsPerRow = 2
	for padIndex = 1, GameConfig.PADS_PER_PLOT do
		local padColumn = (padIndex - 1) % padsPerRow
		local padRow = math.floor((padIndex - 1) / padsPerRow)
		local offsetX = (padColumn - (padsPerRow - 1) / 2) * GameConfig.PAD_SPACING
		local offsetZ = (padRow - (padsPerRow - 1) / 2) * GameConfig.PAD_SPACING

		local pad = part({
			Name = "Pad" .. padIndex,
			Size = GameConfig.PAD_SIZE,
			Position = platform.Position
				+ Vector3.new(offsetX, GameConfig.PAD_SIZE.Y / 2 + platform.Size.Y / 2, offsetZ),
			Color = Color3.fromRGB(235, 225, 140),
			Material = Enum.Material.Metal,
			Parent = pads,
		})
		pad:SetAttribute("PlotIndex", index)
		pad:SetAttribute("PadIndex", padIndex)
		pad:SetAttribute("Occupied", false)
		pad:SetAttribute("CharacterId", "")
		pad:SetAttribute("StoredValue", 0)
		pad:SetAttribute("PlacedAt", 0) -- see ProtectionService for these three
		pad:SetAttribute("LockLevel", 0)
		pad:SetAttribute("LockHP", 0)
	end

	plot.Parent = plotsFolder
end

-- Shop kiosk + spawn --------------------------------------------------------------------

local function buildShop()
	local shop = Instance.new("Model")
	shop.Name = "Shop"

	local base = Vector3.new(0, 0.5, -20)

	-- Counter (this part carries the ProximityPrompt, so keep its name)
	local stall = part({
		Name = "EggShopStall",
		Size = Vector3.new(10, 3.5, 4),
		Position = base + Vector3.new(0, 1.75, 0),
		Color = Color3.fromRGB(255, 200, 0),
		Material = Enum.Material.WoodPlanks,
		Parent = shop,
	})

	-- Back wall and roof posts
	part({
		Name = "BackBoard",
		Size = Vector3.new(10, 8, 0.6),
		Position = base + Vector3.new(0, 4, 3),
		Color = Color3.fromRGB(60, 40, 30),
		Material = Enum.Material.Wood,
		Parent = shop,
	})
	for _, x in ipairs({ -4.6, 4.6 }) do
		part({
			Name = "Post",
			Size = Vector3.new(0.6, 8, 0.6),
			Position = base + Vector3.new(x, 4, -2),
			Color = Color3.fromRGB(60, 40, 30),
			Material = Enum.Material.Wood,
			Parent = shop,
		})
	end

	-- Striped awning
	for i = 0, 4 do
		part({
			Name = "Awning",
			Size = Vector3.new(2.2, 0.3, 6.5),
			CFrame = CFrame.new(base + Vector3.new(-4.4 + i * 2.2, 8.4, 0.2)) * CFrame.Angles(math.rad(-12), 0, 0),
			Color = i % 2 == 0 and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(240, 240, 240),
			Material = Enum.Material.Fabric,
			CanCollide = false,
			Parent = shop,
		})
	end

	-- Giant egg on the roof so the shop reads from across the map
	part({
		Name = "BigEgg",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(4, 5, 4),
		Position = base + Vector3.new(0, 11.5, 1),
		Color = Color3.fromRGB(255, 240, 200),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Parent = shop,
	})

	local signBoard = part({
		Name = "SignBoard",
		Size = Vector3.new(8, 2, 0.3),
		Position = base + Vector3.new(0, 6.2, 2.6),
		Color = Color3.fromRGB(20, 20, 25),
		Material = Enum.Material.Metal,
		Parent = shop,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = signBoard
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "EGG SHOP"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 220, 0)
	label.Parent = gui

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyBasicEgg"
	prompt.ObjectText = "Basic Egg"
	prompt.ActionText = "Buy (" .. GameConfig.EGGS.Basic.Cost .. " coins)"
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = stall

	shop.Parent = workspace

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(12, 0.4, 12)
	spawn.Position = Vector3.new(0, 0.9, -40)
	spawn.Anchored = true
	spawn.Color = Color3.fromRGB(100, 200, 255)
	spawn.Material = Enum.Material.Neon
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = workspace
end

-- Build order ------------------------------------------------------------------------------

createGround()
createDecor()

local plotsFolder = Instance.new("Folder")
plotsFolder.Name = "Plots"
plotsFolder.Parent = workspace

for index = 1, GameConfig.NUM_PLOTS do
	buildPlot(index, plotsFolder)
end

buildShop()
