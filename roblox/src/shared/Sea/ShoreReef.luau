-- ShoreReef: la composición del fondo de TODAS las orillas y del mar poco y medio hondo de Valmar
-- (v126; el dueño en la v125.5: «el fondo marino está cutre, debes mejorarlo al 1000%»).
--
-- Antes (SeaBiome v124): en cada trozo de 14 studs, 0–9 cosas sueltas elegidas al azar de una lista por
-- zona, sobre un fondo de Salt plano a −14 (las orillas: hasta 60 studs de tierra no se tocaba nada).
-- Ahora el fondo se COMPONE por parcelas de 24 studs, con ruidos lentos que deciden qué hay en cada sitio:
--
--   Reef      racimo de arrecife: un afloramiento de roca DEL TERRENO (caliza, pizarra o basalto) con los
--             corales creciendo encima y alrededor (cerebro, cuerno, mesa, abanico, esponjas, coral
--             blando y a veces un pilar), un lecho de anémonas, una roca porosa al lado, praderas en el
--             borde y vida pequeña (estrellas, erizos, conchas, cangrejos)
--   Rubble    el borde del arrecife: cascajo de lajas y cantos pequeños, algún coral joven
--   Meadow    pradera densa de posidonia (7–12 matas) sobre arena con ondas, alguna alga ancha
--   Kelp      bosque de kelp gigante en el agua media (de 7 m para abajo), con praderas y cantos
--   Boulders  campo de rocas (cantos, rocas porosas y lajas de 1,5 a 5 studs) con erizos y esponjas
--   Sand      arena con ONDAS de arenisca (relieve del terreno) y vida pequeña suelta: los «canales»
--             de arena entre los parches, para que no sea todo igual
--
-- Dos salidas, del mismo plan (las mismas parcelas y ruidos, así los corales caen ENCIMA de las rocas):
--   ShoreReef.relief(ix, iz)  -> { Op }   el relieve del terreno (lo rellena World/ShoreReliefBuilder
--       en el servidor: afloramientos, repisas, ondas de arena y montículos; nunca a menos de 2,5 m de la
--       superficie, ni en puertos, islas, la Garganta, el Cañón de Dorada o Nácara)
--   ShoreReef.decor(ix, iz)   -> { Item } lo que se planta encima (Controllers/SeaBiome, en tu pantalla,
--       con las mallas del kit: ReplicatedStorage.MarMallas; el alto del fondo, por rayo)
-- Funciones puras (sin Instance): se prueban con Lune (scripts/test-mar.luau) y se vuelcan a JSON para
-- la vista previa de Blender (scripts/map/orillas-export.luau → scripts/map/orillas_preview.py).
--
--   Op   = { Shape = "Ball" | "Block", X, Y, Z, R? (bola), Size? {x, y, z} (bloque), Yaw?, Pitch?, Material }
--          (bloque: CFrame.new(X, Y, Z) * CFrame.Angles(0, Yaw, 0) * CFrame.Angles(Pitch, 0, 0))
--   Item = { Piece (nombre de MarKit), X, Z, H (alto en studs), Yaw, Tint ({r, g, b} o nil), Small (se
--            oculta antes: LOD), Sway (se mece), Lift (studs por encima del fondo: sobre una roca de malla) }

local Shared = game:GetService("ReplicatedStorage").Shared
local Ocean = require(Shared.Sea.Ocean)
local ReefZone = require(Shared.Sea.ReefZone)
local Nacara = require(Shared.Sea.Nacara)
local Civ = require(Shared.Sea.Civ) -- (Nácara fase 1: barrios, farolas, tablones, la persecución y la posada)

local ShoreReef = {}
ShoreReef.V4 = Ocean.V4 == true -- (el mar v4, docs/mar/v4-objetivo.md: burbuja de densidad, corales gigantes e hitos)

ShoreReef.Cell = 24
ShoreReef.MaxD = 820 -- hasta el final del talud (más lejos y más hondo manda SeaBiome con sus zonas)
ShoreReef.MinD = 6 -- (los primeros studs junto a la arena de la playa, nada)
ShoreReef.Ceiling = Ocean.Surface - 9 -- el relieve nunca sube más (2,5 m de agua como poco: se nada encima)
ShoreReef.NacaraRing = 460 -- alrededor de Nácara (studs desde su centro) también se compone el fondo
ShoreReef.KelpBelow = Ocean.Surface - 24
ShoreReef.BankWidth = 34 -- el talud de arena de la orilla: de la tierra (−1,5) al fondo (−14) en ~30 studs -- kelp solo con 6–7 m de agua o más
-- LOD (Controllers/SeaBiome): lo pequeño (vida, matas) se quita antes, luego lo mediano (< 2,5 studs) y lo
-- grande (rocas, corales grandes, kelp) llega hasta Radius: así de lejos se ven siluetas en la bruma
ShoreReef.SmallDistance = { Mobile = 48, Desktop = 72 }
ShoreReef.MidDistance = { Mobile = 68, Desktop = 110 }
ShoreReef.MidHeight = 2.5
ShoreReef.Radius = { Mobile = 120, Desktop = 170 }
ShoreReef.Density = { Mobile = 0.7, Desktop = 1 } -- (el móvil planta un 30 % menos en cada parcela)

local floor, abs, sqrt, min, max, pi = math.floor, math.abs, math.sqrt, math.min, math.max, math.pi
local noise = Ocean.noise

local function hash(a: number, b: number, c: number): number
	local v = math.sin(a * 127.1 + b * 311.7 + c * 74.7) * 43758.5453
	return v - floor(v)
end
ShoreReef.hash = hash

-- Paletas (como el Cañón de Dorada: shared/Sea/ReefZone.Palette). Corales: cálidos con poca agua, fríos y
-- morados más abajo; las mesas, pardas y verdosas (azul puro parecía un disco de plástico: captura v124)
local P = ReefZone.Palette
local TABLE_TINT = { { 150, 130, 92 }, { 120, 140, 96 }, { 168, 120, 96 }, { 132, 116, 140 } }
local SPONGE_TINT = { { 230, 160, 70 }, { 176, 82, 160 }, { 214, 96, 70 }, { 240, 200, 90 } }
-- (el cuerno de ciervo morado y grande parecía una mano: tonos de coral de verdad, ocres y naranjas)
local STAG_TINT = { { 214, 150, 88 }, { 236, 176, 96 }, { 196, 120, 84 }, { 230, 140, 110 } }
-- (ronda 3: con la paleta fría pura, los cerebros del borde parecían piedras azules: tonos de coral de
-- agua más honda, apagados —verdes, pardos, malvas—, y los abanicos en rojo y violeta)
local LEDGE_TINT = { { 128, 150, 110 }, { 170, 140, 110 }, { 150, 120, 160 }, { 196, 170, 140 }, { 120, 140, 150 } }
local FAN_TINT = { { 176, 64, 120 }, { 150, 70, 170 }, { 200, 90, 80 } }
local ANEMONE_TINT = { { 250, 170, 200 }, { 255, 200, 150 }, { 190, 230, 210 }, { 240, 150, 220 } }

local function pick(list: { any }, r: number): any
	return list[1 + floor(r * #list) % #list]
end

---------------------------------------------------------------------
-- Qué hay en cada parcela
---------------------------------------------------------------------
export type Plan = { Kind: string?, X: number, Z: number, Floor: number?, D: number, Zone: string?, Keep: number, Bank: boolean }

local excluded: ((number, number) -> boolean)? = nil
-- (las pruebas pueden quitar Nácara y el Cañón)
function ShoreReef.setExcluded(fn: ((number, number) -> boolean)?)
	excluded = fn
end
-- Lo de la ciudad de Nácara que no se pisa (coordenadas de la plaza): los barrios, las farolas, los tablones,
-- los sitios de la historia y el camino de la persecución de «Redes cortadas»; y la posada de La Burbuja.
-- margin: studs de más (el relieve del terreno, que choca, deja más sitio que el decorado)
local chasePts: { { number } } = {}
do
	local P = Civ.Chase.Path
	for i = 1, #P - 1 do
		for t = 0, 1, 0.125 do
			table.insert(chasePts, { P[i][1] + (P[i + 1][1] - P[i][1]) * t, P[i][2] + (P[i + 1][2] - P[i][2]) * t })
		end
	end
end
function ShoreReef.cityBlocked(x: number, z: number, margin: number): boolean
	local px, pz = x - Nacara.Center.X, z - Nacara.Center.Z
	if px * px + pz * pz < (Civ.Districts[1].R + 40) ^ 2 then
		for _, a in Civ.Areas do
			if (px - a.X) ^ 2 + (pz - a.Z) ^ 2 < (a.R + 6 + margin) ^ 2 then
				return true
			end
		end
		for _, list in { Civ.Lamps, Civ.Beds } do
			for _, l in list do
				if (px - l.X) ^ 2 + (pz - l.Z) ^ 2 < (5 + margin) ^ 2 then
					return true
				end
			end
		end
		for _, b in Civ.Boards do
			if (px - b.X) ^ 2 + (pz - b.Z) ^ 2 < (8 + margin) ^ 2 then
				return true
			end
		end
		for _, sp in Civ.StorySpots do
			if not sp.World and (px - sp.X) ^ 2 + (pz - sp.Z) ^ 2 < (sp.Radius * 0.7 + margin) ^ 2 then
				return true
			end
		end
		for _, c in chasePts do
			if (px - c[1]) ^ 2 + (pz - c[2]) ^ 2 < (4 + margin) ^ 2 then
				return true
			end
		end
	end
	local pos = Civ.Posada
	return (x - pos.X) ^ 2 + (z - pos.Z) ^ 2 < (pos.Radius + 14 + margin) ^ 2
end

local function skip(x: number, z: number): boolean
	if excluded then
		return excluded(x, z)
	end
	return ReefZone.contains(x, z) or Nacara.covers(x, z) or ShoreReef.cityBlocked(x, z, 0)
end

function ShoreReef.plan(ix: number, iz: number): Plan
	local C = ShoreReef.Cell
	local x, z = (ix + 0.5) * C, (iz + 0.5) * C
	local s = Ocean.sample(x, z)
	local out: Plan = { Kind = nil, X = x, Z = z, Floor = s.Floor, D = s.D, Zone = s.Zone, Keep = s.Keep, Bank = false }
	-- La orilla: la arena de la isla acababa en una PARED de 13 studs (TerrainBuilder: tierra hasta −1, mar a
	-- −14). Un talud de arena la suaviza (relief: «Bank»), salvo en puertos e islas
	if s.Floor and s.D > 0 and s.D < ShoreReef.BankWidth and s.Keep < 0.15 and not s.Corridor and not skip(x, z) then
		out.Bank = true
	end
	-- (la llegada a Nácara, en la Llanura Sumergida, también: plano 5 de docs/mar/v3-objetivo.md)
	local nacaraD = sqrt((x - Nacara.Center.X) ^ 2 + (z - Nacara.Center.Z) ^ 2)
	local nearNacara = nacaraD < ShoreReef.NacaraRing and nacaraD > Nacara.Clear + 6
	if not s.Floor or s.D < ShoreReef.MinD or (s.D > ShoreReef.MaxD and not nearNacara) or s.Keep > 0.25 or s.Corridor or s.Floor < -150 then
		return out
	end
	if s.Zone == "Abismo" or s.Zone == "Sima" or s.Zone == "Garganta" or s.Zone == "Catedrales" or s.Zone == "Canon" then
		return out
	end
	if skip(x, z) then
		return out
	end
	local shelf = s.D < 360
	-- Los sitios de arrecife con nombre (Jardín Escarlata, Arco de Coral, los jardines de las playas): siempre
	-- arrecife cerca de su centro
	for _, poi in Ocean.Pois do
		if poi.Zone == "Arrecife" and (x - poi.X) ^ 2 + (z - poi.Z) ^ 2 < (poi.Radius * 0.9) ^ 2 then
			out.Kind = "Reef"
			return out
		end
	end
	for i = 1, Ocean.ShoreReefNamed do
		local r = Ocean.ShoreReefs[i]
		if (x - r.X) ^ 2 + (z - r.Z) ^ 2 < (r.R * 0.6) ^ 2 then
			out.Kind = "Reef"
			return out
		end
	end
	local reefN = noise(x, z, 70, 301)
	-- (ronda 2: más arrecife en la plataforma —el fondo de las vistas previas seguía casi vacío—)
	local reefLine = if s.Zone == "Coral" or s.Zone == "Arrecife" then 0.42 elseif shelf then 0.52 elseif nearNacara then 0.55 else 0.66
	local meadowN = noise(x, z, 90, 302)
	local kelpN = noise(x, z, 120, 303)
	local rockN = noise(x, z, 55, 304)
	local kind: string
	-- Nácara (docs/mar/v3-objetivo.md, plano 5; la ciudad es una civilización, no una plaza en la arena):
	-- jardines de coral densos alrededor de los barrios y, más lejos, un anillo de peñascos con agujas de
	-- roca —el «zócalo» de la ciudad— que hace de silueta al llegar
	if nearNacara then
		if nacaraD > 235 and nacaraD < 330 and rockN > 0.38 then
			out.Kind = "Rim"
			return out
		end
		if nacaraD < 180 and reefN > 0.3 then
			out.Kind = "Reef"
			return out
		end
	end
	-- (el borde de la plataforma —ShelfEnd, ~13 m—: murete de roca y caída; plano 3 de docs/mar/v3-objetivo.md)
	-- (justo antes del escalón de Ocean.LedgeDrop: el murete queda en el filo)
	local edge = s.D - 360
	if edge > -30 and edge < 2 and rockN > 0.32 then
		out.Kind = "Ledge"
		return out
	end
	if reefN > reefLine then
		kind = "Reef"
	elseif reefN > reefLine - 0.07 then
		kind = "Rubble"
	elseif s.Floor < ShoreReef.KelpBelow and (s.Zone == "Kelp" or kelpN > (if nearNacara then 0.5 else 0.64)) then
		kind = "Kelp"
	elseif rockN > (if shelf then 0.7 else 0.6) then
		kind = "Boulders"
	elseif shelf and meadowN > (if s.D < 140 then 0.42 else 0.52) and s.Floor > -60 then
		kind = "Meadow"
	else
		kind = "Sand"
	end
	out.Kind = kind
	return out
end

---------------------------------------------------------------------
-- Relieve del terreno (servidor)
---------------------------------------------------------------------
export type Op = { Shape: string, X: number, Y: number, Z: number, R: number?, Size: { number }?, Yaw: number?, Pitch: number?, Material: string }

local ROCKS = { "Limestone", "Slate", "Basalt", "Rock" }
-- (ronda 1 de la vista previa: el basalto azul oscuro en lo poco hondo eran manchas negras. Arriba, caliza y roca)
local ROCKS_SHALLOW = { "Limestone", "Limestone", "Rock", "Limestone" } -- (ronda 3: la roca oscura bajo los corales parecía una sombra)

-- Lo que puede subir una bola de radio r con el centro a cy: su cima, nunca por encima del techo
local function capBall(floorY: number, r: number, rise: number): (number, number)
	local top = min(floorY + rise, ShoreReef.Ceiling)
	local room = top - floorY
	if room <= 0.4 then
		return floorY - r, 0
	end
	return top - r, room
end

-- La dirección hacia el mar (del gradiente de la distancia a tierra)
local function seaward(x: number, z: number): (number, number)
	local e = 6
	local gx = Ocean.landDistance(x + e, z) - Ocean.landDistance(x - e, z)
	local gz = Ocean.landDistance(x, z + e) - Ocean.landDistance(x, z - e)
	local m = sqrt(gx * gx + gz * gz)
	if m < 1e-6 then
		return 0, 1
	end
	return gx / m, gz / m
end
ShoreReef.seaward = seaward

-- (memo opcional: la vista previa y las pruebas piden la misma parcela muchas veces)
ShoreReef.Memo = nil :: { [string]: { Op } }?
function ShoreReef.relief(ix: number, iz: number, plan: Plan?): { Op }
	local memo = ShoreReef.Memo
	if memo then
		local key = ix .. "," .. iz
		local got = memo[key]
		if not got then
			ShoreReef.Memo = nil
			got = ShoreReef.relief(ix, iz, plan)
			ShoreReef.Memo = memo
			memo[key] = got
		end
		return got
	end
	local p = plan or ShoreReef.plan(ix, iz)
	local ops: { Op } = {}
	if p.Bank and p.Floor then
		local nx, nz = seaward(p.X, p.Z)
		local cx, cz = p.X - nx * p.D, p.Z - nz * p.D -- el punto de la orilla
		local fy = p.Floor :: number
		local run = ShoreReef.BankWidth - 4
		local drop = (-1.5) - fy
		if drop > 1 then
			local a = math.atan2(drop, run)
			local thick = 6
			local tx, tz, ty = cx + nx * run / 2, cz + nz * run / 2, -1.5 - drop / 2
			local sa, ca = math.sin(a), math.cos(a)
			table.insert(ops, {
				Shape = "Block",
				X = tx - nx * sa * thick / 2,
				Y = ty - ca * thick / 2,
				Z = tz - nz * sa * thick / 2,
				Size = { ShoreReef.Cell * 1.4, thick, run / ca + 4 },
				Yaw = math.atan2(nx, nz),
				Pitch = a,
				Material = "Salt",
			})
		end
	end
	if not p.Kind or not p.Floor then
		return ops
	end
	ShoreReef.reliefKind(ops, ix, iz, p)
	if ShoreReef.V4 then
		ShoreReef.landmarkRelief(ops, ix, iz)
	end
	-- (nada encima de los cofres de los sitios: el del Arco de Coral queda en la arena, a la vista)
	for i = #ops, 1, -1 do
		local op = ops[i]
		-- (lo que se sale de la parcela hacia el Cañón de Dorada o la plaza de Nácara, fuera)
		if skip(op.X, op.Z) or (excluded == nil and ShoreReef.cityBlocked(op.X, op.Z, (op.R or 6) + 6)) then
			table.remove(ops, i)
			continue
		end
		for _, poi in Ocean.Pois do
			if poi.Chest and (op.X - poi.X) ^ 2 + (op.Z - poi.Z) ^ 2 < (10 + (op.R or 6)) ^ 2 then
				table.remove(ops, i)
				break
			end
		end
	end
	return ops
end

function ShoreReef.reliefKind(ops: { Op }, ix: number, iz: number, p: Plan)
	local C = ShoreReef.Cell
	local fy = p.Floor :: number
	local h1, h2, h3 = hash(ix, iz, 11), hash(ix, iz, 12), hash(ix, iz, 13)
	local deep = fy < -60
	if p.Kind == "Reef" then
		-- Afloramiento: una bola grande medio enterrada y una repisa al lado (los corales crecen encima)
		-- (ronda 2: más grande y alto, para que el arrecife tenga volumen; los corales lo cubren)
		local r = 6 + h1 * 3
		local mat = pick(if fy > -60 then ROCKS_SHALLOW else ROCKS, hash(floor(ix / 3), floor(iz / 3), 14)) -- (por manchas)
		local cy, room = capBall(fy, r, 2.4 + h2 * 3)
		if room > 0 then
			table.insert(ops, { Shape = "Ball", X = p.X + (h3 - 0.5) * 6, Y = cy, Z = p.Z + (h1 - 0.5) * 6, R = r, Material = mat })
		end
		local r2 = 2.6 + h3 * 1.6
		local cy2, room2 = capBall(fy, r2, 1 + h1 * 1.2)
		if room2 > 0 then
			local a = h2 * pi * 2
			table.insert(ops, { Shape = "Ball", X = p.X + math.cos(a) * 7, Y = cy2, Z = p.Z + math.sin(a) * 7, R = r2, Material = if h3 > 0.5 then "Limestone" else mat })
		end
	elseif p.Kind == "Rim" then
		-- Peñascos grandes (basalto y pizarra) del anillo de Nácara: hasta 10 studs (la ciudad está a 37 m)
		for k = 1, 2 do
			local r = 8 + hash(ix, iz, 80 + k) * 5
			local cy, room = capBall(fy, r, 5 + hash(ix, iz, 82 + k) * 5)
			if room > 0 then
				-- (ronda 5: el basalto, casi negro, eran manchas oscuras enormes delante de la ciudad: pizarra y roca)
				table.insert(ops, { Shape = "Ball", X = p.X + (hash(ix, iz, 84 + k) - 0.5) * 12, Y = cy, Z = p.Z + (hash(ix, iz, 86 + k) - 0.5) * 12, R = r, Material = if k == 1 then "Slate" else "Rock" })
			end
		end
	elseif p.Kind == "Ledge" then
		-- El borde de la plataforma: un murete de roca (2–3 bolas grandes en fila a lo largo de la costa) que
		-- deja ver la caída hacia el azul; por detrás, una repisa más baja
		local nx, nz = seaward(p.X, p.Z)
		local tx, tz = -nz, nx
		-- (ronda 2: caliza clara y pizarra oscura juntas parecían un mosaico de papel: roca y pizarra, de tono parecido)
		for k = -1, 1 do
			local r = 6 + hash(ix, iz, 70 + k) * 3
			local cy, room = capBall(fy, r, 3.5 + hash(ix, iz, 71 + k) * 3)
			if room > 0 then
				table.insert(ops, { Shape = "Ball", X = p.X + tx * k * 8 + nx * 4, Y = cy, Z = p.Z + tz * k * 8 + nz * 4, R = r, Material = if k == 0 then "Slate" else "Rock" })
			end
		end
		local r = 5 + h2 * 2
		local cy, room = capBall(fy, r, 1.4)
		if room > 0 then
			table.insert(ops, { Shape = "Ball", X = p.X - nx * 9, Y = cy, Z = p.Z - nz * 9, R = r, Material = "Rock" })
		end
	elseif p.Kind == "Boulders" then
		for k = 1, 1 + floor(h1 * 2) do
			local r = 2 + hash(ix, iz, 20 + k) * 2
			local cy, room = capBall(fy, r, 0.8 + hash(ix, iz, 30 + k) * 1.6)
			if room > 0 then
				table.insert(ops, { Shape = "Ball", X = p.X + (hash(ix, iz, 40 + k) - 0.5) * 16, Y = cy, Z = p.Z + (hash(ix, iz, 50 + k) - 0.5) * 16, R = r, Material = if deep then "Basalt" else pick(ROCKS, hash(ix, iz, 60 + k)) })
			end
		end
	elseif p.Kind == "Rubble" then
		local r = 2.2 + h1 * 1.2
		local cy, room = capBall(fy, r, 0.6 + h2)
		if room > 0 then
			table.insert(ops, { Shape = "Ball", X = p.X + (h3 - 0.5) * 10, Y = cy, Z = p.Z + (h2 - 0.5) * 10, R = r, Material = "Limestone" })
		end
	elseif p.Kind == "Sand" or p.Kind == "Meadow" then
		-- Ondas: dos crestas bajas de arenisca, paralelas, con el rumbo del ruido (como las de la corriente)
		if h1 > 0.35 and fy + 1 <= ShoreReef.Ceiling then
			local yaw = noise(p.X, p.Z, 300, 305) * pi
			for k = -1, 1, 2 do
				local off = k * (4 + h2 * 3)
				table.insert(ops, {
					Shape = "Block",
					X = p.X + math.cos(yaw + pi / 2) * off,
					Y = fy - 0.6,
					Z = p.Z + math.sin(yaw + pi / 2) * off,
					Size = { C * 0.9, 2.2, 3 },
					Yaw = yaw,
					-- (del MISMO material que el fondo: la onda la da la forma. En arenisca, las tiras de otro color
					-- parecían tablones en la vista previa —ronda 1—)
					Material = "Salt",
				})
			end
		end
		-- y dunas: lomas anchas y bajas (radio 14–22, 1,5–3,5 studs) con el ruido lento, para que la arena
		-- ondule de lejos (ronda 1: «un plano liso y vacío» en el medio de todas las vistas)
		local dune = noise(p.X, p.Z, 140, 306)
		if dune > 0.5 and h3 > 0.35 then
			local r = 14 + h2 * 8
			local cy, room = capBall(fy, r, 1.5 + (dune - 0.5) * 4)
			if room > 0 then
				table.insert(ops, { Shape = "Ball", X = p.X + (h1 - 0.5) * 10, Y = cy, Z = p.Z + (h2 - 0.5) * 10, R = r, Material = "Salt" })
			end
		end
	elseif p.Kind == "Kelp" then
		-- (v127.1: en un servidor de verdad el Laberinto de Kelp salía plano —0,0 studs en 40×40—: en cada
		-- parcela, una roca de pizarra donde se agarra el kelp, y en la mitad, una loma baja de arena)
		local r = 2.6 + h1 * 2
		local cy, room = capBall(fy, r, 1.4 + h3 * 1.6)
		if room > 0 then
			table.insert(ops, { Shape = "Ball", X = p.X + (h1 - 0.5) * 12, Y = cy, Z = p.Z + (h3 - 0.5) * 12, R = r, Material = if h2 > 0.3 then "Slate" else "Rock" })
		end
		if h2 > 0.5 then
			local rd = 9 + h3 * 5
			local cyd, roomd = capBall(fy, rd, 1.6 + h1 * 1.4)
			if roomd > 0 then
				table.insert(ops, { Shape = "Ball", X = p.X - (h1 - 0.5) * 10, Y = cyd, Z = p.Z - (h3 - 0.5) * 10, R = rd, Material = "Salt" })
			end
		end
		if deep and h3 > 0.72 then
			table.insert(ops, { Shape = "Ball", X = p.X, Y = fy - 3.2, Z = p.Z, R = 4, Material = "Mud" })
		end
	end
end

-- La cima de un bloque (girado con Yaw y Pitch, como CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0))
-- encima de (x, z), o nil si (x, z) cae fuera
function ShoreReef.blockTop(op: Op, x: number, z: number): number?
	local s = op.Size :: { number }
	local yaw, pitch = op.Yaw or 0, op.Pitch or 0
	local sy, cy = math.sin(yaw), math.cos(yaw)
	local sp, cp = math.sin(pitch), math.cos(pitch)
	-- ejes del bloque en el mundo: X = (cy, 0, -sy), Z = (sy*cp, -sp, cy*cp), Y = (sy*sp, cp, cy*sp)
	local nx, ny, nz = sy * sp, cp, cy * sp
	local tx, ty, tz = op.X + nx * s[2] / 2, op.Y + ny * s[2] / 2, op.Z + nz * s[2] / 2
	local dx, dz = x - tx, z - tz
	local lx = dx * cy - dz * sy
	local lz = (dx * sy + dz * cy) / math.max(cp, 0.2)
	if abs(lx) > s[1] / 2 or abs(lz) > s[3] / 2 then
		return nil
	end
	return ty - (nx * dx + nz * dz) / ny
end

-- La altura del relieve en un punto y el material de lo que queda arriba (para la vista previa y las
-- pruebas: con las bolas y bloques de esta parcela y de las de al lado; baseMaterial: el del fondo)
function ShoreReef.surfaceAt(x: number, z: number, floorY: number, baseMaterial: string?): (number, string)
	local C = ShoreReef.Cell
	local ix, iz = floor(x / C), floor(z / C)
	local y, mat = floorY, baseMaterial or "Salt"
	for dx = -1, 1 do
		for dz = -1, 1 do
			for _, op in ShoreReef.relief(ix + dx, iz + dz) do
				local top: number? = nil
				if op.Shape == "Ball" then
					local d2 = (x - op.X) ^ 2 + (z - op.Z) ^ 2
					local r = op.R :: number
					if d2 < r * r then
						top = op.Y + sqrt(r * r - d2)
					end
				else
					top = ShoreReef.blockTop(op, x, z)
				end
				if top and top > y then
					y, mat = top, op.Material
				end
			end
		end
	end
	return y, mat
end

function ShoreReef.heightAt(x: number, z: number, floorY: number): number
	return (ShoreReef.surfaceAt(x, z, floorY))
end

---------------------------------------------------------------------
-- Lo que se planta encima (cliente)
---------------------------------------------------------------------
export type Item = { Piece: string, X: number, Z: number, H: number, Yaw: number, Tint: { number }?, Small: boolean, Sway: boolean, Lift: number }

local MarKitTint = { CoralCerebro = true, CoralCuerno = true, CoralMesa = true, CoralBlando = true, CoralPilar = true, Abanico = true }
local SWAY = { Pradera = true, AlgaAncha = true, KelpGigante = true, Abanico = true, CoralBlando = true, AnemonaLuz = true }
-- (ronda 3: la pradera ya no cuenta como «pequeña»: con LOD de 48 studs, la arena del plano medio se veía vacía)
local SMALL = { Estrella = true, Concha = true, Erizo = true, Cangrejo = true, AnemonaLuz = true }

local function coralTint(fy: number, r: number): { number }
	-- (ronda 3: el arrecife a 10 m salía casi todo morado y cian; los cálidos, hasta ~17 m)
	local deep = fy < -60
	return pick(if deep then P.Cool else (if r > 0.75 then P.Cool else P.Warm), r)
end

function ShoreReef.decor(ix: number, iz: number, density: number?, plan: Plan?): { Item }
	local p = plan or ShoreReef.plan(ix, iz)
	local items: { Item } = {}
	if not p.Kind or not p.Floor then
		return items
	end
	local C = ShoreReef.Cell
	local fy = p.Floor :: number
	local k = density or 1
	local n = 0
	local function put(piece: string, x: number, z: number, h: number, tint: { number }?, lift: number?)
		if excluded == nil and ShoreReef.cityBlocked(x, z, 0) then
			return
		end
		n += 1
		table.insert(items, {
			Piece = piece,
			X = x,
			Z = z,
			H = h,
			Yaw = hash(x, z, 90) * pi * 2,
			Tint = tint,
			Small = SMALL[piece] == true,
			Sway = SWAY[piece] == true,
			Lift = lift or 0,
		})
	end
	-- un punto de la parcela (u, v en 0..1 alrededor de su centro, con radio rad)
	local function at(seed: number, rad: number, cx: number?, cz: number?): (number, number)
		local a = hash(ix, iz, seed) * pi * 2
		local d = sqrt(hash(iz, ix, seed + 0.5)) * rad
		return (cx or p.X) + math.cos(a) * d, (cz or p.Z) + math.sin(a) * d
	end
	local function count(lo: number, hi: number, seed: number): number
		return floor((lo + hash(ix, iz, seed) * (hi - lo + 1)) * k + 0.5)
	end
	local function life(seed: number, howMany: number)
		-- (la concha blanca de la malla, sola en la arena, parecía un cubo blanco: ronda 1. Menos conchas)
		local kinds = { "Estrella", "Erizo", "Cangrejo", "Estrella", "Erizo", "Concha" }
		for i = 1, howMany do
			local x, z = at(seed + i * 3, C * 0.48)
			local kind = pick(kinds, hash(x, z, seed))
			put(kind, x, z, if kind == "Cangrejo" then 0.8 elseif kind == "Erizo" then 0.7 elseif kind == "Concha" then 0.3 else 0.25)
		end
	end
	if p.Kind == "Reef" then
		-- el centro del afloramiento del terreno (el mismo hash que relief)
		local h1, h3 = hash(ix, iz, 11), hash(ix, iz, 13)
		local ox, oz = p.X + (h3 - 0.5) * 6, p.Z + (h1 - 0.5) * 6
		-- (ronda 4: el cuerno de ciervo grande y de cerca parece una mano: menos y más pequeño)
		local species = { "CoralCerebro", "CoralCuerno", "CoralMesa", "Abanico", "Esponjas", "CoralBlando", "CoralCerebro", "CoralMesa", "CoralBlando" }
		for i = 1, count(9, 14, 100) do
			local x, z = at(100 + i * 7, 8.5, ox, oz)
			local r = hash(x, z, 101)
			local sp = pick(species, hash(x, z, 102))
			-- (de lejos a cerca del centro del afloramiento: los grandes en medio, los pequeños en el borde)
			local edge = sqrt((x - ox) ^ 2 + (z - oz) ^ 2) / 8
			local big = 1.3 - edge * 0.55
			local h = (if sp == "CoralMesa" then 1.6 + r * 1.4 elseif sp == "Abanico" then 3.2 + r * 2.6 elseif sp == "Esponjas" then 1.4 + r * 1.6 else 2.2 + r * 2.6) * big
			-- (ronda 2: un coral cerebro de 8 studs era un globo morado: tope por especie)
			h = math.min(h, if sp == "CoralCerebro" then 3.2 elseif sp == "CoralBlando" then 3.6 elseif sp == "CoralCuerno" then 3 else 6)
			local tint = if sp == "CoralMesa" then pick(TABLE_TINT, r) elseif sp == "Esponjas" then pick(SPONGE_TINT, r) elseif sp == "CoralCuerno" then pick(STAG_TINT, r) else coralTint(fy, r)
			put(sp, x, z, h, tint)
		end
		if hash(ix, iz, 103) > 0.82 then
			local x, z = at(104, 4, ox, oz)
			put("CoralPilar", x, z, 3 + hash(x, z, 105) * 3, coralTint(fy, hash(x, z, 106)))
		end
		-- lecho de anémonas
		local bx, bz = at(110, 9)
		for i = 1, count(3, 5, 111) do
			local x, z = at(112 + i, 2.2, bx, bz)
			put("AnemonaLuz", x, z, 1 + hash(x, z, 113) * 0.8, pick(ANEMONE_TINT, hash(x, z, 114)))
		end
		-- setas de luz entre los corales (de día, de color; de noche brillan: plano 6 —ronda 2: casi nada brillaba—)
		for i = 1, count(1, 2, 115) do
			local x, z = at(116 + i * 3, 7, ox, oz)
			put("SetaLuz", x, z, 1 + hash(x, z, 117) * 1.2, pick(ANEMONE_TINT, hash(x, z, 118)))
		end
		-- roca porosa de malla al lado, con un coral encima
		do
			local x, z = at(120, 10)
			local h = 1.6 + hash(x, z, 121) * 2
			put("RocaPorosa", x, z, h, nil)
			put("CoralCerebro", x, z, 0.9 + hash(x, z, 122) * 0.8, coralTint(fy, hash(x, z, 123)), h * 0.8)
		end
		for i = 1, count(2, 4, 130) do
			local x, z = at(131 + i * 5, C * 0.5)
			put("Pradera", x, z, 1.6 + hash(x, z, 132) * 1.6, pick(P.Grass, hash(x, z, 133)))
		end
		life(140, count(1, 3, 141))
	elseif p.Kind == "Rubble" then
		for i = 1, count(2, 4, 200) do
			local x, z = at(201 + i * 3, C * 0.45)
			-- (sin lajas en lo poco hondo: oscuras y planas, de lejos parecían losas —capturas del dueño, ronda 1—)
			put(if hash(x, z, 202) > 0.5 then "RocaPorosa" else "Canto", x, z, 0.6 + hash(x, z, 203) * 1.0, nil)
		end
		if hash(ix, iz, 204) > 0.4 then
			local x, z = at(205, C * 0.4)
			put(if hash(x, z, 206) > 0.5 then "CoralCerebro" else "CoralCuerno", x, z, 0.9 + hash(x, z, 207) * 0.9, coralTint(fy, hash(x, z, 208)))
		end
		life(210, count(0, 2, 211))
	elseif p.Kind == "Meadow" then
		for i = 1, count(7, 12, 300) do
			local x, z = at(301 + i * 2, C * 0.55)
			put("Pradera", x, z, 1.8 + hash(x, z, 302) * 2.2, pick(P.Grass, hash(x, z, 303)))
		end
		if hash(ix, iz, 304) > 0.6 then
			local x, z = at(305, C * 0.4)
			put("AlgaAncha", x, z, 2.6 + hash(x, z, 306) * 1.6, pick(P.Kelp, hash(x, z, 307)))
		end
		life(310, count(0, 1, 311))
	elseif p.Kind == "Kelp" then
		local water = Ocean.Surface - 2 - fy
		for i = 1, count(2, 3, 400) do
			local x, z = at(401 + i * 4, C * 0.45)
			put("KelpGigante", x, z, math.clamp(water * (0.55 + hash(x, z, 402) * 0.35), 10, 34), pick(P.Kelp, hash(x, z, 403)))
		end
		-- (ronda 1: entre los tallos el suelo estaba vacío: praderas bajas y cantos)
		for i = 1, count(3, 6, 410) do
			local x, z = at(411 + i * 2, C * 0.5)
			put("Pradera", x, z, 1.6 + hash(x, z, 412) * 1.4, pick(P.Grass, hash(x, z, 413)))
		end
		if hash(ix, iz, 417) > 0.45 then
			local x, z = at(418, C * 0.45)
			put("AlgaAncha", x, z, 2.4 + hash(x, z, 419) * 1.6, pick(P.Kelp, hash(x, z, 420)))
		end
		if hash(ix, iz, 414) > 0.3 then
			local x, z = at(415, C * 0.4)
			put("Canto", x, z, 1.2 + hash(x, z, 416) * 1.4, nil)
		end
		life(420, count(0, 1, 421))
	elseif p.Kind == "Rim" then
		-- agujas de roca altas (la silueta), abanicos y corales fríos encima, setas de luz al pie
		for i = 1, count(1, 2, 540) do
			local x, z = at(541 + i * 3, C * 0.35)
			put("RocaAguja", x, z, 16 + hash(x, z, 542) * 22, nil, -1)
		end
		for i = 1, count(3, 5, 550) do
			local x, z = at(551 + i * 3, C * 0.45)
			local r = hash(x, z, 552)
			local sp = pick({ "Abanico", "CoralCerebro", "CoralBlando", "Esponjas" }, r)
			put(sp, x, z, if sp == "Abanico" then 3.5 + r * 3 else 1.8 + r * 2, if sp == "Abanico" then pick(FAN_TINT, r) elseif sp == "Esponjas" then pick(SPONGE_TINT, r) else pick(LEDGE_TINT, r))
		end
		for i = 1, count(1, 2, 560) do
			local x, z = at(561 + i * 3, C * 0.45)
			put("SetaLuz", x, z, 1.4 + hash(x, z, 562) * 1.6, pick(ANEMONE_TINT, hash(x, z, 563)))
		end
	elseif p.Kind == "Ledge" then
		-- encima del murete: abanicos altos de frente al azul, esponjas, corales fríos y erizos
		for i = 1, count(4, 7, 520) do
			local x, z = at(521 + i * 3, C * 0.45)
			local r = hash(x, z, 522)
			local sp = pick({ "Abanico", "Esponjas", "CoralCerebro", "CoralBlando", "Abanico" }, r)
			put(sp, x, z, if sp == "Abanico" then 3.5 + r * 3 else 1.6 + r * 2, if sp == "Esponjas" then pick(SPONGE_TINT, r) elseif sp == "Abanico" then pick(FAN_TINT, r) else pick(LEDGE_TINT, r))
		end
		life(530, count(1, 2, 531))
	elseif p.Kind == "Boulders" then
		local rocks = if fy < -60 then { "Canto", "RocaPorosa", "RocaLaja", "Canto" } else { "Canto", "RocaPorosa", "Canto", "RocaPorosa" }
		for i = 1, count(3, 5, 500) do
			local x, z = at(501 + i * 3, C * 0.5)
			local rk = pick(rocks, hash(x, z, 502))
			-- (las lajas, hundidas: solo asoman)
			put(rk, x, z, 1.5 + hash(x, z, 503) * 3.5, nil, if rk == "RocaLaja" then -0.6 else 0)
		end
		if hash(ix, iz, 504) > 0.55 then
			local x, z = at(505, C * 0.4)
			put("Esponjas", x, z, 1.4 + hash(x, z, 506) * 1.4, pick(SPONGE_TINT, hash(x, z, 507)))
		end
		life(510, count(1, 2, 511))
	else -- Sand
		-- (nunca más de ~12 studs sin nada: vida pequeña y algún canto o coral pequeño suelto)
		life(600, count(1, 3, 601))
		if hash(ix, iz, 606) > 0.4 then
			local x, z = at(607, C * 0.45)
			if hash(x, z, 608) > 0.5 then
				put("Canto", x, z, 0.7 + hash(x, z, 609) * 0.9, nil)
			else
				put("CoralCerebro", x, z, 0.8 + hash(x, z, 610) * 0.7, coralTint(fy, hash(x, z, 611)))
			end
		end
		-- (ronda 2: matas de pradera sueltas por la arena, que no quede lisa entre parche y parche)
		for i = 1, count(1, 3, 602) do
			local x, z = at(603 + i * 2, C * 0.5)
			put("Pradera", x, z, 1.2 + hash(x, z, 604) * 1.2, pick(P.Grass, hash(x, z, 605)))
		end
	end
	if ShoreReef.V4 then
		ShoreReef.extras(items, ix, iz, k, p)
	end
	return items
end

-- ¿Se ve a esta distancia (studs a la cámara)? (LOD de SeaBiome; mobile: el móvil)
function ShoreReef.visible(item: Item, distance: number, mobile: boolean): boolean
	local key = if mobile then "Mobile" else "Desktop"
	if (item :: any).Bubble then
		return distance <= ShoreReef.Bubble[key]
	end
	if item.Small then
		return distance <= ShoreReef.SmallDistance[key]
	end
	if item.H < ShoreReef.MidHeight then
		return distance <= ShoreReef.MidDistance[key]
	end
	return distance <= ShoreReef.Radius[key]
end

---------------------------------------------------------------------
-- v4 (Config.Sea.V4): más de todo
---------------------------------------------------------------------
-- La «burbuja» de densidad: alrededor de la cámara (Bubble studs) cada parcela lleva otra capa de cosas
-- pequeñas (matas, cascajo, corales jóvenes, vida); de lejos no se ven y no gastan. Los corales GIGANTES
-- (3–6× el tamaño de siempre) y los HITOS, cada ~128 studs: torres de coral, ruinas, campos de almejas
-- gigantes, arcos de roca, peñascos con abanicos, corros de corales y círculos de kelp.
ShoreReef.Bubble = { Mobile = 34, Desktop = 50 }
ShoreReef.LandmarkCell = 128
ShoreReef.Top = Ocean.Surface - 5 -- (lo más alto que llega una malla: nada asoma por la superficie)

-- El hito de la celda grande (mx, mz), o nil: { Kind, X, Z, Floor, Yaw, IX, IZ (la parcela donde cae) }
ShoreReef.LandmarkMemo = {} :: { [string]: any }
function ShoreReef.landmark(mx: number, mz: number): any
	local key = mx .. "," .. mz
	local got = ShoreReef.LandmarkMemo[key]
	if got ~= nil then
		return if got == false then nil else got
	end
	local LC = ShoreReef.LandmarkCell
	local out: any = nil
	local x = (mx + 0.2 + hash(mx, mz, 900) * 0.6) * LC
	local z = (mz + 0.2 + hash(mx, mz, 901) * 0.6) * LC
	local C = ShoreReef.Cell
	local ix, iz = floor(x / C), floor(z / C)
	local p = ShoreReef.plan(ix, iz)
	if p.Kind and p.Floor and p.Kind ~= "Ledge" and p.Kind ~= "Rim" and hash(mx, mz, 902) < 0.8 and not ShoreReef.cityBlocked(x, z, 30) then
		local fy = p.Floor :: number
		local water = Ocean.Surface - fy
		local r = hash(mx, mz, 903)
		local kind: string?
		if p.Kind == "Reef" or p.Kind == "Rubble" then
			kind = if water > 22 then "TorreCoral" else "Corro"
		elseif p.Kind == "Kelp" then
			kind = "CirculoKelp"
		elseif p.Kind == "Boulders" then
			kind = if water > 26 then "Arco" else "Pena"
		else
			kind = if r < 0.45 then "Almejas" elseif water > 22 and r < 0.8 then "Ruinas" else "Corro"
		end
		-- (los sitios de siempre ya son hitos: nada encima)
		for _, poi in Ocean.Pois do
			if (x - poi.X) ^ 2 + (z - poi.Z) ^ 2 < ((poi.Radius or 40) + 40) ^ 2 then
				kind = nil
				break
			end
		end
		if kind then
			out = { Kind = kind, X = p.X, Z = p.Z, Floor = fy, Yaw = hash(mx, mz, 904) * pi * 2, IX = ix, IZ = iz }
		end
	end
	ShoreReef.LandmarkMemo[key] = if out then out else false
	return out
end

local function landmarkOf(ix: number, iz: number): any
	local C, LC = ShoreReef.Cell, ShoreReef.LandmarkCell
	local x, z = (ix + 0.5) * C, (iz + 0.5) * C
	local lm = ShoreReef.landmark(floor(x / LC), floor(z / LC))
	if lm and lm.IX == ix and lm.IZ == iz then
		return lm
	end
	return nil
end
ShoreReef.landmarkOf = landmarkOf

-- El alto del pedestal de una torre de coral (lo que sube su roca)
local function towerRise(fy: number): number
	return min(18, ShoreReef.Ceiling - fy - 2)
end

-- El relieve de un hito (en la parcela donde cae)
function ShoreReef.landmarkRelief(ops: { Op }, ix: number, iz: number)
	local lm = landmarkOf(ix, iz)
	if not lm then
		return
	end
	local fy = lm.Floor
	local c, sn = math.cos(lm.Yaw), math.sin(lm.Yaw)
	if lm.Kind == "TorreCoral" then
		-- un pedestal de roca alto (hasta 5 m) donde crecen las torres
		local rise = towerRise(fy)
		if rise > 4 then
			table.insert(ops, { Shape = "Ball", X = lm.X, Y = fy + rise - 9, Z = lm.Z, R = 9, Material = "Limestone" })
			table.insert(ops, { Shape = "Ball", X = lm.X + c * 7, Y = fy - 2, Z = lm.Z + sn * 7, R = 8, Material = "Rock" })
		end
	elseif lm.Kind == "Arco" then
		local R = 12
		for k = 0, 8 do
			local a = pi * k / 8
			local r = 3 + (1 - math.sin(a)) * 1.6
			local y = fy - 1 + math.sin(a) * R * 1.05
			if y + r <= ShoreReef.Ceiling then
				table.insert(ops, { Shape = "Ball", X = lm.X + c * math.cos(a) * R, Y = y, Z = lm.Z + sn * math.cos(a) * R, R = r, Material = if k % 3 == 0 then "Slate" else "Rock" })
			end
		end
	elseif lm.Kind == "Pena" then
		local cy, room = capBall(fy, 8, 7)
		if room > 0 then
			table.insert(ops, { Shape = "Ball", X = lm.X, Y = cy, Z = lm.Z, R = 8, Material = "Rock" })
		end
	elseif lm.Kind == "Ruinas" then
		-- el zócalo de un templo: una losa de caliza medio enterrada
		table.insert(ops, { Shape = "Block", X = lm.X, Y = fy - 0.6, Z = lm.Z, Size = { 22, 2.4, 14 }, Yaw = lm.Yaw, Material = "Limestone" })
	end
end

-- Lo de la v4 que se añade al decorado de una parcela
function ShoreReef.extras(items: { Item }, ix: number, iz: number, k: number, p: Plan)
	local C = ShoreReef.Cell
	local fy = p.Floor :: number
	local function put(piece: string, x: number, z: number, h: number, tint: { number }?, extra: { [string]: any }?)
		if excluded == nil and ShoreReef.cityBlocked(x, z, 0) then
			return
		end
		if extra and extra.Giant then
			-- (lo grande, con el alto del fondo de verdad debajo —encima de una roca del relieve—: nunca asoma)
			local ground = ShoreReef.surfaceAt(x, z, Ocean.floorY(x, z) or fy)
			h = min(h, ShoreReef.Top - ground)
			if h < 1 then
				return
			end
		end
		local it: any = { Piece = piece, X = x, Z = z, H = h, Yaw = hash(x, z, 91) * pi * 2, Tint = tint, Small = SMALL[piece] == true, Sway = SWAY[piece] == true, Lift = 0 }
		if extra then
			for key, v in extra do
				it[key] = v
			end
		end
		table.insert(items, it)
	end
	local function at(seed: number, rad: number, cx: number?, cz: number?): (number, number)
		local a = hash(ix, iz, seed) * pi * 2
		local d = sqrt(hash(iz, ix, seed + 0.5)) * rad
		return (cx or p.X) + math.cos(a) * d, (cz or p.Z) + math.sin(a) * d
	end
	local cap = ShoreReef.Top - fy -- (lo más alto que puede ser una malla aquí)
	-- 1) la burbuja: cosas pequeñas de más, solo cerca de la cámara
	local bubbleKinds = if p.Kind == "Reef"
		then { "CoralCerebro", "CoralBlando", "AnemonaLuz", "Esponjas", "Erizo", "Estrella", "CoralCuerno", "Pradera" }
		elseif p.Kind == "Kelp" or p.Kind == "Meadow" then { "Pradera", "Pradera", "AlgaAncha", "Canto", "Estrella", "Erizo" }
		elseif p.Kind == "Boulders" or p.Kind == "Rubble" then { "Canto", "RocaPorosa", "Erizo", "CoralCerebro", "Esponjas", "Estrella" }
		else { "Pradera", "Estrella", "Canto", "CoralCerebro", "Erizo", "Concha" }
	for i = 1, floor((10 + hash(ix, iz, 950) * 8) * k + 0.5) do
		local x, z = at(951 + i * 3, C * 0.55)
		local piece = pick(bubbleKinds, hash(x, z, 952))
		local r = hash(x, z, 953)
		local h = if piece == "Pradera" then 1 + r * 1.6 elseif piece == "AlgaAncha" then 1.8 + r * 1.4 elseif piece == "Erizo" or piece == "Estrella" or piece == "Concha" then 0.3 + r * 0.5 else 0.7 + r * 1.2
		local tint = if piece == "Pradera" or piece == "AlgaAncha" then pick(P.Grass, r)
			elseif piece == "Esponjas" then pick(SPONGE_TINT, r)
			elseif piece == "AnemonaLuz" then pick(ANEMONE_TINT, r)
			elseif piece == "CoralCuerno" then pick(STAG_TINT, r)
			elseif MarKitTint[piece] then coralTint(fy, r)
			else nil
		put(piece, x, z, h, tint, { Bubble = true, Small = true })
	end
	-- 2) un coral gigante en algunas parcelas de arrecife (3–6× los de siempre)
	if p.Kind == "Reef" and hash(ix, iz, 960) > 0.8 and cap > 9 then
		local x, z = at(961, 5)
		local r = hash(ix, iz, 962)
		local piece = pick({ "CoralCerebro", "CoralMesa", "CoralPilar", "Esponjas", "Abanico" }, r)
		local h = math.min(cap, if piece == "CoralPilar" then 9 + r * 9 elseif piece == "Abanico" then 8 + r * 7 elseif piece == "CoralMesa" then 5 + r * 4 else 6 + r * 6)
		local tint = if piece == "CoralMesa" then pick(TABLE_TINT, r) elseif piece == "Esponjas" then pick(SPONGE_TINT, r) elseif piece == "Abanico" then pick(FAN_TINT, r) else coralTint(fy, r)
		put(piece, x, z, h, tint, { Giant = true })
	end
	-- 3) el hito, si cae en esta parcela
	local lm = landmarkOf(ix, iz)
	if not lm then
		return
	end
	local c, sn = math.cos(lm.Yaw), math.sin(lm.Yaw)
	if lm.Kind == "TorreCoral" then
		local rise = towerRise(fy)
		local room = ShoreReef.Top - (fy + rise)
		if rise > 4 and room > 6 then
			for i = 1, 4 do
				local a = i * 1.7 + lm.Yaw
				local x, z = lm.X + math.cos(a) * (2 + i), lm.Z + math.sin(a) * (2 + i)
				local r = hash(ix, iz, 970 + i)
				local piece = pick({ "CoralPilar", "CoralCuerno", "CoralPilar", "Abanico" }, r)
				put(piece, x, z, math.min(room, (if piece == "CoralPilar" then 10 else 7) + r * 8), if piece == "Abanico" then pick(FAN_TINT, r) else coralTint(fy, r), { Giant = true })
			end
		end
		for i = 1, 8 do
			local x, z = at(980 + i * 3, 13, lm.X, lm.Z)
			local r = hash(x, z, 981)
			put(pick({ "CoralCerebro", "CoralMesa", "Esponjas", "CoralBlando" }, r), x, z, math.min(cap, 2.5 + r * 4), coralTint(fy, r), { Giant = true })
		end
	elseif lm.Kind == "Ruinas" then
		for i = -2, 2 do
			local x, z = lm.X + c * i * 4.5, lm.Z + sn * i * 4.5
			local h = if hash(ix, iz, 990 + i) > 0.45 then math.min(cap, 6 + hash(ix, iz, 991 + i) * 8) else 3
			put("ColumnaRuina", x - sn * 5, z + c * 5, h, nil, { Giant = true })
			if hash(ix, iz, 993 + i) > 0.5 then
				put("ColumnaRuina", x + sn * 5, z - c * 5, math.min(cap, 4 + hash(ix, iz, 994 + i) * 7), nil, { Giant = true })
			end
		end
		for i = 1, 6 do
			local x, z = at(1000 + i * 3, 12, lm.X, lm.Z)
			local r = hash(x, z, 1001)
			put(pick({ "Esponjas", "CoralBlando", "Abanico", "AlgaAncha" }, r), x, z, 1.6 + r * 2.4, if r < 0.25 then pick(SPONGE_TINT, r) else coralTint(fy, r))
		end
	elseif lm.Kind == "Almejas" then
		-- campo de almejas gigantes (de momento, la concha del kit en grande)
		for i = 1, 7 do
			local x, z = at(1010 + i * 3, 11, lm.X, lm.Z)
			put("Concha", x, z, 1.4 + hash(x, z, 1011) * 1.6, nil, { Giant = true, Small = false })
		end
		for i = 1, 5 do
			local x, z = at(1020 + i * 3, 13, lm.X, lm.Z)
			put("AnemonaLuz", x, z, 1 + hash(x, z, 1021), pick(ANEMONE_TINT, hash(x, z, 1022)))
		end
	elseif lm.Kind == "CirculoKelp" then
		local water = Ocean.Surface - 2 - fy
		for i = 1, 9 do
			local a = i / 9 * pi * 2
			local x, z = lm.X + math.cos(a) * 14, lm.Z + math.sin(a) * 14
			put("KelpGigante", x, z, math.clamp(water * 0.92, 12, 40), pick(P.Kelp, hash(x, z, 1031)), { Giant = true })
		end
		for i = 1, 4 do
			local x, z = at(1040 + i * 3, 6, lm.X, lm.Z)
			put("RocaPorosa", x, z, 2 + hash(x, z, 1041) * 2, nil)
		end
	elseif lm.Kind == "Arco" or lm.Kind == "Pena" then
		for i = 1, 7 do
			local x, z = at(1050 + i * 3, 12, lm.X, lm.Z)
			local r = hash(x, z, 1051)
			local piece = pick({ "Abanico", "Esponjas", "CoralCerebro", "CoralBlando" }, r)
			put(piece, x, z, math.min(cap, if piece == "Abanico" then 4 + r * 5 else 2 + r * 3), if piece == "Abanico" then pick(FAN_TINT, r) elseif piece == "Esponjas" then pick(SPONGE_TINT, r) else pick(LEDGE_TINT, r))
		end
	else -- Corro: un corro de corales grandes en la arena
		for i = 1, 9 do
			local x, z = at(1060 + i * 3, 10, lm.X, lm.Z)
			local r = hash(x, z, 1061)
			local piece = pick({ "CoralCerebro", "CoralMesa", "CoralBlando", "Esponjas", "Abanico", "CoralPilar" }, r)
			local tint = if piece == "CoralMesa" then pick(TABLE_TINT, r) elseif piece == "Esponjas" then pick(SPONGE_TINT, r) elseif piece == "Abanico" then pick(FAN_TINT, r) else coralTint(fy, r)
			put(piece, x, z, math.min(cap, 2.6 + r * 5), tint, { Giant = true })
		end
	end
end

-- Dónde se juntan los peces (SeaLife: bancos alrededor de los arrecifes): el centro de la parcela «Reef»
-- más cercana a (x, z) en ±2 parcelas, o nil
function ShoreReef.fishSpotNear(x: number, z: number): Vector3?
	local C = ShoreReef.Cell
	local cx, cz = floor(x / C), floor(z / C)
	local best, bestD = nil, math.huge
	for dx = -2, 2 do
		for dz = -2, 2 do
			local p = ShoreReef.plan(cx + dx * 2, cz + dz * 2)
			if p.Kind == "Reef" and p.Floor then
				local d = (p.X - x) ^ 2 + (p.Z - z) ^ 2
				if d < bestD then
					bestD = d
					best = Vector3.new(p.X, (p.Floor :: number) + 4, p.Z)
				end
			end
		end
	end
	return best
end

return ShoreReef
