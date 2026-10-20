# Auditoría del sistema de cinemáticas, diálogos y acontecimientos

Primera misión del encargo (`docs/cine/encargo-sistema-cinematografico.md`, §15): **auditar lo que ya
existe antes de crear nada nuevo**. Este documento dice qué hay, cómo funciona, qué falla de verdad
(con pruebas), qué podría fallar (por comprobar), qué falta frente al encargo y en qué orden mejorarlo.

Se apoya en la auditoría anterior de planos (`docs/auditoria/cinematicas.md`, v119), que ya arregló que
la cámara se metiera en las paredes y la decoración (`CineOccluders`, `SafeSpot.decorAt`). Eso no se
rehace aquí.

## 0. Resumen corto

- El sistema **ya es grande y bastante sólido**: dos motores de escenas (las cinemáticas viejas y el
  «motor de escenas» con línea de tiempo), conversaciones por turnos con escenificación automática,
  cámara que no atraviesa paredes, voces, música, efectos en el mundo y muchas redes de seguridad
  (controles, cámara e interfaz vuelven siempre). Las pruebas automáticas de todo esto pasan.
- Los nombres que propone el encargo (§8) **casi todos existen ya** con otro nombre o con el mismo
  (hay un `CinematicService` y un `DialogueService`). No hay que crear módulos paralelos: hay que
  completar los que hay.
- Se han encontrado **3 bugs confirmados** y se han arreglado los 3 en esta fase (con prueba):
  1. Palabras que perdían letras en los diálogos («sabíal nombre», «seríal reto», «enseñal anuario»).
  2. El servidor daba una conversación por terminada (o **elegía la respuesta por ti**) a los 3 minutos
     de mandarla aunque siguieras leyendo.
  3. En las escenas del motor, el rótulo grande y su subtítulo podían pisarse en el móvil.
- Lo que más falta frente al encargo no son bugs sino **calidad de dirección y actuación**: solo el 2 %
  de las frases tienen un gesto escrito, no hay retratos en el diálogo, no hay sonido de tecleo ni
  velocidad de texto ajustable, casi ninguna escena deja cambios en el mundo, y el silencio dramático
  casi no se usa.

## 1. Qué se ha mirado de verdad (y qué no)

| Tipo | Qué |
|---|---|
| Código leído entero | `client/Controllers/Cinematics.luau`, `DialogueUI.luau` (la mitad final entera y la cabecera), `Controls.luau`, `UI/SceneGuis.luau`, `server/Services/DialogueService.luau` (pump, answer, vigilante), `shared/LifeStory/Strings.luau` (get), la escena `Grieta_Caen` (`Happenings/Cielo.luau`), el meteorito del catálogo (`StoryFxCatalog.luau`) |
| Código leído por partes | `HappeningClient.luau` (cabecera, interfaz, esperas, `play`), `CinematicService.luau`, `HappeningService.luau` y `SceneService.luau` (cabeceras y limpiezas), `ActorLife.luau` (animaciones), `StoryAudio`/`Speech` (cabeceras), `LifeStory.luau` (cola de cinemáticas), `Main.client.luau` (HUD ocupado), `ReadingTime`, `Sequencer` (API) |
| Sondas propias (borradas después) | longitud de todos los rótulos y subtítulos de las 21 cinemáticas viejas y las 312 escenas del motor; tiempo de lectura de cada tramo de conversación sin pregunta (1380 tramos); conteo de tipos de escena |
| Herramientas de auditoría ya existentes, ejecutadas | `scripts/audit/narrativa.luau resumen` |
| Pruebas automáticas ejecutadas | ver §9 |
| **No** hecho | prueba en Studio, comprobación visual en un móvil real, multijugador real, `test-cineplanos` completo (ver §9) |

## 2. Inventario: qué módulos hay

### 2.1 Los datos (qué cuenta cada escena)

| Qué | Dónde | Notas |
|---|---|---|
| Cinemáticas «viejas» (21) | `shared/LifeStory/Cinematics.luau` | Planos por anclas, subtítulos, rótulos, gestos, música. Nacimiento, cabeceras y finales de capítulo |
| Escenas del motor (312) | `shared/LifeStory/Happenings/*.luau` + `HappeningIndex.luau` | Línea de tiempo con pistas: Camera, Actors, Fx, Sky, Sound, Music, Lines, Dialogue, Titles, Wait, World, Light… 247 de 312 no traen pista Camera en su definición base (son «ligeras»: efectos y frases sin quitarte el control) |
| Guiones reescritos (58) | `shared/LifeStory/Guiones/*.luau` (**generados**, no se editan) desde `docs/historia/reescritura/*.md` con `scripts/audit/aplicar-reescritura.luau`; se montan con `GuionOverlay.luau` | Conversaciones con planos, gestos y pausas; escenas nuevas del motor |
| Misiones y conversaciones | `shared/LifeStory/Misiones/*.luau`, `Quests.luau` | 159 misiones, 4989 frases, 63 pasos de cinemática (`narrativa.luau`) |
| Reparto, voces, emociones | `Cast.luau`, `CastVoices.luau`, `Emotion.luau`, `ActorMoods.luau` | |
| Textos | `Strings.luau` (y las frases escritas en las misiones) | |
| Tiempos de lectura | `ReadingTime.luau`, `SceneTiming.luau` | Un solo sitio para «cuánto se queda una frase» |

### 2.2 El servidor (decide y valida)

| Módulo | Qué hace | Nombre del encargo (§8) |
|---|---|---|
| `server/Services/CinematicService.luau` | Lanza una escena para UN jugador, resuelve sus anclas, espera a que cargue el mapa, marca `InScene` con latido y topes | **CinematicService** (ya existe) |
| `server/Services/HappeningService.luau` | Director de las escenas del motor: actores, esperas, memoria del mundo, saltar con consecuencias, morir/salir | **NarrativeEventService** |
| `server/Services/DialogueService.luau` | Conversaciones por turnos: condiciones, efectos, decisiones, reenvío y vigilante | **DialogueService** (ya existe) |
| `server/Services/SceneService.luau` + `server/LifeStory/StageActors.luau` | Actores y objetos de cada paso de misión, andar, entrar, salir, fundidos | parte de **CharacterAnimationController** (lado servidor) |
| `server/Services/WorldMemoryService.luau` + `shared/LifeStory/StageSets.luau` | Lo que queda en el mundo por tu historia (cráteres…) y los decorados por fase | cambios permanentes del §6 |
| `server/Services/LifeStoryService.luau` | La historia: pasos, misiones, cuándo lanzar cada escena | |

### 2.3 El cliente (cámara e interfaz)

| Módulo | Qué hace | Nombre del encargo |
|---|---|---|
| `Controllers/Cinematics.luau` | Reproduce las cinemáticas viejas: bandas, planos, subtítulos, rótulos, Saltar, recuperación de errores | parte de **CinematicService** (cliente) |
| `Controllers/HappeningClient.luau` | Reproduce las escenas del motor con el reloj del servidor | parte de **NarrativeEventService** (cliente) |
| `Controllers/DialogueUI.luau` + `UI/SpeechBubbles.luau` | Caja y bocadillos, texto letra a letra, tocar para seguir, respuestas | **DialogueUIController** |
| `Controllers/CineCamera.luau` + `shared/CameraShots.luau` + `Controllers/CineOccluders.luau` | Cámara de cine: planos, encuadre, paredes, vuelta suave al juego, red de seguridad | **CameraDirector** |
| `shared/LifeStory/StageDirector.luau`, `ActorStaging.luau` | Escoge planos de la conversación, pausas, acotaciones → acción | dirección automática |
| `Controllers/ActorLife.luau` (+ `WorkAnim`, `AlienAnim`, `AnimalPose`, `PunchAnim`) | Actuación: respirar, mirar, hablar con el cuerpo, gestos, posturas | **CharacterAnimationController** |
| `Controllers/StoryAudio.luau`, `Speech.luau` | Música por intensidad, ambiente, voces sintetizadas (`AudioTextToSpeech`) | sonido |
| `Controllers/StoryFx.luau` + `shared/StoryFxBuild.luau` / `StoryFxCatalog.luau` | Efectos del mundo: meteorito, impacto, portal, grieta… | efectos §6 |
| `Controllers/Controls.luau` | Quita y devuelve el control con un contador por motivo y pregunta de seguridad | recuperación §10 |
| `UI/SceneGuis.luau`, `UI/SceneChain.luau` | Esconder y devolver la interfaz; puente negro entre escenas seguidas | recuperación §10 |
| `Controllers/SceneClient.luau` | Latido al servidor, cortes (morir, reaparecer, teletransporte), esconder a otros jugadores | multijugador §9 |

### 2.4 Las herramientas de depuración

`scripts/test-cinematic.luau`, `test-scenes`, `test-scenecontrol`, `test-stagedirector`,
`test-transiciones`, `test-reescritura`, `test-cineplanos` (+ `scripts/lib/CineGeo.luau`,
`CinePlanos.luau`), `scripts/audit/cine-planos.luau`, `cine-vista.luau`, `cine-extras.luau`,
`cine-guiones.luau`, `narrativa.luau`, `exportar-dialogos.luau`. Esto ya es el **CinematicDebugTools**
del encargo. **CinematicRegistry** = `Cinematics.luau` + `HappeningIndex.luau`.

## 3. Cómo funciona una escena, de principio a fin

1. **Se define** como datos: una cinemática vieja (`Cinematics.luau`) o una escena del motor
   (`Happenings/*.luau` o un guion generado). Las misiones la piden con un paso
   `{ Type = "Cinematic", Id = … }` o con el efecto `Scene = "Id"`.
2. **Empieza en el servidor**: `CinematicService.play(jugador, id)` busca las anclas de ESE jugador
   (su casa, su colegio…), pide al mapa que cargue esas zonas y manda la escena solo a su pantalla. Si
   el id es del motor, delega en `HappeningService.play`, que además mueve actores y lleva el reloj.
3. **Se ve en el cliente**: `LifeStory.luau` mete la cinemática en una cola (`Cinematics.hold`, tope
   180 s) y `Cinematics.play` la reproduce; las del motor las reproduce `HappeningClient`. Las dos:
   bandas negras, `SceneGuis.hide` (toda la interfaz fuera), `Controls.disable` (con pregunta de
   seguridad), cámara `Scriptable`, música y luz de cine, voces y subtítulos con tiempo de lectura.
4. **Saltar**: botón «Saltar» arriba. Vieja: se corta y la historia sigue. Motor: el servidor deja
   hechas las consecuencias.
5. **Si falla o se corta** (error, muerte, reaparecer, teletransporte): `Cinematics.play` lo envuelve en
   `pcall` y devuelve interfaz, controles, cámara, luz y sonido; `HappeningClient` igual; `Controls`
   suelta solo a quien ya no lo necesita cada 2 s; `CineCamera.ensureReleased` no deja la cámara fija.
6. **Multijugador**: todo es de UN jugador. Sus actores viven en su carpeta (`StoryScenes/Scene_<id>`)
   y los demás no los ven; durante tu escena los otros jugadores se esconden en tu pantalla. El
   servidor sabe quién está en escena (`InScene`, latido cada segundo, topes) y lo usan otros sistemas
   (la invasión no te ataca, no salen avisos encima).
7. **Final**: `CinematicDone`/`Done` al servidor, que sigue la historia; la cámara vuelve suave
   (`CineCamera.restore`), el HUD vuelve cuando no queda ninguna escena ni conversación
   (`Main.client.luau`, comprobado en cada fotograma).
8. **Conversaciones**: `DialogueService.play` → el servidor manda trozos hasta cada pregunta →
   `DialogueUI` los enseña (plano de situación, planos de hombro, bocadillos, letra a letra, tocar para
   seguir) → contesta `Next` con la respuesta → efectos en el servidor. Si una cinemática está en
   pantalla, la conversación espera.

## 4. Diagnóstico por gravedad

### 4.1 Bugs confirmados (arreglados en esta fase)

**B1 · Grave para el texto · Palabras que pierden letras en los diálogos.**
`Strings.get` contrae «a el» → «al» y «de el» → «del» al rellenar variables
(`Strings.luau:534` en la versión anterior). Usaba el patrón `%f[%a]`, que solo conoce letras sin tilde:
la «a» final de «sabía», «sería», «enseña», «guiña» se tomaba por la preposición. `DialogueService`
llama a `Strings.get` con variables en **todas** las frases (`DialogueService.luau:142`), así que pasaba
en todas las conversaciones.
Evidencia: la sonda de rótulos dio «La excursión a Villaverde | Paula se **sabíal** nombre de cada
gallina» (el texto escrito en `Happenings/Etapas.luau:449` es correcto). Afectaba a **14 frases**,
entre ellas «te guardaría el sitio» → «guardaríal sitio» (`Uni04_Practicas`), «Sería el reto más
grande» → «Seríal reto» (`Saga_23_Fusion`, `Saga_Acto4`), «Marisa te enseña el anuario» → «enseñal
anuario» (`Cole11_Proyecto`), «Primero decía el año» → «decíal año» (`Cole09_Misterio`).
Arreglo: la contracción mira la letra de antes con UTF-8 (`Strings.contract`). Prueba:
`test-stagedirector` (sección 3: 6 casos y un barrido de **todas** las frases de la historia; con el
código anterior fallan 3 comprobaciones, con el nuevo pasan).

**B2 · Grave para las decisiones · El servidor contestaba por ti a los 3 minutos.**
`DialogueService` pone un plazo de 180 s desde que **manda** un trozo (`DialogueService.luau:270`,
`:297`) y el vigilante, al pasar, contesta la opción 1 o da la conversación por terminada (`:522`). El
cliente no avisaba de que seguía leyendo. Un trozo sin pregunta puede ser largo (el más largo,
`Saga_04_Ventanilla` «Ventanilla2»: 50 frases, **~149 s** solo de lectura según `ReadingTime`, sin
contar voces, pausas ni planos), y además el plazo corre mientras la conversación espera a que acabe
una cinemática. Bastaba un rato sin tocar el móvil. Lo que pasaba entonces (comprobado en el código):
- en un trozo con pregunta, el servidor elegía la respuesta 1 y seguía; cuando tú elegías otra, tu
  `Next` llevaba un número de trozo viejo y **se ignoraba**, y veías las consecuencias de la 1;
- en el último trozo, la historia seguía (la misión avanzaba, otra escena podía empezar) con las frases
  aún en pantalla («misiones que avanzan a destiempo», §15).
Arreglo: mientras la conversación está en pantalla o en cola, `DialogueUI` manda `Alive` cada 20 s
(`DialogueUI.AliveEvery`) y `DialogueService.alive` alarga el plazo (con tope `AliveCap` = 15 min por
trozo). Si el cliente no da señales, la red de seguridad sigue igual (a los 180 s sigue sola). Pruebas:
`test-stagedirector` (sección 8: con la pregunta en pantalla 2,5 s con plazo de 1 s el servidor espera
y cuenta TU respuesta; sin señales sigue sola; con señales para siempre, el tope la acaba) y
`test-cinematic` (sección 3: la caja manda `Alive` de su conversación y deja de mandarlo al cerrarse).

**B3 · Leve (móvil) · Rótulo y subtítulo pisados en las escenas del motor.**
En `HappeningClient.luau:378-405` (versión anterior) el rótulo iba en una caja fija de 50 px centrada
al 44 % de la pantalla y el subtítulo fijo al 52 %. En un móvil (letra 30 px) un rótulo que pasa a dos
líneas mide ~72 px y su segunda línea cae encima del subtítulo. Las cinemáticas viejas ya lo
resolvieron con una columna (`Cinematics.luau:379`, «TitleBlock»), las escenas del motor no. Hay 10
rótulos de más de 30 letras (p. ej. «Pasan los años… y llega el instituto.», «☄️ Han caído tres cosas
del cielo»). Que se vea pisado depende del ancho del móvil y de la letra: **confirmado en el código,
no visto en un móvil**. Arreglo: la misma columna que las cinemáticas viejas. Prueba: `test-cinematic`
(sección 2: el rótulo y el subtítulo van en una columna con `UIListLayout` y tamaño automático).

### 4.2 Ya arreglado antes (se conserva, no se rehace)

- Cámara dentro de paredes y decoración, paredes delante, actores dentro de bancos y parterres
  (`CineOccluders`, `SafeSpot.decorAt/freeForActor`, `CameraShots.fit/clutter/keepAim`): cámara
  dentro 58 → 9, pared delante 62 → 0, atraviesa 11 → 0 (`docs/auditoria/cinematicas.md`).
  Quedan 44 avisos leves en la lista `PENDIENTES` de `test-cineplanos` (grupos cortados en el borde,
  sitios estrechos, llegadas en vehículo).
- Controles, cámara, interfaz, sonido y luz vuelven siempre: al acabar, al saltar, al morir, si falla
  a medias, con una conversación dentro de una cinemática, con dos escenas seguidas (lo prueba
  `test-cinematic`, 1.ª–3.ª parte, y todas las cinemáticas saltándolas).
- Conversaciones sin duplicados (claves `Token:Seq`, reenvíos ignorados), sin quedarse abiertas si el
  servidor las corta o mueres, sin pasarse frases con un doble toque (`TAP_GUARD`), frases que se
  quedan lo que se tarda en leerlas (`ReadingTime`).

### 4.3 Hipótesis (por comprobar; no se han visto fallar)

| # | Hipótesis | Por qué se sospecha | Cómo comprobarla |
|---|---|---|---|
| H1 | **Voces que llegan tarde o no suenan** en escenas con muchas frases seguidas | `Speech.luau` cuenta el cupo de Roblox: 7 frases nuevas por minuto jugando solo. Una escena del motor con 10 frases en 30 s no cabe | Studio: contar en `Output` las frases que esperan cupo en `Grieta_Caen` y en `Saga_04_Ventanilla` |
| H2 | **Desfase voz–texto** en las conversaciones | `DialogueUI` espera a que la voz EMPIECE (`StoryAudio.waitVoice`, tope `WaitText`), no a que acabe; si tocas rápido se corta | Studio con voces; medir |
| H3 | **Subtítulos de abajo demasiado justos en móviles pequeños** | La banda mide el 11 % del alto (~33 px útiles en un móvil apaisado de 375 px) y la letra baja hasta 12 px. La frase más larga mide 133 letras: por cuenta cabe en 2 líneas, pero va justa | Captura en un móvil de 667×375 con `Uni06_Ceremonia` |
| H4 | **Escena que nunca empieza** si la cinemática anterior se atasca | Las conversaciones esperan a `Cinematics.isPlaying()` sin tope propio (`DialogueUI.luau:1100`; sí lo tienen `Cinematics.hold` y `HappeningClient.isPlaying`); el tope real es `Cinematics.HoldMax` = 180 s | Forzar en `test-cinematic` una cinemática que no acaba |
| H5 | **Bocadillo y caja a la vez** un instante cuando el bocadillo sale y entra de cuadro | `DialogueUI` cambia caja/bocadillo cada 0,25 s según se vea | Comprobación visual |
| H6 | **Gestos de cuerpo entero con rigs que no son R15** (criaturas, alienígenas) | `ActorLife.play` usa las animaciones R15 de Roblox (`ActorLife.luau:70-80`); con otro rig, probablemente no encuentra sus articulaciones y el gesto no se hace (no rompe, pero no actúa). No comprobado | Lista de actores con rig no R15 en `Cast` y `StoryCreatures` |
| H7 | **Planos que no dicen nada** (sin función) en las escenas generadas | La sonda de planos mira geometría, no intención; el encargo pide función por plano | Revisión de guion (fase 2) |

### 4.4 Lo que NO está (no son bugs, son huecos)

- **Lip sync**: no hay. Las caras no mueven la boca. No se debe decir que lo hay.
- **Retrato** de quien habla: no hay (solo el nombre).
- **Velocidad de texto ajustable** y **sonido de tecleo**: no hay (`TYPE_SPEED` = 55 fijo).
- **Escenas para varios jugadores** (de grupo o globales): todas son individuales; el modo
  espectador (`Audience = "Nearby"`) existe en el código pero **ninguna escena lo usa** (0 de 312).
- **Cambios del mundo**: solo 1 escena de 312 deja algo en el mundo (`Grieta_Caen`: los cráteres).
- **Gestos escritos**: 102 de 4989 frases (2 %); el resto se adivina por el texto (`Emotion.of`).

## 5. Huecos frente a cada parte del encargo

| § | Qué pide | Qué hay | Falta |
|---|---|---|---|
| 1 | Analizar antes | Este documento | — |
| 2 | Dirección: tipos de plano, reacciones, silencios, transiciones | Planos de situación, hombro, dos, primer plano, reacción, órbita, seguimiento; cortes, fundidos, destello | **Silencios** (casi ninguna escena tiene un hueco sin frase después de un gran momento); planos de reacción de secundarios en las escenas del motor |
| 3 | Cámara reutilizable, sin atravesar, siempre vuelve | `CineCamera` + `CameraShots` + `CineOccluders`, `ensureReleased`, `restore` | Puntos de cámara colocados en el escenario (todo es por anclas + offset); 44 avisos leves |
| 4 | Diálogos: nombre y retrato, letra a letra, velocidad, saltar a entero, respuestas, tecleo, móvil, sin duplicados | Todo menos retrato, velocidad ajustable y tecleo | Retrato, ajuste de velocidad, sonido de tecleo; B2 ya arreglado |
| 5 | Actuación: cabeza, manos, miradas, emociones, objetos | `ActorLife`: miradas de grupo, respiración, gestos por emoción, posturas, oficios | Gestos escritos por frase (2 %); objetos en la mano en escenas; animaciones propias por acontecimiento; nada de lip sync |
| 6 | Acontecimientos en el mundo (meteorito en 10 pasos) | `Grieta_Caen` cumple 8 de 10 (ver §8) | Silencio tras el impacto; más escenas que dejen huella |
| 7 | Continuidad | Condiciones `If` (25 % de las frases), memoria del mundo, `StoryContext` | Comprobación previa automática «dónde está cada uno» antes de cada escena |
| 8 | Arquitectura por pasos con fin claro | Pistas por tiempo + esperas del servidor (`Wait`, `Until`) | Las cinemáticas viejas van por tiempo fijo; pasarlas al motor |
| 9 | Multijugador | Todo individual, servidor valida, latido, topes | Escenas de grupo/globales (no hay ninguna) |
| 10 | Recuperación de errores | Muy completa (§4.2) | Registro de errores: solo `warn` en el cliente, el servidor no se entera |
| 11 | Pruebas por fases | Muchas pruebas automáticas | Pruebas en Studio y visuales: pendientes |
| 13 | Rendimiento | Topes de partículas en el catálogo, `CineOccluders` con tope de 9000 piezas | Medir en móvil |
| 14 | Entrega por cinemática A–P | No existía | Ejemplo en §8 |

## 6. Arquitectura propuesta (reutilizando lo que hay)

No se crean módulos nuevos con los nombres del encargo: ya existen. Cada nombre del encargo apunta a lo
que ya hay y se completa ahí.

| Encargo | Es (y se completa en) |
|---|---|
| CinematicService | `server/Services/CinematicService.luau` (servidor) + `Controllers/Cinematics.luau` (cliente) |
| NarrativeEventService | `server/Services/HappeningService.luau` + `Controllers/HappeningClient.luau` + `Sequencer` |
| CameraDirector | `Controllers/CineCamera.luau` + `shared/CameraShots.luau` + `CineOccluders` |
| DialogueService | `server/Services/DialogueService.luau` |
| DialogueUIController | `Controllers/DialogueUI.luau` + `UI/SpeechBubbles.luau` |
| CharacterAnimationController | `Controllers/ActorLife.luau` (cliente) + `StageActors`/`SceneService` (servidor) |
| CinematicRegistry | `shared/LifeStory/Cinematics.luau` + `HappeningIndex.luau` (+ `Guiones` generados) |
| CinematicDebugTools | `scripts/test-*` de cine y `scripts/audit/cine-*` |

Dirección a medio plazo: **un solo motor**. Las 21 cinemáticas viejas pasan poco a poco al motor de
escenas (ya empezó: el nacimiento se ve con la escena del motor `Bebe_NacimientoCuna` en lugar de la cinemática vieja `Bebe_Nacimiento`, `Happenings/Colegio.luau:20`). Así cada escena es una
secuencia de pasos con condición de final (§8 del encargo: esperas del servidor, `Until`), no tiempos
fijos, y hay un solo sitio para arreglar cosas.

## 7. Plan por fases (cada una con sus pruebas)

| Fase | Qué | Pruebas |
|---|---|---|
| **1. Auditoría y arreglos seguros** (esta) | B1, B2, B3 | `test-stagedirector`, `test-cinematic` + las rápidas (§9) |
| 2. Diálogo completo | Retrato de quien habla (el mismo dibujo del HUD o una cámara a la cara), velocidad de texto en el menú (lenta/normal/rápida), sonido de tecleo discreto que se calla con la voz | `test-cinematic` (la caja no se sale con 4 velocidades y textos de 140 letras), `test-hud` (menú), captura en móvil |
| 3. Registro de errores | Que el cliente avise al servidor cuando una escena falla (`Cinematics`/`HappeningClient`/`DialogueUI`) y quede en el log del servidor | `test-cinematic` (una escena rota manda el aviso) |
| 4. Actuación | Gestos escritos en las 20 escenas más importantes (desde los `.md` de reescritura, regenerando), objetos en la mano, reacciones de secundarios; rigs no R15 (H6) | `test-reescritura`, `test-stagedirector`, `test-actors` |
| 5. Acontecimientos | `Grieta_Caen` con silencio y segundo impacto en cámara; plantilla «meteorito en 10 pasos» para las demás escenas grandes; decidir qué deja huella (memoria del mundo) | `test-scenes`, `test-worldmemory`, `test-cineplanos` |
| 6. Un solo motor | Pasar las cinemáticas viejas al motor una a una | `test-cinematic`, `test-scenes`, `test-cineplanos` |
| 7. Multijugador | Primera escena de grupo (dos amigos en la misma misión) o espectadores cercanos | prueba nueva con dos jugadores de mentira; Studio con 2 jugadores |
| 8. Validación en Studio y móvil | H1–H5 | Studio + capturas |

## 8. Ejemplo de entrega por cinemática (A–P): «Grieta_Caen»

Elegida porque es el «meteorito» del encargo (§6) y la escena de referencia del motor.

- **A. Objetivo narrativo**: la Grieta deja de ser una rareza del cielo: algo ha llegado a Valmar.
  Empieza la búsqueda.
- **B. Contexto**: misión `Saga_02_Grieta`, paso 2 (`Misiones/Saga_Acto1.luau:52`). Estás en el garaje
  de Cosme con Cosme y Pip; el medidor de Cosme acaba de pitar. Ya viste el primer rasguño de la
  Grieta (`Grieta_Rasguno`).
- **C. Personajes**: Cosme (inventor, nervioso pero valiente), Pip (su ayudante, miedoso y sarcástico),
  Chispa (la criatura del cráter), tú.
- **D. Guion**: la Grieta se ilumina; Pip: «La Grieta está abierta». Cosme lo ve. ¡Cúbrete! Caen tres
  estrellas verdes (parque, patio del cole, camino al cole). Del cráter del parque sale algo pequeño y
  verde que huye. Narrador: tres cosas han caído. Pip: «Tres impactos. Tres objetos». Cosme: «No. Tres
  mensajes». Rótulo: «Han caído tres cosas del cielo · Busca los cráteres humeantes».
- **E. Guion técnico** (`Happenings/Cielo.luau:59`, 16,5 s):

  | # | Segundo | Plano | Función |
  |---|---|---|---|
  | 1 | 0–1,6 | Travelling desde el garaje que gira al cielo (zoom 62→55) | Situación y mirada a la Grieta |
  | 2 | 1,6–2,6 | Fijo junto a ti mirando a la Grieta, cámara en mano, corte seco | Peligro: «¡Cúbrete!» |
  | 3 | 2,6–4,6 | Sigue al meteorito 1, destello | La caída (trayectoria) |
  | 4 | 4,6–7 | Fijo en el parque | El impacto y el cráter |
  | 5 | 7–10 | Órbita alrededor del cráter | Chispa sale y huye |
  | 6 | 10–13,5 | Fijo en el garaje mirando a Pip, fundido rápido | Reacción |
  | 7 | 13,5–16,5 | Se aleja de ti y sube al cielo | Cierre y rótulo |

- **F. Diálogos**: 8 frases (`Lines`), dos según si te cubriste o no.
- **G. Animaciones**: miradas a la Grieta y a ti, miedo (Pip), sorpresa (Cosme), «Point» (Cosme, R15 de
  Roblox `507770453`), Chispa corre. Sin lip sync.
- **H. Efectos**: cielo «GrietaVerde», destello de la Grieta, 3 meteoritos (estela, fuego, humo,
  chispas) con impacto (destello, onda, bola de fuego, humo, escombros con física, temblor, mancha
  quemada), «Poof» al irse Chispa.
- **I. Sonido**: «Momento» al empezar, «Whoosh» de cada meteorito, «Boom» de cada impacto, voces.
- **J. Mundo**: tres cráteres humeantes que **se quedan** (`Cielo.Crater.Parque/Patio/Camino`,
  `WorldMemoryService`). Temporal: el cielo verde (se quita al final).
- **K. Misiones**: al acabar, el paso siguiente pide buscar los cráteres; la espera «¡Cúbrete!» cambia
  la frase de Pip (no cambia la misión).
- **L. Archivos**: `shared/LifeStory/Happenings/Cielo.luau`, `shared/StoryFxCatalog.luau`,
  `shared/StoryFxBuild.luau`, `shared/LifeStory/StageSets.luau`, `Misiones/Saga_Acto1.luau`; guion en
  `docs/historia/reescritura/Saga_02_Grieta.md` (la escena se dejó como estaba al reescribir).
- **M. Implementación**: escena del motor (servidor `HappeningService` + cliente `HappeningClient`).
- **N. Pruebas**: `test-scenes` (valida la escena y sus pistas), `test-cinematic` (cámara y controles
  vuelven en escenas del motor), `test-cineplanos` (encuadres).
- **O. Errores pendientes** (frente al meteorito en 10 pasos del encargo):
  1–7 sí (cielo, trayectoria, efectos que crecen, reacciones, impacto en un punto, polvo/luz/partículas,
  consecuencias que se quedan). 10 sí (empieza la búsqueda).
  8 **no**: no hay silencio después del impacto (el narrador habla a los 5,2 s, justo al caer).
  9 a medias: reaccionan Pip y Cosme, pero en el plano 6, lejos del cráter.
  Además: los impactos 2 y 3 no se ven en cámara; el temblor escrito (1,8 s) es antes de los impactos
  (los impactos traen su propio temblor). El rótulo de 33 letras era uno de los que podían pisar el
  subtítulo en el móvil (B3, arreglado).
- **P. Cómo validarla**: en Studio, misión `Saga_02_Grieta` paso 2 (o el modo pruebas de escenas):
  mirar que los tres meteoritos salen de la Grieta, el temblor al caer, Chispa huye, el rótulo y su
  subtítulo no se pisan en el emulador de móvil, y que al acabar vuelven la cámara y los controles.
  Repetir pulsando «Saltar» a mitad: deben quedar los tres cráteres.

## 9. Pruebas de esta fase

Hechas con Lune, fuera de Roblox. **No** hay prueba en Studio ni comprobación visual en móvil.

| Prueba | Antes de los cambios | Después |
|---|---|---|
| `test-compile` | ✅ 812 archivos | ✅ 812 archivos |
| `test-cinematic` | ✅ (580 s) | ✅ (582 s), con las comprobaciones nuevas de B2 (`Alive`) y B3 (`TitleBlock`) |
| `test-stagedirector` | ✅ | ✅, con las nuevas de B1 (contracciones y barrido de 14 frases) y B2 (vigilante) |
| `test-scenecontrol`, `test-scenes`, `test-transiciones` | ✅ | ✅ |
| `test-reescritura`, `test-hud`, `test-clientboot`, `test-serverboot` | ✅ | ✅ |
| `test-storycontext`, `test-storyengine` | — | ✅ |
| `test-lifestory` | — | sin terminar: 462 ✅ y 0 ❌ cuando lo cortó el tope de 25 min (iba con otras 12 pruebas a la vez) |
| `test-cineplanos` | no ejecutada en esta fase (10–11 min y construye el mapa; los cambios no tocan cámara ni posiciones de actores) | — |

Con el código anterior, las comprobaciones nuevas de B1 fallan (3 de 3); las de B2 y B3 no existían
(el código anterior no tenía `Alive` ni `TitleBlock` en las escenas del motor).

## Fase 2 · Diálogo completo

Segunda fase del plan (§7): la caja de las conversaciones. **No hay sistema nuevo**: se ha completado
`DialogueUI` (la caja), `SpeechBubbles` (los bocadillos), `StoryAudio` (la voz) y `SettingsService`
(los ajustes que se guardan). Las cuentas nuevas van en dos módulos pequeños y puros, para poder
probarlas: `shared/LifeStory/TextSpeed.luau` (velocidad y tecleo) y `shared/LifeStory/DialogueLook.luau`
(retrato y medidas de la caja). `DialogueService` (servidor) no ha hecho falta tocarlo: ya manda quién
habla (`Id`, `Name`, `Me`, `Narrator`, `Direction.Remote`), que es todo lo que necesita el retrato.

### Qué ha cambiado

1. **Retrato de quien habla.** A la izquierda del texto sale una foto redonda:
   - si quien habla está en la escena (un personaje, Cosme, un alienígena o tú), **su cara**: una copia
     de su cabeza con lo que lleva puesto (pelo, gafas, gorra) dentro de un `ViewportFrame`, hecha una
     vez por personaje;
   - si no se puede (no está cerca, habla por teléfono…), una **insignia** con su inicial (con tildes y
     ñ) en el color de su ropa del reparto (`Cast`), oscurecido para que la letra blanca se lea. Los
     seres de otro mundo (los que brillan en `Cast`: Pip, Cósimo, Don Escamas…) llevan el borde del
     color de su brillo. Al teléfono, un icono 📱 (o 💬, 🔊… según `StageDirector.RemoteIcons`).
   - tú, sin tu personaje cerca: la foto de tu avatar de Roblox (`rbxthumb://`, sin descargar nada) con
     tu inicial debajo por si no carga;
   - el narrador no lleva retrato. Con bocadillo encima del personaje, la caja sigue siendo la pastilla
     «Toca para seguir» (sin retrato: la cara ya se ve en el mundo).
2. **Velocidad del texto** en el menú: **💬 Velocidad del texto: Lento / Normal / Rápido /
   Instantáneo** (30, 55 —la de siempre—, 110 letras por segundo, o la frase entera de golpe).
3. **Tocar**: un toque mientras se escribe → la frase sale entera (no se pasa); otro toque → la
   siguiente. Un toque justo después de salir entera no cuenta (`ReadingTime.TAP_GUARD`, 0,35 s): así
   un doble toque no se come una frase. Las pausas escritas también se acaban tocando.
4. **Sonido de tecleo**: un «tic» muy suave cada pocas letras (como mucho 12 por segundo), con el
   volumen de **🔔 Efectos** (`Config.Sounds.DialogoTecla`, un sonido de Roblox que ya existe: no hay que
   subir nada). Se calla en Instantáneo y mientras suena (o se está esperando) la voz de la frase.
5. **Voz y texto a la vez (H2).** Si se sabe lo que dura la voz de la frase (`StoryAudio.voiceLength`),
   en Lento y Normal el texto se acompasa para acabar al 85 % de la voz, sin bajar de la mitad ni subir
   del doble de la velocidad elegida. En Rápido e Instantáneo manda lo que eligió el jugador.
6. **Bocadillo y caja a la vez (H5).** Antes, cuando el bocadillo se salía de plano y volvía, durante
   hasta 0,25 s se veía la frase en los dos sitios. Ahora, mientras la frase va en la caja, el bocadillo
   está **callado** (`SpeechBubbles.mute`: se sigue calculando si se vería, pero no se dibuja), vuelve
   al bocadillo solo si lleva 0,3 s visible, y siempre se calla uno antes de enseñar el otro. Se mira
   en cada fotograma, no cada 0,25 s.
7. **Frases largas (H3).** La caja crece hacia arriba con el texto (ya lo hacía). Se ha medido con la
   frase más larga de verdad de las conversaciones (**201 letras** con un nombre de jugador de 20
   letras): cabe en 5 líneas, con retrato, en móviles de 640×360, 667×375 y 844×390 **sin encoger la
   letra** por debajo del 0,8 de siempre. En los subtítulos de las escenas (la banda negra de abajo),
   el más largo es de **127 letras** con el nombre delante; antes cabía con letra de 12–13 px. Ahora el
   subtítulo va pegado abajo, puede crecer unos píxeles por encima de la banda (mínimo 44 px) y no baja
   de 13 px: el más largo sale con 15–16 px en esos móviles (cuenta, no visto en un móvil).
8. **Móvil.** Las respuestas miden al menos 44 px de alto en pantalla táctil (y letra un poco mayor), la
   pastilla «Toca para seguir» también, y la caja respeta la muesca y la barra de Roblox
   (`ScreenInsets = CoreUISafeInsets`). No se ha escondido ningún control.

Lo de la fase 1 sigue igual: el latido «Alive» de las conversaciones y `Strings.contract`.

### Cómo se usa la velocidad del texto

- En el juego: **ValPhone → Ajustes → Juego → 💬 Velocidad del texto** (o la ventana MENÚ). Cada toque
  pasa a la siguiente: Lento → Normal → Rápido → Instantáneo → Lento. Se nota en la frase siguiente.
- Se guarda con la partida **sin campo nuevo ni DataStore nuevo**: va dentro de los ajustes de sonido
  que ya existían (`data.Audio.TextSpeed`), con el mismo remoto que los volúmenes (`AudioVolume`,
  `("Set", "TextSpeed", valor)`). Por eso, como los volúmenes, se queda al empezar una vida nueva. Al
  entrar llega en el atributo del jugador `TextSpeed`. Lo que no vale se queda en Normal.

### Pruebas de esta fase

Con Lune, fuera de Roblox. **No** hay prueba en Studio ni captura en un móvil real.

| Prueba | Resultado | Qué comprueba de nuevo |
|---|---|---|
| `test-stagedirector` | ✅ | sección 10: las 4 velocidades, el botón del menú, tocar (pausa / entera / no se come / siguiente), acompasar con la voz, tecleo; **dónde se guarda** (SettingsService con su remoto: entra en Normal, se guarda en `data.Audio.TextSpeed`, lo raro no se guarda, cambiar un volumen no la borra, vuelve al entrar, sin campo nuevo en `DataService`); **retrato de repuesto** (Cosme, Pip y Cósimo con borde, quien no está en el reparto, tú, teléfono, narrador, iniciales con tilde y ñ); **la frase más larga cabe** en la caja (4 pantallas) y en el subtítulo (2 móviles) |
| `test-cinematic` | ✅ | sección 3: retrato con la inicial y la cara del personaje; en Lento se escribe letra a letra con «tic»; un toque = entera sin pasar, otro enseguida no se la come, otro después pasa; Instantáneo sale de golpe y sin «tic»; el narrador sin retrato; y todo (cámara, controles, HUD) vuelve después |
| `test-hud` | ✅ | la fila «Velocidad del texto» en Ajustes → Juego y que Main.client la pone en el menú y la guarda |
| `test-compile`, `test-clientboot`, `test-serverboot`, `test-scenes`, `test-reescritura`, `test-scenecontrol` | ✅ | — |
| `test-audiomix`, `test-graphicsprefs` | ✅ | (también usan SettingsService; a las dos les faltaba el remoto `ShooterPrefs` en su doble y fallaban ya antes de esta fase: arreglado en la prueba) |

### Lo que queda pendiente

- **Verlo en Studio y en un móvil de verdad**: el retrato (que la cara salga bien encuadrada en niños,
  bebés y criaturas grandes), el tamaño de la letra y el «tic» (que no moleste).
- **H2 a medias**: el texto solo se acompasa si la voz ya ha empezado cuando se empieza a escribir (se
  espera como mucho `WaitText`, 0,6 s). Si la voz tarda más, la frase se escribe a la velocidad elegida.
  Tampoco hay sincronización labial (no la hay en el juego).
- **H1** (voces que llegan tarde por el cupo de Roblox) y **H4** (escena que no empieza si la anterior
  se atasca): sin tocar en esta fase.
- Las escenas del motor y las cinemáticas viejas no tienen retrato en sus subtítulos (solo el nombre
  delante): es otra caja, la banda de cine.
- La velocidad del texto se aplica a las conversaciones (la caja y sus bocadillos); los subtítulos de
  las escenas siguen su propio tiempo de lectura (`ReadingTime`), porque van con el reloj de la escena.
- Siguiente fase del plan: la 3 (registro de errores del cliente en el servidor).

## Fase 3 · Si algo falla en tu pantalla: se avisa al servidor y todo vuelve

Tercera fase del plan (§7). Antes, cuando una escena o una conversación fallaba en el cliente, se
recuperaba casi todo, pero **solo se escribía un `warn` en tu pantalla**: el servidor no se enteraba y
nadie podía saber qué escenas fallan de verdad en las partidas. Además, un fallo pequeño (una frase, un
efecto) cortaba la escena entera.

### Qué se ha hecho

1. **Aviso al servidor.** Nuevo `client/Controllers/SceneReport.luau`. Cuando algo falla manda por el
   remoto de siempre de las escenas (`Remotes.Scene`, el del latido) `("Error", aviso)` con solo esto:
   **de dónde** (`Cinematics`, `Happening`, `Dialogue`, `Camera`, `Director`), **qué escena**, **qué paso**
   (`Shot`, `Lines`, `Wait`, `Open`…), **de qué tipo** (`Error` = algo falló; `Watchdog` = un paso no acabó
   a tiempo; `Abort` = se cortó la escena) y el **mensaje limpio**. Sin nombre, sin id de usuario, sin
   rutas de `Players.<nombre>` y sin números largos (`shared/LifeStory/SceneFaults.clean`). En tu pantalla
   como mucho 8 avisos por minuto y el mismo una vez cada 30 s (un fallo en cada fotograma no inunda la red).
2. **En el servidor.** `server/LifeStory/SceneErrorLog.luau` lo vuelve a limpiar (no se fía del cliente),
   lo limita por jugador (6 seguidos y luego uno cada 15 s) y para todo el servidor (60 por minuto), lo
   escribe en el log (`[SCENE] fallo de cliente Error Happening/Grieta_Caen/Shot (x3): …`, **sin decir de
   quién**) y lo cuenta: total, por escena y paso, por fuente, por tipo y cuántos jugadores distintos
   (solo el número). `SceneErrorLog.summary()` da los contadores. **Nada se guarda en el DataStore.**
   Lo recibe `CinematicService` (el mismo remoto `Scene`).
3. **Cada paso en su propia red.** En las cinemáticas viejas (`Cinematics`) cada plano, frase, gesto y
   rótulo va en su `pcall`; en las escenas del motor (`HappeningClient`) cada suceso de cada pista (Fx,
   Lines, Titles, Sky, Sound, Music, Light, Ambience, Fade, Wait) y la cámara; en las conversaciones
   (`DialogueUI`) cada frase. **Un paso que falla se salta y la escena sigue.** Si fallan 4 pasos (lo
   normal cuando es la cámara, que falla en cada fotograma), la escena se corta como si la saltaras, en
   vez de quedarse con la cámara rota.
4. **Vigilante en cada espera.** En las escenas del motor, cuando la escena se para a esperar (una
   espera `Wait`), el servidor la reanuda como mucho a su tope (`Seconds`/`Timeout`, máximo 120 s). Si ese
   aviso no llega (se perdió), antes la escena se quedaba parada para siempre en tu pantalla. Ahora, a
   los `tope + 15 s` sigue sola y se avisa (`Watchdog`).
5. **H4 resuelto: la conversación ya no espera para siempre.** Si una cinemática se queda atascada en la
   cola, la conversación espera como mucho `DialogueUI.SceneWaitMax` = 200 s (más que el tope de la cola,
   180 s), avisa y sale igual.
6. **La conversación se retoma.** Si la caja falla a media conversación, se cierra, se avisa y pide al
   servidor que le vuelva a mandar el trozo (`"Again"`, nuevo en `DialogueService.again`, como mucho 2 veces
   por conversación): la conversación vuelve a salir desde ese trozo. Si vuelve a fallar, se queda cerrada
   y el vigilante del servidor la sigue sola (como antes). Si falla solo una frase, se salta esa frase.
   Si falla el plano de la conversación (`StageDirector.camera`), se avisa y se queda el plano que había.
7. **Red de seguridad final** (`SceneReport.recover`): un momento después de cualquier fallo, si ya no
   queda ninguna escena ni conversación en pantalla (ni el puente negro entre dos escenas), se devuelve lo
   que pudiera haberse quedado: la cámara (`CineCamera.ensureReleased`), los controles de las escenas
   (`Cinematica`, `Escena`, `Dialogo`), **el giro del personaje** (`AutoRotate`, que las conversaciones
   apagan para girarte hacia quien habla: si no volvía, el personaje se quedaba «congelado» mirando a un
   lado), la interfaz (nuevo `SceneGuis.forceRestore`) y las marcas `InCinematic`/`InDialogue`. Si aún
   queda una escena, no toca nada (es de esa escena).
8. **Voces que llegan tarde (H1/H2).** Con el cupo de voces de Roblox (7 frases nuevas por minuto
   jugando solo) una voz podía sonar mucho después de su subtítulo. Ahora, si llega tarde, **no se dice**
   y el subtítulo sale igual: en una escena, si llega pasada la mitad del tiempo que la frase está en
   pantalla (mínimo 1,2 s); en una conversación, si llega más de 6 s tarde (`StoryAudio.lateLimit`, pasado
   a `Speech.say` como `MaxDelay`). La voz se queda generada: si la frase se repite, suena a tiempo. El
   texto **nunca** espera a la voz más de lo que ya esperaba (0,6 s).
9. La vuelta suave de la cámara (`CineCamera.restore`) ya devolvía la cámara si fallaba; ahora además
   avisa (`Camera/Restore/Glide`).

### Revisado

- `Cinematics.play`, `HappeningClient.play` (preparar, bucle, cámara, cada pista, esperas, recogida),
  `DialogueUI.process`/`processQueue`/`frameShot`, `CineCamera.restore`, `SceneGuis`, `Controls`,
  `DialogueService` (remoto y vigilante), `CinematicService.init`, `StoryAudio.speak`, `Speech.say`
  (cupo, `MaxDelay`, `Cancelled`).
- Lo que ya había (fases 1 y 2, §4.2) se conserva: los `pcall` grandes siguen, ahora con aviso.

### Probado técnicamente (Lune, fuera de Roblox)

| Prueba | Qué comprueba de nuevo |
|---|---|
| `test-cinematic` sección 5 | Se hace fallar **a propósito** cada paso (`SceneReport.Inject`) y se comprueba que se avisa con su fuente, paso y tipo, que la escena termina (o sigue sin ese paso) y que **todo vuelve** (controles, cámara, campo de visión, HUD, `InCinematic`, `InDialogue`, nombres): cinemáticas viejas en Shot, Line, Title, Anim y Play; escenas del motor en Shot, Lines, Titles, Fx, Sound, Play y Compile; la espera que el servidor nunca acaba (Watchdog) y que una espera normal **no** se acaba antes; conversaciones en Line, Open y Ask (se avisa, se cierra y pide «Again»), que se retoma cuando el servidor la reenvía, que una frase rota se salta y la conversación sigue, que el plano roto no impide leerla; H4 con una cinemática atascada en cola; la vuelta suave de la cámara rota; la red de seguridad (devuelve cámara, controles, giro, interfaz y marcas sin escena, y no toca nada con una escena en pantalla); el límite de avisos; y que ningún aviso lleva el nombre ni el id del jugador |
| `test-stagedirector` sección 8 y 11 | `DialogueService.again` (reenvía solo SU conversación, como mucho 2 veces); `SceneFaults` (limpia nombre, id, rutas y saltos de línea, corta sin romper letras, rechaza fuentes raras); `SceneErrorLog` (log `SCENE` sin datos del jugador, límite por jugador y por servidor, contadores, inválidos, sin DataStore) |
| `test-storyaudio` | `StoryAudio.lateLimit` (mitad del tiempo en pantalla, mínimo 1,2 s; 6 s en conversación) y que llega a `Speech.say` |

Resultados de esta fase: ver «Pruebas de la fase 3» abajo.

### Probado visualmente

**Nada.** No hay prueba en Studio ni en un móvil en esta fase.

### Pendiente

- Ver en Studio el log del servidor con un fallo real (la ruta está probada fuera de Roblox).
- Un panel para leer `SceneErrorLog.summary()` en el juego (ahora solo en el log).
- H1 de verdad (cuántas voces se quedan sin decir en `Grieta_Caen` o en `Saga_04_Ventanilla` por el
  cupo): solo se puede medir en Studio con voces.

### Pruebas de la fase 3

Con Lune, fuera de Roblox. **No** hay prueba en Studio ni comprobación visual.

| Prueba | Resultado |
|---|---|
| `test-cinematic` | ✅ 159 comprobaciones (la sección 5 es nueva) |
| `test-stagedirector` | ✅ (secciones 8 y 11 nuevas) |
| `test-storyaudio` | ✅ (voces que llegan tarde) |
| `test-compile`, `test-clientboot`, `test-serverboot`, `test-hud`, `test-scenes`, `test-reescritura`, `test-scenecontrol`, `test-transiciones`, `test-storyengine`, `test-storycontext`, `test-playthrough`, `test-cast`, `test-saga` | ✅ |

Lo que estas pruebas encontraron y se arregló en la misma fase:

- La red de seguridad no soltaba la cámara si se había quedado puesta la marca `InCinematic` (la cámara
  creía que seguía habiendo escena): ahora quita primero las marcas que sobran.
- Con una cinemática atascada en cola (H4), la conversación salía, pero al cerrarla **la cámara no
  volvía** (esperaba a una cinemática que nunca empezaba). La caja ahora solo cede la cámara a una
  cinemática que está **en pantalla**, no a una que espera turno.
- (Prueba) el doble del `Humanoid` no tenía `HipHeight` y dos escenas de verdad (`Pan2_Alarma`,
  `Adu01_Buzon`) fallaban en la prueba al medir la altura de un actor; en Roblox siempre existe.

## Fase 4 · Actuación: los personajes gesticulan en las frases importantes

Cuarta fase del plan (§7). Antes, solo el **1 %** de las frases de los guiones reescritos (38 de 3840)
llevaba un gesto o una emoción escritos; el resto se adivinaba en el momento por el texto
(`Emotion.of`: «¡Hola!» → saluda, «lo siento» → triste…), y una frase neutra se decía con las manos
«hablando», sin más.

### Qué se ha hecho

1. **Gestos escritos en los guiones, en su fuente.** Los guiones de `src/shared/LifeStory/Guiones` son
   **generados** y no se tocan a mano. Las acotaciones se han escrito en sus fuentes
   (`docs/historia/reescritura/*.md`), como las escribiría un guionista: «COSME: (señala) ¡Mira eso!»,
   y después se han regenerado los 58 guiones con `scripts/audit/aplicar-reescritura.luau --todas`
   (**0 errores**).
   - Para escribirlas: herramienta nueva `scripts/audit/gestos.luau` (`cobertura`, `proponer <Id>`,
     `escribir <Id>…` o `--todas`). Elige el gesto por lo que dice la frase (saludo, risa, señalar «¡mira!»,
     miedo «¡cuidado!», enfado, tristeza «lo siento», «sí» → asiente —«Si soy…» sin tilde no—, «no» → niega,
     duda «no sé» → hombros, «mmm» o «…» → pensativo, alegría «¡genial!», sorpresa «¿en serio?», pregunta
     → ceja levantada) y, si la frase no dice nada especial, por **cómo es quien habla**: Cosme en jarras,
     señalando, sonriendo o inclinándose; Pip con los brazos cruzados o encogiéndose de hombros; Bigotes
     con los brazos cruzados; Cósimo sonriendo de anuncio; Varkun pensativo y apartando la mirada…
   - Solo escribe palabras que el importador entiende (`Reescritura.gestureOf`) y nunca en el narrador.
   - **El guion generado es el mismo salvo los gestos.** Una acotación en la segunda frase de una racha de
     quien habla impediría que el importador la junte con la anterior en el mismo bocadillo; por eso solo
     se escribe en la **primera frase de cada turno** (y en 6 frases concretas que el importador junta de
     otra forma: `Gestos.Skip`). Se ha comprobado comparando los 58 guiones con los de antes **sin contar
     `A`, `G` y `Mood`: 0 cambios** (mismas frases, mismo texto, mismo orden, mismos tiempos, mismas
     condiciones). Pasarla otra vez no escribe nada (es idempotente).
   - Resultado: **1919 acotaciones**; **46,8 %** de todas las frases (1799 de 3840) y **75 %** de las
     frases que empiezan un turno (1755 de 2338) llevan gesto o emoción escritos. Las que quedan sin
     escribir son sobre todo las tuyas (el jugador solo gesticula si la frase lo pide) y las frases de
     detrás en un mismo turno, que siguen adivinándose por el texto.
2. **Vocabulario nuevo** (`Emotion.Poses` + `ActorLife`): **Lean** (se inclina hacia quien escucha: la
   cintura hacia delante y la cabeza compensa), **LookAway** (aparta la mirada un momento hacia un lado)
   y **PointLite** (señala con el brazo estirado, sin animación). Ya había: asentir, negar, hombros, brazos
   cruzados, en jarras, mano en la frente, aplaudir, mano en la barbilla, saludo corto, nervios,
   vergüenza, y las animaciones R15 de Roblox (saludar, señalar, reír, celebrar, bailar). El importador
   entiende las acotaciones nuevas: «se lleva la mano a la frente», «brazos en jarra», «manos en la
   cintura», «mano en la barbilla», «se inclina», «aparta la mirada», «desvía la mirada», «mira hacia otro
   lado» y «avergonzado» (antes solo «avergüenza»).
3. **En las escenas del motor, también la postura.** Las frases de las escenas generadas ya llevaban la
   emoción (`Mood`); ahora llevan también la postura y el gesto (`A`, `G`), que `HappeningClient` ya sabía
   hacer.
4. **Cuerpos que no son R15 (H6).** `ActorLife` solo anima R15; un R6 o una criatura con solo cuello
   hablaba sin moverse. Nuevo `client/Controllers/SimpleActing.luau`: con lo que tenga (cuello «Neck» y,
   si los hay, hombros «Right/Left Shoulder»), cabeceo suave al hablar, asentir, negar, ladear al
   preguntar, bajar la cabeza (triste, vergüenza), apartar la mirada, mirar a un punto, señalar, saludar,
   aplaudir, en jarras y brazos cruzados (aproximado). Al acabar deja cada articulación como estaba. Sin
   cuello no hace nada (ni falla). **Comprobado en el código:** todos los actores y criaturas de las
   escenas son R15 (`StageActors` los crea con `HumanoidRigType.R15` y las criaturas son R15 con otra
   piel), así que hoy esto solo se usa si algún personaje no lo es.
5. **Si una animación no se puede hacer** (sin `Animator`, la animación no carga, o un cuerpo que no es
   R15), se hace la postura parecida en vez de nada: señalar → PointLite, saludar → saludo corto,
   celebrar → aplaudir, reír y bailar → contento.
6. **La boca al hablar.** Si la cabeza del personaje tiene caras dinámicas de Roblox (`FaceControls`), la
   mandíbula (`JawDrop`) se abre y se cierra mientras habla, y se cierra al acabar. **No es
   sincronización labial**: no sigue las sílabas. Si la cabeza no tiene `FaceControls` (la mayoría de las
   cabezas clásicas), no cambia nada: ya había cabeceo al hablar.
7. **Quien escucha mira a quien habla**: ya lo hacía `ActorLife` en las conversaciones y en las escenas
   (`Look = "Speaker"`); se conserva. En los cuerpos que no son R15, `SimpleActing.lookAt` lo permite,
   pero las conversaciones aún no se lo piden (pendiente).

### Revisado

- `Emotion`, `ActorLife` (posturas, cabeza, brazos, `play`, `gesture`, `speak`), `Reescritura`
  (`GESTURES`, `linesOf`, la escena de frases y la regla que junta bocadillos), `aplicar-reescritura`,
  `HappeningClient` (frases de escena con `A`/`G`), `DialogueService` (`Emotion`/`Gesture`),
  `StageActors` (rig R15), `StoryCreatures`.
- Las acotaciones de una muestra de misiones (prólogo, `Cole12_UltimoDia`, `Saga_12_Graduacion`,
  `Saga_24_Final`) leídas una a una: se cambió «se inclina hacia ti» por «se inclina hacia delante»
  (Cosme también se inclina hacia Cósimo) y el «Si…» sin tilde.

### Probado técnicamente (Lune)

| Prueba | Qué comprueba de nuevo |
|---|---|
| `test-reescritura` 2e | todos los `A` de los 58 guiones están en `Emotion.Poses`, los `G` son gestos que existen y los `Mood` emociones de `ActorMoods`; cobertura ≥ 40 % de las frases y ≥ 70 % de los turnos; cada palabra de la herramienta la entiende el importador; volver a pasarla no añade nada; ActorLife tiene las posturas nuevas, el apaño para cuerpos que no son R15 y la boca. Además, la sección 1 de siempre: cada guion generado es el que sale de su `.md` (`--check`) |
| `test-joints` | `SimpleActing` con un R6 de verdad (Motor6D): asentir mueve la cabeza, señalar levanta el brazo, al acabar todo vuelve a su postura, sin cuello no falla, y la cuenta de la postura |
| comparación de los 58 guiones con los de antes (sin `A`/`G`/`Mood`) | 0 cambios de estructura (se hizo con un script fuera del repositorio; la herramienta y `test-reescritura` aseguran que se puede repetir) |

Resultados: ver «Pruebas de la fase 4» abajo.

### Probado visualmente

**Nada.** Ningún gesto nuevo se ha visto en Studio.

### Pendiente

- Verlo en Studio: que inclinarse, apartar la mirada y señalar sin animación queden naturales y no se
  pisen con los gestos de siempre; la boca en una cabeza dinámica.
- Las frases de detrás en un mismo turno (el 25 % de los turnos y la mitad de las frases) siguen sin
  acotación escrita: escribirlas a mano en los `.md` y comprobar que el bocadillo no cambia.
- Las 21 cinemáticas viejas (`Cinematics.luau`) y las escenas escritas a mano (`Happenings/*.luau`) no
  salen de los `.md`: su actuación se ha revisado en la revisión por cinemática (abajo) y se migrarán en
  la fase 6.
- Sentarse e inclinarse sobre una mesa como gesto de una frase (hoy sentarse es una acción del mundo, no
  un gesto de la frase).

### Pruebas de la fase 4

Con Lune, fuera de Roblox. **No** hay prueba en Studio.

| Prueba | Resultado |
|---|---|
| `test-reescritura` | ✅ (sección 2e nueva; los 58 guiones al día con su `.md`) |
| `test-joints` | ✅ (SimpleActing con un R6) |
| `test-actors`, `test-cinematic`, `test-playthrough`, `test-compile`, `test-clientboot`, `test-serverboot`, `test-hud`, `test-scenes`, `test-stagedirector`, `test-scenecontrol`, `test-transiciones`, `test-storyengine`, `test-storycontext`, `test-cast`, `test-saga`, `test-storyaudio` | ✅ |
| `aplicar-reescritura --todas` | 0 errores en los 58 |

## Fase 5 · Acontecimientos en el mundo: el meteorito en 10 pasos y lo que se queda

Quinta fase del plan (§7). `Grieta_Caen` cumplía 8 de los 10 pasos del meteorito del encargo (§8 de este
documento): faltaba el **silencio después del impacto** y las reacciones salían lejos del cráter; los
impactos 2 y 3 no se veían. Y solo una escena de 312 dejaba algo en el mundo (los cráteres).

### Qué se ha hecho

1. **`Grieta_Caen` rehecha como el meteorito en 10 pasos** (`Happenings/Cielo.luau`, 16,5 → 35 s,
   7 → 13 planos). Hoja completa con el plano a plano en `docs/cine/revision-cinematicas.md` (hoja 18):
   1. **avisos**: el medidor de Cosme pita cada vez más deprisa, un temblor pequeño antes de que se vea
      nada y **se callan los pájaros** (el ambiente se apaga);
   2. **el cielo cambia** (GrietaVerde y el destello de la Grieta);
   3. **la primera estela** (la cámara la sigue);
   4. **reacciones**: Pip se asusta, Cosme señala, «¡Cúbrete!» (si reaccionas, Pip te felicita);
   5. **tres impactos, cada uno en su plano** (parque, patio del cole, camino al cole), uno detrás de otro;
   6. **polvo, luz, onda, bola de fuego, humo, chispas, cascotes y temblor** (el impacto del catálogo, con
      topes de partículas por nivel gráfico);
   7. **consecuencias que se quedan**: los tres cráteres y, nuevo, **la valla del patio del cole partida**;
   8. **silencio**: después del tercer impacto, ~4 s sin música (`Intensity = "Nada"`), sin ambiente y sin
      ninguna frase, con un acercamiento muy lento al cráter humeante;
   9. **reacciones otra vez**: Chispa sale del cráter y rompe el silencio («¡Bip!»), dos vecinos del parque
      que habían huido al caer la estrella: uno vuelve a ver si estáis bien («¿Estáis bien? ¡No os
      acerquéis!»), la otra se queda lejos mirándole; en el garaje, la cara de Cosme mientras el narrador lo
      cuenta, Pip y Cosme;
   10. **empieza la búsqueda**: rótulo «Han caído tres cosas del cielo · Busca los cráteres humeantes» (el
       paso siguiente de la misión).
   Saltar la escena deja las mismas consecuencias (cráteres y valla), como antes.
2. **Lo que se queda y se arregla con el tiempo.** Nuevo dibujo `Damage` (`shared/StageBuilders`): **roto**
   (mancha quemada, cascotes y lo que se rompió: una valla de madera partida o losas levantadas con los
   papeles de una fiesta), **en obras** (vallas amarillas y negras, conos, casi sin cascotes) y **arreglado**
   (un parche de suelo nuevo, la valla nueva y una placa pequeña). Sin choque (no estorba) y entre 3 y 27
   piezas (menos en gráficos bajos). Tres decorados nuevos en `shared/LifeStory/StageSets`:
   - `DanoPatio` (Grieta_Caen): roto la noche de la caída → en obras al acabar `Saga_02_Grieta` → arreglado
     al acabar `Saga_04_Ventanilla`;
   - `AgujaPatio` (Grieta_Coser, otra escena grande que ahora deja huella): donde despegó la aguja queda una
     marca que **brilla azul** (cosido) → **roja** desde `Saga_12_Graduacion` (la costura se rompe) →
     **blanca y tranquila** desde `Saga_24_Final` (la Grieta se cierra). Las partidas que ya habían cosido el
     cielo antes de esto también la ven;
   - `BajadaInstituto` (Grieta_Rota, la tercera): donde aterriza Cósimo en tu graduación, losas levantadas y
     papeles de la fiesta → en obras al acabar `Saga_13_SinCosme` → arreglado al acabar `Saga_15_Reestreno`.
   **Por qué estas dos**: son los otros dos momentos del cielo que pasan en un sitio concreto de Valmar que
   el jugador vuelve a pisar (el patio del cole y el del instituto), y su huella cuenta la historia sola
   (la aguja cambia de color con la Grieta; el destrozo de la graduación se arregla mientras Cosme no está).
   `Grieta_Fusion` pasa en el Monte del Silencio y `Grieta_Final` cierra la historia: su huella es la marca
   de la aguja que se vuelve blanca.
3. **Persistencia sin claves nuevas de guardado.** Todo va en la **memoria del mundo de siempre**
   (`data.Story.World`, `WorldMemoryService`, la que ya guardaba los cráteres) con tres claves de mundo
   nuevas (`Cielo.Dano.Patio`, `Cielo.Aguja`, `Cielo.Bajada.Instituto`) que escriben las pistas `World` de
   las escenas, y en las misiones completadas. **Ningún campo nuevo en el perfil, ningún DataStore nuevo, y
   las pruebas no escriben ningún DataStore** (usan un `DataService` de mentira).
4. **Revisión por cinemática** (24 escenas): `docs/cine/revision-cinematicas.md`, con la herramienta nueva
   `scripts/audit/cine-revision.luau` y `test-cineplanos`. Arreglos: silencio tras el apagón en
   `Grieta_Coser`, huecos sin plano en `Grieta_Final` y `Uni01_Campus`, actuación y plano de Abu en
   `Uni06_Final`, y las frases de las fotos de los montajes las dice el actor de la foto.

### Revisado

- `Grieta_Caen`, `Grieta_Coser`, `Grieta_Rota`, `Grieta_Fusion`, `Grieta_Final` y las 19 escenas más de la
  revisión; `StageSets`, `StageBuilders`, `WorldMemoryService`, `StageSetsClient` (lo dibuja tu pantalla),
  `HappeningService` (nombres y voces de los actores de escena), `StoryFxCatalog` (meteorito e impacto).

### Probado técnicamente (Lune)

| Prueba | Qué comprueba de nuevo |
|---|---|
| `test-scenes` | `Grieta_Caen`: 35 s, 13 planos, la espera «¡Cúbrete!», 4 claves del mundo entre 4,8 y 7,5 s (tres cráteres y la valla), **silencio**: ninguna frase de 4,6 a 12 s, la música a «Nada» tras el último impacto y el ambiente callado antes; saltar a mitad deja los cráteres que faltan y las idas de Chispa y los vecinos; dos jugadores a la vez, cada uno con su memoria |
| `test-worldmemory` sección 5 | los tres decorados nuevos en cada estado según la historia; partidas de antes; que las tres escenas lo apuntan; **que sobrevive a reiniciar el servidor** (se guarda con la partida, pasa SaveCheck y en otro servidor se ve igual: la valla en obras y la marca de la aguja); el dibujo `Damage` en sus 3 estados × 2 estilos, sin choque y con menos piezas en gráficos bajos |
| `test-mision-grieta`, `test-etapas`, `test-transiciones` | la misión y los montajes siguen igual |
| `test-cineplanos` | ver abajo |

### Probado visualmente

**Nada.** Ni el meteorito nuevo ni los decorados se han visto en Studio.

### Pendiente

- Verlo en Studio y en el móvil: los tres impactos y sus planos cortos (1,2 s), que el silencio se note,
  que la valla rota y las vallas de obra se vean bien junto a los columpios y que no tapen el camino.
- La plantilla «meteorito en 10 pasos» para las demás escenas grandes (`Grieta_Fusion`, las invasiones):
  se puede copiar de `Grieta_Caen`; no se ha hecho.
- Los arreglos «con el tiempo» van por misiones completadas, no por días de juego.

### Pruebas de la fase 5

Con Lune, fuera de Roblox (el mapa de `test-cineplanos` se construye con `rojo` + `build-place`, sin Studio).

| Prueba | Resultado |
|---|---|
| `test-scenes` | ✅ (Grieta_Caen nueva: duración, planos, mundo, silencio, saltar, dos jugadores) |
| `test-worldmemory` | ✅ (sección 5 nueva: los decorados nuevos, reiniciar el servidor, el dibujo `Damage`) |
| `test-cinematic` | ✅ (todas las escenas del motor, Grieta_Caen incluida, se pueden saltar y lo devuelven todo) |
| `test-playthrough`, `test-mision-grieta`, `test-etapas`, `test-transiciones`, `test-compile`, `test-clientboot`, `test-serverboot`, `test-hud`, `test-stagedirector`, `test-reescritura`, `test-scenecontrol`, `test-storyengine`, `test-storycontext`, `test-cast`, `test-saga` | ✅ |
| `test-cineplanos` (dos pasadas) | ❌ **por 167 avisos de las misiones de Tefra** (sitios de la ciudad de Tefra que el mapa de la prueba no tiene; contenido de otro equipo, no tocado). Las escenas de esta fase y de la revisión: **sin avisos nuevos**; 3 conocidos arreglados (`Uni06_Final`) y quitados de PENDIENTES (93 quedan, explicados en `docs/cine/revision-cinematicas.md`) |
| `test-lifestory` | ver «Prueba larga» abajo |

### Prueba larga (`test-lifestory`, sola, al final de las fases 3–5)

**Sin terminar**: el tope de 30 min de las tareas en segundo plano la cortó con **481 comprobaciones ✅ y
0 ❌** (iba por las citas de la universidad). Como en la fase 1, no se puede decir que pase entera: falta
ejecutarla sin tope (tarda más de 30 min).

## Fase 6 · Un solo motor: las 21 cinemáticas de siempre pasan al motor de escenas

Sexta fase del plan (§7). Había **dos reproductores**: el de las cinemáticas viejas
(`shared/LifeStory/Cinematics.luau` + `client/Controllers/Cinematics.luau`, con sus tiempos fijos, su banda
de cine y su cola en la pantalla) y el motor de escenas (`HappeningService` + `HappeningClient`). Cada arreglo
había que hacerlo dos veces y las 21 viejas no tenían el encuadre que no atraviesa paredes, ni la
actuación de la fase 4, ni el reloj del servidor.

### Implementado

1. **Las 21 son escenas del motor** con el **mismo id**: `shared/LifeStory/Happenings/Capitulos.luau` (grupo
   nuevo `Capitulos` en `HappeningIndex`). Mismos planos (los mismos puntos, órbitas, zooms, temblores y
   fundidos; se escriben con un ayudante `planos()` que los pone uno detrás de otro como antes), mismos
   tiempos, mismas frases y rótulos (las mismas claves de `Strings`), misma música y efecto de entrada,
   mismas voces y los mismos gestos. Nada cambia para las misiones, los capítulos (`IntroCinematic` /
   `OutroCinematic`), `Quests` (`Nino_Creces`) ni las partidas guardadas.
2. **Tres cosas nuevas del motor** para que cupieran sin perder nada:
   - pista **`Acting`** (cliente): el gesto de «Todos» (tú y la gente de tu escena) o de «Yo», como el
     `Anims` de las viejas (la foto de grupo: todos celebran; el festival: todos bailan 7,5 s);
   - **`Speakers`**: quien habla sin ser del reparto, con su nombre y su voz (la rectora: «Rectora Amaia
     Soler», voz `Rectora`);
   - **`Queue` / `AfterScene`** (servidor): si ya hay otra escena con cámara (el montaje de cambio de etapa),
     la nueva **espera su turno** en vez de cortarla, como mucho `QUEUE_MAX` = 60 s; su tope ya cuenta esa
     espera (la historia no sigue antes). Antes esto lo hacía la cola de la pantalla de las viejas. Saltar
     una que espera turno: no sale, cuenta como saltada y la historia sigue.
3. **El camino viejo ya no se usa, con un puente fino**:
   - `shared/LifeStory/Cinematics.luau` ya no tiene definiciones: solo `Ids` (las 21), `isLegacy(id)` y
     `get(id)`.
   - `server/Services/CinematicService.play` manda todo a `HappeningService` (se quitó el envío de
     «Cinematic»; `InScene`, latido, topes y el puente entre escenas siguen igual).
   - `client/Controllers/Cinematics.luau` es un **puente** con la API de siempre (`isOnScreen`, `isPlaying`,
     `hold`, `interrupt`, `play`), que usan la caja de diálogo, el prólogo, la cámara a pie, el parkour, las
     armas y el HUD: responde «hay una de las de siempre en pantalla» mirando a `HappeningClient`
     (`legacyOnScreen`). Si por error llegara un «Cinematic» viejo, avisa al servidor de que ha acabado (la
     historia no se queda esperando) y del fallo (`SceneReport`).
   - `HappeningClient` ya no espera a la cinemática vieja en la pantalla (lo hace el servidor).
4. **Los guiones generados no cambian**: `scripts/audit/aplicar-reescritura.luau` sigue tratando las 21 como
   «cinemática vieja» (con su formato de antes para copiar rótulos y música). Se regeneraron los 60:
   **0 errores** y los guiones salen **iguales** (salvo el arreglo de abajo).
5. **Hueco de tiempo arreglado**: `Cole12_FinDeEpisodio` (hoja 7 de la revisión) tenía el primer plano de
   1,4 s y la cámara quieta 1,8 s antes del general. El plano sale de la escena escrita a mano
   (`Happenings/Colegio.luau`, el guion no trae planos): ahora dura hasta el grito (3,2 s) y se regeneró
   su guion. Los demás huecos de la revisión se dejan a propósito (pausas, fundidos a negro: ver hojas).
6. **Encuadres que el motor ahora sí audita** (`test-cineplanos` ya pasa por las 21 como escenas del motor
   y encontró 36 planos nuevos con fallo): `Adu02_Atardecer` (el primer plano de Abu era un travelling a
   mano que cortaba al jugador en el borde: ahora toma prestada a la Abu de la misión y usa el plano con
   nombre `PrimerPlano:Abu`) y `Uni_Graduacion` (la órbita de 10 studs cruzaba la fachada de la facultad:
   ahora 7,5). Quedan 3 casos, solo **llegando en coche** (la órbita pasa por el coche aparcado a tu lado, en
   `Uni_Graduacion` y `Loco_Abduccion`): anotados en `PENDIENTES` con su razón (96 en total).
7. Herramientas al día: `cine-revision`, `narrativa` (cuenta 0 viejas), `exportar-dialogos`, `Validate`
   (comprueba que las 21 siguen en el motor y que sus textos y gestos existen), `StoryHarness` (cuenta las
   escenas del motor como vistas).

### Revisado

- Las 21 una a una contra la versión anterior (planos, frases, rótulos, gestos, anclas, música, fundidos).
- Quién usa el camino viejo: `CinematicService`, `LifeStory` (cliente, «Cinematic»), `DialogueUI`,
  `Prologue`, `SeaEventsUI`, `Actions`, `FootCamera`, `Parkour`, `Stances`, `Locomotion`, `Main.client`,
  `HappeningClient`, `Validate`, los generadores y 10 pruebas. Todos siguen funcionando con el puente.
- La fase 3 (cada paso en su `pcall`, vigilantes, aviso al servidor, vuelta final) y la fase 4 (actuación)
  valen ya para las 21 porque las reproduce el mismo motor.

### Probado técnicamente (Lune)

| Prueba | Qué comprueba de nuevo |
|---|---|
| `test-scenes` sección 10 | las 21, **cada una de principio a fin** por `HappeningService` (llegan a la pantalla, acaban solas sin cortarse, la historia se entera con `clientDone`, la rectora con su nombre y voz, Abu con el nombre de tu familia); la cola: la cabecera no corta el montaje y sale después, al revés también, dos escenas normales siguen cortándose como siempre, una colgada no bloquea más de `QUEUE_MAX`, saltar una que espera turno |
| `test-cinematic` sección 1 | por el motor: cámara, controles, HUD, nombres y `InCinematic` durante y después; el puente (`isOnScreen`, `isPlaying`, `interrupt`); el gesto de «Todos»; saltar, morir, un gesto que falla; un «Cinematic» viejo no deja nada a medias; **las 21 enteras** (todos sus pasos) sin ningún aviso de fallo y devolviéndolo todo; `Cole03_Foto` a su ritmo (7 s) y `Uni_PrimerDia` saltada; dos escenas seguidas sin ver el HUD. Sección 5: fallos a propósito en cada paso de una «de las de siempre» (plano, frase, rótulo, gesto, escena entera) |
| `test-transiciones` | las 21 son escenas del motor válidas, sin pisarse rótulo y frase, y **conservan sus planos, frases, rótulos y gestos** (cuenta por cuenta) con los planos seguidos hasta el final |
| `test-scenecontrol`, `test-etapas`, `test-saga`, `test-cast`, `test-stagedirector` | adaptadas: `InScene` con las de siempre por el motor; nadie pisa sus ids; la rectora como `Speakers`; un solo subtítulo para todas |

### Pruebas de la fase 6

Con Lune, fuera de Roblox. **No** hay prueba en Studio.

| Prueba | Resultado |
|---|---|
| `test-scenes` | ✅ (sección 10 nueva) |
| `test-cinematic` | ✅ (sección 1 rehecha; 734 s, el tope sube a 25 min) |
| `test-transiciones`, `test-scenecontrol`, `test-etapas`, `test-saga`, `test-cast`, `test-stagedirector` | ✅ |
| `test-compile`, `test-clientboot`, `test-serverboot`, `test-hud`, `test-reescritura`, `test-storyengine`, `test-storycontext`, `test-playthrough`, `test-worldmemory`, `test-tefra`, `test-mision-visible` | ✅ |
| `aplicar-reescritura --todas` | 0 errores en los 60; guiones iguales (salvo `Cole12_UltimoDia`, el arreglo del hueco) |
| `test-cineplanos` | ❌ solo por los **167 avisos de Tefra** de siempre (2622 escenas, 10009 planos). Las 21 de siempre, auditadas ya por el motor: 36 planos nuevos con fallo → arreglados 33, 3 en `PENDIENTES` (en coche). La fase 8 se ocupa de Tefra |

### Probado visualmente

**Nada.** Ninguna de las 21 se ha visto en Studio por el motor nuevo.

### Pendiente

- Verlas en Studio y en el móvil (sobre todo las órbitas grandes: Plaza Mayor, granja, campus): el motor
  encuadra con `CineCamera.fit` y podría acercar algún plano que antes atravesaba algo.
- `Bebe_Nacimiento`, `Prologo_Apertura`, `Prologo_Cierre`, `Cole03_Foto`, `Cole07_Viaje` y `Cole07_Foto` ya no
  las pide la historia (sus misiones usan las escenas de sus guiones reescritos); se conservan con su id.
- Borrar el puente `Controllers/Cinematics` del todo exigiría cambiar 12 archivos que solo preguntan
  `isPlaying`/`isOnScreen`; no se ha hecho (no aporta nada y es riesgo).

## Fase 7 · Escenas con varios jugadores: personal, de grupo y del mundo

Séptima fase del plan (§7, §9 del encargo). Hasta ahora todas las escenas eran de UN jugador; el modo
espectador (`Audience = "Nearby"`) existía pero ninguna escena lo usaba. Ahora cada escena dice su
**alcance** (`Scope`) y el **servidor** decide quién la vive, cuándo empieza, cuándo sigue y cuándo acaba.

### Implementado

| Alcance | Quién la vive | Qué ven los demás |
|---|---|---|
| **Personal** (por defecto, casi todas) | solo tú: tu cámara, tus actores, tu historia | nada. En TU pantalla, los demás jugadores que entran en el plano se esconden (ya existía: `SceneClient`, C-16) |
| **Group** | tú y quien esté **cerca** (60 studs) y en el **mismo paso** de la historia: cuando su historia pide la misma escena mientras la tuya empieza (10 s), **se une a la tuya** en vez de tener otra | la viven juntos: el mismo reloj, los mismos actores (los de quien la empezó; los tuyos de la misión se apartan mientras tanto, nunca dos Nicos), cada uno con su cámara, y **no se esconden** unos a otros en los planos |
| **World** (un acontecimiento del mundo) | tú, con la cámara | quien está cerca de ti **o de donde pasa algo** (los cráteres) ve los efectos, el sonido y el cielo **sin perder la cámara ni el control**; quien llega a mitad lo ve desde ese momento (mismo reloj); quien se aleja deja de verlo |

Reglas que cumple (`server/Services/HappeningService.luau`, «FASE 7 · ALCANCE»):

- **El servidor manda**: él empieza la escena, la para en las esperas, la sigue y la acaba; las pantallas
  solo la enseñan. Las esperas («¡Cúbrete!») y los toques para seguir los decide quien la empezó.
- **Nadie bloquea a nadie**: en una de grupo, «Saltar», morir o irse del juego solo te saca a TI (te llega
  el final, tu historia sigue y lo que deja en el mundo queda también para ti). Si se va quien la empezó,
  a los demás se les acaba bien (con sus consecuencias). Un espectador no puede saltar, adelantar ni
  parar la escena de otro.
- **Entrar y salir a mitad** es seguro: quien se une recibe el reloj de la escena (con sus pausas); quien
  llega tarde a una de grupo (pasados 10 s) tiene la suya desde el principio.
- **No se toca a quien no la vive**: a un espectador no se le baja del vehículo, no se le mueve, no se le
  teletransporta ni se le quita el control (va en coche, nadando o donde sea). Los portales de una escena
  solo llevan a quien la vive. Quien está en el espacio (muy lejos) no la recibe.
- Quien **se une** a una de grupo sí la vive: se baja de la bici como en la suya.
- Cada uno guarda **su** memoria del mundo (los cráteres de Ana son de Ana; en una de grupo, cada uno
  apunta lo que deja la escena).

Escenas con alcance:

- **World**: `Grieta_Caen` (el meteorito: radio 220 studs desde el garaje y desde cada cráter),
  `Grieta_Rota` (la graduación del instituto) y `Grieta_Fusion`.
- **Group**: las fotos de grupo y fiestas de siempre: `Cole03_Foto`, `Cole07_Foto`, `Cole10_Festival`,
  `Adu03_Foto` y `Uni_Graduacion`.
- El resto: **Personal**.

En la pantalla (`HappeningClient`, `SceneClient`): el espectador no pone bandas ni esconde la interfaz y
ve `Fx`, `Sound` y `Sky`; quien participa la ve entera, sin pedir esperas ni toques; `SceneClient`
(`setCompanions`, `shareScene`) deja ver a los compañeros y los actores de quien la empezó, y al acabar
todo vuelve a ser como antes. `Sequencer.validate` comprueba `Scope` y `AudienceRadius`.

### Revisado

- El código de espectadores que ya había (`Audience = "Nearby"`, `run.Spectators`, el cliente con
  `Spectator`) se ha reutilizado y ampliado (gente que llega o se va a mitad, el cielo).
- `SceneClient`: esconder a otros jugadores en tus planos (C-16) y las carpetas de escena de otros.
- `CinematicService`: `InScene` y `waitFor` funcionan igual para quien se une (cuenta como en marcha y su
  historia sigue al acabar).

### Probado técnicamente (Lune)

| Prueba | Qué comprueba de nuevo |
|---|---|
| `test-scenes` sección 11 (2–5 jugadores de mentira) | **Personal**: con tres al lado solo la recibe uno; a nadie más se le toca. **World**: los de cerca a pie, **en coche** y **nadando** la ven como espectadores con el mismo reloj; quien está **en el espacio** no; al de coche no se le baja; a nadie que mira se le mueve ni teletransporta; uno que se acerca a mitad la ve desde ahí; uno que se aleja deja de verla; un espectador no puede saltarla ni adelantarla; uno que se va del juego a mitad no rompe nada; acaba entera y no toca la historia de quien mira. **Group** (4 jugadores): dos se unen a la de Ana (misma escena, mismo reloj, sin escena duplicada, Pip una sola vez), el lejano tiene la suya; cuenta como en marcha para quien se une; se baja de la bici; todos saben con quién la viven; quien se une no la adelanta; saltarla solo saca a quien salta (su historia sigue); al acabar acaba para todos con su memoria del mundo; **se va del juego quien la empezó** y al otro se le acaba bien; quien llega tarde tiene la suya; **muere** quien se unió y solo sale él |
| `test-cinematic` sección 6 | espectador: tu cámara y tu control siguen, sin bandas ni interfaz escondida, sin `InCinematic`; grupo: la vives entera, tu compañero **no** se esconde de tus planos, ves los actores de quien la empezó y al acabar todo vuelve; «Saltar» de quien se unió |

### Pruebas de la fase 7

Con Lune, fuera de Roblox, con jugadores de mentira. **No** hay prueba en Studio con dos jugadores.

| Prueba | Resultado |
|---|---|
| `test-scenes` | ✅ (sección 11 nueva; la vieja de dos jugadores con `Grieta_Caen`, adaptada: ahora el de al lado la mira como espectador) |
| `test-cinematic` | ✅ (sección 6 nueva; 729 s) |
| `test-compile`, `test-clientboot`, `test-serverboot`, `test-hud`, `test-transiciones`, `test-stagedirector`, `test-scenecontrol`, `test-reescritura`, `test-storyengine`, `test-storycontext`, `test-cast`, `test-saga`, `test-worldmemory`, `test-tefra`, `test-mision-grieta`, `test-playthrough` | ✅ |
| `test-cineplanos` | ❌ igual que en la fase 6: solo los 167 avisos de Tefra (2622 escenas, 10009 planos; nada nuevo con los alcances). La fase 8 se ocupa de Tefra |

### Probado visualmente

**Nada.** No se ha probado con dos personas de verdad en un servidor (ni en Studio con 2 jugadores).

### Pendiente

- Probarlo con un amigo de verdad (está en la lista del móvil, `docs/cine/validacion-movil.md`).
- En una de grupo, los nombres y la familia que salen en las frases son los de quien la empezó (su Abu).
- Un espectador que llega justo mientras la escena está parada en una espera ve los efectos con el reloj
  corriendo (desfase pequeño; solo efectos).
- No hay «grupo» de amigos (party) en el juego: el grupo es «cerca y en el mismo paso».

## Fase 8 · Validación: test-cineplanos en verde, la prueba larga y la lista para el móvil

Última fase del plan (§7). Lo que se podía validar **sin una pantalla de verdad** está hecho; lo que solo se
puede ver en el móvil está en una lista para Sebastián (`docs/cine/validacion-movil.md`).

### Implementado

1. **La ciudad de Tefra en el mapa de la prueba.** `scripts/audit/cine-extras.luau` (lo que el servidor
   monta al arrancar y no está en el archivo del mapa) ahora construye también **Bastión Ceniza** con
   `World/TefraCityBuilder`, igual que `PlanetWorld.buildCity` cuando alguien baja a Tefra, con sus marcas
   de historia `StorySpot` «Tefra_…». Para eso el cargador de la herramienta entiende `require` de módulos
   de `ReplicatedStorage.Shared` por su ruta (`Shared.Cosmos.Tefra`) y trae lo que la ciudad usa
   (`NumberSequenceKeypoint`, `Random`…). Nunca toca `RealLifeSimulator.rbxl` (es una copia del mapa).
2. Con la ciudad, los **167 avisos `SinLugar` de Tefra desaparecen** y la prueba encontró **7 encuadres de
   verdad** en las escenas de Tefra, arreglados:
   - `Tefra_LanzaCae` (la Lanza cae): los dos primeros planos fijos tenían la cámara **dentro de la torre**
     de un edificio (6 casos, llegando por todos lados): la cámara se aleja a otro punto de la plaza.
   - `Tefra_04_Pozos` · conversación «Hospital»: el ingeniero Orsi tapaba la cara de la doctora Fermina en
     el plano de dos: Orsi un paso a un lado (`Misiones/Tefra_Episodio.luau`, la marca del paso).
   Ninguna excepción nueva en `PENDIENTES`.
3. **Panel de pruebas «🎬 CINE»** (solo dueño y testers; `server/Services/TesterService`,
   `client/UI/TesterPanel`): botones para lanzar las 9 escenas de la lista del móvil (el meteorito, coser el
   cielo, el nacimiento, la foto de grupo, la cabecera de la universidad, el atardecer con Abu, el fin del
   colegio, la despedida con Abu, la Gran Fusión), una **conversación de prueba** (retrato, letra a letra,
   frase muy larga, silencio y pregunta, sin consecuencias), **saltar** la escena y **ver los fallos de
   escena** del servidor (los contadores de `SceneErrorLog`: total, por sitio, por tipo y los 5 que más se
   repiten). El servidor solo lanza escenas de su lista y solo a testers.
4. **`docs/cine/validacion-movil.md`**: la lista para el móvil (qué lanzar y cómo, qué mirar en cada una —
   gestos y boca, el meteorito y el silencio, la valla rota, la caja de diálogo, los encuadres, saltar y
   volver, con un amigo—) y un formulario corto (OK / MAL + captura).

### Revisado

- Las **93 excepciones** de `PENDIENTES` de antes (más 3 de la fase 6): se han vuelto a pasar con el mapa nuevo;
  **siguen fallando igual** (ninguna aparece como «ya no falla») y sus razones siguen valiendo. Las
  «baratas» que señalaba la revisión (las 5 de `Cole12` con dos personas casi juntas) **no lo son**: las
  marcas del paso están separadas (6 studs); se juntan al acercarse a ti quien te habla
  (`HappeningService.nearYou`), así que el arreglo es del motor de colocación, no de una marca. Se dejan
  anotadas.
- Lo opcional que **no** se ha hecho: el patrón del meteorito en 10 pasos para `Grieta_Fusion` y las
  llegadas de la invasión (no da tiempo a hacerlo con cuidado y probarlo en esta fase; queda pendiente).

### Probado técnicamente (Lune)

| Prueba | Resultado |
|---|---|
| `test-cineplanos` (mapa con la ciudad de Tefra) | ✅ **en verde**: 2622 escenas, 10162 planos (153 planos más que antes: los de Tefra, que ahora sí se pueden poner en escena), 0 nuevos; las excepciones de `PENDIENTES` siguen todas (ninguna «ya no falla») |
| `test-tester` | ✅ (sección CINE nueva: la lista de escenas existe, se lanzan solo las de la lista y solo a testers, saltar, fallos de escena, la conversación de prueba con gente del reparto y abre la caja) |
| `test-compile`, `test-clientboot`, `test-serverboot`, `test-hud`, `test-scenes`, `test-cinematic`, `test-stagedirector`, `test-reescritura`, `test-scenecontrol`, `test-transiciones`, `test-storyengine`, `test-storycontext`, `test-cast`, `test-saga`, `test-worldmemory`, `test-tefra`, `test-playthrough` | ✅ |
| `test-lifestory` (sola, sin tope de tiempo) | ✅ **entera por primera vez**: 493 comprobaciones, 0 fallos, en 31 min (1869 s). En las fases 1 y 3–5 la cortaba el tope de 25–30 min |

### Probado visualmente

**Pendiente.** Nada de las fases 1–8 se ha visto en Studio ni en un móvil. Se pasará a «probado» cuando
Sebastián conteste el formulario de `docs/cine/validacion-movil.md` con sus capturas.

### Pendiente

- La validación visual del dueño (lista del móvil), y lo que salga de ella.
- `Grieta_Fusion` y las llegadas de la invasión con el patrón de 10 pasos.
- Las excepciones de `PENDIENTES` que dependen de mover marcas o del motor de colocación.
