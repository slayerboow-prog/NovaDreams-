-- Gym: reglas de los gimnasios de Valmar (lo usan GymService en el servidor, GymUI y GymMotion en
-- el cliente, World/Kit/GymKit al construir las máquinas y scripts/test-gym.luau).
--
--   * ENTRAR: en la recepción se paga la entrada del día o el abono mensual (los niños, la mitad).
--     Los días son días de juego (Config.DayLengthMinutes), contados con la hora real: valen igual
--     en cualquier servidor.
--   * ENTRENAR: en cada máquina "Entrenar". Abajo sale la barra del ritmo: toca (clic, E o el botón)
--     cuando el marcador pasa por la zona verde. Cada acierto es una repetición; cada serie completa
--     sube la Fuerza (máquinas de pesas) o la Forma física (cardio) y gasta energía y hambre.
--     El esfuerzo (barra naranja) baja con cada repetición y se recupera descansando unos segundos.
--   * EDAD: los bebés no entrenan; los niños solo en las máquinas ligeras (cardio, esterillas, comba,
--     saco); desde adolescente, todas.
--   * CUERPO: la Fuerza (0..100) ensancha el cuerpo (hombros, brazos, torso) hasta un 25 % a 100.
--     Si pasan muchos días de juego sin entrenar, baja poco a poco (nunca de golpe).
--
-- Todo lo de aquí son datos y funciones puras (sin Roblox), para poder probarlo con Lune.

local Gym = {}

---------------------------------------------------------------------
-- Precios y abonos
---------------------------------------------------------------------
Gym.Passes = {
	Dia = { Id = "Dia", Name = "Entrada del día", Icon = "🎟️", Price = 5, Days = 1 },
	Mes = { Id = "Mes", Name = "Abono mensual", Icon = "💳", Price = 60, Days = 28 }, -- un mes de juego (Config.Calendar)
}
Gym.PassOrder = { "Dia", "Mes" }
Gym.KidDiscount = 0.5 -- los niños pagan la mitad

-- Precio de un abono según la edad (nil si no se puede comprar)
function Gym.price(passId: string, stage: string?): number?
	local pass = Gym.Passes[passId]
	if not pass then
		return nil
	end
	if stage == "Nino" then
		return math.max(1, math.floor(pass.Price * Gym.KidDiscount + 0.5))
	end
	return pass.Price
end

-- Segundos reales que dura un día de juego
function Gym.daySeconds(dayLengthMinutes: number): number
	return math.max(60, dayLengthMinutes * 60)
end

-- ¿Puede entrenar ahora? (PassUntil = hora real a la que caduca su entrada o abono)
function Gym.hasAccess(gym: { [string]: any }?, now: number): boolean
	return gym ~= nil and type(gym.PassUntil) == "number" and gym.PassUntil > now
end

-- Compra: el abono se suma a lo que le quedara (no se pierde lo ya pagado).
-- Devuelve la nueva hora de caducidad.
function Gym.extend(passUntil: number?, passId: string, now: number, daySeconds: number): number
	local pass = Gym.Passes[passId]
	local from = math.max(passUntil or 0, now)
	return from + (if pass then pass.Days else 0) * daySeconds
end

-- Días de juego que le quedan (redondeando hacia arriba; 0 si no tiene)
function Gym.daysLeft(passUntil: number?, now: number, daySeconds: number): number
	if not passUntil or passUntil <= now then
		return 0
	end
	return math.ceil((passUntil - now) / daySeconds)
end

---------------------------------------------------------------------
-- Máquinas
---------------------------------------------------------------------
-- Stat: "Fuerza" | "Cardio" | "Mixto" (60 % fuerza, 40 % cardio)
-- Light: la pueden usar los niños
-- Loop: cardio que no para (cinta, bici…); si no, cada acierto es una repetición completa
-- Tempo: segundos que tarda el marcador del ritmo en ir y volver (más corto = más difícil)
-- Zone: ancho de la zona verde (0..1)
-- Effort: esfuerzo que gasta cada repetición
-- Gain: cuánto sube la estadística por serie (al principio; luego cuesta más)
-- Geo: medidas que comparten la máquina (GymKit) y la postura (GymPoses), en studs desde el suelo
export type Machine = {
	Kind: string,
	Name: string,
	Icon: string,
	Stat: string,
	Light: boolean,
	Loop: boolean,
	Tempo: number,
	Zone: number,
	Effort: number,
	Gain: number,
	Geo: { [string]: number },
}

local function M(kind: string, name: string, icon: string, stat: string, light: boolean, loop: boolean, tempo: number, zone: number, effort: number, gain: number, geo: { [string]: number }?): Machine
	return { Kind = kind, Name = name, Icon = icon, Stat = stat, Light = light, Loop = loop, Tempo = tempo, Zone = zone, Effort = effort, Gain = gain, Geo = geo or {} }
end

Gym.Machines = {
	Cinta = M("Cinta", "Cinta de correr", "🏃", "Cardio", true, true, 1.3, 0.24, 5, 1.2, { Belt = 0.8 }),
	Bici = M("Bici", "Bicicleta estática", "🚴", "Cardio", true, true, 1.4, 0.26, 4, 1.0, { Seat = 1.75 }),
	Eliptica = M("Eliptica", "Elíptica", "⛷️", "Cardio", true, true, 1.4, 0.24, 5, 1.1, { Pedal = 0.7 }),
	Remo = M("Remo", "Máquina de remo", "🚣", "Mixto", false, true, 1.6, 0.22, 6, 1.1, { Seat = 0.9 }),
	PressBanca = M("PressBanca", "Press de banca", "🏋️", "Fuerza", false, false, 1.5, 0.2, 8, 1.3, { Bench = 1.5 }),
	PressHombros = M("PressHombros", "Press de hombros", "💪", "Fuerza", false, false, 1.4, 0.22, 7, 1.1, { Seat = 1.35 }),
	Jalon = M("Jalon", "Jalón al pecho", "⏬", "Fuerza", false, false, 1.4, 0.22, 7, 1.1, { Seat = 1.35 }),
	Prensa = M("Prensa", "Prensa de piernas", "🏋️", "Fuerza", false, false, 1.6, 0.22, 8, 1.2, { Seat = 1.3 }),
	Sentadilla = M("Sentadilla", "Sentadilla con barra", "🏋️", "Fuerza", false, false, 1.7, 0.18, 9, 1.4),
	Mancuernas = M("Mancuernas", "Mancuernas", "💪", "Fuerza", false, false, 1.3, 0.24, 6, 1.0, { Seat = 1.35 }),
	Dominadas = M("Dominadas", "Barra de dominadas", "🧗", "Fuerza", false, false, 1.6, 0.18, 9, 1.4, { Bar = 7.4 }),
	Saco = M("Saco", "Saco de boxeo", "🥊", "Mixto", true, true, 1.1, 0.24, 6, 1.1),
	Abdominales = M("Abdominales", "Esterilla de abdominales", "🧘", "Fuerza", true, false, 1.3, 0.26, 5, 0.8, { Mat = 0.12 }),
	Yoga = M("Yoga", "Esterilla de yoga", "🧘", "Cardio", true, true, 2.2, 0.3, 3, 0.7, { Mat = 0.12 }),
	Comba = M("Comba", "Comba", "🤸", "Cardio", true, true, 1.0, 0.24, 5, 1.1),
}
Gym.MachineOrder = { "Cinta", "Bici", "Eliptica", "Remo", "PressBanca", "PressHombros", "Jalon", "Prensa", "Sentadilla", "Mancuernas", "Dominadas", "Saco", "Abdominales", "Yoga", "Comba" }

Gym.SetReps = 8 -- repeticiones por serie
Gym.MinEnergy = 12 -- sin energía (o con mucha hambre) no se puede entrenar
Gym.MinHunger = 10
Gym.SetCost = { Fuerza = { Hunger = 3, Energy = 4 }, Cardio = { Hunger = 2, Energy = 5 }, Mixto = { Hunger = 3, Energy = 5 } }
Gym.SetXp = 6 -- experiencia de personaje por serie (ProgressionService)
Gym.EffortMax = 100
Gym.EffortRegen = 14 -- por segundo, descansando
Gym.EffortRestDelay = 1.2 -- segundos sin repetir antes de recuperarse
Gym.MissEffort = 3 -- un fallo de ritmo también cansa
Gym.PerfectBonus = 1.25 -- en la zona central sube más
Gym.MonitorBonus = 1.2 -- con un monitor/a de gimnasio de turno cerca

-- ¿Puede alguien de esta etapa usar esta máquina? (y por qué no)
function Gym.canUse(kind: string, stage: string?): (boolean, string?)
	local machine = Gym.Machines[kind]
	if not machine then
		return false, "Esa máquina no existe."
	end
	if stage == nil or stage == "Bebe" then
		return false, "👶 Los bebés no pueden entrenar en el gimnasio."
	end
	if stage == "Nino" and not machine.Light then
		return false, "🧒 Esta máquina es para mayores. Prueba la cinta, la bici, las esterillas, la comba o el saco."
	end
	return true, nil
end

-- Tiempo mínimo entre dos repeticiones (el servidor no se fía de clics más rápidos)
function Gym.minRepGap(kind: string): number
	local machine = Gym.Machines[kind]
	return if machine then machine.Tempo * 0.45 else 1
end

---------------------------------------------------------------------
-- Ritmo: el marcador va y viene; la zona verde está en el centro
---------------------------------------------------------------------
-- Posición del marcador (0..1) a los `t` segundos, yendo y viniendo cada `tempo` segundos
function Gym.cursor(t: number, tempo: number): number
	local f = (t / tempo) % 1
	return if f < 0.5 then f * 2 else 2 - f * 2
end

-- "Perfecto" en el centro de la zona, "Bien" dentro, "Fallo" fuera
function Gym.judge(position: number, zone: number): string
	local d = math.abs(position - 0.5)
	if d <= zone / 4 then
		return "Perfecto"
	elseif d <= zone / 2 then
		return "Bien"
	end
	return "Fallo"
end

---------------------------------------------------------------------
-- Progreso
---------------------------------------------------------------------
Gym.MaxStat = 100

-- Lo que sube una serie: cuesta más cuanto más fuerte estás (nunca se pasa de 100)
function Gym.gain(base: number, current: number): number
	local room = math.clamp(1 - current / (Gym.MaxStat * 1.1), 0.12, 1)
	return math.min(Gym.MaxStat - current, base * room)
end

-- Reparte una serie en fuerza y cardio según la máquina. quality: multiplicador (perfectos, monitor)
function Gym.setGains(kind: string, strength: number, cardio: number, quality: number?): (number, number)
	local machine = Gym.Machines[kind]
	if not machine then
		return 0, 0
	end
	local k = quality or 1
	local strengthPart = if machine.Stat == "Fuerza" then 1 elseif machine.Stat == "Mixto" then 0.6 else 0
	local cardioPart = if machine.Stat == "Cardio" then 1 elseif machine.Stat == "Mixto" then 0.4 else 0
	local ds = if strengthPart > 0 then Gym.gain(machine.Gain * strengthPart * k, strength) else 0
	local dc = if cardioPart > 0 then Gym.gain(machine.Gain * cardioPart * k, cardio) else 0
	return math.max(0, ds), math.max(0, dc)
end

-- Sin entrenar: los primeros días no pasa nada; después se pierde un poco cada día de juego
Gym.DecayGraceDays = 3
Gym.DecayPerDay = 0.02 -- 2 % de lo que tienes por cada día de más

function Gym.decayed(value: number, idleDays: number): number
	local days = math.max(0, math.floor(idleDays) - Gym.DecayGraceDays)
	if days <= 0 or value <= 0 then
		return math.max(0, value)
	end
	return math.max(0, value * (1 - Gym.DecayPerDay) ^ days)
end

-- Días de pérdida que hay que aplicar ahora (ya aplicados: `applied` desde el último entreno)
function Gym.pendingDecayDays(lastTrain: number, now: number, daySeconds: number, applied: number): number
	if lastTrain <= 0 or now <= lastTrain then
		return 0
	end
	local idle = math.floor((now - lastTrain) / daySeconds)
	return math.max(0, math.max(0, idle - Gym.DecayGraceDays) - applied)
end

---------------------------------------------------------------------
-- Cuerpo: cuánto se ensancha con la Fuerza (se multiplica por el tamaño de la edad)
---------------------------------------------------------------------
Gym.MaxWidth = 0.25 -- +25 % de ancho a 100 de Fuerza
Gym.MaxDepth = 0.25 -- +25 % de fondo

-- Factores de BodyWidthScale / BodyDepthScale (redondeados a centésimas: no se reescala por nada)
function Gym.bodyScale(strength: number?): (number, number)
	local k = math.clamp((strength or 0) / Gym.MaxStat, 0, 1)
	-- Al principio se nota antes (curva suave hacia arriba)
	local curve = k ^ 0.85
	local width = 1 + Gym.MaxWidth * curve
	local depth = 1 + Gym.MaxDepth * curve
	return math.floor(width * 100 + 0.5) / 100, math.floor(depth * 100 + 0.5) / 100
end

-- Extra de daño en los golpes (CombatService): hasta +20 % a 100 de Fuerza
Gym.PunchBonus = 0.2
function Gym.punchMultiplier(strength: number?): number
	return 1 + Gym.PunchBonus * math.clamp((strength or 0) / Gym.MaxStat, 0, 1)
end

-- Nombre del nivel de forma (para la ficha)
function Gym.level(value: number): string
	if value >= 85 then
		return "de competición"
	elseif value >= 60 then
		return "muy en forma"
	elseif value >= 35 then
		return "en forma"
	elseif value >= 12 then
		return "empezando a notarse"
	end
	return "principiante"
end

return Gym
