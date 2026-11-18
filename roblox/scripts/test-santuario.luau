-- test-santuario: el Santuario del Bosque jugable (Services/SanctuaryService, World/Kit/ForestSanctuary,
-- World/Kit/AncientTree). lune run scripts/test-santuario.luau

local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local check = L.check

print("🌳 La misión «El Santuario Perdido»")
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
L.services.CollectionService = L.services.CollectionService or { GetTagged = function()
	return {}
end }
L.services.TweenService = L.services.TweenService or { Create = function() return { Play = function() end } end }
local S = L.load("src/server/Services/SanctuaryService")
local p = L.player("Ana", 77)
p:SetAttribute("Level", 30)
local st = S._state(p)
check(st.Step == 0 and not st.Done, "al principio, la misión sin empezar")
-- (sin diálogos de verdad: el paso 1 lo da hablar con el guardián)
st.Step = 2
S.publish(p)
check(p:GetAttribute("SantuarioQuest") ~= nil, "la misión sale en el panel")
local function rune(n)
	local part = { GetAttribute = function(_, k)
		return if k == "RunaSantuario" then n else nil
	end, Color = nil }
	S._touchRune(p, part)
end
rune(1)
rune(1)
rune(2)
check(st.Step == 2, "con dos runas aún no se pasa de paso")
rune(3)
check(st.Step == 3, "con las tres runas despiertas, a cazar")
for _ = 1, 9 do
	S._onKill(p, { Region = "BosqueEtereo" })
end
S._onKill(p, { Region = "PantanoMaldito" })
check(st.Step == 3 and st.Kills == 9, "solo cuentan las bestias del Bosque Etéreo")
S._onKill(p, { Region = "BosqueEtereo" })
check(st.Step == 4, "diez bestias: al núcleo")
p:SetAttribute("Level", 20)
S._activateCore(p, { GetAttribute = function()
	return true
end, FindFirstAncestorOfClass = function()
	return nil
end })
check(not st.Done, "con menos de nivel 25 el núcleo te rechaza")
p:SetAttribute("Level", 25)
S._activateCore(p, { GetAttribute = function()
	return true
end, FindFirstAncestorOfClass = function()
	return nil
end })
check(st.Done and paid == S.Rewards.Money and p:GetAttribute("SantuarioQuest") == nil, "a nivel 25 el núcleo despierta: recompensa y misión cumplida")

print("🏛 El santuario")
local sanct = fs.readFile("src/server/World/Kit/ForestSanctuary.luau")
for _, w in { "Escalon", "Columna", "EstatuaGuardian", "AltarRuna", "AltarNucleo", "Farol", "Estandarte", "Agua", "AnilloRunas", "Muro" } do
	check(string.find(sanct, w, 1, true) ~= nil, "el santuario tiene: " .. w)
end
local tree = fs.readFile("src/server/World/Kit/AncientTree.luau")
check(string.find(tree, "AncientTree.buildMesh", 1, true) ~= nil and string.find(tree, "ArbolAssetIds", 1, true) ~= nil, "el árbol se hace con las mallas de Blender (y, si no están, con piezas)")
local ids = L.load("src/shared/ArbolAssetIds")
local plan = L.load("src/shared/ArbolMalla")
local allIds = true
for _, piece in plan.Pieces do
	allIds = allIds and type(ids.Piezas[piece.Name]) == "string"
	check(piece.Tris <= 20000, ("%s: %d triángulos (≤ 20.000)"):format(piece.Name, piece.Tris))
end
check(allIds, "todas las piezas del árbol están subidas")
local main = fs.readFile("src/server/Main.server.luau")
check(string.find(main, '"SanctuaryService"', 1, true) ~= nil, "el servidor arranca el santuario")
L.finish("test-santuario")
