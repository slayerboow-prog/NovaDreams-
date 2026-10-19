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
