# Auditoría narrativa y cinematográfica (NARRATIVE & CINEMATIC AUDIT)

> Fase 1 del [encargo de Sebastián](cinematicas-encargo.md): **auditar antes de programar**. Este documento no cambia
> el juego. Dice qué funciona, qué está mal, qué hay que modificar, qué hay que reconstruir y qué se mantiene,
> y propone el plan de trabajo por paquetes para la fase 2.
>
> Fecha: 5 de octubre de 2026 · rama `claude/roblox-game-d98vy8`.
> Cómo se ha hecho: lectura del código (archivo:línea en cada hallazgo), las pruebas de Lune que ya existen
> (`test-lifestory`, `test-playthrough`, `test-scenes`, `test-storycontext`, `test-worldmemory`,
> `test-mision-grieta`, `test-onboarding`, `validate-report`) y un script nuevo de auditoría
> estática, [`scripts/audit/narrativa.luau`](../../scripts/audit/narrativa.luau), que recorre las 153 misiones.
> Los números de línea son los del 5 de octubre: otros agentes tocan estos archivos y pueden moverse unas líneas.

---

## 0. Resumen

### Veredicto

**La historia FUNCIONA, pero NO PARECE UNA PELÍCULA.**

- **Lógica de misiones: sana.** El validador no encuentra errores (0 errores, 0 avisos, ninguna misión
  bloqueada). Las pruebas juegan tres vidas enteras (de bebé a adulto, con y sin universidad) sin que el
  vigilante tenga que arreglar nada. Además «rompen» las 40 principales: salir y volver, morir, doble
  toque, tocar a otros, irse lejos. **No se ha encontrado ningún softlock ni misión imposible.** El motor
  tiene muchas protecciones (vigilante, reintentos, tiempos de espera, `Validate`).
- **Puesta en escena: de prototipo.** Las 294 escenas de conversación y las 141 charlas se ven como
  bocadillos y cámara automática. Los personajes no entran andando, desaparecen de golpe al cambiar de paso
  (259 veces) y el jugador se teletransporta sin fundido (44 saltos). La cámara vuelve al juego de golpe.
  Los que escuchan no miran a quien habla, y las frases no tienen pausas. Solo 2 escenas usan el motor
  nuevo de escenas (`Happenings`, la Saga). Las otras 27 cinemáticas son vuelos de cámara con rótulos.
- **Continuidad: floja.** Se escriben 222 marcas, 128 recuerdos y 93 decisiones. **80 marcas, 79 recuerdos y
  25 decisiones no los vuelve a leer nadie**, ni los datos ni el código. Los NPC solo «recuerdan» 4 hechos.
- **Transiciones de etapa y finales de capítulo: flojos.** Cada cambio de etapa es un vuelo de 10 a 18 s
  sobre la ciudad con rótulos. El paso a la vida adulta no tiene escena: es un premio. La vida termina
  con «ve a casa» y un texto.

### Hallazgos por gravedad

| Gravedad | Cuántos | Qué son |
|---|---|---|
| **Bloqueante** | **0** | Ningún softlock, misión imposible ni control bloqueado en las pruebas |
| **Grave** | **12** | Saltos sin fundido, actores que desaparecen, cámara que vuelve de golpe, miradas, aviso de «cinemática» que el servidor no ve, transiciones de etapa, finales de capítulo y de vida, cita sin la otra persona, continuidad, escenas importantes sin escenificar |
| **Medio** | **18** | Reloj en multijugador, reaparecer en el hospital, lugares que faltan, cámara de diálogo pobre, pausas, gestos, música, ambiente, otros jugadores en plano, escritura… |
| **Menor** | **7** | Contenido muerto, misiones viejas sin escena, frases largas, monólogos… |

Acción: **MANTENER** el motor de misiones, las protecciones y los arreglos ya hechos (§3.10).
**MODIFICAR** SceneService, DialogueUI, ActorLife, CineCamera, StoryAudio y las misiones.
**RECONSTRUIR** las transiciones de etapa, los finales de capítulo, el final de la vida y las escenas clave,
sobre el motor de escenas (`Sequencer` + `CameraShots` + `HappeningService`), **ampliado y sin sustituirlo**.

### Los 10 peores fallos

| # | Id | Fallo | Dónde |
|---|---|---|---|
| 1 | C-02 | Los actores **desaparecen de golpe** al cambiar de paso (se destruyen). 259 veces; en 79, el paso no tiene reparto y se va todo el mundo a la vez | `SceneService.luau:1299`, `:1531`; lista en el anexo B |
| 2 | C-01 | **Teletransporte del jugador sin fundido**: 44 saltos; 17 justo al empezar una conversación, sin pantalla que lo tape | `SceneService.luau:1859` (`teleportTo`), `LifeStoryService.luau` (`teleportStep`) |
| 3 | C-04 | La **cámara vuelve al juego de golpe**: un `camera.CFrame =` seco al acabar cada conversación y cada cinemática | `CineCamera.luau:90-112` |
| 4 | M-04 | El aviso **`InCinematic` solo existe en el cliente** y no llega al servidor. Por eso, en el nacimiento, Abu puede decir «levántate» encima de la cinemática, y los avisos de otras misiones pueden caer en mitad de una escena | `BabyService.luau:513`, `Cinematics.luau:224`, `HappeningClient.luau:697` |
| 5 | C-06 | **Miradas**: quien escucha no mira a quien habla hasta que habla él. Un NPC que contesta a otro NPC te mira a ti | `ActorLife.luau:581-610` |
| 6 | C-13 | **Cambios de etapa** como vuelo de cámara genérico, sin tu gente ni tus recuerdos. **Adulto joven → adulto no tiene escena** (es un premio) | `Cinematics.luau` (`Nino_AInstituto`, `Adol_Selectividad`…), `Adu03_Reencuentro.luau:72` |
| 7 | M-07 | **El final de la vida** (`Adulto_MirarAtras`) es «vuelve a casa» y un texto | `Quests.luau:178-188` |
| 8 | W-05 | **Continuidad**: 80 marcas, 79 recuerdos y 25 decisiones que no se vuelven a leer (el nombre del grupo, la promesa a Abu, el tema del TFG…) | anexo D |
| 9 | C-09 | **La cita sin la otra persona**: en `UniS_Cita` la persona invitada no está ni al invitarla ni en el atardecer de la playa. Sus frases salen en la caja | `Uni_Secundarias.luau:438, 441` |
| 10 | C-12 | **Las escenas importantes son chat con bocadillos**. El motor de escenas con actores, miradas, planos y esperas (`Happenings`) solo lo usan 2 escenas de la Saga | `HappeningIndex.luau:14` (`GROUPS = { "Cielo" }`) |

---

## 1. Inventario de los sistemas narrativos

### 1.1 Mapa

```
 DATOS (shared/LifeStory)                         SERVIDOR                                CLIENTE
 ───────────────────────                          ────────                                ───────
 Chapters ─┐                                      LifeStoryService ──(remoto LifeStory)──► LifeStory (tarjeta, pantallas,
 Quests ───┼─► Validate (al arrancar)               │  capítulos, pasos, vigilante,           momentos), TaskMarker, StoryJournal
 MissionIndex → Misiones/*.luau                     │  consecuencias diferidas (Later)
 Cast, Locations, Strings, Memories,                ├─► SceneService ──(StoryScenes)───────► SceneClient (ocultar ajenos, fundidos)
 WorldState, EventCatalog, Conditions,              │     actores y objetos por jugador       ActorLife (mirada, gestos, respirar)
 Emotion, ActorMoods, StoryContext                  ├─► DialogueService ─(remoto Dialogue)─► DialogueUI + SpeechBubbles/BubbleLayout
                                                    ├─► CinematicService ─────────────────► Cinematics (cámara vieja) + CineCamera
 Cinematics (27 escenas de cámara)                  │      └─► HappeningService ───────────► HappeningClient (motor nuevo) + StoryFx
 HappeningIndex → Happenings/Cielo (3 escenas)      │            (Sequencer, CameraShots)
 Sequencer, CameraShots, StageSets, StoryFx*        ├─► MiniGameService / ClassService ───► MiniGameUI / ClassUI
                                                    ├─► BabyService (bebé, familia) ──────► Baby (frases sueltas)
 StoryEvents (avisos de otros sistemas) ──────────► │
 DataService (guardar) · PositionService ─────────► │                                         StoryAudio (música, voces) · SoundFx
```

### 1.2 Piezas, qué hacen y en qué estado están

| Pieza | Archivo | Qué hace | Estado |
|---|---|---|---|
| Capítulos | `src/shared/LifeStory/Chapters.luau` | 8 capítulos por etapa con `Main`, `Loop`, `IntroCinematic`, `Music` | ✅ · `Adolescente_Instituto` sin intro ni música (M-05) |
| Misiones | `Quests.luau` (sencillas) + `MissionIndex.luau` → `Misiones/*.luau` (episódicas) | 153 misiones, 1048 pasos, 3020 frases | ✅ lógica · ⚠️ escena |
| Validador | `Validate.luau` (969 líneas) | Textos, lugares, reparto, eventos, condiciones, escenas, cámaras, ventanas horarias… Una misión con errores no se activa | ✅ excelente (0 errores) |
| Reparto | `Cast.luau` | Nombre, voz, aspecto y `Bio` (personalidad) de cada personaje | ✅ |
| Lugares | `Locations.luau` + `server/Services/LocationService.luau` | Lugares por modelo, etiqueta, casa, entre dos sitios, con plan B (`Fallback`) | ✅ · sin prueba contra el mapa real (M-03) |
| Contexto | `StoryContext.luau` | Tarjetas, resumen «Anteriormente…», tipos de misión | ✅ (test-storycontext 134 ✅) |
| Recuerdos | `Memories.luau` + `Story.Memories` | Grandes recuerdos (texto e icono) para la biografía y el último día de cole | ✅ · poco citados (W-05) |
| Memoria del mundo | `WorldState.luau` + `WorldMemoryService` | Cráteres, puertas… que se quedan (`World`) | ✅ (test-worldmemory 53 ✅) |
| Catálogo de eventos | `EventCatalog.luau` | Qué avisos existen; el validador rechaza esperar uno que nadie emite | ✅ |
| Motor de la historia | `server/Services/LifeStoryService.luau` (3981 líneas) | Capítulos, pasos (`Reach`, `Talk`, `Scene`, `Use`, `Group`, `Choice`, `MiniGame`, `Class`, `Fight`, `Wait`, `Transition`, `Cinematic`…), efectos, `Later`, vigilante (`Watchdog`, l. 2727), guardia de toques (`Guard`, l. 3275), prólogo | ✅ muy defendido |
| Escenas (actores y objetos) | `server/Services/SceneService.luau` (2258) + cliente `SceneClient` | Actores y objetos **por jugador** (invisibles para los demás); andan con PathfindingService, se sientan, siguen, persiguen | ✅ multijugador · ⚠️ entradas y salidas (C-02, C-03) |
| Conversaciones | `server/Services/DialogueService.luau` + cliente `DialogueUI.luau` | Por turnos, preguntas, efectos sin repetir, reenvío si se pierde, `InDialogue`, `TalkingTo` | ✅ robusto · ⚠️ escenificación (C-05, C-07) |
| Bocadillos | `client/UI/SpeechBubbles.luau` + `BubbleLayout.luau` | Bocadillo encima de quien habla; los de la historia por encima de todo; a la caja si no se ve | ✅ (arreglado) |
| Cinemáticas viejas | `shared/LifeStory/Cinematics.luau` + `CinematicService` + cliente `Cinematics.luau` | 27 escenas: travellings y órbitas, rótulos, subtítulos, gestos sueltos, bandas negras, Saltar | ✅ estables · ⚠️ planas (C-12) |
| **Motor de escenas nuevo** | `Sequencer.luau`, `CameraShots.luau`, `HappeningService` (832), `HappeningClient` (895), `StoryFx`, `StageActors`, `StageSets`, `ActorMoods` | Pistas con tiempos: cámara (travelling, fijo, órbita, seguir, cortes, zoom, temblor), actores (aparecer, andar, mirar, emoción, gesto, decir, irse), esperas (`Input`, `Near`, `Arrived`), cielo, efectos, sonido, música, rótulos, memoria del mundo; saltar aplica las consecuencias | ✅ **es la base buena** (test-scenes 113 ✅) · solo 3 escenas escritas |
| Animación de NPC | `client/Controllers/ActorLife.luau` (1451) + `Emotion.luau` + `WorkAnim`, `AgeMotion`, `ReactMotion`, `PunchAnim` | Respiran, miran, hablan con el cuerpo según la emoción, oficio, gestos R15 de Roblox | ✅ · mirada en grupo (C-06) |
| Audio | `client/Controllers/StoryAudio.luau` + `SoundFx.luau` + `Config.Audio` | 4 músicas con fundidos, 3 efectos, voces TTS por perfil; ambiente: lluvia, viento, multitud del centro, metro, mar | ⚠️ sin intensidades ni ambiente de interiores (C-14, C-15) |
| Control del jugador | `client/Controllers/Controls.luau` | Contador por motivo (`Dialogo`, `Cinematica`, `Escena`) que se reaplica al reaparecer | ✅ |
| Cámara | `client/Controllers/CineCamera.luau` | No atravesar paredes, devolver la cámara, callar los carteles | ⚠️ vuelta seca (C-04) |
| Bebé | `server/Services/BabyService.luau` + cliente `Baby.luau` | Gatear, ponerse de pie, familia de la casa, frases sueltas | ✅ · espera a un atributo que no llega (M-04) |
| Etapa y edad | `LifeStoryService.setStage` (l. 352) + `LifeService` | Etapa, edad, `ScaleTo` del cuerpo | ✅ |
| Guardar | `DataService` (bloqueo de sesión, plantilla) + `PositionService` | `Story` completo; reengancha la escena al volver (`returnToScene`) | ✅ (el JSON se guarda en todas las pruebas) |
| Multijugador | `SceneClient` (oculta escenas ajenas), `DialogueService` por jugador, `Transition` solo cambia la hora si juegas solo | ✅ aislado · ⚠️ reloj (M-01), jugadores en plano (C-16) |

---

## 2. Misiones y etapas: la cadena START → OBJECTIVE → ACTION → NPC → NEXT → REWARD → NEXT EVENT

### 2.1 Resultado de las pruebas (5 de octubre)

| Prueba | Resultado |
|---|---|
| `validate-report` | 0 errores · 0 avisos · ninguna misión que no se active |
| `test-playthrough` | 63 ✅ 0 ❌ · 3 vidas enteras (todas las opciones de todas las decisiones) · las 40 principales «rotas» a propósito |
| `test-lifestory` | ver §2.5 (la prueba larga) |
| `test-scenes` | 113 ✅ (motor de escenas, planos, posturas) |
| `test-storycontext` | 134 ✅ (prólogo, resumen, tarjetas, diario) |
| `test-worldmemory` | 53 ✅ |
| `test-mision-grieta` | 14 ✅ (cráteres y Chispa siguen al volver) |
| `test-onboarding` | 44 ✅ |

**Lo que las pruebas NO cubren** (y la fase 2 debe añadir):
- «Morir y volver» solo se prueba en 6 principales.
- Las secundarias de la Saga, las Locas, las Rarezas, los Aliados, `UniS_*` y el Metro no pasan por «Romperlo».
- No se prueba que cada lugar de `Locations` exista en el **mapa real** (el arnés usa un `LocationService` falso).
- No se prueba nada del cliente en una escena: que la cámara vuelva, que los controles vuelvan, qué ven los otros jugadores.

### 2.2 La cadena por etapa

Tabla completa de las 153 misiones (cómo empiezan, pasos, escenas, saltos, final) en el **anexo A**.

| Etapa | Capítulo y principales | Inicio | Final (recompensa → siguiente) | Estado de la cadena |
|---|---|---|---|---|
| Prólogo | `Prologo_Sueno` (9 pasos) | lo lanza el motor al crear personaje | recuerdo `SuenoGrieta` → nacimiento | ✅ (test-storycontext) |
| **Bebé** | `Bebe_PrimerosPasos`: AprendeACaminar → ExploraLaCasa → HoraDeSalir | `Bebe_Nacimiento` (17 s) | `Transition` + `Bebe_AnosDespues` → **Niño** | ✅ lógica · ⚠️ Abu puede hablar encima del nacimiento (M-04); conversaciones del bebé = frases sueltas |
| **Niño** | `Nino_ElColegio`: Cole01…Cole12 + `Nino_Recados` + `Nino_Jornada` (bucle) | `Cole01_Amanecer` | Cole12: fotos + `Nino_FinPrimaria` + `Transition Nino_AInstituto` → **Adolescente** | ✅ · el mejor capítulo escrito; ⚠️ saltos sin fundido (Cole01, Cole08) |
| **Adolescente** | `Adolescente_Instituto`: Ins01–Ins03, Pan1, Pan2, Ins04, Pan3, Ins05, Ins06 + `Adol_Jornada` | **sin cinemática ni música propia** (M-05) | Ins06: graduación + `Transition Adol_Selectividad` → Universidad o trabajo | ✅ · las dos ramas (estudiar / trabajar) probadas |
| **Universidad** | `Joven_Universidad` (si `VaALaUniversidad`): Uni01, Uni01b, Uni02, UniEx1, Uni03, UniEx2, Uni04, UniEx3, Uni05, UniEx4, Uni06 + `Uni_Jornada` | `Uni_PrimerDia` | Uni06: ceremonia + `Uni_Graduacion` + brindis → Volar del nido | ✅ |
| **Profesión** | `Adulto_VolarDelNido` (requiere Ins06): Adu01 PrimerContrato, Adu02 Atardecer, Adu03 Reencuentro | **sin escena de inicio** | Adu03: foto; **la etapa Adulto llega como premio**, sin escena (M-06) | ✅ lógica · ⚠️ ascensos y despidos no son escenas (el evento `Promoted` existe pero nadie lo escenifica) |
| **Vida adulta** | `Adulto_TuVida`: `Adulto_MirarAtras` + `Adulto_Jornada` | texto | **«Ve a casa» + un `Moment`** (M-07) | ✅ lógica · ❌ final de la vida sin escena |
| Veteranos | `Adulto_NuevaVida`: Llegada, PrimerSueldo, ConoceLaRegion | `Adulto_Llegada` | `Adulto_TuCiudad` | ✅ · sin conversaciones (M-08) |
| Secundarias | Saga de la Grieta (23, canónicas), Locas (21), Rarezas (24), Aliados (7), Uni (7), Metro (3), Ecos y Consecuencias (diferidas) | `Offer` por lugar o evento, `Later.Start` | momento + premio + recuerdo | ✅ (test-lifestory las recorre todas) |

### 2.3 Hallazgos de misiones y sistemas

| Id | Hallazgo | Dónde | Grav. | Acción |
|---|---|---|---|---|
| M-01 | **Reloj en multijugador.** Un `Transition` como «Esa noche…» solo mueve la hora si estás solo en el servidor. Con más gente sale el texto, pero el cielo sigue de día. Lo mismo con el «amanece» del bebé | `LifeStoryService.luau:1640` | medio | MODIFICAR: noche **local** (luz del cliente) durante la escena |
| M-02 | **Al reaparecer en el hospital** te lleva al `Teleport` del paso de *cualquier* misión activa, aunque sea una secundaria que no sigues. Además, sin fundido | `LifeStoryService.luau:2476-2500` (`afterRevive`) | medio | MODIFICAR: solo la seguida y con fundido |
| M-03 | **Lugar que no existe en el mapa**: el vigilante da el paso `Reach` por hecho a los 30 s, **en silencio**. La historia sigue, pero el jugador no sabe por qué. Ninguna prueba resuelve los `Locations` contra el mapa real | `LifeStoryService.luau:2867-2890`, `Watchdog.MissingPlace` | medio | MODIFICAR: aviso narrativo + prueba de lugares contra el mapa (paquete P10) |
| M-04 | **`InCinematic` no llega al servidor.** Lo ponen `Cinematics.luau:224` y `HappeningClient.luau:697` en el **cliente**, y los atributos que pone el cliente no se replican. `BabyService.luau:513` espera a que se quite para que Abu diga «levántate», pero en el servidor nunca está puesto: **Abu puede hablar encima de la cinemática del nacimiento**. Además, `busy()` (`LifeStoryService.luau:280`) no cuenta las escenas de cámara: los avisos (`Nudge`) de otra misión pueden caer en mitad de una | ver columna | **grave** | MODIFICAR: el servidor marca `InScene` al lanzar y lo quita con `clientDone` o por tiempo |
| M-05 | `Adolescente_Instituto` sin `IntroCinematic` ni `Music` (suena la música de la etapa). `Adulto_VolarDelNido` y `Adulto_TuVida` tampoco tienen escena de entrada | `Chapters.luau` | medio | MODIFICAR (va con el montaje de etapa, §6.3) |
| M-06 | **Adulto joven → adulto sin escena**: es `Rewards.SetStage = "Adulto"` de Adu03 | `Adu03_Reencuentro.luau:72` | **grave** | RECONSTRUIR: montaje de etapa |
| M-07 | **El final de la vida** = `Reach CasaFamiliar` + `Moment` de texto | `Quests.luau:178-188` | **grave** | RECONSTRUIR: escena final con la familia y el álbum de recuerdos |
| M-08 | `Adulto_NuevaVida` (quien ya jugaba antes): 3 misiones sin conversaciones ni actores | `Quests.luau` | medio | MODIFICAR: una escena de llegada con Lola o Ernesto |
| M-09 | `Adol_Jornada` usa **las mismas frases** que `Nino_Jornada` (`SchoolLife.Dialogues`): con 15 años te dicen «¡Mitad para ti, mitad para mí! Así se hacen los amigos» | `Quests.luau:131, 146` | medio | MODIFICAR: frases de adolescente |
| M-10 | Capítulo `Nino_Puente` (`Nino_TuBarrio`) desactivado: contenido muerto | `Chapters.luau`, `Quests.luau:193` | menor | MANTENER (documentado; no molesta) |
| M-11 | Secundarias viejas sin escena: `Side_MochilaPerdida`, `Side_TardeDePlaya`, `Side_MedicinasUrgentes` | `Quests.luau` | menor | MODIFICAR (una frase con actor) |
| M-12 | `Metro_Secundarias`: el 100 % de las frases son del narrador | `Misiones/Metro_Secundarias.luau` | menor | MODIFICAR |

**Comprobado y sano** (sin hallazgo): orden de los pasos, ramas `If`, decisiones en el mundo, `Late`, `Timeout`,
`Nudge`, consecuencias diferidas (`Later`, probadas a 1 h y a 10 h), secundarias rechazadas que vuelven,
el carnet ya conseguido, el objeto cogido antes de tiempo, los actores que faltan (el vigilante los vuelve a montar),
salir y volver en plena conversación (no se repiten los efectos: `DlgApplied`), morir en plena conversación
(se cancela y se reanuda), el prólogo abandonado (cuenta como visto, `LifeStoryService.luau:3858`), el guardado (JSON válido
y de tamaño correcto).

### 2.4 Abandonar, volver, morir y reconectar

| Caso | Qué pasa hoy | Valoración |
|---|---|---|
| Irse lejos en mitad de un paso | La escena espera (`canAutoStart`, aviso «sigue tu misión») | ✅ |
| Salir del juego y volver | `returnToScene` te lleva a la escena si estás a más de 120 studs (sin fundido, pero mientras carga) | ✅ / menor |
| Morir | Se corta la conversación, reapareces y vuelves al `Teleport` del paso | ⚠️ M-02 |
| Morir o salir durante una cinemática | El servidor sigue cuando el cliente avisa o al acabar el tiempo de seguridad (`CinematicService.waitFor`, +20 s) | ✅ |
| Escena + otra escena seguidas | `DialogueUI` espera a que acabe la cinemática y la pantalla de capítulo (como mucho 15 s) | ✅ |
| Dos jugadores en la misma misión | Cada uno ve **sus** actores; el Nico fijo del patio se oculta para quien tiene a Nico en su escena | ✅ |
| Otro jugador cruza tu escena | Se ve y puede ponerse delante de la cámara | ⚠️ C-16 |

### 2.5 La prueba larga (`test-lifestory`)

Se ha lanzado entera. Resultado: ver el apéndice de esta sección al final del documento (anexo E).

---

## 3. Calidad cinematográfica

Cifras del script de auditoría (anexo A–C):

| Medida | Valor |
|---|---|
| Escenas de conversación (`Scene`) / charlas (`Talk`) | 294 / 141 |
| Escenas de cámara que usan las misiones | 22 pasos (27 cinemáticas viejas + 3 del motor nuevo) |
| Saltos del jugador (`Teleport`) | 44 (17 pegados a una conversación sin nada que los tape) |
| Actores que desaparecen de golpe al cambiar de paso | 259 casos (79: el paso no tiene reparto y se van todos) |
| Hablan sin estar en la escena (su frase sale en la caja) | 22 conversaciones |
| Conversaciones solo de narrador o del jugador | 25 |
| Frases con gesto o emoción **marcados** (`A`/`G`) | 9 de 3020 (0,3 %); el resto lo adivina `Emotion.of` por el texto |
| Frases con acotación escrita «(desde lejos)», «(aprieta tu mano)»… | 97 |
| Frases del narrador | 783 de 3020 (26 %) |

### 3.1 Conversaciones importantes que son chat estático

Hoy **toda** conversación de misión funciona igual (`DialogueUI.luau`). El jugador toca para pasar, el texto se
escribe letra a letra en un bocadillo y la cámara elige sola entre tres planos. Los personajes:
- ya están colocados cuando empieza;
- hablan con gestos que se adivinan por el texto;
- no se mueven de su sitio.

Nada distingue la primera vez que conoces a tu tutora, la discusión con Bruno o la noche antes de decidir
tu futuro de pedir un helado. Escenas que el encargo pide cinematizar y que hoy son chat:

| Etapa | Escenas (misión · diálogo) |
|---|---|
| Niño | Cole01 `Despertar`, `ConoceLucia`, `Bienvenida`, `LibrosCaen`/`MateoGracias`, `Cena` · Cole02 `Deduccion` (narrador) · Cole04 enfrentamiento con Bruno · Cole05 confesión · Cole06 `Aprobado` (Iker y Mateo no están) · Cole08 final y `Medallas` (la familia no está) · Cole09 la foto de Lucía · Cole12 despedidas |
| Adolescente | Ins01 `Parada`, `Leire_Recreo`, `Tutor` · Ins03 orientación con Carmen · Pan1–Pan3 la pandilla (Pan2 #10 comisaría con salto seco) · Ins04 la entrevista · Ins05 el rumor · Ins06 `Noche`, `Decidido`, `Graduacion` |
| Universidad | Uni01 llegada y Beltrán · Uni01b primera cena · Uni02 conflicto del grupo · Uni04 `Error` (6 frases, todas del narrador) · Uni05 la caja de Abu · Uni06 `Brindis`, `Final` (solo narrador) · UniS_Cita (sin la otra persona) |
| Profesión y adulto | Adu01 `Contrato` (41 % narrador), Adu02 hospital y atardecer con Abu, Adu03 banco del parque, final de la vida |

### 3.2 Teletransportes en vez de andar

| Id | Hallazgo | Dónde | Grav. | Acción |
|---|---|---|---|---|
| C-01 | **El jugador salta sin fundido.** `SceneService.teleportTo` mueve al personaje sin oscurecer la pantalla. Hay 44 pasos con `Teleport`. **17** de ellos caen justo antes de una conversación sin que nada los tape (ni una pantalla de `Transition` ni una cinemática anterior): un corte seco y a hablar. Cole01 #1, #15–17 (pupitre), #28 (cena) · Cole03 #20 · Cole08 #19, #21, #27, #29, #31 (cinco saltos entre pistas) · Cole09 #11 · Pan2 #10 (comisaría) · Uni01b #2 · UniEx1 #13 · UniEx2 #11 · UniS_Pabellon0 #5 | `SceneService.luau:1847-1897` | **grave** | MODIFICAR: `teleport` con fundido rápido (dip) en el cliente y reencuadre |
| C-02 | **Los actores se van de golpe.** Al cambiar de paso, quien ya no está en el reparto se **destruye** (`actor.Model:Destroy()`), sin andar hacia la puerta ni desvanecerse. Pasa 259 veces; en 79 el paso no tiene `Actors` y se va todo el mundo a la vez (p. ej. Cole03 #17: nueve niños; Adu03 #11: diez personas) | `SceneService.luau:1299`, `applyClear` l. 1531 | **grave** | MODIFICAR: salida andando (o fundido si no hay camino), y «quedarse» por defecto mientras el jugador mira |
| C-03 | **Entradas**: el actor aparece en su marca con un fundido suave (`SceneClient`). Solo entra andando si ya estaba en el mapa a menos de 110 studs. Si tiene que moverse más de 70 studs, se destruye y se vuelve a crear (salto). No hay forma de decir «entra por la puerta» | `SceneService.luau:1380-1420`, `ambientStart` l. 1473 | medio | MODIFICAR: `Enter = { From = lugar, Walk = true }` |

### 3.3 Actores que no miran a quien habla

| Id | Hallazgo | Dónde | Grav. | Acción |
|---|---|---|---|---|
| C-06 | En una conversación, `ActorLife` solo cuenta como oyentes a quien **ya ha hablado** y al jugador. El resto del reparto sigue con su mirada de siempre: mira al jugador si está cerca o a su compañero. Así, en la `Bienvenida` de Lucía los diez niños no la miran. Y quien habla **siempre te mira a ti** (`target = myHead`, l. 601), aunque conteste a otro NPC (Omar contestando a Sara). El servidor también gira el cuerpo de quien habla hacia el jugador (`SceneService.luau:1906-1975`) | `ActorLife.luau:581-610` | **grave** | MODIFICAR: todos los actores de la escena miran a quien habla. Cada línea puede decir a quién habla (`To = "Sara"`), y la mirada se aparta al pensar y baja con vergüenza (las emociones ya existen) |
| C-11 | 97 frases llevan la acción **escrita** en vez de hecha: «(desde lejos)», «(aprieta tu mano)», «(se frota la cara)», «(Omar levanta el pulgar sin dejar de dibujar)» | misiones (anexo F, apartado 9 del script) | medio | MODIFICAR: pasarlas a `A`/`G`/`Look`/`Move` y quitar el paréntesis |

### 3.4 Pausas y ritmo

| Id | Hallazgo | Dónde | Grav. | Acción |
|---|---|---|---|---|
| C-07 | **No hay pausas.** El texto sale siempre a 55 letras por segundo y el jugador decide cuándo pasar. Las líneas no tienen `Pause` ni `Beat`, y los «…» no hacen esperar: el «Yo… no sé si esto es buena idea. *(pausa)* Pero tenemos que hacerlo» del encargo no se puede escribir | `DialogueUI.luau:36`, `:485-488` | medio | MODIFICAR: `Pause` antes y después, pausa en «…» y «.», `Beat` (mirar, respirar) |
| C-08 | Solo 9 de 3020 frases marcan su emoción o gesto. El resto los adivina `Emotion.of` por los signos y las palabras: funciona, pero todo el mundo se mueve igual | `Emotion.luau`, datos | medio | MODIFICAR: marcar las escenas importantes |

### 3.5 Cámara: planos que se usan y planos que hay

| Sistema | Planos disponibles | Planos que se usan |
|---|---|---|
| `CameraShots` (motor nuevo) | Travelling, fijo, órbita, seguir (a un actor, un efecto o el jugador), zoom, inclinación, temblor, 4 entradas (`Cut`, `Dip`, `Fade`, `Flash`), suavizados | Solo en `Grieta_Caen`/`Grieta_Recoger`: 2 travellings, 5 fijos, 1 seguir, 3 órbitas, 3 cortes, 3 dips, 1 destello |
| Cinemáticas viejas | Travelling y órbita, `Dip`, `FadeIn`/`FadeOut`, `Fov` | 35 travellings y 22 órbitas: **todo vuelos aéreos y órbitas alrededor del jugador** («fotos») |
| `DialogueUI` (conversaciones) | Automático: dos de perfil al empezar, sobre tu hombro, primer plano de quien habla, contraplano cuando hablas tú | Los mismos en todas las conversaciones; si quien habla está a más de 60 studs o en la caja, **no hay cámara** (`DialogueUI.luau:165`) |

**Faltan**, según el encargo: plano general de situación al empezar, plano de reacción, plano de objeto (inserto),
de dos con intención, lateral, travelling o dolly lento durante una frase, y planos elegidos por la escena (hoy
los elige un contador: `shotCount % 3`). → **C-05 (medio, MODIFICAR)**: presets de plano en `CameraShots` que una
escena o una línea pueda pedir (`Shot = "Reaccion:Mateo"`).

### 3.6 Transiciones, fundidos y control

| Id | Hallazgo | Dónde | Grav. | Acción |
|---|---|---|---|---|
| C-04 | **La cámara vuelve de golpe.** `CineCamera.restore` pone `camera.CFrame` y la deja en `Custom` en el mismo fotograma. Lo usan las conversaciones y las cinemáticas (en estas, tras un fundido a negro solo si se salta o hay `FadeOut`). La entrada sí es suave (0,6 s) | `CineCamera.luau:90-112`, `DialogueUI.luau:268-280`, `Cinematics.luau:537-547` | **grave** | MODIFICAR: vuelta con suavizado de 0,8-1,2 s hasta detrás del jugador |
| — | Bloqueo y vuelta de los controles: contador por motivo (`Controls.luau`), se reaplica al reaparecer y la cinemática que falla lo devuelve todo (`Cinematics.play` con `pcall`) | `Controls.luau`, `Cinematics.luau:575-603` | ✅ | MANTENER |
| C-16 | **Los otros jugadores salen en plano**: nadie los oculta durante tu escena, y pueden cruzarse o ponerse delante de la cámara. Sus bocadillos sí se callan (`quietLabels`) | `Cinematics.luau`, `HappeningClient.luau`, `DialogueUI.luau` | medio | MODIFICAR: ocultarlos en tu pantalla mientras dura la escena si están en el encuadre |
| C-17 | Iluminación: hay desenfoque de fondo (`DayLight.setFocus`) y ambientes de cielo (`SkyMoods`, en el motor nuevo), pero ninguna escena pide luz propia (cálida de interior, atardecer íntimo…) | `DayLight.luau`, `SkyMoods.luau` | menor | MODIFICAR: pista `Light` con presets que se deshacen solos |

### 3.7 Sonido ambiente y música

| Id | Hallazgo | Dónde | Grav. | Acción |
|---|---|---|---|---|
| C-14 | **Música: 4 piezas** (`Nacimiento`, `TemaValmar`, `PasanLosAnos`, `VidaAdulta`) y 3 efectos. La música va por capítulo o por cinemática. No hay intensidades (descubrimiento, íntima, tensión, resolución, tema de final de capítulo) ni capas que suban y bajen | `Config.luau:265-275`, `StoryAudio.luau` | medio | MODIFICAR + componer 5 piezas (`scripts/audio/compose.py` ya existe) |
| C-15 | **Ambiente**: lluvia y viento (`Weather`), multitud del centro (`SoundFx.luau:619`), andén del metro, mar y fauna. **No hay ambiente de interiores**: el colegio no tiene timbre, pasos ni puertas; la casa no tiene reloj ni tele; el hospital no tiene pitidos. Dentro de una escena puede haber silencio absoluto | `SoundFx.luau`, `Weather.luau` | medio | MODIFICAR: capa de ambiente por tipo de lugar (`Locations` → «Escuela», «Casa»…) y pista `Ambience` en las escenas |

### 3.8 Transiciones de etapa

| Paso | Cómo es hoy | Dónde |
|---|---|---|
| Bebé → niño | Vuelo de 9 s desde tu casa al cielo + «Han pasado varios años…» | `Quests.luau:100`, `Cinematics` `Bebe_AnosDespues` |
| Niño → adolescente | Vuelo de 10 s sobre Los Pinos y el campus + rótulos | `Cole12_UltimoDia.luau:133`, `Nino_AInstituto` |
| Adolescente → universidad o trabajo | Órbita del campus y vuelo sobre el centro, 10 s | `Ins06_LaGranDecision.luau:138`, `Adol_Selectividad` |
| Universidad → vida adulta | El capítulo cambia sin escena; `Uni_Graduacion` sí es buena | `Chapters.luau` |
| Adulto joven → adulto | **Nada**: premio de Adu03 | `Adu03_Reencuentro.luau:72` |

**C-13 (grave, RECONSTRUIR).** El encargo pide que el cambio de etapa sea un acontecimiento: el mundo y los
personajes evolucionan, cambia la música, se ven lugares conocidos y hay un montaje corto. Hoy son vuelos de
cámara iguales para todos. No sale ni un personaje, ni un recuerdo tuyo, ni nada de lo que has decidido. Diseño en §6.3.

### 3.9 Finales de capítulo

**C-18 (grave, RECONSTRUIR).** Solo `Adulto_NuevaVida` tiene `OutroCinematic`. Los demás terminan con la tarjeta de
texto del capítulo. El colegio (fotos + `Nino_FinPrimaria`) y la universidad (`Uni_Graduacion` + brindis)
tienen un buen final en sus misiones. El bebé, el instituto (graduación en chat + vuelo), «Volar del nido» y la
vida adulta no. Propuesta: un final de episodio por etapa (§6.2) con el tema memorable (C-14).

**C-19 (medio).** En el bebé no hay ninguna escena escenificada: la familia habla con frases sueltas (`BabyService.say`).

### 3.10 Fallos conocidos ya arreglados: comprobación

| Fallo | Arreglo | Comprobado | Acción |
|---|---|---|---|
| NPC que flotan o se hunden | `SceneService.groundAt` (l. 116), `spaced` (nadie aparece encima de ti), `SafeGround`/`SafeSpot`, acompañante apoyado en el suelo | ✅ en el código | MANTENER |
| Bocadillos tapados | Bocadillos de la historia `AlwaysOnTop` (`BubbleLayout.style`); si no se ven 1 s, el texto pasa a la caja (`DialogueUI.luau:451-475`); lo que dice el jugador, en la caja (commit 1625a11) | ✅ | MANTENER |
| Frases sueltas que interrumpen | `Guard.bark` (8 s por personaje), los toques no se atienden si hay conversación (`interact` mira `busy`), los `Nudge` miran `busy`, la calle calla con `InDialogue`/`InCinematic` (`SoundFx.luau:575, 595`; commit f60bddc) | ✅ … **salvo M-04**: el servidor no sabe cuándo hay cinemática | MANTENER + arreglar M-04 |
| Conversaciones duplicadas | Token y número de trozo, `queuedKeys`/`answeredKeys`, `DlgApplied` | ✅ (test-lifestory «no se repiten») | MANTENER |
| Controles que no vuelven | `Controls` con contador; `Cinematics.play` con `pcall` | ✅ | MANTENER |

---

## 4. Calidad de la escritura

### 4.1 Valoración general

**La escritura es buena: es lo mejor del proyecto y se MANTIENE.** Los personajes tienen voz propia y humor.
Las frases son cortas, y hay recuerdos condicionados (634 frases, el 21 %, dependen de lo vivido). Ejemplos que funcionan:
- Leire: «Ahora tengo una cámara y un bocadillo de chorizo. El bocadillo es buena compañía, pero no habla.»
- Omar: «Lo sé. Me he chocado dos veces con el marco de la puerta. Mi madre dice que es la edad.»
- Abu: «Un consejo de los de antes: el primer día, sonríe a una persona que no conozcas. Solo a una.»

Lo que falla es **cómo** se cuenta, más que **qué** se dice:

| Id | Hallazgo | Ejemplos | Grav. | Acción |
|---|---|---|---|---|
| W-01 | **Dobletes de género robóticos** (no hay forma de saber si el jugador es chico o chica). 34 casos | «Quiero que seas encargado o encargada», «duermes tranquilo o tranquila», «Estás guapísimo o guapísima», «Bienvenida, bienvenido al equipo» (Adu01, Ins04, Uni03, Uni04, Uni05, Uni06, Pan2, Pan3, Ins03, Saga…; lista en el anexo F) | medio | MODIFICAR: token `{o/a}` con el género que elige el jugador, o reescribir en neutro |
| W-02 | **Demasiado narrador** («contar» en vez de «mostrar»): 26 % de todas las frases; Uni04 50 %, Rarezas 50 %, Adu01 41 %, Uni05 40 %, Metro 100 % | Adu01: «Tu primer turno como responsable: organizas, ayudas, resuelves. Nadie se da cuenta de lo difícil que es. Salvo tú.» (resume una escena que debería verse) | medio | MODIFICAR: cada línea de narrador de una escena clave → acción de actores, plano o rótulo |
| W-03 | **Parrafadas**: 165 frases de más de 150 caracteres (Rarezas 39, Loco_Uni 18, Saga_Acto1 17…) | Saga_Acto3, narrador, 258 caracteres: el cuaderno de Cosme | menor | MODIFICAR: partir en dos o tres frases |
| W-04 | **Monólogos**: 5 o más frases seguidas de la misma persona (Cole12: 8, Ins03: 7, Cole01: 5, Ins04: 5) | Ins03 (las 8 profesiones) | menor | MODIFICAR: reacción del grupo entre medias |
| W-05 | **Continuidad**: ver §4.3 | — | **grave** | MODIFICAR |
| W-06 | «Familia» tiene una voz genérica (`Bio` de una línea; 113 frases). Es el personaje más presente de la infancia y el menos definido | Cast `Familia` | menor | MODIFICAR: perfil propio (manías, frase recurrente) |

### 4.2 Personajes principales y su voz actual

| Personaje | Frases · misiones | Personalidad (`Cast.Bio`) | Voz en la práctica |
|---|---|---|---|
| Narrador | 783 · 130 | — | Demasiado presente; buen humor seco |
| Omar | 167 · 30 | Artista tranquilo, siempre con hambre y un lápiz | ✅ muy distinto (comida, «me lo digo a mí mismo») |
| Cosme | 130 · 26 | Inventor caótico, «criatura», batido de apio | ✅ muy distinto |
| Sara | 126 · 24 | Curiosa y científica, habla rapidísimo, palabras largas | ✅ («Yo quería hablar de hongos») |
| Familia | 113 · 24 | Cariño con prisas, bromea, pregunta qué tal el día | ⚠️ genérica (W-06) |
| Nico | 112 · 26 | Deportista, impulsivo, exclamaciones | ✅ |
| Lucía | 109 · 16 | Tutora, cariñosa y exigente, frases cortas, humor seco | ✅ |
| Pip | 83 · 34 | Robot mayordomo, educadísimo, crisis existencial | ✅ |
| Bruno | 82 · 18 | Fanfarrón; su hermano le presiona | ✅ arco (de malote a «de cero») |
| Abu | 66 · 18 | Calma y refranes, historias de Valmar | ✅ |
| Mateo | 47 · 15 | Tímido, cromos, leal | ✅ |
| Hugo | 47 · 14 | Va con Bruno sin querer, piratas, habla bajito | ✅ |
| Iván / Candela | 46 / 42 · 23 / 21 | Compañeros de cuarto: caótico y generoso / organizadísima | ✅ |
| Rayo / Nerea | 42 / 25 · 4 / 3 | La pandilla | ✅ |
| Carmen | 37 · 4 | Orientadora: «No tienes que saberlo hoy» | ✅ |
| Leire | 36 · 11 | Nueva, cámara de carrete, seca y luego leal | ✅ |
| Cosimo | 28 · 8 | Villano, presentador de concursos | ✅ |
| Yo (el jugador) | 66 · 27 | — | Correcto; habla poco |

(Lista completa con ejemplos: `lune run scripts/audit/narrativa.luau todo`, apartado 8.)

### 4.3 Continuidad: lo que pasó y nadie recuerda

El motor tiene buenas herramientas: `Flags`, `Memories`, `Choices`, `Rel`, `Traits`, `Remember` y `Later`. Pero
muchas marcas se escriben y **nadie las vuelve a leer** (ni las misiones ni el código; los recuerdos sí salen en el diario):

| Tipo | Escritos | Sin leer en ningún sitio |
|---|---|---|
| Marcas (`Flags`) | 222 | **80** |
| Recuerdos (`Memories`) | 128 | **79** (salen en el diario, pero ningún NPC los cita) |
| Decisiones (`Choices`) | 93 | **25** |
| Hechos de NPC (`Remember`) | 4 | todos «SeConocen» (Dani, Lucía, Marisa, Ramón) |

Huecos que más se notan (lista completa en el anexo D):
- **El nombre del grupo** (`NombreGrupo`, Cole03): lo eliges y nadie lo vuelve a decir. Ni en el instituto, ni en el reencuentro.
- **La promesa a Abu** (`PromesaAbu`, Adu02) y **la promesa adulta** (`PromesaAdulta`, Adu03): nunca se cumplen ni se mencionan.
- **La posición en el equipo** (`Posicion`), el talento del festival (`Talento`), el tema del TFG (`TemaTFG`), el primer caso (`PrimerCaso`).
- Recuerdos que ningún NPC cita: `PrimerDiaInstituto`, `PrimerClub`, `QueQuieresSer`, `LaNoche`/`ElCruce` (la
  pandilla), `UltimoDiaCole`, `Practicas`, `PrimerPiso`, `PrimerContrato`, `AtardecerConAbu`, `ElReencuentro`, y
  toda la Saga (`GrietaEnElCielo`, `FinDeLaSaga`…).
- Marcas de la Saga que no cambian nada después: `CosimoPerdonado`, `ConsorcioCaido`, `SagaCompleta`, `AliadosReunidos`.
- `SuspendisteExamen`, `Estudiaste` (Cole06), `JunioAprobado`: nadie te felicita ni te lo recuerda.

Lo que **sí** funciona (MANTENER): las consecuencias diferidas (`Eco_*`, `*_Consecuencias`), la vuelta de Rubén 10 h
después, Bruno «de cero» en el instituto y los flashbacks del último día de colegio.

---

## 5. Clasificación de todos los hallazgos

| Id | Hallazgo (resumen) | Gravedad | Acción |
|---|---|---|---|
| C-02 | Actores que desaparecen de golpe (259) | grave | MODIFICAR |
| C-01 | Teletransporte del jugador sin fundido (17 cortes secos) | grave | MODIFICAR |
| C-04 | La cámara vuelve de golpe | grave | MODIFICAR |
| M-04 | `InCinematic` solo en el cliente (Abu encima del nacimiento; avisos en escenas) | grave | MODIFICAR |
| C-06 | Miradas: los oyentes no miran a quien habla; el NPC que contesta a otro te mira a ti | grave | MODIFICAR |
| C-13 | Transiciones de etapa genéricas; adulto sin escena | grave | RECONSTRUIR |
| M-06 | Adulto joven → adulto como premio | grave | RECONSTRUIR (con C-13) |
| M-07 | Final de la vida = ir a casa + texto | grave | RECONSTRUIR |
| C-18 | Finales de capítulo con tarjeta de texto | grave | RECONSTRUIR |
| C-12 | Escenas importantes como chat; motor nuevo casi sin usar | grave | RECONSTRUIR (las escenas clave) · MANTENER el motor |
| C-09 | UniS_Cita sin la otra persona (grave). Hay otras 20 conversaciones en las que habla alguien que no está en la escena. Unas son a propósito, por teléfono o con una voz (mejor enseñarlas como móvil); otras no: Cole06 `Aprobado`, Cole08 `Medallas`, Cole07 `Vuelta`, Uni06 `Foto` (Leire)… (medio) | grave / medio | MODIFICAR |
| W-05 | Continuidad: 80 marcas, 79 recuerdos y 25 decisiones sin leer | grave | MODIFICAR |
| M-01 | «Esa noche…» de día en multijugador | medio | MODIFICAR |
| M-02 | Al reaparecer te lleva a cualquier misión, sin fundido | medio | MODIFICAR |
| M-03 | Lugar que falta: el paso se da por hecho en silencio; sin prueba contra el mapa | medio | MODIFICAR |
| M-05 | Instituto sin cinemática ni música; Volar del nido y Tu vida sin entrada | medio | MODIFICAR |
| M-08 | Adulto_NuevaVida sin conversaciones | medio | MODIFICAR |
| M-09 | El instituto repite las frases del colegio | medio | MODIFICAR |
| C-03 | Entradas: aparecen en su marca; salto si se mueven más de 70 studs | medio | MODIFICAR |
| C-05 | Cámara de diálogo: 3 planos automáticos, sin general, reacción ni inserto | medio | MODIFICAR |
| C-07 | Sin pausas ni ritmo en las frases | medio | MODIFICAR |
| C-08 | Gestos y emociones casi nunca marcados | medio | MODIFICAR |
| C-10 | 25 conversaciones solo de narrador o del jugador | medio | MODIFICAR |
| C-11 | 97 acotaciones escritas en el texto | medio | MODIFICAR |
| C-14 | Música: 4 piezas, sin intensidades | medio | MODIFICAR |
| C-15 | Sin ambiente de interiores | medio | MODIFICAR |
| C-16 | Otros jugadores en plano durante tu escena | medio | MODIFICAR |
| C-19 | Bebé sin escenas escenificadas | medio | MODIFICAR |
| W-01 | Dobletes de género (34) | medio | MODIFICAR |
| W-02 | Narrador en exceso (26 %) | medio | MODIFICAR |
| M-10 | Capítulo puente desactivado | menor | MANTENER |
| M-11 | Secundarias viejas sin escena | menor | MODIFICAR |
| M-12 | Metro: todo narrador | menor | MODIFICAR |
| C-17 | Sin iluminación por escena | menor | MODIFICAR |
| W-03 | 165 parrafadas | menor | MODIFICAR |
| W-04 | Monólogos | menor | MODIFICAR |
| W-06 | «Familia» sin voz propia | menor | MODIFICAR |

Total: **0 bloqueantes · 12 graves · 18 medios · 7 menores** (37). C-09 cuenta como grave: la cita sin la otra persona.

**MANTENER sin tocar:**
- el motor de misiones y su vigilante;
- `Validate`, `EventCatalog`, `Conditions` y `Later`;
- los guardados;
- el aislamiento por jugador de las escenas;
- `Controls`, `Guard` y el reenvío de conversaciones;
- los arreglos de suelo y bocadillos;
- el texto de las misiones, salvo lo señalado.

---

## 6. Plan de implementación

### 6.1 El sistema CINEMATIC_SCENE: ampliar el motor que ya existe

**No se crea un motor nuevo.** Las escenas de `Happenings` (`Sequencer` + `CameraShots` + `HappeningService` +
`HappeningClient`) ya traen casi todo lo que pide el encargo:
- cámara con todos los tipos de plano y cortes;
- actores que aparecen, andan, miran, cambian de emoción, hacen gestos, dicen frases y se van;
- esperas (`Input`, `Near`, `Arrived`), cielo, efectos, sonido, música, rótulos y memoria del mundo;
- saltar sin perder las consecuencias, y pruebas (test-scenes).

**CINEMATIC_SCENE = una escena de `Happenings` con estas ampliaciones**:

| Pide el encargo | Hoy | Ampliación (pista o campo) |
|---|---|---|
| Cámara con intención | `Camera` con From/To, Fixed, Orbit, Follow | **Presets** en `CameraShots.preset(name, actors)`: `General`, `Medio`, `PrimerPlano:X`, `PPP:X`, `Hombro:X>Y`, `DosPlanos:X,Y`, `Lateral:X`, `Reaccion:X`, `Seguir:X`, `Inserto:Objeto`. Movimientos `Dolly`, `Pan`, `Tilt` = travelling con `LookTo`. Se traducen a los planos que ya existen (sin código nuevo de cámara en el cliente) |
| Actores, entradas y salidas andando | `Spawn`, `Move`, `Despawn` | `Enter = { From = "Puerta"/lugar, Walk = true }`, `Exit = { To = …, Walk = true }`, `Sit`/`Stand`, `Carry`/`Drop` (objeto), `Door` (abrir y cerrar) |
| Mirada contextual | `Look = { Key, At }` | `Look = "Speaker"` por defecto para todo el reparto; `At = "Suelo"` (vergüenza), `Away` (pensar), `Door`, objeto |
| Emociones y gestos | `Mood`, `Gesture` (ActorMoods, Emotion) | Mismas emociones; la tabla del encargo (alegría, tristeza, enfado, sorpresa, nervios, vergüenza) → `ActorMoods` + `ReactMotion` |
| Diálogo con pausas y subtítulos | `Lines` (subtítulo con tiempo) | **Pista `Dialogue`**: líneas `{ S, T, To?, A?, G?, Pause?, Beat?, Shot? }`. Las preguntas (`Ask`) van por **DialogueService**: efectos en el servidor y sin repetir, igual que ahora. La escena espera con `Wait = { Input = "…" }` |
| Ambiente | — | **Pista `Ambience`**: capa por tipo de lugar (colegio, casa, universidad, hospital, calle) con fundido; nunca silencio absoluto |
| Música por intensidad | `Music` (una pieza) | `Music = { Intensity = "Nada|Descubrimiento|Intima|Tension|Resolucion|Tema" }` → `StoryAudio` cruza entre piezas o capas |
| Iluminación | `Sky` (moods de cielo) | **Pista `Light`**: presets (`InteriorCalido`, `Atardecer`, `Noche`) solo en tu pantalla y que **siempre** se deshacen; con la noche local se arregla M-01 |
| Eventos | `World`, `Fx`, `Sound` | + `Effects` (los efectos de misión de siempre, en el servidor) |
| Condición de final | `Duration` + esperas | + `Until = { Event = "…" }` y `OnSkip` |
| Control bloqueado y restaurado SIEMPRE | `Controls("Escena")` + `pcall` | El **servidor** marca `InScene` (arregla M-04) y hay un latido del cliente. Sin latido, el servidor cierra la escena. El cliente lo devuelve todo en un `finally`: al morir, al reaparecer, al teletransportarse y al salir. Vuelta de cámara **suave** (arregla C-04) |
| Aislamiento multijugador | Actores por jugador (SceneService) | + ocultar a los otros jugadores que entran en el encuadre (solo en tu pantalla) · sin frases sueltas ni avisos mientras `InScene` · cola de escenas por jugador |
| Cinemáticas dinámicas | `If`/`IfNot` con `Input` | `If` con `Conditions` completas (`Flags`, `Rel`, `Memories`, `Late`, `Items`…), resueltas en el servidor al empezar: **variantes** por cómo te llevas con el personaje, si llegaste tarde, si discutisteis o si tienes cierto objeto |

**Puente para las 294 escenas que ya existen: «escenificación automática»**. No se pueden reescribir todas a mano.
Una capa nueva (`StageDirector`) toma un paso `Scene` con su `Dialogue` de siempre y le añade:
1. entrada: quien está lejos se acerca unos pasos y se gira;
2. plano general de situación (0,8 s) → planos de hombro o de dos según quién hable → plano de reacción en las preguntas;
3. todo el reparto mira a quien habla;
4. pausas según la puntuación («…» = 0,6 s, «.» al final = 0,3 s);
5. salida suave de la cámara.

Una escena importante puede pedir `Stage = "IdDeEscena"` para usar una CINEMATIC_SCENE escrita a mano. **Ningún dato
de misión cambia de formato**: lo nuevo son campos opcionales y el validador los comprueba.

Regla: cada escena nueva responde a las cinco preguntas de la regla de oro del encargo, en un comentario arriba de su definición.

### 6.2 Escenas que hay que cinematizar, por orden y por etapa

Prioridad 1 = finales y transiciones (lo que más se recuerda). Prioridad 2 = primeros encuentros y conflictos.
Prioridad 3 = el resto, que se cubre con la escenificación automática.

| Etapa | Prioridad 1 | Prioridad 2 | Prioridad 3 |
|---|---|---|---|
| Bebé | Nacimiento con la familia en la cuna (hoy solo cámara) · Primeros pasos: Abu de rodillas con los brazos abiertos | Ventanal: la familia detrás del bebé | Exploración de la casa |
| Niño | **Final de episodio**: Cole12 despedidas + cápsula + foto · montaje niño → adolescente | Cole01 `ConoceLucia` y `Bienvenida` (presentar a la clase), `LibrosCaen` (Mateo), `Cena` · Cole04 enfrentamiento con Bruno · Cole06 la nota · Cole08 final y medallas con la familia **presente** · Cole09 la foto de Lucía (descubrimiento: general → reacción → primer plano → inserto → reacción) | Cole02, Cole03, Cole05, Cole07, Cole10, Cole11 |
| Adolescente | **Final**: Ins06 `Noche` (decisión en casa) + graduación + montaje | Ins01 `Parada` y Leire · Ins03 Carmen · Pan2 la noche del súper y la comisaría (tensión) · Pan3 el cruce · Ins04 la entrevista · Ins05 el rumor (discusión con Nico) | Ins02, `Adol_Jornada` |
| Universidad | **Final**: Uni06 ceremonia + brindis + `Final` (hoy solo narrador) | Uni01 llegada al campus y Beltrán · Uni01b primera cena · Uni02 la pelea del grupo · Uni04 el error del informe (confesión) · Uni05 la caja de Abu · UniS_Cita con la persona **en escena** | UniEx1–4, secundarias |
| Profesión | Adu01 primer día con contrato (hoy 41 % narrador) | Ascenso (evento `Promoted`: escena corta con tu jefe) · **despido** (no existe: contenido nuevo) · entrevista Uni03 | Recados de trabajo |
| Vida adulta | **Montaje adulto joven → adulto** · **final de la vida** (`Adulto_MirarAtras` reconstruida: la casa, la familia, el álbum de `Memories`, la gente que conociste) | Adu02 hospital y atardecer con Abu · Adu03 el banco del parque | Saga: `Saga_Final`, `Saga_Fusion` al motor nuevo |

### 6.3 Diseño del montaje de cambio de etapa

Una escena de `Happenings` por transición (`Happenings/Etapas.luau`), en cuatro tiempos (25–40 s, se puede saltar):

1. **Cierre íntimo** (6–8 s): plano medio del último momento de la etapa (Abu arropando al bebé, la foto del
   grupo, el birrete). Música íntima.
2. **Tus recuerdos** (10–15 s): 3 o 4 «fotos vivas». Se eligen de tus `Memories` y `Choices` por prioridad: el amigo
   que ayudaste, tu grupo con su nombre, tu club, tu carrera. Cada una es un plano fijo con los actores reales
   de la misión, puestos en su lugar conocido, congelados con un ligero zoom, con rótulo y transición `Dip`.
3. **El mundo cambia** (6–8 s): vuelo por un lugar conocido de la etapa nueva con sus personajes ya mayores (escala
   `Teen`/adulto), y la música sube al tema de la etapa nueva.
4. **Llegada** (4–6 s): la cámara baja hasta el jugador ya crecido, en el primer sitio de la etapa nueva, y se suelta
   suave. La edad cambia (`ScaleTo`) mientras la pantalla está en los recuerdos, nunca a la vista.

Datos: `Montajes = { Bebe_Nino = {…}, Nino_Adolescente = {…}, Adolescente_Joven = {…}, Joven_Adulto = {…} }`. Cada tiempo
dice qué recuerdos admite, con prioridad y un plan B genérico, para que nunca quede vacío. `Transition.Cinematic` ya existe:
solo cambia el Id. Para «adulto joven → adulto», un paso `Transition` en Adu03 sustituye a `Rewards.SetStage`.

### 6.4 Reparto en paquetes independientes (agentes en paralelo, sin tocar los mismos archivos)

**Primera ola** (se pueden hacer a la vez). El formato de datos se congela en la §6.1 de este documento, y los
paquetes de contenido escriben contra él.

| Paquete | Qué hace | Archivos (solo estos) | Arregla |
|---|---|---|---|
| **P1 · Motor de escenas** | Pistas `Dialogue`, `Ambience`, `Light`; presets de plano; `Enter`/`Exit`; `Look = "Speaker"`; variantes con `Conditions`; validación de lo nuevo | `src/shared/LifeStory/Sequencer.luau`, `src/shared/CameraShots.luau`, `src/server/Services/HappeningService.luau`, `src/client/Controllers/HappeningClient.luau`, `src/client/Controllers/StoryFx.luau`, `scripts/test-scenes.luau` | C-05, C-12 (base) |
| **P2 · Control, cámara y aislamiento** | `InScene` en el servidor + latido; vuelta de cámara suave; ocultar a otros jugadores en plano; arreglo de BabyService | `src/client/Controllers/Controls.luau`, `src/client/Controllers/CineCamera.luau`, `src/client/Controllers/Cinematics.luau`, `src/server/Services/CinematicService.luau`, `src/server/Services/BabyService.luau`, `src/client/Controllers/SceneClient.luau` | M-04, C-04, C-16 |
| **P3 · Motor de la historia** | `busy()` cuenta las escenas; `afterRevive` solo con la misión seguida; noche local en `Transition` con varios jugadores; aviso al saltar un lugar que falta | `src/server/Services/LifeStoryService.luau` (**solo este paquete lo toca**) | M-01, M-02, M-03 |
| **P4 · Actores: entrar, salir, mirar** | Salidas andando o desvanecidas; entradas desde un lugar; teletransporte del jugador con fundido; mirada de grupo e interlocutor (`To`) | `src/server/Services/SceneService.luau`, `src/client/Controllers/ActorLife.luau`, `src/shared/LifeStory/ActorMoods.luau`, `src/shared/LifeStory/Emotion.luau` | C-01, C-02, C-03, C-06 |
| **P5 · Conversaciones escenificadas** | `StageDirector` (escenificación automática); `Pause`/`Beat`/`To`/`Shot` en las líneas; pausas por puntuación; token de género `{o/a}`; validación de los campos nuevos | `src/client/Controllers/DialogueUI.luau`, `src/server/Services/DialogueService.luau`, `src/client/UI/SpeechBubbles.luau`, `src/client/UI/BubbleLayout.luau`, `src/shared/LifeStory/Validate.luau`, `src/shared/LifeStory/Strings.luau`, nuevo `src/shared/LifeStory/StageDirector.luau` | C-05, C-07, W-01 (motor) |
| **P6 · Audio** | Música por intensidad (5 piezas nuevas con `compose.py`), capas de ambiente por lugar, `Ambience` en escenas | `src/client/Controllers/StoryAudio.luau`, `src/client/Controllers/SoundFx.luau`, bloque `Audio` y `Sounds` de `src/shared/Config.luau` (solo ese bloque), `audio/`, `scripts/audio/` | C-14, C-15 |
| **P10 · QA** | Prueba de lugares contra el mapa real; prueba de cliente (cámara y controles vuelven, otros jugadores ocultos); «Romperlo» para secundarias y morir en todas; ampliar `scripts/audit/narrativa.luau` | `scripts/audit/*`, nuevo `scripts/test-cinematic.luau`, `scripts/test-playthrough.luau`, `scripts/lib/StoryHarness.luau` | M-03, cobertura |

**Segunda ola** (cuando P1, P4 y P5 hayan entrado). Cada paquete de contenido es **dueño de sus archivos de misión**,
tanto para escenificar como para reescribir, y así nunca dos agentes tocan la misma misión:

| Paquete | Qué hace | Archivos |
|---|---|---|
| **P7 · Montajes y finales** | Los 4 montajes de etapa; finales de episodio; `Adulto_MirarAtras` reconstruida; entradas de capítulo | nuevo `src/shared/LifeStory/Happenings/Etapas.luau`, `HappeningIndex.luau` (añadir el grupo), `Chapters.luau`, `Quests.luau`, `Cinematics.luau` |
| **P8a · Niño y bebé** | Escenas de prioridad 1–2, continuidad (nombre del grupo…), acotaciones → acción, narrador → escena | `Misiones/Cole*.luau`, `Misiones/Cole_Consecuencias.luau`, `Misiones/Prologo_Sueno.luau`, nuevo `Happenings/Colegio.luau` |
| **P8b · Adolescente** | Íd. + frases propias de `Adol_Jornada` | `Misiones/Ins*.luau`, `Misiones/Pan*.luau`, `Misiones/Loco_Adolescente.luau`, `SchoolLife.luau`, `DayPlans.luau`, nuevo `Happenings/Instituto.luau` |
| **P8c · Universidad** | Íd. + cita con la persona en escena | `Misiones/Uni*.luau`, `Misiones/Loco_Uni.luau`, nuevo `Happenings/Universidad.luau` |
| **P8d · Profesión y adulto** | Íd. + escenas de ascenso y despido (contenido nuevo), Adulto_NuevaVida con actores | `Misiones/Adu*.luau`, `Misiones/Loco_Adulto.luau`, `Misiones/Metro_Secundarias.luau`, nuevo `Happenings/Adulto.luau` |
| **P8e · Saga, Rarezas y Aliados** | `Saga_Final`/`Saga_Fusion` al motor nuevo; recuerdos de la Saga citados; partir las parrafadas | `Misiones/Saga_Acto*.luau`, `Misiones/Rarezas.luau`, `Misiones/Aliados.luau`, `Misiones/Loco_Nino.luau`, `Happenings/Cielo.luau` |
| **P9 · Reparto** | Perfil de «Familia», `Bio` con forma de hablar y muletillas para quien escriba | `src/shared/LifeStory/Cast.luau` |

Reglas para todos los paquetes:
- `git add` solo de sus archivos;
- pasar `validate-report`, `test-scenes`, `test-playthrough` y `test-lifestory` antes de subir;
- ningún formato viejo deja de funcionar;
- cada paquete añade sus pruebas.

La **tercera revisión** del encargo («¿esto parece una película?») se hace al final, en un servidor de Roblox, escena
por escena de la tabla §6.2.

---

## Anexos (generados con `lune run scripts/audit/narrativa.luau todo`)

