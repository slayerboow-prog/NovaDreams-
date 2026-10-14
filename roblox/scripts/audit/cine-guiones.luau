-- Auditoría visual SOLO de las escenas de los guiones reescritos (Guiones/*): qué plano falla y por qué.
-- Uso (desde roblox/): lune run scripts/audit/cine-guiones.luau [mapa.rbxl]   (o CINEPLANOS_MAPA=ruta)
local process = require("@lune/process")
local E = require("../lib/CinePlanos")

local placePath = nil
for _, a in process.args do
	if a:match("%.rbxl$") then
		placePath = a
	end
end
placePath = placePath or process.env.CINEPLANOS_MAPA or E.buildMap()
local ctx = E.open(placePath)
local bad = 0
for _, scene in E.collect(ctx) do
	if scene.Id:find("_G") then
		E.audit(ctx, scene)
		for i, shot in scene.Shots do
			for _, problem in shot.Problems do
				bad += 1
				print(("%s · plano %d (%s, At %s): %s · %s"):format(scene.Id, i, tostring(shot.Spec), tostring(shot.At or (shot.Shot and shot.Shot.At)), problem.Kind, problem.Detail))
			end
		end
	end
end
print(("%d problemas"):format(bad))
