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

## Música por intensidad (escenas)

Las escenas piden una **intensidad** (`StoryAudio.setIntensity`, `Config.Audio.Intensity`) y la música cruza
suave a su pieza. Mientras una pieza nueva no esté subida (su `Id` es `0` y no está en `SoundIds`), suena su
`Fallback`, una de las de arriba que ya está subida; si no tiene `Fallback`, solo suena el ambiente.

| Intensidad | Archivo | Cómo es | Mientras no esté subida | En Config.Audio |
|---|---|---|---|---|
| Nada | — | Momento normal: sin música, solo ambiente | — | `Intensity.Nada` |
| Descubrimiento | `descubrimiento.ogg` | Ligera y curiosa: pizzicato y caja de música (bucle de 46 s) | `tema_valmar` | `Music.Descubrimiento` |
| Intima | `intima.ogg` | Piano solo, lento, con aire entre frases (bucle de 66 s) | `nacimiento` | `Music.Intima` |
| Tension | `tension.ogg` | Ostinato grave, latido y disonancias, sin melodía (bucle de 38 s) | (solo ambiente) | `Music.Tension` |
| Resolucion | `resolucion.ogg` | El éxito: sube y cierra en re mayor (41 s, no se repite) | `vida_adulta` | `Music.Resolucion` |
| Tema | `tema_final.ogg` | Final de capítulo: el tema de Valmar orquestado (64 s, no se repite) | `tema_valmar` | `Music.TemaFinal` |

Para subirlas: `bash scripts/upload-audio.sh --music` (sube las que faltan y escribe sus IDs en
`src/shared/SoundIds.luau`; no hay que tocar Config). Solo estas cinco:
`bash scripts/upload-audio.sh --music descubrimiento intima tension resolucion tema_final`.
Para rehacerlas: `python3 scripts/audio/compose.py descubrimiento intima tension resolucion tema_final`.

## Cómo ponerla en el juego — forma fácil (sin copiar IDs)

1. Abre el juego en Roblox Studio.
2. **Window → Asset Manager → Bulk Import** y elige los 12 archivos `.ogg` de esta carpeta.
3. En el Asset Manager, carpeta **Audio**, arrastra cada audio al **Explorer**, dentro de
   **ReplicatedStorage → Musica** (se crea un `Sound` con su ID).
4. Guarda el juego. El juego reconoce cada audio por su nombre (`tema_valmar`, `nacimiento`…).

## Cómo ponerla en el juego — con IDs (una sola vez)

1. Abre el juego en Roblox Studio.
2. **Ventana (Window) → Asset Manager** → botón **Bulk Import** (importar varios) y elige los 12 archivos `.ogg` de
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

## Si la música no suena

Desde que entras suena la música de fondo de tu etapa (**🔊 Música: sí** por defecto), a los 2 s,
con fundidos. Si una pieza no carga en el juego, `StoryAudio` prueba sus otras copias (su `Id` de
`Config.Audio`, su id en `SoundIds`, un `Sound` en **ReplicatedStorage → Musica**) y luego su
`Fallback` (TemaValmar y VidaAdulta → Descubrimiento, Nacimiento → Intima, PasanLosAnos → Resolucion).
En la ventana Salida (F9) sale `[Música] No se ha podido cargar …` con el id que falla.

Un audio de Roblox **solo suena en juegos de su mismo creador** (o con permiso dado a este juego):
si se subió con otra cuenta o a nombre de un grupo, y el juego es de un usuario (o al revés), no suena.
Tampoco suena mientras está **en revisión** o si Roblox lo ha rechazado.

Para saber qué pasa con cada id, en un servidor de verdad (clave con «luau-execution-sessions»):

```
bash scripts/cloud-test.sh -v audio
```

Dice para cada audio si es de tipo Audio (`AssetTypeId = 3`), si es del dueño del juego y si se puede
descargar. Si las cuatro piezas de `Config.Audio.Music` con `Id` fallan, súbelas otra vez a nombre del
dueño del juego (quedan en `SoundIds` y entran solas como copia):

```
bash scripts/upload-audio.sh --music nacimiento tema_valmar pasan_los_anos vida_adulta sting_momento sting_capitulo sting_primeros_pasos
```

Si un audio es tuyo pero el juego es de un grupo (o es de otra cuenta tuya), también vale darle permiso:
create.roblox.com → *Creations* → *Development Items* → *Audio* → el audio → *Permissions* → añade este
juego (Real Life Simulator).

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
| `choque_leve.ogg` | Choque flojo de coche: "tunk" de chapa y algún trasto (0,45 s) | Chocar despacio (menos de 30) | `Sounds.ChoqueLeve` |
| `choque_fuerte.ogg` | Choque fuerte: crujido de chapa, traqueteo y cristalitos (0,9 s) | Chocar rápido | `Sounds.ChoqueFuerte` |
| `golpe_caida.ogg` | "Pof" corto del cuerpo al caer (0,26 s) | Caer desde alto | `Sounds.GolpeCaida` |
| `golpe_choque.ogg` | "Tuc" seco (0,2 s) | Chocar corriendo con una pared, puñetazos | `Sounds.Golpe` |
| `disparo_pistola.ogg` | Disparo de pistola, seco y agudo (0,45 s) | Pistola y pistola de policía | `Sounds.DisparoPistola` |
| `disparo_revolver.ogg` | Disparo de revólver, más gordo (0,65 s) | Revólver | `Sounds.DisparoRevolver` |
| `disparo_escopeta.ogg` | Estampido ancho de escopeta (0,85 s) | Escopeta | `Sounds.DisparoEscopeta` |
| `disparo_subfusil.ogg` | Disparo corto y seco para ráfagas (0,28 s) | Subfusil | `Sounds.DisparoSubfusil` |
| `disparo_fusil.ogg` | Chasquido supersónico + estampido (0,7 s) | Fusil y (más lento) francotirador | `Sounds.DisparoFusil`, `Sounds.DisparoFrancotirador` |
| `disparo_eco.ogg` | Eco del disparo en los edificios, apagado (1,1 s) | Detrás de cada disparo | `Sounds.EcoDisparo` |

### Ambiente por tipo de lugar (`amb_*`)

Capas en bucle de 8-10 s que `StoryAudio` pone muy bajas, con fundido, según dónde estás (o lo que pida la
escena con `StoryAudio.setAmbience`). Ver `Config.Audio.Ambience`.

| Archivo | Qué es | Tipo de lugar | En Config | Mientras no esté subido |
|---|---|---|---|---|
| `amb_sala.ogg` | Aire de sala cerrada: climatizador y zumbido flojo | Base de colegio, universidad, oficinas, tiendas, salas… | `Sounds.AmbSala` | `viento`, apagado (`AmbAire`) |
| `amb_casa.ogg` | Nevera, la calle por la ventana, algún crujido | Casa (con el tic-tac del reloj aparte) | `Sounds.AmbCasa` | `viento`, apagado |
| `amb_colegio.ogg` | Niños en el pasillo, pasos, puertas | Colegio (de 8 a 18 h) | `Sounds.AmbColegio` | `multitud`, más aguda |
| `amb_universidad.ogg` | Estudiantes, vestíbulo, la máquina expendedora | Universidad | `Sounds.AmbUniversidad` | `multitud` |
| `amb_hospital.ogg` | Ventilación, murmullo, una camilla que pasa | Hospital (con el pitido del monitor aparte) | `Sounds.AmbHospital` | `viento`, apagado |
| `amb_calle.ogg` | Tráfico lejano que va y viene, gente a lo lejos | Calle, parques, estación | `Sounds.AmbCalle` | `multitud`, bajita |

Los golpes sueltos (reloj, pitido del monitor, puertas, teclas, gong de la estación) son sonidos de Roblox:
suenan siempre. Para subir los seis: `bash scripts/upload-audio.sh amb_sala amb_casa amb_colegio
amb_universidad amb_hospital amb_calle`. Para rehacerlos: `python3 scripts/audio/sfx.py amb_sala amb_casa …`.

Golpes, choques y disparos no tienen subgraves (nada de "bum" de bomba). Mientras no estén subidos suena su
`Fallback` de Config (un sonido de Roblox agudo y flojo) y el eco no suena.

Los de ambiente (multitud, andén, lluvia, trueno, pájaros, viento y los `amb_*`) van al grupo **Ambience**; los demás, a
**SFX**. El botón «Sonidos: no» los calla todos.

### Respuesta del juego (`scripts/audio/sfx_feedback.py`)

Hechos por capas como en un juego grande (ataque + cuerpo modal o campana FM + aire + sala), sin pitidos,
e igualados de sonoridad por categoría (interfaz -24, recompensas -20, momentos -19, mundo -20 dBFS RMS,
pico ≤ -1 dBFS). **Mientras no estén subidos**: los que ya sonaban (clic, aviso, error, menú, puerta,
fútbol) siguen con su sonido de Roblox; los nuevos **no suenan** (mejor nada que un pitido).

| Archivo | Qué es | En Config.Sounds | Dónde suena |
|---|---|---|---|
| `ui_toque.ogg` | Tock de madera fina | `Clic`, `MenuOk` | Botones |
| `ui_seleccion.ogg` | Tick de madera redondo | `MenuMover`, `Seleccion` | Menú de comandos, barra rápida |
| `ui_abrir.ogg` / `ui_cerrar.ogg` | Soplo de aire que sube / baja con un tick | `MenuAbrir` / `MenuAtras` | Abrir / volver en menús |
| `movil_abrir.ogg` | Roce del bolsillo y dos toques de cristal | `MovilAbrir` | Sacar el ValPhone |
| `notificacion.ogg` | Dos notas de marimba (quinta) | `Aviso` | Avisos, mensajes al móvil |
| `error_suave.ogg` | Dos golpes de madera graves que bajan | `Error` | Denegado |
| `dinero.ogg` | «Ka-ching»: palanca, campanilla y monedas | `Dinero` | Cobrar |
| `caja_registradora.ogg` | Pitido del lector y cajón | `Pago` | Pagar |
| `xp.ogg` | Tres campanitas y chispas | `Xp` | Ganar experiencia |
| `nivel_sube.ogg` | Riser + golpe + acorde de campanas + cuerdas + chispas (4 s) | `SubirNivel` | Nivel nuevo (agacha la música) |
| `mision_empieza.ogg` | Golpe grave suave y dos notas que suben | `MisionEmpieza` | Empieza una misión |
| `mision_completa.ogg` | Arpegio + acorde de metales + chispas | `MisionCompleta` | Misión cumplida |
| `logro.ogg` | Aire + golpe de cristal + acorde de celesta | `Logro` | Recompensa del pase desbloqueada |
| `descubrimiento_fx.ogg` | Aire que crece y se abre en campanas | `Descubrimiento` | Sitio descubierto |
| `tension_golpe.ogg` | Impacto grave y cluster disonante | `Tension` | Entra la música de tensión |
| `coger_objeto.ogg` | Roce y tock | `Coger` | Algo nuevo en la mochila |
| `puerta_madera.ogg` | Pestillo y golpe de madera | `Puerta` | Puertas |
| `balon_patada.ogg` | Golpe sordo y cuero | `FutbolChute` | Chutes |
| `balon_bote.ogg` | Bote con el ping de la cámara | `BalonBote`, `VoleyGolpe` | Baloncesto, vóley |
| `aro_rebote.ogg` | Aro de acero que vibra | `AroRebote`, `FutbolPoste` | Aro, poste |
| `red_swish.ogg` | Roce de la red | `RedSwish` | Canasta, gol |
| `silbato.ogg` | Silbato de bolita (corto + largo) | `FutbolSilbato` | Árbitro, carreras |
| `raqueta_golpe.ogg` | Cuerdas y thock | `RaquetaGolpe` | Tenis y pádel |
| `pesas_golpe.ogg` | Discos de hierro | `PesasGolpe` | Gimnasio (pesas) |
| `estadio_ovacion.ogg` | Grada que grita y aplaude (4,8 s) | `Ovacion` | Gol, canasta, punto |
| `grillos.ogg` | Grillos de noche (bucle 8 s) | `Grillos` | De noche al aire libre |
| `olas.ogg` | Olas en la orilla (bucle 12 s) | `Olas` | Cerca de la costa |

Para subirlos: `bash scripts/upload-audio.sh` (sube solo los que faltan). Para rehacerlos:
`python3 scripts/audio/sfx_feedback.py` (o solo algunos: `… dinero xp`). Antes de publicar conviene
escucharlos en Studio (Asset Manager): si alguno no da la talla, se cambia por otro poniendo un `Sound`
con su nombre de Config (p. ej. `Ovacion`) en **ReplicatedStorage → Sonidos**.

## Efectos de la biblioteca de Roblox (calidad profesional)

Casi todos los efectos usan ya un audio **público** de la biblioteca de Roblox: los oficiales de interfaz
(subidos por **Roblox**) y grabaciones de la librería profesional con licencia **ProSoundEffects** (socia de
Roblox). Suenan en cualquier experiencia, sin subir nada. Van en el `Id` de `Config.Sounds`, que manda
sobre el archivo nuestro (`File`) y sobre el `Fallback`.

- `Region = { desde, hasta }` (segundos): solo suena ese trozo de una grabación larga (en los bucles,
  el bucle se queda dentro del trozo). `FadeOut = s`: fundido al final del trozo (sin «clic»).
- Volúmenes igualados midiendo cada audio (RMS) contra el nivel de diseño de su categoría.
- Comprobado en un servidor de verdad: `bash scripts/cloud-test.sh -v audio-biblioteca` (carga, es un
  audio y dura lo que toca; los trozos caben). `lune run scripts/test-sfx.luau` vigila que esa lista
  sea la de `Config.Sounds`.

| Hueco (`Config.Sounds`) | Qué es | Origen |
|---|---|---|
| `Clic`, `MenuOk`, `MenuMover`/`Seleccion`, `MenuAbrir`, `MenuAtras`, `MovilAbrir` | Clic, select, hover, swipe, back y tab oficiales | Roblox |
| `Aviso`, `Error`, `Dinero`, `Xp`, `Coger` | Notificación, negativo, compra, recoger, equipar | Roblox |
| `Logro`, `MisionEmpieza` | Stinger tonal e indicador oficiales | Roblox |
| `Pago` | Caja registradora real | ProSoundEffects |
| `Descubrimiento` | Árbol de campanas (brillo) | ProSoundEffects |
| `Tension` | Impacto grave lejano | ProSoundEffects |
| `Puerta` | Puerta de madera (trozo) | ProSoundEffects |
| `FutbolChute`, `FutbolSilbato`, `SilbatoGol`, `FutbolPoste`/`AroRebote` | Patada, silbato de árbitro, pitido largo de gol, golpe en poste metálico | ProSoundEffects |
| `BalonBote`, `VoleyGolpe`, `RedSwish`, `RaquetaGolpe`, `PesasGolpe` | Bote de balón, swish de la red (trozo), raquetazo (trozo), discos de pesas | ProSoundEffects |
| `Ovacion`, `PublicoEstadio` | Grada que celebra; grada de fondo en bucle (mientras juegas: `InSport`) | ProSoundEffects |
| `Grillos`, `Olas`, `Multitud` | Grillos y cigarras, olas en la orilla, murmullo de gente | ProSoundEffects |
| `Claxon`, `ClaxonPesado`, `Timbre` | Claxon de coche, bocina de autobús/camión/barco, timbre de bici | ProSoundEffects |
| `PuertaCoche`, `PuertaCocheAbrir`, `CambioMarcha`, `Derrape` | Puerta al subir/bajar, palanca de cambios, chirrido de ruedas (bucle) | ProSoundEffects |
| `BiciCadena`, `PatineteZumbido`, `MonopatinRodar` | Cadena y piñón libre, motor eléctrico, ruedas en asfalto (bucles con la velocidad) | ProSoundEffects |
| `Comer`, `Beber`, `Cocinar`, `Fabricar` | Mordisco, trago, sartén, martillo | ProSoundEffects |
| `PistolaSalida`, `KO` (+ `KOCaida`), `Brazada` | Disparo de fogueo, golpe a la barbilla y caída, brazada | ProSoundEffects |
| `MetroGong`, `AvisoAeropuerto`, `BocinaTren` | Ding-dong de megafonía (metro y aeropuerto), bocina del tren al llegar | ProSoundEffects |

| `SubirNivel`, `MisionCompleta` | Fanfarrias orquestales cortas («Final Achievement C», «Orchestral Sting») | APM Music |

Los que ya estaban subidos (motor, lluvia, trueno, pájaros, viento, metro, choques, disparos, `amb_*`)
siguen con el nuestro.

### Música por intensidad de la biblioteca (APM Music)

Las cinco piezas por intensidad (`Config.Audio.Music`) usan una pista con licencia de **APM Music**
(«APMOfficial», pública para cualquier experiencia). La nuestra (`File`, ya subida en `SoundIds`) queda
de copia: si la de la biblioteca no carga, StoryAudio prueba la nuestra y luego el `Fallback`. Volumen
igualado con la nuestra. Los cuatro temas propios (Nacimiento, Tema de Valmar, Pasan los años, Vida
adulta) y los stings de capítulo siguen siendo los nuestros.

| Intensidad | Pista | Id |
|---|---|---|
| Descubrimiento | «Pizzicato Playtime» (111 s, bucle) | 1836329853 |
| Intima | «Solo Piano - Gentle Rain - Remastered» (96 s, bucle) | 9046644321 |
| Tension | «Too Quiet c» (144 s, bucle) | 1841589066 |
| Resolucion | «Anticipating The Future 60 A» (62 s) | 9047298617 |
| Tema (final de capítulo) | «Imagine Tomorrow 60» (61 s) | 9047308022 |

## Cómo ponerlos en el juego — forma fácil (Studio, sin copiar IDs)

1. Abre el juego en Roblox Studio.
2. **Window → Asset Manager → Bulk Import** y elige los archivos `.ogg` de la carpeta `audio/sfx`.
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
bash scripts/upload-audio.sh --music   # (opcional) también los 12 de música
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
