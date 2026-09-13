local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Modules").Remotes)

local ServerModules = script.Parent.Modules
local DataManager = require(ServerModules.DataManager)
local PlacementService = require(ServerModules.PlacementService)
local PlayerState = require(ServerModules.PlayerState)
local PlotManager = require(ServerModules.PlotManager)
local ProtectionService = require(ServerModules.ProtectionService)
local HouseBuilder = require(ServerModules.HouseBuilder)

local function onPlayerAdded(player)
	local data = DataManager.Load(player)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.Coins
	coins.Parent = leaderstats

	leaderstats.Parent = player

	PlayerState.Init(player, data.Inventory)

	local plot = PlotManager.AssignPlot(player)
	if plot then
		HouseBuilder.SetLevel(plot, data.BuildLevel)
		local pads = plot:FindFirstChild("Pads")
		for padIndex, level in ipairs(data.PadLocks) do
			local pad = pads and pads:FindFirstChild("Pad" .. padIndex)
			if pad then
				ProtectionService.SetLockLevel(pad, level)
			end
		end
		for _, entry in ipairs(data.Placed) do
			local pad = pads and pads:FindFirstChild("Pad" .. tostring(entry.PadIndex))
			if pad then
				PlacementService.SpawnCharacterOnPad(plot, pad, entry.CharacterId, entry.StoredValue)
			end
		end
	end

	Remotes.InventoryUpdated:FireClient(player, PlayerState.Get(player).Inventory)
end

Remotes.RequestInventory.OnServerInvoke = function(player)
	local state = PlayerState.Get(player)
	return state and state.Inventory or {}
end

local function onPlayerRemoving(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local state = PlayerState.Get(player)

	local placed = {}
	local padLocks = {}
	local plot = PlotManager.GetPlotByOwner(player)
	if plot then
		local pads = plot:FindFirstChild("Pads")
		if pads then
			for _, pad in ipairs(pads:GetChildren()) do
				padLocks[pad:GetAttribute("PadIndex")] = pad:GetAttribute("LockLevel") or 0
				if pad:GetAttribute("Occupied") then
					table.insert(placed, {
						PadIndex = pad:GetAttribute("PadIndex"),
						CharacterId = pad:GetAttribute("CharacterId"),
						StoredValue = math.floor(pad:GetAttribute("StoredValue")),
					})
				end
			end
		end
	end

	DataManager.Save(player, {
		Coins = leaderstats and leaderstats.Coins.Value or 0,
		Inventory = state and state.Inventory or {},
		Placed = placed,
		PadLocks = padLocks,
		BuildLevel = plot and HouseBuilder.GetLevel(plot) or 0,
	})

	if plot then
		ProtectionService.ClearPlot(plot)
	end
	PlotManager.ReleasePlot(player, PlacementService.ClearPad)
	PlayerState.Clear(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerRemoving(player)
	end
end)
