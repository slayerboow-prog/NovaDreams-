# 12 · Misiones locas (secundarias de cada etapa)

Cada etapa de la vida tiene **5 misiones secundarias especiales** (la infancia, 6): historias de ciencia ficción gamberra, en el
tono de las series de dibujos para adultos jóvenes (portales, alienígenas, clones, versiones malvadas de ti…),
pero **originales** y **aptas para Roblox**. Todas dan una **recompensa exclusiva** que no se puede comprar.

- **El hilo conductor es Cosme**, el vecino inventor del garaje. Genio, desastre, cínico por fuera y
  cariñoso por dentro. Te llama «criatura» toda la vida, incluso de adulto. Bebe batido de apio, nunca alcohol.
- **Pip** es su robot mayordomo. Educadísimo y en plena crisis existencial.
- **Las reglas de tono**:
  - Sin sangre ni muertes: los «malos» se desintegran en chispas y vuelven teletransportados a su nave,
    a su dimensión o a su tamaño.
  - Sin romance entre jugadores y sin apuestas.
  - El humor sale de lo absurdo tratado con total seriedad: una aduana del tiempo con formularios,
    un reality alienígena, un banco galáctico que embarga la Tierra por un bocadillo.
- **Cada misión mezcla** investigación, conversaciones con decisiones, persecución o huida, combate con
  un gadget y un final con giro.

## Mecánicas nuevas del motor

| Paso | Qué hace |
|---|---|
| `Fight` | Enemigos (`Enemies = { { Npc, HP, Speed, Hurt, Bye } }`) que te **persiguen** (modo `Hunt`). El botón del enemigo es la acción (`Action = "Disparar 🔫"`). Cada pulsación es un impacto con rayo de color (`BeamColor`); con `HP` impactos, el enemigo se desintegra. Si te atrapa (`Catch`), vuelves a `Respawn`. El texto admite `{count}/{total}`. |
| `Escape` | Huir. Termina si llegas a `Place` o si aguantas `Seconds` sin que te atrapen. Si te atrapan, vuelves a `Respawn` (y en una huida por tiempo, el tiempo vuelve a empezar). |
| `Reach` con `Hours` | Solo cuenta si llegas a esa hora (la luz del monte sale de madrugada). |

Además:

- **Modo de actor `Hunt`**: te persigue. Si te pierde de vista, reaparece cerca.
- **`Glow`** en el reparto: brillo y luz para alienígenas, robots y seres de otras dimensiones.
- **Objetos de escena nuevos**:
  - `Nave`: platillo con rayo tractor.
  - `Portal`, `Maquina`, `Huevo`, `Cristal`, `Cohete`, `Moco` y `Pantalla`.
- **Gadgets** (tipo de objeto `Gadget`, `server/Services/GadgetService.luau`):
  - Se usan desde la mochila o la barra rápida y no se gastan.
  - Hacen su efecto delante de todos: rayo, burbujas, brillo, portal que te lleva a otro sitio de la
    región, o una frase.
  - No hacen daño a nadie.

## Infancia · `Misiones/Loco_Nino.luau`

| Misión | Dónde empieza | Historia | Juego | Recompensa |
|---|---|---|---|---|
| **El vecino del garaje** | Garaje de Cosme | Explota su microondas temporal. Recuperas 3 piezas: el tornillo cuántico en la fuente, la bobina dentro de un helado y el chip… en el collar de Bigotes, el gato del cole, que empieza a hablar. El bocadillo sale calentado «al martes pasado» (y mordido por el Cosme del pasado). | Buscar piezas y tomar decisiones | 🫧 Pistola de burbujas cuánticas |
| **Bigotes, emperador de Gatonia** | Patio del cole | El gato del cole es un emperador exiliado. Tres cucarachas cazarrecompensas del planeta Crujiente aterrizan en el patio. | Combate con globos de agua | 👑 Corona del emperador |
| **La gallina de seis metros** | Garaje de Cosme | El rayo agrandador alcanzó a Petra, una gallina de Villaverde. Se la ve (20 studs, 6 m) comiendo en el granero de Julián; miras su huevo gigante en el nido y te persigue hasta el silo; cada disparo del rayo la encoge. | Huida y combate con el rayo encogedor | 🔬 Rayo encogedor |
| **Deberes clónicos** | Garaje de Cosme | La clonadora de bolsillo crea tres clones: el hambriento, el cantante y el mandón. Van al cole por ti y te quieren abrazar. | Combate con el «botón de deshacer» | 📸 Foto con tus clones |
| **La huelga del Ratón Pérez** | Tu cuarto, de noche | El Ratón Pérez está en huelga: 300 años sin vacaciones. La Rata Ladrona le roba los dientes. Decides si la contrata. | Persecución nocturna | 🪙 Moneda del Ratón Pérez (+50) |
| **El tirachinas del campeón** | Salón de casa, en cuanto empiezas el cole (tras «El primer día») | {abu} fue campeón del Gran Torneo de Tirachinas de 1962. Te da su tirachinas con una regla de oro: nunca a personas ni a animales de verdad, solo a latas. Practicas en el parque y aparecen las palomas robot de Cosme robando bocadillos. | Minijuego de puntería y combate | 🪃 Tirachinas (gadget: dispara bellotas en arco que hacen «¡plof!») |

## Adolescencia · `Misiones/Loco_Adolescente.luau`

| Misión | Dónde empieza | Historia | Juego | Recompensa |
|---|---|---|---|---|
| **Mensajes del futuro** | Patio del instituto | Tu yo de 2036 viene a impedir que publiques un vídeo con un calcetín en la cabeza, porque se hará viral para siempre. Llega la Aduana del Tiempo. | Huida hasta el garaje de Cosme | 📱 Móvil del futuro |
| **La Dimensión Examen** | Aula del instituto | Tu estuche es un portal a un instituto de papel cuadriculado con lápices gigantes. Para salir hay que responder a la Última Pregunta: «¿Para qué sirven los exámenes?». | Huida | ✏️ Lápiz dimensional |
| **El concierto hipnótico** | Plaza del centro | DJ Zumbido, un alienígena, hipnotiza con tecno de 400 pulsaciones. El antídoto es la música del camión de los helados. | Combate contra los fans y contra el DJ | 🎧 Cascos anti-hipnosis |
| **La crisis de Pip** | Garaje de Cosme | Pip se escapa a buscar su propósito. Tres pistas (Omar, Paco y Lucía), una persecución y una charla junto al estanque. Cosme le echa de menos «un 3 %»… en realidad, un 97 %. | Investigación y persecución | 🤖 Pip de bolsillo |
| **Zoltán, la máquina de los deseos** | Recreativos | La máquina concede deseos al pie de la letra: «que todo el mundo me haga caso», «ser famoso», «no hacer deberes»… y todo el barrio te persigue. | Huida | 🟡 Ficha dorada |

## Universidad · `Misiones/Loco_Uni.luau`

| Misión | Dónde empieza | Historia | Juego | Recompensa |
|---|---|---|---|---|
| **La luz del Monte del Silencio** | Campus | Rumor: una luz a las tres de la madrugada hace desaparecer a la gente. Subes a la cima entre las 2 y las 5 y ves una escena de cámara con la nave. Huyes de la luz 25 segundos. Los alienígenas bajan a capturarte: es el reality «Terrícolas en apuros» y te quieren de protagonista. A Blorp se le cae la pistola y la usas contra ellos. Liberas a Fermín, el senderista, y a los demás desaparecidos. En comisaría, la agente Inés escribe o «alienígenas» o «gases». | Huida y combate | 🔫 Pistola de rayos (+150) |
| **Mi compañero de piso es un dinosaurio** | Tu casa | Rex es un velocirraptor de una línea temporal sin meteorito que estudia Derecho. Se come tu jamón y tiene el visado temporal caducado. Hay que llevarlo a la facultad de Derecho y defenderlo ante la Aduana del Tiempo. | Huida y juicio | 🦖 Diente de Rex |
| **Las tres Valmar** | Garaje de Cosme | Portales a tres Valmar: una llena de gatos (Bigotes es presidente), otra en la que tú eres el alcalde (y es horrible) y otra aburrida en la que Cosme es normal y feliz. Giro: el Cosme que te acompaña es de otra dimensión; el tuyo se quedó en la aburrida. Decides si lo rescatas. | Exploración y decisión | 🌀 Mando de dimensiones (teletransporte real) |
| **La fiesta de los cambiaformas** | Campus, de noche | Dos invitados saludan con el codo y se ríen tres segundos tarde. Buscas pistas, acusas (puedes equivocarte) y los desenmascaras. | Investigación y combate | 🕶️ Gafas de ver impostores |
| **El examen del universo** | Biblioteca | El Evaluador congela el tiempo: si suspendes, la Tierra repite curso. Tres pruebas: reflejos, un dilema («helado gratis para todos o Cosme se convierte en pato») y los exámenes sorpresa. | Minijuego, decisión y combate | 📜 Diploma del Universo |

## Vida adulta · `Misiones/Loco_Adulto.luau`

| Misión | Dónde empieza | Historia | Juego | Recompensa |
|---|---|---|---|---|
| **El lunes eterno** | Oficinas | Una cafetera de 2240 ha atrapado la oficina en un lunes infinito, porque los lunes se vende un 300 % más café. | Pistas y combate contra las cafeteras | ☕ Taza del tiempo |
| **La deuda galáctica** | Banco | El Banco Galáctico embarga la Tierra por un bocadillo de calamares que Cosme compró en Plutón en 1987. Tres caminos: pagar, leer la letra pequeña o resistir. | Decisión con ramas | 💳 Tarjeta galáctica (+100) |
| **Cosme en una tostadora** | Garaje de Cosme | Cosme, mayor y con miedo a olvidar, se guarda en una tostadora. Los electrodomésticos se rebelan. Escena emotiva: «Siempre vienes». | Combate y rescate | 🍞 La tostadora de Cosme |
| **La noche de los gnomos** | Tu casa, de noche | Los gnomos de jardín reclaman sus tierras ancestrales «desde 1623». Boca abajo no se pueden mover. Eliges paz o duelo con el Gran Gnomo. | Combate y decisión | 🧙 Gnomo aliado |
| **Tu yo malvado** | Tu casa | Tu versión de la dimensión 66-B, con perilla (porque es el reglamento), se ha quedado con tu vida. Tu familia sabe cuál eres tú por las croquetas. Hay que huir del portal y arrancarle la perilla. Luego le das otra oportunidad. | Huida y combate | 🥸 La perilla malvada |

## Mapa (lo que necesita del mapa, con plan B)

| Lugar | Qué pide al mapa | Si no existe |
|---|---|---|
| `GarajeCosme` | Un `StorySpot` con `SpotId = "GarajeCosme"` | En la acera, entre tu casa y la parada del bus |
| `MonteSilencio` / `CimaMonte` | Un modelo `MonteSilencio` con una pieza `Cima`: una montaña cerca del campus | Entre la universidad y la granja |

## Pruebas

`scripts/test-lifestory.luau` juega las 21 misiones de principio a fin. Comprueba lo siguiente:

- Las ofertas en su sitio y a su hora.
- Los combates: impactos por enemigo y que te atrapen.
- Las huidas.
- La madrugada del monte: a mediodía no pasa nada.
- Las decisiones.
- Las recompensas, los recuerdos y los 11 gadgets.
