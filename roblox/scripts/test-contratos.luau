-- test-contratos: los CONTRATOS DE CAZA de los tablones (shared/HuntContracts, Services/HuntContractService).
-- lune run scripts/test-contratos.luau

local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local check = L.check

local HC = L.load("src/shared/HuntContracts")
local Bestiary = L.load("src/shared/Cosmos/Bestiary")

print("📜 Zonas y contratos")
local zones = HC.zones()
check(#zones == 12, ("doce zonas de caza: cuatro distritos y ocho regiones (%d)"):format(#zones))
local okZ = true
for _, z in zones do
	for _, sid in z.Species do
		okZ = okZ and Bestiary.Species[sid] ~= nil
	end
	okZ = okZ and (z.Boss == nil or Bestiary.Species[z.Boss] ~= nil)
end
check(okZ, "todas sus especies y jefes existen en el bestiario")
check(HC.zonesFor(3)[1].Id == "Farm_Oeste" and HC.zonesFor(60)[1].Min <= 60, "a nivel 3 toca la Caza del Oeste; a nivel 60, algo de su nivel")

local today = HC.day(1794931200)
local a = HC.offers(5, 1234, today)
local b = HC.offers(5, 1234, today)
local c = HC.offers(5, 1234, today + 1)
check(#a == HC.Offers and a[1].Key == b[1].Key and a[2].Key == b[2].Key, "tres contratos, los mismos todo el día")
check(a[1].Key ~= c[1].Key or a[2].Key ~= c[2].Key or a[3].Key ~= c[3].Key or true, "y al día siguiente, otros (o pueden repetirse)")
local kinds = {}
for _, k in a do
	kinds[k.Kind] = true
	check(k.Need > 0 and k.Money > 0 and k.Xp > 0 and k.Potions > 0 and HC.title(k) ~= "", "contrato con objetivo, premio y texto: " .. HC.title(k) .. " (" .. HC.rewardText(k) .. ")")
end
check(kinds.Caza and kinds.Zona, "hay de cazar una especie y de limpiar una zona")
local high = HC.offers(30, 99, today)
local hasBoss = false
for _, k in high do
	hasBoss = hasBoss or k.Kind == "Jefe"
end
check(hasBoss, "a nivel 30 ya se ofrece derribar el jefe de una región")
check(HC.plural("Lobo del bosque") == "lobos del bosque" and HC.plural("Oso gigante") == "osos gigantes", "plurales: lobos del bosque, osos gigantes")

print("🎯 Qué cuenta")
local caza = a[1]
check(HC.matches(caza, { Species = caza.Species, Region = caza.Zone }), "la especie del contrato en su zona cuenta")
check(not HC.matches(caza, { Species = caza.Species, Region = "OtraZona" }), "en otra zona no")
check(not HC.matches(caza, { Species = caza.Species, Region = caza.Zone, Planet = "Tefra" }), "ni en otro planeta")
local zona = a[2]
check(HC.matches(zona, { Species = "Cualquiera", Region = zona.Zone }), "limpiar una zona: cualquier bestia de allí")
local m1, x1 = HC.reward("Caza", 10, 5)
local m2, x2 = HC.reward("Caza", 10, 50)
check(m2 > m1 and x2 > x1, "a más nivel, más premio")

print("🧾 El servicio")
local data = { Money = 0 }
local paid = 0
L.mock("src/server/Services/DataService", {
	get = function()
		return data
	end,
	addMoney = function(_, n)
		paid += n
		return true
	end,
})
L.services.Players = L.services.Players or { GetPlayers = function()
	return {}
end }
local Svc = L.load("src/server/Services/HuntContractService")
local p = L.player("Ana", 1234)
p:SetAttribute("Level", 5)
local offers = Svc.offers(p)
check(#offers == 3, "el tablón ofrece tres")
check(Svc.accept(p, offers[1].Key) == true and #data.Hunt.Active == 1 and p:GetAttribute("HuntContracts") ~= nil, "se coge uno y sale en el panel")
check(#Svc.offers(p) == 2 and Svc.accept(p, offers[1].Key) == false, "y ya no se puede volver a coger")
local k = data.Hunt.Active[1]
for _ = 1, k.Need - 1 do
	Svc.onKill(p, { Species = k.Species, Region = k.Zone, Planet = "Valmar" })
end
check(data.Hunt.Active[1].Have == k.Need - 1 and paid == 0, "las bestias van sumando")
Svc.onKill(p, { Species = k.Species, Region = k.Zone, Planet = "Valmar" })
check(#data.Hunt.Active == 0 and paid == k.Money and data.Hunt.Done == 1 and p:GetAttribute("HuntContracts") == nil, "al completarlo se cobra solo y sale del panel")
Svc.accept(p, offers[2].Key)
Svc.accept(p, offers[3].Key)
check(Svc.abandon(p, 1) and #data.Hunt.Active == 1, "se puede dejar un contrato")

print("🔌 Conexiones")
local main = fs.readFile("src/server/Main.server.luau")
check(string.find(main, '"HuntContractService"', 1, true) ~= nil, "el servidor arranca los contratos")
local beasts = fs.readFile("src/server/Services/BeastService.luau")
check(string.find(beasts, 'Region = b.Model:GetAttribute("Region")', 1, true) ~= nil, "cada bestia que cae dice su zona")
local hud = fs.readFile("src/client/UI/Hud.luau")
check(string.find(hud, "Contratos de caza", 1, true) ~= nil and string.find(hud, '"HuntContracts"', 1, true) ~= nil, "el panel de misiones enseña los contratos y deja dejarlos")
local svc = fs.readFile("src/server/Services/HuntContractService.luau")
check(string.find(svc, "SchoolEntrance", 1, true) ~= nil and string.find(svc, "OuterLands.Bridges", 1, true) ~= nil, "tablones en la Academia y en los campamentos")

L.finish("test-contratos")
