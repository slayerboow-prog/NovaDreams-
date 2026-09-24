# Música de la historia

Música **original**, compuesta por código (`scripts/audio/compose.py`). Es nuestra: se puede subir a Roblox sin
problemas de derechos.

| Archivo | Cuándo suena | En Config.Audio |
|---|---|---|
| `nacimiento.ogg` | El nacimiento y, bajito, mientras eres bebé en casa (nana de caja de música) | `Music.Nacimiento` |
| `tema_valmar.ogg` | Mirar la ciudad por el ventanal, de fondo de niño, final del capítulo adulto (tema principal) | `Music.TemaValmar` |
| `pasan_los_anos.ogg` | "Han pasado varios años…" y el salto de niño a adulto | `Music.PasanLosAnos` |
| `vida_adulta.ogg` | Llegada a Valmar de adulto | `Music.VidaAdulta` |
| `sting_momento.ogg` | Cada momento de vida ("Ya tienes un hogar en Valmar") | `Stings.Momento` |
| `sting_capitulo.ogg` | Empieza un capítulo | `Stings.Capitulo` |
| `sting_primeros_pasos.ogg` | ¡Primeros pasos! | `Stings.PrimerosPasos` |

## Cómo ponerla en el juego (una sola vez)

1. Abre el juego en Roblox Studio.
2. **Ventana (Window) → Asset Manager** → botón **Bulk Import** (importar varios) y elige los 7 archivos `.ogg` de
   esta carpeta. También se puede en create.roblox.com → *Creations* → *Development Items* → *Audio* → *Upload Asset*.
   (Roblox puede pedir verificar la cuenta o limitar cuántos audios subes al mes: es normal.)
3. Cuando estén subidos, en el Asset Manager haz clic derecho en cada audio → **Copy ID**.
4. Pega cada ID en `src/shared/Config.luau`, sección `Config.Audio`, en el campo `Id` que corresponde
   (o pásamelos y lo hago yo).

Mientras un `Id` sea `0`, ese audio simplemente no suena; el resto del juego funciona igual.

Para cambiar la música: edita `scripts/audio/compose.py` y ejecuta `python3 scripts/audio/compose.py`
(necesita `pip install numpy soundfile`). Después hay que volver a subir el archivo cambiado.
