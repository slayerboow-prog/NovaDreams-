-- Auditoría VISUAL de las cinemáticas y conversaciones escenificadas (motor: scripts/lib/CinePlanos).
--
-- Con el mapa real construido, pone en escena cada conversación (StageDirector) y cada escena del motor
-- (Happenings) de cada misión, calcula cada plano (posición, orientación y campo de visión de la
-- cámara, quién tiene que salir) y comprueba:
--   CamaraDentro       la cámara está dentro de una pieza que se ve (pared, suelo, techo, coche…)
--   CamaraEnPersonaje  la cámara está dentro del cuerpo de alguien
--   BajoTierra         la cámara está por debajo del suelo donde están los personajes
--   Lejos / Pegada     a más de 70 studs del sujeto, o a menos de 1 de su cara
--   FueraDeCuadro      quien tiene que salir (quien habla, quien reacciona) no sale en pantalla
--   Tapado             sale, pero hay una pieza del mapa entre la cámara y su cabeza
--   TapadoPorPersona   sale, pero otro personaje se cruza entre la cámara y su cara
--   Atraviesa          un movimiento (dolly, travelling, pan) cruza una pared a mitad de recorrido
--   Salta180           dos planos seguidos de la misma pareja (hombro / dos) con la cámara a cada lado
--                      de la línea que les une (regla de los 180°)
--   Solapados          dos personas (actores o tú) metidas la una en la otra
--   Actor              un actor flotando, hundido o metido dentro de algo
--   Terreno            (aviso, no fallo) sin piezas debajo: el monte y la playa son terreno, que Lune
--                      no puede leer; esos sitios se revisan solo en parte
--
-- Uso (desde roblox/):
--   lune run scripts/audit/cine-planos.luau [mapa.rbxl] [--out DIR] [--quest Cole01] [--render N] [--antes]
--     mapa.rbxl: uno ya construido con
--       rojo build default.project.json -o X.rbxl && lune run scripts/build-place.luau X.rbxl
--     (sin él lo construye: ~3 min). --out: carpeta del informe (informe.txt) y de los datos para
--     dibujar (escenas.json); por defecto $TMPDIR/cineplanos. --render N: cuántas escenas BUENAS se
--     guardan para dibujar además de las que fallan (10). --antes: con el ajuste de cámara de antes de
--     CameraShots.fit (DialogueUI solo se acercaba a las paredes con choque; HappeningClient, nada).
-- Dibujar (3 vistas por plano: arriba, lado y la vista de la cámara):
--   python3 scripts/audit/cine-render.py DIR/escenas.json DIR/img

local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")

local E = require("../lib/CinePlanos")

local args = process.args
local placePath: string? = nil
local outDir = (process.env.TMPDIR or "/tmp") .. "/cineplanos"
local questFilter: string? = nil
local goodToRender = 10
local i = 1
while i <= #args do
	local a = args[i]
	if a == "--out" then
		outDir = args[i + 1]
		i += 1
	elseif a == "--quest" then
		questFilter = args[i + 1]
		i += 1
	elseif a == "--antes" then
		E.Legacy = true -- (imita el ajuste de cámara de antes de CameraShots.fit, para comparar)
	elseif a == "--render" then
		goodToRender = tonumber(args[i + 1]) or 10
		i += 1
	else
		placePath = a
	end
	i += 1
end
fs.writeDir(outDir)
placePath = placePath or E.buildMap(outDir)
local ctx = E.open(placePath :: string)

local t0 = os.clock()
local scenes = E.collect(ctx, if questFilter then function(id)
	return id:find(questFilter :: string, 1, true) ~= nil
end else nil)
print(("▶ %d escenas (%.1f s)"):format(#scenes, os.clock() - t0))

local totals = { Shots = 0, Bad = 0, Scenes = 0, BadScenes = 0 }
local byKind: { [string]: number } = {}
local byPreset: { [string]: { Total: number, Bad: number } } = {}
local lines = {}
local function out(s: string)
	table.insert(lines, s)
end
local badScenes, goodScenes = {}, {}
local notices = {} -- (avisos que no son fallos: terreno que Lune no ve)
for _, scene in scenes do
	E.audit(ctx, scene)
	totals.Scenes += 1
	local sceneBad = false
	local report = {}
	for _, p in scene.Problems do
		byKind[p.Kind] = (byKind[p.Kind] or 0) + 1
		table.insert(report, ("    · %s: %s"):format(p.Kind, p.Detail))
		if not E.Notices[p.Kind] then
			sceneBad = true
		end
	end
	for n, shot in scene.Shots do
		totals.Shots += 1
		local preset = (shot.Spec or "?"):match("^(%a+)") or "?"
		byPreset[preset] = byPreset[preset] or { Total = 0, Bad = 0 }
		byPreset[preset].Total += 1
		if #shot.Problems > 0 then
			totals.Bad += 1
			byPreset[preset].Bad += 1
			sceneBad = true
			for _, p in shot.Problems do
				byKind[p.Kind] = (byKind[p.Kind] or 0) + 1
				table.insert(report, ("    plano %d %s: %s · %s"):format(n, shot.Spec, p.Kind, p.Detail))
			end
		end
	end
	if not sceneBad and #report > 0 then
		table.insert(notices, ("ℹ %s (%s)"):format(scene.Id, scene.Kind))
		for _, r in report do
			table.insert(notices, r)
		end
	end
	if sceneBad then
		totals.BadScenes += 1
		table.insert(badScenes, scene)
		out(("✗ %s (%s, %d planos)"):format(scene.Id, scene.Kind, #scene.Shots))
		for _, r in report do
			out(r)
		end
	else
		table.insert(goodScenes, scene)
	end
end
print(("  revisadas en %.1f s"):format(os.clock() - t0))

local kinds = {}
for k in byKind do
	table.insert(kinds, k)
end
table.sort(kinds)
local summary = {
	("Escenas: %d (%d con algún fallo) · planos: %d (%d con fallo)"):format(totals.Scenes, totals.BadScenes, totals.Shots, totals.Bad),
}
for _, k in kinds do
	table.insert(summary, ("  %-18s %d%s"):format(k, byKind[k], if E.Notices[k] then "  (aviso: no es fallo)" else ""))
end
local presets = {}
for k in byPreset do
	table.insert(presets, k)
end
table.sort(presets)
table.insert(summary, "Por plano:")
for _, k in presets do
	table.insert(summary, ("  %-12s %4d planos, %3d con fallo"):format(k, byPreset[k].Total, byPreset[k].Bad))
end
for _, s in summary do
	print(s)
end
fs.writeFile(outDir .. "/informe.txt", table.concat(summary, "\n") .. "\n\n" .. table.concat(lines, "\n") .. "\n\n" .. table.concat(notices, "\n") .. "\n")
print("  informe: " .. outDir .. "/informe.txt")

---------------------------------------------------------------------
-- Datos para dibujar (cine-render.py): las escenas con fallos y una muestra de buenas
---------------------------------------------------------------------
local function v3(v)
	return { math.floor(v.X * 100) / 100, math.floor(v.Y * 100) / 100, math.floor(v.Z * 100) / 100 }
end
local function export(scene): { [string]: any }
	local people = {}
	for id, p in scene.People do
		table.insert(people, { Id = id, Feet = v3(p.Feet), Facing = v3(p.Facing), Scale = p.Scale })
	end
	local center = scene.Player.Feet
	local shots = {}
	for _, shot in scene.Shots do
		local cams = {}
		for _, cf in shot.Cams do
			table.insert(cams, { Pos = v3(cf.Position), Look = v3(cf.LookVector), Up = v3(cf.UpVector) })
		end
		local who = {}
		for id, p in shot.People or scene.People do
			table.insert(who, { Id = id, Feet = v3(p.Feet), Facing = v3(p.Facing), Scale = p.Scale })
		end
		table.insert(shots, { Spec = shot.Spec, Line = shot.Line, Fov = shot.Fov, Cams = cams, Subjects = shot.Subjects, Problems = shot.Problems, People = who })
	end
	local parts = {}
	for _, info in ctx.World:around(center, 45, E.blocks) do
		local cf = info.CFrame
		table.insert(parts, {
			P = v3(cf.Position),
			R = { cf.RightVector.X, cf.RightVector.Y, cf.RightVector.Z, cf.UpVector.X, cf.UpVector.Y, cf.UpVector.Z, -cf.LookVector.X, -cf.LookVector.Y, -cf.LookVector.Z },
			S = v3(info.Size),
			N = info.Name,
			Sh = info.Shape,
		})
		if #parts > 6000 then
			break
		end
	end
	return { Id = scene.Id, Kind = scene.Kind, Problems = scene.Problems, People = people, Shots = shots, Parts = parts, Center = v3(center) }
end
local data = {}
for _, scene in badScenes do
	table.insert(data, export(scene))
end
-- (la muestra de buenas: repartida por toda la lista, siempre las mismas)
local step = math.max(1, math.floor(#goodScenes / math.max(goodToRender, 1)))
local taken = 0
for k = 1, #goodScenes, step do
	if taken >= goodToRender then
		break
	end
	local item = export(goodScenes[k])
	item.Good = true
	table.insert(data, item)
	taken += 1
end
fs.writeFile(outDir .. "/escenas.json", serde.encode("json", data))
print(("  datos para dibujar: %s/escenas.json (%d escenas)"):format(outDir, #data))
