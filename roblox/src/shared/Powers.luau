-- Powers: los poderes SOBRENATURALES del combate (energía, habilidades, definitiva e impulso aéreo).
--
-- No son de la vida normal de Valmar: se despiertan con la Saga de la Grieta (Cosme y la grieta del
-- cielo, shared/SkyRift). Al principio no hay ninguno; cada acto de la saga despierta uno nuevo. En el
-- Modo pruebas («Sin requisitos», TesterService.bypass) están todos.
--
--   Energía (barra y Cargar) + Ráfaga de esferas  «La grieta en el cielo» (Saga_02_Grieta)
--   Embestida + Impulso aéreo                     «Coser el cielo» (Saga_06_Coser, fin del Acto I)
--   Onda de energía (se carga manteniendo)        «Graduación» (Saga_12_Graduacion, fin del Acto II)
--   Puñetazo explosivo                            «El rescate» (Saga_17_Rescate)
--   Definitiva: Estallido de la Grieta            «El precio» (Saga_18_Precio, fin del Acto III)
--
-- El color de la energía es el de la Grieta (verde-cian con el núcleo ámbar). Cuentas puras: las
-- usan CombatService (servidor), CombatController y CombatFx (cliente) y scripts/test-combos.luau.

local Powers = {}

export type Power = {
	Id: string,
	Name: string,
	Icon: string,
	Cost: number, -- energía
	Cooldown: number,
	Unlock: string, -- misión de la saga que lo despierta
	Flag: string?, -- (o esta marca de la historia)
	Damage: number,
	Knockback: number,
	Lift: number,
	Stun: number,
	Range: number,
	Radius: number?,
	Width: number?,
	Count: number?,
	Speed: number?,
	MaxCharge: number?, -- se carga manteniendo (Onda)
	ChargeBonus: number?, -- daño extra con la carga completa
	Down: number?,
	GuardBreak: boolean?,
	Wall: boolean?,
	WindUp: number?, -- tiempo antes de soltarlo (definitiva: mini-cinemática)
	Hitstop: number,
	Hint: string,
}

Powers.Energy = { Unlock = "Saga_02_Grieta", Flag = nil :: string? }
Powers.AirDash = { Unlock = "Saga_06_Coser", Flag = "SagaActo1" :: string? }

Powers.List = {
	{
		Id = "Esferas", Name = "Ráfaga de esferas", Icon = "rayo", Cost = 20, Cooldown = 2.5, Unlock = "Saga_02_Grieta",
		Damage = 4, Knockback = 6, Lift = 2, Stun = 0.3, Range = 70, Radius = 2.6, Count = 5, Speed = 110, Hitstop = 0.03,
		Hint = "Cinco esferas de energía seguidas hacia tu objetivo",
	},
	{
		Id = "Embestida", Name = "Embestida", Icon = "correr", Cost = 20, Cooldown = 3, Unlock = "Saga_06_Coser", Flag = "SagaActo1",
		Damage = 14, Knockback = 46, Lift = 10, Stun = 0.8, Range = 26, Width = 3.5, Speed = 90, Down = 1, Wall = true, Hitstop = 0.1,
		Hint = "Te lanzas como un rayo y golpeas lo primero que encuentres",
	},
	{
		Id = "Onda", Name = "Onda de energía", Icon = "rayo", Cost = 35, Cooldown = 5, Unlock = "Saga_12_Graduacion", Flag = "SagaActo2",
		Damage = 18, ChargeBonus = 22, MaxCharge = 1.5, Knockback = 58, Lift = 16, Stun = 1, Range = 80, Width = 4.5, Down = 1.4, Wall = true, Hitstop = 0.12,
		Hint = "Mantén para cargarla; suéltala y atraviesa a todos en línea",
	},
	{
		Id = "Explosivo", Name = "Puñetazo explosivo", Icon = "espada", Cost = 30, Cooldown = 4, Unlock = "Saga_17_Rescate", Flag = "CosmeRescatado",
		Damage = 24, Knockback = 64, Lift = 20, Stun = 1, Range = 5, Radius = 9, Down = 1.3, GuardBreak = true, Wall = true, Hitstop = 0.14,
		Hint = "Un puñetazo que estalla delante de ti: rompe la guardia",
	},
} :: { Power }

Powers.Ultimate = {
	Id = "Definitiva", Name = "Estallido de la Grieta", Icon = "corona", Cost = 100, Cooldown = 12, Unlock = "Saga_18_Precio", Flag = "SagaActo3",
	Damage = 55, Knockback = 80, Lift = 30, Stun = 1.6, Range = 45, Radius = 16, Width = 9, Down = 2, GuardBreak = true, Wall = true, WindUp = 1.3, Hitstop = 0.2,
	Hint = "La grieta se abre en tus manos: un estallido enorme (necesita la energía llena)",
} :: Power

local byId: { [string]: Power } = {}
for _, p in Powers.List do
	byId[p.Id] = p
end
byId[Powers.Ultimate.Id] = Powers.Ultimate

function Powers.get(id: any): Power?
	return if type(id) == "string" then byId[id] else nil
end

-- ¿Ha vivido esa parte de la saga? (misión terminada o la marca de la historia)
local function reached(story: { [string]: any }?, unlock: string, flag: string?): boolean
	if not story then
		return false
	end
	local completed = story.Completed
	local skipped = story.Skipped
	if type(completed) == "table" and completed[unlock] ~= nil and not (type(skipped) == "table" and skipped[unlock] ~= nil) then
		return true
	end
	local flags = story.Flags
	return flag ~= nil and type(flags) == "table" and flags[flag] == true
end

-- Poderes despiertos con los datos guardados (data.Story) o todos en Modo pruebas.
-- Devuelve un conjunto: Energia, AirDash, Definitiva y los Id de Powers.List.
function Powers.unlocked(data: { [string]: any }?, tester: boolean?): { [string]: boolean }
	local set = {}
	local story = data and data.Story
	if tester or reached(story, Powers.Energy.Unlock, Powers.Energy.Flag) then
		set.Energia = true
	end
	if tester or reached(story, Powers.AirDash.Unlock, Powers.AirDash.Flag) then
		set.AirDash = true
	end
	for _, p in Powers.List do
		if tester or reached(story, p.Unlock, p.Flag) then
			set[p.Id] = true
		end
	end
	if tester or reached(story, Powers.Ultimate.Unlock, Powers.Ultimate.Flag) then
		set.Definitiva = true
	end
	-- (sin la energía no hay poderes: siempre se despierta primero)
	if not set.Energia then
		return {}
	end
	return set
end

-- Para el atributo "Powers" del jugador (el cliente lo lee): "Energia,Esferas,…" (en orden fijo)
local ORDER = { "Energia", "AirDash", "Esferas", "Embestida", "Onda", "Explosivo", "Definitiva" }
function Powers.encode(set: { [string]: boolean }): string
	local list = {}
	for _, id in ORDER do
		if set[id] then
			table.insert(list, id)
		end
	end
	return table.concat(list, ",")
end

function Powers.decode(text: any): { [string]: boolean }
	local set = {}
	if type(text) == "string" then
		for id in string.gmatch(text, "[^,]+") do
			set[id] = true
		end
	end
	return set
end

-- Habilidades (no la definitiva) que tiene, en orden (para el selector)
function Powers.abilities(set: { [string]: boolean }): { Power }
	local list = {}
	for _, p in Powers.List do
		if set[p.Id] then
			table.insert(list, p)
		end
	end
	return list
end

-- Los que acaba de despertar (para avisarle): los de `now` que no estaban en `before`
function Powers.newOnes(before: { [string]: boolean }, now: { [string]: boolean }): { string }
	local list = {}
	for _, id in ORDER do
		if now[id] and not before[id] then
			table.insert(list, id)
		end
	end
	return list
end

function Powers.label(id: string): string
	if id == "Energia" then
		return "Energía (mantén Cargar para llenarla)"
	elseif id == "AirDash" then
		return "Impulso aéreo (salta otra vez en el aire)"
	end
	local p = byId[id]
	return if p then p.Name else id
end

-- Daño de la Onda según lo cargada (0..MaxCharge)
function Powers.damage(p: Power, charge: number?): number
	local bonus = 0
	if p.MaxCharge and p.ChargeBonus then
		bonus = p.ChargeBonus * math.clamp((charge or 0) / p.MaxCharge, 0, 1)
	end
	return math.floor(p.Damage + bonus + 0.5)
end

-- ¿Se puede usar? (lo tiene, hay energía y no está en pausa). Devuelve el motivo si no.
function Powers.canUse(p: Power?, set: { [string]: boolean }, energy: number, readyAt: number?, now: number): (boolean, string?)
	if not p then
		return false, "No existe"
	end
	if not set[p.Id] then
		return false, "Aún no has despertado este poder"
	end
	if energy < p.Cost then
		return false, "Te falta energía"
	end
	if readyAt and now < readyAt then
		return false, "Aún no está listo"
	end
	return true, nil
end

-- ¿Está un punto dentro de una "cápsula" (línea de `from` en dirección `dir` (unitaria), largo
-- `length`, radio `width`)? Con números: (x, y, z) del punto y del origen. Lo usan la Onda, la
-- Embestida y la definitiva. Devuelve también a qué distancia (a lo largo) está.
function Powers.inLine(px: number, py: number, pz: number, ox: number, oy: number, oz: number, dx: number, dy: number, dz: number, length: number, width: number): (boolean, number)
	local vx, vy, vz = px - ox, py - oy, pz - oz
	local along = vx * dx + vy * dy + vz * dz
	if along < -1 or along > length then
		return false, along
	end
	local cx, cy, cz = vx - dx * along, vy - dy * along, vz - dz * along
	return cx * cx + cy * cy + cz * cz <= width * width, along
end

return Powers
