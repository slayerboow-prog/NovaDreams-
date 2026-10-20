# Licencias del audio

De dónde sale cada audio del juego. Solo hay tres orígenes, todos legales:

1. **Nuestro**: hecho por código en este repositorio (`scripts/audio/*.py`: síntesis de instrumentos,
   ruido filtrado y voces inventadas sin palabras). Es 100 % nuestro: no hay derechos de nadie más.
   Se sube a Roblox a nombre del dueño del juego con `scripts/upload-audio.sh`.
2. **Biblioteca de Roblox**: audios públicos de la Creator Store que Roblox deja usar en cualquier
   experiencia: los oficiales de **Roblox**, los de **ProSoundEffects** y los de **APM Music**
   (socios con licencia de Roblox). Se usan por su id; no se descargan ni se vuelven a subir.
3. **Sonidos que vienen con Roblox** (`rbxasset://sounds/…`: `clickfast.wav`, `swoosh.wav`,
   `electronicpingshort.wav`, `collide.wav`, `switch.wav`…): instalados con el cliente de Roblox.

Nada de música con derechos de autor, artistas reales ni marcas.

## 1. Nuestro (hecho por código)

### Música (`audio/`, `scripts/audio/compose.py`)

| Archivo | Id en Roblox |
|---|---|
| `nacimiento.ogg` | 99685990275611 |
| `tema_valmar.ogg` | 71915200549382 |
| `pasan_los_anos.ogg` | 136669358482377 |
| `vida_adulta.ogg` | 90317690788724 |
| `sting_momento.ogg` | 107278309519549 |
| `sting_capitulo.ogg` | 99594760388393 |
| `sting_primeros_pasos.ogg` | 129269798599195 |
| `descubrimiento.ogg`, `intima.ogg`, `tension.ogg`, `resolucion.ogg`, `tema_final.ogg` | en `src/shared/SoundIds.luau` (copia de las de APM, abajo) |

### Música por zona (`audio/`, `scripts/audio/zonas.py`) — **pendiente de subir**

| Archivo | Zona | Cómo suena |
|---|---|---|
| `espacio_crucero.ogg` | Espacio (crucero) | colchones largos en re lidio, bajo hondo, estrellitas de caja de música (48 s, bucle) |
| `espacio_deriva.ogg` | Espacio (crucero, la otra) | la menor con novena, cuerdas lentas y piano suelto (60 s, bucle) |
| `espacio_combate.ogg` | Combate (piratas, patrullas, la Rueca) | pulso de cuerdas graves a 120, bombo y caja sintéticos, sin melodía (32 s, bucle) |
| `espacio_estacion.ogg` | Atracado en una estación | acordes cálidos con séptima, bajo que camina, platillo finísimo (46 s, bucle) |
| `tefra_guerra.ogg` | Tefra (Bastión Ceniza) | tambores de guerra apagados, yunque lejano, bordón en do (27 s, bucle) |
| `tefra_refugio.ogg` | Tefra: refugio y tras la tregua | cuerdas graves y piano lento en do menor, esperanza (48 s, bucle) |
| `nacara.ogg` | Nácara y bajo el mar | arpegios de cristal en mi mayor con mucho eco, etéreo (55 s, bucle) |

### Efectos y ambientes (`audio/sfx/`, `scripts/audio/sfx.py` y `sfx_feedback.py`)

Todos los `audio/sfx/*.ogg` son nuestros (lista y descripción en `audio/README.md`; los ids, en
`src/shared/SoundIds.luau`).

### Ambientes por zona (`audio/sfx/`, `scripts/audio/zonas.py`) — **pendientes de subir**

| Archivo | Zona | Cómo suena |
|---|---|---|
| `amb_espacio.ogg` | Espacio | zumbido muy grave que respira y un aire oscuro; nada de viento ni pájaros (12 s, bucle) |
| `amb_cabina.ogg` | Subida, espacio, arena | zumbido eléctrico suave y ventilación de la cabina (8 s, bucle) |
| `amb_radio.ogg` | Cerca de una estación y dentro | radio lejana: voces inventadas sin palabras, chasquidos y un pitido (10 s, bucle) |
| `amb_tefra.ogg` | Tefra | rumor de la lava, burbujas espesas, crujidos de roca y viento de ceniza (12 s, bucle) |
| `amb_fundicion.ogg` | Tefra | martillazos de metal lejos con eco y una prensa que late (10 s, bucle) |
| `sirena_tefra.ogg` | Tefra, solo en bombardeo | sirena que sube 4 s y baja 4 s, lejana (8 s, bucle) |
| `amb_submarino.ogg` | Bajo el mar, Nácara | rumor apagado que va y viene y burbujitas que suben (10 s, bucle) |
| `ballena_lejos.ogg` | Bajo el mar, Nácara | canto de ballena muy lejos, con eco (6 s, suelto) |

Para subir todo lo de las zonas (la sesión de publicar):
`bash scripts/upload-audio.sh --zonas` (sube los efectos y ambientes que falten y la música por zona;
escribe sus ids en `src/shared/SoundIds.luau`). Mientras no estén subidos, cada capa usa su sonido de
reserva (ya subido) y cada pieza su `Fallback` de `Config.Audio.Music`.

## 2. Biblioteca de Roblox (por id)

### Música con licencia de APM Music (cuenta «APMOfficial»)

| Pieza | Id | Pista |
|---|---|---|
| Descubrimiento | 1836329853 | «Pizzicato Playtime» |
| Intima | 9046644321 | «Solo Piano - Gentle Rain - Remastered» |
| Tension | 1841589066 | «Too Quiet c» |
| Resolucion | 9047298617 | «Anticipating The Future 60 A» |
| TemaFinal | 9047308022 | «Imagine Tomorrow 60» |
| `SubirNivel` (efecto) | 1846170664 | «Final Achievement C» |
| `MisionCompleta` (efecto) | 1846284687 | «Orchestral Sting» |

La música por zona no añade ningún id nuevo de la biblioteca: mientras la nuestra no esté subida, sus
piezas de reserva son estas (Intima y Tension).

### Efectos oficiales de Roblox

`Clic` 15675059323 · `MenuOk` 17208396156 · `MenuMover` / `Seleccion` 17208339919 · `MenuAbrir`
17208405682 · `MenuAtras` 17208186900 · `MovilAbrir` 17208408337 · `Aviso` 17208361335 · `Error`
17208353912 · `Dinero` 17208380755 · `Xp` 17208319162 · `Coger` 17208323435 · `Logro` 15675043410 ·
`MisionEmpieza` 15675085146

### Efectos de ProSoundEffects

`FutbolChute` 9119327232 · `FutbolPoste` / `AroRebote` 9116764099 · `FutbolSilbato` 9117261163 ·
`SilbatoGol` 9125965988 · `Ovacion` 9120974911 · `BalonBote` 9113329573 · `RedSwish` 9113342890 ·
`RaquetaGolpe` 9119985541 · `VoleyGolpe` 9113330443 · `PesasGolpe` 9113271308 · `Pago` 9113728756 ·
`Descubrimiento` (efecto) 9119447936 · `Tension` (efecto) 9125404320 · `Puerta` 9120839870 · `Claxon`
9113013987 · `Timbre` 9125390528 · `Multitud` 9112767169 · `MetroGong` 9114132738 · `BocinaTren`
9120247994 · `AvisoAeropuerto` 9114132512 · `Grillos` 9112762281 · `Olas` 9119677145 ·
`PublicoEstadio` 9119562817 · `BiciCadena` 9113438203 · `PatineteZumbido` 9116980359 ·
`MonopatinRodar` 9125955674 · `Derrape` 9120399191 · `CambioMarcha` 9113018515 · `PuertaCoche`
9113205539 · `PuertaCocheAbrir` 9113205239 · `ClaxonPesado` 9114661361 · `Comer` 9113138343 ·
`Beber` 9114686828 · `Cocinar` 9114542867 · `Fabricar` 9114756156 · `PistolaSalida` 9114700217 ·
`KO` 9113798204 · `KOCaida` 9113469292 · `Brazada` 9120589166

Comprobarlos en un servidor de verdad: `bash scripts/cloud-test.sh -v audio-biblioteca`.
