-- HunterSkills: las HABILIDADES DE CAZADOR (contra las bestias de los planetas). Cuentas puras: las usan
-- Services/HunterSkillService (comprueba nivel y espera, hace el daño), Controllers/HunterSkillsUI (los botones
-- con su cuenta atrás) y las pruebas (scripts/test-bestias.luau).
--
--   * Se desbloquean con el nivel de cazador (shared/Crafting.hunterLevel) y cada una tiene su espera.
--   * El daño sale del golpe fuerte del combo (shared/Combat) por el multiplicador de la habilidad; el servidor le
--     suma tu arma, sus mejoras, tus accesorios y tu nivel (Services/BeastService.hit).
--   * Kind: "Area" (a todo lo que tengas alrededor), "Dash" (te lanzas hacia delante y golpeas lo que cruzas) o
--     "Buff" (un rato pegando más fuerte).

local HunterSkills = {}

-- Key: tecla en el ordenador (en el móvil, sus botones)
HunterSkills.List = {
	{ Id = "TajoCircular", Name = "Tajo circular", Icon = "🌀", Key = "Z", Level = 2, Cooldown = 8, Kind = "Area", Radius = 14, Power = 2.2, MaxTargets = 8,
		Desc = "Giras y golpeas a todas las bestias que tengas alrededor." },
	{ Id = "Embestida", Name = "Embestida", Icon = "💨", Key = "X", Level = 6, Cooldown = 12, Kind = "Dash", Distance = 30, Width = 8, Power = 3, MaxTargets = 6,
		Desc = "Te lanzas hacia delante y golpeas a todo lo que cruzas." },
	{ Id = "Furia", Name = "Furia del cazador", Icon = "🔥", Key = "C", Level = 12, Cooldown = 45, Kind = "Buff", Amount = 0.4, Seconds = 15,
		Desc = "Durante 15 segundos tus golpes a las bestias hacen un 40 % más." },
	{ Id = "GolpeSismico", Name = "Golpe sísmico", Icon = "💥", Key = "V", Level = 20, Cooldown = 30, Kind = "Area", Radius = 22, Power = 4.5, MaxTargets = 12,
		Desc = "Golpeas el suelo: una onda alcanza a todas las bestias cercanas." },
}

local byId: { [string]: { [string]: any } } = {}
for _, sk in HunterSkills.List do
	byId[sk.Id] = sk
end

function HunterSkills.get(id: any): { [string]: any }?
	return if type(id) == "string" then byId[id] else nil
end

function HunterSkills.unlocked(sk: { [string]: any }, hunterLevel: number): boolean
	return hunterLevel >= sk.Level
end

-- Cuánto falta para volver a usarla (0 = lista)
function HunterSkills.remaining(sk: { [string]: any }, lastUsed: number?, now: number): number
	if not lastUsed then
		return 0
	end
	return math.max(0, sk.Cooldown - (now - lastUsed))
end

-- ¿Está el punto p dentro del pasillo de una embestida? (desde from, hacia dir —unitario, en horizontal—)
function HunterSkills.inDash(sk: { [string]: any }, from: Vector3, dir: Vector3, p: Vector3): boolean
	local rel = Vector3.new(p.X - from.X, 0, p.Z - from.Z)
	local along = rel:Dot(dir)
	if along < -2 or along > sk.Distance + 4 then
		return false
	end
	local side = (rel - dir * along).Magnitude
	return side <= sk.Width / 2 + 2 and math.abs(p.Y - from.Y) < 16
end

return HunterSkills
