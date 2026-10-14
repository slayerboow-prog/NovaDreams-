-- BodyPieces (compartido): las piezas que se pegan al cuerpo de un personaje (pelo, cuello, mochila,
-- ropa 3D del aspecto de Valmar y de los conjuntos del pase, el disfraz de Cosme…).
--
-- Fallo del dueño (v114, móvil): «Hay muchos pelos volando por todos lados»: el pelo de bloques de un
-- NPC (gorro + nuca + flequillo) se quedaba solo en el aire, sin nadie debajo. Una pieza así solo
-- tiene sentido pegada a una parte del cuerpo de SU personaje; si esa parte ya no está (o no se ve, o
-- la pieza se ha quedado lejos de ella), es basura que hay que quitar o esconder.
--
--   BodyPieces.TAG                    etiqueta de CollectionService de todas estas piezas
--   BodyPieces.mark(piece, to)        la marca (etiqueta + atributo BodyOn = nombre de la parte) y la
--                                     deja desanclada: se mueve SOLO por su soldadura
--   BodyPieces.characterOf(piece)     el personaje (Model con Humanoid) en el que está, o nil
--   BodyPieces.partnerOf(piece)       la parte del cuerpo a la que está soldada (Weld o WeldConstraint)
--   BodyPieces.inspect(piece) -> Info lo que se sabe de ella (para verdict)
--   BodyPieces.verdict(info)          "Keep" | "NoCharacter" | "NoWeld" | "Far" | "Anchored" |
--                                     "Hidden" (su parte no se ve: la pieza tampoco debe verse)
--   BodyPieces.orphan(verdict)        ¿hay que quitarla? (en el servidor) / esconderla (en el cliente)
--   BodyPieces.Log                    contador con aviso limitado (como mucho uno cada LOG_EVERY s)
-- Lo usan Npc.dress, OutfitBuilder, AvatarService, CosmeLook y PlaceLife (al crear las piezas), el
-- servidor (Services/BodyPieceService: barrendero) y el cliente (Controllers/BodyPieceGuard).

local BodyPieces = {}

BodyPieces.TAG = "BodyPiece"
BodyPieces.ATTR = "BodyOn"
-- Una pieza nunca está más lejos de su parte que esto (en tamaños de la parte + de la pieza): un pelo
-- de gigante sigue cerca de su cabeza de gigante. Más lejos = suelta (se ha quedado atrás).
BodyPieces.FAR_SLACK = 3
BodyPieces.LOG_EVERY = 60

export type Info = {
	InWorld: boolean, -- en workspace (las de los modelos aún sin colocar no se juzgan)
	Character: boolean, -- dentro de un Model con Humanoid
	Welded: boolean, -- soldada a una parte del cuerpo que existe, de ese mismo personaje
	Distance: number?, -- del centro de la pieza al de su parte
	Reach: number?, -- lo más lejos que puede estar (tamaños)
	Anchored: boolean,
	PartnerHidden: boolean?, -- su parte no se ve (transparente del todo)
}

-- La marca: etiqueta, de qué parte cuelga y desanclada (la mueve la soldadura, nunca por su cuenta)
function BodyPieces.mark(piece: Instance, to: Instance?)
	pcall(function()
		(piece :: any).Anchored = false
	end)
	pcall(function()
		piece:AddTag(BodyPieces.TAG)
	end)
	if to then
		pcall(function()
			piece:SetAttribute(BodyPieces.ATTR, to.Name)
		end)
	end
end

function BodyPieces.isPiece(piece: Instance): boolean
	local ok, has = pcall(function()
		return piece:HasTag(BodyPieces.TAG)
	end)
	return ok and has == true
end

-- El personaje (Model con Humanoid) en el que está la pieza, subiendo por carpetas y modelos
function BodyPieces.characterOf(piece: Instance): Model?
	local node = piece.Parent
	while node do
		if node:IsA("Model") and node:FindFirstChildOfClass("Humanoid") then
			return node :: Model
		end
		node = node.Parent
	end
	return nil
end

-- La parte del cuerpo a la que está soldada (la otra punta de su Weld / WeldConstraint)
function BodyPieces.partnerOf(piece: Instance): BasePart?
	for _, d in piece:GetChildren() do
		if d:IsA("WeldConstraint") or d:IsA("Weld") or d:IsA("Motor6D") then
			local joint = d :: any
			local enabled = true
			pcall(function()
				enabled = joint.Enabled ~= false
			end)
			if enabled then
				local other = if joint.Part1 == piece then joint.Part0 elseif joint.Part0 == piece then joint.Part1 else nil
				if other and other:IsA("BasePart") then
					return other
				end
			end
		end
	end
	return nil
end

local function hiddenPart(part: BasePart): boolean
	if part.Name == "HumanoidRootPart" then
		return false -- (la raíz siempre es invisible: lo que va pegado a ella se ve igual)
	end
	local ltm = 0
	pcall(function()
		ltm = (part :: any).LocalTransparencyModifier or 0
	end)
	return part.Transparency >= 0.99 or ltm >= 0.99
end

function BodyPieces.inspect(piece: BasePart, world: Instance?): Info
	local character = BodyPieces.characterOf(piece)
	local partner = BodyPieces.partnerOf(piece)
	local welded = partner ~= nil and character ~= nil and partner:IsDescendantOf(character) and not BodyPieces.isPiece(partner)
	local info: Info = {
		InWorld = world == nil or piece:IsDescendantOf(world),
		Character = character ~= nil,
		Welded = welded,
		Anchored = piece.Anchored,
	}
	if welded and partner then
		info.Distance = (piece.CFrame.Position - partner.CFrame.Position).Magnitude
		info.Reach = partner.Size.Magnitude * BodyPieces.FAR_SLACK + piece.Size.Magnitude + 2
		info.PartnerHidden = hiddenPart(partner)
	end
	return info
end

-- Qué le pasa a la pieza (orden: lo más grave primero)
function BodyPieces.verdict(info: Info): string
	if not info.InWorld then
		return "Keep" -- (aún en construcción o guardada fuera del mundo)
	end
	if not info.Character then
		return "NoCharacter" -- su personaje ya no existe (o la pieza se salió de él)
	end
	if not info.Welded then
		return "NoWeld" -- sin soldadura a una parte de su personaje: cae, flota o se queda atrás
	end
	if info.Distance and info.Reach and info.Distance > info.Reach then
		return "Far" -- soldada, pero lejos de su parte: se ha quedado atrás
	end
	if info.Anchored then
		return "Anchored" -- anclada: no seguiría a su parte (se suelta el ancla, no se borra)
	end
	if info.PartnerHidden then
		return "Hidden" -- su parte no se ve: la pieza tampoco (si no, pelo sin cabeza)
	end
	return "Keep"
end

-- ¿Es basura? (el servidor la quita; el cliente la esconde mientras siga así)
function BodyPieces.orphan(verdict: string): boolean
	return verdict == "NoCharacter" or verdict == "NoWeld" or verdict == "Far"
end

-- Contador con aviso limitado: add(n) suma; flush(now) devuelve el texto del aviso si toca (como mucho
-- uno cada LOG_EVERY s, con todo lo acumulado desde el anterior) o nil
function BodyPieces.Log(label: string, every: number?)
	local self = { Pending = 0, Total = 0, Last = -math.huge, Every = every or BodyPieces.LOG_EVERY }
	function self.add(n: number)
		self.Pending += n
		self.Total += n
	end
	function self.flush(now: number): string?
		if self.Pending <= 0 or now - self.Last < self.Every then
			return nil
		end
		local text = ("[%s] %d pieza(s) de pelo/ropa sueltas sin su personaje retiradas (total %d)"):format(label, self.Pending, self.Total)
		self.Pending = 0
		self.Last = now
		return text
	end
	return self
end

return BodyPieces
