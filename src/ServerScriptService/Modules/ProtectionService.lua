-- Everything that stops (or slows) a steal: placement grace, plot shields, pad locks.
-- State lives in replicated attributes so the client UI can read it directly:
--   plot: ShieldUntil, ShieldCooldownUntil   (server time, see workspace:GetServerTimeNow())
--   pad:  PlacedAt, LockLevel, LockHP
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules.GameConfig)
local Remotes = require(Modules.Remotes)

local HouseBuilder = require(script.Parent.HouseBuilder)
local PlotManager = require(script.Parent.PlotManager)

local CONFIG = GameConfig.PROTECTION

local ProtectionService = {}

local lockResetTokens = {} -- pad -> token, so an old reset timer can't clobber a newer attack

local function now()
	return workspace:GetServerTimeNow()
end

local function notify(player, text, color, duration)
	Remotes.Notify:FireClient(player, text, color, duration)
end

-- Shield --------------------------------------------------------------------

local function buildDome(plot)
	local platform = plot:FindFirstChild("Platform")
	if not platform or plot:FindFirstChild("ShieldDome") then
		return
	end

	-- With a Door built, the shield is a barrier across the doorway instead of a dome
	local doorway = plot:FindFirstChild("Doorway", true)
	if doorway then
		local barrier = Instance.new("Part")
		barrier.Name = "ShieldDome"
		barrier.Size = doorway.Size + Vector3.new(0, 0, 0.2)
		barrier.CFrame = doorway.CFrame
		barrier.Anchored = true
		barrier.CanCollide = false
		barrier.CanQuery = false
		barrier.CastShadow = false
		barrier.Material = Enum.Material.Neon
		barrier.Color = Color3.fromRGB(80, 200, 255)
		barrier.Transparency = 0.55
		barrier.Parent = plot
		return
	end

	local dome = Instance.new("Part")
	dome.Name = "ShieldDome"
	dome.Shape = Enum.PartType.Ball
	local diameter = math.max(GameConfig.PLOT_SIZE.X, GameConfig.PLOT_SIZE.Z) * 1.4
	dome.Size = Vector3.new(diameter, diameter, diameter)
	dome.CFrame = platform.CFrame
	dome.Anchored = true
	dome.CanCollide = false
	dome.CanQuery = false
	dome.CastShadow = false
	dome.Material = Enum.Material.ForceField
	dome.Color = Color3.fromRGB(80, 200, 255)
	dome.Transparency = 0.4
	dome.Parent = plot
end

local function removeDome(plot)
	local dome = plot:FindFirstChild("ShieldDome")
	if dome then
		dome:Destroy()
	end
end

function ProtectionService.IsShielded(plot)
	return (plot:GetAttribute("ShieldUntil") or 0) > now()
end

-- Raises the shield for `seconds` without charging or checking cooldown (Robux product path)
function ProtectionService.GrantShield(plot, seconds)
	local until_ = math.max(plot:GetAttribute("ShieldUntil") or 0, now()) + seconds
	plot:SetAttribute("ShieldUntil", until_)
	buildDome(plot)

	task.delay(until_ - now(), function()
		if plot.Parent and not ProtectionService.IsShielded(plot) then
			removeDome(plot)
		end
	end)
end

-- Shield cost and duration for this plot, after house perks
function ProtectionService.ShieldTerms(plot)
	local door = HouseBuilder.PerkFor(plot, "Door")
	if door then
		return door.ShieldCost, door.ShieldDuration
	end
	return CONFIG.SHIELD.Cost, CONFIG.SHIELD.Duration
end

-- Placement grace for this plot, after house perks
function ProtectionService.GraceSeconds(plot)
	local walls = HouseBuilder.PerkFor(plot, "Walls")
	return CONFIG.PLACE_GRACE_SECONDS * (walls and walls.GraceMultiplier or 1)
end

local function activateShield(player)
	local plot = PlotManager.GetPlotByOwner(player)
	if not plot then
		return { success = false, reason = "You don't have a plot" }
	end
	if ProtectionService.IsShielded(plot) then
		return { success = false, reason = "Shield is already up" }
	end
	local cooldownUntil = plot:GetAttribute("ShieldCooldownUntil") or 0
	if cooldownUntil > now() then
		return { success = false, reason = ("Shield recharging (%ds)"):format(math.ceil(cooldownUntil - now())) }
	end

	local cost, duration = ProtectionService.ShieldTerms(plot)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or leaderstats.Coins.Value < cost then
		return { success = false, reason = "Not enough coins" }
	end

	leaderstats.Coins.Value -= cost
	plot:SetAttribute("ShieldCooldownUntil", now() + CONFIG.SHIELD.Cooldown)
	ProtectionService.GrantShield(plot, duration)
	return { success = true, duration = duration }
end

-- Pad locks -----------------------------------------------------------------

local PAD_BASE_COLOR = Color3.fromRGB(235, 225, 140)
local PAD_LOCKED_COLOR = Color3.fromRGB(120, 140, 200)

local function updateLockVisual(pad)
	local level = pad:GetAttribute("LockLevel") or 0
	local hp = pad:GetAttribute("LockHP") or 0

	pad.Color = level > 0 and PAD_LOCKED_COLOR or PAD_BASE_COLOR

	local gui = pad:FindFirstChild("LockGui")
	if level == 0 then
		if gui then
			gui:Destroy()
		end
		return
	end

	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = "LockGui"
		gui.Size = UDim2.new(0, 90, 0, 22)
		gui.StudsOffset = Vector3.new(0, 1.2, 0)
		gui.AlwaysOnTop = true
		gui.Parent = pad

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
		label.BackgroundTransparency = 0.3
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.TextColor3 = Color3.fromRGB(180, 210, 255)
		label.Parent = gui
	end

	gui.Label.Text = ("LOCK %d/%d"):format(hp, level)
	gui.Label.TextColor3 = hp < level and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(180, 210, 255)
end

function ProtectionService.SetLockLevel(pad, level)
	level = math.clamp(level, 0, CONFIG.PAD_LOCK.MaxLevel)
	pad:SetAttribute("LockLevel", level)
	pad:SetAttribute("LockHP", level)
	lockResetTokens[pad] = (lockResetTokens[pad] or 0) + 1
	updateLockVisual(pad)
end

local function buyPadLock(player, padIndex)
	if typeof(padIndex) ~= "number" then
		return { success = false, reason = "Bad pad" }
	end
	local plot = PlotManager.GetPlotByOwner(player)
	local pad = plot and plot.Pads:FindFirstChild("Pad" .. padIndex)
	if not pad then
		return { success = false, reason = "That's not your pad" }
	end

	local level = pad:GetAttribute("LockLevel") or 0
	if level >= CONFIG.PAD_LOCK.MaxLevel then
		return { success = false, reason = "Lock is maxed out" }
	end

	local cost = CONFIG.PAD_LOCK.Costs[level + 1]
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or leaderstats.Coins.Value < cost then
		return { success = false, reason = "Not enough coins" }
	end

	leaderstats.Coins.Value -= cost
	ProtectionService.SetLockLevel(pad, level + 1)
	return { success = true, level = level + 1 }
end

-- House stages ----------------------------------------------------------------

local function buyBuilding(player)
	local plot = PlotManager.GetPlotByOwner(player)
	if not plot then
		return { success = false, reason = "You don't have a plot" }
	end

	local nextLevel = HouseBuilder.GetLevel(plot) + 1
	local stage = HouseBuilder.Stage(nextLevel)
	if not stage then
		return { success = false, reason = "Your house is complete" }
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or leaderstats.Coins.Value < stage.Cost then
		return { success = false, reason = "Not enough coins" }
	end

	leaderstats.Coins.Value -= stage.Cost
	HouseBuilder.SetLevel(plot, nextLevel)

	-- A shield raised before the door existed keeps working; just swap its visual
	if ProtectionService.IsShielded(plot) then
		removeDome(plot)
		buildDome(plot)
	end

	return { success = true, level = nextLevel, name = stage.Name }
end

-- Called when a non-owner completes the prompt hold. Returns true if the steal may proceed.
-- Otherwise it tells both sides what happened and returns false.
function ProtectionService.TrySteal(plot, pad, thief)
	local owner = Players:GetPlayerByUserId(plot:GetAttribute("OwnerUserId"))

	if ProtectionService.IsShielded(plot) then
		notify(thief, "This plot is shielded!", Color3.fromRGB(80, 200, 255), 2)
		return false
	end

	local placedAt = pad:GetAttribute("PlacedAt") or 0
	local graceLeft = placedAt + ProtectionService.GraceSeconds(plot) - now()
	if graceLeft > 0 then
		notify(thief, ("Just placed - protected for %ds"):format(math.ceil(graceLeft)), Color3.fromRGB(255, 200, 80), 2)
		return false
	end

	local hp = pad:GetAttribute("LockHP") or 0
	if hp > 0 then
		hp -= 1
		pad:SetAttribute("LockHP", hp)
		updateLockVisual(pad)

		if hp > 0 then
			notify(thief, ("Lock cracked! %d more to break it"):format(hp), Color3.fromRGB(255, 200, 80), 2)
		else
			notify(thief, "Lock broken! Hold E again to steal", Color3.fromRGB(255, 120, 120), 3)
		end
		if owner then
			notify(owner, ("%s is breaking the lock on Pad %d!"):format(thief.Name, pad:GetAttribute("PadIndex")), Color3.fromRGB(255, 70, 70), 3)
		end

		-- Refill the lock if the attacker gives up
		local token = (lockResetTokens[pad] or 0) + 1
		lockResetTokens[pad] = token
		task.delay(CONFIG.PAD_LOCK.ResetSeconds, function()
			if lockResetTokens[pad] == token and pad.Parent then
				pad:SetAttribute("LockHP", pad:GetAttribute("LockLevel") or 0)
				updateLockVisual(pad)
			end
		end)
		return false
	end

	return true
end

-- After a successful steal the lock stays bought but must be re-armed for the next character
function ProtectionService.OnPadStolen(pad)
	pad:SetAttribute("LockHP", pad:GetAttribute("LockLevel") or 0)
	updateLockVisual(pad)
end

function ProtectionService.ClearPlot(plot)
	HouseBuilder.Clear(plot)
	plot:SetAttribute("ShieldUntil", 0)
	plot:SetAttribute("ShieldCooldownUntil", 0)
	removeDome(plot)
	for _, pad in ipairs(plot.Pads:GetChildren()) do
		ProtectionService.SetLockLevel(pad, 0)
		pad:SetAttribute("PlacedAt", 0)
	end
end

Remotes.ActivateShield.OnServerInvoke = activateShield
Remotes.BuyPadLock.OnServerInvoke = buyPadLock
Remotes.BuyBuilding.OnServerInvoke = buyBuilding

return ProtectionService
