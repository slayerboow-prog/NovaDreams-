-- SeaEvents: catástrofes marinas (SeaEventService en el servidor, SeaEventsUI en cada jugador).
--
-- De vez en cuando pasa algo en el mar. Se avisa a todos con una alerta y cuenta atrás:
--   Tsunami         una ola enorme llega a una playa o al puerto. Sube a un sitio alto (más de
--                   14 de altura) o métete en un edificio; si te pilla, te arrastra y te hace daño.
--                   Después, la costa se queda inundada un rato.
--   Temporal        tormenta en alta mar: olas grandes, el barco se mueve y caen rayos en el mar.
--                   Pican más peces raros, pero cuidado con los rayos cerca del barco.
--   Remolino        un remolino gigante cerca del barco: si nadas cerca te arrastra hacia el centro.
--   Marea negra     un vertido de petróleo en la costa: ahí no pican los peces y nadar ensucia.
--                   Los jugadores la limpian (manchas con "Limpiar") y cobran por cada una.
--   Tiburón         un tiburón ronda una playa: si te bañas, te puede morder. Un buceador con arpón
--                   puede cazarlo y acabar con el peligro.
--   Medusas         plaga de medusas en una playa: pican a quien se baña (el equipo de buceo protege).
--
-- Estado en workspace (se replica a todos): SeaEvent (tipo), SeaEventAt (hora del servidor en que
-- empieza el peligro, después del aviso), SeaEventEnd, SeaEventPos (centro), SeaEventDir (hacia dónde
-- avanza la ola), SeaEventSite (nombre del sitio).

local SeaEvents = {}

SeaEvents.Kinds = {
	Tsunami = {
		Id = "Tsunami",
		Name = "Tsunami",
		Icon = "🌊",
		Warning = 30,
		Duration = 75,
		Radius = 420, -- ancho de costa que barre (a cada lado del sitio)
		Inland = 260, -- cuánto entra en tierra
		SafeHeight = 14, -- por encima de esto no te pilla
		Damage = 45,
		Weight = 1,
		Tip = "Sube a un sitio alto o entra en un edificio",
	},
	Temporal = {
		Id = "Temporal",
		Name = "Temporal marino",
		Icon = "⛈️",
		Warning = 10,
		Duration = 150,
		Radius = 450, -- alrededor del barco de pesca
		StrikeEvery = 3,
		StrikeDamage = 35,
		StrikeRange = 8,
		RareBoost = 1.6,
		Weight = 3,
		Tip = "Olas y rayos en alta mar: pican peces raros, pero cuidado",
	},
	Remolino = {
		Id = "Remolino",
		Name = "Remolino gigante",
		Icon = "🌀",
		Warning = 8,
		Duration = 100,
		Radius = 70,
		CoreRadius = 10,
		Damage = 8, -- por segundo en el centro
		Weight = 2,
		Tip = "No te acerques nadando: te arrastra al centro",
	},
	MareaNegra = {
		Id = "MareaNegra",
		Name = "Marea negra",
		Icon = "🛢️",
		Warning = 5,
		Duration = 600,
		Radius = 150,
		Patches = 8,
		Reward = 30, -- por cada mancha limpiada
		Bonus = 50, -- a cada uno que ha ayudado, si se limpia toda
		Damage = 2,
		Weight = 2,
		Tip = "Ayuda a limpiar las manchas de petróleo (y cobra por ello)",
	},
	Tiburon = {
		Id = "Tiburon",
		Name = "Tiburón en la playa",
		Icon = "🦈",
		Warning = 5,
		Duration = 120,
		Radius = 90,
		BiteChance = 0.4,
		Damage = 20,
		Weight = 3,
		Tip = "¡Todos fuera del agua! Un buceador con arpón puede cazarlo",
	},
	Medusas = {
		Id = "Medusas",
		Name = "Plaga de medusas",
		Icon = "🪼",
		Warning = 5,
		Duration = 150,
		Radius = 120,
		StingChance = 0.5,
		Damage = 8,
		Weight = 3,
		Tip = "Pican a quien se baña (el equipo de buceo protege)",
	},
}
SeaEvents.Order = { "Tsunami", "Temporal", "Remolino", "MareaNegra", "Tiburon", "Medusas" }

-- Cada cuánto pasa algo (segundos reales, al azar entre los dos)
SeaEvents.Every = { 480, 960 }
SeaEvents.WaveSpeed = 70 -- studs por segundo
SeaEvents.WaveStart = 600 -- a qué distancia mar adentro sale la ola
SeaEvents.FloodSeconds = 40

-- Sitios de la costa (playas y puerto). Dir = hacia dónde avanza la ola (del mar a tierra).
SeaEvents.Sites = {
	{ Name = "Playa Dorada", X = 4200, Z = -1000, Dir = { -1, 0 } },
	{ Name = "el puerto", X = 700, Z = 3420, Dir = { 0, -1 } },
	{ Name = "la marina", X = -3850, Z = 1300, Dir = { 1, 0 } },
	{ Name = "la playa del sur", X = -700, Z = 3500, Dir = { 0, -1 } },
}

function SeaEvents.site(name: string): { [string]: any }?
	for _, s in SeaEvents.Sites do
		if s.Name == name then
			return s
		end
	end
	return nil
end

-- Dónde va el frente de la ola: distancia recorrida desde el sitio (negativa = aún en el mar)
function SeaEvents.waveFront(startAt: number, now: number): number
	return (now - startAt) * SeaEvents.WaveSpeed - SeaEvents.WaveStart
end

-- ¿Pilla la ola a este punto? (along = cuánto está tierra adentro desde el sitio; side = de lado)
function SeaEvents.inWavePath(site: { [string]: any }, position: Vector3): (boolean, number)
	local dx, dz = site.Dir[1], site.Dir[2]
	local rx, rz = position.X - site.X, position.Z - site.Z
	local along = rx * dx + rz * dz
	local side = math.abs(rx * -dz + rz * dx)
	local kind = SeaEvents.Kinds.Tsunami
	return side < kind.Radius and along > -SeaEvents.WaveStart and along < kind.Inland, along
end

-- ¿Hay marea negra en este punto? (lo usa la pesca: ahí no pican)
function SeaEvents.oilAt(position: Vector3): boolean
	if workspace:GetAttribute("SeaEvent") ~= "MareaNegra" then
		return false
	end
	local center = workspace:GetAttribute("SeaEventPos")
	if typeof(center) ~= "Vector3" then
		return false
	end
	local flat = Vector3.new(position.X - center.X, 0, position.Z - center.Z)
	return flat.Magnitude < SeaEvents.Kinds.MareaNegra.Radius + 40
end

-- Tipo al azar según su peso
function SeaEvents.pick(r: number): string
	local total = 0
	for _, id in SeaEvents.Order do
		total += SeaEvents.Kinds[id].Weight
	end
	local x = r * total
	for _, id in SeaEvents.Order do
		x -= SeaEvents.Kinds[id].Weight
		if x <= 0 then
			return id
		end
	end
	return SeaEvents.Order[#SeaEvents.Order]
end

return SeaEvents
