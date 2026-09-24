# Fase 2 — Diseño del mapa: Región Nova

## 2.1 Límites reales de Roblox que condicionan el mapa

| Límite | Consecuencia para el diseño |
|---|---|
| La precisión numérica empeora lejos del origen (0,0,0). Por encima de ~±10.000 studs aparecen temblores en físicas y cámara | El mundo se centra en el origen y se mantiene dentro de **±6.144 studs** |
| La memoria en móvil es limitada | **StreamingEnabled obligatorio.** El cliente solo carga lo que tiene cerca |
| Cada Part y cada script cuesta rendimiento | Edificios con mallas reutilizadas, interiores cargados bajo demanda y un número de piezas por casilla limitado |
| Pocos jugadores por servidor (ver Fase 12) | Mapa grande + pocos jugadores = mundo vacío. Los NPCs (Fase 11) y la densidad por zonas lo compensan |
| Construir el arte a mano es lo más caro del proyecto | El mapa se genera primero en **"gris"** (volúmenes simples) desde datos. Luego se sustituye edificio a edificio por arte final |

Escala: 1 stud ≈ 0,28 m. Un personaje adulto mide ~5 studs.

## 2.2 La cuadrícula maestra

- **Casilla (tile) = 512 × 512 studs** (~143 m). Es la unidad de construcción y ampliación del mundo.
- **Región = 24 × 24 casillas = 12.288 × 12.288 studs** (~3,4 km × 3,4 km), centrada en el origen.
- Las calles encajan en una **subcuadrícula de 32 studs**. Una manzana típica mide 128 o 256 studs.
- Las **parcelas son de tamaños estándar**. Esta es la decisión más importante del mapa, porque permite casas instanciadas, construcción, negocios y mercado inmobiliario sin casos especiales:

| Tipo de parcela | Tamaño (studs) | Uso |
|---|---|---|
| P-S | 48 × 48 | Casa pequeña, adosado |
| P-M | 64 × 80 | Casa familiar |
| P-L | 96 × 112 | Chalet |
| P-XL | 144 × 160 | Mansión |
| P-FARM | 256 × 256 | Granja (rural) |
| C-S / C-M / C-L | 48×64 / 80×96 / 128×160 | Locales comerciales (tienda, restaurante, supermercado) |
| T-APT | Portal de edificio | Edificios de apartamentos (interiores instanciados) |

Cada casilla es un `Model` independiente (`World/Districts/<Distrito>/<Casilla>`). Añadir territorio significa añadir casillas nuevas en zonas reservadas, sin tocar las existentes.

## 2.3 Mapa general

```
  N ↑                     (cada carácter ≈ 1 casilla de 512 studs)
      A   B   C   D   E   F   G   H   I   J   K   L   M   N   O   P   Q   R   S   T   U   V   W   X
  1   ~~~~~~~~ MONTES (límite visual) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  2   ·   VALLE VERDE (rural) ········  ·   NOVA NORTE (suburbios) ······  ·   [RESERVA: AEROPUERTO]
  3   ·   granjas · campos · establos   ·   casas unifamiliares · colegios ·   ·
  4   ·   ┌ VILLAVERDE ┐ (pueblo)       ·   centro comercial · parque     ·   ·
  5   ·   └ plaza, iglesia, tienda ┘    ═══════════════ A-1 AUTOPISTA (circunvalación) ════════════
  6   ·   ·   ·   ·   ·   ·   ·   ·   ║   ·   ·   ·   ·   ·   ·   ·   ·   ║  DISTRITO UNIVERSITARIO
  7   ═══ A-2 ══════════════════════ ║  SAN ROQUE      CENTRO           ║  campus · biblioteca
  8   ·   POLÍGONO INDUSTRIAL        ║  (económico)    rascacielos     ║  residencias · estadio
  9   ·   fábricas · almacenes       ║  pisos baratos  bancos · tiendas║  ─────────────────────
 10   ·   talleres · obras           ║  mercado        ayuntamiento    ║  DISTRITO EMPRESARIAL
 11   ·   estación de mercancías     ║  comercios      estación central║  oficinas · hoteles
 12   ·   ·   ·   ·   ·   ·   ·   ·  ║  ·   ·   ·   ·  ·   ·   ·   ·   ║  ·   ·   ·   ·   ·
 13   ·   PUERTO DE CARGA            ║  LOS PINOS (residencial)        ║  COLINAS DEL MIRADOR
 14   ·   grúas · contenedores       ║  casas · colegio · instituto    ║  (lujo, en la colina)
 15   ·   ·   ·   ·   ·   ·   ·   ·  ║  hospital · parque · súper      ║  mansiones · club de golf
 16   ═══════════════════════════════╩═════ A-1 ═══════════════════════╩═══════════════════════════
 17   ·   ·   PLAYA NOVA · paseo marítimo · hoteles · discotecas · puerto deportivo · chiringuitos
 18   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ MAR ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 19-24 ~~~~ mar abierto (agua de Terrain, barcos, futura isla vía teletransporte) ~~~~~~~~~~~~~~~
```

La costa al sur y los montes al norte cierran el mundo de forma natural, sin muros invisibles.

## 2.4 Ciudades y distritos

**Ciudad principal: Nova City.** Pueblo rural: **Villaverde.** Zona costera: **Playa Nova.**

| Distrito | Identidad | Contenido clave | Tipo de vida | Fase |
|---|---|---|---|---|
| **Centro** | Edificios altos, tráfico, neón de noche | Oficinas, bancos, ayuntamiento, centro comercial, cine, restaurantes, apartamentos caros, **estación central**, comisaría central | Urbanita, profesional | M1 |
| **Los Pinos** (residencial) | Árboles, familias, tranquilo | Casas P-S/P-M, colegio, instituto, **hospital**, parque, supermercado, gimnasio, **bomberos** | Familia, clase media | M1 |
| **San Roque** (económico) | Denso, colorido, callejero | Pisos baratos, habitaciones en alquiler, mercado, pequeños comercios, taller, gasolinera | Empezar desde abajo | M1 |
| **Distrito Empresarial** | Cristal, orden, ejecutivos | Rascacielos de oficinas (empresas de jugadores), hoteles, restaurantes caros, concesionario premium | Empresario, ejecutivo | M4 |
| **Distrito Universitario** | Campus, juventud | Universidad (facultades), FP, biblioteca, residencias, pisos de estudiantes, estadio, cafeterías | Estudiante | M3 |
| **Colinas del Mirador** (lujo) | Vistas al mar, verjas, silencio | Mansiones P-XL, club de golf, restaurante exclusivo, concesionario de lujo, helipuerto | Rico, famoso | M5 |
| **Polígono Industrial + Puerto** | Grúas, camiones, humo | Fábricas, almacenes, obras, talleres, desguace, puerto de carga, estación de mercancías | Obrero, camionero, industrial | M5 |
| **Playa Nova** (costa) | Verano, ocio, noche | Paseo marítimo, hoteles, discotecas, puerto deportivo, chiringuitos, deportes de agua | Ocio, turismo, hostelería | M5 |
| **Nova Norte** (suburbios) | Chalets, jardines, centros comerciales | Parcelas P-L, colegios, centro comercial grande, parque deportivo | Familia acomodada | M6 |
| **Valle Verde + Villaverde** (rural) | Campos, animales, calma | Granjas P-FARM, terrenos baratos, pueblo con plaza, veterinario, cooperativa agrícola | Agricultor, vida sencilla | M6 |
| **Reservas de expansión** | — | Aeropuerto (NE), parque natural, segundo barrio residencial | — | Futuro |

## 2.5 Red de carreteras

Jerarquía (todas encajan en la subcuadrícula de 32 studs):

| Tipo | Carriles | Velocidad | Función |
|---|---|---|---|
| **Autopista A-1** (circunvalación) + **A-2** (a Villaverde y polígono) | 2+2 con mediana | Alta | Conectar distritos rápido |
| **Avenidas** | 2+2 | Media | Ejes principales de cada distrito |
| **Calles** | 1+1 | Baja | Barrios |
| **Caminos rurales** | 1+1 estrecho | Baja | Valle Verde |

**El grafo de carreteras es un dato, no un dibujo.** Cada tramo se define como nodos y carriles en `Registry/World/RoadGraph`. Este grafo alimenta a la vez:
- La **generación** del asfalto, las aceras y las señales
- El **GPS** del teléfono (ruta más corta)
- El **tráfico NPC** y los peatones (grafo de aceras derivado)
- Las **líneas de autobús** y el taxi
- El **minimapa**

Por eso el grafo debe existir antes que los NPCs y los vehículos: es una dependencia crítica.

## 2.6 Transporte público

| Medio | Recorrido | Implementación |
|---|---|---|
| **Tren ligero L1** | Villaverde → Polígono → San Roque → **Centro** → Universitario → Nova Norte | Tren movido por código sobre raíles (sin físicas). Los pasajeros viajan sentados en asientos soldados al tren |
| **Autobús** L2, L3, L4 | Circuitos por distritos | Conducidos por NPC por el grafo, o por jugadores con la profesión de conductor de autobús |
| **Taxi** | Cualquier punto | Taxista jugador (profesión) o taxi NPC que te "teletransporta" con una escena corta |
| **Ferry** (futuro) | Puerto → Isla Resort | Teletransporte a otro place |

Estaciones: Central (Centro), una por distrito en L1, y paradas de autobús cada ~2 manzanas.

## 2.7 Interiores

- **Edificios pequeños** (tiendas, casas): el interior está dentro del propio edificio.
- **Edificios grandes** (hospital, universidad, centro comercial): el interior forma parte del modelo, con partes internas que se cargan por streaming solo al acercarse.
- **Apartamentos** (torres de muchas plantas): al usar la puerta del portal, el jugador pasa a su **interior instanciado**, colocado en una zona oculta bajo el mapa. Así una sola torre puede tener apartamentos ilimitados sin cientos de interiores reales. El mismo sistema sirve para hoteles y residencias.

## 2.8 Cómo se construye el mapa (flujo de producción)

1. **Layout como datos:** distritos, casillas, calles, parcelas y ubicación de cada servicio (`Registry/World/*`).
2. **Generador en gris:** el servidor, o un plugin en Studio, genera terreno, carreteras, aceras y volúmenes grises de cada edificio con su nombre. El juego ya es 100% jugable en gris.
3. **Arte:** los artistas construyen cada edificio en Studio como **Package** (`assets/`) respetando la huella de su parcela y los puntos de interacción marcados (puertas, mostradores, camas…).
4. **Sustitución:** el edificio gris se cambia por el Package final sin tocar ningún sistema, porque los sistemas solo buscan etiquetas y puntos de interacción.

Así se puede lanzar pronto con partes en gris, se trabaja el arte en paralelo al código y nunca hace falta rehacer el mapa.

## 2.9 Terrenos urbanizables

- Cada distrito reserva **parcelas vacías** de cada tamaño (señalizadas con carteles de "SE VENDE").
- Son la base del mercado inmobiliario (Fase 9): se compran vacías, se construye encima y se venden o alquilan.
- El precio depende del distrito (el suelo de Colinas del Mirador vale ~10 veces lo que vale en San Roque) y de la demanda global (Fase 5).
