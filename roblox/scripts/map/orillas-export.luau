-- (con MAR_V4=1: los 8 planos de docs/mar/v4-objetivo.md —el Gran Veril, el borde del abismo y un hito—, con
-- la roca del veril (shared/Sea/DeepReef), lo que crece en su pared, la burbuja de densidad y la vida de la v4)
-- Vuelca los 6 planos de docs/mar/v3-objetivo.md con el MISMO código del juego (shared/Sea/ShoreReef: plan,
-- relieve y decorado; Ocean.sample; OceanBiomes.look; MarKit/MarFauna) para la vista previa de Blender
-- (scripts/map/orillas_preview.py). Lo que se vuelca es lo que el móvil plantaría alrededor de la cámara
-- (ShoreReef.visible con mobile = true, densidad del móvil) y los peces como los pone SeaLife.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/map/orillas-export.luau SALIDA.json [--antes]
--   (--antes: el fondo de la v125: Salt plano a −14 sin relieve y el decorado viejo de SeaBiome, para comparar)

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local roblox = require("@lune/roblox")
local L = require("../lib/ModuleLoader")

local Vector3 = roblox.Vector3
local out = process.args[1] or "orillas.json"
local before = table.find(process.args, "--antes") ~= nil

local Ocean = L.load("src/shared/Sea/Ocean")
local OceanBiomes = L.load("src/shared/Sea/OceanBiomes")
local ShoreReef = L.load("src/shared/Sea/ShoreReef")
local MarKit = L.load("src/shared/Sea/MarKit")
local MarFauna = L.load("src/shared/Sea/MarFauna")
local Nacara = L.load("src/shared/Sea/Nacara")
local DeepReef = L.load("src/shared/Sea/DeepReef")
local V4 = Ocean.V4 == true
-- (v4, ronda 2: las bolas grandes de los hitos, en el terreno de alturas, salían como silos —sin la parte de
-- abajo de la bola—. Van aparte, como esferas, igual que la roca del veril)
ShoreReef.NoLandmarkRelief = true
ShoreReef.Memo = {}
DeepReef.Memo = {}

local C = ShoreReef.Cell
local floor, sqrt = math.floor, math.sqrt
local MOBILE = true
local DENSITY = ShoreReef.Density.Mobile

local function color(c: Color3): { number }
	return { math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) }
end

-- Buscar una parcela que cumpla cond cerca de (x, z)
local function find(x: number, z: number, radius: number, cond: (any) -> boolean): any
	local best, bestD = nil, math.huge
	local cx, cz = floor(x / C), floor(z / C)
	local r = math.ceil(radius / C)
	for ix = cx - r, cx + r do
		for iz = cz - r, cz + r do
			local p = ShoreReef.plan(ix, iz)
			if cond(p) then
				local d = (p.X - x) ^ 2 + (p.Z - z) ^ 2
				if d < bestD then
					best, bestD = { P = p, IX = ix, IZ = iz }, d
				end
			end
		end
	end
	return best
end

local function unit(x: number, z: number): (number, number)
	local m = sqrt(x * x + z * z)
	return x / m, z / m
end

-- Los seis planos
local frames = {}
local function frame(id: string, name: string, player: Vector3, lookX: number, lookZ: number, night: number, extra: { [string]: any }?)
	local lx, lz = unit(lookX, lookZ)
	local cam = player - Vector3.new(lx, 0, lz) * 11 + Vector3.new(0, 3, 0)
	local target = player + Vector3.new(lx, 0, lz) * 9 + Vector3.new(0, 0.5 + ((extra or {}).Pitch or 0), 0)
	if extra and extra.CamAt then
		cam, target = extra.CamAt, extra.TargetAt
	end
	table.insert(frames, { Id = id, Name = name, Player = player, Cam = cam, Target = target, Night = night, Extra = extra or {} })
end

do -- 1 · Orilla de arena, 2 m (Playa del Sur)
	local f = find(1781, 3300, 420, function(p)
		return (p.Kind == "Sand" or p.Kind == "Meadow") and p.D > 28 and p.D < 70
	end)
	local p = f.P
	local nx, nz = ShoreReef.seaward(p.X, p.Z)
	-- a lo largo de la costa y un poco hacia fuera (la playa a la izquierda)
	frame("1", "Orilla de arena, 2 m", Vector3.new(p.X, Ocean.Surface - Ocean.studs(2), p.Z), -nz + nx * 0.7, nx + nz * 0.7, 0)
end
local reefPlayer, reefLX, reefLZ
do -- 2 · Arrecife a 6 m (Jardín Escarlata, en el Arrecife Escarlata: el de las capturas del dueño)
	local poi = Ocean.PoiById.JardinEscarlata
	local f = find(poi.X, poi.Z, 160, function(p)
		return p.Kind == "Reef" and p.Floor and p.Floor < -18
	end)
	local p = f.P
	local nx, nz = ShoreReef.seaward(p.X, p.Z)
	local px, pz = p.X - nx * 14 - nz * 6, p.Z - nz * 14 + nx * 6
	reefPlayer = Vector3.new(px, p.Floor + 7, pz)
	reefLX, reefLZ = p.X - px, p.Z - pz
	frame("2", "Arrecife, 10 m", reefPlayer, reefLX, reefLZ, 0)
end
local verilSpot = nil
if V4 then
	-- (v4) El pie de pared más alto y más «lleno» de veril cerca de una playa con arrecife (frente a Levante)
	local best, bestScore = nil, -math.huge
	local D = DeepReef.Cell
	local nx0, nz0 = ShoreReef.seaward(4107, -1772)
	local cx, cz = 4107 + nx0 * 420, -1772 + nz0 * 420
	for _, c in { { cx, cz }, { 1781 + 0, 3408 + 420 }, { -3381, -3250 - 420 }, { -4006 - 420, 531 } } do
		for ix = math.floor((c[1] - 900) / D), math.floor((c[1] + 900) / D) do
			for iz = math.floor((c[2] - 900) / D), math.floor((c[2] + 900) / D) do
				local sp = DeepReef.spot(ix, iz)
				if sp and math.abs(sp.U) < 14 and sp.M > 0.85 then
					local score = (sp.Top - sp.Fosa) + DeepReef.hash(ix, iz, 2) * 30
					if score > bestScore then
						best, bestScore = { Spot = sp, IX = ix, IZ = iz }, score
					end
				end
			end
		end
	end
	verilSpot = best
end
if V4 and verilSpot then -- 3 · v4: el Gran Veril (desde el filo de la plataforma, mirando al azul y hacia abajo)
	local sp = verilSpot.Spot
	local tx, tz = -sp.NZ, sp.NX
	-- (ronda 1: desde detrás del filo no se veía la pared. Ahora el jugador flota ya pasado el filo y la cámara
	-- mira a lo largo de la pared y hacia abajo, 28°: la cara del veril baja por un lado y el azul por el otro)
	-- (ronda 2: desde encima del filo la pared queda debajo, fuera del plano. El jugador ya está sobre el azul,
	-- 24 studs fuera y algo por debajo del filo, y mira de lado a la pared y hacia abajo)
	-- (ronda 3: de cerca, la pared era una mancha oscura y las gorgonias, discos de frente. Plano general: el
	-- jugador a 34 studs de la pared sobre el azul, la pared en diagonal de arriba a la izquierda a abajo)
	local P = Vector3.new(sp.WX + sp.NX * 34, sp.Top - 10, sp.WZ + sp.NZ * 34)
	local d = Vector3.new(tx * 0.62 - sp.NX * 0.78, 0, tz * 0.62 - sp.NZ * 0.78).Unit
	local side = Vector3.new(d.Z, 0, -d.X)
	local cam = P - d * 12 + Vector3.new(0, 3, 0) + side * 4
	local target = cam + d * 22 - Vector3.new(0, 22 * math.tan(math.rad(12)), 0)
	frame("3", "El Gran Veril, 13 m", P, d.X, d.Z, 0, { Manta = true, Veril = true, CamAt = cam, TargetAt = target })
else do -- 3 · Repisa y caída a 15 m (el borde de la plataforma frente a Levante)
	local nx0, nz0 = ShoreReef.seaward(4107, -1772)
	local f = find(4107 + nx0 * 360, -1772 + nz0 * 360, 260, function(p)
		return p.Kind == "Ledge" and p.Floor ~= nil
	end)
	local p = f.P
	local nx, nz = ShoreReef.seaward(p.X, p.Z)
	frame("3", "Repisa y caída, 13 m", Vector3.new(p.X - nx * 16, p.Floor + 9, p.Z - nz * 16), nx + nz * 0.25, nz - nx * 0.25, 0, { Manta = true })
end end
do -- 4 · Bosque de kelp (Laberinto de Kelp), desde un pasillo de arena entre los tallos
	local k = Ocean.Kelp[1]
	local f = find(k.X, k.Z, 300, function(p)
		if p.Kind == "Kelp" or not p.Floor then
			return false
		end
		-- (una parcela sin kelp con kelp delante: el pasillo)
		local ix, iz = math.floor(p.X / C), math.floor(p.Z / C)
		local n = 0
		for dz = 1, 3 do
			if ShoreReef.plan(ix, iz + dz).Kind == "Kelp" then
				n += 1
			end
		end
		return n >= 2
	end)
	local p = f.P
	frame("4", "Bosque de kelp", Vector3.new(p.X, p.Floor + 8, p.Z), 0.15, 1, 0)
end
do -- 5 · Llegada a Nácara: desde 170 studs, algo por encima, para ver la ciudad entera con su anillo
	local c = Nacara.centerPosition()
	local f = find(c.X + 120, c.Z - 120, 90, function(p)
		local d = sqrt((p.X - c.X) ^ 2 + (p.Z - c.Z) ^ 2)
		return p.Floor ~= nil and d > 150 and d < 190
	end)
	local p = f.P
	frame("5", "Llegada a Nácara, 37 m", Vector3.new(p.X, Nacara.FloorY + 16, p.Z), c.X - p.X, c.Z - p.Z, 0, { Nacara = true })
end
-- 6 · El arrecife de noche
frame("6", "El arrecife de noche", reefPlayer, reefLX, reefLZ, 1, if V4 then { Swarm = true } else nil)
if V4 and verilSpot then -- 7 · v4: el borde del abismo (al pie del veril, en la fosa, mirando a lo largo de la pared)
	local sp = verilSpot.Spot
	local tx, tz = -sp.NZ, sp.NX
	local V = Ocean.Veril
	local px, pz = sp.WX + sp.NX * (V.Drop + 18), sp.WZ + sp.NZ * (V.Drop + 18)
	local fy = Ocean.floorY(px, pz) or sp.Fosa
	-- (ronda 1: la pared no salía. A lo largo de la fosa, con la pared a un lado y mirando algo hacia arriba)
	local P = Vector3.new(px, fy + 12, pz)
	local d = Vector3.new(tx * 0.8 - sp.NX * 0.6, 0, tz * 0.8 - sp.NZ * 0.6).Unit
	local cam = P - d * 11 + Vector3.new(0, 3, 0) + Vector3.new(sp.NX, 0, sp.NZ) * 8
	local target = cam + d * 22 + Vector3.new(0, 22 * math.tan(math.rad(14)), 0)
	frame("7", "El borde del abismo, " .. math.floor(Ocean.meters(fy + 12) + 0.5) .. " m", P, d.X, d.Z, 0, { Swarm = true, Veril = true, CamAt = cam, TargetAt = target })
end
if V4 then -- 8 · v4: un hito (una torre de coral en el arrecife, la más cercana al Jardín Escarlata con agua de sobra)
	local poi = Ocean.PoiById.JardinEscarlata
	local LC = ShoreReef.LandmarkCell
	local best, bestD = nil, math.huge
	for mx = math.floor((poi.X - 1400) / LC), math.floor((poi.X + 1400) / LC) do
		for mz = math.floor((poi.Z - 1400) / LC), math.floor((poi.Z + 1400) / LC) do
			local lm = ShoreReef.landmark(mx, mz)
			if lm and lm.Kind == "TorreCoral" and lm.Floor < -30 then
				local d = (lm.X - poi.X) ^ 2 + (lm.Z - poi.Z) ^ 2
				if d < bestD then
					best, bestD = lm, d
				end
			end
		end
	end
	if best then
		local nx, nz = ShoreReef.seaward(best.X, best.Z)
		local px, pz = best.X - nx * 30 + nz * 8, best.Z - nz * 30 - nx * 8
		frame("8", "Un hito: torre de coral, " .. math.floor(Ocean.meters(best.Floor) + 0.5) .. " m", Vector3.new(px, best.Floor + 9, pz), best.X - px, best.Z - pz, 0, { Bait = true, Pitch = 3 })
	end
end

---------------------------------------------------------------------
-- Volcar cada plano
---------------------------------------------------------------------
local AREA, STEP = if V4 then 360 else 300, 2
-- (v4) La pared del veril en el juego son columnas de 16 studs (Ocean.Cell, sin juntar: tolerancia 0): aquí igual
local function stepped(x: number, z: number): number?
	if not V4 then
		return nil
	end
	local s = Ocean.sample(x, z)
	if (s.VerilWall or 0) > 0.3 or (s.Veril or 0) > 0.05 then
		local c = Ocean.Cell
		local cx, cz = (math.floor(x / c) + 0.5) * c, (math.floor(z / c) + 0.5) * c
		return Ocean.floorY(cx, cz)
	end
	return nil
end
local result = { Frames = {}, Before = before, Kit = {}, Fauna = {} }
for name, info in MarKit.Pieces do
	result.Kit[name] = { Size = info.Size, Tint = info.Tint == true, Glow = info.Glow == true, Group = info.Group }
end
for name, info in MarFauna.Pieces do
	result.Fauna[name] = { Size = info.Size, Transparency = info.Transparency }
end

local function baseMaterial(x: number, z: number): (number?, string)
	local fy, mat = Ocean.cellInfo(x, z)
	return fy, mat
end

for _, f in frames do
	local cam: Vector3 = f.Cam
	local dir = (f.Target - cam).Unit
	local center = cam + Vector3.new(dir.X, 0, dir.Z).Unit * (AREA / 2 - 40)
	local x0, z0 = floor((center.X - AREA / 2) / STEP) * STEP, floor((center.Z - AREA / 2) / STEP) * STEP
	local n = AREA / STEP + 1
	local heights, mats = {}, {}
	local matIndex, matNames = {}, {}
	local function mi(name: string): number
		if not matIndex[name] then
			table.insert(matNames, name)
			matIndex[name] = #matNames
		end
		return matIndex[name]
	end
	for j = 0, n - 1 do
		for i = 0, n - 1 do
			local x, z = x0 + i * STEP, z0 + j * STEP
			local fy, base = baseMaterial(x, z)
			local y, mat
			if not fy then
				local d = Ocean.landDistance(x, z)
				y, mat = -1, if d < -70 then "LeafyGrass" else "Sand"
			elseif before then
				y, mat = fy, if base == "Snow" then "Salt" else base -- (la v125: Salt agrietado y sin relieve)
			else
				local st = stepped(x, z)
				if st then
					y, mat = st, base
				else
					y, mat = ShoreReef.surfaceAt(x, z, fy, base)
				end
			end
			table.insert(heights, math.floor(y * 100 + 0.5) / 100)
			table.insert(mats, mi(mat))
		end
	end
	-- Decorado (lo que plantaría el móvil con la cámara aquí)
	local items = {}
	local reefs = {}
	if before then
		-- Aproximación del decorado de la v125 (Controllers/SeaBiome de antes: trozos de 14 studs hasta 56 de la
		-- cámara en el móvil, cosas sueltas por zona con la malla del kit; sin los corales de piezas del servidor)
		local OLD = { CoralHead = "CoralCerebro", Branch = "CoralCuerno", Table = "CoralMesa", Fan = "Abanico", Anemone = "CoralBlando", Seagrass = "Pradera", Rock = "RocaPorosa", Shell = "Concha", Starfish = "Estrella", Urchin = "Erizo", Crab = "Cangrejo", Sponge = "Esponjas", Coral = "CoralCerebro", Kelp = "KelpGigante" }
		local OLD_H = { CoralCerebro = 2.5, CoralCuerno = 2.7, CoralMesa = 1.7, Abanico = 3.5, CoralBlando = 2, Pradera = 3, RocaPorosa = 2.3, Concha = 0.5, Estrella = 0.25, Erizo = 0.7, Cangrejo = 0.8, Esponjas = 2.5, KelpGigante = 20 }
		local DENS = { Kelp = 4, Arrecife = 4.5, Abismo = 3, Sima = 3, Garganta = 3, Catedrales = 4, Orilla = 4, Coral = 5 }
		local P = L.load("src/shared/Sea/ReefZone").Palette
		local h = ShoreReef.hash
		local CELL = 14
		local cx, cz = floor(cam.X / CELL), floor(cam.Z / CELL)
		for ix = cx - 5, cx + 5 do
			for iz = cz - 5, cz + 5 do
				local mx, mz = (ix + 0.5) * CELL, (iz + 0.5) * CELL
				if sqrt((mx - cam.X) ^ 2 + (mz - cam.Z) ^ 2) <= 56 then
					local zoneId = Ocean.zoneAt(mx, mz)
					local zz = zoneId and OceanBiomes.zone(zoneId)
					if zz then
						local list, total = {}, 0
						for name, w in zz.Flora do
							if OLD[name] and w > 0 then
								table.insert(list, { OLD[name], w })
								total += w
							end
						end
						table.sort(list, function(a, b)
							return a[2] > b[2]
						end)
						local count = floor(h(ix, iz, 1) * (DENS[zoneId] or 3.2))
						local cl = Ocean.noise(mx, mz, 46, 77)
						count = floor(count * (if cl > 0.6 then 2.2 elseif cl > 0.46 then 0.9 else 0.2) + 0.5)
						for j = 1, count do
							local x = (ix + h(ix, iz, j * 2)) * CELL
							local z = (iz + h(iz, ix, j * 2 + 1)) * CELL
							local fy = Ocean.floorY(x, z)
							if fy and #list > 0 then
								local r = h(x, z, 7) * total
								local piece = list[1][1]
								for _, e in list do
									r -= e[2]
									if r <= 0 then
										piece = e[1]
										break
									end
								end
								local rr = h(z, x, 8)
								local tint = nil
								if piece == "Pradera" then
									tint = P.Grass[1 + floor(rr * 3) % 3]
								elseif piece ~= "RocaPorosa" and piece ~= "Concha" and piece ~= "Estrella" and piece ~= "Erizo" and piece ~= "Cangrejo" then
									local l = if rr > 0.5 then P.Warm else P.Cool
									tint = l[1 + floor(h(x, z, 77) * #l) % #l]
								end
								table.insert(items, { Piece = piece, X = x, Y = fy, Z = z, H = OLD_H[piece] or 2, Yaw = rr * 6.28, Tint = tint })
							end
						end
					end
				end
			end
		end
	else
		local r = ShoreReef.Radius.Mobile
		local cx, cz = floor(cam.X / C), floor(cam.Z / C)
		local rc = math.ceil(r / C) + 1
		for ix = cx - rc, cx + rc do
			for iz = cz - rc, cz + rc do
				local p = ShoreReef.plan(ix, iz)
				if p.Kind == "Reef" then
					table.insert(reefs, { p.X, p.Floor, p.Z })
				end
				for _, it in ShoreReef.decor(ix, iz, DENSITY, p) do
					local d = sqrt((it.X - cam.X) ^ 2 + (it.Z - cam.Z) ^ 2)
					if ShoreReef.visible(it, d, MOBILE) then
						local fy, base = baseMaterial(it.X, it.Z)
						if fy then
							local y = ShoreReef.surfaceAt(it.X, it.Z, fy, base)
							table.insert(items, { Piece = it.Piece, X = it.X, Y = y + it.Lift, Z = it.Z, H = it.H, Yaw = it.Yaw, Tint = it.Tint, Sway = it.Sway })
						end
					end
				end
			end
		end
	end
	-- (v4) La roca del veril (bolas: en Blender, esferas de roca; el agua de las cuevas, bocas oscuras) y lo que
	-- crece en su pared: el sitio en la cara se busca como en SeaBiome —un rayo horizontal hacia la pared—,
	-- aquí contra las columnas del fondo y las bolas de roca
	local rocks, caves = {}, {}
	local lmBalls = {}
	if V4 and not before then
		local cx0, cz0 = floor(cam.X / C), floor(cam.Z / C)
		local rc0 = math.ceil((AREA / 2 + 30) / C)
		for ix = cx0 - rc0, cx0 + rc0 do
			for iz = cz0 - rc0, cz0 + rc0 do
				local ops = {}
				ShoreReef.landmarkRelief(ops, ix, iz)
				for _, op in ops do
					if op.Shape == "Ball" then
						table.insert(rocks, { X = op.X, Y = op.Y, Z = op.Z, R = op.R, Material = op.Material })
						table.insert(lmBalls, op)
					end
				end
			end
		end
		-- (lo que va encima de una bola de hito: a su cima)
		for _, it in items do
			for _, b in lmBalls do
				local d2 = (it.X - b.X) ^ 2 + (it.Z - b.Z) ^ 2
				if d2 < b.R * b.R then
					it.Y = math.max(it.Y, b.Y + math.sqrt(b.R * b.R - d2))
				end
			end
		end
	end
	if V4 and not before then
		local D = DeepReef.Cell
		local balls = {}
		local dcx, dcz = floor(cam.X / D), floor(cam.Z / D)
		local rr = math.ceil((AREA / 2 + 60) / D)
		for ix = dcx - rr, dcx + rr do
			for iz = dcz - rr, dcz + rr do
				for _, op in DeepReef.relief(ix, iz) do
					if op.Shape == "Ball" then
						if op.Material == "Water" then
							table.insert(caves, { X = op.X, Y = op.Y, Z = op.Z, R = op.R })
						else
							table.insert(rocks, { X = op.X, Y = op.Y, Z = op.Z, R = op.R, Material = op.Material })
							table.insert(balls, op)
						end
					end
				end
			end
		end
		local function solid(x: number, y: number, z: number): boolean
			local h = stepped(x, z) or Ocean.floorY(x, z)
			if h and y < h then
				return true
			end
			for _, b in balls do
				if (x - b.X) ^ 2 + (y - b.Y) ^ 2 + (z - b.Z) ^ 2 < b.R * b.R then
					return true
				end
			end
			return false
		end
		local radius = DeepReef.Radius.Mobile
		for ix = dcx - 4, dcx + 4 do
			for iz = dcz - 4, dcz + 4 do
				for _, it in DeepReef.decor(ix, iz, DENSITY) do
					local y0 = it.Y or -100
					local d = sqrt((it.X - cam.X) ^ 2 + (it.Z - cam.Z) ^ 2 + (y0 - cam.Y) ^ 2)
					if DeepReef.visible(it, d, MOBILE) then
						if it.Wall then
							-- el rayo hacia la pared, de 0,5 en 0,5 studs
							local hit = nil
							for k = 0, 140 do
								local t = k * 0.5
								local x, z = it.X - it.NX * t, it.Z - it.NZ * t
								if solid(x, it.Y, z) then
									hit = { x + it.NX * 0.3, it.Y, z + it.NZ * 0.3 }
									break
								end
							end
							if hit then
								local up = Vector3.new(it.NX, 0.7, it.NZ).Unit
								table.insert(items, { Piece = it.Piece, X = hit[1], Y = hit[2], Z = hit[3], H = it.H, Yaw = it.Yaw, Tint = it.Tint, Sway = it.Sway, Up = { up.X, up.Y, up.Z } })
							end
						else
							local fy = stepped(it.X, it.Z) or Ocean.floorY(it.X, it.Z)
							if fy then
								table.insert(items, { Piece = it.Piece, X = it.X, Y = fy, Z = it.Z, H = it.H, Yaw = it.Yaw, Tint = it.Tint, Sway = it.Sway })
							end
						end
					end
				end
			end
		end
	end
	-- Peces (SeaLife: bancos alrededor de los arrecifes, de 10 en el móvil)
	local fish = {}
	local rnd = L.Random.new(7)
	local function school(at: Vector3, species: string, count: number, length: number)
		-- (los bancos se apartan de ti: SeaLife los aleja a menos de 9 studs; aquí, a 16 de la cámara como poco)
		local away = Vector3.new(at.X - cam.X, 0, at.Z - cam.Z)
		if away.Magnitude < 16 then
			at = at + (if away.Magnitude > 0.1 then away.Unit else dir) * (16 - away.Magnitude)
		end
		local hx, hz = rnd:NextNumber(-1, 1), rnd:NextNumber(-1, 1)
		for _ = 1, count do
			local p = at + Vector3.new(rnd:NextNumber(-3.5, 3.5), rnd:NextNumber(-1.5, 1.5), rnd:NextNumber(-3.5, 3.5))
			table.insert(fish, { Piece = species, X = p.X, Y = p.Y, Z = p.Z, Length = length, DX = hx + rnd:NextNumber(-0.2, 0.2), DZ = hz + rnd:NextNumber(-0.2, 0.2) })
		end
	end
	local zone = Ocean.zoneAt(f.Player.X, f.Player.Z)
	local reefSpecies = MarFauna.ForCreature.ReefSchool
	if not before then
		table.sort(reefs, function(a, b)
			return (a[1] - f.Player.X) ^ 2 + (a[3] - f.Player.Z) ^ 2 < (b[1] - f.Player.X) ^ 2 + (b[3] - f.Player.Z) ^ 2
		end)
		local nSchools, perSchool = if V4 then 6 else 3, if V4 then 24 else 10
		for i = 1, math.min(nSchools, #reefs) do
			local r = reefs[1 + (i - 1) * (if V4 then 2 else 1)] or reefs[i]
			school(Vector3.new(r[1], r[2] + 5, r[3]), reefSpecies[1 + (i - 1) % #reefSpecies], perSchool, 1.2)
		end
	end
	if V4 and f.Extra.Bait then
		-- (v4) un banco cerrado en bola que gira (SeaLife: anillos de tres pisos)
		local side = Vector3.new(dir.Z, 0, -dir.X)
		local c = f.Player + dir * 30 + side * 12 + Vector3.new(0, 4, 0)
		for i = 1, 38 do
			local a = (i / 38) * math.pi * 2
			local ring = 3.2 + (i % 3) * 1.1
			local p = c + Vector3.new(math.cos(a) * ring, ((i % 3) - 1) * 1.3, math.sin(a) * ring)
			table.insert(fish, { Piece = "PezBanco", X = p.X, Y = p.Y, Z = p.Z, Length = 1.0, DX = -math.sin(a), DZ = math.cos(a), Trail = true })
		end
	end
	if V4 then
		for _, fsh in fish do
			fsh.Trail = true
		end
	end
	-- (y un banco de peces de banco por delante de la cámara)
	school(f.Player + dir * 26 + Vector3.new(4, 2, 0), "PezBanco", if V4 then 24 else 10, 1.0)
	if V4 then
		school(f.Player + dir * 48 + Vector3.new(-14, 5, 10), "PezBanco", 24, 1.0)
	end
	local big = {}
	if f.Extra.Manta then
		table.insert(big, { Piece = "Manta", X = f.Player.X + dir.X * 40, Y = f.Player.Y + 6, Z = f.Player.Z + dir.Z * 40, Length = 7, DX = dir.Z, DZ = -dir.X })
	end
	if f.Id == "2" or f.Id == "6" then
		table.insert(big, { Piece = "Tortuga", X = f.Player.X + dir.X * 55 + 14, Y = f.Player.Y + 3, Z = f.Player.Z + dir.Z * 55, Length = 3.6, DX = -dir.Z, DZ = dir.X })
	end
	if f.Id == "6" and not f.Extra.Swarm then
		table.insert(big, { Piece = "Medusa", X = f.Player.X + dir.X * 18 - 5, Y = f.Player.Y + 4, Z = f.Player.Z + dir.Z * 18, Length = 1.8, DX = 1, DZ = 0, Glow = true })
	end
	if f.Extra.Swarm then
		-- (v4) una nube de medusas (SeaLife: 6 en el móvil, 10 en el ordenador; aquí 10)
		local c = f.Player + dir * 24 + Vector3.new(0, 5, 0)
		for i = 1, 10 do
			table.insert(big, { Piece = "Medusa", X = c.X + rnd:NextNumber(-7, 7), Y = c.Y + rnd:NextNumber(-4, 4), Z = c.Z + rnd:NextNumber(-7, 7), Length = rnd:NextNumber(1.2, 2.4), DX = 1, DZ = 0, Glow = true })
		end
	end
	if V4 and (f.Id == "1" or f.Id == "2") then
		-- (v4) una raya que planea pegada a la arena
		local rx, rz = f.Player.X + dir.X * 30 + dir.Z * 10, f.Player.Z + dir.Z * 30 - dir.X * 10
		local ry = Ocean.floorY(rx, rz)
		if ry then
			table.insert(big, { Piece = "Manta", X = rx, Y = ShoreReef.surfaceAt(rx, rz, ry) + 1.4, Z = rz, Length = 6, DX = dir.Z, DZ = -dir.X, Trail = true })
		end
	end
	if V4 and (f.Id == "2" or f.Id == "3" or f.Id == "8") then
		-- (v4) un tiburón de arrecife que pasa (SeaLife «Shark»)
		local side = Vector3.new(dir.Z, 0, -dir.X)
		local p0 = f.Player + dir * 46 - side * 18 + Vector3.new(0, 4, 0)
		table.insert(big, { Piece = "Tiburon", X = p0.X, Y = p0.Y, Z = p0.Z, Length = 9, DX = side.X, DZ = side.Z, Trail = true })
	end
	if V4 and f.Id == "3" then
		-- (v4) delfines junto a la superficie, sobre el veril
		local side = Vector3.new(dir.Z, 0, -dir.X)
		for k = 0, 2 do
			local p0 = f.Player + dir * (60 + k * 6) + side * (10 + k * 5)
			table.insert(big, { Piece = "Delfin", X = p0.X, Y = Ocean.Surface - 4 - k, Z = p0.Z, Length = 7.5, DX = -side.X, DZ = -side.Z, Trail = true })
		end
	end
	if V4 and f.Extra.Veril then
		-- (v4) a lo lejos, una ballena que pasa por el azul (SeaAmbient)
		table.insert(big, { Piece = "Ballena", X = f.Player.X + dir.X * 150 + dir.Z * 40, Y = f.Player.Y - 18, Z = f.Player.Z + dir.Z * 150 - dir.X * 40, Length = 34, DX = dir.Z, DZ = -dir.X })
	end
	local meters = Ocean.meters(f.Player.Y)
	local look = OceanBiomes.look(zone, meters, nil, f.Night)
	if f.Extra.Nacara then
		look = Nacara.lookNear(look, f.Player)
	end
	local lookOut = {}
	for k, v in look do
		lookOut[k] = if typeof(v) == "Color3" then color(v) else v
	end
	table.insert(result.Frames, {
		Id = f.Id,
		Name = f.Name,
		Zone = zone,
		Meters = meters,
		Night = f.Night,
		Player = { f.Player.X, f.Player.Y, f.Player.Z },
		Cam = { cam.X, cam.Y, cam.Z },
		Target = { f.Target.X, f.Target.Y, f.Target.Z },
		Look = lookOut,
		Caustics = (not before) and f.Night < 0.5 and meters < 12,
		Terrain = { X0 = x0, Z0 = z0, N = n, Step = STEP, H = heights, M = mats, Materials = matNames },
		Items = items,
		Fish = fish,
		Big = big,
		Rocks = rocks,
		Caves = caves,
		V4 = V4,
		Nacara = f.Extra.Nacara == true,
		Sand = { 204, 186, 146 },
	})
	print(("plano %s (%s): zona %s, %.1f m, %d mallas, %d peces"):format(f.Id, f.Name, tostring(zone), meters, #items, #fish))
end

fs.writeFile(out, serde.encode("json", result))
print("-> " .. out)
