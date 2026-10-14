-- BodyPieceService (servidor): red de seguridad contra «pelos volando por todos lados» (v114).
--
-- Cada pieza pegada a un cuerpo (pelo, cuello, ropa 3D, disfraz…) lleva la etiqueta BodyPiece
-- (shared/BodyPieces.mark). Cada SWEEP_EVERY segundos se mira solo esa lista (barato: no recorre el
-- mapa) y se quita lo que ya no tiene sentido:
--   * NoCharacter: ya no está dentro de un personaje (Model con Humanoid)
--   * NoWeld:      sin soldadura a una parte del cuerpo de su personaje (cae, flota o se queda atrás)
--   * Far:         soldada pero lejos de su parte, dos vistazos seguidos (se ha quedado atrás)
-- Una pieza anclada se suelta (Anchored = false: la mueve su soldadura). Lo que está fuera de
-- workspace (modelos aún sin colocar, los del colegio guardados fuera de horario) no se toca.
-- Aviso en la consola como mucho uno por minuto con cuántas se han quitado (BodyPieces.Log).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BodyPieces = require(ReplicatedStorage.Shared.BodyPieces)

local BodyPieceService = {}

BodyPieceService.SWEEP_EVERY = 10
BodyPieceService.BATCH = 400 -- piezas por tanda (si hay muchas, se reparte en varios fotogramas)

local log = BodyPieces.Log("BodyPieceService")
local far: { [BasePart]: boolean } = setmetatable({}, { __mode = "k" }) :: any
BodyPieceService._log = log -- (pruebas)

-- Un vistazo a una lista de piezas. Devuelve cuántas se han quitado. world: workspace (o el de la prueba)
function BodyPieceService.sweep(pieces: { Instance }, world: Instance, wait: (() -> ())?): number
	local removed = 0
	for i, piece in pieces do
		if wait and i % BodyPieceService.BATCH == 0 then
			wait()
		end
		if not piece:IsA("BasePart") or not piece.Parent or not BodyPieces.isPiece(piece) then
			continue -- (solo las piezas con la etiqueta BodyPiece)
		end
		local ok, verdict = pcall(function()
			return BodyPieces.verdict(BodyPieces.inspect(piece :: BasePart, world))
		end)
		if not ok then
			continue
		end
		if verdict == "Far" and not far[piece :: BasePart] then
			far[piece :: BasePart] = true -- (a la segunda: un tirón de un fotograma no cuenta)
			continue
		end
		if verdict ~= "Far" then
			far[piece :: BasePart] = nil
		end
		if BodyPieces.orphan(verdict) then
			removed += 1
			far[piece :: BasePart] = nil
			pcall(piece.Destroy, piece)
		elseif verdict == "Anchored" then
			pcall(function()
				(piece :: BasePart).Anchored = false
			end)
		end
	end
	log.add(removed)
	return removed
end

function BodyPieceService.init()
	task.spawn(function()
		while true do
			task.wait(BodyPieceService.SWEEP_EVERY)
			local ok, err = pcall(function()
				BodyPieceService.sweep(CollectionService:GetTagged(BodyPieces.TAG), workspace, task.wait)
				local text = log.flush(os.clock())
				if text then
					warn(text)
				end
			end)
			if not ok then
				warn("[BodyPieceService] " .. tostring(err))
			end
		end
	end)
end

return BodyPieceService
