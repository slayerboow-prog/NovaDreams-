# Biblia Maestra · Volumen V — El cine

> HEROES OF HISTORY · «Los Ocho Mundos» · Referencia oficial.
> Cómo se dirigen las escenas y guion técnico de las 15 grandes secuencias. Todo lo que se pide aquí se apoya en el
> motor de escenas que ya existe (§1). Lo que el motor todavía no sabe hacer está listado en el §7, con su auditoría
> previa. **No se toca ningún sistema sin auditarlo antes** (decisión del dueño).

---

## 1. Auditoría del motor existente (lo que ya sabe hacer)

Revisado el 18-11-2026 en `shared/LifeStory/Sequencer.luau`, `shared/CameraShots.luau`,
`client/Controllers/HappeningClient.luau`, `CineCamera.luau`, `SceneDirector.luau`, `ActorStaging.luau` y
`ActorMoods.luau`.

| Capacidad | Cómo se pide en una escena | Estado |
|---|---|---|
| **Línea de tiempo con pistas** | Escena de `Happenings` con `Tracks` (cada suceso con `At`) | Funciona |
| **Planos con nombre** | `Shot = "General" / "Medio:X" / "PrimerPlano:X" / "PPP:X" / "Hombro:X>Y" / "DosPlanos:X,Y" / "Lateral:X" / "Reaccion:X" / "Seguir:X" / "Inserto:Objeto" / "Dolly:X" / "Pan:X>Y" / "Tilt:X"` | Funciona; respeta la regla de los 180° |
| **Movimientos libres** | `Travelling { From, To, Look }`, `Fijo`, `Órbita { Radius, Height, FromAngle, ToAngle }`, `Seguir { Follow = "Actor:X" }` | Funciona |
| **Lente y pulso** | `Fov` (fijo o zoom), `Roll` (inclinar), `Shake` (cámara en mano), `Easing` | Funciona |
| **Transiciones** | `Cut = "Cut" / "Dip" / "Fade" / "Flash"` | Funciona |
| **Diálogo en el mundo** | `Dialogue { S, T, To, A (emoción), Pause, Beat, Shot }`; bocadillo, subtítulo en la banda y voz sintetizada | Funciona |
| **Silencio y reacción** | `Pause` (antes y después de la frase); `Beat = Mirar / Suelo / Apartar / Pensar / Respirar` | Funciona |
| **Actores que se mueven** | `Actors`: `Enter` y `Exit` andando o corriendo desde un ancla, `Look` (a quien habla, al suelo, a otro lado), `Mood` (Calm, Fear, Angry, Surprise, Joy, Sad, Hurt, Nervous, Shame) | Funciona |
| **Gestos** | `Acting` y `Beat`: Wave, Point, Cheer, Laugh, Dance | Funciona (repertorio corto) |
| **Luz de cine** | `Light`: InteriorCalido, Atardecer, Noche, Intima, Tension, Sueno, Grieta, Ceniza, Impacto, Recuerdo; luz de relleno automática de noche | Funciona; se deshace siempre |
| **Música por intensidad** | `Music { Intensity = Nada / Descubrimiento / Intima / Tension / Resolucion / Tema }`; `Silence` | Funciona |
| **Ambiente** | `Ambience` (o «Auto», el del sitio) | Funciona |
| **Efectos** | `Fx` (meteorito, impacto, portal, grieta, orbe, aura, tormenta…), `Sky` y `SkyRift` (la Grieta en el cielo), `Shake`, `Sound`, `Titles`, `Fade` | Funciona |
| **Interrupciones** | `Wait` (la escena se para hasta que pasa algo, por ejemplo «¡Cúbrete!»), `Until` (termina con un suceso del juego) | Funciona |
| **Consecuencias** | `If` / `IfNot` / `Variants` con Flags, Choices, relaciones y memorias | Funciona |
| **Saltar** | Botón «Saltar»; `OnSkip` deja hechas las consecuencias | Funciona |
| **Multijugador** | `Scope = Personal / Group / World`; `Queue` | Funciona |
| **Vuelta al control** | `CineCamera.restore`: vuelta suave en ~1 s; bandas de cine y menús escondidos mientras dura | Funciona |
| **Dirección automática** | `SceneDirector`: ambiente, luz según la hora, planos que «respiran» | Funciona |

**Conclusión:** el motor ya cubre la gramática de la directiva. Lo que falta es repertorio corporal, cortes a mitad de
frase, temas musicales y algunos efectos propios (§7).

---

## 2. Tres niveles de escena

| Nivel | Qué es | Cámara y control | Ejemplos |
|---|---|---|---|
| **A · Escena del mundo** | Algo pasa mientras juegas | Sin bandas, sin quitar el control (`Scope = World` o escena ligera) | Un Coloso cruza el horizonte; una nave aterriza mientras dos discuten |
| **B · Conversación dirigida** | Personajes que hablan en el mundo | Bandas y planos; tocar para seguir | La mayoría de las escenas de misión |
| **C · Gran secuencia** | Las 15 secuencias del §6 y los finales | Bandas, planos de autor, música propia; «Saltar» con consecuencias | La muerte de Kael, el encuentro con Ithar |

Un acto de campaña tiene, como norma: 1 escena C como mucho, de 4 a 8 B y las A que pida el mundo. Si hay más
cinemáticas de la cuenta, se pierde el control del jugador y la película se convierte en vídeo.

---

## 3. Gramática cinematográfica (obligatoria)

| Plano de la directiva | En el motor | Cuándo | Cuándo NO |
|---|---|---|---|
| 1 · Establecimiento | `General` u `Órbita` lenta o `Travelling` alto (6-10 s), con `Ambience` del sitio | Al llegar a un lugar nuevo o a un gran acontecimiento | En lugares ya conocidos (máximo 3 s) |
| 2 · Presentación | `Medio:X`, con X descentrado y mirando a otro (`To`) | Quien habla por primera vez en la escena | Para cada frase |
| 3 · Primer plano emocional | `PrimerPlano:X`, `PPP:X` o `Dolly:X` | La frase que duele, la confesión | Más de 2 o 3 por escena |
| 4 · Reacción | `Reaccion:Y`, con `Pause { After = 1.2 }` y un `Beat` | Después de una noticia terrible: no se corta enseguida | En réplicas rápidas |
| 5 · Sobre el hombro | `Hombro:X>Y` y `Hombro:Y>X` | Discusiones, interrogatorios, negociaciones | Conversaciones tranquilas |
| 6 · Acción | `General`, `Órbita` con `Shake`, o `Travelling` con `Fov { 70, 55 }` | Empieza una batalla o pasa algo grande | Durante el combate jugable: la cámara es del jugador |

**Reglas de autor.**
- **Composición.** El que habla, a un tercio de la imagen y mirando hacia el espacio libre. Nunca dos personajes de
  frente a cámara a la vez.
- **El eje.** Un eje por conversación (regla de los 180°, que el motor ya cuida). Se cambia con un plano de movimiento,
  nunca con un corte.
- **Ritmo.** Las frases cortas van con planos largos y los planos cortos con frases largas. Ningún plano dura menos de
  1,5 s salvo en un golpe de acción.
- **Lo que no se dice.** Antes de cada verdad, un `Pause` de 1-2 s. Después, un plano de reacción.

---

## 4. Movimiento, interrupciones, silencio y música

### 4.1 Personajes que se mueven
- **Nadie queda quieto en una escena de más de 20 s.** Hay que usar al menos un `Enter`, `Exit`, `Look` o `Beat` de
  movimiento.
- **Repertorio por personaje.** Hoy se apoya en Mood y Beat. Las posturas nuevas del §7 quedan pendientes.

| Personaje | Al hablar | Cuando le duele algo |
|---|---|---|
| Kael | Quieta, con los brazos detrás (postura nueva); cierra puertas al entrar | Mira al suelo y cuenta en voz baja |
| Sorel | Se mueve, gesticula (Point) | Aparta la mirada (`Apartar`) |
| Brenn | De frente, hombros cerrados | Aprieta la empuñadura (postura nueva) |
| Ilse | Toca el auricular (postura nueva) | `Pensar` |
| Cosme | Se apoya en el bastón (postura nueva); bromea (Laugh) | Se queda quieto: en él, eso ya es dramático |
| Ithar | No hace ningún gesto; solo gira la cabeza | Se toca la corona (postura nueva) |

### 4.2 Interrupciones
Con lo que ya existe:
- `Wait` («¡Cúbrete!»);
- un `Fx` de impacto con `Shake` y `Cut = "Flash"`;
- un actor que entra corriendo (`Enter { Run = true }`);
- un actor que se va antes de terminar (`Exit` a mitad de diálogo).

Lo que falta es **cortar una frase a medias** (`Cut` en la línea, §7).

### 4.3 Silencio
- `Silence` y `Music { Intensity = "Nada" }`, más el `Ambience` del sitio en solitario.
- Silencio obligatorio en: muertes, traiciones, revelaciones, despedidas, reencuentros y decisiones difíciles.
- Dura al menos un plano completo.

### 4.4 Música

**Capas** (lo que ya hace el motor):
1. ambiente del planeta;
2. Descubrimiento o Íntima;
3. Tensión;
4. combate;
5. Resolución.

**Identidad por planeta** (detalle en el Vol. IV):

| Planeta | Instrumentos |
|---|---|
| Valmar | Piano gastado y cuerdas |
| Tefra | Martillos, metales y acordeón |
| Miasma | Cristal frotado y pads que respiran |
| Siroco | Laúd, percusión de mano y viento |
| Nivalis | Coro femenino lejano y celesta |
| Umbría | Maderas, flautas y gotas |
| Tálasa | Graves profundos y cantos de ballena procesados |
| Vértice | Sintetizador limpio que se degrada |
| Oren | Coro de voces sin palabras |

**Temas de personaje:**

| Personaje | Tema |
|---|---|
| Kael | Cello solo |
| Sorel | Melodía silbada que pierde notas |
| Brenn | Percusión grave que se convierte en marcha |
| Ilse | Estática que se convierte en nana |
| Cosme | Acordeón desafinado |
| Lys | Flauta con eco |
| Ithar | Coro con una nota grave que no resuelve |

- **Nunca música épica en escenas íntimas.** La épica se reserva para las batallas y para la luz de un Sello.

---

## 5. Multijugador, saltos y vuelta al control

| Situación | Regla | Motor |
|---|---|---|
| Escena de historia personal (las 15 grandes) | `Personal`: cada jugador la ve en su partida | Existe |
| Misión en grupo | `Group`: quien está cerca y en el mismo paso se une. Las esperas y los toques los decide quien la empezó. «Saltar» solo saca a quien lo pulsa. | Existe |
| Acontecimientos del mundo (asedios, un Sello que se enciende para todos) | `World`: los demás ven efectos, cielo y sonido sin perder el control | Existe |
| Jugador que llega tarde a una escena de grupo | Ve el resto desde su sitio. Lo que se perdió queda en `Variants` con `Late = true` (una frase de resumen de un PNJ) | Existe (`Late`) |
| Decisiones | **Siempre individuales** (cada uno elige en su partida). En grupo, cada jugador ve su propio menú; las consecuencias del mundo compartido son canónicas (Vol. III §6.3). | Existe |
| Saltar | Se puede saltar toda escena B o C. **Las decisiones nunca se saltan:** van fuera de la escena. | Existe (`OnSkip`) |
| Vuelta al control | Toda escena termina con la cámara volviendo detrás del jugador en ~1 s, mirando hacia el siguiente objetivo | Existe (`restore`); falta «mirando al objetivo» (§7) |
| Accesibilidad | Subtítulos siempre con el tiempo de lectura (`ReadingTime`); «tocar para seguir» en las conversaciones | Existe |

---

## 6. Las 15 grandes secuencias (guion técnico)

**Formato:** cada secuencia indica la misión de destino, la duración, el alcance (`Scope`), la intención emocional, los
planos en orden, los actores, la luz, el sonido, la vuelta al control y lo que hace falta del motor.
**Leyenda:** ✅ ya existe en el motor · 🆕 capacidad nueva (§7).

### S1 · La caída de Valmar
- **Dónde:** recuerdo jugable al empezar Valmar IV (Brenn cuenta la noche del Sur). También al final de `Gri03`, cuando
  se lee la orden de las 23:40.
- **Duración:** 2 min 30 s.
- **Alcance:** Personal.
- **Intención:** que el jugador entienda el crimen de Varn antes de que haya un culpable en pantalla.

| # | Plano | Qué se ve | Sonido |
|---|---|---|---|
| 1 | `Travelling` alto sobre la Valmar moderna de noche, `Light = Atardecer→Noche` | La ciudad intacta: tráfico y ventanas | Ciudad normal; un pulso grave lejano |
| 2 | `Fijo` hacia el observatorio orbital; `Fx = grieta` + `SkyRift` + `Cut = "Flash"` | Se abre la Grieta en el cielo | Silencio de 1 s y después un trueno ✅ |
| 3 | `Seguir:Tomas` (Tomás joven, 17) corriendo por la calle del mercado; `Shake 0.4` | Bestias entre los coches, gente huyendo | Alarmas ✅ |
| 4 | `Inserto` del reloj de la torre: 23:40 | — | Tic del reloj |
| 5 | `Medio:Varn` en un despacho, firmando; `Light = InteriorCalido` | Varn firma la orden | Solo el bolígrafo |
| 6 | `PrimerPlano:Tomas` en una cabina, llamando; `Light = Noche` | — | «Brenn. Brenn, ¿me oyes?» |
| 7 | `Reaccion:Brenn` joven, en la muralla, teléfono en mano | — | «Espera a la evacuación. Vendrán.» |
| 8 | `General` del Sur cubierto de ceniza; `Fade` a negro | Las luces del Sur se apagan barrio a barrio | Silencio total ✅ |

- **Vuelta al control:** con Brenn en el presente, en la muralla. Su línea: «Le dije que esperara.»
- **Motor:** todo ✅. Hacen falta los modelos de la Valmar moderna intacta: ya existen en la ciudad antigua, que se
  reutiliza como decorado del recuerdo.

### S2 · La primera aparición de los Velados
- **Dónde:** Valmar IV, la noche del asedio.
- **Duración:** 1 min 40 s.
- **Alcance:** Group (todos los que defienden la muralla) y World para los que estén lejos.
- **Intención:** miedo nuevo. Hasta ahora las bestias eran animales; esto son personas.

| # | Plano | Qué se ve | Sonido |
|---|---|---|---|
| 1 | `General` desde la muralla, con niebla gris avanzando; `Light = Ceniza` | El Sur sin luz | Viento, perros que aúllan y callan |
| 2 | `Dolly:Velado1` lento | Siluetas humanas quietas en la niebla | El pulso de once segundos ✅ |
| 3 | `Órbita` corta alrededor de Sorel | Sorel se lleva la mano a la sien: oye el pulso antes que nadie (semilla) | — |
| 4 | `General`: todos los Velados giran la cabeza **a la vez** | — | Un coro bajo, una sola nota |
| 5 | `Medio:Kael`: «Que nadie dispare hasta que yo lo diga.» | — | — |
| 6 | `Pan:Muralla>Puerta`; `Cut = "Flash"` | Los Hijos de la Ceniza abren la puerta desde dentro | Golpe metálico y alarma ✅ |

- **Vuelta al control:** combate de defensa en la muralla.
- **Motor:** ✅. 🆕 Velados con giro sincronizado (animación de grupo, §7.4).

### S3 · El descubrimiento de Tomás
- **Dónde:** Valmar IV (Brenn le reconoce). Se completa con la frase de la muralla en el asedio.
- **Duración:** 1 min 10 s.
- **Alcance:** Personal.
- **Intención:** romperle el corazón a Brenn sin una sola palabra de más.

| # | Plano | Qué se ve | Sonido |
|---|---|---|---|
| 1 | `Hombro:Brenn>Tomas` a distancia | Un Velado joven con la chaqueta de Brenn de cuando eran críos | El pulso |
| 2 | `PrimerPlano:Brenn` | Brenn no se mueve | Silencio ✅ |
| 3 | `Inserto`: la empuñadura «B. y T.» en su mano | — | — |
| 4 | `PrimerPlano:Tomas`; `Light = Recuerdo` durante 2 s | Tomás inclina la cabeza como un niño | Un acorde del tema de Brenn, roto |
| 5 | `Reaccion:Sorel`, `Beat = Mirar` | — | — |
| 6 | `Medio:Brenn`: «Tomás.» Una palabra. `Pause { Before = 2, After = 2 }` | Tomás se da la vuelta y se va con la niebla | — |

- **Vuelta al control:** Brenn se queda quieto y el jugador tiene que decidir si se acerca (variante de Rel).
- **Motor:** ✅. 🆕 Postura «aprieta la empuñadura».

### S4 · La llegada a Tefra
- **Dónde:** `Tef01` (existe). Se mejora con la nueva dirección.
- **Duración:** 1 min 20 s.
- **Alcance:** Personal (o Group si el jugador vuela con otros).
- **Intención:** escala. Un planeta entero convertido en máquina de guerra.

| # | Plano | Qué se ve | Sonido |
|---|---|---|---|
| 1 | Entrada atmosférica (el sistema de vuelo existente) con `Shake` | Cielo malva, Ovilla ocupando medio cielo | Viento de reentrada |
| 2 | `Travelling` alto sobre Bastión Ceniza | Murallas negras, foso de lava, chimeneas, la Gran Cúpula partida | Martillos de forja a lo lejos (tema de Tefra) |
| 3 | `Órbita` alrededor de los Pozos de Magma | La Lanza, que se ve desde todas partes | Retumbar volcánico |
| 4 | `General` de la Calle del Horno en ruinas | Un muro con una ventana redonda | Silencio salvo la ceniza |
| 5 | `Medio:Cosme`: «Huele igual. A azufre y a pan.» | — | — |

- **Vuelta al control:** en la Calle del Horno (la misión existente sigue igual).
- **Motor:** ✅. Requiere la Gran Cúpula y la Lanza visible (Vol. IV Tefra).

### S5 · El regreso de Cosme
- **Dónde:** Tefra IV, en el asedio de Bastión: el encuentro con Lía.
- **Duración:** 2 min.
- **Alcance:** Personal.
- **Intención:** el chiste que no sale.

| # | Plano | Qué se ve | Sonido |
|---|---|---|---|
| 1 | `General` del Puente de los Mil Candados en plena batalla | Velados de la guardia de Corvo cruzando | Combate (se apaga) |
| 2 | `Seguir:Cosme` | Cosme se separa del grupo con el bastón | El acordeón, una sola nota |
| 3 | `Hombro:Cosme>Lia` | Una Velada con un zapato de niño colgado del cinturón | — |
| 4 | `PrimerPlano:Cosme`: «Lía… He traído el otro.» (el zapato) | Cosme saca el zapato petrificado de `Tef01` | Silencio ✅ |
| 5 | `PrimerPlano:Lia`; `Light = Recuerdo` 1,5 s | Un segundo de reconocimiento | — |
| 6 | `DosPlanos:Cosme,Lia`: «Llegas tarde, Cosme.» | — | — |
| 7 | **Decisión de Cosme** (el jugador le aconseja): traerla o dejarla descansar | — | — |

- **Vuelta al control:** se reanuda la batalla.
- **Motor:** ✅. 🆕 Postura «apoyarse en el bastón».

### S6 · La verdad del Coro
- **Dónde:** Siroco V, en la Biblioteca de Arena (combate de Luz Pozo y murales).
- **Duración:** 2 min 30 s.
- **Alcance:** Personal.
- **Intención:** el universo cambia de tamaño.

| # | Plano | Qué se ve | Sonido |
|---|---|---|---|
| 1 | `Fijo` hacia Luz, de rodillas; la voz de Ana suena en la sala | La voz canta una nana y se para | La nana en el ambiente |
| 2 | `PrimerPlano:Luz`: «¿Cómo me llamo, mamá?» `Pause { After = 3 }` | La voz no contesta | Silencio total ✅ |
| 3 | `Reaccion:Ilse`, `Beat = Pensar` | Ilse lo ha oído (semilla) | — |
| 4 | `Tilt` sobre el mural; `Light = Grieta` | Nueve estrellas, una tachada | Coro bajo (el tema de Oren entra por primera vez) |
| 5 | `Travelling` lateral por el friso | Refugiados ante puertas que se cierran, ocho figuras votando | Las voces suben |
| 6 | `Inserto`: el nombre grabado, «Ithar, rey de Oren, que no llegó a tiempo» | — | Una nota grave que no resuelve (tema de Ithar) |
| 7 | `DosPlanos:Jugador,Sorel`, `Beat = Respirar` | — | — |

- **Vuelta al control:** en la sala del Archivo, que se puede explorar (fragmentos del Registro de los Tejedores).
- **Motor:** ✅. 🆕 Mural animado (decorado con estados, §7.5).

### S7 · El encendido del sol de Nivalis
- **Dónde:** Nivalis V (el corazón del Sello).
- **Duración:** 2 min.
- **Alcance:** Personal, más World: todo el que esté en Nivalis ve amanecer.
- **Intención:** la luz como milagro. Contrasta con el encendido del Acto I (`Niv03`), que fue con la reserva.

| # | Plano | Qué se ve | Sonido |
|---|---|---|---|
| 1 | `PrimerPlano:Jugador` con las manos en el corazón del sol; `Light = Noche` | Oscuridad casi total | Las criaturas cantan (el tema de Madre Copo) |
| 2 | `Dolly` reverso desde el corazón | Una chispa azul que crece | El canto se ordena y deja de ser amenaza |
| 3 | `General` de la montaña desde la ciudad; `Fade` blanco breve | El sol se enciende azul y blanco, no amarillo como en el Acto I | La música pasa a `Tema` |
| 4 | `Travelling` por las calles de Fortaleza Albor | Las criaturas se deshacen en luz cantando; la gente se tapa los ojos | Coro y campanas |
| 5 | `Medio:Casimir` | Comprende lo que eran | Silencio para él solo ✅ |
| 6 | `Medio:Ambar`: decide sobre Casimir | — | — |

- **Vuelta al control:** con la luz del día en Nivalis (estado Liberado, Vol. IV).
- **Motor:** ✅, más `Sky` (amanecer). 🆕 Cambio de estado del planeta para todos (§7.6).

### S8 · El deterioro de Sorel
- **Dónde:** no es una sola escena: es una **secuencia en cuatro tiempos** a lo largo de la campaña. Cada tiempo es una
  escena corta.
- **Alcance:** Personal.
- **Intención:** que el jugador lo note antes de que nadie lo diga.

| Tiempo | Dónde | Plano clave | Detalle |
|---|---|---|---|
| T1 · El contacto | Nivalis V | `PrimerPlano:Sorel`, con la mano gris hasta la muñeca, en `Light = Sueno` | Saca a Tila de la oscuridad. Silencio. «No duele. Eso es lo raro.» |
| T2 · El chiste | Umbría II | `DosPlanos:Cosme,Sorel` | Cosme cuenta un chiste; `Reaccion:Sorel` sin reír; `Reaccion:Cosme` lo nota y calla |
| T3 · Las lágrimas | Tálasa V, tras la muerte de Kael | `PrimerPlano:Sorel` 4 s | No llora: «¿Por qué no lloro?» |
| T4 · Los parches | Vértice III | `Inserto` de su chaqueta con un parche arrancado; después `Medio:Sorel` | Llama al jugador por otro nombre. `Pause { After = 2 }`. «…Perdona.» |

- **Motor:** ✅. 🆕 Variante de animación «lenta» para Sorel desde Umbría (§7.1).

### S9 · El descubrimiento de Lys
- **Dónde:** Umbría V, después de Savia.
- **Duración:** 2 min 20 s.
- **Alcance:** Personal.
- **Intención:** asombro y ternura en medio de la guerra.

| # | Plano | Qué se ve | Sonido |
|---|---|---|---|
| 1 | `Travelling` bajando por las raíces del árbol madre | Raíces grises que se vuelven verdes | Gotas, flauta con eco (tema de Lys) |
| 2 | `General` de la cámara de la Semilla | Una semilla del tamaño de una casa que late | — |
| 3 | `Dolly:Lys` | Una muchacha de luz verde y hojas se forma | Silencio y respiración ✅ |
| 4 | `Medio:Lys`: «Hace mucho que nadie viene sin que le llame mi padre.» | — | — |
| 5 | **Recuerdo de Lys:** `Light = Recuerdo`, Oren intacto, Ithar joven: «Un día más, Lys. El Sello aguantará.» (aparición 5) | — | Un coro, claro por primera vez |
| 6 | `Hombro:Ilse>Lys`: «¿Los muertos están en el Coro?» / «Están. Pero no son.» | — | — |
| 7 | `Reaccion:Ilse` | Se queda solo con la primera mitad | — |

- **Vuelta al control:** en la cámara de la Semilla; Lys se queda como punto de conversación.
- **Motor:** ✅. 🆕 Actor de luz (material Neon con partículas, §7.4).

### S10 · La traición de Ilse
- **Dónde:** Tálasa IV.
- **Duración:** 1 min 50 s.
- **Alcance:** Personal.
- **Intención:** entender a la traidora mientras traiciona.

| # | Plano | Qué se ve | Sonido |
|---|---|---|---|
| 1 | `Medio`: Noa y su madre abrazadas en la enfermería, vistas por Ilse desde la puerta | — | Íntima |
| 2 | `PrimerPlano:Ilse`, `Beat = Apartar` | — | — |
| 3 | `Fijo`: el taller de noche; Ilse con el fragmento de la Lanza (peldaño 2) | — | El pulso, cada vez más claro |
| 4 | `PPP:Ilse` | — | Voz de Adrián: «Mamá, abre.» |
| 5 | `Seguir:Ilse` por los pasillos de la estación hasta el Nudo | — | Sus pasos; la estática se convierte en nana (su tema) |
| 6 | `Inserto`: su mano en la palanca. `Pause { Before = 3 }` | — | Silencio ✅ |
| 7 | `General` del Nudo; `Cut = "Flash"` | Se abre y el agua entra | Alarma e inundación ✅ |

- **Vuelta al control:** persecución por la estación inundándose.
- **Motor:** ✅. 🆕 Agua que sube en la escena (efecto de inundación, §7.5).

### S11 · La muerte de Kael
- **Dónde:** Tálasa V. **Hecho fijo.**
- **Duración:** 3 min.
- **Alcance:** Personal. En grupo, cada jugador la vive en su propia escena: no se comparte.
- **Intención:** el momento más importante del juego. La tercera puerta.

| # | Plano | Qué se ve | Sonido |
|---|---|---|---|
| 1 | `General` de la compuerta del Nudo cerrándose; el agua sube | El grupo al otro lado; la Marea detrás | Caos ✅ |
| 2 | `Seguir:Kael` corriendo hacia la compuerta | — | El cello entra solo |
| 3 | `Medio:Kael` sujetando la compuerta con el cuerpo | — | — |
| 4 | `Hombro:Kael>Jugador` | **Variante:** si el jugador intentó ocupar su sitio, Kael le empuja: «No dejarás a nadie atrás. Pero yo no soy nadie: soy tu comandante.» | — |
| 5 | `PrimerPlano:Kael`. Últimas palabras, 3 variantes por relación (Vol. II §4.1) | Variante si Irene la perdonó: «Dile a Irene que esta vez la sostuve.» | `Music = Nada` ✅ |
| 6 | `Reaccion:Brenn` | Brenn sujeta al jugador para que no vuelva | — |
| 7 | `Dolly` reverso desde la compuerta, lento, 6 s | Kael sigue sujetando mientras el grupo cruza | Solo agua |
| 8 | `Inserto`: la compuerta se cierra sin ella | — | Silencio total, 3 s ✅ |
| 9 | Aparición 6 de Ithar: la ceniza forma una mano abierta sobre la compuerta | «Me cerró una puerta hace veinte años. Hoy ha abierto una. Os envidio.» | El coro, muy bajo |
| 10 | `General` de la fosa: el Nudo se enciende azul | — | El cello resuelve por primera vez |

- **Vuelta al control:** el jugador sube a la superficie sin música. Brenn: «Ahora mando yo. Moveos.»
- **«Saltar»:** desactivado en esta escena la primera vez (excepción documentada); se puede saltar al repetirla.
- **Motor:** ✅. 🆕 Postura «sujetar compuerta» y anclaje del actor a un objeto (§7.1).

### S12 · El asalto a Vértice
- **Dónde:** Vértice IV.
- **Duración:** 1 min 30 s de apertura y después escenas A durante el asalto.
- **Alcance:** World (toda la Coalición asalta). La apertura es Personal.
- **Intención:** la flota de lo salvado: la escala galáctica.

| # | Plano | Qué se ve | Sonido |
|---|---|---|---|
| 1 | `Travelling` desde la órbita | Las naves de los mundos liberados, cada una con su color y su forma | El tema de cada planeta suena un compás, uno tras otro |
| 2 | `General` de Distrito Cero bajo su cúpula | Las pantallas, todas con la cara amable de ÁGORA | Música de ascensor que se distorsiona |
| 3 | `Medio:Brenn` en el puente: «Por Kael.» | — | — |
| 4 | `Órbita` de la torre MegaVerso con `Shake` | La cúpula se rompe | Combate ✅ |

- **Vuelta al control:** aterrizaje en la planta 60, inicio de la mazmorra 2.
- **Motor:** ✅. La flota depende de las decisiones (`Variants` por planetas liberados).

### S13 · El primer encuentro físico con Ithar
- **Dónde:** Vértice V, tras ÁGORA.
- **Duración:** 3 min 30 s.
- **Alcance:** Personal.
- **Intención:** un rey, no un monstruo.

| # | Plano | Qué se ve | Sonido |
|---|---|---|---|
| 1 | `General` de la Consola; la luz azul de la Torre parpadea | La ceniza se levanta del suelo y forma una figura alta | El coro sube despacio |
| 2 | `Tilt:Ithar` de los pies a la cara (su presentación) | Manto deshilachado, corona de hilos rotos, venas azules muy débiles | Una nota grave que no resuelve |
| 3 | `Medio:Ithar`: «Te oigo desde el Umbral. Siéntate. No he venido a pelear.» | — | — |
| 4 | `Hombro:Jugador>Ithar` y `Hombro:Ithar>Jugador`, alternos | La conversación: Ithar responde todo y nunca miente | Silencios largos ✅ |
| 5 | `PrimerPlano:Ithar`: «El Coro olvida. Lo sé. ¿Crees que no lo sé?» | Sus bordes se deshacen en ceniza al decirlo | — |
| 6 | `Reaccion:Sorel` | Sorel, medio gris, le mira | — |
| 7 | `Medio:Ithar` se toca la corona: «Mi hija te espera en Oren. Ella cree que tienes razón.» | — | — |
| 8 | `Dolly` reverso; Ithar se deshace | — | Silencio y la Consola abre el Hilo ✅ |

- **Vuelta al control:** ante el Hilo abierto hacia Oren.
- **Motor:** ✅. 🆕 Actor de ceniza (modelo con partículas y bordes que se deshacen, §7.4).

### S14 · La llegada a Oren
- **Dónde:** La puerta, parte 2.
- **Duración:** 2 min.
- **Alcance:** Group (el grupo de la misión) y Personal en solitario.
- **Intención:** asombro y duelo. Un mundo detenido en el último segundo.

| # | Plano | Qué se ve | Sonido |
|---|---|---|---|
| 1 | Cruce del Hilo: `Fx = portal`, `Cut = "Flash"` | — | Silencio total ✅ |
| 2 | `General` lento de 10 s | Ciudades de piedra viva grises, multitudes petrificadas corriendo hacia los Hilos | Ningún ambiente: el mundo no suena |
| 3 | `Travelling` entre las figuras | Una madre con un niño, de piedra gris, mirando hacia arriba | Ceniza que cae |
| 4 | `Inserto` de un Hilo apagado con forma de puerta | La línea vertical tejedora: «puerta» | — |
| 5 | `General`: al fondo, el Árbol Primero petrificado | — | El tema de Oren, por fin completo |
| 6 | `Medio:Cosme`: «Aquí no hay chiste que valga.» | — | — |

- **Vuelta al control:** mazmorra final.
- **Motor:** ✅. Decorados de Oren (Vol. IV, anexo de Oren, pendiente).

### S15 · Los tres finales
Los tres comparten apertura: la conversación final (Vol. III §6.1), con la cámara en planos de hombro alternos y Lys
siempre en el fondo del encuadre.

| Final | Secuencia | Planos clave | Sonido |
|---|---|---|---|
| **Cerrar el Telar** | El generador del Umbral sella los Hilos. Ithar y el Coro se apagan. | `PrimerPlano:Ithar`: «Lo mismo que ellos.» Después, `General` de los ocho cielos: los Hilos se apagan uno a uno, como las luces del Gran Corte (eco de S6). Sorel no reconoce al jugador: `DosPlanos` y `Reaccion:Jugador`. | El tema de Ithar resuelve en menor; silencio largo |
| **Liberar el Coro** (canónico) | Lys pide a su padre que se deje ir. Ithar suelta el Coro. | `DosPlanos:Ithar,Lys` (padre e hija, sin gris). `Travelling` por Oren mientras las figuras grises se vuelven luz. Montaje de despertares: Lía, los hijos de Corvo, Nilo y Sorel, si se cumplen las condiciones. Los ocho Sellos sostienen el borde: `General` del Telar. | Todos los temas de personaje en un solo coro; después, el piano de Valmar |
| **Ocupar su lugar** | Alguien se queda como Pastor: Ilse, Sorel o el jugador. | `PrimerPlano` del que se queda; la corona de hilos pasa a sus manos. Si es el jugador: plano subjetivo dentro del Coro y vuelta con una cicatriz. | El coro, pero con una melodía nueva |

**Epílogo común:**
- montaje de reconstrucción, un plano por planeta, cada uno con su música;
- último plano: la pared de nombres de la Academia (`Inserto`) y el nombre de Kael;
- **vuelve la ciudad de antes** (flag **UniversoRecuperado**).

---

## 7. Capacidades nuevas del motor (con auditoría previa obligatoria)

**Regla.** Antes de programar cada punto se lee el sistema afectado, se documenta qué se reutiliza y se añade la
capacidad **como campo opcional**: las escenas viejas siguen funcionando igual.

| # | Capacidad | Para qué | Sistema que se amplía | Coste |
|---|---|---|---|---|
| 7.1 | **Posturas y animaciones de personaje:** cruzar los brazos, brazos a la espalda, apretar la empuñadura, tocar el auricular, apoyarse en el bastón, tocarse la corona, sentarse, levantarse, arrodillarse, cubrirse, sujetar una compuerta; variante «lenta» para Sorel | Lenguaje corporal (directiva §7) | `Actors` / `Acting` (Sequencer y ActorLife). Animaciones R15 subidas por el dueño o de la biblioteca de Roblox. | Medio |
| 7.2 | **Corte a mitad de frase** (`Cut = true` en la línea, con un suceso) | Interrupciones reales | `Dialogue` (Sequencer y HappeningClient) | Bajo |
| 7.3 | **Temas musicales** por personaje y por planeta | Leitmotivs | `Music { Play = cue }` ya existe; hacen falta las pistas (biblioteca de Roblox con licencia, o subidas por el dueño) | Medio (audio) |
| 7.4 | **Actores especiales:** Velados con giro sincronizado, Lys (luz y hojas), Ithar de ceniza | Seres únicos | Modelos, más un `Mood` de grupo para el giro sincronizado | Alto (arte) |
| 7.5 | **Decorados con estados:** mural animado, agua que sube, compuerta que se cierra | Escenas de lugar | `StageSets` (decorados condicionales) | Medio |
| 7.6 | **Estado del planeta visible para todos:** Ocupado, Liberado o Pleno | La liberación se ve (directiva §9) | `WorldState`, `StageSets` y `EnvDirector`. Ver Vol. IV §0. | Medio-alto |
| 7.7 | **Vuelta al control mirando al objetivo** | La cinemática deja al jugador orientado | `CineCamera.restore` (un parámetro de dirección) | Bajo |
| 7.8 | **Escena sin «Saltar» la primera vez** (solo S11) | El momento central | `HappeningService` (un campo `NoSkipFirst`) | Bajo |

**Orden propuesto:** 7.2, 7.7 y 7.8 primero (bajo coste, mucho efecto); después 7.1 y 7.5; y 7.4, 7.3 y 7.6 con el
arte de cada planeta.
