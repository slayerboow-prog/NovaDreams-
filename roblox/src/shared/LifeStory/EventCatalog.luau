-- EventCatalog: los avisos (StoryEvents) que de verdad manda algún sistema del servidor.
-- Un paso "Event" solo se puede cumplir si alguien emite ese evento; el validador de misiones
-- (Validate) rechaza los pasos que esperan un evento que no está aquí, y la prueba
-- test-playthrough busca en src/server que cada evento de esta lista se emite de verdad
-- (y que no se emite ninguno que falte aquí).

local EventCatalog = {}

EventCatalog.Names = {
	-- Historia y escenas
	Talk = true, TalkDone = true, PropUsed = true, EnemyDefeated = true, Caught = true,
	-- Prólogo (tutorial de controles): empezar a correr (ProgressionService) y abrir el mapa (LifeStoryService)
	Sprinted = true, MapOpened = true,
	-- Bebé y casa familiar (BabyService)
	BabyStood = true, BabySteps = true, BabyInteract = true, LookedOutside = true,
	-- Vida diaria
	Ate = true, Slept = true, HomeClaimed = true, Traveled = true, BusRide = true, RodeMetro = true, MetroGate = true, RodeTrain = true, TrainBoard = true, BoardedFlight = true, Flew = true,
	BoughtItem = true, SupermarketPurchase = true, SchoolMeal = true, WatchedMovie = true, ArcadePlayed = true,
	GymSet = true, CaughtFish = true, BuskPlayed = true, PrizeRedeemed = true, TaxFiled = true,
	SeasonChanged = true, WeatherChanged = true, TakenHome = true,
	-- Trabajo, negocios y progreso
	JobTaskDone = true, Promoted = true, LevelUp = true, BusinessBought = true, BusinessOpened = true,
	FarmMade = true, FarmHarvest = true, MetroMissionDone = true,
	-- Vehículos y carnés
	VehicleBought = true, VehicleMounted = true, LicenseEarned = true, LicenseFailed = true, GotLicence = true,
	-- Barcos (BoatService): sacar tu barco del amarre al agua ({ Boat = "Lancha" | … })
	BoatLaunched = true,
	-- Pase de temporada (ver PassOnly abajo): solo se emiten con BattlePass.Config.Enabled
	VehicleTrip = true, ZoneEntered = true, ErrandDone = true,
	-- Conducta, crimen y justicia
	Misbehaved = true, ConductNoted = true, Vandalism = true, Crime = true, HitSomeone = true, GotHit = true,
	-- Combate (FighterService): ganar a un rival del torneo ({ Level, Model })
	BeatRival = true,
	ShotFired = true, KnockedOut = true, Died = true, Revived = true, Arrested = true, EvadedPolice = true,
	Sentenced = true, Imprisoned = true, Released = true, PrisonWork = true, PrisonEscape = true, PrisonDegree = true,
}

-- Eventos que SOLO se emiten con el pase de temporada encendido (BattlePass.Config.Enabled); con el
-- pase apagado nadie los manda, así que ninguna misión de la historia puede esperarlos (Validate lo
-- rechaza). Los usan las misiones del pase (BattlePass/Season*.luau):
--   VehicleTrip  (VehicleService, al bajarte tras más de 50 studs; no en el examen de la autoescuela):
--                { Kind, Km, Rented }
--   ZoneEntered  (LifeStoryService.discoverZone, al entrar en otro barrio): { Zone, First }
--   ErrandDone   (CityErrandService, al terminar un encargo de un vecino): { Errand }
EventCatalog.PassOnly = {
	VehicleTrip = true, ZoneEntered = true, ErrandDone = true,
}

function EventCatalog.passOnly(name: any): boolean
	return type(name) == "string" and EventCatalog.PassOnly[name] == true
end

function EventCatalog.has(name: any): boolean
	return type(name) == "string" and EventCatalog.Names[name] == true
end

return EventCatalog
