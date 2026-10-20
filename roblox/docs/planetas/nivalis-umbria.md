# Nivalis y Umbría: la primera media hora de cada uno

Dos planetas más con el marco común ([marco-planetas.md](marco-planetas.md)), como Miasma y Siroco: se
puede ir ya (Saga 1 terminada o tester), el mapa galáctico dice «Misiones activas» y cada uno tiene un
barrio de su capital, su cielo, su sonido, su desventaja, su oficio, sus materiales y unos 30 minutos de
historia. El diseño completo está en [diseno-mundos.md](diseno-mundos.md) §3.4 y §3.5.

## Nivalis · Fortaleza Albor (episodio 4 «La noche del Regente»)

**El barrio.** Dentro de la Muralla Vieja (almenas nevadas, cuatro puertas con arco y una torre-farol en
cada esquina): el **Patio de Armas** (la plataforma), la **Plaza de los Faroles** con la **Estatua Rota de
la Reina** y tres **hogueras de musgo**, el **Mercado de Hielo** (puestos de mantas, guantes, lana y
cristal), la **Torre del Farolero**, casas de piedra con tejado empinado nevado y un farol ámbar en la
cumbrera, arcos de hielo tallado sobre la Calle Norte, estandartes azules del Regente y trineos.
Se entra en las **Termas del Farol**, el **puesto de sopa de Brisa** (tienda: sopa caliente), la
**Biblioteca de los Ecos** (de hielo, con agujas transparentes) y la **casa de Tila**. Fuera: el Valle de
Albor nevado, el Bosque de Escarcha, el Lago de los Ahogados helado, las Fuentes Calientes, el Monasterio
de Hielo, la Cabaña del Ermitaño, la Antena de las Auroras en los picos, el **Palacio de Escarcha** en la
ladera norte y tres cortinas de **aurora** verde y rosa en el cielo.

**La luz y el sonido.** Noche eterna: cielo de estrellas, luz de luna azul con el verde de la aurora,
bruma fría y brillo en el hielo. Nieve fina siempre y, en la **ventisca** (dos al día, ~1 min), nieve a
ráfagas y otra música. Dentro de un refugio, el viento se apaga.

**El frío** (❄). Sube fuera de la muralla (deprisa en los picos y en la ventisca), despacio dentro.
Junto a una hoguera, en las Fuentes Calientes y en los refugios (Termas, sopa, casa de Tila) baja.
Equipo: **abrigo de lana de lanudo** (−40 %) y **abrigo de lana doble** (−65 %). Contramedida: **sopa
caliente de Albor** (desde la mochila; se compra en el puesto de Brisa). Nunca mata: si te tumba,
despiertas en el refugio más cercano.

**El oficio: farolero/a** (🏮, tablón junto a la Torre del Farolero). Encender dos faroles (tres desde
Veterano) con el minijuego de la mecha y dejar el mensaje de la resistencia en un buzón de la muralla,
andando y quieto un rato. Desde 45 € por ronda, rangos de la galaxia; a veces te llevas un cristal de eco.

**Materiales.** Musgo de nieve y cristal de eco («Recoger» en el barrio); hielo eterno y lana de lanudo
(premios de la historia).

**La historia (≈ 36 min, 5 misiones).**

| # | Misión | Qué se juega | Decisión |
|---|---|---|---|
| 1 | Aterrizaje a oscuras | Escena de llegada (la aurora sobre el Palacio y no sobre el barrio), salir al Mirador del Valle, el frío en aviso, Tila en la hoguera (abrigo y sopa), tomarse la sopa. | — |
| 2 | La hora del silencio | Cruzar la plaza sin que te pille la guardia (andando), el vecino que os delata, esconderse en las Termas. | ¿Denunciar al señor Carámbano o dejarle? |
| 3 | El código de los faroles | Una ronda de farolero de verdad, encender los tres faroles del código, leer la respuesta (minijuego): «Vivo. Minas.» | — |
| 4 | La Biblioteca de los Ecos | Colarse por el callejón, el puzle de los cristales (minijuego), Madre Copo y la canción de la Reina, pelea con dos guardias (resbalan en la nieve), huida a la Muralla Vieja. | ¿Llevarte el cristal de la Reina o dejarlo con Copo? |
| 5 | La Muralla Vieja | La vela por los que no vuelven, escena de la princesa que «murió» en el Glaciar, Ilse. **Gancho:** Nilo está vivo en las Minas. | — |

Las dos decisiones cambian lo que dice Ilse al final. Premios: abrigo de lana doble, la vela de Tila, el
cristal de la Reina (si te lo llevas), hielo eterno, lana de lanudo y musgo.

## Para programadores

- Superficie y datos: `shared/Cosmos/Nivalis.luau` (frío, oficio, cielo), `shared/Cosmos/NivalisCity.luau`
  (plano; `Decor` = muralla, torres, puestos y hogueras, que dibuja el kit sin contar como edificios).
- Kit: `server/World/NivalisKit.luau` (solo piezas; estilos Box `NivalisPiedra` y `NivalisHielo`).
- Historia: `LifeStory/Misiones/Nivalis_Episodio.luau`, escenas `LifeStory/Happenings/Nivalis.luau`, guion
  de la misión 1 en `docs/historia/reescritura/Nivalis_01_Oscuras.md` (→ `Guiones/`).
- `PlanetClient`: lo que cae del cielo (`S.Fx`) puede llevar `Mode` (solo en ese momento del planeta: la
  ventisca de Nivalis, la lluvia de Umbría).
- Pruebas: `scripts/test-planetas.luau` (sección de cada planeta del marco y `EPISODES`).
