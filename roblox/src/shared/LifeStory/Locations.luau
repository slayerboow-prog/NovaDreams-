-- Locations: los lugares de la ciudad que puede usar la historia ("ve al colegio", "vuelve a casa").
-- Cada lugar dice cómo encontrarlo en el mapa, sin tocar el código del mapa:
--   Model = "Colegio"        -> un Model con ese nombre dentro de workspace.Town
--   Tag = "JobBoard"         -> una pieza con esa etiqueta (CollectionService)
--   Attribute = { ... }      -> (con Tag) que además tenga esos atributos
--   Special = "Home"         -> la casa del jugador (su parcela)
--   Special = "NearPlayer"   -> delante del jugador (personajes que vienen a buscarte)
--   Between = { "A", "B" }, At = 0.5  -> un punto del camino entre dos lugares, en la acera
--   Child = "Court"          -> (con Model) una pieza con ese nombre dentro del edificio elegido
--   Index = 3                -> el tercero del mismo edificio (pupitres); también por actor
--   Offset = Vector3         -> desplazado (en los ejes del lugar) desde el lugar encontrado
--   Radius = 8               -> a qué distancia ya "has llegado"
--   Fallback = "OtroLugar"   -> si este no existe en el mapa, se usa ese
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
	Between: { string }?,
	At: number?,
	Child: string?,
	Index: number?,
	Offset: Vector3?,
	Radius: number?,
	Fallback: string?,
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

	-- Dentro del colegio (Civic.school del mapa, ver docs/mapa/ETIQUETAS.md)
	EntradaColegio = { NameKey = "PLACE.ENTRADA_COLEGIO", Tag = "SchoolEntrance", Zone = "Home" },
	Aula = { NameKey = "PLACE.AULA", Tag = "Classroom", Zone = "Home", Inside = true },
	AulaMusica = { NameKey = "PLACE.AULA_MUSICA", Tag = "MusicRoom", Zone = "Home", Inside = true },
	Patio = { NameKey = "PLACE.PATIO", Tag = "RecessArea", Zone = "Home", Inside = true },
	Pista = { NameKey = "PLACE.PISTA", Tag = "PEArea", Zone = "Home" },
	-- Rincones del colegio para las misiones (ver docs/historia/11). "Colegio" = el más cercano a casa.
	Vestibulo = { NameKey = "Vestíbulo", Tag = "SchoolEntrance", Zone = "Home", Offset = Vector3.new(0, 0, 9), Radius = 7 },
	Conserjeria = { NameKey = "Conserjería", Tag = "SchoolEntrance", Zone = "Home", Offset = Vector3.new(7, 0, 5), Radius = 6 },
	AulaA = { NameKey = "Aula de 1.º A", Tag = "Classroom", Attribute = { ClassroomId = "A" }, Zone = "Home", Inside = true, Fallback = "Aula" },
	PupitreA = { NameKey = "Tu pupitre", Tag = "Desk", Attribute = { ClassroomId = "A" }, Zone = "Home", Radius = 4, Fallback = "AulaA" },
	PizarraA = { NameKey = "Pizarra", Tag = "TeacherSpot", Attribute = { ClassroomId = "A" }, Zone = "Home", Radius = 5, Fallback = "AulaA" },
	CanchaColegio = { NameKey = "Cancha de baloncesto", Model = "Colegio", Child = "Court", Zone = "Home", Fallback = "Patio" },
	CampoColegio = { NameKey = "Campo de fútbol", Model = "Colegio", Child = "Pitch", Zone = "Home", Fallback = "Pista" },
	GimnasioColegio = { NameKey = "Gimnasio", Model = "Colegio", Child = "Gimnasio", Zone = "Home", Fallback = "CampoColegio" },
	AlmacenColegio = { NameKey = "Almacén del gimnasio", Model = "Colegio", Child = "Gimnasio", Zone = "Home", Offset = Vector3.new(16, 0, 8), Radius = 7, Fallback = "GimnasioColegio" },
	JuegosColegio = { NameKey = "Zona de juegos", Model = "Colegio", Child = "Playground", Zone = "Home", Fallback = "Patio" },
	CaminoAlCole = { NameKey = "Camino al cole", Between = { "CasaFamiliar", "EntradaColegio" }, At = 0.5, Radius = 16, Fallback = "EntradaColegio" },
	CercaDeTi = { NameKey = "Aquí", Special = "NearPlayer" },

	-- Instituto (el colegio grande de Campus Valmar)
	Instituto = { NameKey = "PLACE.INSTITUTO", Model = "Colegio", Zone = "Campus Valmar" },
	AulaInstituto = { NameKey = "PLACE.AULA_INSTITUTO", Tag = "Classroom", Zone = "Campus Valmar", Inside = true },
	PatioInstituto = { NameKey = "PLACE.PATIO", Tag = "RecessArea", Zone = "Campus Valmar", Inside = true },
	PistaInstituto = { NameKey = "PLACE.PISTA", Tag = "PEArea", Zone = "Campus Valmar" },

	-- Universidad
	FacultadMedicina = { NameKey = "PLACE.FACULTAD_MEDICINA", Model = "Facultad", Attribute = { Faculty = "Medicina" }, Zone = "Campus Valmar" },
	FacultadIngenieria = { NameKey = "PLACE.FACULTAD_INGENIERIA", Model = "Facultad", Attribute = { Faculty = "Ingenieria" }, Zone = "Campus Valmar" },
	FacultadDerecho = { NameKey = "PLACE.FACULTAD_DERECHO", Model = "Facultad", Attribute = { Faculty = "Derecho" }, Zone = "Campus Valmar" },
	FacultadEconomia = { NameKey = "PLACE.FACULTAD_ECONOMIA", Model = "Facultad", Attribute = { Faculty = "Economia" }, Zone = "Campus Valmar" },
	Biblioteca = { NameKey = "PLACE.BIBLIOTECA", Tag = "Library", Zone = "Campus Valmar" },
	OficinasFinanciero = { NameKey = "PLACE.OFICINAS", Model = "Torres", Zone = "Distrito Financiero" },

	-- Tiendas (tag Shop + ShopId)
	Libreria = { NameKey = "PLACE.LIBRERIA", Tag = "Shop", Attribute = { ShopId = "Libreria" }, Zone = "Home" },
	Farmacia = { NameKey = "PLACE.FARMACIA", Tag = "Shop", Attribute = { ShopId = "Farmacia" }, Zone = "Home" },
	Heladeria = { NameKey = "PLACE.HELADERIA", Tag = "Shop", Attribute = { ShopId = "Heladeria" }, Zone = "Home" },
	Banco = { NameKey = "PLACE.BANCO", Tag = "Shop", Attribute = { ShopId = "Banco" } },
	Parque = { NameKey = "PLACE.PARQUE", Model = "Parque", Zone = "Home" },
	EstanqueParque = { NameKey = "Estanque del parque", Model = "Parque", Child = "PondRim", Zone = "Home", Fallback = "Parque" },
	JuegosParque = { NameKey = "Columpios del parque", Model = "Parque", Child = "Playground", Zone = "Home", Fallback = "Parque" },
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
