-- Diving: las reglas del buceo en el mar hondo (aire, presión, equipo, recursos, cofres, fotos y
-- misiones del mar). Puras: las usan DivingService y OceanService (servidor, que es quien decide),
-- DiveHud (cliente, solo para enseñarlo) y scripts/test-mar.luau. docs/mar/diseno.md.
--
-- Equipo (tienda de pesca, shared/Fishing.Tools; el mejor que lleves en la mochila):
--   sin nada        30 s de aire · hasta 12 m
--   Gafas y tubo    60 s         · hasta 25 m   (el arrecife, el kelp, la pradera, el pecio)
--   Equipo de buceo 4 min        · hasta 75 m   (el talud, la garganta, el Abismo Silente)
--   Traje abisal    8 min        · hasta 180 m  (la Sima del Kraken)
-- Pasarte de tu límite: un aviso claro; el aire se gasta el triple y, pasado un momento, la presión
-- hace daño hasta que subas. El aire se recupera en la superficie, en el barco de pesca y en las
-- bolsas de aire de las cuevas.

local Fishing = require(script.Parent.Parent.Fishing)
local Ocean = require(script.Parent.Ocean)

local Diving = {}

Diving.GearOrder = { "TrajeAbisal", "Botella", "Gafas" } -- del mejor al peor
Diving.Gear = {
	Base = { Name = "sin equipo", Oxygen = Fishing.Dive.Oxygen.Base, Depth = 12 },
	Gafas = { Name = "gafas y tubo", Oxygen = Fishing.Dive.Oxygen.Gafas, Depth = 25 },
	Botella = { Name = "equipo de buceo", Oxygen = Fishing.Dive.Oxygen.Botella, Depth = 75 },
	TrajeAbisal = { Name = "traje abisal", Oxygen = Fishing.Dive.Oxygen.TrajeAbisal, Depth = 180 },
}

Diving.Refill = Fishing.Dive.Refill -- aire por segundo fuera del agua
Diving.PocketRefill = 25 -- aire por segundo en una bolsa de aire o junto al barco de pesca
Diving.BoatRadius = 26 -- junto al barco de pesca (a su cubierta) se respira de la botella de a bordo
Diving.Warn = 3 -- a menos de estos metros del límite: aviso
Diving.OverDrain = 3 -- pasado el límite, el aire se gasta así de rápido
Diving.OverGrace = 4 -- segundos pasado el límite antes de que la presión haga daño
Diving.OverDamage = 8 -- vida por segundo (después del margen)

-- El mejor equipo que tienes (has(id) -> bool). nil = sin equipo
function Diving.gearOf(has: (string) -> boolean): string?
	for _, id in Diving.GearOrder do
		if has(id) then
			return id
		end
	end
	return nil
end

function Diving.info(gear: string?): { Name: string, Oxygen: number, Depth: number }
	return Diving.Gear[gear or "Base"] or Diving.Gear.Base
end

-- Lo que te dice la presión a esta profundidad (m) con tu equipo:
--   "Ok", "Warn" (cerca del límite) u "Over" (pasado: el aire se gasta más y luego hace daño)
function Diving.pressure(meters: number, gear: string?): string
	local limit = Diving.info(gear).Depth
	if meters > limit then
		return "Over"
	elseif meters > limit - Diving.Warn then
		return "Warn"
	end
	return "Ok"
end

-- El equipo que hace falta para bajar a esta profundidad (m) (nil = no hay)
function Diving.gearFor(meters: number): string?
	if meters <= Diving.Gear.Base.Depth then
		return "Base"
	end
	for i = #Diving.GearOrder, 1, -1 do
		local id = Diving.GearOrder[i]
		if meters <= Diving.Gear[id].Depth then
			return id
		end
	end
	return nil
end

-- El aviso de pasarte (claro: qué llevas, hasta dónde, qué te falta y dónde se compra)
function Diving.overText(gear: string?, meters: number): string
	local info = Diving.info(gear)
	local need = Diving.gearFor(meters)
	local needInfo = if need then Diving.Gear[need] else nil
	local tail = if needInfo and need ~= "Base" then (" Para bajar a %d m necesitas %s (tienda de pesca)."):format(math.floor(meters), needInfo.Name) else ""
	return ("🫧 ¡Presión! Con %s puedes bajar hasta %d m.%s Sube un poco."):format(info.Name, info.Depth, tail)
end

-- Un segundo de buceo (lo hace DivingService cada segundo). Devuelve el aire nuevo, el daño y los
-- segundos que llevas pasado el límite.
--   state: { Oxygen, Max, Under (cabeza bajo el agua), Meters, Gear, Over (segundos pasado), Pocket (en
--            una bolsa de aire o junto al barco) }
function Diving.tick(state: { [string]: any }): (number, number, number)
	local oxygen, max = state.Oxygen, state.Max
	local over = state.Over or 0
	local damage = 0
	if state.Pocket then
		return math.min(max, oxygen + Diving.PocketRefill), 0, 0
	end
	if not state.Under then
		return math.min(max, oxygen + Diving.Refill), 0, 0
	end
	local p = Diving.pressure(state.Meters or 0, state.Gear)
	local drain = 1
	if p == "Over" then
		drain = Diving.OverDrain
		over += 1
		if over > Diving.OverGrace then
			damage += Diving.OverDamage
		end
	else
		over = 0
	end
	oxygen = math.max(0, oxygen - drain)
	if oxygen <= 0 then
		damage += Fishing.Dive.DrownDamage
	end
	return oxygen, damage, over
end

---------------------------------------------------------------------
-- Recursos del fondo (van a la mochila; los compra la lonja de la pescadería)
---------------------------------------------------------------------
Diving.Loot = {
	Concha = { Id = "Concha", Item = "Mar_Concha", Name = "Concha", Icon = "🐚", Price = 4, Color = Color3.fromRGB(245, 225, 205) },
	Perla = { Id = "Perla", Item = "Mar_Perla", Name = "Perla", Icon = "⚪", Price = 70, Color = Color3.fromRGB(240, 240, 255) },
	Coral = { Id = "Coral", Item = "Mar_Coral", Name = "Muestra de coral", Icon = "🪸", Price = 18, Color = Color3.fromRGB(240, 90, 110) },
	Bio = { Id = "Bio", Item = "Mar_Bio", Name = "Muestra bioluminiscente", Icon = "🧪", Price = 45, Color = Color3.fromRGB(90, 240, 255) },
	Doblon = { Id = "Doblon", Item = "Mar_Doblon", Name = "Doblón antiguo", Icon = "🪙", Price = 120, Color = Color3.fromRGB(240, 200, 80) },
}
Diving.LootOrder = { "Concha", "Perla", "Coral", "Bio", "Doblon" }
Diving.LootByItem = {}
for _, def in Diving.Loot do
	Diving.LootByItem[def.Item] = def
end

-- Recoger (OceanService lo comprueba todo en el servidor)
Diving.Pickup = {
	Range = 12, -- studs del centro del cuerpo al recurso
	Gap = 0.6, -- segundos entre dos recogidas
	PerMinute = 30, -- como mucho (contra trampas)
	Respawn = 150, -- segundos hasta que vuelve a salir
	Nodes = 150, -- recursos en todo el mar
}

-- ¿Puede recoger este? (lista vacía = sí). Puro: el servidor le pasa lo que ha medido.
--   a: { Distance, Underwater, Active, SinceLast, LastMinute, Meters, Gear, Alive }
function Diving.pickupProblem(a: { [string]: any }): string?
	if a.Alive == false then
		return "muerto"
	elseif not a.Active then
		return "ya recogido"
	elseif (a.Distance or math.huge) > Diving.Pickup.Range then
		return "lejos"
	elseif not a.Underwater then
		return "fuera del agua"
	elseif (a.SinceLast or math.huge) < Diving.Pickup.Gap then
		return "demasiado rápido"
	elseif (a.LastMinute or 0) >= Diving.Pickup.PerMinute then
		return "demasiados"
	elseif Diving.pressure(a.Meters or 0, a.Gear) == "Over" then
		return "presión"
	end
	return nil
end

-- Qué recurso sale en una zona (pesos de OceanBiomes.Zones[z].Loot); r en 0..1
function Diving.pickLoot(zoneLoot: { [string]: number }, r: number): string?
	local total = 0
	for _, id in Diving.LootOrder do
		total += zoneLoot[id] or 0
	end
	if total <= 0 then
		return nil
	end
	local x = r * total
	for _, id in Diving.LootOrder do
		x -= zoneLoot[id] or 0
		if x <= 0 and (zoneLoot[id] or 0) > 0 then
			return id
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Cofres del tesoro (uno por persona y día en cada uno)
---------------------------------------------------------------------
Diving.ChestRange = 12
Diving.ChestCooldown = 20 * 3600 -- segundos reales
Diving.Chests = {
	ArcoCoral = { Money = 120, Loot = { Perla = 1 } },
	Pecio = { Money = 450, Loot = { Doblon = 2, Perla = 1 } },
	Ruinas = { Money = 600, Loot = { Doblon = 3 } },
	Batiscafo = { Money = 900, Loot = { Bio = 2, Perla = 2 } },
	Guarida = { Money = 2500, Loot = { Doblon = 5, Perla = 3 } },
}

-- ¿Se puede abrir ya? (opened = os.time de la última vez, now = os.time)
function Diving.chestReady(opened: number?, now: number): (boolean, number)
	if type(opened) ~= "number" then
		return true, 0
	end
	local left = opened + Diving.ChestCooldown - now
	return left <= 0, math.max(0, left)
end

---------------------------------------------------------------------
-- Fotos de criaturas (Fotografiar con la cámara)
---------------------------------------------------------------------
Diving.Photo = { Range = 90, Gap = 1.5 }

---------------------------------------------------------------------
-- Misiones del mar (sin orden fijo: cuentan aunque las hagas antes). La primera sin terminar sale en el
-- HUD con su sitio y la distancia.
--   Step: Found (descubrir sitios), Chest (abrir cofres), Loot (recoger: { Concha = 5 }), Photo
--   FoundAny + Need: descubrir Need sitios cualesquiera de la lista (el HUD lleva al más cercano)
---------------------------------------------------------------------
-- (v122) «Explora el arrecife» ya no manda a 2,6 km: vale el Arco de Coral, el Jardín Escarlata o
-- cualquiera de los jardines de coral delante de las playas (Ocean.ShoreReefs).
local REEFS = { "ArcoCoral", "JardinEscarlata" }
for _, reef in Ocean.ShoreReefs do
	table.insert(REEFS, reef.Id)
end
Diving.Reefs = REEFS
Diving.Missions = {
	{ Id = "Arrecife", Title = "Explora el arrecife", Text = "Descubre dos arrecifes: hay un jardín de coral delante de cada playa", FoundAny = REEFS, Need = 2, Target = "ArcoCoral", Reward = 300 },
	{ Id = "Conchas", Title = "Recolector del fondo", Text = "Recoge 5 conchas y una perla", Loot = { Concha = 5, Perla = 1 }, Target = "JardinEscarlata", Reward = 250 },
	{ Id = "Pecio", Title = "Encuentra el pecio", Text = "Encuentra el Pecio del Albatros y abre su cofre", Found = { "Pecio" }, Chest = { "Pecio" }, Target = "Pecio", Reward = 600 },
	{ Id = "ValmarHundida", Title = "Valmar Hundida", Text = "Baja al Cañón de las Catedrales: encuentra el barrio de los faroles, abre su cofre y entra en la Catedral Abisal", Found = { "ValmarHundida", "CatedralAbisal" }, Chest = { "ValmarHundida" }, Target = "ValmarHundida", Reward = 1200 },
	{ Id = "Megalodon", Title = "Fotografía al megalodón", Text = "Baja al Abismo Silente y hazle una foto (sin acercarte demasiado)", Photo = { "Megalodon" }, Target = "JardinLuz", Reward = 1500 },
	{ Id = "Kraken", Title = "La guarida del Kraken", Text = "Llega a la Guarida del Kraken, en la Sima", Found = { "Guarida" }, Target = "Guarida", Reward = 2500 },
}
Diving.MissionById = {}
for _, m in Diving.Missions do
	Diving.MissionById[m.Id] = m
end

-- Progreso de una misión con los datos del mar (data.Sea): hecho, total
function Diving.progress(mission: { [string]: any }, sea: { [string]: any }): (number, number)
	local done, total = 0, 0
	for _, id in mission.Found or {} do
		total += 1
		if sea.Found and sea.Found[id] then
			done += 1
		end
	end
	for _, id in mission.Chest or {} do
		total += 1
		if sea.Chests and sea.Chests[id] then
			done += 1
		end
	end
	for _, id in mission.Photo or {} do
		total += 1
		if sea.Photos and sea.Photos[id] then
			done += 1
		end
	end
	if mission.FoundAny then
		local need = mission.Need or 1
		local got = 0
		for _, id in mission.FoundAny do
			if sea.Found and sea.Found[id] then
				got += 1
			end
		end
		total += need
		done += math.min(need, got)
	end
	for id, n in mission.Loot or {} do
		total += n
		done += math.min(n, (sea.Loot and sea.Loot[id]) or 0)
	end
	return done, total
end

-- La misión que toca enseñar (la primera sin terminar), o nil si están todas
function Diving.current(sea: { [string]: any }): { [string]: any }?
	for _, m in Diving.Missions do
		if not (sea.Done and sea.Done[m.Id]) then
			return m
		end
	end
	return nil
end

return Diving
