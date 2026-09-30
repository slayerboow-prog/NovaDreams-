--!strict
-- RideState: ¿va el jugador montado en un vehículo? (conduciendo un coche, una moto, un patinete o
-- un barco; o de pasajero en un coche, el autobús, el metro, el tren o el avión)
--
-- Lo usan la historia (LifeStoryService: una conversación o una escena NUNCA empieza sola mientras
-- conduces o viajas; espera a que te bajes) y la caja de diálogo del cliente (DialogueUI: la cámara de
-- conversación no se lleva la cámara del vehículo). Solo LEE lo que ya ponen los servicios de
-- vehículos: los atributos Riding / Passenger / BusLine (solo si va sentado) y Humanoid.SeatPart. Sentarse en un banco,
-- una silla o el váter NO cuenta como ir en un vehículo.
-- Funciona igual en el servidor y en el cliente.

local RideState = {}

-- Etiquetas de los asientos de transporte público (MetroKit, RailKit, Airport)
local SEAT_TAGS = { MetroSeat = "Metro", RailSeat = "Tren", PlaneSeat = "Avion" }

local function attr(inst: any, name: string): any
	local ok, value = pcall(function()
		return inst:GetAttribute(name)
	end)
	return if ok then value else nil
end

-- El asiento de un vehículo en el que va sentado (o nil). Devuelve el tipo («Coche», «Metro»…).
function RideState.seatKind(seat: any): string?
	if seat == nil then
		return nil
	end
	local ok, kind = pcall(function(): string?
		for tag, name in SEAT_TAGS do
			if seat:HasTag(tag) then
				return name
			end
		end
		local model = seat:FindFirstAncestorOfClass("Model")
		while model do
			if model:GetAttribute("Drivable") or model:GetAttribute("BusLine") then
				local k = model:GetAttribute("Kind")
				return if type(k) == "string" then k else "Vehiculo"
			end
			model = model:FindFirstAncestorOfClass("Model")
		end
		if seat:IsA("VehicleSeat") then
			return "Vehiculo"
		end
		return nil
	end)
	return if ok then kind else nil
end

-- ¿En qué vehículo va? nil = a pie (o sentado en un banco, una silla…)
function RideState.vehicleOf(player: any): string?
	if player == nil then
		return nil
	end
	local riding = attr(player, "Riding")
	if type(riding) == "string" and riding ~= "" then
		return riding
	end
	local passenger = attr(player, "Passenger")
	if type(passenger) == "string" and passenger ~= "" then
		return passenger
	end
	local ok, seat = pcall(function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		return humanoid and humanoid.SeatPart
	end)
	seat = if ok then seat else nil
	-- En el autobús: «BusLine» y sentado. Sin asiento, es un «BusLine» que se quedó puesto (se levantó
	-- sin que BusService se enterase): no cuenta, o ninguna escena de la historia volvería a empezar
	if attr(player, "BusLine") ~= nil and seat ~= nil then
		return "Bus"
	end
	if seat then
		return RideState.seatKind(seat)
	end
	return nil
end

function RideState.inVehicle(player: any): boolean
	return RideState.vehicleOf(player) ~= nil
end

return RideState
