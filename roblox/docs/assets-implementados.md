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
