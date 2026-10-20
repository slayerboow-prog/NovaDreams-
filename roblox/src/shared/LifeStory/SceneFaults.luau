-- SceneFaults: lo que se cuenta de un fallo de escena (fase 3 del sistema de cine,
-- docs/cine/auditoria-sistema.md). Lo usan el cliente (Controllers/SceneReport: avisa al servidor) y el
-- servidor (server/LifeStory/SceneErrorLog: lo apunta y lo cuenta). Puro: sin servicios de Roblox.
--
-- Un aviso es SOLO esto (nada que identifique al jugador):
--   { Source = "Cinematics" | "Happening" | "Dialogue" | "Camera" | "Director",
--     Scene  = id de la escena o conversación ("Grieta_Caen", "Saga_02_Grieta"…),
--     Step   = el paso que falló ("Shot", "Lines", "Wait", "Open"…),
--     Kind   = "Error" (algo lanzó un error) | "Watchdog" (un paso no acabó a tiempo) | "Abort"
--              (demasiados fallos: se cortó la escena),
--     Message = el error, limpio y corto }
-- clean() quita del mensaje el nombre y el id del jugador (y cualquier número largo), las rutas de
-- instancias de Players y lo deja en MaxMessage letras.

local SceneFaults = {}

SceneFaults.Sources = { Cinematics = true, Happening = true, Dialogue = true, Camera = true, Director = true }
SceneFaults.Kinds = { Error = true, Watchdog = true, Abort = true }
SceneFaults.MaxMessage = 160
SceneFaults.MaxId = 48

-- Un id corto y seguro (letras, números, _ . - :), o nil
function SceneFaults.id(value: any): string?
	if type(value) ~= "string" and type(value) ~= "number" then
		return nil
	end
	local text = tostring(value):gsub("[^%w_%.%-:]", "")
	if text == "" then
		return nil
	end
	return text:sub(1, SceneFaults.MaxId)
end

local function escape(text: string): string
	return (text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

-- El mensaje sin datos del jugador. names: textos que se quitan (su Name, DisplayName, UserId)
function SceneFaults.clean(message: any, names: { string }?): string
	local text = tostring(message or "")
	-- (ni saltos de línea ni caracteres de control: una línea en el log)
	text = text:gsub("[%c]+", " ")
	for _, name in names or {} do
		if type(name) == "string" and #name >= 2 then
			text = text:gsub(escape(name), "<jugador>")
		end
	end
	-- Rutas de instancias del jugador: Players.Leo.PlayerGui… → Players.<jugador>.PlayerGui…
	text = text:gsub("Players%.[^%.%s:]+", "Players.<jugador>")
	-- Números largos (ids de usuario, JobId…)
	text = text:gsub("%d%d%d%d%d%d+", "<n>")
	text = text:gsub("%s+", " ")
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	if #text > SceneFaults.MaxMessage then
		-- (sin partir una letra UTF-8 por la mitad)
		local cut = SceneFaults.MaxMessage
		while cut > 1 and (text:byte(cut + 1) or 0) >= 0x80 and (text:byte(cut + 1) or 0) < 0xC0 do
			cut -= 1
		end
		text = text:sub(1, cut) .. "…"
	end
	return text
end

-- Un aviso válido y limpio, o nil si no vale
function SceneFaults.normalize(report: any, names: { string }?): { [string]: string }?
	if type(report) ~= "table" then
		return nil
	end
	local source = report.Source
	if type(source) ~= "string" or not SceneFaults.Sources[source] then
		return nil
	end
	local kind = if type(report.Kind) == "string" and SceneFaults.Kinds[report.Kind] then report.Kind else "Error"
	return {
		Source = source,
		Scene = SceneFaults.id(report.Scene) or "?",
		Step = SceneFaults.id(report.Step) or "?",
		Kind = kind,
		Message = SceneFaults.clean(report.Message, names),
	}
end

-- Clave para contar avisos iguales
function SceneFaults.key(report: { [string]: string }): string
	return ("%s|%s|%s|%s"):format(report.Source, report.Scene, report.Step, report.Kind)
end

return SceneFaults
