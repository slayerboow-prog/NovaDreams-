# Encargo del dueño: reconstrucción completa de los entornos submarinos (v2)

Resumen fiel del «súper mega prompt» de Sebastián (después de la v123). Referencias: `referencias-v2/ref_01..15.png`
(cañones rocosos con corales, arrecifes de colores, cuevas con luz cenital, bioluminiscencia, medusas gigantes,
ruinas/pirámide alienígena, kelp gigante). También `referencia-video/` y `referencia-submarina.png`. Captura de
cómo se ve ahora: `captura-dueno-v123-orilla.png`. Son referencias de estilo: no se copia nada de otros juegos.

## Lo que pide

1. **Arreglarlo de forma definitiva.** Nada de suelos planos con arena, hierbas y objetos de colores. Cambiar la
   dirección artística: composición, escala, iluminación, profundidad y distribución.
2. **Antes de tocar nada, auditar** cómo se construye hoy el mar. No borrar sistemas que funcionan, no rehacer el
   juego, no duplicar, nada de scripts decorativos desconectados. No dar por terminado solo por crear modelos:
   hay que comprobar cómo se ve desde la cámara real del jugador.
3. **Problemas a corregir:** el suelo ocupa toda la pantalla, horizonte plano, superficies vacías, vegetación de
   piezas sueltas, poca escala, sin profundidad entre primer plano y fondo, sin composición, no parece bajo el
   agua, objetos sin diseño, no parece un ecosistema alienígena, pocos puntos de interés, parece un escenario de
   prueba.
4. **Geografía real:** paredes, montañas sumergidas, acantilados, columnas, arcos, cuevas, grietas, pasadizos,
   barrancos, salientes; arrecifes grandes, corales ramificados/tubulares/abanico, columnas de coral, «árboles»
   submarinos, corales luminosos, túneles; relieve con llanuras, elevaciones, depresiones, jardines, entradas de
   cueva, cambios de material; estructuras destacadas (arcos gigantes, columnas minerales, cristales, ruinas,
   estructuras alienígenas). Espacios abiertos + zonas densas + puntos de interés claros.
5. **Vegetación de calidad** con muchas siluetas y escalas (pequeñas, medias, algas gigantes, hojas anchas,
   «medusas vegetales», filamentos luminosos, formas alienígenas), variando altura/forma/color/luz/densidad, en
   grupos, con balanceo suave no sincronizado y paleta controlada.
6. **Profundidad obligatoria en 5 planos:** primer plano, zona jugable, distancia media (siluetas grandes),
   fondo lejano (el mundo sigue), ambiente lejano. Sin abusar de la niebla; horizonte nunca vacío; el suelo no
   puede ocupar toda la imagen.
7. **Iluminación submarina** según planeta y profundidad: superficial azul/turquesa con rayos; profundo oscuro
   con puntos luminosos y contraste. Jerarquía de luz; no una luz por planta; niebla que deje orientarse.
8. **Bioluminiscencia y vida alienígena** con intención (zonas protagonistas y zonas oscuras); emisivo ≠ luz real;
   pocas criaturas bien puestas mejor que miles.
9. **Agua y movimiento:** partículas de varios tamaños y velocidades (no nieve), corrientes, burbujas solo con
   fuente, efectos por zona, sonido distinto por zona.
10. **Regiones:** A arrecife exterior, B jardín coralino, C caverna, D abismo, E ruinas sumergidas, con
    transiciones naturales.
11. **Cada planeta con identidad propia** (turquesa, abisal, cristal, coralino, ruinas, tóxico, bioluminiscente):
    diferencias reales de geometría, distribución, materiales, luz, fauna y actividades, no solo de color.
12. **Escala:** formaciones gigantes que hagan pequeño al jugador; tamaños variados; rutas transitables.
13. **Composición artística:** puntos focales, siluetas, caminos naturales, marcos, contrastes, zonas de descanso,
    algo que llame la atención al llegar; diseñado desde la cámara real del juego.
14. **Biblioteca modular** (rocas, paredes, arcos, corales, plantas, algas, cristales, organismos, formaciones
    gigantes, ruinas, puntos de interés), variaciones controladas, más detalle cerca y siluetas simples lejos.
15. **Técnica Roblox real:** sin shaders inventados ni propiedades falsas; recursos gratuitos/propios; control de
    piezas y colisiones (CanCollide/CanTouch/CanQuery), anclado, pocas luces, partículas limitadas,
    StreamingEnabled, carga por zonas; buen rendimiento.
16. **No romper la jugabilidad:** oxígeno, profundidad, misiones, inventario, puntos de aparición, zonas accesibles.
17. **Método por fases:** 1 auditoría · 2 diseño · 3 prototipo de UNA zona · 4 revisión desde la cámara real ·
    5 corrección · 6 integración · 7 optimización · 8 expansión a otras regiones y planetas. No hacer decenas de
    zonas sin validar una.
18. **16 criterios de aceptación** (no plano, varios planos de profundidad, grandes formaciones, vegetación
    variada, puntos de interés a varias distancias, atmósfera submarina, buena composición desde la cámara,
    regiones distintas, detalle sin saturar, recorrible, sistemas intactos, rendimiento, no depender solo de
    niebla/partículas, funciona en el juego y no solo en imagen, identidad propia, arquitectura reutilizable).
19. **Evidencias:** cambios, modelos, scripts, recursos, pendientes, optimización, criterios comprobados, pruebas
    hechas y pruebas que necesitan Roblox Studio. Si no se ha visto en el juego, no decir que se ha visto; dejar
    claro qué debe mirar el dueño. Una imagen conceptual no es prueba.
20. **Final:** los océanos son mundos importantes. Empezar por la auditoría; construir una única zona de referencia
    con la máxima calidad; comprobar, corregir y solo entonces extender. El juego se llama Heroes of History.
