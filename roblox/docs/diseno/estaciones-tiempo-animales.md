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
