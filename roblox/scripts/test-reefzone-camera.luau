-- Revisión «desde la cámara del jugador» de la zona de referencia del mar (Cañón de Dorada,
-- shared/Sea/ReefZone; encargo v2 del dueño, fase 4). FUERA de Roblox, con Lune.
--
-- No podemos hacer capturas de Roblox desde aquí, así que se mide lo que vería la cámara: desde cada
-- cámara de ReefZone.Cameras (donde va a estar el jugador, a la altura de la cámara de tercera persona)
-- se lanza una rejilla de rayos de pantalla (campo de visión de 70° en vertical, pantalla de móvil
-- apaisada) contra la MISMA geometría que construye el juego (el fondo de shared/Sea/Ocean + las
-- operaciones de terreno de ReefZone en orden + las piezas del kit como volúmenes). Cada rayo cae en:
--   suelo     una superficie plana y horizontal (el lecho, arena) sin nada encima
--   formación una pared, saliente, arco, columna, aguja, repisa o roca
--   vida      una pieza del kit (coral, kelp, setas de luz, ruinas…)
--   agua      nada en la distancia que deja ver el agua (Visibilidad: el horizonte vacío)
-- y por distancia: cerca (< 25), medio (25-90), lejos (90-Visibilidad).
--
-- Lo que se exige (encargo §3, §6 y §13): en ninguna vista el suelo pasa del 60 % de la pantalla; la
-- franja del horizonte (el tercio del medio) nunca está vacía (al menos un 25 % de sus rayos chocan con
-- formaciones o vida, no con suelo ni agua); en cada vista hay cosas en al menos dos de los tres planos (cerca, medio, lejos); y en el
-- conjunto de vistas hay de todo (formaciones y vida).
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-reefzone-camera.luau                (prueba)
--   lune run scripts/test-reefzone-camera.luau --json FILE    (además, las cámaras y la geometría para
--                                                               las vistas previas de Blender)

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
local L = require("./lib/ModuleLoader")

local Ocean = L.load("src/shared/Sea/Ocean")
local ReefZone = L.load("src/shared/Sea/ReefZone")
local MarKit = L.load("src/shared/Sea/MarKit")

local failures = 0
local function check(ok: any, what: string)
	if ok then
		print("  ✅ " .. what)
	else
		failures += 1
		print("  ❌ " .. what)
	end
end

local sqrt, floor, rad, cos, sin, tan, abs = math.sqrt, math.floor, math.rad, math.cos, math.sin, math.tan, math.abs

-- El fondo (Ocean.floorY) con caché cada 2 studs (es caro: mira toda la costa)
local floorCache: { [number]: number | boolean } = {}
local function floorY(x: number, z: number): number?
	local gx, gz = floor(x / 2 + 0.5), floor(z / 2 + 0.5)
	local key = gx * 100000 + gz
	local v = floorCache[key]
	if v == nil then
		local f = Ocean.floorY(gx * 2, gz * 2)
		v = if f then f else false
		floorCache[key] = v
	end
	return if v == false then nil else v :: number
end

-- Las piezas del kit como volúmenes sencillos (cilindros verticales; la pirámide, una pirámide)
local placements = ReefZone.placements(floorY)
local DGRID = 16
local decorGrid: { [number]: { any } } = {}
for _, p in placements do
	local info = MarKit.Pieces[p.Kind]
	local size = info and info.Size or { 1, 1, 1 }
	local k = p.Scale / size[2]
	local r = math.max(size[1], size[3]) * k * 0.5 * (info and info.Fill or 0.6)
	local vol = { X = p.X, Y = p.Y, Z = p.Z, R = r, H = p.Scale, Pyramid = p.Kind == "Piramide", Half = size[1] * k * 0.5 }
	for gx = floor((p.X - r) / DGRID), floor((p.X + r) / DGRID) do
		for gz = floor((p.Z - r) / DGRID), floor((p.Z + r) / DGRID) do
			local key = gx * 4096 + gz
			decorGrid[key] = decorGrid[key] or {}
			table.insert(decorGrid[key], vol)
		end
	end
end
local function decorAt(x: number, y: number, z: number): boolean
	local list = decorGrid[floor(x / DGRID) * 4096 + floor(z / DGRID)]
	if not list then
		return false
	end
	for _, v in list do
		if y >= v.Y and y <= v.Y + v.H then
			if v.Pyramid then
				local half = v.Half * (1 - (y - v.Y) / v.H)
				if abs(x - v.X) <= half and abs(z - v.Z) <= half then
					return true
				end
			else
				local dx, dz = x - v.X, z - v.Z
				if dx * dx + dz * dz <= v.R * v.R then
					return true
				end
			end
		end
	end
	return false
end

local VIS = 200 -- lo que deja ver el agua de la orilla con la luz nueva (OceanBiomes: Visibility)
local COLS, ROWS = 44, 20 -- rejilla de rayos (pantalla de móvil apaisada ≈ 2,17:1)
local FOV = rad(70)
local ASPECT = 2.17

local function classify(x: number, y: number, z: number, tag: string): string
	if tag == "Bed" or tag == "Patch" or tag == "Plateau" or tag == "Bommie" or tag == "Ledge" then
		-- ¿plano y abierto? (nada sólido alrededor un poco más arriba)
		local open = true
		for _, o in { { 3, 0 }, { -3, 0 }, { 0, 3 }, { 0, -3 } } do
			if ReefZone.solid(x + o[1], y + 1.2, z + o[2], floorY) then
				open = false
				break
			end
		end
		if open and (tag == "Bed" or tag == "Patch") then
			return "suelo"
		elseif open then
			return "suelo" -- (la cima plana de una meseta también es «suelo»)
		end
	end
	return "formacion"
end

local function cast(ox: number, oy: number, oz: number, dx: number, dy: number, dz: number): (string, number)
	local d = 0.5
	while d < VIS do
		local step = if d < 30 then 0.8 elseif d < 90 then 1.6 else 3
		d += step
		local x, y, z = ox + dx * d, oy + dy * d, oz + dz * d
		if y > ReefZone.Surface then
			-- (la superficie del agua desde abajo: espejo azul, no cuenta como «vacío» ni como suelo)
			return "superficie", d
		end
		if decorAt(x, y, z) then
			return "vida", d
		end
		local solid, _, tag = ReefZone.solid(x, y, z, floorY)
		if solid then
			return classify(x, y, z, tag), d
		end
	end
	return "agua", VIS
end

local cameras = ReefZone.Cameras
local results = {}
local totals = { suelo = 0, formacion = 0, vida = 0, agua = 0, superficie = 0 }
print("▶ Revisión desde la cámara (rejilla de " .. COLS .. "×" .. ROWS .. " rayos por vista, visibilidad " .. VIS .. " studs)")
print("   vista                              suelo  forma  vida  agua  sup | cerca medio lejos | horizonte*")
for _, cam in cameras do
	local yaw, pitch = rad(cam.Yaw), rad(cam.Pitch)
	-- base de la cámara: adelante (yaw 0 = +X), derecha y arriba
	local fx, fy, fz = cos(pitch) * cos(yaw), sin(pitch), cos(pitch) * sin(yaw)
	local rx, rz = -sin(yaw), cos(yaw) -- derecha (en horizontal)
	local ux, uy, uz = -sin(pitch) * cos(yaw), cos(pitch), -sin(pitch) * sin(yaw)
	local counts = { suelo = 0, formacion = 0, vida = 0, agua = 0, superficie = 0 }
	local planes = { cerca = 0, medio = 0, lejos = 0 }
	local band, bandHit = 0, 0
	local th = tan(FOV / 2)
	for j = 0, ROWS - 1 do
		local v = (1 - (j + 0.5) / ROWS * 2) * th
		for i = 0, COLS - 1 do
			local u = ((i + 0.5) / COLS * 2 - 1) * th * ASPECT
			local dx, dy, dz = fx + rx * u + ux * v, fy + uy * v, fz + rz * u + uz * v
			local m = sqrt(dx * dx + dy * dy + dz * dz)
			dx, dy, dz = dx / m, dy / m, dz / m
			local kind, dist = cast(cam.X, cam.Y, cam.Z, dx, dy, dz)
			counts[kind] += 1
			if kind ~= "agua" and kind ~= "superficie" then
				if dist < 25 then
					planes.cerca += 1
				elseif dist < 90 then
					planes.medio += 1
				else
					planes.lejos += 1
				end
			end
			if j >= ROWS / 3 and j < ROWS * 2 / 3 then
				band += 1
				if kind == "formacion" or kind == "vida" then
					bandHit += 1
				end
			end
		end
	end
	local n = COLS * ROWS
	local function pct(v: number): number
		return v / n * 100
	end
	for k, v in counts do
		totals[k] += v
	end
	local filled = 0
	for _, v in planes do
		if v >= n * 0.04 then
			filled += 1
		end
	end
	local r = { Name = cam.Name, Floor = pct(counts.suelo), Form = pct(counts.formacion), Life = pct(counts.vida), Water = pct(counts.agua), Surf = pct(counts.superficie), Near = pct(planes.cerca), Mid = pct(planes.medio), Far = pct(planes.lejos), Horizon = bandHit / band * 100, Planes = filled }
	table.insert(results, r)
	print(("   %-34s %5.0f%% %5.0f%% %4.0f%% %4.0f%% %4.0f%% | %4.0f%% %5.0f%% %5.0f%% | %4.0f%%"):format(r.Name, r.Floor, r.Form, r.Life, r.Water, r.Surf, r.Near, r.Mid, r.Far, r.Horizon))
end

-- Antes (para comparar): la orilla como en la v123, solo el fondo (sin la zona), desde la llegada al
-- jardín y desde otro jardín de la orilla (el del Faro) mirando al mar. (El decorado pequeño de SeaBiome
-- no se cuenta: era de 1 a 3 studs de alto.)
do
	local function castFlat(ox, oy, oz, dx, dy, dz): (string, number)
		local d = 0.5
		while d < VIS do
			d += if d < 30 then 0.8 elseif d < 90 then 1.6 else 3
			local x, y, z = ox + dx * d, oy + dy * d, oz + dz * d
			if y > ReefZone.Surface then
				return "superficie", d
			end
			local f = floorY(x, z)
			if f == nil or y <= f then
				return "suelo", d
			end
		end
		return "agua", VIS
	end
	print("\n▶ Antes (v123: la orilla solo con su fondo llano), para comparar")
	for _, cam in { { Name = "Llegada al jardín (antes)", X = 4262, Y = -6, Z = -300, Yaw = 0, Pitch = -14 }, { Name = "Jardín del Faro (antes)", X = 4000, Y = -6, Z = 1220, Yaw = 0, Pitch = -14 } } do
		local yaw, pitch = rad(cam.Yaw), rad(cam.Pitch)
		local fx, fy, fz = cos(pitch) * cos(yaw), sin(pitch), cos(pitch) * sin(yaw)
		local rx, rz = -sin(yaw), cos(yaw)
		local ux, uy, uz = -sin(pitch) * cos(yaw), cos(pitch), -sin(pitch) * sin(yaw)
		local th = tan(FOV / 2)
		local n, floorN, band, bandHit = 0, 0, 0, 0
		for j = 0, ROWS - 1 do
			local v = (1 - (j + 0.5) / ROWS * 2) * th
			for i = 0, COLS - 1 do
				local u = ((i + 0.5) / COLS * 2 - 1) * th * ASPECT
				local dx, dy, dz = fx + rx * u + ux * v, fy + uy * v, fz + rz * u + uz * v
				local m = sqrt(dx * dx + dy * dy + dz * dz)
				local kind = castFlat(cam.X, cam.Y, cam.Z, dx / m, dy / m, dz / m)
				n += 1
				if kind == "suelo" then
					floorN += 1
				end
				if j >= ROWS / 3 and j < ROWS * 2 / 3 then
					band += 1
					if kind ~= "agua" and kind ~= "suelo" then
						bandHit += 1
					end
				end
			end
		end
		print(("   %-34s suelo %3.0f%% · formaciones 0%% · horizonte con formaciones o vida: %3.0f%%"):format(cam.Name, floorN / n * 100, bandHit / band * 100))
	end
end

print("\n▶ Lo que se exige")
do
	local bad = {}
	for _, cam in cameras do
		local clear = not ReefZone.solid(cam.X, cam.Y, cam.Z, floorY)
		for _, o in { { 2.5, 0, 0 }, { -2.5, 0, 0 }, { 0, 2.5, 0 }, { 0, -2.5, 0 }, { 0, 0, 2.5 }, { 0, 0, -2.5 } } do
			if ReefZone.solid(cam.X + o[1], cam.Y + o[2], cam.Z + o[3], floorY) then
				clear = false
			end
		end
		if not clear then
			table.insert(bad, cam.Name)
		end
	end
	check(#bad == 0, "Cada cámara está en el agua, donde puede estar el jugador (no dentro de la roca)" .. (if #bad > 0 then ": " .. table.concat(bad, ", ") else ""))
end
local worstFloor, worstFloorName, worstHorizon, worstHorizonName = 0, "", 100, ""
local planesOk = true
for _, r in results do
	if r.Floor > worstFloor then
		worstFloor, worstFloorName = r.Floor, r.Name
	end
	if r.Horizon < worstHorizon then
		worstHorizon, worstHorizonName = r.Horizon, r.Name
	end
	if r.Planes < 2 then
		planesOk = false
		print("   (" .. r.Name .. ": solo " .. r.Planes .. " plano con cosas)")
	end
end
check(worstFloor <= 60, ("En ninguna vista el suelo plano pasa del 60 %% de la pantalla (lo más: %.0f %% en «%s»)"):format(worstFloor, worstFloorName))
check(worstHorizon >= 25, ("El horizonte nunca está vacío: en la franja del medio, al menos un 25 %% de los rayos chocan con formaciones o vida (no con suelo ni agua) (lo menos: %.0f %% en «%s»)"):format(worstHorizon, worstHorizonName))
check(planesOk, "En cada vista hay cosas en al menos dos de los tres planos (cerca, medio, lejos)")
local all = 0
for _, v in totals do
	all += v
end
check(totals.formacion / all > 0.25 and totals.vida / all > 0.06, ("En el conjunto hay formaciones grandes (%.0f %%) y vida (%.0f %%), no solo suelo (%.0f %%)"):format(totals.formacion / all * 100, totals.vida / all * 100, totals.suelo / all * 100))

-- Para Blender: las cámaras, el fondo alrededor, las operaciones y las piezas
local args = process.args
for i, a in args do
	if a == "--json" and args[i + 1] then
		local grid = {}
		local box = ReefZone.Box
		local step = 4
		for z = box.MinZ - 120, box.MaxZ + 120, step do
			local row = {}
			for x = box.MinX - 60, box.MaxX + 260, step do
				table.insert(row, floorY(x, z) or 6)
			end
			table.insert(grid, row)
		end
		local ops = {}
		for _, op in ReefZone.ops() do
			table.insert(ops, { Kind = op.Kind, X = op.X, Y = op.Y, Z = op.Z, R = op.R, H = op.H, SX = op.SX, SY = op.SY, SZ = op.SZ, Yaw = op.Yaw, Material = op.Material, Tag = op.Tag })
		end
		local out = {
			Cameras = cameras,
			Grid = { X0 = box.MinX - 60, Z0 = box.MinZ - 120, Step = step, Rows = grid },
			Ops = ops,
			Placements = placements,
			Lights = ReefZone.Lights,
			Shafts = ReefZone.Shafts,
			Results = results,
			Axis = (function()
				local t = {}
				for x = 4250, 4900, 10 do
					local bed = ReefZone.bedAt(x)
					table.insert(t, { x, ReefZone.axisZ(x), bed })
				end
				return t
			end)(),
		}
		-- dónde está cada cosa en ReefZone.where (luces, haces)
		for _, list in { out.Lights, out.Shafts } do
			for _, l in list do
				local x, z = ReefZone.where(l)
				l.WX, l.WZ = x, z
			end
		end
		fs.writeFile(args[i + 1], serde.encode("json", out))
		print("\n📄 " .. args[i + 1])
	end
end

---------------------------------------------------------------------
-- v126: las ORILLAS (shared/Sea/ShoreReef) desde la cámara del jugador, en 5 playas
---------------------------------------------------------------------
print("\n▶ v126: cinco playas desde la cámara del móvil (relieve del terreno + lo que planta el móvil con su LOD)")
do
	local ShoreReef = L.load("src/shared/Sea/ShoreReef")
	ShoreReef.Memo = {}
	local C = ShoreReef.Cell
	local hcache: { [number]: number } = {}
	local function ground(x: number, z: number): (number?, number?)
		local gx, gz = floor(x / 2 + 0.5), floor(z / 2 + 0.5)
		local key = gx * 100000 + gz
		local base = floorY(gx * 2, gz * 2)
		if not base then
			return nil, nil
		end
		local v = hcache[key]
		if v == nil then
			v = ShoreReef.heightAt(gx * 2, gz * 2, base)
			hcache[key] = v
		end
		return v, base
	end
	local worstFlat, worstHz, rows = 0, 100, {}
	for i = 2, 6 do
		local r = Ocean.ShoreReefs[i]
		local nx, nz = ShoreReef.seaward(r.X, r.Z)
		-- el jugador a 2–4 m sobre el fondo mirando a lo largo de la costa y algo hacia fuera
		local px, pz = r.X - nx * 10, r.Z - nz * 10
		local pfloor = ground(px, pz) or -14
		local py = math.min(pfloor + 8, Ocean.Surface - 4)
		local lx, lz = -nz + nx * 0.6, nx + nz * 0.6
		local m = sqrt(lx * lx + lz * lz)
		lx, lz = lx / m, lz / m
		local cam = { X = px - lx * 11, Y = py + 3, Z = pz - lz * 11 }
		-- lo que plantaría el móvil (cilindros con el alto de la pieza y su huella)
		local grid: { [number]: { any } } = {}
		local cx, cz = floor(cam.X / C), floor(cam.Z / C)
		for ix = cx - 6, cx + 6 do
			for iz = cz - 6, cz + 6 do
				for _, it in ShoreReef.decor(ix, iz, ShoreReef.Density.Mobile) do
					local d = sqrt((it.X - cam.X) ^ 2 + (it.Z - cam.Z) ^ 2)
					if ShoreReef.visible(it, d, true) then
						-- (v4: la morena asomada es de la fauna)
						local info = MarKit.Pieces[it.Piece] or L.load("src/shared/Sea/MarFauna").Pieces[it.Piece]
						local k = it.H / info.Size[2]
						local rad0 = math.max(info.Size[1], info.Size[3]) * k * 0.35
						local g = ground(it.X, it.Z) or -14
						local key = floor(it.X / 8) * 100000 + floor(it.Z / 8)
						grid[key] = grid[key] or {}
						table.insert(grid[key], { X = it.X, Z = it.Z, R = rad0, Y0 = g + it.Lift, Y1 = g + it.Lift + it.H })
					end
				end
			end
		end
		local COLS2, ROWS2, VIS2 = 32, 18, 150
		local fy = tan(rad(35))
		local fx = fy * 16 / 9
		local count = { suelo = 0, forma = 0, vida = 0, agua = 0, sup = 0 }
		local hz, hzHit = 0, 0
		for row = 0, ROWS2 - 1 do
			for col = 0, COLS2 - 1 do
				local u = ((col + 0.5) / COLS2 * 2 - 1) * fx
				local v = (1 - (row + 0.5) / ROWS2 * 2) * fy
				-- la cámara mira hacia el jugador, algo hacia abajo
				local pitch = -0.18
				local dy = v * cos(pitch) + sin(pitch)
				local fwd = cos(pitch) - v * sin(pitch)
				local dx, dz = lx * fwd + lz * u, lz * fwd - lx * u
				local len = sqrt(dx * dx + dy * dy + dz * dz)
				dx, dy, dz = dx / len, dy / len, dz / len
				local hit = "agua"
				local t = 1
				while t < VIS2 do
					local x, y, z = cam.X + dx * t, cam.Y + dy * t, cam.Z + dz * t
					if y > Ocean.Surface then
						hit = "sup"
						break
					end
					local key = floor(x / 8) * 100000 + floor(z / 8)
					local cell = grid[key]
					local found = false
					if cell then
						for _, c in cell do
							if y >= c.Y0 and y <= c.Y1 and (x - c.X) ^ 2 + (z - c.Z) ^ 2 <= c.R * c.R then
								found = true
								break
							end
						end
					end
					if found then
						hit = "vida"
						break
					end
					local g, base = ground(x, z)
					if g and y <= g then
						hit = if base and g - base > 0.8 then "forma" else "suelo"
						break
					end
					t += if t < 30 then 0.7 else 1.5
				end
				count[hit] += 1
				if row >= ROWS2 / 3 and row < ROWS2 * 2 / 3 then
					hz += 1
					if hit == "vida" or hit == "forma" then
						hzHit += 1
					end
				end
			end
		end
		local total = COLS2 * ROWS2
		local flat = count.suelo / total * 100
		local hzp = hzHit / hz * 100
		worstFlat = math.max(worstFlat, flat)
		worstHz = math.min(worstHz, hzp)
		table.insert(rows, ("   %-38s suelo %3.0f %% · relieve %3.0f %% · vida %3.0f %% · agua %3.0f %% | horizonte %3.0f %%"):format(r.Name, flat, count.forma / total * 100, count.vida / total * 100, (count.agua + count.sup) / total * 100, hzp))
	end
	for _, line in rows do
		print(line)
	end
	check(worstFlat <= 55, ("En ninguna playa el suelo liso pasa del 55 %% de la pantalla (lo más: %.0f %%)"):format(worstFlat))
	check(worstHz >= 20, ("En la franja del medio, al menos un 20 %% de los rayos dan en relieve o vida (lo menos: %.0f %%)"):format(worstHz))
	ShoreReef.Memo = nil
end

if failures > 0 then
	print(("\n❌ %d comprobaciones fallidas"):format(failures))
	process.exit(1)
end
print("\n✅ La zona se ve llena desde la cámara del jugador (prueba por rayos; la de verdad es en el móvil)")
