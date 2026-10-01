-- AvatarService: aspecto por defecto del protagonista (Config.DefaultLook).
--   Sudadera negra con capucha gris abierta, camiseta blanca, colgante con chapa, pantalón cargo
--   negro ancho con bolsillos, zapatillas blancas, mochila negra y pelo castaño despeinado.
--   * Cambia con la etapa de vida: el bebé lleva pelele, el niño no lleva colgante y de mayor
--     el pelo es canoso y sin mochila.
--   * En el Menú, "👕 Ropa" cambia entre este aspecto y el avatar de Roblox de cada jugador
--     (se guarda en su partida: data.OwnAvatar).
-- La ropa son piezas pegadas al cuerpo (carpeta "ValmarLook" dentro del personaje): no hace
-- falta subir nada a Roblox. Si algún día subes una cara o ropa, pon sus IDs en Config.DefaultLook.
--   * Conjuntos del pase (shared/Outfits, 30): si llevas uno equipado, lo viste shared/OutfitBuilder
--     (con sus plantillas de ropa si ya están subidas: shared/OutfitIds; si no, con colores y piezas).
--     El bebé sigue con su pelele; de niño, en talla de niño. De servicio en un oficio con uniforme
--     (Outfits.SuspendJobs) o en prisión se guarda y llevas el aspecto de siempre bajo el uniforme;
--     al acabar el turno vuelve solo. La ropa nunca da un trabajo ni sus permisos (eso es el atributo Job).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local OutfitBuilder = require(ReplicatedStorage.Shared.OutfitBuilder)
local Outfits = require(ReplicatedStorage.Shared.Outfits)
local DataService = require(script.Parent.DataService)
local LifeService = require(script.Parent.LifeService)

local AvatarService = {}

local LOOK = Config.DefaultLook
local busy: { [Player]: boolean } = {}

local function useOwn(player: Player): boolean
	local data = DataService.get(player)
	return not LOOK.Enabled or (data ~= nil and data.OwnAvatar == true)
end

---------------------------------------------------------------------
-- Piezas de ropa
---------------------------------------------------------------------

local function paint(character: Model, names: { string }, color: Color3, material: Enum.Material?)
	for _, name in names do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = color
			if material then
				part.Material = material
			end
		end
	end
end

local function attach(folder: Instance, to: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Size = Vector3.new(math.max(size.X, 0.05), math.max(size.Y, 0.05), math.max(size.Z, 0.05))
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = size.Magnitude > 1
	part.CFrame = to.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = to
	weld.Part1 = part
	weld.Parent = part
	part.Parent = folder
	return part
end

-- Conjunto de ropa equipado del pase de temporada (BattlePassRewardService.outfitFor): su
-- definición (Outfit = clave de shared/Outfits, Colors = colores del aspecto de Valmar) o, en
-- versiones viejas, solo los colores. nil = el aspecto de siempre.
AvatarService.OutfitFor = nil :: ((Player) -> { [string]: any }?)?

-- Lo equipado ahora (nil si no hay, si el gancho falla o si está guardado por el uniforme/prisión)
function AvatarService.outfitOf(player: Player): { [string]: any }?
	if not AvatarService.OutfitFor or Outfits.suspended(player) then
		return nil
	end
	local ok, def = pcall(AvatarService.OutfitFor, player)
	return if ok and type(def) == "table" then def else nil
end

local function lookFor(outfit: { [string]: any }?): { [string]: any }
	local colors = if outfit and type(outfit.Colors) == "table" then outfit.Colors else outfit
	if type(colors) ~= "table" then
		return LOOK
	end
	local merged = table.clone(LOOK)
	for key, color in colors do
		if typeof(color) == "Color3" and typeof(LOOK[key]) == "Color3" and key ~= "Skin" then
			merged[key] = color
		end
	end
	return merged
end

local function dress(player: Player, character: Model)
	local old = character:FindFirstChild("ValmarLook")
	if old then
		old:Destroy()
	end
	OutfitBuilder.clearClothes(character)
	if useOwn(player) then
		return
	end
	local stage = player:GetAttribute("LifeStage")
	local baby = stage == "Bebe"
	local kid = stage == "Nino"
	local isOld = stage == "Mayor"
	local outfit = AvatarService.outfitOf(player)
	local full = outfit and Outfits.get(outfit.Outfit)
	if full and not baby then
		-- Conjunto del pase (con su talla según la edad)
		paint(character, { "Head" }, LOOK.Skin)
		local ok, err = pcall(OutfitBuilder.dress, character, full, {
			Stage = stage,
			Skin = LOOK.Skin,
			HairColor = if isOld then LOOK.HairOld else LOOK.Hair,
			Seed = player.UserId,
		})
		if ok then
			return
		end
		warn("[AvatarService] No se pudo poner el conjunto " .. tostring(full.Key) .. ": " .. tostring(err))
		local broken = character:FindFirstChild("ValmarLook")
		if broken then
			broken:Destroy()
		end
		OutfitBuilder.clearClothes(character, true)
	end
	local LOOK = lookFor(if full then nil else outfit)
	local folder = Instance.new("Folder")
	folder.Name = "ValmarLook"
	local rng = Random.new(player.UserId)
	local fabric = Enum.Material.Fabric

	paint(character, { "Head", "LeftHand", "RightHand", "Head", "Left Arm", "Right Arm" }, LOOK.Skin)
	OutfitBuilder.hair(folder, character, "Messy", if isOld then LOOK.HairOld else LOOK.Hair, rng, baby)

	if baby then
		-- Pelele de una pieza con botones
		paint(character, { "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot", "Torso", "Left Leg", "Right Leg" }, LOOK.Onesie, fabric)
		local torso = character:FindFirstChild("UpperTorso") :: BasePart?
		if torso then
			local t = torso.Size
			for k = 0, 2 do
				attach(folder, torso, "Button", Vector3.new(t.X * 0.08, t.X * 0.08, 0.05), CFrame.new(0, t.Y * (0.25 - k * 0.25), -t.Z / 2 - 0.02), Color3.new(1, 1, 1))
			end
			attach(folder, torso, "Bib", Vector3.new(t.X * 0.5, t.Y * 0.35, 0.05), CFrame.new(0, t.Y * 0.28, -t.Z / 2 - 0.02), Color3.new(1, 1, 1), fabric)
		end
		folder.Parent = character
		return
	end

	-- SUDADERA con capucha, abierta sobre la camiseta blanca
	paint(character, { "UpperTorso", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "Torso", "Left Arm", "Right Arm" }, LOOK.Hoodie, fabric)
	paint(character, { "LeftHand", "RightHand" }, LOOK.Skin)
	local torso = character:FindFirstChild("UpperTorso") :: BasePart?
	if torso then
		local t = torso.Size
		local front = -t.Z / 2
		attach(folder, torso, "Tee", Vector3.new(t.X * 0.4, t.Y * 0.98, 0.05), CFrame.new(0, 0, front - 0.02), LOOK.Tee, fabric)
		for _, sx in { -1, 1 } do
			-- Borde de la cremallera y forro gris de la capucha bajando por el cuello
			attach(folder, torso, "Zip", Vector3.new(t.X * 0.04, t.Y, 0.06), CFrame.new(sx * t.X * 0.21, 0, front - 0.03), Color3.fromRGB(60, 60, 66), Enum.Material.Metal)
			attach(folder, torso, "HoodEdge", Vector3.new(t.X * 0.08, t.Y * 0.45, 0.07), CFrame.new(sx * t.X * 0.25, t.Y * 0.26, front - 0.04) * CFrame.Angles(0, 0, math.rad(sx * 12)), LOOK.HoodLining, fabric)
			-- Cordones de la capucha
			attach(folder, torso, "Drawstring", Vector3.new(0.06, t.Y * 0.4, 0.06), CFrame.new(sx * t.X * 0.15, t.Y * 0.12, front - 0.07), Color3.fromRGB(235, 235, 235))
			-- Bolsillo delantero (canguro), a cada lado de la cremallera
			attach(folder, torso, "PocketLine", Vector3.new(t.X * 0.24, 0.05, 0.05), CFrame.new(sx * t.X * 0.36, -t.Y * 0.2, front - 0.03), Color3.fromRGB(50, 50, 56))
		end
		-- Capucha caída en la espalda (gris por dentro, negra por fuera)
		attach(folder, torso, "HoodLining", Vector3.new(t.X * 0.72, t.Y * 0.3, t.Z * 0.55), CFrame.new(0, t.Y * 0.52, t.Z * 0.2), LOOK.HoodLining, fabric)
		attach(folder, torso, "Hood", Vector3.new(t.X * 0.78, t.Y * 0.42, t.Z * 0.3), CFrame.new(0, t.Y * 0.42, t.Z * 0.55), LOOK.Hoodie, fabric)
		-- Logo pequeño en el pecho
		attach(folder, torso, "Logo", Vector3.new(t.X * 0.1, t.X * 0.1, 0.04), CFrame.new(-t.X * 0.33, t.Y * 0.24, front - 0.03), Color3.fromRGB(230, 230, 230))
		-- Colgante: cadena y chapa (desde adolescente)
		if not kid then
			for _, sx in { -1, 1 } do
				attach(folder, torso, "Chain", Vector3.new(0.05, t.Y * 0.42, 0.05), CFrame.new(sx * t.X * 0.08, t.Y * 0.25, front - 0.06) * CFrame.Angles(0, 0, math.rad(sx * 18)), LOOK.Metal, Enum.Material.Metal)
			end
			attach(folder, torso, "DogTag", Vector3.new(t.X * 0.1, t.Y * 0.2, 0.05), CFrame.new(0, t.Y * 0.0, front - 0.07), LOOK.Metal, Enum.Material.Metal)
		end
		-- MOCHILA negra con asas por delante (de mayor, sin mochila)
		if not isOld then
			local bag = CFrame.new(0, -t.Y * 0.08, t.Z * 0.5 + t.Z * 0.38)
			attach(folder, torso, "Backpack", Vector3.new(t.X * 0.82, t.Y * 1.1, t.Z * 0.72), bag, LOOK.Backpack, fabric)
			attach(folder, torso, "BackpackPocket", Vector3.new(t.X * 0.6, t.Y * 0.45, t.Z * 0.22), bag * CFrame.new(0, -t.Y * 0.22, t.Z * 0.45), LOOK.Backpack:Lerp(Color3.new(1, 1, 1), 0.06), fabric)
			attach(folder, torso, "BackpackZip", Vector3.new(t.X * 0.62, 0.05, 0.05), bag * CFrame.new(0, 0.02, t.Z * 0.57), Color3.fromRGB(90, 90, 96), Enum.Material.Metal)
			attach(folder, torso, "BackpackLogo", Vector3.new(t.X * 0.12, t.X * 0.12, 0.04), bag * CFrame.new(0, -t.Y * 0.2, t.Z * 0.58), Color3.fromRGB(220, 220, 220))
			attach(folder, torso, "BackpackHandle", Vector3.new(t.X * 0.25, 0.1, 0.1), bag * CFrame.new(0, t.Y * 0.57, 0), LOOK.Backpack, fabric)
			for _, sx in { -1, 1 } do
				attach(folder, torso, "Strap", Vector3.new(t.X * 0.1, t.Y * 1.02, 0.08), CFrame.new(sx * t.X * 0.4, 0, front - 0.05), Color3.fromRGB(16, 16, 18), fabric)
				attach(folder, torso, "StrapTop", Vector3.new(t.X * 0.1, 0.08, t.Z * 1.1), CFrame.new(sx * t.X * 0.4, t.Y / 2 + 0.03, 0), Color3.fromRGB(16, 16, 18), fabric)
			end
		end
	end
	-- Puños de la sudadera
	for _, name in { "LeftLowerArm", "RightLowerArm" } do
		local arm = character:FindFirstChild(name) :: BasePart?
		if arm then
			local a = arm.Size
			attach(folder, arm, "Cuff", Vector3.new(a.X * 1.12, a.Y * 0.18, a.Z * 1.12), CFrame.new(0, -a.Y * 0.4, 0), Color3.fromRGB(40, 40, 46), fabric)
		end
	end

	-- PANTALÓN CARGO negro, ancho, con bolsillos laterales
	paint(character, { "LowerTorso", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "Left Leg", "Right Leg" }, LOOK.Pants, Enum.Material.Fabric)
	local waist = character:FindFirstChild("LowerTorso") :: BasePart?
	if waist then
		local w = waist.Size
		-- Bajo de la sudadera y la camiseta que asoma
		attach(folder, waist, "HoodieHem", Vector3.new(w.X * 1.05, w.Y * 0.35, w.Z * 1.06), CFrame.new(0, w.Y * 0.32, 0), Color3.fromRGB(34, 34, 38), fabric)
		attach(folder, waist, "TeeHem", Vector3.new(w.X * 0.38, w.Y * 0.38, 0.05), CFrame.new(0, w.Y * 0.3, -w.Z * 0.53 - 0.03), LOOK.Tee, fabric)
	end
	for _, side in { { "LeftUpperLeg", -1 }, { "RightUpperLeg", 1 } } do
		local leg = character:FindFirstChild(side[1]) :: BasePart?
		if leg then
			local l, sx = leg.Size, side[2]
			attach(folder, leg, "CargoPocket", Vector3.new(0.12, l.Y * 0.42, l.Z * 0.62), CFrame.new(sx * (l.X / 2 + 0.05), -l.Y * 0.1, 0), LOOK.Pants:Lerp(Color3.new(1, 1, 1), 0.06), Enum.Material.Fabric)
			attach(folder, leg, "PocketFlap", Vector3.new(0.14, l.Y * 0.1, l.Z * 0.66), CFrame.new(sx * (l.X / 2 + 0.07), l.Y * 0.12, 0), LOOK.Pants:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.Fabric)
		end
	end
	for _, name in { "LeftLowerLeg", "RightLowerLeg" } do
		local leg = character:FindFirstChild(name) :: BasePart?
		if leg then
			local l = leg.Size
			-- Pernera ancha que cae sobre la zapatilla
			attach(folder, leg, "BaggyLeg", Vector3.new(l.X * 1.2, l.Y * 0.95, l.Z * 1.2), CFrame.new(0, -l.Y * 0.04, 0), LOOK.Pants, Enum.Material.Fabric)
		end
	end

	-- ZAPATILLAS blancas con suela y cordones
	paint(character, { "LeftFoot", "RightFoot" }, LOOK.Shoes)
	for _, name in { "LeftFoot", "RightFoot" } do
		local foot = character:FindFirstChild(name) :: BasePart?
		if foot then
			local f = foot.Size
			attach(folder, foot, "Sneaker", Vector3.new(f.X * 1.14, f.Y * 1.05, f.Z * 1.18), CFrame.new(0, 0, -f.Z * 0.05), LOOK.Shoes)
			attach(folder, foot, "Sole", Vector3.new(f.X * 1.2, f.Y * 0.3, f.Z * 1.24), CFrame.new(0, -f.Y * 0.4, -f.Z * 0.05), Color3.fromRGB(215, 215, 218), Enum.Material.Rubber)
			attach(folder, foot, "Laces", Vector3.new(f.X * 0.45, 0.05, f.Z * 0.4), CFrame.new(0, f.Y * 0.55, -f.Z * 0.2), Color3.fromRGB(200, 200, 204))
		end
	end
	folder.Parent = character
end

AvatarService._dress = dress -- (pruebas)

---------------------------------------------------------------------

local function description(player: Player): HumanoidDescription?
	if useOwn(player) then
		local ok, desc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(math.max(player.UserId, 1))
		end)
		return if ok then desc else nil
	end
	local desc = Instance.new("HumanoidDescription")
	for _, field in { "HeadColor", "TorsoColor", "LeftArmColor", "RightArmColor", "LeftLegColor", "RightLegColor" } do
		(desc :: any)[field] = LOOK.Skin
	end
	desc.Face = LOOK.FaceId
	desc.Shirt = LOOK.ShirtId
	desc.Pants = LOOK.PantsId
	return desc
end

-- Aplica el aspecto (el de Valmar o el avatar propio) al personaje actual
function AvatarService.apply(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or busy[player] then
		return
	end
	busy[player] = true
	local ok, err = pcall(function()
		local desc = description(player)
		if desc then
			-- Con tamaño normal: luego LifeService le devuelve el tamaño de su edad
			if math.abs(character:GetScale() - 1) > 0.01 then
				character:ScaleTo(1)
			end
			humanoid:ApplyDescription(desc)
		end
		dress(player, character)
	end)
	if not ok then
		warn("[AvatarService] No se pudo aplicar el aspecto:", err)
	end
	busy[player] = false
	LifeService.refresh(player)
end

local function watch(player: Player)
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 10)
		-- Esperar a que Roblox cargue su avatar (si no, lo pisaría después)
		local deadline = os.clock() + 6
		while not player:HasAppearanceLoaded() and os.clock() < deadline and character.Parent do
			task.wait(0.2)
		end
		DataService.waitFor(player, 15)
		if player.Character == character then
			AvatarService.apply(player)
		end
	end)
	-- Al cambiar de etapa cambia la ropa (pelele de bebé, colgante, canas…)
	player:GetAttributeChangedSignal("LifeStage"):Connect(function()
		if player.Character and not useOwn(player) then
			local character = player.Character
			if character then
				dress(player, character)
			end
		end
	end)
	-- Empezar o acabar un turno con uniforme (o entrar/salir de prisión): el conjunto del pase se
	-- guarda y vuelve (solo si cambia algo y llevas uno equipado)
	local wasSuspended = Outfits.suspended(player)
	local function onDuty()
		local now = Outfits.suspended(player)
		if now == wasSuspended then
			return
		end
		wasSuspended = now
		local character = player.Character
		if character and not useOwn(player) and AvatarService.OutfitFor then
			local ok, def = pcall(AvatarService.OutfitFor, player)
			if ok and type(def) == "table" then
				dress(player, character)
			end
		end
	end
	player:GetAttributeChangedSignal("Job"):Connect(onDuty)
	player:GetAttributeChangedSignal("JailUntil"):Connect(onDuty)
end

local lastToggle: { [Player]: number } = {}

function AvatarService.init()
	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
		lastToggle[player] = nil
	end)
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	DataService.onLoaded(function(player, data)
		player:SetAttribute("OwnAvatar", data.OwnAvatar == true)
	end)
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Avatar") :: RemoteEvent
	remote.OnServerEvent:Connect(function(player, action)
		local data = DataService.get(player)
		-- (con su pausa: cada cambio vuelve a vestir al personaje, no se puede pedir sin parar)
		if action ~= "Toggle" or not data or busy[player] or os.clock() - (lastToggle[player] or -10) < 2 then
			return
		end
		lastToggle[player] = os.clock()
		data.OwnAvatar = not data.OwnAvatar
		player:SetAttribute("OwnAvatar", data.OwnAvatar)
		AvatarService.apply(player)
	end)
end

return AvatarService
