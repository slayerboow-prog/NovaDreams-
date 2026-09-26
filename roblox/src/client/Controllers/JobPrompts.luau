-- JobPrompts (cliente): los carteles de trabajo solo los ve quien trabaja en ese oficio.
--   Un ProximityPrompt con el atributo JobOnly = "<Oficio>" solo se enseña si tu atributo Job
--   es ese oficio; si además tiene OwnerUserId, solo lo ve ese jugador (p. ej. la casa a la que
--   le toca llevar el paquete a un repartidor concreto). El servidor comprueba igualmente quién lo usa.

local Players = game:GetService("Players")

local JobPrompts = {}

local player = Players.LocalPlayer
local tracked: { ProximityPrompt } = {}

local function visible(prompt: ProximityPrompt): boolean
	local job = prompt:GetAttribute("JobOnly")
	local owner = prompt:GetAttribute("OwnerUserId")
	return player:GetAttribute("Job") == job and (owner == nil or owner == player.UserId)
end

local function track(d: Instance)
	if d:IsA("ProximityPrompt") and d:GetAttribute("JobOnly") then
		table.insert(tracked, d)
		d.Enabled = visible(d)
	end
end

local function refresh()
	for i = #tracked, 1, -1 do
		local prompt = tracked[i]
		if prompt.Parent then
			prompt.Enabled = visible(prompt)
		else
			table.remove(tracked, i)
		end
	end
end

function JobPrompts.init()
	for _, d in workspace:GetDescendants() do
		track(d)
	end
	workspace.DescendantAdded:Connect(track)
	player:GetAttributeChangedSignal("Job"):Connect(refresh)
end

return JobPrompts
