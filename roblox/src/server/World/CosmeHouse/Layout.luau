-- Layout: el plano de la casa de Cosme (docs/historia/casa-cosme.md) en datos puros, sin Instances.
-- Lo usan los constructores (Exterior, Interior, Laboratory…), la rutina de Cosme (NPC) y la prueba
-- scripts/test-cosmehouse.luau.
--
-- Coordenadas LOCALES de la parcela (studs): origen en el centro de la manzana a ras de suelo (y = 0),
-- la fachada mira a -Z (a la calle de las casas familiares). La parcela va de -50 a 50 en X y en Z.
--
--   Alturas (cara de arriba de cada suelo):
--     Sótano  FB = -24   (techo a -2: la losa del jardín, de -2 a 0, es su techo; 22 de alto)
--     Baja    F0 = 1     (techo a 15)
--     Alta    F1 = 16    (techo a 30)
--     Ático   F2 = 31    (azotea y ático acristalado; techo del ático a 43, cúpula encima)
--
--   Planta baja (vista desde arriba, la calle abajo):
--     z=18 ┌──────────────┬─────────┬────────┐  terraza (z 18..26) y jardín trasero
--          │    SALÓN     │ COMEDOR │ COCINA │
--          │              │         ├────────┤
--     z=-6 ├────────┬─────┼─────────┤  ASEO  │┌───────────────┐
--      ( ) │DESPACHO│VEST.│ESCALERA │ SÓTANO ││    GARAJE     │ (escalera al sótano al fondo)
--   torre  │        │     │(4 tramos│(bajada)││  coche y      │
--     z=-32└────────┴─puerta───────┴────────┘└──portal───────┘
--         x=-34    -20   -12        0       12              46
--
--   El sótano ocupa casi toda la manzana (más grande que la casa: «¿cómo cabe todo esto aquí?»).

local Layout = {}

Layout.FB = -24
Layout.F0 = 1
Layout.F1 = 16
Layout.F2 = 31
Layout.CEIL = { B = -2, G = 15, U = 30, A = 43 }
Layout.LevelY = { B = -24, G = 1, U = 16, A = 31 }

Layout.Lot = { X0 = -50, X1 = 50, Z0 = -50, Z1 = 50 }
Layout.House = { X0 = -34, X1 = 12, Z0 = -32, Z1 = 18 }
Layout.Garage = { X0 = 12, X1 = 46, Z0 = -32, Z1 = 6 }
Layout.Basement = { X0 = -48, X1 = 46, Z0 = -46, Z1 = 46 }
Layout.Tower = { X = -40, Z = -22, R = 9 }
Layout.PortalTower = { X = 29, Z = 27, R = 6 }
Layout.Deck = { X0 = -34, X1 = 12, Z0 = 18, Z1 = 26 }

-- Escaleras de ida y vuelta (dos tramos de 6 de ancho, rellano en cada vuelta).
--   X0..X1: 12 de ancho (carril A = la mitad de +X, carril B = la de -X). Z0: lado del rellano cercano.
--   Near: fondo del rellano cercano; Run: largo de cada tramo; Far: fondo del rellano del otro lado.
--   Y0: altura de salida; Rise: lo que sube (o baja, negativo) cada tramo; Flights: número de tramos.
Layout.Stairs = {
	Hall = { X0 = -12, X1 = 0, Z0 = -32, Near = 7, Run = 12.5, Far = 6.5, Y0 = 1, Rise = 7.5, Flights = 4 },
	Sotano = { X0 = 0, X1 = 12, Z0 = -32, Near = 7, Run = 12.5, Far = 6.5, Y0 = 1, Rise = -6.25, Flights = 4 },
	Garaje = { X0 = 34, X1 = 46, Z0 = -20, Near = 7, Run = 12.5, Far = 6.5, Y0 = 1, Rise = -6.25, Flights = 4 },
}

-- Peldaños de un tramo (para construirlos y para la prueba): { { x0, x1, z0, z1, top } }
function Layout.flight(stair: { [string]: any }, k: number): { { number } }
	local laneA = k % 2 == 1
	local x0 = if laneA then stair.X0 + 6 else stair.X0
	local zNear, zFar = stair.Z0 + stair.Near, stair.Z0 + stair.Near + stair.Run
	local yStart = stair.Y0 + (k - 1) * stair.Rise
	local n = math.ceil(math.abs(stair.Rise) / 0.8)
	local h = stair.Rise / n
	local d = stair.Run / n
	local steps = {}
	for i = 1, n do
		-- Tramo A va de cerca a lejos; el B de lejos a cerca
		local za = if laneA then zNear + (i - 1) * d else zFar - i * d
		local zb = za + d
		-- Al bajar, cada peldaño queda medio peldaño por debajo del anterior
		local top = if stair.Rise > 0 then yStart + i * h else yStart + i * h
		table.insert(steps, { x0, x0 + 6, za, zb, top })
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
-- Habitaciones (Level: B sótano, G baja, U alta, A ático, O fuera). Rect en local. MinProps: lo
-- mínimo de piezas que tiene que tener dentro (la prueba comprueba que ninguna está vacía).
---------------------------------------------------------------------
export type Room = { Id: string, Name: string, Level: string, X0: number, X1: number, Z0: number, Z1: number, MinProps: number, Light: boolean? }

Layout.Rooms = {
	-- Exterior
	{ Id = "Jardin", Name = "Jardín delantero", Level = "O", X0 = -50, X1 = 12, Z0 = -50, Z1 = -33, MinProps = 40 },
	{ Id = "JardinTrasero", Name = "Jardín trasero", Level = "O", X0 = -50, X1 = 50, Z0 = 27, Z1 = 50, MinProps = 60 },
	{ Id = "Terraza", Name = "Terraza", Level = "O", X0 = -34, X1 = 12, Z0 = 18.5, Z1 = 26, MinProps = 15 },
	-- Planta baja
	{ Id = "Vestibulo", Name = "Vestíbulo", Level = "G", X0 = -20, X1 = -12, Z0 = -32, Z1 = -6, MinProps = 20, Light = true },
	{ Id = "Escalera", Name = "Escalera principal", Level = "G", X0 = -12, X1 = 0, Z0 = -32, Z1 = -6, MinProps = 30 },
	{ Id = "Despacho", Name = "Despacho", Level = "G", X0 = -34, X1 = -20, Z0 = -32, Z1 = -6, MinProps = 40, Light = true },
	{ Id = "Salon", Name = "Sala de estar", Level = "G", X0 = -34, X1 = -12, Z0 = -6, Z1 = 18, MinProps = 50, Light = true },
	{ Id = "Comedor", Name = "Comedor", Level = "G", X0 = -12, X1 = 0, Z0 = -6, Z1 = 18, MinProps = 25, Light = true },
	{ Id = "Cocina", Name = "Cocina", Level = "G", X0 = 0, X1 = 12, Z0 = 4, Z1 = 18, MinProps = 40, Light = true },
	{ Id = "Aseo", Name = "Baño de abajo", Level = "G", X0 = 0, X1 = 12, Z0 = -6, Z1 = 4, MinProps = 10, Light = true },
	{ Id = "BajadaSotano", Name = "Bajada al sótano", Level = "G", X0 = 0, X1 = 12, Z0 = -32, Z1 = -6, MinProps = 20 },
	{ Id = "GarajeCosme", Name = "Garaje experimental", Level = "G", X0 = 12, X1 = 46, Z0 = -32, Z1 = 6, MinProps = 80, Light = true },
	-- Planta alta
	{ Id = "Pasillo", Name = "Pasillo", Level = "U", X0 = -20, X1 = -12, Z0 = -32, Z1 = 8, MinProps = 12, Light = true },
	{ Id = "Biblioteca", Name = "Biblioteca científica", Level = "U", X0 = -34, X1 = -20, Z0 = -32, Z1 = -6, MinProps = 60, Light = true },
	{ Id = "Ordenadores", Name = "Sala de ordenadores", Level = "U", X0 = 0, X1 = 12, Z0 = -32, Z1 = -6, MinProps = 60, Light = true },
	{ Id = "Dormitorio", Name = "Habitación de Cosme", Level = "U", X0 = -34, X1 = -20, Z0 = -6, Z1 = 18, MinProps = 40, Light = true },
	{ Id = "BanoArriba", Name = "Baño de arriba", Level = "U", X0 = -20, X1 = -12, Z0 = 8, Z1 = 18, MinProps = 10, Light = true },
	{ Id = "Experimentos", Name = "Sala de experimentos", Level = "U", X0 = -12, X1 = 12, Z0 = -6, Z1 = 18, MinProps = 60, Light = true },
	{ Id = "Balcon", Name = "Balcón", Level = "U", X0 = -34, X1 = 12, Z0 = 18.5, Z1 = 24, MinProps = 10 },
	-- Ático
	{ Id = "Control", Name = "Centro de control", Level = "A", X0 = -34, X1 = -12, Z0 = -32, Z1 = -6, MinProps = 40, Light = true },
	{ Id = "Observatorio", Name = "Observatorio", Level = "A", X0 = -49, X1 = -34, Z0 = -31, Z1 = -13, MinProps = 15 },
	{ Id = "Azotea", Name = "Azotea", Level = "A", X0 = -34, X1 = 12, Z0 = -6, Z1 = 18, MinProps = 30 },
	-- Sótano
	{ Id = "PasilloSotano", Name = "Pasillo del sótano", Level = "B", X0 = -30, X1 = 0, Z0 = -34, Z1 = -24, MinProps = 15, Light = true },
	{ Id = "Laboratorio", Name = "Laboratorio principal", Level = "B", X0 = -48, X1 = 0, Z0 = -24, Z1 = 24, MinProps = 150, Light = true },
	{ Id = "Prototipos", Name = "Sala de prototipos", Level = "B", X0 = 0, X1 = 12, Z0 = -6, Z1 = 24, MinProps = 40, Light = true },
	{ Id = "Almacen", Name = "Almacén", Level = "B", X0 = -48, X1 = 12, Z0 = 24, Z1 = 46, MinProps = 60, Light = true },
	{ Id = "Energia", Name = "Sala de energía", Level = "B", X0 = 12, X1 = 46, Z0 = -34, Z1 = -20, MinProps = 40, Light = true },
	{ Id = "Portales", Name = "Sala de portales", Level = "B", X0 = 13, X1 = 45, Z0 = 11, Z1 = 43, MinProps = 60, Light = true },
	{ Id = "Secreta", Name = "Habitación secreta", Level = "B", X0 = -48, X1 = -30, Z0 = -46, Z1 = -24, MinProps = 40, Light = true },
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
	return -0.5, 14
end

---------------------------------------------------------------------
-- Puntos de paso (pies) por donde anda Cosme y aristas entre ellos. Cada arista es un tramo recto
-- que se puede andar (la prueba comprueba que no atraviesa paredes ni muebles).
---------------------------------------------------------------------
local P: { [string]: { number } } = {
	-- Calle y jardín
	Calle = { -16, 0, -47 },
	Porche = { -16, 0.5, -36 },
	Entrada = { -16, 1, -30 },
	-- Planta baja
	VestibuloMedio = { -16, 1, -19 },
	VestibuloFondo = { -16, 1, -8 },
	PieEscalera = { -6, 1, -28.5 },
	EscaleraA1 = { -3, 1, -25.5 },
	PuertaDespacho = { -20, 1, -19 },
	Despacho = { -27, 1, -19 },
	DespachoTorre = { -38, 1, -22 },
	Salon = { -21, 1, 1 },
	SalonSofa = { -19.5, 1, 5.4 },
	SalonEste = { -14.5, 1, 2 },
	SalonEsteFondo = { -14.5, 1, 13 },
	SalonTerraza = { -26, 1, 15 },
	Comedor = { -10.5, 1, 1 },
	ComedorFondo = { -10.5, 1, 15.5 },
	CocinaPaso = { -1, 1, 15.5 },
	Cocina = { 5, 1, 11 },
	AseoPuerta = { -2, 1, 0 },
	Aseo = { 5, 1, -1 },
	Terraza = { -26, 1, 22 },
	TerrazaEste = { -6, 1, 22 },
	JardinTrasero = { -26, 0, 34 },
	JardinTorre = { 18, 0, 34 },
	-- Escalera principal (vestíbulo): tramos de 7,5 y rellanos
	EscaleraA1Arriba = { -3, 8.5, -12.5 },
	RellanoA = { -6, 8.5, -9.5 },
	EscaleraB1 = { -9, 8.5, -12.5 },
	EscaleraB1Arriba = { -9, 16, -25 },
	RellanoB = { -6, 16, -28.5 },
	EscaleraA2 = { -3, 16, -25.5 },
	EscaleraA2Arriba = { -3, 23.5, -12.5 },
	RellanoC = { -6, 23.5, -9.5 },
	EscaleraB2 = { -9, 23.5, -12.5 },
	EscaleraB2Arriba = { -9, 31, -25 },
	RellanoD = { -6, 31, -28.5 },
	-- Bajada al sótano (núcleo de la derecha) y garaje
	SotanoL0 = { 6, 1, -28.5 },
	SotanoA1 = { 9, 1, -25.5 },
	SotanoA1Abajo = { 9, -5.25, -12.5 },
	SotanoL1 = { 6, -5.25, -9.5 },
	SotanoB1 = { 3, -5.25, -12.5 },
	SotanoB1Abajo = { 3, -11.5, -25 },
	SotanoL2 = { 6, -11.5, -28.5 },
	SotanoA2 = { 9, -11.5, -25.5 },
	SotanoA2Abajo = { 9, -17.75, -12.5 },
	SotanoL3 = { 6, -17.75, -9.5 },
	SotanoB2 = { 3, -17.75, -12.5 },
	SotanoB2Abajo = { 3, -24, -25 },
	SotanoL4 = { 6, -24, -28.5 },
	GarajeEntrada = { 17, 1, -28.5 },
	Garaje = { 31, 1, -24 },
	GarajeCoche = { 31, 1, -10 },
	GarajeBanco = { 17, 1, -20 },
	GarajeEscalera = { 40, 1, -16.5 },
	GarajeA1 = { 43, 1, -13.5 },
	GarajeA1Abajo = { 43, -5.25, -0.5 },
	GarajeL1 = { 40, -5.25, 2.5 },
	GarajeB1 = { 37, -5.25, -0.5 },
	GarajeB1Abajo = { 37, -11.5, -13 },
	GarajeL2 = { 40, -11.5, -16.5 },
	GarajeA2 = { 43, -11.5, -13.5 },
	GarajeA2Abajo = { 43, -17.75, -0.5 },
	GarajeL3 = { 40, -17.75, 2.5 },
	GarajeB2 = { 37, -17.75, -0.5 },
	GarajeB2Abajo = { 37, -24, -13 },
	GarajeL4 = { 40, -24, -16.5 },
	Acera = { 29, 0, -42 },
	-- Planta alta
	PasilloDelante = { -16, 16, -28.5 },
	PasilloMedio = { -16, 16, -19 },
	PasilloAtras = { -16, 16, -9 },
	PasilloFondo = { -16, 16, 1 },
	PasilloBano = { -16, 16, 6 },
	Biblioteca = { -27, 16, -19 },
	BibliotecaTorre = { -38, 16, -22 },
	PuertaOrdenadores = { 2, 16, -28.5 },
	Ordenadores = { 6, 16, -16 },
	Dormitorio = { -27, 16, 1 },
	DormitorioCama = { -24.5, 16, 6 },
	BanoArriba = { -17, 16, 11 },
	Experimentos = { -5, 16, 1 },
	ExperimentosFondo = { 4, 16, 10 },
	Balcon = { -26, 16, 20 },
	BalconEste = { 4, 16, 20 },
	-- Ático y azotea
	Control = { -20, 31, -27 },
	ControlOeste = { -30, 31, -24 },
	Observatorio = { -37.5, 31, -22 },
	AticoPuerta = { -24, 31, -8 },
	Azotea = { -24, 31, 4 },
	AzoteaMaquina = { 2, 31, 6 },
	AticoOeste = { -16, 31, -28.5 },
	AzoteaDelante = { 6, 31, -28.5 },
	AzoteaEste = { 6, 31, -12 },
	-- Sótano
	PasilloSotano = { -12, -24, -29 },
	PasilloSotanoEste = { -1, -24, -28.5 },
	PasilloSotanoOeste = { -26, -24, -29 },
	Estanteria = { -28, -24, -28.5 },
	SecretaEntrada = { -33, -24, -28.5 },
	Secreta = { -40, -24, -29 },
	SecretaPortal = { -40, -24, -38.5 },
	LabEntrada = { -15, -24, -21 },
	Laboratorio = { -8, -24, -6 },
	LabSur = { -12, -24, -16 },
	LabMaquina = { -26, -24, -14.5 },
	LabEste = { -5, -24, 9 },
	LabFondo = { -26, -24, 18 },
	PuertaPrototipos = { 1, -24, 9 },
	Prototipos = { 6, -24, 12 },
	PrototiposNorte = { 6, -24, 0 },
	PuertaEnergia = { 13, -24, -28.5 },
	Energia = { 24, -24, -27 },
	EnergiaEste = { 40, -24, -27 },
	EnergiaNorte = { 23, -24, 0 },
	PuertaPortales = { 29, -24, 8 },
	Portales = { 29, -24, 16 },
	PuertaAlmacen = { -26, -24, 25 },
	Almacen = { -26, -24, 34 },
	AlmacenEste = { 6, -24, 34 },
}
Layout.Points = P

local E = {
	{ "Calle", "Porche" }, { "Porche", "Entrada" }, { "Entrada", "VestibuloMedio" }, { "VestibuloMedio", "VestibuloFondo" },
	{ "Entrada", "PieEscalera" }, { "PieEscalera", "EscaleraA1" }, { "VestibuloMedio", "PuertaDespacho" },
	{ "PuertaDespacho", "Despacho" }, { "Despacho", "DespachoTorre" }, { "VestibuloFondo", "Salon" },
	{ "Salon", "SalonSofa" }, { "Salon", "SalonEste" }, { "SalonEste", "SalonEsteFondo" }, { "SalonEsteFondo", "SalonTerraza" }, { "Salon", "Comedor" }, { "Comedor", "ComedorFondo" },
	{ "ComedorFondo", "CocinaPaso" }, { "CocinaPaso", "Cocina" }, { "Comedor", "AseoPuerta" }, { "AseoPuerta", "Aseo" },
	{ "SalonTerraza", "Terraza" }, { "Terraza", "TerrazaEste" }, { "ComedorFondo", "TerrazaEste" },
	{ "Terraza", "JardinTrasero" }, { "JardinTrasero", "JardinTorre" },
	-- Escalera principal
	{ "EscaleraA1", "EscaleraA1Arriba" }, { "EscaleraA1Arriba", "RellanoA" }, { "RellanoA", "EscaleraB1" },
	{ "EscaleraB1", "EscaleraB1Arriba" }, { "EscaleraB1Arriba", "RellanoB" }, { "RellanoB", "EscaleraA2" },
	{ "EscaleraA2", "EscaleraA2Arriba" }, { "EscaleraA2Arriba", "RellanoC" }, { "RellanoC", "EscaleraB2" },
	{ "EscaleraB2", "EscaleraB2Arriba" }, { "EscaleraB2Arriba", "RellanoD" },
	-- Sótano por el núcleo de la derecha
	{ "PieEscalera", "SotanoL0" }, { "SotanoL0", "SotanoA1" }, { "SotanoA1", "SotanoA1Abajo" }, { "SotanoA1Abajo", "SotanoL1" },
	{ "SotanoL1", "SotanoB1" }, { "SotanoB1", "SotanoB1Abajo" }, { "SotanoB1Abajo", "SotanoL2" }, { "SotanoL2", "SotanoA2" },
	{ "SotanoA2", "SotanoA2Abajo" }, { "SotanoA2Abajo", "SotanoL3" }, { "SotanoL3", "SotanoB2" }, { "SotanoB2", "SotanoB2Abajo" },
	{ "SotanoB2Abajo", "SotanoL4" },
	{ "SotanoL0", "GarajeEntrada" }, { "GarajeEntrada", "Garaje" }, { "Garaje", "GarajeCoche" }, { "GarajeEntrada", "GarajeBanco" },
	{ "Garaje", "GarajeEscalera" }, { "Garaje", "Acera" },
	{ "GarajeEscalera", "GarajeA1" }, { "GarajeA1", "GarajeA1Abajo" }, { "GarajeA1Abajo", "GarajeL1" }, { "GarajeL1", "GarajeB1" },
	{ "GarajeB1", "GarajeB1Abajo" }, { "GarajeB1Abajo", "GarajeL2" }, { "GarajeL2", "GarajeA2" }, { "GarajeA2", "GarajeA2Abajo" },
	{ "GarajeA2Abajo", "GarajeL3" }, { "GarajeL3", "GarajeB2" }, { "GarajeB2", "GarajeB2Abajo" }, { "GarajeB2Abajo", "GarajeL4" },
	{ "GarajeL4", "EnergiaEste" },
	-- Planta alta
	{ "RellanoB", "PasilloDelante" }, { "PasilloDelante", "PasilloMedio" }, { "PasilloMedio", "PasilloAtras" },
	{ "PasilloAtras", "PasilloFondo" }, { "PasilloFondo", "PasilloBano" }, { "PasilloBano", "BanoArriba" },
	{ "PasilloMedio", "Biblioteca" }, { "Biblioteca", "BibliotecaTorre" }, { "RellanoB", "PuertaOrdenadores" },
	{ "PuertaOrdenadores", "Ordenadores" }, { "PasilloFondo", "Dormitorio" }, { "Dormitorio", "DormitorioCama" },
	{ "PasilloFondo", "Experimentos" }, { "Experimentos", "ExperimentosFondo" }, { "DormitorioCama", "Balcon" },
	{ "Balcon", "BalconEste" }, { "BalconEste", "ExperimentosFondo" },
	-- Ático y azotea
	{ "RellanoD", "AticoOeste" }, { "AticoOeste", "Control" }, { "Control", "ControlOeste" }, { "ControlOeste", "Observatorio" },
	{ "Control", "AticoPuerta" }, { "AticoPuerta", "Azotea" }, { "Azotea", "AzoteaMaquina" }, { "RellanoD", "AzoteaDelante" },
	{ "AzoteaDelante", "AzoteaEste" }, { "AzoteaEste", "AzoteaMaquina" },
	-- Sótano
	{ "SotanoL4", "PasilloSotanoEste" }, { "PasilloSotanoEste", "PasilloSotano" }, { "PasilloSotano", "PasilloSotanoOeste" },
	{ "PasilloSotanoOeste", "Estanteria" }, { "Estanteria", "SecretaEntrada" }, { "SecretaEntrada", "Secreta" }, { "Secreta", "SecretaPortal" },
	{ "PasilloSotano", "LabEntrada" }, { "LabEntrada", "Laboratorio" }, { "Laboratorio", "LabSur" }, { "LabSur", "LabMaquina" },
	{ "Laboratorio", "LabEste" }, { "LabEste", "LabFondo" }, { "LabEste", "PuertaPrototipos" },
	{ "PuertaPrototipos", "Prototipos" }, { "Prototipos", "PrototiposNorte" },
	{ "SotanoL4", "PuertaEnergia" }, { "PuertaEnergia", "Energia" }, { "Energia", "EnergiaEste" }, { "Energia", "EnergiaNorte" },
	{ "EnergiaNorte", "PuertaPortales" }, { "PuertaPortales", "Portales" },
	{ "LabFondo", "PuertaAlmacen" }, { "PuertaAlmacen", "Almacen" }, { "Almacen", "AlmacenEste" },
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
	GarajeCosme = { 29, 0, -38, 0 },
	CosmeCocina = { 5, 1, 11, 180 },
	CosmeSalon = { -21, 1, 1, 0 },
	CosmeDespacho = { -27, 1, -19, 90 },
	CosmeLaboratorio = { -8, -24, -6, 0 },
	CosmeMaquina = { -26, -24, -14.5, 180 },
	CosmePortal = { 29, -24, 18, 180 },
	CosmeObservatorio = { -37.5, 31, -22, 90 },
	CosmeOrdenadores = { 6, 16, -16, 0 },
	CosmeSecreta = { -40, -24, -29, 0 },
	CosmeGarajeCoche = { 31, 1, -10, 90 },
	CosmeJardin = { -26, 0, 34, 0 },
}

return Layout
