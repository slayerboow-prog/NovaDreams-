-- Hyperspeed: la HIPERVELOCIDAD de la nave (Espacio AAA, fase 5; docs/espacio-aaa/diseno.md). Cuentas
-- puras: el servidor decide (Services/ShipSystems: aprueba, gasta energía, da margen al movimiento) y el
-- cliente vuela y la enseña (Controllers/AirCombatClient, AirCombatFx, UI/AirCombatHud).
--
-- Cuatro fases:
--   "Prepare"   (Times.Prepare s) se comprueba todo (energía, estado, combate, estaciones, tráfico,
--               atmósfera y obstáculos delante); los motores brillan más. Sin gastar nada.
--   "Activate"  (Times.Activate s) la velocidad sube poco a poco hasta Speed: estelas, temblor suave,
--               campo de visión más abierto, distorsión y HUD especial. Aquí se gasta Cost.
--   "Travel"    viaje de verdad: gasta Drain/s, avisa de obstáculos y se puede cortar (freno, la tecla o la
--               ranura). Se corta sola sin energía, con un obstáculo delante, al llegar al borde del
--               espacio, cerca de una estación o de la atmósfera de un planeta, o si te atacan.
--   "Decel"     (Times.Decel s) la velocidad baja poco a poco; la cámara vuelve; efecto de salida.
-- Distinta del IMPULSO (Shift): otra velocidad (1500 contra 340), gasta energía y tiene fases.
--
-- Nunca atraviesa nada: además de los choques barridos de ShipFlight, mira por adelantado LookAhead
-- segundos de recorrido (sweep) y, si hay algo, empieza a frenar con tiempo.

local Hyperspeed = {}

Hyperspeed.Speed = 1500 -- studs/s
Hyperspeed.Turn = 0.25 -- cuánto gira (multiplica el giro normal)
Hyperspeed.Times = { Prepare = 1, Activate = 1, Decel = 1.2 }
Hyperspeed.LookAhead = 2.5 -- segundos de recorrido que se miran por delante
Hyperspeed.StationRadius = 830 -- (1,6 × la zona segura)
Hyperspeed.EnemyRadius = 1500 -- enemigos a menos de esto = combate
Hyperspeed.HurtSeconds = 6 -- te han dado hace menos de esto = combate
Hyperspeed.TrafficRadius = 250 -- otra nave a menos de esto = tráfico
Hyperspeed.AtmosMargin = 300 -- por encima de la atmósfera de un planeta

Hyperspeed.Phases = { "Prepare", "Activate", "Travel", "Decel" }
Hyperspeed.Titles = {
	Prepare = "HIPERVELOCIDAD · PREPARANDO",
	Activate = "HIPERVELOCIDAD · ACTIVANDO",
	Travel = "HIPERVELOCIDAD",
	Decel = "HIPERVELOCIDAD · SALIENDO",
}

-- Lo que hace falta saber para decidir (lo rellena quien llama):
export type Context = {
	World: string?, -- "Cosmos" | "Planet" | "Arena"
	Mode: string?, -- "Space" | "Atmos" (ShipFlight)
	Down: boolean?,
	Busy: boolean?, -- otro salto en marcha
	Energy: number,
	MinEnergy: number,
	Cooldown: number, -- segundos que faltan
	InCombat: boolean?,
	NearStation: boolean?,
	Traffic: boolean?,
	InAtmosphere: boolean?,
	Obstacle: string?, -- lo que hay delante (sweep) o nil
}

-- ¿Se puede? -> ok, motivo (clave de ShipAbilities.Reasons)
function Hyperspeed.check(c: Context): (boolean, string?)
	if c.Down then
		return false, "Derribado"
	elseif c.Busy then
		return false, "Ocupada"
	elseif c.World ~= "Cosmos" then
		return false, if c.World == "Planet" then "Atmosfera" else "Mundo"
	elseif c.Mode ~= "Space" or c.InAtmosphere then
		return false, "Atmosfera"
	elseif c.Cooldown > 0 then
		return false, "Recarga"
	elseif c.Energy < c.MinEnergy then
		return false, "Energia"
	elseif c.InCombat then
		return false, "Combate"
	elseif c.NearStation then
		return false, "Estacion"
	elseif c.Traffic then
		return false, "Trafico"
	elseif c.Obstacle then
		return false, "Obstaculo"
	end
	return true, nil
end

-- Mira por delante: recorre `distance` studs desde `from` hacia `dir` en saltos de `step` y devuelve lo
-- primero que toca (collide(pos, radio) -> nombre?) o que se sale (inside(pos) -> bool), y a qué distancia
function Hyperspeed.sweep(from: Vector3, dir: Vector3, distance: number, radius: number, collide: (Vector3, number) -> string?, inside: ((Vector3) -> boolean)?, step: number?): (string?, number?)
	if dir.Magnitude < 1e-6 then
		return nil, nil
	end
	local u = dir.Unit
	local s = step or math.max(radius * 2, 20)
	local n = math.max(1, math.ceil(distance / s))
	for i = 1, n do
		local d = math.min(distance, i * s)
		local p = from + u * d
		local hit = collide(p, radius)
		if hit then
			return hit, d
		end
		if inside and not inside(p) then
			return "el borde del espacio", d
		end
	end
	return nil, nil
end

-- Lo que la nave debe hacer en cada fase (para ShipFlight.Override); fromSpeed: velocidad al empezar
function Hyperspeed.override(phase: string, cruise: number): { Speed: number, Accel: number, Decel: number, Turn: number }?
	local H = Hyperspeed
	if phase == "Activate" or phase == "Travel" then
		local accel = (H.Speed - cruise) / H.Times.Activate
		return { Speed = H.Speed, Accel = accel, Decel = accel, Turn = H.Turn }
	elseif phase == "Decel" then
		local decel = (H.Speed - cruise) / H.Times.Decel
		return { Speed = cruise, Accel = decel, Decel = decel, Turn = 0.6 }
	end
	return nil
end

-- Velocidad de más que el servidor admite en cada fase (studs/s)
function Hyperspeed.allowance(phase: string?): number
	if phase == "Activate" or phase == "Travel" or phase == "Decel" then
		return Hyperspeed.Speed * 1.1
	end
	return 0
end

-- Distancia de frenada desde la hipervelocidad (para mirar con tiempo)
function Hyperspeed.stopDistance(): number
	return Hyperspeed.Speed * Hyperspeed.LookAhead
end

-- Avanza la máquina de fases (pura): st = { Phase, Since }. Devuelve la fase nueva si cambia sola
-- (Prepare → Activate, Activate → Travel, Decel → nil). Travel solo cambia por fuera (stop).
function Hyperspeed.advance(st: { Phase: string?, Since: number }, now: number): string?
	local T = Hyperspeed.Times
	local p = st.Phase
	local dt = now - st.Since
	if p == "Prepare" and dt >= T.Prepare then
		return "Activate"
	elseif p == "Activate" and dt >= T.Activate then
		return "Travel"
	elseif p == "Decel" and dt >= T.Decel then
		return "Off"
	end
	return nil
end

return Hyperspeed
