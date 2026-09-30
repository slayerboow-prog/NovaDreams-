-- fisica: ¿se puede ir andando entre los sitios clave? (PathfindingService del motor de verdad)
--
-- Sitios: la plaza donde se aparece (SpawnLocation), la puerta de una casa familiar (StorySpot
-- "SalirCasa"), el colegio más cercano (SchoolEntrance), la parada de bus más cercana (delante del
-- banco de la marquesina), la boca de metro más cercana a la plaza (MetroEntrance) y su andén
-- (MetroAlight).
--   1. En cada sitio: hay suelo y cabe una persona de pie (una caja del tamaño de un personaje).
--   2. Entre parejas de sitios: PathfindingService calcula el camino para un personaje normal
--      (radio 2, alto 5, puede saltar). Si no hay camino, o se queda lejos, falla.
-- En estas pruebas la física no corre (lo dice la documentación de Roblox), así que no se hace
-- andar a un personaje de verdad: se comprueba con el cálculo de caminos, que usa la misma malla
-- de navegación que usan los NPC del juego.
--
-- Uso: bash scripts/cloud-test.sh fisica

local Cloud = Cloud :: any -- (lo pone scripts/cloud-test.sh delante: scripts/cloud/_comun.luau)

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")

local LLEGA = 6 -- studs: el camino tiene que acabar a esto del destino

Cloud.escuchar()
for _, p in Cloud.prepararMundo() do
	if not p.ok then
		Cloud.check("Preparar el mundo: " .. p.name, false, p.err)
	end
end

---------------------------------------------------------------------
-- Sitios clave
---------------------------------------------------------------------
local function nearest(list: { Instance }, to: Vector3?, filter: ((Instance) -> boolean)?): Instance?
	local best, bestD = nil, math.huge
	for _, inst in list do
		if filter and not filter(inst) then
			continue
		end
		local p = Cloud.posicion(inst)
		if p then
			local d = if to then (p - to).Magnitude else 0
			if d < bestD then
				best, bestD = inst, d
			end
		end
	end
	return best
end

local sitios: { [string]: { p: Vector3, label: string }? } = {}
local orden = {}
local function sitio(key: string, label: string, p: Vector3?)
	table.insert(orden, key)
	if p then
		sitios[key] = { p = p, label = label }
	end
end

-- Plaza (SpawnLocation)
local spawn: Instance? = nil
for _, d in workspace:GetDescendants() do
	if d:IsA("SpawnLocation") then
		spawn = d
		break
	end
end
local spawnP = if spawn then (spawn :: BasePart).Position + Vector3.new(0, 1, 0) else nil
sitio("plaza", "plaza (SpawnLocation)", spawnP)

-- Casa: la puerta de la primera casa familiar (por HomeId)
local casas = {}
for _, spot in CollectionService:GetTagged("StorySpot") do
	if spot:GetAttribute("SpotId") == "SalirCasa" and spot:IsA("BasePart") then
		table.insert(casas, spot)
	end
end
table.sort(casas, function(a, b)
	return tostring(a:GetAttribute("HomeId")) < tostring(b:GetAttribute("HomeId"))
end)
local casaP = if casas[1] then (casas[1] :: BasePart).Position else nil
sitio("casa", "puerta de casa (SalirCasa " .. tostring(casas[1] and casas[1]:GetAttribute("HomeId") or "?") .. ")", casaP)

-- Colegio más cercano a casa
local cole = nearest(CollectionService:GetTagged("SchoolEntrance"), casaP)
sitio("colegio", "entrada del colegio" .. (if cole then " (" .. Cloud.nombre(cole.Parent) .. ")" else ""), cole and Cloud.posicion(cole))

-- Parada de bus más cercana a casa (delante del banco de la marquesina)
local function frenteParada(sign: Instance?): Vector3?
	local shelter = sign and sign:FindFirstAncestorOfClass("Model")
	local seat = shelter and shelter:FindFirstChild("Seat")
	if seat and seat:IsA("BasePart") then
		return (seat.CFrame * CFrame.new(0, 0, -2.5)).Position
	end
	return sign and Cloud.posicion(sign)
end
local paradaCasa = nearest(CollectionService:GetTagged("BusStop"), casaP)
sitio("parada", "parada de bus " .. tostring(paradaCasa and paradaCasa:GetAttribute("StopName") or ""), frenteParada(paradaCasa))
local paradaPlaza = nearest(CollectionService:GetTagged("BusStop"), spawnP)
sitio("parada_plaza", "parada de bus " .. tostring(paradaPlaza and paradaPlaza:GetAttribute("StopName") or ""), frenteParada(paradaPlaza))

-- Metro: la boca de la estación más cercana a la plaza. Se baja ANDANDO por la escalera de la calle
-- y la escalera fija del pozo (Shared/Metro.access(...).Route) hasta el vestíbulo de andenes. Allí el
-- muro de cristal de los tornos (World/Kit/MetroKit: GateGlass) separa a propósito el vestíbulo del
-- andén: se cruza tocando un torno (MetroService.onGate teletransporta al atributo Through). Por eso
-- el camino andando va de la boca a la fila de tornos, y otro del otro lado del torno al andén.
-- (La pieza MetroEntrance es el ascensor: un atajo con teletransporte, dentro de una caseta de
-- cristal de 4.4 studs; no sirve como punto de partida andando.)
local Metro = nil
pcall(function()
	Metro = require(game:GetService("ReplicatedStorage").Shared.Metro) :: any
end)
local boca = nearest(CollectionService:GetTagged("MetroEntrance"), spawnP)
local estacion = boca and boca:GetAttribute("Station")
local acceso: any = nil
if Metro and type(estacion) == "string" then
	pcall(function()
		acceso = (Metro :: any).access(estacion)
	end)
end
local rutaMetro: { Vector3 }? = acceso and acceso.Route
local lineaMetro = acceso and acceso.Line and acceso.Line.Id
sitio("metro_boca", "boca de metro (arriba de la escalera, " .. tostring(estacion or "?") .. ")", if rutaMetro then rutaMetro[1] + Vector3.new(0, 1, 0) else boca and Cloud.posicion(boca))
-- Delante del torno (lado del vestíbulo) y detrás (lado del andén)
local torno = nearest(CollectionService:GetTagged("MetroGate"), if rutaMetro then rutaMetro[#rutaMetro] else nil, function(g)
	return g:GetAttribute("Station") == estacion and (lineaMetro == nil or g:GetAttribute("Line") == lineaMetro)
end)
local tornoFuera, tornoDentro = nil, nil
if torno and torno:IsA("BasePart") and typeof(torno:GetAttribute("Through")) == "Vector3" then
	local through = torno:GetAttribute("Through") :: Vector3
	local d = Vector3.new(torno.Position.X - through.X, 0, torno.Position.Z - through.Z)
	if d.Magnitude > 0 then
		tornoFuera = Vector3.new(torno.Position.X, through.Y, torno.Position.Z) + d.Unit * 2.5
	end
	tornoDentro = through
end
sitio("metro_torno", "delante de los tornos", tornoFuera)
sitio("metro_torno_dentro", "pasados los tornos", tornoDentro)
local anden = nearest(CollectionService:GetTagged("MetroAlight"), tornoDentro, function(a)
	return a:GetAttribute("Station") == estacion and (lineaMetro == nil or a:GetAttribute("Line") == lineaMetro)
end)
sitio("metro_anden", "andén del metro" .. (if anden then " (" .. tostring(anden:GetAttribute("Station") or "?") .. " " .. tostring(anden:GetAttribute("Line") or "") .. ")" else ""), anden and Cloud.posicion(anden))

---------------------------------------------------------------------
-- 1) Suelo y sitio para estar de pie en cada uno
---------------------------------------------------------------------
local pie: { [string]: Vector3 } = {}
local faltan, malos, buenos = {}, {}, {}
for _, key in orden do
	local s = sitios[key]
	if not s then
		table.insert(faltan, key)
		continue
	end
	local hit = Cloud.suelo(s.p, 3, 10)
	if not hit then
		table.insert(malos, ("%s %s: sin suelo"):format(s.label, Cloud.v3(s.p)))
		continue
	end
	local cabe, estorbo = Cloud.cabe(hit.Position)
	if not cabe then
		table.insert(malos, ("%s %s: no cabe una persona (%s)"):format(s.label, Cloud.v3(hit.Position), Cloud.nombre(estorbo)))
	end
	pie[key] = hit.Position
	table.insert(buenos, s.label)
end
if #faltan > 0 then
	Cloud.check("Están los sitios clave en el mapa", false, "no se encuentran: " .. table.concat(faltan, ", "))
end
Cloud.check("Se puede estar de pie en los sitios clave", #malos == 0, if #malos == 0 then table.concat(buenos, "; ") else Cloud.lista(malos, 8))

---------------------------------------------------------------------
-- 2) Caminos
---------------------------------------------------------------------
-- (Los caminos del metro son solo un aviso si falla PathfindingService pero la bajada andando
-- —comprobación 3— está bien: su malla de navegación va en celdas de 4 studs y la escalera fija del
-- pozo mide 3.6 de ancho, así que el cálculo puede no pasar por donde una persona sí pasa.)
local PAREJAS = {
	{ "casa", "colegio" },
	{ "casa", "parada" },
	{ "parada", "colegio" },
	{ "plaza", "parada_plaza" },
	{ "plaza", "metro_boca" },
	{ "metro_boca", "metro_torno", metro = true },
	{ "metro_torno_dentro", "metro_anden", metro = true },
	{ "plaza", "casa" },
}

local path = PathfindingService:CreatePath({
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = true,
	AgentCanClimb = false,
	WaypointSpacing = 8,
	Costs = { Water = 20 },
})
-- En el metro, del ancho de un personaje (2 studs): las escaleras miden 3.6 y 6 de ancho
local pathMetro = PathfindingService:CreatePath({
	AgentRadius = 1,
	AgentHeight = 5,
	AgentCanJump = true,
	AgentCanClimb = false,
	WaypointSpacing = 4,
})

local rotos, bien, errores, rotosMetro = {}, {}, {}, {}
local calculados = 0
for _, pair in PAREJAS do
	local path = if pair.metro then pathMetro else path
	local a, b = pie[pair[1]], pie[pair[2]]
	local la, lb = pair[1], pair[2]
	if not a or not b then
		continue
	end
	if Cloud.quedan() < 25 then
		Cloud.salta("Caminos que faltan por calcular", "sin tiempo: " .. la .. " → " .. lb .. " y siguientes")
		break
	end
	local recta = (b - a).Magnitude
	local t = os.clock()
	local ok, err = pcall(function()
		path:ComputeAsync(a + Vector3.new(0, 2.5, 0), b + Vector3.new(0, 2.5, 0))
	end)
	local secs = os.clock() - t
	if not ok then
		table.insert(errores, ("%s → %s: %s"):format(la, lb, tostring(err)))
		continue
	end
	calculados += 1
	local status = path.Status
	local waypoints = path:GetWaypoints()
	local largo = 0
	for i = 2, #waypoints do
		largo += (waypoints[i].Position - waypoints[i - 1].Position).Magnitude
	end
	local last = waypoints[#waypoints]
	local falta = if last then (last.Position - b).Magnitude else recta
	if status == Enum.PathStatus.Success or falta <= LLEGA then
		table.insert(bien, ("%s → %s: %.0f studs andando (%.0f en línea recta, %.1f s)"):format(la, lb, largo, recta, secs))
	else
		local lejos = if recta > 3000 then " (muy lejos: el cálculo puede no llegar)" else ""
		table.insert(if pair.metro then rotosMetro else rotos, ("%s → %s: %s, se queda a %.0f studs de %.0f%s"):format(la, lb, status.Name, falta, recta, lejos))
	end
end

if calculados == 0 and #errores > 0 then
	Cloud.salta("Caminos entre los sitios clave", "PathfindingService no ha podido calcular: " .. Cloud.lista(errores, 3))
else
	if #errores > 0 then
		Cloud.check("PathfindingService calcula sin errores", false, Cloud.lista(errores, 5))
	end
	Cloud.check(("Se llega andando entre los sitios clave (%d caminos)"):format(calculados), #rotos == 0 and calculados > 0, if #rotos == 0 then Cloud.lista(bien, 8) else ("sin camino: %s"):format(Cloud.lista(rotos, 8)))
end

---------------------------------------------------------------------
-- 3) Bajar andando al metro: suelo y sitio para el cuerpo en cada paso de la bajada
---------------------------------------------------------------------
-- Cada studs por Metro.access(...).Route (calle → escalera → vestíbulo → escalera fija del pozo →
-- vestíbulo de andenes), con rayos y la forma de verdad de las piezas: sin huecos (suelo a menos de
-- 1.5 studs) y nada sólido a la altura del cuerpo (una caja de 1.6 × 3.6 que empieza a 1 stud del
-- suelo, para que los peldaños y la rampa de la escalera no cuenten).
local bajadaOk = true
if rutaMetro and #rutaMetro >= 2 then
	local huecos, tapones = {}, {}
	local pasos = 0
	for k = 2, #rutaMetro do
		local a, b = rutaMetro[k - 1], rutaMetro[k]
		local n = math.max(1, math.ceil((b - a).Magnitude / 1))
		local dir = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
		local lado = if dir.Magnitude > 0 then Vector3.new(-dir.Z, 0, dir.X).Unit else Vector3.new(1, 0, 0)
		for i = 0, if k == #rutaMetro then n else n - 1 do
			local q = a:Lerp(b, i / n)
			pasos += 1
			local hit = Cloud.suelo(q + Vector3.new(0, 0.5, 0), 1.5, 2)
			if not hit or math.abs(hit.Position.Y - q.Y) > 1.5 then
				table.insert(huecos, Cloud.v3(q))
			else
				-- Sitio para el cuerpo en el paso, o a 1 stud a un lado (en los giros del vestíbulo
				-- el camino pasa rozando las máquinas de billetes: una persona se aparta un poco)
				local cabe, estorbo = false, nil
				for _, desvio in { 0, 1, -1 } do
					local ok, what = Cloud.cabe(hit.Position + lado * desvio, nil, Vector3.new(1.6, 3.6, 1.6), 1)
					if ok then
						cabe = true
						break
					end
					estorbo = estorbo or what
				end
				if not cabe then
					table.insert(tapones, ("%s (%s)"):format(Cloud.v3(q), Cloud.nombre(estorbo)))
				end
			end
		end
	end
	bajadaOk = #huecos == 0 and #tapones == 0
	local detalle = ("%d pasos de %s a %s"):format(pasos, Cloud.v3(rutaMetro[1]), Cloud.v3(rutaMetro[#rutaMetro]))
	if #huecos > 0 then
		detalle ..= "; sin suelo en: " .. Cloud.lista(huecos, 5)
	end
	if #tapones > 0 then
		detalle ..= "; algo estorba en: " .. Cloud.lista(tapones, 5)
	end
	Cloud.check("Se baja andando de la calle al vestíbulo de andenes (" .. tostring(estacion) .. ")", bajadaOk, detalle)
elseif boca then
	Cloud.salta("Se baja andando de la calle al vestíbulo de andenes", "no se ha podido leer Shared/Metro.access en el juego publicado")
end

-- Caminos del metro con PathfindingService: aviso si solo falla el cálculo y la bajada está bien
if #rotosMetro > 0 then
	if bajadaOk and rutaMetro then
		Cloud.aviso("PathfindingService encuentra el camino por el metro", false, Cloud.lista(rotosMetro, 4) .. " (la bajada andando sí está bien: mira la comprobación de arriba)")
	else
		Cloud.check("Se llega andando por el metro (PathfindingService)", false, Cloud.lista(rotosMetro, 4))
	end
end

for key, s in sitios do
	if s then
		Cloud.info("sitio_" .. key, Cloud.v3(s.p))
	end
end
return Cloud.resultado()
