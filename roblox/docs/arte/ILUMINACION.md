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
