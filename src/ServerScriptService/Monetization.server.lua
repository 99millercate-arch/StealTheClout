-- Robux: Developer Product receipts and Game Pass ownership.
-- Product/pass definitions (and their ids) live in GameConfig.MONETIZATION.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local Remotes = require(Modules.Remotes)

local ServerModules = script.Parent.Modules
local PlacementService = require(ServerModules.PlacementService)
local PlotManager = require(ServerModules.PlotManager)
local ProtectionService = require(ServerModules.ProtectionService)

local MONETIZATION = GameConfig.MONETIZATION

local productsById = {}
for _, product in ipairs(MONETIZATION.Products) do
	if product.Id ~= 0 then
		productsById[product.Id] = product
	end
end

local passesById = {}
for _, pass in ipairs(MONETIZATION.Passes) do
	if pass.Id ~= 0 then
		passesById[pass.Id] = pass
	end
end

local function passAttribute(pass)
	return "Pass_" .. pass.Key
end

-- Developer Products -----------------------------------------------------------

-- Grants a product's effect. Returns true on success. Shared by ProcessReceipt and by
-- anything that wants to hand out a product for free (e.g. a test command).
local function grantProduct(player, product)
	if product.Coins then
		local leaderstats = player:FindFirstChild("leaderstats")
		if not leaderstats then
			return false
		end
		leaderstats.Coins.Value += product.Coins
		Remotes.Notify:FireClient(player, ("+%d coins!"):format(product.Coins), Color3.fromRGB(255, 220, 0), 4)
		return true
	end

	if product.ShieldSeconds then
		local plot = PlotManager.GetPlotByOwner(player)
		if not plot then
			return false
		end
		ProtectionService.GrantShield(plot, product.ShieldSeconds)
		Remotes.Notify:FireClient(player, ("Shield up for %d minutes!"):format(product.ShieldSeconds / 60), Color3.fromRGB(80, 200, 255), 4)
		return true
	end

	return false
end

-- Roblox retries ProcessReceipt until it returns PurchaseGranted, so the same PurchaseId can
-- arrive more than once (e.g. after a server hiccup). Remember the ones we've handled.
local processedReceipts = {}

MarketplaceService.ProcessReceipt = function(receiptInfo)
	if processedReceipts[receiptInfo.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local product = productsById[receiptInfo.ProductId]
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not product or not player then
		-- Unknown product or player left: let Roblox retry later / refund
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, granted = pcall(grantProduct, player, product)
	if not ok or not granted then
		warn(("Failed to grant %s to %s: %s"):format(product.Key, player.Name, tostring(granted)))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	processedReceipts[receiptInfo.PurchaseId] = true
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Game Passes ------------------------------------------------------------------

local function refreshPasses(player)
	for _, pass in ipairs(MONETIZATION.Passes) do
		local owns = false
		if pass.Id ~= 0 then
			local ok, result = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
			end)
			owns = ok and result == true
		end
		player:SetAttribute(passAttribute(pass), owns)
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	local pass = passesById[passId]
	if pass and purchased then
		player:SetAttribute(passAttribute(pass), true)
		Remotes.Notify:FireClient(player, pass.Name .. " unlocked!", Color3.fromRGB(120, 255, 120), 4)
	end
end)

Players.PlayerAdded:Connect(refreshPasses)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(refreshPasses, player)
end

-- Auto-Collect pass: bank every pad on the owner's plot on an interval
local autoCollect
for _, pass in ipairs(MONETIZATION.Passes) do
	if pass.Key == "AutoCollect" then
		autoCollect = pass
	end
end

if autoCollect then
	task.spawn(function()
		while true do
			task.wait(autoCollect.Interval)
			for _, player in ipairs(Players:GetPlayers()) do
				if player:GetAttribute(passAttribute(autoCollect)) then
					local plot = PlotManager.GetPlotByOwner(player)
					local total = 0
					if plot then
						for _, pad in ipairs(plot.Pads:GetChildren()) do
							total += PlacementService.CollectPad(pad, player)
						end
					end
					if total > 0 then
						Remotes.Notify:FireClient(player, ("Auto-collected %d coins"):format(total), Color3.fromRGB(255, 220, 0), 2)
					end
				end
			end
		end
	end)
end
