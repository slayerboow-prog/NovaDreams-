-- SettingsRows: las opciones del menú (Hud.menuToggles, textos como «🔊 Música: sí») convertidas en
-- las filas de la app Ajustes del ValPhone, como los ajustes de un móvil:
--
--   * por secciones (Sonido, Pantalla, Juego, Personaje, Tu vida, Partida), cada una en su tarjeta;
--   * icono de color, nombre limpio (sin emoji ni «: sí») y una línea de ayuda;
--   * sí/no -> interruptor; Gráficos -> selector Auto · Bajo · Medio · Alto; Ropa -> Estilo Valmar ·
--     Mi avatar; lo que abre algo (Mi historia, tutorial) -> flecha; la vida nueva, en rojo y aparte.
--
-- SettingsRows.build(toggles, graphicsChoice) -> (filas, toggles en el mismo orden, tipo de cada fila)
-- Las opciones que no conoce salen igual, en «Otros».

local SettingsRows = {}

export type Toggle = { Text: string, Order: number, Press: () -> string }

SettingsRows.Sections = { "Sonido", "Pantalla", "Juego", "Controles", "Personaje", "Tu vida", "Partida", "Otros" }

SettingsRows.GraphicsOptions = { "Auto", "Bajo", "Medio", "Alto" }
SettingsRows.GraphicsChoices = { "Auto", "Low", "Medium", "High" }
SettingsRows.LookOptions = { "Estilo Valmar", "Mi avatar" }

type Info = { Section: string, Icon: string, Color: { number }, Label: string?, Detail: string?, Kind: string? }

local INFO: { [string]: Info } = {
	["Música"] = { Section = "Sonido", Icon = "musica", Color = { 255, 45, 85 }, Detail = "Banda sonora de Valmar" },
	["Sonidos"] = { Section = "Sonido", Icon = "timbre", Color = { 255, 149, 0 }, Detail = "Efectos, pasos, motores y avisos" },
	["Gráficos"] = { Section = "Pantalla", Icon = "habilidades", Color = { 88, 86, 214 }, Kind = "Graphics" },
	["GPS"] = { Section = "Juego", Icon = "lugar", Color = { 52, 199, 89 }, Detail = "Ruta por las calles y flechas en el suelo" },
	["Correr al empujar el joystick"] = { Section = "Controles", Icon = "correr", Color = { 0, 122, 255 }, Label = "Correr con el joystick", Detail = "Empujándolo hasta el borde (móvil)" },
	["Ropa"] = { Section = "Personaje", Icon = "👕", Color = { 255, 159, 10 }, Label = "Ropa", Kind = "Look" },
	["Mi historia"] = { Section = "Tu vida", Icon = "📖", Color = { 175, 82, 222 }, Detail = "Capítulos, personajes y recuerdos", Kind = "Action" },
	["Ver tutorial otra vez"] = { Section = "Tu vida", Icon = "ayuda", Color = { 90, 200, 250 }, Detail = "Los primeros pasos, desde el principio", Kind = "Action" },
	["Empezar una vida nueva"] = { Section = "Partida", Icon = "👶", Color = { 255, 59, 48 }, Detail = "Vuelves a nacer: se borra la partida", Kind = "NewLife" },
}
-- La vida nueva cambia de texto al pedir confirmación: se reconoce por su orden
local BY_ORDER: { [number]: string } = { [4] = "Empezar una vida nueva" }

-- «🔊 Música: sí» -> ("Música", "sí"); «📖 Mi historia» -> ("Mi historia", nil)
function SettingsRows.parse(text: string): (string, string?)
	local rest = text
	local first, after = text:match("^(%S+)%s+(.+)$")
	-- quita el emoji del principio (empiezan por un byte alto; las letras con tilde, no)
	if first and (string.byte(first, 1) or 0) >= 0xE2 then
		rest = after
	end
	local name, value = rest:match("^(.-):%s*(.+)$")
	if name and name ~= "" then
		return name, value
	end
	return rest, nil
end

local function sectionIndex(section: string): number
	return table.find(SettingsRows.Sections, section) or #SettingsRows.Sections
end

function SettingsRows.build(toggles: { Toggle }, graphicsChoice: string?): ({ any }, { Toggle }, { string })
	local items = {}
	for position, toggle in toggles do
		local name, value = SettingsRows.parse(toggle.Text)
		local info = INFO[name] or INFO[BY_ORDER[toggle.Order] or ""]
		local row: { [string]: any } = { Label = name }
		local kind = "Plain"
		if info then
			kind = info.Kind or "Plain"
			row.Section = info.Section
			row.Icon = info.Icon
			row.Color = info.Color
			row.Label = info.Label or name
			row.Detail = info.Detail
		else
			row.Section = "Otros"
			row.Label = toggle.Text
		end
		if kind == "Graphics" then
			local choice = graphicsChoice or "Auto"
			row.Segments = SettingsRows.GraphicsOptions
			row.Selected = table.find(SettingsRows.GraphicsChoices, choice) or 1
			local now = value and value:match("%((.-)%)")
			row.Detail = if now then "Ahora: " .. now .. " (según tu dispositivo)" else "Más calidad o más fluidez"
		elseif kind == "Look" then
			row.Segments = SettingsRows.LookOptions
			row.Selected = if value and value:find("avatar") then 2 else 1
		elseif kind == "NewLife" then
			row.Danger = true
			row.Action = true
			if not INFO[name] then
				-- (pidiendo confirmación: «⚠️ Se borra la partida. Pulsa otra vez»)
				row.Label = "Empezar una vida nueva"
				row.Detail = name .. (if value then ": " .. value else "")
			end
		elseif kind == "Action" then
			row.Action = true
		elseif value == "sí" or value == "no" then
			row.Switch = value == "sí"
			kind = "Switch"
		elseif value then
			row.Value = value
			row.ValueColor = { 160, 184, 220 }
		end
		table.insert(items, { Row = row, Toggle = toggle, Kind = kind, Section = sectionIndex(row.Section), Position = position })
	end
	table.sort(items, function(a, b)
		if a.Section ~= b.Section then
			return a.Section < b.Section
		end
		return a.Position < b.Position
	end)
	local rows, ordered, kinds = {}, {}, {}
	for _, item in items do
		table.insert(rows, item.Row)
		table.insert(ordered, item.Toggle)
		table.insert(kinds, item.Kind)
	end
	return rows, ordered, kinds
end

return SettingsRows
