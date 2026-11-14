-- TerrainPerils: los PELIGROS DEL TERRENO de cada planeta (cuentas puras; los aplica
-- Services/PlanetPerilService). Además de la desventaja con medidor (shared/Cosmos/PlanetHazard), cada
-- planeta tiene problemas propios del suelo y del clima que SE VEN y te pasan a ti:
--
--   Pozo    zonas fijas del suelo (arenas movedizas, ciénaga, coral negro, charcos con corriente):
--           dentro andas muy lento, el medidor sube y, si quema, pierdes algo de vida. Se sale andando.
--   Hielo   zonas fijas de hielo fino: si te quedas quieto encima, cruje (aviso) y luego se rompe:
--           caes al agua helada (el medidor sube de golpe) y sales en la orilla.
--   Rayo    en un momento del planeta (tormenta, lluvia ácida): un círculo de aviso en el suelo junto a
--           quien está al descubierto y, al poco, el rayo. Quien sigue dentro recibe el golpe.
--   Caida   igual que el rayo pero cae algo de arriba (ramas, paneles de la Cúpula).
--   Empuje  en un momento del planeta (tormenta de arena, ventisca, viento): ráfagas que te empujan
--           de lado si estás al descubierto.
--
-- Cada planeta los declara en S.Perils (lista de definiciones como las de abajo). Las zonas fijas salen
-- de una semilla: las mismas en el servidor, en cada cliente y en las pruebas.

local TerrainPerils = {}

export type Peril = {
	Id: string,
	Kind: string, -- "Pozo" | "Hielo" | "Rayo" | "Caida" | "Empuje"
	Name: string,
	Icon: string,
	Mode: string?, -- el momento del planeta en que pasa (nil: siempre)
	-- Zonas fijas (Pozo, Hielo): o una lista Fixed de { X, Z, R } (locales) o Count zonas generadas
	Fixed: { { X: number, Z: number, R: number } }?,
	Count: number?,
	Radius: { number }?, -- { mín, máx } de las generadas
	Materials: { string }?, -- solo sobre estos materiales del terreno (generadas)
	MaxSlope: number?,
	Seed: number?,
	Color: Color3?,
	Material: Enum.Material?,
	-- Efectos
	Slow: number?, -- Pozo: lo que te frena (0..1)
	Rate: number?, -- Pozo: medidor por segundo dentro
	Burn: number?, -- Pozo: vida por segundo dentro (nunca por debajo de 15)
	Hold: number?, -- Hielo: segundos quieto antes de que cruja
	Drop: number?, -- Hielo/Rayo/Caida: medidor que sube de golpe
	Damage: number?, -- Rayo/Caida: vida que quita el golpe
	Every: number?, -- Rayo/Caida/Empuje: segundos entre uno y otro (por jugador)
	Warn: number?, -- Rayo/Caida: segundos de aviso
	Reach: number?, -- Rayo/Caida: radio del golpe
	Force: number?, -- Empuje: fuerza de la ráfaga
	Dir: Vector3?, -- Empuje: hacia dónde sopla
	Text: string, -- el aviso la primera vez que te pasa
	Hit: string?, -- el aviso cuando te da
}

TerrainPerils.Kinds = { Pozo = true, Hielo = true, Rayo = true, Caida = true, Empuje = true }

-- Generador pseudoaleatorio con semilla (igual en todas partes)
local function rng(seed: number): () -> number
	local state = math.floor(seed * 9973) % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	return function(): number
		state = (state * 16807) % 2147483647
		return state / 2147483647
	end
end

local cache: { [string]: { { X: number, Z: number, R: number } } } = {}

-- Las zonas fijas de un peligro (locales al planeta)
function TerrainPerils.zones(S: any, peril: Peril): { { X: number, Z: number, R: number } }
	if peril.Fixed then
		return peril.Fixed
	end
	local key = tostring(S.Id) .. ":" .. peril.Id
	if cache[key] then
		return cache[key]
	end
	local out: { { X: number, Z: number, R: number } } = {}
	local count = peril.Count or 0
	local radius = peril.Radius or { 10, 16 }
	local r = rng((peril.Seed or 7) + (S.Seed or 0) * 31)
	local O = S.Origin
	local tries = 0
	while #out < count and tries < count * 80 do
		tries += 1
		local lx = (r() * 2 - 1) * S.Half * 0.72
		local lz = (r() * 2 - 1) * S.Half * 0.72
		local rad = radius[1] + (radius[2] - radius[1]) * r()
		local ok = S.goodSpot == nil or S.goodSpot(lx, lz, peril.MaxSlope or 0.35, rad + 12)
		if ok and peril.Materials and S.materialAt then
			local mat = S.materialAt(O.X + lx, O.Z + lz)
			ok = table.find(peril.Materials, mat) ~= nil
		end
		if ok then
			for _, z in out do
				if (z.X - lx) ^ 2 + (z.Z - lz) ^ 2 < (z.R + rad + 30) ^ 2 then
					ok = false
					break
				end
			end
		end
		if ok then
			table.insert(out, { X = math.floor(lx + 0.5), Z = math.floor(lz + 0.5), R = math.floor(rad * 10 + 0.5) / 10 })
		end
	end
	cache[key] = out
	return out
end

-- ¿En qué zona de este peligro está el punto local (lx, lz)? (la zona o nil)
function TerrainPerils.zoneAt(S: any, peril: Peril, lx: number, lz: number): { X: number, Z: number, R: number }?
	for _, z in TerrainPerils.zones(S, peril) do
		if (lx - z.X) ^ 2 + (lz - z.Z) ^ 2 <= z.R * z.R then
			return z
		end
	end
	return nil
end

-- ¿Está activo ahora? (los de zona fija, siempre; los de momento, solo en su momento)
function TerrainPerils.active(peril: Peril, mode: string?): boolean
	if peril.Mode == nil then
		return true
	end
	return peril.Mode == mode
end

-- Las definiciones de un planeta (S.Perils) que estén bien escritas
function TerrainPerils.of(S: any): { Peril }
	local out = {}
	for _, p in (S and S.Perils) or {} do
		if type(p) == "table" and TerrainPerils.Kinds[p.Kind] and type(p.Id) == "string" then
			table.insert(out, p)
		end
	end
	return out
end

-- Fuera de la zona: el punto de la orilla más cercano (para salir del hielo roto), a `gap` studs
function TerrainPerils.shore(zone: { X: number, Z: number, R: number }, lx: number, lz: number, gap: number): (number, number)
	local dx, dz = lx - zone.X, lz - zone.Z
	local d = math.sqrt(dx * dx + dz * dz)
	if d < 1e-3 then
		dx, dz, d = 1, 0, 1
	end
	local k = (zone.R + gap) / d
	return zone.X + dx * k, zone.Z + dz * k
end

TerrainPerils._rng = rng
function TerrainPerils._clearCache()
	table.clear(cache)
end

return TerrainPerils
