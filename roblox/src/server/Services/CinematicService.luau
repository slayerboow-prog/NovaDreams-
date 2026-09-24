-- CinematicService: prepara y lanza las escenas de cámara de la historia (shared/LifeStory/Cinematics.luau).
-- Para cada jugador busca sus anclas (SU casa, SU ventanal, la zona…), pide al mapa que cargue esas
-- zonas (el mapa se carga por trozos, StreamingEnabled) y manda la escena al cliente, que la dibuja.
-- Devuelve lo que dura la escena, para que la historia siga cuando termine.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cinematics = require(ReplicatedStorage.Shared.LifeStory.Cinematics)
local LocationService = require(script.Parent.LocationService)

local CinematicService = {}

local function rootCFrame(player: Player): CFrame?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root and root.CFrame
end

-- Anclas de la escena para este jugador. Si alguna no existe en el mapa, se usa el propio jugador,
-- así la escena se ve igualmente (nunca se queda la cámara en el vacío).
function CinematicService.resolveAnchors(player: Player, cinematic: { [string]: any }): { [string]: CFrame }
	local fallback = rootCFrame(player) or CFrame.new()
	local anchors = {}
	for name, anchor in cinematic.Anchors or {} do
		local cf: CFrame? = nil
		if anchor == "Player" then
			cf = rootCFrame(player)
		else
			local kind, value = anchor:match("^(%a+):(.+)$")
			if kind == "Place" then
				local spot = LocationService.resolve(player, value)
				cf = spot and spot.CFrame
			elseif kind == "Zone" then
				local center = LocationService.zoneCenter(value)
				cf = center and CFrame.new(center)
			end
		end
		if not cf and anchor ~= "Player" then
			warn(("[CinematicService] Ancla '%s' (%s) no encontrada; se usa el jugador"):format(name, anchor))
		end
		anchors[name] = cf or fallback
	end
	return anchors
end

-- Lanza la escena y devuelve cuánto dura (0 si no existe)
function CinematicService.play(player: Player, id: string): number
	local cinematic = Cinematics[id]
	local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("LifeStory")
	if not cinematic or not remote then
		warn("[CinematicService] No se puede reproducir", id)
		return 0
	end
	local anchors = CinematicService.resolveAnchors(player, cinematic)
	remote:FireClient(player, "Cinematic", {
		Id = id,
		Anchors = anchors,
		Names = {
			Abu = player:GetAttribute("AbuKey") or "NPC.ABU_ROSA",
			Familia = player:GetAttribute("FamilyKey") or "NPC.MAMA",
			Profe = "NPC.PROFE_LUCIA",
			Rectora = "NPC.AMAIA",
		},
		Args = { nombre = player.DisplayName },
	})
	-- Que el mapa cargue lo que va a enseñar la cámara (en paralelo: la escena ya ha empezado)
	for _, cf in anchors do
		task.spawn(function()
			pcall(function()
				player:RequestStreamAroundAsync(cf.Position, 4)
			end)
		end)
	end
	return cinematic.Duration
end

function CinematicService.init() end

return CinematicService
