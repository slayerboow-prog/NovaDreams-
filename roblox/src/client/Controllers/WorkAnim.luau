-- WorkAnim (cliente): los personajes hacen su oficio o su tarea de casa mientras esperan.
--
-- El servidor pone el atributo "Work" en el personaje (por ejemplo Work = "Sweep") y ActorLife
-- mueve sus brazos, torso y cabeza con estas posturas, encima de su animación de estar de pie.
-- Todo con código: no hay que subir animaciones a Roblox.
--
-- Cada tarea tiene:
--   Pose(t, seed, out)  -> rellena `out` con los ángulos (radianes) de cada articulación
--   Prop                -> objeto que lleva en la mano (escoba, carpeta, móvil…), solo en tu pantalla
--   Walk                -> sigue con la tarea aunque ande (el camarero con la bandeja)
--
-- Ángulos (los mismos que usa ActorLife):
--   np, ny, nr  cabeza: np < 0 mira abajo, ny > 0 gira a su izquierda
--   wp, wy, wr  cintura: wp < 0 se inclina hacia delante
--   rx / lx     hombro: > 0 levanta el brazo hacia delante
--   rz / lz     hombro: > 0 abre el brazo hacia fuera (los dos lados igual)
--   rt / lt     hombro: > 0 gira el brazo hacia dentro (el antebrazo va hacia el pecho)
--   re / le     codo: > 0 dobla el brazo
--   Look        0..1: cuánto deja de mirar la tarea para mirar a la gente (levantar la vista)

local WorkAnim = {}

export type Pose = {
	np: number,
	ny: number,
	nr: number,
	wp: number,
	wy: number,
	wr: number,
	rx: number,
	rz: number,
	rt: number,
	re: number,
	lx: number,
	lz: number,
	lt: number,
	le: number,
	Look: number,
}

export type PropPart = {
	Name: string,
	Hand: "Right" | "Left" | "Torso", -- se sujeta a esa mano (o al pecho: la guitarra)
	Size: Vector3,
	Offset: CFrame, -- desde la mano (se sujeta con una soldadura a esa mano)
	Color: Color3,
	Material: Enum.Material?,
	Shape: Enum.PartType?,
	Transparency: number?,
}

export type Work = {
	Pose: (t: number, seed: number, out: Pose) -> (),
	Prop: { PropPart }?,
	Walk: boolean?,
}

local rgb = Color3.fromRGB
local sin, cos, abs = math.sin, math.cos, math.abs

function WorkAnim.clear(out: Pose)
	out.np, out.ny, out.nr = 0, 0, 0
	out.wp, out.wy, out.wr = 0, 0, 0
	out.rx, out.rz, out.rt, out.re = 0, 0, 0, 0
	out.lx, out.lz, out.lt, out.le = 0, 0, 0, 0
	out.Look = 0
end

-- 0..1 dentro de un ciclo de `period` segundos (cada personaje con su desfase)
local function cycle(t: number, period: number, seed: number): number
	return ((t + seed * 7.3) / period) % 1
end

-- 1 entre a y b (fracciones del ciclo), con subida y bajada suaves de `edge`.
-- Tiene que caber entero en el ciclo (a - edge >= 0, b + edge <= 1): si no, da un tirón al dar la vuelta.
local function window(f: number, a: number, b: number, edge: number): number
	if f < a - edge or f > b + edge then
		return 0
	end
	if f < a then
		return (f - (a - edge)) / edge
	end
	if f > b then
		return 1 - (f - b) / edge
	end
	return 1
end

-- Objetos en la mano. Offset está calculado colocando cada objeto en un R15 con la postura de su
-- tarea (la escoba hasta el suelo, la carpeta y el libro inclinados hacia la cara, la taza derecha…)
local PROPS: { [string]: { PropPart } } = {
	Sweep = {
		{ Name = "Palo", Hand = "Right", Size = Vector3.new(0.14, 4.4, 0.14), Offset = CFrame.new(0.48, -1.41, 0.82) * CFrame.Angles(3.04, 0.95, -0.39), Color = rgb(150, 105, 60), Material = Enum.Material.Wood },
		{ Name = "Cepillo", Hand = "Right", Size = Vector3.new(1.3, 0.35, 0.45), Offset = CFrame.new(1.05, -3.11, 1.81) * CFrame.Angles(-0.70, -1.00, -0.11), Color = rgb(220, 180, 60), Material = Enum.Material.Fabric },
	},
	Clipboard = {
		{ Name = "Carpeta", Hand = "Left", Size = Vector3.new(0.95, 0.06, 1.25), Offset = CFrame.new(0.06, -0.28, -0.18) * CFrame.Angles(-0.45, 0.82, -0.75), Color = rgb(120, 85, 50), Material = Enum.Material.Wood },
		{ Name = "Papel", Hand = "Left", Size = Vector3.new(0.8, 0.02, 1.05), Offset = CFrame.new(0.08, -0.26, -0.21) * CFrame.Angles(-0.45, 0.82, -0.75), Color = rgb(250, 250, 245) },
	},
	Phone = {
		{ Name = "Movil", Hand = "Right", Size = Vector3.new(0.32, 0.06, 0.62), Offset = CFrame.new(0.05, -0.10, -0.10) * CFrame.Angles(0.05, -1.06, 1.25), Color = rgb(25, 25, 30), Material = Enum.Material.Glass },
	},
	Cut = {
		{ Name = "Cuchillo", Hand = "Right", Size = Vector3.new(0.06, 0.9, 0.22), Offset = CFrame.new(0.33, -0.44, 0.02) * CFrame.Angles(-0.94, 0.70, -2.10), Color = rgb(200, 205, 210), Material = Enum.Material.Metal },
	},
	Coffee = {
		{ Name = "Taza", Hand = "Left", Size = Vector3.new(0.45, 0.5, 0.45), Offset = CFrame.new(0.03, -0.16, -0.21) * CFrame.Angles(-1.87, 1.24, 0.61), Color = rgb(250, 250, 250) },
	},
	Tray = {
		{ Name = "Bandeja", Hand = "Left", Size = Vector3.new(0.08, 2.1, 2.1), Offset = CFrame.new(0.21, -0.03, -0.20) * CFrame.Angles(-2.87, -1.27, 0.15), Color = rgb(190, 190, 195), Material = Enum.Material.Metal, Shape = Enum.PartType.Cylinder },
	},
	Wipe = {
		{ Name = "Vaso", Hand = "Left", Size = Vector3.new(0.35, 0.55, 0.35), Offset = CFrame.new(0.03, -0.14, -0.21) * CFrame.Angles(-1.87, 1.24, 0.61), Color = rgb(200, 230, 240), Material = Enum.Material.Glass, Transparency = 0.35 },
		{ Name = "Trapo", Hand = "Right", Size = Vector3.new(0.5, 0.1, 0.5), Offset = CFrame.new(-0.01, -0.05, -0.01) * CFrame.Angles(-2.60, -1.18, -1.28), Color = rgb(240, 240, 235), Material = Enum.Material.Fabric },
	},
	Count = {
		{ Name = "Entradas", Hand = "Left", Size = Vector3.new(0.5, 0.12, 0.8), Offset = CFrame.new(0.01, -0.12, -0.12) * CFrame.Angles(-0.20, 1.08, -0.97), Color = rgb(250, 235, 190) },
	},
	Fold = {
		{ Name = "Ropa", Hand = "Left", Size = Vector3.new(0.9, 0.15, 0.8), Offset = CFrame.new(0.14, -0.22, -0.24) * CFrame.Angles(-1.52, 1.04, 0.57), Color = rgb(90, 140, 200), Material = Enum.Material.Fabric },
	},
	Knit = {
		{ Name = "Ovillo", Hand = "Left", Size = Vector3.new(0.55, 0.55, 0.55), Offset = CFrame.new(-0.04, -0.12, -0.20) * CFrame.Angles(-2.57, 1.22, 1.51), Color = rgb(200, 70, 90), Material = Enum.Material.Fabric, Shape = Enum.PartType.Ball },
		{ Name = "Aguja", Hand = "Right", Size = Vector3.new(0.05, 1, 0.05), Offset = CFrame.new(0.17, -0.11, -0.28) * CFrame.Angles(-1.79, 0.27, -0.31), Color = rgb(210, 210, 215), Material = Enum.Material.Metal },
	},
	Stir = {
		{ Name = "Bol", Hand = "Left", Size = Vector3.new(0.9, 0.4, 0.9), Offset = CFrame.new(-0.02, -0.17, -0.28) * CFrame.Angles(-2.28, 1.21, 1.37), Color = rgb(245, 245, 240) },
		{ Name = "Cuchara", Hand = "Right", Size = Vector3.new(0.08, 0.9, 0.08), Offset = CFrame.new(-0.11, -0.19, 0.20) * CFrame.Angles(0.47, 1.17, 1.52), Color = rgb(160, 115, 70), Material = Enum.Material.Wood },
	},
	Eat = {
		{ Name = "Cuchara", Hand = "Right", Size = Vector3.new(0.08, 0.8, 0.08), Offset = CFrame.new(-0.11, -0.19, 0.20) * CFrame.Angles(0.47, 1.17, 1.52), Color = rgb(200, 200, 205), Material = Enum.Material.Metal },
	},
	Book = {
		{ Name = "Libro", Hand = "Left", Size = Vector3.new(1.2, 0.12, 0.9), Offset = CFrame.new(0.09, -0.32, -0.16) * CFrame.Angles(-0.42, 0.91, -0.86), Color = rgb(150, 40, 40) },
		{ Name = "Hojas", Hand = "Left", Size = Vector3.new(1.1, 0.03, 0.8), Offset = CFrame.new(0.12, -0.30, -0.21) * CFrame.Angles(-0.42, 0.91, -0.86), Color = rgb(250, 248, 238) },
	},
	Hose = {
		{ Name = "Boquilla", Hand = "Right", Size = Vector3.new(0.28, 0.9, 0.28), Offset = CFrame.new(0.36, -0.25, 0.11) * CFrame.Angles(-2.40, 0.60, -1.32), Color = rgb(60, 62, 66), Material = Enum.Material.Metal },
		{ Name = "Manguera", Hand = "Left", Size = Vector3.new(0.3, 3.64, 0.3), Offset = CFrame.new(1.17, -0.72, 1.19) * CFrame.Angles(0.70, -0.86, -1.54), Color = rgb(200, 40, 40), Material = Enum.Material.Plastic },
	},
	Garden = {
		{ Name = "Regadera", Hand = "Right", Size = Vector3.new(0.6, 0.7, 0.9), Offset = CFrame.new(0.16, -0.20, 0.34) * CFrame.Angles(-1.30, -0.38, 0.27), Color = rgb(60, 150, 90), Material = Enum.Material.Plastic },
		{ Name = "Pitorro", Hand = "Right", Size = Vector3.new(0.12, 0.9, 0.12), Offset = CFrame.new(0.40, -0.88, -0.11) * CFrame.Angles(-2.55, -0.39, -0.26), Color = rgb(60, 150, 90), Material = Enum.Material.Plastic },
	},
	Hammer = {
		{ Name = "Mango", Hand = "Right", Size = Vector3.new(0.14, 1, 0.14), Offset = CFrame.new(0.36, -0.17, -0.05) * CFrame.Angles(-2.53, 0.14, -1.14), Color = rgb(150, 105, 60), Material = Enum.Material.Wood },
		{ Name = "Cabeza", Hand = "Right", Size = Vector3.new(0.28, 0.6, 0.28), Offset = CFrame.new(0.75, -0.38, -0.07) * CFrame.Angles(-1.46, -1.07, -0.51), Color = rgb(90, 92, 98), Material = Enum.Material.Metal },
	},
	Rake = {
		{ Name = "Palo", Hand = "Right", Size = Vector3.new(0.14, 4.6, 0.14), Offset = CFrame.new(0.72, -1.41, 0.62) * CFrame.Angles(-2.94, 0.89, -0.71), Color = rgb(150, 105, 60), Material = Enum.Material.Wood },
		{ Name = "Peine", Hand = "Right", Size = Vector3.new(1.5, 0.15, 0.25), Offset = CFrame.new(1.65, -3.24, 1.41) * CFrame.Angles(-0.82, -1.06, -0.16), Color = rgb(90, 92, 98), Material = Enum.Material.Metal },
		{ Name = "Dientes", Hand = "Right", Size = Vector3.new(1.4, 0.3, 0.08), Offset = CFrame.new(1.68, -3.41, 1.52) * CFrame.Angles(-0.82, -1.06, -0.16), Color = rgb(90, 92, 98), Material = Enum.Material.Metal },
	},
	Guitar = {
		{ Name = "Caja", Hand = "Torso", Size = Vector3.new(1.3, 1.6, 0.35), Offset = CFrame.new(0.30, -0.75, -0.72) * CFrame.Angles(-0.00, 0.00, 0.61), Color = rgb(170, 100, 45), Material = Enum.Material.Wood },
		{ Name = "Boca", Hand = "Torso", Size = Vector3.new(0.45, 0.45, 0.02), Offset = CFrame.new(0.30, -0.75, -0.91) * CFrame.Angles(-0.00, 0.00, -0.00), Color = rgb(40, 25, 15) },
		{ Name = "Mastil", Hand = "Torso", Size = Vector3.new(0.2, 0.99, 0.12), Offset = CFrame.new(-0.61, -0.22, -0.80) * CFrame.Angles(-1.57, 0.38, 1.57), Color = rgb(60, 40, 25), Material = Enum.Material.Wood },
	},
	Mop = {
		{ Name = "Palo", Hand = "Right", Size = Vector3.new(0.14, 4.4, 0.14), Offset = CFrame.new(0.48, -1.41, 0.82) * CFrame.Angles(3.04, 0.95, -0.39), Color = rgb(70, 130, 200), Material = Enum.Material.Plastic },
		{ Name = "Mocho", Hand = "Right", Size = Vector3.new(0.9, 0.45, 0.9), Offset = CFrame.new(1.05, -3.11, 1.81) * CFrame.Angles(-0.70, -1.00, -0.11), Color = rgb(220, 220, 215), Material = Enum.Material.Fabric },
	},
}

local function smoothstep(x: number): number
	x = math.clamp(x, 0, 1)
	return x * x * (3 - 2 * x)
end

local function mix(a: number, b: number, w: number): number
	return a + (b - a) * w
end

-- Suma una postura de brazo con peso w: x adelante, t hacia dentro, z hacia fuera, e codo.
-- (Los valores salen de colocar la mano donde debe ir en un personaje R15: carpeta delante del
-- pecho, manos a la altura del mostrador…)
local function right(out: Pose, x: number, t: number, z: number, e: number, w: number?)
	local k = w or 1
	out.rx += x * k
	out.rt += t * k
	out.rz += z * k
	out.re += e * k
end

local function left(out: Pose, x: number, t: number, z: number, e: number, w: number?)
	local k = w or 1
	out.lx += x * k
	out.lt += t * k
	out.lz += z * k
	out.le += e * k
end

-- Manos juntas delante, a la altura del cinturón (de pie, esperando)
local function handsFront(out: Pose, w: number)
	right(out, 0.4, 1.3, -0.4, 0.65, w)
	left(out, 0.4, 1.3, -0.4, 0.65, w)
end

-- Cada 'period' segundos levanta la vista un rato (mira a la gente que pasa)
local function lookUp(t: number, seed: number, period: number, length: number): number
	local f = cycle(t, period, seed + 3)
	return smoothstep(window(f, 0.15, 0.15 + length / period, 0.12))
end

---------------------------------------------------------------------
-- Tareas
---------------------------------------------------------------------

local works: { [string]: Work } = {}

-- Barrer (conserje): la escoba en la derecha, barriendo de lado a lado
works.Sweep = {
	Pose = function(t, seed, out)
		local s = sin(t * 2.4 + seed)
		out.wp = -0.12
		out.wy = s * 0.25
		out.np = -0.35
		out.ny = -s * 0.12
		right(out, 0.55 + s * 0.08, 0.95, -0.4, 0.3)
		left(out, 0.25, 1.4, 0.1, 0.95)
		out.Look = lookUp(t, seed, 11, 2)
	end,
	Prop = PROPS.Sweep,
}

-- Apuntar en una carpeta (médicos, enfermeras, funcionarios, recepcionistas, monitores)
works.Clipboard = {
	Pose = function(t, seed, out)
		local up = lookUp(t, seed, 8, 2.2)
		local write = 1 - up
		out.np = mix(-0.4, -0.02, up)
		left(out, 0.05, 1.05, 0, 1.35)
		right(out, 0.7 - up * 0.2, 1.45, -0.3, 1.2 - up * 0.3)
		out.re += write * sin(t * 13 + seed) * 0.04
		out.rt += write * sin(t * 9 + seed) * 0.05
		out.Look = up
	end,
	Prop = PROPS.Clipboard,
}

-- Mirar el móvil
works.Phone = {
	Pose = function(t, seed, out)
		local up = lookUp(t, seed, 10, 1.8)
		out.np = mix(-0.45, -0.05, up)
		right(out, 0.7, 1.4, -0.4, 1.2)
		left(out, 0.4, 1.55, 0, 1.15)
		out.re += sin(t * 11 + seed) * 0.03 * (1 - up)
		out.Look = up
	end,
	Prop = PROPS.Phone,
}

-- Escribir en el ordenador del mostrador (recepción, taquilla)
works.Type = {
	Pose = function(t, seed, out)
		local up = lookUp(t, seed, 9, 2.5)
		local typing = 1 - up
		out.np = mix(-0.32, 0, up)
		right(out, 0.25, 0.4, -0.4, 1.05)
		left(out, 0.25, 0.4, -0.4, 1.05)
		out.re += typing * sin(t * 15 + seed) * 0.05
		out.le += typing * sin(t * 15 + seed + 1.7) * 0.05
		out.Look = up
	end,
}

-- Pasar productos por la caja (cajero): de derecha a izquierda, y entre cliente y cliente descansa
works.Scan = {
	Pose = function(t, seed, out)
		local f = cycle(t, 7, seed)
		local busy = 1 - smoothstep(window(f, 0.76, 0.92, 0.06))
		local s = (sin(t * 3.9 + seed) + 1) / 2 -- 0 = a su derecha, 1 = pasado hacia la izquierda
		out.np = -0.3 * busy
		out.ny = (s - 0.5) * 0.4 * busy
		out.wy = (s - 0.5) * 0.3 * busy
		right(out, mix(0.5, 0.45, s), mix(0.1, 1.55, s), mix(-0.3, 0, s), mix(0.65, 0.9, s), busy)
		left(out, 0.15, 1.2, 0.1, 0.85, busy)
		handsFront(out, 1 - busy)
		out.Look = 1 - busy
	end,
}

-- Cortar en la charcutería
works.Cut = {
	Pose = function(t, seed, out)
		local f = cycle(t, 6, seed)
		local busy = 1 - smoothstep(window(f, 0.75, 0.92, 0.06))
		local s = (sin(t * 7 + seed) + 1) / 2 * busy -- adelante y atrás
		out.wp = -0.08 * busy
		out.np = -0.4 * busy
		right(out, mix(0.55, 0.9, s), mix(0.6, 1.0, s), -0.4, mix(0.75, 0.4, s))
		left(out, 0.35, 1.1, -0.1, 0.9)
		out.Look = 1 - busy
	end,
	Prop = PROPS.Cut,
}

-- Preparar café: sujeta la taza, remueve y de vez en cuando se gira a la cafetera
works.Coffee = {
	Pose = function(t, seed, out)
		local turn = smoothstep(window(cycle(t, 9, seed), 0.6, 0.82, 0.08))
		local w = t * 6 + seed
		out.np = -0.35
		out.wy = turn * 0.5
		out.ny = turn * 0.2
		left(out, 0.3, 1.3, -0.1, 1.2)
		right(out, 0.85 + sin(w) * 0.05 * (1 - turn), 1.45 - turn * 0.5, -0.4 + cos(w) * 0.05 * (1 - turn), 1.25 - turn * 0.3)
		out.Look = lookUp(t, seed, 13, 1.8)
	end,
	Prop = PROPS.Coffee,
}

-- Llevar la bandeja (camarero): también andando
works.Tray = {
	Walk = true,
	Pose = function(_t, _seed, out)
		left(out, 0.15, 0, -0.3, 1.3)
	end,
	Prop = PROPS.Tray,
}

-- Secar un vaso (barman)
works.Wipe = {
	Pose = function(t, seed, out)
		local w = t * 5 + seed
		out.np = -0.3
		left(out, 0.3, 1.3, -0.1, 1.2)
		right(out, 0.85 + sin(w) * 0.06, 1.45, -0.4 + cos(w) * 0.06, 1.25)
		out.Look = lookUp(t, seed, 10, 2.2)
	end,
	Prop = PROPS.Wipe,
}

-- Contar billetes o entradas (taquilla, revisor)
works.Count = {
	Pose = function(t, seed, out)
		local up = lookUp(t, seed, 7, 2)
		local flick = abs(sin(t * 5.2 + seed)) ^ 4 * (1 - up)
		out.np = mix(-0.35, -0.02, up)
		left(out, 0.3, 1.3, -0.1, 1.2)
		right(out, 0.3, 1.4 - flick * 0.25, 0, 1.25 + flick * 0.15)
		out.Look = up
	end,
	Prop = PROPS.Count,
}

-- Llamar a la gente (feriante: «¡pasen y vean!»)
works.Call = {
	Pose = function(t, seed, out)
		local open = smoothstep(window(cycle(t, 6, seed), 0.1, 0.35, 0.08))
		local beckon = 1 - open
		out.wy = sin(t * 0.5 + seed) * 0.35
		out.wp = open * 0.06
		out.np = open * 0.1
		right(out, mix(0.9, 0.4, open), 0, mix(0.45, 1.1, open), mix(0.6 + 0.5 * abs(sin(t * 6 + seed)), 0.4, open))
		left(out, 0.4, 0, 1.1, 0.4, open)
		out.Look = beckon
	end,
}

-- Enseñar el sitio con el brazo abierto (guía)
works.Present = {
	Pose = function(t, seed, out)
		local show = smoothstep(window(cycle(t, 8, seed), 0.15, 0.55, 0.12))
		local sweep = sin(t * 0.6 + seed)
		out.wy = sweep * 0.2 * show
		out.ny = sweep * 0.3 * show
		right(out, 0.5, 0, 0.7 + sweep * 0.2, 0.35, show)
		right(out, 0.4, 1.3, -0.4, 0.65, 1 - show)
		left(out, 0.4, 1.3, -0.4, 0.65)
		out.Look = 1 - show
	end,
}

-- Mirar el reloj (conductor): manos juntas delante y, de vez en cuando, mira la hora
works.Watch = {
	Pose = function(t, seed, out)
		local check = smoothstep(window(cycle(t, 9, seed), 0.1, 0.3, 0.06))
		right(out, 0.4, 1.3, -0.4, 0.65)
		left(out, 0.4, 1.3, -0.4, 0.65, 1 - check)
		left(out, 0.4, 1.45, 0, 1.4, check)
		out.np = -0.3 * check
		out.ny = -0.15 * check
		out.Look = 1 - check
	end,
}

-- Doblar ropa (dependiente): junta y separa las manos
works.Fold = {
	Pose = function(t, seed, out)
		local f = (sin(t * 2.6 + seed) + 1) / 2 -- 0 = manos separadas, 1 = juntas
		out.wp = -0.06
		out.np = -0.35
		right(out, mix(0.15, 0.25, f), mix(0.85, 1.4, f), 0.1, mix(0.9, 0.95, f))
		left(out, mix(0.15, 0.25, f), mix(0.85, 1.4, f), 0.1, mix(0.9, 0.95, f))
		out.Look = lookUp(t, seed, 12, 2)
	end,
	Prop = PROPS.Fold,
}

-- Tejer (la abuela)
works.Knit = {
	Pose = function(t, seed, out)
		local w = t * 8 + seed
		out.np = -0.35
		right(out, 0.4, 1.65, 0, 0.95 + sin(w) * 0.07)
		left(out, 0.35, 1.55, 0, 1.0 - sin(w) * 0.07)
		out.Look = lookUp(t, seed, 10, 2.5)
	end,
	Prop = PROPS.Knit,
}

-- Cocinar: remover en un bol (en la cocina de casa)
works.Stir = {
	Pose = function(t, seed, out)
		local w = t * 5 + seed
		out.wp = -0.05
		out.np = -0.4
		left(out, 0.35, 1.5, 0, 0.9)
		right(out, 0.45 + sin(w) * 0.06, 1.55, cos(w) * 0.06, 1.15)
		out.Look = lookUp(t, seed, 11, 2)
	end,
	Prop = PROPS.Stir,
}

-- Comer sentado a la mesa (el comedor del colegio): la cuchara del plato a la boca cada pocos
-- segundos, la otra mano apoyada junto al plato; entre bocado y bocado mira a los de la mesa
works.Eat = {
	Pose = function(t, seed, out)
		local bite = smoothstep(window(cycle(t, 3.4, seed), 0.3, 0.52, 0.14))
		out.np = mix(-0.35, -0.12, bite)
		out.wp = -0.08
		left(out, 0.45, 1.3, -0.3, 0.7)
		right(out, mix(0.45, 1.05, bite), mix(1.5, 0.35, bite), mix(0, -0.3, bite), mix(1.1, 2.0, bite))
		out.Look = lookUp(t, seed, 9, 2.2) * (1 - bite)
	end,
	Prop = PROPS.Eat,
}

-- Leer un libro y explicar (profes)
works.Book = {
	Pose = function(t, seed, out)
		local up = lookUp(t, seed, 7, 2.5)
		out.np = mix(-0.32, 0, up)
		left(out, 0.3, 1.15, -0.2, 1.3)
		-- Al levantar la vista, explica con la otra mano
		right(out, 0.5, 0.3, 0.2, 0.8 + sin(t * 3 + seed) * 0.15, up)
		out.Look = up
	end,
	Prop = PROPS.Book,
}

-- Brazos cruzados, vigilando (guardia)
works.Guard = {
	Pose = function(t, seed, out)
		out.wr = sin(t * 0.3 + seed) * 0.03
		out.ny = sin(t * 0.35 + seed) * 0.5
		right(out, 0.25, 1.55, 0, 1.3)
		left(out, 0.3, 1.55, 0, 1.45) -- un poco más alta, por encima de la otra
		out.Look = 0.6
	end,
}

-- Policía: manos juntas y, de vez en cuando, dirige el tráfico con el brazo
works.Traffic = {
	Pose = function(t, seed, out)
		local wave = smoothstep(window(cycle(t, 10, seed), 0.1, 0.4, 0.06))
		right(out, 0.4, 1.3, -0.4, 0.65, 1 - wave)
		right(out, 0.1, 0, 1.45, 0.3 + 0.5 * (sin(t * 5 + seed) * 0.5 + 0.5), wave)
		left(out, 0.4, 1.3, -0.4, 0.65)
		out.ny = -0.4 * wave
		out.Look = 1 - wave
	end,
}

-- Llevar algo con las dos manos delante (cajas, platos, paquetes): también andando
works.Carry = {
	Walk = true,
	Pose = function(t, seed, out)
		right(out, 0.6, 0, -0.4, 0.2)
		left(out, 0.6, 0, -0.4, 0.2)
		out.wp = 0.04 -- un poco hacia atrás, por el peso
		out.Look = 1
	end,
}

-- Bombero: sujeta la manguera con las dos manos y riega de lado a lado
works.Hose = {
	Pose = function(t, seed, out)
		local s = sin(t * 1.3 + seed)
		out.wy = s * 0.3
		out.wp = -0.06
		out.np = -0.1
		out.ny = s * 0.1
		right(out, 0.9, 1.35, -0.4, 0.6)
		left(out, 0.25, 1.55, 0, 0.9)
		out.re += sin(t * 17 + seed) * 0.02 -- tiembla con la presión del agua
		out.Look = 0.3
	end,
	Prop = PROPS.Hose,
}

-- Jardinero: riega con la regadera, inclinándola de vez en cuando
works.Garden = {
	Pose = function(t, seed, out)
		local pour = smoothstep(window(cycle(t, 6, seed), 0.2, 0.6, 0.1))
		out.wp = -0.08 * pour
		out.np = -0.35 * pour - 0.1
		right(out, mix(0, 0.45, pour), mix(0.7, 0.25, pour), mix(0, -0.4, pour), mix(1.05, 0.95, pour))
		out.Look = 1 - pour
	end,
	Prop = PROPS.Garden,
}

-- Mecánico u obrero: martillea sujetando el clavo con la otra mano
works.Hammer = {
	Pose = function(t, seed, out)
		local f = cycle(t, 5, seed)
		local busy = 1 - smoothstep(window(f, 0.72, 0.9, 0.06))
		-- Sube despacio y baja de golpe
		local k = (t * 1.4 + seed) % 1
		local up = if k < 0.6 then smoothstep(k / 0.6) else 1 - smoothstep((k - 0.6) / 0.4)
		up *= busy
		out.wp = -0.12 * busy
		out.np = -0.4 * busy
		right(out, mix(0.7, 0.05, up), mix(1.1, 1.0, up), mix(-0.4, -0.1, up), mix(0.7, 1.95, up), busy)
		left(out, 0.4, 1.55, 0, 0.75, busy)
		handsFront(out, 1 - busy)
		out.Look = 1 - busy
	end,
	Prop = PROPS.Hammer,
}

-- Granjero: rastrilla la tierra, tirando hacia sí
works.Rake = {
	Pose = function(t, seed, out)
		local s = (sin(t * 1.8 + seed) + 1) / 2 -- 0 = rastrillo cerca, 1 = estirado
		out.wp = -0.1 - s * 0.06
		out.np = -0.35
		right(out, mix(0.45, 0.65, s), mix(1.2, 0.85, s), -0.4, mix(0.45, 0.35, s))
		left(out, mix(0.65, 0.5, s), mix(1.5, 1.55, s), mix(-0.4, 0, s), mix(1.15, 1.0, s))
		out.Look = lookUp(t, seed, 12, 2)
	end,
	Prop = PROPS.Rake,
}

-- Músico callejero: toca la guitarra y mueve la cabeza al ritmo
works.Guitar = {
	Pose = function(t, seed, out)
		local beat = t * 4.4 + seed
		local strum = (sin(beat) + 1) / 2
		out.np = -0.12 + sin(beat * 0.5) * 0.06
		out.nr = sin(beat * 0.5) * 0.06
		out.wr = sin(beat * 0.5) * 0.02
		left(out, 0, 0.15, -0.4, 1.9)
		left(out, sin(t * 0.7 + seed) * 0.05, 0, 0, 0) -- cambia de acorde
		right(out, mix(0.15, 0, strum), mix(1.1, 1.55, strum), mix(-0.4, 0, strum), mix(1.1, 0.85, strum))
		out.Look = lookUp(t, seed, 9, 3)
	end,
	Prop = PROPS.Guitar,
}

-- Fregar el suelo (limpieza): como barrer, con la fregona
works.Mop = {
	Pose = works.Sweep.Pose,
	Prop = PROPS.Mop,
}

---------------------------------------------------------------------
-- En un vehículo (las pone RidePose según el asiento; no son oficios del servidor)
---------------------------------------------------------------------

-- Conductor de coche, autobús o camión: las dos manos en el volante, con pequeñas correcciones
-- (el giro del volante lo añade RidePose según cómo gira el vehículo)
works.Drive = {
	Pose = function(t, seed, out)
		local fix = sin(t * 0.9 + seed) * 0.02
		out.wp = -0.04
		out.np = 0.02
		right(out, 1.0 + fix, 0.6, -0.4, 0.6)
		left(out, 1.0 - fix, 0.6, -0.4, 0.6)
		out.ny = sin(t * 0.21 + seed) * 0.08 -- mira un poco a los lados (retrovisores)
	end,
}

-- Moto, bici y patinete: agarrado al manillar, un poco echado hacia delante
works.Handlebar = {
	Pose = function(t, seed, out)
		out.wp = -0.12
		out.np = 0.1 -- cabeza levantada: mira la calle
		right(out, 1.25, 0.1, -0.1, 0.25)
		left(out, 1.25, 0.1, -0.1, 0.25)
		out.re += sin(t * 1.1 + seed) * 0.02
	end,
}

-- Pasajero (copiloto, detrás, autobús, metro): manos en las piernas y mirando por la ventanilla
works.Passenger = {
	Pose = function(t, seed, out)
		local look = sin(t * 0.23 + seed) * 0.5 + sin(t * 0.61 + seed * 2) * 0.15
		out.ny = look * 0.55
		out.np = -0.04
		right(out, 0.45, 1.2, -0.3, 0.9)
		left(out, 0.45, 1.2, -0.3, 0.9)
	end,
}

-- Detrás en la moto: agarrado a la cintura de quien conduce
works.Pillion = {
	Pose = function(t, seed, out)
		out.wp = -0.1
		out.ny = sin(t * 0.3 + seed) * 0.25
		right(out, 0.7, 0.8, -0.4, 0.8)
		left(out, 0.7, 0.8, -0.4, 0.8)
	end,
}

WorkAnim.Works = works

---------------------------------------------------------------------
-- Objetos en la mano (los crea cada jugador en su pantalla: ActorLife para los personajes y
-- AgeMotion para los jugadores)
---------------------------------------------------------------------

export type HeldProp = { Part: BasePart, Hand: BasePart, Alpha: number }

local ATTACH = { Right = "RightHand", Left = "LeftHand", Torso = "UpperTorso" }

function WorkAnim.makeProps(model: Model, work: Work): { HeldProp }
	local list = {}
	for _, spec in work.Prop or {} do
		local hand = model:FindFirstChild(ATTACH[spec.Hand] or "")
		if not hand or not hand:IsA("BasePart") then
			continue
		end
		local part = Instance.new("Part")
		part.Name = "WorkProp_" .. spec.Name
		part.Size = spec.Size
		part.Color = spec.Color
		part.Material = spec.Material or Enum.Material.SmoothPlastic
		if spec.Shape then
			part.Shape = spec.Shape
		end
		part.Anchored = false
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.CastShadow = false
		part.Transparency = 1 -- se enseña cuando empieza la tarea
		part.CFrame = hand.CFrame * spec.Offset
		local weld = Instance.new("Weld")
		weld.Part0 = hand
		weld.Part1 = part
		weld.C0 = spec.Offset
		weld.Parent = part
		part.Parent = model
		table.insert(list, { Part = part, Hand = hand, Alpha = spec.Transparency or 0 })
	end
	return list
end

function WorkAnim.clearProps(list: { HeldProp })
	for _, prop in list do
		prop.Part:Destroy()
	end
	table.clear(list)
end

-- Se ven solo mientras hace la tarea, y se ocultan con el personaje (SceneClient, primera persona)
function WorkAnim.showProps(list: { HeldProp }, shown: boolean)
	for _, prop in list do
		local hidden = prop.Hand.LocalTransparencyModifier
		if prop.Part.LocalTransparencyModifier ~= hidden then
			prop.Part.LocalTransparencyModifier = hidden
		end
		local want = if shown then prop.Alpha else 1
		if prop.Part.Transparency ~= want then
			prop.Part.Transparency = want
		end
	end
end

function WorkAnim.get(name: any): Work?
	if type(name) ~= "string" then
		return nil
	end
	return works[name]
end

return WorkAnim
