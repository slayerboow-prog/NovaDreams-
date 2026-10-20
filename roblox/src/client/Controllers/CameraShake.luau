-- CameraShake: temblor de cámara compartido (golpes, choques con el coche…).
-- Va justo después de que Roblox coloque la cámara (RenderPriority.Camera + 1), como el de
-- SeaEventsUI: si se moviera desde Heartbeat, la cámara de Roblox lo pisaría en el fotograma
-- siguiente y apenas se notaría. Solo se añade la diferencia con el fotograma anterior (la cámara
-- de Roblox parte de donde la dejamos), así que al acabar vuelve justo a su sitio.
-- Con mando, además, una vibración corta (HapticService; si no hay, no pasa nada).

local HapticService = game:GetService("HapticService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CameraShake = {}

local STEP = "CameraShake"

local amount = 0 -- fuerza que queda (se apaga sola)
local decay = 4 -- cuánto se apaga por segundo (relativo a la fuerza inicial)
local last = CFrame.identity
local bound = false
local rumbleToken = 0

local function step(dt: number)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	-- Cámara de cinemática (la coloca otro script cada fotograma): no se toca
	if camera.CameraType == Enum.CameraType.Scriptable then
		last = CFrame.identity
		return
	end
	if amount <= 0.001 and last == CFrame.identity then
		return -- quieta: nada que hacer
	end
	local offset = CFrame.identity
	if amount > 0.001 then
		local t = os.clock()
		local k = amount
		offset = CFrame.new(math.sin(t * 47) * k * 0.35, math.cos(t * 53) * k * 0.35, 0) * CFrame.Angles(math.sin(t * 31) * k * 0.02, math.cos(t * 37) * k * 0.02, 0)
		amount = math.max(0, amount - dt * decay * math.max(amount, 0.2))
	end
	camera.CFrame = camera.CFrame * last:Inverse() * offset
	last = offset
end

local function bind()
	if bound then
		return
	end
	bound = true
	RunService:BindToRenderStep(STEP, Enum.RenderPriority.Camera.Value + 1, function(dt)
		local ok, err = pcall(step, dt)
		if not ok then
			warn("[CameraShake] " .. tostring(err))
		end
	end)
end

-- Vibración del mando (motor grande), `seconds` segundos
local function rumble(strength: number, seconds: number)
	if not UserInputService.GamepadEnabled then
		return
	end
	rumbleToken += 1
	local token = rumbleToken
	pcall(function()
		if HapticService:IsVibrationSupported(Enum.UserInputType.Gamepad1) and HapticService:IsMotorSupported(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large) then
			HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, math.clamp(strength, 0, 1))
		end
	end)
	task.delay(seconds, function()
		if token == rumbleToken then
			pcall(function()
				HapticService:SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Large, 0)
			end)
		end
	end)
end

-- Sacude la cámara: strength ~0.2 (flojo) a ~1.5 (fuerte). Si ya temblaba, se queda el más fuerte.
function CameraShake.shake(strength: number, seconds: number?)
	if strength <= 0 then
		return
	end
	bind()
	amount = math.max(amount, strength)
	decay = 1 / math.max(seconds or 0.25, 0.05)
	rumble(strength * 0.6, math.min(seconds or 0.25, 0.4))
end

return CameraShake
