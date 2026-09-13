local Rarities = {
	Common = { Order = 1, Color = Color3.fromRGB(190, 190, 190) },
	Rare = { Order = 2, Color = Color3.fromRGB(30, 144, 255) },
	Epic = { Order = 3, Color = Color3.fromRGB(170, 0, 255) },
	Legendary = { Order = 4, Color = Color3.fromRGB(255, 170, 0) },
	Mythic = { Order = 5, Color = Color3.fromRGB(255, 0, 64) },
	Secret = { Order = 6, Color = Color3.fromRGB(20, 20, 20) },
}

-- Original parody "internet clout" characters -- intentionally NOT real people,
-- to avoid right-of-publicity / likeness issues. Swap freely for your own IP.
local Items = {
	ring_light_goblin = { Name = "Ring Light Goblin", Rarity = "Common", Income = 1, Color = Color3.fromRGB(170, 170, 170), AccentColor = Color3.fromRGB(220, 220, 220) },
	subscribe_beggar = { Name = "Subscribe Beggar", Rarity = "Common", Income = 1, Color = Color3.fromRGB(150, 150, 150), AccentColor = Color3.fromRGB(255, 255, 255) },
	livestream_gremlin = { Name = "Livestream Gremlin", Rarity = "Common", Income = 1, Color = Color3.fromRGB(110, 130, 110), AccentColor = Color3.fromRGB(150, 170, 150) },

	ratio_king = { Name = "Ratio King", Rarity = "Rare", Income = 3, Color = Color3.fromRGB(30, 144, 255), AccentColor = Color3.fromRGB(0, 80, 200) },
	clout_chaser_9000 = { Name = "Clout Chaser 9000", Rarity = "Rare", Income = 3, Color = Color3.fromRGB(0, 170, 255), AccentColor = Color3.fromRGB(0, 100, 180) },
	donation_goal_yeti = { Name = "Donation Goal Yeti", Rarity = "Rare", Income = 3, Color = Color3.fromRGB(120, 190, 255), AccentColor = Color3.fromRGB(255, 255, 255) },

	diamond_play_button_wizard = { Name = "Diamond Play Button Wizard", Rarity = "Epic", Income = 8, Color = Color3.fromRGB(170, 0, 255), AccentColor = Color3.fromRGB(100, 255, 255) },
	one_v_one_titan = { Name = "1v1 Me Bro Titan", Rarity = "Epic", Income = 8, Color = Color3.fromRGB(150, 0, 200), AccentColor = Color3.fromRGB(255, 0, 0) },
	mod_abuse_overlord = { Name = "Mod Abuse Overlord", Rarity = "Epic", Income = 8, Color = Color3.fromRGB(120, 0, 160), AccentColor = Color3.fromRGB(255, 215, 0) },

	verified_checkmark_demon = { Name = "Verified Checkmark Demon", Rarity = "Legendary", Income = 18, Color = Color3.fromRGB(255, 170, 0), AccentColor = Color3.fromRGB(0, 120, 255) },
	algorithm_whisperer = { Name = "Algorithm Whisperer", Rarity = "Legendary", Income = 18, Color = Color3.fromRGB(255, 140, 0), AccentColor = Color3.fromRGB(0, 255, 150) },
	sponsor_read_sorcerer = { Name = "Sponsor Read Sorcerer", Rarity = "Legendary", Income = 18, Color = Color3.fromRGB(255, 120, 0), AccentColor = Color3.fromRGB(150, 255, 0) },

	ban_hammer_deity = { Name = "Ban Hammer Deity", Rarity = "Mythic", Income = 40, Color = Color3.fromRGB(255, 0, 64), AccentColor = Color3.fromRGB(255, 255, 255) },
	viral_clip_phoenix = { Name = "Viral Clip Phoenix", Rarity = "Mythic", Income = 40, Color = Color3.fromRGB(255, 60, 0), AccentColor = Color3.fromRGB(255, 200, 0) },

	final_boss_streamer = { Name = "The Final Boss Streamer", Rarity = "Secret", Income = 100, Color = Color3.fromRGB(10, 10, 10), AccentColor = Color3.fromRGB(255, 0, 255) },
}

local byRarity = {}
for id, data in pairs(Items) do
	byRarity[data.Rarity] = byRarity[data.Rarity] or {}
	table.insert(byRarity[data.Rarity], id)
end

return {
	Items = Items,
	Rarities = Rarities,
	ByRarity = byRarity,
}
