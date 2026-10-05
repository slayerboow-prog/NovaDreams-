-- Family: quién es tu familia. Depende de la casa familiar donde naciste (BabyService): en unas
-- casas te cuidan Papá y Abu Rosa, en otras Mamá y Abu Tomás. Siempre van por parejas.
--
--   Family.keysFor(index)       -> familyKey, abuKey de la casa número index
--   Family.keysOf(player, life) -> las de un jugador: sus atributos, lo guardado (data.Life) o,
--                                  si aún no hay nada, la pareja de la primera casa
--   Family.household(index)     -> todos los que viven en la casa número index: SIEMPRE Papá, Mamá y
--                                  la abuela (Abu Rosa); en las casas de Abu Tomás, él también
--                                  (los abuelos viven juntos). La pareja de la historia va en sus sitios
--                                  del mapa (FamilySpot); los demás, al lado (Anchor + Offset).
-- (antes cada sitio tenía su propio "por si acaso" y salían parejas que no existen: Mamá con Abu Rosa)

local Family = {}

Family.Pairs = {
	Odd = { Family = "NPC.PAPA", Abu = "NPC.ABU_ROSA" }, -- casas 1, 3, 5…
	Even = { Family = "NPC.MAMA", Abu = "NPC.ABU_TOMAS" }, -- casas 2, 4, 6…
}

-- La pareja de la casa número index (1, 2, 3…)
function Family.keysFor(index: number?): (string, string)
	local pair = if (tonumber(index) or 1) % 2 == 1 then Family.Pairs.Odd else Family.Pairs.Even
	return pair.Family, pair.Abu
end

export type Member = {
	Npc: string, -- nombre del sitio (FamilySpot Npc = …) o del familiar extra
	NameKey: string, -- su nombre (Strings)
	NpcId: string, -- reparto (Cast): "Familia" y "Abu" se ocultan si una escena trae al personaje
	Story: boolean, -- es de la pareja de la historia (habla en las misiones)
	Anchor: string?, -- los extra: junto a qué FamilySpot van…
	Offset: Vector3?, -- …y a qué distancia (en los ejes de la casa)
	Work: string?, -- lo que hace en casa (Npc.work: "Knit", "Stir")
	Old: boolean?, -- anda encorvado (abuelos)
	LongHair: boolean?,
}

-- Toda la familia de la casa número index. Siempre hay padre, madre y abuela.
function Family.household(index: number?): { Member }
	local familyKey, abuKey = Family.keysFor(index)
	local otherParent = if familyKey == "NPC.PAPA" then "NPC.MAMA" else "NPC.PAPA"
	local list: { Member } = {
		{ Npc = "Familia_Abu", NameKey = abuKey, NpcId = "Abu", Story = true, Work = "Knit", Old = true, LongHair = abuKey == "NPC.ABU_ROSA" },
		{ Npc = "Familia_Padre", NameKey = familyKey, NpcId = "Familia", Story = true, Work = "Stir", LongHair = familyKey == "NPC.MAMA" },
		-- El otro padre, en la cocina junto a la mesa
		{ Npc = "Familia_Pareja", NameKey = otherParent, NpcId = "FamiliaPareja", Story = false, Anchor = "Familia_Padre", Offset = Vector3.new(-3, 0, 1.5), LongHair = otherParent == "NPC.MAMA" },
	}
	if abuKey ~= "NPC.ABU_ROSA" then
		-- La abuela, en el salón junto al sofá (el abuelo, el de la historia, en su sillón)
		table.insert(list, { Npc = "Familia_Abuela", NameKey = "NPC.ABU_ROSA", NpcId = "Abuela", Story = false, Anchor = "Familia_Abu", Offset = Vector3.new(-22, 0, 0.5), Old = true, LongHair = true })
	end
	return list
end

-- Qué casa familiar le toca a un jugador (BabyService). ids = todas las casas del mapa; saved = la
-- guardada (data.Life.FamilyHomeId); others = cuántos OTROS jugadores conectados viven en cada una.
--   * La guardada, si existe y nadie más vive en ella -> "Kept" (se queda la suya)
--   * Si no (no existe, o es de otro jugador), una libre al azar -> "New", "Invalid" o "Taken"
--   * Todas ocupadas (más jugadores que casas): la guardada si existe; si no, la menos llena
-- rng: con :NextInteger(a, b) (Random de Roblox); sin él, math.random.
function Family.chooseHome(ids: { string }, saved: string?, others: { [string]: number }, rng: any?): (string?, string)
	if #ids == 0 then
		return nil, "None"
	end
	local function pick(list: { string }): string
		local i = if rng then rng:NextInteger(1, #list) else math.random(1, #list)
		return list[i]
	end
	local exists = saved ~= nil and table.find(ids, saved) ~= nil
	if exists and (others[saved :: string] or 0) == 0 then
		return saved, "Kept"
	end
	local free = {}
	for _, id in ids do
		if (others[id] or 0) == 0 then
			table.insert(free, id)
		end
	end
	local reason = if saved == nil then "New" elseif exists then "Taken" else "Invalid"
	if #free > 0 then
		return pick(free), reason
	end
	if exists then
		return saved, "Kept"
	end
	local least, best = {}, math.huge
	for _, id in ids do
		local n = others[id] or 0
		if n < best then
			least, best = { id }, n
		elseif n == best then
			table.insert(least, id)
		end
	end
	return pick(least), reason
end

-- La pareja de un jugador. life = data.Life (opcional), donde se guardan FamilyKey y AbuKey.
function Family.keysOf(player: Player?, life: { [string]: any }?): (string, string)
	local family = player and player:GetAttribute("FamilyKey")
	local abu = player and player:GetAttribute("AbuKey")
	if type(family) == "string" and type(abu) == "string" then
		return family, abu
	end
	if life and type(life.FamilyKey) == "string" and type(life.AbuKey) == "string" then
		return life.FamilyKey, life.AbuKey
	end
	-- Solo se sabe uno de los dos: el otro, el de su pareja
	for _, pair in Family.Pairs do
		if family == pair.Family or abu == pair.Abu then
			return pair.Family, pair.Abu
		end
	end
	return Family.keysFor(1)
end

return Family
