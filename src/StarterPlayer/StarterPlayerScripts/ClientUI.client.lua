local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local Modules = ReplicatedStorage:WaitForChild("Modules")
local CharacterData = require(Modules.CharacterData)
local GameConfig = require(Modules.GameConfig)
local Remotes = require(Modules.Remotes)

local inventory = {}
local placingCharacterId = nil

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(0, 220, 0, 50)
coinsLabel.Position = UDim2.new(0, 20, 0, 20)
coinsLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
coinsLabel.BackgroundTransparency = 0.25
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextScaled = true
coinsLabel.TextColor3 = Color3.fromRGB(255, 220, 0)
coinsLabel.Text = "0 coins"
coinsLabel.Parent = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 520, 0, 36)
statusLabel.Position = UDim2.new(0.5, -260, 0, 80)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextScaled = true
statusLabel.TextStrokeTransparency = 0.4
statusLabel.TextColor3 = Color3.new(1, 1, 1)
statusLabel.Text = ""
statusLabel.Parent = screenGui

local statusToken = 0
local function setStatus(text, color, duration)
	statusToken += 1
	local token = statusToken
	statusLabel.Text = text
	statusLabel.TextColor3 = color or Color3.new(1, 1, 1)
	if duration then
		task.delay(duration, function()
			if statusToken == token then
				statusLabel.Text = ""
			end
		end)
	end
end

local leaderstats = player:WaitForChild("leaderstats")
local coins = leaderstats:WaitForChild("Coins")
local function updateCoins()
	coinsLabel.Text = coins.Value .. " coins"
end
coins.Changed:Connect(updateCoins)
updateCoins()

local inventoryFrame = Instance.new("Frame")
inventoryFrame.Size = UDim2.new(1, -40, 0, 96)
inventoryFrame.Position = UDim2.new(0, 20, 1, -116)
inventoryFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
inventoryFrame.BackgroundTransparency = 0.25
inventoryFrame.Parent = screenGui

local inventoryPadding = Instance.new("UIPadding")
inventoryPadding.PaddingLeft = UDim.new(0, 8)
inventoryPadding.PaddingTop = UDim.new(0, 6)
inventoryPadding.Parent = inventoryFrame

local inventoryLayout = Instance.new("UIListLayout")
inventoryLayout.FillDirection = Enum.FillDirection.Horizontal
inventoryLayout.Padding = UDim.new(0, 8)
inventoryLayout.Parent = inventoryFrame

local emptyLabel = Instance.new("TextLabel")
emptyLabel.Name = "EmptyLabel"
emptyLabel.Size = UDim2.new(0, 420, 0, 80)
emptyLabel.BackgroundTransparency = 1
emptyLabel.Font = Enum.Font.Gotham
emptyLabel.TextScaled = true
emptyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
emptyLabel.Text = "Buy an egg to get your first character"
emptyLabel.Parent = inventoryFrame

local function refreshInventory()
	for _, child in ipairs(inventoryFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	emptyLabel.Visible = #inventory == 0

	for _, characterId in ipairs(inventory) do
		local charData = CharacterData.Items[characterId]
		if charData then
			local button = Instance.new("TextButton")
			button.Size = UDim2.new(0, 110, 0, 80)
			button.BackgroundColor3 = charData.Color
			button.Font = Enum.Font.GothamBold
			button.TextScaled = true
			button.TextWrapped = true
			button.TextColor3 = Color3.new(1, 1, 1)
			button.TextStrokeTransparency = 0.5
			button.Text = charData.Name .. "\n+" .. charData.Income .. "/s"
			button.Parent = inventoryFrame

			button.MouseButton1Click:Connect(function()
				placingCharacterId = characterId
				setStatus("Click an empty pad on YOUR plot to place " .. charData.Name, Color3.fromRGB(120, 255, 120))
			end)
		end
	end
end

Remotes.InventoryUpdated.OnClientEvent:Connect(function(newInventory)
	inventory = newInventory
	refreshInventory()
end)

refreshInventory()
task.spawn(function()
	inventory = Remotes.RequestInventory:InvokeServer()
	refreshInventory()
end)

Remotes.StolenNotice.OnClientEvent:Connect(function(thiefName, characterName, amount)
	setStatus(thiefName .. " stole your " .. characterName .. " and " .. amount .. " coins!", Color3.fromRGB(255, 70, 70), 5)
end)

local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.new(0, 240, 0, 140)
shopFrame.Position = UDim2.new(1, -260, 0, 20)
shopFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
shopFrame.BackgroundTransparency = 0.25
shopFrame.Parent = screenGui

local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 8)
shopLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
shopLayout.VerticalAlignment = Enum.VerticalAlignment.Center
shopLayout.Parent = shopFrame

local function createEggButton(eggName)
	local egg = GameConfig.EGGS[eggName]

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 216, 0, 54)
	button.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Text = eggName .. " Egg\n" .. egg.Cost .. " coins"
	button.Parent = shopFrame

	button.MouseButton1Click:Connect(function()
		button.Active = false
		local ok, result = pcall(function()
			return Remotes.BuyEgg:InvokeServer(eggName)
		end)
		button.Active = true

		if ok and result and result.success then
			local charData = CharacterData.Items[result.characterId]
			setStatus("You hatched: " .. (charData and charData.Name or "???"), charData and charData.Color, 4)
		else
			setStatus((result and result.reason) or "Purchase failed", Color3.fromRGB(255, 120, 120), 3)
		end
	end)
end

createEggButton("Basic")
createEggButton("Premium")

local mouse = player:GetMouse()
mouse.Button1Down:Connect(function()
	if not placingCharacterId then
		return
	end

	local target = mouse.Target
	if not target or target:GetAttribute("PadIndex") == nil then
		return
	end

	if target:GetAttribute("Occupied") then
		setStatus("That pad is already taken", Color3.fromRGB(255, 120, 120), 2)
		return
	end

	Remotes.PlaceCharacter:FireServer(
		placingCharacterId,
		target:GetAttribute("PlotIndex"),
		target:GetAttribute("PadIndex")
	)
	placingCharacterId = nil
	statusLabel.Text = ""
end)
