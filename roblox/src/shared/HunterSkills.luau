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
	{ Id = "TajoCircular", Art = "hab_tajo", Name = "Tajo circular", Icon = "🌀", Key = "Z", Level = 2, Cooldown = 8, Kind = "Area", Radius = 14, Power = 2.2, MaxTargets = 8, Mana = 18,
		Desc = "Giras y golpeas a todas las bestias que tengas alrededor." },
	{ Id = "Embestida", Art = "hab_embestida", Name = "Embestida", Icon = "💨", Key = "X", Level = 6, Cooldown = 12, Kind = "Dash", Distance = 30, Width = 8, Power = 3, MaxTargets = 6, Mana = 24,
		Desc = "Te lanzas hacia delante y golpeas a todo lo que cruzas." },
	{ Id = "Furia", Art = "hab_furia", Name = "Furia del cazador", Icon = "🔥", Key = "C", Level = 12, Cooldown = 45, Kind = "Buff", Buff = "Furia", Amount = 0.4, Seconds = 15, Mana = 40,
		Desc = "Durante 15 segundos tus golpes a las bestias hacen un 40 % más." },
	{ Id = "GolpeSismico", Art = "hab_sismico", Name = "Golpe sísmico", Icon = "💥", Key = "V", Level = 20, Cooldown = 30, Kind = "Area", Radius = 22, Power = 4.5, MaxTargets = 12, Mana = 45,
		Desc = "Golpeas el suelo: una onda alcanza a todas las bestias cercanas." },
	{ Id = "TormentaAcero", Art = "hab_tormenta", Name = "Tormenta de acero", Icon = "⚔", Key = "B", Level = 9, Cooldown = 14, Kind = "Area", Radius = 11, Power = 3.4, MaxTargets = 6, Mana = 30,
		Desc = "Encadenas cortes a tu alrededor: mucho daño a las bestias pegadas a ti." },
	{ Id = "Coraza", Art = "hab_coraza", Name = "Coraza de grieta", Icon = "🛡", Key = "N", Level = 15, Cooldown = 50, Kind = "Buff", Buff = "Coraza", Amount = 0.3, Seconds = 12, Mana = 35,
		Desc = "Durante 12 segundos las bestias te hacen un 30 % menos de daño." },
}
table.sort(HunterSkills.List, function(a, b)
	return a.Level < b.Level
end)

local byId: { [string]: { [string]: any } } = {}
for _, sk in HunterSkills.List do
	byId[sk.Id] = sk
end

function HunterSkills.get(id: any): { [string]: any }?
	return if type(id) == "string" then byId[id] else nil
end

-- ESPÍRITU (la barra azul, como el maná): cada habilidad gasta el suyo (Mana) y se recupera solo, más deprisa
-- fuera de combate. Sube con el nivel de cazador.
function HunterSkills.manaMax(hunterLevel: number): number
	return 100 + 6 * math.max(0, math.floor(hunterLevel) - 1)
end
function HunterSkills.manaRegen(max: number, fighting: boolean): number -- por segundo
	return (if fighting then 0.015 else 0.05) * max + 1
end

-- RANGOS: cada habilidad empieza en rango 1 al desbloquearse y sube hasta el 10 («Maestra») con PUNTOS DE
-- HABILIDAD: uno por cada nivel de cazador desde el 2. Cada rango: +12 % de fuerza y −3 % de espera.
HunterSkills.MaxRank = 10
HunterSkills.PerRank = 0.12
HunterSkills.CooldownPerRank = 0.03

function HunterSkills.rankOf(ranks: { [string]: any }?, id: string): number
	return math.clamp(math.floor(tonumber(ranks and ranks[id]) or 1), 1, HunterSkills.MaxRank)
end
function HunterSkills.power(sk: { [string]: any }, rank: number): number
	return (sk.Power or 0) * (1 + HunterSkills.PerRank * (rank - 1))
end
function HunterSkills.buffAmount(sk: { [string]: any }, rank: number): number
	return (sk.Amount or 0) * (1 + HunterSkills.PerRank * (rank - 1))
end
function HunterSkills.cooldown(sk: { [string]: any }, rank: number): number
	return sk.Cooldown * (1 - HunterSkills.CooldownPerRank * (rank - 1))
end
-- Puntos que quedan por gastar: (nivel de cazador − 1) menos los rangos ya subidos
function HunterSkills.pointsLeft(hunterLevel: number, ranks: { [string]: any }?): number
	local spent = 0
	for _, sk in HunterSkills.List do
		spent += HunterSkills.rankOf(ranks, sk.Id) - 1
	end
	return math.max(0, (hunterLevel - 1) - spent)
end
function HunterSkills.rankName(rank: number): string
	return if rank >= HunterSkills.MaxRank then "Maestra" else ("Rango %d"):format(rank)
end

-- (17-11-2026) Las habilidades se APRENDEN EN LA ACADEMIA (la escuela de guerreros: Misiones/Acad*). known =
-- { Learned = { [Id] = true }, Graduated = bool } o nil. Mientras estudias solo tienes las que te han enseñado;
-- al graduarte (y en las partidas de antes de la Academia) las demás llegan con el nivel de cazador.
function HunterSkills.unlocked(sk: { [string]: any }, hunterLevel: number, known: { [string]: any }?): boolean
	if type(known) == "table" then
		if type(known.Learned) == "table" and known.Learned[sk.Id] then
			return true
		end
		if not known.Graduated then
			return false
		end
	end
	return hunterLevel >= sk.Level
end

-- Lo que sabes, en un texto para el atributo HabilidadesSabidas del jugador: "*" = graduado; luego las ids
function HunterSkills.knownToText(known: { [string]: any }): string
	local parts = {}
	if known.Graduated then
		table.insert(parts, "*")
	end
	for _, sk in HunterSkills.List do
		if type(known.Learned) == "table" and known.Learned[sk.Id] then
			table.insert(parts, sk.Id)
		end
	end
	return table.concat(parts, ",")
end
function HunterSkills.knownFromText(text: any): { [string]: any }?
	if type(text) ~= "string" then
		return nil
	end
	local known = { Learned = {}, Graduated = false }
	for part in string.gmatch(text, "[^,]+") do
		if part == "*" then
			known.Graduated = true
		else
			known.Learned[part] = true
		end
	end
	return known
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

-- PRUEBA (19-11-2026, el dueño: «que puedas hacer todas las habilidades al menos 1 vez sin tiempo de
-- demora»): la PRIMERA vez de cada habilidad en cada sesión sale sin esperar, sin gastar y aunque aún no
-- esté desbloqueada. Las ya probadas van en un atributo del jugador (texto «Id,Id,…»: HabPrueba para las
-- habilidades, PoderPrueba para los poderes del combate). Después, las reglas de siempre.
function HunterSkills.trialUsed(text: any, id: string): boolean
	if type(text) ~= "string" or text == "" then
		return false
	end
	for part in string.gmatch(text, "[^,]+") do
		if part == id then
			return true
		end
	end
	return false
end

function HunterSkills.trialMark(text: any, id: string): string
	if HunterSkills.trialUsed(text, id) then
		return text :: string
	end
	return if type(text) == "string" and text ~= "" then text .. "," .. id else id
end

return HunterSkills
