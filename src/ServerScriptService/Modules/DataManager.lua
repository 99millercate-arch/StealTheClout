local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("StealTheClout_PlayerData_v1")

local DataManager = {}

function DataManager.Load(player)
	local success, result = pcall(function()
		return store:GetAsync("Player_" .. player.UserId)
	end)

	if success and type(result) == "table" then
		result.Coins = result.Coins or 0
		result.Inventory = result.Inventory or {}
		result.Placed = result.Placed or {}
		return result
	end

	if not success then
		warn("Failed to load data for " .. player.Name .. ": " .. tostring(result))
	end

	return { Coins = 100, Inventory = {}, Placed = {} }
end

function DataManager.Save(player, data)
	local success, err = pcall(function()
		store:SetAsync("Player_" .. player.UserId, data)
	end)
	if not success then
		warn("Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
end

return DataManager
