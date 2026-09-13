local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local CharacterData = require(Modules.CharacterData)
local Remotes = require(Modules.Remotes)

local ServerModules = script.Parent.Modules
local PlacementService = require(ServerModules.PlacementService)
local PlayerState = require(ServerModules.PlayerState)

local plotsFolder = workspace:WaitForChild("Plots")

Remotes.PlaceCharacter.OnServerEvent:Connect(function(player, characterId, plotIndex, padIndex)
	if typeof(characterId) ~= "string" or typeof(plotIndex) ~= "number" or typeof(padIndex) ~= "number" then
		return
	end
	if not CharacterData.Items[characterId] then
		return
	end

	local plot = plotsFolder:FindFirstChild("Plot" .. plotIndex)
	if not plot or plot:GetAttribute("OwnerUserId") ~= player.UserId then
		return
	end

	local pads = plot:FindFirstChild("Pads")
	local pad = pads and pads:FindFirstChild("Pad" .. padIndex)
	if not pad or pad:GetAttribute("Occupied") then
		return
	end

	if not PlayerState.RemoveItem(player, characterId) then
		return
	end

	PlacementService.SpawnCharacterOnPad(plot, pad, characterId, 0)
	Remotes.InventoryUpdated:FireClient(player, PlayerState.Get(player).Inventory)
end)
