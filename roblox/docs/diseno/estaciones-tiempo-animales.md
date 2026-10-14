# Estaciones, tiempo y animales

El mundo de Valmar cambia con el año y con el tiempo. Lo decide el servidor (igual para todos los
jugadores) y cada dispositivo lo pinta a su manera, sin gastar red.

## Estaciones

| Estación | Dura | Tiempo más habitual | Cómo se ve |
|---|---|---|---|
| 🌸 Primavera | 7 días de juego (~2 h 20 min reales) | sol, nubes, lluvia | hierba verde viva, pétalos rosas cayendo, muchas mariposas y pájaros |
| ☀️ Verano | 7 días | mucho sol, alguna tormenta | luz cálida, hierba más seca, mariposas; **luciérnagas por la noche** |
| 🍂 Otoño | 7 días | nubes, lluvia, niebla | copas de los árboles naranjas, **hojas cayendo**, menos pájaros |
| ❄️ Invierno | 7 días | nubes, **nieve**, niebla | luz fría, árboles apagados; cuando nieva, **el suelo y las copas se ponen blancos** poco a poco y luego se derrite |

El tiempo puede cambiar cada 6 horas de juego (unos 5 minutos reales): ☀️ despejado, ☁️ nublado,
🌧️ lluvia, ⛈️ tormenta (con relámpagos), 🌨️ nieve (solo en invierno) y 🌫️ niebla. Dentro de casa no
llueve. Arriba en el centro de la pantalla hay una etiqueta pequeña («🍂 Otoño · 🌧️ Lluvia») y sale un
aviso cuando cambia la estación o empieza a llover, nevar o hay tormenta.

## Lluvia y nieve que se notan

El servidor publica lo mojado que está todo (`Wet`, sube en ~30 s de lluvia y se seca en ~2,5 min) y la
nieve acumulada (`Snow`). Con eso:

| Qué | Con lluvia | Con nieve |
|---|---|---|
| Suelo y objetos al aire libre (calles, aceras, tejados, coches, bancos, fachadas) | Más oscuros y con reflejos, sobre todo el asfalto y lo liso | Lo de arriba se pone blanco (la calzada, poco) |
| Charcos | Aparecen en calles y plazas llanas y reflejan el cielo | — |
| Gotas | Salpican al caer al suelo | — |
| Personas (jugadores y personajes) | Ropa y pelo más oscuros y gotean; a cubierto se secan poco a poco | — |
| Coche que conduces | Levanta agua al pasar | — |
| Conducir | Agarra menos: frena peor y derrapa en las curvas | Mucho menos agarre: más despacio, frena mucho peor, gira menos y derrapa |
| Tráfico de la ciudad | Va más despacio | Aún más despacio |

- Lo que está bajo techo no se moja (se mira con un rayo hacia el cielo).
- Las motos, bicis y patinetes resbalan más que los coches.
- Al subir a un vehículo con el suelo mojado o nevado sale un aviso.
- Todo se hace en cada pantalla y solo cerca (100 studs); lo lejano vuelve a su color.

## Piedras, ventanas y puertas

- **Tecla B** (botón 🪨 en móvil, Y en el mando): coges una piedra del suelo de tierra, césped, arena o
  roca (hasta 3, se ve en tu mano). Otra vez B: la lanzas hacia donde apuntas (el ratón en el ordenador,
  el centro de la pantalla en móvil). La piedra da donde apuntas si está a tiro.
- **Cristales** (ventanas de casas y edificios, cristales de coches, de balcones): se rompen en trozos que
  caen. Las fachadas enteras de cristal y los escaparates de toda una manzana no se rompen.
- **Puertas**: aguantan 12 pedradas; con cada una tiemblan y se ven más estropeadas, y a la última se caen
  (con su pomo). Si pasan 30 s sin golpes, se recuperan y hay que empezar de nuevo.
- **Todo se arregla solo** a los 2-3 minutos.
- **Consecuencias**: los policías de servicio reciben un aviso («🚨 Vandalismo en …»), a quien le das se
  entera y los personajes se quejan. Los bebés no pueden coger piedras.
- La piedra la calcula el servidor con rayos (no atraviesa los cristales finos) y cada jugador la dibuja
  volando por el mismo camino.

## Animales

Aparecen alrededor del jugador (como el tráfico) y dependen de la estación, la hora y el tiempo:

- **Bandadas de pájaros** volando en círculos (de día y sin lluvia). En Playa Dorada, **gaviotas**.
- **Palomas** en el suelo de las ciudades: picotean y **salen volando si te acercas**.
- **Mariposas** (primavera y verano) y **luciérnagas** (noches de verano).
- **Patos** flotando en el agua (y gaviotas en el mar).
- **Perros y gatos** paseando por las ciudades.
- En **Villaverde**: **vacas, ovejas y gallinas** en la hierba.

## Para ajustar (sin programar)

`src/shared/Config.luau` → `Config.Seasons`:
- `DaysPerSeason`: cuántos días dura cada estación (7 = una semana de juego).
- `WeatherHours`: cada cuántas horas de juego puede cambiar el tiempo.
- `Start`: la estación del primer día.
- `Sounds`: IDs de audio para lluvia, trueno, pájaros y viento (0 = sin sonido). Se suben en Studio
  (Asset Manager) y se pega aquí el número.

`src/shared/Seasons.luau` → probabilidad de cada tiempo en cada estación, colores de hierba y hojas y
cuántos animales salen (Birds, Butterflies, Ground).

## Para la historia

Las misiones y los diálogos pueden depender del tiempo: `If = { Season = "Invierno" }` o
`If = { Weather = { "Lluvia", "Tormenta" } }` (por ejemplo, una línea de la familia: «¡Coge el paraguas!»).

## Archivos

- `src/shared/Seasons.luau` — datos y reglas (se prueba fuera de Roblox).
- `src/server/Services/WeatherService.luau` — decide la estación, el tiempo, la nieve acumulada y lo mojado.
- `src/client/Controllers/Weather.luau` — lluvia, nieve, relámpagos, hojas, colores y la etiqueta.
- `src/client/Controllers/Wildlife.luau` — los animales.
- `src/client/Controllers/DayLight.luau` — tiene un gancho (`setModifier`) para que el tiempo cambie la luz.
- `src/shared/Wetness.luau` — cuánto oscurece y brilla lo mojado, el agarre de los vehículos (se prueba: `test-weather`).
- `src/client/Controllers/WetWorld.luau` — suelo y objetos mojados o nevados, charcos, salpicaduras, personas mojadas.
- `src/shared/Breakables.luau` — qué se rompe y cómo vuela la piedra (se prueba: `test-breakables`).
- `src/server/Services/BreakService.luau` y `src/client/Controllers/StoneThrow.luau` — piedras, ventanas y puertas.
