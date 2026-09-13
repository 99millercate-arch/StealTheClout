local PlayerState = {}

local states = {}

function PlayerState.Init(player, inventory)
	states[player] = { Inventory = inventory or {} }
end

function PlayerState.Get(player)
	return states[player]
end

function PlayerState.AddItem(player, characterId)
	local state = states[player]
	if not state then
		return
	end
	table.insert(state.Inventory, characterId)
end

function PlayerState.RemoveItem(player, characterId)
	local state = states[player]
	if not state then
		return false
	end
	for index, id in ipairs(state.Inventory) do
		if id == characterId then
			table.remove(state.Inventory, index)
			return true
		end
	end
	return false
end

function PlayerState.Clear(player)
	states[player] = nil
end

return PlayerState
