local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules").GameConfig)

local function createBaseplate()
	local base = Instance.new("Part")
	base.Name = "Ground"
	base.Size = Vector3.new(400, 1, 400)
	base.Position = Vector3.new(0, 0, 40)
	base.Anchored = true
	base.Color = Color3.fromRGB(60, 130, 60)
	base.Material = Enum.Material.Grass
	base.Parent = workspace
end

local function createNameplate(parent, text)
	local sign = Instance.new("Part")
	sign.Name = "NameplatePart"
	sign.Size = Vector3.new(8, 3, 0.5)
	sign.Anchored = true
	sign.CanCollide = false
	sign.Color = Color3.fromRGB(255, 255, 255)
	sign.Parent = parent

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
	label.TextColor3 = Color3.new(0, 0, 0)
	label.Parent = gui

	return sign
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

	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Size = GameConfig.PLOT_SIZE
	platform.Position = Vector3.new(originX, 1, originZ)
	platform.Anchored = true
	platform.Color = Color3.fromRGB(200, 200, 200)
	platform.Material = Enum.Material.Concrete
	platform.Parent = plot

	local sign = createNameplate(plot, "Empty Plot")
	sign.CFrame = platform.CFrame * CFrame.new(0, 3, -GameConfig.PLOT_SIZE.Z / 2 - 0.5)

	local pads = Instance.new("Folder")
	pads.Name = "Pads"
	pads.Parent = plot

	local padsPerRow = 2
	for padIndex = 1, GameConfig.PADS_PER_PLOT do
		local padColumn = (padIndex - 1) % padsPerRow
		local padRow = math.floor((padIndex - 1) / padsPerRow)
		local offsetX = (padColumn - (padsPerRow - 1) / 2) * GameConfig.PAD_SPACING
		local offsetZ = (padRow - (padsPerRow - 1) / 2) * GameConfig.PAD_SPACING

		local pad = Instance.new("Part")
		pad.Name = "Pad" .. padIndex
		pad.Size = GameConfig.PAD_SIZE
		pad.Position = platform.Position
			+ Vector3.new(offsetX, GameConfig.PAD_SIZE.Y / 2 + platform.Size.Y / 2, offsetZ)
		pad.Anchored = true
		pad.Color = Color3.fromRGB(235, 225, 140)
		pad.Material = Enum.Material.Metal
		pad:SetAttribute("PlotIndex", index)
		pad:SetAttribute("PadIndex", padIndex)
		pad:SetAttribute("Occupied", false)
		pad:SetAttribute("CharacterId", "")
		pad:SetAttribute("StoredValue", 0)
		pad:SetAttribute("PlacedAt", 0) -- see ProtectionService for these three
		pad:SetAttribute("LockLevel", 0)
		pad:SetAttribute("LockHP", 0)
		pad.Parent = pads
	end

	plot.Parent = plotsFolder
end

local function buildShop()
	local shop = Instance.new("Model")
	shop.Name = "Shop"

	local stall = Instance.new("Part")
	stall.Name = "EggShopStall"
	stall.Size = Vector3.new(8, 6, 8)
	stall.Position = Vector3.new(0, 4, -20)
	stall.Anchored = true
	stall.Color = Color3.fromRGB(255, 200, 0)
	stall.Material = Enum.Material.Wood
	stall.Parent = shop

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyBasicEgg"
	prompt.ObjectText = "Basic Egg"
	prompt.ActionText = "Buy (50 coins)"
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = stall

	shop.Parent = workspace

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "MainSpawn"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 1, -38)
	spawn.Anchored = true
	spawn.Color = Color3.fromRGB(100, 200, 255)
	spawn.Parent = workspace
end

createBaseplate()

local plotsFolder = Instance.new("Folder")
plotsFolder.Name = "Plots"
plotsFolder.Parent = workspace

for index = 1, GameConfig.NUM_PLOTS do
	buildPlot(index, plotsFolder)
end

buildShop()
