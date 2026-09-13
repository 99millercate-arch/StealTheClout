return {
	NUM_PLOTS = 12,
	PLOTS_PER_ROW = 4,
	PLOT_SPACING = 40,
	PLOT_SIZE = Vector3.new(24, 1, 24),
	PADS_PER_PLOT = 4,
	PAD_SIZE = Vector3.new(5, 1, 5),
	PAD_SPACING = 8,

	STEAL_HOLD_TIME = 3,
	MAX_STORAGE_SECONDS = 120,
	INCOME_TICK = 1,

	EGGS = {
		Basic = {
			Cost = 50,
			Odds = { Common = 60, Rare = 25, Epic = 10, Legendary = 4, Mythic = 0.9, Secret = 0.1 },
		},
		Premium = {
			Cost = 500,
			Odds = { Common = 30, Rare = 30, Epic = 25, Legendary = 10, Mythic = 4.5, Secret = 0.5 },
		},
	},

	-- Ways to keep your clout safe (all bought with coins)
	PROTECTION = {
		-- Seconds after placing (or rejoining) during which a character can't be stolen
		PLACE_GRACE_SECONDS = 30,

		-- Plot Shield: nothing on the plot can be stolen while it's up
		SHIELD = {
			Cost = 200,
			Duration = 60,
			Cooldown = 120, -- measured from activation, so effectively 60s of downtime
		},

		-- Pad Lock: a thief must hold E (Level) extra times to crack it before a steal lands.
		-- Lock HP refills if nobody attacks it for ResetSeconds.
		PAD_LOCK = {
			MaxLevel = 3,
			Costs = { 150, 400, 1000 }, -- cost to go 0->1, 1->2, 2->3
			ResetSeconds = 20,
		},
	},

	-- Robux purchases. Ids are 0 until you create them on the Creator Dashboard
	-- (Monetization > Developer Products / Passes) and paste the ids here.
	-- The UI shows them as "Coming soon" while the id is 0.
	MONETIZATION = {
		-- Developer Products: consumable, granted in Monetization.server.lua ProcessReceipt
		Products = {
			{ Key = "Coins500", Id = 0, Name = "500 Coins", Coins = 500 },
			{ Key = "Coins2500", Id = 0, Name = "2,500 Coins", Coins = 2500 },
			{ Key = "Coins10000", Id = 0, Name = "10,000 Coins", Coins = 10000 },
			{ Key = "MegaShield", Id = 0, Name = "5 min Shield", ShieldSeconds = 300 },
		},

		-- Game Passes: permanent. Owned passes are mirrored as Player attributes "Pass_<Key>".
		Passes = {
			{ Key = "VIP", Id = 0, Name = "VIP: 2x Income", Description = "All your characters earn double.", IncomeMultiplier = 2 },
			{ Key = "AutoCollect", Id = 0, Name = "Auto-Collect", Description = "Your plot banks its coins automatically every minute.", Interval = 60 },
			{ Key = "LuckyEggs", Id = 0, Name = "Lucky Eggs", Description = "Double the odds of Legendary, Mythic and Secret hatches.", RareOddsMultiplier = 2 },
		},
	},
}
