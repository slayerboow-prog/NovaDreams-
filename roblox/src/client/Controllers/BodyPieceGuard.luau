-- BodyPieceGuard (cliente): en ESTA pantalla nunca se ve un pelo (o una pieza de ropa 3D) sin su
-- personaje («Hay muchos pelos volando por todos lados», v114 en el móvil).
--
-- Las piezas pegadas al cuerpo llevan la etiqueta BodyPiece (shared/BodyPieces). Cada CHECK_EVERY s se
-- miran (solo esa lista) y se esconde aquí (LocalTransparencyModifier = 1) la que:
--   * no tiene su parte del cuerpo en esta pantalla (la carga por zonas aún no la ha traído o ya se
--     la ha llevado) o no está en un personaje (NoWeld / NoCharacter)
--   * se ha quedado lejos de su parte (Far)
--   * cuelga de una parte que no se ve (Hidden: cuerpo invisible = pelo invisible)
-- En cuanto vuelve a estar bien, se enseña otra vez (solo las que escondió este guardia). El servidor
-- además quita de verdad las que se quedan sueltas (Services/BodyPieceService).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BodyPieces = require(ReplicatedStorage.Shared.BodyPieces)

local BodyPieceGuard = {}

BodyPieceGuard.CHECK_EVERY = 1.5
BodyPieceGuard.BATCH = 300

local hidden: { [BasePart]: boolean } = setmetatable({}, { __mode = "k" }) :: any

-- ¿Se esconde? (las cuentas, aparte para las pruebas)
function BodyPieceGuard.shouldHide(verdict: string): boolean
	return BodyPieces.orphan(verdict) or verdict == "Hidden"
end

function BodyPieceGuard.check(pieces: { Instance }, world: Instance, wait: (() -> ())?): number
	local count = 0
	for i, piece in pieces do
		if wait and i % BodyPieceGuard.BATCH == 0 then
			wait()
		end
		if not piece:IsA("BasePart") or not piece.Parent or not BodyPieces.isPiece(piece) then
			continue -- (solo las piezas con la etiqueta BodyPiece)
		end
		local part = piece :: BasePart
		local ok, verdict = pcall(function()
			return BodyPieces.verdict(BodyPieces.inspect(part, world))
		end)
		if not ok then
			continue
		end
		if BodyPieceGuard.shouldHide(verdict) then
			count += 1
			local ok, ltm = pcall(function()
				return (part :: any).LocalTransparencyModifier
			end)
			if not ok or type(ltm) ~= "number" or ltm < 1 then
				(part :: any).LocalTransparencyModifier = 1
			end
			hidden[part] = true
		elseif hidden[part] then
			hidden[part] = nil
			;(part :: any).LocalTransparencyModifier = 0
		end
	end
	return count
end

function BodyPieceGuard.init()
	task.spawn(function()
		while true do
			task.wait(BodyPieceGuard.CHECK_EVERY)
			pcall(BodyPieceGuard.check, CollectionService:GetTagged(BodyPieces.TAG), workspace, task.wait)
		end
	end)
end

return BodyPieceGuard
