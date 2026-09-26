# Personajes vivos y cinemáticas

Objetivo: que los personajes no parezcan maniquís. Tienen que respirar, mirar, moverse al hablar y
reaccionar con el cuerpo a lo que dicen. Las escenas de cámara tienen que parecer de película.

## Qué hace cada pieza

| Pieza | Dónde | Qué hace |
|---|---|---|
| `SceneService` | servidor | Anima a los actores de las escenas con las animaciones R15 de Roblox: estar de pie, andar, **correr**, saludar, celebrar, **reírse**, **bailar**, señalar, sentarse. Cada uno respira a su ritmo (la animación de pie empieza en un punto al azar) y el paso va a la velocidad de sus pies. Quien saluda o celebra lo repite cada pocos segundos, y al acabar el gesto sigue de pie (antes se quedaba congelado). |
| `ActorLife` | cliente | Añade la capa «viva» encima de cualquier animación. Solo trabaja con los 32 personajes más cercanos (a menos de 95 studs), así que no pesa en el móvil. |
| `Emotion` | compartido | Decide con qué gesto se dice cada frase. |
| `DialogueUI` | cliente | Es la cámara de las conversaciones y avisa a `ActorLife` de quién habla. |
| `Cinematics` | cliente | Es la cámara de cine: cámara en mano, zoom, enfoque, cortes a negro y gestos. |

### ActorLife: la capa «viva»

- **Respiración**: el pecho y los hombros suben y bajan, y cada personaje tiene su propio ritmo.
- **Mirada**: cabeza (65 %) y torso (35 %).
  - Si pasas cerca te miran un rato, apartan la vista y te vuelven a mirar.
  - Cuando no hay nadie cerca echan vistazos alrededor.
  - Nunca giran la cabeza más de 75° ni miran hacia atrás.
- **En una conversación**:
  - Quien habla te mira, y de vez en cuando aparta la vista un momento, como pensando lo que dice.
  - Los demás miran a quien habla, y tú también.
- **Hablar con el cuerpo**: mientras se escribe la frase, quien habla asiente un poco, mueve la cabeza y
  gesticula con las manos. La intensidad depende de la emoción:
  - Cuando está enfadado gesticula mucho.
  - Cuando está triste casi no mueve las manos.
- **Posturas por emoción**:

  | Emoción | Postura |
  |---|---|
  | Contento | Barbilla arriba y un pequeño rebote. |
  | Triste | Cabeza baja y hombros caídos. |
  | Enfadado | Barbilla baja y codos tensos. |
  | Sorprendido | Cabeza atrás y manos arriba. |
  | Pensando | Mano a la barbilla y cabeza ladeada. |
  | Preguntando | Cabeza ladeada y palmas abiertas. |
  | Encogerse de hombros | — |
  | Asentir | — |
  | Negar con la cabeza | — |

- **Personajes fijos del mapa**:
  - Afecta a los profes, los dependientes y la gente que el servidor mueve sin animación.
  - Ahora tienen animación de estar de pie, y de andar o correr cuando se desplazan.
  - De vez en cuando cambian de postura y miran alrededor.
  - Todo esto lo ve solo cada jugador en su pantalla, así que no carga al servidor.
- **Modo `Chat`** (actores de escena):
  - Los personajes de un grupo charlan entre ellos por turnos: se miran, gesticulan, asienten y a veces se ríen.
  - Si te acercas, alguno te mira.
  - Se usa en la parada del bus del instituto, en la cafetería de la universidad y en la fiesta del reencuentro.

### Emotion: el gesto de cada frase

Una línea de diálogo puede elegir su gesto a mano:

```lua
{ S = "Nico", T = "¡Hemos ganado!", A = "Cheer" }
```

Si la línea no dice nada, el gesto se adivina por el texto:

| Texto | Gesto |
|---|---|
| «jaja» | se ríe |
| «¡Hola…», «¡Adiós…» | saluda |
| «¡Bien…», «¡Enhorabuena…» | celebra |
| «Mira…» | señala |
| «lo siento», «perdón», «…» | triste |
| «¡¿…?!», «¡Hala…» | sorprendido |
| «Vale», «Claro», «Sí.» | asiente |
| «¡No!», «Ni hablar» | niega |
| «Mmm», «A ver», «No sé» | pensando |
| «Bah», «Ni idea» | se encoge de hombros |
| termina en «?» | pregunta |

Valores de `A`:

- Con animación: `Wave`, `Cheer`, `Laugh`, `Point`, `Dance`.
- Posturas: `Happy`, `Sad`, `Angry`, `Surprised`, `Thinking`, `Ask`, `Shrug`, `Nod`, `No`, `Calm`.

Si `A` tiene otro valor, el validador da error.

## Cámara de las conversaciones

- **Tipos de plano**:
  - Plano de los dos de perfil al empezar.
  - Por encima de tu hombro.
  - Primer plano de quien habla, cada tercera frase de la misma persona.
  - Contraplano cuando hablas tú.
- **Transiciones**: si cambia quien habla, la cámara corta en seco. Si sigue la misma persona, se desliza.
- **Durante la frase**:
  - La cámara se acerca muy despacio y se mece un poco, como una cámara en mano.
  - El fondo se desenfoca y quien habla queda nítido (`DayLight.setFocus`).

## Cinemáticas: extras de cada plano

```lua
{ Orbit = "Yo", Radius = 13, Height = 4, FromAngle = -30, ToAngle = 30, Duration = 7,
  Fov = { 68, 52 },  -- zoom lento (o un número fijo; 70 es el normal)
  Shake = 0.2,       -- cámara en mano (0-2)
  Roll = -4,         -- inclinar la cámara (grados)
  Dip = true,        -- fundido rápido a negro al empezar el plano
  Focus = false,     -- no desenfocar el fondo (por defecto se enfoca lo que se mira)
  LookHeight = 2 }   -- (Orbit) a qué altura mira
```

Opciones de la escena:

- **Anclas de personaje**: `Anchors = { Abu = "Actor:Abu" }` sirve para hacer primeros planos de alguien
  de la escena. Los offsets `Local` van girados con el personaje: `V(0, 1.5, -5)` es delante de su cara.
  Si el personaje no está, se usa el jugador.
- **Gestos en la línea de tiempo**: `Anims = { { At = 2.3, Who = "Todos", Play = "Cheer" } }`.
  `Who` puede ser `"Player"`, `"Todos"` (toda tu escena y tú) o alguien del reparto.
- **Quien habla en `Lines` también se mueve**. Su gesto sale de `Emotion`, o de `A` si la línea lo pone.

El validador comprueba lo siguiente:

- Las anclas `Actor:` son del reparto.
- `Anims` usa gestos que existen y caen dentro de la escena.
- `Shake` y `Fov` están en rango.
- Los planos cubren la duración de la escena, para que la cámara no se quede quieta.

### Escenas mejoradas

| Escena | Cambio |
|---|---|
| Nacimiento | Dron con temblor suave y zoom lento sobre la cuna. |
| Primeros pasos | Zoom y toda la familia celebra. |
| «Creces» | Vuelo de dron con cortes a negro. |
| Fotos del grupo (parque, granja, último día de primaria, reencuentro) | Zoom, cámara en mano y todos celebran a la vez. |
| Festival de primavera | Todos bailan. |
| Fin de primaria y graduación | Todos celebran. |
| Atardecer con {abu} | Primer plano de {abu} mirando el mar. |
