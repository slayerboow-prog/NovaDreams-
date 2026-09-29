-- Tower: los edificios de varias plantas por dentro, una planta encima de otra (InteriorService).
--
-- Cada planta (Floors: medidas y puertas):
--   ┌──────────┬──────────────────────────────────────────┐ z = +10
--   │ escalera │                                          │
--   │ ↑    ↓   │   (detrás: las viviendas u oficinas de   │
--   │ ↑ ▌▌ ↓   │    este lado; se entra por su puerta)    │
--   │ ↑    ↓   ├──[ascensor]──[3ºC]──────[3ºD]───────────┤ z = -4
--   │ rellano  │   pasillo                           ventana
--   └──────────┴────[3ºA]──────[3ºB]──────[3ºE]──────────┘ z = -10
--   x = -W/2   -W/2+10                                 W/2
--
--   * Escalera de verdad: tramo que sube hacia el fondo (+Z), descansillo a media altura y tramo
--     de vuelta que llega al rellano de la planta de arriba. Escalones de 0,75 studs (se suben
--     andando), barandillas y el número de la planta en la pared.
--   * Pasillo con las puertas numeradas (con bisagra, placa con el nombre y felpudo). Detrás de cada
--     puerta hay una sala aparte (su piso, oficina, aula o local) que se monta al entrar.
--   * La planta baja es el portal: puerta a la calle, buzones o recepción.
-- Se monta planta a planta: InteriorService solo tiene montadas las plantas cerca de los jugadores.

local Builder = require(script.Parent.Builder)
local Furniture = require(script.Parent.Furniture)
local Lift = require(script.Parent.Lift)
local Floors = require(game:GetService("ReplicatedStorage").Shared.Floors)

local Tower = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local ANG = CFrame.Angles
local PI = math.pi
local M = Enum.Material

local FH = Floors.Height
local CORE = Floors.CoreWidth
local HALF_D = Floors.Depth / 2
local CORRIDOR_Z0, CORRIDOR_Z1 = -HALF_D, -HALF_D + Floors.CorridorWidth -- pasillo: z entre -10 y -4
local DOOR_W, DOOR_H = 3.6, 8
local FIRE_DOOR_W: number, EMERGENCY_W: number -- (se fijan más abajo)
local emergencyStair, corridorDetails -- (se definen más abajo)

export type Door = { Unit: Floors.Unit, CFrame: CFrame, Front: boolean } -- CFrame: en el suelo, mirando al pasillo
export type Plan = {
	Key: string, -- clave del edificio
	Title: string,
	Ground: string, -- sala de la planta baja (Portal, Local, OficinaLobby, Aula, CentroComercial, Walk)
	Upper: string,
	Top: number, -- última planta
	W: number,
	Style: { [string]: any },
}

-- Estilos por distrito (shared/Floors.themeFor): colores del portal y los pasillos y sus detalles.
--   Lujo (Oeste): mármol claro, puertas oscuras, barandillas doradas, alfombra en el pasillo,
--     lámpara de araña y espejo en el portal.
--   Clásico (Centro): suelo de madera, zócalo alto de madera, barandillas de hierro.
--   Moderno (Este, algo del Centro): gris claro, puertas blancas, tira de luz en el pasillo.
--   Familiar (Norte, Este): colores cálidos, macetas y el tablón de la comunidad.
--   Joven (Universitario): paredes de color, tablón con carteles y aparcabicis en el portal.
--   Obrero (Sur): terrazo, pared pintada a media altura, barandilla sencilla y el tablón.
-- (Las oficinas tienen siempre su estilo de oficina.)
Tower.Themes = {
	Lujo = {
		Wall = rgb(236, 228, 212), Floor = rgb(232, 230, 226), FloorMaterial = M.Marble, Door = rgb(60, 40, 30),
		Stair = rgb(226, 222, 214), Rail = rgb(200, 164, 80), Accent = rgb(130, 30, 40),
		Details = { "Runner", "Chandelier", "Mirror" },
	},
	Clasico = {
		Wall = rgb(226, 214, 190), Floor = rgb(150, 110, 76), FloorMaterial = M.WoodPlanks, Door = rgb(96, 64, 40),
		Stair = rgb(170, 160, 150), Rail = rgb(40, 42, 46), Accent = rgb(110, 76, 50),
		Details = { "Wainscot" },
	},
	Moderno = {
		Wall = rgb(232, 234, 236), Floor = rgb(170, 172, 176), FloorMaterial = M.Slate, Door = rgb(245, 245, 242),
		Stair = rgb(200, 200, 204), Rail = rgb(200, 204, 210), Accent = rgb(120, 200, 255),
		Details = { "LedStrip" },
	},
	Familiar = {
		Wall = rgb(240, 222, 196), Floor = rgb(186, 176, 160), FloorMaterial = M.Slate, Door = rgb(150, 110, 76),
		Stair = rgb(186, 176, 160), Rail = rgb(150, 110, 76), Accent = rgb(90, 140, 80),
		Details = { "Pots", "Board" },
	},
	Joven = {
		Wall = rgb(250, 214, 120), Floor = rgb(200, 196, 188), FloorMaterial = M.Concrete, Door = rgb(60, 120, 170),
		Stair = rgb(160, 150, 140), Rail = rgb(220, 90, 60), Accent = rgb(220, 90, 60),
		Details = { "Board", "BikeRack" },
	},
	Obrero = {
		Wall = rgb(214, 222, 200), Floor = rgb(170, 160, 150), FloorMaterial = M.Granite, Door = rgb(120, 84, 56),
		Stair = rgb(160, 150, 140), Rail = rgb(90, 96, 100), Accent = rgb(110, 140, 110),
		Details = { "Wainscot", "Board" },
	},
}

-- Cómo es el edificio (ancho según la planta con más puertas, colores fijos). district: el Id del
-- distrito (CityPlan.Districts) para el estilo del portal y los pasillos; sin él, colores al azar.
function Tower.plan(key: string, title: string, ground: string, upper: string, floors: number, district: string?): Plan
	local most = 0
	for f = 0, math.min(floors - 1, 40) do
		most = math.max(most, #Floors.units(key, ground, upper, f))
	end
	local rand = Furniture.rng(key .. ":torre")
	local office = upper == "Oficina"
	local style: { [string]: any } = {
		Wall = if office then rgb(236, 236, 232) else rand.pick(Furniture.Palette.Walls),
		Floor = if office then rgb(120, 126, 140) else rand.pick({ rgb(200, 196, 188), rgb(186, 176, 160), rgb(170, 160, 150), rgb(214, 208, 196) }),
		FloorMaterial = if office then M.Carpet else rand.pick({ M.Marble, M.Slate, M.WoodPlanks }),
		Door = rand.pick({ rgb(96, 64, 40), rgb(150, 110, 76), rgb(240, 240, 236), rgb(70, 50, 36), rgb(120, 84, 56) }),
		Stair = rand.pick({ rgb(200, 196, 188), rgb(160, 150, 140), rgb(150, 110, 76) }),
		Rail = rand.pick({ rgb(40, 42, 46), rgb(200, 204, 210), rgb(150, 110, 76) }),
		Details = {},
	}
	local theme = if office then nil else Floors.themeFor(district, key)
	local t = theme and Tower.Themes[theme]
	if t then
		for k, v in t do
			style[k] = v
		end
		style.Theme = theme
	end
	return {
		Key = key,
		Title = title,
		Ground = ground,
		Upper = upper,
		Top = floors - 1,
		W = Floors.width(most),
		Style = style,
	}
end

-- Camino por la escalera principal de una planta a otra (en coordenadas del edificio: se multiplica
-- por el origen de la torre), a la altura de los pies
function Tower.stairRoute(plan: Plan, from: number, to: number): { Vector3 }
	local out = {}
	for _, p in Floors.stairPath(plan.W, from, to) do
		table.insert(out, V(p.X, p.Y, p.Z))
	end
	return out
end

-- Las puertas de una planta: la mitad en la pared de fuera (-Z), el resto en la de dentro
function Tower.doors(plan: Plan, floor: number): { Door }
	local out = {}
	local W = plan.W
	local units = Floors.units(plan.Key, plan.Ground, plan.Upper, floor)
	-- (en la planta baja, todas en la pared de dentro: la de fuera tiene la puerta de la calle)
	local front = if floor == 0 then 0 else math.ceil(#units / 2)
	for i, unit in units do
		if i <= front then
			local x = -W / 2 + CORE + 5 + (i - 1) * Floors.DoorSpacing
			table.insert(out, { Unit = unit, CFrame = CF(x, 0, CORRIDOR_Z0) * ANG(0, PI, 0), Front = true })
		else
			local x = -W / 2 + CORE + 12 + (i - front - 1) * Floors.DoorSpacing
			table.insert(out, { Unit = unit, CFrame = CF(x, 0, CORRIDOR_Z1), Front = false })
		end
	end
	return out
end

-- Dónde se aparece al llegar a una planta (en el rellano, mirando al pasillo) y dónde está el ascensor
function Tower.landing(plan: Plan, floor: number): CFrame
	return CF(-plan.W / 2 + CORE / 2, floor * FH + 3, (CORRIDOR_Z0 + CORRIDOR_Z1) / 2) * ANG(0, -PI / 2, 0)
end

function Tower.elevatorAt(plan: Plan, floor: number): CFrame
	return CF(-plan.W / 2 + CORE + 4.5, floor * FH, CORRIDOR_Z1)
end

-- El suelo del hueco del ascensor en la planta baja (detrás de la pared del pasillo; -Z = hacia el
-- pasillo). Relativo al edificio: towerCf * Tower.shaftBase(plan)
function Tower.shaftBase(plan: Plan): CFrame
	local ex = Tower.elevatorAt(plan, 0).Position.X
	return CF(ex, 0, CORRIDOR_Z1 + 0.6 + Lift.Depth / 2)
end

-- Delante de una puerta, en el pasillo
function Tower.doorFront(plan: Plan, floor: number, letter: string): CFrame?
	for _, d in Tower.doors(plan, floor) do
		if d.Unit.Letter == letter then
			local cf = CF(0, floor * FH, 0) * d.CFrame
			return cf * CF(0, 3, -2.2) * ANG(0, PI, 0)
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Piezas
---------------------------------------------------------------------
local function solid(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	return Builder.part({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or M.SmoothPlastic, CanTouch = false, Parent = parent })
end

local function deco(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): BasePart
	return Builder.decor({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or M.SmoothPlastic, Parent = parent })
end

-- Pared a lo largo de X (en z) con huecos de puerta en xs
local function wallX(parent: Instance, at: (number, number, number) -> CFrame, z: number, x0: number, x1: number, gaps: { number }, gapW: number, gapH: number, color: Color3)
	table.sort(gaps)
	local x = x0
	local function piece(a: number, b: number)
		if b - a > 0.05 then
			solid(parent, "Wall", V(b - a, FH, 0.6), at((a + b) / 2, FH / 2, z), color)
		end
	end
	for _, gx in gaps do
		piece(x, gx - gapW / 2)
		solid(parent, "Lintel", V(gapW, FH - gapH, 0.6), at(gx, gapH + (FH - gapH) / 2, z), color)
		x = gx + gapW / 2
	end
	piece(x, x1)
end

local function plateText(label: string, name: string?): string
	return if name and name ~= "" then label .. "\n" .. name else label
end

-- Puerta de una vivienda u oficina (la hoja gira en su bisagra al entrar; el cartel lo pone
-- InteriorService según quién vive: "Entrar", "Llamar", "Visitar"…)
local function unitDoor(parent: Instance, plan: Plan, floor: number, door: Door, cf: CFrame, name: string?)
	local m = Instance.new("Model")
	m.Name = "UnitDoor_" .. door.Unit.Id
	m.Parent = parent
	local closed = cf * CF(0, DOOR_H / 2, 0)
	local panel = solid(m, "DoorPanel", V(DOOR_W - 0.1, DOOR_H - 0.1, 0.3), closed, plan.Style.Door, M.Wood)
	panel:AddTag("UnitDoor")
	panel:SetAttribute("Floor", floor)
	panel:SetAttribute("Letter", door.Unit.Letter)
	panel:SetAttribute("UnitId", door.Unit.Id)
	panel:SetAttribute("Label", door.Unit.Label)
	panel:SetAttribute("Hinge", cf * CF(-DOOR_W / 2, DOOR_H / 2, 0))
	panel:SetAttribute("Closed", closed)
	panel:SetAttribute("Swing", math.rad(-95)) -- (se abre hacia dentro)
	local knob = deco(m, "DoorKnob", V(0.3, 0.3, 0.6), closed * CF(DOOR_W / 2 - 0.5, -0.4, 0), rgb(210, 190, 120), M.Metal)
	knob:SetAttribute("FollowDoor", "DoorPanel")
	deco(m, "Peephole", V(0.2, 0.2, 0.35), closed * CF(0, 1.2, 0), rgb(40, 40, 44), M.Metal):SetAttribute("FollowDoor", "DoorPanel")
	for _, x in { -DOOR_W / 2 - 0.15, DOOR_W / 2 + 0.15 } do
		deco(m, "DoorFrame", V(0.3, DOOR_H, 0.8), cf * CF(x, DOOR_H / 2, 0), rgb(240, 240, 236))
	end
	deco(m, "DoorFrame", V(DOOR_W + 0.6, 0.3, 0.8), cf * CF(0, DOOR_H + 0.15, 0), rgb(240, 240, 236))
	-- Placa con el número y el nombre (hacia el pasillo = -Z de cf)
	local plate = deco(m, "NamePlate", V(2.6, 1.3, 0.1), cf * CF(DOOR_W / 2 + 1.7, 5.6, -0.4), rgb(200, 180, 120), M.Metal)
	plate:SetAttribute("UnitId", door.Unit.Id)
	local label = Builder.sign(plate, plateText(door.Unit.Label, name), Enum.NormalId.Front, rgb(30, 30, 34))
	label.Name = "PlateText"
	deco(m, "Doormat", V(3, 0.08, 1.8), cf * CF(0, 0.05, -1.3), rgb(120, 90, 60), M.Fabric)
	deco(m, "Doorbell", V(0.3, 0.4, 0.1), cf * CF(DOOR_W / 2 + 0.7, 4.5, -0.35), rgb(236, 236, 230))
	return panel
end

-- Escalera de una planta a la siguiente, en un hueco de ancho CORE que empieza en x0 (la principal,
-- a la izquierda: x0 = -W/2; la de emergencia, al final del pasillo)
local function stairs(parent: Instance, plan: Plan, at: (number, number, number) -> CFrame, x0: number?, color0: Color3?)
	local W = plan.W
	local left = x0 or -W / 2
	local laneW = CORE / 2 - 0.4
	local lanes = { left + CORE - laneW / 2, left + laneW / 2 } -- tramo 1 (sube hacia +Z), tramo 2 (vuelve)
	local color = color0 or plan.Style.Stair
	for i, s in Floors.steps() do
		local step = solid(parent, "Step", V(laneW, Floors.StepRise, Floors.StepRun), at(lanes[s.Lane], s.Y - Floors.StepRise / 2, s.Z), color, M.Concrete)
		step:SetAttribute(if x0 then "EmergencyStep" else "Step", i)
		deco(parent, "Nosing", V(laneW, 0.08, 0.15), at(lanes[s.Lane], s.Y + 0.02, s.Z - (if s.Lane == 1 then 0.45 else -0.45)), rgb(60, 60, 64))
	end
	local half = Floors.StepsPerFlight * Floors.StepRise
	local zf = Floors.StepsPerFlight * Floors.StepRun / 2 -- los tramos van de z = -zf a +zf
	-- Descansillo a media altura (al fondo)
	local landing = solid(parent, "MidLanding", V(CORE, 1, HALF_D - zf), at(left + CORE / 2, half - 0.5, (zf + HALF_D) / 2), color, M.Concrete)
	landing:SetAttribute("Landing", "Mid")
	-- Muro entre los dos tramos y pasamanos
	solid(parent, "StairDivider", V(0.8, FH, zf * 2), at(left + CORE / 2, FH / 2, 0), plan.Style.Wall)
	for _, side in { -1, 1 } do
		local x = left + CORE / 2 + side * 0.55
		-- Pasamanos inclinado (sube con el tramo)
		local rise = half
		local length = math.sqrt((zf * 2) ^ 2 + rise ^ 2)
		local slope = math.atan2(rise, zf * 2)
		local base = if side > 0 then 0 else half
		local tilt = if side > 0 then -slope else slope
		deco(parent, "Handrail", V(0.2, 0.2, length), at(x, base + rise / 2 + 3, 0) * ANG(tilt, 0, 0), plan.Style.Rail, M.Metal)
	end
end

---------------------------------------------------------------------
-- Escalera de emergencia (al final del pasillo, tras la puerta cortafuegos) y detalles del pasillo
---------------------------------------------------------------------
FIRE_DOOR_W = 3.8
EMERGENCY_W = CORE + 0.6 -- lo que ocupa la escalera de emergencia más allá del pasillo

local function exitSign(parent: Instance, cf: CFrame, text: string)
	local sign = deco(parent, "ExitSign", V(2.6, 0.9, 0.15), cf, rgb(20, 150, 70), M.Neon)
	Builder.sign(sign, text, Enum.NormalId.Front, rgb(255, 255, 255))
	return sign
end

emergencyStair = function(m: Model, plan: Plan, floor: number, at: (number, number, number) -> CFrame, ctx: any)
	local W = plan.W
	local x0 = W / 2 + 0.6 -- empieza detrás de la pared del fondo
	local fz = (CORRIDOR_Z0 + CORRIDOR_Z1) / 2
	local grey = rgb(170, 172, 176)
	local top = floor == plan.Top
	-- Puerta cortafuegos (roja, con barra antipánico) y su cartel verde de salida
	local door = Furniture.door(ctx, at(W / 2 + 0.3, 0, fz) * ANG(0, -PI / 2, 0), FIRE_DOOR_W, DOOR_H, rgb(170, 40, 34), false, m, true)
	door:AddTag("FireDoor")
	deco(m, "PanicBar", V(0.2, 0.2, FIRE_DOOR_W - 0.8), at(W / 2 - 0.05, 3.4, fz), rgb(200, 200, 205), M.Metal)
	exitSign(m, at(W / 2 - 0.1, DOOR_H + 1, fz) * ANG(0, -PI / 2, 0), "🏃 SALIDA DE EMERGENCIA")
	-- Suelo del rellano (y en la planta baja, todo el hueco)
	if floor == 0 then
		solid(m, "EmergencyFloor", V(CORE, 1, HALF_D * 2), at(x0 + CORE / 2, -0.5, 0), grey, M.Concrete)
	else
		solid(m, "EmergencyLanding", V(CORE, 1, CORRIDOR_Z1 - CORRIDOR_Z0), at(x0 + CORE / 2, -0.5, fz), grey, M.Concrete):SetAttribute("Landing", "Floor")
	end
	-- Paredes del hueco
	solid(m, "EmergencyOuter", V(0.6, FH, HALF_D * 2 + 0.6), at(x0 + CORE + 0.3, FH / 2, 0), plan.Style.Wall)
	solid(m, "EmergencyBack", V(CORE + 0.6, FH, 0.6), at(x0 + CORE / 2, FH / 2, HALF_D + 0.3), plan.Style.Wall)
	solid(m, "EmergencyFront", V(CORE + 0.6, FH, 0.6), at(x0 + CORE / 2, FH / 2, -HALF_D - 0.3), plan.Style.Wall)
	solid(m, "EmergencyInner", V(0.6, FH, HALF_D - CORRIDOR_Z1 + 0.6), at(W / 2 + 0.3, FH / 2, (CORRIDOR_Z1 + HALF_D) / 2), plan.Style.Wall)
	if not top then
		stairs(m, plan, at, x0, grey)
	else
		local laneW = CORE / 2 - 0.4
		local zf = Floors.StepsPerFlight * Floors.StepRun / 2
		solid(m, "StairRail", V(laneW, 3.4, 0.25), at(x0 + CORE - laneW / 2, 1.7, -zf + 0.15), plan.Style.Rail, M.Metal)
		solid(m, "StairRail", V(0.8, 3.4, zf * 2), at(x0 + CORE / 2, 1.7, 0), plan.Style.Rail, M.Metal)
	end
	-- Luz de emergencia (siempre encendida, verdosa) y el número de la planta
	local lamp = deco(m, "EmergencyLight", V(1.4, 0.3, 0.5), at(x0 + CORE / 2, FH - 0.6, fz), rgb(230, 255, 230), M.Neon)
	local light = Instance.new("PointLight")
	light.Range = 14
	light.Brightness = 0.7
	light.Color = rgb(200, 255, 210)
	light.Parent = lamp
	local label = if floor == 0 then "PB · SALIDA" else ("PLANTA %d"):format(floor)
	local plate = deco(m, "EmergencyFloorSign", V(0.15, 1.4, 4), at(x0 + CORE + 0.05, 5.5, fz), rgb(20, 150, 70))
	Builder.sign(plate, label, Enum.NormalId.Left, rgb(255, 255, 255))
	-- En la planta baja: la puerta a la calle
	if floor == 0 then
		local exit = solid(m, "EmergencyExit", V(0.6, DOOR_H, FIRE_DOOR_W), at(x0 + CORE + 0.3, DOOR_H / 2, fz), rgb(170, 40, 34), M.Metal)
		exit:AddTag("InteriorExit")
		exitSign(m, at(x0 + CORE - 0.1, DOOR_H + 1, fz) * ANG(0, PI / 2, 0), "🏃 SALIDA A LA CALLE")
	end
end

-- Detalles del pasillo: detectores de humo, cámara, cuadro eléctrico, cuadros, papelera, plano de
-- evacuación… (cada planta a su manera: el mismo edificio siempre igual)
corridorDetails = function(m: Model, plan: Plan, floor: number, at: (number, number, number) -> CFrame, ctx: any, doors: { Door })
	local W = plan.W
	local rand = ctx.Rand
	local fz = (CORRIDOR_Z0 + CORRIDOR_Z1) / 2
	local x0, x1 = -W / 2 + CORE + 2, W / 2 - 2
	-- Detectores de humo cada ~12 studs
	local n = math.max(1, math.floor((x1 - x0) / 12))
	for i = 1, n do
		deco(m, "SmokeDetector", V(0.7, 0.2, 0.7), at(x0 + (i - 0.5) * (x1 - x0) / n, FH - 0.1, fz + 1.2), rgb(245, 245, 245))
	end
	-- Cámara de seguridad (en la mitad de los edificios) y cuadro eléctrico junto a la escalera
	if Floors.hash("camara:" .. plan.Key) % 2 == 0 then
		deco(m, "SecurityCamera", V(0.5, 0.4, 0.9), at(W / 2 - 0.6, FH - 0.8, CORRIDOR_Z0 + 0.6) * ANG(-0.4, PI * 0.75, 0), rgb(40, 40, 44), M.Metal)
	end
	local panel = deco(m, "ElectricPanel", V(1.6, 2.2, 0.3), at(-W / 2 + CORE + 1.2, 6.6, CORRIDOR_Z0 + 0.2), rgb(150, 154, 160), M.Metal)
	Builder.sign(panel, "⚡", Enum.NormalId.Back, rgb(250, 210, 40))
	-- Plano de evacuación («Usted está aquí»)
	local evac = deco(m, "EvacuationPlan", V(2.4, 1.8, 0.1), at(-W / 2 + CORE + 1.6, 5.4, CORRIDOR_Z1 - 0.1), rgb(250, 250, 245))
	Builder.sign(evac, "PLANO DE EVACUACIÓN\n● Usted está aquí\n→ Salida al fondo", Enum.NormalId.Front, rgb(20, 120, 60))
	-- Cuadros entre las puertas (en los huecos de las paredes) y una papelera junto al ascensor
	if plan.Upper ~= "Oficina" or rand.chance(0.5) then
		local used = {}
		for _, d in doors do
			used[math.floor(d.CFrame.Position.X / 4)] = true
		end
		local placed = 0
		for x = x0 + 4, x1 - 4, 8 do
			if placed < 3 and not used[math.floor(x / 4)] and not used[math.floor(x / 4) + 1] and not used[math.floor(x / 4) - 1] and rand.chance(0.6) then
				Furniture.picture(ctx, at(x, 5.2, CORRIDOR_Z0) * ANG(0, PI, 0), 2.2, 1.6, m)
				placed += 1
			end
		end
	end
	deco(m, "Bin", V(0.9, 1.4, 0.9), at(Tower.elevatorAt(plan, 0).Position.X + 4.2, 0.7, CORRIDOR_Z1 - 0.6), rgb(90, 96, 100), M.Metal)
	-- Portal: portero automático junto a la puerta de la calle
	if floor == 0 then
		local sx = (-W / 2 + CORE + W / 2) / 2 + 4
		local intercom = deco(m, "Intercom", V(1, 1.6, 0.2), at(sx, 4.6, CORRIDOR_Z0 + 0.1), rgb(180, 184, 190), M.Metal)
		Builder.sign(intercom, "🔔", Enum.NormalId.Back, rgb(40, 40, 44))
	end
end

-- Los detalles del estilo del distrito (Tower.Themes): pocas piezas y sin colisión (móvil)
local function themeDetails(m: Model, plan: Plan, floor: number, at: (number, number, number) -> CFrame, ctx: any, doors: { Door })
	local style = plan.Style
	local details = style.Details or {}
	if #details == 0 then
		return
	end
	m:SetAttribute("Theme", style.Theme)
	local W = plan.W
	local fz = (CORRIDOR_Z0 + CORRIDOR_Z1) / 2
	local cx = (-W / 2 + CORE + W / 2) / 2 -- centro del pasillo
	local sx = cx -- (la puerta de la calle, en la planta baja)
	local accent = style.Accent or rgb(120, 90, 60)
	local ex = Tower.elevatorAt(plan, floor).Position.X
	-- Una banda a lo largo de una pared, cortada en los huecos de las puertas
	local function band(name: string, z: number, gaps: { { number } }, height: number, y: number)
		table.sort(gaps, function(a, b)
			return a[1] < b[1]
		end)
		local x = -W / 2 + CORE + 0.6
		local function piece(a: number, b: number)
			if b - a > 0.3 then
				deco(m, name, V(b - a, height, 0.08), at((a + b) / 2, y, z), accent, M.Wood)
			end
		end
		for _, g in gaps do
			piece(x, g[1])
			x = math.max(x, g[2])
		end
		piece(x, W / 2)
	end
	for _, detail in details do
		if detail == "Runner" then
			deco(m, "Runner", V(W - CORE - 3, 0.06, 2.6), at(cx, 0.03, fz), accent, M.Fabric)
		elseif detail == "LedStrip" then
			deco(m, "LedStrip", V(W - CORE - 3, 0.12, 0.3), at(cx, FH - 0.15, fz), accent, M.Neon)
		elseif detail == "Wainscot" then
			local front, back = {}, {}
			for _, d in doors do
				local x = d.CFrame.Position.X
				table.insert(if d.Front then front else back, { x - DOOR_W / 2 - 0.4, x + DOOR_W / 2 + 0.4 })
			end
			table.insert(back, { ex - 3.2, ex + 3.2 })
			if floor == 0 then
				table.insert(front, { sx - 3.4, sx + 3.4 })
			end
			band("Wainscot", CORRIDOR_Z0 + 0.05, front, 3.4, 1.7)
			band("Wainscot", CORRIDOR_Z1 - 0.05, back, 3.4, 1.7)
		elseif detail == "Pots" then
			Furniture.plant(ctx, at(-W / 2 + 1.4, 0, CORRIDOR_Z0 + 1.2), 0.8)
		elseif floor == 0 and detail == "Chandelier" then
			local lamp = deco(m, "Chandelier", V(2.4, 1.2, 2.4), at(sx, FH - 1.8, fz), rgb(250, 230, 170), M.Neon)
			local light = Instance.new("PointLight")
			light.Range = 18
			light.Brightness = 0.9
			light.Color = rgb(255, 236, 200)
			light.Parent = lamp
		elseif floor == 0 and detail == "Mirror" then
			deco(m, "LobbyMirror", V(4, 5.5, 0.1), at(sx - 7, 5, CORRIDOR_Z0 + 0.06), rgb(200, 220, 235), M.Glass).Transparency = 0.2
		elseif floor == 0 and detail == "Board" then
			local board = deco(m, "NoticeBoard", V(3, 2.2, 0.1), at(-W / 2 + CORE + 4.5, 5.2, CORRIDOR_Z0 + 0.06), rgb(180, 140, 90), M.Wood)
			local text = if style.Theme == "Joven"
				then "TABLÓN\n· Se busca compañero de piso\n· Clases de guitarra\n· Fiesta en el 3ºB (¡sin ruido!)"
				else "COMUNIDAD DE VECINOS\n· Reunión el jueves, 20:00\n· No dejéis bicis en el portal"
			Builder.sign(board, text, Enum.NormalId.Back, rgb(30, 30, 34))
		elseif floor == 0 and detail == "BikeRack" then
			deco(m, "BikeRack", V(4, 1.6, 0.3), at(W / 2 - 6, 0.8, CORRIDOR_Z1 - 0.6), rgb(90, 96, 100), M.Metal)
		end
	end
end

---------------------------------------------------------------------
-- Una planta
---------------------------------------------------------------------
export type Built = { Model: Model, Doors: { BasePart }, Parts: number }

function Tower.buildFloor(parent: Instance, towerCf: CFrame, plan: Plan, floor: number, names: { [string]: string }?): Built
	local W = plan.W
	local base = towerCf * CF(0, floor * FH, 0)
	local function at(x: number, y: number, z: number): CFrame
		return base * CF(x, y, z)
	end
	local m = Instance.new("Model")
	m.Name = "Planta_" .. floor
	m:SetAttribute("Floor", floor)
	local style = plan.Style
	local wall = style.Wall
	local top = floor == plan.Top
	local room = "Planta" .. floor
	local ctx = { Model = m, Rand = Furniture.rng(plan.Key .. ":planta" .. floor), Wood = rgb(150, 110, 76), Fabric = rgb(70, 90, 140), Accent = rgb(230, 190, 90) } :: any

	-- Suelo: rellano y pasillo (y en la planta baja, todo el hueco de la escalera)
	local slab = solid(m, "FloorSlab", V(W, 1, CORRIDOR_Z1 - CORRIDOR_Z0), at(0, -0.5, (CORRIDOR_Z0 + CORRIDOR_Z1) / 2), style.Floor, style.FloorMaterial)
	slab:SetAttribute("Landing", "Floor")
	if floor == 0 then
		solid(m, "CoreFloor", V(CORE, 1, HALF_D - CORRIDOR_Z1), at(-W / 2 + CORE / 2, -0.5, (CORRIDOR_Z1 + HALF_D) / 2), style.Floor, style.FloorMaterial)
	end
	-- Paredes de la escalera
	solid(m, "CoreBack", V(CORE, FH, 0.6), at(-W / 2 + CORE / 2, FH / 2, HALF_D + 0.3), wall)
	solid(m, "CoreLeft", V(0.6, FH, HALF_D * 2), at(-W / 2 - 0.3, FH / 2, 0), wall)
	solid(m, "CoreRight", V(0.6, FH, HALF_D - CORRIDOR_Z1), at(-W / 2 + CORE + 0.3, FH / 2, (CORRIDOR_Z1 + HALF_D) / 2), wall)
	if not top then
		stairs(m, plan, at)
	else
		-- Última planta: tejado y barandilla sobre el hueco
		solid(m, "Roof", V(W + EMERGENCY_W, 1, HALF_D * 2), at(EMERGENCY_W / 2, FH + 0.5, 0), rgb(236, 236, 232))
		-- (sobre el tramo que ya no sube, y a lo largo del muro de en medio: la bajada queda libre)
		local laneW = CORE / 2 - 0.4
		local zf = Floors.StepsPerFlight * Floors.StepRun / 2
		solid(m, "StairRail", V(laneW, 3.4, 0.25), at(-W / 2 + CORE - laneW / 2, 1.7, -zf + 0.15), style.Rail, M.Metal)
		solid(m, "StairRail", V(0.8, 3.4, zf * 2), at(-W / 2 + CORE / 2, 1.7, 0), style.Rail, M.Metal)
	end
	-- Paredes del pasillo con las puertas
	local doors = Tower.doors(plan, floor)
	local frontGaps, backGaps = {}, {}
	for _, d in doors do
		table.insert(if d.Front then frontGaps else backGaps, d.CFrame.Position.X)
	end
	local elevator = Tower.elevatorAt(plan, floor)
	table.insert(backGaps, elevator.Position.X)
	if floor == 0 then
		table.insert(frontGaps, (-W / 2 + CORE + W / 2) / 2 + 0.01) -- la puerta de la calle (en medio)
	end
	if floor == 0 then
		wallX(m, at, CORRIDOR_Z0 - 0.3, -W / 2, W / 2, frontGaps, 6, 9, wall)
	else
		wallX(m, at, CORRIDOR_Z0 - 0.3, -W / 2, W / 2, frontGaps, DOOR_W, DOOR_H, wall)
	end
	-- (la pared de dentro solo en el pasillo: el rellano da a la escalera)
	local backDoors = {}
	for _, x in backGaps do
		table.insert(backDoors, x)
	end
	local gapW = DOOR_W
	-- El hueco del ascensor es algo más ancho: se hace con dos piezas a mano
	local ex = elevator.Position.X
	for i = #backDoors, 1, -1 do
		if backDoors[i] == ex then
			table.remove(backDoors, i)
		end
	end
	wallX(m, at, CORRIDOR_Z1 + 0.3, -W / 2 + CORE + 0.6, ex - 2.5, {}, gapW, DOOR_H, wall)
	solid(m, "Lintel", V(5, FH - 8.5, 0.6), at(ex, 8.5 + (FH - 8.5) / 2, CORRIDOR_Z1 + 0.3), wall)
	wallX(m, at, CORRIDOR_Z1 + 0.3, ex + 2.5, W / 2, backDoors, gapW, DOOR_H, wall)
	-- Pared del fondo del pasillo con la puerta cortafuegos a la escalera de emergencia
	local fz = (CORRIDOR_Z0 + CORRIDOR_Z1) / 2
	local band = CORRIDOR_Z1 - CORRIDOR_Z0
	local sideW = (band + 0.6 - FIRE_DOOR_W) / 2
	solid(m, "EndWall", V(0.6, FH, sideW), at(W / 2 + 0.3, FH / 2, CORRIDOR_Z0 - 0.3 + sideW / 2), wall)
	solid(m, "EndWall", V(0.6, FH, sideW), at(W / 2 + 0.3, FH / 2, CORRIDOR_Z1 + 0.3 - sideW / 2), wall)
	solid(m, "EndWall", V(0.6, FH - DOOR_H, FIRE_DOOR_W), at(W / 2 + 0.3, DOOR_H + (FH - DOOR_H) / 2, fz), wall)
	emergencyStair(m, plan, floor, at, ctx)
	-- Zócalos del pasillo
	Furniture.baseboard(ctx, at(0, 0, CORRIDOR_Z0) * ANG(0, PI, 0), W)
	Furniture.baseboard(ctx, at((-W / 2 + CORE + W / 2) / 2, 0, CORRIDOR_Z1), W - CORE)

	-- Ascensor: marco, puertas de rellano (dos hojas que se abren con la cabina aquí: World/Lift),
	-- pantalla con la planta en la que está la cabina, botón de llamada y el hueco por detrás
	deco(m, "ElevatorFrame", V(6, 9.5, 0.4), at(ex, 4.75, CORRIDOR_Z1 + 0.05), rgb(160, 166, 172), M.Metal)
	for side = -1, 1, 2 do
		local leaf = solid(m, if side < 0 then "LiftLandingL" else "LiftLandingR", V(2.4, 8.4, 0.2), at(ex + side * 1.2, 4.2, CORRIDOR_Z1 + 0.35), rgb(190, 196, 204), M.Metal)
		leaf:AddTag("LiftLandingDoor")
		leaf:SetAttribute("Closed", leaf.CFrame)
		leaf:SetAttribute("Side", side)
		leaf:SetAttribute("Floor", floor)
	end
	deco(m, "ElevatorLight", V(1.2, 0.6, 0.1), at(ex, 9.1, CORRIDOR_Z1 - 0.2), rgb(120, 220, 255), M.Neon)
	local panelSign = deco(m, "ElevatorFloor", V(1.6, 0.8, 0.1), at(ex, 10.1, CORRIDOR_Z1 - 0.1), rgb(20, 20, 24))
	Builder.sign(panelSign, tostring(floor), Enum.NormalId.Front, rgb(255, 170, 60))
	-- (botón de llamada, a un lado)
	deco(m, "LiftCallPlate", V(0.6, 1.2, 0.1), at(ex + 3.4, 4.4, CORRIDOR_Z1 - 0.05), rgb(200, 204, 210), M.Metal)
	deco(m, "LiftCallButton", V(0.26, 0.26, 0.08), at(ex + 3.4, 4.6, CORRIDOR_Z1 - 0.12), rgb(255, 240, 200), M.Neon)
	Builder.part({ Name = "InteriorElevator", Size = V(6, 8, 2), CFrame = at(ex, 4, CORRIDOR_Z1 - 1.6), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = { "InteriorElevator" }, Attributes = { Floor = floor }, Parent = m })
	-- Hueco: paredes a los lados y al fondo (la cabina sube y baja por dentro)
	local sz = CORRIDOR_Z1 + 0.6 + Lift.Depth / 2
	solid(m, "ShaftLeft", V(0.5, FH, Lift.Depth + 0.6), at(ex - Lift.Width / 2 - 0.25, FH / 2, sz), wall)
	solid(m, "ShaftRight", V(0.5, FH, Lift.Depth + 0.6), at(ex + Lift.Width / 2 + 0.25, FH / 2, sz), wall)
	solid(m, "ShaftBack", V(Lift.Width + 1, FH, 0.5), at(ex, FH / 2, sz + Lift.Depth / 2 + 0.25), wall)
	if floor == 0 then
		solid(m, "ShaftPit", V(Lift.Width + 1, 1, Lift.Depth + 0.6), at(ex, -0.5, sz), rgb(80, 80, 86), M.Concrete)
	end

	-- Número de la planta en el rellano (y en el descansillo)
	local label = if floor == 0 then "Planta baja" else ("Planta %d"):format(floor)
	local floorSign = deco(m, "FloorSign", V(0.2, 2, 5), at(-W / 2 + 0.1, 6, (CORRIDOR_Z0 + CORRIDOR_Z1) / 2), rgb(30, 60, 110))
	floorSign:SetAttribute("FloorLabel", label)
	Builder.sign(floorSign, label, Enum.NormalId.Right)
	local corridorSign = deco(m, "FloorSign", V(5, 1.6, 0.2), at(-W / 2 + CORE + 1.2 + 2.5, 9.5, CORRIDOR_Z0 + 0.1), rgb(30, 60, 110))
	corridorSign:SetAttribute("FloorLabel", label)
	Builder.sign(corridorSign, label, Enum.NormalId.Back)

	-- Puertas
	local built: { BasePart } = {}
	for _, d in doors do
		local name = names and names[d.Unit.Id]
		table.insert(built, unitDoor(m, plan, floor, d, base * d.CFrame * ANG(0, PI, 0) * ANG(0, PI, 0), name))
	end

	-- Luces del pasillo (con su interruptor), ventana al final, plantas y extintor
	local lights = math.max(2, math.floor((W - CORE) / 12))
	for i = 1, lights do
		Furniture.ceilingLight(ctx, at(-W / 2 + CORE + (i - 0.5) * (W - CORE) / lights, FH - 1, (CORRIDOR_Z0 + CORRIDOR_Z1) / 2), room, "Panel")
	end
	Furniture.ceilingLight(ctx, at(-W / 2 + CORE / 2, FH - 1, (CORRIDOR_Z0 + CORRIDOR_Z1) / 2), room, "Dome")
	Furniture.lightSwitch(ctx, at(-W / 2 + CORE + 1.4, 4.2, CORRIDOR_Z1), room)
	Furniture.plant(ctx, at(W / 2 - 1.4, 0, CORRIDOR_Z0 + 1.1), 0.9)
	deco(m, "Extinguisher", V(0.7, 1.5, 0.7), at(-W / 2 + CORE + 0.5, 2.2, CORRIDOR_Z0 + 0.5), rgb(210, 30, 30), M.Metal)
	corridorDetails(m, plan, floor, at, ctx, doors)
	themeDetails(m, plan, floor, at, ctx, doors)

	-- Planta baja: puerta a la calle, buzones o recepción
	if floor == 0 then
		local sx = (-W / 2 + CORE + W / 2) / 2 + 0.01
		local exit = solid(m, "InteriorExit", V(6, 9, 0.6), at(sx, 4.5, CORRIDOR_Z0 - 0.3), rgb(96, 64, 40), M.Wood)
		exit:AddTag("InteriorExit")
		deco(m, "DoorGlass", V(4, 5, 0.65), at(sx, 5.5, CORRIDOR_Z0 - 0.3), rgb(180, 210, 230), M.Glass).Transparency = 0.4
		Builder.part({ Name = "InteriorEntry", Size = V(2, 2, 2), CFrame = at(sx, 3, CORRIDOR_Z0 + 3) * ANG(0, PI, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = { "InteriorEntry" }, Parent = m })
		deco(m, "Doormat", V(5, 0.08, 2.4), at(sx, 0.05, CORRIDOR_Z0 + 1.6), rgb(60, 60, 66), M.Fabric)
		local title = deco(m, "BuildingSign", V(10, 1.6, 0.2), at(sx, 10.2, CORRIDOR_Z0 + 0.1), rgb(40, 40, 46))
		Builder.sign(title, string.upper(plan.Title), Enum.NormalId.Back, rgb(240, 220, 160))
		if plan.Ground == "OficinaLobby" then
			-- Recepción (con recepcionista detrás, junto a la pared de la calle)
			local desk = Furniture.group(m, "Reception")
			Furniture.solid(desk, "Counter", V(6, 3.6, 1.6), at(W / 2 - 7, 1.8, CORRIDOR_Z0 + 2.6), rgb(60, 70, 90), M.Wood)
			Furniture.deco(desk, "CounterTop", V(6.4, 0.2, 1.8), at(W / 2 - 7, 3.7, CORRIDOR_Z0 + 2.6), rgb(240, 240, 236), M.Marble)
			Builder.part({ Name = "ClerkSpot", Size = V(2, 2, 2), CFrame = at(W / 2 - 7, 0, CORRIDOR_Z0 + 0.9) * ANG(0, PI, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = { "ClerkSpot" }, Attributes = { ClerkName = "Recepción" }, Parent = desk })
		else
			-- Buzones en la pared del fondo del rellano y portero
			local boxes = Furniture.group(m, "Mailboxes")
			Furniture.solid(boxes, "MailboxWall", V(5, 3, 0.5), at(-W / 2 + CORE / 2, 4.5, HALF_D - 0.25), rgb(150, 130, 80), M.Metal)
			for k = 0, 7 do
				Furniture.deco(boxes, "Mailbox", V(1.1, 1.2, 0.1), at(-W / 2 + CORE / 2 - 1.8 + (k % 4) * 1.2, 3.8 + math.floor(k / 4) * 1.4, HALF_D - 0.55), rgb(190, 170, 100), M.Metal)
			end
			if plan.Ground == "Portal" and Floors.hash("portero:" .. plan.Key) % 10 < 6 then
				local names0 = { "Manolo", "Encarna", "Paco", "Remedios", "Julio" }
				Builder.part({ Name = "ClerkSpot", Size = V(2, 2, 2), CFrame = at(W / 2 - 5, 0, CORRIDOR_Z0 + 1.5) * ANG(0, PI / 2, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Tags = { "ClerkSpot" }, Attributes = { ClerkName = "Portero " .. names0[Floors.hash(plan.Key) % #names0 + 1] }, Parent = m })
			end
		end
		Furniture.bench(ctx, at(W / 2 - 1.2, 0, CORRIDOR_Z1 - 1.8) * ANG(0, PI / 2, 0), 3, rgb(96, 64, 40))
	end

	m.Parent = parent
	local count = 0
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			count += 1
		end
	end
	return { Model = m, Doors = built, Parts = count }
end

-- Cambia el nombre de la placa de una puerta (al comprar o vender)
function Tower.setPlate(panel: BasePart, name: string?)
	local model = panel.Parent
	local plate = model and model:FindFirstChild("NamePlate")
	local text = plate and plate:FindFirstChild("PlateText", true)
	if text and text:IsA("TextLabel") then
		text.Text = plateText(panel:GetAttribute("Label") or "", name)
	end
end

return Tower
