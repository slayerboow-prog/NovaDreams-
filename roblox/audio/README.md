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

## Cómo ponerla en el juego — forma fácil (sin copiar IDs)

1. Abre el juego en Roblox Studio.
2. **Window → Asset Manager → Bulk Import** y elige los 7 archivos `.ogg` de esta carpeta.
3. En el Asset Manager, carpeta **Audio**, arrastra cada audio al **Explorer**, dentro de
   **ReplicatedStorage → Musica** (se crea un `Sound` con su ID).
4. Guarda el juego. El juego reconoce cada audio por su nombre (`tema_valmar`, `nacimiento`…).

## Cómo ponerla en el juego — con IDs (una sola vez)

1. Abre el juego en Roblox Studio.
2. **Ventana (Window) → Asset Manager** → botón **Bulk Import** (importar varios) y elige los 7 archivos `.ogg` de
   esta carpeta. También se puede en create.roblox.com → *Creations* → *Development Items* → *Audio* → *Upload Asset*.
   (Roblox puede pedir verificar la cuenta o limitar cuántos audios subes al mes: es normal.)
3. Cuando estén subidos, en el Asset Manager haz clic derecho en cada audio → **Copy ID**.
4. Pega cada ID en `src/shared/Config.luau`, sección `Config.Audio`, en el campo `Id` que corresponde
   (o pásamelos y lo hago yo).

Mientras un `Id` sea `0` (y el audio no esté en `SoundIds` ni en **ReplicatedStorage → Musica**), ese audio
simplemente no suena; el resto del juego funciona igual.

Para cambiar la música: edita `scripts/audio/compose.py` y ejecuta `python3 scripts/audio/compose.py`
(necesita `pip install numpy soundfile`). Después hay que volver a subir el archivo cambiado.

---

# Efectos de sonido (`audio/sfx`)

También **originales** y hechos por código (`scripts/audio/sfx.py`): ruido filtrado, tonos y voces
inventadas, sin palabras. Son cortos, en mono y ocupan poco. Los que van en bucle empalman sin "clic".

| Archivo | Qué es | Dónde suena | En Config |
|---|---|---|---|
| `motor.ogg` | Motor en bucle (2 s); el juego le sube el tono al acelerar | Conducir coche, moto, bus… | `Sounds.Motor` |
| `claxon.ogg` | Claxon de dos tonos (0,6 s) | Tecla H en coche o moto | `Sounds.Claxon` |
| `timbre.ogg` | Timbre de bici "ring ring" (0,8 s) | Tecla H en bici o patinete | `Sounds.Timbre` |
| `tele.ogg` | Tele de fondo: voces bajitas y música (bucle 4 s) | Tele encendida en casa | `Sounds.Tele` |
| `multitud.ogg` | Murmullo de gente (bucle 6 s) | Cerca de la Plaza Mayor | `Sounds.Multitud` |
| `metro_tren.ogg` | Traqueteo del tren con su clac-clac (bucle 4 s) | Dentro del metro o del cercanías | `Sounds.MetroTren` |
| `metro_freno.ogg` | Frenazo suave y soplido del aire (2 s) | El tren llega a la estación | `Sounds.MetroFreno` |
| `metro_anden.ogg` | Ambiente del andén: rumor lejano y gente (bucle 6 s) | Bajo tierra, en las estaciones | `Sounds.MetroAnden` |
| `lluvia.ogg` | Lluvia (bucle 6 s) | Cuando llueve | `Seasons.Sounds.Rain` |
| `trueno.ogg` | Trueno (4 s) | Tormenta, tras cada relámpago | `Seasons.Sounds.Thunder` |
| `pajaros.ogg` | Pájaros, pocos cantos (bucle 8 s) | De día con buen tiempo (más en primavera) | `Seasons.Sounds.Birds` |
| `viento.ogg` | Viento (bucle 8 s) | Siempre flojito; más con tormenta, nieve o en lo alto | `Seasons.Sounds.Wind` |

Los de ambiente (multitud, andén, lluvia, trueno, pájaros, viento) van al grupo **Ambience**; los demás, a
**SFX**. El botón «Sonidos: no» los calla todos.

## Cómo ponerlos en el juego — forma fácil (Studio, sin copiar IDs)

1. Abre el juego en Roblox Studio.
2. **Window → Asset Manager → Bulk Import** y elige los 12 archivos `.ogg` de la carpeta `audio/sfx`.
3. Si no existe, crea una carpeta **Sonidos** dentro de **ReplicatedStorage** (clic derecho → Insert
   Object → Folder, y le cambias el nombre).
4. En el Asset Manager, carpeta **Audio**, arrastra cada audio al **Explorer**, dentro de
   **ReplicatedStorage → Sonidos**. Deja el nombre como está (`motor`, `lluvia`…).
5. Guarda el juego. Ya suenan: el juego busca cada efecto por el nombre del archivo.

## Cómo ponerlos en el juego — automático (con un comando)

Desde la carpeta `roblox/`:

```
export ROBLOX_API_KEY=…            # clave de Open Cloud con permiso para subir audios (asset: read, write)
bash scripts/upload-audio.sh       # sube los efectos de audio/sfx
bash scripts/upload-audio.sh --music   # (opcional) también los 7 de música
```

El script sube los audios y escribe sus IDs en `src/shared/SoundIds.luau`; luego solo hay que construir y
publicar el juego. Los sube a nombre del dueño del juego; si no lo puede averiguar, te pedirá
`export ROBLOX_CREATOR_USER_ID=<tu id de Roblox>`. Si lo vuelves a lanzar, solo sube los que faltan
(`--force` para subirlos todos otra vez). La clave no se enseña nunca.

## Qué audio usa el juego (por orden)

1. El `Id` de `src/shared/Config.luau`, si no es `0`.
2. El de `src/shared/SoundIds.luau` (lo escribe `scripts/upload-audio.sh`).
3. Un `Sound` con el nombre del archivo en **ReplicatedStorage → Sonidos** (en la música, **→ Musica**).
4. Si no hay ninguno, no suena (sin errores).

(Un `Sound` en **Sonidos** con el nombre de Config, por ejemplo `Motor`, cambia ese efecto siempre.)

Para cambiar un efecto: edita `scripts/audio/sfx.py` y ejecuta `python3 scripts/audio/sfx.py` (también
necesita `pip install numpy soundfile`; al final enseña la duración, el volumen y si los bucles empalman
bien). Después hay que volver a subir el archivo cambiado (`bash scripts/upload-audio.sh --force motor`).
