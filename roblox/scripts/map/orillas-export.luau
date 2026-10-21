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
ShoreReef.Memo = {}

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
	local target = player + Vector3.new(lx, 0, lz) * 9 + Vector3.new(0, 0.5, 0)
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
	frame("2", "Arrecife, 6 m", reefPlayer, reefLX, reefLZ, 0)
end
do -- 3 · Repisa y caída a 15 m (el borde de la plataforma frente a Levante)
	local nx0, nz0 = ShoreReef.seaward(4107, -1772)
	local f = find(4107 + nx0 * 360, -1772 + nz0 * 360, 260, function(p)
		return p.Kind == "Ledge" and p.Floor ~= nil
	end)
	local p = f.P
	local nx, nz = ShoreReef.seaward(p.X, p.Z)
	frame("3", "Repisa y caída, 13 m", Vector3.new(p.X - nx * 16, p.Floor + 9, p.Z - nz * 16), nx + nz * 0.25, nz - nx * 0.25, 0, { Manta = true })
end
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
do -- 5 · Llegada a Nácara
	local c = Nacara.centerPosition()
	local f = find(c.X + 80, c.Z - 90, 120, function(p)
		return p.Kind ~= nil and sqrt((p.X - c.X) ^ 2 + (p.Z - c.Z) ^ 2) > 105
	end)
	local p = f.P
	frame("5", "Llegada a Nácara, 37 m", Vector3.new(p.X, Nacara.FloorY + 14, p.Z), c.X - p.X, c.Z - p.Z, 0, { Nacara = true })
end
-- 6 · El arrecife de noche
frame("6", "El arrecife de noche", reefPlayer, reefLX, reefLZ, 1)

---------------------------------------------------------------------
-- Volcar cada plano
---------------------------------------------------------------------
local AREA, STEP = 300, 2
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
				y, mat = ShoreReef.surfaceAt(x, z, fy, base)
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
		for i = 1, math.min(3, #reefs) do
			local r = reefs[i]
			school(Vector3.new(r[1], r[2] + 5, r[3]), reefSpecies[1 + (i - 1) % #reefSpecies], 10, 1.2)
		end
	end
	-- (y un banco de peces de banco por delante de la cámara)
	school(f.Player + dir * 26 + Vector3.new(4, 2, 0), "PezBanco", 10, 1.0)
	local big = {}
	if f.Extra.Manta then
		table.insert(big, { Piece = "Manta", X = f.Player.X + dir.X * 40, Y = f.Player.Y + 6, Z = f.Player.Z + dir.Z * 40, Length = 7, DX = dir.Z, DZ = -dir.X })
	end
	if f.Id == "2" or f.Id == "6" then
		table.insert(big, { Piece = "Tortuga", X = f.Player.X + dir.X * 55 + 14, Y = f.Player.Y + 3, Z = f.Player.Z + dir.Z * 55, Length = 3.6, DX = -dir.Z, DZ = dir.X })
	end
	if f.Id == "6" then
		table.insert(big, { Piece = "Medusa", X = f.Player.X + dir.X * 18 - 5, Y = f.Player.Y + 4, Z = f.Player.Z + dir.Z * 18, Length = 1.8, DX = 1, DZ = 0, Glow = true })
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
		Nacara = f.Extra.Nacara == true,
		Sand = { 204, 186, 146 },
	})
	print(("plano %s (%s): zona %s, %.1f m, %d mallas, %d peces"):format(f.Id, f.Name, tostring(zone), meters, #items, #fish))
end

fs.writeFile(out, serde.encode("json", result))
print("-> " .. out)
