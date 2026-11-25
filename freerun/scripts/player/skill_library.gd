class_name SkillLibrary
extends RefCounted
## Habilidades de suelo con apoyo (gimnasia y tricking): rondada, flic-flac, rueda, macaco,
## kip-up, pino, snap down, hook, raiz y touchdown raiz.
##
## Cada habilidad es una secuencia de FASES con nombre (entrada, apoyo de manos, bloqueo,
## vuelo, recepción...). Para cada instante se define la orientación del cuerpo, la altura
## del centro de masas, la forma corporal y qué manos/pies están apoyados. El BodyRig fija
## las manos apoyadas en un punto del suelo (IK de dos huesos) mientras el cuerpo gira por
## encima: el apoyo es real, no una rotación del muñeco en el aire.
##
## Parámetros de potencia (por habilidad):
##   travel     dirección de desplazamiento local (x lateral, y adelante)
##   keep       fracción de la velocidad de entrada (en esa dirección) que conserva
##   leg / arm  impulso de piernas (m/s horizontal) y bloqueo de brazos (m/s vertical)
##   vmin/vmax  velocidad de desplazamiento mínima y máxima de la técnica
##   conv       fracción de la velocidad horizontal que el bloqueo convierte en vertical
##   rebound    elasticidad de la recepción (rebote disponible para el siguiente movimiento)
##   land_drop  caída del centro de masas en la recepción (m) → velocidad de recepción
##   stability  estabilidad de la recepción (0..1): alarga la ventana de enlace
##   exit_yaw   giro horizontal al terminar (rondada y raiz: media vuelta)
##   link_at    fase en la que los pies ya reciben: desde aquí se puede enlazar

const G := 22.0

# ------------------------------------------------------------------ poses
# Convenciones del rig: hombro x+ = brazo adelante/arriba (3 = por encima de la cabeza),
# cadera x+ = pierna adelante, rodilla x- = flexión, columna x+ = arqueo atrás.
# En las poses asimétricas la pierna/mano "activa" es la derecha (lado +1); el lado -1 se
# obtiene por espejo.
const POSES := {
	"stand": {"shoulder_l": Vector3(0, 0, -0.12), "shoulder_r": Vector3(0, 0, 0.12), "elbow_l": Vector3(0.15, 0, 0),
		"elbow_r": Vector3(0.15, 0, 0), "hip_l": Vector3(0.05, 0, 0), "hip_r": Vector3(0.05, 0, 0),
		"knee_l": Vector3(-0.08, 0, 0), "knee_r": Vector3(-0.08, 0, 0)},
	"arms_up": {"shoulder_l": Vector3(2.95, 0, -0.15), "shoulder_r": Vector3(2.95, 0, 0.15), "spine": Vector3(0.12, 0, 0),
		"neck": Vector3(0.2, 0, 0), "hip_l": Vector3(0.05, 0, 0), "hip_r": Vector3(0.05, 0, 0)},
	# Zancada de entrada: pierna delantera flexionada, tronco cayendo, brazos arriba
	"lunge": {"spine": Vector3(-0.5, 0, 0), "neck": Vector3(0.3, 0, 0), "shoulder_l": Vector3(2.9, 0, -0.15),
		"shoulder_r": Vector3(2.9, 0, 0.15), "elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
		"hip_r": Vector3(0.95, 0, 0), "knee_r": Vector3(-1.0, 0, 0), "hip_l": Vector3(-0.45, 0, 0), "knee_l": Vector3(-0.05, 0, 0)},
	"lunge_side": {"spine": Vector3(-0.2, 0, 0.35), "neck": Vector3(0.2, 0, 0.2), "shoulder_l": Vector3(2.95, 0, -0.2),
		"shoulder_r": Vector3(2.95, 0, 0.2), "hip_r": Vector3(0.1, 0, 0.55), "knee_r": Vector3(-0.8, 0, 0),
		"hip_l": Vector3(0.0, 0, -0.25), "knee_l": Vector3(-0.05, 0, 0)},
	# Manos al suelo: brazos estirados por encima de la cabeza, cabeza entre los brazos
	"reach": {"spine": Vector3(-0.15, 0, 0), "neck": Vector3(0.35, 0, 0), "shoulder_l": Vector3(3.0, 0, -0.15),
		"shoulder_r": Vector3(3.0, 0, 0.15), "elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
		"hip_r": Vector3(0.3, 0, 0), "knee_r": Vector3(-0.2, 0, 0), "hip_l": Vector3(-1.0, 0, 0), "knee_l": Vector3(-0.05, 0, 0)},
	"straddle": {"neck": Vector3(0.3, 0, 0), "shoulder_l": Vector3(3.05, 0, -0.25), "shoulder_r": Vector3(3.05, 0, 0.25),
		"elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0), "hip_l": Vector3(0.05, 0, -1.15),
		"hip_r": Vector3(0.05, 0, 1.15), "knee_l": Vector3(-0.05, 0, 0), "knee_r": Vector3(-0.05, 0, 0)},
	"stand_wide": {"shoulder_l": Vector3(2.4, 0, -0.6), "shoulder_r": Vector3(2.4, 0, 0.6), "hip_l": Vector3(0.0, 0, -0.45),
		"hip_r": Vector3(0.1, 0, 0.35), "knee_l": Vector3(-0.15, 0, 0), "knee_r": Vector3(-0.35, 0, 0)},
	# Pino: cuerpo recto y bloqueado, hombros abiertos, piernas juntas
	"hollow": {"spine": Vector3(-0.05, 0, 0), "neck": Vector3(0.45, 0, 0), "shoulder_l": Vector3(3.08, 0, -0.12),
		"shoulder_r": Vector3(3.08, 0, 0.12), "elbow_l": Vector3(0.0, 0, 0), "elbow_r": Vector3(0.0, 0, 0),
		"hip_l": Vector3(0.0, 0, -0.03), "hip_r": Vector3(0.0, 0, 0.03), "knee_l": Vector3(0.0, 0, 0), "knee_r": Vector3(0.0, 0, 0)},
	"handstand_kick": {"spine": Vector3(-0.2, 0, 0), "neck": Vector3(0.4, 0, 0), "shoulder_l": Vector3(3.05, 0, -0.12),
		"shoulder_r": Vector3(3.05, 0, 0.12), "hip_l": Vector3(-1.3, 0, 0), "knee_l": Vector3(-0.05, 0, 0),
		"hip_r": Vector3(0.55, 0, 0), "knee_r": Vector3(-0.35, 0, 0)},
	# Split invertido (walkovers, valdez): una pierna pasa delante, la otra detrás
	"split": {"spine": Vector3(0.35, 0, 0), "neck": Vector3(0.5, 0, 0), "shoulder_l": Vector3(3.05, 0, -0.12),
		"shoulder_r": Vector3(3.05, 0, 0.12), "hip_r": Vector3(1.35, 0, 0), "knee_r": Vector3(-0.05, 0, 0),
		"hip_l": Vector3(-1.25, 0, 0), "knee_l": Vector3(-0.05, 0, 0)},
	"split_down": {"spine": Vector3(0.6, 0, 0), "neck": Vector3(0.5, 0, 0), "shoulder_l": Vector3(2.9, 0, -0.15),
		"shoulder_r": Vector3(2.9, 0, 0.15), "hip_r": Vector3(1.6, 0, 0), "knee_r": Vector3(-0.35, 0, 0),
		"hip_l": Vector3(-0.8, 0, 0), "knee_l": Vector3(-0.05, 0, 0)},
	"step_down": {"spine": Vector3(0.25, 0, 0), "neck": Vector3(0.2, 0, 0), "shoulder_l": Vector3(2.7, 0, -0.2),
		"shoulder_r": Vector3(2.7, 0, 0.2), "hip_r": Vector3(0.5, 0, 0), "knee_r": Vector3(-0.6, 0, 0),
		"hip_l": Vector3(-0.6, 0, 0), "knee_l": Vector3(-0.1, 0, 0)},
	# Flic-flac: sentarse con los brazos atrás (carga), extensión con brazos arriba, arco en vuelo
	"squat_swing": {"spine": Vector3(-0.35, 0, 0), "neck": Vector3(0.1, 0, 0), "shoulder_l": Vector3(-0.95, 0, -0.15),
		"shoulder_r": Vector3(-0.95, 0, 0.15), "elbow_l": Vector3(0.2, 0, 0), "elbow_r": Vector3(0.2, 0, 0),
		"hip_l": Vector3(1.25, 0, -0.06), "hip_r": Vector3(1.2, 0, 0.06), "knee_l": Vector3(-1.7, 0, 0), "knee_r": Vector3(-1.65, 0, 0)},
	"arch_takeoff": {"spine": Vector3(0.45, 0, 0), "neck": Vector3(0.55, 0, 0), "shoulder_l": Vector3(3.0, 0, -0.2),
		"shoulder_r": Vector3(3.0, 0, 0.2), "elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
		"hip_l": Vector3(-0.15, 0, 0), "hip_r": Vector3(-0.15, 0, 0), "knee_l": Vector3(-0.2, 0, 0), "knee_r": Vector3(-0.2, 0, 0)},
	"arch": {"spine": Vector3(0.8, 0, 0), "neck": Vector3(0.75, 0, 0), "shoulder_l": Vector3(3.05, 0, -0.18),
		"shoulder_r": Vector3(3.05, 0, 0.18), "elbow_l": Vector3(0.05, 0, 0), "elbow_r": Vector3(0.05, 0, 0),
		"hip_l": Vector3(-0.45, 0, -0.04), "hip_r": Vector3(-0.45, 0, 0.04), "knee_l": Vector3(-0.15, 0, 0), "knee_r": Vector3(-0.15, 0, 0)},
	# Bloqueo de hombros y "snap": la cadera carpa y las piernas bajan juntas y rápido al suelo
	"snap": {"spine": Vector3(-0.4, 0, 0), "neck": Vector3(0.2, 0, 0), "shoulder_l": Vector3(2.85, 0, -0.15),
		"shoulder_r": Vector3(2.85, 0, 0.15), "elbow_l": Vector3(0.0, 0, 0), "elbow_r": Vector3(0.0, 0, 0),
		"hip_l": Vector3(0.75, 0, -0.03), "hip_r": Vector3(0.75, 0, 0.03), "knee_l": Vector3(-0.15, 0, 0), "knee_r": Vector3(-0.15, 0, 0)},
	"push_arms": {"spine": Vector3(-0.15, 0, 0), "neck": Vector3(0.35, 0, 0), "shoulder_l": Vector3(2.7, 0, -0.15),
		"shoulder_r": Vector3(2.7, 0, 0.15), "hip_l": Vector3(0.3, 0, 0), "hip_r": Vector3(0.3, 0, 0)},
	"arch_fhs": {"spine": Vector3(0.5, 0, 0), "neck": Vector3(0.6, 0, 0), "shoulder_l": Vector3(3.05, 0, -0.18),
		"shoulder_r": Vector3(3.05, 0, 0.18), "hip_l": Vector3(-0.4, 0, 0), "hip_r": Vector3(-0.2, 0, 0),
		"knee_l": Vector3(-0.1, 0, 0), "knee_r": Vector3(-0.15, 0, 0)},
	# Recepción con rebote: piernas flexionadas absorbiendo, brazos arriba listos para el siguiente
	"land": {"spine": Vector3(-0.25, 0, 0), "neck": Vector3(0.15, 0, 0), "shoulder_l": Vector3(2.5, 0, -0.25),
		"shoulder_r": Vector3(2.5, 0, 0.25), "elbow_l": Vector3(0.1, 0, 0), "elbow_r": Vector3(0.1, 0, 0),
		"hip_l": Vector3(0.75, 0, -0.06), "hip_r": Vector3(0.75, 0, 0.06), "knee_l": Vector3(-1.1, 0, 0), "knee_r": Vector3(-1.1, 0, 0)},
	"land_rebound": {"spine": Vector3(-0.1, 0, 0), "neck": Vector3(0.2, 0, 0), "shoulder_l": Vector3(2.9, 0, -0.2),
		"shoulder_r": Vector3(2.9, 0, 0.2), "hip_l": Vector3(0.35, 0, -0.04), "hip_r": Vector3(0.35, 0, 0.04),
		"knee_l": Vector3(-0.5, 0, 0), "knee_r": Vector3(-0.5, 0, 0)},
	# A un pie: la pierna de apoyo flexionada bajo el cuerpo y la libre claramente en el aire
	# (rodilla delante y talón arriba), brazos abiertos para equilibrar
	"land_one": {"spine": Vector3(-0.32, 0, 0), "shoulder_l": Vector3(1.1, 0, -1.1), "shoulder_r": Vector3(0.9, 0, 1.2),
		"elbow_l": Vector3(0.45, 0, 0), "elbow_r": Vector3(0.45, 0, 0), "hip_r": Vector3(0.95, 0, 0.08),
		"knee_r": Vector3(-1.95, 0, 0), "hip_l": Vector3(0.4, 0, -0.04), "knee_l": Vector3(-0.7, 0, 0)},
	"land_low": {"spine": Vector3(-0.4, 0, 0), "shoulder_l": Vector3(1.2, 0, -0.5), "shoulder_r": Vector3(1.0, 0, 0.5),
		"hip_l": Vector3(1.3, 0, -0.1), "hip_r": Vector3(1.2, 0, 0.1), "knee_l": Vector3(-1.9, 0, 0), "knee_r": Vector3(-1.8, 0, 0)},
	# Macaco: muy bajo, mano derecha atrás al suelo, tronco girado hacia ella
	"crouch_hand_back": {"spine": Vector3(-0.35, -0.45, 0), "neck": Vector3(0.1, -0.3, 0), "shoulder_r": Vector3(-1.35, 0, 0.35),
		"elbow_r": Vector3(0.1, 0, 0), "shoulder_l": Vector3(1.1, 0, -0.3), "elbow_l": Vector3(0.9, 0, 0),
		"hip_l": Vector3(1.75, 0, -0.15), "hip_r": Vector3(1.6, 0, 0.15), "knee_l": Vector3(-2.3, 0, 0), "knee_r": Vector3(-2.2, 0, 0)},
	"macaco_push": {"spine": Vector3(0.4, -0.35, 0), "neck": Vector3(0.6, -0.2, 0), "shoulder_r": Vector3(-2.2, 0, 0.2),
		"elbow_r": Vector3(0.0, 0, 0), "shoulder_l": Vector3(2.4, 0, -0.9), "elbow_l": Vector3(0.3, 0, 0),
		"hip_l": Vector3(0.9, 0, -0.2), "knee_l": Vector3(-0.4, 0, 0), "hip_r": Vector3(0.2, 0, 0.1), "knee_r": Vector3(-1.4, 0, 0)},
	"macaco_arc": {"spine": Vector3(0.85, -0.25, 0), "neck": Vector3(0.65, 0, 0), "shoulder_r": Vector3(2.95, 0, 0.15),
		"elbow_r": Vector3(0.0, 0, 0), "shoulder_l": Vector3(2.3, 0, -1.1), "elbow_l": Vector3(0.3, 0, 0),
		"hip_l": Vector3(1.35, 0, -0.3), "knee_l": Vector3(-0.35, 0, 0), "hip_r": Vector3(-0.35, 0, 0.1), "knee_r": Vector3(-0.3, 0, 0)},
	# Puente (back walkover) y patada por encima
	"bridge": {"spine": Vector3(1.15, 0, 0), "neck": Vector3(0.85, 0, 0), "shoulder_l": Vector3(3.05, 0, -0.15),
		"shoulder_r": Vector3(3.05, 0, 0.15), "hip_l": Vector3(-0.55, 0, 0), "knee_l": Vector3(-0.7, 0, 0),
		"hip_r": Vector3(-0.2, 0, 0), "knee_r": Vector3(-0.25, 0, 0)},
	"bridge_lean": {"spine": Vector3(0.95, 0, 0), "neck": Vector3(0.75, 0, 0), "shoulder_l": Vector3(3.05, 0, -0.15),
		"shoulder_r": Vector3(3.05, 0, 0.15), "hip_l": Vector3(-0.4, 0, 0), "knee_l": Vector3(-0.6, 0, 0),
		"hip_r": Vector3(0.5, 0, 0), "knee_r": Vector3(-0.05, 0, 0)},
	"kick_over": {"spine": Vector3(0.9, 0, 0), "neck": Vector3(0.7, 0, 0), "shoulder_l": Vector3(3.05, 0, -0.15),
		"shoulder_r": Vector3(3.05, 0, 0.15), "hip_r": Vector3(1.7, 0, 0), "knee_r": Vector3(-0.05, 0, 0),
		"hip_l": Vector3(-0.35, 0, 0), "knee_l": Vector3(-0.45, 0, 0)},
	# Valdez: sentado, mano derecha atrás, pierna izquierda doblada empuja, la derecha estirada
	"sit": {"spine": Vector3(-0.15, -0.2, 0), "neck": Vector3(0.1, 0, 0), "shoulder_r": Vector3(-1.3, 0, 0.3),
		"elbow_r": Vector3(0.0, 0, 0), "shoulder_l": Vector3(1.5, 0, -0.2), "elbow_l": Vector3(0.2, 0, 0),
		"hip_r": Vector3(1.45, 0, 0.05), "knee_r": Vector3(-0.1, 0, 0), "hip_l": Vector3(1.9, 0, -0.1), "knee_l": Vector3(-2.3, 0, 0)},
	"valdez_push": {"spine": Vector3(0.55, -0.15, 0), "neck": Vector3(0.6, 0, 0), "shoulder_r": Vector3(-2.4, 0, 0.2),
		"shoulder_l": Vector3(2.8, 0, -0.3), "hip_r": Vector3(1.9, 0, 0), "knee_r": Vector3(-0.05, 0, 0),
		"hip_l": Vector3(0.3, 0, 0), "knee_l": Vector3(-1.2, 0, 0)},
	# Volteretas y kip-up
	"squat": {"spine": Vector3(-0.5, 0, 0), "neck": Vector3(-0.2, 0, 0), "shoulder_l": Vector3(1.6, 0, -0.2),
		"shoulder_r": Vector3(1.6, 0, 0.2), "elbow_l": Vector3(0.8, 0, 0), "elbow_r": Vector3(0.8, 0, 0),
		"hip_l": Vector3(1.9, 0, -0.1), "hip_r": Vector3(1.9, 0, 0.1), "knee_l": Vector3(-2.4, 0, 0), "knee_r": Vector3(-2.4, 0, 0)},
	"roll_tuck": {"spine": Vector3(-0.85, 0, 0), "neck": Vector3(-0.5, 0, 0), "shoulder_l": Vector3(2.75, 0, -0.35),
		"shoulder_r": Vector3(2.75, 0, 0.35), "elbow_l": Vector3(2.0, 0, 0), "elbow_r": Vector3(2.0, 0, 0),
		"hip_l": Vector3(2.4, 0, -0.08), "hip_r": Vector3(2.4, 0, 0.08), "knee_l": Vector3(-2.5, 0, 0), "knee_r": Vector3(-2.5, 0, 0)},
	"pike_ext": {"spine": Vector3(-0.2, 0, 0), "neck": Vector3(0.3, 0, 0), "shoulder_l": Vector3(2.9, 0, -0.15),
		"shoulder_r": Vector3(2.9, 0, 0.15), "elbow_l": Vector3(0.6, 0, 0), "elbow_r": Vector3(0.6, 0, 0),
		"hip_l": Vector3(1.0, 0, 0), "hip_r": Vector3(1.0, 0, 0), "knee_l": Vector3(-0.1, 0, 0), "knee_r": Vector3(-0.1, 0, 0)},
	"lying": {"neck": Vector3(-0.2, 0, 0), "shoulder_l": Vector3(0.3, 0, -0.35), "shoulder_r": Vector3(0.3, 0, 0.35),
		"hip_l": Vector3(0.1, 0, -0.05), "hip_r": Vector3(0.1, 0, 0.05), "knee_l": Vector3(-0.2, 0, 0), "knee_r": Vector3(-0.15, 0, 0)},
	"kip_pike": {"spine": Vector3(-0.6, 0, 0), "neck": Vector3(-0.3, 0, 0), "shoulder_l": Vector3(2.9, 0, -0.35),
		"shoulder_r": Vector3(2.9, 0, 0.35), "elbow_l": Vector3(2.0, 0, 0), "elbow_r": Vector3(2.0, 0, 0),
		"hip_l": Vector3(2.35, 0, -0.05), "hip_r": Vector3(2.35, 0, 0.05), "knee_l": Vector3(-0.3, 0, 0), "knee_r": Vector3(-0.3, 0, 0)},
	"kip_kick": {"spine": Vector3(0.65, 0, 0), "neck": Vector3(0.4, 0, 0), "shoulder_l": Vector3(2.5, 0, -0.3),
		"shoulder_r": Vector3(2.5, 0, 0.3), "elbow_l": Vector3(0.4, 0, 0), "elbow_r": Vector3(0.4, 0, 0),
		"hip_l": Vector3(-0.15, 0, 0), "hip_r": Vector3(-0.15, 0, 0), "knee_l": Vector3(-0.8, 0, 0), "knee_r": Vector3(-0.8, 0, 0)},
	# Patadas (pierna derecha): guardia, recogida, extensión, gancho y crescents
	"guard": {"spine": Vector3(-0.1, 0, 0), "shoulder_l": Vector3(1.5, 0, -0.25), "shoulder_r": Vector3(1.4, 0, 0.25),
		"elbow_l": Vector3(2.1, 0, 0), "elbow_r": Vector3(2.1, 0, 0), "hip_l": Vector3(0.2, 0, 0), "hip_r": Vector3(0.15, 0, 0),
		"knee_l": Vector3(-0.35, 0, 0), "knee_r": Vector3(-0.3, 0, 0)},
	"hook_chamber": {"spine": Vector3(-0.1, 0, -0.35), "neck": Vector3(0, 0, 0.2), "shoulder_l": Vector3(1.4, 0, -0.35),
		"shoulder_r": Vector3(1.1, 0, 0.5), "elbow_l": Vector3(2.0, 0, 0), "elbow_r": Vector3(1.9, 0, 0),
		"hip_r": Vector3(1.35, 0, 0.95), "knee_r": Vector3(-2.1, 0, 0), "hip_l": Vector3(0.15, 0, 0), "knee_l": Vector3(-0.3, 0, 0)},
	"hook_ext": {"spine": Vector3(-0.2, 0, -0.6), "neck": Vector3(0, 0, 0.35), "shoulder_l": Vector3(1.2, 0, -0.6),
		"shoulder_r": Vector3(0.6, 0, 0.9), "elbow_l": Vector3(1.8, 0, 0), "elbow_r": Vector3(1.0, 0, 0),
		"hip_r": Vector3(1.45, 0, 1.35), "knee_r": Vector3(-0.08, 0, 0), "hip_l": Vector3(0.1, 0, 0), "knee_l": Vector3(-0.25, 0, 0)},
	"hook_hook": {"spine": Vector3(-0.15, 0, -0.5), "neck": Vector3(0, 0, 0.3), "shoulder_l": Vector3(1.3, 0, -0.5),
		"shoulder_r": Vector3(0.9, 0, 0.7), "elbow_l": Vector3(1.9, 0, 0), "elbow_r": Vector3(1.4, 0, 0),
		"hip_r": Vector3(1.1, 0, 1.05), "knee_r": Vector3(-1.95, 0, 0), "hip_l": Vector3(0.12, 0, 0), "knee_l": Vector3(-0.28, 0, 0)},
	"cresc_out": {"spine": Vector3(-0.15, -0.2, -0.4), "neck": Vector3(0, 0, 0.25), "shoulder_l": Vector3(1.0, 0, -1.25),
		"shoulder_r": Vector3(0.5, 0, 1.25), "elbow_l": Vector3(0.9, 0, 0), "elbow_r": Vector3(0.6, 0, 0), "hip_r": Vector3(1.5, 0, 1.4),
		"knee_r": Vector3(-0.05, 0, 0), "hip_l": Vector3(0.15, 0, 0), "knee_l": Vector3(-0.35, 0, 0)},
	"cresc_up": {"spine": Vector3(-0.45, 0, -0.1), "neck": Vector3(0.1, 0, 0), "shoulder_l": Vector3(0.9, 0, -1.2),
		"shoulder_r": Vector3(0.9, 0, 1.2), "elbow_l": Vector3(0.8, 0, 0), "elbow_r": Vector3(0.8, 0, 0), "hip_r": Vector3(2.4, 0, 0.2),
		"knee_r": Vector3(-0.03, 0, 0), "hip_l": Vector3(0.15, 0, 0), "knee_l": Vector3(-0.4, 0, 0)},
	"cresc_in": {"spine": Vector3(-0.25, 0.4, 0.2), "neck": Vector3(0, 0.2, 0), "shoulder_l": Vector3(0.7, 0, -1.35),
		"shoulder_r": Vector3(1.3, 0, 0.45), "elbow_l": Vector3(0.7, 0, 0), "elbow_r": Vector3(1.0, 0, 0), "hip_r": Vector3(1.5, 0, -0.8),
		"knee_r": Vector3(-0.1, 0, 0), "hip_l": Vector3(0.15, 0, 0), "knee_l": Vector3(-0.35, 0, 0)},
	# Raiz: paso en diagonal, barrido de brazos abajo, la pierna de atrás (derecha) patea arriba y
	# el cuerpo vuela tumbado y arqueado de lado
	"raiz_step": {"spine": Vector3(-0.35, 0.35, 0), "neck": Vector3(0.1, 0.2, 0), "shoulder_l": Vector3(1.8, 0, -0.9),
		"shoulder_r": Vector3(1.6, 0, 0.9), "elbow_l": Vector3(0.4, 0, 0), "elbow_r": Vector3(0.4, 0, 0),
		"hip_l": Vector3(0.6, 0, 0), "knee_l": Vector3(-0.7, 0, 0), "hip_r": Vector3(-0.3, 0, 0), "knee_r": Vector3(-0.1, 0, 0)},
	"raiz_swing": {"spine": Vector3(-0.85, 0.45, 0), "neck": Vector3(0.4, 0, 0), "shoulder_l": Vector3(-0.5, 0, -0.6),
		"shoulder_r": Vector3(-0.5, 0, 0.6), "elbow_l": Vector3(0.3, 0, 0), "elbow_r": Vector3(0.3, 0, 0),
		"hip_r": Vector3(-0.9, 0, 0.2), "knee_r": Vector3(-0.15, 0, 0), "hip_l": Vector3(0.5, 0, 0), "knee_l": Vector3(-0.6, 0, 0)},
	"raiz_layout": {"spine": Vector3(0.4, 0, 0), "neck": Vector3(0.45, 0, 0), "shoulder_l": Vector3(1.7, 0, -1.1),
		"shoulder_r": Vector3(1.7, 0, 1.1), "elbow_l": Vector3(0.3, 0, 0), "elbow_r": Vector3(0.3, 0, 0),
		"hip_r": Vector3(-1.15, 0, 0.35), "knee_r": Vector3(-0.1, 0, 0), "hip_l": Vector3(0.55, 0, -0.1), "knee_l": Vector3(-0.35, 0, 0)},
	"td_reach": {"spine": Vector3(0.3, 0, 0.3), "neck": Vector3(0.4, 0, 0.2), "shoulder_r": Vector3(2.95, 0, 0.3),
		"elbow_r": Vector3(0.05, 0, 0), "shoulder_l": Vector3(1.5, 0, -1.2), "elbow_l": Vector3(0.4, 0, 0),
		"hip_r": Vector3(-0.6, 0, 0.3), "knee_r": Vector3(-0.3, 0, 0), "hip_l": Vector3(1.0, 0, -0.1), "knee_l": Vector3(-0.6, 0, 0)},
	# Scoot: carga sobre la pierna izquierda, la derecha barre por delante a ras y salta de lado
	"scoot_load": {"spine": Vector3(-0.45, -0.3, 0), "neck": Vector3(0.2, 0, 0), "shoulder_l": Vector3(-0.4, 0, -0.5),
		"shoulder_r": Vector3(-0.6, 0, 0.6), "hip_l": Vector3(1.0, 0, 0), "knee_l": Vector3(-1.5, 0, 0),
		"hip_r": Vector3(0.3, 0, 0.5), "knee_r": Vector3(-0.2, 0, 0)},
	"scoot_sweep": {"spine": Vector3(-0.35, 0.45, 0.1), "neck": Vector3(0.1, 0.25, 0), "shoulder_l": Vector3(1.6, 0, -1.1),
		"shoulder_r": Vector3(2.0, 0, 0.7), "hip_r": Vector3(1.35, 0, -0.85), "knee_r": Vector3(-0.1, 0, 0),
		"hip_l": Vector3(0.8, 0, 0), "knee_l": Vector3(-1.1, 0, 0)},
	"scoot_air": {"spine": Vector3(-0.15, 0.3, 0.15), "neck": Vector3(0.1, 0.2, 0), "shoulder_l": Vector3(2.6, 0, -0.5),
		"shoulder_r": Vector3(2.6, 0, 0.5), "elbow_l": Vector3(0.2, 0, 0), "elbow_r": Vector3(0.2, 0, 0),
		"hip_r": Vector3(1.15, 0, -0.35), "knee_r": Vector3(-0.3, 0, 0), "hip_l": Vector3(-0.45, 0, 0.1), "knee_l": Vector3(-1.3, 0, 0)},
	# Entrada de cork: zancadas de carrera, carga de la pierna de patada y patada "al balón"
	"stride_r": {"spine": Vector3(-0.25, 0.15, 0), "neck": Vector3(0.15, -0.1, 0), "shoulder_l": Vector3(0.8, 0, -0.15),
		"shoulder_r": Vector3(-0.6, 0, 0.15), "elbow_l": Vector3(1.3, 0, 0), "elbow_r": Vector3(1.1, 0, 0),
		"hip_r": Vector3(0.75, 0, 0), "knee_r": Vector3(-0.35, 0, 0), "hip_l": Vector3(-0.5, 0, 0), "knee_l": Vector3(-0.7, 0, 0)},
	"stride_l": {"spine": Vector3(-0.25, -0.15, 0), "neck": Vector3(0.15, 0.1, 0), "shoulder_r": Vector3(0.8, 0, 0.15),
		"shoulder_l": Vector3(-0.6, 0, -0.15), "elbow_l": Vector3(1.1, 0, 0), "elbow_r": Vector3(1.3, 0, 0),
		"hip_l": Vector3(0.75, 0, 0), "knee_l": Vector3(-0.35, 0, 0), "hip_r": Vector3(-0.5, 0, 0), "knee_r": Vector3(-0.7, 0, 0)},
	"kick_load": {"spine": Vector3(-0.35, 0.4, 0.05), "neck": Vector3(0.2, -0.2, 0), "shoulder_l": Vector3(-0.7, 0, -0.4),
		"shoulder_r": Vector3(1.1, 0, 0.5), "elbow_l": Vector3(0.6, 0, 0), "elbow_r": Vector3(0.8, 0, 0),
		"hip_l": Vector3(0.55, 0, 0), "knee_l": Vector3(-1.0, 0, 0), "hip_r": Vector3(-0.95, 0, 0.1), "knee_r": Vector3(-1.35, 0, 0)},
	# Cork quieto: pierna de impulso delante y flexionada, la de patada atrás de puntillas y
	# brazos cargados atrás; luego patada arriba en diagonal por delante del cuerpo y brazos arriba.
	"cork_set": {"spine": Vector3(-0.3, 0.35, 0), "neck": Vector3(0.15, -0.15, 0), "shoulder_l": Vector3(-0.95, 0, -0.35),
		"shoulder_r": Vector3(-0.85, 0, 0.35), "elbow_l": Vector3(0.35, 0, 0), "elbow_r": Vector3(0.35, 0, 0),
		"hip_l": Vector3(0.65, 0, -0.05), "knee_l": Vector3(-0.95, 0, 0), "hip_r": Vector3(-0.45, 0, 0.08), "knee_r": Vector3(-0.4, 0, 0)},
	"cork_swing": {"spine": Vector3(0.25, -0.2, 0), "neck": Vector3(0.35, 0.1, 0), "shoulder_l": Vector3(2.9, 0, -0.25),
		"shoulder_r": Vector3(2.8, 0, 0.3), "elbow_l": Vector3(0.1, 0, 0), "elbow_r": Vector3(0.15, 0, 0),
		"hip_l": Vector3(-0.05, 0, 0), "knee_l": Vector3(-0.05, 0, 0), "hip_r": Vector3(2.05, 0, -0.3), "knee_r": Vector3(-0.1, 0, 0)},
	"football_kick": {"spine": Vector3(0.3, -0.35, 0), "neck": Vector3(0.35, 0.15, 0), "shoulder_l": Vector3(2.6, 0, -0.6),
		"shoulder_r": Vector3(1.7, 0, 0.9), "elbow_l": Vector3(0.3, 0, 0), "elbow_r": Vector3(0.5, 0, 0),
		"hip_l": Vector3(0.2, 0, 0), "knee_l": Vector3(-0.45, 0, 0), "hip_r": Vector3(1.8, 0, -0.15), "knee_r": Vector3(-0.15, 0, 0)},
}

const SWAP := {"shoulder_l": "shoulder_r", "shoulder_r": "shoulder_l", "elbow_l": "elbow_r", "elbow_r": "elbow_l",
	"hip_l": "hip_r", "hip_r": "hip_l", "knee_l": "knee_r", "knee_r": "knee_l"}

# ------------------------------------------------------------------ habilidades
# keys: [t, pitch(+atrás), roll(+cabeza a la derecha), yaw, twist(eje largo), com(m), pose, vel(0..1), fase]
# contacts: hl/hr manos, fl/fr pies: listas de intervalos [desde, hasta] en tiempo normalizado.
const SKILLS := {
	"roundoff": {"name": "Round-off", "dur": 0.84, "travel": Vector2(0, 1), "keep": 0.8, "leg": 0.6, "arm": 1.2,
		"vmin": 2.6, "vmax": 8.0, "conv": 0.09, "rebound": 0.22, "land_drop": 0.45, "stability": 0.85,
		"exit_yaw": PI, "link_at": 0.84, "window": 0.38, "difficulty": 0.8, "chain_start": 0.0,
		"rot": "360° adelante con medio giro (eje largo)",
		"keys": [[0.0, 0, 0, 0, 0, 0.95, "stand", 1.0, "carrera"],
			[0.14, -0.45, 0, 0, 0, 0.84, "lunge", 1.0, "zancada"],
			[0.29, -1.7, 0, 0, 0.5, 0.9, "reach", 0.9, "apoyo de manos"],
			[0.42, -2.6, 0, 0, 1.25, 1.08, "straddle", 0.8, "inversión"],
			[0.52, -3.25, 0, 0, 1.8, 1.16, "hollow", 0.75, "piernas juntas"],
			[0.64, -4.25, 0, 0, 2.55, 1.04, "snap", 0.72, "bloqueo"],
			[0.76, -5.4, 0, 0, 3.05, 0.86, "snap", 0.66, "vuelo"],
			[0.86, -6.283, 0, 0, 3.1416, 0.74, "land", 0.6, "recepción"],
			[1.0, -6.283, 0, 0, 3.1416, 0.8, "land_rebound", 0.55, "rebote"]],
		"contacts": {"hl": [[0.27, 0.5]], "hr": [[0.36, 0.6]], "fl": [[0.0, 0.12], [0.86, 1.0]], "fr": [[0.0, 0.2], [0.86, 1.0]]}},
	"bhs": {"name": "Back Handspring", "dur": 0.76, "travel": Vector2(0, -1), "keep": 0.95, "leg": 0.8, "arm": 1.6,
		"vmin": 3.0, "vmax": 7.0, "conv": 0.05, "rebound": 0.25, "land_drop": 0.45, "stability": 0.8,
		"exit_yaw": 0.0, "link_at": 0.84, "window": 0.36, "difficulty": 0.9, "chain_start": 0.16,
		"rot": "360° atrás con fase de manos",
		"keys": [[0.0, 0, 0, 0, 0, 0.95, "stand", 0.0, "preparación"],
			[0.11, 0.2, 0, 0, 0, 0.62, "squat_swing", 0.25, "flexión y brazos atrás"],
			[0.27, 0.95, 0, 0, 0, 0.86, "arch_takeoff", 1.0, "impulso atrás (los brazos pasan por delante)"],
			[0.38, 2.25, 0, 0, 0, 1.0, "arch", 1.0, "arqueo en vuelo"],
			[0.47, 3.05, 0, 0, 0, 1.14, "hollow", 0.9, "apoyo de manos"],
			[0.58, 4.0, 0, 0, 0, 1.02, "snap", 0.85, "bloqueo de hombros"],
			[0.72, 5.4, 0, 0, 0, 0.86, "snap", 0.8, "paso de piernas"],
			[0.84, 6.283, 0, 0, 0, 0.74, "land", 0.7, "recepción"],
			[1.0, 6.283, 0, 0, 0, 0.82, "land_rebound", 0.65, "extensión"]],
		"contacts": {"hl": [[0.42, 0.62]], "hr": [[0.42, 0.62]], "fl": [[0.0, 0.27], [0.84, 1.0]], "fr": [[0.0, 0.27], [0.84, 1.0]]}},
	"cartwheel": {"name": "Cartwheel", "dur": 1.02, "travel": Vector2(1, 0), "keep": 0.35, "leg": 2.6, "arm": 0.5,
		"vmin": 2.4, "vmax": 4.5, "conv": 0.0, "rebound": 0.12, "land_drop": 0.15, "stability": 0.75,
		"exit_yaw": 0.0, "link_at": 0.86, "window": 0.3, "difficulty": 0.5, "chain_start": 0.0,
		"rot": "360° lateral (plano frontal)",
		"keys": [[0.0, 0, 0, 0, 0, 0.95, "stand", 0.6, "entrada"],
			[0.15, -0.15, 0.35, 0, 0, 0.86, "lunge_side", 0.9, "paso lateral"],
			[0.32, 0, 1.5, 0, 0, 0.92, "straddle", 1.0, "primera mano"],
			[0.5, 0, 3.1416, 0, 0, 1.13, "straddle", 1.0, "inversión en straddle"],
			[0.68, 0, 4.75, 0, 0, 0.95, "straddle", 1.0, "segunda mano"],
			[0.86, 0, 6.0, 0, 0, 0.88, "stand_wide", 0.7, "primer pie"],
			[1.0, 0, 6.283, 0, 0, 0.95, "stand", 0.4, "de pie"]],
		"contacts": {"hr": [[0.29, 0.5]], "hl": [[0.46, 0.7]], "fl": [[0.0, 0.18], [0.92, 1.0]], "fr": [[0.0, 0.12], [0.82, 1.0]]}},
	"macaco": {"name": "Macaco", "dur": 0.9, "travel": Vector2(0.3, -1), "keep": 0.3, "leg": 2.4, "arm": 1.0,
		"vmin": 2.0, "vmax": 4.0, "conv": 0.0, "rebound": 0.15, "land_drop": 0.3, "stability": 0.6,
		"exit_yaw": 0.0, "link_at": 0.86, "window": 0.3, "difficulty": 1.0, "chain_start": 0.0,
		"rot": "360° atrás por encima del brazo de apoyo",
		"keys": [[0.0, 0, 0, 0, 0, 0.95, "stand", 0.0, "de pie"],
			[0.2, -0.15, 0, 0.35, 0, 0.5, "crouch_hand_back", 0.1, "posición baja"],
			[0.34, 0.6, 0.25, 0.3, 0, 0.55, "macaco_push", 0.6, "mano atrás e impulso de cadera"],
			[0.5, 1.75, 0.65, 0.2, 0, 0.86, "macaco_arc", 1.0, "arqueo"],
			[0.62, 3.14, 0.8, 0.1, 0, 1.06, "macaco_arc", 1.0, "por encima del brazo"],
			[0.76, 4.6, 0.5, 0.05, 0, 0.92, "split_down", 0.8, "pierna busca el suelo"],
			[0.88, 6.0, 0.1, 0, 0, 0.72, "land_low", 0.4, "recepción"],
			[1.0, 6.283, 0, 0, 0, 0.88, "stand", 0.2, "recuperación"]],
		"contacts": {"hr": [[0.28, 0.72]], "fl": [[0.0, 0.42], [0.86, 1.0]], "fr": [[0.0, 0.38], [0.8, 1.0]]}},
	"kipup": {"name": "Kip-up", "dur": 0.85, "travel": Vector2(0, 1), "keep": 0.0, "leg": 0.5, "arm": 1.0,
		"vmin": 0.0, "vmax": 1.0, "conv": 0.0, "rebound": 0.05, "land_drop": 0.3, "stability": 0.7,
		"exit_yaw": 0.0, "link_at": 0.88, "window": 0.25, "difficulty": 0.6, "chain_start": 0.0,
		"rot": "de tumbado a de pie con golpe de riñones",
		"keys": [[0.0, 1.57, 0, 0, 0, 0.18, "lying", 0.0, "tumbado"],
			[0.26, 2.55, 0, 0, 0, 0.28, "kip_pike", 0.0, "piernas por encima, manos al suelo"],
			[0.42, 1.25, 0, 0, 0, 0.62, "kip_kick", 0.5, "golpe de piernas y empuje"],
			[0.58, 0.35, 0, 0, 0, 0.98, "kip_kick", 1.0, "vuelo"],
			[0.74, 0.0, 0, 0, 0, 0.7, "land_low", 0.5, "recepción"],
			[1.0, 0.0, 0, 0, 0, 0.95, "stand", 0.0, "de pie"]],
		"contacts": {"hl": [[0.2, 0.47]], "hr": [[0.2, 0.47]], "fl": [[0.72, 1.0]], "fr": [[0.72, 1.0]]}},
	"handstand": {"name": "Handstand", "dur": 0.75, "travel": Vector2(0, 1), "keep": 0.2, "leg": 0.8, "arm": 0.2,
		"vmin": 0.6, "vmax": 2.0, "conv": 0.0, "rebound": 0.0, "land_drop": 0.0, "stability": 1.0,
		"exit_yaw": 0.0, "link_at": 2.0, "window": 0.0, "difficulty": 0.6, "chain_start": 0.0, "hold": true,
		"rot": "subida al pino y equilibrio (mientras se mantiene el joystick)",
		"keys": [[0.0, 0, 0, 0, 0, 0.95, "arms_up", 0.6, "brazos arriba"],
			[0.2, -0.45, 0, 0, 0, 0.84, "lunge", 0.8, "zancada"],
			[0.45, -1.7, 0, 0, 0, 0.94, "reach", 0.5, "manos al suelo"],
			[0.72, -2.75, 0, 0, 0, 1.1, "handstand_kick", 0.2, "patada arriba"],
			[0.88, -3.14, 0, 0, 0, 1.17, "hollow", 0.0, "pino"],
			[1.0, -3.14, 0, 0, 0, 1.17, "hollow", 0.0, "equilibrio"]],
		"contacts": {"hl": [[0.42, 9.0]], "hr": [[0.42, 9.0]], "fl": [[0.0, 0.5]], "fr": [[0.0, 0.62]]}},
	"pushoff": {"name": "Handstand Push-off", "dur": 0.5, "travel": Vector2(0, -1), "keep": 0.0, "leg": 1.2, "arm": 2.0,
		"vmin": 1.0, "vmax": 2.0, "conv": 0.0, "rebound": 0.3, "land_drop": 0.55, "stability": 0.8,
		"exit_yaw": 0.0, "link_at": 0.78, "window": 0.36, "difficulty": 0.7, "chain_start": 0.0,
		"rot": "snap down: bloqueo de hombros desde el pino y bajada rápida",
		"keys": [[0.0, -3.14, 0, 0, 0, 1.17, "hollow", 0.0, "pino"],
			[0.22, -2.75, 0, 0, 0, 1.26, "push_arms", 0.6, "bloqueo de hombros"],
			[0.52, -1.3, 0, 0, 0, 1.0, "snap", 1.0, "piernas al suelo"],
			[0.78, 0.0, 0, 0, 0, 0.74, "land", 0.8, "recepción"],
			[1.0, 0.0, 0, 0, 0, 0.82, "land_rebound", 0.7, "rebote"]],
		"contacts": {"hl": [[0.0, 0.28]], "hr": [[0.0, 0.28]], "fl": [[0.78, 1.0]], "fr": [[0.78, 1.0]]}},
	"td_raiz": {"name": "Touchdown Raiz", "dur": 0.94, "travel": Vector2(0.75, 0.66), "keep": 0.5, "leg": 1.5, "arm": 0.9,
		"vmin": 1.8, "vmax": 5.0, "conv": 0.0, "rebound": 0.12, "land_drop": 0.35, "stability": 0.7,
		"exit_yaw": PI, "link_at": 0.86, "window": 0.38, "difficulty": 1.4, "chain_start": 0.0, "spin": 1.0,
		"rot": "raiz más invertido: una mano toca el suelo antes que los pies",
		"keys": [[0.0, 0, 0, 0, 0, 0.95, "stand", 0.6, "entrada"],
			[0.14, -0.25, 0, 0.35, 0, 0.84, "raiz_step", 0.8, "paso en diagonal"],
			[0.28, -0.7, 0.35, 0.85, 0, 0.82, "raiz_swing", 0.9, "barrido de brazos e impulso"],
			[0.4, -0.55, 1.3, 1.45, 0, 1.32, "raiz_layout", 1.0, "patada de la pierna de atrás"],
			[0.53, -0.45, 2.1, 2.15, 0, 1.62, "raiz_layout", 1.0, "rotación invertida"],
			[0.64, -0.3, 2.35, 2.65, 0, 1.12, "td_reach", 0.9, "mano hacia el suelo"],
			[0.74, -0.15, 1.9, 2.95, 0, 0.84, "td_reach", 0.8, "apoyo de una mano"],
			[0.86, 0, 0.3, 3.1416, 0, 0.8, "land_one", 0.6, "paso de piernas y recepción"],
			[1.0, 0, 0, 3.1416, 0, 0.92, "stand", 0.4, "de pie"]],
		"contacts": {"hr": [[0.66, 0.8]], "fl": [[0.0, 0.38], [0.93, 1.0]], "fr": [[0.0, 0.28], [0.85, 1.0]]}},
	# Cork quieto (standing cork): un único apoyo, la patada de la pierna de atrás da la elevación,
	# bloqueo de cadera, despegue vertical y el tirabuzón empieza ya invertido (en el aire).
	"cork_swing": {"name": "Cork", "dur": 0.44, "travel": Vector2(0, 1), "keep": 0.3, "leg": 0.0, "arm": 0.0,
		"vmin": 0.0, "vmax": 2.0, "conv": 0.0, "rebound": 0.0, "land_drop": 0.0, "stability": 1.0,
		"exit_yaw": 0.0, "link_at": 2.0, "window": 0.0, "difficulty": 0.0, "chain_start": 0.0,
		"cork_takeoff": true, "rot": "patada en diagonal y despegue vertical",
		"keys": [[0.0, 0, 0, 0, 0, 0.92, "stand", 0.1, "postura"],
			[0.42, -0.05, 0, 0, 0, 0.8, "cork_set", 0.2, "carga: pierna de patada atrás y brazos atrás"],
			[0.74, 0.12, 0, 0, 0, 0.93, "cork_swing", 0.3, "patada arriba en diagonal y brazos arriba"],
			[1.0, 0.22, 0, 0, 0, 1.0, "cork_swing", 0.3, "bloqueo de cadera y despegue vertical"]],
		"contacts": {"fl": [[0.0, 1.0]], "fr": [[0.0, 0.6]]}},
	# Recepción a un pie (botón 1 PIE): cae sobre una pierna con la otra libre y abre una ventana
	# para enlazar el siguiente movimiento sin apoyar el segundo pie (combos a un pie)
	# Dura lo bastante para verse y para enlazar con calma (antes 0,46 s: casi no se veía)
	"one_foot": {"name": "One-Foot Landing", "dur": 0.8, "travel": Vector2(0, 1), "keep": 0.85, "leg": 0.0, "arm": 0.0,
		"vmin": 0.0, "vmax": 8.0, "conv": 0.0, "rebound": 0.14, "land_drop": 0.25, "stability": 0.8,
		"exit_yaw": 0.0, "link_at": 0.1, "window": 0.7, "difficulty": 0.4, "chain_start": 0.0,
		"rot": "recepción a un pie",
		"keys": [[0.0, 0, 0, 0, 0, 0.8, "land_one", 0.8, "recepción a un pie"],
			[0.45, 0, 0, 0, 0, 0.86, "land_one", 0.6, "equilibrio sobre una pierna"],
			[0.78, 0, 0, 0, 0, 0.88, "land_one", 0.5, "equilibrio sobre una pierna"],
			[1.0, 0, 0, 0, 0, 0.93, "stand", 0.4, "apoya el otro pie"]],
		"contacts": {"fl": [[0.0, 1.0]], "fr": [[0.92, 1.0]]}},
	# Vuelta de 3 pasos largos girando 360 (entrada de potencia antes de la rueda: piru desde el lado)
	"spin_entry": {"name": "3-Step 360", "dur": 0.95, "travel": Vector2(0, 1), "keep": 0.7, "leg": 3.2, "arm": 0.0,
		"vmin": 3.0, "vmax": 6.5, "conv": 0.0, "rebound": 0.0, "land_drop": 0.0, "stability": 1.0,
		"exit_yaw": 0.0, "link_at": 0.96, "window": 0.35, "difficulty": 0.4, "chain_start": 0.0, "spin": 1.0,
		"rot": "tres pasos largos girando 360",
		"keys": [[0.0, 0, 0, 0, 0, 0.92, "stride_r", 0.6, "paso 1"],
			[0.33, 0, 0, 2.09, 0, 0.9, "stride_l", 0.7, "paso 2"],
			[0.66, 0, 0, 4.19, 0, 0.9, "stride_r", 0.7, "paso 3"],
			[1.0, 0, 0, 6.283, 0, 0.86, "lunge", 0.6, "carga de la rueda"]],
		"contacts": {"fl": [[0.0, 0.18], [0.36, 0.58], [0.9, 1.0]], "fr": [[0.0, 0.1], [0.2, 0.4], [0.64, 0.86]]}},
	"scoot": {"name": "Scoot", "dur": 0.62, "travel": Vector2(1, 0.2), "keep": 0.4, "leg": 2.4, "arm": 0.4,
		"vmin": 2.0, "vmax": 4.5, "conv": 0.0, "rebound": 0.14, "land_drop": 0.3, "stability": 0.7,
		"exit_yaw": PI * 0.5, "link_at": 0.78, "window": 0.4, "difficulty": 0.5, "chain_start": 0.0, "spin": 1.0,
		"rot": "salto lateral con barrido de pierna y cuarto de giro",
		"keys": [[0.0, 0, 0, 0, 0, 0.95, "stand", 0.3, "entrada"],
			[0.18, 0, 0, 0.3, 0, 0.72, "scoot_load", 0.4, "carga sobre una pierna"],
			[0.36, 0, 0, 0.9, 0, 0.82, "scoot_sweep", 1.0, "barrido de la pierna"],
			[0.55, 0, 0.25, 1.35, 0, 1.42, "scoot_air", 1.0, "salto lateral"],
			[0.76, 0, 0, 1.5708, 0, 0.78, "land_one", 0.7, "recepción"],
			[1.0, 0, 0, 1.5708, 0, 0.92, "stand", 0.4, "de pie"]],
		"contacts": {"fl": [[0.0, 0.4], [0.84, 1.0]], "fr": [[0.0, 0.2], [0.75, 1.0]]}},
}

## Mueve la articulación al lado opuesto (lado -1).
static func mirror_pose(p: Dictionary) -> Dictionary:
	var out := {}
	for k in p.keys():
		var v: Vector3 = p[k]
		out[SWAP.get(k, k)] = Vector3(v.x, -v.y, -v.z)
	return out

static func contact_name(c: String, side: int) -> String:
	if side >= 0:
		return c
	return {"hl": "hr", "hr": "hl", "fl": "fr", "fr": "fl"}[c]

static func get_def(id: String) -> Dictionary:
	return SKILLS.get(id, {})

## Estado del cuerpo en el instante s (0..1) de la habilidad.
## Devuelve basis (orientación relativa a la dirección de entrada), com (altura del centro de
## masas sobre el suelo), pose, vel (fracción de la velocidad de desplazamiento), contactos
## (peso 0..1 por mano/pie) y el nombre de la fase.
static func sample(id: String, s: float, side: int) -> Dictionary:
	var d: Dictionary = SKILLS[id]
	var keys: Array = d.keys
	var i := 0
	while i < keys.size() - 2 and s >= float(keys[i + 1][0]):
		i += 1
	var a: Array = keys[i]
	var b: Array = keys[mini(i + 1, keys.size() - 1)]
	var span := maxf(float(b[0]) - float(a[0]), 0.0001)
	var u := clampf((s - float(a[0])) / span, 0.0, 1.0)
	var sd := float(side)
	# Curvas suaves (Hermite monótona) entre las claves: la velocidad de giro y de cada
	# articulación es continua al pasar por una clave (antes iba a tramos rectos y cada pose se
	# paraba en su clave: el movimiento se veía a tirones). Pasa exactamente por las claves.
	var ip := i - 1 if i > 0 else -1
	var inx := i + 2 if i + 2 < keys.size() else -1
	var kp: Array = keys[ip] if ip >= 0 else []
	var kn: Array = keys[inx] if inx >= 0 else []
	var pitch := _hermite_ch(kp, a, b, kn, 1, u)
	var roll := _hermite_ch(kp, a, b, kn, 2, u) * sd
	var yaw := _hermite_ch(kp, a, b, kn, 3, u) * sd
	var twist := _hermite_ch(kp, a, b, kn, 4, u) * sd
	var com := _hermite_ch(kp, a, b, kn, 5, u)
	var vel := lerpf(a[7], b[7], u)
	var pa: Dictionary = POSES[a[6]]
	var pb: Dictionary = POSES[b[6]]
	var pp: Dictionary = POSES[kp[6]] if not kp.is_empty() else {}
	var pn: Dictionary = POSES[kn[6]] if not kn.is_empty() else {}
	var pose := {}
	for k in pa.keys():
		pose[k] = pa[k]
	for k in pb.keys():
		if not pose.has(k):
			pose[k] = Vector3.ZERO
	var ta := float(a[0])
	var tb := float(b[0])
	var tpv := float(kp[0]) if not kp.is_empty() else NAN
	var tnx := float(kn[0]) if not kn.is_empty() else NAN
	for k in pose.keys():
		var va: Vector3 = pa.get(k, Vector3.ZERO)
		var vb: Vector3 = pb.get(k, Vector3.ZERO)
		var vp: Vector3 = pp.get(k, Vector3.ZERO) if not kp.is_empty() else va
		var vn: Vector3 = pn.get(k, Vector3.ZERO) if not kn.is_empty() else vb
		pose[k] = Vector3(
			_hermite(vp.x, va.x, vb.x, vn.x, tpv, ta, tb, tnx, u),
			_hermite(vp.y, va.y, vb.y, vn.y, tpv, ta, tb, tnx, u),
			_hermite(vp.z, va.z, vb.z, vn.z, tpv, ta, tb, tnx, u))
	if side < 0:
		pose = mirror_pose(pose)
	var basis := (Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch) * Basis(Vector3.BACK, -roll)
		* Basis(Vector3.UP, twist)).orthonormalized()
	var contacts := {}
	var soft := {}
	# Contactos: la mano/pie se clava en ~0,03 de la duración (apoyo seco, sin resbalar). La
	# altura del cuerpo se adapta al apoyo con una transición más larga (~0,12 s) para que no
	# salte de golpe al tocar con la mano (se veía "trabado").
	var ramp_soft := clampf(0.12 / float(d.dur), 0.03, 0.18)
	for c in ["hl", "hr", "fl", "fr"]:
		var w := 0.0
		var ws := 0.0
		for iv in d.contacts.get(c, []):
			w = maxf(w, _contact_w(s, float(iv[0]), float(iv[1]), ramp_soft, ramp_soft))
			ws = maxf(ws, _contact_w(s, float(iv[0]), float(iv[1]), ramp_soft, ramp_soft))
		contacts[contact_name(c, side)] = w
		soft[contact_name(c, side)] = ws
	# Apoyo de manos: el cuerpo pivota sobre las manos. Los hombros quedan a la longitud del
	# brazo por encima del apoyo (el centro de masas se ajusta a ello) y el desplazamiento lo
	# da la propia rotación alrededor de las manos (ver support_velocity).
	var hw := maxf(contacts.hl, contacts.hr)
	var off := shoulder_offset(basis, contacts, pose.get("spine", Vector3.ZERO))
	var hs := maxf(soft.hl, soft.hr)
	if hs > 0.0:
		com = lerpf(com, SUPPORT_H - off.y, _smooth(hs))
	return {"basis": basis, "com": com, "support": hw, "shoulder": off, "pose": pose, "vel": vel, "contacts": contacts, "soft": soft,
		"phase": a[8] if u < 0.5 else b[8], "pitch": pitch, "roll": roll, "yaw": yaw, "twist": twist}

## Un canal (columna c) de las claves con Hermite monótona; kp/kn vacíos en los extremos.
static func _hermite_ch(kp: Array, a: Array, b: Array, kn: Array, c: int, u: float) -> float:
	return _hermite(float(kp[c]) if not kp.is_empty() else float(a[c]), float(a[c]), float(b[c]),
		float(kn[c]) if not kn.is_empty() else float(b[c]),
		float(kp[0]) if not kp.is_empty() else NAN, float(a[0]), float(b[0]),
		float(kn[0]) if not kn.is_empty() else NAN, u)

## Hermite cúbica monótona (Fritsch-Carlson) entre a (t=ta) y b (t=tb), con las claves vecinas
## p (tp) y n (tn) para las tangentes. Sin vecina (NAN) la tangente es cero: arranca o termina
## en reposo. Sin rebasar: si la curva cambia de sentido en una clave, allí la tangente es cero.
static func _hermite(p: float, a: float, b: float, n: float, tp: float, ta: float, tb: float, tn: float, u: float) -> float:
	var h := maxf(tb - ta, 1e-4)
	var dab := (b - a) / h
	var ma := 0.0
	var mb := 0.0
	if not is_nan(tp):
		var dpa := (a - p) / maxf(ta - tp, 1e-4)
		if dpa * dab > 0.0:
			ma = 2.0 / (1.0 / dpa + 1.0 / dab)
	if not is_nan(tn):
		var dbn := (n - b) / maxf(tn - tb, 1e-4)
		if dbn * dab > 0.0:
			mb = 2.0 / (1.0 / dab + 1.0 / dbn)
	var u2 := u * u
	var u3 := u2 * u
	return (2.0 * u3 - 3.0 * u2 + 1.0) * a + (u3 - 2.0 * u2 + u) * h * ma \
		+ (-2.0 * u3 + 3.0 * u2) * b + (u3 - u2) * h * mb

## Peso de un contacto [x0, x1] en s, con rampa de entrada de anchura ramp.
## Al soltar la rampa es más larga (ramp_out): el brazo vuelve a su pose sin latigazo.
static func _contact_w(s: float, x0: float, x1: float, ramp: float, ramp_out: float) -> float:
	if s >= x0 and s <= x1:
		return 1.0
	if s < x0 and s > x0 - ramp:
		return (s - (x0 - ramp)) / ramp
	if s > x1 and s < x1 + ramp_out:
		return 1.0 - (s - x1) / ramp_out
	return 0.0

const SUPPORT_H := 0.52           # altura de los hombros sobre el suelo con los brazos de apoyo
const SHOULDER := Vector3(0.0, 0.53, 0.0)
const SHOULDER_W := 0.23

static func _smooth(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)

## Hombro(s) que apoyan, relativo al centro de masas y en el marco de la habilidad.
## Cinemática directa del tronco del rig: la columna (arqueo/carpado) mueve los hombros.
static func shoulder_offset(basis: Basis, contacts: Dictionary, spine := Vector3.ZERO) -> Vector3:
	var wl: float = contacts.get("hl", 0.0)
	var wr: float = contacts.get("hr", 0.0)
	var x := 0.0
	if wl + wr > 0.001:
		x = (-wl + wr) / (wl + wr) * SHOULDER_W
	var local := Vector3(0.0, 0.06, 0.0) + Basis.from_euler(spine) * Vector3(x, 0.47, 0.0)
	return basis * local

## Velocidad horizontal (marco de la habilidad) que mantiene quietos los hombros de apoyo:
## con las manos clavadas, el centro de masas avanza lo que la rotación del cuerpo exige.
static func support_velocity(id: String, s: float, side: int, dur: float) -> Vector3:
	var e := 0.01
	var a := sample(id, clampf(s, 0.0, 1.0), side)
	var b := sample(id, clampf(s + e, 0.0, 1.0), side)
	# Los dos instantes con los mismos apoyos: el cambio de una mano a la otra no es un
	# movimiento del cuerpo (antes daba un salto de 15-25 cm en dos fotogramas)
	var da := shoulder_offset(a.basis, a.contacts, (a.pose as Dictionary).get("spine", Vector3.ZERO))
	var db := shoulder_offset(b.basis, a.contacts, (b.pose as Dictionary).get("spine", Vector3.ZERO))
	var v := -(db - da) / (e * dur)
	return Vector3(v.x, 0.0, v.z)

## Dirección de desplazamiento en el mundo.
static func travel_dir(id: String, facing: Vector3, side: int) -> Vector3:
	var d: Dictionary = SKILLS[id]
	var tv: Vector2 = d.travel
	var right := facing.cross(Vector3.UP).normalized()
	var v := right * tv.x * float(side) + facing * tv.y
	return v.normalized() if v.length() > 0.01 else facing

## Potencia de la habilidad a partir de la técnica y de la velocidad de entrada:
## velocidad de desplazamiento, velocidad de salida, velocidad de recepción y rebote vertical.
static func power(id: String, entry_vel: Vector3, facing: Vector3, side: int, quality := 1.0) -> Dictionary:
	var d: Dictionary = SKILLS[id]
	var dir := travel_dir(id, facing, side)
	var along := maxf(0.0, Vector3(entry_vel.x, 0, entry_vel.z).dot(dir))
	var travel := clampf(along * float(d.keep) + float(d.leg), float(d.vmin), float(d.vmax))
	var last_v: float = d.keys[-1][7]
	var land_speed := sqrt(2.0 * G * float(d.land_drop))
	var rebound := float(d.rebound) * land_speed + float(d.conv) * along + float(d.arm) * 0.25 * float(d.rebound > 0.0)
	rebound = clampf(rebound * quality, 0.0, 3.2)
	var peak := 0.0
	for k in d.keys:
		peak = maxf(peak, float(k[5]))
	return {"dir": dir, "entry": along, "travel": travel, "exit_speed": travel * last_v, "land_speed": land_speed,
		"rebound_vy": rebound, "height": peak, "stability": float(d.stability), "spin": float(d.get("spin", 0.0))}
