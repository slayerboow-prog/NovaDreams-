-- ZonasDeporteService (servidor): los carteles «Jugar» de los deportes en las zonas verdes de ocio.
--
--   * Playa de Levante (zona 6): «Jugar · Vóley» en cada pista (tag OcioVolleyCourt) → partido libre
--     2 contra 2 con VolleyService.startFree en ESA pista (red y líneas ya construidas), fuera de la
--     historia. Una pista, un partido. Al acabar: diversión, experiencia y un poco de dinero si ganas.
--   * Polideportivo del Campus (zona 8): «Jugar · Tenis» y «Jugar · Pádel» en las pistas (tag
--     OcioRacketCourt → RacketService.joinHere) y «Correr · Carrera» en la recta (tag OcioTrack →
--     RaceService.startPickup). El fútbol 7 ya lo pone FootballService solo (su campo «Pitch»).
-- Los carteles son los de World/SportPrompts (ordenador: [E] encima; móvil: el botón grande del
-- racimo pasa a «Jugar»); se apagan solos mientras juegas (SportInput.watchPrompts).

local CollectionService = game:GetService("CollectionService")

local SportPrompts = require(script.Parent.Parent.World.SportPrompts)
local OcioFun = require(script.Parent.OcioFun)

local ZonasDeporteService = {}

ZonasDeporteService.VolleyReward = { Fun = 10, WinFun = 5, WinMoney = 10, Xp = 8 }
ZonasDeporteService.StartFun = 6 -- tenis, pádel y carrera: diversión al empezar

local busyCourt: { [Instance]: Player } = {}

local function service(name: string): any
	local ok, svc = pcall(function()
		return require((script.Parent :: any)[name])
	end)
	return if ok and type(svc) == "table" then svc else nil
end

-- Centro de la pista de vóley a ras de arena (X a lo largo de la pista)
function ZonasDeporteService.courtFrame(area: BasePart): CFrame
	return area.CFrame * CFrame.new(0, -area.Size.Y / 2, 0)
end

function ZonasDeporteService.playVolley(player: Player, area: BasePart): boolean
	local owner = busyCourt[area]
	if owner and owner.Parent and owner:GetAttribute("InSport") == "Voley" then
		OcioFun.say(player, "Error", "🏐 En esta pista ya se está jugando. Prueba en la otra.")
		return false
	end
	local Volley = service("VolleyService")
	if not Volley or not Volley.startFree then
		return false
	end
	local started = Volley.startFree(player, ZonasDeporteService.courtFrame(area), function(result)
		busyCourt[area] = nil
		local r = ZonasDeporteService.VolleyReward
		local won = type(result) == "table" and result.Won == true
		OcioFun.reward(player, {
			Fun = r.Fun + (if won then r.WinFun else 0),
			Money = if won then r.WinMoney else 0,
			Xp = r.Xp,
			Reason = "Voley",
			Event = "OcioPlayed",
			Data = { Activity = "Voley", Won = won },
			Text = if won then "🏐 ¡Partido ganado!" else "🏐 Buen partido",
		})
	end)
	if started then
		busyCourt[area] = player
	end
	return started
end

local function standOn(player: Player, part: BasePart)
	local character = player.Character
	if character then
		character:PivotTo(part.CFrame * CFrame.new(0, part.Size.Y / 2 + 3, 0))
	end
end

function ZonasDeporteService.playRacket(player: Player, court: BasePart, kind: string): boolean
	local Racket = service("RacketService")
	if not Racket or not Racket.joinHere then
		return false
	end
	local ok = Racket.joinHere(player, kind)
	if not ok and not player:GetAttribute("InSport") then
		-- (el cartel se pulsa desde el borde: se pone en la pista y se vuelve a probar)
		standOn(player, court)
		ok = Racket.joinHere(player, kind)
	end
	if ok then
		OcioFun.reward(player, { Fun = ZonasDeporteService.StartFun, Reason = kind, Event = "OcioPlayed", Data = { Activity = kind } })
	end
	return ok
end

function ZonasDeporteService.playRace(player: Player, track: BasePart): boolean
	local Race = service("RaceService")
	if not Race or not Race.startPickup then
		return false
	end
	local ok = Race.startPickup(player, "Carrera")
	if ok then
		OcioFun.reward(player, { Fun = ZonasDeporteService.StartFun, Reason = "Carrera", Event = "OcioPlayed", Data = { Activity = "Carrera" } })
	end
	return ok == true
end

function ZonasDeporteService.place()
	local folder = SportPrompts.folder("OcioDeportePrompts")
	folder:ClearAllChildren()
	for _, area in CollectionService:GetTagged("OcioVolleyCourt") do
		if area:IsA("BasePart") then
			-- en el centro y a los dos fondos de la pista
			for i, x in { 0, -area.Size.X / 2 + 3, area.Size.X / 2 - 3 } do
				local anchor = SportPrompts.anchor(folder, ("Voley_%s_%d"):format(tostring(area:GetAttribute("Court")), i), (area.CFrame * CFrame.new(x, 2.5, 0)).Position)
				SportPrompts.attach(anchor, { Sport = "Voley", Action = "Jugar", Object = "Vóley", Distance = 12 }, function(player)
					ZonasDeporteService.playVolley(player, area)
				end)
			end
		end
	end
	for _, court in CollectionService:GetTagged("OcioRacketCourt") do
		if court:IsA("BasePart") then
			local kind = if court:GetAttribute("OcioRacket") == "Padel" then "Padel" else "Tenis"
			local label = if kind == "Padel" then "Pádel" else "Tenis"
			for i, x in { -10, 10 } do
				local anchor = SportPrompts.anchor(folder, ("%s_%d"):format(kind, i), (court.CFrame * CFrame.new(x, 3, 0)).Position)
				SportPrompts.attach(anchor, { Sport = kind, Action = "Jugar", Object = label, Distance = 14 }, function(player)
					ZonasDeporteService.playRacket(player, court, kind)
				end)
			end
		end
	end
	for _, track in CollectionService:GetTagged("OcioTrack") do
		if track:IsA("BasePart") then
			local anchor = SportPrompts.anchor(folder, "Carrera", (track.CFrame * CFrame.new(0, 3, 0)).Position)
			SportPrompts.attach(anchor, { Sport = "Carrera", Action = "Correr", Object = "Carrera", Distance = 12 }, function(player)
				ZonasDeporteService.playRace(player, track)
			end)
		end
	end
end

function ZonasDeporteService.init()
	ZonasDeporteService.place()
	-- (la ciudad la pone TownBuilder antes de los servicios; si llegara tarde, se vuelve a mirar)
	local found = #CollectionService:GetTagged("OcioVolleyCourt")
	task.delay(30, function()
		if found == 0 and #CollectionService:GetTagged("OcioVolleyCourt") > 0 then
			ZonasDeporteService.place()
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		for area, owner in busyCourt do
			if owner == player then
				busyCourt[area] = nil
			end
		end
	end)
end

return ZonasDeporteService
