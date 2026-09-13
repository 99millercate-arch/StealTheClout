local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local CharacterData = require(Modules.CharacterData)
local GameConfig = require(Modules.GameConfig)

local HouseBuilder = require(script.Parent.Modules.HouseBuilder)

local plotsFolder = workspace:WaitForChild("Plots")

local vipPass
for _, pass in ipairs(GameConfig.MONETIZATION.Passes) do
	if pass.Key == "VIP" then
		vipPass = pass
	end
end

-- Income and storage-cap multipliers for a plot: VIP pass and house perks stack
local function plotMultipliers(plot)
	local income, storage = 1, 1
	local owner = Players:GetPlayerByUserId(plot:GetAttribute("OwnerUserId"))
	if vipPass and owner and owner:GetAttribute("Pass_" .. vipPass.Key) then
		income *= vipPass.IncomeMultiplier
	end
	local trim = HouseBuilder.PerkFor(plot, "Trim")
	if trim then
		income *= trim.IncomeMultiplier
	end
	local roof = HouseBuilder.PerkFor(plot, "Roof")
	if roof then
		storage *= roof.StorageMultiplier
	end
	return income, storage
end

local function updatePad(pad, incomeMultiplier, storageMultiplier)
	if not pad:GetAttribute("Occupied") then
		return
	end

	local charData = CharacterData.Items[pad:GetAttribute("CharacterId")]
	if not charData then
		return
	end

	local income = charData.Income * incomeMultiplier
	local maxStorage = income * GameConfig.MAX_STORAGE_SECONDS * storageMultiplier
	local stored = math.min(
		pad:GetAttribute("StoredValue") + income * GameConfig.INCOME_TICK,
		maxStorage
	)
	pad:SetAttribute("StoredValue", stored)

	local model = pad:FindFirstChild("CharacterModel")
	local info = model and model.PrimaryPart and model.PrimaryPart:FindFirstChild("Info")
	local valueLabel = info and info:FindFirstChild("ValueLabel")
	if valueLabel then
		valueLabel.Text = math.floor(stored) .. " coins"
		valueLabel.TextColor3 = stored >= maxStorage and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(255, 220, 0)
	end
end

while true do
	task.wait(GameConfig.INCOME_TICK)
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		local pads = plot:FindFirstChild("Pads")
		if pads then
			local incomeMultiplier, storageMultiplier = plotMultipliers(plot)
			for _, pad in ipairs(pads:GetChildren()) do
				updatePad(pad, incomeMultiplier, storageMultiplier)
			end
		end
	end
end
