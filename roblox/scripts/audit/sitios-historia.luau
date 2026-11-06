--!nocheck
-- ¿Existen en el mapa construido todos los sitios que usan las misiones y las escenas de la historia?
--
--   lune run scripts/audit/sitios-historia.luau <mapa construido .rbxl>
--
-- Junta los Place que aparecen en shared/LifeStory (Place = "X", "Place:X", Teleport/Before/Between…),
-- mira su definición en Locations.Places y cuenta en el mapa sus candidatos (la etiqueta o el nombre del
-- modelo, con los atributos que pida). Un sitio:
--   * sin definición en Locations           → ❌ (la misión no puede llevarte a ningún lado)
--   * sin candidatos y sin Fallback que sí  → ❌ (la escena saldría en un prado o donde estés)
--   * sin candidatos pero con Fallback bueno → ⚠️ (va al de reserva)
--   * de interior (Inside) o especial        → se da por bueno (las salas las crea InteriorService al
--                                              entrar; Home, NearPlayer… dependen del jugador)

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local L = require("../lib/ModuleLoader")

local mapPath = assert(process.args[1], "Uso: lune run scripts/audit/sitios-historia.luau <mapa construido .rbxl>")

local Locations = L.load("src/shared/LifeStory/Locations")
local Places = Locations.Places

-- 1. Los sitios que se usan (y dónde)
local used: { [string]: { string } } = {}
local function note(id: string, file: string)
	used[id] = used[id] or {}
	if #used[id] < 3 and not table.find(used[id], file) then
		table.insert(used[id], file)
	end
end
local function scan(dir: string)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			scan(path)
		elseif name:match("%.luau$") and not path:match("Locations%.luau$") then
			-- (sin comentarios: «Place = "Lugar"» de una explicación no es un sitio)
			local src = fs.readFile(path):gsub("%-%-%[(=*)%[.-%]%1%]", ""):gsub("%-%-[^\n]*", "")
			local short = path:gsub("^src/shared/LifeStory/", "")
			for id in src:gmatch('Place%s*=%s*"([%w_]+)"') do
				note(id, short)
			end
			for id in src:gmatch('"Place:([%w_]+)"') do
				note(id, short)
			end
			for a, b in src:gmatch('Between%s*=%s*{%s*"([%w_]+)"%s*,%s*"([%w_]+)"') do
				note(a, short)
				note(b, short)
			end
		end
	end
end
scan("src/shared/LifeStory")

-- 2. El mapa: etiquetas y nombres de modelo (con sus atributos)
local game = roblox.deserializePlace(fs.readFile(mapPath))
local byTag: { [string]: { Instance } } = {}
local byName: { [string]: { Instance } } = {}
for _, inst in game:GetService("Workspace"):GetDescendants() do
	for _, tag in inst:GetTags() do
		byTag[tag] = byTag[tag] or {}
		table.insert(byTag[tag], inst)
	end
	if inst:IsA("Model") or inst:IsA("BasePart") or inst:IsA("Folder") then
		byName[inst.Name] = byName[inst.Name] or {}
		table.insert(byName[inst.Name], inst)
	end
end

local function matches(inst: Instance, attrs: { [string]: any }?): boolean
	for k, v in attrs or {} do
		if inst:GetAttribute(k) ~= v then
			return false
		end
	end
	return true
end

local function count(place: any): number
	local list = if place.Model then byName[place.Model] elseif place.Tag then byTag[place.Tag] else nil
	local n = 0
	for _, inst in list or {} do
		if matches(inst, place.Attribute) then
			n += 1
		end
	end
	return n
end

-- Sitios que el juego construye al arrancar (no van en el archivo): la isla del sueño del prólogo
-- (Kit/DreamIsland), los planetas (PlanetWorld/PlanetService) y el mar hondo y Nácara
local RUNTIME = { "^Prologo", "^Tefra_", "^Talasa_", "^Umbria_", "^Vertice_", "^Nivalis", "^Miasma", "^Siroco", "^Varkun", "^Mar_", "^Nacara", "^Abismo" }
local function runtimeBuilt(id: string): boolean
	for _, pattern in RUNTIME do
		if id:match(pattern) then
			return true
		end
	end
	return false
end

local function ok(id: string, depth: number): (boolean, string)
	local place = Places[id]
	if place and runtimeBuilt(id) then
		return true, "se construye al arrancar"
	end
	if not place then
		return false, "sin definición en Locations"
	end
	if place.Special then
		return true, "especial (" .. tostring(place.Special) .. ")"
	end
	if place.Between then
		local a = ok(place.Between[1], depth + 1)
		local b = ok(place.Between[2], depth + 1)
		return a and b, "entre " .. place.Between[1] .. " y " .. place.Between[2]
	end
	if place.Inside then
		return true, "interior (lo crea InteriorService)"
	end
	local n = count(place)
	if n > 0 then
		return true, n .. " en el mapa"
	end
	if place.Fallback and depth < 4 then
		local fb = ok(place.Fallback, depth + 1)
		if fb then
			return true, "⚠️ 0 en el mapa, va a su reserva " .. place.Fallback
		end
	end
	return false, "0 en el mapa (" .. (if place.Model then "modelo «" .. place.Model .. "»" else "etiqueta «" .. tostring(place.Tag) .. "»") .. ")"
end

local ids = {}
for id in used do
	table.insert(ids, id)
end
table.sort(ids)
local bad, warn = 0, 0
for _, id in ids do
	local good, why = ok(id, 0)
	if not good then
		bad += 1
		print(("❌ %s: %s · usado en %s"):format(id, why, table.concat(used[id], ", ")))
	elseif why:find("⚠️", 1, true) then
		warn += 1
		print(("%s: %s · usado en %s"):format(id, why, table.concat(used[id], ", ")))
	end
end
print(("\n%d sitios usados por la historia · %d sin sitio en el mapa · %d van a su reserva"):format(#ids, bad, warn))
process.exit(if bad > 0 then 1 else 0)
