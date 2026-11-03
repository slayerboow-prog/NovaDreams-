# Auditoría de textos y misiones (v132)

**Encargo de Sebastián:** «continúa arreglando textos, cinemáticas y misiones». Esta pasada se queda en
los TEXTOS y el FLUJO de las misiones. La cámara y los efectos son de otro agente (`Happenings/Direccion.luau`).

## Cómo se comprueba

Hay una prueba nueva: `lune run scripts/test-textos.luau`. Con `informe` lo lista todo y no falla.

Lee los textos de verdad del juego:
- las misiones, con los guiones reescritos encima;
- las escenas;
- los textos por clave (`Strings`);
- las tiendas y los capítulos;
- y todas las frases del código, para buscar lo prohibido.

Son unos 11 800 textos y 28 700 frases del código.

| Regla | Límite |
|---|---|
| Objetivo de un paso (la tarjeta del móvil) | **64** letras; en mayúscula y sin punto final |
| Pregunta de una decisión (paso `Choice`) | **120** letras: lleva su contexto |
| Frase de diálogo o de escena (bocadillo de 230 px a 17 pt) | **160** letras (unas 6 líneas) |
| Rótulo de transición | **140** letras |
| Nova, NovaLife, NovaDreams y NV-7 | prohibidos (la nave es la HX-7 Halcón) |
| Marcas reales y palabrotas | prohibidas (13+) |
| Ortografía | ~130 palabras que siempre llevan tilde o eñe, «¿» y «¡» de apertura, sin espacios dobles |
| Nombres | Un nombre del reparto con tilde no se escribe sin ella (Cósimo, Halcón, Tálasa…) |

El objetivo se mide como se ve en pantalla: `{count}/{total}` cuenta como «9/9» y `{o/a}` con la forma más larga.

## Lo que se ha arreglado

- **112 objetivos acortados** a 64 letras o menos. Siguen diciendo qué hacer y dónde.
  - Ejemplo de antes: «Haz un turno de técnico/a de presión (tablón junto al Faro): ajusta dos válvulas antes de que cambie la marea».
  - Ahora: «Ajusta 2 válvulas: tablón 🔧 de presión, junto al Faro».
  - Están en el prólogo y las misiones del cole, del instituto y de la universidad.
  - También en las misiones locas, el metro, el Mar y los siete planetas.
- **5 decisiones** con más de 120 letras, resumidas (Nivalis, Tálasa y Tefra).
- **22 frases de diálogo** de más de 160 letras, recortadas sin perder el chiste (sobre todo en las misiones locas y las secundarias de la uni).
- **3 rótulos** demasiado largos (`Rareza_Columpio`, `Rareza_Piso13` y `Saga_16_66B`).
- **Objetivos de los guiones en minúscula y con punto** («colocar los tres anclajes en Valmar.»).
  - La herramienta (`scripts/lib/Reescritura.luau`) ahora los pone siempre en mayúscula y sin punto final.
  - Se han regenerado los guiones.
- **Ortografía:**
  - «¡Ciao!», «¡Avanti!» y «¡Buonasera!» de Luca llevan ya su «¡».
  - El ladrido del perro de `Rareza_Perro` tenía espacios dobles.
- **Objetivos de la Saga 1 que no decían qué hacer o dónde:**
  - «Bigotes te espera en el tejado del cole… bueno, en el patio» → «Habla con Bigotes en el patio del cole».
  - «Ventanilla 1: Correos» → «Ventanilla 1: ve a Correos».
  - «Investiga el tercer cráter» → «Investiga el cráter del camino al cole».
  - «Entra en la oficina. La recepcionista sonríe» → «Habla con la recepcionista de la oficina de MegaVerso».
  - «Cosme se ha despertado…» → «Habla con Cosme en la puerta del garaje».
  - «Tus amigos están en la fiesta…» → «Habla con Omar en la fiesta de la plaza».
  - «Cosme ha venido a tu graduación…» → «Habla con Cosme en tu graduación (patio del instituto)».
  - «La Capitana Ñoz baja de la nave» → «Habla con la Capitana Ñoz junto a su nave, en el monte».
  - «Alguien con tu cara…» → «Habla con tu doble de perilla en el banco de la plaza».
  - «Cosme tiene la lista de aliados» → «Habla con Cosme en el garaje: tiene la lista de aliados».
  - «Abre la puerta» → «Llaman a tu puerta: ábrela».
- **`Saga_17_Rescate`, paso 1:** el guion lo había dejado en «llegar a la entrada del laboratorio.», pero el paso es una pelea.
  - Ahora dice «Desconecta a los guardias del laboratorio (n/m)».
- **`Saga_23_Fusion`:** los pasos 6 y 7 (con y sin los Restos de la Grieta) decían lo mismo.
  - El 6 ahora dice «¡Tus Restos de la Grieta frenan a Cósimo! Cóselo de vuelta».
- **Huecos del plan (`docs/cine/plan-historia-cine.md`), sin cambiar ningún número de paso:**
  - **De la infancia a la adolescencia** (`Saga_07`): Pip abre la misión con «Tres años sin un solo pitido del medidor. Hasta esta mañana.».
    - Está en `reescritura/Saga_07_Costuras.md`.
  - **Por qué viajas en la Saga 2** (`Varkun_02_Escarcha`, al final del prólogo):
    - Pip: «Señor, la Aguja de oro está temblando. Ha oído otro desgarro.»
    - Cosme: «La señal es de mi casa, criatura. De Tefra.»
    - Cosme: «Coge el casco. Esto acaba de empezar.»
    - Así el juego dice por qué Tefra va primero.

**Lo que ya estaba bien** (la prueba lo vigila a partir de ahora):
- Ningún «Nova» ni «NV-7».
- Ninguna marca real: «Mercedes» solo sale como el nombre de una abuela.
- Ninguna palabrota.
- Ningún resto en inglés en los textos que se ven.
- Ningún nombre escrito de dos maneras.

## Flujo de las misiones

- **El validador** (`Validate`, dentro de `test-lifestory`) da 0 errores. Comprueba:
  - que existan los sitios, los personajes, los objetos, los requisitos y las ofertas.
- **Avisos que quedan:** 13, todos del Mar.
  - En `Mar_00`–`Mar_04` y `Mar_S1`–`Mar_S2`, Ilun, Oriana, Bartolo, Maresa, Tome, Sargo y Lía no salen en la escena de su paso.
  - Se habla con ellos con el plan B, el NPC del sitio. No bloquea, pero sale en la caja de texto y no en un bocadillo.
  - Lo debería mirar quien monta las escenas del Mar.
- **Saga 1, paso a paso:** las 24 misiones y `Loco_N1` encadenan bien sus requisitos. Cada paso jugable tiene línea guía (personaje, objeto, sitio o enemigos), salvo tres:
  - `Saga_15`, paso 2: el minijuego del rodaje, que empieza solo.
  - `Saga_22`, paso 2: la decisión en casa.
  - `Saga_23`, paso 3: aguantar 25 s en la cima. Ya estás allí.
- **Después de morir o al volver a entrar:**
  - Los combates se reinician con `Respawn` o `Place`.
  - Las huidas te devuelven al sitio de salida.
  - El vigilante de atascos de `LifeStoryService.Watchdog`:
    - vuelve a montar los actores que faltan;
    - reenvía las decisiones;
    - da por hecho un paso cuyo sitio o enemigo no existe.
  - `test-mision-visible` ya prueba los pasos insertados en partidas viejas.
  - No se ha visto ningún paso imposible.
- **Minijuegos sin texto** (10 pasos `MiniGame` de los planetas, `Cole07` y `Tefra`): el HUD pone «Juega el minijuego» y el minijuego tiene su título. Se han dejado así.

## Lo que queda (y por qué)

| Pendiente | Por qué no se ha hecho |
|---|---|
| Escena de Cósimo en las pantallas antes de `Saga_18` | Necesita un paso nuevo al principio: cambia los números de paso y hace falta migrar las partidas |
| «Ya te he visto, Ancla» al final de `Grieta_Coser` | Es dirección de cámara (otro agente) |
| Partir `Varkun1_G1_Fin` en dos escenas | Lo mismo: cámara, y faltan las anclas de la nave |
| Los 13 avisos del Mar (personajes con plan B) | Es montaje de escena, no texto. Se juega igual |
| Frases de 140 a 160 letras (unas 100) | Caben en 6 líneas. Si en el móvil se ven largas, se baja `Limits.Line` en la prueba y se recortan |
| Ortografía fina (acentos diacríticos: «tu/tú», «el/él», «solo», «mas/más») | No se puede decidir con una lista: hay que leerlo frase a frase |
