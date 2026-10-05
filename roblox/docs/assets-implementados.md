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
