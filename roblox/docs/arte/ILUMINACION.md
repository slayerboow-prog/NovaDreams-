# Iluminación realista

La luz del juego cambia con la hora del día para que Valmar parezca real. Se calcula en el dispositivo de cada
jugador (`src/client/Controllers/DayLight.luau`): así los cambios son suaves, no gastan red y se adaptan a la calidad
gráfica de cada uno. El servidor (`WorldService`) solo mueve el reloj y prepara lo básico.

## Qué hay

| Elemento | Qué hace |
|---|---|
| **11 momentos del día** | Noche de luna, antes del alba, amanecer rosado, mañana dorada, mañana, mediodía, tarde, hora dorada, puesta de sol naranja, hora azul. Entre uno y otro se pasa poco a poco |
| **Luz y sombras** | Iluminación `Future` y estilo realista, sombras nítidas de día y más suaves al anochecer, reflejos del cielo en los materiales |
| **Cielo y bruma** | Atmósfera con el color de cada hora (bruma dorada al amanecer, rosa al atardecer, azul por la noche), sol y luna más grandes, estrellas |
| **Nubes de verdad** | Nubes volumétricas que cambian de color con la hora; cada día de juego trae más o menos nubes (igual para todo el servidor) |
| **Agua** | El mar de Playa Dorada más transparente, con reflejos y olas suaves |
| **Efecto cámara** | Corrección de color por hora, brillo en las luces fuertes, rayos de sol y un desenfoque muy suave a lo lejos |
| **Los ojos se acostumbran** | Dentro de casa la imagen se aclara un poco, como una cámara de verdad (los árboles no cuentan como techo) |
| **Modo cine** | En las cinemáticas, más desenfoque de fondo y algo más de contraste |
| **Móviles** | Con calidad gráfica baja se quitan el desenfoque y los rayos de sol, y las nubes son más ligeras |

## Cómo ajustarla

Todos los valores están en la tabla `KEYS` de `DayLight.luau` (una fila por momento del día). Por ejemplo, para un
atardecer más rojo se sube el rojo de `AtmColor` y de `Tint` en la fila de las 18:00. El agua y las nubes base están
en `setupLighting` de `src/server/Services/WorldService.luau`.

## Luces de la ciudad (mapa)

| Elemento | Qué hace | Dónde se ajusta |
|---|---|---|
| **Farolas** | Luz LED cálida hacia abajo con sombras de verdad. No se encienden todas a la vez: cada una tarda un poco (como las fotocélulas) | `Props.lamp` (`Kit/Props.luau`) y `setNight` en `WorldService` |
| **Ventanas de las casas** | Cada ventana tiene su color (bombilla cálida, neutra o el azul de la tele) y su horario: la ciudad se va encendiendo al anochecer y apagando de madrugada; unas pocas siguen encendidas toda la noche | `HOME_LIGHTS` y `nightSchedule` en `Kit/Building.luau` |
| **Oficinas** | Fluorescente frío que se apaga al acabar la jornada (algunas trabajan hasta tarde) | `Kit/Building.luau` (fachadas de cristal) |
| **Escaparates** | Luz blanca de tienda hasta la hora de cierre; algunos comercios 24 h | `glass(..., shop)` en `Kit/Building.luau` |
| **Interiores** | Plafones en el techo que iluminan hacia abajo (charcos de luz), el principal con sombras, y una luz de relleno suave | final de `Building.build` |
| **Tráfico** | Los coches que circulan encienden los faros al anochecer | `addHeadlight` en `client/Controllers/Ambient.luau` |
| **Tu coche y tu moto** | Faro delantero con sombras, encendido de noche | `addHeadlight` en `Services/VehicleService.luau` |

Horario: `OnAt` / `OffAt` son horas del juego; 25 = la 1 de la madrugada, 30 = las 6 de la mañana.
