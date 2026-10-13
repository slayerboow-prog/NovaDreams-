# Cambio de nombre: «Heroes of History»

Decisión del dueño (2026-10-13): el juego pasa a llamarse **Heroes of History**.

- **Saga 1** (la historia de ahora, en la isla de Valmar): **«History of Valmar»**.
- **Saga 2** (futura): tendrá su propio subtítulo. Todavía no hay contenido.
- El lema antiguo, **«Tu vida, tu historia»**, se guarda en `Config.GameMotto` por si se quiere usar
  como línea secundaria (por ahora no se ve en ninguna pantalla).

## Qué se ha cambiado en el código

| Dónde | Antes | Ahora |
|---|---|---|
| `src/shared/Config.luau` → `Config.GameName` | Real Life Simulator | Heroes of History |
| `src/shared/Config.luau` → `Config.SagaName` (nuevo) | — | History of Valmar |
| `src/shared/MapScreen.luau` → `Title` (logo del mapa grande) | REAL LIFE SIMULATOR | HEROES OF HISTORY |
| `src/shared/MapScreen.luau` → `Tagline` (debajo del título) | Tu vida, tu historia | History of Valmar |
| `src/shared/MapScreen.luau` → `Badge` (cuadradito del logo, lo pinta `MapUI`) | RL | HH |
| `src/server/Main.server.luau` (mensaje de la consola al arrancar) | [Real Life Simulator] Servidor listo | [Heroes of History] Servidor listo |
| Descripciones de los assets que suben `scripts/upload-*.sh` | … de Real Life Simulator | … de Heroes of History |

## Qué NO se cambia (a propósito)

- `Config.DataStoreName = "RealLifeSim_PlayerData_v1"`: es donde están guardadas las partidas. Cambiarlo
  dejaría a todos los jugadores sin su partida.
- El nombre del proyecto de Rojo (`default.project.json` → `"name": "RealLifeSimulator"`) y el archivo
  `RealLifeSimulator.rbxl`: los usan los scripts de compilación, pruebas y publicación. El jugador no los ve.
- Los ids del universo (`10767975237`) y del lugar (`113359543879512`) en `scripts/publish.sh` y los demás
  scripts: son la misma experiencia, solo cambia cómo se llama.
- Nombres de scripts, atributos y claves internas.

## Lo que tiene que hacer el dueño en el Creator Dashboard

El nombre y la descripción que se ven en la página del juego en Roblox (buscador, portada, «Jugar»)
**no están en el código**: se cambian a mano.

1. Entra en <https://create.roblox.com/dashboard/creations> y abre la experiencia (universo `10767975237`).
2. **Configure → Basic Info** (o «Información básica»):
   - **Name / Nombre:** `Heroes of History`
   - **Description / Descripción:** por ejemplo
     «Heroes of History · Saga 1: History of Valmar. Tu vida, tu historia: crece en la isla de Valmar…»
3. Si quieres, cambia también el nombre del **lugar de inicio** (Places → el lugar `113359543879512` → nombre).
4. Revisa los textos de las **insignias** y **pases** en el Dashboard (Monetization / Engagement →
   Badges / Passes): sus nombres y descripciones se editan allí, no en el código.
5. Guarda. Roblox puede tardar unos minutos en mostrar el nombre nuevo.

### ¿Se puede hacer con Open Cloud?

Hoy **ningún script de `scripts/` cambia el nombre** de la experiencia: los `upload-*.sh` solo *leen*
el universo (`GET /cloud/v2/universes/{id}`) para saber quién es el dueño, y `publish.sh` solo sube el
archivo `.rbxl`. Open Cloud tiene `PATCH /cloud/v2/universes/{id}` (con `displayName` y `description`
y el permiso `universe:write` en la clave), pero **no se ha añadido ni ejecutado**: cambiar el nombre
público es decisión del dueño y lo más sencillo es hacerlo en el Dashboard.

Cuando se cambie, el permiso de la clave para las pruebas en la nube (ver `docs/pruebas-en-roblox.md`)
seguirá funcionando: va por el id del universo, no por su nombre.
