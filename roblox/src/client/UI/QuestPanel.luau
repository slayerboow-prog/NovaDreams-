-- QuestPanel: las cuentas de la ventana MISIONES (UI/Hud: openQuests y renderQuestList), puras para
-- poder probarlas (scripts/test-hud.luau). Referencia del dueño: docs/bugs/misiones-referencia.png.
--
--   ┌ 📋 MISIONES                                         ✕ ┐
--   │ ┌ ◈ EVENTO GLOBAL ─────────────────────────────────┐ │
--   │ │ ┌──────────────────────────────────────────────┐ │ │
--   │ │ │ [🛸] Vórtidos                  Oleada 1 de 4 │ │ │  tarjeta del evento: raza, oleada,
--   │ │ │      [██████████░░░░░░░░░░░░]              › │ │ │  barra y una línea de qué pasa
--   │ │ │      Defensa de la ciudad contra la oleada…  │ │ │
--   │ │ └──────────────────────────────────────────────┘ │ │
--   │ │ ○ ✈ Ojos sobre la bahía · toca para cogerla      │ │  las misiones del evento
--   │ └──────────────────────────────────────────────────┘ │
--   │ ┌ ◈ MISIÓN PRINCIPAL ──────────────────────────────┐ │
--   │ │ La mochila desaparecida                          │ │
--   │ │ ● El colegio está cerrado · abre a las 8:30      │ │
--   │ └──────────────────────────────────────────────────┘ │
--   └──────────────────────────────────────────────────────┘
-- Opaca (antes se veían a través los letreros del mundo) y del alto de lo que lleva (con tope; si no
-- cabe, se desplaza).

local QuestPanel = {}

QuestPanel.Width = 560
QuestPanel.MaxHeight = 440
QuestPanel.MinHeight = 180
QuestPanel.Header = 52 -- título y ✕
QuestPanel.Footer = 12 -- margen de abajo (más la fila del trabajo si trabajas)
QuestPanel.JobRow = 56
QuestPanel.Background = 0.04 -- casi opaca
QuestPanel.EventCardHeight = 68
QuestPanel.HintColor = "#8fa3c4"

-- Alto de la ventana para un contenido de `content` (lienzo): entre MinHeight y MaxHeight
function QuestPanel.height(content: number, job: boolean): number
	local h = QuestPanel.Header + content + QuestPanel.Footer + (if job then QuestPanel.JobRow else 0)
	return math.clamp(math.ceil(h), QuestPanel.MinHeight, QuestPanel.MaxHeight)
end

-- Lo que enseña la tarjeta del evento. inv = atributo Invasion de workspace (decodificado); book = tus
-- misiones de la invasión; raceNames = Races.names(inv.Races)
function QuestPanel.eventInfo(inv: { [string]: any }, book: { { [string]: any } }, raceNames: string): { Name: string, Wave: string, Progress: number, Desc: string }
	local wave = tonumber(inv.Wave) or 0
	local waves = math.max(tonumber(inv.Waves) or 4, 1)
	local waveText = if inv.State == "Wave" then ("Oleada %d de %d"):format(math.max(wave, 1), waves)
		elseif inv.State == "Warn" then "¡Llegan!"
		elseif inv.State == "End" then (if inv.Outcome == "Victoria" then "🏆 Victoria" else "Ha acabado")
		else tostring(inv.Text or "")
	local desc = "Defensa de la ciudad contra la oleada de la grieta."
	for _, m in book do
		if m.Chain == "Evento" and m.Step then
			desc = tostring(m.Step)
			break
		end
	end
	local progress = if inv.State == "End" then 1 elseif inv.State == "Wave" then math.clamp(wave / waves, 0, 1) else 0
	return { Name = if raceNames ~= "" then raceNames else "Invasión de la Grieta", Wave = waveText, Progress = progress, Desc = desc }
end

-- Texto de una fila: el título y, en gris, la pista («toca para cogerla», el paso…). Para RichText.
function QuestPanel.rowText(title: string, hint: string?): string
	local function esc(s: string): string
		return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
	end
	if not hint or hint == "" then
		return esc(title)
	end
	return ('%s <font color="%s">· %s</font>'):format(esc(title), QuestPanel.HintColor, esc(hint))
end

return QuestPanel
