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
}
