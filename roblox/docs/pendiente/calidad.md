# Traspaso: ventana de publicación y candado de `publish.sh`

## Qué pidió el dueño en esta ventana
1. Publicar el juego en Roblox (compilar, construir y subir).
2. Guardar en GitHub el `RealLifeSimulator.rbxl` regenerado.
3. Ver cómo iba el metro y el resto del trabajo.
4. Publicar la continuidad de la historia de Cosme.
5. Unir la rama `claude/hud-touchlayout-alternativa` (botones 👊 y 🛡 en el móvil).
6. Evitar que tantas ventanas publicando a la vez estropeen el juego → poner un candado en `publish.sh`.

## Qué se hizo
- **Versión 56 publicada** (commit `1fe8b04`) y su `.rbxl` subido en `2243246`.
- Instalados `lune` 0.10.5 y `rojo` 7.7.0 con `cargo install` (no venían en el contenedor).
- Metro revisado: todo el trabajo del metro ya estaba en la versión 56.
- Historia de Cosme: otra ventana ya la había publicado como **versión 57** (`6fbb916`). Se reconstruyó
  y salió idéntico, así que no se volvió a publicar.
- Rama `claude/hud-touchlayout-alternativa`: **no se unió**. Es una solución alternativa al mismo problema
  que la rama principal ya arregló a su manera (`TouchLayout` propio, HUD nuevo, e7dd4d4/7ddb064/7de0bad).
  La unión chocaba en los 8 archivos que toca; se abortó. Recomendación: dejarla sin unir y arreglar
  cualquier fallo de botones sobre el HUD actual.
- **Candado en `scripts/publish.sh`** (commit `dc8142c`), terminado y probado:
  - Solo publica desde `claude/roblox-game-d98vy8` (cambiable con `PUBLISH_BRANCH`).
  - Se niega con cambios sin guardar (el `.rbxl` no cuenta).
  - `upToDate()`: se niega si HEAD ≠ `origin/<rama>` y dice si falta `pull`, falta `push` o las ramas se separaron.
  - Compila (`test-compile`), construye (`rojo build` + `build-place`) él mismo y vuelve a llamar a
    `upToDate()` justo antes del `curl` a Open Cloud.
  - Probado en una copia aparte con `curl` falso: al día → publica; atrasado, adelantado, separadas,
    otra rama y cambios sin guardar → bloquea.
  - Documentado en `roblox/README.md`, sección "Publicar en Roblox".

## Qué quedó a medias
Nada. El candado está terminado, probado y subido.

## Qué falta
- Que las demás ventanas traigan lo último (`git pull`) para usar el `publish.sh` con candado. Quien
  publique a mano con `curl` se lo salta.
- Decidir que publique una sola ventana (recomendado).
- Cerrar o borrar la rama `claude/hud-touchlayout-alternativa` para que nadie la una por error.
- Comprobar en el móvil que 👊 y 🛡 se ven bien en la versión publicada; si no, arreglarlo sobre el HUD actual.
