-- JobPrompts (cliente): los carteles de trabajo solo los ve quien trabaja en ese oficio
-- (y los que tienen MinStage, solo quien tiene edad para ellos).
--   Un ProximityPrompt con el atributo JobOnly = "<Oficio>" solo se enseña si tu atributo Job
--   es ese oficio; si además tiene OwnerUserId, solo lo ve ese jugador (p. ej. la casa a la que
--   le toca llevar el paquete a un repartidor concreto). El servidor comprueba igualmente quién lo usa.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stages = require(ReplicatedStorage.Shared.LifeStory.Stages)
local Business = require(ReplicatedStorage.Shared.Business)

local JobPrompts = {}

local player = Players.LocalPlayer
local tracked: { ProximityPrompt } = {}

local function visible(prompt: ProximityPrompt): boolean
	local job = prompt:GetAttribute("JobOnly")
	local owner = prompt:GetAttribute("OwnerUserId")
	-- MinStage: solo a partir de esa edad (p. ej. "Atracar")
	if prompt:GetAttribute("JailedOnly") and not player:GetAttribute("JailUntil") then
		return false -- (trabajos de los presos)
	end
	-- StaffOff: no a los de la casa (el «Atracar» de la caja de tu propia tienda: BusinessStaff)
	local holder = prompt.Parent
	if prompt:GetAttribute("StaffOff") and holder and Business.isStaff(holder:GetAttribute("BusinessStaff"), player.UserId) then
		return false
	end
	local minStage = prompt:GetAttribute("MinStage")
	local stage = player:GetAttribute("LifeStage")
	-- (modo pruebas: el tester ve los carteles de cualquier edad; el servidor lo vuelve a comprobar)
	if minStage and stage and not Stages.inRange(stage, minStage, nil) and not player:GetAttribute("TesterBypass") then
		return false
	end
	return (job == nil or player:GetAttribute("Job") == job) and (owner == nil or owner == player.UserId)
end

local function track(d: Instance)
	if d:IsA("ProximityPrompt") and (d:GetAttribute("JobOnly") or d:GetAttribute("MinStage") or d:GetAttribute("JailedOnly") or d:GetAttribute("OwnerUserId") or d:GetAttribute("StaffOff")) then
		table.insert(tracked, d)
		d.Enabled = visible(d)
		local holder = d.Parent
		if d:GetAttribute("StaffOff") and holder then
			-- (cambia de dueño o contrata a alguien: se vuelve a mirar)
			holder:GetAttributeChangedSignal("BusinessStaff"):Connect(function()
				if d.Parent then
					d.Enabled = visible(d)
				end
			end)
		end
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
	player:GetAttributeChangedSignal("LifeStage"):Connect(refresh)
	player:GetAttributeChangedSignal("JailUntil"):Connect(refresh)
	player:GetAttributeChangedSignal("TesterBypass"):Connect(refresh)
end

return JobPrompts
