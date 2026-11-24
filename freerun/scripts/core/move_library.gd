class_name MoveLibrary
extends RefCounted
## Biblioteca interna de movimientos (menú de pausa → Movimientos).
## Nombres, variantes y niveles tomados de pkfr.world/tutorials (niveles 1-4) y
## trickipedia.app (niveles y prerrequisitos). Ninguna de las dos fuentes describe la técnica
## en texto (sus vídeos no se han podido ver), así que la biomecánica del juego se basa en
## la técnica deportiva estándar.
##
## estado:  "ok"        implementado con impulso, trayectoria y postura propias, y probado
##          "parcial"   se reconoce y rota bien, pero comparte postura con su familia
##          "pendiente" aún no está en el juego (motivo en la nota)
##
## Validación (5 niveles, no se confunden):
##   1 Documentado · 2 Implementado · 3 Probado técnicamente (pruebas automáticas)
##   4 Inspeccionado visualmente (capturas/vídeo revisados) · 5 Validado en móvil (por el jugador)
## Ningún movimiento está en el nivel 5 hasta que se confirme en un iPhone real.
##
## Entrada: SALTO, VAULT, AGARRAR, RODAR · Rueda = SALTO con zonas ADELANTE/ATRÁS/LATERAL · GIRO / JD = joystick derecho · JI = joystick izquierdo.

const CATEGORIES := ["Vaults", "Precision", "Paredes", "Escalada", "Barras", "Rolls y recepciones",
	"Mortales adelante y atrás", "Laterales", "Aerials y Websters", "Gainers", "Corks",
	"Butterfly y patadas", "Tricking", "Handsprings", "Ruedas y rondadas", "Suelo", "Combos", "Avanzados"]

const MOVES := [
	# --- Vaults ---
	{"name": "Step Vault / Safety Vault", "cat": "Vaults", "lvl": 1, "input": "VAULT (o SALTO) a poca velocidad u obstáculo bajo", "status": "ok"},
	{"name": "Speed Vault", "cat": "Vaults", "lvl": 1, "input": "VAULT corriendo de frente", "status": "ok"},
	{"name": "Lazy Vault", "cat": "Vaults", "lvl": 1, "input": "VAULT llegando en diagonal al obstáculo", "status": "ok"},
	{"name": "Kong Vault / Monkey / Cat Pass", "cat": "Vaults", "lvl": 1, "input": "VAULT a sprint en obstáculo profundo", "status": "ok"},
	{"name": "Dash Vault", "cat": "Vaults", "lvl": 1, "input": "VAULT a sprint despegando lejos", "status": "ok"},
	{"name": "Double Kong", "cat": "Vaults", "lvl": 2, "input": "VAULT + JD ↑ en obstáculo muy profundo", "status": "ok"},
	{"name": "Kash Vault", "cat": "Vaults", "lvl": 1, "input": "VAULT + JD ↓ en caja de kong (Kong + Dash)", "status": "ok"},
	{"name": "Reverse Vault / 360 Vault", "cat": "Vaults", "lvl": 2, "input": "VAULT + JD ← o →", "status": "ok"},
	{"name": "Step Up", "cat": "Vaults", "lvl": 1, "input": "VAULT ante un muro bajo para subirlo", "status": "ok"},
	{"name": "Thief Vault", "cat": "Vaults", "lvl": 1, "input": "VAULT + JD ↖ o ↗ (obstáculo estrecho y con carrera; piernas primero, una mano detrás)", "status": "ok"},
	{"name": "Turn Vault", "cat": "Vaults", "lvl": 1, "input": "VAULT + JD ↙ o ↘ (dos manos, media vuelta; cae frenado y de cara al obstáculo, sin quedarse colgado)", "status": "ok"},
	{"name": "Gate Vault", "cat": "Vaults", "lvl": 1, "input": "-", "status": "pendiente", "note": "pendiente de postura propia"},
	{"name": "Dive Kong", "cat": "Vaults", "lvl": 2, "input": "SALTO con carrera lejos del obstáculo: las manos llegan solo si la distancia y la altura dan (récord de distancia)", "status": "ok"},
	# --- Precision ---
	{"name": "Precision Jump", "cat": "Precision", "lvl": 1, "input": "SALTO y caer en un apoyo estrecho", "status": "ok"},
	{"name": "Running Precision", "cat": "Precision", "lvl": 1, "input": "SALTO corriendo a un apoyo estrecho", "status": "ok"},
	{"name": "Stride", "cat": "Precision", "lvl": 1, "input": "-", "status": "pendiente", "note": "zancadas encadenadas a una pierna"},
	{"name": "Plyo", "cat": "Precision", "lvl": 1, "input": "SALTO justo al aterrizar (rebote)", "status": "ok"},
	# --- Paredes ---
	{"name": "Wall Run", "cat": "Paredes", "lvl": 1, "input": "Mantén SALTO corriendo hacia una pared", "status": "ok"},
	{"name": "Tic Tac", "cat": "Paredes", "lvl": 1, "input": "SALTO en el aire junto a una pared lateral", "status": "ok"},
	{"name": "Wall Flip", "cat": "Paredes", "lvl": 2, "input": "Durante el wall run / wall climb: rueda ATRÁS", "status": "ok"},
	{"name": "Wall Gainer", "cat": "Paredes", "lvl": 3, "input": "Wall run lateral + rueda ATRÁS", "status": "ok"},
	{"name": "Wall Front", "cat": "Paredes", "lvl": 3, "input": "Desde la pared: rueda ADELANTE", "status": "ok"},
	{"name": "Wall Flip 180 / Wall Half · Wall Full", "cat": "Paredes", "lvl": 3, "input": "Wall flip + GIRO ½ o 1", "status": "parcial"},
	{"name": "Wall Spin", "cat": "Paredes", "lvl": 2, "input": "-", "status": "pendiente", "note": "giro apoyando manos en la pared"},
	{"name": "Palm Flip", "cat": "Paredes", "lvl": 3, "input": "-", "status": "pendiente", "note": "empuje con la mano en la pared"},
	# --- Escalada ---
	{"name": "Wall Climb / Climb Up", "cat": "Escalada", "lvl": 1, "input": "VAULT o AGARRAR ante una pared alta", "status": "ok"},
	{"name": "Cat Leap", "cat": "Escalada", "lvl": 1, "input": "Salta a un borde alto (o AGARRAR en el aire)", "status": "ok"},
	{"name": "Ledge Grab y Shimmy", "cat": "Escalada", "lvl": 1, "input": "AGARRAR en el aire; JI a los lados para desplazarte", "status": "ok"},
	{"name": "Mantle", "cat": "Escalada", "lvl": 1, "input": "VAULT/AGARRAR en un borde a la altura del pecho", "status": "ok"},
	{"name": "Soltar / Drop", "cat": "Escalada", "lvl": 1, "input": "Colgado: AGARRAR (SOLTAR)", "status": "ok"},
	{"name": "Wall Jump desde borde", "cat": "Escalada", "lvl": 1, "input": "Colgado: SALTO + JI hacia atrás (rueda = mortal)", "status": "ok"},
	{"name": "Cat Leap 180", "cat": "Escalada", "lvl": 1, "input": "-", "status": "pendiente", "note": "giro de 180 colgado"},
	# --- Barras ---
	{"name": "Underbar", "cat": "Barras", "lvl": 1, "input": "-", "status": "pendiente", "note": "no hay barras en el mapa (fase de escenarios)"},
	{"name": "Bar Swing / Kickstart", "cat": "Barras", "lvl": 1, "input": "-", "status": "pendiente", "note": "requiere barras"},
	{"name": "Muscle Up", "cat": "Barras", "lvl": 1, "input": "-", "status": "pendiente", "note": "requiere barras"},
	{"name": "Lache", "cat": "Barras", "lvl": 2, "input": "-", "status": "pendiente", "note": "requiere barras"},
	{"name": "Fly Away / Bar Gainer", "cat": "Barras", "lvl": 2, "input": "-", "status": "pendiente", "note": "requiere barras"},
	# --- Rolls y recepciones ---
	{"name": "Parkour Roll", "cat": "Rolls y recepciones", "lvl": 1, "input": "RODAR corriendo", "status": "ok"},
	{"name": "Safety Roll", "cat": "Rolls y recepciones", "lvl": 1, "input": "RODAR justo antes de caer desde alto", "status": "ok"},
	{"name": "Drop Landing", "cat": "Rolls y recepciones", "lvl": 1, "input": "Aterrizar limpio desde alto", "status": "ok"},
	{"name": "Dive Roll", "cat": "Rolls y recepciones", "lvl": 1, "input": "-", "status": "pendiente", "note": "vuelo en plancha antes del roll"},
	{"name": "Barrel Roll / Side Roll", "cat": "Rolls y recepciones", "lvl": 1, "input": "-", "status": "pendiente"},
	{"name": "Back Roll", "cat": "Rolls y recepciones", "lvl": 1, "input": "-", "status": "pendiente"},
	# --- Mortales adelante y atrás ---
	{"name": "Backflip / Back Tuck", "cat": "Mortales adelante y atrás", "lvl": 2, "input": "Rueda: ATRÁS (parado)", "status": "ok"},
	{"name": "Frontflip / Front Tuck", "cat": "Mortales adelante y atrás", "lvl": 2, "input": "Rueda: ADELANTE (parado)", "status": "ok"},
	{"name": "Double Backflip", "cat": "Mortales adelante y atrás", "lvl": 4, "input": "Rueda: ATRÁS y otra vez ATRÁS en el aire", "status": "ok"},
	{"name": "Double / Triple Front", "cat": "Mortales adelante y atrás", "lvl": 4, "input": "Rueda: ADELANTE dos veces", "status": "ok"},
	{"name": "Hyper (¼ de giro en cualquier mortal)", "cat": "Mortales adelante y atrás", "lvl": 3, "input": "Cualquier mortal + toque corto de GIRO: aterriza de lado", "status": "ok"},
	{"name": "Back Full", "cat": "Mortales adelante y atrás", "lvl": 4, "input": "ATRÁS + GIRO una vuelta (o tocar el joystick GIRO)", "status": "ok"},
	{"name": "Back Half · Back 1.5 · Double Full · Full In", "cat": "Mortales adelante y atrás", "lvl": 4, "input": "ATRÁS + GIRO ½, 1½, 2 vueltas…", "status": "parcial"},
	{"name": "Front Full", "cat": "Mortales adelante y atrás", "lvl": 4, "input": "ADELANTE + GIRO una vuelta", "status": "ok"},
	{"name": "Arabian (Backflip 180 a front)", "cat": "Mortales adelante y atrás", "lvl": 3, "input": "Frontflip + GIRO ½", "status": "parcial"},
	{"name": "Barani (Front 180)", "cat": "Mortales adelante y atrás", "lvl": 3, "input": "-", "status": "pendiente"},
	{"name": "Rudi (Front 540)", "cat": "Mortales adelante y atrás", "lvl": 4, "input": "Front Full + GIRO", "status": "parcial"},
	{"name": "Layout · Pike", "cat": "Mortales adelante y atrás", "lvl": 4, "input": "-", "status": "pendiente", "note": "formas extendida y carpada"},
	{"name": "Ledge Backflip", "cat": "Mortales adelante y atrás", "lvl": 2, "input": "Backflip saliendo de un borde", "status": "ok"},
	# --- Laterales ---
	{"name": "Sideflip", "cat": "Laterales", "lvl": 2, "input": "Rueda: LATERAL (corriendo se pone de lado y avanza girando)", "status": "ok"},
	{"name": "Double Sideflip", "cat": "Laterales", "lvl": 4, "input": "Sideflip + volver a inclinar", "status": "ok"},
	{"name": "Wall Sideflip", "cat": "Laterales", "lvl": 2, "input": "Desde la pared: rueda LATERAL", "status": "parcial"},
	{"name": "Raiz", "cat": "Tricking", "lvl": 3, "input": "MANTÉN el joystick GIRO ← o → en el suelo", "status": "ok", "note": "vuelo lateral arqueado con media vuelta"},
	{"name": "Touchdown Raiz", "cat": "Tricking", "lvl": 3, "input": "MANTÉN el joystick GIRO ↖ o ↗ en el suelo", "status": "ok", "note": "una mano toca el suelo antes que los pies"},
	# --- Aerials y Websters ---
	{"name": "Aerial (rueda sin manos)", "cat": "Aerials y Websters", "lvl": 2, "input": "Joystick GIRO ↖ en el suelo, parado", "status": "ok", "note": "es la misma técnica que el Aerial Cartwheel"},
	{"name": "Webster (front a una pierna)", "cat": "Aerials y Websters", "lvl": 1, "input": "Rueda: ADELANTE corriendo", "status": "ok"},
	{"name": "Aerial Twist", "cat": "Aerials y Websters", "lvl": 3, "input": "Aerial + GIRO", "status": "parcial"},
	{"name": "Double Aerial", "cat": "Aerials y Websters", "lvl": 4, "input": "Aerial + volver a inclinar", "status": "parcial"},
	# --- Gainers ---
	{"name": "Gainer (backflip avanzando)", "cat": "Gainers", "lvl": 2, "input": "Rueda: ATRÁS corriendo", "status": "ok"},
	{"name": "Cheat Gainer / Kick the Moon", "cat": "Gainers", "lvl": 2, "input": "Gainer + GIRO ½", "status": "ok"},
	{"name": "Piru", "cat": "Gainers", "lvl": 3, "input": "ATRÁS + una vuelta de GIRO (suelto, parado o corriendo)", "status": "ok", "note": "mortal atrás con tirabuzón de 360; con más GIRO: Piru 540 / 720"},
	{"name": "Double Gainer", "cat": "Gainers", "lvl": 4, "input": "Gainer + ↓ otra vez", "status": "ok"},
	{"name": "Kong Gainer · Dash Gainer · Vault Gainer", "cat": "Gainers", "lvl": 3, "input": "JD ↓ durante el vault", "status": "ok"},
	# --- Corks ---
	{"name": "Cork / Corkscrew", "cat": "Corks", "lvl": 4, "input": "Botón CORK: salta en cork al momento (o, cayendo de una altura, lo empieza en ese punto); o ATRÁS + GIRO dentro de un combo (tras TD Raiz, raiz, hook, rondada...)", "status": "ok"},
	{"name": "Cork 720", "cat": "Corks", "lvl": 4, "input": "Cork + GIRO en el mismo sentido", "status": "ok"},
	{"name": "ST (recepción a un pie)", "cat": "Corks", "lvl": 4, "input": "Pulsa CORK durante un cork: cae a un pie y enlaza otro cork", "status": "ok"},
	{"name": "Cork 540 · Cork 1080", "cat": "Corks", "lvl": 4, "input": "Cork + giros añadidos", "status": "parcial"},
	{"name": "Double Cork · Triple Cork", "cat": "Corks", "lvl": 4, "input": "Cork + volver a inclinar", "status": "ok"},
	# --- Butterfly y patadas ---
	{"name": "Butterfly Kick", "cat": "Butterfly y patadas", "lvl": 2, "input": "Joystick GIRO ↖ en el suelo, corriendo", "status": "ok"},
	{"name": "Butterfly Twist / B-Twist", "cat": "Butterfly y patadas", "lvl": 3, "input": "Butterfly + GIRO (mejor tras scoot o touchdown raiz)", "status": "ok"},
	{"name": "360 Kick / Tornado Kick", "cat": "Butterfly y patadas", "lvl": 1, "input": "Joystick GIRO ↗ en el suelo, o SALTO + GIRO sin mortal", "status": "ok"},
	{"name": "Cheat 360 Kick", "cat": "Butterfly y patadas", "lvl": 2, "input": "Joystick GIRO ↗ en la ventana de enlace de un hook", "status": "ok", "note": "el 360 con despegue de entrada (cheat)"},
	{"name": "Hook Kick", "cat": "Tricking", "lvl": 2, "input": "Joystick GIRO en ARCO por abajo (← ↙ ↓ ↘ →)", "status": "ok", "note": "giro de entrada, cadera, extensión y gancho"},
	{"name": "Scoot", "cat": "Tricking", "lvl": 2, "input": "Joystick GIRO: CAMBIO DE DIRECCIÓN (← y enseguida →)", "status": "ok", "note": "interpretación propia de la técnica (no verificada con vídeo)"},
	{"name": "Master Scoot", "cat": "Tricking", "lvl": 3, "input": "-", "status": "pendiente", "note": "no he podido verificar su técnica: no se inventa"},
	{"name": "540 Kick", "cat": "Butterfly y patadas", "lvl": 1, "input": "360 Kick + GIRO otra vez", "status": "ok"},
	{"name": "720 · Cheat 720 · 900 · 1080", "cat": "Butterfly y patadas", "lvl": 3, "input": "Más toques de GIRO", "status": "parcial"},
	{"name": "Axe Kick Aerial · Frisbee", "cat": "Butterfly y patadas", "lvl": 3, "input": "-", "status": "pendiente"},
	# --- Handsprings ---
	{"name": "Back Handspring (flic-flac)", "cat": "Handsprings", "lvl": 3, "input": "Joystick GIRO ↓ (inclinar y soltar) en el suelo", "status": "ok"},
	{"name": "Side Handspring", "cat": "Handsprings", "lvl": 1, "input": "-", "status": "pendiente"},
	{"name": "Back Handspring Twist", "cat": "Handsprings", "lvl": 3, "input": "Flic-flac + GIRO", "status": "parcial"},
	# --- Ruedas y rondadas ---
	{"name": "Cartwheel (rueda)", "cat": "Ruedas y rondadas", "lvl": 1, "input": "Joystick GIRO ← o → en el suelo (sin SALTO)", "status": "ok"},
	{"name": "Round-off (rondada)", "cat": "Ruedas y rondadas", "lvl": 2, "input": "Joystick GIRO ↙ o ↘ en el suelo (sin SALTO)", "status": "ok"},
	{"name": "One Arm Round-off", "cat": "Ruedas y rondadas", "lvl": 2, "input": "-", "status": "pendiente"},
	# --- Suelo ---
	{"name": "Kip-up", "cat": "Suelo", "lvl": 1, "input": "Tumbado tras una caída: SALTO o GIRO ↑", "status": "ok"},
	{"name": "Macaco", "cat": "Suelo", "lvl": 2, "input": "MANTÉN GIRO ↙ o ↘ en el suelo", "status": "ok", "note": "giro atrás sobre una mano desde agachado"},
	{"name": "Gumbi", "cat": "Suelo", "lvl": 2, "input": "-", "status": "pendiente"},
	{"name": "Handstand (pino)", "cat": "Suelo", "lvl": 1, "input": "MANTÉN GIRO ↑: se sostiene mientras no sueltes", "status": "ok"},
	{"name": "Handstand Push-off (snap down)", "cat": "Suelo", "lvl": 2, "input": "En el pino, SALTO", "status": "ok"},
	# --- Combos ---
	{"name": "Round-off → Backflip", "cat": "Combos", "lvl": 3, "input": "GIRO ↙ y en la recepción rueda ATRÁS (rebote más alto)", "status": "ok"},
	{"name": "Round-off → Back Handspring → Backflip", "cat": "Combos", "lvl": 4, "input": "GIRO ↙ · GIRO ↓ durante la rondada · rueda ATRÁS", "status": "ok"},
	{"name": "Round-off → Back Handspring → Double Backflip", "cat": "Combos", "lvl": 4, "input": "… rueda ATRÁS mantenida y ATRÁS otra vez en el aire", "status": "ok"},
	{"name": "Round-off → BHS → BHS → Double Backflip", "cat": "Combos", "lvl": 4, "input": "GIRO ↙ · ↓ · ↓ · rueda ATRÁS ×2", "status": "ok"},
	{"name": "Round-off → BHS → Cork / Double Cork", "cat": "Combos", "lvl": 4, "input": "… rueda ATRÁS + GIRO (y ATRÁS otra vez para el doble)", "status": "ok"},
	{"name": "Hook → Cork / Double Cork", "cat": "Combos", "lvl": 4, "input": "Arco por abajo y en la recepción ATRÁS + GIRO (el giro del hook acelera el tirabuzón)", "status": "ok"},
	{"name": "Macaco → Back Handspring / Backflip", "cat": "Combos", "lvl": 3, "input": "Macaco y en la recepción GIRO ↓ o rueda ATRÁS", "status": "ok"},
	{"name": "Raiz → Cork", "cat": "Combos", "lvl": 4, "input": "Raiz y en la recepción ATRÁS + GIRO", "status": "ok"},
	{"name": "TD Raiz → Butterfly Twist", "cat": "Combos", "lvl": 4, "input": "TD Raiz y en la recepción GIRO ↖ y luego GIRO lateral", "status": "ok"},
	{"name": "Scoot → B-Twist", "cat": "Combos", "lvl": 4, "input": "Cambio de dirección y en la recepción GIRO ↖ + GIRO lateral", "status": "ok"},
	{"name": "Cartwheel → Backflip", "cat": "Combos", "lvl": 3, "input": "Rueda y en la recepción rueda ATRÁS", "status": "ok"},
	{"name": "Round-off / BHS Rebound", "cat": "Combos", "lvl": 2, "input": "En la recepción, SALTO sin mortal (rebote vertical)", "status": "ok"},
	{"name": "Kong Vault → Frontflip (Kong Front)", "cat": "Combos", "lvl": 3, "input": "VAULT a sprint + JD ↑ durante el vault", "status": "ok"},
	{"name": "Wall Run → Wall Flip", "cat": "Combos", "lvl": 2, "input": "Mantén SALTO en la pared + JD ↓", "status": "ok"},
	{"name": "Aerial → Butterfly Kick", "cat": "Combos", "lvl": 3, "input": "Al caer del aerial, GIRO ↖ con carrera", "status": "ok"},
	{"name": "Gainer → Cork", "cat": "Combos", "lvl": 4, "input": "Gainer y, al aterrizar, ATRÁS + GIRO una vuelta", "status": "ok"},
	{"name": "Backflip + giro adicional", "cat": "Combos", "lvl": 4, "input": "Backflip + GIRO (Back Full)", "status": "ok"},
	# --- Avanzados ---
	{"name": "Double Full · Full In · Rudi", "cat": "Avanzados", "lvl": 4, "input": "Mortales con varios GIROS", "status": "parcial"},
	{"name": "Cork 1080 · Triple Cork", "cat": "Avanzados", "lvl": 4, "input": "Cork con varios giros y vueltas", "status": "parcial"},
	{"name": "Dash Bomb (Dash + Frontflip)", "cat": "Avanzados", "lvl": 3, "input": "Dash Vault + JD ↑", "status": "ok"},
	{"name": "360 Kong · Screwdriver", "cat": "Avanzados", "lvl": 4, "input": "-", "status": "pendiente"},
	{"name": "Palm Spin Gainer · Cast Gainer", "cat": "Avanzados", "lvl": 3, "input": "-", "status": "pendiente"},
]

const CATEGORY_ES := {"Vaults": "Pasavallas (vaults)", "Precision": "Precisión",
	"Rolls y recepciones": "Volteretas y recepciones", "Aerials y Websters": "Ruedas sin manos y websters",
	"Gainers": "Mortales atrás en carrera (gainers)", "Corks": "Sacacorchos (corks)",
	"Butterfly y patadas": "Mariposas y patadas", "Handsprings": "Flic-flacs",
	"Tricking": "Tricking (patadas, raiz y entradas)"}
const LEVELS := ["", "Documentado", "Implementado", "Probado técnicamente", "Inspeccionado visualmente", "Validado en móvil"]
## Revisados en capturas/vídeo de la partida (fotogramas de las fases del movimiento).
const VISUALLY_INSPECTED := ["Backflip / Back Tuck", "Frontflip / Front Tuck", "Double Backflip", "Sideflip",
	"Gainer (backflip avanzando)", "Thief Vault", "Turn Vault",
	# Habilidades con apoyo real (capturas por fases tras el sistema de apoyos con IK)
	"Round-off (rondada)", "Back Handspring (flic-flac)", "Cartwheel (rueda)",
	"Macaco", "Kip-up",
	"Handstand (pino)", "Handstand Push-off (snap down)", "Raiz", "Touchdown Raiz", "Hook Kick",
	"Scoot", "Speed Vault", "Kong Vault / Monkey / Cat Pass"]
## Confirmados por el jugador en su móvil (vacío hasta tener esa confirmación).
const MOBILE_VALIDATED: Array[String] = []

static func validation(m: Dictionary) -> int:
	if m.status == "pendiente":
		return 1
	if m.status == "parcial":
		return 2
	if m.name in MOBILE_VALIDATED:
		return 5
	if m.name in VISUALLY_INSPECTED:
		return 4
	return 3

static func by_category() -> Dictionary:
	var out := {}
	for c in CATEGORIES:
		out[c] = []
	for m in MOVES:
		out[m.cat].append(m)
	return out

static func counts() -> Dictionary:
	var c := {"ok": 0, "parcial": 0, "pendiente": 0}
	for m in MOVES:
		c[m.status] += 1
	return c

## Texto con formato BBCode para el panel de la biblioteca.
static func bbcode() -> String:
	var n := counts()
	var t := "[b]%d movimientos[/b]  ·  [color=#5fe08a]%d hechos[/color]  ·  [color=#f2c14e]%d parciales[/color]  ·  [color=#999999]%d pendientes[/color]\n" % [MOVES.size(), n.ok, n.parcial, n.pendiente]
	t += "[color=#aaaaaa]Validación: 1 documentado · 2 implementado · 3 probado técnicamente · 4 inspeccionado visualmente · 5 validado en móvil[/color]\n"
	t += "[color=#aaaaaa]SALTO · VAULT · AGARRAR · RODAR · Rueda = SALTO con zonas ADELANTE/ATRÁS/LATERAL · GIRO / JD = joystick derecho · JI = joystick izquierdo[/color]\n"
	var groups := by_category()
	for c in CATEGORIES:
		t += "\n[b][color=#2fd9c6]%s[/color][/b]\n" % CATEGORY_ES.get(c, c)
		for m in groups[c]:
			var col: String = {"ok": "#5fe08a", "parcial": "#f2c14e", "pendiente": "#999999"}[m.status]
			var es_name := MoveNames.es_text(m.name)
			var orig := ("  [color=#777777](%s)[/color]" % m.name) if es_name != m.name else ""
			var line := "[color=%s]•[/color] [b]%s[/b]%s  [color=#888888]nivel %d · %d/5 %s[/color]" % [col, es_name, orig, m.lvl, validation(m), LEVELS[validation(m)]]
			if m.status != "pendiente":
				line += "\n     " + MoveNames.es_phrase(m.input)
			elif m.has("note"):
				line += "  [color=#888888](%s)[/color]" % m.note
			t += line + "\n"
	return t
