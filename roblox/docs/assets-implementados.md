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
