-- Locations: los lugares de la ciudad que puede usar la historia ("ve al colegio", "vuelve a casa").
-- Cada lugar dice cómo encontrarlo en el mapa, sin tocar el código del mapa:
--   Model = "Colegio"        -> un Model con ese nombre dentro de workspace.Town
--   Tag = "JobBoard"         -> una pieza con esa etiqueta (CollectionService)
--   Attribute = { ... }      -> (con Tag) que además tenga esos atributos
--   Special = "Home"         -> la casa del jugador (su parcela)
-- Y cuál elegir si hay varios (Zone):
--   "Nearest" (por defecto)  -> el más cercano al jugador
--   "Home"                   -> el más cercano a su casa (su colegio, su parque, su centro de salud)
--   "San Roque"              -> el de esa zona
--   "FamilyHome"             -> el de la casa familiar donde vive el jugador (atributo HomeId)
-- Inside = true: hay que estar DENTRO del volumen (habitaciones), no solo cerca.

local Locations = {}

export type Place = {
	NameKey: string,
	Model: string?,
	Tag: string?,
	Attribute: { [string]: any }?,
	Special: string?,
	Zone: string?,
	Inside: boolean?,
}

Locations.Places = {
	Home = { NameKey = "PLACE.HOME", Special = "Home" },

	-- Casa familiar donde nace el bebé (Kit/Home del mapa, ver docs/mapa/ETIQUETAS.md)
	HomeSalon = { NameKey = "PLACE.HOME_SALON", Tag = "Room", Attribute = { Room = "Salon" }, Zone = "FamilyHome", Inside = true },
	HomeCocina = { NameKey = "PLACE.HOME_COCINA", Tag = "Room", Attribute = { Room = "Cocina" }, Zone = "FamilyHome", Inside = true },
	HomeDormitorio = { NameKey = "PLACE.HOME_DORMITORIO", Tag = "Room", Attribute = { Room = "Dormitorio" }, Zone = "FamilyHome", Inside = true },
	FamiliaAbu = { NameKey = "PLACE.FAMILIA_ABU", Tag = "FamilySpot", Attribute = { Npc = "Familia_Abu" }, Zone = "FamilyHome" },
	FamiliaPadre = { NameKey = "PLACE.FAMILIA_PADRE", Tag = "FamilySpot", Attribute = { Npc = "Familia_Padre" }, Zone = "FamilyHome" },
	Ventanal = { NameKey = "PLACE.VENTANAL", Tag = "LookOutside", Zone = "FamilyHome" },
	CasaFamiliar = { NameKey = "PLACE.CASA_FAMILIAR", Tag = "FamilyHome", Zone = "FamilyHome" },
	Cuna = { NameKey = "PLACE.CUNA", Tag = "BabySpawn", Zone = "FamilyHome" },

	PlazaCentro = { NameKey = "PLACE.PLAZA_CENTRO", Model = "Plaza", Zone = "Valmar Centro" },
	CafeteriaCentral = { NameKey = "PLACE.CAFETERIA_CENTRAL", Tag = "JobBoard", Attribute = { JobId = "Barista" } },
	Correos = { NameKey = "PLACE.CORREOS", Tag = "JobBoard", Attribute = { JobId = "Repartidor" } },
	Supermercado = { NameKey = "PLACE.SUPERMERCADO", Tag = "JobBoard", Attribute = { JobId = "Reponedor" } },
	PuntoLimpio = { NameKey = "PLACE.PUNTO_LIMPIO", Model = "PuntoLimpio" },
	ParadaBus = { NameKey = "PLACE.PARADA_BUS", Tag = "TravelStop" },
	Colegio = { NameKey = "PLACE.COLEGIO", Model = "Colegio", Zone = "Home" },
	Parque = { NameKey = "PLACE.PARQUE", Model = "Parque", Zone = "Home" },
	Columpios = { NameKey = "PLACE.COLUMPIOS", Model = "Playground", Zone = "Home" },
	CentroSalud = { NameKey = "PLACE.CENTRO_SALUD", Model = "CentroSalud", Zone = "Home" },
	Hospital = { NameKey = "PLACE.HOSPITAL", Model = "Hospital" },
	Bomberos = { NameKey = "PLACE.BOMBEROS", Model = "Bomberos" },
	Policia = { NameKey = "PLACE.POLICIA", Model = "Policia" },
	CentroComercial = { NameKey = "PLACE.CENTRO_COMERCIAL", Model = "CentroComercial" },
	Gasolinera = { NameKey = "PLACE.GASOLINERA", Model = "Gasolinera" },
	Ocio = { NameKey = "PLACE.OCIO", Model = "Ocio" },
	Universidad = { NameKey = "PLACE.UNIVERSIDAD", Model = "Facultad", Zone = "Campus Valmar" },
	EstadioUniversitario = { NameKey = "PLACE.ESTADIO_UNI", Model = "Estadio", Zone = "Campus Valmar" },
	EstadioAltamar = { NameKey = "PLACE.ESTADIO_ALTAMAR", Model = "Estadio", Zone = "Distrito Financiero" },
	PlazaFinanciera = { NameKey = "PLACE.PLAZA_FINANCIERA", Model = "PlazaFinanciera", Zone = "Distrito Financiero" },
	Playa = { NameKey = "PLACE.PLAYA", Model = "Playa", Zone = "Playa Dorada" },
	Granja = { NameKey = "PLACE.GRANJA", Model = "Granja", Zone = "Villaverde" },
} :: { [string]: Place }

-- Las 8 zonas de la región (los nombres son los del mapa)
Locations.Zones = {
	"Valmar Centro",
	"Valmar Norte",
	"San Roque",
	"Playa Dorada",
	"Los Pinos",
	"Villaverde",
	"Campus Valmar",
	"Distrito Financiero",
}

return Locations
