# 09 — Textos y traducción (español → inglés)

El juego se lanza en **español e inglés** (decisión D1 del [diseño](../diseno/README.md)). Para que traducir sea
fácil y barato, todos los textos de esta carpeta siguen estas reglas desde el primer día.

## 9.1 Reglas de escritura

| # | Regla | Mal | Bien |
|---|---|---|---|
| 1 | **Cada texto tiene una clave.** El código nunca lleva frases escritas | `"¡Hola!"` en el código | `DLG.NICO.PARQUE.01` |
| 2 | **Frases completas, nunca trozos pegados.** El orden de las palabras cambia entre idiomas | `"Has ganado " .. n .. " dólares"` | `UI.PAGA.GANADO` = "Has ganado {dinero}." |
| 3 | **Variables con nombre**, no con número | `%s llega a %s` | `{nombre} llega a {zona}` |
| 4 | **Sin adjetivos con género referidos al jugador** cuando se pueda evitar | "¡Qué cansado estás!" | "¡Menudo día llevas!" |
| 5 | Si no se puede evitar el género, **dos versiones** con sufijo `_F` y `_M`. El juego elige según la forma que el jugador escogió para su personaje | "¡Campeón!" | `…_M` "¡Campeón!" / `…_F` "¡Campeona!" |
| 6 | **Plurales en claves separadas** | "Tienes {n} amigo(s)" | `…_UNO` "Tienes 1 amigo" / `…_VARIOS` "Tienes {n} amigos" |
| 7 | **Números, dinero y fechas los formatea el código** (`Format.luau`), no el texto | "$1,500" escrito a mano | `{dinero}` → "$1.500" en español, "$1,500" en inglés |
| 8 | **Frases cortas**: máximo 2 líneas por globo (unos 90 caracteres). El inglés suele ocupar menos que el español, pero la interfaz debe dejar un 30% de margen por si acaso | — | — |
| 9 | **Juegos de palabras y refranes**: se marcan en el contexto para que el traductor los adapte (no los traduzca literalmente) | — | Contexto: "Refrán mal dicho a propósito (humor del comisario)" |
| 10 | **Nada de texto dentro de imágenes** (carteles, logos): los carteles del mundo usan `TextLabel` con clave, o son nombres propios | Cartel pintado "PANADERÍA" | Cartel con clave `PLACE.PANADERIA` |

Los textos que escriben los **jugadores** (nombres, mensajes, carteles de negocios, artículos) no se traducen: se filtran
con `TextService` como exige Roblox ([Fase 12.7](../diseno/12-multijugador-social.md)).

## 9.2 Prefijos de las claves

| Prefijo | Para qué | Ejemplo |
|---|---|---|
| `DLG.` | Diálogos de NPC | `DLG.ERNESTO.TURNO1.02` |
| `TUTO.` | Globos e instrucciones del tutorial que no dice un NPC | `TUTO.CONTROLES.MOVER_MOVIL` |
| `QUEST.` | Títulos y pasos de misiones | `QUEST.NINO_BICI.TITLE` |
| `ACH.` | Logros (nombre y descripción) | `ACH.VIDA_EMPIEZA.NAME`, `ACH.VIDA_EMPIEZA.DESC` |
| `EVT.` | Eventos y festivales | `EVT.CARNAVAL.TITLE` |
| `NEWS.` | Titulares de Radio Valmar en la app | `NEWS.INCENDIO.RESUELTO` |
| `PLACE.` | Nombres de lugares y carteles | `PLACE.CAFETERIA_CENTRAL` |
| `CAREER.` | Profesiones y rangos (con `_F` / `_M`) | `CAREER.BOMBERO.RANK1_F` |
| `UI.` | Interfaz (botones, apps, avisos) | `UI.PHONE.APP_BANCO` |
| `LEGACY.` | Libro de Valmar y sobrenombres | `LEGACY.EPITHET.PROF_ZONA_F` |

Los sobrenombres del Libro de Valmar ([07](07-progresion-logros-legado.md)) se hacen con **plantillas completas**, no
pegando palabras: `LEGACY.EPITHET.PROF_ZONA_F` = "La {profesion} de {zona}" → "The {profesion} of {zona}".

## 9.3 Glosario: qué se traduce y qué no

**Nombres propios de lugares y personas: se mantienen** (dan personalidad mediterránea al juego).
Las palabras que describen el lugar **sí** se traducen.

| Español | Inglés propuesto | Nota |
|---|---|---|
| Valmar, San Roque, Los Pinos, Villaverde, Playa Dorada | *igual* | Nombres propios |
| Valmar Centro / Valmar Norte | Valmar Centro / Valmar Norte | Se mantienen como nombres de zona |
| Campus Valmar | Valmar Campus | |
| Distrito Financiero | Financial District | Es descriptivo |
| Cafetería Central | Central Café | |
| Mercado de San Roque | San Roque Market | |
| Faro de la Punta | Point Lighthouse | |
| Libro de Valmar | Book of Valmar | |
| Radio Valmar | Radio Valmar | |
| Recuerdos (Álbum) | Memories (Album) | |
| Estrellas de Valmar | Valmar Stars | Moneda cosmética gratuita |
| Puntos de Legado | Legacy Points | |
| Proyectos de Ciudad | City Projects | |
| Abu Rosa / Abu Tomás | Grandma Rosa / Grandpa Tomás | "Abu" es cariñoso; en inglés se usa el equivalente familiar |
| Don Ernesto | Mr. Ernesto | "Don" no existe en inglés |
| Dólar de Valmar ($) | Valmar Dollar ($) | |
| Día redondo | Perfect Day | |
| Pasar el testigo | Pass the Torch | |
| Valmar CF / "los Marineros" | Valmar FC / "the Sailors" | |
| Deportivo Universitario / "los Búhos" | University FC / "the Owls" | |
| "criatura" (apodo de Don Ernesto y Bernardo) | "kiddo" | Cariñoso, no literal |

## 9.4 La tabla lista para Roblox

- **Archivo:** [`textos/dialogos.csv`](textos/dialogos.csv) — todos los diálogos del [documento 08](08-dialogos.md)
  (**212 textos**), con las columnas `Key`, `Source` (español), `Context` (quién lo dice y en qué escena), `Example`
  (ejemplo de las variables) y `en` (vacía, para rellenar con el inglés).
- **Cómo se genera:** el script [`textos/generar_csv.py`](textos/generar_csv.py) lee el documento 08 y crea el CSV.
  Si se cambia o añade un diálogo en el documento 08, se vuelve a ejecutar el script y la tabla se actualiza sola
  (también avisa si hay claves repetidas).
- **Cómo se usa en Roblox:** el CSV se sube como tabla de localización de la experiencia (idioma de origen: español)
  desde la sección de localización del panel de creador o con las herramientas de localización de Studio. En el código,
  cada texto se pide por su clave con el `Translator` de `LocalizationService`, por ejemplo:

```lua
-- Cliente: muestra el saludo de Abu en el idioma del jugador
local text = translator:FormatByKey("DLG.ABU.NACER.01", { nombre = playerName })
```

> Nota para quien no programa: no hace falta tocar nada de esto ahora. Cuando llegue el momento de meter los diálogos
> en el juego (hitos M2–M3), el programador usará esta tabla tal cual. Para traducir al inglés basta con rellenar
> la columna `en` del CSV (por ejemplo, abriéndolo con Excel o Google Sheets).
