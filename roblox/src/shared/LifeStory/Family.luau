-- Family: quién es tu familia. Depende de la casa familiar donde naciste (BabyService): en unas
-- casas te cuidan Papá y Abu Rosa, en otras Mamá y Abu Tomás. Siempre van por parejas.
--
--   Family.keysFor(index)       -> familyKey, abuKey de la casa número index
--   Family.keysOf(player, life) -> las de un jugador: sus atributos, lo guardado (data.Life) o,
--                                  si aún no hay nada, la pareja de la primera casa
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
