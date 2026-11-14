-- Prueba de los peligros del terreno de los planetas (shared/Cosmos/TerrainPerils), con Lune.
--
-- Uso (desde la carpeta roblox/):
--   lune run scripts/test-peligros.luau
--
-- Comprueba, planeta a planeta:
--   * cada planeta (menos Tefra, que lleva su guerra y su calor aparte) tiene al menos dos peligros
--     propios, bien escritos, con su aviso, y que no se repiten entre planetas;
--   * las zonas del suelo (arenas movedizas, ciénaga, hielo fino…) salen, siempre las mismas, dentro
--     del planeta, fuera de la ciudad, de la plataforma y de los puntos de interés, y sin pisarse;
--   * los peligros de momento (rayos, ráfagas, ramas, paneles) usan un momento que el planeta tiene de
--     verdad (S.moment lo devuelve a alguna hora);
--   * las cuentas: zoneAt, active y la orilla del hielo roto.

local roblox = require("@lune/roblox")
local L = require("./lib/ModuleLoader")

local Vector3 = roblox.Vector3
local check = L.check

local PlanetRegistry = L.load("src/shared/Cosmos/PlanetRegistry")
local TerrainPerils = L.load("src/shared/Cosmos/TerrainPerils")

print("▶ Peligros del terreno de cada planeta")
local seenIds: { [string]: string } = {}
local seenNames: { [string]: string } = {}
for _, id in PlanetRegistry.ids() do
	local S = PlanetRegistry.get(id)
	if id ~= "Tefra" and S and S.Hazard then
		local perils = TerrainPerils.of(S)
		check(#perils >= 2, ("%s: tiene sus propios peligros del terreno (%d)"):format(id, #perils))
		-- Los momentos que tiene el planeta de verdad
		local modes: { [string]: boolean } = {}
		if S.moment then
			for h = 0, 23.75, 0.25 do
				local m = S.moment(h, nil)
				if m then
					modes[m] = true
				end
			end
		end
		for _, p in perils do
			check(seenIds[p.Id] == nil and p.Id:sub(1, #id) == id, ("%s: «%s» tiene un nombre propio del planeta"):format(id, p.Id))
			seenIds[p.Id] = id
			check(seenNames[p.Name] == nil, ("%s: «%s» no lo tiene otro planeta"):format(id, p.Name))
			seenNames[p.Name] = id
			check(type(p.Text) == "string" and #p.Text > 20, ("%s: «%s» explica qué hacer"):format(id, p.Name))
			if p.Mode then
				check(modes[p.Mode] == true, ("%s: «%s» pasa en «%s», un momento que el planeta tiene"):format(id, p.Name, p.Mode))
			end
			if p.Kind == "Pozo" or p.Kind == "Hielo" then
				local zones = TerrainPerils.zones(S, p)
				local again = TerrainPerils.zones(S, p)
				check(#zones >= math.min(p.Count or #zones, 3) and #zones > 0, ("%s: «%s» tiene zonas en el suelo (%d)"):format(id, p.Name, #zones))
				check(again == zones, ("%s: «%s» salen siempre las mismas"):format(id, p.Name))
				local okPlace, okGap = true, true
				for i, z in zones do
					local inCity = S.City and S.City.inside and S.City.inside(z.X, z.Z, 0)
					local onPad = math.sqrt(z.X ^ 2 + z.Z ^ 2) < (S.PadRadius or 28) + z.R
					if math.max(math.abs(z.X), math.abs(z.Z)) + z.R > S.Half or inCity or onPad then
						okPlace = false
						print(("     %s %s #%d en (%d, %d) r=%.1f%s%s"):format(id, p.Id, i, z.X, z.Z, z.R, if inCity then " · en la ciudad" else "", if onPad then " · en la plataforma" else ""))
					end
					for _, poi in S.POIs do
						if not poi.Pad and not p.Fixed and math.sqrt((z.X - poi.X) ^ 2 + (z.Z - poi.Z) ^ 2) < poi.Flat + z.R then
							okPlace = false
							print(("     %s %s #%d encima de %s"):format(id, p.Id, i, poi.Id))
						end
					end
					for j, w in zones do
						if j ~= i and math.sqrt((z.X - w.X) ^ 2 + (z.Z - w.Z) ^ 2) < z.R + w.R then
							okGap = false
						end
					end
				end
				check(okPlace, ("%s: «%s» fuera de la ciudad, la plataforma y los sitios de la historia"):format(id, p.Name))
				check(okGap, ("%s: «%s» las zonas no se pisan"):format(id, p.Name))
				local z = zones[1] or { X = 0, Z = 0, R = 1 }
				check(TerrainPerils.zoneAt(S, p, z.X, z.Z) ~= nil and TerrainPerils.zoneAt(S, p, z.X + z.R + 1, z.Z) == nil or #zones > 1, ("%s: «%s» se sabe si estás dentro"):format(id, p.Name))
			end
		end
	end
end

print("▶ Las cuentas")
local rayo = { Id = "X_Rayo", Kind = "Rayo", Name = "Rayo", Icon = "⚡", Mode = "Tormenta", Text = "aviso" }
check(TerrainPerils.active(rayo, "Tormenta") and not TerrainPerils.active(rayo, nil) and not TerrainPerils.active(rayo, "Otra"), "un rayo solo cae en su momento")
check(TerrainPerils.active({ Id = "X", Kind = "Pozo", Name = "P", Icon = "", Text = "" }, nil), "un pozo está siempre")
local sx, sz = TerrainPerils.shore({ X = 0, Z = 0, R = 10 }, 3, 4, 6)
check(math.abs(math.sqrt(sx * sx + sz * sz) - 16) < 1e-6 and sx > 0 and sz > 0, "al romperse el hielo sales a la orilla, del lado por el que ibas")
local cx = TerrainPerils.shore({ X = 5, Z = 5, R = 10 }, 5, 5, 6)
check(cx == 21, "en el centro justo también hay orilla")
check(#TerrainPerils.of({ Perils = { { Id = "Mal", Kind = "Nada" }, rayo } }) == 1, "los peligros mal escritos no cuentan")
local _ = Vector3

L.finish("test-peligros")
