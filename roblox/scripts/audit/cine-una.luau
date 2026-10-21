-- cine-una: la auditoría de planos (scripts/lib/CinePlanos) de UNA misión, con el detalle de cada plano
-- (cámara, foco, personas y fallos). Para arreglar un caso concreto de test-cineplanos sin esperar a todas.
--
-- Uso (desde roblox/):  lune run scripts/audit/cine-una.luau <Misión> [mapa.rbxl]
--   (sin mapa: el de la caché de test-cineplanos, o lo construye)

local process = require("@lune/process")

local E = require("../lib/CinePlanos")

local questId = process.args[1] or error("falta la misión (p. ej. Mar_03_Juicio)")
local placePath = process.args[2] or process.env.CINEPLANOS_MAPA or E.buildMap()
local ctx = E.open(placePath)
local scenes = E.collect(ctx, function(id)
	return id == questId
end)
local function v3(v: any): string
	if typeof(v) == "Vector3" then
		return ("(%.1f, %.1f, %.1f)"):format(v.X, v.Y, v.Z)
	end
	return tostring(v)
end
for _, scene in scenes do
	E.audit(ctx, scene)
	print(("== %s"):format(scene.Id))
	for _, problem in scene.Problems or {} do
		print(("   escena: %s · %s"):format(problem.Kind, problem.Detail))
	end
	for i, shot in scene.Shots do
		local cams = shot.Cams or {}
		local last = cams[#cams]
		print(("  %d. %s  cámara %s  foco %s"):format(i, tostring(shot.Spec), if last then v3(last.Position) else "-", v3(shot.Focus)))
		for _, problem in shot.Problems do
			print(("     ✗ %s · %s"):format(problem.Kind, problem.Detail))
		end
	end
	for id, p in scene.People or {} do
		print(("   %s: pies %s"):format(id, v3(p.Feet)))
	end
	for id, p in scene.Actors or {} do
		print(("   actor %s: pies %s · marca %s"):format(id, v3(p.Feet), v3(p.Mark)))
	end
end
