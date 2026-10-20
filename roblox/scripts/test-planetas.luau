-- Prueba de los planetas (docs/planetas.md), con Lune (sin Roblox).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-planetas.luau
--
-- Comprueba:
--   * Planetas en el espacio (PlanetBodies): los 7, fuera de la columna pero alcanzables, sin pisarse;
--     la esfera impostora tiene el MISMO tamaño en pantalla que el planeta de verdad, nunca toca la
--     cámara ni pasa del tamaño máximo de una pieza; de lejos estrella, de cerca esfera; apuntar;
--     los cerrados apartan la nave. Zone deja volar hacia ellos y los planetas son sólidos.
--   * Volar de la Estación Alba a Tefra con la geometría de verdad hasta su atmósfera.
--   * Entrada y salida (PlanetEntry): fases, avisos al servidor una sola vez, nubes que tapan la
--     pantalla justo al pasar, abortar si das la vuelta, sin respuesta → atrás; los mandos siempre son
--     tuyos; el paso deja la velocidad, el motor y el turbo igual.
--   * Pasar de la esfera a la superficie (toSurface / toSpace): el sitio cae dentro de la zona, por
--     encima del terreno, con el rumbo equivalente; ida y vuelta da lo mismo; al salir no vuelves a
--     entrar sin querer.
--   * Tefra: terreno repetible, plataforma llana, lagos, materiales que no usa Valmar, lejos de
--     Valmar y de la arena, mineral y flora en tierra, choques (suelo y lago), bordes.
--   * Aterrizar y despegar (Landing): se posa sola despacio y bajo, no en el agua ni rápido ni en una
--     cuesta; despega con la palanca; vuelo de verdad hasta posarse sin estrellarse.
--   * Servidor (PlanetService): bajar solo si está abierto (Saga 1 o tester, orden de la saga) y la nave
--     está de verdad en la atmósfera; subir solo desde el techo; bajarse solo posada; volver a subir;
--     minar a pie con las reglas de Mining (cerca, ritmo, bodega, en la nave no, agotado); puntos de
--     interés con premio una vez; AirCombatService.relocate y los "Pose" viejos.
--   * El terreno de verdad (PlanetWorld.chunk): ocupación según la altura, agua en los lagos.
--   * Texturas: sin ids todo tiene respaldo (cielos, planetas, chapa); con ids, cada cosa la suya; los
--     archivos existen, ≤ 1024 px, y LICENCIAS.md los nombra todos; el script de subida no enseña la
--     clave. Botón VISOR sin pisar los de la nave.

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3, Vector2, CFrame = roblox.Vector3, roblox.Vector2, roblox.CFrame
local check = L.check

L.services.Players = { PlayerAdded = { Connect = function() end }, PlayerRemoving = { Connect = function() end }, GetPlayers = function()
	return {}
end }
L.services.RunService.Heartbeat = { Connect = function()
	return { Disconnect = function() end }
end }

local Layers = L.load("src/shared/Cosmos/Layers")
local Planets = L.load("src/shared/Cosmos/Planets")
local PlanetBodies = L.load("src/shared/Cosmos/PlanetBodies")
local PlanetEntry = L.load("src/shared/Cosmos/PlanetEntry")
local Tefra = L.load("src/shared/Cosmos/Tefra")
local Landing = L.load("src/shared/Cosmos/Landing")
local Zone = L.load("src/shared/Cosmos/Zone")
local Stations = L.load("src/shared/Cosmos/Stations")
local Mining = L.load("src/shared/Cosmos/Mining")
local Access = L.load("src/shared/Cosmos/Access")
local EspacioLook = L.load("src/shared/Cosmos/EspacioLook")
local EspacioTextureIds = L.load("src/shared/Cosmos/EspacioTextureIds")
local ShipFlight = L.load("src/shared/AirCombat/ShipFlight")
local Arena = L.load("src/shared/AirCombat/Arena")

local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-3)
end

local function facing(look: Vector3): CFrame
	return CFrame.new(Vector3.zero) * PlanetEntry.facing(look)
end

---------------------------------------------------------------------
print("\n🪐 Los planetas en el espacio (PlanetBodies)")
---------------------------------------------------------------------
do
	check(#PlanetBodies.List == 7, "los 7 planetas tienen cuerpo")
	local sameIds = true
	for _, p in Planets.List do
		sameIds = sameIds and PlanetBodies.ById[p.Id] ~= nil
	end
	check(sameIds, "los mismos que la Saga 2 (Tefra, Siroco, Talasa, Nivalis, Umbria, Miasma, Vertice)")
	local outside, reachable, apart = true, true, true
	for i, b in PlanetBodies.List do
		local flat = Vector3.new(b.Center.X, 0, b.Center.Z).Magnitude
		outside = outside and flat - b.Radius > Layers.Half
		-- el punto de su zona de llegada más cercano al centro del espacio queda dentro de la columna
		local toward = (PlanetBodies.Hub - b.Center).Unit
		local edge = b.Center + toward * (PlanetBodies.approachRadius(b) - 50)
		reachable = reachable and Layers.inColumn(edge) and edge.Y > Layers.SpaceY and edge.Y < Layers.TopY
		for j = i + 1, #PlanetBodies.List do
			local o = PlanetBodies.List[j]
			apart = apart and (b.Center - o.Center).Magnitude > PlanetBodies.entryRadius(b) + PlanetBodies.entryRadius(o) + 500
		end
	end
	check(outside, "todos fuera de la columna del espacio (no tapan estaciones ni asteroides)")
	if not reachable then
		for _, b in PlanetBodies.List do
			local toward = (PlanetBodies.Hub - b.Center).Unit
			local edge = b.Center + toward * (PlanetBodies.approachRadius(b) - 50)
			print(("    %s borde %s columna %s"):format(b.Id, tostring(edge), tostring(Layers.inColumn(edge))))
		end
	end
	check(reachable, "pero su zona de llegada empieza dentro de la columna: se llega volando")
	check(apart, "no se pisan entre ellos (ni sus atmósferas)")
	local farFromSurface = true
	for _, b in PlanetBodies.List do
		farFromSurface = farFromSurface and (b.Center - Tefra.Origin).Magnitude > 20000 and (b.Center - Vector3.new(Arena.Center and Arena.Center.X or 24000, 0, 24000)).Magnitude > 8000
	end
	check(farFromSurface, "lejos de la superficie de Tefra y de la arena de pruebas")
	-- Dibujo: el mismo tamaño en pantalla, sin tocar la cámara, sin pasar de una pieza
	local lon = PlanetBodies.ById.Tefra
	local ok, lastPx, monotonic = true, -1, true
	for _, alt in { 60000, 30000, 15000, 8000, 4000, 2000, 1200, 950, 600, 300, 160 } do
		local cam = lon.Center + (PlanetBodies.Hub - lon.Center).Unit * (lon.Radius + alt)
		local v = PlanetBodies.view(lon, cam, 70, 720)
		local ratio = lon.Radius / v.Distance
		ok = ok and near(v.DrawRadius / v.DrawDistance, ratio, 1e-6) and v.DrawRadius <= PlanetBodies.PartMax and v.DrawDistance - v.DrawRadius > 0 and v.DrawDistance <= PlanetBodies.DrawMax
		monotonic = monotonic and v.Px >= lastPx
		lastPx = v.Px
	end
	check(ok, "esfera impostora: mismo tamaño en pantalla, más pequeña que una pieza (≤ 2048) y nunca toca la cámara")
	check(monotonic, "al acercarte crece en pantalla")
	local farV = PlanetBodies.view(lon, Vector3.new(0, 0, 0), 70, 720)
	local stationV = PlanetBodies.view(lon, Stations.List[1].Center, 70, 720)
	local closeV = PlanetBodies.view(lon, lon.Center + Vector3.new(0, lon.Radius + 3000, 0), 70, 720)
	check(farV.Px > 0 and stationV.Body > 0.99 and closeV.Body == 1 and closeV.Star == 0, ("de lejos es pequeño (%.0f px desde Valmar), desde la estación ya es esfera (%.0f px)"):format(farV.Px, stationV.Px))
	local tiny = PlanetBodies.view(lon, lon.Center + Vector3.new(0, 0, 900000), 70, 720)
	check(tiny.Star == 1 and tiny.Body == 0, "muy lejos se ve como la estrella de siempre (la esfera se funde)")
	local hub = PlanetBodies.Hub
	check(PlanetBodies.aimed(hub, (lon.Center - hub).Unit) == lon and PlanetBodies.aimed(hub, Vector3.new(0, -1, 0)) == nil, "apuntar con el morro al planeta lo elige")
	local inside = lon.Center + (hub - lon.Center).Unit * (PlanetBodies.entryRadius(lon) - 10)
	local push = PlanetBodies.repel(inside, function()
		return false
	end)
	check(push and push:Dot((inside - lon.Center).Unit) > 0.99, "un planeta cerrado aparta la nave de su atmósfera")
	check(PlanetBodies.repel(inside, function(id)
		return id == "Tefra"
	end) == nil, "uno abierto, no")
	-- Zone: se puede volar hacia ellos y son sólidos
	local outCol = lon.Center + (hub - lon.Center).Unit * (PlanetBodies.entryRadius(lon) + 100)
	check(not Layers.inColumn(outCol) and Zone.contains(outCol, 0) and Zone.bounds(outCol) == nil, "junto a un planeta, fuera de la columna: dentro de la zona y sin paredes")
	local lost: Vector3? = nil
	for a = 0, 359, 5 do
		for _, y in { 3700, 5000, 6500, 8000 } do
			local p = Vector3.new(math.sin(math.rad(a)) * (Layers.Half + 1500), y, -math.cos(math.rad(a)) * (Layers.Half + 1500))
			if not lost and not PlanetBodies.approachAt(p, 450) and not Layers.inColumn(p, 450) then
				lost = p
			end
		end
	end
	lost = lost or Vector3.new(0, 6000, 99999)
	check(Zone.bounds(lost) ~= nil and not Zone.contains(lost, 400), "lejos de todo planeta, la columna sigue teniendo paredes")
	check(Zone.collide(lon.Center + Vector3.new(0, lon.Radius - 1, 0), 6) == "un planeta", "los planetas son sólidos (se baja por la atmósfera)")
end

---------------------------------------------------------------------
print("\n🚀 Volar de la Estación Alba a la atmósfera de Tefra (ShipFlight + Zone)")
---------------------------------------------------------------------
do
	local lon = PlanetBodies.ById.Tefra
	local start = Stations.launch(Stations.ById.Alba)
	local sim = ShipFlight.new("Caza", start, "Space")
	local env = {
		mode = Zone.modeAt,
		collide = Zone.collide,
		bounds = function(pos)
			local back = Zone.bounds(pos)
			local push = PlanetBodies.repel(pos, function(id)
				return id == "Tefra"
			end)
			if push then
				back = if back then (back + push * 2).Unit else push
			end
			return back
		end,
	}
	local E = PlanetEntry.new()
	local reached, crashed, descend, t = false, nil, 0, 0
	for _ = 1, 30 * 240 do
		-- piloto automático: el morro hacia el planeta
		sim.Rot = facing((lon.Center - sim.Pos).Unit)
		local events = ShipFlight.advance(sim, { Pitch = 0, Yaw = 0, Roll = 0, SetThrottle = 1, Boost = true }, 1 / 30, env)
		t += 1 / 30
		if table.find(events, "Crash") then
			crashed = sim.Crashed
			break
		end
		local act = PlanetEntry.update(E, { World = "Cosmos", Pos = sim.Pos, Look = sim.Rot.LookVector, Open = function(id)
			return id == "Tefra"
		end }, 1 / 30)
		if act == "Descend" then
			descend += 1
			reached = true
			break
		end
	end
	check(reached and not crashed, ("de la estación a la atmósfera de Tefra volando (%.0f s), sin chocar con nada%s"):format(t, if crashed then " (choca con " .. tostring(crashed) .. ")" else ""))
	check(descend == 1 and E.Phase == "Descending", "al fondo de la entrada se pide «Descend» una vez")
end

---------------------------------------------------------------------
print("\n☁️ Entrada y salida (PlanetEntry)")
---------------------------------------------------------------------
do
	local lon = PlanetBodies.ById.Tefra
	local up = PlanetEntry.frame(lon)
	local open = function(id)
		return id == "Tefra"
	end
	local E = PlanetEntry.new()
	local function at(depth: number): Vector3
		return lon.Center + up * (lon.Radius + depth)
	end
	PlanetEntry.update(E, { World = "Cosmos", Pos = at(PlanetBodies.EntryDepth - 20), Look = up, Open = open }, 0.1)
	check(E.Phase == "Space", "dentro de la atmósfera pero alejándote: no entras")
	PlanetEntry.update(E, { World = "Cosmos", Pos = at(PlanetBodies.EntryDepth - 20), Look = -up, Open = function()
		return false
	end }, 0.1)
	check(E.Phase == "Space", "un planeta cerrado: no entras")
	PlanetEntry.update(E, { World = "Cosmos", Pos = at(PlanetBodies.EntryDepth - 20), Look = -up, Open = open }, 0.1)
	check(E.Phase == "Entry" and E.Body == "Tefra", "hacia dentro y abierto: empieza la entrada")
	local lastP, mono, sent, maxCloud, heatMid, control = -1, true, 0, 0, 0, true
	for d = PlanetBodies.EntryDepth - 20, PlanetBodies.RelocDepth - 40, -20 do
		local act = PlanetEntry.update(E, { World = "Cosmos", Pos = at(d), Look = -up, Open = open }, 0.1)
		if act == "Descend" then
			sent += 1
		end
		if E.Phase == "Entry" then
			mono = mono and E.P >= lastP
			lastP = E.P
			local fx = PlanetEntry.effects(E, 200)
			if E.P > 0.4 and E.P < 0.6 then
				heatMid = math.max(heatMid, fx.Heat)
			end
		end
		maxCloud = math.max(maxCloud, PlanetEntry.effects(E, 200).Cloud)
		control = control and PlanetEntry.inControl(E)
	end
	check(control, "en todas las fases los mandos son tuyos (nada los bloquea)")
	check(mono, "cuanto más hondo, más entrada (calor, nubes, cielo)")
	check(heatMid > 0.5, ("a media entrada el casco ya brilla de calor (%.2f)"):format(heatMid))
	check(sent == 1 and E.Phase == "Descending", "«Descend» una sola vez")
	check(maxCloud >= 0.999 and PlanetEntry.effects(E).Cloud == 1, "al pasar a la superficie, las nubes tapan la pantalla entera")
	-- Abortar: dar la vuelta
	local E2 = PlanetEntry.new()
	PlanetEntry.update(E2, { World = "Cosmos", Pos = at(PlanetBodies.EntryDepth - 50), Look = -up, Open = open }, 0.1)
	PlanetEntry.update(E2, { World = "Cosmos", Pos = at(PlanetBodies.EntryDepth + 200), Look = up, Open = open }, 0.1)
	check(E2.Phase == "Space" and E2.P == 0, "si das la vuelta y sales, se acaba la entrada")
	-- Sin respuesta del servidor
	local E3 = PlanetEntry.new()
	E3.Phase, E3.Body, E3.Sent = "Descending", "Tefra", true
	local act = nil
	for _ = 1, 50 do
		act = PlanetEntry.update(E3, { World = "Cosmos", Pos = at(100), Look = -up, Open = open }, 0.1)
		if act then
			break
		end
	end
	check(act == "Timeout" and E3.Phase ~= "Descending", "si el servidor no contesta, vuelve atrás (y se avisa)")
	-- Llegada
	PlanetEntry.relocated(E, "Planet", "Tefra")
	check(E.Phase == "Arrival" and PlanetEntry.effects(E).Cloud > 0.99, "llegada: aún entre nubes")
	local S = Tefra.Surface
	local arrivePos = Tefra.toWorld(0, 0, S.ArriveY)
	local clouds = {}
	for _ = 1, 30 do
		PlanetEntry.update(E, { World = "Planet", Pos = arrivePos, Look = Vector3.new(0, -0.3, -1).Unit, Surface = S }, 0.1)
		table.insert(clouds, PlanetEntry.effects(E).Cloud)
	end
	check(E.Phase == "Surface" and clouds[#clouds] == 0 and clouds[5] < clouds[1], "las nubes se abren y estás sobre Tefra")
	-- Subir: nubes, «Ascend» una vez y de vuelta
	local asc = 0
	for y = S.ClimbY - 100, S.CeilingY + 60, 40 do
		local a = PlanetEntry.update(E, { World = "Planet", Pos = Tefra.toWorld(0, 0, y), Look = Vector3.new(0, 0.6, -0.8), Surface = S }, 0.1)
		if a == "Ascend" then
			asc += 1
		end
	end
	check(asc == 1 and E.Phase == "Ascending" and PlanetEntry.effects(E).Cloud == 1, "subiendo: nubes y «Ascend» una sola vez en el techo")
	PlanetEntry.relocated(E, "Cosmos", "Tefra")
	for _ = 1, 30 do
		PlanetEntry.update(E, { World = "Cosmos", Pos = at(PlanetBodies.EntryDepth + 200), Look = up, Open = open }, 0.1)
	end
	check(E.Phase == "Space", "de vuelta en el espacio")
	-- El paso no toca la velocidad, el motor ni el turbo
	local sim = ShipFlight.new("Caza", CFrame.new(at(200)), "Space")
	sim.Speed, sim.Throttle, sim.Boost = 287, 0.9, 0.42
	local cf = PlanetEntry.toSurface(lon, S, at(PlanetBodies.RelocDepth), -up)
	PlanetEntry.applyRelocation(sim, cf)
	check(sim.Speed == 287 and sim.Throttle == 0.9 and sim.Boost == 0.42 and (sim.Pos - cf.Position).Magnitude < 1e-3, "al pasar: misma velocidad, motor y turbo (solo cambia el sitio)")
	local src = fs.readFile("src/client/Controllers/AirCombatClient.luau")
	check(string.find(src, "PlanetEntry.applyRelocation(sim, p.CFrame)", 1, true) ~= nil, "y el cliente lo hace así al recibir «Relocate»")
end

---------------------------------------------------------------------
print("\n🗺️ De la esfera a la superficie y al revés")
---------------------------------------------------------------------
do
	local lon = PlanetBodies.ById.Tefra
	local S = Tefra.Surface
	local up, east, north = PlanetEntry.frame(lon)
	check(near(up:Dot(east), 0) and near(up:Dot(north), 0) and near(east:Dot(north), 0), "ejes del planeta perpendiculares")
	local cf0 = PlanetEntry.toSurface(lon, S, lon.Center + up * (lon.Radius + 150), -up)
	check(math.abs(cf0.Position.X - S.Origin.X) < 1 and math.abs(cf0.Position.Z - S.Origin.Z) < 1, "entrar por la cara que mira a Valmar: al centro de la zona")
	local maxH = -math.huge
	for lx = -1500, 1500, 60 do
		for lz = -1500, 1500, 60 do
			maxH = math.max(maxH, Tefra.heightAt(S.Origin.X + lx, S.Origin.Z + lz))
		end
	end
	local allIn, allAbove, headingOk, roundOk, noReenter = true, true, true, true, true
	local r = Tefra.rng(99)
	for _ = 1, 60 do
		local dir = (up + east * (r() * 2 - 1) * 0.9 + north * (r() * 2 - 1) * 0.9).Unit
		local pos = lon.Center + dir * (lon.Radius + 150)
		-- morro: hacia dentro con algo de rumbo
		local tangent = (east * (r() * 2 - 1) + north * (r() * 2 - 1))
		tangent = tangent - dir * tangent:Dot(dir)
		local look = (-dir * (0.3 + r() * 0.6) + tangent.Unit).Unit
		local cf, surf = PlanetEntry.toSurface(lon, S, pos, look)
		local lx, lz = Tefra.toLocal(cf.Position)
		allIn = allIn and math.abs(lx) <= S.Half - PlanetEntry.EdgeMargin + 0.01 and math.abs(lz) <= S.Half - PlanetEntry.EdgeMargin + 0.01
		allAbove = allAbove and cf.Position.Y - Tefra.heightAt(cf.Position.X, cf.Position.Z) > 600
		headingOk = headingOk and near(cf.LookVector:Dot(surf), 1, 1e-4) and surf.Y < 0
		-- la parte horizontal del rumbo se conserva (mismo ángulo respecto a este/norte)
		local e = east - dir * east:Dot(dir)
		e = e.Unit
		local n = dir:Cross(e).Unit
		local a1 = math.atan2(look:Dot(n), look:Dot(e))
		local a2 = math.atan2(-surf.Z, surf.X)
		headingOk = headingOk and math.abs(math.atan2(math.sin(a1 - a2), math.cos(a1 - a2))) < 0.02
		-- ida y vuelta
		if math.abs(lx) < S.Half - PlanetEntry.EdgeMargin - 1 and math.abs(lz) < S.Half - PlanetEntry.EdgeMargin - 1 then
			local back = PlanetEntry.toSpace(lon, S, cf.Position, Vector3.new(surf.X, -surf.Y, surf.Z))
			local nBack = (back.Position - lon.Center).Unit
			roundOk = roundOk and nBack:Dot(dir) > 0.9999
		end
		-- al salir (subiendo) apareces fuera de la entrada y alejándote: no vuelves a entrar
		local out = PlanetEntry.toSpace(lon, S, Tefra.toWorld(lx, lz, S.CeilingY), Vector3.new(surf.X, 0.5, surf.Z).Unit)
		local E = PlanetEntry.new()
		PlanetEntry.update(E, { World = "Cosmos", Pos = out.Position, Look = out.LookVector, Open = function()
			return true
		end }, 0.1)
		noReenter = noReenter and E.Phase == "Space" and (out.Position - lon.Center).Magnitude > PlanetBodies.entryRadius(lon) and out.LookVector:Dot((out.Position - lon.Center).Unit) > 0
	end
	check(allIn, "el sitio de llegada cae siempre dentro de la zona de la superficie")
	check(allAbove, ("y por encima del terreno (llegas a %d; el monte más alto, %.0f)"):format(S.ArriveY, maxH))
	check(headingOk, "con el mismo rumbo (este/norte → X/−Z) y bajando")
	check(roundOk, "ida y vuelta: el mismo punto del planeta")
	check(noReenter, "al salir apareces fuera de la entrada y alejándote (no vuelves a entrar sin querer)")
	check(S.ArriveY > maxH + 500 and S.ClimbY > S.ArriveY + 200 and S.CeilingY > S.ClimbY + 300, "alturas: monte < llegada < empieza la salida < techo")
end

---------------------------------------------------------------------
print("\n🏔️ La superficie de Tefra")
---------------------------------------------------------------------
do
	local O = Tefra.Origin
	check(Tefra.heightAt(O.X + 123, O.Z - 456) == Tefra.heightAt(O.X + 123, O.Z - 456), "el terreno sale igual cada vez (semilla)")
	check(not Layers.inColumn(O, 3000) and (O - Vector3.new(24000, 0, 24000)).Magnitude > 20000, "lejos de Valmar, del espacio y de la arena de pruebas")
	local pad = Tefra.padY()
	local flat = true
	for a = 0, 7 do
		for _, d in { 0, 15, 30, 40 } do
			local h = Tefra.heightAt(O.X + math.cos(a) * d, O.Z + math.sin(a) * d)
			flat = flat and math.abs(h - pad) < 0.6
		end
	end
	check(flat and pad > Tefra.WaterY + 10, "la plataforma de aterrizaje es llana y está en seco")
	local water, total = 0, 0
	local mats = {}
	local allowed = true
	local maxSlopeOk = true
	for lx = -1400, 1400, 50 do
		for lz = -1400, 1400, 50 do
			local x, z = O.X + lx, O.Z + lz
			local h = Tefra.heightAt(x, z)
			total += 1
			if h < Tefra.WaterY then
				water += 1
			end
			local m = Tefra.materialAt(x, z, h)
			mats[m] = true
			allowed = allowed and Tefra.TerrainColors[m] ~= nil
		end
	end
	check(water > 0 and water / total < 0.15, ("lagos de agua (%.1f %% de la zona)"):format(water / total * 100))
	check(allowed, "el terreno solo usa materiales que el de Valmar no usa (se pueden teñir sin tocar la ciudad)")
	local valmarTerrain = { Grass = true, LeafyGrass = true, Rock = true, Sand = true, Ground = true, Mud = true, Water = true }
	local clash = false
	for m in Tefra.TerrainColors do
		clash = clash or valmarTerrain[m] == true
	end
	check(not clash, "(ni césped, ni roca, ni arena, ni tierra, ni barro de Valmar)")
	local n = 0
	for _ in mats do
		n += 1
	end
	check(n >= 5, ("variedad de suelo (%d materiales: tierra malva, ceniza, peñascos, orilla, quemado…)"):format(n))
	-- Mineral
	local nodes = Tefra.nodes()
	local onLand, spaced = true, true
	local ores = {}
	for i, nd in ipairs(nodes) do
		local _, w = Tefra.groundAt(nd.Pos.X, nd.Pos.Z)
		onLand = onLand and not w and Tefra.inRegion(nd.Pos) and near(nd.Pos.Y, Tefra.heightAt(nd.Pos.X, nd.Pos.Z), 0.01)
		ores[nd.Ore] = true
		for j = i + 1, #nodes do
			spaced = spaced and (nd.Pos - nodes[j].Pos).Magnitude > 60
		end
	end
	check(#nodes == Tefra.NodeCount and onLand and spaced, ("%d minerales en tierra y separados"):format(#nodes))
	check(ores.Obsidiana and Mining.Ores.Obsidiana ~= nil and (ores.Hierro or ores.Cobalto), "obsidiana de Tefra (solo de Tefra) y también hierro o cobalto")
	check(Tefra.node(nodes[1].Id) == nodes[1], "cada mineral con su id")
	local decorOk = true
	for kind, count in Tefra.DecorCounts do
		local list = Tefra.decor(kind)
		decorOk = decorOk and #list == count
		for _, d in list do
			local _, w = Tefra.groundAt(d.Pos.X, d.Pos.Z)
			decorOk = decorOk and not w
		end
	end
	check(decorOk, "flora (pelusa, arbustos) y rocas en tierra, las justas para el móvil")
	local pieces = Tefra.DecorCounts.Pelusa * 2 + Tefra.DecorCounts.Arbusto * 3 + Tefra.DecorCounts.Roca + #nodes * 6
	check(pieces < 1000, ("piezas de encima razonables para el móvil (≈ %d)"):format(pieces))
	-- Choques y bordes
	local x, z = O.X + 40, O.Z + 60
	local h = Tefra.heightAt(x, z)
	check(Tefra.collide(Vector3.new(x, h + 3, z), 6) == "el suelo" and Tefra.collide(Vector3.new(x, h + 30, z), 6) == nil, "chocar con el suelo (sin rayos: la misma cuenta del terreno)")
	local lake = Tefra.Lakes[1]
	check(Tefra.collide(Tefra.toWorld(lake.X, lake.Z, Tefra.WaterY + 2), 6) == "el lago", "y con el lago")
	local edge = Tefra.toWorld(Tefra.Half - 100, 0, 800)
	check(Tefra.bounds(edge) and Tefra.bounds(edge).X < 0 and Tefra.bounds(Tefra.toWorld(0, 0, 800)) == nil, "en el borde de la zona, la nave gira hacia dentro")
	check(Tefra.bounds(Tefra.toWorld(0, 0, Tefra.CeilingY + 100)) == nil, "arriba no hay techo: subir es volver al espacio")
	local cp = Tefra.checkpoint()
	check(cp.Position.Y - Tefra.heightAt(cp.Position.X, cp.Position.Z) > 200 and Tefra.inRegion(cp.Position), "si te estrellas, reapareces volando por encima del terreno")
	check(Tefra.modeAt(cp.Position) == "Atmos" and not Tefra.safeAt(cp.Position), "con gravedad (modo atmósfera)")
end

---------------------------------------------------------------------
print("\n🛬 Aterrizar y despegar (Landing)")
---------------------------------------------------------------------
do
	local O = Tefra.Origin
	local function ground(x: number, z: number)
		local h, w = Tefra.groundAt(x, z)
		return h, w, Tefra.slopeAt(x, z)
	end
	local pad = O.Y + Tefra.padY()
	local function simAt(lx: number, lz: number, agl: number, speed: number, look: Vector3?)
		local p = Tefra.toWorld(lx, lz, 0)
		p = Vector3.new(p.X, Tefra.heightAt(p.X, p.Z) + agl, p.Z)
		local s = ShipFlight.new("Caza", CFrame.new(p) * PlanetEntry.facing(look or Vector3.new(1, -0.05, 0).Unit), "Atmos")
		s.Speed = speed
		return s
	end
	local L1 = Landing.new()
	local s1 = simAt(-10, 0, 20, 150)
	local handled = Landing.step(L1, s1, {}, 1 / 30, ground)
	check(not handled and L1.Phase == "Flying", "deprisa no se posa (pasa rasante)")
	local s2 = simAt(-10, 0, 20, 60)
	local L2 = Landing.new()
	local touched = false
	for _ = 1, 90 do
		local _, ev = Landing.step(L2, s2, {}, 1 / 30, ground)
		touched = touched or ev == "Touchdown"
	end
	check(touched and L2.Phase == "Landed" and Landing.landed(L2), "despacio y bajo: se posa sola")
	check(near(s2.Pos.Y, Tefra.heightAt(s2.Pos.X, s2.Pos.Z) + Landing.RestHeight, 0.01) and s2.Speed == 0 and near(s2.Rot.UpVector.Y, 1, 1e-3), "posada: sobre el tren, quieta y nivelada")
	check(Zone and Tefra.collide(s2.Pos, ShipFlight.Specs.Caza.Radius * 0.7) == nil, "y el servidor no la ve chocar (radio de choque del servidor)")
	local lake = Tefra.Lakes[1]
	local s3 = ShipFlight.new("Caza", CFrame.new(Tefra.toWorld(lake.X, lake.Z, Tefra.WaterY + 15)), "Atmos")
	s3.Speed = 50
	local L3 = Landing.new()
	Landing.step(L3, s3, {}, 1 / 30, ground)
	check(L3.Phase == "Flying", "sobre el agua no se posa")
	-- Una cuesta: buscamos un sitio empinado
	local steep: Vector3? = nil
	for lx = -1300, 1300, 37 do
		for lz = -1300, 1300, 41 do
			local x, z = O.X + lx, O.Z + lz
			if Tefra.slopeAt(x, z) > 0.7 and not select(2, Tefra.groundAt(x, z)) then
				steep = Vector3.new(x, Tefra.heightAt(x, z) + 15, z)
				break
			end
		end
		if steep then
			break
		end
	end
	if steep then
		local s4 = ShipFlight.new("Caza", CFrame.new(steep), "Atmos")
		s4.Speed = 50
		local L4 = Landing.new()
		Landing.step(L4, s4, {}, 1 / 30, ground)
		check(L4.Phase == "Flying", "en una cuesta empinada tampoco")
	end
	-- En tierra: quieta sin tocar nada; palanca arriba → despega
	for _ = 1, 30 do
		Landing.step(L2, s2, { Pitch = 0, Yaw = 0, Roll = 0, SetThrottle = 0.65 }, 1 / 30, ground)
	end
	check(L2.Phase == "Landed", "posada, se queda quieta (el motor del móvil a crucero no la hace despegar)")
	local groundY = Tefra.heightAt(s2.Pos.X, s2.Pos.Z)
	local evs = {}
	for _ = 1, 60 do
		local _, ev = Landing.step(L2, s2, { Pitch = 1, Yaw = 0, Roll = 0 }, 1 / 30, ground)
		if ev then
			table.insert(evs, ev)
		end
	end
	check(table.find(evs, "TakeOff") and table.find(evs, "Airborne") and L2.Phase == "Flying", "palanca arriba: despegue vertical y a volar")
	check(s2.Pos.Y - groundY >= Landing.TakeOffRise and s2.Speed >= Landing.TakeOffSpeed, "sube recta y sale con velocidad")
	local handledAgain = Landing.step(L2, s2, {}, 1 / 30, ground)
	check(not handledAgain and L2.Cool > 0, "y no se vuelve a posar enseguida")
	-- Vuelo de verdad: llegar despacio a la plataforma frenando y posarse sin estrellarse
	local env = { mode = Tefra.modeAt, collide = Tefra.collide, bounds = Tefra.bounds }
	local s5 = ShipFlight.new("Caza", CFrame.new(Tefra.toWorld(-140, 0, pad + 36)) * PlanetEntry.facing(Vector3.new(1, 0, 0)), "Atmos")
	s5.Speed = 110
	local L5 = Landing.new()
	local crashed, landed = nil, false
	for _ = 1, 30 * 20 do
		local input = { Pitch = 0, Yaw = 0, Roll = 0, Brake = true }
		local done = Landing.step(L5, s5, input, 1 / 30, ground)
		if not done then
			local ev = ShipFlight.advance(s5, input, 1 / 30, env)
			if table.find(ev, "Crash") then
				crashed = s5.Crashed
				break
			end
		end
		if L5.Phase == "Landed" then
			landed = true
			break
		end
	end
	check(landed and not crashed, ("frenando sobre la plataforma: se posa sin estrellarse%s"):format(if crashed then " (choca con " .. tostring(crashed) .. ")" else ""))
	-- El servidor: ¿posada?
	local PS0 = L.load("src/server/Services/PlanetService")
	check(PS0.isLanded(Tefra, s5.Pos, Vector3.zero) and not PS0.isLanded(Tefra, s5.Pos + Vector3.new(0, 40, 0), Vector3.zero) and not PS0.isLanded(Tefra, s5.Pos, Vector3.new(40, 0, 0)), "servidor: posada sí; alta o deprisa, no")
	check(not PS0.isLanded(Tefra, Tefra.toWorld(lake.X, lake.Z, Tefra.WaterY + 3), Vector3.zero), "servidor: sobre el agua, no")
	L.reset("src/server/Services/PlanetService")
end

---------------------------------------------------------------------
print("\n🖥️ Servidor: PlanetService (bajar, subir, bajarse, minar a pie)")
---------------------------------------------------------------------
do
	local lon = PlanetBodies.ById.Tefra
	local up = PlanetEntry.frame(lon)
	local data = { Money = 100, Story = { Completed = {} }, Space = { Chispas = 0, Ore = {}, Missions = {}, Mined = 0, Kills = 0, Done = 0, Planets = {} } }
	local status = "Locked"
	local events = {}
	L.mock("src/server/Services/DataService", {
		get = function()
			return data
		end,
		addMoney = function(_, amount)
			data.Money += amount
			return true
		end,
	})
	L.mock("src/server/Services/SpaceService", {
		planetStatus = function(_, id)
			if id ~= "Tefra" then
				return if status == "Locked" then "Locked" else "Soon", nil
			end
			return status, nil
		end,
		spaceData = function()
			return data.Space
		end,
		canFly = function()
			return status ~= "Locked", "Locked"
		end,
		board = function()
			return false
		end,
		shipState = function()
			return { Hull = 80, Missiles = 3 }
		end,
		objectiveFor = function()
			return function()
				return "espacio"
			end
		end,
		event = function(_, ev)
			table.insert(events, ev)
		end,
		onExitRequest = function() end,
	})
	local ac = { World = "Cosmos", Pos = lon.Center + up * (PlanetBodies.relocRadius(lon) + 20), Look = -up, Vel = Vector3.zero, Down = false, Planet = nil }
	local acLog = {}
	L.mock("src/server/Services/AirCombatService", {
		status = function()
			if not ac.World then
				return nil
			end
			return { Pos = ac.Pos, Look = ac.Look, Vel = ac.Vel, Down = ac.Down, World = ac.World, Planet = ac.Planet, CFrame = CFrame.new(ac.Pos) * PlanetEntry.facing(ac.Look) }
		end,
		world = function()
			return ac.World
		end,
		relocate = function(_, cf, opts)
			table.insert(acLog, { "relocate", cf, opts })
			ac.World = opts.World
			ac.Planet = opts.Planet
			ac.Pos = cf.Position
			ac.Look = cf.LookVector
			return true
		end,
		setObjective = function() end,
		setReturn = function(_, cf)
			table.insert(acLog, { "return", cf })
		end,
		exit = function(_, reason)
			table.insert(acLog, { "exit", reason })
			ac.World = nil
		end,
		enter = function(_, opts)
			table.insert(acLog, { "enter", opts })
			ac.World = opts.World
			ac.Planet = opts.Planet
			return true
		end,
	})
	local parked = {}
	local lit = {}
	L.mock("src/server/World/PlanetWorld", {
		ensure = function()
			return "Building"
		end,
		park = function(player, cf)
			parked[player] = { PrimaryPart = { Position = cf.Position, CFrame = cf } }
		end,
		unpark = function(player)
			parked[player] = nil
		end,
		parked = function(player)
			return parked[player]
		end,
		setNodeLit = function(id, on)
			lit[id] = on
		end,
		prompts = function()
			return { Node = {}, Poi = {}, Ship = {} }
		end,
		setupLooks = function()
			return {}
		end,
	})
	local PS = L.load("src/server/Services/PlanetService")
	local player = L.player("Piloto", 4242)
	local sent = {}
	local remoteFake = { FireClient = function(_, _p, kind, payload)
		table.insert(sent, { kind, payload })
	end }
	-- (el remoto de mentira: lo que init crea)
	local remotes = { FindFirstChild = function(_, name)
		return if name == "Planet" then { OnServerEvent = { Connect = function() end }, FireClient = remoteFake.FireClient } else nil
	end }
	L.services.ReplicatedStorage.Remotes = remotes
	L.services.Players = { PlayerAdded = { Connect = function() end }, PlayerRemoving = { Connect = function() end }, GetPlayers = function()
		return {}
	end }
	L.services.RunService.Heartbeat = { Connect = function()
		return { Disconnect = function() end }
	end }
	pcall(PS.init)
	-- Cerrado
	check(not PS.descend(player) and #acLog == 0, "sin la Saga 1: no se baja (aunque estés en la atmósfera)")
	status = "Soon"
	check(PS.statusFor(player).Siroco == "Soon", "los otros planetas: «próximamente»")
	status = "Ready"
	check(PS.statusFor(player).Tefra == "Ready", "Tefra abierto (Saga 1 terminada o tester)")
	-- Lejos de la atmósfera: no
	local real = ac.Pos
	ac.Pos = lon.Center + up * (PlanetBodies.entryRadius(lon) + 2000)
	check(not PS.descend(player), "pedir «Descend» lejos del planeta: no (lo comprueba el servidor)")
	ac.Pos = real
	check(PS.descend(player) and acLog[1][1] == "relocate" and acLog[1][3].World == "Planet" and acLog[1][3].Planet == "Tefra", "en el fondo de la atmósfera: a la superficie (relocate, sin cortar el vuelo)")
	local cf = acLog[1][2]
	check(Tefra.inRegion(cf.Position) and cf.Position.Y == Tefra.ArriveY and player:GetAttribute("Planeta") == "Tefra", "dentro de la zona de Tefra, a la altura de llegada")
	check(player:GetAttribute("SpaceReturn") == Access.arrival().Position, "si te desconectas en el planeta, vuelves al puerto espacial")
	-- Subir
	check(not PS.ascend(player), "subir desde abajo: no")
	ac.Pos = Tefra.toWorld(100, -200, Tefra.CeilingY + 10)
	ac.Look = Vector3.new(0.3, 0.7, -0.6).Unit
	check(PS.ascend(player) and ac.World == "Cosmos" and player:GetAttribute("Planeta") == nil, "desde el techo: de vuelta al espacio")
	check((ac.Pos - lon.Center).Magnitude > PlanetBodies.entryRadius(lon), "junto a Tefra, fuera de su atmósfera")
	-- Bajarse: solo posada
	ac.World, ac.Planet = "Planet", "Tefra"
	local spot = Tefra.toWorld(10, 5, Tefra.padY() + 30)
	ac.Pos, ac.Look, ac.Vel = spot, Vector3.new(1, 0, 0), Vector3.new(30, 0, 0)
	table.clear(acLog)
	check(not PS.disembark(player) and #acLog == 0, "volando: no te puedes bajar")
	ac.Pos = Vector3.new(spot.X, Tefra.heightAt(spot.X, spot.Z) + Landing.RestHeight, spot.Z)
	ac.Vel = Vector3.zero
	check(PS.disembark(player) and parked[player] ~= nil, "posada: te bajas y la nave se queda aparcada")
	local ret = nil
	for _, e in acLog do
		if e[1] == "return" then
			ret = e[2]
		end
	end
	check(ret and ret.Position.Y > Tefra.heightAt(ret.Position.X, ret.Position.Z) and (ret.Position - ac.Pos).Magnitude < 20, "apareces al lado de la nave, de pie sobre el suelo")
	local pcf = parked[player].PrimaryPart.CFrame
	check(near(pcf.UpVector.Y, 1, 1e-3) and near(pcf.Position.Y, Tefra.heightAt(pcf.Position.X, pcf.Position.Z) + Landing.RestHeight, 0.01), "la nave aparcada, nivelada sobre su tren")
	-- Volver a subir
	player.Character = { FindFirstChild = function(_, name)
		if name == "HumanoidRootPart" then
			return { Position = ret.Position }
		end
		return nil
	end }
	table.clear(acLog)
	check(PS.reboard(player) and acLog[1][1] == "enter" and acLog[1][2].World == "Planet" and acLog[1][2].Landed == true and acLog[1][2].Hull == 80, "«Subir a la nave»: vuelves a ella posada (con su casco y misiles)")
	check(parked[player] == nil and (acLog[1][2].Start.Position - pcf.Position).Magnitude < 0.01, "desde donde la dejaste")
	-- Minar a pie
	ac.World = nil
	local node = Tefra.nodes()[1]
	local function standAt(p: Vector3)
		player.Character = { FindFirstChild = function(_, name)
			if name == "HumanoidRootPart" then
				return { Position = p }
			end
			return nil
		end }
	end
	standAt(node.Pos + Vector3.new(200, 0, 0))
	check(PS.harvest(player, node.Id) == "Far" and Mining.cargo(data.Space.Ore) == 0, "desde lejos: no")
	standAt(node.Pos + Vector3.new(6, 2, 0))
	local r1 = PS.harvest(player, node.Id)
	check((r1 == "Unit" or r1 == "Empty") and data.Space.Ore[node.Ore] == 1 and data.Space.Mined == 1 and events[#events].Type == "Mine", ("cerca: +1 %s a la bodega (y cuenta para las misiones)"):format(node.Ore))
	check(PS.harvest(player, node.Id) == "Rate" and data.Space.Ore[node.Ore] == 1, "otra al instante: no (demasiado rápido)")
	check(PS.harvest(player, "inventado") == nil, "un mineral inventado: nada")
	ac.World = "Planet"
	check(PS.harvest(player, node.Id) == "Ship", "desde la nave, no (se extrae a pie)")
	ac.World = nil
	local rock = PS._nodeRocks[node.Id]
	local ps = PS._states[player]
	local got = {}
	for _ = 1, 20 do
		ps.Rate.Last = -math.huge
		local res = PS.harvest(player, node.Id)
		table.insert(got, res)
		if res == "Dry" then
			break
		end
	end
	check(table.find(got, "Empty") and got[#got] == "Dry" and lit[node.Id] == false, "se agota (se apaga) y vacío no da nada")
	rock.EmptyAt = os.clock() - Mining.RefillSeconds - 1
	PS._tick()
	check(lit[node.Id] == true and rock.Units == rock.Max, "a los minutos se rellena y vuelve a brillar")
	data.Space.Ore = { Hierro = Mining.CargoMax }
	ps.Rate.Last = -math.huge
	check(PS.harvest(player, node.Id) == "Cargo", "con la bodega llena: no")
	-- Puntos de interés: premio la primera vez
	local beacon = Tefra.PoiById.Baliza
	standAt(Tefra.toWorld(beacon.X, beacon.Z, Tefra.poiY("Baliza") + 3))
	local m0 = data.Money
	PS.poi(player, "Baliza")
	PS.poi(player, "Baliza")
	check(data.Money == m0 + PS.PoiReward and data.Space.Pistas.Baliza ~= nil, "la baliza: premio la primera vez y queda apuntada (pista de la Saga 2)")
	local found = 0
	for _, s in sent do
		if s[1] == "Found" then
			found += 1
		end
	end
	check(found == 2 and #Tefra.POIs >= 3, ("%d puntos de interés (baliza, ruinas, restos de nave, plataforma)"):format(#Tefra.POIs))
	-- Se va a Valmar: fuera la nave aparcada y los atributos
	PS.disembark(player)
	PS.leave(player)
	check(parked[player] == nil and player:GetAttribute("Planeta") == nil and player:GetAttribute("SpaceReturn") == nil, "VALMAR desde el planeta: fuera la nave aparcada y los atributos")
end

---------------------------------------------------------------------
print("\n🛰️ AirCombatService.relocate (la misma nave, otro sitio)")
---------------------------------------------------------------------
do
	L.reset()
	L.mock("src/server/Services/AirCombatService", nil)
	L.mock("src/server/World/PlanetWorld", nil)
	L.services.Players = { PlayerAdded = { Connect = function() end }, PlayerRemoving = { Connect = function() end }, GetPlayers = function()
		return {}
	end }
	L.services.RunService.Heartbeat = { Connect = function()
		return { Disconnect = function() end }
	end }
	local AC = L.load("src/server/Services/AirCombatService")
	local lon = PlanetBodies.ById.Tefra
	local up = PlanetEntry.frame(lon)
	local cp = CFrame.new(lon.Center + up * (PlanetBodies.relocRadius(lon) + 10)) * PlanetEntry.facing(-up)
	local player = L.player("Piloto", 77)
	local root = setmetatable({ CFrame = cp, Parent = true }, { __index = function(t, k)
		if k == "Position" then
			return rawget(t, "CFrame").Position
		end
		return nil
	end })
	local s = {
		Player = player, Root = root, Enemies = {}, Bolts = { {} }, Missiles = { {} }, LastPos = cp.Position, LastGood = cp,
		PoseAt = os.clock(), Down = false, Geo = Zone, World = "Cosmos", Free = true, Rejects = 0, Section = "Space",
	}
	AC._sessions[player] = s
	local target = PlanetEntry.toSurface(lon, Tefra.Surface, cp.Position, -up)
	check(AC.relocate(player, target, { World = "Planet", Geo = Tefra, Planet = "Tefra" }), "relocate al planeta")
	check(s.World == "Planet" and s.Geo == Tefra and s.Planet == "Tefra" and (root.CFrame.Position - target.Position).Magnitude < 1e-3 and s.LastGood == target, "la nave está en la superficie y es el último sitio bueno")
	check(#s.Bolts == 0 and #s.Missiles == 0 and s.Section == "Atmos" and player:GetAttribute("AirCombatWorld") == "Planet", "sin disparos del espacio, con gravedad, y el cliente lo sabe")
	-- Un «Pose» viejo (del espacio) que llega tarde: se ignora (no hay «Reset» que te devuelva atrás)
	AC._pose(s, cp)
	check((root.CFrame.Position - target.Position).Magnitude < 1e-3 and s.Rejects == 0, "un «Pose» de antes del paso se ignora")
	s.PoseAt = os.clock() - 0.05
	local ahead = target * CFrame.new(0, 0, -8)
	AC._pose(s, ahead)
	check((root.CFrame.Position - ahead.Position).Magnitude < 1e-3, "y los nuevos mueven la nave en el planeta")
	check(AC.spawnEnemy(player, "Dron", target.Position + Vector3.new(0, 0, -200)) == nil, "en el planeta no salen enemigos del espacio")
	AC._sessions[player] = nil
end

---------------------------------------------------------------------
print("\n⛰️ El terreno de verdad (PlanetWorld.chunk)")
---------------------------------------------------------------------
do
	local PW = L.load("src/server/World/PlanetWorld")
	local writes, fills = {}, 0
	local terrain = {
		WriteVoxels = function(_, region, res, mats, occs)
			table.insert(writes, { Region = region, Res = res, Mats = mats, Occs = occs })
		end,
		FillBlock = function()
			fills += 1
		end,
	}
	local O = Tefra.Origin
	-- un trozo en la plataforma y otro en el lago grande
	local lake = Tefra.Lakes[1]
	local chunks = { { O.X - 32, O.Z - 32 }, { O.X + lake.X - 32, O.Z + lake.Z - 32 } }
	local okAll, waterSeen, surfaceOk, allowed = true, false, true, true
	for _, c in chunks do
		local x0 = math.floor(c[1] / 4) * 4
		local z0 = math.floor(c[2] / 4) * 4
		local ok, err = pcall(PW.chunk, terrain, x0, z0, 64)
		okAll = okAll and ok
		if not ok then
			print("    " .. tostring(err))
		end
	end
	check(okAll and #writes == 2 and fills >= 1, "cada trozo: macizo por debajo y la capa de arriba con WriteVoxels")
	local shapeOk = true
	for wi, w in writes do
		local minY = w.Region.CFrame.Position.Y - w.Region.Size.Y / 2
		shapeOk = shapeOk and w.Res == 4 and #w.Mats == 16 and #w.Occs[1] >= 2
		for i = 1, 16, 5 do
			for k = 1, 16, 5 do
				local x = chunks[wi][1] - (chunks[wi][1] % 4) + (i - 1) * 4 + 2
				local z = chunks[wi][2] - (chunks[wi][2] % 4) + (k - 1) * 4 + 2
				local h = Tefra.heightAt(x, z)
				-- la ocupación de la columna suma la altura del suelo sobre el fondo de la región
				local sum = 0
				for j = 1, #w.Occs[i] do
					local m = w.Mats[i][j][k]
					if m == roblox.Enum.Material.Water then
						waterSeen = true
					elseif m ~= roblox.Enum.Material.Air then
						sum += w.Occs[i][j][k] * 4
						allowed = allowed and Tefra.TerrainColors[m.Name] ~= nil
					end
				end
				surfaceOk = surfaceOk and math.abs(minY + sum - h) < 1.2
			end
		end
	end
	check(shapeOk, "rejilla de 4 studs, 16 × 16 columnas por trozo")
	check(surfaceOk, "la superficie de los vóxeles está a la altura de heightAt (lo que choca es lo que se ve)")
	check(waterSeen, "agua en el lago")
	check(allowed, "materiales de Tefra")
	check(PW.State == "None", "no se construye nada hasta que alguien se acerca (PlanetWorld.ensure)")
	local looks = PW.setupLooks()
	check(type(looks) == "table" and #looks == 0, "sin texturas subidas, setupLooks no crea cielos ni materiales a medias")
end

---------------------------------------------------------------------
print("\n🎨 Texturas: respaldo sin ids, archivos y licencias")
---------------------------------------------------------------------
do
	local empty = {}
	check(EspacioLook.skyFaces(empty, "cielo_espacio") == nil and EspacioLook.variantMaps(empty, "NaveCasco") == nil, "sin ids: ni cielo ni chapa (se ve con colores y materiales)")
	local pl = EspacioLook.planet(empty, "Tefra")
	check(pl.Texture == nil and pl.Clouds == nil and pl.Halo == nil, "sin ids: el planeta va de color (PlanetBodies.Ground) con su aro dibujado")
	local fake = {}
	for i, name in EspacioLook.allNames() do
		fake[name] = "rbxassetid://" .. (1000 + i)
	end
	local faces = EspacioLook.skyFaces(fake, "cielo_lontana")
	local n = 0
	for _ in faces or {} do
		n += 1
	end
	check(n == 6 and faces.SkyboxFt == fake.cielo_lontana_ft, "con ids: las 6 caras del cielo")
	local partial = table.clone(fake)
	partial.cielo_espacio_up = nil
	check(EspacioLook.skyFaces(partial, "cielo_espacio") == nil, "un cielo con una cara de menos no se pone (se vería roto)")
	local maps = EspacioLook.variantMaps(fake, "NaveCasco")
	check(maps and maps.ColorMap and maps.NormalMap and maps.RoughnessMap and maps.MetalnessMap, "con ids: la chapa de la nave con sus 4 mapas")
	check(EspacioLook.planet(fake, "Miasma").Texture == fake.planeta_zefira, "y cada planeta su superficie (Miasma → planeta_zefira)")
	local valid = true
	for _, v in EspacioTextureIds do
		valid = valid and EspacioLook.valid(v)
	end
	check(valid, "EspacioTextureIds: solo ids válidos (o vacío)")
	-- La nave sin el material: sus piezas como siempre; el tren escondido
	local ShipModel = L.load("src/shared/AirCombat/ShipModel")
	local ship = ShipModel.build("Caza", CFrame.new(0, 100, 0))
	local hull = ship:FindFirstChild("Fuselaje")
	check(hull and hull.MaterialVariant == "" and hull.Material.Name == "SmoothPlastic", "sin el MaterialVariant NaveCasco, la chapa va de color como siempre")
	local gear, hidden = 0, true
	for _, d in ship:GetChildren() do
		if d.Name == ShipModel.Gear or d.Name == ShipModel.GearPad then
			gear += 1
			hidden = hidden and d.Transparency == 1
		end
	end
	check(gear == 6 and hidden, "tren de aterrizaje (3 patas), escondido hasta acercarse al suelo")
	-- Archivos, tamaños y licencias
	local licence = fs.readFile("assets/espacio/LICENCIAS.md")
	local onDisk = {}
	for _, f in fs.readDir("assets/espacio") do
		if f:match("%.png$") or f:match("%.jpg$") then
			onDisk[f:gsub("%.%a+$", "")] = f
		end
	end
	local missing, unlisted, big = {}, {}, {}
	for _, name in EspacioLook.allNames() do
		if not onDisk[name] then
			table.insert(missing, name)
		end
	end
	local function dims(path: string): (number, number)
		local b = fs.readFile(path)
		if b:sub(2, 4) == "PNG" then
			return string.unpack(">I4", b, 17), string.unpack(">I4", b, 21)
		end
		local i = 3
		while i < #b do
			local marker = b:byte(i + 1)
			local len = string.unpack(">I2", b, i + 2)
			if marker >= 0xC0 and marker <= 0xC2 then
				local h, w = string.unpack(">I2", b, i + 5), string.unpack(">I2", b, i + 7)
				return w, h
			end
			i += 2 + len
		end
		return 0, 0
	end
	for _, file in onDisk do
		if not string.find(licence, file, 1, true) then
			table.insert(unlisted, file)
		end
		local w, h = dims("assets/espacio/" .. file)
		if w > 1024 or h > 1024 or w == 0 then
			table.insert(big, ("%s %dx%d"):format(file, w, h))
		end
	end
	check(#missing == 0, "están todas las imágenes que usa el juego" .. (if #missing > 0 then ": faltan " .. table.concat(missing, ", ") else ""))
	check(#unlisted == 0, "LICENCIAS.md nombra cada archivo (fuente y licencia)" .. (if #unlisted > 0 then ": faltan " .. table.concat(unlisted, ", ") else ""))
	check(#big == 0, "todas ≤ 1024 px por lado (el máximo de Roblox)" .. (if #big > 0 then ": " .. table.concat(big, ", ") else ""))
	local script = fs.readFile("scripts/upload-espacio.sh")
	check(string.find(script, "set +x", 1, true) and string.find(script, "src/shared/Cosmos/EspacioTextureIds.luau", 1, true) and not string.find(script, 'echo "$ROBLOX_API_KEY', 1, true) and not string.find(script, "echo $ROBLOX_API_KEY", 1, true), "upload-espacio.sh: escribe EspacioTextureIds y nunca enseña la clave")
end

---------------------------------------------------------------------
print("\n📱 Botón VISOR (móvil)")
---------------------------------------------------------------------
do
	local HudLayout = L.load("src/client/UI/HudLayout")
	local ids = { "Fuego", "Misil", "Turbo", "FrenoNave", "SalirNave", "ValmarNave", "AccionNave", "VisorNave" }
	for _, size in { { 932, 430 }, { 844, 390 }, { 640, 360 } } do
		local layout = HudLayout.compute(Vector2.new(size[1], size[2]), { Touch = true })
		local rects, clash = {}, {}
		for _, id in ids do
			local p = layout.FlySlots[id]
			if p then
				rects[id] = HudLayout.rect(p, layout.Canvas)
			else
				table.insert(clash, id .. " sin hueco")
			end
		end
		local v = rects.VisorNave
		local need = if size[1] == 640 then 32 else 44
		if v and math.min(v.W, v.H) * layout.Scale < need then
			table.insert(clash, "VisorNave pequeño")
		end
		if v and (v.X < 0 or v.Y < 0 or v.X + v.W > layout.Canvas.X or v.Y + v.H > layout.Canvas.Y) then
			table.insert(clash, "VisorNave fuera")
		end
		for _, id in ids do
			if id ~= "VisorNave" and v and rects[id] and HudLayout.overlaps(v, rects[id]) then
				table.insert(clash, "VisorNave/" .. id)
			end
		end
		for _, item in { "Hotbar", "Mission", "Minimap", "Flight", "Joystick" } do
			local p = layout.Items[item]
			if v and p and HudLayout.overlaps(v, HudLayout.rect(p, layout.Canvas)) then
				table.insert(clash, "VisorNave/" .. item)
			end
		end
		check(#clash == 0, ("%dx%d: VISOR grande y sin pisar nada%s"):format(size[1], size[2], if #clash > 0 then " (" .. table.concat(clash, ", ") .. ")" else ""))
	end
end

---------------------------------------------------------------------
print("\n🌄 El cielo de cada planeta (shared/Cosmos/EnvZones): Tefra con el suyo, nunca el de Valmar")
---------------------------------------------------------------------
do
	local EnvZones = L.load("src/shared/Cosmos/EnvZones")
	local DayGrade = L.load("src/shared/DayGrade")
	local SkyMoods = L.load("src/shared/SkyMoods")
	local ground = Tefra.toWorld(0, 0, 40)
	local surface = EnvZones.resolve({ Pos = ground, Surface = "Tefra" })
	local f = EnvZones.flags(surface)
	check(surface.Zone == "Planeta" and surface.Planet == "Tefra" and surface.PlanetMix == 1, "en la superficie de Tefra: zona Planeta (Tefra del todo)")
	check(f.Sky == "Planeta" and f.SkySlots and f.SkySlots[1] == "CieloTefra", "Tefra: su cielo malva con la luna Ovilla (Sky «CieloTefra»), no el de Valmar")
	check(not f.Rift and not f.Weather and not f.ValmarSky and f.Atmosphere and f.Clouds, "Tefra: sin la Grieta, sin la lluvia ni la luna de Valmar; con su bruma de ceniza y sus nubes")
	-- La luz de Tefra manda aunque en Valmar haya la Grieta (etapa 7) y lluvia
	local valmar = SkyMoods.apply(DayGrade.weather(DayGrade.sample(12), { Brightness = 0.7, Density = 0.5, Cover = 0.9, Rain = 1 }, nil, 0, 1), SkyMoods.List.GrietaFinal, 1, DayGrade.mix)
	local k = EnvZones.applyKey(valmar, surface)
	local T = EnvZones.Tefra.Mood
	local function same(a: any, b: any): boolean
		return math.abs(a.R - b.R) < 1e-3 and math.abs(a.G - b.G) < 1e-3 and math.abs(a.B - b.B) < 1e-3
	end
	check(same(k.AtmColor, T.AtmColor) and same(k.CloudColor, T.CloudColor) and k.Cover == T.Cover and (k.Veil == nil or k.Veil == 0), "la luz de Tefra (bruma malva, nubes de ceniza) manda sobre la Grieta y la lluvia de Valmar")
	check(T.AtmColor.R > T.AtmColor.G and T.AtmColor.B > T.AtmColor.G and T.SunTint.R > T.SunTint.B and T.CloudColor.R < 0.9, "Tefra: malva y ceniza, con luz volcánica (sol cálido), nubes nunca blancas")
	-- Cada planeta, su perfil
	local all = true
	for _, b in PlanetBodies.List do
		local p = EnvZones.planet(b.Id)
		if not (p and p.Sky and p.Sky[1] ~= "Day" and p.Mood and p.Mood.AtmColor) then
			all = false
		end
	end
	check(all, "los 7 planetas tienen su perfil de cielo y luz (ninguno usa el cielo de Valmar)")
	-- Entrando: del negro al cielo del planeta, poco a poco
	local lon = PlanetBodies.ById.Tefra
	local above = lon.Center + Vector3.new(0, lon.Radius + 500, 0)
	local last, ok = -1, true
	for i = 0, 10 do
		local e = EnvZones.resolve({ Pos = above, Entry = { Planet = "Tefra", Mix = i / 10 } })
		if e.Zone ~= "Entrada" or e.Space ~= 1 or e.PlanetMix < last then
			ok = false
		end
		last = e.PlanetMix
	end
	check(ok, "entrando en la atmósfera: del espacio al cielo de Tefra sin saltos")
	local mixes = {}
	for _, m in { 0.2, 0.5, 0.8 } do
		local kk = EnvZones.applyKey(valmar, EnvZones.resolve({ Pos = above, Entry = { Planet = "Tefra", Mix = m } }))
		table.insert(mixes, kk.Density)
	end
	check(mixes[1] < mixes[2] and mixes[2] < mixes[3], ("la bruma del planeta crece al bajar (%.2f → %.2f → %.2f)"):format(mixes[1], mixes[2], mixes[3]))
	local climbing = EnvZones.resolve({ Pos = ground, Surface = "Tefra", Entry = { Planet = "Tefra", Mix = 0.1, Climbing = true } })
	check(climbing.PlanetMix >= 0.3 and climbing.PlanetMix < 1, "subiendo desde la superficie el cielo se abre al negro (nunca menos de 0,3 de Tefra)")
	-- Saltar de la nave a la superficie (relocalizar) o volver a Valmar: fundido, sin fogonazo
	local cur = EnvZones.approach(nil, EnvZones.resolve({ Pos = Vector3.new(0, 5200, 0) }), 0.1)
	cur = EnvZones.approach(cur, surface, 0.1)
	check(cur.Planet == "Tefra" and cur.PlanetMix > 0 and cur.PlanetMix < 0.5, "del espacio a Tefra de golpe: el cielo del planeta entra en fundido")
	local home = EnvZones.approach(EnvZones.approach(nil, surface, 0.1), EnvZones.resolve({ Pos = Vector3.new(0, 40, 0) }), 0.1)
	check(home.Planet == "Tefra" and home.PlanetMix < 1 and home.PlanetMix > 0.5, "de Tefra a Valmar (VALMAR): Tefra se apaga poco a poco, no de golpe")
	-- Las estrellas de los planetas, lejos y cerca: en el espacio no hay bruma que las lave
	local fst = EnvZones.flags(EnvZones.resolve({ Pos = Stations.List[1].Center }))
	local farV = PlanetBodies.view(lon, Stations.List[1].Center, 70, 720)
	local nearV = PlanetBodies.view(lon, lon.Center + Vector3.new(0, lon.Radius + 3000, 0), 70, 720)
	check(not fst.Atmosphere and farV.DrawDistance <= PlanetBodies.DrawMax and nearV.Body == 1 and nearV.DrawRadius * 2 <= 2048, "desde la estación, sin bruma: los planetas (estrella o esfera a ≤1500 studs) se ven nítidos; de cerca, esfera entera")

	-- EnvDirector en Tefra: el HUD de Valmar fuera, la Grieta apagada
	local zoneCalls, riftCalls, focusCalls = {}, {}, {}
	L.mock("src/client/Controllers/DayLight", { setZone = function(e, fl)
		table.insert(zoneCalls, { e, fl })
	end })
	L.mock("src/client/Controllers/SkyRift", { setSuppressed = function(on, why)
		table.insert(riftCalls, { on, why })
	end })
	L.mock("src/client/Controllers/PlanetClient", { envEntry = function()
		return nil
	end })
	L.mock("src/client/UI/FlightFocus", { setZone = function(name)
		table.insert(focusCalls, name or "Valmar")
	end })
	local oldPlayers = L.services.Players
	local me = L.player("Exploradora", 88)
	me:SetAttribute("Planeta", "Tefra")
	L.services.Players = { LocalPlayer = me }
	L.reset("src/client/Controllers/EnvDirector")
	local Director = L.load("src/client/Controllers/EnvDirector")
	for _ = 1, 20 do
		Director.update(0.1, ground)
	end
	local e, fl = zoneCalls[#zoneCalls][1], zoneCalls[#zoneCalls][2]
	check(e.Zone == "Planeta" and fl.SkySlots[1] == "CieloTefra" and riftCalls[#riftCalls][1] == true and not Director.allows("Weather"), "EnvDirector a pie en Tefra: cielo de Tefra, sin Grieta ni lluvia de Valmar")
	check(focusCalls[#focusCalls] == "Planeta", "EnvDirector a pie en Tefra: el HUD de Valmar (GPS, minimapa, misión) se aparta")
	me:SetAttribute("Planeta", nil)
	for _ = 1, 30 do
		Director.update(0.1, Vector3.new(0, 40, 0))
	end
	check(zoneCalls[#zoneCalls][1].Zone == "Valmar" and riftCalls[#riftCalls][1] == false and focusCalls[#focusCalls] == "Valmar", "de vuelta en Valmar: su cielo, su Grieta y su HUD")

	-- 🔊 El sonido de Tefra (docs/audio/zonas.md): la misma zona que el cielo, con sus momentos
	local TefraCity = L.load("src/shared/Cosmos/TefraCity")
	local Soundscapes = L.load("src/shared/Cosmos/Soundscapes")
	local Config = L.load("src/shared/Config")
	local zoneSounds = {}
	L.mock("src/client/Controllers/StoryAudio", { setZone = function(s)
		table.insert(zoneSounds, s)
	end })
	local wsAttrs: { [string]: any } = {}
	local oldWs = L.workspace
	L.workspace = { GetAttribute = function(_, k)
		return wsAttrs[k]
	end, FindFirstChild = function()
		return nil
	end }
	me:SetAttribute("Planeta", "Tefra")
	L.reset("src/client/Controllers/EnvDirector")
	local Snd = L.load("src/client/Controllers/EnvDirector")
	local function at(pos: Vector3, n: number?)
		for _ = 1, n or 20 do
			Snd.update(0.1, pos)
		end
		return Snd.soundscape()
	end
	local street = ground
	local lx0, lz0 = Tefra.toLocal(street)
	check(TefraCity.shelterAt(lx0, lz0) == nil, "(la prueba empieza en la calle, fuera de un refugio)")
	local s1 = at(street)
	check(s1.Key == "Tefra" and s1.Ambience == "Tefra" and s1.Music[1] == "TefraGuerra" and Snd.valmarAudio() == 0, "en Tefra: lava, ceniza y fundiciones, tambores de guerra apagados; nada de Valmar")
	wsAttrs.TefraWar = '{"State":"Aviso","Zones":[],"FireAt":1,"EndAt":2}'
	check(at(street, 1).Key == "Tefra:Bombardeo", "suenan las sirenas del bombardeo (workspace.TefraWar)")
	local refugio = TefraCity.BuildingById.Tefra_Refugio
	check(at(Tefra.toWorld(refugio.X, refugio.Z, 60), 1).Key == "Tefra:Refugio", "dentro del refugio antibombas: el bombardeo apagado y música en calma")
	wsAttrs.TefraWar = '{"State":"Despues","Zones":[]}'
	check(at(street, 1).Key == "Tefra", "pasado el bombardeo: sin sirenas")
	me:SetAttribute("WorldState", '{"Tefra.Tregua":true}')
	check(at(street, 1).Key == "Tefra:Tregua" and Snd.soundscape().Music[1] == "TefraRefugio", "tras la tregua: la ciudad respira (música en calma)")
	check(zoneSounds[#zoneSounds].Key == "Tefra:Tregua", "StoryAudio recibe cada cambio")
	me:SetAttribute("WorldState", nil)
	me:SetAttribute("Planeta", nil)
	-- Los demás planetas ya tienen su perfil (al entrar en su atmósfera)
	local own = true
	for _, b in PlanetBodies.List do
		local e = Soundscapes.resolve({ Zone = "Entrada", Space = 1, Planet = b.Id, PlanetMix = 1 }, {}, nil)
		if e.Planet ~= b.Id or e.Valmar ~= 0 or not Config.Audio.Ambience.Kinds[e.Ambience] or not e.Music or not Config.Audio.Music[e.Music[1]] then
			own = false
		end
	end
	check(own, "los 7 planetas suenan a lo suyo al entrar (ninguno a Valmar)")
	L.workspace = oldWs
	L.mock("src/client/Controllers/StoryAudio", nil)
	L.services.Players = oldPlayers
	for _, path in { "src/client/Controllers/DayLight", "src/client/Controllers/SkyRift", "src/client/Controllers/PlanetClient", "src/client/UI/FlightFocus" } do
		L.mock(path, nil)
	end
	L.reset("src/client/Controllers/EnvDirector")

	-- Un solo dueño: PlanetClient y SpaceClient ya no tocan la luz ni el cielo
	local planetSrc = fs.readFile("src/client/Controllers/PlanetClient.luau")
	local spaceSrc = fs.readFile("src/client/Controllers/SpaceClient.luau")
	check(not planetSrc:find("forceSky", 1, true) and not planetSrc:find("pushLayer", 1, true) and not planetSrc:find("setSuppressed", 1, true) and not spaceSrc:find("pushLayer", 1, true), "PlanetClient y SpaceClient ya no pelean por el cielo (solo EnvDirector)")
	-- Cosme (y los demás de Valmar) no te siguen a otro planeta
	local sceneSrc = fs.readFile("src/server/Services/SceneService.luau")
	check(sceneSrc:find('player:GetAttribute("Planeta") ~= nil and not (spec and spec.Planetas == true)', 1, true) ~= nil and sceneSrc:find("onFoot(player, actor.Spec)", 1, true) ~= nil, "los acompañantes de Valmar (Cosme) no te siguen a Tefra salvo que su misión lo diga (Planetas = true)")
end

---------------------------------------------------------------------
print("\n🏙️ Bastión Ceniza, la ciudad de Tefra (shared/Cosmos/TefraCity + World/TefraCityBuilder)")
---------------------------------------------------------------------
do
	local City = L.load("src/shared/Cosmos/TefraCity")
	local O = Tefra.Origin
	local base = O.Y + Tefra.padY()
	local R = City.Rect
	check(Tefra.City ~= nil and Tefra.City.Name == City.Name, "Tefra lleva su ciudad (Tefra.City)")
	-- Los 8 barrios del diseño (diseno-mundos §3.1.7)
	local want = { "Barrio del Ovillo", "Mercado Espiral", "Muelle Bastión", "Campus Nilda", "Los Pozos de Magma", "Mirador de las Lunas", "Las Fundiciones", "La Muralla" }
	local names = {}
	for _, d in City.Districts do
		names[d.Name] = true
	end
	local allDistricts = true
	for _, n in want do
		allDistricts = allDistricts and names[n] == true
	end
	check(#City.Districts == 8 and allDistricts, "los 8 barrios: Ovillo, Mercado Espiral, Muelle, Campus Nilda, Pozos de Magma, Mirador, Fundiciones y Muralla")
	-- Cada manzana cae en un barrio, y cada edificio en el suyo
	local blocksOk, buildingsInDistrict = true, true
	for _, cx in City.BlockCols do
		for _, cz in City.BlockRows do
			blocksOk = blocksOk and City.districtAt(cx, cz) ~= nil
		end
	end
	for _, b in City.Buildings do
		local d = City.districtAt(b.X, b.Z)
		buildingsInDistrict = buildingsInDistrict and d ~= nil and d.Id == b.District
		if not (d and d.Id == b.District) then
			print(("    %s está en %s (dice %s)"):format(b.Id, d and d.Id or "nada", b.District))
		end
	end
	check(blocksOk and buildingsInDistrict, "cada manzana y cada edificio, en su barrio")

	-- Llegas a la ciudad: la plataforma (y el centro de llegada) dentro, en el Muelle Bastión
	local padDistrict = City.districtAt(0, 0)
	check(City.inside(0, 0) and padDistrict ~= nil and padDistrict.Id == "Muelle", "la plataforma de aterrizaje de siempre está en el centro del Muelle Bastión")
	local cx, cz = Tefra.toLocal(Tefra.center())
	local kx, kz = Tefra.toLocal(Tefra.checkpoint().Position)
	check(City.inside(cx, cz) and City.inside(kx, kz), "la nave llega (y reaparece) encima de la ciudad")
	check(City.walkable(0, 70) and City.walkable(0, -70) and not City.landingBlocked(0, 0), "alrededor de la plataforma se anda y en ella se posa la nave")

	-- El terreno: meseta llana, foso y canal hundidos, sin agua dentro
	local flat, noWater = true, true
	for lx = R.X0 + 10, R.X1 - 10, 37 do
		for lz = R.Z0 + 10, R.Z1 - 10, 41 do
			if not City.inLava(lx, lz) and (lx * lx + lz * lz) > 130 * 130 then
				local h = Tefra.heightAt(O.X + lx, O.Z + lz)
				flat = flat and math.abs(h - (base - City.GroundDrop)) < 0.01
			end
			local _, w = Tefra.groundAt(O.X + lx, O.Z + lz)
			noWater = noWater and not w
		end
	end
	check(flat and noWater, "dentro de la muralla el suelo es una meseta llana (sin agua)")
	local moatH = Tefra.heightAt(O.X + (R.X0 + R.X1) / 2, O.Z + R.Z0 - 18)
	local canalH = Tefra.heightAt(O.X - 300, O.Z + City.Canal.Z)
	check(math.abs(moatH - (base - City.LavaDepth)) < 0.01 and math.abs(canalH - (base - City.LavaDepth)) < 0.01, "el foso y el Canal de la Forja están hundidos (la lava va por debajo de las calles)")
	check(City.inLava((R.X0 + R.X1) / 2, R.Z0 - 18) and City.inLava(-300, City.Canal.Z) and City.inLava(City.Wells[1].X, City.Wells[1].Z) and not City.inLava(0, 0), "lava: el foso, el canal y los pozos (no la plataforma)")
	-- Ni mineral ni flora dentro de la ciudad
	local clean = true
	for _, nd in Tefra.nodes() do
		clean = clean and not City.inside(Tefra.toLocal(nd.Pos))
	end
	for kind in Tefra.DecorCounts do
		for _, d in Tefra.decor(kind) do
			clean = clean and not City.inside(Tefra.toLocal(d.Pos))
		end
	end
	check(clean, "ni mineral ni flora salvaje dentro de la ciudad")

	-- Calles conectadas: cada una cruza o toca otra, y todas forman una sola red
	local function touches(a: any, b: any): boolean
		if a.Axis == b.Axis then
			return a.At == b.At and a.From <= b.To and b.From <= a.To
		end
		local sx = if a.Axis == "X" then a else b
		local sz = if a.Axis == "Z" then a else b
		local x, z = sz.At, sx.At
		return x >= sx.From and x <= sx.To and z >= sz.From and z <= sz.To
	end
	local seen, queue = { [City.Streets[1]] = true }, { City.Streets[1] }
	while #queue > 0 do
		local a = table.remove(queue)
		for _, b in City.Streets do
			if not seen[b] and touches(a, b) then
				seen[b] = true
				table.insert(queue, b)
			end
		end
	end
	local nSeen = 0
	for _ in seen do
		nSeen += 1
	end
	check(nSeen == #City.Streets, ("las %d calles forman una sola red (todas conectadas)"):format(#City.Streets))
	-- Las puertas: una calle sale por cada una, cruza el foso y llega a la orilla de fuera
	local gatesOk = true
	for _, g in City.Gates do
		local ox, oz = g.X + g.Dir[1] * (City.Bank - 2), g.Z + g.Dir[2] * (City.Bank - 2)
		local d = City.streetDistance(ox, oz)
		gatesOk = gatesOk and d < 1 and City.walkable(ox, oz) and City.solidTop(g.X + g.Dir[1] * 3, g.Z + g.Dir[2] * 3) == nil
	end
	check(#City.Gates == 4 and gatesOk, "4 puertas: la calle cruza la muralla y el foso (puente) hasta la orilla de fuera")
	-- Puentes sobre el canal: cada calle que lo cruza es un puente (se anda por encima de la lava)
	local bridges, bridgesOk = 0, true
	for _, st in City.Streets do
		if st.Axis == "Z" and st.From < City.Canal.Z and st.To > City.Canal.Z then
			bridges += 1
			bridgesOk = bridgesOk and City.walkable(st.At, City.Canal.Z) and City.inLava(st.At + City.RoadHalf + 2, City.Canal.Z)
		end
	end
	check(bridges >= 4 and bridgesOk, ("%d puentes de hierro sobre el Canal de la Forja (se anda por encima de la lava)"):format(bridges))

	-- Edificios: claves de Tefra, sin pisarse, sin tapar calles, fuera de la lava, dentro de la muralla
	local keysOk, overlapOk, roadOk, lavaOk, insideOk = true, true, true, true, true
	local list = City.Buildings
	for i, b in ipairs(list) do
		keysOk = keysOk and string.sub(b.Id, 1, 6) == "Tefra_"
		local x0, x1, z0, z1 = City.footprint(b)
		insideOk = insideOk and x0 >= R.X0 and x1 <= R.X1 and z0 >= R.Z0 and z1 <= R.Z1
		for j = i + 1, #list do
			local o = list[j]
			if b.Shape ~= "Court" and o.Shape ~= "Court" then
				local a0, a1, c0, c1 = City.footprint(o)
				local ox = math.min(x1, a1) - math.max(x0, a0)
				local oz = math.min(z1, c1) - math.max(z0, c0)
				if ox > 0.5 and oz > 0.5 then
					overlapOk = false
					print(("    se pisan %s y %s (%.1f × %.1f)"):format(b.Id, o.Id, ox, oz))
				end
			end
		end
		-- (muestras dentro de la huella: ni calzada ni acera, ni lava)
		for sx = 0, 4 do
			for sz = 0, 4 do
				local px, pz = x0 + (x1 - x0) * (0.02 + sx * 0.24), z0 + (z1 - z0) * (0.02 + sz * 0.24)
				if City.streetDistance(px, pz) < City.RoadHalf - 0.5 then
					roadOk = false
					print(("    %s pisa la calle en (%.0f, %.0f)"):format(b.Id, px, pz))
				end
				if City.inLava(px, pz) then
					lavaOk = false
					print(("    %s está sobre la lava en (%.0f, %.0f)"):format(b.Id, px, pz))
				end
			end
		end
	end
	check(#list >= 30, ("%d edificios y sitios en el plano"):format(#list))
	check(keysOk, "todas las claves empiezan por «Tefra_» (nunca las de Valmar: Casa_x_z, Portal_…)")
	check(overlapOk, "ningún edificio se mete en otro")
	check(roadOk, "ningún edificio tapa una calle ni su acera")
	check(lavaOk, "ningún edificio sobre la lava (foso, canal ni pozos)")
	check(insideOk, "todos dentro de la muralla")

	-- Puertas de los edificios: salen a una acera, a una calle o a una plaza, y desde la plataforma se llega
	-- andando (rejilla de 4 studs por lo que se puede pisar: calles, aceras, puentes, paseos y plazas)
	local CELL = 4
	local function key(i: number, k: number): number
		return (i + 500) * 1000 + (k + 500)
	end
	local function free(lx: number, lz: number): boolean
		return City.walkable(lx, lz) and City.buildingAt(lx, lz, 0.5) == nil and City.solidTop(lx, lz) == nil
	end
	local reached = {}
	local q = { { 0, 18 } } -- (al sur de la plataforma, en la explanada del Muelle)
	reached[key(0, 18)] = true
	local head = 1
	while head <= #q do
		local c = q[head]
		head += 1
		for _, dv in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local i, k = c[1] + dv[1], c[2] + dv[2]
			local kk = key(i, k)
			if not reached[kk] and math.abs(i * CELL) < 600 and math.abs(k * CELL) < 600 and free(i * CELL, k * CELL) then
				reached[kk] = true
				table.insert(q, { i, k })
			end
		end
	end
	local function near(px: number, pz: number): boolean
		local i, k = math.floor(px / CELL + 0.5), math.floor(pz / CELL + 0.5)
		for di = -1, 1 do
			for dk = -1, 1 do
				if reached[key(i + di, k + dk)] then
					return true
				end
			end
		end
		return false
	end
	local doors, doorsOk = 0, true
	for _, b in list do
		local dx, dz, f = City.door(b)
		if dx and f then
			doors += 1
			local px, pz = dx + f[1] * 3, dz + f[2] * 3
			if not near(px, pz) then
				doorsOk = false
				print(("    la puerta de %s (%.0f, %.0f) no da a ningún sitio por donde se ande desde la plataforma"):format(b.Id, px, pz))
			end
		end
	end
	check(doors >= 20 and doorsOk, ("las %d puertas dan a la calle (o a una plaza) y se llega andando desde la plataforma"):format(doors))
	local gatesReached = true
	for _, g in City.Gates do
		gatesReached = gatesReached and near(g.X + g.Dir[1] * 34, g.Z + g.Dir[2] * 34)
	end
	check(gatesReached, "y por las 4 puertas se sale andando al resto del planeta")

	-- La nave: choca con los edificios y la muralla, no se posa encima ni en la lava
	local astillero = City.BuildingById.Tefra_Astillero
	local hit = Tefra.collide(Tefra.toWorld(astillero.X, astillero.Z, base + 10), 6)
	local over = Tefra.collide(Tefra.toWorld(astillero.X, astillero.Z, base + City.topOf(astillero) + 20), 6)
	local wallHit = Tefra.collide(Tefra.toWorld(-100, R.Z0 - 3, base + 8), 4)
	check(hit == "un edificio" and over == nil and wallHit == "un edificio", "la nave choca con los edificios y con la muralla (y pasa por encima)")
	check(Tefra.landSlopeAt(O.X + astillero.X, O.Z + astillero.Z) > Landing.MaxSlope and Tefra.landSlopeAt(O.X - 300, O.Z + City.Canal.Z) > Landing.MaxSlope and Tefra.landSlopeAt(O.X, O.Z) <= Landing.MaxSlope, "no se posa encima de un edificio ni en la lava; en la plataforma, sí")
	local planetSrc = fs.readFile("src/client/Controllers/PlanetClient.luau")
	check(planetSrc:find("S.landSlopeAt or S.slopeAt", 1, true) ~= nil, "el cliente usa esa pendiente para posarse (Landing)")

	-- Si te caes a la lava: a la orilla, en un sitio por donde se anda
	local rescueOk = true
	for _, p in { { (R.X0 + R.X1) / 2, R.Z0 - 18 }, { -300, City.Canal.Z }, { City.Wells[1].X + 3, City.Wells[1].Z }, { R.X1 + 18, 200 } } do
		local rx, rz = City.rescueSpot(p[1], p[2])
		local ok = not City.inLava(rx, rz) and City.walkable(rx, rz) and City.buildingAt(rx, rz, 1) == nil
		rescueOk = rescueOk and ok
		if not ok then
			print(("    desde (%.0f, %.0f) te saca a (%.0f, %.0f)"):format(p[1], p[2], rx, rz))
		end
	end
	check(rescueOk, "si te caes al foso, al canal o a un pozo, te sacan a una acera cercana")

	-- El reloj en Tefra: su tiempo (ceniza y calor), no el de Valmar
	local w = City.weather(14)
	local hudSrc = fs.readFile("src/client/UI/Hud.luau")
	check(w.Name == "Lluvia de ceniza" and w.Temp >= 30 and hudSrc:find('player:GetAttribute("Planeta") == "Tefra"', 1, true) ~= nil and hudSrc:find("TefraCity.weather", 1, true) ~= nil, ("el reloj en Tefra enseña su tiempo: %s, %d °C"):format(w.Name, w.Temp))
	-- El minimapa en Tefra: Bastión Ceniza (y FlightFocus ya no lo esconde a pie en el planeta)
	local mapSrc = fs.readFile("src/client/Controllers/MapUI.luau")
	local focusSrc = fs.readFile("src/client/UI/FlightFocus.luau")
	local zoneBlock = string.match(focusSrc, "ZoneHidden = (%b{})") or ""
	check(mapSrc:find("buildTefraLayer", 1, true) ~= nil and mapSrc:find("syncMiniWorld", 1, true) ~= nil and not zoneBlock:find('"MapUI"', 1, true), "el minimapa en Tefra enseña Bastión Ceniza (barrios, calles, lava y sitios)")
	local landmarks = City.landmarks()
	check(#landmarks >= 20, ("%d sitios con icono en el minimapa"):format(#landmarks))

	-- Tiendas: claves «Tefra…» que ShopService conoce
	local ShopItems = L.load("src/shared/LifeStory/ShopItems")
	local shopsOk = true
	for _, b in list do
		if b.ShopId then
			shopsOk = shopsOk and string.sub(b.ShopId, 1, 5) == "Tefra" and ShopItems[b.ShopId] ~= nil
		end
	end
	check(shopsOk, "las tiendas de Tefra (panadería, sopa, mercado, raciones) tienen su ShopId «Tefra…» y se venden")
	-- Ninguna clave de Tefra en la migración de las casas de Valmar
	local Migration = L.load("src/server/Migrations/BuildingKeyMigration")
	local migrated = false
	for k, v in Migration.Map.Buildings do
		migrated = migrated or string.find(tostring(k), "Tefra", 1, true) ~= nil or string.find(tostring(v), "Tefra", 1, true) ~= nil
	end
	check(not migrated, "la migración de claves de Valmar no toca nada de Tefra")

	-- Construida de verdad (los kits de Valmar con el estilo de Tefra)
	local CityBuilder = L.load("src/server/World/TefraCityBuilder")
	local folder = roblox.Instance.new("Folder")
	local prompts = {}
	local model, stats = CityBuilder.build(folder, function(parent, kind, id, action, object, hold)
		local pp = roblox.Instance.new("ProximityPrompt")
		pp.ActionText = action
		pp.ObjectText = object
		pp:SetAttribute("Kind", kind)
		pp:SetAttribute("Id", id)
		pp.Parent = parent
		table.insert(prompts, pp)
		return pp
	end)
	check(model.Parent == folder and model.Name == "Ciudad", "la ciudad se construye (World/TefraCityBuilder)")
	local tags: { [string]: number } = {}
	local minY, maxY = math.huge, -math.huge
	local outside = 0
	local noHeist = true
	for _, d in model:GetDescendants() do
		for _, t in d:GetTags() do
			tags[t] = (tags[t] or 0) + 1
		end
		if d:IsA("BasePart") then
			local pos = d.CFrame.Position
			minY = math.min(minY, pos.Y)
			maxY = math.max(maxY, pos.Y)
			local lx, lz = Tefra.toLocal(pos)
			if not City.inside(lx, lz, City.Bank + 10) then
				outside += 1
			end
			if d:HasTag("Shop") then
				noHeist = noHeist and d:GetAttribute("NoHeist") == true and string.sub(tostring(d:GetAttribute("ShopId")), 1, 5) == "Tefra"
			end
		end
	end
	print(("    Bastión Ceniza: %d piezas, %d edificios, %d avisos, %d farolas, %d ventanas de noche, %d marcas de gente, %d bancos"):format(stats.Parts, stats.Buildings, #prompts, tags.StreetLamp or 0, tags.NightWindow or 0, tags.CrowdSpot or 0, tags.Bench or 0))
	check(stats.Parts < 12000, ("piezas razonables para el móvil (%d; Valmar entera ≈ 365 000)"):format(stats.Parts))
	check(stats.Buildings >= 30, ("%d edificios construidos"):format(stats.Buildings))
	check(minY > base - City.LavaDepth - 6 and maxY < base + 200 and outside == 0, "todo a la altura de la meseta y dentro de la ciudad (subido de Y = 0 a la plataforma)")
	check((tags.StreetLamp or 0) >= 20 and (tags.NightWindow or 0) >= 40, "de noche se encienden las farolas y las ventanas (StreetLamp, NightWindow: WorldService)")
	check((tags.CrowdSpot or 0) >= 30 and (tags.Bench or 0) >= 8 and #stats.Areas >= 3, "gente: marcas CrowdSpot, bancos y zonas de paseo (CrowdService)")
	check((tags.Shop or 0) >= 4 and noHeist, "tiendas con «Comprar» (ShopService) y sin «Atracar» (NoHeist)")
	-- (los tablones «Trabajar» que hay son los de los oficios de Tefra: shared/Cosmos/TefraJobs)
	local TefraJobs = L.load("src/shared/Cosmos/TefraJobs")
	local valmarBoards, tefraBoards = 0, 0
	local storySpots: { [string]: any } = {}
	for _, d in model:GetDescendants() do
		if d:HasTag("JobBoard") then
			if TefraJobs.isTefraJob(d:GetAttribute("JobId")) then
				tefraBoards += 1
			else
				valmarBoards += 1
			end
		end
		if d:HasTag("StorySpot") then
			storySpots[d:GetAttribute("SpotId")] = d
		end
	end
	for _, d in folder:GetDescendants() do
		if d:HasTag("StorySpot") then
			storySpots[d:GetAttribute("SpotId")] = d
		end
	end
	check((tags.Papelera or 0) == 0 and (tags.TrafficLight or 0) == 0 and valmarBoards == 0, ("sin semáforos, papeleras del basurero ni tablones de trabajos de Valmar (%d, %d, %d)"):format(tags.TrafficLight or 0, tags.Papelera or 0, valmarBoards))
	local nJobs = 0
	for _ in TefraJobs.Jobs do
		nJobs += 1
	end
	check(tefraBoards == nJobs, ("un tablón «Trabajar» por oficio de Tefra (%d de %d)"):format(tefraBoards, nJobs))
	-- Las marcas de la historia (StorySpot «Tefra_…»): una por sitio, a su altura (las de fuera, en el suelo)
	local missingSpots, badSpots = {}, {}
	for _, s in City.StorySpots do
		local part = storySpots["Tefra_" .. s.Id]
		if not part then
			table.insert(missingSpots, s.Id)
		else
			local ground = part.CFrame.Position.Y - part.Size.Y / 2
			local want = if s.Outside then Tefra.heightAt(Tefra.Origin.X + s.X, Tefra.Origin.Z + s.Z) else base + (s.Y or 1)
			if math.abs(ground - want) > 2 then
				table.insert(badSpots, s.Id)
			end
		end
	end
	check(#missingSpots == 0, "cada sitio de la historia tiene su marca StorySpot " .. table.concat(missingSpots, ", "))
	check(#badSpots == 0, "las marcas de la historia están a la altura del suelo " .. table.concat(badSpots, ", "))
	local tefraPrompts = 0
	for _, pp in prompts do
		if pp:GetAttribute("Kind") == "Tefra" then
			tefraPrompts += 1
		end
	end
	check(tefraPrompts >= 3, ("avisos propios de Tefra: Forja, invernadero y pan de sirena (%d)"):format(tefraPrompts))
	local cityPrompts, idsOk = 0, true
	for _, pp in prompts do
		if pp:GetAttribute("Kind") == "City" then
			cityPrompts += 1
			local id = pp:GetAttribute("Id")
			local spot = City.SpotById[id] or City.BuildingById[id]
			idsOk = idsOk and spot ~= nil and spot.Info ~= nil
		end
	end
	check(cityPrompts >= 12 and idsOk, ("%d avisos «Mirar» (estatua de Nilda, casa de Cosme, controles, candados…) con su texto"):format(cityPrompts))
	local names2, unique = {}, true
	for _, b in (model:FindFirstChild("Edificios") :: any):GetChildren() do
		unique = unique and not names2[b.Name] and string.sub(b.Name, 1, 6) == "Tefra_"
		names2[b.Name] = true
	end
	check(unique, "cada edificio, su modelo con su clave «Tefra_…» (sin repetir)")
	-- PlanetWorld la construye con el resto; PlanetService enseña sus textos
	local pwSrc = fs.readFile("src/server/World/PlanetWorld.luau")
	local psSrc = fs.readFile("src/server/Services/PlanetService.luau")
	check(pwSrc:find("PlanetWorld.buildCity(folder", 1, true) ~= nil and psSrc:find('kind == "City"', 1, true) ~= nil, "PlanetWorld la construye al llegar alguien y PlanetService responde a sus avisos")
	-- Los colores de Valmar no cambian (el tema de Tefra se devuelve)
	local Palette = L.load("src/server/World/Kit/Palette")
	check(Palette.Ground.Asphalt == roblox.Color3.fromRGB(46, 48, 53) and Palette.Street.LampLight == roblox.Color3.fromRGB(255, 214, 160), "después, las calles de Valmar siguen con sus colores (Palette.withTheme lo devuelve todo)")
end

---------------------------------------------------------------------
print("\n🧩 Marco común de los planetas (docs/planetas/marco-planetas.md)")
---------------------------------------------------------------------
do
	local PlanetRegistry = L.load("src/shared/Cosmos/PlanetRegistry")
	local PlanetSurface = L.load("src/shared/Cosmos/PlanetSurface")
	local PlanetCity = L.load("src/shared/Cosmos/PlanetCity")
	local PlanetHazard = L.load("src/shared/Cosmos/PlanetHazard")
	local PlanetJobs = L.load("src/shared/Cosmos/PlanetJobs")
	local TefraHeat = L.load("src/shared/Cosmos/TefraHeat")
	-- Huecos del mundo: uno por planeta, lejos de Valmar, de la arena de pruebas y entre ellos
	local n, apart, farHome = 0, true, true
	for id, a in PlanetRegistry.Slots do
		n += 1
		farHome = farHome and Vector3.new(a.X, 0, a.Z).Magnitude >= 24000 and (a - Arena.Origin).Magnitude >= 20000
		for id2, b in PlanetRegistry.Slots do
			if id ~= id2 and (a - b).Magnitude < 20000 then
				apart = false
			end
		end
	end
	check(n == 7 and apart and farHome, "7 huecos reservados (uno por planeta), lejos de Valmar, de la arena y entre ellos")
	check(PlanetRegistry.Slots.Tefra == Tefra.Origin and PlanetRegistry.get("Tefra").Origin == Tefra.Origin and PlanetRegistry.get("Tefra").City.Name == Tefra.City.Name and PlanetRegistry.Modules.Tefra == "Tefra", "Tefra está en el registro, en su sitio de siempre")
	local okSurf = true
	for _, id in PlanetRegistry.ids() do
		local S = PlanetRegistry.get(id)
		okSurf = okSurf and S ~= nil and S.Origin == PlanetRegistry.Slots[id] and PlanetBodies.ById[id] ~= nil and S.Surface and S.Surface.Id == id
		if S and id ~= "Tefra" then
			okSurf = okSurf and S.Half <= 1536 and Planets.EarlyAccess[id] == true
		end
	end
	check(okSurf, "cada planeta del registro tiene su superficie en su hueco, su cuerpo en el espacio y (los nuevos) acceso como Tefra")
	local idAt = PlanetRegistry.at(Tefra.toWorld(0, 0, 100))
	check(idAt == "Tefra" and PlanetRegistry.at(Vector3.new(0, 40, 0)) == nil, "el registro sabe en qué planeta está un punto (y Valmar no es ninguno)")
	-- El calor de Tefra es una configuración del medidor genérico (mismos números)
	local cases = {
		{ Lava = 3 }, { Lava = 200 }, { Lava = 3, Shelter = 6 }, { Lava = 10, Suit = 0.4, Gel = true, Newbie = true },
		{ District = "Fundiciones", Lava = 200 }, { Outside = true, Day = true, Lava = 200 }, { Lava = 20, Hot = { 5, 12 } },
	}
	local function oldRate(ctx: any): number
		local function band(list, d)
			for _, b in list do
				if d <= b[1] then
					return b[2]
				end
			end
			return 0
		end
		if ctx.Shelter and ctx.Shelter > 0 then
			return -ctx.Shelter
		end
		local gain = 0
		if ctx.Lava then
			gain += band(TefraHeat.LavaBands, ctx.Lava)
		end
		for _, d in ctx.Hot or {} do
			gain += band(TefraHeat.HotBands, d)
		end
		gain += TefraHeat.DistrictHeat[ctx.District or ""] or 0
		if ctx.Outside and ctx.Day then
			gain += TefraHeat.OutsideDay
		end
		if gain <= 0 then
			return -TefraHeat.Cooling
		end
		gain *= math.clamp(ctx.Suit or 1, 0, 1)
		if ctx.Gel then
			gain *= TefraHeat.GelFactor
		end
		if ctx.Newbie then
			gain *= TefraHeat.NewbieFactor
		end
		return gain
	end
	local same = true
	for _, c in cases do
		same = same and math.abs(TefraHeat.rate(c) - oldRate(c)) < 1e-9
	end
	check(same and TefraHeat.Hazard.Id == "Calor" and TefraHeat.phase(90) == "Peligro" and TefraHeat.slow("Aviso") == 0.86, "el calor de Tefra es una configuración de PlanetHazard (mismas cuentas que antes)")

	-- Un planeta de ejemplo hecho solo con datos: superficie, barrio, desventaja y oficio
	local origin = Vector3.new(60000, 0, 60000)
	local City = PlanetCity.new({
		Id = "Ejemplo", Name = "Pueblo de Prueba", Planet = "Ejemplo", KeyPrefix = "Ejemplo_",
		Rect = { X0 = -120, X1 = 120, Z0 = -120, Z1 = 120 },
		Floors = { { Id = "Plaza", Kind = "Rect", X0 = -110, X1 = 110, Z0 = -110, Z1 = 110 } },
		Pits = { { Kind = "Disc", X = 80, Z = 80, R = 14, Depth = 40, Text = "¡Al hueco no!" } },
		Buildings = {
			{ Id = "Casa", Shape = "Box", Name = "Casa", X = -60, Z = -60, W = 30, D = 24, Face = "S", Floors = 2, Style = "Moderno", Ground = "Lobby", Info = "Una casa." },
			{ Id = "Torre", Shape = "Tower", Name = "Torre", X = 60, Z = -60, R = 8, Height = 40 },
		},
		Shelters = { Casa = { Cool = 5, Name = "la casa" } },
		StorySpots = { { Id = "Centro", Name = "El centro", X = 0, Z = 20 }, { Id = "Fuera", Name = "Fuera", X = 400, Z = 0, Outside = true } },
		Gather = { { Id = "Ejemplo_Seta", Name = "Setas", X = 20, Z = 40, Item = "SetaCeniza" } },
		Lamps = { { X = 10, Z = 10 } },
		Crowd = { { Group = "Plaza", X = 0, Z = 0 } },
		Areas = { { X0 = -40, X1 = 40, Z0 = -40, Z1 = 40 } },
	})
	local S = PlanetSurface.new({
		Id = "Ejemplo", Name = "Ejemplo", Origin = origin, Half = 900, Seed = 9, City = City, NodeCount = 6,
		NodeOres = { { Id = "Hierro", Weight = 2 }, { Id = "Cobalto", Weight = 1 } }, DecorCounts = { Roca = 10 },
		POIs = { { Id = "Ejemplo_Plataforma", Name = "Plataforma", X = 0, Z = 0, Flat = 40, Pad = true }, { Id = "Ejemplo_Torre", Name = "Torre", X = 500, Z = 300, Flat = 20 } },
	})
	local base = origin.Y + S.padY()
	check(math.abs(S.heightAt(origin.X + 30, origin.Z - 90) - (base - City.GroundDrop)) < 0.01 and S.heightAt(origin.X + 80, origin.Z + 80) < base - 30, "el barrio es una meseta llana y el hueco está hundido")
	check(S.collide(S.toWorld(60, -60, base + 10), 4) == "un edificio" and S.landSlopeAt(origin.X + 60, origin.Z - 60) > Landing.MaxSlope and S.landSlopeAt(origin.X, origin.Z) <= Landing.MaxSlope, "la nave choca con sus edificios y se posa en la plataforma")
	local nodes = S.nodes()
	local prefixed = #nodes > 0
	for _, nd in nodes do
		prefixed = prefixed and string.sub(nd.Id, 1, 8) == "Ejemplo_" and not City.inside(S.toLocal(nd.Pos))
	end
	check(prefixed and S.node(nodes[1].Id) == nodes[1], "el mineral lleva el prefijo del planeta («Ejemplo_L1») y no cae en el barrio")
	check(City.walkable(0, 0) and not City.walkable(80, 80) and City.buildingAt(-60, -60) ~= nil and City.shelterAt(-60, -60) == "Ejemplo_Casa", "suelo andable, hueco, edificios y refugios con su clave «Ejemplo_…»")
	local rx, rz = City.rescueSpot(80, 80)
	check(City.walkable(rx, rz) and not City.inPit(rx, rz), "si caes al hueco, sales a un sitio andable")
	-- Desventaja genérica
	local H = PlanetHazard.new({ Id = "Gas", Name = "Gas", Bands = { Nube = { { 10, 4 }, { 30, 1 } } }, ZoneRate = { Bajo = 0.5 }, Base = 0.2, Recovery = 2, Gear = { Mascara = { Level = 1, Factor = 0.5 } }, Consumable = { Item = "Filtro", Drop = 40, Seconds = 30, Factor = 0.2 } })
	local up = H.rate({ Near = { Nube = 5 } })
	check(up > 4 and H.rate({ Near = { Nube = 5 }, Shelter = 6 }) == -6 and H.rate({}) > 0 and H.rate({ Near = { Nube = 50 } }) == 0.2, "el medidor sube con la fuente, el refugio lo baja y el ritmo de fondo sigue (la sed)")
	check(H.rate({ Near = { Nube = 5 }, Gear = H.gearFactor({ Mascara = 1 }) }) < up and H.rate({ Near = { Nube = 5 }, Boost = true }) < up and H.phase(90) == "Peligro" and H.knocked(100, 7, 80), "equipo y contramedida lo frenan; fases y derribo (nunca muerte de golpe)")
	-- Oficio genérico
	PlanetJobs.register({ { Id = "EjemploRecadero", Planet = "Ejemplo", Name = "Recadero", Icon = "📦", Pay = 40, MinSeconds = 10, Board = { 30, 30 },
		task = function(r, rank)
			return { { Kind = "Go", At = { 10, 10 }, Text = "Recoge" }, { Kind = "Game", Spec = PlanetJobs.timing("Ya", "⭐", "", rank) }, { Kind = "Go", At = { -10, 40 }, Text = "Entrega" } }
		end } })
	local Config = L.load("src/shared/Config")
	local phases = PlanetJobs.task("EjemploRecadero", 5, 1)
	check(#phases == 3 and Config.Jobs.EjemploRecadero ~= nil and PlanetJobs.pay("EjemploRecadero", 0, 1, 1) == 40 and PlanetJobs.pay("EjemploRecadero", 300, 1, 1) > 80 and not PlanetJobs.allowed("EjemploRecadero", {}, 0, 5), "oficio con datos: fases, entrada en el tablón (Config.Jobs), paga por rango y nada de cobrar antes de tiempo")
	-- Construido con el marco (sin kit: formas por defecto)
	local PlanetCityBuilder = L.load("src/server/World/PlanetCityBuilder")
	local folder = roblox.Instance.new("Folder")
	local prompts = {}
	local model, stats = PlanetCityBuilder.build(folder, function(parent, kind, id, action, object, hold)
		local pp = roblox.Instance.new("ProximityPrompt")
		pp.ActionText = action
		pp:SetAttribute("Kind", kind)
		pp:SetAttribute("Id", id)
		pp.Parent = parent
		table.insert(prompts, pp)
		return pp
	end, S, { Kit = {} })
	local tags, spots = {}, {}
	for _, d in folder:GetDescendants() do
		for _, t in d:GetTags() do
			tags[t] = (tags[t] or 0) + 1
		end
		if d:HasTag("StorySpot") then
			spots[d:GetAttribute("SpotId")] = d
		end
	end
	local kinds = {}
	for _, pp in prompts do
		kinds[pp:GetAttribute("Kind")] = (kinds[pp:GetAttribute("Kind")] or 0) + 1
	end
	check(model.Parent == folder and stats.Buildings == 2 and stats.Parts > 20, ("el barrio de ejemplo se construye (%d piezas, %d edificios)"):format(stats.Parts, stats.Buildings))
	check(spots.Ejemplo_Centro ~= nil and spots.Ejemplo_Fuera ~= nil and (tags.StreetLamp or 0) >= 1 and (tags.CrowdSpot or 0) >= 1 and (tags.JobBoard or 0) == 1, "marcas de la historia «Ejemplo_…», farola de noche, gente y el tablón de su oficio")
	check((kinds.City or 0) >= 1 and (kinds.Gather or 0) == 1 and #stats.Areas == 1, "avisos «Mirar», «Recoger» y su zona de paseo")
	-- Los sitios del cliente y del servidor miran el registro (no solo Tefra)
	local pcSrc = fs.readFile("src/client/Controllers/PlanetClient.luau")
	local edSrc = fs.readFile("src/client/Controllers/EnvDirector.luau")
	local psSrc = fs.readFile("src/server/Services/PlanetService.luau")
	local pwSrc = fs.readFile("src/server/World/PlanetWorld.luau")
	check(pcSrc:find("PlanetRegistry.surfaces()", 1, true) and edSrc:find("PlanetRegistry.surfaces()", 1, true) and psSrc:find("PlanetRegistry.surfaces()", 1, true) and pwSrc:find("function PlanetWorld.ensurePlanet", 1, true), "PlanetClient, EnvDirector, PlanetService y PlanetWorld usan el registro")
	check(psSrc:find("GalaxyMap.setPlanetMissions", 1, true) ~= nil, "el mapa galáctico sabe las misiones de cada planeta (setPlanetMissions)")
end

L.finish("test-planetas")
