-- test-mapadefinitivo: el MAPA DEFINITIVO del dueño (docs/mapa/mapa-definitivo.png): el orden de las regiones, el
-- asentamiento (World/Kit/Settlement), la pantalla del mapa (Controllers/WorldMapUI) y el HUD (UI/MmoHud).
-- lune run scripts/test-mapadefinitivo.luau

local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local check = L.check

local VR = L.load("src/shared/Cosmos/ValmarRegions")
local OL = L.load("src/shared/Cosmos/OuterLands")

print("🗺 Las regiones, como en el dibujo")
local function at(b: number): string
	local a = math.rad(b)
	local reg = VR.at(math.sin(a) * 4000, -math.cos(a) * 4000)
	return reg and reg.Id or "?"
end
check(at(315) == "TierrasOscuras" and at(0) == "MontanasHeladas" and at(45) == "TierrasVolcanicas", "arriba: Tierras Oscuras, Montañas Heladas y Tierras Volcánicas")
check(at(270) == "PantanoMaldito" and at(90) == "DesiertoDorado" and VR.ById.DesiertoDorado.Name == "Desierto Devastado", "a los lados: el Pantano Maldito y el Desierto Devastado")
check(at(225) == "BosqueEtereo" and at(180) == "LlanurasSalvajes" and at(135) == "RuinasAntiguas", "abajo: Bosque Etéreo, Llanuras Salvajes y Ruinas Antiguas")
check(OL.Volcano.X > 0 and OL.Volcano.Z < 0, "el volcán, arriba a la derecha")
local lv = {}
for _, r in VR.List do
	lv[r.Id] = ("%d-%d"):format(r.MinLevel, r.MaxLevel)
end
check(lv.BosqueEtereo == "10-30" and lv.LlanurasSalvajes == "20-40" and lv.PantanoMaldito == "40-60" and lv.DesiertoDorado == "50-70" and lv.RuinasAntiguas == "60-80"
	and lv.MontanasHeladas == "70-90" and lv.TierrasOscuras == "80-100" and lv.TierrasVolcanicas == "90-110", "los niveles de cada región, los del dibujo")

print("🏚 El asentamiento")
local town = fs.readFile("src/server/World/TownBuilder.luau")
check(string.find(town, "Kit.Settlement", 1, true) ~= nil, "el mapa monta el asentamiento (casas rústicas, empalizada y ruinas)")
local set = fs.readFile("src/server/World/Kit/Settlement.luau")
check(string.find(set, "Manzana_Downtown", 1, true) ~= nil and string.find(set, "PlacaSolar", 1, true) ~= nil and string.find(set, "TorreVigia", 1, true) ~= nil, "casas con placa solar donde estaban los rascacielos y torres de vigía en la empalizada")

print("🧭 La pantalla del mapa y el HUD")
local ids = L.load("src/shared/MapTextureIds")
check(type(ids.definitivo) == "string" and string.match(ids.definitivo, "^rbxassetid://%d+$") ~= nil, "el dibujo del dueño está subido")
local ui = fs.readFile("src/client/Controllers/WorldMapUI.luau")
for _, word in { "Leyenda", "Tu ubicación", "Jefe Mundial", "Campamento", "Camino Principal", "Explora el mundo, derrota monstruos y mejora tu personaje.", "100%%" } do
	check(string.find(ui, word) ~= nil, "en el mapa: " .. word)
end
local mapui = fs.readFile("src/client/Controllers/MapUI.luau")
check(string.find(mapui, "WorldMapUI.toggle()", 1, true) ~= nil, "la M y el botón Mapa abren el mapa definitivo en Valmar")
local hud = fs.readFile("src/client/UI/MmoHud.luau")
check(string.find(hud, '"Vida"', 1, true) ~= nil and string.find(hud, '"Energia"', 1, true) ~= nil and string.find(hud, '"Gemas"', 1, true) ~= nil and string.find(hud, "🪙", 1, true) == nil, "HUD: retrato con nivel, vida, energía, dinero y gemas (sin emoji modernos)")

L.finish("test-mapadefinitivo")
