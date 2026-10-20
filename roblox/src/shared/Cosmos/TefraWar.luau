-- TefraWar: la GUERRA CON HORARIO de Tefra (docs/planetas/diseno-mundos.md §3.1.10 y §3.1.18).
-- Cuentas puras: las usa Services/TefraService (el bombardeo es el mismo para todo el servidor) y las
-- pruebas (scripts/test-tefra.luau).
--
-- Bombardeo: dos veces por día de juego (a las 9:00 y a las 19:00 de Tefra) la artillería de Ovilla
-- dispara sobre TRES zonas marcadas de Bastión Ceniza. Las sirenas suenan WarnSeconds (60 s reales)
-- antes: las zonas se ven en rojo en el suelo y en el minimapa. Durante el fuego (FireSeconds), quien
-- está en una zona y FUERA de un refugio cae «Derribado» (sin sangre ni daño: despierta en el refugio
-- más cercano). Después (AfterSeconds) hay escombros con gente atrapada (rescatista, ingeniero, con
-- paga extra) y en la Panadería del Ovillo se reparte el «pan de sirena».
-- Tras el alto el fuego (misión Tefra_07, marca TreguaTefra) los bombardeos son raros: solo uno de
-- cada TreguaEvery días, y solo si alguien del planeta no ha vivido la tregua.

local TefraCity = require(script.Parent.TefraCity)

local TefraWar = {}

TefraWar.Hours = { 9, 19 } -- hora de Tefra a la que caen las primeras bombas
TefraWar.WarnSeconds = 60 -- sirenas antes del fuego (segundos reales)
TefraWar.FireSeconds = 24
TefraWar.AfterSeconds = 150
TefraWar.ZonesPerRaid = 3
TefraWar.ShellsPerZone = 5
TefraWar.TreguaEvery = 3 -- con la tregua, un bombardeo cada tantos días (el de la mañana)
TefraWar.AfterBonus = 1.5 -- paga de rescatista e ingeniero justo después de un bombardeo

-- Zonas donde puede caer el fuego (local x, z, radio). Nunca en la plataforma del Muelle (llegan las
-- naves) ni dentro de los refugios (el refugio te protege aunque la zona lo toque).
TefraWar.Zones = {
	{ Id = "Ovillo", Name = "las cúpulas del Ovillo", X = -300, Z = -150, R = 34 },
	{ Id = "OvilloNorte", Name = "la Ronda Norte del Ovillo", X = -150, Z = -232, R = 26 },
	{ Id = "Mercado", Name = "el Mercado Espiral", X = -350, Z = 0, R = 30 },
	{ Id = "Fundiciones", Name = "el patio de las Fundiciones", X = -200, Z = 165, R = 30 },
	{ Id = "Explanada", Name = "la explanada de la pelota", X = -320, Z = 345, R = 32 },
	{ Id = "MurallaOeste", Name = "la Muralla Oeste", X = -395, Z = 160, R = 26 },
	{ Id = "Pozos", Name = "la explanada de los Pozos", X = 160, Z = 200, R = 30 },
	{ Id = "MurallaEste", Name = "la Muralla Este", X = 232, Z = 300, R = 26 },
	{ Id = "Campus", Name = "el patio del Campus", X = 185, Z = 60, R = 24 },
}
TefraWar.ZoneById = {}
for _, z in TefraWar.Zones do
	TefraWar.ZoneById[z.Id] = z
end

-- Números repetibles (el mismo bombardeo para la misma semilla)
local function rng(seed: number): () -> number
	-- (la semilla se mezcla bien y se tiran los primeros números: con semillas pequeñas y parecidas,
	-- el primero salía casi siempre igual)
	local s = (math.floor(math.abs(seed)) * 2654435 + 977) % 2147483647
	if s == 0 then
		s = 1
	end
	local function nextValue(): number
		s = (s * 16807) % 2147483647
		return s / 2147483647
	end
	for _ = 1, 4 do
		nextValue()
	end
	return nextValue
end
TefraWar.rng = rng

-- Las zonas de un bombardeo (día de juego, 1 = mañana / 2 = tarde): siempre las mismas para ese día
function TefraWar.pickZones(day: number, slot: number): { { [string]: any } }
	local r = rng(day * 97 + slot * 13 + 5)
	local pool = table.clone(TefraWar.Zones)
	local out = {}
	for _ = 1, math.min(TefraWar.ZonesPerRaid, #pool) do
		local i = 1 + math.floor(r() * #pool)
		i = math.clamp(i, 1, #pool)
		table.insert(out, table.remove(pool, i))
	end
	return out
end

-- Dónde cae cada proyectil de una zona (local x, z): repartidos dentro del círculo
function TefraWar.shells(zone: { [string]: any }, seed: number, n: number?): { { number } }
	local r = rng(seed)
	local out = {}
	for _ = 1, n or TefraWar.ShellsPerZone do
		local a = r() * math.pi * 2
		local d = math.sqrt(r()) * zone.R * 0.85
		table.insert(out, { zone.X + math.cos(a) * d, zone.Z + math.sin(a) * d })
	end
	return out
end

-- ¿Está este punto en alguna de las zonas? (la zona o nil)
function TefraWar.zoneAt(zones: { { [string]: any } }, lx: number, lz: number): { [string]: any }?
	for _, z in zones do
		if (lx - z.X) ^ 2 + (lz - z.Z) ^ 2 <= z.R * z.R then
			return z
		end
	end
	return nil
end

-- ¿Le alcanza el fuego? (en una zona y fuera de un refugio)
function TefraWar.exposed(zones: { { [string]: any } }, lx: number, lz: number): boolean
	if not TefraWar.zoneAt(zones, lx, lz) then
		return false
	end
	return TefraCity.shelterAt(lx, lz) == nil
end

-- ¿Toca bombardeo? clock = hora del juego (0-24, la de Tefra); day = día de juego; leadHours = las
-- horas de juego que duran las sirenas (WarnSeconds pasado a horas de juego); done = { [clave] = true }
-- con los ya hechos; tregua = el planeta vive la tregua. Devuelve la clave ("día:turno"), el turno y
-- cuántas horas de juego faltan para el fuego (o nil si no toca).
function TefraWar.due(clock: number, day: number, leadHours: number, done: { [string]: boolean }, tregua: boolean?): (string?, number?, number?)
	for slot, hour in TefraWar.Hours do
		if tregua and (slot ~= 1 or day % TefraWar.TreguaEvery ~= 0) then
			continue
		end
		local key = ("%d:%d"):format(day, slot)
		local left = hour - clock
		if not done[key] and left > 0 and left <= leadHours then
			return key, slot, left
		end
	end
	return nil, nil, nil
end

-- Horas de juego que equivalen a unos segundos reales (dayMinutes = Config.DayLengthMinutes)
function TefraWar.gameHours(seconds: number, dayMinutes: number): number
	return seconds / (dayMinutes * 60) * 24
end

-- Lo que dice la sirena (para el aviso de la pantalla)
function TefraWar.warnText(zones: { { [string]: any } }, seconds: number): string
	local names = {}
	for _, z in zones do
		table.insert(names, z.Name)
	end
	return ("🚨 ¡Sirenas! Bombardeo de Ovilla en %d s sobre %s. Corre a un refugio 🛡"):format(math.max(0, math.floor(seconds + 0.5)), table.concat(names, ", "))
end

return TefraWar
