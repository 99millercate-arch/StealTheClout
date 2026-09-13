# Steal The Clout

A Roblox "steal-a-brainrot"-style tycoon built around **internet-streamer culture** characters:
you hatch characters from eggs, place them on pads at your plot where they generate coins,
and other players can walk up and **steal** them if you don't collect in time.

## About the characters (read this first)

The roster is **original parody characters** ("Ring Light Goblin", "Diamond Play Button Wizard",
"The Final Boss Streamer") — deliberately *not* real streamers or YouTubers.

Using a real creator's name, face, or avatar in a monetized game without permission runs into
right-of-publicity and trademark problems, and Roblox moderation regularly takes down experiences
that do it. The original *Steal a Brainrot* avoids this the same way — its characters are fictional
meme creatures, not real people. If you want actual named creators in the game, get written
permission from each of them (or their management) first.

You can rename/restyle the whole roster in one file: `src/ReplicatedStorage/Modules/CharacterData.lua`.

## Gameplay loop

1. Spawn in, get auto-assigned an empty plot (12 plots, 4 pads each).
2. Buy an egg — at the yellow shop stall (hold E) or via the shop panel in the top-right UI.
3. Eggs roll a random character weighted by rarity: Common → Rare → Epic → Legendary → Mythic → Secret.
4. Click a character in your inventory bar, then click an empty pad on your plot to place it.
5. Placed characters generate coins into local storage (capped at 120 seconds of income).
6. Walk up to your own character and hold E to **collect** the stored coins — banking them safely.
7. Anyone else who holds E on your character **steals** it outright, plus whatever you failed to collect.

That last step is the whole game: uncollected income is the risk, and full storage bars
(the value label turns red at cap) are what thieves hunt for.

## Setup

### Option A — Rojo (recommended)

```bash
rojo serve
```

Then connect from the Rojo plugin inside Roblox Studio. `default.project.json` maps
`src/` onto the right services. Press Play — the map, remotes, and UI all build themselves at runtime.

### Option B — Generated place file (no Rojo)

```bash
bash scripts/gen-rbxlx.sh
```

Builds `build/StealTheClout.rbxlx` straight from `src/` with every script in the right service and
instance type. Open it in Studio and press Play. Re-run after editing `src/` (needs Git Bash on Windows).

### Option C — Manual (no tooling)

Create these instances in Studio and paste in each file's contents. **Instance type matters:**

| Studio path | Instance type | File |
|---|---|---|
| `ReplicatedStorage/Modules/CharacterData` | ModuleScript | `src/ReplicatedStorage/Modules/CharacterData.lua` |
| `ReplicatedStorage/Modules/GameConfig` | ModuleScript | `src/ReplicatedStorage/Modules/GameConfig.lua` |
| `ReplicatedStorage/Modules/Remotes` | ModuleScript | `src/ReplicatedStorage/Modules/Remotes.lua` |
| `ReplicatedStorage/Modules/CharacterModelBuilder` | ModuleScript | `src/ReplicatedStorage/Modules/CharacterModelBuilder.lua` |
| `ServerScriptService/Modules/PlayerState` | ModuleScript | `src/ServerScriptService/Modules/PlayerState.lua` |
| `ServerScriptService/Modules/DataManager` | ModuleScript | `src/ServerScriptService/Modules/DataManager.lua` |
| `ServerScriptService/Modules/PlotManager` | ModuleScript | `src/ServerScriptService/Modules/PlotManager.lua` |
| `ServerScriptService/Modules/PlacementService` | ModuleScript | `src/ServerScriptService/Modules/PlacementService.lua` |
| `ServerScriptService/MapBuilder` | Script | `src/ServerScriptService/MapBuilder.server.lua` |
| `ServerScriptService/PlayerSetup` | Script | `src/ServerScriptService/PlayerSetup.server.lua` |
| `ServerScriptService/PlacementHandler` | Script | `src/ServerScriptService/PlacementHandler.server.lua` |
| `ServerScriptService/EggService` | Script | `src/ServerScriptService/EggService.server.lua` |
| `ServerScriptService/IncomeLoop` | Script | `src/ServerScriptService/IncomeLoop.server.lua` |
| `StarterPlayer/StarterPlayerScripts/ClientUI` | LocalScript | `src/StarterPlayer/StarterPlayerScripts/ClientUI.client.lua` |

The `.server` / `.client` suffixes are Rojo conventions for Script vs LocalScript — drop them when naming instances manually.

Nothing needs to be built by hand in Workspace: `MapBuilder` generates the ground, 12 plots with
pads and nameplates, the shop stall, and the spawn point on server start. Delete Studio's default
Baseplate and SpawnLocation so they don't overlap.

Saving requires **Studio Access to API Services** enabled in Game Settings > Security, otherwise
DataStore calls fail (harmlessly — they're pcall-wrapped and just warn).

## Tuning

Everything numeric lives in `src/ReplicatedStorage/Modules/GameConfig.lua`:

- `STEAL_HOLD_TIME` — how long the E-hold takes (3s). Lower = more chaos.
- `MAX_STORAGE_SECONDS` — income cap per character (120s). Lower = must collect more often.
- `PADS_PER_PLOT` / `NUM_PLOTS` — plot capacity and server capacity.
- `EGGS` — costs and per-rarity odds for Basic (50) and Premium (500).

Character stats and colors live in `CharacterData.lua`. Adding a character is one table entry;
rarity pools and egg odds pick it up automatically.

## Known limitations / next steps

- **Placeholder art.** Characters are a neon cube + accent sphere with a name billboard.
  Swap `CharacterModelBuilder.Create` to clone real rigs from `ReplicatedStorage` once you have models.
- **No offline earnings.** Placed characters and their stored value persist across sessions,
  but don't tick while you're gone.
- **Plots aren't sticky.** You get the first free plot on join, not the same one as last session.
- **ProximityPrompt trust.** Roblox validates prompt range server-side, but a determined exploiter
  can still spam triggers. Add a server-side distance re-check in `PlacementService.onPromptTriggered`
  before shipping publicly.
- **No steal cooldown or protection window.** Consider a grace period after placing, or a
  per-thief cooldown, if testing shows spawn-camping.
- Obvious next features: trading, a character index/collection book, rebirths, gamepass eggs,
  a "lock pad" upgrade that slows steals.
