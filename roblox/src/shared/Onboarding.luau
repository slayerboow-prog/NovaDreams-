-- Onboarding: los primeros pasos del jugador nuevo, en un solo sitio (lo usan OnboardingService en el
-- servidor y Controllers/Guide y Controllers/HelpUI en el cliente). Aquí no se toca Roblox: solo datos
-- y cuentas, así lo prueba scripts/test-onboarding.luau.
--
--   * Steps: la lista de primeros pasos (moverse, correr, hablar, mapa, mochila, ayuda y misión), con
--     lo que dice la tarjeta en el móvil y con teclado o mando, y qué parte del HUD se señala.
--   * Tips: los consejos que salen UNA vez la primera vez que te encuentras algo nuevo.
--   * decide(): ¿al jugador le toca el tutorial? (nuevo sí; quien ya había jugado, no).
--   * suggest(): 2-3 cosas que hacer ahora mismo si no tienes misión (según tu edad, la hora y si
--     las tiendas están abiertas: shared/OpeningHours).
--   * Stuck: cuándo dar una pista si llevas rato sin avanzar en la misión o te alejas de ella.

local OpeningHours = require(script.Parent.OpeningHours)

local Onboarding = {}

-- Estado del tutorial guardado (DataService: data.Onboarding.Tutorial)
Onboarding.Pending = "Pendiente" -- le toca (o lo está haciendo)
Onboarding.Done = "Hecho"
Onboarding.Skipped = "Saltado"
Onboarding.Veteran = "Veterano" -- ya jugaba antes de que existiera el tutorial: no se le enseña

export type Step = {
	Id: string,
	Title: string,
	Touch: string, -- lo que dice la tarjeta en el móvil y la tableta
	Keys: string, -- con teclado y ratón (y el mando)
	Target: { Touch: string, Keys: string }, -- qué se señala: "Items.X" o "Slots.X" de UI/HudLayout
}

-- En orden: la tarjeta enseña siempre el primero que falte
Onboarding.Steps = {
	{
		Id = "Mover",
		Title = "Muévete",
		Touch = "Arrastra el joystick de abajo a la izquierda para andar.",
		Keys = "Usa W A S D para andar (con mando: el stick izquierdo).",
		Target = { Touch = "Items.Joystick", Keys = "Items.Hints" },
	},
	{
		Id = "Correr",
		Title = "Corre",
		Touch = "Toca el botón Correr o empuja el joystick hasta el borde.",
		Keys = "Mantén pulsado Mayús (Shift) mientras andas (con mando: L3).",
		Target = { Touch = "Slots.Correr", Keys = "Items.Hints" },
	},
	{
		Id = "Interactuar",
		Title = "Habla o usa algo",
		Touch = "Acércate a una persona o a una cosa: el botón grande cambia («Hablar», «Coger»…). Tócalo.",
		Keys = "Acércate a una persona o a una cosa y pulsa E (con mando: X).",
		Target = { Touch = "Slots.Ataque", Keys = "Items.Hints" },
	},
	{
		Id = "Mapa",
		Title = "Abre el mapa",
		Touch = "Toca el botón del mapa 🗺️ en el minimapa (arriba a la derecha).",
		Keys = "Pulsa M o toca el botón del mapa 🗺️ del minimapa.",
		Target = { Touch = "Items.Minimap", Keys = "Items.Minimap" },
	},
	{
		Id = "Mochila",
		Title = "Abre la mochila",
		Touch = "Toca tu ValPhone (abajo a la izquierda) y abre la app «Mochila».",
		Keys = "Pulsa E cuando no tengas nada delante, o abre el ValPhone (Tab) y elige «Mochila».",
		Target = { Touch = "Items.Phone", Keys = "Items.Hotbar" },
	},
	{
		Id = "Ayuda",
		Title = "¿No sabes qué hacer?",
		Touch = "Toca el botón ❓ y te decimos qué hacer ahora.",
		Keys = "Pulsa H o haz clic en ❓ y te decimos qué hacer ahora.",
		Target = { Touch = "Slots.Ayuda", Keys = "Items.Help" },
	},
	{
		Id = "Mision",
		Title = "Sigue tu misión",
		Touch = "Toca «Llévame» o sigue las flechas azules del suelo hasta tu objetivo.",
		Keys = "Pulsa «Llévame» o sigue las flechas azules del suelo hasta tu objetivo.",
		Target = { Touch = "Items.Mission", Keys = "Items.Mission" },
	},
} :: { Step }

Onboarding.StepById = {} :: { [string]: Step }
for index, step in Onboarding.Steps do
	Onboarding.StepById[step.Id] = step;
	(step :: any).Index = index
end

-- Consejos de la primera vez (uno por cosa nueva; se guardan para no repetirlos)
Onboarding.Tips = {
	Vehiculo = "🚗 Vas en un vehículo. Al volante: flechas para girar y pedales ACELERAR y FRENO (o W A S D). Para bajarte, toca «Bajarse» (tecla F).",
	Tienda = "🛒 Estás en una tienda. Coge lo que quieras con el botón de acción y paga en una caja antes de salir.",
	Gimnasio = "💪 Máquina del gimnasio. Úsala con el botón de acción y toca «¡YA!» cuando el marcador pase por la zona verde.",
	Transporte = "🚏 Parada de bus, metro o Cercanías. Espera y sube con el botón de acción. En el bus, «Bajar en la próxima». El metro y el tren piden billete.",
	Busqueda = "⭐ ¡La policía te busca! Aléjate y escóndete un rato: si no te ven, las estrellas se van solas.",
	Necesidades = "🍎 Tienes hambre o sueño. Come algo (nevera, súper o cafetería) y duerme en tu cama.",
} :: { [string]: string }

---------------------------------------------------------------------
-- Estado guardado
---------------------------------------------------------------------

-- ¿Qué toca al cargar el perfil? Perfil nuevo (sin tiempo jugado) -> tutorial; perfil que ya jugaba
-- antes de existir el tutorial -> no se le enseña. Si ya estaba decidido, se queda como estaba.
function Onboarding.decide(tutorial: string?, playSeconds: number?): string
	if type(tutorial) == "string" and tutorial ~= "" then
		return tutorial
	end
	return if (tonumber(playSeconds) or 0) > 0 then Onboarding.Veteran else Onboarding.Pending
end

-- { Mover = true, Correr = true } <-> "Mover,Correr" (para los atributos del jugador)
function Onboarding.encode(set: { [string]: boolean }?): string
	local list = {}
	for id, on in set or {} do
		if on then
			table.insert(list, id)
		end
	end
	table.sort(list)
	return table.concat(list, ",")
end

function Onboarding.decode(text: any): { [string]: boolean }
	local set = {}
	if type(text) == "string" then
		for id in string.gmatch(text, "[^,]+") do
			set[id] = true
		end
	end
	return set
end

-- El primer paso que falta (nil = todos hechos)
function Onboarding.nextStep(done: { [string]: boolean }): Step?
	for _, step in Onboarding.Steps do
		if not done[step.Id] then
			return step
		end
	end
	return nil
end

function Onboarding.allDone(done: { [string]: boolean }): boolean
	return Onboarding.nextStep(done) == nil
end

---------------------------------------------------------------------
-- ¿Qué hago ahora? (sin misión): 2-3 ideas según tu edad, la hora y lo que está abierto
---------------------------------------------------------------------
export type Suggestion = { Id: string, Text: string, Place: string?, Name: string? }
export type Context = {
	Stage: string?,
	Clock: number?,
	Weekday: number?, -- 1 = lunes … 7 = domingo
	Hunger: number?,
	Energy: number?,
	Wanted: number?,
	Job: string?,
}

-- Horario de los sitios a los que se manda (los de shared/OpeningHours y unos pocos más)
Onboarding.PlaceHours = {
	Supermercado = OpeningHours.Services.Supermercado,
	GimnasioValmar = OpeningHours.Places.Gym,
	Recreativos = OpeningHours.Places.Arcade,
	Colegio = { 8.5, 17 }, -- (como Config.SchoolDay: abre a las 8:30)
	Facultad = OpeningHours.Places.Faculty,
	Playa = { 8, 20.5 },
	Parque = { 7, 22 },
} :: { [string]: { number } }

local function kid(stage: string?): boolean
	return stage == "Nino" or stage == "Adolescente"
end

function Onboarding.suggest(ctx: Context): { Suggestion }
	local clock = ctx.Clock or 12
	local stage = ctx.Stage or "Adulto"
	local night = clock >= 22 or clock < 7
	local candidates: { Suggestion } = {}
	local function add(id: string, text: string, place: string?, name: string?)
		table.insert(candidates, { Id = id, Text = text, Place = place, Name = name })
	end

	if (ctx.Wanted or 0) > 0 then
		add("Esconderse", "⭐ La policía te busca: aléjate y escóndete un rato.")
	end
	if stage == "Bebe" then
		add("Familia", "🧸 Explora tu casa y habla con tu familia.")
		add("Levantarse", "👣 Intenta ponerte de pie y dar pasitos.")
		return candidates
	end
	if (ctx.Energy or 100) < 30 or night then
		add("Dormir", if night then "💤 Es de noche: vete a dormir a tu cama." else "💤 Tienes mucho sueño: duerme un rato en tu cama.", "Casa", "Tu casa")
	end
	if (ctx.Hunger or 100) < 40 then
		if not kid(stage) and OpeningHours.isOpen(Onboarding.PlaceHours.Supermercado, clock) then
			add("Comer", "🛒 Tienes hambre: compra comida en el supermercado.", "Supermercado", "Supermercado")
		else
			add("Comer", "🍎 Tienes hambre: come algo de la nevera de casa.", "Casa", "Tu casa")
		end
	end
	local weekend = (ctx.Weekday or 1) >= 6
	if stage == "Nino" or stage == "Adolescente" then
		if not weekend then
			add("Clase", if stage == "Nino" then "🏫 Ve al colegio: hay clase." else "📚 Ve a clase al instituto.", "Colegio", "Colegio")
		end
		-- (de noche, a los niños no se les manda de paseo: en casa)
		if night then
			add("EnCasa", "📺 Quédate en casa: mira la tele o juega con tu familia.", "Casa", "Tu casa")
		else
			add("Parque", "⚽ Juega en el parque con otros chicos.", "Parque", "Parque")
			add("Recreativos", "🕹️ Echa una partida en los recreativos.", "Recreativos", "Recreativos")
			if stage == "Adolescente" then
				add("Gimnasio", "💪 Entrena en el gimnasio.", "GimnasioValmar", "Gimnasio")
			end
			add("Playa", "🏖️ Date un baño en Playa Dorada.", "Playa", "Playa Dorada")
		end
	else
		if not ctx.Job then
			add("Trabajo", "💼 Gana dinero: el supermercado busca cajeros.", "Supermercado", "Supermercado")
		end
		if stage == "AdultoJoven" and not weekend then
			add("Universidad", "🎓 Ve a clase a la universidad.", "Facultad", "Universidad")
		end
		add("Gimnasio", "💪 Entrena en el gimnasio.", "GimnasioValmar", "Gimnasio")
		add("Playa", "🏖️ Relájate en Playa Dorada.", "Playa", "Playa Dorada")
		add("Parque", "🌳 Da un paseo por el parque.", "Parque", "Parque")
	end
	if not (night and kid(stage)) then
		add("Plaza", "⛲ Pasea por la Plaza Mayor y conoce gente.", "Plaza", "Plaza Mayor")
	end

	-- Solo lo que está abierto ahora, sin repetir, y como mucho 3
	local out: { Suggestion } = {}
	local seen: { [string]: boolean } = {}
	for _, s in candidates do
		local hours = s.Place and Onboarding.PlaceHours[s.Place]
		if not seen[s.Id] and OpeningHours.isOpen(hours, clock) then
			seen[s.Id] = true
			table.insert(out, s)
			if #out >= 3 then
				break
			end
		end
	end
	return out
end

-- El sitio más cercano de uno de esos tipos: landmarks = { { Kind = "Parque", Position = Vector3 } }
function Onboarding.nearest(landmarks: { { Kind: string, Position: Vector3 } }, kind: string, from: Vector3?): Vector3?
	local best, bestDistance = nil, math.huge
	for _, mark in landmarks do
		if mark.Kind == kind then
			local d = if from then (Vector3.new(mark.Position.X, 0, mark.Position.Z) - Vector3.new(from.X, 0, from.Z)).Magnitude else 0
			if d < bestDistance then
				best, bestDistance = mark.Position, d
			end
		end
	end
	return best
end

-- "hacia el norte", "hacia el sureste"… (el norte es −Z, como en el mapa)
function Onboarding.direction(from: Vector3, to: Vector3): string
	local dx, dz = to.X - from.X, to.Z - from.Z
	if math.abs(dx) < 1 and math.abs(dz) < 1 then
		return "aquí mismo"
	end
	local angle = math.deg(math.atan2(dx, -dz)) % 360 -- 0 = norte, 90 = este
	local names = { "el norte", "el noreste", "el este", "el sureste", "el sur", "el suroeste", "el oeste", "el noroeste" }
	return "hacia " .. names[math.floor((angle + 22.5) / 45) % 8 + 1]
end

---------------------------------------------------------------------
-- Pistas si te atascas
---------------------------------------------------------------------
Onboarding.Stuck = {
	Seconds = 90, -- jugando (sin conversaciones ni cinemáticas) sin que avance el paso
	NoApproach = 20, -- y sin acercarte al objetivo en este rato
	Approach = 4, -- studs que hay que acercarse para que cuente
	AwayMargin = 60, -- más lejos que lo más cerca que has estado: te estás alejando
	AwaySeconds = 45, -- tanto tiempo alejándote
	MaxRepeats = 2, -- la misma pista, como mucho dos veces
}

export type StuckState = {
	Key: string?,
	StepTime: number,
	SinceApproach: number,
	Best: number?,
	Away: number,
	Shown: { [string]: number },
}

function Onboarding.newStuck(): StuckState
	return { Key = nil, StepTime = 0, SinceApproach = 0, Best = nil, Away = 0, Shown = {} }
end

-- Una vuelta: key = el paso actual (nil = sin misión), distance = studs hasta el objetivo (nil = sin
-- sitio), busy = en una conversación o cinemática (no cuenta). Devuelve "Stuck", "Away" o nil.
function Onboarding.stuckStep(s: StuckState, dt: number, key: string?, distance: number?, busy: boolean): string?
	if key ~= s.Key then
		s.Key = key
		s.StepTime, s.SinceApproach, s.Away = 0, 0, 0
		s.Best = distance
	end
	if key == nil or busy then
		return nil
	end
	local cfg = Onboarding.Stuck
	s.StepTime += dt
	s.SinceApproach += dt
	if distance then
		if s.Best == nil or distance < (s.Best :: number) - cfg.Approach then
			s.Best = distance
			s.SinceApproach = 0
		end
		if distance > (s.Best :: number) + cfg.AwayMargin then
			s.Away += dt
		else
			s.Away = 0
		end
	end
	if (s.Shown[key] or 0) >= cfg.MaxRepeats then
		return nil
	end
	local kind: string? = nil
	if s.Away >= cfg.AwaySeconds then
		kind = "Away"
	elseif s.StepTime >= cfg.Seconds and s.SinceApproach >= cfg.NoApproach then
		kind = "Stuck"
	end
	if kind then
		s.Shown[key] = (s.Shown[key] or 0) + 1
		s.StepTime, s.SinceApproach, s.Away = 0, 0, 0
		s.Best = distance
	end
	return kind
end

return Onboarding
