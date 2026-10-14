-- TyreService (servidor): pinchazos de las ruedas (cuentas y reglas en shared/Tyres).
--
--   * Lo decide SOLO el servidor y lo apunta en el vehículo (atributo Flat_<rueda> = true; lo ven
--     todos: WheelSpin la chafa y Driving tira hacia ese lado y corre menos).
--   * Causas: un disparo de verdad que atraviesa la rueda (WeaponService, con el rayo del servidor),
--     un choque muy fuerte (CrashService.damage, con la velocidad que ha validado el servidor) y, muy
--     de vez en cuando, mala suerte en un viaje largo (VehicleService, con la distancia que ve él).
--   * Arreglo: «Reparar rueda» en el surtidor (se paga, VehicleService), la rueda de repuesto (cartel
--     junto al vehículo, mantener unos segundos; una vez cada vez que se saca) o sacarlo de nuevo.
--   * Los vehículos de pago (Premium) no pinchan.
-- No tiene init: lo usan VehicleService, CrashService y WeaponService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Gameplay = require(ReplicatedStorage.Shared.Gameplay)
local Tyres = require(ReplicatedStorage.Shared.Tyres)

local TyreService = {}

local SPARE_PROMPT = "SparePrompt"

local function notify(player: Player?, kind: string, text: string)
	if not player then
		return
	end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild("Notify")
	if remote and remote:IsA("RemoteEvent") then
		remote:FireClient(player, kind, text)
	end
end

local function kindOf(model: Model): string?
	local kind = model:GetAttribute("Kind")
	return if type(kind) == "string" then kind else nil
end

function TyreService.isPremium(model: Model): boolean
	local kind = kindOf(model)
	return Tyres.isPremium(if kind then Gameplay.Vehicles[kind] else nil, model:GetAttribute("Premium"))
end

-- Las ruedas del vehículo: { Part, Id, Center, Axis, Radius, Width }
type WheelInfo = { Part: BasePart, Id: string, Center: Vector3, Axis: Vector3, Radius: number, Width: number }
function TyreService.wheels(model: Model): { WheelInfo }
	local frame = model.PrimaryPart
	local parts, local_ = {}, {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Wheel" and math.abs(d.Size.Y - d.Size.Z) < 0.01 then
			table.insert(parts, d)
			table.insert(local_, if frame then frame.CFrame:PointToObjectSpace(d.CFrame.Position) else d.CFrame.Position)
		end
	end
	local ids = Tyres.ids(local_)
	local out = {}
	for i, part in parts do
		table.insert(out, { Part = part, Id = ids[i], Center = part.CFrame.Position, Axis = part.CFrame.RightVector, Radius = part.Size.Y / 2, Width = part.Size.X })
	end
	return out
end

local function driverOf(model: Model): Player?
	local id = model:GetAttribute("Driver")
	if type(id) == "number" then
		return Players:GetPlayerByUserId(id)
	end
	id = model:GetAttribute("OwnerId")
	return if type(id) == "number" then Players:GetPlayerByUserId(id) else nil
end

-- El cartel de la rueda de repuesto (junto al vehículo), si hay alguna pinchada y no se ha usado
local function refreshSpare(model: Model)
	local chassis = model.PrimaryPart
	if not chassis then
		return
	end
	local want = #Tyres.flats(model:GetAttributes()) > 0 and model:GetAttribute("SpareUsed") ~= true
	local prompt = chassis:FindFirstChild(SPARE_PROMPT)
	if want and not prompt then
		local p = Instance.new("ProximityPrompt")
		p.Name = SPARE_PROMPT
		p.ActionText = "Poner la de repuesto"
		p.ObjectText = "🛞 Rueda pinchada"
		p.HoldDuration = Tyres.SpareSeconds
		p.MaxActivationDistance = 12
		p.RequiresLineOfSight = false
		p.Parent = chassis
		pcall(function()
			p.Triggered:Connect(function(player)
				TyreService.spare(player, model)
			end)
		end)
	elseif not want and prompt then
		prompt:Destroy()
	end
end

-- Pincha una rueda (por su Id). cause: "Disparo" | "Choque" | "Suerte". Devuelve si ha pinchado.
function TyreService.puncture(model: Model, id: string, cause: string): boolean
	if not model.Parent or not Tyres.canPuncture(kindOf(model), TyreService.isPremium(model)) then
		return false
	end
	local key = Tyres.PREFIX .. id
	if model:GetAttribute(key) == true then
		return false
	end
	model:SetAttribute(key, true)
	refreshSpare(model)
	local text = if cause == "Disparo" then "💥 ¡Te han reventado una rueda de un disparo!"
		elseif cause == "Choque" then "💥 ¡El golpe ha pinchado una rueda!"
		else "💥 ¡Has pinchado una rueda!"
	notify(driverOf(model), "Error", text .. " Ve despacio: repárala en una gasolinera o bájate y pon la de repuesto.")
	return true
end

function TyreService.repair(model: Model, id: string?)
	for _, flat in Tyres.flats(model:GetAttributes()) do
		if id == nil or flat == id then
			model:SetAttribute(Tyres.PREFIX .. flat, nil)
		end
	end
	refreshSpare(model)
end

-- Un disparo de verdad (WeaponService): el tramo que ha recorrido la bala, de a a b
function TyreService.shot(a: Vector3, b: Vector3): boolean
	local folder = workspace:FindFirstChild("Rides")
	if not folder then
		return false
	end
	local hit = false
	-- (si se para en la propia goma, el punto queda en su borde: un poco más allá)
	if (b - a).Magnitude > 0.01 then
		b += (b - a).Unit * 0.5
	end
	local mid, half = (a + b) / 2, (b - a).Magnitude / 2
	for _, model in folder:GetChildren() do
		local chassis = model:IsA("Model") and model.PrimaryPart
		if chassis and (chassis.CFrame.Position - mid).Magnitude <= half + 25 and Tyres.canPuncture(kindOf(model :: Model), TyreService.isPremium(model :: Model)) then
			for _, w in TyreService.wheels(model :: Model) do
				if Tyres.segmentHits(a, b, w.Center, w.Axis, w.Radius, w.Width) then
					hit = TyreService.puncture(model :: Model, w.Id, "Disparo") or hit
				end
			end
		end
	end
	return hit
end

-- Un choque validado (CrashService.damage): la rueda más cercana al golpe, a veces
function TyreService.crash(model: Model, point: Vector3, closing: number, roll: number?): boolean
	if not Tyres.crashPunctures(closing, roll or math.random()) then
		return false
	end
	local wheels = TyreService.wheels(model)
	local positions = {}
	for i, w in wheels do
		positions[i] = w.Center
	end
	local i = Tyres.nearest(positions, point)
	return i ~= nil and TyreService.puncture(model, wheels[i].Id, "Choque")
end

-- Lo que ha recorrido (VehicleService, cada medio segundo): muy de vez en cuando, mala suerte
function TyreService.travelled(model: Model, distance: number, roll: number?): boolean
	if not Tyres.unlucky(distance, roll or math.random()) then
		return false
	end
	local wheels = TyreService.wheels(model)
	if #wheels == 0 then
		return false
	end
	return TyreService.puncture(model, wheels[math.random(1, #wheels)].Id, "Suerte")
end

-- Rueda de repuesto: el dueño (o quien lo conduce), a pie, junto al vehículo parado. Una vez cada
-- vez que se saca el vehículo.
function TyreService.spare(player: Player, model: Model): boolean
	local flats = Tyres.flats(model:GetAttributes())
	if #flats == 0 then
		return false
	end
	if model:GetAttribute("SpareUsed") == true then
		notify(player, "Info", "Ya has usado la rueda de repuesto: repárala en una gasolinera.")
		return false
	end
	local owner = model:GetAttribute("OwnerId")
	if owner ~= player.UserId and model:GetAttribute("Driver") ~= player.UserId then
		notify(player, "Info", "Solo el dueño puede cambiar la rueda.")
		return false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local chassis = model.PrimaryPart
	if not humanoid or humanoid.SeatPart or not root or not root:IsA("BasePart") or not chassis then
		notify(player, "Info", "Bájate del vehículo para cambiar la rueda.")
		return false
	end
	local okVel, speed = pcall(function()
		return chassis.AssemblyLinearVelocity.Magnitude
	end)
	if (root.CFrame.Position - chassis.CFrame.Position).Magnitude > 16 or (okVel and speed > 2) then
		notify(player, "Info", "Para el vehículo y acércate a la rueda.")
		return false
	end
	model:SetAttribute("SpareUsed", true)
	TyreService.repair(model, flats[1])
	notify(player, "Success", "🛞 Rueda de repuesto puesta." .. (if #flats > 1 then " Te queda otra pinchada: llévalo a una gasolinera." else ""))
	return true
end

-- Gasolinera: repara todas las pinchadas (pagando). pay(cost) -> bool la pone VehicleService.
function TyreService.repairAt(player: Player, model: Model?, pay: (number) -> boolean): boolean
	if not model then
		notify(player, "Info", "Acércate al surtidor con tu vehículo para reparar la rueda.")
		return false
	end
	local flats = Tyres.flats(model:GetAttributes())
	if #flats == 0 then
		notify(player, "Info", "Las ruedas están bien.")
		return false
	end
	local cost = Tyres.RepairPrice * #flats
	if not pay(cost) then
		notify(player, "Error", ("No tienes dinero para reparar la rueda (%d €)."):format(cost))
		return false
	end
	TyreService.repair(model)
	notify(player, "Success", ("🛞 Rueda reparada (%d €)."):format(cost))
	return true
end

return TyreService
