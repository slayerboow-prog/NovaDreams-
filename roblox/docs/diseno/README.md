# Nova Life — Documento de diseño (GDD técnico)

> *"Una segunda vida dentro de Roblox."*

Este documento es la guía maestra del proyecto: qué construimos, cómo y en qué orden.
Cualquier sistema nuevo debe encajar aquí. Si cambia una decisión, se actualiza este documento.

## Resumen ejecutivo

**Nova Life** es un simulador de vida persistente para Roblox. Cada jugador vive una vida completa (bebé → mayor → legado) en una región de ~3,4 × 3,4 km con varias ciudades, distritos con identidad, profesiones jugables, educación con consecuencias, economía con decisiones, viviendas y negocios de jugadores y una población NPC que mantiene el mundo vivo.

Las cinco decisiones de arquitectura que hacen posible la escala:

1. **Servidor autoritativo + contenido en datos.** Profesiones, cursos, objetos y distritos son tablas. Crecer es añadir datos, no reescribir código.
2. **Mundo modular en casillas de 512 studs y parcelas estándar**, generado desde un layout. Primero en gris, después con arte, sin rehacer nunca el mapa.
3. **Propiedades y negocios instanciados.** Tu casa y tu empresa aparecen en una parcela libre de su tipo en cualquier servidor. Lo global (economía, mercado, familias) se comparte entre servidores.
4. **Un Motor de actividades con ~12 minijuegos reutilizables** que dan vida a más de 40 profesiones.
5. **Población en cuatro niveles** (datos → peatones en el cliente → tráfico → NPC de servicio) para simular una sociedad sin hundir el rendimiento.

## Índice

| Fase | Documento |
|---|---|
| 1 | [Arquitectura completa](01-arquitectura.md) |
| 2 | [Diseño del mapa](02-mapa.md) |
| 3 | [Sistemas principales, dependencias y dificultades](03-sistemas.md) |
| 4 | [Datos y persistencia](04-datos.md) |
| 5 | [Economía](05-economia.md) |
| 6 | [Edades y progresión](06-edades-progresion.md) |
| 7 | [Profesiones](07-profesiones.md) |
| 8 | [Educación](08-educacion.md) |
| 9 | [Viviendas](09-viviendas.md) |
| 10 | [Vehículos y transporte](10-vehiculos-transporte.md) |
| 11 | [NPCs, población y emergencias](11-npcs-poblacion.md) |
| 12 | [Multijugador, social y familias](12-multijugador-social.md) |
| 13 | [Interfaz](13-interfaz.md) |
| 14 | [Monetización](14-monetizacion.md) |
| 15 | [Optimización y seguridad](15-optimizacion.md) |
| 16 | [Roadmap de desarrollo](16-roadmap.md) |
| A1 | [Negocios, servicios públicos, mundo dinámico y personalización](A1-negocios-servicios-mundo.md) |

## Qué construimos primero y por qué

```
M0 Cimientos (datos, red, registros) ─► M1 Mundo en gris + grafo ─► M2 Vida adulta jugable (ALFA)
      ─► M3 Educación e infancia ─► M4 Ciudad viva (BETA) ─► M5 Familias ─► M6 Construcción y mercado
      ─► M7 Negocios ─► M8 Legado ─► expansión continua
```

Lo que obligaría a rehacer el proyecto si se hace mal (formato de los datos, red, layout del mundo, libro contable) va **primero**. Lo que más se ve (NPCs, arte, familias) va encima de eso.

## Decisiones abiertas (necesitan tu respuesta)

| # | Decisión | Recomendación |
|---|---|---|
| D1 | ¿Idiomas? | **Español + inglés desde el inicio.** La mayoría de jugadores de Roblox no hablan español, y traducir después es muy costoso |
| D2 | ¿Nacer como bebé obligatorio? | **No:** ofrecer nacer, empezar a los 18 o continuar el linaje (ver Fase 6) |
| D3 | ¿Arte? | Avanzar en gris hasta la alfa. Después contratar a 1–2 constructores o modeladores o comprar recursos |
| D4 | ¿Nombre definitivo? | "Nova Life" enlaza con NovaDreams. Conviene comprobar que no está muy usado en Roblox |
| D5 | ¿Jugadores por servidor? | Empezar con 30–40 y ajustar midiendo |
| D6 | Pareja y matrimonio | Solo como rol de hogar, sin mecánicas de romance, sujeto a las normas de Roblox (ver Fase 12) |
| D7 | ¿Qué pasa con la v0.1? | Sirvió de prototipo. En M0 se reorganiza según esta arquitectura, reaprovechando lo útil |
