-- Lift: el ascensor de verdad de los edificios de varias plantas (World/Tower; lo mueve InteriorService).
--
--   * Hueco detrás de la pared del pasillo (World/Tower pone en cada planta sus paredes y las puertas
--     de rellano, dos hojas que se abren hacia los lados) y una cabina que sube y baja por él: suelo,
--     paredes, techo con luz, pasamanos, espejo, sus propias puertas de dos hojas y la botonera
--     («Elegir planta»).
--   * El viaje sigue un horario fijo (salida, llegada, hora de inicio y duración, con arranque y
--     frenada suaves: Lift.heightAt). El servidor mueve la cabina; el cliente (Controllers/LiftRide)
--     mueve a quien va dentro con la misma cuenta, así el viaje se ve fluido en cada pantalla.
--   * Las puertas solo se abren con la cabina parada en esa planta: no hay forma de caer por el hueco.
-- Medidas en coordenadas de la planta (Floors): el hueco va de z = Z0 a Z0 + DEPTH, centrado en x.

local LiftMath = require(game:GetService("ReplicatedStorage").Shared.LiftMath)
local Builder = require(script.Parent.Builder)

local Lift = {}

local rgb = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local M = Enum.Material

Lift.Width = 5.6 -- hueco (por dentro)
Lift.Depth = 6.4
Lift.CabinHeight = 9
Lift.DoorOpenWidth = 2.5 -- lo que se abre cada hoja
Lift.DoorSeconds = 0.9
Lift.DwellSeconds = 6 -- puertas abiertas si nadie entra ni pulsa

-- (las cuentas del viaje están en shared/LiftMath: las usa también el cliente)
Lift.ease = LiftMath.ease
Lift.duration = LiftMath.duration
Lift.heightAt = LiftMath.heightAt

-- ¿Está ese punto (en coordenadas de la cabina: suelo en y = 0) dentro de la cabina?
function Lift.inside(localPos: Vector3): boolean
	return math.abs(localPos.X) < Lift.Width / 2 and localPos.Y > -1 and localPos.Y < Lift.CabinHeight and math.abs(localPos.Z) < Lift.Depth / 2
end

export type Cabin = {
	Model: Model,
	Base: CFrame, -- centro del suelo de la cabina en la planta baja (mirando al pasillo: -Z)
	Doors: { BasePart }, -- hojas de la cabina (izquierda, derecha)
	Display: TextLabel?,
	Panel: BasePart,
	Parts: { BasePart },
}

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, collide: boolean?): BasePart
	return Builder.part({ Name = name, Size = size, CFrame = cf, Color = color, Material = material or M.SmoothPlastic, CanCollide = collide ~= false, CanTouch = false, Parent = parent })
end

-- Crea la cabina en la planta baja. base: el centro del suelo del hueco en la planta baja, con -Z
-- mirando al pasillo (World/Tower.shaftBase)
function Lift.build(parent: Instance, base: CFrame): Cabin
	local model = Instance.new("Model")
	model.Name = "Ascensor"
	local W, D, H = Lift.Width - 0.2, Lift.Depth - 0.2, Lift.CabinHeight
	local function at(x: number, y: number, z: number): CFrame
		return base * CF(x, y, z)
	end
	local steel = rgb(176, 182, 190)
	local parts = {}
	local function add(p: BasePart): BasePart
		table.insert(parts, p)
		return p
	end
	add(part(model, "CabinFloor", V(W, 0.4, D), at(0, -0.2, 0), rgb(70, 72, 78), M.DiamondPlate))
	add(part(model, "CabinBack", V(W, H, 0.25), at(0, H / 2, D / 2 - 0.125), steel, M.Metal))
	add(part(model, "CabinLeft", V(0.25, H, D), at(-W / 2 + 0.125, H / 2, 0), steel, M.Metal))
	add(part(model, "CabinRight", V(0.25, H, D), at(W / 2 - 0.125, H / 2, 0), steel, M.Metal))
	add(part(model, "CabinRoof", V(W, 0.3, D), at(0, H + 0.15, 0), rgb(220, 222, 226), M.SmoothPlastic))
	-- Frente: a los lados de la puerta y encima
	add(part(model, "CabinFrontL", V(0.3, H, 0.25), at(-W / 2 + 0.15, H / 2, -D / 2 + 0.125), steel, M.Metal))
	add(part(model, "CabinFrontR", V(0.3, H, 0.25), at(W / 2 - 0.15, H / 2, -D / 2 + 0.125), steel, M.Metal))
	add(part(model, "CabinHeader", V(W, H - 8.2, 0.25), at(0, 8.2 + (H - 8.2) / 2, -D / 2 + 0.125), steel, M.Metal))
	-- Luz del techo, pasamanos y espejo
	local lamp = add(part(model, "CabinLight", V(3, 0.1, 3), at(0, H - 0.05, 0), rgb(255, 248, 230), M.Neon, false))
	local light = Instance.new("PointLight")
	light.Range = 12
	light.Brightness = 1.2
	light.Color = rgb(255, 244, 220)
	light.Parent = lamp
	add(part(model, "Handrail", V(W - 0.8, 0.18, 0.18), at(0, 3.2, D / 2 - 0.4), rgb(210, 214, 220), M.Metal, false))
	add(part(model, "Mirror", V(W - 1.2, 4, 0.05), at(0, 5.4, D / 2 - 0.27), rgb(200, 220, 235), M.Glass, false)).Transparency = 0.2
	-- Puertas de la cabina (dos hojas)
	local doorL = add(part(model, "CabinDoorL", V(2.5, 8.2, 0.15), at(-1.25, 4.1, -D / 2 + 0.3), rgb(196, 200, 206), M.Metal))
	local doorR = add(part(model, "CabinDoorR", V(2.5, 8.2, 0.15), at(1.25, 4.1, -D / 2 + 0.3), rgb(196, 200, 206), M.Metal))
	doorL:SetAttribute("Closed", doorL.CFrame)
	doorR:SetAttribute("Closed", doorR.CFrame)
	-- Botonera (junto a la puerta, por dentro) con la pantalla de la planta
	local panel = add(part(model, "ButtonPanel", V(1.2, 3, 0.15), at(W / 2 - 0.9, 4.4, -D / 2 + 0.45), rgb(40, 42, 48), M.Metal, false))
	for i = 0, 5 do
		add(part(model, "Button", V(0.28, 0.28, 0.06), at(W / 2 - 1.1 + (i % 2) * 0.4, 3.6 + math.floor(i / 2) * 0.45, -D / 2 + 0.53), rgb(230, 230, 220), M.Neon, false))
	end
	local screen = add(part(model, "CabinDisplay", V(1.6, 0.6, 0.06), at(0, 8.6, -D / 2 + 0.33), rgb(12, 14, 18), M.SmoothPlastic, false))
	local display = Builder.sign(screen, "0", Enum.NormalId.Back, rgb(255, 170, 60))
	model:SetAttribute("Floor", 0)
	model:SetAttribute("Doors", "Closed")
	model:SetAttribute("Base", base)
	model.Parent = parent
	return { Model = model, Base = base, Doors = { doorL, doorR }, Display = display, Panel = panel, Parts = parts }
end

-- Mueve la cabina entera a esa altura (suelo de la cabina a `height` studs de la planta baja)
function Lift.place(cabin: Cabin, height: number)
	local base = cabin.Base
	local target = base * CF(0, height, 0)
	local current = cabin.Model:GetAttribute("Height") or 0
	local delta = target.Position - (base * CF(0, current, 0)).Position
	for _, p in cabin.Parts do
		if p.Parent then
			p.CFrame = p.CFrame + delta
		end
	end
	-- (las posiciones cerradas de las puertas también suben)
	for _, door in cabin.Doors do
		local closed = door:GetAttribute("Closed")
		if typeof(closed) == "CFrame" then
			door:SetAttribute("Closed", closed + delta)
		end
	end
	cabin.Model:SetAttribute("Height", height)
end

-- Abre o cierra unas puertas de dos hojas (las de la cabina o las de un rellano). closedAt: CFrame
-- de cada hoja cerrada (atributo "Closed"); abiertas se apartan hacia los lados y no chocan.
function Lift.setDoors(doors: { BasePart }, open: boolean, tween: ((BasePart, CFrame) -> ())?)
	for i, door in doors do
		local closed = door:GetAttribute("Closed")
		if typeof(closed) ~= "CFrame" then
			continue
		end
		local side = if i == 1 then -1 else 1
		local goal = if open then closed * CF(side * Lift.DoorOpenWidth * 0.95, 0, 0) else closed
		if tween then
			tween(door, goal)
		else
			door.CFrame = goal
		end
		door.CanCollide = not open
		door:SetAttribute("Open", open)
	end
end

return Lift
