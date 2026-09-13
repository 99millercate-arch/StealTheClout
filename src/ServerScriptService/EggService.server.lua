local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local CharacterData = require(Modules.CharacterData)
local GameConfig = require(Modules.GameConfig)
local Remotes = require(Modules.Remotes)

local PlayerState = require(script.Parent.Modules.PlayerState)

local function rollRarity(odds)
	local total = 0
	for _, weight in pairs(odds) do
		total += weight
	end

	local roll = math.random() * total
	local cumulative = 0
	for rarity, weight in pairs(odds) do
		cumulative += weight
		if roll <= cumulative then
			return rarity
		end
	end
	return "Common"
end

local luckyPass
for _, pass in ipairs(GameConfig.MONETIZATION.Passes) do
	if pass.Key == "LuckyEggs" then
		luckyPass = pass
	end
end

-- Lucky Eggs pass: scale up the top-tier weights before rolling
local function oddsFor(player, egg)
	if not (luckyPass and player:GetAttribute("Pass_" .. luckyPass.Key)) then
		return egg.Odds
	end
	local odds = table.clone(egg.Odds)
	for _, rarity in ipairs({ "Legendary", "Mythic", "Secret" }) do
		odds[rarity] = (odds[rarity] or 0) * luckyPass.RareOddsMultiplier
	end
	return odds
end

local function rollCharacter(player, egg)
	local pool = CharacterData.ByRarity[rollRarity(oddsFor(player, egg))]
	if not pool or #pool == 0 then
		return nil
	end
	return pool[math.random(1, #pool)]
end

local function attemptBuy(player, eggName)
	local egg = typeof(eggName) == "string" and GameConfig.EGGS[eggName] or nil
	if not egg then
		return { success = false, reason = "Unknown egg" }
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or leaderstats.Coins.Value < egg.Cost then
		return { success = false, reason = "Not enough coins" }
	end

	local state = PlayerState.Get(player)
	if not state then
		return { success = false, reason = "Still loading" }
	end

	local characterId = rollCharacter(player, egg)
	if not characterId then
		return { success = false, reason = "Roll failed" }
	end

	leaderstats.Coins.Value -= egg.Cost
	PlayerState.AddItem(player, characterId)
	Remotes.InventoryUpdated:FireClient(player, state.Inventory)

	return { success = true, characterId = characterId }
end

Remotes.BuyEgg.OnServerInvoke = function(player, eggName)
	return attemptBuy(player, eggName)
end

local stall = workspace:WaitForChild("Shop"):WaitForChild("EggShopStall")
stall:WaitForChild("BuyBasicEgg").Triggered:Connect(function(player)
	attemptBuy(player, "Basic")
end)
