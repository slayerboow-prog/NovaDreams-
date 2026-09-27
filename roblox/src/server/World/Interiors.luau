-- Interiors: las salas por dentro de los edificios del mapa (las usa InteriorService).
--
-- Los edificios de la ciudad son, por fuera, bloques ligeros (para que el móvil vaya fluido).
-- Al pulsar "Entrar" en su puerta, InteriorService crea la sala de ese tipo en una zona oculta
-- y te lleva allí; al salir vuelves a la calle. Cada sala:
--   * se construye alrededor de cf: suelo en y = 0, la puerta de salida en el lado -Z (local)
--   * tiene una pieza "InteriorEntry" (donde apareces) y una "InteriorExit" (puerta para salir)
--   * puede tener "InteriorElevator" (ascensor a otras plantas)
--   * está amueblada y decorada según su tipo (World/Furniture), con un número fijo por edificio
--     (opts.Seed = la clave del edificio y la planta): cada casa es distinta, pero siempre la misma
--   * lo que se puede usar (sentarse, camas, tele, luces, nevera, grifos, ducha, puertas, armarios,
--     ordenador, piano, ventanas) lleva la etiqueta "Interact" (InteractService le pone el cartel)
-- Tipos: Casa, Villa, Portal, Piso, OficinaLobby, Oficina, Local, Nave, Taller, Ocio, Aula,
--        Ayuntamiento, Museo, Teatro, Estacion, CentroComercial, Juzgado, Hacienda, Cuartel.
--
-- Viviendas (Casa, Villa y cada Piso): recibidor y salón-comedor delante, y al fondo el dormitorio
-- principal, el baño y otra habitación (infantil, despacho o de invitados), con tabiques y puertas.
--   ┌────────────┬───────┬────────────┐  fondo
--   │ DORMITORIO │ BAÑO  │ HABITACIÓN │
--   ├───puerta───┴─puerta┴──puerta────┤
--   │  COCINA    │       SALÓN        │
--   │  COMEDOR   │  (sofá ← → tele)   │
--   └──────────puerta / ascensor──────┘  entrada

local Builder = require(script.Parent.Builder)
local Furniture = require(script.Parent.Furniture)

local Interiors = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local PI = math.pi
local M = Enum.Material

local WOOD = rgb(150, 110, 76)
local DARKWOOD = rgb(96, 64, 40)
local WHITE = Furniture.WHITE
local DARK = Furniture.DARK
local STEEL = Furniture.STEEL
local P = Furniture.Palette

export type Room = {
	Model: Model,
	W: number,
	D: number,
	H: number,
	at: (number, number, number) -> CFrame,
	Rand: Furniture.Rng,
	Wood: Color3,
	Fabric: Color3,
	Accent: Color3,
	Kind: string,
	WallColor: Color3,
	Spots: { CFrame }, -- sitios libres para personas (vecinos, dependientes…)
	SignAt: ((number) -> CFrame)?, -- dónde van los carteles de la vivienda (lado -1 o 1; PropertyService)
}

export type Options = { Seed: string?, Floor: number? }

---------------------------------------------------------------------
-- Piezas sueltas
---------------------------------------------------------------------
local function solid(r: Room, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, extra: { [string]: any }?): BasePart
	local props = { Name = name, Size = size, CFrame = cf, Color = color, Material = material or M.SmoothPlastic, Parent = r.Model }
	for k, v in extra or {} do
		props[k] = v
	end
	return Builder.part(props)
end

local function bit(r: Room, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?): BasePart
	return Builder.decor({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or M.SmoothPlastic, Transparency = transparency or 0, Parent = r.Model })
end

local function spot(r: Room, name: string, cf: CFrame, tags: { string }?, attributes: { [string]: any }?): BasePart
	return Builder.part({ Name = name, Size = V(2, 2, 2), CFrame = cf, Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = tags, Attributes = attributes, Parent = r.Model })
end

local function sign(r: Room, text: string, size: Vector3, cf: CFrame, color: Color3?, textColor: Color3?)
	local p = bit(r, "Sign", size, cf, color or DARK)
	Builder.sign(p, text, Enum.NormalId.Front, textColor)
end

-- CFrame en (x, y, z) mirando hacia (dx, dz): así se colocan los muebles (su frente mira a -Z)
local function face(r: Room, x: number, y: number, z: number, dx: number, dz: number): CFrame
	return r.at(x, y, z) * ANG(0, math.atan2(-dx, -dz), 0)
end

-- Asiento público (teatros, aulas, salas de espera): asiento de verdad y respaldo
local function seat(r: Room, cf: CFrame, color: Color3?)
	local m = Furniture.group(r.Model, "PublicSeat")
	local s = Furniture.seatPart(m, cf * CF(0, 1.6, 0), V(2, 0.4, 2), color or DARK, M.Fabric, true)
	Furniture.usable(s, "Sit")
	Furniture.deco(m, "SeatBack", V(2, 2, 0.3), cf * CF(0, 2.7, 0.9), color or DARK, M.Fabric)
	Furniture.deco(m, "SeatLeg", V(1.6, 1.4, 0.2), cf * CF(0, 0.7, 0.6), DARK, M.Metal)
end

local function counter(r: Room, cf: CFrame, width: number, color: Color3?): BasePart
	local c = solid(r, "Counter", V(width, 3.6, 2.4), cf * CF(0, 1.8, 0), color or WOOD, M.Wood)
	bit(r, "CounterTop", V(width + 0.4, 0.2, 2.8), cf * CF(0, 3.7, 0), WHITE, M.Marble)
	return c
end

-- Panel de pintura o azulejos pegado a una pared (cf en la pared, mirando a la sala)
local function panel(r: Room, cf: CFrame, w: number, h: number, color: Color3, material: Enum.Material?)
	bit(r, "WallFinish", V(w, h, 0.06), cf * CF(0, h / 2, -0.03), color, material or M.SmoothPlastic)
end

-- Suelo de otro material en una zona (x0..x1, z0..z1)
local function floorPatch(r: Room, x0: number, x1: number, z0: number, z1: number, color: Color3, material: Enum.Material)
	bit(r, "FloorFinish", V(x1 - x0, 0.06, z1 - z0), r.at((x0 + x1) / 2, 0.03, (z0 + z1) / 2), color, material)
end

---------------------------------------------------------------------
-- Sala vacía: suelo, techo, paredes (puerta de salida en la pared -Z), luces y ventanas
---------------------------------------------------------------------
local function room(parent: Instance, name: string, cf: CFrame, W: number, D: number, H: number, style: { [string]: any }?, opts: Options?): Room
	local m = Instance.new("Model")
	m.Name = "Interior_" .. name
	local s = style or {}
	local rand = Furniture.rng((opts and opts.Seed) or name)
	local wall = s.Wall or rand.pick(P.Walls)
	local r: Room = {
		Model = m,
		W = W,
		D = D,
		H = H,
		at = function(x: number, y: number, z: number): CFrame
			return cf * CFrame.new(x, y, z)
		end,
		Rand = rand,
		Wood = rand.pick(P.Woods),
		Fabric = rand.pick(P.Fabrics),
		Accent = rand.pick(P.Accents),
		Kind = name,
		WallColor = wall,
		Spots = {},
	}
	solid(r, "Floor", V(W, 1, D), r.at(0, -0.5, 0), s.Floor or rgb(190, 170, 140), s.FloorMaterial or M.WoodPlanks)
	solid(r, "Ceiling", V(W, 1, D), r.at(0, H + 0.5, 0), s.Ceiling or WHITE)
	solid(r, "WallBack", V(W, H, 1), r.at(0, H / 2, D / 2 + 0.5), wall, s.WallMaterial)
	solid(r, "WallLeft", V(1, H, D), r.at(-W / 2 - 0.5, H / 2, 0), wall, s.WallMaterial)
	solid(r, "WallRight", V(1, H, D), r.at(W / 2 + 0.5, H / 2, 0), wall, s.WallMaterial)
	local gap = 6
	local side = (W - gap) / 2
	solid(r, "WallFront", V(side, H, 1), r.at(-(gap / 2 + side / 2), H / 2, -D / 2 - 0.5), wall, s.WallMaterial)
	solid(r, "WallFront", V(side, H, 1), r.at(gap / 2 + side / 2, H / 2, -D / 2 - 0.5), wall, s.WallMaterial)
	solid(r, "WallFront", V(gap, H - 9, 1), r.at(0, 9 + (H - 9) / 2, -D / 2 - 0.5), wall, s.WallMaterial)
	-- Puerta (cerrada: pulsar "Salir")
	local door = solid(r, "InteriorExit", V(gap, 9, 0.6), r.at(0, 4.5, -D / 2 - 0.3), s.Door or DARKWOOD, M.Wood)
	door:AddTag("InteriorExit")
	bit(r, "DoorHandle", V(0.3, 0.3, 0.4), r.at(2, 4.5, -D / 2 + 0.1), rgb(220, 190, 90), M.Metal)
	spot(r, "InteriorEntry", r.at(0, 3, -D / 2 + 4), { "InteriorEntry" })
	-- Zócalos
	if s.Baseboards ~= false then
		local base = s.Baseboard or WHITE
		Furniture.baseboard(r, face(r, 0, 0, D / 2, 0, -1), W, base)
		Furniture.baseboard(r, face(r, -W / 2, 0, 0, 1, 0), D, base)
		Furniture.baseboard(r, face(r, W / 2, 0, 0, -1, 0), D, base)
		Furniture.baseboard(r, face(r, -(gap / 2 + side / 2), 0, -D / 2, 0, 1), side, base)
		Furniture.baseboard(r, face(r, gap / 2 + side / 2, 0, -D / 2, 0, 1), side, base)
	end
	-- Luces del techo (toda la sala es una habitación: "Main") e interruptor junto a la entrada
	if s.Lamps ~= false then
		local nx, nz = math.max(1, math.floor(W / 20)), math.max(1, math.floor(D / 20))
		for i = 1, nx do
			for k = 1, nz do
				Furniture.ceilingLight(r, r.at(-W / 2 + (i - 0.5) * W / nx, H, -D / 2 + (k - 0.5) * D / nz), "Main", s.LightKind or "Panel")
			end
		end
		Furniture.lightSwitch(r, face(r, gap / 2 + 1.4, 4.2, -D / 2, 0, 1), "Main")
	end
	-- Ventanas (con luz de día) en las paredes laterales
	if s.Windows ~= false then
		local n = math.max(1, math.floor(D / 18))
		for k = 1, n do
			local z = -D / 2 + (k - 0.5) * D / n
			local h = math.min(H * 0.4, 6)
			Furniture.window(r, face(r, -W / 2, H * 0.55, z, 1, 0), 5, h, "Main", s.Curtains)
			Furniture.window(r, face(r, W / 2, H * 0.55, z, -1, 0), 5, h, "Main", s.Curtains)
		end
	end
	m.Parent = parent
	return r
end

local function elevator(r: Room, x: number, z: number, facing: number?)
	local cf = r.at(x, 0, z) * ANG(0, facing or 0, 0)
	bit(r, "ElevatorFrame", V(7, 10, 0.6), cf * CF(0, 5, 0), STEEL, M.Metal)
	bit(r, "ElevatorDoors", V(5, 8.5, 0.2), cf * CF(0, 4.25, -0.35), rgb(190, 196, 204), M.Metal)
	bit(r, "ElevatorSeam", V(0.08, 8.5, 0.22), cf * CF(0, 4.25, -0.36), rgb(120, 126, 134), M.Metal)
	bit(r, "ElevatorLight", V(1.2, 0.6, 0.1), cf * CF(0, 9.2, -0.4), rgb(120, 220, 255), M.Neon)
	bit(r, "ElevatorButton", V(0.4, 0.8, 0.1), cf * CF(3.1, 4.2, -0.4), rgb(230, 230, 220), M.Metal)
	Builder.part({ Name = "InteriorElevator", Size = V(6, 8, 2), CFrame = cf * CF(0, 4, -1.6), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = { "InteriorElevator" }, Parent = r.Model })
end

-- Quita la puerta a la calle (pisos y oficinas de arriba: se entra y se sale en ascensor)
local function noStreetDoor(r: Room)
	for _, child in r.Model:GetChildren() do
		if child.Name == "InteriorExit" or child.Name == "DoorHandle" then
			child:Destroy()
		end
	end
	-- Donde estaba la puerta, pared
	solid(r, "WallFront", V(6, 9, 1), r.at(0, 4.5, -r.D / 2 - 0.5), r.WallColor)
end

-- Tabique a lo largo de X (en z) con huecos de puerta en xs (centros); zócalos a los dos lados
local DOOR_W, DOOR_H = 4.4, 8.6
local function wallX(r: Room, z: number, x0: number, x1: number, doors: { number }, color: Color3)
	local H = r.H
	table.sort(doors)
	local x = x0
	local function piece(a: number, b: number)
		if b - a > 0.05 then
			solid(r, "Partition", V(b - a, H, 0.6), r.at((a + b) / 2, H / 2, z), color)
			Furniture.baseboard(r, face(r, (a + b) / 2, 0, z - 0.3, 0, -1), b - a)
			Furniture.baseboard(r, face(r, (a + b) / 2, 0, z + 0.3, 0, 1), b - a)
		end
	end
	for _, dx in doors do
		piece(x, dx - DOOR_W / 2)
		solid(r, "Lintel", V(DOOR_W, H - DOOR_H, 0.6), r.at(dx, DOOR_H + (H - DOOR_H) / 2, z), color)
		x = dx + DOOR_W / 2
	end
	piece(x, x1)
end

local function wallZ(r: Room, x: number, z0: number, z1: number, color: Color3)
	solid(r, "Partition", V(0.6, r.H, z1 - z0), r.at(x, r.H / 2, (z0 + z1) / 2), color)
	Furniture.baseboard(r, face(r, x - 0.3, 0, (z0 + z1) / 2, -1, 0), z1 - z0)
	Furniture.baseboard(r, face(r, x + 0.3, 0, (z0 + z1) / 2, 1, 0), z1 - z0)
end

---------------------------------------------------------------------
-- Viviendas
---------------------------------------------------------------------
local function homePlan(r: Room, rich: boolean?)
	local W, D, H = r.W, r.D, r.H
	local R = r.Rand
	local bd = math.clamp(math.floor(D * 0.42 + 0.5), 13, 18) -- fondo de las habitaciones de atrás
	local zp = D / 2 - bd -- tabique de atrás
	local wa = math.floor(W * 0.4 + 0.5)
	local wb = math.clamp(math.floor(W * 0.22 + 0.5), 9, 12)
	local xa, xb = -W / 2 + wa, -W / 2 + wa + wb -- dormitorio | baño | habitación
	local xk = -W / 2 + math.floor(W * 0.4 + 0.5) -- cocina | salón
	local wall = r.WallColor
	local doorA, doorB, doorC = xa - 3, (xa + xb) / 2, xb + 3
	local zf = zp - 0.3 -- pared de atrás del salón y la cocina (cara de delante del tabique)
	local zb = zp + 0.3 -- pared de delante de las habitaciones

	-- Tabiques y puertas (abren hacia dentro de cada habitación)
	wallX(r, zp, -W / 2, W / 2, { doorA, doorB, doorC }, wall)
	wallZ(r, xa, zb, D / 2, wall)
	wallZ(r, xb, zb, D / 2, wall)
	local doorColor = R.pick({ WHITE, r.Wood, rgb(220, 214, 200) })
	Furniture.door(r, face(r, doorA, 0, zp, 0, 1), DOOR_W, DOOR_H, doorColor, true, nil, false)
	Furniture.door(r, face(r, doorB, 0, zp, 0, 1), DOOR_W, DOOR_H, doorColor, false, nil, true)
	Furniture.door(r, face(r, doorC, 0, zp, 0, 1), DOOR_W, DOOR_H, doorColor, true, nil, true)

	---------------------------------------------------------------- Salón
	local zcl = (-D / 2 + zf) / 2
	local salon = "Salon"
	Furniture.rug(r, r.at(W / 2 - 6.8, 0, zcl), 8, 10)
	Furniture.tvUnit(r, face(r, W / 2 - 1.05, 0, zcl, -1, 0), 7)
	local sofaSeats = if zf + D / 2 < 20 then R.pick({ 2, 3, 3 }) else R.pick({ 3, 3, 4, 2 })
	Furniture.sofa(r, face(r, W / 2 - 12, 0, zcl, 1, 0), r.Fabric, sofaSeats)
	Furniture.coffeeTable(r, face(r, W / 2 - 6.8, 0, zcl, 1, 0), 4.5, 2.6)
	local armchairs = R.int(1, 2)
	local chairColor = R.pick(P.Fabrics)
	Furniture.armchair(r, face(r, W / 2 - 7, 0, zcl - 6.2, 0, 1), chairColor)
	if (armchairs == 2 or rich) and zcl + 7.9 < zf - 1.9 then
		Furniture.armchair(r, face(r, W / 2 - 7, 0, zcl + 6.2, 0, -1), chairColor)
	end
	local sideZ = zcl + (sofaSeats * 2.4 + 1.6) / 2 + 1.3
	if sideZ + 1 < zf then
		Furniture.sideTable(r, face(r, W / 2 - 12.4, 0, sideZ, 1, 0), salon)
	end
	Furniture.floorLamp(r, r.at(W / 2 - 12.4, 0, zcl - (sofaSeats * 2.4 + 1.6) / 2 - 1.2), salon)
	if rich then
		Furniture.fireplace(r, face(r, W / 2 - 7, 0, zf - 1.1, 0, -1), salon)
		Furniture.bookshelf(r, face(r, W / 2 - 15, 0, zf - 1, 0, -1), 6, 8)
		Furniture.piano(r, face(r, W / 2 - 20, 0, -D / 2 + 1.9, 0, 1))
		Furniture.ceilingLight(r, r.at(W / 2 - 9, H, zcl), salon, "Chandelier")
	else
		Furniture.bookshelf(r, face(r, W / 2 - 5, 0, zf - 1, 0, -1), 6, R.pick({ 6, 7.5 }))
		Furniture.ceilingLight(r, r.at(W / 2 - 7, H, zcl), salon, R.pick({ "Dome", "Pendant" }))
	end
	Furniture.ceilingLight(r, r.at(xk + 5, H, zcl), salon, "Dome")
	Furniture.plant(r, r.at(xk + 1.6, 0, zf - 1.8), R.range(0.9, 1.3))
	-- Ventanas a los lados de la tele (si caben sin taparla) y otra en la fachada
	local curtains = r.Fabric:Lerp(WHITE, 0.4)
	local wz = math.min(7, (zf + D / 2) / 2 - 3.4) -- (las cortinas no se meten en la pared)
	if wz >= 6.6 then
		Furniture.window(r, face(r, W / 2, 6.4, zcl - wz, -1, 0), 4.5, 4.4, salon, curtains)
		Furniture.window(r, face(r, W / 2, 6.4, zcl + wz, -1, 0), 4.5, 4.4, salon, curtains)
	end
	Furniture.window(r, face(r, W / 2 - 5.5, 6, -D / 2, 0, 1), 4.5, 5, salon, curtains)
	if not rich then
		Furniture.picture(r, face(r, W / 2 - 12, 6.5, -D / 2, 0, 1), R.pick({ 4, 5 }), 3.2)
		-- Cuadro en el tabique, entre la puerta de la habitación y la estantería
		local gap = (W / 2 - 8.2) - (doorC + 2.6)
		if gap > 2.4 then
			Furniture.picture(r, face(r, (doorC + 2.6 + W / 2 - 8.2) / 2, 6.5, zf, 0, -1), math.min(3, gap - 0.4), 2.6)
		end
	end
	Furniture.lightSwitch(r, face(r, 4.6, 4.2, -D / 2, 0, 1), salon)
	-- Recibidor: felpudo y perchero junto a la entrada
	bit(r, "Doormat", V(5, 0.1, 3), r.at(0, 0.05, -D / 2 + 2), rgb(120, 90, 60), M.Fabric)
	local rack = Furniture.group(r.Model, "CoatRack")
	Furniture.deco(rack, "CoatPole", V(0.25, 6.5, 0.25), r.at(5.8, 3.25, -D / 2 + 1.2), DARK, M.Metal)
	for k = -1, 1 do
		Furniture.deco(rack, "Coat", V(0.9, 2.4, 0.5), r.at(5.8 + k * 0.45, 4.8, -D / 2 + 1.2 + math.abs(k) * 0.2), R.pick(P.Fabrics), M.Fabric)
	end

	---------------------------------------------------------------- Cocina y comedor
	local cocina = "Cocina"
	local front = zf + D / 2
	local L = math.clamp(math.floor(front - 5.6), 8, 16)
	local zc = zf - 3.6 - L / 2
	Furniture.kitchenRun(r, face(r, -W / 2 + 1.3, 0, zc, 1, 0), L)
	Furniture.fridge(r, face(r, -W / 2 + 1.45, 0, zf - 1.8, 1, 0))
	-- Azulejos detrás de la encimera y ventana sobre el fregadero
	panel(r, face(r, -W / 2, 3.6, zc, 1, 0), L, 2.6, R.pick(P.Tiles), M.CeramicTiles)
	Furniture.window(r, face(r, -W / 2, 6.8, zc + L / 2 - 2, 1, 0), 3, 3, cocina, nil)
	if R.chance(0.5) then
		floorPatch(r, -W / 2, xk, -D / 2, zf, R.pick(P.Tiles), M.CeramicTiles)
	end
	local dineX = (-W / 2 + 3.2 + xk) / 2 + 0.3
	local seats = if rich then 8 else R.pick({ 4, 4, 6 })
	if rich then
		Furniture.island(r, face(r, -W / 2 + 7.6, 0, zc, 1, 0), 8)
		dineX = (-W / 2 + 10 + xk) / 2
	end
	local dineZ = (-D / 2 + zf) / 2 + 1.5
	Furniture.diningSet(r, face(r, dineX, 0, dineZ, 0, -1), seats)
	Furniture.ceilingLight(r, r.at(dineX, H, dineZ), cocina, "Pendant")
	Furniture.ceilingLight(r, r.at(-W / 2 + 4, H, zc), cocina, "Dome")
	Furniture.window(r, face(r, -W / 2 + 7, 6, -D / 2, 0, 1), 4.5, 4.5, cocina, R.pick(P.Fabrics):Lerp(WHITE, 0.5))
	Furniture.picture(r, face(r, -W / 2 + 12.5, 6.5, -D / 2, 0, 1), 3.6, 3)
	Furniture.clock(r, face(r, dineX - 4, 8.5, zf, 0, -1))
	Furniture.plant(r, r.at(xk - 1.6, 0, -D / 2 + 1.6), R.range(0.9, 1.3))
	Furniture.lightSwitch(r, face(r, -W / 2 + 5.2, 4.2, zf, 0, -1), cocina)

	---------------------------------------------------------------- Dormitorio principal
	local dorm = "Dormitorio"
	local bx = -W / 2 + wa * 0.45
	local bw = R.pick({ 5.6, 6.4 })
	if R.chance(0.5) then
		panel(r, face(r, (-W / 2 + xa - 0.3) / 2, 0, D / 2, 0, -1), wa - 0.3, H, R.pick(P.Walls):Lerp(R.pick(P.Accents), 0.25))
	end
	if R.chance(0.5) then
		floorPatch(r, -W / 2, xa - 0.3, zb, D / 2, R.pick(P.Carpets), M.Carpet)
	end
	Furniture.bed(r, face(r, bx, 0, D / 2 - 4.2, 0, -1), bw)
	Furniture.nightstand(r, face(r, bx - bw / 2 - 1.5, 0, D / 2 - 1.2, 0, -1), dorm)
	Furniture.nightstand(r, face(r, bx + bw / 2 + 1.5, 0, D / 2 - 1.2, 0, -1), dorm)
	Furniture.rug(r, r.at(bx, 0, D / 2 - 6.8), bw + 3, 4.5)
	Furniture.picture(r, face(r, bx, 7.4, D / 2, 0, -1), 5, 2.6)
	Furniture.wardrobe(r, face(r, -W / 2 + 1.25, 0, zb + 3.8, 1, 0), 5)
	Furniture.dresser(r, face(r, xa - 1.3, 0, D / 2 - 5.5, -1, 0))
	if bd >= 15 then
		Furniture.desk(r, face(r, -W / 2 + 7, 0, zb + 1.3, 0, 1), { Computer = R.chance(0.5), Lamp = true, Room = dorm })
	end
	Furniture.window(r, face(r, -W / 2, 5.6, D / 2 - 3.4, 1, 0), 4.5, 4.5, dorm, r.Fabric:Lerp(WHITE, 0.3))
	Furniture.plant(r, r.at(xa - 1.3, 0, D / 2 - 1.3), 0.9)
	bit(r, "Slippers", V(1.2, 0.25, 1.1), r.at(bx + bw / 2 + 0.2, 0.13, D / 2 - 9), R.pick(P.Accents), M.Fabric)
	Furniture.ceilingLight(r, r.at(bx, H, (zb + D / 2) / 2), dorm, R.pick({ "Dome", "Pendant" }))
	Furniture.lightSwitch(r, face(r, doorA - 3.4, 4.2, zb, 0, 1), dorm)

	---------------------------------------------------------------- Baño
	local bano = "Bano"
	local tile = R.pick(P.Tiles)
	floorPatch(r, xa + 0.3, xb - 0.3, zb, D / 2, tile:Lerp(DARK, 0.1), M.CeramicTiles)
	panel(r, face(r, (xa + xb) / 2, 0, D / 2, 0, -1), wb - 0.6, 5, tile, M.CeramicTiles)
	panel(r, face(r, xa + 0.3, 0, (zb + D / 2) / 2, 1, 0), bd - 0.3, 5, tile, M.CeramicTiles)
	panel(r, face(r, xb - 0.3, 0, (zb + D / 2) / 2, -1, 0), bd - 0.3, 5, tile, M.CeramicTiles)
	Furniture.shower(r, face(r, xb - 0.3 - 2.3, 0, D / 2 - 2.3, 0, -1), 4.4)
	Furniture.toilet(r, face(r, xb - 0.3 - 5.8, 0, D / 2 - 1.3, 0, -1))
	if rich then
		Furniture.bathtub(r, face(r, xa + 2.1, 0, D / 2 - 4.2, 0, -1))
		Furniture.vanity(r, face(r, xa + 1.2, 0, zb + 7.3, 1, 0), bano)
	else
		Furniture.vanity(r, face(r, xa + 1.2, 0, D / 2 - 3.6, 1, 0), bano)
	end
	Furniture.towelRail(r, face(r, xb - 0.3, 0, zb + 6.5, -1, 0))
	bit(r, "BathMat", V(3, 0.08, 2), r.at(xb - 2.6, 0.08, D / 2 - 5.6), R.pick(P.Accents), M.Fabric)
	Furniture.window(r, face(r, xb - 7, 7.6, D / 2, 0, -1), 2, 1.6, bano, nil)
	Furniture.ceilingLight(r, r.at((xa + xb) / 2, H, (zb + D / 2) / 2), bano, "Dome")
	Furniture.lightSwitch(r, face(r, doorB + 3.2, 4.2, zb, 0, 1), bano)

	---------------------------------------------------------------- Otra habitación
	local cx0, cx1, cz0, cz1 = xb + 0.3, W / 2, zb, D / 2
	local mid = (cx0 + cx1) / 2
	local hab = "Habitacion"
	local kind = R.pick({ "Kid", "Study", "Guest" })
	r.Model:SetAttribute("SecondRoom", kind)
	if kind == "Kid" then
		panel(r, face(r, mid, 0, D / 2, 0, -1), cx1 - cx0, H, R.pick({ rgb(190, 220, 240), rgb(240, 210, 220), rgb(220, 240, 200), rgb(250, 236, 180) }))
		Furniture.bed(r, face(r, cx1 - 3, 0, cz1 - 4.2, 0, -1), 4.2)
		Furniture.nightstand(r, face(r, cx1 - 6.8, 0, cz1 - 1.1, 0, -1), hab)
		Furniture.desk(r, face(r, cx0 + 1.3, 0, cz1 - 3.5, 1, 0), { Computer = R.chance(0.4), Lamp = true, Room = hab, Width = 4.4 })
		local box = Furniture.group(r.Model, "ToyBox")
		Furniture.solid(box, "ToyBox", V(3, 2, 2), face(r, cx1 - 1.2, 1, cz0 + 2.2, -1, 0), R.pick(P.Accents), M.Wood)
		Furniture.rug(r, r.at(mid - 1, 0, (cz0 + cz1) / 2 + 1), 6, 5, R.pick({ rgb(90, 160, 220), rgb(240, 140, 60), rgb(120, 190, 120) }))
		Furniture.ball(r.Model, "ToyBall", V(1.2, 1.2, 1.2), r.at(mid, 0.6, (cz0 + cz1) / 2 + 2), R.pick(P.Accents))
		for k = 0, 3 do
			bit(r, "ToyBlock", V(0.8, 0.8, 0.8), r.at(mid - 2 + k * 0.6, 0.4 + (k % 2) * 0.8, (cz0 + cz1) / 2) * ANG(0, k * 0.4, 0), R.pick(P.Products))
		end
		Furniture.picture(r, face(r, cx0, 6.5, cz1 - 3.5, 1, 0), 3, 3.6)
	elseif kind == "Study" then
		Furniture.desk(r, face(r, mid + 2, 0, cz1 - 1.35, 0, -1), { Computer = true, Tower = true, Lamp = true, Room = hab, Width = 5.6 })
		Furniture.bookshelf(r, face(r, cx1 - 1, 0, (cz0 + cz1) / 2 - 0.5, -1, 0), 6, 8)
		Furniture.armchair(r, face(r, cx0 + 2, 0, cz1 - 2.2, 1, 0), R.pick(P.Fabrics))
		Furniture.floorLamp(r, r.at(cx0 + 1.1, 0, cz1 - 4.8), hab)
		Furniture.filingCabinet(r, face(r, mid + 6.6, 0, cz1 - 1.1, 0, -1))
		Furniture.rug(r, r.at(mid + 1, 0, (cz0 + cz1) / 2 + 1), 7, 5)
		Furniture.window(r, face(r, mid + 2, 7, cz1, 0, -1), 4, 2.6, hab, nil)
	else
		Furniture.bed(r, face(r, mid + 1, 0, cz1 - 4.2, 0, -1), 5.6)
		Furniture.nightstand(r, face(r, mid + 1 + 4.2, 0, cz1 - 1.1, 0, -1), hab)
		Furniture.wardrobe(r, face(r, cx1 - 1.25, 0, cz0 + 3.2, -1, 0), 5)
		Furniture.picture(r, face(r, mid + 1, 7.4, cz1, 0, -1), 4, 2.4)
	end
	if kind ~= "Study" then
		Furniture.window(r, face(r, cx1, 5.6, cz1 - 3.2, -1, 0), 4, 4.2, hab, R.pick(P.Fabrics):Lerp(WHITE, 0.5))
	end
	Furniture.ceilingLight(r, r.at(mid, H, (cz0 + cz1) / 2), hab, "Dome")
	Furniture.lightSwitch(r, face(r, doorC + 3.4, 4.2, zb, 0, 1), hab)

	-- Carteles de la vivienda (dueño, en venta, vender): a los lados de la entrada, sin tapar nada
	r.SignAt = function(side: number): CFrame
		return r.at(side * 5.2, 4.5, -D / 2 + 4.5)
	end
	-- Sitios libres para los vecinos (salón, comedor, junto a la ventana)
	r.Spots = {
		face(r, W / 2 - 5.5, 0, -D / 2 + 3.2, 0, -1),
		face(r, dineX, 0, dineZ - 5, 0, 1),
		face(r, W / 2 - 3.5, 0, zcl + 4, -1, 0),
	}
end

function Interiors.Casa(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Casa", cf, 48, 36, 12, { Floor = rgb(176, 140, 100), Lamps = false, Windows = false }, opts)
	local floor = r.Rand.pick(P.Floors)
	r.Model:FindFirstChild("Floor").Color = floor[1]
	r.Model:FindFirstChild("Floor").Material = floor[2]
	homePlan(r)
	return r
end

function Interiors.Villa(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Villa", cf, 64, 44, 14, { Floor = rgb(230, 226, 214), FloorMaterial = M.Marble, Lamps = false, Windows = false }, opts)
	homePlan(r, true)
	return r
end

function Interiors.Piso(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Piso", cf, 44, 32, 11, { Floor = rgb(186, 150, 110), Lamps = false, Windows = false }, opts)
	local floor = r.Rand.pick(P.Floors)
	r.Model:FindFirstChild("Floor").Color = floor[1]
	r.Model:FindFirstChild("Floor").Material = floor[2]
	-- En los pisos se entra y se sale por el ascensor (no hay puerta a la calle)
	noStreetDoor(r)
	homePlan(r)
	elevator(r, 0, -r.D / 2 + 0.4)
	return r
end

function Interiors.Portal(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Portal", cf, 30, 24, 12, { Floor = rgb(210, 206, 196), FloorMaterial = M.Marble, Windows = false, LightKind = "Dome" }, opts)
	local W, D = r.W, r.D
	local R = r.Rand
	-- Buzones (pared izquierda)
	local boxes = Furniture.group(r.Model, "Mailboxes")
	Furniture.solid(boxes, "MailboxWall", V(0.6, 4.4, 7.4), r.at(-W / 2 + 0.3, 4.4, -2.2), rgb(150, 130, 80), M.Metal)
	for k = 0, 11 do
		local row, col = k % 3, math.floor(k / 3)
		Furniture.deco(boxes, "Mailbox", V(0.12, 1.2, 1.6), r.at(-W / 2 + 0.66, 3 + row * 1.4, -4.8 + col * 1.75), rgb(190, 170, 100), M.Metal)
		Furniture.deco(boxes, "Slot", V(0.14, 0.12, 0.9), r.at(-W / 2 + 0.7, 3.3 + row * 1.4, -4.8 + col * 1.75), DARK)
	end
	-- Mostrador del portero (el portero se pone detrás: PropertyService)
	counter(r, r.at(-6, 0, 4), 6, r.Wood)
	Furniture.deco(r.Model, "Logbook", V(1.2, 0.15, 0.9), r.at(-6.5, 3.9, 3.8), rgb(120, 40, 40))
	Furniture.deco(r.Model, "Phone", V(0.8, 0.4, 0.6), r.at(-4.5, 3.95, 4.2), DARK)
	-- Sofá, mesita, plantas, espejo y alfombra hasta el ascensor
	Furniture.sofa(r, face(r, W / 2 - 1.8, 0, 1, -1, 0), R.pick(P.Fabrics), 2)
	Furniture.sideTable(r, face(r, W / 2 - 1.6, 0, -3.4, -1, 0), "Main")
	Furniture.plant(r, r.at(W / 2 - 2, 0, -D / 2 + 2), 1.3)
	Furniture.plant(r, r.at(-W / 2 + 2, 0, D / 2 - 2), 1.3)
	Furniture.plant(r, r.at(W / 2 - 2, 0, D / 2 - 2), 1.1)
	local mirror = bit(r, "Mirror", V(0.15, 5, 4), r.at(W / 2 - 0.1, 6.5, 1), rgb(200, 215, 225), M.Glass)
	mirror.Reflectance = 0.5
	bit(r, "Runner", V(5, 0.08, D - 6), r.at(0, 0.05, -1), rgb(140, 40, 40), M.Fabric)
	-- Tablón de anuncios de la comunidad
	bit(r, "NoticeBoard", V(0.2, 3, 4), r.at(-W / 2 + 0.1, 6, 5), rgb(180, 140, 90), M.Wood)
	for k = 0, 3 do
		bit(r, "Notice", V(0.22, 0.9, 1.1), r.at(-W / 2 + 0.15, 6.4 - (k % 2) * 1.2, 4 + math.floor(k / 2) * 1.6), R.pick({ WHITE, rgb(250, 240, 160), rgb(200, 230, 250) }))
	end
	-- Apliques de pared
	for _, x in { -W / 2 + 0.2, W / 2 - 0.2 } do
		local sconce = bit(r, "Sconce", V(0.4, 1, 0.8), r.at(x, 8, -D / 2 + 5), rgb(255, 238, 200), M.Neon)
		Furniture.roomLight(sconce, "Main", 12, 0.6)
	end
	for _, x in { -9, 9 } do
		Furniture.window(r, face(r, x, 6, -D / 2, 0, 1), 4, 5, "Main", nil)
	end
	elevator(r, 0, D / 2 - 0.4, PI)
	sign(r, "PORTAL · ASCENSOR", V(8, 1.2, 0.2), r.at(0, 10.5, D / 2 - 0.2) * ANG(0, PI, 0))
	return r
end

---------------------------------------------------------------------
-- Oficinas
---------------------------------------------------------------------
local COMPANIES = { "GRUPO VALMAR", "NOVA SEGUROS", "INMOBILIARIA SOL", "TECNOVAL", "BANCO DEL PUERTO", "CONSULTORES ATLÁNTICO", "VALMAR MEDIA", "LOGÍSTICA NORTE" }

-- Bloque de 4 mesas (dos y dos, enfrentadas, con mampara en medio)
local function deskCluster(r: Room, cx: number, cz: number)
	local R = r.Rand
	local color = R.pick({ WHITE, r.Wood, rgb(200, 196, 190) })
	for _, sx in { -2.6, 2.6 } do
		Furniture.desk(r, face(r, cx + sx, 0, cz - 1.4, 0, -1), { Color = color, ChairColor = r.Fabric })
		Furniture.desk(r, face(r, cx + sx, 0, cz + 1.4, 0, 1), { Color = color, ChairColor = r.Fabric })
	end
	Furniture.deco(r.Model, "Divider", V(10.4, 1.6, 0.2), r.at(cx, 3.8, cz), R.pick({ rgb(120, 150, 170), rgb(150, 150, 156), rgb(120, 160, 130) }), M.Fabric)
end

function Interiors.OficinaLobby(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "OficinaLobby", cf, 40, 30, 14, { Floor = rgb(200, 204, 210), FloorMaterial = M.Marble, Wall = rgb(236, 236, 232) }, opts)
	local W, D = r.W, r.D
	local R = r.Rand
	local company = R.pick(COMPANIES)
	r.Model:SetAttribute("Company", company)
	-- Recepción (la recepcionista va en ClerkSpot)
	local desk = Furniture.checkout(r, r.at(0, 0, 0), 12, rgb(60, 70, 90))
	desk:SetAttribute("Reception", true)
	Furniture.deco(r.Model, "ReceptionScreen", V(1.8, 1.1, 0.1), r.at(-3, 4.5, 0.6) * ANG(0, PI, 0), rgb(40, 120, 200), M.Neon)
	sign(r, "RECEPCIÓN", V(8, 1.4, 0.2), r.at(0, 8, -1.3))
	bit(r, "LogoWall", V(16, 5, 0.4), r.at(0, 8.5, 5), rgb(40, 50, 70))
	sign(r, company, V(14, 2.4, 0.2), r.at(0, 8.5, 4.7), rgb(40, 50, 70), rgb(240, 210, 130))
	-- Zona de espera
	Furniture.rug(r, r.at(-W / 2 + 6.5, 0, -4), 9, 11, rgb(70, 80, 100))
	Furniture.sofa(r, face(r, -W / 2 + 1.8, 0, -4, 1, 0), r.Fabric, 3)
	Furniture.armchair(r, face(r, -W / 2 + 8, 0, -10, 0, 1), r.Fabric)
	Furniture.coffeeTable(r, face(r, -W / 2 + 6.5, 0, -4, 1, 0), 3, 5)
	Furniture.wallTV(r, face(r, -W / 2, 7, 6.5, 1, 0), 6)
	-- Agua, plantas y torniquetes camino de los ascensores
	Furniture.waterCooler(r, face(r, W / 2 - 1.2, 0, -9.5, -1, 0))
	for _, p in { { -W / 2 + 2, -D / 2 + 1.8 }, { W / 2 - 2, -D / 2 + 1.8 }, { W / 2 - 2, D / 2 - 1.8 }, { -W / 2 + 2, D / 2 - 1.8 } } do
		Furniture.plant(r, r.at(p[1], 0, p[2]), 1.4)
	end
	for _, x in { -8, 8 } do
		for k = -1, 1, 2 do
			bit(r, "Turnstile", V(0.6, 3.4, 2.2), r.at(x + k * 2.2, 1.7, 8), STEEL, M.Metal)
			bit(r, "TurnstileLight", V(0.2, 0.3, 0.6), r.at(x + k * 2.2, 3.5, 7.2), rgb(80, 220, 120), M.Neon)
		end
	end
	Furniture.bench(r, face(r, W / 2 - 1.6, 0, -4.5, -1, 0), 6, DARK)
	Furniture.picture(r, face(r, -W / 2, 7, -9, 1, 0), 3, 3)
	-- Directorio de plantas, paragüero, revistero y alfombra de entrada
	local directory = bit(r, "Directory", V(0.2, 5, 4), r.at(W / 2 - 0.1, 5, 6), rgb(30, 36, 50))
	Builder.sign(directory, "DIRECTORIO\n" .. company .. "\nPlantas 1 a 20\nAscensores al fondo", Enum.NormalId.Left, rgb(240, 220, 160))
	Furniture.cyl(r.Model, "UmbrellaStand", 2, 1, r.at(4.5, 1, -D / 2 + 1.2), DARK, M.Metal)
	for k = 0, 2 do
		Furniture.deco(r.Model, "Umbrella", V(0.25, 3, 0.25), r.at(4.3 + k * 0.2, 2.2, -D / 2 + 1.2) * ANG(0, 0, (k - 1) * 0.15), R.pick(P.Accents))
	end
	bit(r, "EntranceMat", V(8, 0.08, 4), r.at(0, 0.05, -D / 2 + 2.2), rgb(40, 44, 50), M.Fabric)
	local rack = Furniture.group(r.Model, "MagazineRack")
	Furniture.solid(rack, "Rack", V(2.4, 3.6, 1), r.at(-W / 2 + 1, 1.8, 3), r.Wood, M.Wood)
	for k = 0, 2 do
		Furniture.deco(rack, "Magazine", V(1.8, 1.1, 0.1), r.at(-W / 2 + 1.55, 1 + k * 1.1, 3) * ANG(0, PI / 2, 0) * ANG(math.rad(-12), 0, 0), R.pick(P.Books))
	end
	elevator(r, -8, D / 2 - 0.4, PI)
	elevator(r, 8, D / 2 - 0.4, PI)
	return r
end

function Interiors.Oficina(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Oficina", cf, 52, 40, 12, { Floor = rgb(120, 126, 140), FloorMaterial = M.Carpet, Wall = rgb(236, 236, 232) }, opts)
	local W, D = r.W, r.D
	local R = r.Rand
	noStreetDoor(r)
	elevator(r, 0, -D / 2 + 0.4)
	-- Mesas de trabajo
	deskCluster(r, -16, -7)
	deskCluster(r, 0, -4)
	deskCluster(r, -4, 11)
	if R.chance(0.6) then
		deskCluster(r, 16, -7)
	else
		Furniture.sofa(r, face(r, 16, 0, -12, 0, 1), r.Fabric, 3)
		Furniture.coffeeTable(r, face(r, 16, 0, -7.5, 0, 1), 4, 2.4)
		Furniture.plant(r, r.at(23, 0, -8), 1.2)
	end
	-- Sala de reuniones (cristal, puerta, mesa, tele y pizarra)
	local mx0, mz0 = W / 2 - 18, D / 2 - 13.5
	bit(r, "GlassWall", V(12, 11, 0.3), r.at(mx0 + 12, 5.5, mz0), rgb(200, 225, 240), M.Glass, 0.6)
	bit(r, "GlassWall", V(1.6, 11, 0.3), r.at(mx0 + 0.8, 5.5, mz0), rgb(200, 225, 240), M.Glass, 0.6)
	bit(r, "GlassWall", V(18, 2.4, 0.3), r.at(mx0 + 9, 9.8, mz0), rgb(200, 225, 240), M.Glass, 0.6)
	Furniture.door(r, face(r, mx0 + 3.8, 0, mz0, 0, 1), DOOR_W, DOOR_H, rgb(200, 225, 240), false, nil, true)
	Furniture.diningSet(r, face(r, mx0 + 10, 0, mz0 + 5, 0, -1), 6)
	Furniture.wallTV(r, face(r, W / 2, 6, D / 2 - 3.5, -1, 0), 6)
	Furniture.whiteboard(r, face(r, mx0 + 10, 0, D / 2, 0, -1), 8)
	Furniture.ceilingLight(r, r.at(mx0 + 10, r.H, mz0 + 5), "Reuniones", "Panel")
	Furniture.lightSwitch(r, face(r, mx0 + 6.6, 4.2, mz0 + 0.15, 0, 1), "Reuniones")
	-- Office: encimera con fregadero y café, nevera, mesa
	local kx = -W / 2 + 9
	Furniture.kitchenRun(r, face(r, kx, 0, D / 2 - 1.3, 0, -1), 10)
	Furniture.fridge(r, face(r, kx - 6.8, 0, D / 2 - 1.5, 0, -1))
	Furniture.table(r, face(r, kx, 0, D / 2 - 7, 0, -1), 4, 3)
	Furniture.chair(r, face(r, kx - 1.2, 0, D / 2 - 9.2, 0, 1))
	Furniture.chair(r, face(r, kx + 1.2, 0, D / 2 - 9.2, 0, 1))
	-- Impresora, agua, archivadores, plantas, pizarra
	Furniture.printer(r, face(r, 7, 0, D / 2 - 1.2, 0, -1))
	Furniture.waterCooler(r, face(r, 5, 0, -D / 2 + 1.2, 0, 1))
	for k = 0, 3 do
		Furniture.filingCabinet(r, face(r, -8 - k * 2.3, 0, -D / 2 + 1.1, 0, 1))
	end
	Furniture.whiteboard(r, face(r, -W / 2, 0, 0, 1, 0), 7)
	for _, p in { { W / 2 - 2, -D / 2 + 2 }, { -W / 2 + 2, -D / 2 + 2 }, { 2, D / 2 - 2 } } do
		Furniture.plant(r, r.at(p[1], 0, p[2]), R.range(1.1, 1.5))
	end
	Furniture.clock(r, face(r, 0, 9, D / 2, 0, -1))
	return r
end

---------------------------------------------------------------------
-- Comercios
---------------------------------------------------------------------
local SHOPS = {
	{ Id = "Ultramarinos", Title = "ULTRAMARINOS", Shelf = "Food", Coolers = 2, Color = rgb(170, 60, 60) },
	{ Id = "Moda", Title = "MODA VALMAR", Shelf = "Clothes", Coolers = 0, Color = rgb(40, 40, 46) },
	{ Id = "Farmacia", Title = "✚ FARMACIA", Shelf = "Pharmacy", Coolers = 0, Color = rgb(40, 150, 80) },
	{ Id = "Ferreteria", Title = "FERRETERÍA", Shelf = "Tools", Coolers = 0, Color = rgb(60, 80, 130) },
	{ Id = "Libreria", Title = "LIBRERÍA", Shelf = "Books", Coolers = 0, Color = rgb(110, 70, 40) },
	{ Id = "Electronica", Title = "ELECTRÓNICA", Shelf = "Tech", Coolers = 0, Color = rgb(30, 60, 110) },
	{ Id = "Panaderia", Title = "PANADERÍA", Shelf = "Food", Coolers = 1, Color = rgb(190, 130, 60) },
}
Interiors.Shops = SHOPS

function Interiors.Local(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Local", cf, 40, 30, 12, { Floor = rgb(220, 220, 214), FloorMaterial = M.Marble, Windows = false }, opts)
	local W, D = r.W, r.D
	local R = r.Rand
	local shop = R.pick(SHOPS)
	r.Model:SetAttribute("Shop", shop.Id)
	-- Pasillos con estanterías
	for k = 0, 2 do
		Furniture.shopShelf(r, face(r, -12 + k * 12, 0, 4.4, 0, -1), 8, shop.Shelf)
		if shop.Shelf ~= "Clothes" and shop.Id ~= "Panaderia" then
			Furniture.shopShelf(r, face(r, -12 + k * 12, 0, 7, 0, 1), 8, shop.Shelf)
		end
	end
	Furniture.checkout(r, r.at(W / 2 - 6, 0, -D / 2 + 7), 8, shop.Color)
	sign(r, shop.Title, V(16, 2.4, 0.3), r.at(0, 9, D / 2 - 0.2) * ANG(0, PI, 0), shop.Color, WHITE)
	bit(r, "Mat", V(6, 0.08, 3), r.at(0, 0.05, -D / 2 + 2), rgb(60, 60, 66), M.Fabric)
	for k = 1, shop.Coolers do
		Furniture.drinksCooler(r, face(r, -W / 2 + 1.3, 0, -6 + (k - 1) * 4.2, 1, 0))
	end
	if shop.Id == "Moda" then
		-- Maniquíes, probador y espejo
		for k = 0, 1 do
			local mq = Furniture.group(r.Model, "Mannequin")
			local x = -W / 2 + 4 + k * 4
			Furniture.cyl(mq, "MannequinBase", 0.2, 1.4, r.at(x, 0.1, -D / 2 + 4), DARK)
			Furniture.deco(mq, "MannequinPole", V(0.15, 2.4, 0.15), r.at(x, 1.3, -D / 2 + 4), DARK)
			Furniture.deco(mq, "MannequinBody", V(1.8, 2.6, 0.9), r.at(x, 3.8, -D / 2 + 4), R.pick(P.Fabrics), M.Fabric)
			Furniture.ball(mq, "MannequinHead", V(0.9, 1.1, 0.9), r.at(x, 5.6, -D / 2 + 4), WHITE)
		end
		bit(r, "FittingRoom", V(6, 8, 0.3), r.at(-W / 2 + 4, 4, D / 2 - 5), rgb(220, 214, 200))
		bit(r, "FittingCurtain", V(4, 7, 0.2), r.at(-W / 2 + 4, 4, D / 2 - 5.3), rgb(150, 40, 60), M.Fabric)
		bit(r, "Mirror", V(0.15, 6, 3), r.at(W / 2 - 0.1, 4, 2), rgb(200, 215, 225), M.Glass).Reflectance = 0.5
		Furniture.bench(r, face(r, W / 2 - 1.4, 0, 8, -1, 0), 5, r.Wood)
	elseif shop.Id == "Libreria" then
		Furniture.armchair(r, face(r, -W / 2 + 3, 0, -D / 2 + 5, 1, 0), r.Fabric)
		Furniture.floorLamp(r, r.at(-W / 2 + 1.4, 0, -D / 2 + 1.6), "Main")
		Furniture.table(r, face(r, -W / 2 + 8, 0, -D / 2 + 6, 0, -1), 4, 3)
	elseif shop.Id == "Electronica" then
		for k = 0, 2 do
			Furniture.wallTV(r, face(r, -W / 2, 6, -8 + k * 8, 1, 0), 5)
		end
	elseif shop.Id == "Panaderia" then
		local vit = Furniture.group(r.Model, "Showcase")
		Furniture.solid(vit, "ShowcaseBase", V(10, 3, 2.4), r.at(-4, 1.5, -D / 2 + 8), WHITE)
		Furniture.deco(vit, "ShowcaseGlass", V(10, 1.8, 2.2), r.at(-4, 3.9, -D / 2 + 8), rgb(210, 230, 240), M.Glass, 0.5)
		for k = 0, 9 do
			Furniture.deco(vit, "Bread", V(0.9, 0.5, 1.6), r.at(-8.5 + k, 3.3, -D / 2 + 8) * ANG(0, k * 0.3, 0), rgb(200, 150, 80), M.Sand)
		end
		for k = 0, 1 do
			local tx = -W / 2 + 5 + k * 7
			Furniture.table(r, face(r, tx, 0, D / 2 - 5, 0, -1), 3, 3)
			Furniture.chair(r, face(r, tx, 0, D / 2 - 7.2, 0, 1))
		end
	else
		Furniture.plant(r, r.at(-W / 2 + 3, 0, -D / 2 + 3), 1.2)
	end
	Furniture.plant(r, r.at(W / 2 - 2, 0, D / 2 - 2), 1.2)
	-- Escaparates a los lados de la puerta
	for _, x in { -9, 9 } do
		Furniture.window(r, face(r, x, 6, -D / 2, 0, 1), 5, 5, "Main", nil)
	end
	-- Estantería larga en la pared de la derecha, cestas, carteles de ofertas y escaparate
	Furniture.shopShelf(r, face(r, W / 2 - 1.2, 0, 5, -1, 0), 12, shop.Shelf)
	local baskets = Furniture.group(r.Model, "Baskets")
	for k = 0, 4 do
		Furniture.deco(baskets, "Basket", V(1.8, 0.5, 1.4), r.at(-5, 0.3 + k * 0.45, -D / 2 + 2.2), rgb(200, 40, 40), M.Plastic)
	end
	for k, x in { -9, 9 } do
		local banner = bit(r, "Banner", V(6, 2, 0.1), r.at(x, r.H - 2, -2 + k * 4) * ANG(0, PI, 0), R.pick({ rgb(250, 200, 40), rgb(220, 50, 50) }))
		Builder.sign(banner, R.pick({ "¡OFERTAS!", "2x1", "NOVEDADES", "-20 %" }), Enum.NormalId.Front, DARK)
	end
	for _, x in { -12, 12 } do
		local stand = Furniture.group(r.Model, "Display")
		Furniture.solid(stand, "Podium", V(4, 2, 3), r.at(x, 1, -D / 2 + 2.5), WHITE)
		for k = -1, 1 do
			Furniture.deco(stand, "Product", V(0.9, R.range(0.8, 1.6), 0.9), r.at(x + k * 1.2, 2.6, -D / 2 + 2.5), R.pick(P.Products))
		end
	end
	bit(r, "Poster", V(4, 5, 0.1), r.at(0, 6, D / 2 - 0.1) * ANG(0, PI, 0) * CF(-12, 0, 0), R.pick(P.Accents))
	elevator(r, -W / 2 + 5, D / 2 - 0.4, PI)
	return r
end

---------------------------------------------------------------------
-- Naves y talleres
---------------------------------------------------------------------
local function pallet(r: Room, cf: CFrame, boxes: number?)
	local m = Furniture.group(r.Model, "Pallet")
	Furniture.solid(m, "Pallet", V(4, 0.5, 4), cf * CF(0, 0.25, 0), rgb(170, 130, 80), M.WoodPlanks)
	local R = r.Rand
	for k = 1, boxes or R.int(1, 4) do
		local h = R.range(1.2, 2)
		Furniture.deco(m, "Box", V(1.8, h, 1.8), cf * CF(((k - 1) % 2 - 0.5) * 1.9, 0.5 + h / 2 + math.floor((k - 1) / 4) * 2, (math.floor((k - 1) / 2) % 2 - 0.5) * 1.9), rgb(190, 150, 90):Lerp(rgb(150, 110, 70), R.next()), M.Cardboard)
	end
end

local function rack(r: Room, cf: CFrame, length: number)
	local m = Furniture.group(r.Model, "Rack")
	local R = r.Rand
	local bays = math.max(1, math.floor(length / 5))
	for i = 0, bays do
		local x = -length / 2 + i * length / bays
		Furniture.solid(m, "Upright", V(0.4, 13, 3.2), cf * CF(x, 6.5, 0), rgb(60, 90, 150), M.Metal)
	end
	for _, y in { 4.4, 8.8 } do
		Furniture.solid(m, "Beam", V(length, 0.4, 3.2), cf * CF(0, y, 0), rgb(230, 120, 30), M.Metal)
	end
	for level = 0, 2 do
		for i = 0, bays - 1 do
			local x = -length / 2 + (i + 0.5) * length / bays
			if R.chance(0.8) then
				local h = R.range(1.6, 3)
				Furniture.deco(m, "Box", V(length / bays - 1, h, 2.6), cf * CF(x, level * 4.4 + (if level == 0 then 0.1 else 0.2) + h / 2, 0), rgb(190, 150, 90):Lerp(rgb(140, 100, 60), R.next()), M.Cardboard)
			end
		end
	end
end

local function forklift(r: Room, cf: CFrame)
	local m = Furniture.group(r.Model, "Forklift")
	local yellow = rgb(230, 180, 30)
	Furniture.solid(m, "Chassis", V(4, 2.4, 6), cf * CF(0, 1.8, 0), yellow, M.Metal)
	Furniture.deco(m, "Counterweight", V(4, 2, 1.2), cf * CF(0, 2.2, 3), rgb(60, 60, 66), M.Metal)
	for _, x in { -1.8, 1.8 } do
		Furniture.deco(m, "CagePost", V(0.2, 4, 0.2), cf * CF(x, 5, -1.4), DARK, M.Metal)
		Furniture.deco(m, "CagePost", V(0.2, 4, 0.2), cf * CF(x, 5, 1.8), DARK, M.Metal)
		Furniture.deco(m, "Mast", V(0.4, 8, 0.4), cf * CF(x * 0.6, 4, -3.2), DARK, M.Metal)
		Furniture.deco(m, "Fork", V(0.4, 0.2, 4), cf * CF(x * 0.5, 0.3, -5), rgb(90, 90, 96), M.Metal)
		for _, z in { -2, 2 } do
			Furniture.cyl(m, "Wheel", 1.4, 1.4, cf * CF(x * 1.15, 0.7, z) * ANG(0, 0, PI / 2), DARK, M.Rubber)
		end
	end
	Furniture.deco(m, "Roof", V(4, 0.2, 3.6), cf * CF(0, 7, 0.2), DARK, M.Metal)
	local s = Furniture.seatPart(m, cf * CF(0, 3.2, 1), V(1.8, 0.3, 1.8), DARK, M.Leather, true)
	Furniture.usable(s, "Sit")
	Furniture.deco(m, "Wheel", V(1, 1, 0.2), cf * CF(0, 4.2, -0.5) * ANG(math.rad(-40), 0, 0), DARK)
end

function Interiors.Nave(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Nave", cf, 70, 50, 22, { Floor = rgb(140, 140, 136), FloorMaterial = M.Concrete, Wall = rgb(180, 176, 166), Windows = false, LightKind = "Spot", Baseboards = false }, opts)
	local W, D, H = r.W, r.D, r.H
	local R = r.Rand
	-- Estanterías altas con cajas
	for row = 0, 2 do
		rack(r, face(r, -8, 0, -6 + row * 12, 0, -1), 36)
	end
	-- Líneas de seguridad en el suelo
	for _, z in { -12, 26 - D / 2 + 12 } do
		bit(r, "SafetyLine", V(W - 8, 0.05, 0.6), r.at(0, 0.03, z), rgb(240, 200, 40))
	end
	bit(r, "SafetyLine", V(0.6, 0.05, D - 10), r.at(W / 2 - 16, 0.03, 2), rgb(240, 200, 40))
	-- Palés, carretilla, bidones y banco de trabajo
	for k = 0, 3 do
		pallet(r, r.at(W / 2 - 10 + (k % 2) * 5, 0, -D / 2 + 6 + math.floor(k / 2) * 5))
	end
	forklift(r, face(r, W / 2 - 8, 0, 4, 0, -1))
	for k = 0, 4 do
		Furniture.cyl(r.Model, "Barrel", 3, 2, r.at(-W / 2 + 2 + (k % 3) * 2.2, 1.5, D / 2 - 2 - math.floor(k / 3) * 2.2), R.pick({ rgb(40, 90, 170), rgb(200, 60, 40), rgb(60, 130, 60) }), M.Metal)
	end
	local bench = Furniture.group(r.Model, "Workbench")
	Furniture.solid(bench, "Workbench", V(10, 3, 3), r.at(W / 2 - 8, 1.5, D / 2 - 3), WOOD, M.Wood)
	Furniture.deco(bench, "Vise", V(1, 1, 1.4), r.at(W / 2 - 4, 3.5, D / 2 - 3), rgb(60, 90, 150), M.Metal)
	Furniture.deco(bench, "Pegboard", V(10, 5, 0.2), r.at(W / 2 - 8, 6.5, D / 2 - 0.1), rgb(200, 170, 120), M.Wood)
	for k = 0, 5 do
		Furniture.deco(bench, "Tool", V(0.3, R.range(1.2, 2.4), 0.2), r.at(W / 2 - 12 + k * 1.5, 6.5, D / 2 - 0.3), R.pick({ rgb(200, 40, 40), DARK, STEEL, rgb(230, 180, 30) }), M.Metal)
	end
	-- Oficina de la nave: caseta con mesa y ordenador
	local ox, oz = -W / 2 + 7, -D / 2 + 6
	bit(r, "OfficeGlass", V(12, 6, 0.3), r.at(ox, 3, oz + 5), rgb(200, 225, 240), M.Glass, 0.5)
	bit(r, "OfficeWall", V(0.3, 6, 10), r.at(ox + 6, 3, oz), rgb(200, 196, 186))
	Furniture.desk(r, face(r, ox, 0, oz - 2.5, 0, 1), { Computer = true, Room = "Main" })
	Furniture.filingCabinet(r, face(r, ox - 4.5, 0, oz - 3.9, 0, 1))
	Furniture.waterCooler(r, face(r, ox + 3.5, 0, oz - 3.9, 0, 1))
	Furniture.lockers(r, face(r, -W / 2 + 1.1, 0, 8, 1, 0), 6)
	Furniture.bench(r, face(r, -W / 2 + 4.5, 0, 8, 1, 0), 6, r.Wood)
	-- Portón de carga
	bit(r, "DockDoor", V(0.4, 14, 16), r.at(W / 2 - 0.2, 7, -6), rgb(160, 160, 166), M.DiamondPlate)
	for k = 0, 6 do
		bit(r, "DockStripe", V(0.45, 0.3, 16), r.at(W / 2 - 0.25, 1 + k * 2, -6), rgb(120, 120, 126), M.Metal)
	end
	bit(r, "Extinguisher", V(0.8, 1.6, 0.8), r.at(-W / 2 + 0.6, 2.5, -D / 2 + 12), rgb(210, 30, 30), M.Metal)
	bit(r, "Extinguisher", V(0.8, 1.6, 0.8), r.at(W / 2 - 0.6, 2.5, D / 2 - 12), rgb(210, 30, 30), M.Metal)
	Furniture.clock(r, face(r, 0, H - 4, D / 2, 0, -1))
	return r
end

function Interiors.Taller(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Taller", cf, 50, 40, 16, { Floor = rgb(120, 120, 118), FloorMaterial = M.Concrete, Windows = false, LightKind = "Panel", Baseboards = false }, opts)
	local W, D = r.W, r.D
	local R = r.Rand
	-- Elevador con coche encima
	local lift = Furniture.group(r.Model, "CarLift")
	for _, x in { -15, -5 } do
		Furniture.solid(lift, "LiftPost", V(1, 9, 1), r.at(x, 4.5, -3), rgb(200, 60, 40), M.Metal)
		Furniture.deco(lift, "LiftArm", V(1, 0.4, 14), r.at(x + (if x < -10 then 2 else -2), 4, 4), rgb(200, 60, 40), M.Metal)
	end
	local car = Furniture.group(r.Model, "Car")
	local paint = R.pick({ rgb(40, 90, 170), rgb(170, 30, 30), rgb(230, 230, 230), rgb(40, 40, 44), rgb(60, 140, 80) })
	Furniture.deco(car, "CarBody", V(6, 2.2, 12), r.at(-10, 5.4, 4), paint, M.Metal)
	Furniture.deco(car, "CarCabin", V(5.4, 2, 6), r.at(-10, 7.4, 4.6), paint, M.Metal)
	Furniture.deco(car, "Windshield", V(5, 1.8, 0.2), r.at(-10, 7.4, 1.5) * ANG(math.rad(25), 0, 0), rgb(160, 200, 230), M.Glass, 0.3)
	for _, x in { -13.1, -6.9 } do
		for _, z in { 0.2, 7.8 } do
			Furniture.cyl(car, "Wheel", 0.9, 2.2, r.at(x, 4.6, z) * ANG(0, 0, PI / 2), DARK, M.Rubber)
		end
	end
	-- Pared de herramientas y banco
	local tools = Furniture.group(r.Model, "ToolWall")
	Furniture.deco(tools, "ToolWall", V(0.3, 8, 16), r.at(W / 2 - 0.2, 5, 0), rgb(90, 90, 96), M.DiamondPlate)
	for k = 0, 11 do
		Furniture.deco(tools, "Tool", V(0.2, R.range(1, 2.4), 0.3), r.at(W / 2 - 0.45, 5 + (k % 2) * 2.6, -7 + k * 1.2), R.pick({ rgb(200, 40, 40), DARK, STEEL, rgb(230, 180, 30) }), M.Metal)
	end
	Furniture.solid(tools, "Workbench", V(3, 3, 12), r.at(W / 2 - 2, 1.5, 0), WOOD, M.Wood)
	Furniture.deco(tools, "Vise", V(1.4, 1, 1), r.at(W / 2 - 2, 3.5, -4), rgb(60, 90, 150), M.Metal)
	-- Neumáticos, bidones, carro de herramientas y compresor
	for k = 0, 4 do
		Furniture.cyl(r.Model, "Tire", 0.9, 3, r.at(W / 2 - 3, 0.45 + k * 0.9, D / 2 - 4), DARK, M.Rubber)
	end
	for k = 0, 2 do
		Furniture.cyl(r.Model, "OilDrum", 3, 2, r.at(-W / 2 + 2 + k * 2.2, 1.5, D / 2 - 2), R.pick({ rgb(40, 90, 170), rgb(200, 60, 40) }), M.Metal)
	end
	local cart = Furniture.group(r.Model, "ToolCart")
	Furniture.solid(cart, "ToolCart", V(3, 3.2, 1.8), r.at(-2, 1.8, 10), rgb(200, 40, 40), M.Metal)
	for k = 0, 3 do
		Furniture.deco(cart, "Drawer", V(2.6, 0.5, 0.08), r.at(-2, 1 + k * 0.7, 9.08), rgb(170, 30, 30), M.Metal)
	end
	Furniture.cyl(r.Model, "Compressor", 3, 1.6, r.at(4, 0.8, D / 2 - 2) * ANG(0, 0, PI / 2), rgb(230, 120, 30), M.Metal)
	bit(r, "OilStain", V(4, 0.04, 3), r.at(-10, 0.03, 8), rgb(50, 46, 44), M.SmoothPlastic, 0.3)
	-- Mostrador con ordenador y taburete
	Furniture.desk(r, face(r, 10, 0, -D / 2 + 5, 0, -1), { Computer = true, Chair = false, Color = rgb(90, 90, 96) })
	Furniture.stool(r, face(r, 10, 0, -D / 2 + 2.6, 0, 1), rgb(40, 40, 46), 2.2)
	Furniture.picture(r, face(r, 10, 7, -D / 2, 0, 1), 3, 4)
	Furniture.lockers(r, face(r, -W / 2 + 1.1, 0, -10, 1, 0), 4, rgb(150, 60, 50))
	Furniture.waterCooler(r, face(r, -W / 2 + 1.2, 0, -4, 1, 0))
	-- Estante de aceites, gato hidráulico, radio y banderín
	local oils = Furniture.group(r.Model, "OilShelf")
	Furniture.solid(oils, "OilShelf", V(6, 5, 1.6), r.at(4, 2.5, D / 2 - 1), STEEL, M.Metal)
	for row = 0, 2 do
		for k = 0, 6 do
			Furniture.deco(oils, "OilCan", V(0.6, 0.9, 0.6), r.at(1.6 + k * 0.8, 1 + row * 1.6, D / 2 - 1.4), R.pick({ rgb(230, 180, 30), rgb(40, 90, 170), rgb(200, 40, 40), DARK }), M.Metal)
		end
	end
	local jack = Furniture.group(r.Model, "Jack")
	Furniture.deco(jack, "JackBody", V(1.4, 0.6, 3), r.at(0, 0.3, 4), rgb(200, 40, 40), M.Metal)
	Furniture.deco(jack, "JackHandle", V(0.15, 0.15, 3.4), r.at(0, 1.2, 6.2) * ANG(math.rad(35), 0, 0), DARK, M.Metal)
	Furniture.deco(r.Model, "Radio", V(1.4, 0.8, 0.6), r.at(W / 2 - 2, 3.4, 4), DARK)
	bit(r, "Pennant", V(0.1, 2, 6), r.at(W / 2 - 0.35, 10.5, 0), R.pick({ rgb(200, 40, 40), rgb(40, 90, 170) }), M.Fabric)
	return r
end

---------------------------------------------------------------------
-- Ocio (bar de copas / discoteca)
---------------------------------------------------------------------
function Interiors.Ocio(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Ocio", cf, 50, 40, 14, { Floor = rgb(50, 40, 50), Wall = rgb(60, 40, 70), Light = rgb(200, 120, 255), Windows = false, LightKind = "Spot", Baseboard = rgb(30, 24, 34) }, opts)
	local W, D, H = r.W, r.D, r.H
	local R = r.Rand
	-- Barra con taburetes, botellas iluminadas, grifos de cerveza y nevera
	local bx = -W / 2 + 4
	counter(r, face(r, bx, 0, 4, 1, 0), 18, DARKWOOD)
	for k = 0, 4 do
		Furniture.stool(r, face(r, bx + 3, 0, -4 + k * 3.8, -1, 0), rgb(160, 40, 60), 3)
	end
	local back = Furniture.group(r.Model, "BackBar")
	Furniture.solid(back, "BackBar", V(1.6, 3.4, 18), r.at(-W / 2 + 0.8, 1.7, 4), DARKWOOD, M.Wood)
	for row = 0, 2 do
		Furniture.deco(back, "BottleShelf", V(1, 0.15, 16), r.at(-W / 2 + 0.5, 5 + row * 1.8, 4), rgb(200, 200, 210), M.Glass)
		for k = 0, 13 do
			Furniture.cyl(back, "Bottle", R.range(0.9, 1.4), 0.4, r.at(-W / 2 + 0.5, 5.7 + row * 1.8, -3 + k * 1.05), R.pick({ rgb(120, 200, 160), rgb(200, 150, 60), rgb(160, 40, 40), rgb(230, 230, 220), rgb(90, 60, 30) }), M.Glass)
		end
		local strip = Furniture.deco(back, "BottleLight", V(0.1, 0.1, 16), r.at(-W / 2 + 0.1, 5.1 + row * 1.8, 4), rgb(120, 80, 255), M.Neon)
		strip.CastShadow = false
	end
	for k = 0, 2 do
		Furniture.deco(r.Model, "TapTower", V(0.3, 1.4, 0.3), r.at(bx, 4.4, 8 + k * 1.2), STEEL, M.Metal)
		local tap = Furniture.deco(r.Model, "TapSpout", V(0.2, 0.2, 0.6), r.at(bx + 0.3, 4.9, 8 + k * 1.2) * ANG(0, PI / 2, 0), STEEL, M.Metal)
		Furniture.usable(tap, "Tap", { Spot = r.at(bx + 3.4, 0, 8 + k * 1.2).Position })
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "Water"
		emitter.Enabled = false
		emitter.Rate = 30
		emitter.Lifetime = NumberRange.new(0.3, 0.4)
		emitter.Speed = NumberRange.new(3, 4)
		emitter.EmissionDirection = Enum.NormalId.Bottom
		emitter.Size = NumberSequence.new(0.12)
		emitter.Color = ColorSequence.new(rgb(240, 190, 60))
		emitter.Parent = tap
	end
	Furniture.drinksCooler(r, face(r, -W / 2 + 1.3, 0, D / 2 - 3.2, 1, 0))
	-- Pista de baile, cabina del DJ, altavoces y bola de espejos
	local colors = { rgb(255, 60, 120), rgb(60, 160, 255), rgb(255, 220, 60), rgb(120, 255, 120) }
	for x = 0, 3 do
		for z = 0, 3 do
			bit(r, "DanceTile", V(4, 0.1, 4), r.at(6 + x * 4, 0.06, -2 + z * 4), colors[(x + z) % 4 + 1], M.Neon)
		end
	end
	local dj = Furniture.group(r.Model, "DJBooth")
	Furniture.solid(dj, "DJBooth", V(8, 4, 3), r.at(12, 2, D / 2 - 3), DARK)
	for _, x in { 10.3, 13.7 } do
		Furniture.cyl(dj, "Deck", 0.2, 1.6, r.at(x, 4.1, D / 2 - 3), rgb(20, 20, 24))
	end
	Furniture.deco(dj, "Mixer", V(1.4, 0.3, 1.2), r.at(12, 4.15, D / 2 - 3), rgb(60, 60, 66))
	Furniture.deco(dj, "BoothLight", V(7.6, 0.3, 0.1), r.at(12, 1, D / 2 - 4.55), rgb(255, 60, 200), M.Neon)
	for _, x in { 4, 20 } do
		Furniture.solid(r.Model, "Speaker", V(2.4, 6, 2.4), r.at(x, 3, D / 2 - 2), rgb(20, 20, 24))
		Furniture.cyl(r.Model, "Woofer", 0.1, 1.8, r.at(x, 2.2, D / 2 - 3.25) * ANG(0, PI / 2, 0), rgb(60, 60, 66))
	end
	local disco = Furniture.ball(r.Model, "DiscoBall", V(2, 2, 2), r.at(12, H - 2.5, 4), rgb(220, 220, 230), M.Foil)
	disco.Reflectance = 0.6
	Furniture.roomLight(disco, "Main", 24, 0.8, rgb(200, 120, 255))
	-- Reservados: sofás con mesa
	for k = 0, 1 do
		local z = -D / 2 + 4 + k * 9
		Furniture.sofa(r, face(r, W / 2 - 2, 0, z, -1, 0), rgb(120, 30, 60), 3)
		Furniture.coffeeTable(r, face(r, W / 2 - 6.5, 0, z, -1, 0), 3, 4)
	end
	-- Mesas altas con taburetes y un rincón con piano
	for k = 0, 2 do
		local tz = -D / 2 + 6 + k * 8
		local t = Furniture.group(r.Model, "HighTable")
		Furniture.cyl(t, "HighTop", 0.2, 2.6, r.at(-6, 3.6, tz), DARKWOOD, M.Wood)
		Furniture.deco(t, "HighLeg", V(0.3, 3.5, 0.3), r.at(-6, 1.75, tz), STEEL, M.Metal)
		Furniture.stool(r, face(r, -8, 0, tz, 1, 0), rgb(40, 40, 46), 2.6)
		Furniture.stool(r, face(r, -4, 0, tz, -1, 0), rgb(40, 40, 46), 2.6)
	end
	Furniture.piano(r, face(r, 0, 0, D / 2 - 2, 0, -1))
	Furniture.wallTV(r, face(r, W / 2, 7.5, 8, -1, 0), 7)
	for k, text in { "🍸 BAR", "♫ VALMAR NIGHT ♫" } do
		local neon = bit(r, "NeonSign", V(8, 1.6, 0.2), r.at(if k == 1 then -W / 2 + 0.2 else 0, 10.5, if k == 1 then 4 else -D / 2 + 0.2) * ANG(0, if k == 1 then PI / 2 else PI, 0), rgb(30, 10, 40))
		Builder.sign(neon, text, Enum.NormalId.Front, if k == 1 then rgb(120, 240, 255) else rgb(255, 90, 200))
	end
	return r
end

---------------------------------------------------------------------
-- Aulas (facultades)
---------------------------------------------------------------------
function Interiors.Aula(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Aula", cf, 50, 40, 14, { Floor = rgb(170, 150, 120) }, opts)
	local W, D = r.W, r.D
	local R = r.Rand
	bit(r, "Board", V(20, 6, 0.3), r.at(0, 7, D / 2 - 0.2), rgb(40, 70, 50))
	bit(r, "BoardFrame", V(20.6, 6.6, 0.2), r.at(0, 7, D / 2 - 0.1), r.Wood, M.Wood)
	for i = 1, 4 do
		bit(r, "Chalk", V(R.range(3, 8), 0.2, 0.05), r.at(R.range(-6, 6), 7 + R.range(-2, 2), D / 2 - 0.37), rgb(236, 236, 230))
	end
	Furniture.wallTV(r, face(r, 16, 7, D / 2, 0, -1), 7)
	Furniture.desk(r, face(r, 0, 0, D / 2 - 6, 0, 1), { Computer = true, Width = 6 })
	-- Pupitres: mesa y silla por alumno
	local color = R.pick({ rgb(60, 90, 150), rgb(150, 60, 50), rgb(60, 120, 80) })
	for row = 0, 4 do
		for k = 0, 5 do
			local x, z = -15 + k * 6, -12 + row * 5
			local d = Furniture.group(r.Model, "SchoolDesk")
			Furniture.solid(d, "DeskTop", V(3.6, 0.2, 1.8), r.at(x, 3, z + 1.4), r.Wood, M.Wood)
			Furniture.deco(d, "DeskLeg", V(3.2, 2.9, 0.15), r.at(x, 1.45, z + 2.2), STEEL, M.Metal)
			if R.chance(0.3) then
				Furniture.deco(d, "Notebook", V(1, 0.08, 1.3), r.at(x + R.range(-1, 1), 3.14, z + 1.4), R.pick(P.Books))
			end
			seat(r, face(r, x, 0, z, 0, -1) * ANG(0, PI, 0), color)
		end
	end
	Furniture.bookshelf(r, face(r, W / 2 - 1, 0, 0, -1, 0), 6, 7)
	Furniture.clock(r, face(r, -W / 2, 9, 0, 1, 0))
	Furniture.plant(r, r.at(W / 2 - 2, 0, -D / 2 + 2), 1.3)
	for _, z in { -3.5, 3.5 } do
		Furniture.picture(r, face(r, -W / 2, 6.5, z, 1, 0), 3, 3.6)
	end
	elevator(r, -W / 2 + 5, -D / 2 + 0.4)
	return r
end

---------------------------------------------------------------------
-- Monumentos
---------------------------------------------------------------------
function Interiors.Ayuntamiento(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Ayuntamiento", cf, 80, 56, 20, { Floor = rgb(210, 200, 180), FloorMaterial = M.Marble, LightKind = "Chandelier", Curtains = rgb(140, 30, 40) }, opts)
	local W, D = r.W, r.D
	for k = 0, 2 do
		counter(r, r.at(-24 + k * 12, 0, -8), 8, DARKWOOD)
		Furniture.desk(r, face(r, -24 + k * 12, 0, -5.3, 0, -1), { Computer = true, Chair = false, Width = 4 })
		Builder.part({ Name = "ClerkSpot", Size = V(2, 2, 2), CFrame = r.at(-24 + k * 12, 0, -4.6) * ANG(0, 0, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = { "ClerkSpot" }, Parent = r.Model })
	end
	sign(r, "REGISTRO · PADRÓN · LICENCIAS", V(30, 2, 0.2), r.at(-12, 10, -6.6) * ANG(0, PI, 0), rgb(90, 40, 40))
	-- Sala de espera
	for row = 0, 1 do
		for k = 0, 5 do
			seat(r, face(r, -30 + k * 3, 0, -20 + row * 4, 0, 1) * ANG(0, PI, 0), rgb(120, 30, 40))
		end
	end
	bit(r, "TicketMachine", V(1.6, 4.4, 1.2), r.at(-8, 2.2, -D / 2 + 3), rgb(200, 60, 50))
	bit(r, "TicketScreen", V(1.2, 0.8, 0.1), r.at(-8, 3.6, -D / 2 + 3.65), rgb(80, 200, 255), M.Neon)
	-- Salón de plenos
	bit(r, "Dais", V(24, 2, 8), r.at(0, 1, D / 2 - 6), DARKWOOD, M.Wood)
	for k = 0, 4 do
		seat(r, r.at(-8 + k * 4, 2, D / 2 - 5) * ANG(0, PI, 0), rgb(120, 30, 40))
	end
	for row = 0, 2 do
		for k = 0, 7 do
			seat(r, r.at(-14 + k * 4, 0, 6 + row * 4) * ANG(0, PI, 0), rgb(120, 30, 40))
		end
	end
	bit(r, "Carpet", V(10, 0.08, 30), r.at(0, 0.05, -8), rgb(150, 30, 40), M.Fabric)
	sign(r, "SALÓN DE PLENOS", V(14, 2, 0.2), r.at(0, 14, D / 2 - 0.2) * ANG(0, PI, 0), rgb(120, 30, 40))
	for _, x in { -14, 14 } do
		local f = Furniture.group(r.Model, "Flag")
		Furniture.deco(f, "FlagPole", V(0.4, 12, 0.4), r.at(x, 6, D / 2 - 2), STEEL, M.Metal)
		for i, color in { rgb(200, 40, 40), rgb(240, 200, 40), rgb(200, 40, 40) } do
			Furniture.deco(f, "Flag", V(4, 0.9, 0.1), r.at(x + 2.2, 11.4 - i * 0.9, D / 2 - 2), color, M.Fabric)
		end
	end
	for _, z in { -9.3, 9.3 } do
		Furniture.picture(r, face(r, W / 2, 9, z, -1, 0), 5, 6)
	end
	for _, p in { { -W / 2 + 3, -D / 2 + 3 }, { W / 2 - 3, -D / 2 + 3 }, { -W / 2 + 3, D / 2 - 3 }, { W / 2 - 3, D / 2 - 3 } } do
		Furniture.plant(r, r.at(p[1], 0, p[2]), 1.6)
	end
	Furniture.bench(r, face(r, 20, 0, -20, 0, 1), 8, DARKWOOD)
	Furniture.clock(r, face(r, 0, 14, -D / 2, 0, 1))
	return r
end

function Interiors.Museo(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Museo", cf, 90, 60, 20, { Floor = rgb(200, 190, 170), FloorMaterial = M.Marble, Wall = rgb(240, 236, 228), Windows = false, LightKind = "Spot" }, opts)
	local W, D = r.W, r.D
	local art = { rgb(200, 80, 60), rgb(60, 120, 200), rgb(230, 190, 60), rgb(90, 160, 90), rgb(150, 80, 160) }
	for k = 0, 5 do
		local z = -D / 2 + 8 + k * 9
		for _, x in { -W / 2 + 0.4, W / 2 - 0.4 } do
			bit(r, "Frame", V(0.4, 8, 6), r.at(x, 8, z), rgb(200, 170, 90), M.Wood)
			bit(r, "Painting", V(0.5, 7, 5), r.at(x, 8, z), art[k % #art + 1])
			bit(r, "PaintingDetail", V(0.55, 3, 2.4), r.at(x, 8 + (k % 3 - 1), z + (k % 2 - 0.5) * 2), art[(k + 2) % #art + 1])
			bit(r, "Plaque", V(0.3, 0.6, 1.2), r.at(x, 3.5, z), rgb(200, 180, 120), M.Metal)
			local light = bit(r, "PictureLight", V(0.6, 0.3, 2.4), r.at(x + (if x < 0 then 1 else -1), 13, z), rgb(255, 244, 220), M.Neon)
			Furniture.roomLight(light, "Main", 10, 0.6)
			-- Cordón delante de los cuadros
			for _, dz in { -2.5, 2.5 } do
				Furniture.deco(r.Model, "Stanchion", V(0.3, 3, 0.3), r.at(x + (if x < 0 then 3 else -3), 1.5, z + dz), rgb(200, 170, 90), M.Metal)
			end
			Furniture.deco(r.Model, "Rope", V(0.15, 0.15, 5), r.at(x + (if x < 0 then 3 else -3), 2.6, z), rgb(150, 20, 30), M.Fabric)
		end
	end
	for k = 0, 2 do
		bit(r, "Pedestal", V(4, 4, 4), r.at(-16 + k * 16, 2, 4), WHITE, M.Marble)
		local statue = bit(r, "Statue", V(6, 2.4, 2.4), r.at(-16 + k * 16, 7, 4) * ANG(0, 0, math.rad(90)), rgb(220, 216, 206), M.Marble)
		statue.Shape = Enum.PartType.Cylinder
		Furniture.ball(r.Model, "StatueHead", V(1.8, 2, 1.8), r.at(-16 + k * 16, 11, 4), rgb(220, 216, 206), M.Marble)
		-- Bancos para mirar
		Furniture.bench(r, face(r, -16 + k * 16, 0, -6, 0, 1), 6, DARKWOOD)
	end
	-- Vitrinas
	for k = 0, 3 do
		local x = -30 + k * 20
		local v = Furniture.group(r.Model, "Vitrine")
		Furniture.solid(v, "VitrineBase", V(4, 3.4, 3), r.at(x, 1.7, 16), rgb(60, 50, 44), M.Wood)
		Furniture.deco(v, "VitrineGlass", V(3.8, 2.6, 2.8), r.at(x, 4.7, 16), rgb(210, 230, 240), M.Glass, 0.6)
		Furniture.ball(v, "Relic", V(1, 1.2, 1), r.at(x, 4, 16), ({ rgb(200, 170, 80), rgb(120, 160, 170), rgb(170, 90, 60), rgb(230, 230, 230) })[k + 1], M.Metal)
	end
	-- Recepción
	counter(r, r.at(-W / 2 + 12, 0, -D / 2 + 8), 10, DARKWOOD)
	Builder.part({ Name = "ClerkSpot", Size = V(2, 2, 2), CFrame = r.at(-W / 2 + 12, 0, -D / 2 + 10.6) * ANG(0, PI, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = { "ClerkSpot" }, Parent = r.Model })
	for _, p in { { W / 2 - 4, -D / 2 + 4 }, { -W / 2 + 4, D / 2 - 4 }, { W / 2 - 4, D / 2 - 4 } } do
		Furniture.plant(r, r.at(p[1], 0, p[2]), 1.6)
	end
	-- Esqueleto de dinosaurio sobre su tarima
	local dino = Furniture.group(r.Model, "Dinosaur")
	local bone = rgb(226, 214, 190)
	local dx, dz = 22, -18
	Furniture.solid(dino, "DinoBase", V(20, 1, 8), r.at(dx, 0.5, dz), rgb(90, 80, 70), M.Slate)
	for k = 0, 11 do
		local x = dx - 8 + k * 1.4
		local y = 6 + math.sin(k / 11 * PI) * 2.2 - (if k > 8 then (k - 8) * 0.8 else 0)
		Furniture.ball(dino, "Vertebra", V(1, 1, 1), r.at(x, y, dz), bone, M.Slate)
		if k >= 3 and k <= 8 then
			for _, sz in { -1, 1 } do
				Furniture.deco(dino, "Rib", V(0.3, 2.6, 0.3), r.at(x, y - 1.2, dz + sz * 0.9) * ANG(sz * 0.35, 0, 0), bone, M.Slate)
			end
		end
	end
	Furniture.deco(dino, "Skull", V(3, 1.6, 1.4), r.at(dx + 9.2, 4.4, dz), bone, M.Slate)
	Furniture.deco(dino, "Jaw", V(2.4, 0.4, 1.2), r.at(dx + 9.4, 3.4, dz), bone, M.Slate)
	for _, lx in { -4, 3 } do
		for _, sz in { -1, 1 } do
			Furniture.deco(dino, "Leg", V(0.6, 5, 0.6), r.at(dx + lx, 3.4, dz + sz * 1.2) * ANG(0, 0, 0.12), bone, M.Slate)
		end
	end
	local plate = bit(r, "DinoPlate", V(4, 1.4, 0.2), r.at(dx, 1.8, dz - 4.1) * ANG(math.rad(20), 0, 0), rgb(40, 40, 44))
	Builder.sign(plate, "TIRANOSAURIO · 66 MILLONES DE AÑOS", Enum.NormalId.Front, rgb(240, 210, 130))
	sign(r, "MUSEO DE VALMAR", V(20, 2.6, 0.2), r.at(0, 14, D / 2 - 0.2) * ANG(0, PI, 0), rgb(40, 40, 44), rgb(240, 210, 130))
	return r
end

function Interiors.Teatro(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Teatro", cf, 80, 70, 26, { Floor = rgb(120, 30, 40), FloorMaterial = M.Carpet, Wall = rgb(90, 30, 40), Light = rgb(255, 220, 170), Windows = false, LightKind = "Chandelier", Baseboard = rgb(200, 170, 90) }, opts)
	local W, D = r.W, r.D
	bit(r, "Stage", V(56, 4, 18), r.at(0, 2, D / 2 - 9), DARKWOOD, M.WoodPlanks)
	bit(r, "StageEdge", V(56, 0.6, 0.4), r.at(0, 3.7, D / 2 - 18.2), rgb(200, 170, 90), M.Wood)
	bit(r, "Curtain", V(56, 20, 1), r.at(0, 14, D / 2 - 1), rgb(170, 20, 30), M.Fabric)
	bit(r, "Valance", V(60, 3, 1.2), r.at(0, 23, D / 2 - 17.5), rgb(170, 20, 30), M.Fabric)
	for _, x in { -30, 30 } do
		bit(r, "SideCurtain", V(6, 22, 1.4), r.at(x, 11, D / 2 - 18), rgb(170, 20, 30), M.Fabric)
		-- Palcos
		bit(r, "Box", V(6, 1, 16), r.at(x + (if x < 0 then -4 else 4), 10, -4), rgb(200, 170, 90), M.Wood)
		bit(r, "BoxRail", V(0.4, 2.4, 16), r.at(x + (if x < 0 then -1.2 else 1.2), 11.7, -4), rgb(200, 170, 90), M.Wood)
	end
	for row = 0, 6 do
		for k = 0, 11 do
			seat(r, r.at(-24 + k * 4.4, 0, -D / 2 + 10 + row * 4.6) * ANG(0, PI, 0), rgb(170, 20, 30))
		end
	end
	-- Focos del escenario y el piano del concierto
	for k = 0, 4 do
		local s = bit(r, "StageSpot", V(1.2, 1.2, 1.6), r.at(-20 + k * 10, 22, D / 2 - 20) * ANG(math.rad(35), 0, 0), rgb(255, 240, 200), M.Neon)
		Furniture.roomLight(s, "Main", 22, 0.9, rgb(255, 230, 190))
	end
	Furniture.piano(r, r.at(12, 4, D / 2 - 8) * ANG(0, PI, 0) * ANG(0, PI, 0))
	bit(r, "Aisle", V(4, 0.08, 34), r.at(28, 0.05, -D / 2 + 22), rgb(200, 160, 80), M.Fabric)
	for _, x in { -W / 2 + 0.3, W / 2 - 0.3 } do
		local exit = bit(r, "ExitSign", V(0.2, 1, 3), r.at(x, 10, -D / 2 + 6), rgb(30, 160, 60), M.Neon)
		Builder.sign(exit, "SALIDA", if x < 0 then Enum.NormalId.Right else Enum.NormalId.Left)
	end
	return r
end

function Interiors.Estacion(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Estacion", cf, 90, 60, 24, { Floor = rgb(200, 196, 188), FloorMaterial = M.Marble }, opts)
	local W, D = r.W, r.D
	local R = r.Rand
	sign(r, "SALIDAS · 10:15 Norte · 10:30 Playa Dorada · 10:45 Campus", V(34, 5, 0.3), r.at(0, 16, D / 2 - 0.3) * ANG(0, PI, 0), rgb(20, 20, 24), rgb(255, 200, 60))
	for k = 0, 3 do
		counter(r, r.at(-30 + k * 10, 0, D / 2 - 10), 7, rgb(40, 70, 130))
		bit(r, "TicketWindow", V(7, 3, 0.2), r.at(-30 + k * 10, 5.4, D / 2 - 11), rgb(200, 225, 240), M.Glass, 0.5)
	end
	Builder.part({ Name = "ClerkSpot", Size = V(2, 2, 2), CFrame = r.at(-30, 0, D / 2 - 7.4) * ANG(0, PI, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = { "ClerkSpot" }, Parent = r.Model })
	-- Bancos de espera
	for row = 0, 2 do
		for k = 0, 2 do
			Furniture.bench(r, face(r, -15 + k * 12, 0, -12 + row * 8, 0, -1), 8, rgb(60, 90, 150))
		end
	end
	-- Máquinas de billetes, quiosco con nevera, reloj, papeleras, carro de maletas, columnas
	for k = 0, 2 do
		local x = W / 2 - 3
		bit(r, "TicketMachine", V(1.6, 4.6, 1.6), r.at(x, 2.3, -10 + k * 4), rgb(200, 40, 40))
		bit(r, "MachineScreen", V(0.1, 1, 1.2), r.at(x - 0.85, 3.6, -10 + k * 4), rgb(80, 200, 255), M.Neon)
	end
	counter(r, face(r, -W / 2 + 6, 0, -D / 2 + 8, 1, 0), 6, rgb(40, 110, 70))
	Furniture.drinksCooler(r, face(r, -W / 2 + 1.3, 0, -D / 2 + 13, 1, 0))
	for k = 0, 5 do
		bit(r, "Magazine", V(0.8, 1.1, 0.1), r.at(-W / 2 + 4.6, 4.5, -D / 2 + 5.8 + k * 0.9) * ANG(math.rad(-15), PI / 2, 0), R.pick(P.Books))
	end
	for _, x in { -30, -10, 10, 30 } do
		solid(r, "Column", V(2.6, 24, 2.6), r.at(x, 12, 13), rgb(220, 216, 206), M.Marble)
	end
	local clock = Furniture.group(r.Model, "StationClock")
	Furniture.deco(clock, "ClockPost", V(0.4, 4, 0.4), r.at(0, 21, 4), DARK, M.Metal)
	Furniture.cyl(clock, "ClockFace", 0.6, 4, r.at(0, 18, 4) * ANG(0, 0, PI / 2) * ANG(0, 0, PI / 2), WHITE)
	for _, p in { { W / 2 - 4, -D / 2 + 4 }, { -W / 2 + 4, D / 2 - 4 } } do
		Furniture.plant(r, r.at(p[1], 0, p[2]), 1.6)
	end
	local trolley = Furniture.group(r.Model, "Trolley")
	Furniture.deco(trolley, "TrolleyBase", V(2.4, 0.3, 4), r.at(20, 1, -20), STEEL, M.Metal)
	Furniture.deco(trolley, "Suitcase", V(2, 2.4, 1.2), r.at(20, 2.4, -21), rgb(40, 60, 110), M.Leather)
	Furniture.deco(trolley, "Suitcase", V(1.8, 1.6, 1), r.at(20, 2, -19.4), rgb(160, 40, 40), M.Leather)
	return r
end

function Interiors.CentroComercial(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "CentroComercial", cf, 110, 70, 24, { Floor = rgb(226, 222, 214), FloorMaterial = M.Marble }, opts)
	local W, D = r.W, r.D
	-- Tiendas: dos junto a la entrada (a los lados, sin tapar la puerta) y tres al fondo
	local names = { { "MODA", "Clothes", -40, true }, { "DEPORTES", "Toys", 40, true }, { "JUGUETES", "Toys", -40, false }, { "TECNOLOGÍA", "Tech", 0, false }, { "LIBRERÍA", "Books", 40, false }, { "PERFUMERÍA", "Pharmacy", 0, true } }
	for _, entry in names do
		local x = entry[3]
		if entry[4] and x == 0 then
			continue -- (delante de la puerta no hay tienda: es la entrada)
		end
		local z = if entry[4] then -D / 2 + 8 else D / 2 - 8
		local turn = if entry[4] then 0 else PI
		local base = r.at(x, 0, z) * ANG(0, turn, 0)
		bit(r, "ShopFront", V(26, 12, 0.4), base * CF(0, 6, 4), rgb(200, 225, 240), M.Glass, 0.6)
		Furniture.shopShelf(r, base * CF(-6, 0, -2) * ANG(0, PI, 0), 8, entry[2])
		Furniture.shopShelf(r, base * CF(6, 0, -2) * ANG(0, PI, 0), 8, entry[2])
		sign(r, entry[1], V(14, 2, 0.3), base * CF(0, 13, 4.2) * ANG(0, PI, 0), rgb(30, 60, 110))
	end
	bit(r, "Fountain", V(12, 2, 12), r.at(0, 1, 0), rgb(200, 200, 196), M.Marble)
	bit(r, "FountainWater", V(10, 0.3, 10), r.at(0, 2.1, 0), rgb(90, 170, 230), M.Glass, 0.3)
	Furniture.cyl(r.Model, "FountainSpout", 4, 1, r.at(0, 3, 0), rgb(200, 200, 196), M.Marble)
	-- Bancos, jardineras, zona de comidas y quiosco
	for _, p in { { -14, 0, 1, 0 }, { 14, 0, -1, 0 }, { 0, -12, 0, 1 }, { 0, 12, 0, -1 } } do
		Furniture.bench(r, face(r, p[1], 0, p[2], p[3], p[4]), 7, DARKWOOD)
	end
	for _, p in { { -25, -10 }, { 25, -10 }, { -25, 10 }, { 25, 10 } } do
		solid(r, "Planter", V(6, 2, 6), r.at(p[1], 1, p[2]), rgb(180, 176, 166), M.Concrete)
		Furniture.ball(r.Model, "Bush", V(5, 4, 5), r.at(p[1], 4, p[2]), rgb(70, 130, 60), M.Grass)
	end
	for k = 0, 2 do
		local tx = 32 + k * 7
		Furniture.table(r, face(r, tx, 0, 0, 0, -1), 3.4, 3.4, WHITE)
		Furniture.chair(r, face(r, tx, 0, -2.6, 0, 1), rgb(200, 60, 50))
		Furniture.chair(r, face(r, tx, 0, 2.6, 0, -1), rgb(200, 60, 50))
	end
	Furniture.drinksCooler(r, face(r, W / 2 - 1.3, 0, -8, -1, 0))
	counter(r, r.at(-36, 0, 0), 8, rgb(30, 60, 110))
	sign(r, "INFORMACIÓN", V(8, 1.4, 0.2), r.at(-36, 6, -1.4), rgb(30, 60, 110))
	Builder.part({ Name = "ClerkSpot", Size = V(2, 2, 2), CFrame = r.at(-36, 0, 2.6) * ANG(0, PI, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = { "ClerkSpot" }, Parent = r.Model })
	elevator(r, W / 2 - 6, 0, math.rad(-90))
	return r
end

---------------------------------------------------------------------
-- Instituciones del Estado (siempre montadas: sus oficios y servicios usan sus etiquetas)
---------------------------------------------------------------------
local function cabinet(r: Room, cf: CFrame): BasePart
	local c = solid(r, "Archivo", V(3, 6, 2), cf * CF(0, 3, 0), STEEL, M.Metal)
	for k = 0, 2 do
		bit(r, "Drawer", V(2.6, 1.4, 0.1), cf * CF(0, 1.2 + k * 1.8, -1.02), rgb(170, 176, 184), M.Metal)
	end
	return c
end

local function jobBoard(r: Room, cf: CFrame, jobId: string, title: string)
	for _, x in { -1.9, 1.9 } do
		bit(r, "Post", V(0.3, 6.5, 0.3), cf * CF(x, 3.25, 0), STEEL, M.Metal)
	end
	local board = Builder.part({ Name = "Board", Size = V(4.4, 3, 0.3), CFrame = cf * CF(0, 4.8, 0), Color = rgb(34, 108, 196), Tags = { "JobBoard" }, Attributes = { JobId = jobId }, Parent = r.Model })
	Builder.sign(board, "SE BUSCA\n" .. title, Enum.NormalId.Front)
	Builder.sign(board, "SE BUSCA\n" .. title, Enum.NormalId.Back)
end

local function flag(r: Room, cf: CFrame)
	bit(r, "FlagPole", V(0.4, 12, 0.4), cf * CF(0, 6, 0), STEEL, M.Metal)
	for i, color in { rgb(200, 40, 40), rgb(240, 200, 40), rgb(200, 40, 40) } do
		bit(r, "Flag", V(4, 0.9, 0.1), cf * CF(2.2, 11.4 - i * 0.9, 0), color, M.Fabric)
	end
end

function Interiors.Juzgado(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Juzgado", cf, 64, 56, 20, { Floor = rgb(150, 110, 80), FloorMaterial = M.WoodPlanks, Wall = rgb(214, 204, 186), LightKind = "Chandelier", Curtains = rgb(90, 30, 40) }, opts)
	local back = r.D / 2
	solid(r, "Estrado", V(22, 2, 8), r.at(0, 1, back - 6), DARKWOOD, M.Wood)
	solid(r, "JudgeBench", V(16, 3.6, 2.4), r.at(0, 3.8, back - 8.5), rgb(96, 60, 38), M.Wood, { Tags = { "Dropoff_Juez" } })
	spot(r, "JudgeSpot", r.at(0, 4, back - 5) * ANG(0, PI, 0), { "CourtJudge" })
	bit(r, "JudgeChair", V(2.4, 5, 2.2), r.at(0, 4.5, back - 4.2), rgb(90, 30, 40), M.Fabric)
	bit(r, "Gavel", V(0.4, 0.4, 1.2), r.at(1.5, 5.8, back - 8.8), DARKWOOD, M.Wood)
	sign(r, "⚖\nJUSTICIA", V(8, 5, 0.2), r.at(0, 12, back - 0.4) * ANG(0, PI, 0), rgb(90, 30, 40), rgb(240, 210, 120))
	flag(r, r.at(-9, 2, back - 2))
	solid(r, "Banquillo", V(5, 2.2, 2), r.at(0, 1.1, 2), DARKWOOD, M.Wood)
	spot(r, "DockSpot", r.at(0, 3, 0.5), { "CourtDock" })
	for _, x in { -12, 12 } do
		bit(r, "PartyTable", V(8, 3, 3), r.at(x, 1.5, 4), WOOD, M.Wood)
		bit(r, "Folders", V(1.4, 0.3, 1), r.at(x - 2, 3.15, 4), rgb(200, 180, 120))
		cyl_(r, x + 2, 4)
		seat(r, r.at(x, 0, 1.5) * ANG(0, PI, 0), DARK)
	end
	for row = 0, 2 do
		for _, x in { -14, 14 } do
			for k = -2, 2 do
				seat(r, r.at(x + k * 2.6, 0, -r.D / 2 + 7 + row * 4) * ANG(0, PI, 0), DARKWOOD)
			end
		end
	end
	for k = 0, 2 do
		cabinet(r, r.at(-r.W / 2 + 2, 0, -4 + k * 4) * ANG(0, math.rad(90), 0)):AddTag("Pickup_Juez")
	end
	-- Biblioteca de leyes, plantas y reloj
	Furniture.bookshelf(r, face(r, r.W / 2 - 1, 0, 8, -1, 0), 8, 9)
	Furniture.bookshelf(r, face(r, r.W / 2 - 1, 0, -9, -1, 0), 8, 9)
	for _, p in { { -r.W / 2 + 3, back - 3 }, { r.W / 2 - 3, back - 3 } } do
		Furniture.plant(r, r.at(p[1], 0, p[2]), 1.5)
	end
	Furniture.clock(r, face(r, -12, 12, back, 0, -1))
	Furniture.waterCooler(r, face(r, -r.W / 2 + 1.2, 0, -r.D / 2 + 4, 1, 0))
	jobBoard(r, r.at(r.W / 2 - 6, 0, -r.D / 2 + 5), "Juez", "JUZGADOS")
	return r
end

-- (jarra de agua y vaso sobre las mesas del juicio)
function cyl_(r: Room, x: number, z: number)
	Furniture.cyl(r.Model, "Jug", 1, 0.6, r.at(x, 3.5, z), rgb(200, 225, 240), M.Glass)
	Furniture.cyl(r.Model, "Glass", 0.5, 0.4, r.at(x + 0.7, 3.25, z), rgb(200, 225, 240), M.Glass)
end

function Interiors.Hacienda(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Hacienda", cf, 60, 44, 14, { Floor = rgb(200, 204, 210), FloorMaterial = M.Marble }, opts)
	local front, back = -r.D / 2, r.D / 2
	solid(r, "TaxWindow", V(16, 3.6, 2.4), r.at(0, 1.8, front + 10), rgb(30, 90, 110), nil, { Tags = { "TaxWindow" } })
	bit(r, "WindowGlass", V(16, 3, 0.12), r.at(0, 5.2, front + 9.4), rgb(200, 225, 240), M.Glass, 0.6)
	sign(r, "DECLARACIÓN DE LA RENTA", V(12, 1.4, 0.2), r.at(0, 8, front + 10.6) * ANG(0, PI, 0), rgb(30, 90, 110))
	-- Sala de espera (a los lados de la entrada)
	for row = 0, 1 do
		for k = 0, 3 do
			seat(r, r.at(-r.W / 2 + 4 + k * 3, 0, front + 3 + row * 4) * ANG(0, PI, 0), rgb(30, 90, 110))
		end
	end
	bit(r, "TicketMachine", V(1.6, 4.4, 1.2), r.at(r.W / 2 - 4, 2.2, front + 3), rgb(30, 90, 110))
	bit(r, "TicketScreen", V(1.2, 0.8, 0.1), r.at(r.W / 2 - 4, 3.6, front + 3.65), rgb(80, 200, 255), M.Neon)
	for k = 0, 2 do
		Furniture.desk(r, face(r, -r.W / 2 + 12 + k * 16, 0, back - 8, 0, -1) * ANG(0, PI, 0), { Computer = true }):AddTag("Dropoff_Hacienda")
	end
	for k = 0, 2 do
		cabinet(r, r.at(r.W / 2 - 2, 0, front + 18 + k * 4) * ANG(0, math.rad(-90), 0)):AddTag("Pickup_Hacienda")
	end
	local board = solid(r, "TreasuryBoard", V(12, 4, 0.3), r.at(-r.W / 4, 8, back - 0.4) * ANG(0, PI, 0), rgb(20, 30, 40), nil, { Tags = { "TreasuryBoard" } })
	Builder.sign(board, "TESORO PÚBLICO\n$0 recaudados", Enum.NormalId.Front, rgb(120, 230, 160))
	Furniture.printer(r, face(r, r.W / 2 - 6, 0, back - 1.2, 0, -1))
	Furniture.waterCooler(r, face(r, -r.W / 2 + 1.2, 0, back - 4, 1, 0))
	for _, p in { { -r.W / 2 + 2, back - 2 }, { r.W / 2 - 2, front + 2 } } do
		Furniture.plant(r, r.at(p[1], 0, p[2]), 1.4)
	end
	Furniture.clock(r, face(r, 0, 10, back, 0, -1))
	jobBoard(r, r.at(r.W / 2 - 6, 0, front + 5), "Hacienda", "AGENCIA TRIBUTARIA")
	return r
end

function Interiors.Cuartel(parent: Instance, cf: CFrame, opts: Options?): Room
	local r = room(parent, "Cuartel", cf, 90, 70, 18, { Floor = rgb(150, 140, 110), FloorMaterial = M.Concrete, Wall = rgb(200, 196, 170), Windows = false, LightKind = "Panel", Baseboards = false }, opts)
	local front, back = -r.D / 2, r.D / 2
	-- Armería
	solid(r, "Armeria", V(14, 3.6, 3), r.at(-r.W / 2 + 10, 1.8, front + 8), rgb(70, 76, 60), M.Metal, { Tags = { "Pickup_Militar" } })
	sign(r, "ARMERÍA", V(8, 1.2, 0.2), r.at(-r.W / 2 + 10, 6, front + 6.4) * ANG(0, PI, 0), rgb(70, 90, 50))
	for k = 0, 5 do
		bit(r, "RifleRack", V(0.3, 3, 0.3), r.at(-r.W / 2 + 4.5 + k * 2.2, 5, front + 9.4) * ANG(0, 0, 0.1), rgb(50, 54, 44), M.Metal)
	end
	-- Puestos de guardia e instrucción (circuito cubierto)
	for k, p in { { -25, 0 }, { -25, 20 }, { 25, 20 }, { 25, 0 } } do
		bit(r, "Pad", V(8, 0.2, 8), r.at(p[1], 0.1, p[2]), rgb(200, 180, 60))
		spot(r, "TrainingPost", r.at(p[1], 3, p[2]), { "Dropoff_Militar" }, { Step = k })
		bit(r, "Hurdle", V(6, 2.4, 0.5), r.at(p[1], 1.2, p[2] + 6), rgb(150, 110, 70), M.Wood)
	end
	spot(r, "GuardPost", r.at(-6, 3, front + 5), { "Dropoff_Militar" })
	spot(r, "GuardPost", r.at(6, 3, front + 5), { "Dropoff_Militar" })
	-- Galería de tiro
	for k = 0, 3 do
		bit(r, "Target", V(3, 4, 0.3), r.at(r.W / 2 - 4, 4, -12 + k * 6) * ANG(0, math.rad(90), 0), rgb(240, 240, 240))
		bit(r, "Bullseye", V(1.2, 1.2, 0.35), r.at(r.W / 2 - 4, 4.4, -12 + k * 6) * ANG(0, math.rad(90), 0), rgb(220, 40, 40))
		bit(r, "Sandbags", V(2, 1.4, 4), r.at(r.W / 2 - 18, 0.7, -12 + k * 6), rgb(170, 150, 110), M.Fabric)
	end
	-- Dormitorio de tropa: literas con manta y almohada (se puede tumbar), taquillas
	for k = 0, 5 do
		local x = -30 + k * 7
		local bunk = Furniture.group(r.Model, "Bunk")
		Furniture.solid(bunk, "BunkFrame", V(4, 0.6, 8), r.at(x, 1.4, back - 5), rgb(70, 80, 60), M.Metal)
		local mattress = Furniture.solid(bunk, "Mattress", V(3.6, 0.6, 7.6), r.at(x, 2, back - 5), rgb(86, 100, 62), M.Fabric)
		Furniture.usable(mattress, "Bed")
		Furniture.deco(bunk, "Pillow", V(2.6, 0.5, 1.2), r.at(x, 2.5, back - 1.8), WHITE, M.Fabric)
		Furniture.deco(bunk, "UpperBunk", V(4, 0.6, 8), r.at(x, 5.4, back - 5), rgb(86, 100, 62), M.Fabric)
		for _, sx in { -1.9, 1.9 } do
			Furniture.deco(bunk, "BunkPost", V(0.25, 6, 0.25), r.at(x + sx, 3, back - 1.1), rgb(70, 80, 60), M.Metal)
			Furniture.deco(bunk, "BunkPost", V(0.25, 6, 0.25), r.at(x + sx, 3, back - 8.9), rgb(70, 80, 60), M.Metal)
		end
	end
	Furniture.lockers(r, face(r, 16, 0, back - 1.1, 0, -1), 8, rgb(80, 90, 60))
	-- Comedor de tropa y sala de mando
	for k = 0, 1 do
		local tz = front + 20 + k * 9
		Furniture.table(r, face(r, -8, 0, tz, 0, -1), 10, 3, rgb(120, 110, 90))
		Furniture.bench(r, face(r, -8, 0, tz - 2.6, 0, 1), 9, rgb(90, 80, 60))
		Furniture.bench(r, face(r, -8, 0, tz + 2.6, 0, -1), 9, rgb(90, 80, 60))
	end
	bit(r, "MapTable", V(12, 3, 8), r.at(0, 1.5, back - 18), rgb(70, 90, 50))
	bit(r, "Map", V(11, 0.1, 7), r.at(0, 3.06, back - 18), rgb(120, 170, 110))
	for k = 0, 3 do
		bit(r, "MapPin", V(0.3, 0.6, 0.3), r.at(-3 + k * 2, 3.4, back - 18 + (k % 2) * 2), rgb(220, 40, 40))
	end
	flag(r, r.at(0, 0, back - 1.5))
	sign(r, "CUARTEL DEL EJÉRCITO DE VALMAR", V(30, 2.6, 0.2), r.at(0, 14, back - 0.2) * ANG(0, PI, 0), rgb(70, 90, 50))
	Furniture.waterCooler(r, face(r, r.W / 2 - 1.2, 0, front + 12, -1, 0))
	Furniture.clock(r, face(r, -20, 12, back, 0, -1))
	jobBoard(r, r.at(r.W / 2 - 8, 0, front + 5), "Militar", "EJÉRCITO")
	return r
end

-- Tipos de interior de las plantas de arriba según la sala de la planta baja
Interiors.UpperFloor = {
	Portal = "Piso",
	Local = "Piso",
	OficinaLobby = "Oficina",
	Aula = "Aula",
	CentroComercial = "Local",
}

-- Tipos que son viviendas (con dormitorio, baño y cocina)
Interiors.Homes = { Casa = true, Villa = true, Piso = true }

return Interiors
