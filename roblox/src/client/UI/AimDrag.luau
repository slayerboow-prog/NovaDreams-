-- AimDrag: la zona de APUNTAR del pulgar derecho en el móvil (Espacio AAA, docs/espacio-aaa/diseno.md).
-- La palanca de la izquierda (UI/FlightStick) dirige la nave; arrastrando el pulgar derecho por la parte
-- libre de la derecha de la pantalla (no encima de un botón ni del HUD de arriba) se afina la puntería,
-- como mover la cámara en un shooter del móvil. Varios dedos a la vez: cada uno es suyo (la palanca, este
-- y los botones no se estorban).
--
--   AimDrag.setEnabled(on)            al subir y bajar de la nave (Controllers/AirCombatClient)
--   AimDrag.read() -> (yaw, pitch)    lo que pide este fotograma (-1..1), y se gasta
--   AimDrag.setSensitivity(k)         0,4 – 2 (⚙️ «Sensibilidad de la nave»)
-- Cuentas puras: AimDrag.zone(viewport) y AimDrag.toInput(delta, sensibilidad) (scripts/test-espacio-aaa).

local AimDrag = {}

AimDrag.Sensitivity = 1
AimDrag.MinSensitivity = 0.4
AimDrag.MaxSensitivity = 2
AimDrag.PixelsForFull = 28 -- píxeles por fotograma que equivalen a la palanca a tope (con sensibilidad 1)

-- La zona (píxeles): la mitad derecha, por debajo del HUD de arriba (radar, misiones) y por encima de
-- los botones grandes; los botones se excluyen aparte (un toque encima de un botón es del botón)
function AimDrag.zone(viewport: Vector2): { X: number, Y: number, W: number, H: number }
	local top = viewport.Y * 0.22
	return { X = viewport.X * 0.5, Y = top, W = viewport.X * 0.5, H = viewport.Y * 0.78 - top }
end

function AimDrag.inside(p: Vector2, viewport: Vector2): boolean
	local z = AimDrag.zone(viewport)
	return p.X >= z.X and p.Y >= z.Y and p.X <= z.X + z.W and p.Y <= z.Y + z.H
end

-- Del arrastre (píxeles en este fotograma) a los mandos: (yaw, pitch); arriba sube el morro
function AimDrag.toInput(delta: Vector2, sensitivity: number?): (number, number)
	local k = (sensitivity or AimDrag.Sensitivity) / AimDrag.PixelsForFull
	return math.clamp(delta.X * k, -1, 1), math.clamp(-delta.Y * k, -1, 1)
end

function AimDrag.setSensitivity(k: number)
	AimDrag.Sensitivity = math.clamp(k, AimDrag.MinSensitivity, AimDrag.MaxSensitivity)
end

local enabled = false
local touch: InputObject? = nil
local last = Vector2.zero
local acc = Vector2.zero
local wired = false

local function overButton(p: Vector2): boolean
	local ok, hit = pcall(function()
		local playerGui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if not playerGui then
			return false
		end
		for _, obj in playerGui:GetGuiObjectsAtPosition(p.X, p.Y) do
			if obj:IsA("GuiButton") and obj.Visible then
				return true
			end
		end
		return false
	end)
	return ok and hit == true
end

local function wire()
	if wired then
		return
	end
	wired = true
	local UserInputService = game:GetService("UserInputService")
	UserInputService.InputBegan:Connect(function(input: InputObject)
		if not enabled or touch or input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local camera = workspace.CurrentCamera
		local p = Vector2.new(input.Position.X, input.Position.Y)
		if not camera or not AimDrag.inside(p, camera.ViewportSize) or overButton(p) then
			return
		end
		touch = input
		last = p
	end)
	UserInputService.InputChanged:Connect(function(input: InputObject)
		if input == touch then
			local p = Vector2.new(input.Position.X, input.Position.Y)
			acc += p - last
			last = p
		end
	end)
	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input == touch then
			touch = nil
		end
	end)
end

function AimDrag.setEnabled(on: boolean)
	enabled = on
	touch = nil
	acc = Vector2.zero
	if on then
		pcall(wire)
	end
end

function AimDrag.read(): (number, number)
	if not enabled then
		return 0, 0
	end
	local d = acc
	acc = Vector2.zero
	return AimDrag.toInput(d)
end

function AimDrag.touching(): boolean
	return touch ~= nil
end

return AimDrag
