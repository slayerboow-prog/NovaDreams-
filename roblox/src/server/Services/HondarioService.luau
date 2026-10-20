-- HondarioService (servidor): la «VIDA HONDARIA» del modo pruebas (docs/mar/civilizacion-marina.md, fase 1).
--
-- El dueño pidió en pruebas «una opción para acceder a una vida nueva bajo el agua». La «Vida nueva» de
-- verdad (DataService.newLife) BORRA la partida y te saca del juego: no vale para probar y volver. Por eso
-- esto es un INTERRUPTOR reversible solo para testers (TesterService: «🐚 Nueva vida: Hondario» y
-- «🧍 Volver a vida humana»), que no borra nada:
--   * Se guarda en los ajustes del tester: data.Tester.Hondario = { On, Home, StayHuman, Prev = { Stage,
--     Spawn } } (Prev = tu etapa y tu cama de antes: al volver a la vida humana se devuelven).
--   * Eres adulto (la etapa la pone TesterService.setStage: las conchas y los oficios piden mayoría de
--     edad; nacer bebé bajo el agua es la fase 5 del plan).
--   * Tu casa: una concha con aire del Barrio de las Conchas (MarCasa_Nacara_1); su hamaca es tu punto de
--     reaparición (data.SpawnPoint, como dormir en una cama). Al activarla apareces allí, y después de
--     morir vuelves allí (no al hospital de Valmar).
--   * El cuerpo (World/MerBody): con cola dentro del agua, con piernas en tierra, en un barco o en una
--     cúpula de aire. «Quedarme en forma humana» (botón del HUD, Controllers/MerForm) lo deja en piernas.
--   * Los dones (los decide el servidor): respiras bajo el agua sin límite (atributo Gills: DivingService
--     deja el aire lleno), la presión no te hace daño hasta MerForm.Depth m y nunca en los barrios de
--     Nácara (atributo HondarioSafe), y nadas más rápido con cola (Controllers/Swimming).
--   * Valmar sigue ahí: sal del agua andando por cualquier playa (piernas) y todo funciona como siempre.
--   * La historia del mar (Mar_00…) empieza sola al activarla (HondarioService.startStory).
-- Atributos del jugador: Hondario, Gills, HondarioSafe, HondarioStayHuman, HondarioHome; del personaje:
-- SeaForm ("Cola" | "Piernas").

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MerForm = require(ReplicatedStorage.Shared.Sea.MerForm)
local Civ = require(ReplicatedStorage.Shared.Sea.Civ)
local Nacara = require(ReplicatedStorage.Shared.Sea.Nacara)
local MerBody = require(script.Parent.Parent.World.MerBody)
local DataService = require(script.Parent.DataService)

local HondarioService = {}

HondarioService.Tick = 0.25
HondarioService.Look = { Scales = Color3.fromRGB(40, 170, 190), Crest = Color3.fromRGB(120, 240, 255), Nacre = Color3.fromRGB(226, 222, 238) }

local notify: RemoteEvent? = nil
local pending: { [Player]: { Form: string, Since: number } } = {}
local died: { [Player]: boolean } = {}

local function service(name: string): any
	return require(script.Parent[name])
end

local function toast(player: Player, kind: string, text: string)
	if notify and player.Parent then
		notify:FireClient(player, kind, text)
	end
end

local function settings(player: Player): { [string]: any }?
	local data = DataService.get(player)
	local t = data and data.Tester
	local h = type(t) == "table" and t.Hondario or nil
	return if type(h) == "table" then h else nil
end

-- ¿Vive ahora una vida hondaria? (SOLO testers: si ya no es tester, el ajuste guardado no hace nada)
function HondarioService.active(player: Player): boolean
	local h = settings(player)
	if not h or h.On ~= true then
		return false
	end
	local ok, tester = pcall(function()
		return service("TesterService").isTester(player)
	end)
	return ok and tester == true
end

local function homeOf(player: Player): { [string]: any }
	local h = settings(player)
	return Civ.HomeByKey[h and h.Home or ""] or Civ.HomeByKey[Civ.DefaultHome]
end

local function setSpawnAtHome(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local bed = Civ.bedPosition(homeOf(player))
	data.SpawnPoint = { X = math.round(bed.X * 10) / 10, Y = math.round(bed.Y * 10) / 10, Z = math.round(bed.Z * 10) / 10 }
	player:SetAttribute("SpawnPoint", bed)
end

local function publish(player: Player)
	local on = HondarioService.active(player)
	local h = settings(player)
	player:SetAttribute("Hondario", if on then true else nil)
	player:SetAttribute("Gills", if on then true else nil)
	player:SetAttribute("HondarioStayHuman", if on and h and h.StayHuman then true else nil)
	player:SetAttribute("HondarioHome", if on then homeOf(player).Key else nil)
	if not on then
		player:SetAttribute("HondarioSafe", nil)
	end
end

local function dress(player: Player)
	local character = player.Character
	if not character then
		return
	end
	if HondarioService.active(player) then
		MerBody.build(character, HondarioService.Look)
	else
		MerBody.remove(character)
	end
end

-- Lleva al jugador a su concha (de pie en el suelo seco)
function HondarioService.goHome(player: Player): boolean
	local pos = Civ.bedPosition(homeOf(player))
	local ok = pcall(function()
		service("SceneService").teleportTo(player, pos)
	end)
	if not ok then
		local character = player.Character
		if character then
			character:PivotTo(CFrame.new(pos))
		end
	end
	return true
end

-- Empieza la vida hondaria. (TesterService ya ha comprobado que es tester y le ha hecho adulto;
-- prevStage = su etapa de antes, para devolvérsela.) Devuelve true si ahora es hondario.
function HondarioService.enable(player: Player, prevStage: string?): boolean
	local ok, tester = pcall(function()
		return service("TesterService").isTester(player)
	end)
	local data = DataService.get(player)
	if not ok or not tester or not data then
		return false
	end
	data.Tester = if type(data.Tester) == "table" then data.Tester else {}
	local h = settings(player)
	if not h then
		h = {}
		data.Tester.Hondario = h
	end
	if h.On ~= true then
		-- lo de antes, para devolverlo al volver a la vida humana
		h.Prev = { Stage = prevStage, Spawn = if type(data.SpawnPoint) == "table" then table.clone(data.SpawnPoint) else nil }
	end
	h.On = true
	h.Home = if Civ.HomeByKey[h.Home or ""] then h.Home else Civ.DefaultHome
	h.StayHuman = false
	h.Since = os.time()
	-- la concha también queda como la vivienda del mar que tienes (la misma clave que al alquilarla)
	local okCiv = pcall(function()
		service("SeaCivService").setHome(player, h.Home, true)
	end)
	local _ = okCiv
	setSpawnAtHome(player)
	publish(player)
	dress(player)
	HondarioService.goHome(player)
	HondarioService.startStory(player)
	return true
end

-- La historia del mar empieza sola («El niño del arrecife»), si se puede ahora; si no (una conversación o
-- una escena en marcha), se vuelve a probar en un momento
HondarioService.FirstMission = "Mar_00_Arrecife"
function HondarioService.startStory(player: Player): boolean
	local function try(): boolean
		local ok, started = pcall(function()
			return service("LifeStoryService").startCanon(player, HondarioService.FirstMission)
		end)
		return ok and started == true
	end
	if try() then
		return true
	end
	task.delay(4, function()
		if player.Parent and HondarioService.active(player) then
			try()
		end
	end)
	return false
end

-- Vuelve a la vida humana: devuelve la cama de antes, quita la cola y te deja en la playa más cercana
-- de Nácara (la del jardín de coral del sur), ya respirando aire. Devuelve la etapa de antes.
function HondarioService.disable(player: Player): (boolean, string?)
	local data = DataService.get(player)
	local h = settings(player)
	if not data or not h or h.On ~= true then
		return false, nil
	end
	h.On = false
	local prev = h.Prev or {}
	data.SpawnPoint = if type(prev.Spawn) == "table" then prev.Spawn else nil
	if type(prev.Spawn) == "table" then
		player:SetAttribute("SpawnPoint", Vector3.new(prev.Spawn.X, prev.Spawn.Y, prev.Spawn.Z))
	else
		player:SetAttribute("SpawnPoint", nil)
	end
	h.Prev = nil
	publish(player)
	dress(player)
	pending[player] = nil
	-- a tierra firme: la playa delante del jardín de coral más cercano a Nácara
	pcall(function()
		local spot = service("LocationService").resolve(player, "Playa")
		if spot then
			service("SceneService").teleportTo(player, spot.Position)
		end
	end)
	return true, prev.Stage
end

-- «Quedarme en forma humana» (el botón del HUD). Devuelve el valor nuevo.
function HondarioService.setStayHuman(player: Player, on: boolean): boolean?
	if not HondarioService.active(player) then
		return nil
	end
	local h = settings(player) :: { [string]: any }
	h.StayHuman = on == true
	publish(player)
	toast(player, "Info", if h.StayHuman then "🧍 Te quedas en forma humana (sigues respirando bajo el agua)" else "🐚 Forma automática: cola en el agua, piernas en tierra")
	return h.StayHuman
end

---------------------------------------------------------------------
-- La forma (cada cuarto de segundo)
---------------------------------------------------------------------
local function sparkle(character: Model)
	local hip = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
	if not hip or not hip:IsA("BasePart") then
		return
	end
	local e = Instance.new("ParticleEmitter")
	e.Name = "BrilloMarea"
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Rate = 0
	e.Lifetime = NumberRange.new(0.6, 1.1)
	e.Speed = NumberRange.new(2, 5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Size = NumberSequence.new(0.4, 0)
	e.LightEmission = 0.8
	e.Color = ColorSequence.new(Color3.fromRGB(150, 245, 255))
	e.Parent = hip
	pcall(function()
		e:Emit(24)
	end)
	task.delay(1.5, function()
		e:Destroy()
	end)
end

function HondarioService.formFor(player: Player): string
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return "Piernas"
	end
	local under = false
	pcall(function()
		under = service("DivingService").underwater(player)
	end)
	local h = settings(player)
	local seated, dead = false, false
	pcall(function()
		seated = humanoid.SeatPart ~= nil or humanoid.Sit == true
		dead = humanoid.Health <= 0
	end)
	return MerForm.form({
		Gift = HondarioService.active(player),
		StayHuman = h ~= nil and h.StayHuman == true,
		Underwater = under,
		InAir = Nacara.inDome(root.CFrame.Position),
		Seated = seated,
		Dead = dead,
	})
end

function HondarioService.step(player: Player, now: number)
	if not HondarioService.active(player) then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	if not character:FindFirstChild(MerBody.Folder) then
		MerBody.build(character, HondarioService.Look)
	end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		local d = Civ.districtAt(root.CFrame.Position)
		player:SetAttribute("HondarioSafe", if d and d.Safe then d.Id else nil)
	end
	local want = HondarioService.formFor(player)
	local have = character:GetAttribute("SeaForm")
	if want == have then
		pending[player] = nil
		if want == "Cola" then
			MerBody.enforce(character)
		end
		return
	end
	local p = pending[player]
	if not p or p.Form ~= want then
		pending[player] = { Form = want, Since = now }
		return
	end
	if now - p.Since >= MerForm.FormGrace then
		pending[player] = nil
		if MerBody.setForm(character, want) then
			sparkle(character)
		end
	end
end

---------------------------------------------------------------------

function HondarioService.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	notify = remotes:FindFirstChild("Notify") :: RemoteEvent?
	local remote = remotes:FindFirstChild("Hondario") :: RemoteEvent?
	if not remote then
		local r = Instance.new("RemoteEvent")
		r.Name = "Hondario"
		r.Parent = remotes
		remote = r
	end
	;(remote :: RemoteEvent).OnServerEvent:Connect(function(player, kind, value)
		if kind == "StayHuman" and type(value) == "boolean" then
			HondarioService.setStayHuman(player, value)
		end
	end)
	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character)
			pending[player] = nil
			local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
			if humanoid then
				humanoid.Died:Connect(function()
					died[player] = true
				end)
			end
			task.delay(1.5, function()
				if player.Character ~= character then
					return
				end
				dress(player)
				if died[player] and HondarioService.active(player) then
					died[player] = nil
					-- después del hospital, a tu concha (no a Valmar)
					for _ = 1, 40 do
						if not player:GetAttribute("Dead") then
							break
						end
						task.wait(0.5)
					end
					if player.Character == character then
						HondarioService.goHome(player)
					end
				end
				died[player] = nil
			end)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	DataService.onLoaded(function(player)
		publish(player)
		if HondarioService.active(player) then
			task.delay(2, dress, player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		pending[player] = nil
		died[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(HondarioService.Tick)
			local now = os.clock()
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(HondarioService.step, player, now)
				if not ok then
					warn("[HondarioService] " .. tostring(err))
				end
			end
		end
	end)
end

-- (pruebas)
HondarioService._pending = pending

return HondarioService
