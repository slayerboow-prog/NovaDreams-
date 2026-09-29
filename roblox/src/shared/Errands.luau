-- Errands: los encargos de los vecinos (funciones puras; las usan HousingService y las pruebas).
--
--   * De vez en cuando (no a cada rato) un vecino de tu edificio te pide un favor: te llama a la
--     puerta de tu casa o te para en el portal.
--   * «Entrega»: han dejado en los buzones del portal un paquete para otro vecino. Lo recoges en
--     los buzones y se lo llevas a su puerta («Entrega en el 5ºB»).
--   * «Visita»: un vecino quiere que busques a otro en su piso y le des un recado («Busca a Carlos
--     en su piso»). Solo lo encuentras si está en casa (shared/Residents): si está trabajando o
--     durmiendo, te dicen cuándo volver.
--   * Se paga con dinero y experiencia. Un encargo sin hacer caduca al rato.

local Residents = require(script.Parent.Residents)

local Errands = {}

Errands.Cooldown = 420 -- segundos entre un encargo y el siguiente (aunque digas que no)
Errands.FirstDelay = 25 -- segundos en tu casa o en tu portal antes de que te pidan nada
Errands.Chance = 0.08 -- probabilidad en cada comprobación (cada 3 s): uno cada ~40 s de media
Errands.Expire = 900 -- segundos para hacerlo
Errands.OfferSeconds = 30 -- lo que espera el vecino a que contestes
Errands.Kinds = { "Entrega", "Visita" }
Errands.Rewards = {
	Entrega = { Money = 60, Xp = 20 },
	Visita = { Money = 45, Xp = 15 },
}

-- Una vivienda de vecinos del edificio: planta, letra, lo que pone en la puerta, su clave (vida del
-- vecino: shared/Residents) y su ID (shared/Housing)
export type Home = { Floor: number, Letter: string, Label: string, UnitKey: string, Id: string? }
export type Errand = {
	Kind: string,
	From: Home & { Name: string },
	To: Home & { Name: string },
	Reward: { Money: number, Xp: number },
}

-- El nombre de pila («Carlos García» -> «Carlos»)
function Errands.firstName(name: string): string
	return string.match(name, "^(%S+)") or name
end

-- ¿Toca ofrecer un encargo ahora? state = { Active, LastAt, Since } (Since: desde cuándo está en su
-- casa o en su portal); roll: un número al azar entre 0 y 1
function Errands.shouldOffer(state: { Active: boolean?, LastAt: number?, Since: number? }, now: number, roll: number): boolean
	if state.Active then
		return false
	end
	if state.LastAt and now - state.LastAt < Errands.Cooldown then
		return false
	end
	if not state.Since or now - state.Since < Errands.FirstDelay then
		return false
	end
	return roll < Errands.Chance
end

-- Elige el encargo entre las viviendas de vecinos del edificio. rolls: tres números entre 0 y 1
-- (tipo, quién lo pide, a quién va). kind: forzar el tipo. Devuelve nil si no hay dos viviendas.
function Errands.pick(homes: { Home }, rolls: { number }, kind: string?): Errand?
	if #homes < 2 then
		return nil
	end
	local function at(list: { Home }, roll: number): Home
		return list[math.clamp(math.floor(roll * #list) + 1, 1, #list)]
	end
	local which = kind or Errands.Kinds[math.clamp(math.floor((rolls[1] or 0) * #Errands.Kinds) + 1, 1, #Errands.Kinds)]
	local from = at(homes, rolls[2] or 0)
	-- (el paquete va a otra planta si se puede: así hay que subir o bajar)
	local others = {}
	for _, h in homes do
		if h.UnitKey ~= from.UnitKey and (which ~= "Entrega" or h.Floor ~= from.Floor) then
			table.insert(others, h)
		end
	end
	if #others == 0 then
		for _, h in homes do
			if h.UnitKey ~= from.UnitKey then
				table.insert(others, h)
			end
		end
	end
	local to = at(others, rolls[3] or 0)
	local fromName = Residents.person(from.UnitKey).Name
	local toName = Residents.person(to.UnitKey).Name
	local reward = Errands.Rewards[which] or Errands.Rewards.Entrega
	return {
		Kind = which,
		From = { Floor = from.Floor, Letter = from.Letter, Label = from.Label, UnitKey = from.UnitKey, Id = from.Id, Name = fromName },
		To = { Floor = to.Floor, Letter = to.Letter, Label = to.Label, UnitKey = to.UnitKey, Id = to.Id, Name = toName },
		Reward = { Money = reward.Money, Xp = reward.Xp },
	}
end

-- Lo que te dice el vecino al pedírtelo
function Errands.offerText(errand: Errand): string
	local from = errand.From
	if errand.Kind == "Entrega" then
		return ("%s (%s): «El repartidor ha dejado en los buzones un paquete para el %s y no había nadie. ¿Se lo subes tú?»"):format(from.Name, from.Label, errand.To.Label)
	end
	return ("%s (%s): «¿Puedes buscar a %s en su piso, el %s? Tengo que devolverle unas llaves y no me coge el teléfono.»"):format(from.Name, from.Label, Errands.firstName(errand.To.Name), errand.To.Label)
end

-- El título corto del encargo («Entrega en el 5ºB», «Busca a Carlos en su piso»)
function Errands.title(errand: Errand): string
	if errand.Kind == "Entrega" then
		return ("Entrega en el %s"):format(errand.To.Label)
	end
	return ("Busca a %s en su piso"):format(Errands.firstName(errand.To.Name))
end

-- Qué hay que hacer ahora (para el aviso y el cartelito de la pantalla)
function Errands.goalText(errand: Errand, hasPackage: boolean?): string
	local to = errand.To
	if errand.Kind == "Entrega" then
		if not hasPackage then
			return "📦 Recoge el paquete en los buzones del portal."
		end
		return ("📦 Lleva el paquete a la puerta del %s (planta %d)%s."):format(to.Label, to.Floor, if to.Id then " · " .. to.Id else "")
	end
	return ("🚪 Llama a la puerta del %s (planta %d) y busca a %s."):format(to.Label, to.Floor, Errands.firstName(to.Name))
end

-- Al llegar a la puerta en una visita: ¿está en casa? Si no, qué te dicen y cuándo volver.
function Errands.visit(errand: Errand, clock: number): (boolean, string)
	local person = Residents.person(errand.To.UnitKey)
	local home, text = Residents.knockText(person, clock)
	if home then
		return true, ("🙂 %s: «¡Ah, las llaves! Qué despiste. Gracias por venir hasta aquí.»"):format(Errands.firstName(person.Name))
	end
	return false, text .. " Vuelve más tarde."
end

-- Al entregar el paquete: si está en casa te abre; si no, lo dejas en el felpudo
function Errands.deliverText(errand: Errand, clock: number): string
	local person = Residents.person(errand.To.UnitKey)
	if Residents.where(person, clock) == "Casa" then
		return ("🙂 %s: «¡Mi paquete! Muchísimas gracias, vecino.»"):format(Errands.firstName(person.Name))
	end
	return ("📦 No hay nadie en el %s: dejas el paquete en el felpudo con una nota."):format(errand.To.Label)
end

return Errands
