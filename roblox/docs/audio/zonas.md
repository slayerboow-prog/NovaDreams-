# El sonido de cada zona

Informe del dueño (v123): «En el espacio los pajaritos siguen sonando. Debe haber otras canciones que se
adapten al espacio y a los nuevos planetas.»

## Qué pasaba

Cada sonido de Valmar miraba solo la hora, el tiempo y si estabas dentro o en el metro. Nadie miraba
**dónde** estabas:

- **Pájaros, viento, lluvia y trueno** (`Controllers/Weather`): sonaban siempre que no estuvieras dentro
  ni en el metro. El viento incluso subía con la altura: en el espacio sonaba **más**.
- **La calle** (`Controllers/StoryAudio`): sin casa, colegio ni edificio cerca, elegía «Calle» (tráfico y
  gente). En el espacio y en Tefra no hay nada de eso cerca, así que sonaba la calle.
- **Grillos y olas** (`Controllers/GameSfx`): solo se callaban por encima de 3000 studs. En la subida y
  en Tefra seguían.
- **La música**: la de tu etapa (Tema de Valmar, Vida adulta…) en cualquier sitio.

## Cómo es ahora

Un solo dueño decide la zona: `shared/Cosmos/EnvZones` + `Controllers/EnvDirector`, el mismo que pinta
el cielo. Con esa zona, `shared/Cosmos/Soundscapes` dice qué suena, y:

- `StoryAudio.setZone` pone el **ambiente** y la **música** de la zona con fundido cruzado (3 s).
- Los bucles de Valmar (pájaros, viento, lluvia, trueno, grillos, olas, la gente del centro) se
  multiplican por `EnvDirector.valmarAudio()`: 1 en Valmar, 0 fuera. En la subida bajan poco a poco.
- Lo que no se oye se **para** (`SoundFx.loopVolume`), no se queda sonando a volumen 0.
- Las escenas siguen mandando encima (una cinemática, `setIntensity`, `setAmbience`).
- Los cuatro controles del menú siguen igual: la música va al 🎵 Música, los ambientes al 🌳 Ambiente.

## Qué suena en cada zona

| Zona | Ambiente | Música |
|---|---|---|
| **Valmar** | el de siempre (casa, colegio, calle…), pájaros, grillos, olas | la del capítulo o la de tu etapa |
| **Subida** (Transición) | el viento de Valmar se apaga solo; zumbido de la cabina | la de Valmar hasta media subida, luego la del espacio |
| **Espacio** | zumbido grave del espacio y la cabina | crucero: `espacio_crucero` y `espacio_deriva`, turnándose |
| Cerca de una estación | lo mismo y la radio lejana | crucero |
| Atracado en una estación | vestíbulo, radio | `espacio_estacion` |
| **Combate** (piratas, patrullas, la Rueca de Varkun) | el del espacio | `espacio_combate` (se queda 8 s tras el último peligro) |
| Arena de pruebas | cabina y aire | `espacio_combate`, más bajita |
| **Tefra** (Bastión Ceniza) | lava, ceniza, fundiciones lejos | `tefra_guerra` (tambores apagados) |
| Tefra, bombardeo | lo mismo y **las sirenas** (solo ahora) | `tefra_guerra` a tope |
| Tefra, dentro de un refugio | sala cerrada y el exterior apagado | `tefra_refugio` (calma) |
| Tefra, tras la tregua | lava, ceniza, fundiciones | `tefra_refugio` |
| **Bajo el mar** | rumor apagado, burbujas, ballenas muy lejos | `nacara`, muy bajita |
| **Nácara** (y su cúpula) | el mar apagado alrededor | `nacara` |
| Siroco (desierto de sal) | viento seco, rumor caliente | `tefra_refugio` |
| Tálasa (océano) | olas y viento salado | `nacara` |
| Nivalis (hielo) | viento frío y silencio | `espacio_crucero` |
| Umbría (selva) | insectos y aire húmedo | `espacio_deriva` |
| Miasma (gas) | drone inquietante y filtros | `Tension` (biblioteca), bajita |
| Vértice (ciudad de máquinas) | zumbido eléctrico y radio | `espacio_estacion` |

Los seis planetas que aún no se pueden visitar ya tienen su perfil: suenan así al entrar en su
atmósfera y sonarán así cuando abran.

## De dónde sale el audio

Todo lo nuevo es **nuestro**, hecho por código: `python3 scripts/audio/zonas.py`. Detalle de cada
archivo y de los ids de la biblioteca de Roblox en `audio/LICENCIAS.md`. Nada con derechos de autor.

**Hay que subirlo** (en la sesión de publicar):

```
bash scripts/upload-audio.sh --zonas
```

Sube los 8 ambientes (`audio/sfx/amb_espacio.ogg`, `amb_cabina`, `amb_radio`, `amb_tefra`,
`amb_fundicion`, `sirena_tefra`, `amb_submarino`, `ballena_lejos`) y las 7 músicas (`audio/espacio_crucero.ogg`,
`espacio_deriva`, `espacio_combate`, `espacio_estacion`, `tefra_guerra`, `tefra_refugio`, `nacara`), y
escribe sus ids en `src/shared/SoundIds.luau`.

Mientras no estén subidos, nunca suena Valmar en su lugar:

- cada capa de ambiente usa su reserva ya subida (el motor, apagado y grave, como zumbido);
- cada música usa su reserva de la biblioteca (Intima o Tension, de APM Music).

## Notas de escucha

- `espacio_crucero`: colchones largos en re lidio, un bajo muy hondo y estrellitas de caja de música.
  Flota, sin pulso.
- `espacio_deriva`: la menor con novena, cuerdas lentas y alguna nota de piano. Más melancólica.
- `espacio_combate`: semicorcheas de cuerdas graves a 120, bombo y caja, un colchón que aprieta. Sin
  melodía, para no tapar los disparos.
- `espacio_estacion`: acordes cálidos con séptima, bajo que camina despacio y un platillo finísimo.
- `tefra_guerra`: tom grave de guerra, un yunque lejano cada dos compases y un bordón en do con la
  segunda menor. Apagada, no épica.
- `tefra_refugio`: cuerdas graves y piano lento, de do menor a mi bemol. Esperanza.
- `nacara`: arpegios de cristal en mi mayor con mucho eco. Etérea.
- `amb_espacio`: zumbido muy grave que respira. `amb_cabina`: ventilación y 50 Hz suave.
  `amb_radio`: frases sin palabras por un altavoz pequeño, chasquidos y un pitido.
- `amb_tefra`: rumor de lava, burbujas espesas, crujidos y viento de ceniza. `amb_fundicion`:
  martillazos lejanos con eco y una prensa. `sirena_tefra`: sube 4 s y baja 4 s, lejana.
- `amb_submarino`: rumor apagado y burbujitas. `ballena_lejos`: un canto que sube y baja, con eco.

Todos los bucles empalman sin «clic». Los ambientes pesan menos de 110 KB y las músicas menos de 520 KB.

## Pruebas

- `test-audiomix`: cada zona da su perfil, nada de Valmar en el espacio, las sirenas solo en el
  bombardeo, el combate se queda un rato, los controles de volumen, archivos pequeños y documentados.
- `test-storyaudio`: `setZone` cruza la música con fundido, quita la de Valmar, combate y vuelta,
  estación, Tefra, el mar y la vuelta a Valmar.
- `test-space`, `test-planetas`, `test-mar`: `EnvDirector` de verdad en el espacio, Tefra, el mar y Nácara.
