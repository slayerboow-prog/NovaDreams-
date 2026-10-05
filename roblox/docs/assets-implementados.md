# Assets de Sebastián que ya están en el juego

Una sección por tema. Solo se añade (no se borra lo de otros temas).

## Naturaleza y paisaje (World/NatureAssets + World/MeshLibrary)

Se carga al arrancar el servidor; de cada pack solo se copian MeshPart + SurfaceAppearance (fuera scripts,
sonidos, carteles, textos, NumberPose…) y solo los objetos de una lista por nombre. Árboles, palmeras y
arbustos no se plantan aparte: son plantillas nuevas de MeshLibrary, que cambia los procedurales en una
sola pasada (nada se planta dos veces). Prueba: `lune run scripts/test-nature-assets.luau`.

| Id | Qué | Dónde / por qué no |
|---|---|---|
| 96924659951632 | Árboles PBR (roble, cerezo, viejo, pino) | Roble/cerezo/viejo: árboles de parque y calle (tope 160 copias c/u). Pino: monte (cipreses del campo y parte de los árboles). Sus 14 scripts fuera: el viento lo pone nuestro Sway. |
| 8553512581 | PalmtreeVar0/1, rocas grandes, arbustos | Palmeras: cambian las procedurales (playas, plaza mayor, chalés). LargeMossBoulder/LargeRiverBoulder: rocas en laderas, río y lagos. Bush/FlowerBush/Fern: arbustos. |
| 16879341926 | Rocas con musgo | Rocas grandes en laderas, orillas del río y de los lagos (90 como mucho, chocan). |
| 13388285234 | Terrain Asset Pack | Solo las 4 «Palm Tree» (palmeras). Lo demás no (recopilado de otros, mallas de Half-Life 2). |
| 13877830677 | Landscape Pack | Medium Moss Boulder (rocas) y Rhododendron (arbustos). El resto pesa demasiado. |
| 9262569938 | 5 piedras pequeñas | Grupos de piedrecitas en el césped de los parques (360 como mucho, LeafDetail: el nivel Bajo las esconde). |
| 8919681750 | Velvet's Nature Pack | Robles, arce y olmo en parques; abetos Douglas, píceas y pino ponderosa en el monte (60 copias c/u: pesados). |
| 114397068371248 | Foliage Pack con palmeras | **No**: puerta trasera (familia 1, activa HttpEnabled). En su lugar, las palmeras de 8553512581 y 13388285234. |
| 72475149726020 | Palmeras tropicales | **No**: puerta trasera (familia 1). |
| 109211499509239 | Cerezo (sakura) | **No**: puerta trasera (familia 1). Hay cerezo limpio en 96924659951632 (CherryTree), que sí está. |
| 126164979250031 | Arbusto/haya | **No**: puerta trasera (familia 1, HttpEnabled). |
| 116641210728889 | Hoguera (Campfire Forest Pack) | **No**: puerta trasera (familia 5). |
| 78188971759943 | Farol japonés de santuario | **No**: puerta trasera (familias 3 y 5). |
| 11330013072 | Moai PBR | **No**: la malla está sacada de Splatoon 3 (IP de otro juego). |
| 8649374407 | Animales marinos | Solo los tiburones: 4 nadan despacio mar adentro frente a las playas del este (se mueven solo si hay alguien a menos de 600 studs), y el tiburón del buceo/evento de playa se ve con su malla. Las estatuas de personas, el perro y el conejo no. |
| 130843005739076 | Peces | Peces sueltos (bacalao, mero, barramundi…): 3 en cada mostrador de pescadería (SuperFish) y como malla de los peces que nadan al bucear (SwimFish). Sin kraken, cocodrilo, NPC, Sketchfab ni mosasaurio. |

## Cielo, tiempo, efectos, luz y sonidos (World/SkyAssets + shared/SkyExtras + Controllers/SkyExtras y Footsteps)

El servidor carga los packs limpios al arrancar (fuera scripts, letreros y textos; piezas ancladas y sin
chocar) y los deja en ReplicatedStorage (SkyLibrary y FxLibrary). Los cielos con puerta trasera NO se
cargan: solo se usan los números de sus imágenes en un Sky nuevo nuestro. Todo lo pinta cada cliente
(nada pesa en el servidor) y el nivel gráfico Bajo se salta la luna 3D, el brillo del sol, las nubes de
tormenta, el agua y casi todo el humo. Si algo no carga, se usa un respaldo o no se hace. Prueba:
`lune run scripts/test-skyextras.luau`.

| Id | Qué | Dónde / por qué no |
|---|---|---|
| 8294099223 | Simple Lighting Pack | Su cielo azul con nubes es el **cielo de día** (shared/SkyChoice). De su luz no se copia nada: DayLight ya pone bruma, resplandor, color y rayos según la hora, y su desenfoque de cerca emborronaba. |
| 136402262 | Realistic Space Skybox (Vía Láctea) | **Cielo de noche** (SkyChoice): la luna y las estrellas siguen siendo las nuestras. |
| 102765136165948 | 11 cielos clásicos | Trae puerta trasera: se descarga a memoria, se copian solo las caras de cada Sky y el paquete se destruye sin entrar al juego. Gris «Broken Sky» de día con lluvia o tormenta, «Winterness» con nieve, «Oblivion» en los apagones de la historia. |
| 113036863157630 | Cielo de nubes verdes | Solo sus imágenes (el pack trae virus). Cuando la Grieta escupe algo (capas GrietaVerde y Ominoso de las escenas). |
| 135266547724797 | Cielo «isla flotante» | Solo su imagen (virus). En el sueño del prólogo (isla del cielo). |
| 92375378852064 | Cielo arcoíris | Solo sus imágenes (virus). Mientras duermes (sueñas) y en los momentos dorados de la historia (capa Dorado). |
| 295604372 | Cielo de asteroides | La noche de la **lluvia de estrellas** (una de cada cinco, de 22:00 a 1:30). |
| 4927992927 | Meteors! | No se carga (solo era un script que hacía 50 de daño). La lluvia de estrellas es nuestra: estelas que cruzan el cielo, sin daño. |
| 12737479807 | Luna/sol realistas | Su luna grande (textura 9013498676, tamaño 14) en el cielo. Su script no (desenfoque). |
| 8159177542 | Luna PBR 3D | De noche en Medio y Alto, en el cielo en la dirección de la luna (la 2D se esconde mientras). Fuera su fondo negro. |
| 122782784244668 | Sun Glare | Trae puerta trasera: no se carga. Brillo del sol nuestro (círculos de la interfaz) al mirar al sol a cielo abierto. |
| 11365590395 | Fuego con humo | Sus llamas encima de los fuegos de los incendios (FireService) y en las chimeneas de las casas por dentro; humo en las chimeneas de fuera cercanas (más en otoño, invierno, mañana y noche). |
| 11552439884 | Lluvia realista | Su gota (3806148993) en nuestra lluvia, que ya era mejor en lo demás (40 000 gotas/s del pack no van en móvil). Nuestro sonido de lluvia se queda; el suyo queda guardado de respaldo. |
| 979423743 | Nube de tormenta | Nubes de malla oscuras sobre ti con tormenta, con relámpagos dentro (luz que parpadea y rayo del pack de partículas). |
| 13188926423 | Bingus Particle Pack | Chispas de los golpes y disparos (CombatFx), copos de nieve, hojas de otoño, humo de chimeneas, cometa de las estrellas fugaces y rayo de las tormentas. |
| 223224044 | Agua animada | Sus texturas, movidas despacio, sobre el agua de las fuentes de la ciudad (Medio y Alto). Su script (cambiaba tamaños cada 0,1 s) no. |
| 994161570 | Shading V.2 | Comparado con DayLight/DayGrade: hace lo mismo (resplandor, rayos y color según la hora) con menos pasos y un desenfoque; no se copia nada. |
| 131772048424194 | Pasos según el suelo | **Pasos para ti, los demás jugadores y la gente**: duro, blando (hierba, arena, nieve), metal; tono distinto en madera, cristal… Audios públicos, de *SCP: Containment Breach* (CC BY-SA 3.0, crédito aquí); en el juego no sale ningún nombre. |
| 5033818552 | Pasos realistas | Solo «Carpet Footstep» (133705377, público) para moqueta y tela. Los otros 20 no son públicos (y son de Garry's Mod / Black Mesa). |
| 195181959 | Cielo Caldari | No: es de EVE Online. |
| 93376997873263 | Mapa de bosque anime | No: trae dos puertas traseras (familias 3 y 5, docs/assets-usuario-4.md: `VFXParticles` y `Protocol` con `require` escondido). Su cielo es un azul con nubes normal: no aporta nada al sueño, que ya tiene la isla morada y el arcoíris. |

## Interiores, muebles, comida y objetos (World/InteriorProps)

Se cargan al arrancar el servidor y se copian **limpios**: solo piezas con su malla, SurfaceAppearance y
Texture; fuera scripts, sonidos, luces, ProximityPrompt, constraints, Decal, SurfaceGui, valores,
atributos y etiquetas (así no queda nada de los virus de la 4ª tanda aunque el asset los traiga). Sin
marcas ni nombres de otros juegos; nombres en español; anclado y a talla real. Lo añadido lleva la
etiqueta `DecorProp` (el nivel Bajo lo esconde); lo que sustituye a una pieza hecha por código esconde
la de antes (`PropShell`), que sigue chocando y usándose igual. Prueba: `scripts/test-interiorprops.luau`.

| id | Qué es | Dónde va |
|---|---|---|
| 8236576991 | Tele antigua | Encima de la cómoda del dormitorio (casas, pisos, residencia), en algunas. Escalada de 50 a 2,6 studs. |
| 13395313510 | Estanterías de almacén | Naves por dentro (2): un tramo de 30 studs de una estantería, 13 de alto, junto a las de antes. |
| 13262637537 | Muebles realistas y grunge | Solo aparador (salón), consola (recibidor), armario y sillón de cuadros (villas) y la alfombra persa (en lugar de la alfombra del salón de las villas). Fuera lo de miedo (huesos, cuervos, carteles de Drácula), los props de Half-Life 2, el StarterCharacter, cajones, luces y scripts. |
| 5674029686 | Mueble | Casas y pisos, junto al comedor o el sofá. |
| 5677783820 | Mesa de ordenador | Oficinas, inmobiliarias, seguros y copisterías. |
| 8136205160 | Váter («t») | En lugar del váter hecho por código en los baños de las casas (el asiento de antes se sigue usando). |
| 991205683 | Almohada | En lugar de las almohadas de todas las camas de casas, pisos, villas y residencia. |
| 106442157390222 | Cómoda de hotel | Junto a la cama en la residencia y en algunas casas. Sin nada de DOORS: fuera los nombres Seek/Rush/Figure, sus sonidos (LSPLASH) y el virus. |
| 123553303846741 | Pack de decoración «Bloxburg» | **No**: sus 65 texturas son las de Bloxburg (subidas por su creador) y trae virus; sin ellas no queda nada. |
| 130817699186912 | Props japoneses | Restaurantes de sushi: bonsái en la barra, ramen en las mesas, farolillos y jardineras. Sin el torii ni nada de The Mimic (y sin su virus). |
| 9802494780 | Small Realistic Mesh Pack | Naves industriales de la ciudad: la chimenea de malla en lugar de la de ladrillo y un depósito, tubos o caseta al lado de cada nave. La torre de alta tensión (93 studs) no: no hay tendido eléctrico donde ponerla. |
| 9658188636 | REALISTIC PACK 1 | Sillas y mesas en oficinas, vestíbulos de oficinas, bancos y seguros. Su Lighting no (ya tenemos el nuestro). |
| 12110426279 | REALISTIC PACK 2 | Nevera (bares, cafeterías, kebabs, hamburgueserías), sillas de cafetería, caseta de perro (tienda de mascotas), archivadores, sofá del vestíbulo, extintores, taquillas (cuartel, naves), papeleras. Sin coches, camiones, bidones de Half-Life 2 ni barriles explosivos. |
| 17519952806 | Comida callejera | Pinchos en la barra de kebabs, bares y hamburgueserías. |
| 4609898985 | Pack de comida | Platos en las mesas de bares, cafeterías, pizzerías, hamburgueserías, kebabs y sushi, y en la mesa o la encimera de las casas. Fuera las latas y la botella de cola (marcas), el logo del autor y las 3 texturas bloqueadas. |
| 82460675146164 | Más comida | Montón de comida en el mostrador de ultramarinos y fruterías, y en la cocina de las villas (sin su virus). |
| 95413639317338 | Huevo frito | En los platos de la mesa de las casas y de cafeterías y bares (sin su virus). |
| 9766849655 | Magdalena | En el mostrador de panaderías, cafeterías y heladerías. |
| 15666503758 | Comida de gato | Tienda de mascotas (mostrador y estantes), con la marca inventada **KESTREL** («comida para gatos»); la textura con la marca real se quita. |
| 1305075170 | Fajos de billetes | En el mostrador de los bancos (sin el texto «$10,000»). |
| 11329271645 | Portapapeles | Consultas y control de enfermería del hospital y centros de salud, mostrador de la comisaría, escritorios de oficinas, juzgado, Hacienda y cuartel. |
| 11444948273 | Puerta de madera | La puerta de salida de casas, pisos y villas (la de antes sigue siendo la salida). |
| 166379099 | Silla gigante | Escaparate de las tiendas de muebles (9 studs de alto). Asset sin revisar: se copian solo sus piezas; si no carga, la tienda queda igual. |
| 123778443128832 | Cofre de recompensa | Solo el modelo (sin el script de grupo ni el virus): guardado en `ReplicatedStorage.ModelosPremio.CofreRecompensa` para el pase y los premios, y uno en las jugueterías. |

No hay sistema de comida en 3D (la comida de la mochila son iconos): la comida va como decorado en
restaurantes, tiendas y cocinas.

## Materiales y texturas (shared/UserMaterialChoice, HouseLook, InteriorLook, StreetLook + World/UserMaterials y World/MaterialExtras)

Las texturas de los MaterialVariant no se pueden leer desde un script y a un variant de la Tienda no se le
puede cambiar el BaseMaterial en un servidor de verdad. Por eso todo se elige por NOMBRE y se usa pieza a
pieza donde el material no encaja. Si un pack no carga (o da error), se usan los de respaldo y el juego sigue.

| id | Pack | Dónde se usa |
|---|---|---|
| 9408271791 | PBR_Textures (20 MaterialVariant) | Respaldo de 13 materiales globales (ladrillo, hormigón, adoquín, pizarra, mármol, madera, tablas, arena, chapa estriada) y **primero en la grava (Pebble)**. Es respaldo de fachadas (ladrillo, zócalo, hormigón, madera, chapa de nave), interiores (parqué, mármol, moqueta, hormigón, pizarra, encimera de granito) y plazas de adoquín. No se usa como primero porque tiene 10 votos negativos y nadie lo ha visto en el juego. «Glass_PBR» va sobre Ice y no se usa. |
| 12715816700 | ALL MATERIALS | No está en los docs: se busca por palabras y BaseMaterial («brick», «concrete», «marble», «carpet», «roof», «stucco», «sand»…). Respaldo de los globales, de las fachadas y de los interiores. |
| 9268236860 | Realistic sand texture | **La arena de la playa y del terreno**: es el primer candidato para Sand si su variant viene sobre Sand. Si viene sobre otro material, se pone pieza a pieza en la arena de la playa (Kit/Civic, con la física de la arena). Si solo trae una textura, va como lámina sobre la playa. |
| 12152263865 | Bronze PBR (SurfaceAppearance) | Placas de los cuadros del museo (bronce limpio) y escultura de la plaza del museo (bronce de estatua). Encima va un bloque de bronce de la misma talla. La pieza de antes sigue para chocar y solo se ve en gráficos Bajo. |
| 12433695725 | Texture pack (realistic) | Texturas antiguas (`Texture`). Se usan sus losetas de techo («Ceiling A–L») como lámina en los techos de placas de parte de las oficinas, tiendas, colegio y hospital. Paredes, suelos, tejados, cristal y terreno no se usan: ahí ya hay PBR, que se ve mejor. |
| 123159368741340 | Realistic Materials Pack (51 losetas) | Texturas antiguas. Las losetas se clasifican por nombre (papel pintado, moqueta, techo o arena) y se usan como lámina. Si sus nombres no dicen nada, no se usan. |
| 11877329379 | Realistic Texture Pack | Texturas antiguas. «Wallpaper» va como papel pintado en la mitad de las salas con papel, «Carpet» como moqueta en el 40 % de las oficinas e «Interior Roofing» como techo de placas. Ladrillo, tejas, baldosas, cristal, metal, hormigón y paisaje no se usan (ya hay PBR). |
| 3778526307 | Custom Material Pack 1 | Texturas antiguas. «Carpet» va como moqueta. Se borran sus 60 scripts del agua animada. Agua, lava, esponja, goma, porexpán y bambú no se usan: no encajan en una ciudad. |
| 856287704 | Ultra HD texture pack (2017) | No está en los docs: sus losetas se clasifican por nombre, como las de los otros packs. Si no dicen papel pintado, moqueta, techo o arena, no se usan. |

Las láminas (`Texture` «U_Lamina») van solo donde una textura plana se ve bien: papel pintado, moqueta y
placas de techo. Cada sala lleva la misma lámina en todas sus piezas, siempre la misma, y el resto de
salas se queda con su PBR. En gráficos Bajo se esconden (etiqueta TextureDetail). No se usa ninguna
loseta que tenga en el nombre una marca, «logo», un juego (DOORS, Bloxburg, The Mimic, SCP) o sangre.

### Packs de MaterialVariant que ya se usaban: cuántos se usan ahora

«Usados» quiere decir que el variant está en alguna lista: en la variedad que se reparte por edificio,
sala o zona, o como respaldo.

| id | Pack | Variants | Usados (antes → ahora) | Sin usar y por qué |
|---|---|---|---|---|
| 11392874817 | Césped 2k | 1 | 1 → 1 | — |
| 13277933714 | Realistic Materials (piedras) | 20 | 12 → 17 | Metal (el metal pintado es nuestro), Sandstone y Snow (en Valmar no hay arenisca ni nieve) |
| 14527172541 | Realistic Materials (madera) | 6 | 4 → 5 | Realistic Snow (no hay nieve) |
| 15221806045 | PBR Realistic Material Mega Pack | 524 (7 rotos) | 70 → 94 | El resto no encaja en una ciudad: 13 asfaltos «Lab» de colores, unos 60 metales de ciencia ficción, piel humana, carne, sangre, lava, calaveras, rocas de cueva y de otros planetas, vegetación y musgo. Los rotos (rbxtemp://) se borran al cargar. |
| 15446413305 | Realistic Materials (generador) | 8 | 3 → 7 | RealisticGold (es oro sobre Sand: nunca en la playa) |
| 92927007790601 | Tylers Realistic Materials | 68 | 19 → 64 | MetalGate, RustedMetalGate, RustedDiamondMetal (verjas y chapa oxidada: el metal pintado es nuestro) y TableCloth (mantel) |

Variedad nueva:
- **Fachadas**: 5 ladrillos, 5 piedras de zócalo, 5 hormigones de edificio público, 4 maderas, 3 tejas (antes 2), 3 chapas de nave, 3 hormigones de muelle y 2 entablados coloniales, fijos por edificio.
- **Interiores**: 6 parqués, 5 hormigones, 4 baldosas de baño, 4 baldosas de local, 3 de cocina, 3 mármoles, 3 moquetas, 2 moquetas de cine, 3 granitos de suelo, 3 encimeras de granito, 3 encimeras de madera, 4 ladrillos vistos y 2 pintados, fijos por vivienda o local.
- **Calles**: la mitad de las plazas son de adoquín hexagonal. Las aceras de barrio, centro y afueras, y el adoquín del casco antiguo, tienen dos suelos repartidos por zonas (siempre una zona entera con el mismo).
- **Globales**: barro de granja (Mud) y grava (Pebble) nuevos, y más respaldos para césped, tierra, roca, pizarra, madera y chapa estriada. El terreno (montañas, campos) solo puede llevar un variant por material, así que ahí no puede haber variedad.

## Coches (World/Kit/CarBodies)

Los coches del tráfico, los aparcados, el tuyo, las patrullas y los taxis cambian su carrocería de piezas
por una **malla de verdad**. Se carga al arrancar el servidor (Ambient.publish, con pcall); de cada coche
solo se copian las piezas visibles de la carrocería con su **textura (TextureID) y su PBR
(SurfaceAppearance)** y los Decals que no son logos; fuera scripts, sonidos, asientos, textos, logos,
matrículas, atributos y etiquetas. **Sin marcas**: las piezas se renombran (CarShell, CarGlass, CarTrim),
cada carrocería tiene nombre y marca inventados (Aurea, Kestrel, Brisa, Toro, Valmar Motors) y lleva
dos placas con esa marca donde va el logo. Se gira (morro a −Z), se escala a la caja de nuestros coches
con los pasos de rueda sobre nuestras ruedas, y nuestras ruedas (que giran y viran) llevan el
**neumático de malla** del mismo pack. La caja de choque de siempre se queda invisible; luces, matrículas,
rótulos de policía y taxi pasan al morro, cola, costado y techo de la malla (medidos con rayos).
Aspecto: pintura con brillo (Reflectance 0,2, o el MaterialVariant de pintura de coche de Modern City si
está en MaterialService) y colores de coche de verdad; cristal oscuro (Reflectance 0,3, transparencia
0,35); molduras claras en cromo. En gráficos Bajo el tráfico usa la carrocería simple. Si no carga nada,
todo queda como antes. Prueba: `lune run scripts/test-carbodies.luau`.

| Id | Qué | Dónde / por qué no |
|---|---|---|
| 6418239833 | Sedan (oficial Roblox) | «Aurea Berlina»: tu coche, taxis, tráfico y aparcados (pintable). |
| 6418234850 | SUV (oficial) | «Kestrel Sierra»: tu todoterreno, tráfico y aparcados. |
| 6418225759 | Pickup Truck (oficial) | «Toro Faena»: tráfico, aparcados y tu todoterreno. |
| 6433316269 | Van (oficial) | «Brisa Carga»: furgoneta del tráfico y aparcada. |
| 6418230807 | Police Car (oficial) | «Valmar Patrulla»: las patrullas, rotuladas «POLICÍA» con nuestras sirenas. Sus textos «POLICE» fuera. |
| 9432856072 | Semi-Realistic Car Pack | 5 coches sin marca: «Aurea Serena» (berlina, también tuya y taxi), «Kestrel Ranchera» (SUV), «Toro Campo» (pick-up), «Brisa Sprint» (compacto), «Valmar Clásico». Fuera logos, matrículas, radio y los 2 coches con `Protector 2.0`. |
| 10935800149 | «Car Pack» (copia del anterior) | Mismo contenido que 9432856072: solo se carga si el original no carga. |
| 10897563593 | «Car» (copia del anterior) | Igual: segundo respaldo de 9432856072. |
| 97902046131324 | mesh pack (11 coches europeos) | Los 11, ligeros y con su textura (no se pintan): «Brisa Uno», «Toro Reparto», «Aurea Nube», «Kestrel Alba», «Aurea Paseo», «Valmar Mini», «Kestrel Vela», «Brisa Ola», «Toro Familia», «Toro Familia Plus», «Kestrel Lince». Aparcados (el doble de a menudo) y tráfico. |
| 4573650411 | Pack de policía (California) | Solo el sedán clásico, simplificado a sus 45 piezas más grandes: «Valmar Patrulla Clásica», 3 patrullas como mucho. Sin «CHP», sin marcas, sin sus 292 scripts. |
| 15418880736 | Berlina importada (ex-marca) | «Aurea Lumen», sin marca, simplificada a 40 piezas: solo 4 aparcadas (pesa 280 000 tris). |
| 18912826861 | Autobús urbano | **No**: 255 000 tris y 866 objetos por autobús, con el logo de una empresa real; nuestro autobús tiene puertas que se abren y asientos que se usan (BusService). |
| 16893586720 | Autocar (ex-marca) | **No**: 1 804 piezas de bloques (no malla) y no hay líneas interurbanas donde ponerlo. |
| 130974691456028 | Camión caja | **No**: trae puerta trasera (familia 3, docs/assets-usuario-4.md) y en el juego no hay camiones de reparto. |
| 18577576400 | «Realistic Car Pack (NOT MINE!)» | **No**: robado (lo dice el título), todo deportivos de marca y con `Protector 2.0`. |
| 131247677717086 | Realistic Tires | **No**: es UNA sola malla con 4 neumáticos apilados (no se puede separar en ruedas) y trae puertas traseras (familias 3 y 4). Los neumáticos de malla salen de cada pack de coches. |

## Armas, ejército y zonas de terror (World/UserArsenal + World/Kit/Pliegues)

No hay un sistema de armas nuevo: las armas siguen siendo las de `shared/Weapons` (WeaponService, Armerías, policía,
Cuartel). Los packs dan **solo mallas de exposición**: sin scripts, sin sonidos, sin GUIs, sin decals de sangre o de
marcas, con nombres genéricos (`Arma_Fusil_3`, «Pieza»). Las armas sacadas de Apex, Half-Life 2 o CoD que vienen
mezcladas, y cuchillos, granadas y lanzacohetes, se descartan por nombre. Todo lleva la etiqueta `CityDetail` (el nivel
gráfico Bajo lo esconde). Prueba: `lune run scripts/test-arsenal.luau`.

Las zonas de terror son **los Pliegues** de la Grieta (Cronos en «El piso 13»: «El piso 13 es un pliegue»): un
vestíbulo lejos de la ciudad con cuatro arcos. Se llega por la misión `Rareza_Piso13` (que ahora pasa en la Planta 13;
lugar `Piso13` con plan B en la biblioteca) o por una puerta vieja en el bosque junto al camping. Las criaturas no
hacen daño: si te alcanzan, te devuelven al vestíbulo.

| id | Qué es | Dónde está / por qué no |
|---|---|---|
| 101748452 | Pistola dorada de bloques («Ban Gun») | Armerías, comisarías, cuartel (pistola). Su script echaba del juego: borrado. |
| 117850698505269 | Pack de 4 armas | Armerías, comisarías, cuartel. Fuera los efectos de sangre/gore y los 59 scripts. |
| 100792423689137 | Pack de 4 armas de bloques | Igual. |
| 115493232746766 | Pack de ~80 armas | Igual; las de Apex/HL2/CoD fuera por nombre; el escudo antidisturbios, al armero de la comisaría. |
| 78033796632460 | Malla de fusil | Igual (su virus era un script/valor: borrados). |
| 14800241387 | ~40 mallas de armas | **No**: mallas sacadas de otro juego (*Bad Business*). |
| 1076538396 | ~60 mallas de armas | **No**: mallas sacadas de otro juego (*Counter-Strike*). |
| 546753609 | Kit P90 | Se carga, pero solo trae GUI y scripts: no aporta ninguna malla (se borra todo). |
| 9700798278 | 5 fusiles | Armerías, cuartel. Sus 70 sonidos (de Tarkov) fuera. |
| 480927087 | Mira de punto rojo | Armerías: dos en el panel de exposición y una montada sobre el fusil de arriba del armero. |
| 124581242124664 | Pistola láser-gato | Parque de atracciones: premio de la «Caseta de premios» (no dispara). |
| 114120925733217 | Mazo de goma | Parque de atracciones: junto al «martillo de fuerza». |
| 9763579280 | Bate de béisbol | Tiendas de deportes (sala `Local` con Shop = Deportes): bidón con 4 bates. |
| 11156149162 | Explosivo («Cee Four») | Comisarías: «PRUEBA 0451 · DESACTIVADO» sobre el mostrador. |
| 5849304432 | Casco militar | Cuartel del Ejército: en las literas y en la mesa del mapa. |
| 266515007 | Carro de combate | Museo: «Carro de combate antiguo», 22 studs, sin NINGUNA imagen (las 6 de la torreta no se podían revisar), sin asiento ni cañón que dispare, sin su nombre. |
| 14887624955 | Horror Pack | Pliegues: texturas de pared en el vestíbulo, su puerta (vuelta a Valmar y la puerta del bosque) y su árbol seco en Valmar Gris. Su Lighting y la cámara que se balancea, no. |
| 13583409363 | Escalera sin fin | Pliegues · Planta 13: «Bajar la escalera» al fondo del pasillo. Solo los últimos 70 studs (entera son 755 000 triángulos), sin decals ni números. |
| 10491752124 | Pasillo en silencio | Pliegues · Planta 13: aquí pasa «El piso 13» (exámenes, Cronos). |
| 13843689263 | Kit de pasillos amarillos | Pliegues · Pliegue Amarillo. |
| 17536656565 | Kit de piscinas | Pliegues · Pliegue Azul (sin el script de flotación). |
| 14062245022 | Criatura pálida | **El Pálido**, ronda el Pliegue Amarillo. Sin sus scripts (mataba), sonidos ni animaciones. |
| 9879827254 | Criatura aulladora | **El Aullador**, ronda el Pliegue Azul. Igual. |
| 522578234 | Cementerio | Pliegues · Valmar Gris (como mucho 90 studs de lado y 700 piezas). |
| 16845477360 | Noria abandonada | Pliegues · Valmar Gris («la feria que cerró antes de abrir»). |
| 891244647 | Cámara (personaje) | Teatro: grabando el escenario desde el pasillo. Sin la marca de la cámara. |
| 7105428424 | Muerto | **No**: 11 decals de sangre y un charco; ni como escena del crimen. |
| 13583409363 (repetido) | Escalera | Ver arriba. |
| 83730474928094 | Moveset de un anime | **No**: personaje de otra franquicia. |
| 95946642626421 | Generador de terreno | **No**: es un script. |
| 113349334619202, 107730003845316, 8043394685, 9342982592, 12061946559 | Animaciones | **No**: de otros creadores, no se pueden reproducir sin volver a subirlas. |
| 132859014 | Trozo de mapa (2013) | **No**: una bandera y un cartel sin uso. |
| 80741429 | Campo de fútbol (2012) | **No**: muy viejo (bloques, 60 decals) y la ciudad ya tiene estadio. |

## Calles, ciudad y edificios por fuera (World/CityAssets + World/CityAssetsKit)

Se cargan al arrancar el servidor y se limpian: **primero se borra todo script** (varios traen las
puertas traseras de la 4ª tanda) y luego se queda solo lo que se ve (piezas, mallas, SurfaceAppearance;
imágenes y luces solo donde hace falta). Fuera sonidos, GUIs con texto, ClickDetector, constraints,
NumberPose, PlaneConstraint, ParticleEmitter, atributos y etiquetas; fuera cualquier pieza o imagen con
marca real u otro juego. Nombres en español, anclado, a talla de Valmar y con topes de piezas. Lo que va
encima de una pieza de bloques que ya había la esconde (`BuildingShell`, sigue chocando; la malla lleva
`BuildingMesh`) y lo nuevo pequeño lleva `CityDetail`: en gráficos Bajo vuelve la ciudad de antes. Los
conos y vallas que salen despedidos al chocar llevan su malla soldada. Si algo no carga, no se hace.
Prueba: `lune run scripts/test-cityassets.luau`.

| Id | Qué | Dónde / por qué no |
|---|---|---|
| 13465440856 | Aire acondicionado Funiki | Aires de las fachadas de casas y pisos (malla encima de cada ACUnit de bloques, con la rejilla escondida). **Sin el logo ni el nombre Funiki**, sin mando ni sonidos. |
| 6795368713 | Casa con aires y ventiladores | Solo los aparatos de aire (sin Daikin/Panasonic/Mitsubishi: logos fuera, renombrados) para las fachadas. La casa y los ventiladores de techo no (5 491 piezas; los ventiladores son de interior). |
| 99479110531330 | Realistic city pack | Bocas de riego, buzones, quioscos de prensa y jardineras PBR en la acera junto a las farolas (solo donde cabe entero sobre la acera); AC_Unit en fachadas; Garbage_Bin, barril y barreras de hormigón en patios y la obra; sus edificios lejanos en el skyline. Fuera la lata «Coke», la máquina de parodia, las cajas de Black Mesa/Half-Life y el autobús/vagón (otros agentes). |
| 5411055653 | Construction Asset Pack | Conos y vallas de las obras de la calzada (malla encima, soldada: sigue saliendo despedida); andamios, contenedor y bidones en la obra del polígono. |
| 99043731526992 | Area51: pared de chapa | Vallado de chapa de la obra del polígono. Familia 3 de virus: sus scripts y el ParticleEmitter se borran antes de usarla; solo queda la pieza con su textura. |
| 11188629897 | Montacargas de obra | En la obra del polígono (una copia: pesa mucho). Quieto. |
| 133967929770771 | Cartel «Out of order» | Junto al montacargas, con el texto en español: «⚠ ASCENSOR FUERA DE SERVICIO · Disculpen las molestias». Sin el logo de Consult lift services; familia 2 de virus borrada. |
| 10396819700 | Palé PBR | Malla encima de los palés de bloques (supermercado…), y en patios y en la obra. |
| 113264079562085 | Factory Props | En los patios del polígono (12 naves): carretilla elevadora, transpaleta, palés con film, cajas, cerca del muelle de carga. |
| 9876129164 | Contenedor de basura | Patios del polígono, la obra, el desguace y los talleres. |
| 82042358715900 | Enchufe | Enchufe en la pared de 8 naves (por fuera). Tenía virus: sin scripts ni PlaneConstraint ya no hace nada. |
| 103449549978145 | Grafitis | Pintadas de los armarios eléctricos de la calle y una en la pared de cada nave. Solo los 24 permitidos: nada de CS:GO, Half-Life 2, Wu-Tang ni el cartel con teléfono. |
| 124865259344404 | Camión abandonado | Desguace en un patio del polígono (2). **Sin su textura** (marca International): oxidado de color propio. |
| 131247677717086 | Neumáticos | → Coches (lo usa el agente de coches). |
| 82136423205151 | Plataforma de exposición | En 3 talleres, con su foco. Quieta (sin la bisagra). |
| 2161748423 + 8386763665 | Vías de tren | Vías propias aparte del Cercanías y del metro: el apartadero de mercancías del polígono (con tope) y bajo la locomotora monumento. No se toca la vía del Cercanías. |
| 8380605189 | Train pack | Solo el vagón cerrado y el furgón, parados en el apartadero. Sin logos (CN, Pullman…), sin scripts ni asientos: no se conducen. El resto (locomotoras, coches de pasajeros) pesa demasiado. |
| 10887600145 | Locomotora de vapor de malla | Monumento en un parque, sobre su vía y una peana. |
| 18777387875 | Barbados Gates | Solo la puerta: en cada villa, corrida a un lado por dentro (abierta, no cierra el paso). Fuera las jardineras de 448 piezas y los scripts. |
| 898778590 | Pista de tenis | Una en un parque con hueco, con sus bancos (se puede sentar). |
| 75541553 | Portería | Malla encima de las porterías del campo de fútbol (la de bloques sigue chocando para el balón), con la red hacia fuera. |
| 120631576642977 | Armario de servidores | Dos en la esquina de cada oficina (salas Interior_Oficina) si está libre. |
| 13728551087 | Barcos | Pesqueros amarrados al muelle del puerto y fondeados mar adentro, barcas varadas y el barco hundido en la playa. Sin el buque de guerra. Decorado (sin asientos). |
| 79665094662717 | Japan City Pack | Sus 5 edificios en el skyline lejano «costa de enfrente», al sur, al otro lado del mar (no choca, carga persistente, Bajo lo esconde). Sin carreteras, farola ni palmeras. Virus (familias 3 y 4) borrado. |
| 111283915226740 | Casa polaca | Casa de campo en un hueco de Villaverde. Sin scripts (familia 5), sin agua ni nombres en polaco. |
| 15004077857 | Realistic road pack | Ya estaba: World/StreetDress (señales y alcantarillas). |
| 12527638598 | Roads | **No**: planos con líneas pintadas; las calles ya tienen sus marcas hechas a medida del tráfico y se duplicarían. |
| 16088161488 | Wessel road pack | **No**: texturas antiguas sin PBR, peores que los materiales que ya llevan calles y aceras. |
| 11347783499 | City Pack Realistic City | **No**: ciudad de 2010 de bloques y Decals, sin ninguna malla; haría las calles más «cutres». |
| 6430696462 | Túnel | **No**: ninguna carretera de Valmar atraviesa un monte; sería una caja de bloques en medio de la calle. |
| 139484418601989 | Skyscraper city | **No**: no trae edificios, solo un cielo con una foto real de Tokio (y virus) que chocaría con el cielo de día/noche. El skyline lejano se hace con 79665094662717 y el city pack. |
| 70353066 | Estadio de fútbol | **No**: 3 644 bloques y 1 812 Decals de 2012, NPCs que dejan sangre; ya hay estadios. |
| 1119962617 | Colegio | **No**: copia del mapa de otro juego (Roblox High School). |
| 26972564 | Búnker | **No**: 12 bloques de 2010, nada aprovechable. |

## Zonas de misión con los materiales exóticos del Mega Pack (World/MissionZones)

Los materiales del Mega Pack (15221806045) que no encajan en una ciudad ahora se usan FUERA de Valmar,
en sitios preparados para las misiones cooperativas. Antes no había ninguna mina ni cueva. El terreno
solo admite un variant por material, así que todo esto son piezas con su variant pieza a pieza (una
copia «U_Zona_…» en MaterialService). Si el Mega Pack no carga, las piezas se quedan con el material de
Roblox. Se usan 81 variants: los 14 asfaltos «Lab», 4 lavas, 3 rocas volcánicas, 11 de cueva y mina, 10
de otros planetas y cristales, 14 metales de ciencia ficción, 6 orgánicos y 11 de riscos.

| Sitio (etiqueta ZonaMision, atributo Zona) | Dónde | Qué lleva |
|---|---|---|
| Mina (Mina de los Montes) | Montaña de -800, -3250. La boca mira a la Carretera de los Montes. | Rampa de grava, boca con marco de madera y letrero, galería de 70 studs con vías, traviesas, entibado y lámparas. El terreno se vacía por dentro. Atributos `Entrada` y `Pie`. |
| CamaraLava | Dentro de la mina | Dos pozas de lava (Hot Lava, Flowing Lava) con luz y brillo, rocas volcánicas, vetas de mineral (Ore, Peacock Ore), una vagoneta y una valla de aviso «PELIGRO · LAVA» que choca. `Peligro = "Lava"`, `Danio = false`. |
| CuevaAlien | Al fondo de la segunda galería | Paredes de roca lunar y planetaria, cristales que brillan, rocas de azufre y de géiser, y restos de nave hechos con 10 metales de ciencia ficción, una caja y un chip. |
| Laboratorio | Dentro de la cueva alienígena | Suelo de baldosas con los 14 asfaltos «Lab» de colores, una mesa y una pantalla que brilla. |
| MuroOrganico | La pared del fondo, lo más hondo | La textura «Meat» teñida de morado como pared alienígena, bultos de hongo y cera, y charcos de ciénaga. Nada de sangre, calaveras, huesos ni piel humana. |
| CraterLava | Cumbre de la montaña de -2600, -3150 | Poza de lava con luz, anillo de lava y roca, rocas volcánicas y valla de aviso. `Peligro = "Lava"`. |
| Meteorito | Campo de -3100, -2900 | Cráter de tierra yerma, borde de roca agujereada, un meteorito que brilla y restos de chapa militar. |
| RiscosMontes | Laderas de las montañas de roca | Riscos con estratos, acantilados, roca cortada y roca ígnea. |

Cada sitio tiene los atributos `Zona` (id), `Nombre` (para enseñar), `Peligro` y `Danio`
(`false`: aún no hace daño). Lo decorativo lleva CityDetail, así que en gráficos Bajo se esconde. Hay
como mucho 24 luces. Prueba: `scripts/test-missionzones.luau`.

## Reemplazos (candidatos limpios para los «No» de arriba)

Revisados en un servidor de Roblox sin ninguna puerta trasera. Detalle y qué quitar: `docs/assets-reemplazos.md`.
Aún **no** están en el juego.

| Sustituye a | Hace falta | Elegido | Otras opciones |
|---|---|---|---|
| 114397068371248, 72475149726020 | Palmeras / tropical | 10562894034 | 7862261626, 9501994254 (por piezas) |
| 109211499509239 | Cerezo | 10586979345 | 15343255788, 10964163041 |
| 126164979250031 | Arbustos | Landscaping Pack 10840661513 (`Bushes`, Roblox) | 9522573337 |
| 116641210728889 | Hoguera | Landscaping Pack 10840661513 (`FirePit`, Roblox) | 8839325037, 9769594863 (sin su sonido) |
| 78188971759943 | Farol de piedra japonés | 9854052347 | 12521854808 (sin su sonido), 5242410723 |
| 11330013072 | Estatua de piedra | 4698399766 | 98862949352791 (escalar), 16920341663 |
| 18912826861 | Autobús urbano | 16358361587 (9 062 tris, sin logos) | 4128266372 (solo mallas) |
| 16893586720 | Autocar | 95641562400547 (sin la suciedad) | 1743965400 (solo mallas) |
| 130974691456028 | Camión caja | 4128265113 | 7170735914 |
| 131247677717086 | Neumático | 8448337398 | 17601139281, 5250689014 |
| 139484418601989 | Skyline lejano | 16524471626 (1 malla, 6 076 tris) | City Building Pack 6418277837 (Roblox) |
| 1119962617 | Colegio | 76558120171446 | 10905662931 (pesado) |
| 70353066, 80741429 | Estadio | 15569059562 | 112163108303427 (modular) |
| 12527638598, 16088161488 | Carreteras PBR | City Road Pack 6432233485 (Roblox) | 12790045445 (`MaterialVariant`) |
| — | Paisaje tropical / bosque | Forest Pack 6432306802 (Roblox) + 9501994254 | 17531535054, 8011666557 |

Descartados en esta búsqueda: 17430288419 (Greyhound), 116752155328441 (rótulos de marcas),
3098736664 (imágenes bloqueadas), 102795561208384 (origen dudoso), 5511084119 (mallas de pago de Unity).
