-- Layout: el plano de la casa de Cosme en datos puros, sin Instances. Sigue el PLANO del dueño
-- (docs/referencias/plano-casa-cosme.png: 48 × 40 studs) a escala ×2 para que quepan los avatares
-- (96 × 80), con el aspecto del render (docs/referencias/casa-cosme.png; encargo: docs/historia/casa-cosme.md).
-- Lo usan los constructores (Exterior, Interior, Laboratory…), la rutina de Cosme (NPC) y la prueba
-- scripts/test-cosmehouse.luau.
--
-- Coordenadas LOCALES de la parcela (studs): origen en el centro de la manzana a ras de suelo (y = 0),
-- la fachada mira a -Z (a la calle). La parcela va de -50 a 50 en X y en Z.
-- OJO: desde la calle, mirando la casa, +X queda a la IZQUIERDA y -X a la DERECHA. Así el plano
-- (garaje a la derecha, salón y paneles solares a la izquierda) se ve igual que en el dibujo.
--
--   Alturas (cara de arriba de cada suelo; 12 de techo en cada planta):
--     Sótano  FB = -14   (techo a -2: la losa del jardín, de -2 a 0)
--     Baja    F0 = 1     (techo a 13)
--     Alta    F1 = 14    (techo a 26)
--     Tejado  F2 = 27    (azotea con la cúpula de observación encima)
--
--   PLANTA BAJA (vista desde arriba, la calle abajo; izquierda del dibujo = +X):
--          x=40           16    4          -22          -44
--     z=24 ┌──────────────┬─────┬───────────┐ terraza lateral (jardín)
--          │   COCINA     │ASEO │LABORATORIO│
--          │  (y comedor  │     │ (máquina  ├───────────┐ z=12
--      8.5 │   de diario) ├─────┤ redonda)  │           │
--          │              │ESC. ├───────────┤  GARAJE   │
--      -12 ├──────────────┤(5)  │  COMEDOR  │  (coche   │
--          │    SALÓN     └─────┤           │ y portal) │
--      -20 │                    ├───┬───────┤           │
--          │                VEST│IBULO DESP.│           │
--     z=-32└────────────────────┴puerta─────┴──abierto──┘
--
--   PLANTA ALTA: habitación de Cosme (izq.), zona de experimentos (der.), núcleo de la escalera en
--   el centro, la sala de observación de cristal en un mirador semicircular DETRÁS, la terraza
--   principal delante (encima del salón) y la terraza lateral encima del garaje.
--   SÓTANO: portal (izq. delante), taller (izq. detrás), almacén (centro detrás), garaje (der.) y la
--   escalera en medio; detrás del taller, la habitación secreta (no sale en el plano: es secreta).
--   TECHO: paneles solares (izq.), la cúpula de observación (torre redonda de dos tambores de cristal
--   con el «platillo» encima), la torre de experimentos con el vórtice y la antena (atrás a la der.)
--   y la terraza chill (delante a la der.).

local Layout = {}

Layout.FB = -14
Layout.F0 = 1
Layout.F1 = 14
Layout.F2 = 27
Layout.CEIL = { B = -2, G = 13, U = 26, A = 38 }
Layout.LevelY = { B = -14, G = 1, U = 14, A = 27 }

Layout.Lot = { X0 = -50, X1 = 50, Z0 = -50, Z1 = 50 }
-- La casa (sin el garaje) y el garaje (a la derecha, a todo el fondo de la planta baja delantera)
Layout.House = { X0 = -22, X1 = 40, Z0 = -32, Z1 = 24 }
Layout.Upper = { X0 = -22, X1 = 40, Z0 = -20, Z1 = 24 } -- planta alta (la terraza principal va delante)
Layout.Garage = { X0 = -44, X1 = -22, Z0 = -32, Z1 = 12 }
Layout.Basement = { X0 = -44, X1 = 44, Z0 = -32, Z1 = 46 }
-- Mirador semicircular de cristal (sala de observación, planta alta) detrás de la casa
Layout.Bay = { X = 4, Z = 24, R = 12 }
-- Cúpula de observación del tejado: dos tambores de cristal y el «platillo»
Layout.Dome = { X = 8, Z = -1, R = 13, Top = 38, DiscR = 17, UpperR = 7.5, UpperTop = 45 }
-- Torre de experimentos (con el vórtice encima) y antena satélite, en el tejado atrás a la derecha
Layout.PortalTower = { X = -14, Z = 17, R = 4.5 }
Layout.Antenna = { X = -5, Z = 19 }
Layout.Deck = { X0 = -22, X1 = 40, Z0 = 24, Z1 = 31 }
Layout.Solar = { X0 = 22, X1 = 39, Z0 = -18, Z1 = 22 }

-- Escaleras de ida y vuelta (dos tramos de 6 de ancho, rellano en cada vuelta).
--   X0..X1: 12 de ancho (carril A = la mitad de +X, carril B = la de -X). Z0: lado del rellano cercano.
--   Near: fondo del rellano cercano; Run: largo de cada tramo; Far: fondo del rellano del otro lado.
--   Y0: altura de salida; Rise: lo que sube (o baja, negativo) cada tramo; Flights: número de tramos.
--   Swap: empieza por el carril B. Las dos escaleras van en el MISMO núcleo (en el centro, como en el
--   plano): la que sube empieza por el carril A y la que baja al sótano por el B, una debajo de otra.
Layout.Stairs = {
	Hall = { X0 = 4, X1 = 16, Z0 = -12, Near = 4, Run = 12.5, Far = 4, Y0 = 1, Rise = 6.5, Flights = 4 },
	Sotano = { X0 = 4, X1 = 16, Z0 = -12, Near = 4, Run = 12.5, Far = 4, Y0 = 1, Rise = -7.5, Flights = 2, Swap = true },
}
-- Núcleo de la escalera (de arriba abajo)
Layout.Core = { X0 = 4, X1 = 16, Z0 = -12, Z1 = 8.5 }

-- Peldaños de un tramo (para construirlos y para la prueba): { { x0, x1, z0, z1, top } }
function Layout.flight(stair: { [string]: any }, k: number): { { number } }
	local laneA = (k % 2 == 1) ~= (stair.Swap == true)
	local forward = k % 2 == 1 -- los impares van de cerca a lejos
	local x0 = if laneA then stair.X0 + 6 else stair.X0
	local zNear, zFar = stair.Z0 + stair.Near, stair.Z0 + stair.Near + stair.Run
	local yStart = stair.Y0 + (k - 1) * stair.Rise
	local n = math.ceil(math.abs(stair.Rise) / 0.8)
	local h = stair.Rise / n
	local d = stair.Run / n
	local steps = {}
	for i = 1, n do
		local za = if forward then zNear + (i - 1) * d else zFar - i * d
		local zb = za + d
		table.insert(steps, { x0, x0 + 6, za, zb, yStart + i * h })
	end
	return steps
end

-- Altura de cada rellano: { near = { y, ... }, far = { y, ... } } (k = tramo que termina en él)
function Layout.landings(stair: { [string]: any }): { { any } }
	local list = {}
	for k = 1, stair.Flights do
		local y = stair.Y0 + k * stair.Rise
		local near = k % 2 == 0
		local z0 = if near then stair.Z0 else stair.Z0 + stair.Near + stair.Run
		local z1 = if near then stair.Z0 + stair.Near else z0 + stair.Far
		table.insert(list, { X0 = stair.X0, X1 = stair.X1, Z0 = z0, Z1 = z1, Y = y, Near = near, K = k })
	end
	return list
end

---------------------------------------------------------------------
-- Habitaciones (Level: B sótano, G baja, U alta, A tejado, O fuera). Rect en local. MinProps: lo
-- mínimo de piezas que tiene que tener dentro (la prueba comprueba que ninguna está vacía). Plan: el
-- número de la habitación en el plano del dueño.
---------------------------------------------------------------------
export type Room = { Id: string, Name: string, Level: string, X0: number, X1: number, Z0: number, Z1: number, MinProps: number, Light: boolean?, Plan: number? }

Layout.Rooms = {
	-- Exterior
	{ Id = "Jardin", Name = "Jardín delantero", Level = "O", X0 = -50, X1 = 50, Z0 = -50, Z1 = -33, MinProps = 40 },
	{ Id = "JardinTrasero", Name = "Jardín trasero", Level = "O", X0 = -50, X1 = 50, Z0 = 31.5, Z1 = 50, MinProps = 50 },
	{ Id = "Terraza", Name = "Terraza trasera", Level = "O", X0 = -22, X1 = 40, Z0 = 24.5, Z1 = 31, MinProps = 15 },
	{ Id = "JardinLateral", Name = "Terraza y jardín lateral", Level = "O", X0 = -50, X1 = -22.5, Z0 = 12.5, Z1 = 31, MinProps = 15 },
	-- Planta baja
	{ Id = "Vestibulo", Name = "Vestíbulo / Entrada", Level = "G", X0 = -10, X1 = 4, Z0 = -32, Z1 = -20, MinProps = 20, Light = true, Plan = 1 },
	{ Id = "Salon", Name = "Salón / Estar", Level = "G", X0 = 4, X1 = 40, Z0 = -32, Z1 = -12, MinProps = 50, Light = true, Plan = 2 },
	{ Id = "Despacho", Name = "Despacho", Level = "G", X0 = -22, X1 = -10, Z0 = -32, Z1 = -20, MinProps = 30, Light = true },
	{ Id = "Comedor", Name = "Comedor", Level = "G", X0 = -22, X1 = 4, Z0 = -20, Z1 = 4, MinProps = 25, Light = true, Plan = 3 },
	{ Id = "Escalera", Name = "Escalera / Acceso planta alta", Level = "G", X0 = 4, X1 = 16, Z0 = -12, Z1 = 8.5, MinProps = 20, Plan = 5 },
	{ Id = "Cocina", Name = "Cocina", Level = "G", X0 = 16, X1 = 40, Z0 = -12, Z1 = 24, MinProps = 40, Light = true, Plan = 3 },
	{ Id = "Aseo", Name = "Aseo", Level = "G", X0 = 4, X1 = 16, Z0 = 8.5, Z1 = 24, MinProps = 10, Light = true },
	{ Id = "Laboratorio", Name = "Laboratorio de inventos", Level = "G", X0 = -22, X1 = 4, Z0 = 4, Z1 = 24, MinProps = 60, Light = true, Plan = 4 },
	{ Id = "GarajeCosme", Name = "Garaje (vehículo experimental)", Level = "G", X0 = -44, X1 = -22, Z0 = -32, Z1 = 12, MinProps = 80, Light = true, Plan = 6 },
	-- Planta alta
	{ Id = "Pasillo", Name = "Pasillo", Level = "U", X0 = 4, X1 = 16, Z0 = -20, Z1 = -12, MinProps = 8, Light = true },
	{ Id = "Dormitorio", Name = "Habitación de Cosme", Level = "U", X0 = 16, X1 = 40, Z0 = -20, Z1 = 6, MinProps = 40, Light = true, Plan = 7 },
	{ Id = "Biblioteca", Name = "Biblioteca científica", Level = "U", X0 = 16, X1 = 28, Z0 = 6, Z1 = 24, MinProps = 40, Light = true },
	{ Id = "BanoArriba", Name = "Baño", Level = "U", X0 = 28, X1 = 40, Z0 = 6, Z1 = 24, MinProps = 10, Light = true },
	{ Id = "Experimentos", Name = "Zona de trabajo / Experimentos", Level = "U", X0 = -22, X1 = 4, Z0 = -20, Z1 = 8.5, MinProps = 60, Light = true, Plan = 8 },
	{ Id = "Ordenadores", Name = "Sala de ordenadores", Level = "U", X0 = -22, X1 = -8, Z0 = 8.5, Z1 = 24, MinProps = 50, Light = true },
	{ Id = "Observacion", Name = "Habitación de observación (cristal)", Level = "U", X0 = -8, X1 = 16, Z0 = 8.5, Z1 = 36, MinProps = 15, Light = true, Plan = 9 },
	{ Id = "TerrazaPrincipal", Name = "Terraza principal", Level = "U", X0 = -22, X1 = 40, Z0 = -31.5, Z1 = -20.5, MinProps = 15, Plan = 10 },
	{ Id = "TerrazaLateral", Name = "Terraza lateral", Level = "U", X0 = -44, X1 = -22.5, Z0 = -32, Z1 = 12, MinProps = 15, Plan = 11 },
	-- Tejado
	{ Id = "Observatorio", Name = "Cúpula de observación", Level = "A", X0 = -5, X1 = 21, Z0 = -14, Z1 = 12, MinProps = 40, Light = true, Plan = 19 },
	{ Id = "Azotea", Name = "Terraza / zona chill", Level = "A", X0 = -22, X1 = -5.5, Z0 = -20, Z1 = 10, MinProps = 25, Plan = 20 },
	{ Id = "PanelesSolares", Name = "Paneles solares", Level = "A", X0 = 21.5, X1 = 40, Z0 = -20, Z1 = 24, MinProps = 20, Plan = 16 },
	{ Id = "TorreExperimentos", Name = "Torre de experimentos y antena", Level = "A", X0 = -22, X1 = 0, Z0 = 12.5, Z1 = 24, MinProps = 15, Plan = 17 },
	-- Sótano
	{ Id = "PasilloSotano", Name = "Pasillo del sótano", Level = "B", X0 = -8, X1 = 16, Z0 = -32, Z1 = 8.5, MinProps = 15, Light = true },
	{ Id = "Portales", Name = "Portal / Máquina de portales", Level = "B", X0 = 16, X1 = 44, Z0 = -32, Z1 = 8, MinProps = 60, Light = true, Plan = 13 },
	{ Id = "Taller", Name = "Taller / Zona de trabajo", Level = "B", X0 = 16, X1 = 44, Z0 = 8, Z1 = 32, MinProps = 50, Light = true, Plan = 14 },
	{ Id = "Almacen", Name = "Almacén / Depósito", Level = "B", X0 = -8, X1 = 16, Z0 = 8.5, Z1 = 32, MinProps = 40, Light = true, Plan = 15 },
	{ Id = "GarajeSotano", Name = "Garaje del sótano (vehículo experimental)", Level = "B", X0 = -44, X1 = -8, Z0 = -32, Z1 = 32, MinProps = 50, Light = true, Plan = 12 },
	{ Id = "Secreta", Name = "Habitación secreta", Level = "B", X0 = 16, X1 = 40, Z0 = 32, Z1 = 46, MinProps = 40, Light = true },
} :: { Room }

function Layout.room(id: string): Room?
	for _, r in Layout.Rooms do
		if r.Id == id then
			return r
		end
	end
	return nil
end

-- Altura del suelo y del techo de cada nivel (para contar lo que hay en cada habitación)
function Layout.levelRange(level: string): (number, number)
	if level == "B" then
		return Layout.FB - 0.5, Layout.CEIL.B
	elseif level == "G" then
		return Layout.F0 - 0.5, Layout.CEIL.G
	elseif level == "U" then
		return Layout.F1 - 0.5, Layout.CEIL.U
	elseif level == "A" then
		return Layout.F2 - 0.5, Layout.CEIL.A + 12
	end
	return -0.5, 13
end

---------------------------------------------------------------------
-- Puntos de paso (pies) por donde anda Cosme y aristas entre ellos. Cada arista es un tramo recto
-- que se puede andar (la prueba comprueba que no atraviesa paredes ni muebles).
---------------------------------------------------------------------
local P: { [string]: { number } } = {
	-- Calle, jardín y porche
	Calle = { -3, 0, -47 },
	Porche = { -3, 0.5, -35.5 },
	Entrada = { -3, 1, -29 },
	Acera = { -33, 0, -40 },
	-- Planta baja
	Vestibulo = { -3, 1, -24 },
	PuertaDespacho = { -10, 1, -27 },
	Despacho = { -16, 1, -27 },
	SalonPaso = { 4, 1, -27 },
	Salon = { 14, 1, -23 },
	SalonFondo = { 18, 1, -15 },
	SalonSofa = { 30, 1, -15.5 },
	ComedorPaso = { -3, 1, -17 },
	Comedor = { -9, 1, -8 },
	PieEscalera = { 0, 1, -10 },
	RellanoBaja = { 10, 1, -10 },
	CocinaPaso = { 28, 1, -9 },
	Cocina = { 28, 1, 4 },
	CocinaFondo = { 28, 1, 17 },
	PuertaAseo = { 16, 1, 17 },
	Aseo = { 10, 1, 17 },
	PuertaTerraza = { 28, 1, 24 },
	Terraza = { 28, 1, 27.5 },
	TerrazaLab = { -4, 1, 27.5 },
	JardinTrasero = { 20, 0, 40 },
	JardinLateral = { -34, 0, 24 },
	PuertaLab = { -9, 1, 4 },
	Laboratorio = { -4, 1, 10 },
	LabMaquina = { -4, 1, 17 },
	PuertaLabFondo = { -4, 1, 24 },
	PuertaGaraje = { -22, 1, -10 },
	GarajeCoche = { -27, 1, -8 },
	Garaje = { -30, 1, -24 },
	-- Escalera principal (núcleo del centro): sube por el carril A
	EscaleraA1 = { 13, 1, -8.5 },
	EscaleraA1Arriba = { 13, 7.5, 4.5 },
	RellanoA = { 10, 7.5, 6.5 },
	EscaleraB1 = { 7, 7.5, 4.5 },
	EscaleraB1Arriba = { 7, 14, -8 },
	RellanoB = { 10, 14, -10 },
	EscaleraA2 = { 13, 14, -8.5 },
	EscaleraA2Arriba = { 13, 20.5, 4.5 },
	RellanoC = { 10, 20.5, 6.5 },
	EscaleraB2 = { 7, 20.5, 4.5 },
	EscaleraB2Arriba = { 7, 27, -8 },
	RellanoD = { 10, 27, -10 },
	-- …y baja al sótano por el carril B, debajo
	SotanoB1 = { 7, 1, -8.5 },
	SotanoB1Abajo = { 7, -6.5, 4.5 },
	SotanoL1 = { 10, -6.5, 6.5 },
	SotanoA1 = { 13, -6.5, 4.5 },
	SotanoA1Abajo = { 13, -14, -8 },
	SotanoL2 = { 10, -14, -10 },
	-- Planta alta
	PasilloAlto = { 10, 14, -16 },
	PuertaDormitorio = { 16, 14, -16 },
	Dormitorio = { 24, 14, -11 },
	DormitorioCama = { 28, 14, -3 },
	PuertaBiblioteca = { 22, 14, 6 },
	Biblioteca = { 22, 14, 14 },
	PuertaBano = { 34, 14, 6 },
	BanoArriba = { 34, 14, 12 },
	PuertaExperimentos = { 4, 14, -16 },
	Experimentos = { -9, 14, -9 },
	ExperimentosFondo = { -2, 14, 3 },
	PuertaObservacion = { -2, 14, 8.5 },
	Observacion = { 4, 14, 15 },
	ObservacionBahia = { 4, 14, 29 },
	PuertaOrdenadores = { -15, 14, 8.5 },
	Ordenadores = { -15, 14, 15 },
	PuertaTerrazaAlta = { 10, 14, -20 },
	TerrazaFrente = { 10, 14, -27 },
	TerrazaIzquierda = { 30, 14, -27.5 },
	TerrazaDerecha = { -30, 14, -27 },
	TerrazaLateral = { -30, 14, -12 },
	-- Tejado
	Cupula = { -1, 27, -10 },
	Observatorio = { -1, 27, 1 },
	CupulaPuerta = { -5, 27, -1 },
	Azotea = { -12, 27, -4 },
	AzoteaMesa = { -12, 27, -12 },
	AzoteaDelante = { -2, 27, -17.5 },
	PanelesSolares = { 30, 27, -17.5 },
	AzoteaTorre = { -12, 27, 9 },
	-- Sótano
	PasilloSotano = { 4, -14, -20 },
	PuertaPortales = { 16, -14, -22 },
	Portales = { 26, -14, -22 },
	PortalDelante = { 30, -14, -14 },
	PortalLado = { 41.5, -14, -12 },
	PuertaTallerPortales = { 40, -14, 8 },
	PuertaGarajeSotano = { -8, -14, -22 },
	GarajeSotano = { -20, -14, -22 },
	GarajeSotanoCoche = { -20, -14, 2 },
	PasilloFondo = { -2, -14, 2 },
	PuertaAlmacen = { -2, -14, 8.5 },
	Almacen = { -2, -14, 18 },
	PuertaTaller = { 16, -14, 20 },
	Taller = { 26, -14, 20 },
	Estanteria = { 30, -14, 29.5 },
	SecretaEntrada = { 30, -14, 33 },
	Secreta = { 30, -14, 38.5 },
	SecretaPortal = { 30, -14, 41.5 },
}
Layout.Points = P

local E = {
	-- Calle, porche y planta baja
	{ "Calle", "Porche" }, { "Porche", "Entrada" }, { "Entrada", "Vestibulo" }, { "Calle", "Acera" }, { "Acera", "Garaje" },
	{ "Vestibulo", "PuertaDespacho" }, { "PuertaDespacho", "Despacho" },
	{ "Vestibulo", "SalonPaso" }, { "SalonPaso", "Salon" }, { "Salon", "SalonFondo" }, { "SalonFondo", "SalonSofa" },
	{ "Vestibulo", "ComedorPaso" }, { "ComedorPaso", "Comedor" }, { "Comedor", "PieEscalera" }, { "PieEscalera", "RellanoBaja" },
	{ "SalonFondo", "RellanoBaja" }, { "RellanoBaja", "CocinaPaso" }, { "SalonFondo", "CocinaPaso" },
	{ "CocinaPaso", "Cocina" }, { "Cocina", "CocinaFondo" }, { "CocinaFondo", "PuertaAseo" }, { "PuertaAseo", "Aseo" },
	{ "CocinaFondo", "PuertaTerraza" }, { "PuertaTerraza", "Terraza" }, { "Terraza", "JardinTrasero" }, { "Terraza", "TerrazaLab" },
	{ "TerrazaLab", "JardinLateral" }, { "TerrazaLab", "PuertaLabFondo" }, { "PuertaLabFondo", "LabMaquina" },
	{ "Comedor", "PuertaLab" }, { "PuertaLab", "Laboratorio" }, { "Laboratorio", "LabMaquina" },
	{ "Comedor", "PuertaGaraje" }, { "PuertaGaraje", "GarajeCoche" }, { "GarajeCoche", "Garaje" },
	-- Escalera principal
	{ "RellanoBaja", "EscaleraA1" }, { "EscaleraA1", "EscaleraA1Arriba" }, { "EscaleraA1Arriba", "RellanoA" }, { "RellanoA", "EscaleraB1" },
	{ "EscaleraB1", "EscaleraB1Arriba" }, { "EscaleraB1Arriba", "RellanoB" }, { "RellanoB", "EscaleraA2" },
	{ "EscaleraA2", "EscaleraA2Arriba" }, { "EscaleraA2Arriba", "RellanoC" }, { "RellanoC", "EscaleraB2" },
	{ "EscaleraB2", "EscaleraB2Arriba" }, { "EscaleraB2Arriba", "RellanoD" },
	-- Bajada al sótano
	{ "RellanoBaja", "SotanoB1" }, { "SotanoB1", "SotanoB1Abajo" }, { "SotanoB1Abajo", "SotanoL1" }, { "SotanoL1", "SotanoA1" },
	{ "SotanoA1", "SotanoA1Abajo" }, { "SotanoA1Abajo", "SotanoL2" },
	-- Planta alta
	{ "RellanoB", "PasilloAlto" }, { "PasilloAlto", "PuertaDormitorio" }, { "PuertaDormitorio", "Dormitorio" }, { "Dormitorio", "DormitorioCama" },
	{ "Dormitorio", "PuertaBiblioteca" }, { "PuertaBiblioteca", "Biblioteca" }, { "DormitorioCama", "PuertaBano" }, { "PuertaBano", "BanoArriba" },
	{ "PasilloAlto", "PuertaExperimentos" }, { "PuertaExperimentos", "Experimentos" }, { "Experimentos", "ExperimentosFondo" },
	{ "ExperimentosFondo", "PuertaObservacion" }, { "PuertaObservacion", "Observacion" }, { "Observacion", "ObservacionBahia" },
	{ "Experimentos", "PuertaOrdenadores" }, { "PuertaOrdenadores", "Ordenadores" },
	{ "PasilloAlto", "PuertaTerrazaAlta" }, { "PuertaTerrazaAlta", "TerrazaFrente" }, { "TerrazaFrente", "TerrazaIzquierda" },
	{ "TerrazaFrente", "TerrazaDerecha" }, { "TerrazaDerecha", "TerrazaLateral" },
	-- Tejado
	{ "RellanoD", "Cupula" }, { "Cupula", "Observatorio" }, { "Cupula", "CupulaPuerta" }, { "CupulaPuerta", "Azotea" },
	{ "Azotea", "AzoteaMesa" }, { "AzoteaMesa", "AzoteaDelante" }, { "AzoteaDelante", "PanelesSolares" }, { "Azotea", "AzoteaTorre" },
	-- Sótano
	{ "SotanoL2", "PasilloSotano" }, { "PasilloSotano", "PuertaPortales" }, { "PuertaPortales", "Portales" }, { "Portales", "PortalDelante" },
	{ "PortalDelante", "PortalLado" }, { "PortalLado", "PuertaTallerPortales" }, { "PuertaTallerPortales", "Taller" },
	{ "PasilloSotano", "PuertaGarajeSotano" }, { "PuertaGarajeSotano", "GarajeSotano" }, { "GarajeSotano", "GarajeSotanoCoche" },
	{ "PasilloSotano", "PasilloFondo" }, { "PasilloFondo", "PuertaAlmacen" }, { "PuertaAlmacen", "Almacen" },
	{ "Almacen", "PuertaTaller" }, { "PuertaTaller", "Taller" }, { "Taller", "Estanteria" }, { "Estanteria", "SecretaEntrada" },
	{ "SecretaEntrada", "Secreta" }, { "Secreta", "SecretaPortal" },
}
Layout.Edges = E

-- Punto de paso por nombre (Vector3 local)
function Layout.point(name: string): Vector3
	local p = P[name]
	return Vector3.new(p[1], p[2], p[3])
end

-- Camino más corto entre dos puntos de paso (lista de nombres) o nil si no hay
function Layout.path(from: string, to: string): { string }?
	if not P[from] or not P[to] then
		return nil
	end
	local adj: { [string]: { string } } = {}
	for _, e in E do
		adj[e[1]] = adj[e[1]] or {}
		adj[e[2]] = adj[e[2]] or {}
		table.insert(adj[e[1]], e[2])
		table.insert(adj[e[2]], e[1])
	end
	local dist: { [string]: number } = { [from] = 0 }
	local prev: { [string]: string } = {}
	local open = { from }
	while #open > 0 do
		-- (pocos nodos: el más cercano a mano)
		local bi = 1
		for i = 2, #open do
			if dist[open[i]] < dist[open[bi]] then
				bi = i
			end
		end
		local cur = table.remove(open, bi) :: string
		if cur == to then
			break
		end
		local a = P[cur]
		for _, nxt in adj[cur] or {} do
			local b = P[nxt]
			local d = dist[cur] + math.sqrt((a[1] - b[1]) ^ 2 + (a[2] - b[2]) ^ 2 * 4 + (a[3] - b[3]) ^ 2)
			if dist[nxt] == nil or d < dist[nxt] then
				if dist[nxt] == nil then
					table.insert(open, nxt)
				end
				dist[nxt] = d
				prev[nxt] = cur
			end
		end
	end
	if dist[to] == nil then
		return nil
	end
	local out = { to }
	local cur = to
	while cur ~= from do
		cur = prev[cur]
		table.insert(out, 1, cur)
	end
	return out
end

-- Punto de paso más cercano a una posición local
function Layout.nearest(pos: Vector3): string
	local best, bestD = "Entrada", math.huge
	for name, p in P do
		local d = (p[1] - pos.X) ^ 2 + ((p[2] - pos.Y) * 3) ^ 2 + (p[3] - pos.Z) ^ 2
		if d < bestD then
			best, bestD = name, d
		end
	end
	return best
end

---------------------------------------------------------------------
-- Rutina de Cosme (hora del juego -> dónde está y qué hace). Anda de un sitio a otro por los puntos
-- de paso, nunca aparece de golpe.
---------------------------------------------------------------------
Layout.Routine = {
	{ Hour = 1, Point = "Secreta", Room = "Secreta", Work = "Book", Lines = { "Shhh… A esta hora el multiverso está más tranquilo.", "Si alguien pregunta, aquí no hay ninguna habitación." } },
	{ Hour = 8, Point = "Cocina", Room = "Cocina", Work = "Stir", Lines = { "Batido de apio cuántico. Por el potasio. Y por la física.", "¡La cafetera ha vuelto a viajar al martes pasado!" } },
	{ Hour = 9, Point = "LabMaquina", Room = "Laboratorio", Work = "Clipboard", Lines = { "Los anillos giran… pero no lo bastante. ¡Más bobinas!", "Esta máquina nos llevará a la luna. O al jueves. Lo que pase antes." } },
	{ Hour = 11, Point = "Ordenadores", Room = "Ordenadores", Work = "Type", Lines = { "Coordenadas 66-B… otra vez. Esto no me gusta, criatura.", "Las anomalías se mueven por el mapa. Como si buscaran algo." } },
	{ Hour = 13, Point = "Cocina", Room = "Cocina", Work = "Stir", Lines = { "La impresora de comida ha impreso una lasaña cuadrada. Progreso.", "Comer es importante. Lo dice mi nevera. Y me juzga." } },
	{ Hour = 15, Point = "GarajeCoche", Room = "GarajeCosme", Work = "Wipe", Lines = { "Este coche corre con energía de grieta. En teoría.", "No toques el botón rojo. Ni el azul. Ni el morado, sobre todo." } },
	{ Hour = 18, Point = "Observatorio", Room = "Observatorio", Work = "Watch", Lines = { "Mira la raja del cielo: hoy está nerviosa.", "La luna. Algún día, criatura. Algún día." } },
	{ Hour = 21, Point = "SalonSofa", Room = "Salon", Work = "Book", Lines = { "Esta casa es solo el principio… ¡pronto voy a construir una máquina que nos llevará a la luna!", "La tele solo da ecuaciones. Es mi canal favorito." } },
}

-- Qué toca a esta hora (la última franja que ya ha empezado, con la vuelta del día)
function Layout.slotAt(clock: number): { [string]: any }
	local best = Layout.Routine[#Layout.Routine]
	local bestHour = -1
	for _, slot in Layout.Routine do
		if slot.Hour <= clock and slot.Hour > bestHour then
			best, bestHour = slot, slot.Hour
		end
	end
	if bestHour < 0 then
		-- Antes de la primera franja del día: la última del día anterior
		local latest = Layout.Routine[1]
		for _, slot in Layout.Routine do
			if slot.Hour > latest.Hour then
				latest = slot
			end
		end
		best = latest
	end
	return best
end

---------------------------------------------------------------------
-- Marcas de la historia (StorySpot, SpotId): la misión las encuentra con shared/LifeStory/Locations.
-- GarajeCosme es la de siempre (91 pasos de misión la usan): delante del garaje, mirando a la calle,
-- con sitio libre alrededor para los actores (Offset de ±3 a 5 studs).
---------------------------------------------------------------------
Layout.Spots = {
	GarajeCosme = { -33, 0, -40, 0 },
	CosmeCocina = { 28, 1, 4, 90 },
	CosmeSalon = { 30, 1, -15.5, 0 },
	CosmeDespacho = { -16, 1, -27, 0 },
	CosmeLaboratorio = { -4, 1, 10, 90 },
	CosmeMaquina = { -4, 1, 17, 90 },
	CosmePortal = { 30, -14, -14, 180 },
	CosmeObservatorio = { -1, 27, 1, 0 },
	CosmeOrdenadores = { -15, 14, 15, 0 },
	CosmeSecreta = { 30, -14, 38.5, 0 },
	CosmeGarajeCoche = { -27, 1, -8, 90 },
	CosmeJardin = { 20, 0, 40, 0 },
}

return Layout
