-- Canto: «La anomalía que canta» (expansión «La Deriva», fase 2; docs/espacio-aaa/expansion-15h.md §6, hora 2).
-- Cuentas puras: las usan Services/DerivaService (sitio, escaneo, interferencia), Controllers/DerelictClient
-- (la interferencia en tu pantalla) y las pruebas (scripts/test-vigia.luau).
--
-- La radio de las estaciones recoge un ruido que se repite como una canción. Viene de una anomalía al otro
-- lado de la Nube Escarcha: una zona donde chocan restos de dos universos y la física falla. Hay que
-- quedarse dentro ScanSeconds mientras el escáner la mide (la radio y la pantalla fallan: interferencia),
-- llevar los datos a la Estación Vigía y conocer a la doctora Ivo, del Instituto Nilda. Abre el laboratorio.

local Stations = require(script.Parent.Stations)

local Canto = {}

Canto.MissionId = "Deriva_00_Canto"
Canto.Steps = { "Signal", "Scanned", "Docked", "Ivo" }
Canto.AnomalyPos = Vector3.new(-2600, 7200, -6200) -- (más allá de la Escarcha, fuera de su sector de patrullas)
Canto.ArriveRadius = 380
Canto.ScanRadius = 460
Canto.ScanSeconds = 30
Canto.Station = "Vigia"
Canto.RewardDatos = 15

export type Phase = { Step: string, Index: number }

function Canto.phaseOf(story: { [string]: any }?): Phase?
	local active = story and story.Active
	local prog = type(active) == "table" and active[Canto.MissionId] or nil
	if type(prog) ~= "table" then
		return nil
	end
	local idx = math.floor(tonumber(prog.Step) or 1)
	local step = Canto.Steps[idx]
	return if step then { Step = step, Index = idx } else nil
end

-- ¿Se le ofrece al atracar? (después del prólogo de Varkun; una vez)
function Canto.offer(story: { [string]: any }?): boolean
	if not story or type(story.Completed) ~= "table" then
		return false
	end
	if story.Completed[Canto.MissionId] or (type(story.Active) == "table" and story.Active[Canto.MissionId]) then
		return false
	end
	return story.Completed["Varkun_02_Escarcha"] ~= nil
end

-- ¿Está dentro de la zona de escaneo?
function Canto.inScan(pos: Vector3): boolean
	return (pos - Canto.AnomalyPos).Magnitude <= Canto.ScanRadius
end

-- Fila del HUD de la nave
function Canto.row(phase: Phase?, scanned: number?): { [string]: any }?
	if not phase then
		return nil
	end
	local title = "♫ La anomalía que canta"
	if phase.Step == "Signal" then
		return { Title = title, Progress = "Sigue el ruido de la radio", Target = Canto.AnomalyPos, TargetName = "Anomalía" }
	elseif phase.Step == "Scanned" then
		local pct = math.floor(100 * math.min(1, (scanned or 0) / Canto.ScanSeconds))
		return { Title = title, Progress = ("Quédate dentro · escaneo %d %%"):format(pct), Target = Canto.AnomalyPos, TargetName = "Anomalía" }
	elseif phase.Step == "Docked" then
		local st = Stations.ById[Canto.Station]
		return { Title = title, Progress = "Lleva los datos a la Vigía", Target = st and st.Dock, TargetName = st and st.Name or "Estación Vigía" }
	end
	return { Title = title, Progress = "En la Estación Vigía", Target = nil, TargetName = nil }
end

return Canto
