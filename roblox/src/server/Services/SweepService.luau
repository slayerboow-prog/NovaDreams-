-- SweepService (servidor): barrendero de piezas sueltas.
--
-- Todo lo que se crea durante la partida sin anclar (objetos en la mano, trozos que caen, cosas que
-- lleva un personaje…) queda apuntado. Cada pocos segundos se mira: si una pieza ya no está unida a
-- nada (ni a una persona, ni a la base de un vehículo, ni a algo anclado) y lleva un rato quieta en el
-- suelo, se retira (shared/LooseParts dice cuánto). Así nunca se quedan bloques sueltos para siempre en
-- la calzada o en un cruce (p. ej. lo que suelta alguien que reaparece o un vehículo que se deshace).
--
-- No se toca: el mapa (no se apunta: viene en el archivo, y sus puertas que se caen las vuelve a poner
-- BreakService), las personas, los vehículos enteros, los juguetes (etiqueta Toy, los devuelve
-- ToyService) y lo marcado con el atributo KeepLoose.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LooseParts = require(ReplicatedStorage.Shared.LooseParts)

local SweepService = {}

local CHECK_EVERY = 5 -- segundos entre vistazos
local KEEP_TAGS = { "Toy" }

type Watch = { Rest: number, Loose: number }
local watched: { [BasePart]: Watch } = {}

local function keepMarked(part: BasePart): boolean
	if part:GetAttribute("KeepLoose") then
		return true
	end
	for _, tag in KEEP_TAGS do
		if CollectionService:HasTag(part, tag) then
			return true
		end
	end
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:GetAttribute("KeepLoose") then
			return true
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return false
end

local function isPerson(part: BasePart): boolean
	local model = part:FindFirstAncestorOfClass("Model")
	while model do
		if model:FindFirstChildOfClass("Humanoid") or model:FindFirstChildOfClass("AnimationController") then
			return true
		end
		model = model:FindFirstAncestorOfClass("Model")
	end
	return false
end

local function infoOf(part: BasePart): LooseParts.Info
	local root = part.AssemblyRootPart or part
	return {
		Anchored = part.Anchored or root.Anchored,
		Grounded = part:IsGrounded(),
		Person = isPerson(part) or (root ~= part and isPerson(root)),
		Vehicle = root.Name == "Chassis",
		Keep = keepMarked(part),
		Speed = root.AssemblyLinearVelocity.Magnitude,
		Y = part.Position.Y,
	}
end

local function check(dt: number)
	for part, watch in watched do
		if not part:IsDescendantOf(workspace) then
			watched[part] = nil
			continue
		end
		if part.Anchored then
			watched[part] = nil -- (se ancló justo después de crearse: lo normal)
			continue
		end
		local ok, info = pcall(infoOf, part)
		if not ok then
			continue
		end
		if isPerson(part) then
			watched[part] = nil -- (es parte de un personaje: se va con él, no hace falta seguir mirándola)
			continue
		end
		watch.Rest = LooseParts.rest(watch.Rest, info.Speed, dt)
		if LooseParts.owned(info) then
			watch.Rest, watch.Loose = 0, 0
			continue
		end
		watch.Loose += dt
		if LooseParts.verdict(info, watch.Rest, watch.Loose) == "Sweep" then
			watched[part] = nil
			pcall(part.Destroy, part)
		end
	end
end

function SweepService.init()
	workspace.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") and not d.Anchored and not d:IsA("Terrain") then
			watched[d] = { Rest = 0, Loose = 0 }
		end
	end)
	task.spawn(function()
		while true do
			task.wait(CHECK_EVERY)
			local ok, err = pcall(check, CHECK_EVERY)
			if not ok then
				warn("[SweepService] " .. tostring(err))
			end
		end
	end)
end

return SweepService
