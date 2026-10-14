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
--   * Volar de la Estación Alba a Lontana con la geometría de verdad hasta su atmósfera.
--   * Entrada y salida (PlanetEntry): fases, avisos al servidor una sola vez, nubes que tapan la
--     pantalla justo al pasar, abortar si das la vuelta, sin respuesta → atrás; los mandos siempre son
--     tuyos; el paso deja la velocidad, el motor y el turbo igual.
--   * Pasar de la esfera a la superficie (toSurface / toSpace): el sitio cae dentro de la zona, por
--     encima del terreno, con el rumbo equivalente; ida y vuelta da lo mismo; al salir no vuelves a
--     entrar sin querer.
--   * Lontana: terreno repetible, plataforma llana, lagos, materiales que no usa Valmar, lejos de
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
local Lontana = L.load("src/shared/Cosmos/Lontana")
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
	check(sameIds, "los mismos que la Saga 2 (Lontana, Ocrea, Marena, Velaria, Fronda, Zéfira, Mercadia)")
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
		farFromSurface = farFromSurface and (b.Center - Lontana.Origin).Magnitude > 20000 and (b.Center - Vector3.new(Arena.Center and Arena.Center.X or 24000, 0, 24000)).Magnitude > 8000
	end
	check(farFromSurface, "lejos de la superficie de Lontana y de la arena de pruebas")
	-- Dibujo: el mismo tamaño en pantalla, sin tocar la cámara, sin pasar de una pieza
	local lon = PlanetBodies.ById.Lontana
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
		return id == "Lontana"
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
print("\n🚀 Volar de la Estación Alba a la atmósfera de Lontana (ShipFlight + Zone)")
---------------------------------------------------------------------
do
	local lon = PlanetBodies.ById.Lontana
	local start = Stations.launch(Stations.ById.Alba)
	local sim = ShipFlight.new("Caza", start, "Space")
	local env = {
		mode = Zone.modeAt,
		collide = Zone.collide,
		bounds = function(pos)
			local back = Zone.bounds(pos)
			local push = PlanetBodies.repel(pos, function(id)
				return id == "Lontana"
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
			return id == "Lontana"
		end }, 1 / 30)
		if act == "Descend" then
			descend += 1
			reached = true
			break
		end
	end
	check(reached and not crashed, ("de la estación a la atmósfera de Lontana volando (%.0f s), sin chocar con nada%s"):format(t, if crashed then " (choca con " .. tostring(crashed) .. ")" else ""))
	check(descend == 1 and E.Phase == "Descending", "al fondo de la entrada se pide «Descend» una vez")
end

---------------------------------------------------------------------
print("\n☁️ Entrada y salida (PlanetEntry)")
---------------------------------------------------------------------
do
	local lon = PlanetBodies.ById.Lontana
	local up = PlanetEntry.frame(lon)
	local open = function(id)
		return id == "Lontana"
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
	check(E.Phase == "Entry" and E.Body == "Lontana", "hacia dentro y abierto: empieza la entrada")
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
	E3.Phase, E3.Body, E3.Sent = "Descending", "Lontana", true
	local act = nil
	for _ = 1, 50 do
		act = PlanetEntry.update(E3, { World = "Cosmos", Pos = at(100), Look = -up, Open = open }, 0.1)
		if act then
			break
		end
	end
	check(act == "Timeout" and E3.Phase ~= "Descending", "si el servidor no contesta, vuelve atrás (y se avisa)")
	-- Llegada
	PlanetEntry.relocated(E, "Planet", "Lontana")
	check(E.Phase == "Arrival" and PlanetEntry.effects(E).Cloud > 0.99, "llegada: aún entre nubes")
	local S = Lontana.Surface
	local arrivePos = Lontana.toWorld(0, 0, S.ArriveY)
	local clouds = {}
	for _ = 1, 30 do
		PlanetEntry.update(E, { World = "Planet", Pos = arrivePos, Look = Vector3.new(0, -0.3, -1).Unit, Surface = S }, 0.1)
		table.insert(clouds, PlanetEntry.effects(E).Cloud)
	end
	check(E.Phase == "Surface" and clouds[#clouds] == 0 and clouds[5] < clouds[1], "las nubes se abren y estás sobre Lontana")
	-- Subir: nubes, «Ascend» una vez y de vuelta
	local asc = 0
	for y = S.ClimbY - 100, S.CeilingY + 60, 40 do
		local a = PlanetEntry.update(E, { World = "Planet", Pos = Lontana.toWorld(0, 0, y), Look = Vector3.new(0, 0.6, -0.8), Surface = S }, 0.1)
		if a == "Ascend" then
			asc += 1
		end
	end
	check(asc == 1 and E.Phase == "Ascending" and PlanetEntry.effects(E).Cloud == 1, "subiendo: nubes y «Ascend» una sola vez en el techo")
	PlanetEntry.relocated(E, "Cosmos", "Lontana")
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
	local lon = PlanetBodies.ById.Lontana
	local S = Lontana.Surface
	local up, east, north = PlanetEntry.frame(lon)
	check(near(up:Dot(east), 0) and near(up:Dot(north), 0) and near(east:Dot(north), 0), "ejes del planeta perpendiculares")
	local cf0 = PlanetEntry.toSurface(lon, S, lon.Center + up * (lon.Radius + 150), -up)
	check(math.abs(cf0.Position.X - S.Origin.X) < 1 and math.abs(cf0.Position.Z - S.Origin.Z) < 1, "entrar por la cara que mira a Valmar: al centro de la zona")
	local maxH = -math.huge
	for lx = -1500, 1500, 60 do
		for lz = -1500, 1500, 60 do
			maxH = math.max(maxH, Lontana.heightAt(S.Origin.X + lx, S.Origin.Z + lz))
		end
	end
	local allIn, allAbove, headingOk, roundOk, noReenter = true, true, true, true, true
	local r = Lontana.rng(99)
	for _ = 1, 60 do
		local dir = (up + east * (r() * 2 - 1) * 0.9 + north * (r() * 2 - 1) * 0.9).Unit
		local pos = lon.Center + dir * (lon.Radius + 150)
		-- morro: hacia dentro con algo de rumbo
		local tangent = (east * (r() * 2 - 1) + north * (r() * 2 - 1))
		tangent = tangent - dir * tangent:Dot(dir)
		local look = (-dir * (0.3 + r() * 0.6) + tangent.Unit).Unit
		local cf, surf = PlanetEntry.toSurface(lon, S, pos, look)
		local lx, lz = Lontana.toLocal(cf.Position)
		allIn = allIn and math.abs(lx) <= S.Half - PlanetEntry.EdgeMargin + 0.01 and math.abs(lz) <= S.Half - PlanetEntry.EdgeMargin + 0.01
		allAbove = allAbove and cf.Position.Y - Lontana.heightAt(cf.Position.X, cf.Position.Z) > 600
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
		local out = PlanetEntry.toSpace(lon, S, Lontana.toWorld(lx, lz, S.CeilingY), Vector3.new(surf.X, 0.5, surf.Z).Unit)
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
print("\n🏔️ La superficie de Lontana")
---------------------------------------------------------------------
do
	local O = Lontana.Origin
	check(Lontana.heightAt(O.X + 123, O.Z - 456) == Lontana.heightAt(O.X + 123, O.Z - 456), "el terreno sale igual cada vez (semilla)")
	check(not Layers.inColumn(O, 3000) and (O - Vector3.new(24000, 0, 24000)).Magnitude > 20000, "lejos de Valmar, del espacio y de la arena de pruebas")
	local pad = Lontana.padY()
	local flat = true
	for a = 0, 7 do
		for _, d in { 0, 15, 30, 40 } do
			local h = Lontana.heightAt(O.X + math.cos(a) * d, O.Z + math.sin(a) * d)
			flat = flat and math.abs(h - pad) < 0.6
		end
	end
	check(flat and pad > Lontana.WaterY + 10, "la plataforma de aterrizaje es llana y está en seco")
	local water, total = 0, 0
	local mats = {}
	local allowed = true
	local maxSlopeOk = true
	for lx = -1400, 1400, 50 do
		for lz = -1400, 1400, 50 do
			local x, z = O.X + lx, O.Z + lz
			local h = Lontana.heightAt(x, z)
			total += 1
			if h < Lontana.WaterY then
				water += 1
			end
			local m = Lontana.materialAt(x, z, h)
			mats[m] = true
			allowed = allowed and Lontana.TerrainColors[m] ~= nil
		end
	end
	check(water > 0 and water / total < 0.15, ("lagos de agua (%.1f %% de la zona)"):format(water / total * 100))
	check(allowed, "el terreno solo usa materiales que el de Valmar no usa (se pueden teñir sin tocar la ciudad)")
	local valmarTerrain = { Grass = true, LeafyGrass = true, Rock = true, Sand = true, Ground = true, Mud = true, Water = true }
	local clash = false
	for m in Lontana.TerrainColors do
		clash = clash or valmarTerrain[m] == true
	end
	check(not clash, "(ni césped, ni roca, ni arena, ni tierra, ni barro de Valmar)")
	local n = 0
	for _ in mats do
		n += 1
	end
	check(n >= 5, ("variedad de suelo (%d materiales: tierra malva, ceniza, peñascos, orilla, quemado…)"):format(n))
	-- Mineral
	local nodes = Lontana.nodes()
	local onLand, spaced = true, true
	local ores = {}
	for i, nd in ipairs(nodes) do
		local _, w = Lontana.groundAt(nd.Pos.X, nd.Pos.Z)
		onLand = onLand and not w and Lontana.inRegion(nd.Pos) and near(nd.Pos.Y, Lontana.heightAt(nd.Pos.X, nd.Pos.Z), 0.01)
		ores[nd.Ore] = true
		for j = i + 1, #nodes do
			spaced = spaced and (nd.Pos - nodes[j].Pos).Magnitude > 60
		end
	end
	check(#nodes == Lontana.NodeCount and onLand and spaced, ("%d minerales en tierra y separados"):format(#nodes))
	check(ores.Cuarzo and Mining.Ores.Cuarzo ~= nil and (ores.Hierro or ores.Cobalto), "cuarzo malva (solo de Lontana) y también hierro o cobalto")
	check(Lontana.node(nodes[1].Id) == nodes[1], "cada mineral con su id")
	local decorOk = true
	for kind, count in Lontana.DecorCounts do
		local list = Lontana.decor(kind)
		decorOk = decorOk and #list == count
		for _, d in list do
			local _, w = Lontana.groundAt(d.Pos.X, d.Pos.Z)
			decorOk = decorOk and not w
		end
	end
	check(decorOk, "flora (pelusa, arbustos) y rocas en tierra, las justas para el móvil")
	local pieces = Lontana.DecorCounts.Pelusa * 2 + Lontana.DecorCounts.Arbusto * 3 + Lontana.DecorCounts.Roca + #nodes * 6
	check(pieces < 1000, ("piezas de encima razonables para el móvil (≈ %d)"):format(pieces))
	-- Choques y bordes
	local x, z = O.X + 40, O.Z + 60
	local h = Lontana.heightAt(x, z)
	check(Lontana.collide(Vector3.new(x, h + 3, z), 6) == "el suelo" and Lontana.collide(Vector3.new(x, h + 30, z), 6) == nil, "chocar con el suelo (sin rayos: la misma cuenta del terreno)")
	local lake = Lontana.Lakes[1]
	check(Lontana.collide(Lontana.toWorld(lake.X, lake.Z, Lontana.WaterY + 2), 6) == "el lago", "y con el lago")
	local edge = Lontana.toWorld(Lontana.Half - 100, 0, 800)
	check(Lontana.bounds(edge) and Lontana.bounds(edge).X < 0 and Lontana.bounds(Lontana.toWorld(0, 0, 800)) == nil, "en el borde de la zona, la nave gira hacia dentro")
	check(Lontana.bounds(Lontana.toWorld(0, 0, Lontana.CeilingY + 100)) == nil, "arriba no hay techo: subir es volver al espacio")
	local cp = Lontana.checkpoint()
	check(cp.Position.Y - Lontana.heightAt(cp.Position.X, cp.Position.Z) > 200 and Lontana.inRegion(cp.Position), "si te estrellas, reapareces volando por encima del terreno")
	check(Lontana.modeAt(cp.Position) == "Atmos" and not Lontana.safeAt(cp.Position), "con gravedad (modo atmósfera)")
end

---------------------------------------------------------------------
print("\n🛬 Aterrizar y despegar (Landing)")
---------------------------------------------------------------------
do
	local O = Lontana.Origin
	local function ground(x: number, z: number)
		local h, w = Lontana.groundAt(x, z)
		return h, w, Lontana.slopeAt(x, z)
	end
	local pad = O.Y + Lontana.padY()
	local function simAt(lx: number, lz: number, agl: number, speed: number, look: Vector3?)
		local p = Lontana.toWorld(lx, lz, 0)
		p = Vector3.new(p.X, Lontana.heightAt(p.X, p.Z) + agl, p.Z)
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
	check(near(s2.Pos.Y, Lontana.heightAt(s2.Pos.X, s2.Pos.Z) + Landing.RestHeight, 0.01) and s2.Speed == 0 and near(s2.Rot.UpVector.Y, 1, 1e-3), "posada: sobre el tren, quieta y nivelada")
	check(Zone and Lontana.collide(s2.Pos, ShipFlight.Specs.Caza.Radius * 0.7) == nil, "y el servidor no la ve chocar (radio de choque del servidor)")
	local lake = Lontana.Lakes[1]
	local s3 = ShipFlight.new("Caza", CFrame.new(Lontana.toWorld(lake.X, lake.Z, Lontana.WaterY + 15)), "Atmos")
	s3.Speed = 50
	local L3 = Landing.new()
	Landing.step(L3, s3, {}, 1 / 30, ground)
	check(L3.Phase == "Flying", "sobre el agua no se posa")
	-- Una cuesta: buscamos un sitio empinado
	local steep: Vector3? = nil
	for lx = -1300, 1300, 37 do
		for lz = -1300, 1300, 41 do
			local x, z = O.X + lx, O.Z + lz
			if Lontana.slopeAt(x, z) > 0.7 and not select(2, Lontana.groundAt(x, z)) then
				steep = Vector3.new(x, Lontana.heightAt(x, z) + 15, z)
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
	local groundY = Lontana.heightAt(s2.Pos.X, s2.Pos.Z)
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
	local env = { mode = Lontana.modeAt, collide = Lontana.collide, bounds = Lontana.bounds }
	local s5 = ShipFlight.new("Caza", CFrame.new(Lontana.toWorld(-140, 0, pad + 36)) * PlanetEntry.facing(Vector3.new(1, 0, 0)), "Atmos")
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
	check(PS0.isLanded(Lontana, s5.Pos, Vector3.zero) and not PS0.isLanded(Lontana, s5.Pos + Vector3.new(0, 40, 0), Vector3.zero) and not PS0.isLanded(Lontana, s5.Pos, Vector3.new(40, 0, 0)), "servidor: posada sí; alta o deprisa, no")
	check(not PS0.isLanded(Lontana, Lontana.toWorld(lake.X, lake.Z, Lontana.WaterY + 3), Vector3.zero), "servidor: sobre el agua, no")
	L.reset("src/server/Services/PlanetService")
end

---------------------------------------------------------------------
print("\n🖥️ Servidor: PlanetService (bajar, subir, bajarse, minar a pie)")
---------------------------------------------------------------------
do
	local lon = PlanetBodies.ById.Lontana
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
			if id ~= "Lontana" then
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
	check(PS.statusFor(player).Ocrea == "Soon", "los otros planetas: «próximamente»")
	status = "Ready"
	check(PS.statusFor(player).Lontana == "Ready", "Lontana abierto (Saga 1 terminada o tester)")
	-- Lejos de la atmósfera: no
	local real = ac.Pos
	ac.Pos = lon.Center + up * (PlanetBodies.entryRadius(lon) + 2000)
	check(not PS.descend(player), "pedir «Descend» lejos del planeta: no (lo comprueba el servidor)")
	ac.Pos = real
	check(PS.descend(player) and acLog[1][1] == "relocate" and acLog[1][3].World == "Planet" and acLog[1][3].Planet == "Lontana", "en el fondo de la atmósfera: a la superficie (relocate, sin cortar el vuelo)")
	local cf = acLog[1][2]
	check(Lontana.inRegion(cf.Position) and cf.Position.Y == Lontana.ArriveY and player:GetAttribute("Planeta") == "Lontana", "dentro de la zona de Lontana, a la altura de llegada")
	check(player:GetAttribute("SpaceReturn") == Access.arrival().Position, "si te desconectas en el planeta, vuelves al puerto espacial")
	-- Subir
	check(not PS.ascend(player), "subir desde abajo: no")
	ac.Pos = Lontana.toWorld(100, -200, Lontana.CeilingY + 10)
	ac.Look = Vector3.new(0.3, 0.7, -0.6).Unit
	check(PS.ascend(player) and ac.World == "Cosmos" and player:GetAttribute("Planeta") == nil, "desde el techo: de vuelta al espacio")
	check((ac.Pos - lon.Center).Magnitude > PlanetBodies.entryRadius(lon), "junto a Lontana, fuera de su atmósfera")
	-- Bajarse: solo posada
	ac.World, ac.Planet = "Planet", "Lontana"
	local spot = Lontana.toWorld(10, 5, Lontana.padY() + 30)
	ac.Pos, ac.Look, ac.Vel = spot, Vector3.new(1, 0, 0), Vector3.new(30, 0, 0)
	table.clear(acLog)
	check(not PS.disembark(player) and #acLog == 0, "volando: no te puedes bajar")
	ac.Pos = Vector3.new(spot.X, Lontana.heightAt(spot.X, spot.Z) + Landing.RestHeight, spot.Z)
	ac.Vel = Vector3.zero
	check(PS.disembark(player) and parked[player] ~= nil, "posada: te bajas y la nave se queda aparcada")
	local ret = nil
	for _, e in acLog do
		if e[1] == "return" then
			ret = e[2]
		end
	end
	check(ret and ret.Position.Y > Lontana.heightAt(ret.Position.X, ret.Position.Z) and (ret.Position - ac.Pos).Magnitude < 20, "apareces al lado de la nave, de pie sobre el suelo")
	local pcf = parked[player].PrimaryPart.CFrame
	check(near(pcf.UpVector.Y, 1, 1e-3) and near(pcf.Position.Y, Lontana.heightAt(pcf.Position.X, pcf.Position.Z) + Landing.RestHeight, 0.01), "la nave aparcada, nivelada sobre su tren")
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
	local node = Lontana.nodes()[1]
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
	local beacon = Lontana.PoiById.Baliza
	standAt(Lontana.toWorld(beacon.X, beacon.Z, Lontana.poiY("Baliza") + 3))
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
	check(found == 2 and #Lontana.POIs >= 3, ("%d puntos de interés (baliza, ruinas, restos de nave, plataforma)"):format(#Lontana.POIs))
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
	local lon = PlanetBodies.ById.Lontana
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
	local target = PlanetEntry.toSurface(lon, Lontana.Surface, cp.Position, -up)
	check(AC.relocate(player, target, { World = "Planet", Geo = Lontana, Planet = "Lontana" }), "relocate al planeta")
	check(s.World == "Planet" and s.Geo == Lontana and s.Planet == "Lontana" and (root.CFrame.Position - target.Position).Magnitude < 1e-3 and s.LastGood == target, "la nave está en la superficie y es el último sitio bueno")
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
	local O = Lontana.Origin
	-- un trozo en la plataforma y otro en el lago grande
	local lake = Lontana.Lakes[1]
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
				local h = Lontana.heightAt(x, z)
				-- la ocupación de la columna suma la altura del suelo sobre el fondo de la región
				local sum = 0
				for j = 1, #w.Occs[i] do
					local m = w.Mats[i][j][k]
					if m == roblox.Enum.Material.Water then
						waterSeen = true
					elseif m ~= roblox.Enum.Material.Air then
						sum += w.Occs[i][j][k] * 4
						allowed = allowed and Lontana.TerrainColors[m.Name] ~= nil
					end
				end
				surfaceOk = surfaceOk and math.abs(minY + sum - h) < 1.2
			end
		end
	end
	check(shapeOk, "rejilla de 4 studs, 16 × 16 columnas por trozo")
	check(surfaceOk, "la superficie de los vóxeles está a la altura de heightAt (lo que choca es lo que se ve)")
	check(waterSeen, "agua en el lago")
	check(allowed, "materiales de Lontana")
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
	local pl = EspacioLook.planet(empty, "Lontana")
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
	check(EspacioLook.planet(fake, "Zefira").Texture == fake.planeta_zefira, "y cada planeta su superficie (Zéfira → planeta_zefira)")
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

L.finish("test-planetas")
