local PlotManager = {}

local function getPlotsFolder()
	return workspace:WaitForChild("Plots")
end

local function setNameplate(plot, text)
	local label = plot:FindFirstChild("Nameplate", true)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

function PlotManager.AssignPlot(player)
	for _, plot in ipairs(getPlotsFolder():GetChildren()) do
		if plot:GetAttribute("OwnerUserId") == 0 then
			plot:SetAttribute("OwnerUserId", player.UserId)
			setNameplate(plot, player.Name .. "'s Plot")
			return plot
		end
	end
	return nil
end

function PlotManager.GetPlotByOwner(player)
	for _, plot in ipairs(getPlotsFolder():GetChildren()) do
		if plot:GetAttribute("OwnerUserId") == player.UserId then
			return plot
		end
	end
	return nil
end

function PlotManager.ReleasePlot(player, clearPad)
	local plot = PlotManager.GetPlotByOwner(player)
	if not plot then
		return
	end

	local pads = plot:FindFirstChild("Pads")
	if pads and clearPad then
		for _, pad in ipairs(pads:GetChildren()) do
			clearPad(pad)
		end
	end

	plot:SetAttribute("OwnerUserId", 0)
	setNameplate(plot, "Empty Plot")
end

return PlotManager
