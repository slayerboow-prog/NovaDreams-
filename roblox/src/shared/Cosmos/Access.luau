-- Access: el puerto espacial de Valmar, los portales y quién puede subir a la nave (cuentas puras;
-- docs/espacio.md).
--
--   * Puerto espacial: en el ISLOTE de la costa oeste (shared/CityPlan.Islands, «Islote»: no hay nada
--     más construido en él). Pista redonda, nave de exposición («Subir a la nave»), portal a la Estación
--     Alba y portal de vuelta a la playa de Valmar.
--   * Portal de la playa: en la costa del Distrito Oeste, mirando al islote. El servidor prueba los
--     sitios de BeachSpots por orden y usa el primero libre de verdad (suelo de arena o hierba, sin
--     piezas encima): así no cae dentro de nada aunque la ciudad cambie.
--   * Subir a la nave y viajar a las estaciones: solo con la Saga 1 terminada (misión «Saga_24_Final»)
--     o siendo tester. Visitar el puerto espacial, mirar y volver: todo el mundo.
--   * Quedarse en Valmar está bien: el espacio es opcional y nada de Valmar lo pide.

local Access = {}

-- Orientación que mira hacia `look` con el techo hacia arriba (sin CFrame.lookAt: el de Lune da la vuelta)
function Access.face(pos: Vector3, look: Vector3): CFrame
	local l = if look.Magnitude > 1e-6 then look.Unit else Vector3.new(0, 0, -1)
	local right = l:Cross(Vector3.new(0, 1, 0))
	if right.Magnitude < 1e-4 then
		right = l:Cross(Vector3.new(0, 0, 1))
	end
	right = right.Unit
	return CFrame.fromMatrix(pos, right, right:Cross(l).Unit, -l)
end

Access.FinalQuest = "Saga_24_Final" -- la última misión de la Saga 1 (LifeStory/Misiones/Saga_Acto4)

-- El puerto espacial (islote: centro y radio de CityPlan.Islands; el suelo de hierba está a Y = -1)
Access.Port = Vector3.new(-4450, 0, 1900)
Access.PadRadius = 50
Access.PadTop = 1.2 -- altura de la superficie de la pista
Access.CorridorRadius = 520 -- alrededor de la pista se puede bajar por debajo de Layers.FloorY
-- Dónde aparece quien vuelve a Valmar (en la pista, al lado de la nave de exposición)
function Access.arrival(): CFrame
	return Access.face(Access.Port + Vector3.new(18, Access.PadTop + 3, 22), Vector3.new(1, 0, 0))
end
-- Donde aparece la nave al despegar (encima de la pista, morro hacia el mar y hacia arriba)
function Access.launch(): CFrame
	return Access.face(Access.Port + Vector3.new(0, Access.PadTop + 16, 0), Vector3.new(-0.42, 0.9, 0.12))
end
-- Sitios del puerto (respecto a Access.Port): la nave de exposición, el portal a la estación y el de
-- vuelta a la playa
Access.ShipSpot = Vector3.new(0, 0, -24)
Access.StationPortalSpot = Vector3.new(-30, 0, 30)
Access.BeachPortalSpot = Vector3.new(30, 0, -30)

-- Sitios para el portal de la playa (X, Z), del mejor al peor: costa oeste frente al islote, un poco
-- tierra adentro. El servidor busca el primero con suelo libre.
Access.BeachSpots = {
	{ -3640, 1430 }, { -3600, 1410 }, { -3700, 1350 }, { -3560, 1520 }, { -3520, 1470 },
	{ -3660, 1260 }, { -3620, 1180 }, { -3480, 1580 }, { -3420, 1640 }, { -3600, 1060 },
	{ -3300, 1800 }, { -3250, 1900 }, { -3560, 940 }, { -3200, 1500 }, { -3100, 1700 },
}
Access.PortalClear = Vector3.new(22, 18, 14) -- lo que tiene que estar libre alrededor del portal

-- ¿Ha terminado la Saga 1? (datos del jugador: Story.Completed)
function Access.sagaDone(data: { [string]: any }?): boolean
	local story = data and data.Story
	local done = type(story) == "table" and type(story.Completed) == "table" and story.Completed[Access.FinalQuest]
	return done ~= nil and done ~= false
end

-- ¿Puede subir a la nave / viajar a las estaciones? Devuelve (sí, motivo si no)
function Access.canFly(info: { SagaDone: boolean?, Tester: boolean? }): (boolean, string?)
	if info.Tester or info.SagaDone then
		return true, nil
	end
	return false, "Locked"
end

Access.Messages = {
	Locked = "🔒 La nave abre cuando termines la Saga 1, «History of Valmar». Sigue tu historia: el espacio te espera (y Valmar también está muy bien 😉).",
	Busy = "Termina lo que estás haciendo antes de subir a la nave.",
	Driving = "Bájate del vehículo antes de subir a la nave.",
	TooHigh = "🛰 Demasiado alto para bajarte: desciende por debajo de %d m o pulsa VALMAR para volver.",
	Home = "🏠 De vuelta en Valmar: puerto espacial del islote.",
}

return Access
