-- Knock: lo que sale despedido al darle con un vehículo (o al chocar andando). Solo la cuenta: sin
-- Roblox, se prueba con scripts/test-collisions.luau. Lo usan KnockService (servidor), Collisions y
-- Ambient (cliente).
--
--   * Objetos de la calle: papeleras, conos, vallas de obra, sillas y mesas de terraza (con su
--     sombrilla), pizarras, cajas de fruta, macetas, sombrillas de playa, motos aparcadas de adorno,
--     bancos del parque, señales… (Knock.Catalog, por su nombre y dónde están). A 10 km/h una
--     papelera se vuelca; a 100, sale volando. Los pesados (banco, contenedor, señal) no se mueven
--     hasta cierta velocidad (MinSpeed). Lo estructural sigue sólido (Knock.Solid): farolas,
--     semáforos, bolardos, jardineras, bocas de riego, quioscos, árboles, paredes…
--   * Las personas: un roce es un traspiés; más fuerte, al suelo; muy fuerte, por los aires
--     (Knock.person). Luego se levantan.
--   * Todo tiene topes (nada sale disparado al cielo) y un presupuesto de objetos con física a la vez
--     (Knock.Budget). Lo que se ha movido vuelve a su sitio solo al rato (Knock.shouldRespawn), nunca
--     con alguien encima de su sitio.

local Knock = {}

Knock.Gravity = 196.2
Knock.Budget = 40 -- objetos con física a la vez en el servidor (los que sobran: el más antiguo vuelve)
Knock.MinSpeed = 1.5 -- menos que esto (studs/s) no mueve nada
Knock.TipSpeed = 20 -- hasta aquí (≈ 20 km/h) se vuelca o se empuja; por encima, sale volando
Knock.MaxLaunch = 85 -- velocidad horizontal máxima que coge (studs/s)
Knock.MaxLift = 42 -- y hacia arriba
Knock.MaxSpin = 14 -- vueltas (rad/s)
Knock.Restitution = 0.4
-- (vídeo de Valmar Centro: papeleras, cajas y vallas por el suelo y por el aire que no volvían nunca
-- mientras andabas cerca. Ahora vuelven antes y solo esperan si alguien está ENCIMA de su sitio;
-- si tarda demasiado, se esconden hasta que el sitio quede libre: nada se queda tirado)
Knock.RestSeconds = 10 -- quieto este rato lejos de su sitio: vuelve
Knock.MaxLife = 30 -- como mucho esto fuera de su sitio
Knock.HideAfter = 40 -- y si su sitio sigue ocupado, a esto desaparece (vuelve cuando quede libre)
Knock.FallDepth = 60 -- más abajo que esto de su sitio: se ha caído del mapa, vuelve ya
Knock.SpotClear = 1.2 -- no vuelve si hay alguien a menos de esto (más su tamaño) de su sitio
Knock.FadeSeconds = 0.6 -- se desvanece antes de volver
Knock.MaxSize = 14 -- nada más grande que esto es un objeto suelto
Knock.MaxMass = 250
Knock.CharacterMass = 70

-- Grupos de choque: los objetos que salen despedidos no paran los rayos del coche (Driving): el coche
-- pasa y el objeto sale volando, en vez de frenar en seco contra una papelera
Knock.Group = "Knockable"
Knock.RayGroup = "VehicleRay"

export type Profile = {
	Mass: number,
	Model: boolean?, -- el objeto es un Model entero (moto de adorno, banco, señal)
	MinSpeed: number?, -- por debajo, no se mueve (pesado)
	Where: { string }?, -- solo si está dentro de algo con uno de estos nombres (la calle, no un interior)
	Companions: { string }?, -- piezas sueltas de al lado que van con él (patas, sombrilla, fruta)
	Reach: number?, -- a qué distancia (en planta) se buscan esas piezas
	Lift: number?, -- cuánto sube (1 = normal)
}

local STREET = { "Streets", "MainRoads", "Detalles", "Obras" }
local FRONT = { "Escaparate" }

Knock.Catalog = {
	-- Piezas sueltas
	Bin = { Mass = 25, Where = { "Streets", "MainRoads", "Casa", "Detalles" } }, -- papeleras (etiqueta Papelera) y cubos de las casas
	Cone = { Mass = 5, Where = STREET, Lift = 1.2 },
	WorksBarrier = { Mass = 40, Where = { "Obras" } },
	WorksFence = { Mass = 30, Where = { "Obras" }, Companions = { "WorksStripe" }, Reach = 1 }, -- (la franja blanca va con la valla)
	TerraceChair = { Mass = 8, Where = FRONT, Lift = 1.1 },
	TerraceTable = { Mass = 20, Where = FRONT, Companions = { "TableLeg", "UmbrellaPole", "Umbrella" }, Reach = 1.8 },
	SandwichBoard = { Mass = 10, Where = FRONT },
	MenuBoard = { Mass = 6, Where = FRONT },
	Crate = { Mass = 15, Where = FRONT, Companions = { "Fruit" }, Reach = 1.3 },
	Bucket = { Mass = 6, Where = FRONT, Companions = { "Bouquet" }, Reach = 0.6 }, -- (las flores van con el cubo)
	Pot = { Mass = 30, Where = FRONT, Companions = { "PotPlant" }, Reach = 0.9 },
	UmbrellaPole = { Mass = 12, Where = { "Playa", "Playas" }, Companions = { "Umbrella" }, Reach = 1.2, Lift = 0.8 },
	Container = { Mass = 160, Where = { "Reciclaje" }, MinSpeed = 22, Lift = 0.5 }, -- iglú de reciclaje: solo muy fuerte
	-- Objetos enteros (Model)
	MotoAparcada = { Mass = 110, Model = true, Where = STREET },
	Bench = { Mass = 70, Model = true, Where = { "Jardin" }, MinSpeed = 16, Lift = 0.7 },
	Senal = { Mass = 35, Model = true, Where = STREET, MinSpeed = 26, Lift = 0.6 },
} :: { [string]: Profile }

-- Lo que NO se mueve nunca (estructural o pesado de verdad): para la documentación y las pruebas
Knock.Solid = {
	"StreetLamp", "TrafficLight", "Bollard", "Planter", "Jardinera", "Hydrant", "BocaRiego", "KioskBody",
	"QuioscoPrensa", "Cabinet", "ArmarioElectrico", "Tree", "Palm", "Wall", "Aparcabicis", "ParadaBus",
}

-- ¿Se puede tumbar esto? name/className = los de la pieza o el Model; ancestors = los nombres de sus
-- padres (de cerca a lejos); size = su tamaño. nil = sigue sólido.
function Knock.profile(name: string, className: string, ancestors: { string }, size: Vector3?): Profile?
	local p = Knock.Catalog[name]
	if not p then
		return nil
	end
	local isModel = className == "Model"
	if (p.Model == true) ~= isModel then
		return nil
	end
	if p.Where then
		local found = false
		for _, a in ancestors do
			if table.find(p.Where, a) then
				found = true
				break
			end
		end
		if not found then
			return nil
		end
	end
	if size and math.max(size.X, size.Y, size.Z) > Knock.MaxSize then
		return nil
	end
	if p.Mass > Knock.MaxMass then
		return nil
	end
	return p
end

function Knock.isSolid(name: string): boolean
	return table.find(Knock.Solid, name) ~= nil
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- La velocidad (y el giro) que coge un objeto al darle algo de masa hitterMass que va (respecto al
-- objeto) a relVel. awayDir = del que golpea hacia el objeto (por si relVel es casi nula).
-- mode: "none" (no se mueve), "tip" (se vuelca / se empuja) o "launch" (sale volando).
function Knock.launch(profile: Profile, relVel: Vector3, hitterMass: number, awayDir: Vector3?): (Vector3, Vector3, string)
	local v = flat(relVel)
	local speed = v.Magnitude
	if speed ~= speed or speed < math.max(Knock.MinSpeed, profile.MinSpeed or 0) then
		return Vector3.zero, Vector3.zero, "none"
	end
	local dir = v.Unit
	-- Un poco hacia donde estaba el objeto respecto al golpe (no sale siempre recto)
	if awayDir then
		local a = flat(awayDir)
		if a.Magnitude > 1e-3 then
			local mix = dir * 0.8 + a.Unit * 0.2
			if mix.Magnitude > 1e-3 then
				dir = mix.Unit
			end
		end
	end
	local m = math.max(profile.Mass, 1)
	local share = (1 + Knock.Restitution) * hitterMass / (hitterMass + m)
	local out = speed * share
	local axis = dir:Cross(Vector3.yAxis) -- vuelca hacia delante
	local lift = profile.Lift or 1
	if speed < Knock.TipSpeed then
		local push = math.min(out * 0.6, 9)
		return dir * push + Vector3.new(0, 2 * lift, 0), -axis * (2 + speed * 0.25), "tip"
	end
	local horizontal = math.min(out, Knock.MaxLaunch)
	local up = math.min((4 + speed * 0.45) * lift, Knock.MaxLift)
	local spin = math.min(speed * 0.25, Knock.MaxSpin)
	return dir * horizontal + Vector3.new(0, up, 0), -axis * spin, "launch"
end

-- Hasta dónde llega (en llano, sin rodar): para las pruebas y para no tirar nada a 1 km
function Knock.range(vel: Vector3): number
	local up = math.max(vel.Y, 0)
	local air = 2 * up / Knock.Gravity
	return flat(vel).Magnitude * air
end

---------------------------------------------------------------------
-- Personas
---------------------------------------------------------------------
export type PersonHit = {
	Mode: string, -- "none", "stumble" (traspiés), "fall" (al suelo) o "launch" (por los aires)
	Vel: Vector3, -- velocidad que coge (plana hacia donde le empujan + hacia arriba)
	Down: number, -- segundos en el suelo
	Damage: number, -- vida que quita (a los jugadores, con las reglas de CombatService)
}

Knock.PersonSpeeds = { Stumble = 5, Fall = 14, Launch = 28 }

function Knock.person(relVel: Vector3, hitterMass: number?): PersonHit
	local v = flat(relVel)
	local speed = v.Magnitude
	local S = Knock.PersonSpeeds
	if speed ~= speed or speed < S.Stumble then
		return { Mode = "none", Vel = Vector3.zero, Down = 0, Damage = 0 }
	end
	local dir = v.Unit
	-- Un peatón que choca con otro peatón no le tira como un coche
	local heavy = (hitterMass or 1300) > Knock.CharacterMass * 2
	if speed < S.Fall or not heavy then
		return { Mode = "stumble", Vel = dir * math.min(speed * 0.5, 8) + Vector3.new(0, 3, 0), Down = 0, Damage = 0 }
	end
	if speed < S.Launch then
		return { Mode = "fall", Vel = dir * math.min(speed * 0.5, 16) + Vector3.new(0, 10, 0), Down = 2.5, Damage = math.floor(5 + (speed - S.Fall) * 0.7) }
	end
	local horizontal = math.min(speed * 0.75, 55)
	local up = math.min(12 + speed * 0.3, 34)
	local damage = math.floor(math.clamp((speed - 20) * 1.1, 15, 60))
	return { Mode = "launch", Vel = dir * horizontal + Vector3.new(0, up, 0), Down = 3.5, Damage = damage }
end

-- Postura de alguien atropellado t segundos después del golpe (para los peatones y NPC, que no tienen
-- física): cuánto se ha desplazado desde donde estaba, cuánto está tumbado (0 de pie, 1 en el suelo)
-- y si ya ha terminado (de pie otra vez).
Knock.GetUp = 0.9
function Knock.personPose(t: number, hit: PersonHit): (Vector3, number, boolean)
	if hit.Mode == "none" then
		return Vector3.zero, 0, true
	end
	local vel = hit.Vel
	local h = flat(vel)
	local air = 2 * math.max(vel.Y, 0) / Knock.Gravity
	local slide = if hit.Mode == "stumble" then 0.15 else 0.3 -- sigue un poco arrastrándose por el suelo
	local landed = h * air
	local final = landed + h * slide * 0.5
	if hit.Mode == "stumble" then
		-- Traspiés: un par de pasos atrás y a su sitio
		local k = math.clamp(t / 0.6, 0, 1)
		local lean = math.sin(k * math.pi) * 0.35
		return h * 0.25 * math.sin(k * math.pi / 2), lean, t >= 0.6
	end
	if t < air then
		local y = vel.Y * t - Knock.Gravity * t * t / 2
		return h * t + Vector3.new(0, math.max(y, 0), 0), math.clamp(t / math.max(air, 0.05), 0, 1), false
	end
	local after = t - air
	if after < slide then
		local k = after / slide
		return landed + h * slide * 0.5 * (1 - (1 - k) * (1 - k)), 1, false
	end
	if after < slide + hit.Down then
		return final, 1, false
	end
	local up = after - slide - hit.Down
	if up < Knock.GetUp then
		return final, 1 - up / Knock.GetUp, false
	end
	return final, 0, true
end

-- Tiempo total hasta que está de pie otra vez
function Knock.personTime(hit: PersonHit): number
	if hit.Mode == "none" then
		return 0
	elseif hit.Mode == "stumble" then
		return 0.6
	end
	local air = 2 * math.max(hit.Vel.Y, 0) / Knock.Gravity
	return air + 0.3 + hit.Down + Knock.GetUp
end

---------------------------------------------------------------------
-- Vuelta a su sitio y presupuesto
---------------------------------------------------------------------
export type Loose = {
	Since: number, -- cuándo salió despedido
	RestSince: number?, -- desde cuándo está quieto (nil = se mueve)
}

-- ¿Vuelve ya a su sitio? pos/home = dónde está y dónde estaba; spotBusy = hay alguien encima de su sitio
function Knock.shouldRespawn(state: Loose, now: number, pos: Vector3, home: Vector3, spotBusy: boolean): boolean
	if pos.Y < home.Y - Knock.FallDepth or pos.Y ~= pos.Y then
		return not spotBusy -- (caído del mapa: en cuanto su sitio esté libre)
	end
	if spotBusy then
		return false
	end
	if state.RestSince and now - state.RestSince >= Knock.RestSeconds then
		return true
	end
	return now - state.Since >= Knock.MaxLife
end

-- ¿Lleva tanto fuera que, aunque su sitio esté ocupado, hay que quitarlo de la calle? (se esconde y
-- vuelve cuando el sitio quede libre)
function Knock.shouldHide(state: Loose, now: number): boolean
	return now - state.Since >= Knock.HideAfter
end

-- Lo que va ENCIMA de un objeto que se puede tumbar y no es de él (una franja, unas flores, una tapa):
-- si el objeto sale despedido, eso se quedaría flotando. Devuelve los índices de `others` que van con
-- él. seed / others = { CFrame, Size, Name, Anchored? }. Solo piezas ancladas, no más grandes que el
-- objeto (como mucho el doble de volumen) que tocan su caja y tienen el centro más alto que el suyo.
-- Las que son a su vez objetos que se tumban (Knock.Catalog) o compañeras de uno (Companions) van
-- por su cuenta.
local function boxOf(cf: CFrame, size: Vector3): (Vector3, Vector3)
	local r, u, l = cf.RightVector * size.X / 2, cf.UpVector * size.Y / 2, cf.LookVector * size.Z / 2
	local ext = Vector3.new(
		math.abs(r.X) + math.abs(u.X) + math.abs(l.X),
		math.abs(r.Y) + math.abs(u.Y) + math.abs(l.Y),
		math.abs(r.Z) + math.abs(u.Z) + math.abs(l.Z)
	)
	return cf.Position - ext, cf.Position + ext
end
function Knock.riders(seed: { [string]: any }, others: { { [string]: any } }): { number }
	local out = {}
	local lo, hi = boxOf(seed.CFrame, seed.Size)
	local biggest = math.max(seed.Size.X, seed.Size.Y, seed.Size.Z) * 1.5 + 0.2
	local volume = seed.Size.X * seed.Size.Y * seed.Size.Z * 2 + 0.5
	local owned = {}
	for _, profile in Knock.Catalog do
		for _, name in profile.Companions or {} do
			owned[name] = true
		end
	end
	local e = 0.06
	for i, o in others do
		if o.Anchored == false or Knock.Catalog[o.Name] or owned[o.Name] then
			continue
		end
		if math.max(o.Size.X, o.Size.Y, o.Size.Z) > biggest or o.Size.X * o.Size.Y * o.Size.Z > volume then
			continue
		end
		local olo, ohi = boxOf(o.CFrame, o.Size)
		local touches = lo.X <= ohi.X + e and hi.X >= olo.X - e and lo.Y <= ohi.Y + e and hi.Y >= olo.Y - e and lo.Z <= ohi.Z + e and hi.Z >= olo.Z - e
		-- (más alto que el objeto y sin apoyo propio en el suelo: su parte de abajo, por encima de la del objeto)
		if touches and o.CFrame.Position.Y > seed.CFrame.Position.Y and olo.Y > lo.Y + 0.15 then
			table.insert(out, i)
		end
	end
	return out
end

-- Actualiza «quieto desde» con la velocidad de ahora
function Knock.rest(state: Loose, now: number, speed: number)
	if speed < 0.5 then
		state.RestSince = state.RestSince or now
	else
		state.RestSince = nil
	end
end

-- Presupuesto: ¿cabe uno más? Si no, cuál de los sueltos vuelve antes (el más antiguo)
function Knock.admit(loose: { [any]: Loose }, budget: number?): (boolean, any?)
	local count, oldest, oldestAt = 0, nil, math.huge
	for key, state in loose do
		count += 1
		if state.Since < oldestAt then
			oldest, oldestAt = key, state.Since
		end
	end
	if count < (budget or Knock.Budget) then
		return true, nil
	end
	return false, oldest
end

---------------------------------------------------------------------
-- Servidor: ¿es posible este golpe que avisa un cliente?
---------------------------------------------------------------------
Knock.Server = { LagSlack = 5, LagTime = 0.35, SpeedSlack = 1.25, Gap = 0.25, Burst = 12, BurstWindow = 2 }

-- hitterPos/hitterReach: dónde está el que golpea y cuánto abulta (media diagonal); targetPos/
-- targetReach: lo mismo del objeto o la persona; speed = la velocidad que dice llevar; maxSpeed = la
-- que puede llevar (su vehículo o corriendo)
function Knock.plausible(hitterPos: Vector3, hitterReach: number, targetPos: Vector3, targetReach: number, speed: number, maxSpeed: number): (boolean, string?)
	local S = Knock.Server
	if typeof(speed) ~= "number" or speed ~= speed or speed < 0 then
		return false, "velocidad rara"
	end
	if speed > maxSpeed * S.SpeedSlack + 6 then
		return false, "velocidad imposible"
	end
	local d = flat(targetPos - hitterPos).Magnitude
	if math.abs(targetPos.Y - hitterPos.Y) > 12 then
		return false, "altura"
	end
	if d > hitterReach + targetReach + S.LagSlack + speed * S.LagTime then
		return false, "lejos"
	end
	return true, nil
end

return Knock
