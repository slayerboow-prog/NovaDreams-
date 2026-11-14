-- Escenas de LA DERIVA (expansión espacial; docs/espacio-aaa/expansion-15h.md). Misión: Misiones/Deriva_ActoI.
-- Los sitios «Deriva_<Id>» son marcas StorySpot del pecio (World/DerelictBuilder; shared/Cosmos/Derelicts).
--
-- Lecciones de la revisión de las cinemáticas de Valmar que se aplican aquí:
--   * Cada plano mira a algo que EXISTE en el sitio (anclas del pecio), nunca al vacío.
--   * Los tiempos de las frases salen de ReadingTime (ninguna se pisa con la siguiente) y los planos se
--     colocan sobre esos tiempos, no al revés.
--   * Silencio de 2 s después de cada golpe (chispazo, crujido del casco) antes de la siguiente frase.
--   * Un plano de reacción tuyo en cada escena; planos medios, no la cara llenando la pantalla.
--   * Sin rótulos encima de las frases; sin emoji modernos (se ven como ▯ en Roblox).
--   * Tono para 13-15 años: hay muertos, pero fuera de plano; nadie sobreactúa.
-- Los REGISTROS que se escuchan en las salas son escenas LIGERAS (sin cámara: puedes seguir andando).

local ReadingTime = require(script.Parent.Parent.ReadingTime)

local V = Vector3.new

-- Coloca las frases una detrás de otra desde `start` (con el tiempo de lectura de cada una y un respiro)
-- y devuelve la lista y cuándo empieza y acaba cada una
local function lines(start: number, list: { { [string]: any } }): ({ { [string]: any } }, { number }, number)
	local out, starts = {}, {}
	local t = start
	for _, l in list do
		if l.Wait then
			t += l.Wait
		end
		local line = table.clone(l)
		line.Wait = nil
		line.At = math.floor(t * 10 + 0.5) / 10
		table.insert(out, line)
		table.insert(starts, line.At)
		t = line.At + ReadingTime.seconds(l.T) + 0.5
	end
	return out, starts, t
end

---------------------------------------------------------------------
-- Deriva_Misericordia_Entrada · al entrar por la esclusa.
--   ¿Qué pasa? Pisas por primera vez la Misericordia: oscuridad, camillas, el zumbido de lo que queda vivo.
--   ¿Qué quiero que sienta el jugador? Respeto y frío. Esto fue un hospital y ya no queda nadie.
---------------------------------------------------------------------
local entradaLines, eS, eEnd = lines(2.2, {
	{ S = "Narrador", T = "La Misericordia lleva dos años a la deriva. Nadie ha vuelto a encender sus luces." },
	{ S = "NILDA", T = "Aire respirable, por poco. Dos grados bajo cero. La gravedad de emergencia aguanta, pero no sé cuánto.", To = "Yo", A = "ThinkChin" },
	-- (después del chispazo del techo: silencio de 2 s)
	{ Wait = 3.2, S = "Cosme", T = "Era un hospital. Trescientas camas. Si no queda nadie, alguien se los llevó. Y quiero saber quién.", To = "Yo" },
	{ S = "NILDA", T = "La red principal tiene tres fusibles quemados. Sin ellos, la puerta del puente no se abre.", To = "Yo" },
	{ S = "NILDA", T = "Y el sistema de seguridad sigue despierto. Si ves un láser rojo, no lo cruces encendido." },
})
local sparkAt = eS[2] + ReadingTime.seconds(entradaLines[2].T) + 0.6

local Entrada = {
	Duration = math.ceil(eEnd + 1.5),
	Speakers = { NILDA = true, Cosme = true }, -- (por radio: no están en el pecio)
	Skippable = true,
	FadeIn = true,
	Anchors = {
		Esclusa = "Place:Deriva_Esclusa",
		Yo = "Player",
	},
	Tracks = {
		Camera = {
			-- (todos los planos DENTRO de la esclusa, donde estás tú: el director de cámara no deja planos con
			-- una pared entre la cámara y el jugador; probado en Studio)
			-- 1 · hacia la compuerta de cristal: fuera, el aro azul y tu nave atracada
			{ At = 0, Duration = eS[2], From = { "Esclusa", V(-7, 5, -7) }, To = { "Esclusa", V(-5, 4, -5) }, Look = { "Esclusa", V(0, 4, 12) }, Fov = { 64, 56 }, Cut = "Fade" },
			{ At = eS[2], Duration = sparkAt - eS[2], Shot = "Reaccion:Yo", Cut = "Cut" },
			-- 3 · por encima de tu hombro, por la puerta al pasillo oscuro (allí salta la chispa)
			{ At = sparkAt, Duration = eS[4] - sparkAt, From = { "Esclusa", V(-4, 6, 9) }, To = { "Esclusa", V(-2, 5, 5) }, Look = { "Esclusa", V(0, 2, -14) }, Fov = { 58, 50 }, Cut = "Cut" },
			{ At = eS[4], Duration = eEnd - eS[4] + 1.5, Shot = "Medio:Yo", Cut = "Cut" },
		},
		Fx = {
			{ At = 0.6, Play = "Dust", Anchor = "Esclusa", Offset = V(0, 3, -6) },
			{ At = eS[2], Play = "KeyLight", Anchor = "Yo" },
			{ At = sparkAt, Play = "SparkShower", Anchor = "Esclusa", Offset = V(0, 9, -15) }, -- (en el pasillo, justo detrás de la puerta: se ve por ella)
		},
		Sound = {
			{ At = 0.2, Play = "Hum", Pitch = 0.4, Volume = 0.45 },
			{ At = sparkAt, Play = "Zap", Volume = 0.6 },
			{ At = sparkAt + 0.3, Play = "Rumble", Pitch = 0.6, Volume = 0.35 }, -- (el casco cruje con el chispazo: dentro del silencio)
		},
		Music = {
			{ At = 0, Intensity = "Tension" },
		},
		Dialogue = entradaLines,
	},
}

---------------------------------------------------------------------
-- Deriva_Misericordia_Registro · en el puente, con la corriente restaurada: el último registro de la
-- doctora Varga (holograma). La primera pista de la traición: el transpondedor «VIG».
--   ¿Qué pasa? La doctora cuenta los dos últimos días de la nave y lo que vio en la grabación del atraque.
--   ¿Qué quiero que sienta el jugador? Un nudo en el estómago. Y al final, una sospecha que no se puede decir.
---------------------------------------------------------------------
local regLines, rS, rEnd = lines(3.4, {
	{ S = "DraVarga", T = "Día dieciséis. Último registro de la Misericordia. Habla la doctora Ilse Varga, médica jefe.", To = "Yo" },
	{ S = "DraVarga", T = "La nave sin bandera se llevó a los heridos hace dos días. A todos, menos a los once de cuarentena y a mí. Dijeron que volverían." },
	{ S = "DraVarga", T = "Ayer Ovilla dejó de emitir. La luna entera. No una ciudad: toda la luna. Como si alguien hubiera apagado un interruptor." },
	{ S = "DraVarga", T = "He repasado la grabación del atraque. Llevaban el transpondedor tapado, pero no del todo. Se leen tres letras: V, I, G." },
	{ S = "DraVarga", T = "No sé qué significa. Lo dejo aquí por si alguien lo sabe. Voy a apagar las luces para ahorrar aire." },
	{ S = "DraVarga", T = "Si encontráis esto… no dejéis que vuelva a pasar.", To = "Yo" },
	-- (se apaga el holograma: silencio)
	{ Wait = 2.6, S = "NILDA", T = "VIG. Es el prefijo de las patrullas de la Vigilancia de Cénit.", To = "Yo" },
	{ S = "Cosme", T = "No lo digas por radio. Ni una palabra más de esto hasta que estemos en casa.", To = "Yo" },
})
local holoOff = rS[6] + ReadingTime.seconds(regLines[6].T) + 0.3

local Registro = {
	Duration = math.ceil(rEnd + 1.5),
	Speakers = { NILDA = true, Cosme = true }, -- (por radio)
	Skippable = true,
	FadeIn = true,
	Anchors = {
		Puente = "Place:Deriva_Puente",
		Holograma = "Place:Deriva_Holograma",
		Yo = "Player",
	},
	Tracks = {
		Camera = {
			{ At = 0, Duration = rS[1] + 1, From = { "Puente", V(12, 7, 9) }, To = { "Puente", V(8, 6, 6) }, Look = { "Holograma", V(0, 3, 0) }, Fov = { 60, 54 }, Cut = "Fade" },
			{ At = rS[1] + 1, Duration = rS[3] - rS[1] - 1, Shot = "Medio:DraVarga", Cut = "Cut" },
			{ At = rS[3], Duration = rS[4] - rS[3], Shot = "PrimerPlano:DraVarga", Cut = "Cut" },
			{ At = rS[4], Duration = rS[5] - rS[4], Shot = "Reaccion:Yo", Cut = "Cut" },
			{ At = rS[5], Duration = holoOff - rS[5], Shot = "Medio:DraVarga", Cut = "Cut" },
			{ At = holoOff, Duration = rS[8] - holoOff, From = { "Puente", V(6, 6, -8) }, To = { "Puente", V(9, 7, -11) }, Look = { "Holograma", V(0, 3, 0) }, Fov = { 56, 60 }, Cut = "Cut" },
			{ At = rS[8], Duration = rEnd - rS[8] + 1.5, Shot = "Medio:Yo", Cut = "Cut" },
		},
		Fx = {
			{ At = 0.8, Play = "KeyLight", Anchor = "Holograma", Offset = V(0, 4, 0) },
			{ At = rS[1] - 0.6, Play = "RimLight", Anchor = "Holograma", Offset = V(0, 3, 2) },
			{ At = holoOff, Play = "Flash", Anchor = "Holograma", Offset = V(0, 3, 0) },
		},
		Sound = {
			{ At = 0.3, Play = "Hum", Pitch = 0.55, Volume = 0.4 },
			{ At = rS[1] - 0.5, Play = "Ping", Pitch = 0.8, Volume = 0.4 },
			{ At = holoOff, Play = "Hum", Pitch = 0.3, Volume = 0.25 },
		},
		Music = {
			{ At = 0, Intensity = "Intima" },
			{ At = rS[4], Intensity = "Tension" },
		},
		Actors = {
			{ At = 0, Use = { Key = "DraVarga", Npc = "DraVarga", Anchor = "Holograma", Offset = V(0, 0, 0), Face = { "Yo" } } }, -- (de cara a ti: probado en Studio, sin Face salía de espaldas)
			{ At = 0.4, Mood = { Key = "DraVarga", Mood = "Sad" } }, -- (cansada desde el principio: nada de sonrisas)
			{ At = 0.5, Look = { Key = "DraVarga", At = "Yo" } },
			{ At = rS[6], Look = { Key = "DraVarga", At = "Yo" } },
			{ At = holoOff, Despawn = { Key = "DraVarga" } },
		},
		Dialogue = regLines,
	},
}

---------------------------------------------------------------------
-- Los tres REGISTROS de las salas (escenas ligeras: el holograma habla y tú sigues andando)
---------------------------------------------------------------------
local function logScene(list: { { [string]: any } }): { [string]: any }
	local ls, _, finish = lines(0.6, list)
	return {
		Duration = math.ceil(finish + 0.5),
		Light = true,
		Speakers = { DraVarga = true }, -- (la grabación: el holograma del panel)
		Anchors = { Yo = "Player" },
		Tracks = {
			Sound = { { At = 0.1, Play = "Ping", Pitch = 0.8, Volume = 0.35 } },
			Dialogue = ls,
		},
	}
end

return {
	Deriva_Misericordia_Entrada = Entrada,
	Deriva_Misericordia_Registro = Registro,
	Deriva_Registro_Triaje = logScene({
		{ S = "DraVarga", T = "Día tres desde que cayó Ovilla. Ciento doce heridos a bordo. Vendas para cuatro días, calmantes para dos." },
		{ S = "DraVarga", T = "Les digo a todos que la ayuda viene. No sé si viene." },
		{ S = "DraVarga", T = "Hoy un niño me ha preguntado si las estrellas se apagan. Le he dicho que no. Es la segunda mentira del día." },
	}),
	Deriva_Registro_Cuarentena = logScene({
		{ S = "DraVarga", T = "Día nueve. Fiebre de ceniza en la cuarentena. Hemos sellado la puerta con once dentro. La orden la di yo." },
		{ S = "DraVarga", T = "Si alguien escucha esto: no abráis esa sala. Ya no hay nada que salvar ahí dentro. Dejadles descansar." },
	}),
	-- En Alba, al entregar el núcleo (la lanza Services/DerivaService): por radio, sin quitar el control
	Deriva_Alba_Fin = (function()
		local scene = logScene({
			{ S = "Narrador", T = "En Alba, el núcleo de la Misericordia acaba en una caja sin etiqueta, debajo del mostrador del Gremio." },
			{ S = "NILDA", T = "He copiado la grabación del atraque tres veces. Si alguien borra una, quedan dos.", To = "Yo" },
			{ S = "Cosme", T = "Bien hecho. Lo que hay ahí dentro puede costarle el puesto a gente muy importante. O algo peor.", To = "Yo" },
			{ S = "Cosme", T = "Trescientas personas subieron a esa nave sin bandera. Quiero saber adónde las llevaron." },
		})
		scene.Speakers = { NILDA = true, Cosme = true }
		return scene
	end)(),
	Deriva_Registro_Comunicaciones = logScene({
		{ S = "DraVarga", T = "Día catorce. Por fin ha contestado alguien. Una nave sin bandera y sin nombre. Dicen que pueden llevarse a todos los heridos." },
		{ S = "DraVarga", T = "Solo piden una cosa a cambio: las coordenadas exactas de Ovilla. Para buscar supervivientes, dicen." },
		{ S = "DraVarga", T = "El capitán ha dicho que sí. Yo también lo habría dicho. Por eso me da miedo." },
	}),
}
