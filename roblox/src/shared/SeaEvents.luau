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
		MinGap = 7200, -- segundos mínimos entre dos Tsunami (de las que más dañan: muy de vez en cuando)
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
		Weight = 2,
		MinGap = 3600, -- segundos mínimos entre dos Temporal (de las que más dañan: muy de vez en cuando)
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
		MinGap = 2700, -- segundos mínimos entre dos Remolino (de las que más dañan: muy de vez en cuando)
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
		Weight = 3,
		MinGap = 1200, -- segundos mínimos entre dos MareaNegra
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
		MinGap = 1200, -- segundos mínimos entre dos Tiburon
		Tip = "¡Todos fuera del agua! Un buceador con arpón puede cazarlo",
	},
	Medusas = {
		Id = "Medusas",
		Name = "Plaga de medusas",
		Icon = "🌊",
		Warning = 5,
		Duration = 150,
		Radius = 120,
		StingChance = 0.5,
		Damage = 8,
		Weight = 4,
		MinGap = 900, -- segundos mínimos entre dos Medusas
		Tip = "Pican a quien se baña (el equipo de buceo protege)",
	},
}
SeaEvents.Order = { "Tsunami", "Temporal", "Remolino", "MareaNegra", "Tiburon", "Medusas" }

-- Cada cuánto pasa algo (segundos reales, al azar entre los dos)
SeaEvents.Every = { 600, 1200 }
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

-- ¿Se enseña la alerta de arriba a este jugador? (función pura; ctx = { Id, Stage, Clock, Distance, Busy })
--   * nunca encima de una conversación o una cinemática (Busy)
--   * los avisos que son "para mayores" (limpiar el petróleo y cobrar, cazar al tiburón, pescar con
--     temporal) no se les enseñan a bebés ni a niños, salvo que estén allí mismo
--   * en horario de cole, a niños y adolescentes solo si el peligro les pilla cerca (Near studs)
--   * el tsunami sí se avisa a todos (hay que subir a un sitio alto)
SeaEvents.AlertNear = 500
SeaEvents.ForAdults = { MareaNegra = true, Tiburon = true, Temporal = true }
function SeaEvents.showAlert(ctx: { [string]: any }): boolean
	if not ctx.Id or ctx.Busy then
		return false
	end
	if ctx.Id == "Tsunami" then
		return true
	end
	local kind = SeaEvents.Kinds[ctx.Id]
	local near = type(ctx.Distance) == "number" and ctx.Distance < ((kind and kind.Radius) or 0) + SeaEvents.AlertNear
	local stage = ctx.Stage
	local young = stage == "Bebe" or stage == "Nino"
	if young and SeaEvents.ForAdults[ctx.Id] and not near then
		return false
	end
	local student = stage == "Nino" or stage == "Adolescente" or stage == "Bebe"
	local schoolTime = type(ctx.Clock) == "number" and ctx.Clock >= 8.5 and ctx.Clock < 17
	if student and schoolTime and not near then
		return false
	end
	return true
end

-- Tipo al azar según su peso. `ready(id)` (opcional) dice si ese tipo ya puede volver a salir
-- (cada uno tiene su MinGap: las que más dañan, como el tsunami, salen muy de vez en cuando).
function SeaEvents.pick(r: number, ready: ((string) -> boolean)?): string?
	local total = 0
	for _, id in SeaEvents.Order do
		if not ready or ready(id) then
			total += SeaEvents.Kinds[id].Weight
		end
	end
	if total <= 0 then
		return nil
	end
	local x = r * total
	local last = nil
	for _, id in SeaEvents.Order do
		if not ready or ready(id) then
			last = id
			x -= SeaEvents.Kinds[id].Weight
			if x <= 0 then
				return id
			end
		end
	end
	return last
end

return SeaEvents
