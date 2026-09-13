local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local CharacterData = require(Modules.CharacterData)
local GameConfig = require(Modules.GameConfig)

local plotsFolder = workspace:WaitForChild("Plots")

local function updatePad(pad)
	if not pad:GetAttribute("Occupied") then
		return
	end

	local charData = CharacterData.Items[pad:GetAttribute("CharacterId")]
	if not charData then
		return
	end

	local maxStorage = charData.Income * GameConfig.MAX_STORAGE_SECONDS
	local stored = math.min(
		pad:GetAttribute("StoredValue") + charData.Income * GameConfig.INCOME_TICK,
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
			for _, pad in ipairs(pads:GetChildren()) do
				updatePad(pad)
			end
		end
	end
end
