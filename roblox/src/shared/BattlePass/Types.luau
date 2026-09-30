-- Tipos y nombres fijos del pase de temporada (solo datos: aquí no hay lógica).
-- Los usan el servidor (Services/BattlePass*), el cliente (la interfaz del pase) y las pruebas.

local Types = {}

-- Pistas de recompensas
Types.Track = {
	Free = "Free", -- gratis: para todos
	Premium = "Premium", -- premium: tras comprar el pase de la temporada
}

-- Estado de cada recompensa para la interfaz
Types.State = {
	Locked = "LOCKED", -- todavía no has llegado a ese nivel
	Available = "AVAILABLE", -- ya puedes reclamarla
	Claimed = "CLAIMED", -- ya es tuya
	PremiumLocked = "PREMIUM_LOCKED", -- es de la pista premium y no tienes el pase
}

-- Estado de la temporada
Types.SeasonStatus = {
	Upcoming = "Upcoming", -- aún no ha empezado («Próximamente»)
	Active = "Active", -- en marcha: se gana XP y se reclama
	Grace = "Grace", -- acabada: ya no se gana XP, pero aún se reclama lo alcanzado
	Ended = "Ended", -- acabada del todo
}

-- Tipos de recompensa (cada uno lo entrega su sistema de siempre: BattlePassRewardService)
Types.RewardType = {
	Money = "Money", -- dinero del juego (poco)
	CharacterXp = "CharacterXp", -- experiencia del personaje (ProgressionService)
	Tickets = "Tickets", -- tickets de los recreativos (ArcadeService)
	Tokens = "Tokens", -- fichas de temporada (solo para cosméticos)
	Vehicle = "Vehicle", -- un vehículo del juego (VehicleService)
	VehicleSkin = "VehicleSkin", -- acabado exclusivo de un vehículo del juego (mismas prestaciones)
	Boat = "Boat", -- barco propio (BoatService: se saca en el puerto deportivo; def.Boat = qué barco)
	Wearable = "Wearable", -- gafas o gorra de los recreativos (ArcadeService)
	Outfit = "Outfit", -- conjunto de ropa: colores del aspecto de Valmar (AvatarService)
	Emote = "Emote", -- gesto nuevo para el menú de gestos
	Title = "Title", -- título que se ve junto a tu nombre
	Nameplate = "Nameplate", -- placa (marco) de tu nombre
	HomeTheme = "HomeTheme", -- tema para tu vivienda de siempre (PropertyService)
	Decor = "Decor", -- objeto de decoración que aparece en tu vivienda
	PhoneTheme = "PhoneTheme", -- fondo y colores del teléfono / menús
	HudSkin = "HudSkin", -- colores de la interfaz (HUD)
	Perk = "Perk", -- ayuda de comodidad (con límites)
	Story = "Story", -- contenido narrativo (postal / recuerdo que se lee en el pase)
	Bundle = "Bundle", -- conjunto: varias recompensas de una vez
}

-- Tipos que se «equipan» (hueco del equipamiento en data.Cosmetics.Equipped)
Types.EquipSlot = {
	Title = "Title",
	Nameplate = "Nameplate",
	PhoneTheme = "PhoneTheme",
	HudSkin = "HudSkin",
	HomeTheme = "HomeTheme",
	Outfit = "Outfit",
	VehicleSkin = "VehicleSkin", -- (uno por tipo de vehículo)
}

-- Tipos de misión
Types.MissionKind = {
	Daily = "Daily",
	Weekly = "Weekly",
	Season = "Season",
	Story = "Story",
	Event = "Event",
}

-- Cómo se mide el progreso de una misión
Types.Measure = {
	Count = "Count", -- cada evento suma 1
	Km = "Km", -- suma los km del evento (VehicleTrip)
	Distinct = "Distinct", -- cuenta valores distintos de un campo del evento (DistinctField)
	DistinctEvent = "DistinctEvent", -- cuenta tipos de evento distintos (p. ej. medios de transporte)
}

-- Rarezas (en orden)
Types.Rarities = { "Comun", "Rara", "Epica", "Legendaria" }

export type Reward = {
	Id: string,
	Level: number,
	Track: string,
	Type: string,
	Name: string,
	Description: string,
	Icon: string,
	Rarity: string,
	Amount: number?,
	Kind: string?, -- (Vehicle / VehicleSkin: tipo de vehículo; Wearable: premio de los recreativos)
	Items: { any }?, -- (Bundle)
	[string]: any,
}

export type Mission = {
	Id: string,
	Title: string,
	Description: string,
	Icon: string,
	Events: { string },
	Goal: number,
	Measure: string?,
	Match: { [string]: any }?,
	DistinctField: string?,
	Xp: number,
	MinStage: string?,
	Place: string?,
	Tokens: number?,
}

return Types
