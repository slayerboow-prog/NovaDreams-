# Saga 1 «History of Valmar» · Tono 13+ (Moderado)

Decisión del dueño (2026-10-13): **toda la experiencia pasa a ser 13+ «Moderado»** (la Saga 1 y la
Saga 2 «Ragnarock» están en la misma experiencia de Roblox, y la etiqueta es de toda la experiencia).

En la Saga 1 **solo cambian los diálogos y el tono**. La historia, las misiones, sus pasos, sus
identificadores, las escenas y los personajes son **los mismos**. Nada de lo jugable se ha tocado.

---

## 1 · Reglas del tono de la Saga 1

De todo lo que permite «Moderado», el dueño ha elegido **solo «Peleas y violencia»**.

### Qué SÍ

- **Peleas, disparos y explosiones** en lo que se dice y en los textos de los combates: drones que
  abren fuego, disparos aturdidores, golpes que te tiran al suelo, comunicadores que revientan en chispas.
- **Peligro de verdad**: la Grieta y los villanos (Cósimo, los agentes grises, el Consorcio MegaVerso)
  se describen como una amenaza real, no como una broma.
- **Personajes que se defienden**: el jugador y sus amigos plantan cara, se cubren las espaldas y
  hablan del combate y de que pueden salir malparados.
- **El humor se queda** (Pip, Cosme, Don Escamas, los agentes que hablan como vendedores), pero las
  amenazas se toman en serio.

### Qué NO (nunca)

- **Sangre, heridas, trozos de cuerpo** o mutilaciones. Un golpe te tumba, te deja sin aire o te
  lanza lejos; nada más.
- **Muertes**: en la Saga 1 no muere nadie. Los enemigos se rinden, se apagan, explotan si son
  máquinas o se van. (La Saga 2 tiene sus propias reglas: ver `saga-2-siete-planetas.md`, apartado 0.)
- **Palabrotas ni insultos nuevos**. No se ha añadido ninguno.
- **Temas serios nuevos** (muerte, duelo, pérdida) ni **sustos de terror** que no estuvieran ya.
- Nada de marcas reales ni de nombres prohibidos del proyecto.

### Cómo se escribe

- **Misma longitud** aproximada que la frase de antes: los bocadillos tienen que caber en el móvil.
- **Mismos hechos**: quién está dónde, qué se sabe en cada momento (Cósimo, el Ancla, la 66-B, Nilda,
  el colegio, la casa…). Si una frase cambia, el dato que da sigue siendo el mismo.
- **Verbos de acción**: pelear, disparar, golpear, embestir, derribar, abrirse paso, explotar.
- Si dudas, la opción más suave.

---

## 2 · Qué se ha cambiado

Los guiones de la Saga de la Grieta se escriben en `docs/historia/reescritura/<Id>.md` y se convierten
con `lune run scripts/audit/aplicar-reescritura.luau <Id>` en `src/shared/LifeStory/Guiones/<Id>.luau`.
Se han cambiado los `.md` y se han vuelto a generar sus guiones e informes.

| Zona | Archivos | Qué cambia |
|---|---|---|
| Prólogo | `Prologo_Sueno` | La Grieta «no deja de crecer»; «habrá días en los que tendrás que pelear». |
| Acto I (infancia) | `Saga_02` a `Saga_07` | Amenazas más claras (cobradores armados, agentes que vigilan, «no te enfrentes a él: corre»). Pip y el jugador plantan cara a los agentes. |
| Acto II (instituto) | `Saga_09` a `Saga_12` | «Si la costura se rompe, Valmar se rompe con ella». En la graduación, Cósimo manda a los drones a separaros y Nico se pone delante. |
| Acto III (universidad) | `Saga_14` a `Saga_17` | Las defensas de Cósimo «no avisan antes de atacar»; en la huida del laboratorio las puertas se cierran. |
| Acto IV (adulto) | `Saga_19` a `Saga_23` | «Esto va a ser una pelea»; Cósimo ordena a los drones abrir fuego en la Gran Fusión. |
| Combates y huidas | `Misiones/Saga_Acto1..4.luau` | Los textos de los pasos `Fight`, `Escape` (objetivo y `CaughtLine`) y algunas descripciones: golpes, derribos, disparos aturdidores, explosiones. **Sin cambiar** tipos, sitios, vida (HP), enemigos ni acciones. |
| Escenas del cielo | `Happenings/Cielo.luau` | Una frase de Cosme en la Gran Fusión («con perilla y drones»), con la misma duración. |
| Rótulo del prólogo | `Strings.luau` (`CINE.PROLOGO.S_SAGA`) | «Busca el ❗ dorado en el mapa: ahí te espera el peligro.» |
| Exportador de diálogos | `scripts/audit/exportar-dialogos.luau` | El texto de ayuda dice ahora 13+ «Moderado» en vez de «para todos los públicos». |

### Limpieza de paso

Al revisar los guiones salían en voz alta **notas de dirección** que el importador había leído como
frases (por ejemplo «Añadir:», «Otro NPC señala:», «Dos agentes aparecen.», «Está completamente
pálido.»). Se han puesto entre paréntesis en el `.md` (así el importador las trata como acotación) y ya
no se dicen. En `Saga_17_Rescate` la pregunta «¿Por qué no me dejaste en paz?» estaba atribuida a
Cósimo; ahora la dice el jugador, como pedía el guion.

### Lo que NO se ha tocado

- Misiones, pasos, identificadores, recompensas, marcas, memorias y el orden de la historia.
- El sistema de voces (`Speech.luau`, `CastVoices.luau`): las voces se generan a partir del texto en el
  momento, así que no hay ninguna lista de frases que actualizar.
- Las historias de la vida diaria (colegio, instituto, pandilla, universidad, adulto): no tienen combates
  y ya tenían un tono adecuado.

---

## 3 · Lo que tiene que hacer el dueño

Rellenar el **cuestionario de madurez** de la experiencia en el Creator Dashboard para que quede en
**13+ «Moderado»**. Los pasos están en [`../cambio-de-nombre.md`](../cambio-de-nombre.md#clasificación-de-madurez-13-moderado).
