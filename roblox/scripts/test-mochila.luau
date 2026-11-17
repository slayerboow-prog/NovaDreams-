-- test-mochila: la mochila con páginas (shared/Items, Controllers/InventoryUI). lune run scripts/test-mochila.luau
local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local check = L.check
local Items = L.load("src/shared/Items")

print("🎒 Páginas")
check(Items.Hotbar == 9 and Items.PageSize == 45 and Items.Pages == 4 and Items.Slots == 189, "barra rápida de 9 y cuatro páginas de 45 (189 casillas)")
check(Items.pageStart(1) == 10 and Items.pageStart(4) == 145 and Items.pageStart(4) + Items.PageSize - 1 == Items.Slots, "cada página empieza donde acaba la anterior")
check(Items.pageOf(5) == nil and Items.pageOf(10) == 1 and Items.pageOf(54) == 1 and Items.pageOf(55) == 2 and Items.pageOf(189) == 4, "cada casilla sabe su página")

print("🗑 Tirar")
check(Items.canDrop({ Id = "PocionCuracion", Kind = "Potion" }) and Items.canDrop({ Id = "Pan", Kind = "Food" }) and Items.canDrop({ Id = "Colmillo", Kind = "Material" }), "se pueden tirar comida, pociones y materiales")
check(not Items.canDrop({ Id = "Foto", Kind = "Keepsake" }) and not Items.canDrop({ Id = "Vehiculo_Bici", Kind = "Vehicle" }) and not Items.canDrop({ Id = "Titulo_X", Kind = "Thing" }) and not Items.canDrop(nil), "pero no los recuerdos de la historia, los vehículos ni los títulos")

print("🔌 Conexiones")
local ui = fs.readFile("src/client/Controllers/InventoryUI.luau")
check(string.find(ui, "pageTabs", 1, true) ~= nil and string.find(ui, "Items.pageStart", 1, true) ~= nil and string.find(ui, "InventoryUI.setPage", 1, true) ~= nil, "la ventana tiene pestañas I-IV y dibuja cada página")
check(string.find(ui, "se encoge hasta caber", 1, true) ~= nil, "y se encoge en pantallas bajas (móvil)")
local svc = fs.readFile("src/server/Services/InventoryService.luau")
check(string.find(svc, "Items.Slots", 1, true) ~= nil and string.find(svc, "for i = 1, 36", 1, true) == nil, "el servidor usa todas las casillas")
check(string.find(svc, '"DropAll"', 1, true) ~= nil and string.find(svc, "Items.canDrop", 1, true) ~= nil, "el servidor deja tirar uno o el montón entero")
check(string.find(ui, '"Tirar todo"', 1, true) ~= nil and string.find(ui, "¿Seguro?", 1, true) ~= nil, "botón «Tirar todo» con confirmación")
check(string.find(ui, "AnchorPoint = Vector2.new(1, 0.5)", 1, true) ~= nil and string.find(ui, "BackgroundTransparency = 0.45", 1, true) == nil, "la mochila va pegada a la derecha y no oscurece ni tapa la pantalla")
local combat = fs.readFile("src/client/Controllers/CombatController.luau")
check(string.find(combat, "not InventoryUI.isOpen()", 1, true) == nil, "con la mochila abierta se sigue atacando")
L.finish("test-mochila")
