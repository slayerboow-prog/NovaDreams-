-- Puerto: el PUERTO DE VALMAR (Distrito Sur), un puerto de verdad (docs/mapa/puerto.md).
--
-- Lo coloca todo según shared/Port/PuertoPlan con las piezas de Kit/PuertoKit:
--   Town.Puerto         (tierra) explanadas, valla y control de acceso, naves y vía de carga, patio de
--                       contenedores, grúas pórtico, oficinas y torre de control, lonja, fábrica de
--                       hielo, estación marítima (barca a la Isla del Faro), torres de luz, carteles,
--                       tablón de pescadores y trabajadores (WorkerSpot)
--   Town.PuertoDarsena  (agua) muelles de hormigón con defensas, neumáticos, bolardos, escaleras y
--                       cabos; buque portacontenedores, remolcadores, pesqueros, veleros y la barca;
--                       pantalanes de pesca y de recreo; dique de abrigo con tetrápodos y baliza;
--                       sitios de pesca y el amarre del barco de pesca (FishingBoatDock)
-- (El barco de pesca de alta mar, FishingKit.boat, sigue fondeado mar adentro, donde siempre.)
--
-- Puerto.terrain(terrain) excava la dársena (agua de verdad junto a los muelles); lo llama
-- TerrainBuilder al arrancar. La costa de la isla (CityPlan.Coast) no cambia.

local Builder = require(script.Parent.Parent.Builder)
local Props = require(script.Parent.Props)
local FishingKit = require(script.Parent.FishingKit)
local K = require(script.Parent.PuertoKit)
local Plan = require(game:GetService("ReplicatedStorage").Shared.Port.PuertoPlan)

local Puerto = {}

local rgb = Color3.fromRGB
local V3 = Vector3.new
local CF = CFrame.new
local C = K.Colors
local G = Plan.Ground
local SEA = Plan.SeaLevel
local box, dec = K.box, K.dec

local function mid(r: any): (number, number, number, number)
	return (r.X0 + r.X1) / 2, (r.Z0 + r.Z1) / 2, r.X1 - r.X0, r.Z1 - r.Z0
end

local function slab(parent: Instance, name: string, r: any, y0: number, y1: number, color: Color3, material: Enum.Material): BasePart
	local cx, cz, w, d = mid(r)
	return box(parent, name, V3(w, y1 - y0, d), CF(cx, (y0 + y1) / 2, cz), color, material)
end

local function spotLight(part: BasePart, range: number, color: Color3)
	local light = Instance.new("PointLight")
	light.Range = range
	light.Brightness = 1.6
	light.Color = color
	light.Shadows = false
	light.Enabled = false
	light.Parent = part
end

local function worker(parent: Instance, role: string, p: Vector3, look: Vector3)
	local spot = Builder.decor({
		Name = "WorkerSpot",
		Size = V3(1, 1, 1),
		CFrame = Builder.facing(p + V3(0, 0.5, 0), look),
		Transparency = 1,
		Parent = parent,
	})
	spot:SetAttribute("Role", role)
	spot:AddTag("WorkerSpot")
end

---------------------------------------------------------------------
-- Tierra: explanadas, valla, control, naves, patio, grúas, edificios
---------------------------------------------------------------------

local function buildGate(m: Instance)
	local g = Plan.Gate
	local gm = Builder.model("ControlAcceso", m)
	Builder.streamable(gm)
	gm:SetAttribute("PlaceName", "Control de acceso (aduana)")
	-- Marquesina sobre los dos carriles
	box(gm, "Marquesina", V3(52, 1, 16), CF(g.X, G + 9.5, 3188), C.White, Enum.Material.Metal)
	dec(gm, "MarquesinaFranja", V3(52.2, 0.8, 16.2), CF(g.X, G + 9.6, 3188), C.Signal)
	for _, x in { g.X - 24, g.X + 24 } do
		for _, z in { 3181, 3195 } do
			box(gm, "Pilar", V3(1, 9, 1), CF(x, G + 4.5, z), C.Steel, Enum.Material.Metal)
		end
	end
	-- Isleta y garita con cristales
	box(gm, "Isleta", V3(6, 0.4, 16), CF(g.X, G + 0.2, 3188), C.ConcreteDark, Enum.Material.Concrete)
	box(gm, "Garita", V3(4.6, 6.4, 6), CF(g.X, G + 3.6, 3189), C.White)
	for _, s in { -1, 1 } do
		local glass = dec(gm, "GaritaCristal", V3(0.1, 2.4, 4.6), CF(g.X + s * 2.33, G + 4.4, 3189), C.Glass, Enum.Material.Glass, { Tags = { "NightWindow" } })
		glass.Transparency = 0.2
	end
	box(gm, "GaritaTecho", V3(5.6, 0.5, 7), CF(g.X, G + 7.05, 3189), C.Signal)
	-- Barreras (rojas y blancas): la de entrada bajada, la de salida levantada (no bloquean los coches)
	for i, x in { g.LaneIn, g.LaneOut } do
		local postX = if i == 1 then g.X - 3.6 else g.X + 3.6
		box(gm, "BarreraPoste", V3(1, 3.4, 1), CF(postX, G + 1.7, 3179), rgb(230, 230, 226), Enum.Material.Metal)
		local dir = if i == 1 then -1 else 1
		local arm = if i == 1
			then CF(postX + dir * 8, G + 3, 3179)
			else CF(postX, G + 3, 3179) * CFrame.Angles(0, 0, math.rad(80) * dir) * CF(dir * 8, 0, 0)
		local a = dec(gm, "BarreraBrazo", V3(16, 0.5, 0.5), arm, rgb(200, 30, 30))
		for k = -2, 2, 2 do
			dec(gm, "BarreraFranja", V3(1.6, 0.52, 0.52), a.CFrame * CF(k * 2.5, 0, 0), C.White)
		end
		-- Línea de detención
		dec(gm, "LineaStop", V3(16, 0.06, 0.8), CF(x, G + 0.03, 3176.6), C.White)
	end
	-- Pórtico con el cartel del puerto, bien de pie sobre la entrada (se lee desde la calle)
	for _, x in { g.X - 26, g.X + 26 } do
		box(gm, "PorticoPilar", V3(1.4, 17, 1.4), CF(x, G + 8.5, 3175.6), C.Steel, Enum.Material.Metal)
	end
	K.board(gm, CF(g.X, G + 15, 3175.6) * CFrame.Angles(0, math.pi, 0), 50, 4.4, "⚓ PUERTO DE VALMAR", rgb(20, 70, 130))
	K.board(gm, CF(g.X, G + 11.6, 3175.6) * CFrame.Angles(0, math.pi, 0), 30, 2, "CONTROL DE ACCESO · ADUANA", C.Steel)
	K.sign(gm, Builder.facing(V3(g.X + 30, G, 3177), V3(0, 0, -1)), 6, 2.4, "20 km/h", rgb(200, 30, 30), 3)
	worker(m, "Guardia", V3(g.X + 3.6, G, 3192), V3(-1, 0, 0))
end

local function buildRailSiding(m: Instance)
	local r = Builder.model("ViaDeCarga", m)
	local z = 3236
	dec(r, "Balasto", V3(150, 0.2, 7), CF(396, G + 0.1, z), rgb(110, 100, 90), Enum.Material.Pebble)
	dec(r, "Traviesas", V3(150, 0.18, 5.4), CF(396, G + 0.3, z), rgb(80, 66, 52), Enum.Material.Wood)
	for _, dz in { -2.35, 2.35 } do
		dec(r, "Carril", V3(150, 0.4, 0.4), CF(396, G + 0.6, z + dz), C.Steel, Enum.Material.Metal)
	end
	box(r, "TopeVia", V3(1.6, 3, 7), CF(322, G + 1.5, z), rgb(200, 40, 30), Enum.Material.Metal)
	dec(r, "TopeFranja", V3(1.7, 0.8, 7.1), CF(322, G + 2.4, z), C.Coping)
	-- Dos vagones plataforma con contenedores
	for i, x in { 360, 400 } do
		box(r, "Vagon", V3(38, 1.2, 6.2), CF(x, G + 2.4, z), rgb(70, 70, 76), Enum.Material.Metal)
		for _, dx in { -14, 14 } do
			dec(r, "Bogie", V3(6, 1.6, 5), CF(x + dx, G + 1.2, z), C.Black, Enum.Material.Metal)
		end
		K.container(r, CF(x, G + 3, z), 34, K.ContainerColors[(i * 4) % #K.ContainerColors + 1])
	end
end

local CODES = { "VLMU 204518 2", "SURU 771302 5", "FARU 390114 8", "GAVU 552876 1", "MARU 118940 3", "CORU 640275 9" }

local function buildYard(m: Instance)
	local y = Builder.model("PatioContenedores", m)
	local cx, cz, w, d = mid(Plan.Yard)
	dec(y, "Asfalto", V3(w, 0.06, d), CF(cx, G + 0.03, cz), C.Asphalt, Enum.Material.Asphalt)
	-- Líneas del carril de camiones y de las calles del patio
	for _, z in { 3240, 3254 } do
		dec(y, "Linea", V3(w - 4, 0.08, 0.6), CF(cx, G + 0.07, z), C.Coping)
	end
	dec(y, "Linea", V3(0.6, 0.08, 44), CF(615, G + 0.07, 3216), C.White)
	local n = 0
	local codeN = 0
	for b, block in Plan.YardBlocks do
		local stacks = Builder.model("Bloque" .. b, y)
		Builder.streamable(stacks)
		for row = 0, 4 do
			local z = block.Z0 + 4 + row * 7.6
			for bay = 0, 2 do
				n += 1
				local x = block.X0 + 4 + 17 + bay * 37
				local tiers = 1 + ((n * 7 + row * 3 + b) % 3) -- 1 a 3 alturas
				if (n + row) % 7 == 0 then
					tiers = 0 -- algún hueco (como en un patio de verdad)
				end
				for t = 0, tiers - 1 do
					local color = K.ContainerColors[(n * 5 + t * 3 + row) % #K.ContainerColors + 1]
					local base = CF(x, G + t * 7.25, z)
					local marks: string? = nil
					if t == 0 and (row == 0 or row == 4) and bay ~= 1 then
						codeN += 1
						marks = CODES[codeN % #CODES + 1]
					end
					if row == 4 then
						base *= CFrame.Angles(0, math.pi, 0) -- (el código hacia el carril)
					end
					if (n + t) % 5 == 0 then
						-- Dos de 20 pies en vez de uno de 40
						K.container(stacks, base * CF(-8.6, 0, 0), 17, color, nil)
						K.container(stacks, base * CF(8.6, 0, 0), 17, K.ContainerColors[(n + t) % #K.ContainerColors + 1], nil)
					else
						K.container(stacks, base, 34, color, marks)
					end
				end
			end
		end
	end
	-- Pórtico apilador (straddle carrier) en el carril, con un contenedor entre las patas
	local sc = Builder.model("Portacontenedores", y)
	local sx, sz = 700, 3247
	for _, dx in { -15, 15 } do
		for _, dz in { -4.6, 4.6 } do
			box(sc, "Pata", V3(1.2, 13, 1.2), CF(sx + dx, G + 7.5, sz + dz), rgb(232, 196, 40), Enum.Material.Metal)
			dec(sc, "Rueda", V3(1.2, 2.4, 2.4), CF(sx + dx, G + 1.2, sz + dz) * CFrame.Angles(0, math.rad(90), 0), C.Black, Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder })
		end
		dec(sc, "Viga", V3(1.4, 1.4, 10.6), CF(sx + dx, G + 14.4, sz), rgb(232, 196, 40), Enum.Material.Metal)
	end
	box(sc, "VigaLarga", V3(32, 1.6, 1.6), CF(sx, G + 15.6, sz - 4.6), rgb(232, 196, 40), Enum.Material.Metal)
	box(sc, "VigaLarga", V3(32, 1.6, 1.6), CF(sx, G + 15.6, sz + 4.6), rgb(232, 196, 40), Enum.Material.Metal)
	dec(sc, "Cabina", V3(3.4, 3, 3.4), CF(sx + 15, G + 18, sz - 4.6), C.Glass, Enum.Material.Glass)
	K.container(sc, CF(sx, G + 3.4, sz), 34, K.ContainerColors[3])
	-- Grúa apiladora (reach stacker) junto al bloque 1
	local rs = Builder.model("Apiladora", y)
	local rx, rz = 560, 3247
	box(rs, "Cuerpo", V3(16, 4, 7), CF(rx, G + 3, rz), rgb(222, 120, 30), Enum.Material.Metal)
	box(rs, "CabinaApiladora", V3(4, 4, 4), CF(rx - 2, G + 7, rz + 1.2), C.Glass, Enum.Material.Glass)
	K.bar(rs, "Brazo", V3(rx + 6, G + 5, rz), V3(rx - 10, G + 16, rz), 1.6, rgb(222, 120, 30), Enum.Material.Metal, true)
	for _, dx in { -5.5, 5.5 } do
		for _, dz in { -3.8, 3.8 } do
			dec(rs, "Rueda", V3(1.6, 3, 3), CF(rx + dx, G + 1.5, rz + dz) * CFrame.Angles(0, math.rad(90), 0), C.Black, Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder })
		end
	end
	dec(rs, "Spreader", V3(2.4, 0.8, 18), CF(rx - 12, G + 15.4, rz), C.Steel, Enum.Material.Metal)
	-- Camiones con remolque portacontenedores (uno bajo la grúa del medio, otro en el carril)
	for i, t in { { 612, 3277, 1 }, { 650, 3247, -1 } } do
		local tm = Builder.model("Camion", y)
		local face = Builder.facing(V3(t[1], G, t[2]), V3(t[3], 0, 0))
		box(tm, "Cabeza", V3(7, 7, 7.6), face * CF(0, 4.2, -19), if i == 1 then rgb(30, 90, 160) else rgb(200, 40, 40), Enum.Material.Metal)
		dec(tm, "Parabrisas", V3(6, 2.4, 0.1), face * CF(0, 5.6, -22.85), C.Glass, Enum.Material.Glass)
		box(tm, "Chasis", V3(6, 1, 34), face * CF(0, 1.8, 2), C.Black, Enum.Material.Metal)
		for _, dz in { -19, -6, 14 } do
			dec(tm, "Ejes", V3(7, 2.2, 2.2), face * CF(0, 1.1, dz) * CFrame.Angles(0, 0, math.rad(90)), C.Black, Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder })
		end
		K.container(tm, face * CF(0, 2.3, 2) * CFrame.Angles(0, math.rad(90), 0), 34, K.ContainerColors[(i * 7) % #K.ContainerColors + 1])
	end
end

local function buildCranes(m: Instance)
	local rails = Plan.CraneRails
	local cm = Builder.model("Gruas", m)
	for _, z in { rails.Sea, rails.Land } do
		dec(cm, "CarrilGrua", V3(rails.X1 - rails.X0, 0.3, 0.8), CF((rails.X0 + rails.X1) / 2, G + 0.15, z), C.Steel, Enum.Material.Metal)
		dec(cm, "CarrilGruaRanura", V3(rails.X1 - rails.X0, 0.05, 2.4), CF((rails.X0 + rails.X1) / 2, G + 0.03, z), C.ConcreteDark, Enum.Material.Concrete)
	end
	for i, x in Plan.Cranes do
		K.crane(cm, x, Plan, i)
	end
	K.sign(m, Builder.facing(V3(476, G, 3258), V3(0, 0, -1)), 12, 2.6, "⚠ ZONA DE GRÚAS · SOLO PERSONAL", rgb(200, 120, 20), 2)
	worker(m, "Estibador", V3(640, G, 3279), V3(0, 0, 1))
	worker(m, "Estibador", V3(590, G, 3247), V3(0, 0, -1))
end

local function buildOffices(m: Instance)
	local o = Builder.model("OficinasPuerto", m)
	Builder.streamable(o)
	o:SetAttribute("PlaceName", "Capitanía y oficinas del puerto")
	local x0, x1, z0, z1 = 796, 876, 3214, 3254
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	box(o, "Edificio", V3(x1 - x0, 17, z1 - z0), CF(cx, G + 8.5, cz), rgb(226, 222, 214), Enum.Material.Concrete)
	for f = 0, 2 do
		local y = G + 3.4 + f * 5.2
		dec(o, "VentanasSur", V3(x1 - x0 - 4, 2.4, 0.1), CF(cx, y, z1 + 0.06), C.Glass, Enum.Material.Glass, { Tags = { "NightWindow" }, Attributes = { Soft = true } })
		dec(o, "VentanasOeste", V3(0.1, 2.4, z1 - z0 - 4), CF(x0 - 0.06, y, cz), C.Glass, Enum.Material.Glass, { Tags = { "NightWindow" }, Attributes = { Soft = true } })
		dec(o, "VentanasNorte", V3(x1 - x0 - 4, 2.4, 0.1), CF(cx, y, z0 - 0.06), C.Glass, Enum.Material.Glass, { Tags = { "NightWindow" }, Attributes = { Soft = true } })
	end
	dec(o, "Peto", V3(x1 - x0 + 0.4, 1.2, z1 - z0 + 0.4), CF(cx, G + 17.6, cz), C.Signal)
	box(o, "Entrada", V3(4, 0.6, 12), CF(x0 - 2, G + 4.2, cz), C.Signal)
	local door = dec(o, "Puerta", V3(0.1, 3.6, 5), CF(x0 - 0.07, G + 1.8, cz), rgb(60, 90, 120), Enum.Material.Glass)
	door.Transparency = 0.2
	local rot = dec(o, "Rotulo", V3(0.15, 2.6, 30), CF(x0 - 0.12, G + 15.6, cz), C.Signal)
	Builder.sign(rot, "CAPITANÍA · OFICINAS DEL PUERTO", Enum.NormalId.Left, C.White, C.Signal)
	-- Mástiles con banderas (azul del puerto y blanca)
	for i, z in { cz - 10, cz + 10 } do
		box(o, "Mastil", V3(0.4, 14, 0.4), CF(x0 - 8, G + 7, z), C.White, Enum.Material.Metal)
		dec(o, "Bandera", V3(0.1, 2.6, 4.2), CF(x0 - 8, G + 12.6, z + 2.2), if i == 1 then rgb(20, 70, 130) else C.White, Enum.Material.Fabric)
	end
	-- Torre de control del puerto (vigila la bocana)
	local t = Builder.model("TorreControl", m)
	Builder.streamable(t)
	box(t, "Fuste", V3(4, 24, 4), CF(866, G + 12, 3274), C.White, Enum.Material.Concrete)
	box(t, "Sala", V3(9, 5, 9), CF(866, G + 26.5, 3274), C.Signal)
	local glass = dec(t, "Cristal", V3(9.2, 3, 9.2), CF(866, G + 27, 3274), rgb(70, 110, 140), Enum.Material.Glass, { Tags = { "NightWindow" } })
	glass.Transparency = 0.1
	dec(t, "Antena", V3(0.3, 7, 0.3), CF(866, G + 32.5, 3274), C.Steel, Enum.Material.Metal)
	dec(t, "Radar", V3(5, 0.4, 0.8), CF(866, G + 36, 3274), C.White)
end

local function buildLonja(m: Instance)
	local l = Builder.model("Lonja", m)
	Builder.streamable(l)
	l:SetAttribute("PlaceName", "Lonja de Valmar")
	local x0, x1, z0, z1 = 372, 436, 3312, 3362
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	dec(l, "Suelo", V3(x1 - x0, 0.1, z1 - z0), CF(cx, G + 0.05, cz), rgb(210, 216, 220), Enum.Material.Marble)
	for _, x in { x0 + 1, (x0 + x1) / 2, x1 - 1 } do
		for _, z in { z0 + 1, z1 - 1 } do
			box(l, "Pilar", V3(1.4, 10, 1.4), CF(x, G + 5, z), C.White, Enum.Material.Concrete)
		end
	end
	box(l, "MuroFondo", V3(1, 10, z1 - z0), CF(x0 + 0.5, G + 5, cz), rgb(206, 220, 230), Enum.Material.Concrete)
	box(l, "Cubierta", V3(x1 - x0 + 4, 1, z1 - z0 + 4), CF(cx, G + 10.5, cz), rgb(60, 110, 150), Enum.Material.Metal)
	local fascia = box(l, "Rotulo", V3(0.4, 2.6, 34), CF(x1 + 2.2, G + 9.2, cz), C.White)
	Builder.sign(fascia, "LONJA DE VALMAR", Enum.NormalId.Right, C.Signal, C.White)
	Builder.sign(fascia, "LONJA DE VALMAR", Enum.NormalId.Left, C.Signal, C.White)
	-- Mesas de subasta con cajas de pescado en hielo
	for i, z in { z0 + 10, cz, z1 - 10 } do
		box(l, "Mesa", V3(18, 3, 4), CF(cx, G + 1.5, z), rgb(200, 204, 210), Enum.Material.Metal)
		for k = -3, 3, 2 do
			dec(l, "CajaPescado", V3(2.2, 0.8, 1.6), CF(cx + k * 2.4, G + 3.4, z), if (k + i) % 4 == 0 then rgb(230, 230, 236) else rgb(60, 140, 200))
			dec(l, "Hielo", V3(2, 0.2, 1.4), CF(cx + k * 2.4, G + 3.85, z), rgb(220, 240, 250), Enum.Material.Ice)
		end
	end
	local board = dec(l, "Pizarra", V3(0.2, 4, 10), CF(x0 + 1.1, G + 6, cz), rgb(30, 40, 36))
	Builder.sign(board, "SUBASTA\n6:00 · 17:00", Enum.NormalId.Right, C.White, rgb(30, 40, 36))
	worker(m, "Pescadera", V3(cx, G, z0 + 14), V3(1, 0, 0))
	-- Fábrica de hielo
	local h = Builder.model("FabricaHielo", m)
	Builder.streamable(h)
	box(h, "Nave", V3(34, 14, 34), CF(347, G + 7, 3330), rgb(220, 232, 240), Enum.Material.Metal)
	box(h, "Silo", V3(14, 6, 6), CF(347, G + 18, 3322) * CFrame.Angles(0, 0, math.rad(90)), C.White, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	for _, z in { 3334, 3342 } do
		dec(h, "Condensador", V3(8, 2.4, 6), CF(347, G + 15.2, z), C.Steel, Enum.Material.Metal)
	end
	local s = dec(h, "Rotulo", V3(20, 3, 0.2), CF(347, G + 10, 3312.9), C.Signal)
	Builder.sign(s, "❄ FÁBRICA DE HIELO", Enum.NormalId.Front, C.White, C.Signal)
	dec(h, "Puerta", V3(10, 9, 0.1), CF(347, G + 4.5, 3347.06), rgb(196, 198, 196), Enum.Material.Metal)
	-- Redes tendidas, cajas y boyas
	for _, x in { 384, 412 } do
		box(m, "PosteRed", V3(0.5, 7, 0.5), CF(x, G + 3.5, 3390), C.Wood, Enum.Material.Wood)
	end
	local net = dec(m, "RedTendida", V3(28, 5, 0.2), CF(398, G + 4, 3390), rgb(60, 130, 90), Enum.Material.Fabric)
	net.Transparency = 0.25
	for i, p in { { 424, 3384 }, { 428, 3398 }, { 392, 3402 } } do
		for t = 0, 2 - (i % 2) do
			dec(m, "CajasPesca", V3(3, 1.2, 2.2), CF(p[1], G + 0.6 + t * 1.2, p[2]) * CFrame.Angles(0, i * 0.4, 0), if t % 2 == 0 then rgb(40, 110, 190) else rgb(230, 120, 40))
		end
	end
	dec(m, "MontonRedes", V3(5, 1.6, 4), CF(420, G + 0.8, 3410), rgb(200, 90, 50), Enum.Material.Fabric)
	dec(m, "MontonBoyas", V3(3, 3, 3), CF(408, G + 1.5, 3412), rgb(240, 120, 30), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball })
	Props.jobBoard(m, Builder.facing(V3(432, G, 3374), V3(1, 0, 0)), "Pescador", "PESCADORES")
	K.sign(m, Builder.facing(V3(434, G, 3300), V3(0, 0, -1)), 12, 2.4, "MUELLE PESQUERO · LONJA", C.Signal, 3)
end

local function buildFerryHall(m: Instance, darsena: Instance, islandTarget: Vector3)
	local f = Builder.model("EstacionMaritima", m)
	Builder.streamable(f)
	f:SetAttribute("PlaceName", "Estación marítima")
	local r = Plan.FerryHall
	local cx, cz, w, d = mid(r)
	dec(f, "Suelo", V3(w, 0.1, d), CF(cx, G + 0.05, cz), rgb(222, 214, 196), Enum.Material.Limestone)
	-- Cristal al norte, al oeste y al sur; abierta al este (hacia el dique y la barca)
	local glassN = box(f, "Cristal", V3(w, 8, 0.4), CF(cx, G + 4, r.Z0), C.Glass, Enum.Material.Glass)
	local glassS = box(f, "Cristal", V3(w, 8, 0.4), CF(cx, G + 4, r.Z1), C.Glass, Enum.Material.Glass)
	local glassW = box(f, "Cristal", V3(0.4, 8, d), CF(r.X0, G + 4, cz), C.Glass, Enum.Material.Glass)
	for _, g in { glassN, glassS, glassW } do
		g.Transparency = 0.45
	end
	box(f, "Cubierta", V3(w + 8, 1, d + 6), CF(cx + 2, G + 8.5, cz), C.White, Enum.Material.Metal)
	local fascia = dec(f, "Rotulo", V3(0.2, 2.6, 36), CF(r.X1 + 6.12, G + 7.4, cz), C.Signal)
	Builder.sign(fascia, "ESTACIÓN MARÍTIMA", Enum.NormalId.Right, C.White, C.Signal)
	for _, z in { r.Z0 + 1, cz, r.Z1 - 1 } do
		box(f, "Pilar", V3(0.8, 8, 0.8), CF(r.X1 + 5, G + 4, z), C.Steel, Enum.Material.Metal)
	end
	for _, z in { cz - 8, cz + 8 } do
		Props.bench(f, Builder.facing(V3(cx - 10, G, z), V3(1, 0, 0)))
	end
	local panel = dec(f, "PanelSalidas", V3(0.2, 3, 8), CF(r.X0 + 0.4, G + 5, cz), rgb(20, 24, 32))
	Builder.sign(panel, "SALIDAS\nISLA DEL FARO · CADA RATO", Enum.NormalId.Right, rgb(250, 200, 60), rgb(20, 24, 32))
	-- Taquilla (con el aviso de la barca): bajo la marquesina, de cara al dique
	local kiosk = box(f, "Taquilla", V3(3, 3.6, 6), CF(r.X1 + 1.5, G + 1.8, cz + 6), C.White)
	dec(f, "TaquillaRotulo", V3(0.1, 1.2, 5.6), CF(r.X1 + 3.05, G + 3, cz + 6), C.Signal)
	local prompt = Builder.prompt(kiosk, "Ir a la Isla del Faro", "Barca", 0)
	prompt.MaxActivationDistance = 12
	prompt:AddTag("Ferry")
	prompt:SetAttribute("Target", islandTarget)
	-- Rampa (pasarela) del dique a la barca y el cartel
	local b = Plan.FerryBerth
	local ramp = box(darsena, "Rampa", V3(8, 0.6, 7), CF(436.5, G - 0.15, b.Z - 2) * CFrame.Angles(0, 0, math.rad(-2)), C.Steel, Enum.Material.DiamondPlate)
	for _, dz in { -3.4, 3.4 } do
		dec(darsena, "RampaBaranda", V3(8, 0.2, 0.2), ramp.CFrame * CF(0, 1.2, dz), C.Coping, Enum.Material.Metal)
	end
	K.sign(darsena, Builder.facing(V3(452, G, 3512), V3(0, 0, -1)), 9, 2.2, "⛴ BARCA A LA ISLA DEL FARO", C.Signal, 2.5)
	worker(m, "Marinero", V3(446, G, 3526), V3(-1, 0, 0))
end

---------------------------------------------------------------------
-- Agua: muelles, dársena, pantalanes, barcos, dique
---------------------------------------------------------------------

local function buildQuays(d: Instance): { Vector3 }
	local bollards: { Vector3 } = {}
	local q = Plan.Quays
	-- Bloques macizos de hormigón (muro vertical hasta el fondo)
	slab(d, "MuelleNorte", q.North, Plan.WallBottom, G, C.Concrete, Enum.Material.Concrete)
	slab(d, "MuelleOeste", q.West, Plan.WallBottom, G, C.Concrete, Enum.Material.Concrete)
	local east = { X0 = q.East.X0, X1 = q.East.X1, Z0 = q.East.Z0, Z1 = Plan.Breakwater.Z0 }
	slab(d, "MuelleEste", east, Plan.WallBottom, G, C.Concrete, Enum.Material.Concrete)
	-- Zócalo oscuro y húmedo en la línea del agua (el muro se ve mojado)
	local b = Plan.Basin
	dec(d, "MuroHumedo", V3(b.X1 - b.X0, 3, 0.2), CF((b.X0 + b.X1) / 2, SEA + 0.6, b.Z0 + 0.12), C.ConcreteDark, Enum.Material.Concrete)
	dec(d, "MuroHumedo", V3(0.2, 3, b.Z1 - b.Z0), CF(b.X0 + 0.12, SEA + 0.6, (b.Z0 + b.Z1) / 2), C.ConcreteDark, Enum.Material.Concrete)
	dec(d, "MuroHumedo", V3(0.2, 3, b.Z1 - b.Z0 + 26), CF(b.X1 - 0.12, SEA + 0.6, (b.Z0 + b.Z1 + 26) / 2), C.ConcreteDark, Enum.Material.Concrete)
	-- Bordes de seguridad (amarillo)
	dec(d, "Borde", V3(b.X1 - b.X0 + 30, 0.12, 0.8), CF((b.X0 + b.X1) / 2, G + 0.06, b.Z0 - 0.5), C.Coping)
	dec(d, "Borde", V3(0.8, 0.12, b.Z1 - b.Z0), CF(b.X0 - 0.5, G + 0.06, (b.Z0 + b.Z1) / 2), C.Coping)
	dec(d, "Borde", V3(0.8, 0.12, Plan.Breakwater.Z0 - b.Z0), CF(b.X1 + 0.5, G + 0.06, (b.Z0 + Plan.Breakwater.Z0) / 2), C.Coping)
	-- Bolardos en el borde de los muelles
	for x = 452, 872, 21 do
		local p = V3(x, G, b.Z0 - 2.2)
		K.bollard(d, p)
		table.insert(bollards, p)
	end
	for z = 3312, 3552, 24 do
		local p = V3(b.X0 - 2.2, G, z)
		K.bollard(d, p)
		table.insert(bollards, p)
		local p2 = V3(b.X1 + 2.2, G, z)
		K.bollard(d, p2)
		table.insert(bollards, p2)
	end
	K.bollard(d, V3(b.X1 + 2.2, G, 3576))
	-- Defensas de goma en el atraque del buque y neumáticos en los otros muros
	for x = 528, 752, 16 do
		K.fender(d, V3(x, G, b.Z0), V3(0, 0, 1), G)
	end
	for z = 3310, 3550, 20 do
		if math.abs(z - 3420) > 6 and math.abs(z - 3490) > 6 then
			K.tyre(d, V3(b.X0, SEA + 1.2, z), V3(1, 0, 0))
		end
		K.tyre(d, V3(b.X1, SEA + 1.2, z), V3(-1, 0, 0))
	end
	-- Atraque de la barca (cara oeste del dique oeste)
	for z = 3516, 3548, 8 do
		K.fender(d, V3(q.West.X0, G, z), V3(-1, 0, 0), G)
	end
	-- Escaleras para salir del agua
	for _, l in Plan.Ladders do
		K.ladder(d, V3(l[1] + l[3] * 0.1, 0, l[2] + l[4] * 0.1), G, SEA - 4)
	end
	-- Salvavidas
	for _, p in { { 466, 3335 }, { 466, 3470 }, { 854, 3420 }, { 760, 3296.5 } } do
		dec(d, "SalvavidasPoste", V3(0.3, 3.4, 0.3), CF(p[1], G + 1.7, p[2]), C.White)
		dec(d, "Salvavidas", V3(0.5, 2.2, 2.2), CF(p[1], G + 2.6, p[2] + 0.3) * CFrame.Angles(0, math.rad(90), 0), rgb(240, 100, 30), nil, { Shape = Enum.PartType.Cylinder })
	end
	return bollards
end

local function nearestBollard(list: { Vector3 }, p: Vector3): Vector3
	local best, bd = list[1], math.huge
	for _, b in list do
		local dd = (b - p).Magnitude
		if dd < bd then
			best, bd = b, dd
		end
	end
	return best
end

local function rope(d: Instance, from: Vector3, to: Vector3)
	-- Un poco de comba: dos tramos con el punto medio más bajo
	local m = (from + to) / 2 - V3(0, 0.8, 0)
	K.bar(d, "Cabo", from, m, 0.25, C.Rope, Enum.Material.Fabric)
	K.bar(d, "Cabo", m, to, 0.25, C.Rope, Enum.Material.Fabric)
end

local function buildBreakwater(d: Instance)
	local bw = Plan.Breakwater
	local cx, cz, w, dd = mid(bw)
	local dique = Builder.model("DiqueAbrigo", d)
	slab(dique, "Dique", bw, -16, Plan.BreakwaterTop, C.Concrete, Enum.Material.Concrete)
	box(dique, "Espaldon", V3(w, Plan.ParapetTop - Plan.BreakwaterTop, 3), CF(cx, (Plan.ParapetTop + Plan.BreakwaterTop) / 2, bw.Z1 - 1.5), C.ConcreteDark, Enum.Material.Concrete)
	-- Rampa del muelle este (Y = Ground) al dique (Y = BreakwaterTop)
	local east = Plan.Quays.East
	Builder.part({
		Name = "RampaDique",
		ClassName = "WedgePart",
		Size = V3(east.X1 - east.X0, Plan.BreakwaterTop - G, 10),
		CFrame = CF((east.X0 + east.X1) / 2, (G + Plan.BreakwaterTop) / 2, bw.Z0 - 5),
		Color = C.Concrete,
		Material = Enum.Material.Concrete,
		Parent = dique,
	})
	-- Escollera (talud de piedra) al sur y al este, con tetrápodos encima
	Builder.part({
		Name = "Escollera",
		ClassName = "WedgePart",
		Size = V3(w + 12, 16, 22),
		CFrame = CF(cx + 6, -8, bw.Z1 + 11) * CFrame.Angles(0, math.pi, 0),
		Color = C.Rock,
		Material = Enum.Material.Rock,
		Parent = dique,
	})
	local coastE = Plan.coastZ(east.X1 + 8)
	local lenE = bw.Z1 - coastE
	Builder.part({
		Name = "Escollera",
		ClassName = "WedgePart",
		Size = V3(lenE, 16, 14),
		CFrame = CF(east.X1 + 7, -8, coastE + lenE / 2) * CFrame.Angles(0, math.rad(-90), 0),
		Color = C.Rock,
		Material = Enum.Material.Rock,
		Parent = dique,
	})
	local tetra = Builder.model("Tetrapodos", dique)
	local k = 0
	for x = bw.X0 + 4, bw.X1 + 4, 9 do
		k += 1
		K.tetrapod(tetra, V3(x, 0.6 + (k % 2) * 0.8, bw.Z1 + 6 + (k % 2) * 4), 7, k * 1.7, (k % 3) * 0.25)
	end
	for z = coastE + 10, bw.Z1 - 4, 10 do
		k += 1
		K.tetrapod(tetra, V3(east.X1 + 6 + (k % 2) * 2, 0.4 + (k % 2) * 0.6, z), 7, k * 1.3, (k % 3) * 0.2)
	end
	-- Punta del dique: baliza verde (luz de noche)
	local p = Plan.Beacon
	local b = Builder.model("Baliza", dique)
	b:SetAttribute("PlaceName", "Baliza del dique")
	for i = 0, 3 do
		box(b, "Torre", V3(3, 2.4, 3), CF(p.X, p.Y + 1.2 + i * 2.4, p.Z) * CFrame.Angles(0, 0, math.rad(90)), if i % 2 == 0 then rgb(30, 150, 70) else C.White, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder })
	end
	dec(b, "Galeria", V3(4.4, 0.4, 4.4), CF(p.X, p.Y + 9.8, p.Z), C.Steel, Enum.Material.Metal)
	local lamp = dec(b, "Luz", V3(1.6, 1.6, 1.6), CF(p.X, p.Y + 11, p.Z), rgb(60, 230, 110), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball, Tags = { "StreetLamp" } })
	spotLight(lamp, 30, rgb(60, 230, 110))
	return dique
end

local function buildPontoons(d: Instance, bollards: { Vector3 })
	local top = Plan.FloatTop
	for _, pt in Plan.Pontoons do
		local pm = Builder.model(pt.Name, d)
		local len = pt.X1 - pt.X0
		local cx = (pt.X0 + pt.X1) / 2
		-- (el de pesca se llama «Pier»: CityAssets.harbour amarra ahí los pesqueros de la tienda)
		box(pm, if pt.Kind == "Pesca" then "Pier" else "Pantalan", V3(len - 8, 0.5, 4.6), CF(cx + 4, top - 0.25, pt.Z), C.Wood, Enum.Material.WoodPlanks)
		dec(pm, "Flotadores", V3(len - 8, 1, 4), CF(cx + 4, top - 1, pt.Z), C.Float, Enum.Material.Plastic)
		-- Pasarela del muelle (G) al pantalán (FloatTop)
		local a, b = V3(pt.X0, G - 0.2, pt.Z), V3(pt.X0 + 8.2, top - 0.2, pt.Z)
		local gang = K.bar(pm, "Pasarela", a, b, 1, C.Steel, Enum.Material.DiamondPlate, true)
		gang.Size = V3(3, 0.4, (b - a).Magnitude)
		for _, s in { -1.5, 1.5 } do
			K.bar(pm, "PasarelaBaranda", a + V3(0, 1.4, s), b + V3(0, 1.4, s), 0.2, C.Coping, Enum.Material.Metal)
		end
		for x = pt.X0 + 12, pt.X1 - 2, 16 do
			dec(pm, "Cornamusa", V3(1.2, 0.3, 0.4), CF(x, top + 0.15, pt.Z - 2), C.Steel, Enum.Material.Metal)
			dec(pm, "Cornamusa", V3(1.2, 0.3, 0.4), CF(x, top + 0.15, pt.Z + 2), C.Steel, Enum.Material.Metal)
		end
		if pt.Kind == "Recreo" then
			-- Fingers a los dos lados y veleros en algunos amarres
			local colors = { C.White, rgb(30, 50, 90), C.White, rgb(150, 30, 30) }
			local n = 0
			for x = pt.X0 + 16, pt.X1 - 6, 14 do
				for _, s in { -1, 1 } do
					dec(pm, "Finger", V3(1.6, 0.4, 10), CF(x, top - 0.2, pt.Z + s * 7.3), C.Wood, Enum.Material.WoodPlanks)
					n += 1
					if n % 2 == 1 then
						local face = Builder.facing(V3(x + 7, SEA, pt.Z + s * 13), V3(0, 0, -s))
						K.sailboat(pm, face, colors[(n // 2) % #colors + 1])
					end
				end
			end
		else
			-- Pesqueros abarloados por el lado norte, proa al este
			local colors = { rgb(30, 90, 160), rgb(180, 50, 40), rgb(30, 130, 100) }
			for i, x in { 500, 532, 564 } do
				local pos = V3(x, SEA, pt.Z - 2.3 - 4.6)
				K.fishingBoat(pm, Builder.facing(pos, V3(1, 0, 0)), colors[i], SEA)
				rope(pm, pos + V3(-8, 3, 4), V3(x - 8, top + 0.3, pt.Z - 2))
			end
			-- Amarre del barco de pesca (subir a bordo): en el muelle, al pie de la pasarela
			FishingKit.dock(d, Builder.facing(V3(pt.X0 - 8, G, pt.Z + 6), V3(1, 0, 0)))
		end
	end
	-- Dos pesqueros más junto al muelle pesquero (proa al norte)
	for i, z in { 3335, 3395 } do
		local pos = V3(Plan.Basin.X0 + 4.6, SEA, z)
		K.fishingBoat(d, CF(pos), if i == 1 then rgb(200, 150, 40) else rgb(40, 100, 150), SEA)
		rope(d, pos + V3(-2, 3, -10), nearestBollard(bollards, pos + V3(-6, 0, -10)) + V3(0, 1.4, 0))
		rope(d, pos + V3(-2, 3, 10), nearestBollard(bollards, pos + V3(-6, 0, 10)) + V3(0, 1.4, 0))
	end
end

local function buildShips(d: Instance, bollards: { Vector3 })
	local s = Plan.Ship
	local ship = K.ship(d, s, SEA)
	-- Amarras: largo de proa, esprines y largo de popa
	for _, sx in { s.X - s.Length / 2 + 14, s.X - 60, s.X + 60, s.X + s.Length / 2 - 8 } do
		local from = V3(sx, s.Deck + 0.6, s.Z - s.Beam / 2)
		local dx = if sx < s.X then -34 else 34
		if math.abs(sx - s.X) < 80 then
			dx = -dx * 0.6 -- (los esprines van cruzados)
		end
		local to = nearestBollard(bollards, V3(sx + dx, G, Plan.Basin.Z0 - 2.2))
		rope(ship, from, to + V3(0, 1.4, 0))
	end
	-- Remolcadores en el muelle este (proa al norte)
	for _, z in { 3392, 3436 } do
		local pos = V3(Plan.Basin.X1 - 6.5, SEA, z)
		K.tug(d, CF(pos))
		rope(d, pos + V3(5, 3, -8), nearestBollard(bollards, pos + V3(8, 0, -8)) + V3(0, 1.4, 0))
	end
	-- La barca de la Isla del Faro, en su atraque (proa al sur)
	local b = Plan.FerryBerth
	local ferry = K.ferry(d, Builder.facing(V3(b.X, SEA, b.Z), V3(0, 0, 1)))
	rope(ferry, V3(b.X + 6, 1, b.Z - 14), V3(Plan.Quays.West.X0 + 2, G + 1.4, b.Z - 16))
	rope(ferry, V3(b.X + 6, 1, b.Z + 14), V3(Plan.Quays.West.X0 + 2, G + 1.4, b.Z + 16))
end

local function buildFishing(d: Instance)
	-- Sitios de pesca: punta del dique oeste, muelle este y dique de abrigo (mirando al agua libre)
	local bt = Plan.BreakwaterTop
	local spots = {
		{ V3(448, G, 3557), V3(0, 0, 1) },
		{ V3(462, G, 3557), V3(0, 0, 1) },
		{ V3(852.5, G, 3475), V3(-1, 0, 0) },
		{ V3(852.5, G, 3505), V3(-1, 0, 0) },
		{ V3(852.5, G, 3535), V3(-1, 0, 0) },
		{ V3(740, bt, 3588), V3(0, 0, -1) },
		{ V3(770, bt, 3588), V3(0, 0, -1) },
		{ V3(830, bt, 3588), V3(0, 0, -1) },
	}
	for _, s in spots do
		FishingKit.spot(d, Builder.facing(s[1], s[2]), "Mar")
	end
	-- El sitio del pescador del puerto (NPC que pesca y lleva pescado al súper)
	local npcSpot = FishingKit.spot(d, Builder.facing(V3(800, bt, 3588), V3(0, 0, -1)), "Mar")
	npcSpot:SetAttribute("Npc", true)
	npcSpot:RemoveTag("FishingSpot")
	npcSpot:AddTag("FishingNpcSpot")
	-- Barco de pesca de alta mar (se sube desde el amarre del muelle pesquero)
	local fb = Plan.FishingBoat
	FishingKit.boat(d, CF(fb) * CFrame.Angles(0, 0, 0))
end

---------------------------------------------------------------------
-- Montaje
---------------------------------------------------------------------

-- islandTarget = adonde lleva la barca (el embarcadero de la Isla del Faro, Kit/Landmarks)
function Puerto.build(world: Instance, islandTarget: Vector3): (Model, Model)
	local m = Builder.model("Puerto", world)
	m:SetAttribute("PlaceName", "Puerto de Valmar")
	local d = Builder.model("PuertoDarsena", world)
	d:SetAttribute("PlaceName", "Dársena del Puerto de Valmar")
	-- Explanadas
	for i, r in Plan.Aprons do
		slab(m, "Explanada", r, G - 2, G, C.Apron, Enum.Material.Concrete).Name = "Explanada" .. i
	end
	-- Valla de la terminal de contenedores
	local fence = Builder.model("Valla", m)
	local g = Plan.Gate
	K.fence(fence, V3(g.X + 23, G, 3175), V3(758, G, 3175))
	K.fence(fence, V3(758, G, 3175), V3(758, G, 3204))
	K.fence(fence, V3(758, G, 3204), V3(772, G, 3204))
	K.fence(fence, V3(772, G, 3204), V3(772, G, 3287))
	K.fence(fence, V3(g.X - 23, G, 3176), V3(g.X - 23, G, 3287))
	buildGate(m)
	-- Naves (almacenes) y vía de carga
	K.nave(m, { X0 = 330, X1 = 462, Z0 = 3186, Z1 = 3226 }, G, 18, "S", "NAVE 1 · ALMACÉN GENERAL", rgb(200, 204, 206))
	K.nave(m, { X0 = 330, X1 = 432, Z0 = 3246, Z1 = 3282 }, G, 14, "N", "NAVE 2 · FRIGORÍFICO", rgb(220, 226, 230))
	buildRailSiding(m)
	buildYard(m)
	buildCranes(m)
	buildOffices(m)
	buildLonja(m)
	buildFerryHall(m, d, islandTarget)
	-- Torres de iluminación
	for _, p in { { 615, 3216 }, { 476, 3268 }, { 790, 3280 }, { 380, 3296 }, { 300 + 146, 3530 }, { 866, 3540 }, { 780, 3592 } } do
		local y = if p[2] > 3586 then Plan.BreakwaterTop else G
		K.mast(if p[1] > 440 and p[2] > 3300 then d else m, V3(p[1], y, p[2]), 40)
	end
	-- Cartel grande del puerto junto a la calle (de pie, mirando a la calle)
	K.sign(m, Builder.facing(V3(372, G, 3180), V3(0, 0, -1)), 26, 5, "PUERTO DE VALMAR", rgb(20, 70, 130), 3)
	K.sign(m, Builder.facing(V3(440, G, 3240), V3(0, 0, -1)), 12, 2.2, "← ESTACIÓN MARÍTIMA · LONJA", C.Signal, 3)
	-- Agua
	local bollards = buildQuays(d)
	buildPontoons(d, bollards)
	buildShips(d, bollards)
	buildBreakwater(d)
	buildFishing(d)
	return m, d
end

---------------------------------------------------------------------
-- Terreno (lo llama TerrainBuilder al arrancar)
---------------------------------------------------------------------

local function fill(terrain: Terrain, r: any, y0: number, y1: number, material: Enum.Material)
	local cx, cz, w, d = mid(r)
	terrain:FillBlock(CFrame.new(cx, (y0 + y1) / 2, cz), Vector3.new(w, y1 - y0, d), material)
end

function Puerto.terrain(terrain: Terrain)
	local b = Plan.Basin
	-- Dársena dragada: se vacía y se llena de agua hasta el nivel del mar
	fill(terrain, b, Plan.WallBottom - 4, 40, Enum.Material.Air)
	fill(terrain, b, Plan.WallBottom - 4, Plan.BasinFloor, Enum.Material.Mud)
	fill(terrain, b, Plan.BasinFloor, SEA, Enum.Material.Water)
	-- Bajo los muelles y el dique no queda agua ni arena (los ocupa el hormigón)
	for _, q in Plan.Quays do
		fill(terrain, q, Plan.WallBottom, 12, Enum.Material.Air)
	end
	fill(terrain, Plan.Breakwater, -16, 12, Enum.Material.Air)
end

return Puerto
