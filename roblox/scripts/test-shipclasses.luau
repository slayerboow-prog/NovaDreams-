-- test-shipclasses: las clases de nave, los módulos con potencia y los materiales (expansión «La Deriva»,
-- fase 1; docs/espacio-aaa/expansion-15h.md §7). lune run scripts/test-shipclasses.luau

local roblox = require("@lune/roblox")
local fs = require("@lune/fs")
local L = require("./lib/ModuleLoader")
local Vector3 = roblox.Vector3
local check = L.check

local ShipFlight = L.load("src/shared/AirCombat/ShipFlight")
local ShipClasses = L.load("src/shared/AirCombat/ShipClasses")
local ShipCombat = L.load("src/shared/AirCombat/ShipCombat")
local Mining = L.load("src/shared/Cosmos/Mining")

print("🚀 Clases de nave")
local base = ShipFlight.Specs.Caza
local _, caza = ShipClasses.flightSpec("Caza", 0)
check(caza.MaxSpeed == base.MaxSpeed and caza.PitchRate == base.PitchRate, "el Caza vuela igual que la nave de siempre")
local _, inter = ShipClasses.flightSpec("Interceptor", 0)
local _, carga = ShipClasses.flightSpec("Carguero", 0)
local _, explo = ShipClasses.flightSpec("Explorador", 0)
check(inter.MaxSpeed > caza.MaxSpeed and inter.PitchRate > caza.PitchRate, "el Interceptor es más rápido y gira mejor")
check(carga.MaxSpeed < caza.MaxSpeed and ShipClasses.shieldSpec("Carguero").Hull > ShipClasses.shieldSpec("Caza").Hull, "el Carguero es lento y más duro")
check(ShipClasses.Defs.Explorador.Radar > 1 and ShipClasses.Defs.Carguero.Cargo > 2, "el Explorador ve más lejos y el Carguero carga mucho más")
check(inter.Radius == caza.Radius, "misma esfera de choque (mismo modelo): el servidor valida igual")
local key, sped = ShipClasses.flightSpec("Caza", 0.2)
check(math.abs(sped.MaxSpeed - base.MaxSpeed * 1.2) < 1e-6 and ShipFlight.Specs[key] == sped, "el impulsor sube la velocidad y la física queda registrada para ShipFlight.new")
local st = ShipFlight.new(key, roblox.CFrame.new(0, 100, 0), "Space")
check(st.Spec == sped, "ShipFlight.new usa la física de la clase (cliente y servidor igual)")
check(ShipClasses.def("NoExiste").Name == ShipClasses.Defs.Caza.Name and not ShipClasses.valid(nil), "una clase rara cae en el Caza")
local names = {}
local distinct = true
for _, id in ShipClasses.Order do
	local d = ShipClasses.Defs[id]
	if names[d.Name] then
		distinct = false
	end
	names[d.Name] = true
	if id ~= ShipClasses.Default and not d.Price then
		distinct = false
	end
end
check(distinct and ShipClasses.Defs.Caza.Price == nil, "cada clase con su nombre y su precio (el Caza ya lo tienes)")

print("⬆ Módulos y potencia")
local old = { Blindaje = 3, Baterias = 3, Bengalas = 2 } -- (una partida de antes: todo al máximo de entonces)
local inst = ShipCombat.installed(old, {})
check(inst.Blindaje == 3 and inst.Baterias == 3 and inst.Bengalas == 2, "las mejoras compradas antes siguen puestas (nadie pierde nada)")
check(ShipCombat.power(inst) == 8 and 8 <= ShipClasses.Defs.Caza.Power and 8 <= ShipClasses.Defs.Interceptor.Power, "y caben en la potencia de cualquier clase")
local off = ShipCombat.installed(old, { Blindaje = true })
check(off.Blindaje == nil and ShipCombat.power(off) == 5, "un módulo apagado no da nada ni gasta potencia")
local b = ShipCombat.bonuses({ Blindaje = 5, Impulsor = 2, Radar = 1, Bodega = 3 })
check(b.Hull == 100 and math.abs(b.Speed - 0.08) < 1e-9 and math.abs(b.Radar - 0.12) < 1e-9 and b.Cargo == 18, "cada módulo da lo suyo (casco, velocidad, radar, bodega)")
local p3 = ShipCombat.upgradePrice("Blindaje", 2)
local p4 = ShipCombat.upgradePrice("Blindaje", 3)
check(p3 and p3.Componentes == 0 and p4 and p4.Componentes > 0, "desde el nivel 4 los módulos piden Componentes")
check(ShipCombat.upgradePrice("Bengalas", 3) == nil, "al máximo no hay precio")
local slots = true
for _, id in ShipCombat.UpgradeOrder do
	if not ShipCombat.Upgrades[id] or type(ShipCombat.Upgrades[id].Slot) ~= "string" then
		slots = false
	end
end
check(slots and #ShipCombat.UpgradeOrder == 6, "6 módulos, cada uno en su tipo de ranura")

print("⛏ Bodega por nave")
local rate = { Last = -math.huge, Times = {} }
local ok1 = Mining.allow(rate, 100, 45, Vector3.new(0, 0, 0), Vector3.new(10, 0, 0), false, 100)
local rate2 = { Last = -math.huge, Times = {} }
local ok2, why = Mining.allow(rate2, 100, 45, Vector3.new(0, 0, 0), Vector3.new(10, 0, 0), false)
check(ok1 and not ok2 and why == "Cargo", "con una bodega grande (Carguero) se sigue minando donde la normal ya está llena")

print("🖥 Servidor y cliente")
local space = fs.readFile("src/server/Services/SpaceService.luau")
local ac = fs.readFile("src/server/Services/AirCombatService.luau")
local client = fs.readFile("src/client/Controllers/AirCombatClient.luau")
local data = fs.readFile("src/server/Services/DataService.luau")
check(string.find(space, "function SpaceService.chooseClass", 1, true) ~= nil and string.find(space, "function SpaceService.toggleModule", 1, true) ~= nil and string.find(space, "Astillero", 1, true) ~= nil, "taller: módulos (subir, encender, apagar) y astillero (comprar y elegir clase)")
check(string.find(space, "Class = sp.Ship.Class", 1, true) ~= nil and string.find(space, "ShipCombat.installed(sp.Upgrades, sp.Ship.Off)", 1, true) ~= nil, "la nave sale con su clase y solo los módulos encendidos")
check(string.find(ac, "Shields.new(ShipClasses.shieldSpec(shipClass))", 1, true) ~= nil and string.find(ac, "local spec = ShipFlight.Specs[AirCombatService.ShipKind]", 1, true) == nil, "el servidor valida el vuelo y el casco con la clase de la sesión")
check(string.find(client, "ShipClasses.flightSpec(payload.Class, payload.Speed)", 1, true) ~= nil, "el cliente vuela con la misma física que el servidor")
check(string.find(data, "Ship = { Class = \"Caza\"", 1, true) ~= nil and string.find(data, "Mats = {}", 1, true) ~= nil, "se guarda la nave y los materiales (valores por defecto para partidas viejas)")
check(string.find(space, "HourCap = { Componentes", 1, true) ~= nil and string.find(space, "grantMat(player, \"Componentes\"", 1, true) ~= nil and string.find(space, "grantMat(player, \"Datos\"", 1, true) ~= nil, "Componentes al derribar y Datos con el escáner, con tope por hora")

L.finish("test-shipclasses")
