local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DEFINITIONS = {
	BuyEgg = "RemoteFunction",
	RequestInventory = "RemoteFunction",
	PlaceCharacter = "RemoteEvent",
	InventoryUpdated = "RemoteEvent",
	StolenNotice = "RemoteEvent",
}

local remotes = {}

if RunService:IsServer() then
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	for name, className in pairs(DEFINITIONS) do
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new(className)
			remote.Name = name
			remote.Parent = folder
		end
		remotes[name] = remote
	end
else
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	for name in pairs(DEFINITIONS) do
		remotes[name] = folder:WaitForChild(name)
	end
end

return remotes
