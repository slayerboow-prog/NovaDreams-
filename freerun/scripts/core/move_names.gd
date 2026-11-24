class_name MoveNames
extends RefCounted
## Nombres en español de los movimientos (solo para mostrarlos al jugador).
## Por dentro el juego sigue usando el nombre original (inglés, el habitual en parkour y
## tricking): así no cambia la lógica, la puntuación ni las pruebas.

const ES := {
	# Mortales adelante y atrás
	"Backflip": "Mortal atrás", "Back Tuck": "Mortal atrás agrupado",
	"Frontflip": "Mortal adelante", "Front Tuck": "Mortal adelante agrupado",
	"Double Backflip": "Doble mortal atrás", "Triple Backflip": "Triple mortal atrás",
	"Double Front": "Doble mortal adelante", "Triple Front": "Triple mortal adelante",
	"Back Half": "Mortal atrás con medio giro", "Back Full": "Mortal atrás con tirabuzón",
	"Back 1.5": "Mortal atrás con tirabuzón y medio", "Double Full": "Mortal con doble tirabuzón",
	"Full In": "Doble mortal con tirabuzón", "Front Full": "Mortal adelante con tirabuzón",
	"Front Double Full": "Mortal adelante con doble tirabuzón", "Arabian": "Árabe",
	"Double Arabian": "Doble árabe", "Barani": "Barani (adelante con medio giro)",
	"Rudi": "Rudi (adelante con tirabuzón y medio)", "Layout": "Mortal estirado", "Pike": "Mortal carpado",
	"Ledge Backflip": "Mortal atrás desde borde", "Webster": "Webster (mortal adelante a una pierna)",
	# Gainers
	"Gainer": "Mortal atrás en carrera", "Double Gainer": "Doble mortal atrás en carrera",
	"Cheat Gainer": "Mortal atrás en carrera cruzado", "Kick the Moon": "Patada a la luna",
	"Gainer Full": "Mortal atrás en carrera con tirabuzón", "Gainer 360": "Mortal atrás en carrera 360",
	"Kong Gainer": "Mortal atrás tras salto de gato", "Dash Gainer": "Mortal atrás tras dash",
	"Vault Gainer": "Mortal atrás tras pasavallas",
	# Corks
	"Cork": "Sacacorchos", "Corkscrew": "Sacacorchos", "Cork 540": "Sacacorchos 540",
	"Cork 720": "Sacacorchos 720", "Cork 1080": "Sacacorchos 1080",
	"Double Cork": "Doble sacacorchos", "Triple Cork": "Triple sacacorchos",
	# Laterales y aerials
	"Sideflip": "Mortal lateral", "Double Sideflip": "Doble mortal lateral",
	"Wall Sideflip": "Mortal lateral desde pared", "Raiz": "Raiz (lateral con medio giro)",
	"Touchdown Raiz": "Raiz con mano al suelo",
	"Aerial": "Rueda sin manos", "Double Aerial": "Doble rueda sin manos",
	"Aerial Twist": "Rueda sin manos con tirabuzón", "Aerial Double Twist": "Rueda sin manos con doble tirabuzón",
	# Patadas
	"Butterfly Kick": "Patada mariposa", "Double Butterfly": "Doble patada mariposa",
	"Butterfly Twist": "Mariposa con tirabuzón", "Butterfly Twist 720": "Mariposa con tirabuzón 720",
	"360 Kick": "Patada 360", "Tornado Kick": "Patada tornado", "540 Kick": "Patada 540",
	"Cheat 720": "Patada 720 cruzada", "720 Kick": "Patada 720", "900 Kick": "Patada 900",
	"1080 Kick": "Patada 1080", "Axe Kick Aerial": "Rueda sin manos con patada hacha", "Frisbee": "Frisbee",
	# Suelo
	"Cartwheel": "Rueda", "Cartwheel Twist": "Rueda con giro", "Round-off": "Rondada",
	"One Arm Round-off": "Rondada a una mano",
	"Back Handspring": "Flic-flac", "Back Handspring Full": "Flic-flac con tirabuzón",
	"Back Handspring Twist": "Flic-flac con giro", "Front Handspring": "Paloma",
	"Side Handspring": "Paloma lateral", "Kip-up": "Kip-up (levantarse de un salto)",
	"Macaco": "Macaco", "Handstand": "Pino", "Scoot": "Scoot", "Gumbi": "Gumbi",
	# Vaults (pasavallas)
	"Step Vault": "Paso con pie", "Safety Vault": "Paso de seguridad", "Speed Vault": "Paso rápido",
	"Lazy Vault": "Paso perezoso", "Kong Vault": "Salto de gato", "Monkey": "Mono", "Cat Pass": "Paso de gato",
	"Dash Vault": "Dash (pies primero)", "Double Kong": "Doble salto de gato",
	"Kash Vault": "Gato + dash", "Reverse Vault": "Paso invertido", "360 Vault": "Paso 360",
	"Step Up": "Subida de muro", "Thief Vault": "Paso de ladrón", "Turn Vault": "Paso con giro",
	"Gate Vault": "Paso de valla", "Dive Kong": "Salto de gato en plancha",
	"Kong Front": "Mortal adelante tras salto de gato", "Dash Bomb": "Mortal adelante tras dash",
	"360 Kong": "Salto de gato 360", "Screwdriver": "Destornillador",
	# Precisión, paredes y escalada
	"Precision Jump": "Salto de precisión", "Running Precision": "Precisión en carrera",
	"Stride": "Zancada", "Plyo": "Salto pliométrico",
	"Wall Run": "Carrera por pared", "Tic Tac": "Tic tac", "Wall Jump": "Salto de pared",
	"Wall Kick": "Impulso en pared", "Wall Climb": "Subida de pared", "Climb Up": "Subida",
	"Wall Flip": "Mortal desde pared", "Wall Gainer": "Mortal atrás desde pared en carrera",
	"Wall Front": "Mortal adelante desde pared", "Wall Half": "Mortal de pared con medio giro",
	"Wall Full": "Mortal de pared con tirabuzón", "Wall Flip 180": "Mortal de pared 180",
	"Wall Spin": "Giro en pared", "Palm Flip": "Mortal de palma",
	"Cat Leap": "Salto de brazo", "Cat Leap 180": "Salto de brazo 180", "Ledge Grab": "Agarre de borde",
	"Mantle": "Subida de borde", "Drop": "Soltarse",
	"Hyper": "Híper", "Hyper (¼ de giro en cualquier mortal)": "Híper (¼ de giro en cualquier mortal)",
	"Ledge Grab y Shimmy": "Agarre de borde y desplazamiento lateral", "Wall Jump desde borde": "Salto de pared desde borde",
	# Barras
	"Underbar": "Paso bajo barra", "Bar Swing": "Balanceo en barra", "Kickstart": "Impulso de piernas",
	"Muscle Up": "Dominada con subida", "Lache": "Lache (soltar y agarrar)", "Fly Away": "Salida en mortal",
	"Bar Gainer": "Mortal atrás desde barra",
	# Rolls y recepciones
	"Roll": "Voltereta", "Parkour Roll": "Voltereta de parkour", "Safety Roll": "Voltereta de seguridad",
	"Drop Landing": "Recepción de caída", "Hard Landing": "Recepción dura", "Dive Roll": "Voltereta en plancha",
	"Barrel Roll": "Voltereta de barril", "Side Roll": "Voltereta lateral", "Back Roll": "Voltereta atrás",
	"Palm Spin Gainer": "Mortal atrás con giro de palma", "Cast Gainer": "Mortal atrás lanzado",
	# Gimnasia, tricking y enlaces de potencia
	"Front Walkover": "Paso adelante (walkover)", "Back Walkover": "Paso atrás (walkover)",
	"Valdez": "Valdez", "Back Extension Roll": "Voltereta atrás al pino", "Handstand Push-off": "Bajada del pino con rebote",
	"Aerial Cartwheel": "Rueda sin manos", "Hook Kick": "Patada de gancho", "Crescent Kick": "Patada creciente",
	"Reverse Crescent Kick": "Patada creciente inversa", "Cheat 360 Kick": "Patada 360 con entrada",
	"B-Twist": "Mariposa con tirabuzón", "Swing Gainer": "Mortal atrás con barrido", "Master Scoot": "Master scoot",
	"Round-off Rebound": "Rebote de rondada", "Back Handspring Rebound": "Rebote de flic-flac",
	"Handstand Push-off Rebound": "Rebote tras bajar del pino", "Macaco Rebound": "Rebote de macaco",
	"Cartwheel Rebound": "Rebote de rueda", "Back Extension Roll Rebound": "Rebote de voltereta al pino",
	"Valdez Rebound": "Rebote de valdez", "Handstand (pino)": "Pino", "Handstand Push-off (snap down)": "Bajada del pino con rebote (snap down)",
	"Butterfly Twist / B-Twist": "Mariposa con tirabuzón (B-Twist)",
}

## Nombre en español de un movimiento (si no está en la lista, se deja tal cual).
static func es(name: String) -> String:
	# Cuartos de vuelta del joystick GIRO: "Backflip Hyper" (¼), "Back Half +¼" (¾)...
	if name.ends_with(" Hyper"):
		return es(name.trim_suffix(" Hyper")) + " híper (¼ de giro)"
	if name.ends_with(" +¼"):
		return es(name.trim_suffix(" +¼")) + " y ¼ de giro"
	return ES.get(name, name)

## Sustituye nombres sueltos dentro de una frase (instrucciones de la biblioteca).
const WORDS := [["Back Full", "mortal atrás con tirabuzón"], ["Front Full", "mortal adelante con tirabuzón"],
	["Dash Vault", "dash"], ["360 Kick", "patada 360"], ["Backflip", "mortal atrás"],
	["Frontflip", "mortal adelante"], ["Sideflip", "mortal lateral"], ["Gainer", "mortal atrás en carrera"],
	["Butterfly", "mariposa"], ["Aerial", "rueda sin manos"], ["aerial", "rueda sin manos"],
	["Cork", "sacacorchos"], ["Wall flip", "mortal desde pared"], ["wall run", "carrera por pared"],
	["Wall run", "carrera por pared"], ["wall climb", "subida de pared"], ["Kong", "gato"], ["kong", "gato"],
	["Dash", "dash"]]

static func es_phrase(text: String) -> String:
	for w in WORDS:
		text = text.replace(w[0], w[1])
	return text

## Traduce textos compuestos de la biblioteca ("Backflip / Back Tuck", "A → B", "A · B").
## Lo que va entre paréntesis ya está en español y se conserva.
static func es_text(text: String) -> String:
	var paren := ""
	var p := text.find(" (")
	if p >= 0 and text.ends_with(")"):
		paren = text.substr(p)
		text = text.substr(0, p)
		if es(text) != text:
			paren = ""                 # el paréntesis era la explicación en español
	for sep in [" → ", " / ", " · ", " + "]:
		if text.contains(sep):
			var parts := text.split(sep)
			var out := PackedStringArray()
			for part in parts:
				out.append(es_text(part))
			return sep.join(out) + paren
	return es(text) + paren
