-- Varkun: el PRÓLOGO de la historia del espacio, «La costura negra» (docs/universo/diseno-espacio.md §2;
-- villano aprobado por el dueño). Cuentas puras: lo usan Services/VarkunService (servidor: pone los sitios
-- en el mundo y avisa a la historia) y scripts/test-varkun.luau.
--
-- Dos misiones del motor de historia (shared/LifeStory/Misiones/Saga2_Prologo.luau) con pasos «Event»:
--   Varkun_01_Costura «La costura negra»: la radio de una estación capta una señal de socorro →
--     1 Wreck     llegar al carguero destrozado de la Ruta de los Saqueadores
--     2 Ambush    derribar a las 3 Agujas de los Hilanderos que lo vigilan
--     3 Delivered atracar en la Estación Cénit con el carrete de hilo negro
--     4 Vault     el carrete se guarda en la caja fuerte (pasa solo VaultSeconds después de atracar,
--                 mientras suenan las frases; si sales antes, pasa al volver a atracar o a volar)
--   Varkun_02_Escarcha «Ruido en la Escarcha»: al volver a atracar, NILDA oye el carrete «cantar» →
--     1 Anomaly   llegar a la anomalía de hilo encima de la Nube Escarcha
--     2 Scanned   quedarse dentro ScanSeconds mientras NILDA la escanea
--     3 Rueca     la Rueca de Varkun aparece al fondo: aguantar RuecaSeconds (o derribar a los suyos)
--     4 Calma     la Rueca se ha ido: pasa solo CalmSeconds después (mientras suenan las frases)
-- El servidor manda los sucesos con StoryEvents: «VarkunSignal» { Part = 1 | 2 } (ofrece la misión, al
-- atracar) y «VarkunStep» { Step = "Wreck" | … }. La historia (LifeStoryService) avanza los pasos.

local Stations = require(script.Parent.Stations)

local Varkun = {}

Varkun.Missions = { "Varkun_01_Costura", "Varkun_02_Escarcha" }
Varkun.Steps = {
	Varkun_01_Costura = { "Wreck", "Ambush", "Delivered", "Vault" },
	Varkun_02_Escarcha = { "Anomaly", "Scanned", "Rueca", "Calma" },
}
-- (los pasos que se cumplen solos al rato, para que suenen las frases del final sin quitar el control)
Varkun.Auto = {
	Vault = 20,
	Calma = 20,
}

-- Sitios (dentro de la columna del espacio; fuera de zonas seguras y de las rocas)
Varkun.WreckPos = Vector3.new(1500, 7350, 2900) -- (en la Ruta de los Saqueadores)
Varkun.WreckRadius = 320
Varkun.AmbushRange = 1500 -- las Agujas salen si estás a menos de esto del carguero
Varkun.AmbushKinds = { "Aguja", "Aguja", "Aguja" }
Varkun.DeliverStation = "Cenit"

Varkun.AnomalyPos = Vector3.new(-600, 7700, -4300) -- (encima de la Nube Escarcha)
Varkun.AnomalyRadius = 260
Varkun.ScanRadius = 420
Varkun.ScanSeconds = 20
Varkun.RuecaPos = Vector3.new(-900, 8100, -6500) -- (al fondo, más allá de la Escarcha)
Varkun.RuecaRadius = 360
Varkun.RuecaSeconds = 35
Varkun.RuecaKinds = { "Aguja", "Aguja", "Pesada" }
Varkun.RuecaRange = 2600 -- hay que estar a menos de esto de la anomalía para que pase

export type Phase = { Mission: string, Step: string, Index: number }

-- En qué punto del prólogo está el jugador (story = data.Story): la misión activa y su paso, o nil
function Varkun.phaseOf(story: { [string]: any }?): Phase?
	local active = story and story.Active
	if type(active) ~= "table" then
		return nil
	end
	for _, id in Varkun.Missions do
		local prog = active[id]
		if type(prog) == "table" then
			local idx = math.floor(tonumber(prog.Step) or 1)
			local step = Varkun.Steps[id][idx]
			if step then
				return { Mission = id, Step = step, Index = idx }
			end
		end
	end
	return nil
end

local function completed(story: { [string]: any }?, id: string): boolean
	return story ~= nil and type(story.Completed) == "table" and story.Completed[id] ~= nil
end
Varkun.completed = completed

-- ¿Qué parte se le puede ofrecer al atracar? (1, 2 o nil). sagaDone = Saga 1 terminada (o tester)
function Varkun.offerPart(story: { [string]: any }?, sagaDone: boolean): number?
	if not sagaDone then
		return nil
	end
	local active = story and type(story.Active) == "table" and story.Active or {}
	if active[Varkun.Missions[1]] or active[Varkun.Missions[2]] then
		return nil
	end
	if not completed(story, Varkun.Missions[1]) then
		return 1
	end
	if not completed(story, Varkun.Missions[2]) then
		return 2
	end
	return nil
end

-- Dónde salen los enemigos de una escena: en anillo alrededor de `center`, a `radius`
function Varkun.ring(center: Vector3, count: number, radius: number, seed: number?): { Vector3 }
	local out = {}
	local base = (seed or 0) * 0.7
	for i = 1, count do
		local a = base + (i - 1) / math.max(1, count) * math.pi * 2
		table.insert(out, center + Vector3.new(math.cos(a) * radius, 40 * math.sin(a * 2), math.sin(a) * radius))
	end
	return out
end

-- Lo que el HUD de la nave enseña como misión (fila con flecha): { Title, Progress, Target, TargetName }
function Varkun.row(phase: Phase?, scanned: number?): { [string]: any }?
	if not phase then
		return nil
	end
	local s = phase.Step
	if s == "Wreck" then
		return { Title = "🧵 La costura negra", Progress = "Sigue la señal de socorro", Target = Varkun.WreckPos, TargetName = "Señal de socorro" }
	elseif s == "Ambush" then
		return { Title = "🧵 La costura negra", Progress = "Derriba a las Agujas", Target = Varkun.WreckPos, TargetName = "Carguero destrozado" }
	elseif s == "Delivered" then
		return { Title = "🧵 La costura negra", Progress = "Lleva el carrete a la Cénit", Target = Stations.ById[Varkun.DeliverStation].Dock, TargetName = Stations.ById[Varkun.DeliverStation].Name }
	elseif s == "Anomaly" then
		return { Title = "🧵 Ruido en la Escarcha", Progress = "Ve a la anomalía", Target = Varkun.AnomalyPos, TargetName = "Anomalía de hilo" }
	elseif s == "Scanned" then
		return { Title = "🧵 Ruido en la Escarcha", Progress = ("Escaneando %d %%"):format(math.floor(100 * math.min(1, (scanned or 0) / Varkun.ScanSeconds))), Target = Varkun.AnomalyPos, TargetName = "Anomalía de hilo" }
	elseif s == "Rueca" then
		return { Title = "🧵 Ruido en la Escarcha", Progress = "Aguanta: la Rueca", Target = Varkun.RuecaPos, TargetName = "La Rueca" }
	elseif s == "Vault" then
		return { Title = "🧵 La costura negra", Progress = "El carrete, a la caja fuerte", Target = nil, TargetName = "Estación Cénit" }
	elseif s == "Calma" then
		return { Title = "🧵 Ruido en la Escarcha", Progress = "La Rueca se ha ido", Target = nil, TargetName = nil }
	end
	return nil
end

return Varkun
