# Estaciones del año y tiempo de Valmar (v126)

Petición del dueño: «Hay que implementar las estaciones del año en Valmar, aparte de nubes grises y nubes
muy oscuras cuando llueva, relámpagos quizás también, y que se vea todo mojado realista AAA».

> **Importante:** todo esto está hecho con código y probado con las pruebas automáticas (Lune). **Nadie lo
> ha visto todavía dentro de Roblox.** Abajo está la lista de lo que hay que mirar y capturar.

## Qué hay

### 1. Las estaciones van con el calendario

- La estación sale **del mes que enseña el HUD** («sáb 6 ene»). Valmar es mediterránea:
  - ❄️ **Invierno**: diciembre, enero y febrero
  - 🌸 **Primavera**: marzo, abril y mayo
  - ☀️ **Verano**: junio, julio y agosto
  - 🍂 **Otoño**: septiembre, octubre y noviembre
- Un mes del juego son 28 días de juego, así que **cada estación dura 84 días de juego (unas 28 horas
  reales)**. Por eso el modo pruebas deja cambiarla al momento (abajo).
- **Sin saltos:** los últimos 10 días de cada estación y los primeros 10 de la siguiente se mezclan
  (colores de los árboles y la hierba, altura del sol, temperatura y qué tiempo hace).
- Si prefieres el ciclo corto de antes (una estación por semana de juego, ~2 h 20 min reales):
  `src/shared/Config.luau` → `Config.Seasons.Mode = "Rapido"`.
- **No cambia** lo que dura el día (`Config.DayLengthMinutes`). La hora del amanecer y del anochecer
  tampoco cambia (los horarios del cole, las tiendas y las farolas dependen de ella): lo que cambia es
  **la altura del sol** (alto en verano, bajo en invierno) y el tono de la luz.

| | Primavera | Verano | Otoño | Invierno |
|---|---|---|---|---|
| Temperatura (mín.–máx., +1 °C con sol, −3 °C con lluvia) | 10–21 °C | 21–32 °C | 11–21 °C | 4–13 °C |
| Tiempo más habitual | variable, chubascos | sol, alguna tormenta de tarde | nubes, lluvia, niebla | nubes, lluvia; **nieve muy rara** |
| Árboles | verdes, **algunos en flor** (rosa y blanco), pétalos cayendo | verde oscuro | **amarillo, naranja y rojo** (cada árbol el suyo), hojas cayendo | apagados y pelados |
| Gente | algo de manga corta | **manga corta** | algunos con abrigo | **abrigos** |
| Playa | a medias | **llena** | poca gente | casi vacía |
| Extra | | vapor del asfalto tras la lluvia | | **árbol de luces en la plaza** (1 dic – 6 ene) |

### 2. Nubes, lluvia y tormentas

Siete tiempos, cada uno con su cielo (nubes de Roblox, bruma, luz):

| Tiempo | Cómo se ve |
|---|---|
| ☀️ Despejado | cielo de siempre |
| ⛅ Poco nuboso | nubes sueltas, casi todo el sol |
| ☁️ Nublado | cielo **gris** tapado, luz plana |
| 🌧️ Lluvia | nubes **oscuras** y bajas, velo gris, menos luz; de llovizna a chaparrón |
| ⛈️ Tormenta | nubes **muy oscuras** (casi de noche a media tarde), aguacero, viento fuerte, **rayos** |
| 🌫️ Niebla | bruma espesa |
| 🌨️ Nieve | cielo blanco, copos; el suelo y las copas se ponen blancos poco a poco |

**Rayos** (los decide el servidor: todos ven el mismo a la vez):
- Un rayo quebrado de la nube al suelo, casi siempre **lejos**; a veces **cerca** (con su luz).
- El **trueno llega después**, más tarde cuanto más lejos cae (la velocidad del sonido de verdad).
  Cerca suena un «crac» fuerte; lejos, un retumbar flojo.
- **Seguridad para la vista:** nunca dos rayos con menos de 6 segundos ni más de 5 por minuto, y cada
  fogonazo es un destello suave. Además, en **Ajustes → Pantalla → «⚡ Destellos de relámpago»** se puede
  poner **No**: el cielo no se ilumina de golpe (el rayo se ve tenue y el trueno suena igual). Se guarda.

### 3. Todo mojado

Ya había: asfalto y aceras más oscuros y con reflejos, rugosidad mojada en calles y aceras, charcos,
salpicaduras, ropa mojada que gotea, coche que levanta agua, gotas en la pantalla. Ahora además:
- **Se seca con el tiempo de juego**: en verano con sol en ~1,4 horas de juego (~70 s reales); en invierno
  ~4,5 horas; de noche y nublado, más despacio.
- **Charcos que crecen** mientras llueve (empiezan pequeños) y **se secan después** que el suelo.
- **Hierba y tierra del terreno más oscuras** cuando está mojado (solo la hierba y la tierra de Valmar:
  el fondo del mar no se toca nunca).
- **Goteo de toldos, balcones y tejados**: una cortina de gotas por el borde del toldo que tienes
  encima o al lado, mientras llueve y un rato después.
- **Vapor** que sube del asfalto caliente tras una lluvia de verano cuando sale el sol.
- **Faros**: con la calzada mojada el haz llega algo más lejos y brilla más (el asfalto mojado refleja).
- El viento de la tormenta inclina la lluvia y mece más los árboles (ya existía; ahora también con el
  tiempo «poco nuboso»).

### 4. Sonido (todo en 🌳 Ambiente)

- Lluvia según dónde estás: **en la calle** (llovizna o chaparrón), **bajo un toldo o dentro de casa**
  (tamborileo en el tejado, la calle apagada), **dentro del coche** (golpeteo en el techo) y **nada en
  el metro**.
- Trueno **cerca** y **lejos**, viento de **tormenta** con rachas.
- Los sonidos nuevos (`lluvia_suave`, `lluvia_fuerte`, `lluvia_tejado`, `lluvia_coche`, `trueno_cerca`,
  `trueno_lejos`, `viento_tormenta`) están hechos por código (`scripts/audio/clima.py`) y **aún no están
  subidos**. Mientras no lo estén suenan los de siempre (lluvia, trueno, viento). Para subirlos (lo hace
  la sesión de publicar, con su clave): `bash scripts/upload-audio.sh --clima`.

### 5. Quién manda

1. **Escenas de la historia y la Grieta del cielo muy abierta**: mientras su cielo manda, el tiempo de
   Valmar se aparta (sin lluvia delante ni rayos). La Cinemateca y las cinemáticas tienen su cielo.
2. **Eventos del mundo** (la tormenta del mar) fuerzan su tiempo.
3. **El modo pruebas** (`/clima`, `/estacion`, panel).
4. **El calendario.**

- Solo en Valmar: **nada** de esto en el espacio, en los planetas ni bajo el mar (Nácara). Dentro de
  casa no llueve y la lluvia se oye apagada; en el metro, ni lluvia ni rayos (el trueno, muy flojo).
- En el coche no salen gotas en la pantalla (no hay cámara de parabrisas en el juego); se oye la lluvia
  en el techo.

### 6. Móviles (rendimiento)

Todo pasa en cada pantalla, solo cerca de la cámara y con piezas que se reutilizan. Según el nivel
gráfico (Bajo / Medio / Alto): goteo en 1 / 3 / 5 bordes, vapor 3 / 8 / 14 nubecitas por segundo,
árbol de luces de 48 / 96 / 128 bombillas, rayo de como mucho 24 piezas (en Bajo sin ramas), hojas que
caen solo cerca de árboles. Las copas se repintan en trozos para no congelar la pantalla.

## Cómo probarlo (modo pruebas)

En el chat (solo testers):

| Comando | Qué hace |
|---|---|
| `/estacion primavera` · `verano` · `otono` (u `otoño`) · `invierno` | fuerza la estación para todo el servidor |
| `/estacion auto` | vuelve a la del calendario |
| `/clima despejado` · `intervalos` · `nublado` · `lluvia` · `tormenta` · `niebla` · `nieve` | fuerza el tiempo para todo el servidor |
| `/clima auto` | vuelve el tiempo normal |

En el panel `/pruebas` → **🌦️ ESTACIONES Y TIEMPO**: un botón por estación y por tiempo, y «Auto».
La hora se cambia en **HORA DEL DÍA** (8:00, 12:00, 18:00, 21:30, 22:00).

## ✅ Lista para el dueño (qué mirar y qué capturar)

Haz cada captura en el **móvil** y, si puedes, también en el ordenador. Ponte en una calle del centro con
árboles cerca (por ejemplo el Parque o la Plaza del centro, con «TELETRANSPORTE»).

1. [ ] `/clima despejado`, `/estacion verano`, 12:00 → **captura**: árboles verde oscuro, sol alto, HUD
   ~30 °C. Ve a la **Playa**: mucha gente.
2. [ ] `/estacion otono` → espera ~5 s → **captura** de los árboles: cada uno amarillo, naranja o rojo, y
   hojas cayendo cerca de ellos.
3. [ ] `/estacion invierno` → **captura**: copas apagadas, gente con abrigo, HUD frío. En la Playa, casi
   nadie. En la **Plaza del centro**, de 18:00 en adelante (o 21:30): ¿sale el **árbol de luces**? (Si
   no sale, dímelo: busca solo un sitio llano y despejado cerca del centro).
4. [ ] `/estacion primavera` → **captura**: algunos árboles con flores rosas/blancas y pétalos.
5. [ ] `/clima nublado` → **captura** del cielo: gris, sin sol.
6. [ ] `/clima lluvia` → espera 20 s → **captura**: nubes oscuras, suelo oscuro y brillante, charcos. Espera
   1-2 minutos más: los charcos se hacen más grandes. Ponte **bajo un toldo o un balcón**: ¿gotea el
   borde? ¿suena distinto?
7. [ ] `/clima tormenta` → **graba un vídeo corto**: cielo muy oscuro, rayos lejos (y alguno cerca), el
   trueno llega después del fogonazo. Pon 21:30 y mira la tormenta de noche.
8. [ ] En Ajustes → «⚡ Destellos de relámpago: no» → con tormenta, el cielo ya no se ilumina de golpe.
9. [ ] Con lluvia, súbete a un **coche**: se oye la lluvia en el techo. Baja al **metro**: no llueve.
   Entra en una **casa**: no llueve y se oye apagada.
10. [ ] `/clima despejado` con el verano y el suelo aún mojado, de día → **captura**: vapor bajito del
    asfalto. Espera ~1-2 minutos: el suelo se seca y los charcos se van.
11. [ ] Con lluvia, súbete a la nave y sube al **espacio** / baja a un **planeta** / bucea en el **mar**:
    allí no llueve ni hay rayos. Al volver a Valmar, el tiempo sigue.
12. [ ] `/clima auto` y `/estacion auto` para dejarlo normal.

Mándame las capturas de lo que no se vea bien (sobre todo 2, 3, 6 y 7).

## Para ajustar (sin programar)

- `src/shared/Config.luau` → `Config.Seasons`: `Mode` (Calendario / Rapido), `BlendDays` (días de
  mezcla), `Lightning` (`MinGap`, `MaxPerMinute`, `NearShare`), sonidos.
- `src/shared/Seasons.luau` → temperatura, probabilidad de cada tiempo, colores de árboles y hierba, ropa,
  playa, altura del sol de cada estación; cómo es el cielo de cada tiempo (`Dark` = lo oscuras que son las nubes).
- `src/shared/Wetness.luau` → cuánto tarda en mojarse y secarse, topes por nivel gráfico.

## Archivos

- `src/shared/Seasons.luau` — calendario → estación, mezcla entre estaciones, tiempo, temperatura, árboles, ropa, playa.
- `src/shared/Storm.luau` — rayos: cuándo (con el límite de seguridad), dónde, el destello y el trueno.
- `src/shared/Wetness.luau` — mojarse y secarse en horas de juego, charcos, vapor, goteo, topes.
- `src/shared/RainLook.luau` — sonido de la lluvia según dónde estás; cuánto mandan las escenas.
- `src/server/Services/WeatherService.luau` — decide y publica todo (atributos de workspace).
- `src/client/Controllers/Weather.luau` — cielo, lluvia, árboles, hierba, sol, sonido.
- `src/client/Controllers/Relampagos.luau` — los rayos y los truenos.
- `src/client/Controllers/SeasonDecor.luau` — goteo, vapor y luces de fiesta.
- `src/client/Controllers/WetWorld.luau` — suelo mojado, charcos (ahora crecen), gente mojada.
- `scripts/audio/clima.py` — los sonidos nuevos. `scripts/test-estaciones.luau` — la prueba.
