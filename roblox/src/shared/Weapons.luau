-- Weapons: armas de fuego (y de juguete) — datos y cuentas puras. Lo usan WeaponService (servidor),
-- WeaponController / WeaponFx / WeaponMotion (cliente) y scripts/test-weapons.luau.
--
-- Reglas de la vida en Valmar:
--   * Las armas de verdad solo las llevan los adultos (desde AdultoJoven) con LICENCIA DE ARMAS
--     (se saca pagando en la comisaría o en la Armería, sin estrellas de búsqueda ni antecedentes).
--   * Los niños y adolescentes pueden jugar con pistolas de agua y de paintball (no hacen daño).
--   * La policía de servicio lleva pistola reglamentaria y táser (munición de la comisaría).
--   * Disparar a una persona es un delito (Disparo); disparar en plena calle, también (Disparos),
--     salvo la policía de servicio contra alguien buscado y dentro de la galería de tiro.
--   * No se puede disparar en zonas seguras: hospitales, colegios, dentro de casas y edificios.
--
-- Unidades: distancias en studs, ángulos en grados, tiempos en segundos.
-- Cada arma: daño, cadencia (disparos por minuto), cargador (+1 en la recámara si recargas sin
-- vaciarlo), recarga táctica / en vacío, alcance y caída de daño, dispersión (desde la cadera y
-- apuntando, y cuánto crece al moverte), retroceso (subida, lado, cómo se acumula y cómo vuelve),
-- modos de fuego, munición, modelo hecho con piezas, sonidos y cómo se sujeta.

local Weapons = {}

local rgb = Color3.fromRGB

export type Part = {
	Name: string,
	Size: Vector3,
	At: CFrame, -- respecto a la empuñadura: -Z hacia el cañón, +Y hacia arriba
	Color: Color3,
	Material: string?,
	Shape: string?, -- "Cylinder" (a lo largo de X) o nada (bloque)
	Neon: boolean?,
}

export type Weapon = {
	Id: string,
	Name: string,
	Icon: string,
	Class: string, -- Pistola, Revolver, Escopeta, Subfusil, Fusil, Francotirador, Taser, Agua, Paintball
	Kind: string, -- "Real" | "Toy" | "Taser"
	Hands: number, -- 1 = una mano (apuntando se ayuda con la otra), 2 = dos manos
	Stock: boolean, -- tiene culata (la mejilla va en ella al apuntar)
	Damage: number, -- por bala (o por perdigón)
	Pellets: number,
	Head: number, -- multiplicador en la cabeza
	Limb: number, -- multiplicador en brazos y piernas
	RPM: number, -- disparos por minuto
	Modes: { string }, -- "Semi" | "Auto" (el primero es el de fábrica)
	Magazine: number,
	Chamber: boolean, -- una más en la recámara al recargar sin vaciar
	Reload: { Tactical: number, Empty: number, PerRound: number?, Start: number? },
	Range: number,
	Falloff: { Start: number, End: number, Min: number },
	Spread: { Hip: number, Aim: number, Move: number, Bloom: number, MaxBloom: number },
	Recoil: { Up: number, Side: number, Bias: number, Build: number, MaxBuild: number, Return: number, Body: number },
	Velocity: number, -- velocidad de la bala (studs/s): cuánto tarda en verse el trazador
	Ammo: string?, -- objeto de munición (nil = infinita: juguetes de agua y armas de servicio)
	Price: number?, -- en la Armería (nil = no se vende)
	MinStage: string,
	Licence: boolean,
	Duty: boolean?, -- de la policía (se da al empezar el turno)
	Stun: number?, -- táser: segundos sin poder moverse
	Casing: string?, -- "Brass" | "Shell" | "Revolver" (todos al recargar) | nil
	Tracer: string, -- "Bullet" | "Wire" | "Water" | "Paint"
	Holster: string, -- "Hip" | "Back"
	Length: number, -- del puño a la boca del cañón (para no meterlo en las paredes)
	Muzzle: Vector3, -- boca del cañón respecto a la empuñadura
	Eject: Vector3, -- ventana de expulsión
	AimFov: number,
	Scope: boolean?,
	Loud: number, -- 0..1: cuánto se oye (los testigos y la policía)
	Sound: { Shot: string, Pitch: number, Volume: number, Tail: boolean },
	Parts: { Part },
}

Weapons.Licence = {
	Price = 350, -- tasa (se paga al empezar el test; si suspendes, vuelves a pagar)
	MinStage = "AdultoJoven",
	Item = "LicenciaArmas",
	Questions = 5, -- preguntas del test de seguridad
	ToPass = 4,
}

-- Test de seguridad de la licencia: la primera respuesta es la buena (se barajan al preguntar)
Weapons.Quiz = {
	{ "¿Cómo se lleva un arma cuando no vas a disparar?", { "Descargada o con el seguro, apuntando a un lugar seguro", "Con el dedo en el gatillo por si acaso", "Apuntando a la gente para que se aparte" } },
	{ "¿Dónde debe estar el dedo hasta el momento de disparar?", { "Fuera del gatillo, estirado junto al armazón", "Dentro del gatillo", "Da igual" } },
	{ "¿Se puede disparar en la calle para celebrar algo?", { "No: es un delito y es muy peligroso", "Sí, si es al aire", "Sí, en fiestas" } },
	{ "Antes de disparar en la galería de tiro, ¿qué compruebas?", { "Qué hay detrás de la diana y que nadie esté en la calle de tiro", "Nada, la diana ya para las balas", "Que haya público mirando" } },
	{ "¿Quién puede comprar un arma de fuego en Valmar?", { "Un adulto con licencia de armas y sin antecedentes", "Cualquiera que tenga dinero", "Los adolescentes acompañados" } },
	{ "Un amigo te pide tu arma prestada. ¿Qué haces?", { "No se la dejo: el arma es personal y con licencia", "Se la dejo si es mayor", "Se la dejo sin balas" } },
	{ "¿Qué haces si un arma falla al disparar?", { "Sigo apuntando a lugar seguro, espero y la reviso descargada", "Miro por el cañón", "La golpeo contra el suelo" } },
	{ "¿Dónde se guardan las armas en casa?", { "Descargadas y bajo llave, lejos de los niños", "En un cajón de la cocina", "Encima de la mesa" } },
}

-- Nota del test: respuestas (índices) contra las buenas
function Weapons.gradeQuiz(correct: { number }, answers: { any }): (number, boolean)
	local right = 0
	for i, good in correct do
		if answers[i] == good then
			right += 1
		end
	end
	return right, right >= Weapons.Licence.ToPass
end

-- Efectos en el cliente (se reciclan: nunca hay más de esto a la vez)
Weapons.Fx = {
	MaxCasings = 30,
	CasingSeconds = 4,
	MaxHoles = 60,
	HoleSeconds = 20,
	MaxTracers = 24,
	SmokeAfter = 3, -- disparos seguidos para que salga humo del cañón al parar
	HearDistance = 450, -- a más distancia no se oyen los disparos
	PanicRadius = 90, -- la gente de la calle huye si oye disparos a menos de esto
}

-- Postura y cámara al apuntar
Weapons.Aim = {
	BlendTime = 0.17, -- lo que tarda en ponerse al hombro
	Zoom = 7, -- distancia de la cámara apuntando
	WalkFactor = 0.55, -- andar apuntando es más lento
	Fov = 55,
}

-- Cámara al hombro con el arma en la mano (apuntando o no): la mira va en el centro de la pantalla y
-- la cámara se aparta a la derecha (en el eje de la cámara, no del cuerpo) lo justo para que el
-- personaje quede a la izquierda de la mira y nunca debajo de ella. WeaponController la aplica
-- después de la cámara de Roblox, con choque contra paredes; aquí solo las cuentas (test-weapons).
Weapons.Shoulder = {
	HalfWidth = 1.7, -- medio ancho del personaje con el arma en la mano derecha (studs)
	TickPx = 14, -- lo que asoman las marcas de la mira fuera del círculo (con su borde)
	MarginPx = 10, -- hueco mínimo entre la mira y el personaje (píxeles)
	Min = 1.9, -- nunca menos que esto (el hombro de siempre)
	Max = 16, -- ni más (con la cámara muy lejos)
	FirstPerson = 1.6, -- con la cámara más cerca que esto es primera persona: sin hombro
	Blend = 0.3, -- lo que tarda en ponerse o quitarse (s)
	Up = { Stand = 0.35, Crouch = -0.2, Prone = -1.2 }, -- altura sobre la cabeza según la postura
}

-- Radio exterior de la mira en píxeles (círculo con sus topes + las marcas)
function Weapons.reticleOuter(w: Weapon, spreadDeg: number, fov: number, viewportHeight: number): number
	local radius = math.clamp(Weapons.reticleRadius(spreadDeg, fov, viewportHeight), 6, 140)
	if w.Pellets > 1 then
		radius = math.max(radius, 22)
	end
	return radius + Weapons.Shoulder.TickPx
end

-- Desplazamiento de la cámara al hombro, en el eje de la cámara: (a la derecha, arriba) en studs.
-- distance = de la cámara a la cabeza; outerPx = Weapons.reticleOuter. El personaje (medio ancho
-- HalfWidth) queda a la izquierda del centro con al menos outerPx + MarginPx de hueco.
function Weapons.shoulderOffset(distance: number, fov: number, viewportHeight: number, outerPx: number, stance: string?): (number, number)
	local S = Weapons.Shoulder
	if distance < S.FirstPerson then
		return 0, 0
	end
	local halfTan = math.tan(math.rad(fov / 2))
	local clearTan = (outerPx + S.MarginPx) / math.max(viewportHeight / 2, 1) * halfTan
	local right = math.clamp(S.HalfWidth + distance * clearTan, S.Min, S.Max)
	local up = S.Up[stance or "Stand"] or S.Up.Stand
	return right, up
end

---------------------------------------------------------------------
-- Modelos (hechos con piezas; empuñadura en el origen, cañón hacia -Z)
---------------------------------------------------------------------
local BLACK, STEEL, DARK = rgb(28, 28, 32), rgb(120, 124, 132), rgb(48, 50, 56)
local WOOD = rgb(120, 76, 42)

local function p(name: string, size: Vector3, at: CFrame, color: Color3, material: string?, shape: string?): Part
	return { Name = name, Size = size, At = at, Color = color, Material = material, Shape = shape }
end
local C = CFrame.new
local tilt = CFrame.Angles(math.rad(12), 0, 0)
local barrelX = CFrame.Angles(0, math.rad(90), 0) -- cilindro (eje X) a lo largo del cañón

local function pistolParts(color: Color3, slideColor: Color3): { Part }
	return {
		p("Empunadura", Vector3.new(0.22, 0.55, 0.3), C(0, -0.05, 0.05) * tilt, color, "SmoothPlastic"),
		p("Cargador", Vector3.new(0.17, 0.5, 0.24), C(0, -0.1, 0.06) * tilt, DARK, "Metal"),
		p("Armazon", Vector3.new(0.24, 0.16, 0.85), C(0, 0.23, -0.22), color, "SmoothPlastic"),
		p("Corredera", Vector3.new(0.26, 0.2, 0.95), C(0, 0.4, -0.22), slideColor, "Metal"),
		p("Guardamonte", Vector3.new(0.06, 0.14, 0.3), C(0, 0.1, -0.18), color, "SmoothPlastic"),
		p("Mira", Vector3.new(0.06, 0.07, 0.07), C(0, 0.53, -0.62), BLACK, "Metal"),
		p("Alza", Vector3.new(0.18, 0.07, 0.06), C(0, 0.53, 0.2), BLACK, "Metal"),
	}
end

local function rifleParts(body: Color3, furniture: Color3, long: number, stock: boolean): { Part }
	local list = {
		p("Empunadura", Vector3.new(0.22, 0.5, 0.3), C(0, -0.05, 0.05) * tilt, furniture, "SmoothPlastic"),
		p("Cajon", Vector3.new(0.3, 0.42, 1.5), C(0, 0.35, -0.35), body, "Metal"),
		p("Cargador", Vector3.new(0.2, 0.7, 0.34), C(0, -0.08, -0.62) * CFrame.Angles(math.rad(-10), 0, 0), DARK, "Metal"),
		p("Guardamanos", Vector3.new(0.3, 0.32, 1.1), C(0, 0.33, -1.6), furniture, "SmoothPlastic"),
		p("Canon", Vector3.new(long, 0.1, 0.1), C(0, 0.4, -2.15 - (long - 0.9) / 2) * barrelX, BLACK, "Metal", "Cylinder"),
		p("Corredera", Vector3.new(0.08, 0.1, 0.35), C(0.17, 0.42, -0.25), STEEL, "Metal"),
		p("Mira", Vector3.new(0.12, 0.2, 0.3), C(0, 0.66, -0.3), BLACK, "Metal"),
	}
	if stock then
		table.insert(list, p("Culata", Vector3.new(0.26, 0.45, 1.05), C(0, 0.22, 0.95), furniture, "SmoothPlastic"))
	end
	return list
end

local LIST: { [string]: Weapon } = {
	Pistola = {
		Id = "Pistola", Name = "Pistola 9 mm", Icon = "🔫", Class = "Pistola", Kind = "Real", Hands = 1, Stock = false,
		Damage = 24, Pellets = 1, Head = 2, Limb = 0.75, RPM = 400, Modes = { "Semi" },
		Magazine = 15, Chamber = true, Reload = { Tactical = 1.5, Empty = 2.0 },
		Range = 300, Falloff = { Start = 60, End = 200, Min = 0.6 },
		Spread = { Hip = 2.2, Aim = 0.6, Move = 0.8, Bloom = 0.35, MaxBloom = 2 },
		Recoil = { Up = 1.8, Side = 0.5, Bias = 0.1, Build = 0.05, MaxBuild = 4, Return = 11, Body = 0.6 },
		Velocity = 1200, Ammo = "Municion_9mm", Price = 900, MinStage = "AdultoJoven", Licence = true,
		Casing = "Brass", Tracer = "Bullet", Holster = "Hip", Length = 1.0, Muzzle = Vector3.new(0, 0.4, -0.72), Eject = Vector3.new(0.14, 0.45, -0.1),
		AimFov = 58, Loud = 0.8, Sound = { Shot = "DisparoPistola", Pitch = 1, Volume = 1, Tail = true },
		Parts = pistolParts(BLACK, DARK),
	},
	PistolaPolicia = {
		Id = "PistolaPolicia", Name = "Pistola reglamentaria", Icon = "🔫", Class = "Pistola", Kind = "Real", Hands = 1, Stock = false,
		Damage = 24, Pellets = 1, Head = 2, Limb = 0.75, RPM = 400, Modes = { "Semi" },
		Magazine = 15, Chamber = true, Reload = { Tactical = 1.4, Empty = 1.9 },
		Range = 300, Falloff = { Start = 60, End = 200, Min = 0.6 },
		Spread = { Hip = 2.0, Aim = 0.5, Move = 0.8, Bloom = 0.3, MaxBloom = 2 },
		Recoil = { Up = 1.7, Side = 0.45, Bias = 0.1, Build = 0.05, MaxBuild = 4, Return = 11, Body = 0.6 },
		Velocity = 1200, Ammo = nil, MinStage = "AdultoJoven", Licence = false, Duty = true,
		Casing = "Brass", Tracer = "Bullet", Holster = "Hip", Length = 1.0, Muzzle = Vector3.new(0, 0.4, -0.72), Eject = Vector3.new(0.14, 0.45, -0.1),
		AimFov = 58, Loud = 0.8, Sound = { Shot = "DisparoPistola", Pitch = 0.97, Volume = 1, Tail = true },
		Parts = pistolParts(DARK, BLACK),
	},
	Revolver = {
		Id = "Revolver", Name = "Revólver .357", Icon = "🔫", Class = "Revolver", Kind = "Real", Hands = 1, Stock = false,
		Damage = 45, Pellets = 1, Head = 2, Limb = 0.75, RPM = 130, Modes = { "Semi" },
		Magazine = 6, Chamber = false, Reload = { Tactical = 2.6, Empty = 2.6 },
		Range = 320, Falloff = { Start = 70, End = 220, Min = 0.6 },
		Spread = { Hip = 2.8, Aim = 0.5, Move = 0.9, Bloom = 0.8, MaxBloom = 3 },
		Recoil = { Up = 4.2, Side = 0.8, Bias = 0.3, Build = 0.02, MaxBuild = 2, Return = 8, Body = 1 },
		Velocity = 1300, Ammo = "Municion_357", Price = 1400, MinStage = "AdultoJoven", Licence = true,
		Casing = "Revolver", Tracer = "Bullet", Holster = "Hip", Length = 1.2, Muzzle = Vector3.new(0, 0.42, -0.95), Eject = Vector3.new(0, 0.4, -0.2),
		AimFov = 56, Loud = 0.95, Sound = { Shot = "DisparoRevolver", Pitch = 1, Volume = 1, Tail = true },
		Parts = {
			p("Empunadura", Vector3.new(0.22, 0.55, 0.32), C(0, -0.05, 0.05) * CFrame.Angles(math.rad(18), 0, 0), WOOD, "Wood"),
			p("Armazon", Vector3.new(0.22, 0.3, 0.55), C(0, 0.3, -0.1), STEEL, "Metal"),
			p("Tambor", Vector3.new(0.4, 0.34, 0.34), C(0, 0.3, -0.2) * barrelX, STEEL, "Metal", "Cylinder"),
			p("Canon", Vector3.new(0.75, 0.13, 0.13), C(0, 0.42, -0.62) * barrelX, STEEL, "Metal", "Cylinder"),
			p("Martillo", Vector3.new(0.06, 0.12, 0.1), C(0, 0.5, 0.18), STEEL, "Metal"),
			p("Mira", Vector3.new(0.05, 0.08, 0.06), C(0, 0.52, -0.92), STEEL, "Metal"),
		},
	},
	Escopeta = {
		Id = "Escopeta", Name = "Escopeta de corredera", Icon = "🔫", Class = "Escopeta", Kind = "Real", Hands = 2, Stock = true,
		Damage = 11, Pellets = 8, Head = 1.5, Limb = 0.75, RPM = 70, Modes = { "Semi" },
		Magazine = 6, Chamber = true, Reload = { Tactical = 0.5, Empty = 0.5, PerRound = 0.5, Start = 0.35 },
		Range = 90, Falloff = { Start = 8, End = 45, Min = 0.2 },
		Spread = { Hip = 6.5, Aim = 4.2, Move = 0.35, Bloom = 0.3, MaxBloom = 1.5 },
		Recoil = { Up = 7, Side = 1.2, Bias = 0.4, Build = 0, MaxBuild = 0, Return = 7, Body = 1.5 },
		Velocity = 900, Ammo = "Cartuchos_12", Price = 1800, MinStage = "AdultoJoven", Licence = true,
		Casing = "Shell", Tracer = "Bullet", Holster = "Back", Length = 3.3, Muzzle = Vector3.new(0, 0.45, -3.2), Eject = Vector3.new(0.18, 0.4, -0.4),
		AimFov = 60, Loud = 1, Sound = { Shot = "DisparoEscopeta", Pitch = 1, Volume = 1.2, Tail = true },
		Parts = (function()
			local list = rifleParts(DARK, WOOD, 1.9, true)
			for _, part in list do
				if part.Name == "Cargador" then
					-- (la escopeta no tiene cargador: tubo bajo el cañón)
					part.Name = "Tubo"
					part.Size = Vector3.new(1.6, 0.13, 0.13)
					part.At = C(0, 0.22, -2.0) * barrelX
					part.Shape = "Cylinder"
				end
			end
			return list
		end)(),
	},
	Subfusil = {
		Id = "Subfusil", Name = "Subfusil 9 mm", Icon = "🔫", Class = "Subfusil", Kind = "Real", Hands = 2, Stock = true,
		Damage = 18, Pellets = 1, Head = 1.8, Limb = 0.75, RPM = 800, Modes = { "Auto", "Semi" },
		Magazine = 30, Chamber = true, Reload = { Tactical = 2.0, Empty = 2.6 },
		Range = 200, Falloff = { Start = 30, End = 120, Min = 0.5 },
		Spread = { Hip = 3.0, Aim = 1.2, Move = 0.6, Bloom = 0.18, MaxBloom = 2.5 },
		Recoil = { Up = 1.0, Side = 0.8, Bias = 0.15, Build = 0.06, MaxBuild = 10, Return = 12, Body = 0.5 },
		Velocity = 1150, Ammo = "Municion_9mm", Price = 2600, MinStage = "AdultoJoven", Licence = true,
		Casing = "Brass", Tracer = "Bullet", Holster = "Back", Length = 2.2, Muzzle = Vector3.new(0, 0.4, -2.3), Eject = Vector3.new(0.18, 0.42, -0.3),
		AimFov = 56, Loud = 0.8, Sound = { Shot = "DisparoSubfusil", Pitch = 1.1, Volume = 0.9, Tail = true },
		Parts = rifleParts(BLACK, DARK, 0.6, true),
	},
	Fusil = {
		Id = "Fusil", Name = "Fusil de asalto", Icon = "🔫", Class = "Fusil", Kind = "Real", Hands = 2, Stock = true,
		Damage = 32, Pellets = 1, Head = 2, Limb = 0.75, RPM = 700, Modes = { "Auto", "Semi" },
		Magazine = 30, Chamber = true, Reload = { Tactical = 2.2, Empty = 2.9 },
		Range = 600, Falloff = { Start = 150, End = 500, Min = 0.7 },
		Spread = { Hip = 3.2, Aim = 0.35, Move = 0.9, Bloom = 0.15, MaxBloom = 2 },
		Recoil = { Up = 1.3, Side = 0.6, Bias = 0.2, Build = 0.07, MaxBuild = 10, Return = 10, Body = 0.8 },
		Velocity = 2900, Ammo = "Municion_556", Price = 4200, MinStage = "AdultoJoven", Licence = true,
		Casing = "Brass", Tracer = "Bullet", Holster = "Back", Length = 3.3, Muzzle = Vector3.new(0, 0.4, -3.1), Eject = Vector3.new(0.18, 0.42, -0.3),
		AimFov = 55, Loud = 1, Sound = { Shot = "DisparoFusil", Pitch = 1, Volume = 1.1, Tail = true },
		Parts = rifleParts(BLACK, DARK, 1.0, true),
	},
	Francotirador = {
		Id = "Francotirador", Name = "Rifle de francotirador", Icon = "🔭", Class = "Francotirador", Kind = "Real", Hands = 2, Stock = true,
		Damage = 95, Pellets = 1, Head = 2.5, Limb = 0.8, RPM = 42, Modes = { "Semi" },
		Magazine = 5, Chamber = true, Reload = { Tactical = 3.0, Empty = 3.6 },
		Range = 1200, Falloff = { Start = 400, End = 1200, Min = 0.85 },
		Spread = { Hip = 8, Aim = 0.05, Move = 3, Bloom = 0, MaxBloom = 0 },
		Recoil = { Up = 8, Side = 1, Bias = 0.2, Build = 0, MaxBuild = 0, Return = 5, Body = 1.4 },
		Velocity = 2800, Ammo = "Municion_308", Price = 6500, MinStage = "AdultoJoven", Licence = true,
		Casing = "Brass", Tracer = "Bullet", Holster = "Back", Length = 4.0, Muzzle = Vector3.new(0, 0.4, -3.9), Eject = Vector3.new(0.18, 0.45, -0.3),
		AimFov = 18, Scope = true, Loud = 1, Sound = { Shot = "DisparoFrancotirador", Pitch = 1, Volume = 1.3, Tail = true },
		Parts = (function()
			local list = rifleParts(rgb(70, 76, 60), rgb(60, 66, 52), 1.8, true)
			for _, part in list do
				if part.Name == "Mira" then
					part.Name = "Visor"
					part.Size = Vector3.new(1.2, 0.2, 0.2)
					part.At = C(0, 0.72, -0.4) * barrelX
					part.Shape = "Cylinder"
					part.Color = BLACK
				end
			end
			return list
		end)(),
	},
	Taser = {
		Id = "Taser", Name = "Táser", Icon = "⚡", Class = "Taser", Kind = "Taser", Hands = 1, Stock = false,
		Damage = 5, Pellets = 1, Head = 1, Limb = 1, RPM = 60, Modes = { "Semi" },
		Magazine = 1, Chamber = false, Reload = { Tactical = 2.2, Empty = 2.2 },
		Range = 25, Falloff = { Start = 25, End = 25, Min = 1 },
		Spread = { Hip = 2.5, Aim = 1, Move = 0.5, Bloom = 0, MaxBloom = 0 },
		Recoil = { Up = 0.6, Side = 0.2, Bias = 0, Build = 0, MaxBuild = 0, Return = 12, Body = 0.2 },
		Velocity = 180, Ammo = nil, MinStage = "AdultoJoven", Licence = false, Duty = true, Stun = 4,
		Casing = nil, Tracer = "Wire", Holster = "Hip", Length = 0.9, Muzzle = Vector3.new(0, 0.35, -0.65), Eject = Vector3.new(0, 0.3, -0.2),
		AimFov = 60, Loud = 0.15, Sound = { Shot = "DisparoTaser", Pitch = 1, Volume = 0.8, Tail = false },
		Parts = (function()
			local list = pistolParts(rgb(250, 210, 30), BLACK)
			table.insert(list, p("Cartucho", Vector3.new(0.28, 0.24, 0.2), C(0, 0.32, -0.72), BLACK, "SmoothPlastic"))
			return list
		end)(),
	},
	PistolaAgua = {
		Id = "PistolaAgua", Name = "Pistola de agua", Icon = "💦", Class = "Agua", Kind = "Toy", Hands = 2, Stock = false,
		Damage = 0, Pellets = 1, Head = 1, Limb = 1, RPM = 480, Modes = { "Auto" },
		Magazine = 40, Chamber = false, Reload = { Tactical = 1.4, Empty = 1.4 },
		Range = 45, Falloff = { Start = 45, End = 45, Min = 1 },
		Spread = { Hip = 3, Aim = 1.5, Move = 0.3, Bloom = 0.1, MaxBloom = 1 },
		Recoil = { Up = 0.2, Side = 0.1, Bias = 0, Build = 0, MaxBuild = 0, Return = 14, Body = 0.1 },
		Velocity = 90, Ammo = nil, Price = 15, MinStage = "Nino", Licence = false,
		Casing = nil, Tracer = "Water", Holster = "Back", Length = 1.6, Muzzle = Vector3.new(0, 0.5, -1.45), Eject = Vector3.new(0, 0.5, 0),
		AimFov = 62, Loud = 0, Sound = { Shot = "DisparoAgua", Pitch = 1, Volume = 0.6, Tail = false },
		Parts = {
			p("Empunadura", Vector3.new(0.24, 0.55, 0.32), C(0, -0.05, 0.05) * tilt, rgb(255, 140, 30), "SmoothPlastic"),
			p("Cuerpo", Vector3.new(0.34, 0.4, 1.3), C(0, 0.4, -0.45), rgb(40, 170, 255), "SmoothPlastic"),
			p("Deposito", Vector3.new(0.5, 0.55, 0.55), C(0, 0.85, -0.1) * barrelX, rgb(120, 220, 255), "Glass", "Cylinder"),
			p("Canon", Vector3.new(0.45, 0.12, 0.12), C(0, 0.5, -1.25) * barrelX, rgb(255, 220, 40), "SmoothPlastic", "Cylinder"),
			p("Bomba", Vector3.new(0.3, 0.26, 0.5), C(0, 0.14, -0.85), rgb(255, 140, 30), "SmoothPlastic"),
		},
	},
	Paintball = {
		Id = "Paintball", Name = "Marcadora de paintball", Icon = "🎨", Class = "Paintball", Kind = "Toy", Hands = 2, Stock = true,
		Damage = 0, Pellets = 1, Head = 1, Limb = 1, RPM = 300, Modes = { "Semi" },
		Magazine = 20, Chamber = false, Reload = { Tactical = 1.8, Empty = 1.8 },
		Range = 120, Falloff = { Start = 120, End = 120, Min = 1 },
		Spread = { Hip = 3.5, Aim = 1.4, Move = 0.5, Bloom = 0.2, MaxBloom = 1.5 },
		Recoil = { Up = 0.5, Side = 0.2, Bias = 0, Build = 0, MaxBuild = 0, Return = 12, Body = 0.2 },
		Velocity = 280, Ammo = "Bolas_Paintball", Price = 60, MinStage = "Nino", Licence = false,
		Casing = nil, Tracer = "Paint", Holster = "Back", Length = 2.2, Muzzle = Vector3.new(0, 0.42, -2.0), Eject = Vector3.new(0, 0.5, 0),
		AimFov = 60, Loud = 0.1, Sound = { Shot = "DisparoPaintball", Pitch = 1, Volume = 0.7, Tail = false },
		Parts = {
			p("Empunadura", Vector3.new(0.22, 0.5, 0.3), C(0, -0.05, 0.05) * tilt, rgb(40, 40, 44), "SmoothPlastic"),
			p("Cuerpo", Vector3.new(0.3, 0.4, 1.2), C(0, 0.35, -0.4), rgb(60, 200, 90), "SmoothPlastic"),
			p("Tolva", Vector3.new(0.5, 0.55, 0.6), C(0, 0.85, -0.3), rgb(255, 230, 40), "SmoothPlastic"),
			p("Canon", Vector3.new(0.9, 0.12, 0.12), C(0, 0.42, -1.45) * barrelX, rgb(40, 40, 44), "Metal", "Cylinder"),
			p("Botella", Vector3.new(0.9, 0.3, 0.3), C(0, 0.2, 0.55) * barrelX, rgb(200, 200, 205), "Metal", "Cylinder"),
		},
	},
}

-- Munición (objetos de la mochila): cuántas balas vienen en cada caja
-- (Real = hace falta la licencia para comprarla)
Weapons.AmmoTypes = {
	Municion_9mm = { Name = "Munición 9 mm", Icon = "🟨", Box = 15, Stack = 240, Price = 30, Real = true },
	Municion_357 = { Name = "Munición .357", Icon = "🟨", Box = 6, Stack = 120, Price = 40, Real = true },
	Cartuchos_12 = { Name = "Cartuchos del 12", Icon = "🟥", Box = 6, Stack = 96, Price = 35, Real = true },
	Municion_556 = { Name = "Munición 5,56", Icon = "🟨", Box = 30, Stack = 300, Price = 45, Real = true },
	Municion_308 = { Name = "Munición .308", Icon = "🟨", Box = 5, Stack = 60, Price = 60, Real = true },
	Bolas_Paintball = { Name = "Bolas de paintball", Icon = "🟢", Box = 40, Stack = 400, Price = 5, Real = false },
}
Weapons.AmmoOrder = { "Bolas_Paintball", "Municion_9mm", "Municion_357", "Cartuchos_12", "Municion_556", "Municion_308" }

-- Orden en el que salen en la tienda
Weapons.ShopOrder = { "PistolaAgua", "Paintball", "Pistola", "Revolver", "Escopeta", "Subfusil", "Fusil", "Francotirador" }

Weapons.List = LIST

for id, w in LIST do
	assert(w.Id == id, "Id distinto en " .. id)
end

function Weapons.get(id: any): Weapon?
	return if type(id) == "string" then LIST[id] else nil
end

-- Objeto de la mochila de cada arma
function Weapons.itemId(id: string): string
	return "Arma_" .. id
end

function Weapons.fromItem(itemId: any): Weapon?
	if type(itemId) ~= "string" then
		return nil
	end
	local id = itemId:match("^Arma_(.+)$")
	return id and LIST[id] or nil
end

---------------------------------------------------------------------
-- Normas: quién puede llevar, comprar y sacarse la licencia
---------------------------------------------------------------------
local ORDER = { Bebe = 1, Nino = 2, Adolescente = 3, AdultoJoven = 4, Adulto = 5, Mayor = 6 }

local function stageAtLeast(stage: string?, min: string): boolean
	if stage == nil then
		return true -- (sin etapa: jugadores antiguos, adultos)
	end
	return (ORDER[stage] or 0) >= (ORDER[min] or 99)
end
Weapons.stageAtLeast = stageAtLeast

-- ¿Puede empuñarla? (los niños no cogen armas de verdad, ni con licencia de otro)
function Weapons.canHold(w: Weapon, stage: string?): boolean
	return stageAtLeast(stage, w.MinStage)
end

export type Buyer = { Stage: string?, Licence: boolean?, Stars: number?, Records: number?, Money: number?, Jailed: boolean? }

-- ¿Puede sacarse la licencia de armas? (ok, motivo)
function Weapons.licenceCheck(b: Buyer): (boolean, string?)
	if not stageAtLeast(b.Stage, Weapons.Licence.MinStage) then
		return false, "La licencia de armas solo se da a mayores de edad."
	elseif b.Licence then
		return false, "Ya tienes la licencia de armas."
	elseif b.Jailed then
		return false, "Estando preso no se tramita ninguna licencia."
	elseif (b.Stars or 0) > 0 then
		return false, "Te está buscando la policía: no te van a dar una licencia."
	elseif (b.Records or 0) > 0 then
		return false, "Tienes antecedentes penales: licencia denegada."
	elseif (b.Money or 0) < Weapons.Licence.Price then
		return false, "No te llega el dinero para la tasa de la licencia."
	end
	return true, nil
end

-- ¿Puede comprar esta arma? (ok, motivo)
function Weapons.buyCheck(w: Weapon, b: Buyer): (boolean, string?)
	if not w.Price then
		return false, "Esto no se vende."
	elseif not stageAtLeast(b.Stage, w.MinStage) then
		return false, if w.Kind == "Real" then "Las armas de verdad solo se venden a adultos con licencia." else "Aún no tienes edad para esto."
	elseif w.Licence and not b.Licence then
		return false, "Necesitas la licencia de armas (comisaría o mostrador de la Armería)."
	elseif w.Kind == "Real" and ((b.Stars or 0) > 0 or b.Jailed) then
		return false, "Con la policía detrás no te venden un arma."
	elseif (b.Money or 0) < w.Price then
		return false, "No te llega el dinero."
	end
	return true, nil
end

---------------------------------------------------------------------
-- Disparar: cadencia, dispersión, daño y retroceso
---------------------------------------------------------------------

-- Segundos entre disparos
function Weapons.interval(w: Weapon): number
	return 60 / w.RPM
end

-- ¿Ya puede volver a disparar? (tolerance: margen para el retraso de la red, 0..0.3)
function Weapons.ready(w: Weapon, lastAt: number, now: number, tolerance: number?): boolean
	return now - lastAt >= Weapons.interval(w) * (1 - (tolerance or 0))
end

export type Stance = { Aiming: boolean?, Speed: number?, Sprinting: boolean?, Airborne: boolean?, Crouching: boolean?, Stance: string?, Bloom: number? }

-- Postura del cuerpo (atributo Stance de la locomoción: "Stand" | "Crouch" | "Prone"; si no está,
-- de pie): (multiplicador de dispersión, multiplicador de retroceso)
function Weapons.stanceFactor(stance: string?): (number, number)
	if stance == "Prone" then
		return 0.45, 0.5
	elseif stance == "Crouch" then
		return 0.7, 0.75
	end
	return 1, 1
end

-- Tumbado no se apunta hacia atrás ni al suelo: (giro máx. a cada lado, mínimo y máximo arriba/abajo), radianes
Weapons.ProneLimits = { Yaw = math.rad(50), PitchMin = math.rad(-20), PitchMax = math.rad(35) }

-- Dirección de disparo tumbado: dentro de los límites respecto a hacia dónde mira el cuerpo
function Weapons.clampProne(bodyLook: Vector3, dir: Vector3): Vector3
	local flatBody = Vector3.new(bodyLook.X, 0, bodyLook.Z)
	if flatBody.Magnitude < 1e-3 or dir.Magnitude < 1e-3 then
		return dir
	end
	flatBody = flatBody.Unit
	local d = dir.Unit
	local bodyYaw = math.atan2(-flatBody.X, -flatBody.Z)
	local yaw = math.atan2(-d.X, -d.Z)
	local rel = (yaw - bodyYaw + math.pi) % (2 * math.pi) - math.pi
	rel = math.clamp(rel, -Weapons.ProneLimits.Yaw, Weapons.ProneLimits.Yaw)
	local pitch = math.clamp(math.asin(math.clamp(d.Y, -1, 1)), Weapons.ProneLimits.PitchMin, Weapons.ProneLimits.PitchMax)
	local finalYaw = bodyYaw + rel
	local horizontal = math.cos(pitch)
	return Vector3.new(-math.sin(finalYaw) * horizontal, math.sin(pitch), -math.cos(finalYaw) * horizontal)
end

-- Dispersión (grados, radio del cono) según cómo estás
function Weapons.spread(w: Weapon, s: Stance): number
	local base = if s.Aiming then w.Spread.Aim else w.Spread.Hip
	local speed = math.clamp((s.Speed or 0) / 16, 0, 1.5)
	local value = base * (1 + speed * w.Spread.Move)
	if s.Sprinting then
		value *= 2
	end
	if s.Airborne then
		value *= 2.5
	end
	if s.Crouching and s.Stance == nil then
		value *= 0.7
	end
	value *= (Weapons.stanceFactor(s.Stance))
	value += math.clamp(s.Bloom or 0, 0, w.Spread.MaxBloom)
	return value
end

-- Crecimiento de la dispersión al disparar seguido (y cómo se recupera con el tiempo)
function Weapons.bloomAfter(w: Weapon, bloom: number, since: number): number
	local recovered = math.max(0, bloom - since * w.Spread.MaxBloom * 2.5)
	return math.min(w.Spread.MaxBloom, recovered + w.Spread.Bloom)
end

-- Dirección con dispersión: dir (unitario), cone en grados, u y v aleatorios en [0, 1)
function Weapons.scatter(dir: Vector3, cone: number, u: number, v: number): Vector3
	if cone <= 0 then
		return dir
	end
	local up = if math.abs(dir.Y) > 0.99 then Vector3.new(1, 0, 0) else Vector3.new(0, 1, 0)
	local right = dir:Cross(up).Unit
	local up2 = right:Cross(dir).Unit
	-- Más probable cerca del centro (como de verdad): radio con raíz cuadrada invertida
	local r = math.tan(math.rad(cone)) * math.sqrt(u)
	local a = v * math.pi * 2
	return (dir + right * (math.cos(a) * r) + up2 * (math.sin(a) * r)).Unit
end

-- Zona del cuerpo por el nombre de la pieza
function Weapons.zoneOf(partName: string): string
	if partName == "Head" or partName:find("Hat") or partName:find("Hair") then
		return "Head"
	end
	for _, word in { "Arm", "Hand", "Leg", "Foot" } do
		if partName:find(word) then
			return "Limb"
		end
	end
	return "Torso"
end

-- Multiplicador por distancia (1 cerca; baja en línea recta hasta Min)
function Weapons.falloff(w: Weapon, distance: number): number
	local f = w.Falloff
	if distance <= f.Start or f.End <= f.Start then
		return 1
	elseif distance >= f.End then
		return f.Min
	end
	local t = (distance - f.Start) / (f.End - f.Start)
	return 1 + (f.Min - 1) * t
end

-- Daño de una bala (o perdigón) a esa distancia y en esa zona
function Weapons.damageAt(w: Weapon, distance: number, zone: string?): number
	if w.Damage <= 0 or distance > w.Range then
		return 0
	end
	local mult = if zone == "Head" then w.Head elseif zone == "Limb" then w.Limb else 1
	return math.max(1, math.floor(w.Damage * Weapons.falloff(w, distance) * mult + 0.5))
end

-- Retroceso del disparo número `shot` de una ráfaga: (arriba, lado) en grados.
-- El dibujo se repite igual cada vez (se puede aprender a controlar): sube y va de lado a lado.
function Weapons.recoilKick(w: Weapon, shot: number): (number, number)
	local r = w.Recoil
	local build = math.min(math.max(shot - 1, 0), r.MaxBuild)
	local up = r.Up * (1 + build * r.Build)
	local side = r.Bias * r.Side + r.Side * math.sin(shot * 1.7) * (0.6 + 0.4 * math.min(build / math.max(r.MaxBuild, 1), 1))
	return up, side
end

-- Un paso de muelle amortiguado hacia 0 (retroceso que vuelve a su sitio): (valor, velocidad)
function Weapons.spring(x: number, v: number, stiffness: number, dt: number): (number, number)
	dt = math.min(dt, 1 / 20)
	local damping = 2 * math.sqrt(stiffness) -- crítico: vuelve sin pasarse
	local a = -stiffness * x - damping * v
	v += a * dt
	x += v * dt
	if math.abs(x) < 1e-4 and math.abs(v) < 1e-3 then
		return 0, 0
	end
	return x, v
end

---------------------------------------------------------------------
-- Munición y recarga
---------------------------------------------------------------------

-- Cuántas caben (con la recámara si no está vacía)
function Weapons.capacity(w: Weapon, loaded: number): number
	return w.Magazine + (if w.Chamber and loaded > 0 then 1 else 0)
end

export type ReloadPlan = { Mag: number, Used: number, Time: number, Kind: string }

-- Qué pasa al recargar con `loaded` dentro y `reserve` en la mochila (math.huge = infinita)
-- Devuelve nil si no hace falta o no hay balas.
function Weapons.reloadPlan(w: Weapon, loaded: number, reserve: number): ReloadPlan?
	local cap = Weapons.capacity(w, loaded)
	local need = cap - loaded
	if need <= 0 or reserve <= 0 then
		return nil
	end
	local used = math.min(need, reserve)
	if w.Reload.PerRound then
		-- Escopeta: cartucho a cartucho
		return { Mag = loaded + used, Used = used, Time = (w.Reload.Start or 0) + used * w.Reload.PerRound, Kind = "Shells" }
	end
	local empty = loaded <= 0
	return { Mag = loaded + used, Used = used, Time = if empty then w.Reload.Empty else w.Reload.Tactical, Kind = if empty then "Empty" else "Tactical" }
end

-- Siguiente modo de fuego (selector)
function Weapons.nextMode(w: Weapon, current: string?): string
	local i = table.find(w.Modes, current or "") or 0
	return w.Modes[i % #w.Modes + 1]
end

---------------------------------------------------------------------
-- Efectos (cuentas puras del cliente)
---------------------------------------------------------------------

local IMPACT: { [string]: string } = {
	Metal = "Sparks", DiamondPlate = "Sparks", CorrodedMetal = "Sparks", Foil = "Sparks",
	Concrete = "Dust", Brick = "Dust", Cobblestone = "Dust", Slate = "Dust", Granite = "Dust", Marble = "Dust",
	Rock = "Dust", Basalt = "Dust", Pavement = "Dust", Asphalt = "Dust", Limestone = "Dust", Sandstone = "Dust",
	CrackedLava = "Dust", Pebble = "Dust", Salt = "Dust",
	Wood = "Splinters", WoodPlanks = "Splinters",
	Water = "Water",
	Grass = "Dirt", LeafyGrass = "Dirt", Ground = "Dirt", Mud = "Dirt", Sand = "Dirt", Snow = "Dirt", Glacier = "Dirt",
	Glass = "Glass", Ice = "Glass", ForceField = "Glass",
	Fabric = "Puff", Plastic = "Puff", SmoothPlastic = "Puff", Neon = "Puff", Cardboard = "Puff", Carpet = "Puff", Rubber = "Puff",
}

-- Qué sale al dar en un material (por su nombre: "Metal", "Concrete"…)
function Weapons.impactKind(material: string?): string
	return IMPACT[material or ""] or "Dust"
end

-- ¿Deja agujero? (el agua, el cristal que se rompe y las personas no)
function Weapons.leavesHole(kind: string): boolean
	return kind ~= "Water" and kind ~= "Glass" and kind ~= "Character"
end

-- Casquillo: qué sale y cuántos. event = "Shot" | "Reload"
function Weapons.casingFor(w: Weapon, event: string, spent: number?): (string?, number)
	if not w.Casing or w.Kind == "Toy" then
		return nil, 0
	end
	if w.Casing == "Revolver" then
		-- El revólver no expulsa al disparar: suelta todos los vacíos al recargar
		return if event == "Reload" and (spent or 0) > 0 then "Brass" else nil, if event == "Reload" then (spent or 0) else 0
	end
	if event == "Shot" then
		return w.Casing, 1
	end
	return nil, 0
end

-- Velocidad del casquillo al salir: a la derecha, hacia arriba y un poco atrás (en el mundo).
-- right/up/back = ejes del arma; r1, r2 aleatorios en [0, 1)
function Weapons.casingVelocity(right: Vector3, up: Vector3, back: Vector3, r1: number, r2: number): Vector3
	return right * (6 + r1 * 3) + up * (5 + r2 * 3) + back * (1 + r1 * 1.5)
end

-- Cómo suena un disparo según lo lejos que estás y si es dentro o fuera:
-- (volumen 0..1, apagado 0..1 = cuánto se pierden los agudos, eco 0..1)
function Weapons.hearing(distance: number, indoors: boolean, loud: number?): (number, number, number)
	local l = loud or 1
	local far = math.clamp(distance / Weapons.Fx.HearDistance, 0, 1)
	local volume = l * (1 - far) ^ 1.6
	local muffle = math.clamp(far * 1.4, 0, 0.9)
	local echo = if indoors then 0.15 * l else l * (0.25 + 0.45 * far)
	return volume, muffle, echo
end

-- La boca del cañón choca con la pared si está más cerca que el arma
function Weapons.muzzleBlocked(w: Weapon, wallDistance: number?): boolean
	return wallDistance ~= nil and wallDistance < w.Length * 0.9 + 0.4
end

-- Balanceo del arma apuntando (y la respiración en la mira telescópica): (arriba, lado) en grados.
-- holding = conteniendo la respiración (casi quieto)
function Weapons.sway(w: Weapon, t: number, aiming: boolean, holding: boolean?): (number, number)
	local amount = if w.Scope and aiming then 0.35 elseif aiming then 0.08 else 0.25
	if holding then
		amount *= 0.2
	end
	return math.sin(t * 1.3) * amount, math.sin(t * 0.7 + 1) * amount * 1.3
end

-- Campo de visión apuntando
function Weapons.aimFov(w: Weapon?, baseFov: number, aim: number): number
	local target = if w then w.AimFov else Weapons.Aim.Fov
	return baseFov + (target - baseFov) * math.clamp(aim, 0, 1)
end

-- Qué casilla reciclar en una lista con tope: si hay sitio, una nueva (#list + 1); si no, la más vieja
function Weapons.recycleIndex(count: number, cap: number, oldest: number): number
	if count < cap then
		return count + 1
	end
	return oldest
end

-- Radio (píxeles) de la mira para una dispersión en grados
function Weapons.reticleRadius(spreadDeg: number, fov: number, viewportHeight: number): number
	local half = math.tan(math.rad(fov / 2))
	return math.tan(math.rad(spreadDeg)) / half * viewportHeight / 2
end

return Weapons
