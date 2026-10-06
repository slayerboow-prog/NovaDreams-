-- Escenas de las ETAPAS DE LA VIDA: los cuatro montajes de cambio de etapa y el final de la vida.
-- Diseño: docs/historia/auditoria-narrativa-cinematica.md §6.3 (C-13, M-06, M-07). Formato: Sequencer.luau.
--
-- MONTAJE (Montaje_Bebe_Nino, Montaje_Nino_Adolescente, Montaje_Adolescente_Joven, Montaje_Joven_Adulto),
-- unos 36 s, se puede saltar. Cuatro tiempos:
--   1. Cierre íntimo (0 – 7,5 s): el último momento de la etapa, con su gente, en su sitio. Música íntima.
--      Lleva la tarjeta de fin de capítulo, como al final de un episodio.
--   2. Tus recuerdos (7,5 – 21,3 s): tres «fotos vivas». Cada foto elige, por prioridad, entre tus
--      Memories, Flags y Choices (el amigo al que ayudaste, tu grupo con su nombre, tu club…) y siempre
--      tiene un plan B genérico: nunca queda vacía. Plano fijo con zoom lento, luz de recuerdo, corte Dip.
--   3. El mundo cambia (21,3 – 29,5 s): un lugar de la etapa nueva con su gente ya mayor, entrando andando.
--      La música sube al tema de la etapa nueva.
--   4. Llegada (29,5 – 36 s): la cámara baja hasta ti, ya mayor, donde estés, y te suelta suave.
-- La edad cambia FUERA DE PLANO: el paso Transition pone la etapa nueva al lanzar el montaje, y la
-- cámara no te enseña hasta la llegada (los tiempos 1–3 son de otros personajes y otros sitios).
--
-- Cómo se lanza: un paso Transition con Cinematic = "<id>" y SetStage (igual que antes con los vuelos).
--   Bebé → niño          Quests.luau, Bebe_HoraDeSalir           Montaje_Bebe_Nino
--   Niño → adolescente   Cole12_UltimoDia (Nino_AInstituto)        Montaje_Nino_Adolescente
--   Adolescente → joven  Ins06_LaGranDecision (Adol_Selectividad)  Montaje_Adolescente_Joven
--   Joven → adulto       Adu03_Reencuentro (último paso)           Montaje_Joven_Adulto
-- Nino_AInstituto y Adol_Selectividad son el MISMO montaje con el nombre viejo: así las misiones de
-- siempre lo ven sin cambiar nada (sus vuelos de cámara viejos ya no están en Cinematics.luau).
--
-- FINAL DE LA VIDA (Vida_MirarAtras, Adulto_MirarAtras en Quests.luau): la casa de Los Pinos, tu familia,
-- el álbum de tus recuerdos (una foto viva por etapa) y la gente que conociste llegando por la calle.
--
-- Las fotos se escriben como datos (photo/slots más abajo): cada candidata tiene UNA condición (un
-- recuerdo, una marca, una decisión o una misión hecha) y se elige la primera que se cumple; la última
-- no tiene condición (el plan B). Aquí se convierten en sucesos normales con If, que el servidor
-- resuelve al empezar (Sequencer.resolve): actores, plano, rótulo y frase de cada foto.

local V = Vector3.new

local Cast = require(script.Parent.Parent.Cast)

local SLOT = 4.6 -- lo que dura cada foto viva
local MEMORIES_AT = 7.5 -- empiezan los recuerdos
local NEW_WORLD_AT = MEMORIES_AT + 3 * SLOT -- 21.3: el mundo cambia
local ARRIVAL_AT = 29.5 -- la llegada
local DURATION = 36

---------------------------------------------------------------------
-- Condiciones: combinar y negar (solo condiciones de UNA pieza: así «no se cumple» es exacto)
---------------------------------------------------------------------
local NEGATE = { Memories = "NotMemories", Flags = "NotFlags", Completed = "NotCompleted", Choices = "NotChoices" }

local function count(t: { [any]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

local function negate(cond: { [string]: any }): { [string]: any }
	local key, value = next(cond)
	assert(key and count(cond) == 1 and NEGATE[key], "Etapas: una foto se elige con UNA condición (Memories, Flags, Completed o Choices)")
	assert(type(value) == "table" and count(value) == 1, "Etapas: la condición de una foto tiene un solo valor")
	return { [NEGATE[key]] = value }
end

local function combine(...: any): { [string]: any }?
	local out: { [string]: any } = {}
	for i = 1, select("#", ...) do
		local cond = select(i, ...)
		if type(cond) == "table" then
			for key, value in cond do
				if type(value) == "table" and #value > 0 then
					out[key] = out[key] or {}
					for _, x in value do
						table.insert(out[key], x)
					end
				elseif type(value) == "table" then
					out[key] = out[key] or {}
					for k, v in value do
						assert(out[key][k] == nil or out[key][k] == v, "Etapas: condiciones que chocan en " .. key .. "." .. tostring(k))
						out[key][k] = v
					end
				else
					out[key] = value
				end
			end
		end
	end
	return if next(out) then out else nil
end

local function with(event: { [string]: any }, cond: { [string]: any }?): { [string]: any }
	if cond then
		event.If = cond
	end
	return event
end

---------------------------------------------------------------------
-- Fotos vivas
---------------------------------------------------------------------
-- Una candidata:
--   { If = condición?, Place = "Lugar", Center = V3?, Era = escala de los niños del reparto?,
--     People = { { Npc, At = V3?, Pose = "Cheer"|…?, Mood?, Scale?, Name?, If? } },
--     Title, Sub?, Titles = { { If, Text, Sub? } }?  (rótulos que sustituyen al de siempre si se cumplen),
--     Line = { S, T, If? }? }
-- slots = { { candidata, candidata, … }, … }. Devuelve las fotos para comprobarlas (pruebas).
local function addPhotos(def: { [string]: any }, t0: number, slots: { { { [string]: any } } }, prefix: string)
	local tracks = def.Tracks
	for _, name in { "Actors", "Camera", "Titles", "Lines", "Sound" } do
		tracks[name] = tracks[name] or {}
	end
	def.Photos = def.Photos or {}
	for si, candidates in slots do
		local t = t0 + (si - 1) * SLOT
		table.insert(tracks.Sound, { At = t + 0.25, Play = "Clic" }) -- (el disparo de la foto)
		local prior: { { [string]: any } } = {}
		for ci, cand in candidates do
			assert(cand.If ~= nil or ci == #candidates, "Etapas: la foto sin condición (el plan B) va la última")
			local gate = combine(cand.If, table.unpack(prior))
			if cand.If then
				table.insert(prior, negate(cand.If))
			end
			local anchor = "P_" .. cand.Place
			def.Anchors[anchor] = "Place:" .. cand.Place
			local center = cand.Center or V(0, 0, 6)
			local people = cand.People or {}
			local grown = cand.Era or 1
			-- (la cámara, a la altura de la cara del más alto: niños 0,65, adolescentes 0,85, adultos 1)
			local tallest = 0
			for _, p in people do
				local person = Cast.People[p.Npc]
				local size = p.Scale or (if person and person.Kid then (if grown ~= 1 then grown else 0.65) else 1)
				tallest = math.max(tallest, size)
			end
			local lookY = 0.2 + 2.9 * (if tallest > 0 then tallest else 1)
			local cam = center + (cand.Cam or V(0.8, lookY + 0.7, 9 + #people * 0.6))
			local look = center + V(0, lookY, 0)
			local keys = {}
			for pi, p in people do
				local key = ("%s%d%d_%s"):format(prefix, si, ci, p.Key or p.Npc)
				keys[pi] = key
				local person = Cast.People[p.Npc]
				local scale = p.Scale or (if person and person.Kid and grown ~= 1 then grown else nil)
				local x = (pi - (#people + 1) / 2) * 2
				local at = p.At or V(x, 0, if pi % 2 == 0 then -0.6 else 0)
				local cond = combine(gate, p.If)
				table.insert(tracks.Actors, with({
					At = math.max(t - 0.8, 0),
					Spawn = { Key = key, Npc = p.Npc, Name = p.Name, Anchor = anchor, Offset = center + at, Scale = scale, Mood = p.Mood, Face = { anchor, cam } },
				}, cond))
				if p.Pose then
					table.insert(tracks.Actors, with({ At = t + 0.5, Gesture = { Key = key, Play = p.Pose } }, cond))
				end
				table.insert(tracks.Actors, with({ At = t + SLOT + 0.3, Despawn = { Key = key } }, cond))
			end
			table.insert(tracks.Camera, with({
				At = t,
				Duration = SLOT,
				Fixed = { anchor, cam },
				Look = { anchor, look },
				Fov = { 46, 39 },
				Cut = "Dip",
			}, gate))
			table.insert(tracks.Titles, with({ At = t + 0.5, Text = cand.Title, Sub = cand.Sub, Duration = SLOT - 1.1 }, gate))
			for _, alt in cand.Titles or {} do
				table.insert(tracks.Titles, with({ At = t + 0.55, Text = alt.Text, Sub = alt.Sub, Duration = SLOT - 1.15 }, combine(gate, alt.If)))
			end
			if cand.Line then
				table.insert(tracks.Lines, with({ At = t + 1.1, Speaker = cand.Line.S, Text = cand.Line.T, Duration = SLOT - 1.4 }, combine(gate, cand.Line.If)))
			end
			table.insert(def.Photos, { Slot = si, Candidate = ci, If = cand.If, Gate = gate, Title = cand.Title, Place = cand.Place, Keys = keys })
		end
	end
end

-- La llegada (tiempo 4): la cámara baja hasta ti (donde estés AHORA: "Player" sigue al personaje) y
-- te suelta suave
local function addArrival(def: { [string]: any }, title: string, sub: string?)
	local tracks = def.Tracks
	table.insert(tracks.Camera, {
		At = ARRIVAL_AT,
		Duration = DURATION - ARRIVAL_AT,
		From = { "Player", V(14, 26, 18) },
		To = { "Player", V(3.5, 3.4, 7) },
		Look = { "Player", V(0, 1.8, 0) },
		Fov = { 60, 52 },
		Easing = "Out",
		Cut = "Dip",
	})
	table.insert(tracks.Titles, { At = ARRIVAL_AT + 0.9, Text = title, Sub = sub, Duration = 4 })
	tracks.Ambience = tracks.Ambience or {}
	table.insert(tracks.Ambience, { At = ARRIVAL_AT, Kind = "Auto", Fade = 2 })
end

-- Lo común de los montajes: recuerdos con luz de recuerdo y «Pasan los años», luz fuera al cambiar el mundo
local function addMemoriesFrame(def: { [string]: any })
	local tracks = def.Tracks
	tracks.Light = tracks.Light or {}
	tracks.Music = tracks.Music or {}
	table.insert(tracks.Light, { At = MEMORIES_AT - 0.2, Preset = "Recuerdo", Fade = 0.6 })
	table.insert(tracks.Light, { At = NEW_WORLD_AT - 0.1, Preset = false, Fade = 0.8 })
	table.insert(tracks.Music, { At = MEMORIES_AT, Play = "PasanLosAnos" })
end

-- Nombre del grupo (Cole03): rótulos que lo dicen, uno por nombre posible
local GRUPOS = { "Los Imparables", "La Patrulla Valmar", "Los del Banco Azul", "Los Dinosaurios" }
local function groupTitles(sub: string): { { [string]: any } }
	local out = {}
	for _, name in GRUPOS do
		table.insert(out, { If = { Choices = { NombreGrupo = name } }, Text = "«" .. name .. "»", Sub = sub })
	end
	return out
end

-- Los amigos que se sumaron al grupo (solo si se sumaron)
local function extraFriends(era: number?): { { [string]: any } }
	return {
		{ Npc = "Mateo", If = { Flags = { "AyudasteAMateo" } }, Pose = "Wave", Scale = era },
		{ Npc = "Hugo", If = { Flags = { "HugoConElGrupo" } }, Scale = era },
	}
end

local function concat(...: { any }): { any }
	local out = {}
	for i = 1, select("#", ...) do
		for _, x in select(i, ...) do
			table.insert(out, x)
		end
	end
	return out
end

local function montage(def: { [string]: any }, photos: { { { [string]: any } } }, arrival: { string? }, prefix: string): { [string]: any }
	def.Duration = def.Duration or DURATION
	def.Skippable = true
	def.FadeIn = true
	def.Tracks.Lines = def.Tracks.Lines or {}
	addPhotos(def, MEMORIES_AT, photos, prefix)
	addMemoriesFrame(def)
	addArrival(def, arrival[1] :: string, arrival[2])
	return def
end

---------------------------------------------------------------------
-- BEBÉ → NIÑO
-- ¿Qué pasa? Una noche más en la casa de Los Pinos; pasan seis años y empieza el colegio.
-- ¿Quién siente qué? Abu y tu familia, ternura y un poco de vértigo: «así se crece».
-- ¿Por qué ahora? Te has asomado al ventanal: ya miras hacia fuera.
-- ¿Qué cambia? Dejas de ser un bebé: en el colegio te esperan Lucía, Nico, Sara y Omar.
-- ¿Qué debe recordar el jugador? Tus primeros pasos fueron hacia tu abu.
---------------------------------------------------------------------
local Bebe_Nino = montage({
	Montaje = { From = "Bebe", To = "Nino", Chapter = "Bebe_PrimerosPasos", Next = "Nino_ElColegio" },
	Anchors = {
		Cuna = "Place:Cuna",
		Colegio = "Place:EntradaColegio",
		Pinos = "Zone:Los Pinos",
	},
	Tracks = {
		-- 1 · Cierre íntimo: Abu arropa la cuna; tu familia mira desde la puerta
		Camera = {
			{ At = 0, Duration = 3.6, Fixed = { "Cuna", V(3.4, 3.4, 4.6) }, Look = { "Cuna", V(0, 1.6, 0) }, Fov = { 54, 47 } },
			{ At = 3.6, Duration = 3.9, Shot = "PrimerPlano:Abu" },
			-- 3 · El mundo cambia: Los Pinos, seis años después; el colegio abre sus puertas
			{ At = NEW_WORLD_AT, Duration = 4, From = { "Pinos", V(-120, 70, 90) }, To = { "Colegio", V(-34, 20, 36) }, Look = { "Colegio", V(0, 3, 0) }, Cut = "Dip" },
			{ At = NEW_WORLD_AT + 4, Duration = ARRIVAL_AT - NEW_WORLD_AT - 4, Fixed = { "Colegio", V(7, 3.2, 17) }, Look = { "Colegio", V(-1, 2, 6) }, Fov = { 55, 50 } },
		},
		Actors = {
			{ At = 0, Use = { Key = "Abu", Npc = "Abu", Anchor = "Cuna", Offset = V(1.4, 0, 1.2), Face = { "Cuna" } } },
			{ At = 0, Use = { Key = "Familia", Npc = "Familia", Anchor = "Cuna", Offset = V(-2.2, 0, 2.4), Face = { "Cuna" } } },
			{ At = 0.2, Look = { Key = "Abu", At = "Cuna" } },
			{ At = 0.2, Mood = { Key = "Abu", Mood = "Calm" } },
			{ At = 2.4, Look = { Key = "Familia", At = "Abu" } },
			{ At = 5.6, Look = { Key = "Abu", At = "Familia" } },
			{ At = MEMORIES_AT + 0.2, Despawn = { Key = "Abu" } },
			{ At = MEMORIES_AT + 0.2, Despawn = { Key = "Familia" } },
			-- 3 · Lucía en la puerta; tus compañeros llegan andando (todavía no los conoces)
			{ At = NEW_WORLD_AT - 0.6, Spawn = { Key = "Lucia", Npc = "Lucia", Anchor = "Colegio", Offset = V(0, 0, 3), Face = { "Colegio", V(0, 0, 14) } } },
			{ At = NEW_WORLD_AT + 0.2, Enter = { Key = "Nico", Npc = "Nico", From = { "Colegio", V(-14, 0, 16) }, To = { "Colegio", V(-1.6, 0, 6) }, Walk = true, Run = true } },
			{ At = NEW_WORLD_AT + 1.2, Enter = { Key = "Sara", Npc = "Sara", From = { "Colegio", V(12, 0, 16) }, To = { "Colegio", V(1.2, 0, 6.4) }, Walk = true } },
			{ At = NEW_WORLD_AT + 2, Enter = { Key = "Omar", Npc = "Omar", From = { "Colegio", V(-8, 0, 18) }, To = { "Colegio", V(0, 0, 7.6) }, Walk = true } },
			{ At = NEW_WORLD_AT + 4.6, Gesture = { Key = "Lucia", Play = "Wave" } },
			{ At = NEW_WORLD_AT + 5, Look = { Key = "Lucia", At = "Nico" } },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Nico" } },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Sara" } },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Omar" } },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Lucia" } },
		},
		Lines = {
			{ At = 0.8, Speaker = "Abu", Text = "Shhh… Ya se ha dormido." },
			{ At = 2.8, Speaker = "Familia", Text = "Hoy se ha asomado al ventanal. Media hora mirando la ciudad." },
			{ At = 5.2, Speaker = "Abu", Text = "Mañana, y pasado, y al otro… Así se crece: un día detrás de otro." },
			{ At = NEW_WORLD_AT + 5.2, Speaker = "Lucia", Text = "¡Buenos días! ¿Primer día? Pasad, pasad. Los nervios se quedan en la puerta." },
		},
		Titles = {
			{ At = 4.4, Text = "CHAPTER.BEBE.TITLE", Sub = "Fin del capítulo", Duration = 2.8 },
			{ At = NEW_WORLD_AT + 0.8, Text = "Los Pinos", Sub = "El colegio de tu barrio", Duration = 3 },
		},
		Light = {
			{ At = 0, Preset = "InteriorCalido", Fade = 0.8 },
		},
		Ambience = {
			{ At = 0, Kind = "Casa" },
			{ At = NEW_WORLD_AT, Kind = "Colegio", Fade = 1.5 },
		},
		Music = {
			{ At = 0, Intensity = "Intima" },
			{ At = NEW_WORLD_AT, Play = "TemaValmar" },
		},
	},
}, {
	-- Foto 1: tus primeros pasos (Abu de rodillas, con los brazos abiertos)
	{
		{ If = { Completed = { "Bebe_AprendeACaminar" } }, Place = "FamiliaAbu",
			People = { { Npc = "Abu", Pose = "Cheer", Mood = "Joy" }, { Npc = "Familia", Pose = "Laugh", Mood = "Joy" } },
			Title = "Tus primeros pasos", Sub = "Directo a los brazos de tu abu",
			Line = { S = "Abu", T = "¡Mira, mira! ¡Ya viene sin agarrarse!" } },
		{ Place = "Cuna", People = { { Npc = "Abu", Mood = "Calm" } }, Title = "Tu primera noche en casa", Sub = "Alguien te vigiló el sueño" },
	},
	-- Foto 2: la casa (la cocina, la tele, los juguetes)
	{
		{ If = { Completed = { "Bebe_ExploraLaCasa" } }, Place = "HomeCocina",
			People = { { Npc = "Familia", Pose = "Point" }, { Npc = "Abu", Pose = "Laugh" } },
			Title = "La cocina, la tele, los juguetes", Sub = "Todo era nuevo. Todo era tuyo." },
		{ Place = "HomeSalon", People = { { Npc = "Familia", Pose = "Wave" } }, Title = "Tu casa", Sub = "Los Pinos, Valmar" },
	},
	-- Foto 3: las tardes en el parque (genérica: un bebé no recuerda, se lo cuentan)
	{
		{ Place = "JuegosParque", People = { { Npc = "Abu", Pose = "Wave", Mood = "Joy" }, { Npc = "Familia", Mood = "Joy" } },
			Title = "Las tardes en el parque", Sub = "CHAPTER.BEBE.OUTRO" },
	},
}, { "Seis años después", "Ya no eres un bebé" }, "B")

---------------------------------------------------------------------
-- NIÑO → ADOLESCENTE
-- ¿Qué pasa? Cierra el colegio después de tu último día; el verano pasa y llega el instituto.
-- ¿Quién siente qué? Lucía y Ramón: nostalgia contenida. Tus amigos: vértigo y ganas.
-- ¿Por qué ahora? Acabas primaria: la cápsula, la foto y la promesa del grupo están recién hechas.
-- ¿Qué cambia? El grupo crece (escala de adolescente) y el mundo se hace más grande: Campus Valmar.
-- ¿Qué debe recordar el jugador? Su grupo (con el nombre que eligió) y el amigo al que ayudó.
---------------------------------------------------------------------
local Nino_Adolescente = montage({
	Montaje = { From = "Nino", To = "Adolescente", Chapter = "Nino_ElColegio", Next = "Adolescente_Instituto" },
	Anchors = {
		Entrada = "Place:EntradaColegio",
		Instituto = "Place:PatioInstituto",
		Campus = "Zone:Campus Valmar",
	},
	Tracks = {
		Camera = {
			-- 1 · Ramón cierra la verja; Lucía se queda mirando el colegio vacío
			{ At = 0, Duration = 3.4, Fixed = { "Entrada", V(-7, 3, 13) }, Look = { "Entrada", V(0, 3, 3) }, Fov = { 56, 49 } },
			{ At = 3.4, Duration = 2.2, Shot = "Reaccion:Lucia" },
			{ At = 5.6, Duration = 1.9, Shot = "DosPlanos:Ramon,Lucia" },
			-- 3 · Campus Valmar: el instituto, con tus amigos ya adolescentes
			{ At = NEW_WORLD_AT, Duration = 3.8, From = { "Campus", V(-200, 120, 150) }, To = { "Instituto", V(-40, 26, 40) }, Look = { "Instituto", V(0, 4, 0) }, Cut = "Dip" },
			{ At = NEW_WORLD_AT + 3.8, Duration = ARRIVAL_AT - NEW_WORLD_AT - 3.8, Fixed = { "Instituto", V(6, 3.6, 16) }, Look = { "Instituto", V(0, 2.8, 5) }, Fov = { 56, 50 } },
		},
		Actors = {
			{ At = 0, Spawn = { Key = "Ramon", Npc = "Ramon", Anchor = "Entrada", Offset = V(1.5, 0, 2), Face = { "Entrada" } } },
			{ At = 0, Spawn = { Key = "Lucia", Npc = "Lucia", Anchor = "Entrada", Offset = V(-1.5, 0, 4), Face = { "Entrada" } } },
			{ At = 0.3, Look = { Key = "Lucia", At = "Entrada" } },
			{ At = 1.6, Look = { Key = "Ramon", At = "Lucia" } },
			{ At = 4.6, Mood = { Key = "Lucia", Mood = "Sad" } },
			{ At = 6.2, Look = { Key = "Lucia", At = "Ramon" } },
			{ At = MEMORIES_AT + 0.2, Despawn = { Key = "Ramon" } },
			{ At = MEMORIES_AT + 0.2, Despawn = { Key = "Lucia" } },
			-- 3 · Ya no caben en el pupitre: escala de adolescente (0,85)
			{ At = NEW_WORLD_AT - 0.6, Spawn = { Key = "Javier", Npc = "Javier", Anchor = "Instituto", Offset = V(-4, 0, 2), Face = { "Instituto", V(0, 0, 12) } } },
			{ At = NEW_WORLD_AT + 0.4, Enter = { Key = "Nico", Npc = "Nico", Scale = 0.85, From = { "Instituto", V(-12, 0, 18) }, To = { "Instituto", V(-1.8, 0, 6) }, Walk = true } },
			{ At = NEW_WORLD_AT + 0.8, Enter = { Key = "Sara", Npc = "Sara", Scale = 0.85, From = { "Instituto", V(-10, 0, 20) }, To = { "Instituto", V(0.2, 0, 6.6) }, Walk = true } },
			{ At = NEW_WORLD_AT + 1.2, Enter = { Key = "Omar", Npc = "Omar", Scale = 0.85, From = { "Instituto", V(-14, 0, 20) }, To = { "Instituto", V(2, 0, 6) }, Walk = true } },
			{ At = NEW_WORLD_AT + 2.4, Enter = { Key = "Leire", Npc = "Leire", Scale = 0.85, From = { "Instituto", V(14, 0, 10) }, To = { "Instituto", V(7, 0, 3) }, Walk = true } },
			{ At = NEW_WORLD_AT + 5, Look = { Key = "Nico", At = "Javier" } },
			{ At = NEW_WORLD_AT + 5.6, Gesture = { Key = "Javier", Play = "Wave" } },
			{ At = NEW_WORLD_AT + 6.4, Look = { Key = "Leire", At = "Omar" } },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Nico" } },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Sara" } },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Omar" } },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Leire" } },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Javier" } },
		},
		Lines = {
			{ At = 0.6, Speaker = "Ramon", Text = "Otro curso que se va. ¿Cierro ya, Lucía?" },
			{ At = 2.6, Speaker = "Ramon", Text = "La cápsula del tiempo, enterrada. Dentro de veinte años, a ver quién se acuerda.", If = { Flags = { "CapsulaDelTiempo" } } },
			{ At = 4.4, Speaker = "Lucia", Text = "Un minuto más, Ramón. Estos… estos se me van a hacer difíciles de olvidar.", IfNot = { Flags = { "SecretoLucia" } } },
			{ At = 4.4, Speaker = "Lucia", Text = "Un minuto más. Alguien de esa clase guardó mi secreto todo el curso. No se me va a olvidar.", If = { Flags = { "SecretoLucia" } } },
			{ At = NEW_WORLD_AT + 4.4, Speaker = "Nico", Text = "¡Es ENORME! ¿Esto tiene ascensor?" },
			{ At = NEW_WORLD_AT + 6.2, Speaker = "Omar", Text = "Juntos contra el puré, ¿os acordáis? Pues seguimos en pie.", If = { Choices = { Promesa = "Juntos" } } },
			{ At = NEW_WORLD_AT + 6.2, Speaker = "Sara", Text = "Tres edificios, dos pistas y un comedor que, según las estadísticas, es peor.", IfNot = { Choices = { Promesa = "Juntos" } } },
		},
		Titles = {
			{ At = 4.6, Text = "CHAPTER.NINO.TITLE", Sub = "Fin del capítulo", Duration = 2.6 },
			{ At = NEW_WORLD_AT + 0.8, Text = "CINE.INSTITUTO.LLEGA", Duration = 3 },
		},
		Light = {
			{ At = 0, Preset = "Atardecer", Fade = 0.8 },
		},
		Ambience = {
			{ At = 0, Kind = "Calle" },
			{ At = NEW_WORLD_AT, Kind = "Instituto", Fade = 1.5 },
		},
		Music = {
			{ At = 0, Intensity = "Intima" },
			{ At = NEW_WORLD_AT, Intensity = "Descubrimiento" },
		},
	},
}, {
	-- Foto 1: el amigo al que ayudaste
	{
		{ If = { Flags = { "AyudasteAMateo" } }, Place = "CaminoAlCole",
			People = { { Npc = "Mateo", Pose = "Wave", Mood = "Joy" }, { Npc = "Dani", Mood = "Joy" } },
			Title = "Mateo", Sub = "Le ayudaste a recoger sus libros. Fue tu primer amigo." },
		{ If = { Flags = { "HugoConElGrupo" } }, Place = "CaminoAlCole",
			People = { { Npc = "Hugo", Mood = "Joy" } },
			Title = "Hugo", Sub = "Dejó a Bruno y se vino con vosotros" },
		{ If = { Memories = { "Detective" } }, Place = "EntradaColegio",
			People = { { Npc = "Iker", Pose = "Point" }, { Npc = "Ruben", Mood = "Shame" } },
			Title = "El caso de las bromas", Sub = "Descubriste quién era. Y no se lo contaste a todo el mundo." },
		{ Place = "EntradaColegio", People = { { Npc = "Lucia", Pose = "Wave" } }, Title = "Tu primer día de colegio", Sub = "«Pasad, pasad.» Y pasaste." },
	},
	-- Foto 2: tu grupo, con su nombre
	{
		{ If = { Memories = { "PrimerGrupo" } }, Place = "SpotParqueReunion",
			People = concat({ { Npc = "Nico", Pose = "Cheer" }, { Npc = "Sara", Pose = "Laugh" }, { Npc = "Omar", Pose = "Cheer" } }, extraFriends()),
			Title = "Tu grupo", Sub = "Nico, Sara, Omar… y tu sitio en el banco",
			Titles = groupTitles("Nico, Sara, Omar… y tu sitio en el banco") },
		{ Place = "JuegosParque", People = { { Npc = "Nico", Pose = "Cheer" }, { Npc = "Sara" }, { Npc = "Omar", Pose = "Laugh" } },
			Title = "Las tardes en el parque", Sub = "Nico, Sara y Omar" },
	},
	-- Foto 3: el gran momento del colegio
	{
		{ If = { Memories = { "PrimerTorneo" } }, Place = "CanchaColegio",
			People = { { Npc = "Andres", Pose = "Cheer" }, { Npc = "Nico", Pose = "Cheer" }, { Npc = "Alex", Pose = "Cheer" } },
			Title = "El torneo del colegio", Sub = "Andrés todavía grita «¡defensa!» en sueños" },
		{ If = { Memories = { "PrimeraExcursion" } }, Place = "GranjaPatio",
			People = { { Npc = "Julian", Pose = "Wave" }, { Npc = "Paula" }, { Npc = "Sara", Pose = "Point" } },
			Title = "La excursión a Villaverde", Sub = "Paula se sabía el nombre de cada gallina" },
		{ If = { Memories = { "ProyectoFinal" } }, Place = "EntradaColegio",
			People = { { Npc = "Sara", Pose = "Point" }, { Npc = "Omar" }, { Npc = "Lucia", Pose = "Cheer" } },
			Title = "El proyecto de Ciencias", Sub = "Delante de todas las familias" },
		{ Place = "EntradaColegio", People = { { Npc = "Lucia", Pose = "Wave" }, { Npc = "Ramon", Pose = "Wave" } },
			Title = "CHAPTER.NINO.OUTRO", Sub = "Seis años en el colegio de Los Pinos" },
	},
}, { "TRANSITION.INSTITUTO", "Septiembre. Primer día." }, "N")

---------------------------------------------------------------------
-- ADOLESCENTE → JOVEN
-- ¿Qué pasa? La noche de la gran decisión, en casa; luego, la universidad o el trabajo.
-- ¿Quién siente qué? Tu familia y Abu: orgullo y miedo a que te vayas. Tú: el futuro de golpe.
-- ¿Por qué ahora? Acabas de elegir tu camino (Futuro: estudiar o trabajar).
-- ¿Qué cambia? Cumples dieciocho: el mundo es el campus o el centro de la ciudad.
-- ¿Qué debe recordar el jugador? El cruce de caminos, su club y que el grupo sigue ahí.
---------------------------------------------------------------------
local UNI = { Flags = { "VaALaUniversidad" } }
local Adolescente_Joven = montage({
	Montaje = { From = "Adolescente", To = "AdultoJoven", Chapter = "Adolescente_Instituto", Next = "Joven_Universidad|Adulto_VolarDelNido" },
	Anchors = {
		Casa = "Place:CasaFamiliar",
		Uni = "Place:Universidad",
		Plaza = "Place:PlazaCentro",
		Campus = "Zone:Campus Valmar",
		Centro = "Zone:Valmar Centro",
	},
	Tracks = {
		Camera = {
			-- 1 · De noche, en la puerta de casa: Abu mira las estrellas; tu familia sale con dos tazas
			{ At = 0, Duration = 3.2, Fixed = { "Casa", V(-8, 4, 14) }, Look = { "Casa", V(0, 3, 4) }, Fov = { 52, 46 } },
			{ At = 3.2, Duration = 4.3, Shot = "DosPlanos:Abu,Familia" },
			-- 3 · La universidad… o el centro de la ciudad, según lo que elegiste
			{ At = NEW_WORLD_AT, Duration = 3.8, From = { "Campus", V(-220, 120, 180) }, To = { "Uni", V(-50, 28, 50) }, Look = { "Uni", V(0, 8, 0) }, Cut = "Dip", If = UNI },
			{ At = NEW_WORLD_AT + 3.8, Duration = ARRIVAL_AT - NEW_WORLD_AT - 3.8, Fixed = { "Uni", V(7, 4, 18) }, Look = { "Uni", V(0, 3, 6) }, Fov = { 56, 50 }, If = UNI },
			{ At = NEW_WORLD_AT, Duration = 3.8, From = { "Centro", V(150, 120, 200) }, To = { "Plaza", V(40, 24, 50) }, Look = { "Plaza", V(0, 5, 0) }, Cut = "Dip", IfNot = UNI },
			{ At = NEW_WORLD_AT + 3.8, Duration = ARRIVAL_AT - NEW_WORLD_AT - 3.8, Fixed = { "Plaza", V(8, 4, 18) }, Look = { "Plaza", V(0, 3, 6) }, Fov = { 56, 50 }, IfNot = UNI },
		},
		Actors = {
			{ At = 0, Spawn = { Key = "Abu", Npc = "Abu", Anchor = "Casa", Offset = V(1.2, 0, 4), Face = { "Casa", V(0, 0, 14) } } },
			{ At = 0.4, Look = { Key = "Abu", At = "Away" } },
			{ At = 1.4, Enter = { Key = "Familia", Npc = "Familia", From = { "Casa", V(-1, 0, 1) }, To = { "Casa", V(-1.4, 0, 4.4) }, Walk = true } },
			{ At = 3.4, Look = { Key = "Abu", At = "Familia" } },
			{ At = 3.6, Look = { Key = "Familia", At = "Abu" } },
			{ At = MEMORIES_AT + 0.2, Despawn = { Key = "Abu" } },
			{ At = MEMORIES_AT + 0.2, Despawn = { Key = "Familia" } },
			-- 3 · Campus: Sara, ya adulta, con su primera carpeta; Beltrán, en la puerta de la facultad
			{ At = NEW_WORLD_AT - 0.6, Spawn = { Key = "Beltran", Npc = "Beltran", Anchor = "Uni", Offset = V(-3, 0, 3), Face = { "Uni", V(0, 0, 14) } }, If = UNI },
			{ At = NEW_WORLD_AT + 0.6, Enter = { Key = "Sara", Npc = "Sara", Scale = 1, From = { "Uni", V(-12, 0, 20) }, To = { "Uni", V(0, 0, 6) }, Walk = true }, If = UNI },
			{ At = NEW_WORLD_AT + 1.2, Enter = { Key = "Luca", Npc = "Luca", From = { "Uni", V(12, 0, 16) }, To = { "Uni", V(2.4, 0, 5) }, Walk = true }, If = UNI },
			{ At = NEW_WORLD_AT + 5.2, Gesture = { Key = "Luca", Play = "Wave" }, If = UNI },
			{ At = NEW_WORLD_AT + 5.6, Look = { Key = "Sara", At = "Luca" }, If = UNI },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Beltran" }, If = UNI },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Sara" }, If = UNI },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Luca" }, If = UNI },
			-- 3 · Centro: la ciudad trabaja; Ernesto reparte, Lola abre la cafetería
			{ At = NEW_WORLD_AT - 0.6, Spawn = { Key = "Lola", Npc = "Lola", Anchor = "Plaza", Offset = V(3, 0, 4), Face = { "Plaza", V(0, 0, 14) } }, IfNot = UNI },
			{ At = NEW_WORLD_AT + 0.6, Enter = { Key = "Ernesto", Npc = "Ernesto", From = { "Plaza", V(-14, 0, 16) }, To = { "Plaza", V(-1, 0, 6) }, Walk = true }, IfNot = UNI },
			{ At = NEW_WORLD_AT + 1.4, Enter = { Key = "Omar", Npc = "Omar", Scale = 1, From = { "Plaza", V(12, 0, 18) }, To = { "Plaza", V(1.6, 0, 6.6) }, Walk = true }, IfNot = UNI },
			{ At = NEW_WORLD_AT + 5.2, Gesture = { Key = "Ernesto", Play = "Wave" }, IfNot = UNI },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Lola" }, IfNot = UNI },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Ernesto" }, IfNot = UNI },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Omar" }, IfNot = UNI },
		},
		Lines = {
			{ At = 1.6, Speaker = "Familia", Text = "Todavía hay luz en su cuarto." },
			{ At = 3.6, Speaker = "Abu", Text = "Déjale pensar. Las decisiones grandes se toman de noche y se cuentan por la mañana." },
			{ At = 6, Speaker = "Familia", Text = "Ha dejado la solicitud en la mesa. Rellenada.", If = UNI },
			{ At = 6, Speaker = "Familia", Text = "Mañana empieza a trabajar. Qué rápido, ¿no?", If = { Flags = { "EmpiezaATrabajar" } } },
			{ At = NEW_WORLD_AT + 4.6, Speaker = "Sara", Text = "Primer curso. Lo he dicho en voz alta y me he mareado un poco.", If = UNI },
			{ At = NEW_WORLD_AT + 6.4, Speaker = "Luca", Text = "Benvenuti! Bienvenidos. Primero, la cafetería. Luego, la vida.", If = UNI },
			{ At = NEW_WORLD_AT + 4.6, Speaker = "Ernesto", Text = "¡Buenos días! Aquí se madruga, ¿eh? Las cartas no se reparten solas.", IfNot = UNI },
			{ At = NEW_WORLD_AT + 6.4, Speaker = "Omar", Text = "¡Eh! ¡Que ahora somos gente que trabaja! Esto hay que celebrarlo con un bocadillo.", IfNot = UNI },
		},
		Titles = {
			{ At = 4.8, Text = "CHAPTER.INSTITUTO.TITLE", Sub = "Fin del capítulo", Duration = 2.5 },
			{ At = NEW_WORLD_AT + 0.8, Text = "Campus Valmar", Sub = "La universidad", Duration = 3, If = UNI },
			{ At = NEW_WORLD_AT + 0.8, Text = "Valmar Centro", Sub = "La ciudad que trabaja", Duration = 3, IfNot = UNI },
		},
		Light = {
			{ At = 0, Preset = "Noche", Fade = 0.8 },
		},
		Ambience = {
			{ At = 0, Kind = "Calle" },
			{ At = NEW_WORLD_AT, Kind = "Universidad", Fade = 1.5, If = UNI },
			{ At = NEW_WORLD_AT, Kind = "Calle", Fade = 1.5, IfNot = UNI },
		},
		Music = {
			{ At = 0, Intensity = "Intima" },
			{ At = NEW_WORLD_AT, Play = "VidaAdulta" },
		},
	},
}, {
	-- Foto 1: el cruce de caminos (la pandilla de Rayo, la noche del súper, el primer sueldo…)
	{
		{ If = { Flags = { "RayoCambia" } }, Place = "PuertoDeportivo", Era = 0.85,
			People = { { Npc = "Rayo", Pose = "Wave" }, { Npc = "Nerea" } },
			Title = "Rayo", Sub = "Cambió de camino. Un poco gracias a ti." },
		{ If = { Memories = { "LaNoche" } }, Place = "Supermercado",
			People = { { Npc = "Paco", Mood = "Calm" }, { Npc = "Ines" } },
			Title = "La noche del supermercado", Sub = "Hay noches que te cambian" },
		{ If = { Memories = { "PrimerSueldo" } }, Place = "CafeteriaCentral",
			People = { { Npc = "Lola", Pose = "Cheer", Mood = "Joy" } },
			Title = "Tu primer sueldo", Sub = "El verano en que aprendiste lo que cuesta ganarlo" },
		{ Place = "PatioInstituto", Era = 0.85, People = { { Npc = "Javier" }, { Npc = "Nico", Pose = "Wave" }, { Npc = "Sara" } },
			Title = "Tu primer día de instituto", Sub = "Y aquel «ascensor de alumnos»" },
	},
	-- Foto 2: tu club (con quien lo llevaba) o la gente nueva
	{
		{ If = { Memories = { "PrimerClub" } }, Place = "PistaInstituto", Era = 0.85,
			People = {
				{ Npc = "Alex", Pose = "Cheer", If = { Choices = { Club = "Baloncesto" } } },
				{ Npc = "Ruben", Pose = "Laugh", If = { Choices = { Club = "Teatro" } } },
				{ Npc = "Sara", Pose = "Point", If = { Choices = { Club = "Robotica" } } },
				{ Npc = "Hugo", If = { Choices = { Club = "Periodico" } } },
				{ Npc = "Leire", Pose = "Point", If = { Choices = { Club = "Fotografia" } } },
				{ Npc = "Omar", Pose = "Wave" },
			},
			Title = "Tu primer club", Sub = "Cada club era un mundo",
			Titles = {
				{ If = { Choices = { Club = "Baloncesto" } }, Text = "El club de baloncesto", Sub = "Álex apostaba por ti (sin dinero)" },
				{ If = { Choices = { Club = "Teatro" } }, Text = "El club de teatro", Sub = "Rubén, por fin, hacía reír a propósito" },
				{ If = { Choices = { Club = "Robotica" } }, Text = "El club de robótica", Sub = "Sara y sus palabras largas" },
				{ If = { Choices = { Club = "Periodico" } }, Text = "El periódico del instituto", Sub = "Hugo escribía bajito y muy bien" },
				{ If = { Choices = { Club = "Fotografia" } }, Text = "El club de fotografía", Sub = "La cámara vieja de Leire" },
			} },
		{ If = { Flags = { "ConocesALeire" } }, Place = "PatioInstituto", Era = 0.85,
			People = { { Npc = "Leire", Pose = "Point" } },
			Title = "Leire", Sub = "Llegó del norte con una cámara vieja al cuello" },
		{ Place = "PatioInstituto", People = { { Npc = "Carmen", Mood = "Calm" } },
			Title = "La semana de las profesiones", Sub = "«No tienes que saberlo hoy.»" },
	},
	-- Foto 3: el grupo, que sigue ahí
	{
		{ If = { Memories = { "ElRumor" } }, Place = "SpotParqueReunion", Era = 0.85,
			People = { { Npc = "Omar", Pose = "Laugh" }, { Npc = "Nico", Pose = "Laugh" }, { Npc = "Sara" } },
			Title = "La foto de Omar", Sub = "Y cómo lo arreglasteis" },
		{ Place = "SpotParqueReunion", Era = 0.85,
			People = concat({ { Npc = "Nico", Pose = "Cheer" }, { Npc = "Sara", Pose = "Laugh" }, { Npc = "Omar", Pose = "Cheer" } }, extraFriends(0.85)),
			Title = "Los de siempre", Sub = "El banco del parque se os quedó pequeño",
			Titles = groupTitles("El banco del parque se os quedó pequeño") },
	},
}, { "Dieciocho años", "TRANSITION.MAYOR_EDAD" }, "A")

---------------------------------------------------------------------
-- JOVEN → ADULTO
-- ¿Qué pasa? La noche del reencuentro, en el banco del parque; pasan los años y la vida se asienta.
-- ¿Quién siente qué? Omar, Nico y Sara: felicidad tranquila, la de estar juntos otra vez.
-- ¿Por qué ahora? Acabáis de hacer una promesa nueva (PromesaAdulta) en el mismo banco de los diez años.
-- ¿Qué cambia? La vida adulta de verdad: Lucía dirige el colegio y otros niños empiezan su historia.
-- ¿Qué debe recordar el jugador? La promesa a Abu, su primer trabajo o su carrera, y el grupo entero.
---------------------------------------------------------------------
local Joven_Adulto = montage({
	Montaje = { From = "AdultoJoven", To = "Adulto", Chapter = "Adulto_VolarDelNido", Next = "Adulto_TuVida" },
	Anchors = {
		Parque = "Place:Parque",
		Colegio = "Place:EntradaColegio",
		Pinos = "Zone:Los Pinos",
	},
	Tracks = {
		Camera = {
			-- 1 · El banco, de noche: los tres apretados; ya no caben (aquí la edad no cambia de tamaño)
			{ At = 0, Duration = 3.4, Fixed = { "Parque", V(-3, 3.4, 14) }, Look = { "Parque", V(0, 2, 4) }, Fov = { 52, 45 } },
			{ At = 3.4, Duration = 4.1, Shot = "DosPlanos:Omar,Nico" },
			-- 3 · Los Pinos, años después: Lucía, directora, recibe a otros niños
			{ At = NEW_WORLD_AT, Duration = 3.8, From = { "Pinos", V(-140, 80, 100) }, To = { "Colegio", V(-34, 20, 36) }, Look = { "Colegio", V(0, 3, 0) }, Cut = "Dip" },
			{ At = NEW_WORLD_AT + 3.8, Duration = ARRIVAL_AT - NEW_WORLD_AT - 3.8, Fixed = { "Colegio", V(7, 3.2, 17) }, Look = { "Colegio", V(-1, 2.2, 6) }, Fov = { 55, 50 } },
		},
		Actors = {
			-- (los del banco de Adu03 si siguen ahí; si no, aparecen sentados donde estaban)
			{ At = 0, Use = { Key = "Omar", Npc = "Omar", Anchor = "Parque", Offset = V(-2, 0, 4), Scale = 1 } },
			{ At = 0, Use = { Key = "Nico", Npc = "Nico", Anchor = "Parque", Offset = V(0, 0, 4), Scale = 1 } },
			{ At = 0, Use = { Key = "Sara", Npc = "Sara", Anchor = "Parque", Offset = V(2, 0, 4), Scale = 1 } },
			{ At = 0.4, Look = { Key = "Omar", At = "Away" } },
			{ At = 2.2, Look = { Key = "Nico", At = "Omar" } },
			{ At = 4, Gesture = { Key = "Nico", Play = "Laugh" } },
			{ At = 5.2, Look = { Key = "Sara", At = "Nico" } },
			{ At = MEMORIES_AT + 0.2, Despawn = { Key = "Omar" } },
			{ At = MEMORIES_AT + 0.2, Despawn = { Key = "Nico" } },
			{ At = MEMORIES_AT + 0.2, Despawn = { Key = "Sara" } },
			-- 3 · Otra generación entra por la misma puerta
			{ At = NEW_WORLD_AT - 0.6, Spawn = { Key = "Lucia", Npc = "Lucia", Anchor = "Colegio", Offset = V(0, 0, 3), Face = { "Colegio", V(0, 0, 14) } } },
			{ At = NEW_WORLD_AT + 0.4, Enter = { Key = "Nina1", Npc = "Alba", Name = "Una alumna nueva", From = { "Colegio", V(-12, 0, 16) }, To = { "Colegio", V(-1.4, 0, 6) }, Walk = true, Run = true } },
			{ At = NEW_WORLD_AT + 1.2, Enter = { Key = "Nino1", Npc = "Dario", Name = "Un alumno nuevo", Scale = 0.62, From = { "Colegio", V(12, 0, 16) }, To = { "Colegio", V(1.2, 0, 6.4) }, Walk = true } },
			{ At = NEW_WORLD_AT + 4.6, Gesture = { Key = "Lucia", Play = "Wave" } },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Lucia" } },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Nina1" } },
			{ At = ARRIVAL_AT + 0.3, Despawn = { Key = "Nino1" } },
		},
		Lines = {
			{ At = 0.8, Speaker = "Omar", Text = "Diez años, y ya no cabíamos. Ahora ni con calzador." },
			{ At = 3.6, Speaker = "Nico", Text = "¿Villaverde, entonces? Yo llevo el balón. Sara, la ciencia.", If = { Choices = { PromesaAdulta = "Viaje" } } },
			{ At = 3.6, Speaker = "Sara", Text = "Hijos que sean amigos. Estadísticamente improbable. Lo vamos a conseguir.", If = { Choices = { PromesaAdulta = "Hijos" } } },
			{ At = 3.6, Speaker = "Nico", Text = "Para siempre. Lo has dicho tú. Ya no hay vuelta atrás.", If = { Choices = { PromesaAdulta = "Siempre" } } },
			{ At = 5.6, Speaker = "Sara", Text = "Esto, de mayores, también va a ser así. Lo sé. Tengo datos.", IfNot = { Choices = { PromesaAdulta = "Hijos" } } },
			{ At = NEW_WORLD_AT + 5, Speaker = "Lucia", Text = "¡Buenos días! Pasad, pasad. …Hace años que digo lo mismo, y me sigue gustando." },
		},
		Titles = {
			{ At = NEW_WORLD_AT + 0.8, Text = "Los Pinos, años después", Sub = "El colegio sigue abriendo cada septiembre", Duration = 3 },
			{ At = NEW_WORLD_AT + 0.85, Text = "Los Pinos, años después", Sub = "Algún día, vuestros hijos entrarán por esa puerta", Duration = 3, If = { Choices = { PromesaAdulta = "Hijos" } } },
		},
		Light = {
			{ At = 0, Preset = "Noche", Fade = 0.8 },
		},
		Ambience = {
			{ At = 0, Kind = "Parque" },
			{ At = NEW_WORLD_AT, Kind = "Colegio", Fade = 1.5 },
		},
		Music = {
			{ At = 0, Intensity = "Intima" },
			{ At = NEW_WORLD_AT, Play = "VidaAdulta" },
		},
	},
}, {
	-- Foto 1: Abu y la promesa del atardecer
	{
		{ If = { Memories = { "AtardecerConAbu" } }, Place = "Playa",
			People = { { Npc = "Abu", Mood = "Calm" } },
			Title = "El mar, con tu abu", Sub = "Como cuando era joven",
			Titles = {
				{ If = { Choices = { PromesaAbu = "Volver" } }, Text = "El mar, con tu abu", Sub = "Le prometiste volver cada año" },
				{ If = { Choices = { PromesaAbu = "CosasBonitas" } }, Text = "El mar, con tu abu", Sub = "Le prometiste hacer cosas bonitas" },
				{ If = { Choices = { PromesaAbu = "Familia" } }, Text = "El mar, con tu abu", Sub = "Le prometiste cuidar de la familia" },
			},
			Line = { S = "Abu", T = "Cada año. Me vale.", If = { Choices = { PromesaAbu = "Volver" } } } },
		{ Place = "CasaFamiliar", People = { { Npc = "Abu", Pose = "Wave" }, { Npc = "Familia", Pose = "Wave" } },
			Title = "Tu familia", Sub = "El nido sigue ahí cuando vuelves" },
	},
	-- Foto 2: tu carrera o tu primer trabajo
	{
		{ If = { Memories = { "Graduacion" } }, Place = "Universidad",
			People = { { Npc = "Beltran", Mood = "Calm" }, { Npc = "Julia", Pose = "Cheer" }, { Npc = "Ivan", Pose = "Cheer" } },
			Title = "Tu graduación", Sub = "Beltrán casi sonrió. Casi." },
		{ If = { Memories = { "PrimerContrato" } }, Place = "PlazaCentro",
			People = { { Npc = "Ernesto", Pose = "Wave" }, { Npc = "Lola", Pose = "Cheer" } },
			Title = "Tu primer contrato", Sub = "Un lunes cualquiera… que no era cualquiera" },
		{ Place = "CafeteriaCentral", People = { { Npc = "Lola", Pose = "Cheer" } },
			Title = "Tus primeros trabajos", Sub = "Lola decía que eras «la mejor ayuda de verano»" },
	},
	-- Foto 3: la Cafetería de Omar, todos otra vez (los que se sumaron, también)
	{
		{ Place = "CafeteriaCentral",
			People = concat({
				{ Npc = "Omar", Pose = "Cheer", Scale = 1 },
				{ Npc = "Lola", Pose = "Laugh" },
				{ Npc = "Nico", Pose = "Cheer", Scale = 1 },
				{ Npc = "Sara", Scale = 1 },
				{ Npc = "Bruno", Scale = 1, If = { Choices = { AdiosBruno = "DeCero" } } },
				{ Npc = "Leire", Scale = 1, If = { Flags = { "ConocesALeire" } } },
			}, extraFriends(1)),
			Title = "La Cafetería de Omar", Sub = "Todos otra vez",
			Titles = groupTitles("Todos otra vez, en la Cafetería de Omar") },
	},
}, { "Años después", "Tu vida es tuya" }, "J")

---------------------------------------------------------------------
-- FINAL DE LA VIDA · Vida_MirarAtras (M-07)
-- ¿Qué pasa? Muchos años después vuelves a la casa de Los Pinos, abres el álbum y llega tu gente.
-- ¿Quién siente qué? Tú: nostalgia serena. Tus amigos: la alegría de seguir ahí. Nadie está triste.
-- ¿Por qué ahora? Has vivido casi toda la etapa adulta: es el momento de mirar atrás.
-- ¿Qué cambia? Nada se pierde: la historia sigue, pero ahora se ve entera.
-- ¿Qué debe recordar el jugador? Una foto de cada etapa, las promesas (a Abu, al grupo) y quién vino.
---------------------------------------------------------------------
local ALBUM_AT = 12.5
local PEOPLE_AT = ALBUM_AT + 5 * SLOT -- 35.5: llega tu gente
local CLOSE_AT = PEOPLE_AT + 15 -- 50.5: la cámara sube al cielo de Valmar
local LIFE_DURATION = CLOSE_AT + 10

local function arrive(key: string, npc: string, x: number, at: number, cond: { [string]: any }?): { { [string]: any } }
	return {
		with({ At = at, Enter = { Key = key, Npc = npc, Scale = 1, Mood = "Joy", From = { "Casa", V(x * 1.6, 0, 26) }, To = { "Casa", V(x, 0, 8 + math.abs(x) * 0.15) }, Walk = true } }, cond),
		with({ At = at + 6.5, Look = { Key = key, At = "Yo" } }, cond),
		with({ At = LIFE_DURATION - 0.3, Despawn = { Key = key } }, cond),
	}
end

local lifeActors = concat(
	-- La familia que te espera en la puerta (una sola: la primera que se cumple)
	{
		{ At = 6, Enter = { Key = "Hija", Npc = "Madre", Name = "Tu hija", From = { "Casa", V(0, 0, 1) }, To = { "Casa", V(-1.6, 0, 4.4) }, Walk = true, Mood = "Joy" }, If = { Choices = { PromesaAdulta = "Hijos" } } },
		{ At = 6.6, Enter = { Key = "Nieta", Npc = "Alba", Name = "Tu nieta", From = { "Casa", V(0.6, 0, 1) }, To = { "Casa", V(0.6, 0, 5) }, Walk = true, Run = true, Mood = "Joy" }, If = { Choices = { PromesaAdulta = "Hijos" } } },
		{ At = 9, Gesture = { Key = "Nieta", Play = "Wave" }, If = { Choices = { PromesaAdulta = "Hijos" } } },
		{ At = LIFE_DURATION - 0.3, Despawn = { Key = "Hija" }, If = { Choices = { PromesaAdulta = "Hijos" } } },
		{ At = LIFE_DURATION - 0.3, Despawn = { Key = "Nieta" }, If = { Choices = { PromesaAdulta = "Hijos" } } },
		{ At = 6, Enter = { Key = "Pareja", Npc = "Padre", Name = "Tu pareja", From = { "Casa", V(0, 0, 1) }, To = { "Casa", V(-1.4, 0, 4.6) }, Walk = true, Mood = "Joy" }, If = { Flags = { "TienePareja" }, NotChoices = { PromesaAdulta = "Hijos" } } },
		{ At = 9, Gesture = { Key = "Pareja", Play = "Wave" }, If = { Flags = { "TienePareja" }, NotChoices = { PromesaAdulta = "Hijos" } } },
		{ At = LIFE_DURATION - 0.3, Despawn = { Key = "Pareja" }, If = { Flags = { "TienePareja" }, NotChoices = { PromesaAdulta = "Hijos" } } },
		{ At = 6, Enter = { Key = "Familia", Npc = "Familia", From = { "Casa", V(0, 0, 1) }, To = { "Casa", V(-1.4, 0, 4.6) }, Walk = true, Mood = "Joy" }, If = { NotFlags = { "TienePareja" }, NotChoices = { PromesaAdulta = "Hijos" } } },
		{ At = 9, Gesture = { Key = "Familia", Play = "Wave" }, If = { NotFlags = { "TienePareja" }, NotChoices = { PromesaAdulta = "Hijos" } } },
		{ At = LIFE_DURATION - 0.3, Despawn = { Key = "Familia" }, If = { NotFlags = { "TienePareja" }, NotChoices = { PromesaAdulta = "Hijos" } } },
	},
	-- La gente que conociste: llegan andando por la calle, uno detrás de otro
	arrive("Omar", "Omar", -2, PEOPLE_AT),
	arrive("Nico", "Nico", 2, PEOPLE_AT + 0.6),
	arrive("Sara", "Sara", 0, PEOPLE_AT + 1.2),
	arrive("Lucia", "Lucia", 4.5, PEOPLE_AT + 2.2),
	arrive("Mateo", "Mateo", -4.5, PEOPLE_AT + 1.8, { Flags = { "AyudasteAMateo" } }),
	arrive("Hugo", "Hugo", 6.5, PEOPLE_AT + 2.8, { Flags = { "HugoConElGrupo" } }),
	arrive("Leire", "Leire", -6.5, PEOPLE_AT + 3.2, { Flags = { "ConocesALeire" } }),
	arrive("Bruno", "Bruno", 8.5, PEOPLE_AT + 3.8, { Choices = { AdiosBruno = "DeCero" } }),
	{
		{ At = PEOPLE_AT + 8.4, Gesture = { Key = "Nico", Play = "Wave" } },
		{ At = PEOPLE_AT + 11.2, Gesture = { Key = "Omar", Play = "Laugh" } },
		{ At = CLOSE_AT + 1.5, Gesture = { Key = "Sara", Play = "Cheer" } },
	}
)

local Vida_MirarAtras = {
	Duration = LIFE_DURATION,
	Skippable = true,
	FadeIn = true,
	FadeOut = true,
	Montaje = { From = "Adulto", Chapter = "Adulto_TuVida", Final = true },
	Anchors = {
		Casa = "Place:CasaFamiliar",
		Pinos = "Zone:Los Pinos",
		Centro = "Zone:Valmar Centro",
	},
	Tracks = {
		Camera = {
			-- 1 · Los Pinos al atardecer; la cámara baja hasta la casa donde creciste
			{ At = 0, Duration = 6, From = { "Pinos", V(-160, 110, 140) }, To = { "Casa", V(-26, 14, 30) }, Look = { "Casa", V(0, 3, 0) }, Easing = "Out" },
			-- 2 · Tú, en la puerta; sale tu familia
			{ At = 6, Duration = 3.2, Fixed = { "Casa", V(-7, 3.4, 13) }, Look = { "Casa", V(-0.5, 2.6, 4.5) }, Fov = { 55, 50 }, Cut = "Cut" },
			{ At = 9.2, Duration = 3.3, Shot = "Reaccion:Yo" },
			-- 4 · Llegan los tuyos: general de la calle, luego quien habla, luego tú
			{ At = PEOPLE_AT, Duration = 5, Fixed = { "Casa", V(10, 5, 22) }, Look = { "Casa", V(0, 2.6, 10) }, Fov = { 58, 52 }, Cut = "Dip" },
			{ At = PEOPLE_AT + 5, Duration = 3.5, Shot = "Medio:Nico" },
			{ At = PEOPLE_AT + 8.5, Duration = 3.2, Shot = "DosPlanos:Omar,Sara" },
			{ At = PEOPLE_AT + 11.7, Duration = CLOSE_AT - PEOPLE_AT - 11.7, Shot = "PrimerPlano:Yo" },
			-- 5 · Todos en la puerta; la cámara sube al cielo de Valmar
			{ At = CLOSE_AT, Duration = LIFE_DURATION - CLOSE_AT, From = { "Player", V(6, 4, 12) }, To = { "Casa", V(40, 120, 90) }, Look = { "Player", V(0, 2, 0) }, LookTo = { "Centro", V(0, 30, 0) }, Easing = "In" },
		},
		Actors = lifeActors,
		Lines = {
			{ At = 7, Speaker = "Narrador", Text = "La casa de Los Pinos. La puerta sigue chirriando igual." },
			{ At = 9.6, Speaker = "Narrador", Text = "Tu hija te espera con el álbum. Tu nieta ya lo ha abierto por la mitad.", If = { Choices = { PromesaAdulta = "Hijos" } } },
			{ At = 9.6, Speaker = "Narrador", Text = "Dentro te espera el álbum. Alguien lo ha dejado abierto por el principio.", IfNot = { Choices = { PromesaAdulta = "Hijos" } } },
			-- 3 · El álbum
			{ At = ALBUM_AT + 0.6, Speaker = "Narrador", Text = "Una foto por etapa. Una vida dentro de cada foto.", Duration = 3.4 },
			-- 4 · La gente que conociste
			{ At = PEOPLE_AT + 5.2, Speaker = "Nico", Text = "¿Qué? ¿Pensabas mirar el álbum sin nosotros?" },
			{ At = PEOPLE_AT + 8.6, Speaker = "Omar", Text = "He traído bocadillos. Por los viejos tiempos. Y por los nuevos." },
			{ At = PEOPLE_AT + 10.4, Speaker = "Sara", Text = "Grupo completo. Que conste en acta.", If = { Memories = { "PrimerGrupo" } } },
			{ At = PEOPLE_AT + 10.4, Speaker = "Sara", Text = "Todos aquí. Estadísticamente, un milagro. Emocionalmente, lo normal.", IfNot = { Memories = { "PrimerGrupo" } } },
			{ At = PEOPLE_AT + 12, Speaker = "Lucia", Text = "Cuarenta cursos dando clase. Y de esa clase me acuerdo de todo. No se lo digáis a nadie." },
			{ At = CLOSE_AT + 4.4, Speaker = "Nico", Text = "Y todavía me debes el viaje a Villaverde. Ya no tenemos treinta, pero el balón sí.", If = { Choices = { PromesaAdulta = "Viaje" } } },
			{ At = CLOSE_AT + 0.4, Speaker = "Omar", Text = "Este año también has ido a la playa, ¿verdad? Claro que sí. Siempre vas.", If = { Choices = { PromesaAbu = "Volver" } } },
			{ At = CLOSE_AT + 0.4, Speaker = "Omar", Text = "Has cuidado de todos. Como le prometiste a tu abu.", If = { Choices = { PromesaAbu = "Familia" } } },
			{ At = CLOSE_AT + 0.4, Speaker = "Omar", Text = "Cosas bonitas, dijo tu abu. Pues mira a tu alrededor.", If = { Choices = { PromesaAbu = "CosasBonitas" } } },
		},
		Titles = {
			{ At = 1.2, Text = "Los Pinos, Valmar", Sub = "Muchos años después", Duration = 3.6 },
			{ At = PEOPLE_AT + 0.8, Text = "La gente que conociste", Sub = "Y la que se quedó", Duration = 3.4 },
			{ At = PEOPLE_AT + 0.85, Text = "«Los Imparables»", Sub = "Y la gente que se quedó", Duration = 3.4, If = { Choices = { NombreGrupo = "Los Imparables" } } },
			{ At = PEOPLE_AT + 0.85, Text = "«La Patrulla Valmar»", Sub = "Y la gente que se quedó", Duration = 3.4, If = { Choices = { NombreGrupo = "La Patrulla Valmar" } } },
			{ At = PEOPLE_AT + 0.85, Text = "«Los del Banco Azul»", Sub = "Y la gente que se quedó", Duration = 3.4, If = { Choices = { NombreGrupo = "Los del Banco Azul" } } },
			{ At = PEOPLE_AT + 0.85, Text = "«Los Dinosaurios»", Sub = "Y la gente que se quedó", Duration = 3.4, If = { Choices = { NombreGrupo = "Los Dinosaurios" } } },
			{ At = CLOSE_AT + 3.4, Text = "Toda una vida en Valmar", Sub = "Y todavía queda mucho por vivir", Duration = 5.5 },
		},
		Light = {
			{ At = 0, Preset = "Atardecer", Fade = 1.2 },
			{ At = ALBUM_AT - 0.2, Preset = "Recuerdo", Fade = 0.6 },
			{ At = PEOPLE_AT - 0.1, Preset = "Atardecer", Fade = 0.8 },
		},
		Ambience = {
			{ At = 0, Kind = "Parque" },
			{ At = ALBUM_AT, Kind = "Casa", Fade = 1 },
			{ At = PEOPLE_AT, Kind = "Calle", Fade = 1.5 },
		},
		Music = {
			{ At = 0, Intensity = "Intima" },
			{ At = ALBUM_AT, Play = "PasanLosAnos" },
			{ At = PEOPLE_AT, Intensity = "Resolucion" },
			{ At = CLOSE_AT, Intensity = "Tema" },
		},
	},
}

-- El álbum: una foto viva por etapa (lo que viviste, o lo que te contaron)
addPhotos(Vida_MirarAtras, ALBUM_AT, {
	-- Bebé
	{
		{ Place = "Cuna", People = { { Npc = "Abu", Mood = "Joy" }, { Npc = "Familia", Mood = "Joy" } },
			Title = "El día que naciste", Sub = "Tu abu dijo tu nombre en voz alta, para que lo oyera el barrio" },
	},
	-- Niño
	{
		{ If = { Memories = { "PrimerGrupo" } }, Place = "SpotParqueReunion",
			People = concat({ { Npc = "Nico", Pose = "Cheer" }, { Npc = "Sara", Pose = "Laugh" }, { Npc = "Omar", Pose = "Cheer" } }, extraFriends()),
			Title = "Tu grupo del colegio", Sub = "Diez años y un banco del parque", Titles = groupTitles("Diez años y un banco del parque") },
		{ If = { Flags = { "AyudasteAMateo" } }, Place = "CaminoAlCole", People = { { Npc = "Mateo", Pose = "Wave" } },
			Title = "Mateo", Sub = "Tu primer amigo empezó con unos libros por el suelo" },
		{ Place = "EntradaColegio", People = { { Npc = "Lucia", Pose = "Wave" } }, Title = "Tu primer día de colegio", Sub = "«Pasad, pasad.»" },
	},
	-- Adolescente
	{
		{ If = { Memories = { "ElCruce" } }, Place = "PuertoDeportivo", Era = 0.85, People = { { Npc = "Rayo" }, { Npc = "Nerea" } },
			Title = "El cruce de caminos", Sub = "El día que elegiste quién ser" },
		{ If = { Flags = { "ConocesALeire" } }, Place = "PatioInstituto", Era = 0.85, People = { { Npc = "Leire", Pose = "Point" } },
			Title = "Leire", Sub = "Te hizo la mejor foto de tu vida y no te la enseñó hasta años después" },
		{ If = { Memories = { "PrimerClub" } }, Place = "PistaInstituto", Era = 0.85, People = { { Npc = "Omar", Pose = "Wave" }, { Npc = "Nico" } },
			Title = "Tu primer club", Sub = "El instituto, por dentro" },
		{ Place = "PatioInstituto", Era = 0.85, People = { { Npc = "Nico", Pose = "Wave" }, { Npc = "Sara" }, { Npc = "Omar" } },
			Title = "El instituto", Sub = "Los de siempre, un poco más altos" },
	},
	-- Joven
	{
		{ If = { Memories = { "Graduacion" } }, Place = "Universidad", People = { { Npc = "Beltran" }, { Npc = "Julia", Pose = "Cheer" } },
			Title = "Tu graduación", Sub = "Beltrán casi sonrió" },
		{ If = { Memories = { "PrimerContrato" } }, Place = "PlazaCentro", People = { { Npc = "Ernesto", Pose = "Wave" } },
			Title = "Tu primer contrato", Sub = "La primera nómina, enmarcada (un tiempo)" },
		{ Place = "CafeteriaCentral", People = { { Npc = "Lola", Pose = "Cheer" } }, Title = "Tus primeros trabajos", Sub = "Lola gritaba en la cocina y abrazaba fuera" },
	},
	-- Adulto: Abu
	{
		{ If = { Memories = { "AtardecerConAbu" } }, Place = "Playa", People = { { Npc = "Abu", Mood = "Calm" } },
			Title = "El atardecer con tu abu", Sub = "Playa Dorada",
			Titles = {
				{ If = { Choices = { PromesaAbu = "Volver" } }, Text = "El atardecer con tu abu", Sub = "Volviste cada año. Contigo o por ti." },
				{ If = { Choices = { PromesaAbu = "CosasBonitas" } }, Text = "El atardecer con tu abu", Sub = "Hiciste cosas bonitas. Muchas." },
				{ If = { Choices = { PromesaAbu = "Familia" } }, Text = "El atardecer con tu abu", Sub = "Cuidaste de la familia, como te cuidó a ti" },
			},
			Line = { S = "Abu", T = "Y que se note que eres feliz haciéndolas.", If = { Choices = { PromesaAbu = "CosasBonitas" } } } },
		{ If = { Memories = { "ElReencuentro" } }, Place = "CafeteriaCentral",
			People = { { Npc = "Omar", Pose = "Cheer", Scale = 1 }, { Npc = "Lola", Pose = "Laugh" }, { Npc = "Nico", Scale = 1 }, { Npc = "Sara", Scale = 1 } },
			Title = "El reencuentro", Sub = "La Cafetería de Omar" },
		{ Place = "CasaFamiliar", People = { { Npc = "Abu", Pose = "Wave" }, { Npc = "Familia", Pose = "Wave" } },
			Title = "Tu familia", Sub = "Los que te enseñaron a andar" },
	},
}, "V")

return {
	Montaje_Bebe_Nino = Bebe_Nino,
	Montaje_Nino_Adolescente = Nino_Adolescente,
	Montaje_Adolescente_Joven = Adolescente_Joven,
	Montaje_Joven_Adulto = Joven_Adulto,
	-- Los nombres viejos (Cole12 y Ins06 ya los usan en su paso Transition): el mismo montaje
	Nino_AInstituto = Nino_Adolescente,
	Adol_Selectividad = Adolescente_Joven,
	Vida_MirarAtras = Vida_MirarAtras,
}
