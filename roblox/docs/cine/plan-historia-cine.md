# Plan de historia y cinemáticas (v130)

**Encargo del dueño:** centrarse en la historia y las cinemáticas, «con las skills». Su veredicto sobre la
Cinemateca fue: «la mayoría tiene fallos… súper sosas». Todavía no hay revisiones guardadas
(`docs/cine/revisiones-dueno.md`).

**Skills aplicadas:**
- **roblox-camera:** cámara Scriptable, sin cenitales y sin atravesar nada.
- **roblox-animation-vfx:** cada golpe en fases (aviso, contacto, pico y fundido), y el temblor solo en los golpes.
- **roblox-npc-ai:** los actores en su marca y mirando a quien habla.
- **roblox-player-psychology:** gancho en el primer minuto y un misterio abierto (efecto Zeigarnik).
- **roblox-lighting:** capas de luz por escena, como mucho 2 o 3 efectos y una luz de relleno de noche.

## 1 · El arco tal y como está

### Saga 1 · «History of Valmar» (Saga de la Grieta, 24 misiones, 4 actos)

- **Prólogo · El sueño** (`Prologo_Sueno`). La noche antes de nacer sueñas con Valmar, con la Grieta y con
  Cosme. Te llevas un tornillo.
- **Nacimiento** (`Bebe_NacimientoCuna`). Después, los tutoriales de bebé: primeros pasos con Abu, explorar
  la casa y salir.
- **Acto I · Infancia: «La Grieta»** (misiones 1–6).
  - El microondas temporal de Cosme abre la Grieta (`Loco_N1_Cosme`).
  - Caen tres estrellas (`Saga_02`, `Grieta_Caen`).
  - Aparecen el Consorcio, la Aduana del Tiempo y las cosas perdidas.
  - Al final se cose el cielo (`Saga_06`, `Grieta_Coser`) y se oye una voz: «Ya te he visto, Ancla».
- **Acto II · Adolescencia: «Los Visitantes»** (7–12).
  - La Grieta vuelve a abrirse y entra MegaVerso S.A.
  - El archivo de Pip te cuenta que eres el Ancla.
  - Cronos cambia de bando.
  - En la graduación se rompe el cielo y Cósimo se lleva a Cosme (`Saga_12`, `Grieta_Rota`).
- **Acto III · Universidad: «El Multiverso»** (13–18).
  - Sin Cosme: Gatonia, el reality y la dimensión 66-B.
  - Rescatas a Cosme, pero sin memoria.
  - Cósimo anuncia la Gran Fusión en todas las pantallas (`Saga_18`).
- **Acto IV · Vida adulta: «La Gran Fusión»** (19–24).
  - Los recuerdos de Cosme y los aliados.
  - La caída del Consorcio y el trato del Ancla.
  - La batalla en el monte (`Grieta_Fusion`).
  - El cielo cosido de verdad (`Grieta_Final`).

### Saga 2 · «Ragnarock» (siete planetas, episodios sueltos, 13+)

- **Se abre** al terminar la Saga 1.
- **Prólogo:** «La costura negra» (`Varkun_01_Costura`), a bordo de la nave.
- **Episodio 1, Tefra** (`Tefra_01_Caida`, `Tefra_Llegada`): Cosme vuelve a su planeta en guerra.
- **Ya hechos:** Miasma, Siroco, Nivalis, Umbría y el mar (Nácara, «La canción de lo hondo»).
- **En curso:** Tálasa.

## 2 · Las escenas clave (primeros 30 minutos y finales de capítulo)

| # | Escena | Cuándo | Por qué es sosa hoy | Estado |
|---|---|---|---|---|
| 1 | `Prologo_G1` · el sueño | Minuto 0: lo primero que ve un jugador nuevo | 10 s de vuelos sin nada; 8 fundidos a negro; los mismos dos planos aéreos repetidos tres veces | ✅ dirigida (v130) |
| 2 | `Prologo_G9` · fin del sueño | Minuto ~5 | Otra vez los mismos vuelos; los rótulos al final, todos seguidos | ✅ dirigida (v130) |
| 3 | `Bebe_NacimientoCuna` · nacimiento | Minuto ~6 | 3 planos de cámara (el resto, planos por frase); 9,6 s hasta la primera frase | ⏳ siguiente tanda |
| 4 | `Bebe_PrimerosPasosAbu` | Minuto ~10 | Bien cubierta (30 planos), pero dura 80 s: le sobran 20 | ⏳ recorte |
| 5 | `Cole01_Bienvenida` | Minuto ~20 | Buena cobertura; sin luz ni efectos, y el aula sin ambiente | ⏳ luz y ambiente (los pone el director automático) |
| 6 | `Loco_N1` · se abre la Grieta | Primera misión de la saga | **No existía**: el momento en que empieza la saga era un destello del cielo mientras Cosme hablaba | ✅ escena nueva `Loco_N1_Grieta` |
| 7 | `Grieta_Caen` · las estrellas | Saga 2 (misión) | Ya dirigida en la fase 5 (10 pasos, silencio, cráteres) | ✅ (revisar en la Cinemateca) |
| 8 | `Grieta_Coser` · final del Acto I | Clímax | Correcta; la voz «Ya te he visto» va en otra escena hablada | ⏳ propuesta abajo |
| 9 | `Grieta_Rota` · final del Acto II | Clímax | Dirigida (planos por frase, cielo, portal) | ✅ (revisar) |
| 10 | `Saga_18` · el anuncio de Cósimo | Final del Acto III | **Solo diálogo**: «Cósimo en todas las pantallas» no se ve | ⏳ propuesta abajo |
| 11 | `Grieta_Fusion` · la Gran Fusión | Clímax del Acto IV | 6 planos de cámara; la batalla va en pasos de lucha | ⏳ siguiente tanda |
| 12 | `Grieta_Final` · el cielo cosido | Final de la Saga 1 | Correcta | ✅ (revisar) |
| 13 | `Tefra_Llegada` · Saga 2, episodio 1 | Primer minuto de la Saga 2 | 3,4 s de plano quieto con el rótulo encima; la explosión llega a los 10 s | ✅ dirigida (v130) |
| 14 | `Varkun1_G1_Fin` · prólogo de la Saga 2 | Saga 2 | Escena ligera de 50 s sin cámara (en la nave) | ⏳ propuesta abajo |

**Ya hecho antes (v125.6):**
- Atardecer con Abu, fotos de grupo, la nave del monte y la graduación.
- El director automático: luz de la hora, ambiente, planos que respiran y reacciones.
- Las reglas de cámara: tope de 35°, distancia mínima y rótulo en la banda.

### Cómo se dirigen (Happenings/Direccion.luau)

Las escenas dirigidas a mano van en un grupo propio, el último de `HappeningIndex`. Con la misma id,
sustituyen a la del guion generado o a la de otro grupo. Así:
- el guion se puede volver a generar sin perder la dirección;
- las misiones y las partidas guardadas no cambian.

**Plantilla de cada una:**
- **Gancho en el primer segundo:** un sonido fuerte, un temblor corto y un plano subjetivo.
- **Situación con el rótulo:** siempre en un plano sin caras de cerca.
- **Variedad de planos:** situación, hombro, primer plano, inserto y reacción.
- **Movimientos:** órbita, dolly y acercamiento; cámara en mano solo en los golpes.
- **Cortes:** en seco en la acción; el fundido solo al final.
- **Reacciones:** se aguantan 2,4–3 s.
- **Luz y sonido:** una capa de luz por escena y la música por intensidad (tensión y luego calma).

## 3 · Huecos de la historia

| Hueco | Qué pasa | Arreglo | Estado |
|---|---|---|---|
| La saga empieza sin verse | En `Loco_N1` la Grieta se abría en un efecto de fondo durante el diálogo | Escena `Loco_N1_Grieta` al terminar la misión: el chasquido, el cielo se raja y Cosme dice «Eso… antes no estaba ahí. A casa, criatura. Y ni una palabra». Deja el misterio abierto para la misión 2 | ✅ hecho |
| El primer segundo del juego | El prólogo empezaba con 10 s de vuelo mudo | La primera frase llega al primer segundo: «Esa luz no debería estar ahí.» | ✅ hecho |
| Acto III → Acto IV | El anuncio de Cósimo («la Gran Fusión») solo se lee | Escena corta antes del diálogo de `Saga_18`: pantallas del barrio que se encienden una a una, Cósimo en primer plano y Cosme que no le reconoce. Necesita un paso de cine nuevo al principio de la misión (cambia los números de paso: se hace con migración de partidas) | 📝 propuesta |
| El salto de infancia a adolescencia (`Saga_06` → `Saga_07`) | Pasan años sin un puente; Cosme lo resuelve con «Ya no eres tan criatura» | Una frase de Pip al empezar: «Tres años sin un solo pitido del medidor. Hasta esta mañana.» En el guion fuente (`docs/historia/reescritura/Saga_07_Costuras.md`) | 📝 propuesta |
| «Ya te he visto, Ancla» (final del Acto I) | Va en una escena hablada después de `Grieta_Coser` | Pasarla al final de `Grieta_Coser`: la cámara sube a la costura, un destello y la voz sobre el negro | 📝 propuesta |
| Prólogo de la Saga 2 | `Varkun1_G1_Fin` dura 50 s sin cámara | Dividirla en dos escenas cortas con planos de la nave (necesita las anclas de la nave en el mapa de la auditoría) | 📝 propuesta |
| Motivación en la Saga 2 | Por qué viajas: está en el documento, pero el juego no lo dice en el primer minuto | La primera frase de Cosme en `Tefra_Llegada` ya lo enfoca en Cosme. Falta una línea en el prólogo: «La señal es de mi casa, criatura.» | 📝 propuesta |

**Reglas que se mantienen:**
- 13+ y sin sangre.
- Nunca las palabras Nova ni NovaLife.
- Cosme es original y no se toca su aspecto: los personajes de bloques llegan con el agente de personajes.

## 4 · Comprobaciones para el móvil

- **Rótulos:** sobre la banda oscura, en el tercio de abajo. En las escenas de aquí, solo en planos de
  situación o sin caras.
- **Cámara:** nunca más de 35° sobre una cara (CameraShots.sane); la auditoría falla por encima de 45°.
- **Sin atravesar nada** (test-cineplanos sobre el mapa construido, con los planetas y Nácara).
- **Pruebas:** test-cineplanos, test-cinematic, test-scenes y test-cinemateca en verde.

## 5 · Guion gráfico para revisar

Tres de las escenas dirigidas (el prólogo, la Grieta del garaje y Tefra), con la vista de cámara de cada
plano sobre el mapa construido. Se generan con `scripts/audit/cine-vista.luau`. Las imágenes van en la
carpeta que se diga en el informe; no se suben al repositorio.
