-- Graphics: niveles de calidad gráfica (Bajo / Medio / Alto) y sus presupuestos. Cuentas puras: se
-- prueban fuera de Roblox (scripts/test-graphics.luau).
--
--   * Cada nivel dice cuánto se puede gastar: cuántas farolas dan luz de verdad a la vez, cuántas luces
--     echan sombra, si hay sombras del sol, desenfoque, rayos de sol, cuánta nube, charcos…
--     El objetivo: el móvil medio no baja de unos 30 fps (presupuestos explícitos, aquí abajo).
--   * Al entrar se elige el nivel según el dispositivo (móvil o no, calidad gráfica de Roblox) y, en
--     «Auto», se va ajustando con los fps de verdad: si van bajos un rato, baja un nivel; si van
--     sobrados mucho rato, sube (pero no vuelve a probar un nivel que fue lento hasta pasados unos minutos).
--   * El jugador puede fijarlo desde el menú («✨ Gráficos: …»).
--   * Elegir qué luces se encienden: las más cercanas a la cámara, hasta el presupuesto.

local Graphics = {}

export type TierName = "Low" | "Medium" | "High"
export type Choice = TierName | "Auto"

export type Tier = {
	LampLights: number, -- farolas con luz de verdad (SpotLight) a la vez; las demás solo brillan
	LampRange: number, -- más lejos de esto, ninguna farola ilumina el suelo
	ShadowLights: number, -- luces cercanas que echan sombra (0 = ninguna)
	ShadowRange: number,
	GlobalShadows: boolean, -- sombras del sol y la luna
	DepthOfField: boolean, -- desenfoque lejano muy suave (y el de cine)
	SunRays: boolean,
	Bloom: number, -- multiplica el brillo del resplandor (1 = el de la hora)
	Clouds: number, -- multiplica la densidad de las nubes volumétricas
	Puddles: number, -- charcos con reflejo a la vez cuando llueve
	WetRadius: number, -- radio (studs) en el que el suelo se ve mojado
	SignGlow: boolean, -- los carteles de las tiendas resplandecen de noche
	NormalMaps: boolean, -- relieve (mapa normal) de las texturas PBR de los materiales
	GrassBlades: boolean, -- briznas de césped 3D en el terreno (Terrain.Decoration): apagadas en todos, asomaban por calles y aceras
	LeafDetail: boolean, -- racimos de relleno de las copas y raíces de los árboles (etiqueta LeafDetail)
	CityDetail: boolean, -- lo PESADO: tejas con relieve, molduras, zócalos, desgaste del asfalto (Kit/CityDetail), el skyline lejano y los edificios 3D (etiquetas CityDetail, BuildingMesh/BuildingShell)
	PropDetail: boolean, -- lo BARATO y nuevo: objetos de malla sueltos de la calle (hidrantes, buzones, jardineras, conos, palés, aires), muebles, láminas, señales (etiquetas PropDetail, PropMesh…): se ven en TODOS los niveles
	WetGloss: boolean, -- con lluvia, el asfalto y las aceras se vuelven lisos y reflejan (rugosidad mojada)
	FarRange: boolean, -- sierra lejana al otro lado del mar (siluetas del horizonte, Controllers/Horizon)
}

Graphics.Order = { "Low", "Medium", "High" } :: { TierName }
Graphics.Labels = { Low = "Bajo", Medium = "Medio", High = "Alto", Auto = "Auto" }
-- El orden del botón del menú: Auto -> Bajo -> Medio -> Alto -> Auto…
Graphics.Choices = { "Auto", "Low", "Medium", "High" } :: { Choice }

-- Presupuestos de cada nivel. (Las farolas con luz son unas 1.600 en el mapa: antes, de noche, en el
-- ordenador se encendían todas a la vez; ahora como mucho las de aquí.)
Graphics.Tiers = {
	Low = {
		LampLights = 8,
		LampRange = 120,
		ShadowLights = 0,
		ShadowRange = 0,
		GlobalShadows = false,
		DepthOfField = false,
		SunRays = false,
		Bloom = 0.7,
		Clouds = 0.55,
		Puddles = 4,
		WetRadius = 60,
		SignGlow = false,
		NormalMaps = true, -- (el relieve es barato: lo pone una textura; sin él «todo se ve igual»)
		GrassBlades = false,
		LeafDetail = false,
		CityDetail = false,
		PropDetail = true, -- (en Bajo TAMBIÉN: es lo nuevo y cuesta poco)
		WetGloss = false,
		FarRange = false,
	},
	Medium = {
		LampLights = 18,
		LampRange = 180,
		ShadowLights = 2,
		ShadowRange = 80,
		GlobalShadows = true,
		DepthOfField = false, -- (solo en cinemáticas y conversaciones)
		SunRays = true,
		Bloom = 0.9,
		Clouds = 0.8,
		Puddles = 10,
		WetRadius = 80,
		SignGlow = true,
		NormalMaps = true,
		GrassBlades = false,
		LeafDetail = true,
		CityDetail = true,
		PropDetail = true,
		WetGloss = true,
		FarRange = true,
	},
	High = {
		LampLights = 40,
		LampRange = 260,
		ShadowLights = 8,
		ShadowRange = 160,
		GlobalShadows = true,
		DepthOfField = true,
		SunRays = true,
		Bloom = 1,
		Clouds = 1,
		Puddles = 16,
		WetRadius = 100,
		SignGlow = true,
		NormalMaps = true,
		GrassBlades = false,
		LeafDetail = true,
		CityDetail = true,
		PropDetail = true,
		WetGloss = true,
		FarRange = true,
	},
} :: { [TierName]: Tier }

-- Qué etiqueta esconde cada nivel: etiqueta -> campo del nivel (si el campo es false, se esconde).
-- Lo usa Controllers/MaterialDetail. Solo lo PESADO se esconde en Bajo; lo nuevo y barato se queda.
--   * LeafDetail: racimos de relleno de las copas y raíces (Kit/Nature, hechos por código)
--   * CityDetail: tejas, molduras y desgaste (Kit/CityDetail) y el skyline lejano (World/CityAssets)
--   * BuildingMesh / BuildingShell: edificios 3D (World/Buildings3D), el estadio y el instituto de
--     malla; en Bajo se ve la caja de bloques de antes
--   * PropDetail / PropMesh / PropShell: los objetos de malla de la Tienda en la calle (World/
--     CityAssets: hidrantes, buzones, jardineras, conos, palés, aires…), las plantillas de la naturaleza
--     (World/NatureAssets) y las armas y objetos puestos (World/UserArsenal)
--   * DecorProp / PropShell: los muebles de la Tienda en los interiores (World/InteriorProps)
--   * StreetSign: las señales de tráfico (World/StreetDress); TextureDetail: papel pintado, moqueta y
--     techos (World/MaterialExtras)
Graphics.DetailTags = {
	LeafDetail = "LeafDetail",
	CityDetail = "CityDetail",
	BuildingMesh = "CityDetail",
	BuildingShell = "CityDetail",
	PropDetail = "PropDetail",
	PropMesh = "PropDetail",
	PropShell = "PropDetail",
	DecorProp = "PropDetail",
	StreetSign = "PropDetail",
	TextureDetail = "PropDetail",
} :: { [string]: string }

-- ¿Esconde este nivel las piezas con esta etiqueta?
function Graphics.hides(name: TierName, tag: string): boolean
	local field = Graphics.DetailTags[tag]
	if not field then
		return false
	end
	return (Graphics.tier(name) :: any)[field] == false
end

-- Modo ligero (móvil, UI/Perf.stripDetails): los objetos de la acera hechos por código (etiqueta
-- LiteDetail, Kit/StreetDetail) que se quitan. Los que dan carácter a la acera y cuestan poco se quedan,
-- y nunca se quita uno que ya lleva una malla nueva encima (World/CityAssets: «Malla»).
Graphics.LiteKeep = {
	Obras = true, -- (sus conos y vallas llevan malla de la Tienda)
	ArmarioElectrico = true, -- (con grafiti)
	Jardinera = true,
	BuzonCorreos = true,
	BancoCalle = true,
	PapeleraCalle = true,
	BocaRiego = true,
}
function Graphics.liteStrips(name: string, hasMesh: boolean): boolean
	return not hasMesh and not Graphics.LiteKeep[name]
end

-- Cuándo cambia de nivel solo (en «Auto»). Pensado para que el móvil NO caiga a Bajo por un rato malo:
--   * bajar pide pocos fps durante bastante rato (DownSeconds)
--   * de Medio a Bajo solo si va de verdad mal (por debajo de LowFloor): un móvil que aguanta más de
--     20 fps se queda en Medio
--   * tras cada cambio, un rato sin cambiar (Hold) y para subir hacen falta muchos fps (Up): así no
--     va y viene (histéresis)
Graphics.Fps = {
	Target = 30, -- lo mínimo que se quiere en un móvil medio
	Down = 27, -- por debajo de esto…
	DownSeconds = 15, -- …durante tantos segundos seguidos: un nivel menos
	LowFloor = 20, -- de Medio a Bajo, solo por debajo de esto (suelo de Medio)
	Up = 50, -- por encima de esto…
	UpSeconds = 25, -- …durante tantos segundos seguidos: un nivel más
	Hold = 45, -- tras cambiar, tantos segundos sin volver a cambiar
	RetrySeconds = 240, -- tras bajar, tanto tiempo sin volver a probar el nivel que fue lento
	Smoothing = 0.1, -- (media móvil de los fps)
}

function Graphics.index(name: TierName): number
	return table.find(Graphics.Order, name) or 2
end

function Graphics.tier(name: TierName?): Tier
	return Graphics.Tiers[name or "Medium"] or Graphics.Tiers.Medium
end

-- El nivel de partida. quality = calidad gráfica guardada de Roblox (1..10) o nil si está en
-- «Automático». En móvil se empieza en Medio (los fps deciden si sube o baja).
function Graphics.detect(info: { Mobile: boolean, Quality: number? }): TierName
	local q = info.Quality
	if q then
		if q <= 3 then
			return "Low"
		elseif q <= 7 or info.Mobile then
			return "Medium"
		end
		return "High"
	end
	return if info.Mobile then "Medium" else "High"
end

-- Texto del botón «✨ Gráficos» del menú: en «Auto», también el nivel de ahora
function Graphics.choiceLabel(choice: Choice, current: TierName): string
	if choice == "Auto" then
		return ("✨ Gráficos: Auto (ahora %s)"):format(Graphics.Labels[current] or "Medio")
	end
	return ("✨ Gráficos: %s (fijo)"):format(Graphics.Labels[choice] or "Medio")
end

-- La siguiente opción del botón del menú
function Graphics.nextChoice(choice: Choice): Choice
	local i = table.find(Graphics.Choices, choice) or 1
	return Graphics.Choices[i % #Graphics.Choices + 1]
end

export type AutoState = {
	Tier: TierName,
	Fps: number, -- media móvil
	Slow: number, -- segundos seguidos con pocos fps
	Fast: number, -- segundos seguidos sobrados
	Ceiling: number, -- nivel más alto al que se puede subir (baja cuando un nivel va lento)
	Retry: number, -- segundos hasta que se puede volver a probar el nivel que fue lento
	Hold: number, -- segundos sin cambiar tras el último cambio (histéresis)
}

function Graphics.newAuto(start: TierName): AutoState
	return { Tier = start, Fps = 60, Slow = 0, Fast = 0, Ceiling = #Graphics.Order, Retry = 0, Hold = 0 }
end

-- Un paso del modo «Auto»: dt = segundos del fotograma. Devuelve el nivel nuevo si cambia (o nil).
function Graphics.autoStep(state: AutoState, dt: number): TierName?
	if dt <= 0 then
		return nil
	end
	local F = Graphics.Fps
	local fps = math.min(1 / dt, 240)
	state.Fps += (fps - state.Fps) * F.Smoothing
	local i = Graphics.index(state.Tier)
	if state.Retry > 0 then
		state.Retry -= dt
		if state.Retry <= 0 then
			state.Ceiling = #Graphics.Order
		end
	end
	-- (de Medio a Bajo hace falta ir de verdad mal: suelo de Medio)
	local down = if i == 2 then F.LowFloor else F.Down
	if state.Fps < down then
		state.Slow += dt
		state.Fast = 0
	elseif state.Fps > F.Up then
		state.Fast += dt
		state.Slow = 0
	else
		state.Slow, state.Fast = 0, 0
	end
	if (state.Hold or 0) > 0 then
		state.Hold -= dt
		return nil -- (recién cambiado: se espera)
	end
	if state.Slow >= F.DownSeconds and i > 1 then
		-- Este nivel no aguanta: se baja y no se vuelve a probar en un rato
		state.Ceiling = math.min(state.Ceiling, i - 1)
		state.Retry = F.RetrySeconds
		state.Tier = Graphics.Order[i - 1]
		state.Slow, state.Fast = 0, 0
		state.Hold = F.Hold
		state.Fps = F.Target -- (se vuelve a medir desde cero)
		return state.Tier
	elseif state.Fast >= F.UpSeconds and i < state.Ceiling then
		state.Tier = Graphics.Order[i + 1]
		state.Slow, state.Fast = 0, 0
		state.Hold = F.Hold
		return state.Tier
	end
	return nil
end

-- Las `budget` posiciones más cercanas a `eye` a menos de `range`. Devuelve un conjunto de índices.
function Graphics.nearest(points: { Vector3 }, eye: Vector3, budget: number, range: number): { [number]: boolean }
	local chosen: { [number]: boolean } = {}
	if budget <= 0 or range <= 0 then
		return chosen
	end
	local near: { { I: number, D: number } } = {}
	for i, p in points do
		local d = (p - eye).Magnitude
		if d < range then
			table.insert(near, { I = i, D = d })
		end
	end
	if #near > budget then
		table.sort(near, function(a, b)
			return a.D < b.D
		end)
	end
	for n = 1, math.min(budget, #near) do
		chosen[near[n].I] = true
	end
	return chosen
end

-- Color de una farola según dónde está (siempre el mismo para la misma farola): la mayoría LED cálido
-- y alguna de sodio (más naranja), como en una ciudad de verdad que va cambiando las bombillas.
Graphics.LampLed = { 255, 226, 186 }
Graphics.LampSodium = { 255, 178, 102 }
function Graphics.lampKind(position: Vector3): "Led" | "Sodium"
	local x = math.sin(math.floor(position.X / 4) * 12.9898 + math.floor(position.Z / 4) * 78.233) * 43758.5453
	return if x - math.floor(x) < 0.28 then "Sodium" else "Led"
end

return Graphics
