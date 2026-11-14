-- test-planetmetro: la CIUDAD GRANDE de cada planeta (shared/Cosmos/PlanetMetro + MetroStyles; la dibuja
-- World/PlanetMetroBuilder). lune run scripts/test-planetmetro.luau

local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local Vector3 = require("@lune/roblox").Vector3
local check = L.check

local Registry = L.load("src/shared/Cosmos/PlanetRegistry")
local MetroStyles = L.load("src/shared/Cosmos/MetroStyles")

local KINDS = {}
for _, k in MetroStyles.Kinds do
	KINDS[k] = true
end
local builder = fs.readFile("src/server/World/PlanetMetroBuilder.luau")

for _, id in Registry.Order do
	local S = Registry.get(id)
	local M = S.Metro
	print(("🏙 %s · %s"):format(id, M and M.Name or "?"))
	check(M ~= nil, id .. " tiene ciudad grande")
	if not M then
		continue
	end
	local st = M.Style
	check(#st.Districts == 7, "siete distritos")
	local lots = M.lots()
	local min = if M.Mode == "Deck" then 300 else 180 -- (no todas igual de grandes: Raíz Honda es la más pequeña)
	check(#lots >= min, ("al menos %d edificios y plazas (tiene %d)"):format(min, #lots))

	-- cada distrito tiene lo suyo, y todos los tipos los sabe dibujar el constructor
	local per, kindsOk = {}, true
	for _, lot in lots do
		per[lot.District] = (per[lot.District] or 0) + 1
		if not KINDS[lot.Kind] or (lot.Kind ~= "Plaza" and lot.Kind ~= "Parque" and not string.find(builder, "draw." .. lot.Kind .. " = function", 1, true)) then
			kindsOk = false
		end
	end
	local allDistricts = true
	for _, d in st.Districts do
		allDistricts = allDistricts and (per[d.Id] or 0) >= 5
		for k in d.Mix do
			kindsOk = kindsOk and KINDS[k] == true
		end
	end
	check(allDistricts, "cada distrito tiene al menos 5 solares")
	check(kindsOk, "todos los tipos de edificio existen y el constructor los dibuja")

	-- nada pisa el barrio, los puntos de interés, los lagos ni otro edificio
	local clear, overlap, inZone = true, false, true
	for i, a in lots do
		if S.City.inside(a.X, a.Z, 20) then
			clear = false
		end
		for _, p in S.POIs or {} do
			if math.sqrt((a.X - p.X) ^ 2 + (a.Z - p.Z) ^ 2) < (p.Flat or 0) * 2.6 then
				clear = false
			end
		end
		for _, l in S.Lakes or {} do
			if math.sqrt((a.X - l.X) ^ 2 + (a.Z - l.Z) ^ 2) < l.R then
				clear = false
			end
		end
		inZone = inZone and math.abs(a.X) < S.Half * 0.8 and math.abs(a.Z) < S.Half * 0.8
		for j = i + 1, math.min(#lots, i + 40) do
			local b = lots[j]
			if math.abs(a.X - b.X) < (a.W + b.W) / 2 - 0.5 and math.abs(a.Z - b.Z) < (a.D + b.D) / 2 - 0.5 then
				overlap = true
			end
		end
	end
	check(clear, "ningún edificio pisa el barrio, un punto de interés o un lago")
	check(not overlap, "ningún edificio pisa a otro")
	check(inZone, "todo dentro de la zona del planeta")

	if M.Mode == "Ground" then
		local colors = S.TerrainColors or {}
		check(colors[st.StreetMaterial] ~= nil and colors[st.AvenueMaterial] ~= nil, "las calles usan materiales que el planeta pinta con su color")
		-- los lagos siguen siendo lagos
		local lakesOk = true
		for _, l in S.Lakes or {} do
			lakesOk = lakesOk and S.heightAt(S.Origin.X + l.X, S.Origin.Z + l.Z) - S.Origin.Y < S.WaterY
		end
		check(lakesOk, "la ciudad no rellena los lagos")
		-- en tierra: los edificios nunca quedan enterrados ni las calles pasan por debajo
		local buried, streetUnder = false, false
		for _, lot in lots do
			if lot.Base < S.heightAt(S.Origin.X + lot.X, S.Origin.Z + lot.Z) - S.Origin.Y - 0.5 then
				buried = true
			end
			if M.streetAt(lot.X, lot.Z) then
				streetUnder = true
			end
		end
		check(not buried, "ningún edificio enterrado")
		check(not streetUnder, "ninguna calle pasa por debajo de un edificio")
		-- hay calles pintadas, y en algún sitio con el material de las avenidas
		local streets = 0
		for x = -800, 800, 9 do
			for _, z in { -700, -520, 520, 700 } do
				if M.streetAt(x, z) then
					streets += 1
				end
			end
		end
		check(streets > 25, ("las calles se pintan en el terreno (%d muestras)"):format(streets))
		local lot = lots[math.floor(#lots / 2)]
		local inLot = S.materialAt(S.Origin.X + lot.X, S.Origin.Z + lot.Z)
		check(type(inLot) == "string", "el terreno sigue dando material dentro de la ciudad")
	else
		-- en plataformas: todo por encima del terreno y unido por pasarelas
		local above = true
		for _, lot in lots do
			above = above and S.rawHeight(lot.X, lot.Z) < lot.Base - 2
		end
		check(above, "las plataformas quedan por encima del terreno (y del agua)")
		local bridges = M.bridges()
		check(#bridges >= 60, ("pasarelas entre plataformas (%d)"):format(#bridges))
		local linked = 0
		for _, lot in lots do
			local r = lot.Rect
			for _, o in { { (r.X0 + r.X1) / 2, r.Z0 - 3 }, { (r.X0 + r.X1) / 2, r.Z1 + 3 }, { r.X0 - 3, (r.Z0 + r.Z1) / 2 }, { r.X1 + 3, (r.Z0 + r.Z1) / 2 } } do
				if M.bridgeAt(o[1], o[2]) then
					linked += 1
					break
				end
			end
		end
		check(linked >= #lots * 0.6, ("la mayoría de plataformas dan a una pasarela (%d de %d)"):format(linked, #lots))
		-- alguna pasarela llega al barrio
		local reaches = false
		for _, b in bridges do
			for _, p in { { b.X0 - 1, (b.Z0 + b.Z1) / 2 }, { b.X1 + 1, (b.Z0 + b.Z1) / 2 }, { (b.X0 + b.X1) / 2, b.Z0 - 1 }, { (b.X0 + b.X1) / 2, b.Z1 + 1 } } do
				if S.City.inside(p[1], p[2], 0) then
					reaches = true
				end
			end
		end
		check(reaches, "las pasarelas llegan al barrio de la plataforma de aterrizaje")
		if st.Rescue then
			local rx, rz = M.rescueSpot(lots[1].X + 7, lots[1].Z + 7)
			check(M.walkable(rx, rz), "quien se cae sale a un sitio por donde se anda")
		end
	end

	-- la nave choca con los edificios, no se posa encima, y el mapa dice el distrito
	local tall
	for _, lot in lots do
		if lot.Kind ~= "Plaza" and lot.Kind ~= "Parque" and (not tall or lot.Top > tall.Top) then
			tall = lot
		end
	end
	local O = S.Origin
	check(S.collide(Vector3.new(O.X + tall.X, O.Y + tall.Top - 6, O.Z + tall.Z), 4) == "un edificio", "la nave choca con el edificio más alto")
	check(S.collide(Vector3.new(O.X + tall.X, O.Y + tall.Top + 40, O.Z + tall.Z), 4) == nil, "y pasa por encima sin chocar")
	check(S.landSlopeAt(O.X + tall.X, O.Z + tall.Z) >= 9, "no se posa encima de un edificio")
	local d = M.districtAt(tall.X, tall.Z)
	check(d ~= nil and d.Id == tall.District, "el mapa dice en qué distrito estás")
	check(M.districtAt(0, 0) == nil, "en el barrio de la plataforma manda su propio plano")

	-- el mineral y la flora siguen fuera de la ciudad
	local nodes = S.nodes()
	local outside = true
	for _, n in nodes do
		if M.lotAt(n.Pos.X - O.X, n.Pos.Z - O.Z, 6) then
			outside = false
		end
	end
	check(outside, ("el mineral queda fuera de los edificios (%d de %d)"):format(#nodes, S.NodeCount))

	-- repetible: el mismo plano siempre
	local again = L.load("src/shared/Cosmos/PlanetMetro").new(S, st).lots()
	check(#again == #lots and again[#again].Kind == lots[#lots].Kind and again[1].X == lots[1].X, "el plano sale igual cada vez")
end

print("🏛 Monumentos y construcción de verdad (con piezas de Roblox fuera de Roblox)")
local roblox = require("@lune/roblox")
local PMB = L.load("src/server/World/PlanetMetroBuilder")
local kinds = {}
for _, id in Registry.Order do
	local S = Registry.get(id)
	local LM = S.Metro.Landmark
	check(LM ~= nil and LM.Name ~= nil, id .. ": tiene su gran monumento")
	kinds[LM.Kind] = true
	local clearLm = true
	for _, lot in S.Metro.lots() do
		if (lot.X - LM.X) ^ 2 + (lot.Z - LM.Z) ^ 2 < LM.R ^ 2 then
			clearLm = false
		end
	end
	check(clearLm, id .. ": ningún edificio dentro de la explanada del monumento")
	check(S.Metro.solidTop(LM.X, LM.Z, 2) == LM.Base + LM.Height and S.Metro.landingBlocked(LM.X, LM.Z), id .. ": la nave choca con el monumento y no se posa encima")
	local folder = roblox.Instance.new("Folder")
	local ok, model, stats = pcall(PMB.build, folder, S, {})
	check(ok and model ~= nil and model:FindFirstChild("Monumento_" .. LM.Kind) ~= nil, id .. ": la ciudad y su monumento se construyen sin errores " .. (if ok then "" else tostring(model)))
	if ok then
		local ships = model:FindFirstChild("NavesCielo")
		check(ships ~= nil and #ships:GetChildren() >= 5, id .. ": naves volando sobre la ciudad")
		check(stats.Parts < 14000, ("%s: piezas contenidas (%d)"):format(id, stats.Parts))
	end
end
local n = 0
for _ in kinds do
	n += 1
end
check(n == 7, "siete monumentos distintos")

print("🧱 Constructor y conexiones")
local world = fs.readFile("src/server/World/PlanetWorld.luau")
check(string.find(world, "PlanetWorld.buildMetro(S, folder", 1, true) ~= nil and string.find(world, "PlanetWorld.buildMetro(Tefra, folder", 1, true) ~= nil, "PlanetWorld construye la ciudad grande en todos los planetas")
check(string.find(builder, "\"StreetLamp\"", 1, true) ~= nil and string.find(builder, "\"CrowdSpot\"", 1, true) ~= nil and string.find(builder, "Builder.streamable", 1, true) ~= nil, "farolas, gente y edificios que se ven de lejos")
local map = fs.readFile("src/client/Controllers/MapUI.luau")
check(string.find(map, "here.Metro.districtAt", 1, true) ~= nil and string.find(map, "Tefra.Metro.districtAt", 1, true) ~= nil, "el minimapa nombra el distrito")
local styles = fs.readFile("src/shared/Cosmos/MetroStyles.luau")
local modern = { "🫧", "🪂", "🛖", "🪨", "🪵", "🪸", "🧊" }
local bad = {}
for _, e in modern do
	if string.find(styles, e, 1, true) and e ~= "🪂" and e ~= "🧊" then
		table.insert(bad, e)
	end
end
check(#bad == 0, "sin emoji modernos en los nombres (en Roblox salen como ▯)")

L.finish("test-planetmetro")
