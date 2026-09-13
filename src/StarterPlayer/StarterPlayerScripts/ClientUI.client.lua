local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

local Modules = ReplicatedStorage:WaitForChild("Modules")
local CharacterData = require(Modules.CharacterData)
local GameConfig = require(Modules.GameConfig)
local Remotes = require(Modules.Remotes)

local PROTECTION = GameConfig.PROTECTION
local MONETIZATION = GameConfig.MONETIZATION

local inventory = {}
local placingCharacterId = nil

-- Layout constants -------------------------------------------------------------
local PANEL_BG = Color3.fromRGB(15, 15, 20)
local PANEL_TRANSPARENCY = 0.2
local ACCENT = Color3.fromRGB(255, 200, 0)
local SHIELD_BLUE = Color3.fromRGB(80, 200, 255)
local ROBUX_GREEN = Color3.fromRGB(0, 200, 120)
local DISABLED_GREY = Color3.fromRGB(70, 70, 80)
local MARGIN = 16
local INVENTORY_HEIGHT = 96
local MENU_BUTTON = 64
local PANEL_WIDTH = 300
local PANEL_MAX_HEIGHT = 400

-- The coins HUD already shows the number that matters; the default player list just
-- fights with our panels for the top-right corner.
task.spawn(function()
	for _ = 1, 10 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
		end)
		if ok then
			return
		end
		task.wait(0.5)
	end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Small builders so the layout code below stays readable ----------------------------

local function makeFrame(parent, size, position, anchor)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.AnchorPoint = anchor or Vector2.new(0, 0)
	frame.BackgroundColor3 = PANEL_BG
	frame.BackgroundTransparency = PANEL_TRANSPARENCY
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	return frame
end

local function makeLabel(parent, text, height, options)
	options = options or {}
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, height)
	label.BackgroundTransparency = 1
	label.Font = options.font or Enum.Font.Gotham
	label.TextScaled = options.scaled ~= false
	label.TextWrapped = true
	label.TextColor3 = options.color or Color3.fromRGB(220, 220, 220)
	label.TextXAlignment = options.align or Enum.TextXAlignment.Center
	label.Text = text
	label.LayoutOrder = options.order or 0
	label.Parent = parent
	return label
end

local function makeButton(parent, text, height, color, onClick)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, height)
	button.BackgroundColor3 = color
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.TextWrapped = true
	button.TextColor3 = Color3.fromRGB(20, 20, 20)
	button.Text = text
	button.AutoButtonColor = true
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = button

	if onClick then
		button.MouseButton1Click:Connect(onClick)
	end
	return button
end

local function setButtonEnabled(button, enabled, color)
	button.Active = enabled
	button.AutoButtonColor = enabled
	button.BackgroundColor3 = enabled and color or DISABLED_GREY
	button.TextColor3 = enabled and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(170, 170, 170)
end

local function makeList(parent, padding)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, padding or 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = parent
	return layout
end

-- HUD: coins + shield status (top-left), status line (top-centre) -------------------

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(0, 220, 0, 50)
coinsLabel.Position = UDim2.new(0, MARGIN, 0, MARGIN)
coinsLabel.BackgroundColor3 = PANEL_BG
coinsLabel.BackgroundTransparency = PANEL_TRANSPARENCY
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextScaled = true
coinsLabel.TextColor3 = ACCENT
coinsLabel.Text = "0 coins"
coinsLabel.Parent = screenGui
Instance.new("UICorner", coinsLabel).CornerRadius = UDim.new(0, 10)

local shieldHud = Instance.new("TextLabel")
shieldHud.Size = UDim2.new(0, 220, 0, 28)
shieldHud.Position = UDim2.new(0, MARGIN, 0, MARGIN + 56)
shieldHud.BackgroundColor3 = PANEL_BG
shieldHud.BackgroundTransparency = PANEL_TRANSPARENCY
shieldHud.Font = Enum.Font.GothamBold
shieldHud.TextScaled = true
shieldHud.TextColor3 = SHIELD_BLUE
shieldHud.Text = ""
shieldHud.Visible = false
shieldHud.Parent = screenGui
Instance.new("UICorner", shieldHud).CornerRadius = UDim.new(0, 8)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 560, 0, 36)
statusLabel.Position = UDim2.new(0.5, 0, 0, MARGIN + 100)
statusLabel.AnchorPoint = Vector2.new(0.5, 0)
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

Remotes.Notify.OnClientEvent:Connect(function(text, color, duration)
	setStatus(text, color, duration or 3)
end)

Remotes.StolenNotice.OnClientEvent:Connect(function(thiefName, characterName, amount)
	setStatus(thiefName .. " stole your " .. characterName .. " and " .. amount .. " coins!", Color3.fromRGB(255, 70, 70), 5)
end)

-- Inventory bar (bottom) --------------------------------------------------------------

local inventoryFrame = makeFrame(
	screenGui,
	UDim2.new(1, -MARGIN * 2, 0, INVENTORY_HEIGHT),
	UDim2.new(0, MARGIN, 1, -MARGIN),
	Vector2.new(0, 1)
)

local inventoryPadding = Instance.new("UIPadding")
inventoryPadding.PaddingLeft = UDim.new(0, 8)
inventoryPadding.PaddingTop = UDim.new(0, 8)
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
			Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)

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

-- Side menu + panels (right edge, above the inventory bar) ----------------------------

local PANEL_BOTTOM_OFFSET = -(MARGIN + INVENTORY_HEIGHT + 12)

local menuColumn = Instance.new("Frame")
menuColumn.Size = UDim2.new(0, MENU_BUTTON, 0, MENU_BUTTON * 3 + 16)
menuColumn.Position = UDim2.new(1, -MARGIN, 1, PANEL_BOTTOM_OFFSET)
menuColumn.AnchorPoint = Vector2.new(1, 1)
menuColumn.BackgroundTransparency = 1
menuColumn.Parent = screenGui
makeList(menuColumn, 8)

local panels = {}
local menuButtons = {}
local openPanel = nil

local function setOpenPanel(name)
	openPanel = (openPanel ~= name) and name or nil
	for key, panel in pairs(panels) do
		panel.Visible = key == openPanel
		menuButtons[key].BackgroundColor3 = key == openPanel and ACCENT or PANEL_BG
		menuButtons[key].TextColor3 = key == openPanel and Color3.fromRGB(20, 20, 20) or Color3.new(1, 1, 1)
	end
end

local function makePanel(name, title, icon, order)
	local panel = makeFrame(
		screenGui,
		UDim2.new(0, PANEL_WIDTH, 0, PANEL_MAX_HEIGHT),
		UDim2.new(1, -(MARGIN + MENU_BUTTON + 12), 1, PANEL_BOTTOM_OFFSET),
		Vector2.new(1, 1)
	)
	panel.Name = name .. "Panel"
	panel.Visible = false

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -44, 0, 40)
	header.Position = UDim2.new(0, 14, 0, 0)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextScaled = true
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextColor3 = ACCENT
	header.Text = title
	header.Parent = panel

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 32, 0, 32)
	close.Position = UDim2.new(1, -4, 0, 4)
	close.AnchorPoint = Vector2.new(1, 0)
	close.BackgroundTransparency = 1
	close.Font = Enum.Font.GothamBold
	close.TextScaled = true
	close.TextColor3 = Color3.fromRGB(200, 200, 200)
	close.Text = "X"
	close.Parent = panel
	close.MouseButton1Click:Connect(function()
		setOpenPanel(nil)
	end)

	local content = Instance.new("ScrollingFrame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -20, 1, -50)
	content.Position = UDim2.new(0, 10, 0, 44)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 4
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.new(0, 0, 0, 0)
	content.Parent = panel
	makeList(content, 8)

	local menuButton = Instance.new("TextButton")
	menuButton.Size = UDim2.new(0, MENU_BUTTON, 0, MENU_BUTTON)
	menuButton.BackgroundColor3 = PANEL_BG
	menuButton.BackgroundTransparency = PANEL_TRANSPARENCY
	menuButton.Font = Enum.Font.GothamBold
	menuButton.TextScaled = true
	menuButton.TextColor3 = Color3.new(1, 1, 1)
	menuButton.Text = icon .. "\n" .. name
	menuButton.LayoutOrder = order
	menuButton.Parent = menuColumn
	Instance.new("UICorner", menuButton).CornerRadius = UDim.new(0, 10)
	menuButton.MouseButton1Click:Connect(function()
		setOpenPanel(name)
	end)

	panels[name] = panel
	menuButtons[name] = menuButton
	return content
end

-- Keep panels on-screen when the viewport is short (phones in landscape)
local function fitPanels()
	local available = screenGui.AbsoluteSize.Y - (MARGIN * 2 + INVENTORY_HEIGHT + 12) - 60
	local height = math.clamp(available, 180, PANEL_MAX_HEIGHT)
	for _, panel in pairs(panels) do
		panel.Size = UDim2.new(0, PANEL_WIDTH, 0, height)
	end
end
screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitPanels)

-- Shop panel ---------------------------------------------------------------------

local shopContent = makePanel("Shop", "Egg Shop", "🥚", 1)
makeLabel(shopContent, "Hatch a random character. Rarer = more coins per second.", 36, { order = 1 })

local function oddsText(egg)
	local parts = {}
	for _, rarity in ipairs({ "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }) do
		if egg.Odds[rarity] and egg.Odds[rarity] > 0 then
			table.insert(parts, ("%s %s%%"):format(rarity, egg.Odds[rarity]))
		end
	end
	return table.concat(parts, "  ·  ")
end

local eggOrder = 2
for _, eggName in ipairs({ "Basic", "Premium" }) do
	local egg = GameConfig.EGGS[eggName]
	local button = makeButton(shopContent, eggName .. " Egg - " .. egg.Cost .. " coins", 52, ACCENT)
	button.LayoutOrder = eggOrder
	button.MouseButton1Click:Connect(function()
		setButtonEnabled(button, false, ACCENT)
		local ok, result = pcall(function()
			return Remotes.BuyEgg:InvokeServer(eggName)
		end)
		setButtonEnabled(button, true, ACCENT)

		if ok and result and result.success then
			local charData = CharacterData.Items[result.characterId]
			setStatus("You hatched: " .. (charData and charData.Name or "???"), charData and charData.Color, 4)
		else
			setStatus((result and result.reason) or "Purchase failed", Color3.fromRGB(255, 120, 120), 3)
		end
	end)
	makeLabel(shopContent, oddsText(egg), 30, { order = eggOrder + 1, color = Color3.fromRGB(160, 160, 170) })
	eggOrder += 2
end

-- Protect panel ------------------------------------------------------------------

local protectContent = makePanel("Protect", "Keep Your Clout Safe", "🛡", 2)
makeLabel(
	protectContent,
	("New placements are safe for %ds. Build your house for perks, shield your plot, and lock your pads."):format(
		PROTECTION.PLACE_GRACE_SECONDS
	),
	56,
	{ order = 1, color = Color3.fromRGB(180, 180, 190) }
)

local shieldButton = makeButton(protectContent, "", 56, SHIELD_BLUE)
shieldButton.LayoutOrder = 2
shieldButton.MouseButton1Click:Connect(function()
	if not shieldButton.Active then
		return
	end
	local ok, result = pcall(function()
		return Remotes.ActivateShield:InvokeServer()
	end)
	if ok and result and result.success then
		setStatus(("Shield up for %ds!"):format(result.duration or PROTECTION.SHIELD.Duration), SHIELD_BLUE, 3)
	else
		setStatus((result and result.reason) or "Couldn't activate shield", Color3.fromRGB(255, 120, 120), 3)
	end
end)

-- Your House: bought stage by stage, each with a perk
local BUILDING = GameConfig.BUILDING

-- Client-side mirror of HouseBuilder.PerkFor, driven by the replicated BuildLevel attribute
local function perkFor(plot, key)
	local level = plot and plot:GetAttribute("BuildLevel") or 0
	for index, stage in ipairs(BUILDING) do
		if stage.Key == key then
			return index <= level and stage or nil
		end
	end
	return nil
end

makeLabel(protectContent, "Your House", 30, { order = 3, font = Enum.Font.GothamBold, color = ACCENT, align = Enum.TextXAlignment.Left })

local stageLabels = {}
for index, stage in ipairs(BUILDING) do
	local label = makeLabel(protectContent, "", 36, { order = 3 + index, align = Enum.TextXAlignment.Left, scaled = false })
	label.TextSize = 14
	label.TextYAlignment = Enum.TextYAlignment.Top
	stageLabels[index] = label
end

local buildButton = makeButton(protectContent, "", 56, ACCENT)
buildButton.LayoutOrder = 4 + #BUILDING
buildButton.MouseButton1Click:Connect(function()
	if not buildButton.Active then
		return
	end
	local ok, result = pcall(function()
		return Remotes.BuyBuilding:InvokeServer()
	end)
	if ok and result and result.success then
		setStatus(("Built: %s!"):format(result.name), ACCENT, 3)
	else
		setStatus((result and result.reason) or "Couldn't build", Color3.fromRGB(255, 120, 120), 3)
	end
end)

makeLabel(protectContent, "Pad Locks", 30, { order = 20, font = Enum.Font.GothamBold, color = ACCENT, align = Enum.TextXAlignment.Left })

local lockRows = {}
for padIndex = 1, GameConfig.PADS_PER_PLOT do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundTransparency = 1
	row.LayoutOrder = 20 + padIndex
	row.Parent = protectContent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.5, -4, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(220, 220, 220)
	label.Text = ("Pad %d"):format(padIndex)
	label.Parent = row

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0.5, -4, 1, 0)
	button.Position = UDim2.new(0.5, 4, 0, 0)
	button.BackgroundColor3 = SHIELD_BLUE
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.TextColor3 = Color3.fromRGB(20, 20, 20)
	button.Text = ""
	button.Parent = row
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
	button.MouseButton1Click:Connect(function()
		if not button.Active then
			return
		end
		local ok, result = pcall(function()
			return Remotes.BuyPadLock:InvokeServer(padIndex)
		end)
		if ok and result and result.success then
			setStatus(("Pad %d lock upgraded to level %d"):format(padIndex, result.level), SHIELD_BLUE, 3)
		else
			setStatus((result and result.reason) or "Couldn't buy lock", Color3.fromRGB(255, 120, 120), 3)
		end
	end)

	lockRows[padIndex] = { label = label, button = button }
end

-- Robux panel --------------------------------------------------------------------

local robuxContent = makePanel("Robux", "Robux Store", "💎", 3)

local function passAttribute(pass)
	return "Pass_" .. pass.Key
end

makeLabel(robuxContent, "Coin Packs", 30, { order = 1, font = Enum.Font.GothamBold, color = ACCENT, align = Enum.TextXAlignment.Left })
local robuxOrder = 2
for _, product in ipairs(MONETIZATION.Products) do
	local configured = product.Id ~= 0
	local button = makeButton(robuxContent, configured and product.Name or (product.Name .. "\n(coming soon)"), 48, ROBUX_GREEN)
	button.LayoutOrder = robuxOrder
	setButtonEnabled(button, configured, ROBUX_GREEN)
	button.MouseButton1Click:Connect(function()
		if not configured then
			return
		end
		MarketplaceService:PromptProductPurchase(player, product.Id)
	end)
	robuxOrder += 1
end

makeLabel(robuxContent, "Passes", 30, { order = robuxOrder, font = Enum.Font.GothamBold, color = ACCENT, align = Enum.TextXAlignment.Left })
robuxOrder += 1

local passButtons = {}
for _, pass in ipairs(MONETIZATION.Passes) do
	local button = makeButton(robuxContent, "", 48, ROBUX_GREEN)
	button.LayoutOrder = robuxOrder
	button.MouseButton1Click:Connect(function()
		if not button.Active then
			return
		end
		MarketplaceService:PromptGamePassPurchase(player, pass.Id)
	end)
	makeLabel(robuxContent, pass.Description, 30, { order = robuxOrder + 1, color = Color3.fromRGB(160, 160, 170) })
	passButtons[pass.Key] = { button = button, pass = pass }
	robuxOrder += 2
end

local function refreshPassButtons()
	for _, entry in pairs(passButtons) do
		local pass = entry.pass
		local owned = player:GetAttribute(passAttribute(pass)) == true
		if owned then
			entry.button.Text = pass.Name .. " - OWNED"
			setButtonEnabled(entry.button, false, ROBUX_GREEN)
			entry.button.TextColor3 = ROBUX_GREEN
		elseif pass.Id == 0 then
			entry.button.Text = pass.Name .. "\n(coming soon)"
			setButtonEnabled(entry.button, false, ROBUX_GREEN)
		else
			entry.button.Text = pass.Name
			setButtonEnabled(entry.button, true, ROBUX_GREEN)
		end
	end
end
player.AttributeChanged:Connect(refreshPassButtons)
refreshPassButtons()

-- Live protection status (shield HUD/button + lock rows) -----------------------------

local plotsFolder = workspace:WaitForChild("Plots")

local function getMyPlot()
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:GetAttribute("OwnerUserId") == player.UserId then
			return plot
		end
	end
	return nil
end

local function refreshProtection()
	local plot = getMyPlot()
	local now = workspace:GetServerTimeNow()

	if not plot then
		shieldHud.Visible = false
		shieldButton.Text = "No plot yet"
		setButtonEnabled(shieldButton, false, SHIELD_BLUE)
		return
	end

	local door = perkFor(plot, "Door")
	local shieldCost = door and door.ShieldCost or PROTECTION.SHIELD.Cost
	local shieldDuration = door and door.ShieldDuration or PROTECTION.SHIELD.Duration

	local shieldLeft = (plot:GetAttribute("ShieldUntil") or 0) - now
	local cooldownLeft = (plot:GetAttribute("ShieldCooldownUntil") or 0) - now

	if shieldLeft > 0 then
		shieldHud.Visible = true
		shieldHud.Text = ("🛡 Shield: %ds"):format(math.ceil(shieldLeft))
		shieldButton.Text = ("Shield active (%ds)"):format(math.ceil(shieldLeft))
		setButtonEnabled(shieldButton, false, SHIELD_BLUE)
	elseif cooldownLeft > 0 then
		shieldHud.Visible = false
		shieldButton.Text = ("Shield recharging (%ds)"):format(math.ceil(cooldownLeft))
		setButtonEnabled(shieldButton, false, SHIELD_BLUE)
	else
		shieldHud.Visible = false
		shieldButton.Text = ("Activate Shield - %d coins (%ds)"):format(shieldCost, shieldDuration)
		setButtonEnabled(shieldButton, true, SHIELD_BLUE)
	end

	local level = plot:GetAttribute("BuildLevel") or 0
	for index, stage in ipairs(BUILDING) do
		local built = index <= level
		stageLabels[index].Text = ("%s %s - %s"):format(built and "[x]" or "[ ]", stage.Name, stage.Perk)
		stageLabels[index].TextColor3 = built and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(170, 170, 180)
	end
	local nextStage = BUILDING[level + 1]
	if nextStage then
		buildButton.Text = ("Build %s - %d coins"):format(nextStage.Name, nextStage.Cost)
		setButtonEnabled(buildButton, true, ACCENT)
	else
		buildButton.Text = "House complete!"
		setButtonEnabled(buildButton, false, ACCENT)
	end

	local pads = plot:FindFirstChild("Pads")
	for padIndex, row in ipairs(lockRows) do
		local pad = pads and pads:FindFirstChild("Pad" .. padIndex)
		local level = pad and pad:GetAttribute("LockLevel") or 0
		local hp = pad and pad:GetAttribute("LockHP") or 0
		row.label.Text = ("Pad %d  Lock %d/%d"):format(padIndex, hp, level)
		row.label.TextColor3 = (level > 0 and hp < level) and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(220, 220, 220)

		if level >= PROTECTION.PAD_LOCK.MaxLevel then
			row.button.Text = "MAX"
			setButtonEnabled(row.button, false, SHIELD_BLUE)
		else
			row.button.Text = ("Upgrade - %d"):format(PROTECTION.PAD_LOCK.Costs[level + 1])
			setButtonEnabled(row.button, true, SHIELD_BLUE)
		end
	end
end

task.spawn(function()
	while true do
		refreshProtection()
		task.wait(0.5)
	end
end)

fitPanels()

-- Placing characters on pads -----------------------------------------------------------

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
