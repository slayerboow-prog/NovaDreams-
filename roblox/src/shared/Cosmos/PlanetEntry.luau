-- PlanetEntry: entrar en un planeta y salir de él SIN pantalla de carga (cuentas puras;
-- docs/planetas.md). Lo usan el cliente (Controllers/PlanetClient: efectos y cuándo pedir el paso) y el
-- servidor (Services/PlanetService: a dónde va la nave).
--
-- Por qué así: Roblox no tiene gravedad esférica y el juego publica un solo place. Así que el planeta
-- del espacio es una esfera que se ve (shared/Cosmos/PlanetBodies) y su SUPERFICIE es una zona de
-- terreno lejos de Valmar en el mismo place (shared/Cosmos/Lontana). Al bajar, entre las nubes de la
-- entrada (que tapan la pantalla un momento), la nave pasa de un sitio a otro con la MISMA velocidad
-- y el mismo rumbo: el jugador no suelta los mandos en ningún momento.
--
-- Fases (E.Phase):
--   "Space"      volando por el espacio. Entras en la capa Entry de un planeta abierto, hacia dentro →
--   "Entry"      calor y plasma en la nave, temblor, nubes cada vez más espesas y el cielo que cambia de
--                color (P = 0..1 según lo hondo que vas). Si das la vuelta, vuelve a "Space". Con P = 1 →
--   "Descending" (se ha pedido "Descend" al servidor; las nubes lo tapan todo) → el servidor manda
--                "Relocate" →
--   "Arrival"    ya sobre la superficie, a ArriveY: las nubes se abren en ArrivalTime segundos →
--   "Surface"    volando o en tierra en el planeta. Si subes por encima de ClimbY →
--   "Climb"      las nubes vuelven y el cielo se oscurece (Q = 0..1). Con Q = 1 (CeilingY) →
--   "Ascending"  (se ha pedido "Ascend") → "Relocate" →
--   "Departure"  de nuevo en el espacio junto al planeta; las nubes se van → "Space".
-- Si el servidor no contesta en Timeout segundos, se vuelve atrás (y PlanetClient avisa).
--
-- Pasar de un sitio a otro (PlanetEntry.toSurface / toSpace): el punto por donde entras en la esfera
-- se lleva a la zona de la superficie (la cara del planeta que mira a Valmar es el centro de la zona)
-- y la dirección del morro se descompone en (este, norte, arriba) del planeta → (+X, −Z, +Y) de la
-- superficie. Al salir, al revés. Ida y vuelta da el mismo sitio y el mismo rumbo.

local PlanetBodies = require(script.Parent.PlanetBodies)

local PlanetEntry = {}

PlanetEntry.ArrivalTime = 2.4
PlanetEntry.DepartureTime = 2
PlanetEntry.Timeout = 4
PlanetEntry.InwardMin = 0.05 -- (morro · hacia el centro) para empezar la entrada
PlanetEntry.MapAngle = 0.6 -- radianes de la esfera que caben en media zona de superficie
PlanetEntry.EdgeMargin = 300 -- (la nave no aparece pegada al borde de la zona)
PlanetEntry.ExitLift = 120 -- al salir, aparece esto por encima de la capa Entry
PlanetEntry.MaxDive = -0.72 -- (llegada) el morro no apunta más abajo que esto

export type Surface = {
	Id: string,
	Origin: Vector3,
	Half: number,
	ArriveY: number,
	ClimbY: number,
	CeilingY: number,
}

export type State = {
	Phase: string,
	P: number, -- 0..1 entrada
	Q: number, -- 0..1 subida (salida)
	T: number, -- segundos en la fase
	Body: string?, -- id del planeta
	Sent: boolean,
}

export type Ctx = {
	World: string, -- "Cosmos" | "Planet"
	Pos: Vector3,
	Look: Vector3,
	Open: ((string) -> boolean)?, -- ¿puedes bajar a ese planeta?
	Surface: Surface?, -- la superficie en la que estás (World = "Planet")
}

function PlanetEntry.new(): State
	return { Phase = "Space", P = 0, Q = 0, T = 0, Body = nil, Sent = false }
end

local function set(E: State, phase: string)
	if E.Phase ~= phase then
		E.Phase = phase
		E.T = 0
	end
end

-- Un fotograma. Devuelve "Descend" o "Ascend" cuando hay que pedírselo al servidor (una vez).
function PlanetEntry.update(E: State, ctx: Ctx, dt: number): string?
	E.T += dt
	local phase = E.Phase
	if phase == "Arrival" then
		if E.T >= PlanetEntry.ArrivalTime then
			set(E, "Surface")
		end
		return nil
	elseif phase == "Departure" then
		if E.T >= PlanetEntry.DepartureTime then
			set(E, "Space")
			E.Body = nil
		end
		return nil
	elseif phase == "Descending" or phase == "Ascending" then
		if E.T >= PlanetEntry.Timeout then
			-- (sin respuesta: atrás)
			E.Sent = false
			set(E, if phase == "Descending" then "Space" else "Surface")
			E.P, E.Q = 0, 0
			return "Timeout"
		end
		return nil
	end
	if ctx.World == "Planet" then
		local S = ctx.Surface
		if not S then
			return nil
		end
		if phase ~= "Surface" and phase ~= "Climb" then
			set(E, "Surface")
		end
		local y = ctx.Pos.Y
		E.Q = math.clamp((y - S.ClimbY) / (S.CeilingY - S.ClimbY), 0, 1)
		if E.Phase == "Surface" and y > S.ClimbY then
			set(E, "Climb")
		elseif E.Phase == "Climb" and y < S.ClimbY - 30 then
			set(E, "Surface")
		end
		if E.Phase == "Climb" and E.Q >= 1 and not E.Sent then
			E.Sent = true
			set(E, "Ascending")
			return "Ascend"
		end
		return nil
	end
	-- En el espacio
	if phase == "Space" then
		E.P = 0
		for _, b in PlanetBodies.List do
			local off = ctx.Pos - b.Center
			local dist = off.Magnitude
			if dist < PlanetBodies.entryRadius(b) and dist > 1 and (not ctx.Open or ctx.Open(b.Id)) then
				local inward = ctx.Look.Unit:Dot(-off.Unit)
				if inward > PlanetEntry.InwardMin then
					E.Body = b.Id
					E.Sent = false
					set(E, "Entry")
					break
				end
			end
		end
	end
	if E.Phase == "Entry" then
		local b = E.Body and PlanetBodies.ById[E.Body]
		if not b then
			set(E, "Space")
			return nil
		end
		local dist = (ctx.Pos - b.Center).Magnitude
		local top, bottom = PlanetBodies.entryRadius(b), PlanetBodies.relocRadius(b)
		E.P = math.clamp((top - dist) / (top - bottom), 0, 1)
		if dist > top + 50 then
			E.P = 0
			set(E, "Space")
			return nil
		end
		if E.P >= 1 and not E.Sent then
			E.Sent = true
			set(E, "Descending")
			return "Descend"
		end
	end
	return nil
end

-- El servidor ha movido la nave: world = "Planet" (has llegado a la superficie) o "Cosmos" (de vuelta)
function PlanetEntry.relocated(E: State, world: string, body: string?)
	E.Sent = false
	if world == "Planet" then
		E.Body = body or E.Body
		E.P, E.Q = 1, 0
		set(E, "Arrival")
	else
		E.Body = body or E.Body
		E.P, E.Q = 0, 1
		set(E, "Departure")
	end
end

export type Effects = { Heat: number, Shake: number, Cloud: number, Sky: number, Plasma: number }

-- Cuánto de cada efecto (0..1): calor del casco, temblor, nubes delante de la cámara, cielo del
-- planeta (0 = negro del espacio, 1 = el del planeta) y plasma (más con más velocidad)
function PlanetEntry.effects(E: State, speed: number?): Effects
	local fast = math.clamp(((speed or 150) - 60) / 220, 0.25, 1)
	local p, q, t = E.P, E.Q, E.T
	local phase = E.Phase
	if phase == "Entry" then
		local heat = math.clamp(p * 1.6, 0, 1) * (1 - math.clamp((p - 0.85) / 0.15, 0, 1) * 0.3)
		return { Heat = heat, Shake = math.clamp(p * 0.9, 0, 0.8) * fast, Cloud = math.clamp((p - 0.35) / 0.5, 0, 1) ^ 1.5, Sky = p, Plasma = heat * fast }
	elseif phase == "Descending" then
		return { Heat = 0.7, Shake = 0.6 * fast, Cloud = 1, Sky = 1, Plasma = 0.6 * fast }
	elseif phase == "Arrival" then
		local k = math.clamp(t / PlanetEntry.ArrivalTime, 0, 1)
		return { Heat = 0.7 * (1 - k), Shake = 0.4 * (1 - k), Cloud = 1 - k * k * (3 - 2 * k), Sky = 1, Plasma = 0.5 * (1 - k) * fast }
	elseif phase == "Climb" then
		return { Heat = 0, Shake = q * 0.25, Cloud = math.clamp((q - 0.3) / 0.7, 0, 1) ^ 1.3, Sky = 1 - 0.7 * q, Plasma = 0 }
	elseif phase == "Ascending" then
		return { Heat = 0, Shake = 0.25, Cloud = 1, Sky = 0.3, Plasma = 0 }
	elseif phase == "Departure" then
		local k = math.clamp(t / PlanetEntry.DepartureTime, 0, 1)
		return { Heat = 0, Shake = 0.2 * (1 - k), Cloud = 1 - k * k * (3 - 2 * k), Sky = 0.3 * (1 - k), Plasma = 0 }
	elseif phase == "Surface" then
		return { Heat = 0, Shake = 0, Cloud = 0, Sky = 1, Plasma = 0 }
	end
	return { Heat = 0, Shake = 0, Cloud = 0, Sky = 0, Plasma = 0 }
end

-- ¿Mandas tú la nave en esta fase? (siempre: ninguna fase quita los mandos; para las pruebas)
function PlanetEntry.inControl(_E: State): boolean
	return true
end

---------------------------------------------------------------------
-- De la esfera a la superficie y al revés
---------------------------------------------------------------------
local Y = Vector3.new(0, 1, 0)

-- Los ejes del planeta: arriba (hacia Valmar), este y norte
function PlanetEntry.frame(b: PlanetBodies.Body): (Vector3, Vector3, Vector3)
	local up = (PlanetBodies.Hub - b.Center).Unit
	local east = Y:Cross(up)
	if east.Magnitude < 1e-4 then
		east = Vector3.new(1, 0, 0)
	end
	east = east.Unit
	local north = up:Cross(east).Unit
	return up, east, north
end

-- Este y norte en un punto n (unitario) de la esfera
local function localFrame(b: PlanetBodies.Body, n: Vector3): (Vector3, Vector3)
	local _, east0 = PlanetEntry.frame(b)
	local e = east0 - n * east0:Dot(n)
	if e.Magnitude < 1e-4 then
		e = n:Cross(Y)
		if e.Magnitude < 1e-4 then
			e = Vector3.new(1, 0, 0)
		end
	end
	e = e.Unit
	return e, n:Cross(e).Unit
end

local function facing(look: Vector3): CFrame
	local l = look.Unit
	local right = l:Cross(Y)
	if right.Magnitude < 1e-4 then
		right = l:Cross(Vector3.new(0, 0, 1))
	end
	right = right.Unit
	return CFrame.fromMatrix(Vector3.zero, right, right:Cross(l).Unit, -l)
end
PlanetEntry.facing = facing

function PlanetEntry.mapScale(S: Surface): number
	return (S.Half - PlanetEntry.EdgeMargin) / PlanetEntry.MapAngle
end

-- Entras en la esfera por `pos` mirando a `look` → (CFrame en la superficie, look de la superficie)
function PlanetEntry.toSurface(b: PlanetBodies.Body, S: Surface, pos: Vector3, look: Vector3): (CFrame, Vector3)
	local up, east, north = PlanetEntry.frame(b)
	local off = pos - b.Center
	local n = if off.Magnitude > 1e-6 then off.Unit else up
	local a = math.atan2(n:Dot(east), n:Dot(up))
	local c = math.atan2(n:Dot(north), n:Dot(up))
	local k = PlanetEntry.mapScale(S)
	local lim = S.Half - PlanetEntry.EdgeMargin
	local lx = math.clamp(a * k, -lim, lim)
	local lz = math.clamp(-c * k, -lim, lim)
	local e, nn = localFrame(b, n)
	local L = look.Unit
	local surf = Vector3.new(L:Dot(e), L:Dot(n), -L:Dot(nn))
	if surf.Magnitude < 1e-4 then
		surf = Vector3.new(0, -0.3, -1)
	end
	surf = surf.Unit
	if surf.Y < PlanetEntry.MaxDive then
		-- (en picado no: se endereza un poco para no llegar mirando al suelo)
		local flat = Vector3.new(surf.X, 0, surf.Z)
		flat = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.new(0, 0, -1)
		local h = math.sqrt(1 - PlanetEntry.MaxDive ^ 2)
		surf = (flat * h + Vector3.new(0, PlanetEntry.MaxDive, 0)).Unit
	end
	local p = Vector3.new(S.Origin.X + lx, S.Origin.Y + S.ArriveY, S.Origin.Z + lz)
	return CFrame.new(p) * facing(surf), surf
end

-- Sales por arriba de la superficie en `pos` mirando a `look` → (CFrame junto al planeta, look)
function PlanetEntry.toSpace(b: PlanetBodies.Body, S: Surface, pos: Vector3, look: Vector3): (CFrame, Vector3)
	local up, east, north = PlanetEntry.frame(b)
	local k = PlanetEntry.mapScale(S)
	local a = (pos.X - S.Origin.X) / k
	local c = -(pos.Z - S.Origin.Z) / k
	a = math.clamp(a, -1.3, 1.3)
	c = math.clamp(c, -1.3, 1.3)
	local n = (up + east * math.tan(a) + north * math.tan(c)).Unit
	local e, nn = localFrame(b, n)
	local L = look.Unit
	local spaceLook = e * L.X + n * L.Y + nn * -L.Z
	if spaceLook:Dot(n) < 0.15 then
		spaceLook = (spaceLook + n * 0.4).Unit
	end
	spaceLook = spaceLook.Unit
	local p = b.Center + n * (PlanetBodies.entryRadius(b) + PlanetEntry.ExitLift)
	return CFrame.new(p) * facing(spaceLook), spaceLook
end

return PlanetEntry
