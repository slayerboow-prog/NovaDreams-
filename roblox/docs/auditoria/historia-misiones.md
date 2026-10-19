# Auditoría de beta tester · Historia y misiones (v117)

Qué se ha revisado: el motor de la historia (LifeStoryService, Sequencer, Validate, EventCatalog, Schedules,
Locations), los guiones de la Saga 1 (`src/shared/LifeStory/Guiones`, generados desde
`docs/historia/reescritura` con `scripts/audit/aplicar-reescritura.luau`), las secundarias, los cambios de
capítulo, las escenas y cinemáticas (SceneService, StageDirector, Cinematics, DialogueUI), las voces (Speech,
CastVoices, StoryAudio), la tarjeta de misión y el GPS, los minijuegos, el prólogo, el panel de pruebas, salir y
volver a mitad de misión, morir en plena misión y lo que la invasión, el mar y el espacio pueden romper de la
historia.

## Pruebas automáticas

| Prueba | Resultado |
|---|---|
| test-playthrough (vidas enteras + «Romperlo» en principales y secundarias, 13 min) | ✅ |
| test-lifestory (~30 min) | ✅ |
| test-saga, test-storyengine, test-storyboot, test-scenes, test-cinematic | ✅ |
| test-reescritura | ❌ antes (Bebe_AprendeACaminar desactualizado) → ✅ ahora |
| test-cineplanos | ✅ las cuentas (`--solo-cuentas`). La auditoría entera contra el mapa (364 750 piezas) no acabó en casi 2 h con la máquina compartida (la guía dice ~2,5 min): se cortó. Con `scripts/audit/cine-planos.luau --quest Bebe_AprendeACaminar` el único guion con cámara cambiada no tiene ningún «PlanRepetido» (los dos «CamaraDentro» son el coche aparcado de las llegadas en vehículo, como antes). **Pendiente: repetir la auditoría entera en una máquina libre** |
| test-escena-al-entrar, test-minijuego-corte, test-mision-visible | ✅ |
| test-voices, test-voices-sim, test-storyaudio | ✅ |
| test-colegio, test-instituto, test-universidad, test-adulto | ✅ |
| test-futbol, test-baloncesto | ✅ |
| test-onboarding, test-transiciones, test-etapas, test-storycontext, test-stagedirector, test-scenecontrol, test-cast, test-mision-grieta, test-tester, test-gps, test-missionzones | ✅ |
| test-invasion (con las comprobaciones nuevas) | ✅ |

Ninguna prueba ha salido «a veces sí, a veces no»: el único fallo de test-reescritura en la primera vuelta
fue porque se estaban regenerando guiones a la vez.

## Bugs encontrados

| # | Gravedad | Qué pasaba | Cómo se reproduce | Arreglo | Commit |
|---|---|---|---|---|---|
| 1 | Alta | Durante una invasión, en plena conversación, escena o prólogo (sin poder moverte) las tropas y las criaturas te pegaban igual: morías a mitad del diálogo y acababas en el hospital con la misión a medias | Lanzar una invasión desde el panel de pruebas y hablar con alguien de la historia cerca de una zona con alienígenas | `InvasionService.storyBusy`: con `InDialogue`, `InPrologue` o una escena del servidor no eres blanco ni recibes daño (test-invasion) | dc7c493 |
| 2 | Media | …y ese escudo no se podía usar para hacer trampa: una escena «Cliente» (la abre la propia pantalla con latidos) no cuenta | Escena «Cliente» abierta + golpe de un alienígena | Solo cuentan las escenas que lanza el servidor (test-invasion) | c603b6d |
| 3 | Alta | Huecos del guion sin rellenar en pantalla: «Somos [nombre de tu grupo]» (Cole04), «[Nombre del grupo] había vuelto a reunirse» (Cole12), «TODOS: «¡[nombre del grupo]!»» (Adu03), «[Nombre]. ¿Estás conmigo?» (Ins01) | Jugar esas misiones | La herramienta traduce `[nombre del grupo]`, `[nombre de tu grupo]`, `[Nombre]` a `{grupo}` / `{nombre}` y da ERROR si queda cualquier `[…]` en una frase; test-reescritura lo comprueba en todos los guiones | b569c10 |
| 4 | Alta | Notas para el equipo dichas por los personajes: en Pan1, Rayo decía «Carismático. Popular. Y precisamente por eso peligroso», Nerea «No es simplemente “la chica buena”», Bruno «Ya no es el niño que intimidaba» y el narrador «Presentarla como: «El jugador está descubriendo…»» | Pan1 · hablar con Bruno al final | En el mapa de Pan1, del PASO 15 solo vale hasta «DIRECCIÓN AAA» (`Lineas`) | b569c10 |
| 5 | Media | Más acotaciones pegadas a frases: Abu «Aparecen las tres opciones.» (Adu02), Omar «Una última. Aparecen tres opciones.» (Adu03), Capitana Ñoz «Pero la misión continúa exactamente igual.» (Saga_15), Cosme «La música comienza muy suavemente. Criatura…» (Saga_18), Abu «El personaje se gira. El primer día…» (Ins01), el narrador «NPC: «¿Eso ha sido… una campana?» NPC: …» (Saga_04), Omar «Voy a por mi almuerzo. Te mira. ¿Vienes?» (Cole09) | Jugar esas misiones | Se quitan desde el mapa de cada guion (`SiTexto … Nunca`, `Reemplazos`); test-reescritura busca esas notas | b569c10, 09e62a2 |
| 6 | Baja | Saga_18: Cosme decía «El hueco se hace más pequeña» a las jugadoras (el arreglo de género tocaba una frase sobre el hueco) | Saga_18 con personaje femenino | `SinGenero` en el mapa | b569c10 |
| 7 | Media | Bebe_AprendeACaminar: el guion generado estaba retocado a mano (plano general repetido) y la herramienta ya no lo regeneraba igual (test-reescritura en rojo desde hace días) | `lune run scripts/test-reescritura.luau` | El cambio de cámara pasa al .md (los dos «PLANO General -> Salón» del final son «Medio -> Madre» y «Reaccion -> Madre»); el generado vuelve a salir igual | b569c10 |
| 8 | Media | La voz leía las acotaciones de en medio o del final («¡Te tengo, terrícola! (Te suelta al ver la pistola. Vuelves a la cima.)» con la voz del alienígena) y la etiqueta del coro («TODOS: …») | Loco_Uni (el monte, los cambiaformas) y Adu03 | `CastVoices.speakable` quita cualquier paréntesis y la etiqueta en mayúsculas del principio (test-voices) | 7c005d2 |
| 9 | Baja | Pan3: «Tú grita: ”¡Camisetas, a diez!”» (sin coma y con comillas inglesas) | Pan3 · el estadio | «Tú, grita: «¡Camisetas, a diez!». Yo cobro.» | 09e62a2 |

## Revisado y sin problemas

- **Invasión y personajes de la historia**: los alienígenas solo «alcanzan» a los vecinos atrapados que crea la
  propia invasión (rescates); los actores de las escenas (StageActors) no se transforman ni huyen. La huida
  (`CrowdService.flee`) solo mueve a la gente de la calle. Los avisos de la invasión esperan en la cola mientras
  hay una cinemática y el temblor de cámara no toca una cámara de escena.
- **Salir y volver, morir, tocar dos veces, alejarse**: «Romperlo» de test-playthrough en las 39 principales y en
  las secundarias (saga, locas, rarezas, aliados, universidad, metro): todas se pueden terminar.
- **Eventos que nadie emite**: cada evento que espera una misión lo emite algún sistema (EventCatalog).
- **Textos largos en el móvil**: ninguna frase de la historia pasa de 200 caracteres (una de 201, en Loco_Uni).
- **Tono 13+**: sin sangre ni palabrotas; «Qué idiota» (Ins05) es lo más fuerte.
- **Quién habla**: todos los que hablan existen en el reparto y tienen voz propia (test-cast, test-voices).

## No arreglado (y por qué)

- **«Alas sobre Valmar» (Invasion_Alas) se ofrece a cualquier adulto joven**, aunque no tenga la licencia de
  piloto ni la nave. No se queda atascada para siempre (te sacas la licencia en el aeroclub y la terminas en la
  siguiente invasión), pero las condiciones de la historia (`Conditions`) no saben nada de licencias. Mejor
  decidirlo con quien lleva el vuelo y la invasión.
- **El mar** (SeaBeastService, SeaEventService) no mira si estás en una conversación. Las conversaciones de la
  historia son en tierra, así que no se ha tocado (es del área del mar).
- Sigue habiendo guiones con notas largas al final del .md (cámara, música, «regla de oro»). Ahora se ven
  porque salen en el informe de cada guion y test-reescritura busca las que se han colado; si sale una nueva, se
  quita desde el mapa (`SiTexto`, `Lineas`).

## Pruebas a mano (en el móvil)

1. **Invasión + conversación**: modo pruebas → «Lanzar invasión»; ve a la plaza y habla con alguien de la
   historia mientras hay tropas cerca. No te tienen que quitar vida hasta que acabe la conversación; al acabar, sí.
2. **Cole04 «Los malotes»** y **Cole12 «El último día»**: en el enfrentamiento con Bruno y en el recuerdo del
   final tiene que salir el nombre de vuestro grupo, nunca «[nombre de tu grupo]».
3. **Ins01**, clase de Historia: Javier dice tu nombre, no «[Nombre]».
4. **Pan1**, al final con Bruno: la charla acaba con «Y otro día es otra cosa»; ni Rayo ni Nerea dicen frases
   sobre sí mismos.
5. **Adu02 y Adu03**: Abu y Omar no dicen «Aparecen tres opciones»; salen directamente las opciones.
6. **Loco_Uni «La luz del monte»**: cuando te atrapan, la voz del alienígena no lee lo de «Vuelves a la cima».
7. **Bebe «Primeros pasos»**: la escena final con mamá/papá en el salón no repite el plano general de la
   esquina.
