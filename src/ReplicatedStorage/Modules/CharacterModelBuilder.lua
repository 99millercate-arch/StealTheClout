local CharacterModelBuilder = {}

function CharacterModelBuilder.Create(charData)
	local model = Instance.new("Model")
	model.Name = charData.Name

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(2, 2, 2)
	base.Color = charData.Color
	base.Material = Enum.Material.Neon
	base.Anchored = true
	base.CanCollide = false
	base.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Color = charData.AccentColor
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = base.CFrame * CFrame.new(0, 1.8, 0)
	head.Parent = model

	model.PrimaryPart = base

	if charData.Rarity == "Mythic" or charData.Rarity == "Secret" then
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = charData.AccentColor
		sparkles.Parent = base
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Info"
	billboard.Size = UDim2.new(0, 160, 0, 60)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = base

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = billboard

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 22)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = charData.Name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.LayoutOrder = 1
	nameLabel.Parent = billboard

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, 0, 0, 16)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = charData.Rarity
	rarityLabel.TextColor3 = charData.Color
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.TextScaled = true
	rarityLabel.LayoutOrder = 2
	rarityLabel.Parent = billboard

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(1, 0, 0, 18)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "0 coins"
	valueLabel.TextColor3 = Color3.fromRGB(255, 220, 0)
	valueLabel.TextStrokeTransparency = 0
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextScaled = true
	valueLabel.LayoutOrder = 3
	valueLabel.Parent = billboard

	return model
end

return CharacterModelBuilder
