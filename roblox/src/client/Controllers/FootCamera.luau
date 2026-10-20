-- FootCamera (cliente): la cámara cuando vas a pie.
--   * Distancia máxima de la cámara con sentido: fuera hasta 55 studs; dentro de casas, tiendas y
--     edificios (hay techo encima o estás en un interior) solo 14, así la cámara no se mete en las
--     paredes ni salta de habitación en habitación. El cambio es suave (la cámara de Roblox acerca
--     el zoom poco a poco). Se mantiene el modo "Zoom" de Roblox: si algo tapa, la cámara se acerca.
--   * Corriendo, el campo de visión se abre un poco (sensación de velocidad) y vuelve suave al parar.
--   * En modo foto la cámara se puede alejar mucho más (Actions llama a FootCamera.setPhoto).
--   * Apuntando con un arma el campo de visión se cierra (WeaponController llama a FootCamera.setAim)
--     y el zoom lo lleva el arma (cámara al hombro).
-- Conduciendo, de pasajero (también en el metro), en cinemáticas y en conversaciones no toca nada
-- (esas cámaras son de otros sistemas: la de los vehículos es RideCamera).
-- Las funciones puras (maxZoom y Locomotion.fov) se prueban en scripts/test-motion.luau.

local FootCamera = {}

FootCamera.OUTDOOR_ZOOM = 55
FootCamera.INDOOR_ZOOM = 14
FootCamera.PHOTO_ZOOM = 140
FootCamera.BASE_FOV = 70 -- el de Roblox

-- Distancia máxima de la cámara según dónde estás (función pura)
function FootCamera.maxZoom(indoors: boolean, photo: boolean): number
	if photo then
		return FootCamera.PHOTO_ZOOM
	end
	return if indoors then FootCamera.INDOOR_ZOOM else FootCamera.OUTDOOR_ZOOM
end

local photo = false
local refresh: (() -> ())? = nil
-- Apuntando con un arma (WeaponController): cuánto (0..1), a qué campo de visión y el zoom lo lleva él
local aimAlpha, aimFov = 0, 55

function FootCamera.setAim(alpha: number, fov: number)
	aimAlpha = math.clamp(alpha, 0, 1)
	aimFov = fov
end

function FootCamera.setPhoto(on: boolean)
	photo = on
	if refresh then
		refresh()
	end
end

function FootCamera.init()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Locomotion = require(script.Parent.Locomotion)
	local Cinematics = require(script.Parent.Cinematics)
	local RideCamera = require(script.Parent.RideCamera)
	local player = Players.LocalPlayer

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	local LEAVES = { [Enum.Material.LeafyGrass] = true, [Enum.Material.Grass] = true }

	-- ¿Hay techo encima de tu cabeza? (las copas de los árboles y los toldos transparentes no cuentan)
	local function roofOverHead(): boolean
		local character = player.Character
		local head = character and character:FindFirstChild("Head") :: BasePart?
		if not head then
			return false
		end
		params.FilterDescendantsInstances = { character :: Instance, workspace.CurrentCamera :: Instance }
		local hit = workspace:Raycast(head.Position, Vector3.new(0, 30, 0), params)
		return hit ~= nil and hit.Instance.Transparency < 0.5 and not LEAVES[hit.Material]
	end

	local indoors = false
	local pending, since = false, 0
	local function busy(): boolean
		return player:GetAttribute("Riding") ~= nil
			or player:GetAttribute("Passenger") ~= nil
			or RideCamera.isActive()
			or player:GetAttribute("InDialogue") == true
			or Cinematics.isPlaying()
	end
	refresh = function()
		if busy() or aimAlpha > 0 then
			return
		end
		local zoom = FootCamera.maxZoom(indoors, photo)
		if player.CameraMaxZoomDistance ~= zoom then
			player.CameraMaxZoomDistance = zoom
		end
	end
	-- Dentro o fuera: se mira 4 veces por segundo y se cambia cuando lleva medio segundo igual
	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = (player:GetAttribute("InteriorKey") ~= nil) or roofOverHead()
			if now ~= pending then
				pending, since = now, os.clock()
			elseif now ~= indoors and os.clock() - since > 0.5 then
				indoors = now
			end
			refresh()
		end
	end)
	-- Entrar o salir de un interior (teletransporte): el zoom se cambia ya, sin esperar el medio
	-- segundo (si no, la cámara llega de lejos y se ve el exterior por un momento)
	player:GetAttributeChangedSignal("InteriorKey"):Connect(function()
		local now = (player:GetAttribute("InteriorKey") ~= nil) or roofOverHead()
		indoors, pending, since = now, now, os.clock()
		if refresh then
			refresh()
		end
	end)

	-- Campo de visión al correr. A pie nadie más lo cambia: se escribe entero (70 de Roblox + lo de
	-- correr). Conduciendo, en cinemáticas y en conversaciones no se toca (y al volver se recoloca).
	local sprint = 0
	RunService.RenderStepped:Connect(function(dt)
		local camera = workspace.CurrentCamera
		if not camera or camera.CameraType ~= Enum.CameraType.Custom or busy() then
			sprint = 0
			return
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local running = false
		if root and humanoid then
			local v = root.AssemblyLinearVelocity
			running = player:GetAttribute("Sprinting") == true and Vector3.new(v.X, 0, v.Z).Magnitude > humanoid.WalkSpeed * 0.6
		end
		sprint = Locomotion.smooth(sprint, if running then 1 else 0, if running then 3 else 4, dt)
		if sprint < 0.002 then
			sprint = 0
		end
		local fov = Locomotion.fov(FootCamera.BASE_FOV, sprint)
		if aimAlpha > 0 then
			fov += (aimFov - fov) * aimAlpha
		end
		if math.abs(camera.FieldOfView - fov) > 0.001 then
			camera.FieldOfView = fov
		end
	end)
end

return FootCamera
