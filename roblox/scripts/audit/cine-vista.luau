-- La VISTA DE LA CÁMARA de planos concretos de la auditoría de cinemáticas, dibujada con rayos contra el
-- mapa construido (las mismas piezas y el mismo terreno que mira scripts/lib/CinePlanos): una imagen
-- por plano (PPM; scripts/audit/cine-hoja.py las junta en hojas de contactos «antes / después»).
--
-- Uso (desde roblox/):
--   lune run scripts/audit/cine-vista.luau mapa.rbxl planos.json DIR [--antes] [--ancho 384]
--     planos.json: [ { "Escena": "Cole01_PrimerDia#24 Cole01_Bienvenida", "Plano": 3 }, … ]
--                  (el id de la escena y el número de plano, como en informe.txt)
--     --antes: con la cámara y el reparto del juego de antes (los rayos no veían la decoración sin
--              CanQuery: CinePlanos.QueryOnly)
--   Deja DIR/<n>.ppm y DIR/vistas.json (qué plano es cada imagen y sus fallos).
-- Colores: las piezas con su color y una luz de sol; el terreno verde (con la cámara dentro de una
-- pieza, todo a rayas de su color); quien tiene que salir en
-- naranja, tú en verde claro y los demás en azul; el cielo degradado.

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local E = require("../lib/CinePlanos")
local Geo = E.Geo
local V = roblox.Vector3.new

local args = process.args
local placePath, listPath, outDir = args[1], args[2], args[3]
assert(placePath and listPath and outDir, "uso: cine-vista.luau mapa.rbxl planos.json DIR [--antes]")
local W = 384
for i = 4, #args do
	if args[i] == "--antes" then
		E.QueryOnly = true
	elseif args[i] == "--ancho" then
		W = tonumber(args[i + 1]) or W
	end
end
local H = math.floor(W * 9 / 16)
fs.writeDir(outDir)

local wanted = serde.decode("json", fs.readFile(listPath))
local quests = {}
for _, w in wanted do
	quests[(w.Escena:match("^([^#]+)#"))] = true
end
local ctx = E.open(placePath)
-- (todas, como la auditoría: dónde acaba el jugador depende de las misiones de antes)
local scenes = E.collect(ctx)
local byId = {}
for _, scene in scenes do
	byId[scene.Id] = scene
end

local SUN = V(0.45, 0.8, 0.35).Unit
local function shade(color: any, n: any, dist: number): (number, number, number)
	local r, g, b = 0.6, 0.6, 0.6
	if color then
		r, g, b = color.R, color.G, color.B
	end
	local light = 0.38 + 0.62 * math.max(0, n:Dot(SUN))
	local fog = math.clamp((dist - 60) / 340, 0, 0.7)
	local sr, sg, sb = 0.72, 0.82, 0.95
	return (r * light) * (1 - fog) + sr * fog, (g * light) * (1 - fog) + sg * fog, (b * light) * (1 - fog) + sb * fog
end

-- (v130) Lo que el juego pone encima de las piezas y que el guion gráfico tiene que enseñar: la Grieta en
-- el cielo, las luces de cine (Rig), los fogonazos e impactos, las partículas del ambiente y la gradación
-- de color del momento (pista Light). Aproximado (no es el motor de Roblox), pero sirve para juzgar.
local function overlays(shot, cf: CFrame, tx: number, ty: number)
	local def = shot.HappeningId and E.HappeningIndex.get(shot.HappeningId)
	local resolve = shot.Resolve
	if not def or not resolve then
		return nil
	end
	local t0 = shot.At or 0
	local t1 = t0 + (shot.Duration or 1)
	local tm = (t0 + t1) / 2
	local function project(p: Vector3): (number?, number?, number?)
		local rel = cf:PointToObjectSpace(p)
		local depth = -rel.Z
		if depth <= 0.1 then
			return nil, nil, nil
		end
		return rel.X / (depth * tx), rel.Y / (depth * ty), depth
	end
	local function at(spec: any): Vector3?
		local name = if type(spec) == "table" then spec[1] else spec
		if type(name) ~= "string" then
			return nil
		end
		local ok, c = pcall(resolve, name)
		if not ok or not c then
			return nil
		end
		local off = if type(spec) == "table" and typeof(spec[2]) == "Vector3" then spec[2] else nil
		return if off then c:PointToWorldSpace(off) else c.Position
	end
	local o = { Lights = {}, Blobs = {}, Dots = {}, Crack = nil, Grade = nil }
	-- La Grieta: un ancla «Rift»
	for name, value in def.Anchors or {} do
		if value == "Rift" then
			local p = at(name)
			if p then
				local sx, sy = project(p)
				if sx then
					o.Crack = { sx, sy }
				end
			end
		end
	end
	local tracks = def.Tracks or {}
	for _, fx in tracks.Fx or {} do
		local recipe = E.FxCatalog.get(fx.Play)
		if recipe then
			local seconds = fx.Seconds or recipe.Seconds or 1.5
			if fx.At <= t1 and fx.At + seconds >= t0 then
				local base = at({ fx.Anchor or "Player", fx.Offset })
				if base then
					local params = fx.Params or {}
					local kind = recipe.Kind
					if kind == "Rig" then
						local off = params.Offset or recipe.Offset or V(0, 3, 0)
						local c = params.Color or recipe.Color
						table.insert(o.Lights, { P = base + off, C = c, B = (params.Brightness or recipe.Brightness or 2) * (if recipe.Burst then 1.5 else 1), R = params.Range or recipe.Range or 16 })
						if recipe.Burst then
							local sx, sy, d = project(base + off)
							if sx then
								table.insert(o.Blobs, { sx, sy, math.clamp(10 / d, 0.05, 0.6), c, 0.9 })
							end
						end
					elseif kind == "Ambient" and recipe.Texture == "Smoke" then
						-- (polvo y humo: una neblina sobre todo el plano, no puntos)
						o.Haze = math.min(0.3, (o.Haze or 0) + 0.12)
						o.HazeColor = recipe.Color
					elseif kind == "Ambient" then
						local size = params.Size or recipe.Size or V(30, 6, 30)
						local seed = #fx.Play * 97 + math.floor(fx.At * 10)
						local function rnd(): number
							seed = (seed * 1103515245 + 12345) % 2147483648
							return seed / 2147483648
						end
						for _ = 1, 70 do
							local p = base + V((rnd() - 0.5) * size.X, (recipe.Lift or 0) + rnd() * size.Y, (rnd() - 0.5) * size.Z)
							local sx, sy, d = project(p)
							if sx and math.abs(sx) < 1.1 and math.abs(sy) < 1.1 then
								table.insert(o.Dots, { sx, sy, math.clamp(0.35 / d, 0.003, 0.016), recipe.Color, recipe.Glow or 0, d })
							end
						end
					elseif kind == "Impact" or kind == "Burst" or kind == "Portal" or kind == "Orb" or kind == "Meteor" then
						-- (el tamaño de verdad del efecto en pantalla: ~16 studs por su escala; con el humo encima)
						local size = 16 * (tonumber(params.Scale) or 1)
						local sx, sy, d = project(base + V(0, size * 0.4, 0))
						if sx then
							local c = recipe.Color or recipe.Glow or roblox.Color3.new(1, 0.8, 0.5)
							table.insert(o.Blobs, { sx, sy, math.clamp(size / (d * ty), 0.03, 0.7), c, 1 })
							local hx, hy = project(base + V(0, size * 1.4, 0))
							if hx then
								table.insert(o.Blobs, { hx, hy, math.clamp(size * 1.3 / (d * ty), 0.03, 0.8), roblox.Color3.new(0.25, 0.22, 0.2), 0.7 })
							end
						end
					end
				end
			end
		end
	end
	-- Gradación: la última pista Light antes de la mitad del plano (o la luz automática de la escena)
	local grade = nil
	for _, l in tracks.Light or {} do
		if l.At <= tm then
			grade = l
		end
	end
	if grade and grade.Preset then
		local mood = E.CameraShots.light(grade.Preset)
		if mood then
			o.Grade = { Mood = mood, W = grade.Weight or 1 }
		end
	end
	return o
end

local function crackDistance(x: number, y: number, cx: number, cy: number): number
	-- Una raja en zigzag de lado a lado de la pantalla, alrededor de donde está la Grieta
	local best = math.huge
	local px, py = cx - 0.9, cy
	for k = 1, 12 do
		local nx = cx - 0.9 + k * 0.15
		local ny = cy + (if k % 2 == 0 then 0.06 else -0.05) * (1 + (k % 3) * 0.4)
		local ax, ay = nx - px, ny - py
		local len2 = ax * ax + ay * ay
		local t = math.clamp(((x - px) * ax + (y - py) * ay) / len2, 0, 1)
		local dx, dy = x - (px + ax * t), y - (py + ay * t)
		best = math.min(best, math.sqrt(dx * dx + dy * dy))
		px, py = nx, ny
	end
	return best
end

local function render(scene, shot, index: number): string
	local cf = shot.Cams[#shot.Cams]
	local fov = shot.Fov or 70
	local ty = math.tan(math.rad(fov) / 2)
	local tx = ty * 16 / 9
	local origin = cf.Position
	local look, right, up = cf.LookVector, cf.RightVector, cf.UpVector
	-- Personas como esferas (las de CameraShots.bodySpheres)
	local subjects = {}
	for _, id in shot.Subjects or {} do
		subjects[id] = true
	end
	local spheres = {}
	for id, p in shot.People or scene.People do
		local color = if subjects[id] then { 1, 0.55, 0.15 } elseif id == "Yo" then { 0.55, 0.95, 0.45 } else { 0.35, 0.55, 1 }
		for _, s in E.CameraShots.bodySpheres({ Head = E.head(p), Feet = p.Feet }) do
			table.insert(spheres, { C = s[1], R = s[2], Color = color })
		end
	end
	-- (con la cámara DENTRO de una pieza, la imagen se tiñe de su color a rayas: en el juego se ve la
	-- pieza cortada por el plano cercano —«aparecen paredes»—; los rayos que salen de dentro no la ven)
	local inside = ctx.World:inside(origin, Geo.Blocks, 0.05)
	local tint = inside and (inside.Color or { R = 0.5, G = 0.5, B = 0.5 })
	local ov = overlays(shot, cf, tx, ty)
	local out = table.create(W * H)
	for j = 0, H - 1 do
		local y = 1 - (j + 0.5) / H * 2
		for i = 0, W - 1 do
			local x = (i + 0.5) / W * 2 - 1
			local dir = (look + right * (x * tx) + up * (y * ty)).Unit
			local best, bestColor, bestN = 600, nil, nil
			local hit = ctx.World:raycast(origin, dir * 600, Geo.GameBlocks)
			if hit then
				best = hit.T
				local point = origin + dir * hit.T
				bestN = Geo.normalAt(hit.Part, point)
				if hit.Part.Terrain then
					bestColor = { R = 0.36, G = 0.55, B = 0.28 }
				else
					bestColor = hit.Part.Color
				end
			end
			local person = nil
			for _, s in spheres do
				local oc = origin - s.C
				local b = oc:Dot(dir)
				local c = oc:Dot(oc) - s.R * s.R
				local disc = b * b - c
				if disc >= 0 then
					local t = -b - math.sqrt(disc)
					if t > 0.05 and t < best then
						best, person = t, s
					end
				end
			end
			local r, g, b
			local world: Vector3? = if person or bestN then origin + dir * best else nil
			if person then
				local n = ((origin + dir * best) - person.C).Unit
				local light = 0.45 + 0.55 * math.max(0, n:Dot(SUN))
				r, g, b = person.Color[1] * light, person.Color[2] * light, person.Color[3] * light
			elseif bestN then
				r, g, b = shade(bestColor, bestN, best)
			else
				local t = math.clamp(dir.Y * 0.5 + 0.5, 0, 1)
				r, g, b = 0.75 - 0.35 * t, 0.84 - 0.25 * t, 0.97 - 0.05 * t
			end
			if ov then
				-- Luces de cine sobre lo que se ve
				if world then
					for _, l in ov.Lights do
						local d = (world - l.P).Magnitude
						if d < l.R then
							local k = (1 - d / l.R) ^ 2 * l.B * 0.1
							r, g, b = r + l.C.R * k, g + l.C.G * k, b + l.C.B * k
						end
					end
				elseif ov.Crack then
					-- La Grieta en el cielo
					local d = crackDistance(x, y, ov.Crack[1], ov.Crack[2])
					if d < 0.012 then
						r, g, b = 0.95, 1, 0.98
					elseif d < 0.08 then
						local k = (1 - d / 0.08) ^ 2
						r, g, b = r + (0.35 - r) * k, g + (1 - g) * k, b + (0.85 - b) * k
					end
				end
				for _, blob in ov.Blobs do
					local dx, dy = (x - blob[1]) * 16 / 9, y - blob[2]
					local d = math.sqrt(dx * dx + dy * dy)
					if d < blob[3] then
						local k = (1 - d / blob[3]) ^ 1.5 * blob[5]
						r, g, b = r + (blob[4].R + 0.3 - r) * k, g + (blob[4].G + 0.25 - g) * k, b + (blob[4].B + 0.2 - b) * k
					end
				end
				for _, dot in ov.Dots do
					if not world or dot[6] < best then
						local dx, dy = (x - dot[1]) * 16 / 9, y - dot[2]
						if dx * dx + dy * dy < dot[3] * dot[3] then
							local k = 0.8 + 0.2 * dot[5]
							r, g, b = r + (dot[4].R - r) * k, g + (dot[4].G - g) * k, b + (dot[4].B - b) * k
						end
					end
				end
				if ov.Haze then
					local hc = ov.HazeColor
					r, g, b = r + (hc.R - r) * ov.Haze, g + (hc.G - g) * ov.Haze, b + (hc.B - b) * ov.Haze
				end
				-- Gradación del momento
				local grade = ov.Grade
				if grade then
					local m, w = grade.Mood, grade.W
					if m.Tint then
						r, g, b = r * (1 + (m.Tint.R - 1) * w), g * (1 + (m.Tint.G - 1) * w), b * (1 + (m.Tint.B - 1) * w)
					end
					local e = 2 ^ ((m.Exposure or 0) * w)
					local c = 1 + (m.Contrast or 0) * w
					r, g, b = ((r * e) - 0.5) * c + 0.5, ((g * e) - 0.5) * c + 0.5, ((b * e) - 0.5) * c + 0.5
					local sat = 1 + (m.Saturation or 0) * w
					local lum = 0.3 * r + 0.59 * g + 0.11 * b
					r, g, b = lum + (r - lum) * sat, lum + (g - lum) * sat, lum + (b - lum) * sat
				end
			end
			if tint and ((i + j) // 6) % 2 == 0 then
				r, g, b = r * 0.35 + tint.R * 0.65, g * 0.35 + tint.G * 0.65, b * 0.35 + tint.B * 0.65
			end
			out[j * W + i + 1] = string.char(math.floor(math.clamp(r, 0, 1) * 255), math.floor(math.clamp(g, 0, 1) * 255), math.floor(math.clamp(b, 0, 1) * 255))
		end
	end
	local path = ("%s/%d.ppm"):format(outDir, index)
	fs.writeFile(path, ("P6\n%d %d\n255\n"):format(W, H) .. table.concat(out))
	return path
end

local meta = {}
for index, w in wanted do
	local scene = byId[w.Escena]
	if not scene then
		print("  ⚠ no está la escena " .. w.Escena)
		continue
	end
	E.audit(ctx, scene)
	local shot = scene.Shots[w.Plano]
	if not shot then
		print(("  ⚠ %s no tiene el plano %d"):format(w.Escena, w.Plano))
		continue
	end
	local problems = {}
	for _, p in shot.Problems or {} do
		if p.Kind ~= "Contraluz" then
			table.insert(problems, p.Kind .. ": " .. p.Detail)
		end
	end
	local path = render(scene, shot, index)
	table.insert(meta, { Imagen = path, Escena = w.Escena, Plano = w.Plano, Spec = shot.Spec, Fallos = problems, Linea = shot.Line })
	print(("  %d. %s · plano %d %s · %d fallos"):format(index, w.Escena, w.Plano, tostring(shot.Spec), #problems))
end
fs.writeFile(outDir .. "/vistas.json", serde.encode("json", meta))
print("  vistas: " .. outDir .. "/vistas.json")
