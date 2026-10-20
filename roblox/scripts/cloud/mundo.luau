-- mundo: comprobaciones del mapa con la geometría de verdad (rayos y cajas del motor de Roblox),
-- que las pruebas de Lune (con piezas de mentira) no pueden hacer.
--
--   1. Suelo debajo de cada StorySpot, de cada sitio con etiqueta que usa la historia
--      (LifeStory/Locations: JobBoard, SchoolEntrance, MetroAlight…) y de cada parada de bus.
--   2. Puertas y avisos (ProximityPrompt): que se pueda llegar de pie hasta ellos.
--   3. Piezas ancladas flotando en el aire cerca de donde aparece la gente.
--   4. Mobiliario de la calle (farolas, bancos, papeleras, semáforos, marquesinas, coches aparcados)
--      metido dentro de una pared.
--
-- Solo se prepara el mundo (terreno, ciudad…), sin arrancar los servicios: las puertas y avisos que
-- crean los servicios al arrancar no se miran aquí.
--
-- Uso: bash scripts/cloud-test.sh mundo

local Cloud = Cloud :: any -- (lo pone scripts/cloud-test.sh delante: scripts/cloud/_comun.luau)

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SUELO_MAX = 6 -- studs: el suelo tiene que estar como mucho a esto por debajo del punto
local PENDIENTE_MIN = 0.7 -- normal.Y mínima para poder andar (≈ 45°)

Cloud.escuchar()
local pasos = Cloud.prepararMundo()
for _, p in pasos do
	if not p.ok then
		Cloud.check("Preparar el mundo: " .. p.name, false, p.err)
	end
end
-- ¿Ven los rayos el terreno en este servidor? (en la cima de la primera montaña solo hay terreno)
do
	local okPlan, CityPlan = pcall(function()
		return require(ReplicatedStorage.Shared.CityPlan) :: any
	end)
	local m = okPlan and CityPlan.Mountains and CityPlan.Mountains[1]
	if m then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { workspace.Terrain }
		local hit = workspace:Raycast(Vector3.new(m.X, m.H + 60, m.Z), Vector3.new(0, -(m.H + 120), 0), params)
		Cloud.info("rayos_ven_el_terreno", if hit then ("sí (cima a Y=%.0f)"):format(hit.Position.Y) else "no (se lee el terreno en vóxeles)")
	end
end

local town = workspace:FindFirstChild("Town")
if not town then
	Cloud.check("La ciudad está en el juego publicado", false, "no hay workspace.Town")
	return Cloud.resultado()
end

---------------------------------------------------------------------
-- 1) Suelo debajo de los sitios
---------------------------------------------------------------------
-- ¿Hay suelo andable cerca por debajo de p? Devuelve (ok, motivo)
local function sueloBajo(p: Vector3, ignorar: { Instance }?): (boolean, string?)
	local hit = Cloud.suelo(p, 3, SUELO_MAX, ignorar)
	if not hit then
		-- ¿Lo hay más abajo? (para decir a cuánto)
		local lejos = Cloud.suelo(p, 3, 200, ignorar)
		if lejos then
			return false, ("suelo %.0f studs más abajo"):format(p.Y - lejos.Position.Y)
		end
		return false, "sin suelo debajo"
	end
	if hit.Normal.Y < PENDIENTE_MIN then
		return false, ("suelo muy inclinado (%s)"):format(Cloud.nombre(hit.Instance))
	end
	return true, nil
end

-- Punto que hay que mirar de un marcador: piezas pequeñas desde su centro; volúmenes (aulas,
-- zonas) desde su parte de abajo.
local function puntoDe(inst: Instance): Vector3?
	if inst:IsA("BasePart") then
		if inst.Size.Y > 6 then
			return (inst.CFrame * CFrame.new(0, -inst.Size.Y / 2, 0)).Position + Vector3.new(0, 1, 0)
		end
		return inst.Position
	end
	return nil
end

local function revisar(titulo: string, cosas: { { inst: Instance, p: Vector3?, label: string } })
	local malos, modelos, total = {}, 0, 0
	for _, c in cosas do
		local p = c.p or puntoDe(c.inst)
		if not p then
			modelos += 1
			continue
		end
		total += 1
		local ok, why = sueloBajo(p, { c.inst })
		if not ok then
			table.insert(malos, ("%s %s: %s"):format(c.label, Cloud.v3(p), why or "?"))
		end
	end
	local detail = ("%d revisados"):format(total)
	if modelos > 0 then
		detail ..= (", %d modelos sin mirar"):format(modelos)
	end
	if #malos > 0 then
		detail = ("%d de %d sin suelo andable: %s"):format(#malos, total, Cloud.lista(malos, 12))
	end
	Cloud.check(titulo, #malos == 0 and total > 0, if total == 0 then "no se ha encontrado ninguno" else detail)
end

-- 1a) StorySpot
local spots = {}
for _, inst in CollectionService:GetTagged("StorySpot") do
	table.insert(spots, { inst = inst, label = tostring(inst:GetAttribute("SpotId") or inst.Name) })
end
revisar("Suelo bajo cada StorySpot", spots)

-- 1b) Sitios de la historia con etiqueta (LifeStory/Locations.Places)
local placeTags: { [string]: boolean } = {}
local okLoc, Locations = pcall(function()
	return require(ReplicatedStorage.Shared.LifeStory.Locations) :: any
end)
if okLoc and type(Locations) == "table" and type(Locations.Places) == "table" then
	for _, place in Locations.Places do
		if type(place) == "table" and type(place.Tag) == "string" and place.Tag ~= "StorySpot" then
			placeTags[place.Tag] = true
		end
	end
else
	Cloud.check("Leer LifeStory/Locations", false, tostring(Locations))
end
local marcas = {}
local tagNames = {}
for tag in placeTags do
	table.insert(tagNames, tag)
end
table.sort(tagNames)
local sinNinguno = {}
for _, tag in tagNames do
	local list = CollectionService:GetTagged(tag)
	if #list == 0 then
		table.insert(sinNinguno, tag)
	end
	for _, inst in list do
		table.insert(marcas, { inst = inst, label = tag .. ":" .. inst.Name })
	end
end
revisar(("Suelo bajo los sitios de la historia (%d etiquetas)"):format(#tagNames), marcas)
if #sinNinguno > 0 then
	-- (algunas las pone un servicio al arrancar: por eso es solo un aviso)
	Cloud.aviso("Etiquetas de la historia que no están en el mapa", false, table.concat(sinNinguno, ", "))
end

-- 1c) Paradas de bus: donde para el autobús (StopPoint) y la marquesina
local paradas = {}
for _, sign in CollectionService:GetTagged("BusStop") do
	local stopPoint = sign:GetAttribute("StopPoint")
	local id = tostring(sign:GetAttribute("StopId") or sign.Name)
	if typeof(stopPoint) == "Vector3" then
		table.insert(paradas, { inst = sign, p = stopPoint + Vector3.new(0, 1, 0), label = "parada " .. id })
	end
	local shelter = sign:FindFirstAncestorOfClass("Model")
	local seat = shelter and shelter:FindFirstChild("Seat")
	if seat and seat:IsA("BasePart") then
		-- delante del banco, donde espera la gente
		local front = (seat.CFrame * CFrame.new(0, 0, -2)).Position
		table.insert(paradas, { inst = shelter :: Instance, p = front, label = "marquesina " .. id })
	end
end
revisar("Suelo en las paradas de bus (parada y marquesina)", paradas)

---------------------------------------------------------------------
-- 2) Puertas y avisos: ¿se llega de pie?
---------------------------------------------------------------------
local DIRS = {}
for i = 0, 7 do
	local a = i * math.pi / 4
	table.insert(DIRS, Vector3.new(math.cos(a), 0, math.sin(a)))
end

local function visible(from: Vector3, to: Vector3, ignorar: { Instance }): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignorar
	params.RespectCanCollide = true
	local hit = workspace:Raycast(from, to - from, params)
	return hit == nil or (hit.Position - to).Magnitude < 1.5
end

-- Busca un sitio de pie desde el que se llegue a `target` (a `distancias` studs alrededor)
-- (`ignorarSuelo`: lo que no cuenta como suelo; por defecto lo mismo que `ignorar`. Para los avisos
-- es {}: el aviso puede estar en la misma pieza que se pisa, como el embarcadero de la Isla del Faro.)
local function accesible(target: Vector3, ignorar: { Instance }, distancias: { number }, alcance: number, vista: boolean, ignorarSuelo: { Instance }?): (boolean, string?)
	local motivo = "sin suelo alrededor"
	for _, d in distancias do
		for _, dir in DIRS do
			local p = target + dir * d
			local hit = Cloud.suelo(Vector3.new(p.X, target.Y, p.Z), 2, 10, ignorarSuelo or ignorar)
			if hit and hit.Normal.Y >= PENDIENTE_MIN then
				local pie = hit.Position
				local cabe, estorbo = Cloud.cabe(pie, ignorar)
				if not cabe then
					motivo = "lo tapa " .. Cloud.nombre(estorbo)
				else
					local head = pie + Vector3.new(0, 4.5, 0)
					if (head - target).Magnitude <= alcance and (not vista or visible(head, target, ignorar)) then
						return true, nil
					end
					motivo = if vista then "no se ve desde el suelo" else "demasiado lejos del suelo"
				end
			end
		end
	end
	return false, motivo
end

-- 2a) Puertas y entradas (las que están en el mapa)
local PUERTAS = { "SchoolEntrance", "Shop", "SuperDoor", "RestaurantDoor", "CinemaDoor", "UnitDoor", "InteriorEntry", "InteriorExit", "MetroEntrance", "TravelStop" }
local puertas, malasPuertas, porTag = 0, {}, {}
for _, tag in PUERTAS do
	local list = CollectionService:GetTagged(tag)
	porTag[tag] = #list
	-- Muestra: hasta 25 de cada tipo, repartidas por la lista
	local step = math.max(1, math.floor(#list / 25))
	for i = 1, #list, step do
		if Cloud.quedan() < 120 then
			break
		end
		local inst = list[i]
		local p = Cloud.posicion(inst)
		if not p then
			continue
		end
		puertas += 1
		local model = inst:FindFirstAncestorOfClass("Model")
		-- Marcadores "delante de la puerta" (entradas): se mira el sitio mismo; puertas: a 2-4 studs
		local ignorar: { Instance } = { inst }
		local ok, why
		if inst:IsA("BasePart") and inst.CanCollide and inst.Transparency < 1 then
			ok, why = accesible(p, ignorar, { 2.5, 4 }, 10, false)
		else
			local hit = Cloud.suelo(p, 3, 10, ignorar)
			if hit then
				local cabe, estorbo = Cloud.cabe(hit.Position, ignorar)
				ok, why = cabe, if cabe then nil else "lo tapa " .. Cloud.nombre(estorbo)
				if not ok then
					-- Si el sitio exacto está tapado, que por lo menos se pueda llegar muy cerca
					ok, why = accesible(p, ignorar, { 2, 3.5 }, 8, false)
				end
			else
				ok, why = false, "sin suelo"
			end
		end
		if not ok then
			table.insert(malasPuertas, ("%s %s (%s): %s"):format(tag, Cloud.nombre(if model then model else inst), Cloud.v3(p), why or "?"))
		end
	end
end
Cloud.check("Se llega de pie a las puertas y entradas", #malasPuertas == 0, if #malasPuertas == 0 then ("%d revisadas"):format(puertas) else ("%d de %d tapadas: %s"):format(#malasPuertas, puertas, Cloud.lista(malasPuertas, 12)))

-- 2b) Avisos (ProximityPrompt) que ya están en el mapa
local prompts = {}
for _, d in workspace:GetDescendants() do
	if d:IsA("ProximityPrompt") and d.Enabled then
		table.insert(prompts, d)
	end
end
local malosPrompts, revisados = {}, 0
local step = math.max(1, math.floor(#prompts / 80))
for i = 1, #prompts, step do
	if Cloud.quedan() < 100 then
		break
	end
	local prompt = prompts[i]
	local parent = prompt.Parent
	local p = parent and Cloud.posicion(parent)
	if not p or not parent then
		continue
	end
	revisados += 1
	-- Se ignora solo lo que lleva el aviso (la pieza, o un modelo pequeño como una máquina), no el
	-- modelo entero: el aviso "Volver al puerto" está en el embarcadero del modelo Faro y el de la
	-- barca en la taquilla del modelo Puerto; ignorando el modelo entero se quitaba también el
	-- embarcadero y el pantalán donde se está de pie ("sin suelo alrededor" sin serlo).
	local holder: Instance = if parent:IsA("Attachment") and parent.Parent then parent.Parent else parent
	local ignorar: { Instance } = { holder }
	local owner = holder:FindFirstAncestorOfClass("Model")
	if owner and owner ~= town then
		local okBox, _, size = pcall(function()
			return (owner :: Model):GetBoundingBox()
		end)
		if okBox and size and math.max(size.X, size.Y, size.Z) <= 16 then
			ignorar = { owner }
		end
	end
	local alcance = math.max(3, prompt.MaxActivationDistance)
	local ok, why = accesible(p, ignorar, { 2.5, 4, math.min(alcance - 0.5, 7) }, alcance, prompt.RequiresLineOfSight, {})
	if not ok then
		table.insert(malosPrompts, ("\"%s\" en %s %s: %s"):format(prompt.ActionText, Cloud.nombre(parent), Cloud.v3(p), why or "?"))
	end
end
if #prompts == 0 then
	Cloud.salta("Se llega a los avisos (ProximityPrompt)", "el mapa no trae avisos: los crean los servicios al arrancar")
else
	Cloud.check("Se llega a los avisos (ProximityPrompt)", #malosPrompts == 0, if #malosPrompts == 0 then ("%d de %d revisados"):format(revisados, #prompts) else ("%d de %d sin acceso: %s"):format(#malosPrompts, revisados, Cloud.lista(malosPrompts, 12)))
end

---------------------------------------------------------------------
-- 3) Piezas flotando cerca de donde aparece la gente
---------------------------------------------------------------------
local origenes: { { p: Vector3, label: string } } = {}
for _, d in workspace:GetDescendants() do
	if d:IsA("SpawnLocation") then
		table.insert(origenes, { p = d.Position, label = "SpawnLocation " .. Cloud.nombre(d) })
	end
end
for _, spot in CollectionService:GetTagged("StorySpot") do
	local id = spot:GetAttribute("SpotId")
	if (id == "SalirCasa" or id == "Despertar") and spot:IsA("BasePart") then
		table.insert(origenes, { p = spot.Position, label = "casa " .. tostring(spot:GetAttribute("HomeId") or "?") })
	end
end
for _, part in CollectionService:GetTagged("SchoolEntrance") do
	if part:IsA("BasePart") then
		table.insert(origenes, { p = part.Position, label = "colegio " .. Cloud.nombre(part.Parent) })
	end
end

local RADIO = 90
local FLOTA_MIN = 1.5 -- studs: más cerca del suelo que esto no se cuenta (asientos, repisas, zócalos)

-- ¿Alguna pieza del mismo modelo (aunque no se pueda consultar) toca a esta? Cajas alineadas con
-- el mundo, con 0.3 studs de margen.
local function apoyadoEnHermanas(part: BasePart): boolean
	local parent = part.Parent
	if not parent then
		return false
	end
	local c, e = part.Position, part.ExtentsSize / 2 + Vector3.new(0.3, 0.3, 0.3)
	for _, other in parent:GetChildren() do
		if other ~= part and other:IsA("BasePart") then
			local d, oe = other.Position - c, other.ExtentsSize / 2
			if math.abs(d.X) <= e.X + oe.X and math.abs(d.Y) <= e.Y + oe.Y and math.abs(d.Z) <= e.Z + oe.Z then
				return true
			end
		end
	end
	return false
end
local vistos: { [BasePart]: boolean } = {}
local flotando = {}
local mirados = 0
local cerca = OverlapParams.new()
cerca.RespectCanCollide = false
local toca = OverlapParams.new()
toca.RespectCanCollide = false
toca.FilterType = Enum.RaycastFilterType.Exclude
toca.MaxParts = 2
for _, origen in origenes do
	if Cloud.quedan() < 70 then
		break
	end
	for _, part in workspace:GetPartBoundsInRadius(origen.p, RADIO, cerca) do
		if vistos[part] or part == workspace.Terrain or not part.Anchored or part.Transparency >= 1 then
			continue
		end
		vistos[part] = true
		if part.Size.Magnitude < 0.5 or (part.CanCollide and Cloud.Ground.skipOf(part) ~= nil) then
			continue -- (motas y vehículos)
		end
		mirados += 1
		-- ¿Toca otra pieza? (con 0.3 studs de margen)
		toca.FilterDescendantsInstances = { part }
		local touching = workspace:GetPartBoundsInBox(part.CFrame, part.Size + Vector3.new(0.3, 0.3, 0.3), toca)
		if #touching > 0 then
			continue
		end
		-- ¿Lo sujeta un adorno de su mismo modelo? Las patas de los bancos y del piano, la cabina de
		-- los teléfonos de pared… son Builder.decor (CanQuery = false): las consultas de arriba no
		-- las ven, así que se miran a mano las piezas hermanas.
		if apoyadoEnHermanas(part) then
			continue
		end
		-- ¿Toca el terreno o tiene algo justo debajo?
		local bottom = part.Position.Y - part.ExtentsSize.Y / 2
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { part }
		local hit = workspace:Raycast(Vector3.new(part.Position.X, bottom + 0.1, part.Position.Z), Vector3.new(0, -300, 0), params)
		local gap = if hit then bottom - hit.Position.Y else math.huge
		if gap > FLOTA_MIN then
			table.insert(flotando, ("%s %s a %s del suelo (cerca de %s)"):format(Cloud.nombre(part), Cloud.v3(part.Position), if gap == math.huge then "∞" else ("%.0f"):format(gap), origen.label))
		end
	end
end
Cloud.info("piezas_mirando_si_flotan", mirados)
Cloud.aviso(("Nada flotando en el aire cerca de donde aparece la gente (%d sitios, radio %d)"):format(#origenes, RADIO), #flotando == 0, if #flotando == 0 then ("%d piezas revisadas"):format(mirados) else ("%d piezas sueltas en el aire (a más de %.1f studs del suelo, sin nada que las sujete): %s"):format(#flotando, FLOTA_MIN, Cloud.lista(flotando, 12)))

---------------------------------------------------------------------
-- 4) Mobiliario de la calle metido en paredes
---------------------------------------------------------------------
local okRoads, Roads = pcall(function()
	return require(Cloud.Server.World.Kit.Roads) :: any
end)
local PROP_TAGS = { "Bench", "StreetLamp", "TrafficLight", "Papelera", "Fountain", "RentalStation" }
local PROP_NAMES = { ParadaBus = true, ParkedCar = true, BusStop = true, StreetLamp = true, TrafficLight = true, Bench = true }
local props: { [Instance]: boolean } = {}
local function addProp(inst: Instance)
	local model = if inst:IsA("Model") then inst else inst:FindFirstAncestorOfClass("Model")
	if model and model ~= town and model.Parent then
		props[model] = true
	elseif inst:IsA("BasePart") then
		props[inst] = true
	end
end
for _, tag in PROP_TAGS do
	for _, inst in CollectionService:GetTagged(tag) do
		addProp(inst)
	end
end
for _, d in town:GetDescendants() do
	if d:IsA("Model") and PROP_NAMES[d.Name] then
		props[d] = true
	end
end

local choques, mirado = {}, 0
local pared = OverlapParams.new()
pared.RespectCanCollide = true
pared.FilterType = Enum.RaycastFilterType.Exclude
for prop in props do
	if Cloud.quedan() < 30 then
		break
	end
	local cf, size
	if prop:IsA("Model") then
		cf, size = prop:GetBoundingBox()
	elseif prop:IsA("BasePart") then
		cf, size = prop.CFrame, prop.Size
	else
		continue
	end
	local p = cf.Position
	if okRoads and type(Roads) == "table" and Roads.near and not Roads.near(p.X, p.Z, 6) then
		continue -- solo lo que está junto a una calle
	end
	mirado += 1
	local bottom = p.Y - size.Y / 2
	pared.FilterDescendantsInstances = { prop }
	local inner = Vector3.new(math.max(0.2, size.X - 1), math.max(0.2, size.Y - 1), math.max(0.2, size.Z - 1))
	for _, part in workspace:GetPartBoundsInBox(cf, inner, pared) do
		if part == workspace.Terrain or Cloud.Ground.skipOf(part) ~= nil then
			continue
		end
		local top = part.Position.Y + part.ExtentsSize.Y / 2
		local isProp = false
		local node: Instance? = part
		while node and node ~= town do
			if props[node] then
				isProp = true
				break
			end
			node = node.Parent
		end
		-- Una pared: algo alto (≥ 6 studs) que sube por encima del objeto, que no es suelo ni otro objeto
		if not isProp and part.ExtentsSize.Y >= 6 and top > bottom + 3 then
			table.insert(choques, ("%s %s dentro de %s"):format(Cloud.nombre(prop), Cloud.v3(p), Cloud.nombre(part)))
			break
		end
	end
end
Cloud.info("mobiliario_junto_a_calles", mirado)
Cloud.aviso("Mobiliario de la calle fuera de las paredes", #choques == 0, if #choques == 0 then ("%d objetos junto a calles revisados"):format(mirado) else ("%d de %d metidos en una pared: %s"):format(#choques, mirado, Cloud.lista(choques, 12)))

-- Recuento
local counts = {}
for tag, n in porTag do
	if n > 0 then
		table.insert(counts, ("%s=%d"):format(tag, n))
	end
end
table.sort(counts)
Cloud.info("puertas_en_el_mapa", table.concat(counts, " "))
Cloud.info("storyspots", #spots)
Cloud.info("paradas_bus", #CollectionService:GetTagged("BusStop"))
Cloud.info("avisos_en_el_mapa", #prompts)
local oido = Cloud.oido()
if #oido.errores > 0 then
	Cloud.check("Sin errores al preparar el mundo", false, Cloud.lista(oido.errores, 6))
end
return Cloud.resultado()
