local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local CharacterData = require(Modules.CharacterData)
local CharacterModelBuilder = require(Modules.CharacterModelBuilder)
local GameConfig = require(Modules.GameConfig)
local Remotes = require(Modules.Remotes)

local PlayerState = require(script.Parent.PlayerState)
local ProtectionService = require(script.Parent.ProtectionService)

local PlacementService = {}

function PlacementService.ClearPad(pad)
	local model = pad:FindFirstChild("CharacterModel")
	if model then
		model:Destroy()
	end
	pad:SetAttribute("Occupied", false)
	pad:SetAttribute("CharacterId", "")
	pad:SetAttribute("StoredValue", 0)
	pad:SetAttribute("PlacedAt", 0)
end

-- Banks whatever the pad has stored into the owner's coins. Used by the owner's E-hold
-- and by the Auto-Collect pass.
function PlacementService.CollectPad(pad, owner)
	local leaderstats = owner:FindFirstChild("leaderstats")
	if not leaderstats or not pad:GetAttribute("Occupied") then
		return 0
	end
	local amount = math.floor(pad:GetAttribute("StoredValue"))
	leaderstats.Coins.Value += amount
	pad:SetAttribute("StoredValue", 0)
	return amount
end

local function onPromptTriggered(plot, pad, triggeringPlayer)
	if not pad:GetAttribute("Occupied") then
		return
	end

	local leaderstats = triggeringPlayer:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local storedValue = math.floor(pad:GetAttribute("StoredValue"))
	local characterId = pad:GetAttribute("CharacterId")
	local ownerUserId = plot:GetAttribute("OwnerUserId")

	if triggeringPlayer.UserId == ownerUserId then
		PlacementService.CollectPad(pad, triggeringPlayer)
		return
	end

	if not PlayerState.Get(triggeringPlayer) then
		return
	end

	if not ProtectionService.TrySteal(plot, pad, triggeringPlayer) then
		return
	end

	leaderstats.Coins.Value += storedValue
	PlayerState.AddItem(triggeringPlayer, characterId)
	Remotes.InventoryUpdated:FireClient(triggeringPlayer, PlayerState.Get(triggeringPlayer).Inventory)

	local victim = Players:GetPlayerByUserId(ownerUserId)
	if victim then
		local charData = CharacterData.Items[characterId]
		Remotes.StolenNotice:FireClient(victim, triggeringPlayer.Name, charData and charData.Name or "a character", storedValue)
	end

	PlacementService.ClearPad(pad)
	ProtectionService.OnPadStolen(pad)
end

function PlacementService.SpawnCharacterOnPad(plot, pad, characterId, storedValue)
	local charData = CharacterData.Items[characterId]
	if not charData then
		return
	end

	PlacementService.ClearPad(pad)

	local model = CharacterModelBuilder.Create(charData)
	model.Name = "CharacterModel"
	model.Parent = pad
	model:PivotTo(pad.CFrame * CFrame.new(0, 2, 0))

	pad:SetAttribute("Occupied", true)
	pad:SetAttribute("CharacterId", characterId)
	pad:SetAttribute("StoredValue", storedValue or 0)
	pad:SetAttribute("PlacedAt", workspace:GetServerTimeNow()) -- starts the anti-steal grace window

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = charData.Name
	prompt.ActionText = "Collect / Steal"
	prompt.HoldDuration = GameConfig.STEAL_HOLD_TIME
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = Vector2.new(0, 30) -- push the prompt down, away from the Info billboard
	prompt.Parent = model.PrimaryPart

	prompt.Triggered:Connect(function(triggeringPlayer)
		onPromptTriggered(plot, pad, triggeringPlayer)
	end)
end

return PlacementService
