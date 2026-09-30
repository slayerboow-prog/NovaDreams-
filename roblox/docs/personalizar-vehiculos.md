# Personalizar vehículos («Taller de Tobías»)

Propuesta de diseño para que cada vehículo de Real Life Simulator esté **hecho por piezas** y cada jugador lo deje a su gusto: pintura, llantas, alerón, parachoques, lunas tintadas, neón, matrícula…

> **Estado:** fase 0 hecha (catálogo, validación y «aplicar al modelo» en `src/shared/`, con su prueba). Todavía **no está conectado** al juego: el taller está apagado (`VehicleParts.Enabled = false`) y ningún servicio lo usa. Ver «C6. Plan por fases».
> **Petición del dueño:** «Estaría muy bien que los vehículos estén hechos por partes para poder implementar llantas diferentes y modificar el coche a gusto del usuario para que sea único.»

---

## Parte A · Para el dueño (en pocas palabras)

### A1. La idea

- Cada vehículo tuyo (coche, moto, bici, patinete, monopatín y, más adelante, la lancha) tendrá **huecos**: pintura, llantas, alerón, parachoques, luces, matrícula… En cada hueco eliges una pieza.
- Las piezas son **solo aspecto**. Tu coche corre, frena y gira igual que cualquier otro. Tampoco choca distinto: las piezas nuevas no tienen colisión. **Nadie gana carreras por pagar.**
- Se personaliza en el **Taller de Tobías**, un taller pegado a cada **gasolinera** (Tobías es el mecánico que ya sale en la historia: «Ve al taller de Tobías (gasolinera)»). Entras, ves tu coche en 3D, lo giras, pruebas piezas **gratis** y solo pagas lo que te quedas.
- Todo se paga con **dinero del juego** (el de trabajar). **Nada se vende por Robux.** El pase de temporada puede regalar piezas exclusivas (como el coche legendario «Faro de Valmar»), pero son de estilo, no de potencia.
- Lo que haces se **guarda**. Cuando sacas tu coche, sale tal cual lo dejaste, y **todos los jugadores lo ven igual**.

### A2. Qué se podrá cambiar (primera versión y después)

| Hueco | Qué es | ¿Primera versión? |
|---|---|---|
| Pintura principal | El color de la carrocería | ✅ |
| Acabado | Brillante, metalizado, mate o perlado | ✅ |
| Pintura secundaria | Retrovisores, franjas, techo (en la moto: asiento y ribetes) | ✅ |
| Llantas (rines) | El dibujo de la rueda y su color | ✅ |
| Lunas tintadas | Ventanillas más oscuras (el parabrisas, nunca) | ✅ |
| Matrícula personalizada | Tu texto, hasta 8 letras y números (con filtro) | ✅ |
| Alerón | Labio, deportivo o GT | ✅ |
| Neón bajo el coche | Luz de color debajo, de noche | ✅ |
| Neumáticos | Normal, letras blancas o banda blanca clásica | Después |
| Parachoques delantero y trasero | De serie o deportivo (en el todoterreno, defensa) | Después |
| Faldones laterales | Taloneras deportivas | Después |
| Capó | Liso, con toma de aire o con franjas | Después |
| Faros | Blanco normal, xenón (azulado) o ámbar | Después (cuando acaben los arreglos de luces) |
| Escape | Simple, doble o deportivo | Después |
| Vinilos / pegatinas | Franjas, llamas, números de carreras… | Después |
| Carrocería | Berlina, compacto, todoterreno y el descapotable legendario | Después |
| Suspensión (altura) | Un poco más bajo, solo de aspecto | Más adelante |
| Bocina | Sonido de la bocina | Cuando exista la bocina |

La moto, la bici, el patinete y el monopatín tienen menos huecos (color, llantas, algún accesorio como el baúl de la moto o la cesta de la bici). Los vehículos de trabajo (autobús, camión de la basura, patrulla, bomberos), los de alquiler y los coches de la calle **no** se personalizan.

### A3. Precios (idea)

- Un trabajo normal paga 25–45 € por tarea; un coche cuesta 9.000 €.
- **Pintar** cuesta cada vez (es mano de obra): 250 € brillante, hasta 850 € perlado.
- **Las piezas se compran una vez** y se quedan en tu garaje: puedes cambiar entre las tuyas gratis.
- Un coche «de ensueño» con todo cuesta unos 8.000–10.000 €, casi como otro coche: es algo para ir mejorando poco a poco, y saca dinero de la economía (lo que llamamos un «sumidero»).
- En bici y patinete todo cuesta menos (×0,3); en la moto, ×0,6.

### A4. Qué decides tú (preguntas abiertas)

> **Decidido por el dueño:** (1) «Vida nueva» **borra** las piezas compradas (las del pase, en `Cosmetics`, se quedan); (2) **paleta fija de 20 colores** + 4 acabados (brillante, metalizado, mate, perlado); (3) **ningún tuning**: las piezas son solo aspecto, sin ningún cambio de prestaciones.

1. **¿«Vida nueva» borra las piezas compradas?** Hoy «Vida nueva» borra los vehículos comprados, así que lo lógico es que se borren también sus piezas. Las del pase de temporada **no** se borran nunca (igual que ahora).
2. **¿Pintura a medida (cualquier color) o solo una paleta de 20?** Recomiendo empezar con la paleta: se ve mejor y es más fácil de controlar.
3. **¿Algún «tuning» de rendimiento?** Recomiendo **ninguno**. Si algún día lo hay, que sea muy pequeño, con tope y ganado jugando, nunca comprado.
4. Hay dos documentos de diseño antiguos que dicen otra cosa: `docs/diseno/10-vehiculos-transporte.md` («matrícula personalizada vía monetización») y `docs/diseno/14-monetizacion.md` («coches premium» por Robux). Chocan con tu regla de «nada de pagar para ganar, solo cosméticos del pase». Conviene corregirlos.

---

## Parte B · Cómo están hechos hoy los vehículos (lo que he estudiado)

| Dónde | Qué hay |
|---|---|
| `src/server/World/Kit/Rides.luau` | Construye en código cada modelo (`Rides.build(kind, parent, cf, color)`): monopatín, patinete, bici, moto (tipo scooter, con pata de cabra `Kickstand`), coche, autobús, camión, patrulla, bomberos, lancha y Gaviota. Un solo color (`paint`) para todo lo pintado. `Rides.prepare` añade la base invisible `Chassis` (tamaño de `Rides.Spec[kind].Size`), el `DriverSeat`, los `RideSeat` de pasajeros y **suelda con WeldConstraint todas las `BasePart` del modelo al chasis** (`Massless = true`, `Anchored = false`; guarda `CanCollide` en el atributo `Collide`). |
| `src/server/World/Kit/CarModel.luau` | El coche detallado (el tuyo, los aparcados y el tráfico). Tres carrocerías (`Berlina`, `Compacto`, `Todoterreno`, tabla `SHAPES`), versión `Lite` para los aparcados. Piezas con nombre: `Body`, `Nose`, `Roof`, `PillarC`, `Mirror` (color de la pintura), `BumperFront`/`BumperRear`, `SideSkirt`, `Grille`, `Exhaust`, `PlateFront`/`PlateRear` (texto con `Builder.sign`), `Headlight`/`HeadlightRight`/`DRL`/`Taillight`/`Indicator*`/`ThirdBrake`, `Windshield`/`RearWindow`/`SideWindow*`, `Wheel`/`Rim`/`Hub`/`Spoke`. El coche del jugador siempre sale como `Berlina` y con matrícula **al azar** cada vez (`Rides.coche`). |
| `src/shared/Gameplay.luau` | `Gameplay.Vehicles` (precio, velocidad, etapa, carnet), `Gameplay.Tuning` (aceleración, frenada, giro…), combustible. Las piezas **no tocan** estas tablas. |
| `src/server/Services/VehicleService.luau` | Datos: `data.Vehicles = { Coche = true, … }`, `data.Fuel[kind]`, `data.Odometer[kind]`. `mount` → `Rides.build(kind, nil, cf, paint)` → `Rides.prepare` → `addHeadlight` → `setupSeats`. Gancho `VehicleService.PaintFor(player, kind)` (pase de temporada) solo si no es alquilado ni examen. `launchAt` (barcos) ya acepta `opts.Decorate(model)` **antes** de `Rides.prepare`: es exactamente el patrón que necesitamos. Detector de saltos imposibles con la velocidad de `Gameplay.Vehicles`. |
| `src/server/Services/BoatService.luau` + `src/shared/Boats.luau` | `data.Boats`, puerto deportivo, nombre en la popa de la Gaviota con `Decorate`. |
| `src/server/Services/DataService.luau` | `DEFAULT_DATA` + `reconcile` (añade campos nuevos a partidas viejas). `newLife` conserva `BattlePass`, `Cosmetics`, `SeasonArchive`… pero **no** `Vehicles`. |
| Pase de temporada (`src/shared/BattlePass/Season1.luau`, `Catalog.luau`, `BattlePassRewardService.luau`) | Recompensas `VehicleSkin` (color para un tipo de vehículo; `GrantsBase` regala también el vehículo): Patinete Brisa Marina (nv 5), Bici Verde Villaverde (nv 15), Moto Brisa de Playa Dorada (nv 15), y el legendario **Descapotable «Faro de Valmar»** (nv 50 premium, `S1_P50_Car`, `Color` perla + `Trim` oro). Se equipa una por tipo en `data.Cosmetics.Equipped.VehicleSkin[kind]`; `paintFor` devuelve solo el `Color`. **Hoy el «descapotable» es una berlina pintada de perla: el `Trim` dorado y el `Material` no se usan.** Vistas previas 3D en `ReplicatedStorage.BattlePassPreviews` (`BattlePassService.buildPreviews`) y `UI/BattlePassPreview` (ViewportFrame que se gira arrastrando). |
| Tiendas | No hay concesionario, ni taller, ni tuning. Los vehículos se compran desde el menú «🚲 Vehículos» (`Controllers/Vehicles`). Hay **gasolineras** (`Civic.gasStation`, 7 en la región según `Region.luau`, surtidores con tag `FuelPump`; se pueden comprar como negocio en `BusinessService`). El mecánico **Tobías** (`Cast.Tomas`) ya existe en la historia y su «taller» está en la gasolinera. |
| Interfaz | `UI/Theme.luau`: paneles azul marino `Panel (10,22,52)`, borde cian `Stroke (150,210,255)`, `Accent (60,160,255)`, `Money (110,230,120)`, fuentes Gotham. `Dialog.window`, `BattlePassLayout` (medidas para móvil y PC, probado en 10 pantallas). |

Nombres que **otros sistemas buscan por nombre** y que las piezas nuevas no deben usar ni borrar: `Chassis`, `DriverSeat`, `RideSeat`, `Body` (PoliceService, VehicleService), `Headlight` (luz de verdad y tráfico), `HeadlightRight`, `Taillight`, `ThirdBrake`, `Indicator*`, `Kickstand`/`StandWeld`, `SirenBlue`/`SirenRed`, `NamePlate`, `BusDoor`, `PassengerSeat`.

---

## Parte C · Diseño técnico (para quien lo programe)

### C1. Piezas y huecos: cómo se reestructura cada modelo

**Principio:** el modelo base (`Rides.build`) no cambia de forma. La personalización es una **capa cosmética** que se aplica sobre el modelo recién construido y **antes** de `Rides.prepare`, así `prepare` la suelda al chasis como todo lo demás. Física, asientos, conducción, colisión y luces siguen siendo los de siempre.

Reglas de toda pieza añadida:

- Se crea con las propiedades de `Builder.decor`: `CanCollide = false`, `CanQuery = false`, `CanTouch = false`, sin sombra si es pequeña. Tras `prepare` queda `Massless = true`.
- Nombre con prefijo `Mod_` (`Mod_Spoiler`, `Mod_RimSpoke`…) y atributos `Mod = true`, `Slot = "Spoiler"`. Nunca usa un nombre reservado (lista de arriba).
- Cabe dentro de la caja del chasis (`Rides.Spec[kind].Size`) más un margen de 0,3 studs (los parachoques deportivos y el alerón no sobresalen de la caja de choque).
- Presupuesto de piezas por vehículo: **coche ≤ 70 piezas extra**, moto ≤ 30, bici/patinete/monopatín ≤ 20 (móvil primero).

Las piezas de serie que se **reemplazan** (llantas, parachoques…) se destruyen en el modelo recién construido antes de añadir las nuevas; las que solo se **recolorean** (carrocería, lunas, matrícula) se modifican en su sitio. Como siempre se aplica sobre un modelo nuevo, «quitar una pieza» = volver a construir sin ella.

#### Cómo se encuentran las piezas de serie (fase 0, sin tocar Rides/CarModel)

Por **nombre** y, cuando hace falta, por **posición** (izquierda/derecha, delante/detrás respecto al `cf` de construcción). Una tabla por tipo en el módulo compartido:

```lua
-- src/shared/VehicleParts.luau (datos)
Zones.Coche = {
	Primary   = { "Body", "Nose", "Roof", "PillarC", "Mirror" },
	Secondary = { "Mirror", "RoofRail" },          -- (si se elige secundaria, pisa a Primary)
	Glass     = { "RearWindow", "SideWindow", "SideWindowFront", "SideWindowRear" }, -- tinte (Windshield no)
	Rim       = { "Rim", "Spoke", "Hub" },          -- se sustituyen por el diseño elegido
	Tire      = { "Wheel" },
	BumperF   = { "BumperFront" }, BumperR = { "BumperRear" },
	Skirts    = { "SideSkirt" }, Exhaust = { "Exhaust" },
	PlateRear = { "PlateRear" }, PlateFront = { "PlateFront" },
	Lights    = { "Headlight", "HeadlightRight", "DRL" },  -- solo color, el nombre no cambia
}
Zones.Moto = { Primary = { "Body", "Tail", "Shield", "FenderFront", "Stem" }, Secondary = { "SeatPiping", "SidePanelLine" }, Rim = { "Rim", "Hub" }, Plate = { "Plate" }, Exhaust = { "Exhaust", "ExhaustTip" } }
Zones.Bici = { Primary = { "TopTube", "DownTube", "SeatTube", "HeadTube", "ChainStay", "SeatStay", "FenderRear", "FenderFront" }, Rim = { "Rim" }, Secondary = { "Seat", "Grip" } }
Zones.Patinete = { Primary = { "Battery", "DeckTrim", "FenderRear", "FenderFront", "Stem" }, Rim = { "Rim" } }
Zones.Monopatin = { Primary = { "Deck", "Kick" }, Vinyl = { "Graphic" }, Tire = { "Wheel" }, Secondary = { "Bushing" } }
```

**Fase 2 (cuando acaben los agentes de vehículos):** `CarModel.build` y `Rides` ponen el atributo `Zone = "Primary"` (etc.) a cada pieza al crearla. Así la capa no depende de nombres y un cambio de geometría no la rompe. La prueba comprueba que las dos formas (nombre y atributo) coinciden.

#### Puntos de anclaje por modelo base

Coordenadas locales del vehículo (las de `Rides.build`: centro a ras de suelo, morro hacia −Z). Salen de `CarModel` (W 6,2 × L 13,5; ruedas r = 1,3 en x = ±2,8, z = ±4,3; cintura/capó a y = 3,3). Se guardan en `VehicleParts.Anchors[kind][variant]`, y la prueba las contrasta con el modelo construido (si alguien mueve una rueda, la prueba falla).

| Ancla | Berlina | Compacto | Todoterreno | Para qué |
|---|---|---|---|---|
| `WheelFL/FR/RL/RR` | (±2,8, 1,3, ∓4,3) | igual | igual | Llantas, neumáticos |
| `Trunk` (tapa trasera) | (0, 3,3, 5,5) | (0, 3,3, 5,8)* | — | Alerón (en el todoterreno: baca en `Roof`) |
| `Roof` | (0, 5,3, 0,8) | (0, 5,4, 1,75) | (0, 6,1, 1,6) | Baca, aleta de tiburón |
| `Hood` | (0, 3,3, −4,6) | (0, 3,3, −4,7) | (0, 3,5, −4,9) | Toma de aire, franjas de capó |
| `BumperF` / `BumperR` | (0, 1,35, ∓6,55) | igual | igual | Parachoques |
| `SkirtL/R` | (±3,12, 1,25, 0) | igual | igual | Faldones |
| `Exhaust` | (−1,8, 1,0, 6,85) | igual | igual | Escape (simple / doble / deportivo) |
| `PlateRear` / `PlateFront` | (0, 2,2, 6,77) / (0, 1,4, −6,87) | igual | igual | Matrícula |
| `Under` | (0, 0,35, 0), 5,6 × 12 | igual | igual | Neón bajo |
| `SideL/R` (vinilo) | caras x = ±3,11, y 1,3–3,3, z −5,5…5,5 | | | Vinilos laterales |

\* El compacto tiene el techo hasta z = 4,6: el alerón «GT» no cabe; solo «Labio».

Moto (scooter): ruedas (0, 1, ±2,3) r = 1; `TopCase` (baúl) (0, 2,9, 2,3); `Screen` (parabrisas alto) sobre `ShieldTrim` (0, 3,6, −2,1); `Plate` (0, 1,55, 2,68); `Exhaust` de (0,6, 0,9, −0,2) a (0,65, 1,2, 1,9). Bici: ruedas (0, 1,3, ±1,8) r = 1,3; `Basket` delante del manillar (0, 3,0, −1,9). Patinete: ruedas (0, 0,38, ±1,5); `Stem` para pegatina. Monopatín: `Graphic` (vinilo de abajo), ruedas en (±0,55, 0,22, ±1,3).

#### Huecos por tipo de vehículo

| Hueco (`Slot`) | Coche | Moto | Bici | Patinete | Monopatín | Lancha / Gaviota |
|---|---|---|---|---|---|---|
| `Paint` (+ `Finish`) | ✅ | ✅ | ✅ | ✅ | ✅ (tabla) | Fase 3 (franja / casco) |
| `Paint2` (secundaria) | ✅ | ✅ (asiento/ribete) | ✅ (sillín/puños) | — | ✅ (bujes) | Fase 3 (cojines) |
| `Rims` (+ `RimColor`) | ✅ 12 diseños | ✅ 4 | ✅ color | ✅ color | ✅ color de ruedas | — |
| `Tires` | ✅ | — | — | — | — | — |
| `Tint` (0–3) | ✅ | — | — | — | — | — |
| `Plate` (texto) | ✅ | ✅ | — | — | — | nombre en la popa (ya existe en la Gaviota) |
| `Spoiler` | ✅ (no todoterreno) | — | — | — | — | — |
| `Roof` (baca / aleta) | ✅ | — | — | — | — | — |
| `BumperF` / `BumperR` | ✅ 2 por carrocería | — | — | — | — | — |
| `Skirts` | ✅ | — | — | — | — | — |
| `Hood` | ✅ | — | — | — | — | — |
| `Lights` (color de faros) | ✅ | ✅ | — | — | — | — |
| `Exhaust` | ✅ | ✅ | — | — | — | — |
| `Vinyl` (+ color) | ✅ | ✅ | — | ✅ | ✅ (dibujo) | — |
| `Neon` | ✅ | ✅ | — | ✅ | — | Fase 3 (luz bajo el agua) |
| `Accessory` | — | baúl / parabrisas alto | cesta / timbre | — | — | — |
| `Body` (carrocería) | Berlina / Compacto / Todoterreno / Descapotable★ | — | — | — | — | — |
| `Ride` (altura, 0/−1/−2) | Fase 3 | — | — | — | — | — |
| `Horn` | cuando exista la bocina | idem | — | — | — | — |

★ Legendaria, del pase.

Qué hace cada hueco en el modelo:

- **Paint / Finish:** `Color` de las zonas; el acabado cambia `Material`/`Reflectance`: Brillante = SmoothPlastic 0,08 (lo de hoy), Metalizado = SmoothPlastic 0,25, Mate = SmoothPlastic 0, Perlado = SmoothPlastic 0,35 con el color aclarado un 8 %, Cromo (solo pase/fichas) = Foil.
- **Rims:** se destruyen `Rim`/`Spoke`/`Hub` de cada rueda y se construye el diseño elegido centrado en el ancla (≤ 8 piezas por rueda: disco + radios + buje). `RimColor`: Cromo, Negro, Grafito, Bronce, Blanco u «color de la carrocería».
- **Tires:** color/grosor visual de `Wheel` y un aro blanco (`Mod_Whitewall`). El tamaño de la rueda no cambia.
- **Tint:** `Transparency` de los cristales de 0,35 (de serie) → 0,25 / 0,15 / 0,08 y color más oscuro. **El parabrisas no se tinta** (se tiene que ver al conductor).
- **Plate:** texto en `PlateRear` (y `PlateFront`) con `Builder.sign` (mismo estilo que hoy).
- **Lights:** color de `Headlight`/`HeadlightRight`/`DRL` y atributo del modelo `LightColor` para que quien cree la luz de verdad (hoy `addHeadlight`) use ese color. **No se renombra nada.**
- **Neon:** una `Mod_Neon` fina bajo el coche (Neon, transparente) + atributo `NeonColor`. El cliente la enciende solo de noche o con luces, y solo a menos de ~150 studs (una sola luz por coche, sin sombras).
- **Ride (altura):** baja 0,15/0,3 studs las piezas pintadas y cristales, nunca las ruedas, el chasis ni los asientos. Solo cuando el agente de colisiones confirme que el choque sale de la caja del chasis y no de `Body`.

### C2. Datos: la «Build» de cada vehículo

#### Guardado (DataService)

Sección nueva en `DEFAULT_DATA` (`reconcile` la crea en partidas viejas):

```lua
-- Taller (GarageService): piezas compradas (una vez, para ese tipo de vehículo), la «build» de
-- cada vehículo propio y la matrícula ya aprobada. «Vida nueva» lo borra, igual que data.Vehicles.
Garage = {
	Version = 1,
	Parts = {},   -- ["Coche:Rims_Estrella6"] = true
	Builds = {},  -- [kind] = Build (abajo)
	Plate = "",   -- texto ya filtrado; "" = se genera una vez "1234 VLM" y se guarda
},
```

Una Build (solo ids y números: nada de `Color3` ni instancias, así cabe en el DataStore y no se puede inventar un color):

```lua
Build = {
	V = 1,                      -- versión del formato
	Body = "Berlina",           -- carrocería (coche)
	Paint = "P_RojoValmar", Finish = "Metal", Paint2 = "P_Negro",
	Rims = "Rims_Estrella6", RimColor = "RC_Cromo", Tires = "T_Normal",
	Tint = 2,                   -- 0..3
	Spoiler = "Sp_Labio", Roof = "", BumperF = "", BumperR = "", Skirts = "", Hood = "",
	Lights = "L_Xenon", Exhaust = "", Vinyl = "", VinylColor = "P_Blanco",
	Neon = "N_Cian", Ride = 0,  -- 0 / -1 / -2
	Horn = "",
}
```

`""` o ausente = pieza de serie. Tamaño típico < 400 bytes por vehículo.

#### Validación (servidor, siempre)

`VehicleBuild.validate(build, ownedParts, kind) -> (Build limpia, { avisos })`, **pura** (sin servicios, probada con Lune):

1. `kind` tiene que ser personalizable (`Coche`, `Moto`, `Bici`, `Patinete`, `Monopatin`; barcos en fase 3). Nada de trabajo, alquiler, examen ni coches de la calle.
2. Cada campo: si el id no existe, no es de ese hueco, no vale para ese `kind`/`Body`, o el jugador no lo tiene desbloqueado → **se ignora** (vuelve a serie) y se apunta un aviso. Nunca da error ni rompe la carga.
3. Números con tope (`Tint` 0..3, `Ride` −2..0), tipos equivocados se descartan, campos desconocidos se borran.
4. `V` antigua → se migra (`migrate[1]`, `migrate[2]`…); `V` del futuro (partida de un servidor más nuevo) → se conserva sin tocar lo que no se entiende.
5. Matrícula: 1–8 caracteres `[A-Z0-9 ]`, en mayúsculas; `NameFilter.check` como primera barrera y **`TextService:FilterStringAsync` + `GetNonChatStringForBroadcastAsync`** (la ven otros jugadores: lo exige Roblox). Si el filtro falla o no responde, no se cambia.

Se valida **al guardar** (remoto) y **otra vez al sacar el vehículo** (por si el catálogo cambió o se quitó una pieza).

#### Cómo la aplica el vehículo al salir

Un gancho igual que `PaintFor`, en `VehicleService.mount`, entre `Rides.build` y `Rides.prepare` (mismo sitio que `Decorate` en `launchAt`):

```lua
-- VehicleService (cambio de 5 líneas, fase 1)
VehicleService.StyleFor = nil :: ((Player, string) -> ((Model) -> ())?)?
...
local model = Rides.build(kind, nil, cf, paint)
if VehicleService.StyleFor and not options.Rented and not options.Exam then
	local okStyle, decorate = pcall(VehicleService.StyleFor, player, kind)
	if okStyle and decorate then pcall(decorate, model) end -- un error aquí nunca impide sacar el vehículo
end
model:SetAttribute("OwnerId", player.UserId)
Rides.prepare(model, kind, cf)
```

`GarageService.styleFor(player, kind)` lee `data.Garage.Builds[kind]`, la valida y devuelve `function(model) VehicleBuild.apply(model, build, { Kind = kind }) end`. El modelo se marca con `model:SetAttribute("Style", json)` (≤ 1 KB) y `StyleV`.

La **carrocería** (`Body`) necesita que `Rides.coche` acepte la variante (hoy fija `Berlina`) y que los asientos de pasajero la lean (`REAR_Z` ya lo hace con el atributo `Variant`). Es un cambio en `Rides.luau`: fase 2.

**Restyle en el taller:** si tu vehículo está aparcado en el taller y vacío, al pulsar «Aplicar» el servidor lo sustituye en el mismo sitio (misma posición, `OwnerId`, `Fuel`, `Odometer`, cartel «Conducir») con `VehicleService.rebuildParked(player)` (función nueva, fase 1). Si no, sale con el estilo nuevo la próxima vez que lo saques.

#### Réplica a todos

Las piezas las crea el **servidor** en el modelo, así que llegan a todos los clientes como cualquier pieza (el modelo ya es `ModelStreamingMode.Atomic`). Solo los efectos que dependen de la noche o la distancia (neón, color de la luz) los hace cada cliente leyendo `NeonColor` / `LightColor` del modelo. La interfaz del taller recibe las builds y lo desbloqueado por el remoto (no por atributos del jugador).

`VehicleBuild.apply` (en el diseño, «VehicleStyle») vive en **`src/shared/`** y solo usa la API de instancias (con su propio `decor()` mínimo), para que la misma función la usen el servidor (al sacar el vehículo) y el cliente (vista previa). Misma entrada → mismas piezas (sin `math.random`).

#### Pase de temporada: piezas que se desbloquean

- Tipo de recompensa nuevo **`VehiclePart`** en `BattlePass/Types` (`Part = "Rims_Faro"`, `Kind = "Coche"` u `"*"`). Se entrega en `data.Cosmetics.Owned` (como todo lo del pase: **sobrevive a «Vida nueva»**). `VehicleParts` marca esas piezas con `Pass = true`: no tienen precio en €, solo se desbloquean.
- Los **`VehicleSkin` actuales** (Patinete Brisa Marina, Bici Verde Villaverde, Moto Brisa de Playa Dorada) pasan a ser **pinturas especiales** en el hueco `Paint` de su tipo (id = el de la recompensa). Compatibilidad: si el taller está apagado, `PaintFor` sigue como hoy; con el taller encendido, `styleFor` manda y «Equipar» en la ventana del pase escribe `Builds[kind].Paint = id` (una sola fuente de verdad).
- **«Faro de Valmar» (nv 50 premium)** pasa a ser un **kit legendario**: carrocería `Descapotable` (CarModel sin techo ni luneta, con marco de parabrisas; asientos de la berlina), pintura `Perla Faro` + secundaria **oro** (el `Trim` que hoy no se usa), llantas `Rims_Faro` doradas, neón ámbar «Luz de faro» y marco de matrícula dorado. Se añade `Parts = { … }` a la definición de `S1_P50_Car`; el `Color` se queda para la vista previa y para `PaintFor`. Mismas prestaciones que cualquier coche.
- La **tienda de fichas** puede vender piezas `Pass` (las fichas se ganan jugando): p. ej. acabado Cromo 4 fichas, vinilo «Luces de Valmar» 3 fichas.
- Las futuras temporadas añaden sus piezas en su `SeasonN.luau`; `Catalog` las indexa como hoy.

### C3. Dónde se personaliza: el Taller de Tobías

**Lugar:** una nave de taller en **cada gasolinera** (`Civic.gasStation`, al lado del toldo; el solar mide hasta 70 × 44 y el toldo ocupa el centro): puerta de persiana, elevador, estanterías de llantas, cartel «TALLER TOBÍAS», un NPC mecánico (Tobías en la del barrio de la historia, otros mecánicos en el resto). Una **plaza de trabajo** marcada en el suelo (tag `VehicleWorkshop`, atributo `Radius = 14`). Sale en el mapa y en el GPS («🔧 Taller»). Aprovecha la historia (misión `Pan3_Cruce` ya manda al «taller de Tobías»).

**Cómo se entra:**
1. Cartel «Personalizar vehículo» (ProximityPrompt) en la plaza o en el mostrador. Funciona a pie o con tu vehículo aparcado en la plaza.
2. Desde el menú «🚲 Vehículos» hay un botón «🔧 Ver en el taller» que **solo previsualiza** (probar gratis en cualquier sitio, comprar solo en el taller, para que el taller tenga sentido y la gente se vea allí).

**Ventana (móvil primero, estilo del juego):**

```
┌──────────────────────────────────────────┐  panel Theme.Colors.Panel, borde cian Stroke
│ 🔧 TALLER TOBÍAS · Coche      💶 12.340 €  ✕│  título Theme.TitleFace
├──────────────────────────────────────────┤
│                                          │
│        [ vista 3D del coche ]            │  ViewportFrame: arrastrar = girar,
│   ⟲ girar   ☀/🌙 día-noche   ⤢ zoom       │  pellizco = zoom, botón noche (neón/faros)
├──────────────────────────────────────────┤
│ [Pintura][Llantas][Carrocería][Luces][Extras][Matrícula] → │ chips con scroll horizontal
├──────────────────────────────────────────┤
│ ┌────┐ ┌────┐   2 columnas en móvil,     │ tarjeta: muestra de color / icono,
│ │ ●  │ │ ●  │   4 en PC                  │ nombre, y abajo:
│ │250€│ │✔Tuyo│                          │  «250 €» (verde Money) · «✔ Tuya»
│ └────┘ └────┘                            │  «🔒 Nivel 12» · «🔒 Pase nv 30» · «🪙 3 fichas»
├──────────────────────────────────────────┤
│ Cambios: 3 · Total 1.150 €  [Deshacer] [💳 Comprar y aplicar] │ barra fija abajo
└──────────────────────────────────────────┘
```

- Todo lo que tocas se **prueba al momento en la vista 3D** (cliente, sin coste, sin llamar al servidor). El servidor solo interviene al pulsar «Comprar y aplicar» (una sola petición con la build entera y el total que el cliente cree; el servidor recalcula el precio y cobra solo si coincide).
- Botones grandes (≥ 44 px), textos ≥ 14 px en móvil, sin nada debajo del joystick ni de los botones del HUD (`HudLayout`/`TouchLayout`).
- Reutiliza: `Dialog.window`, `Theme`, el `mountViewport` de `UI/BattlePassPreview` (sacarlo a un módulo común `UI/ModelViewport.luau`), y el patrón de medidas puras de `BattlePassLayout` (`UI/GarageLayout.luau`, probado en 10 pantallas).
- Los modelos base para la vista previa: el servidor deja en `ReplicatedStorage.GaragePreviews` un modelo de cada tipo y carrocería (como `BattlePassPreviews`), y el cliente les aplica la build con el mismo `VehicleBuild.apply`.
- Desbloqueos: por **nivel de personaje** (atributo `Level`, ya existe), por **pase** (`Cosmetics.Owned`), por **fichas** (tienda de fichas) o por **dinero**. Lo bloqueado se ve y se puede probar en la vista 3D, con el candado y el motivo.

### C4. Economía

Referencias del juego: tareas de trabajo 25–45 € (`Config.Jobs`), dinero inicial 500 €, moto 3.500 €, lancha 7.500 €, coche 9.000 €, casa familiar 5.000 €, gasolina 1,50 €/L. Estimación (a confirmar con `test-economy` o telemetría): **~1.500–2.500 € por hora de trabajo**.

| Qué | Precio (coche) | Tipo de gasto |
|---|---|---|
| Pintar brillante / mate / metalizado / perlado | 250 / 450 / 550 / 850 € | **Cada vez** (mano de obra) |
| Pintura secundaria | 150 € | Cada vez |
| Llantas | 400 € (sencillas) – 1.500 € (turbina, malla) | Una vez |
| Color de llanta | 100 € | Cada vez |
| Neumáticos letras blancas / banda blanca | 300 / 450 € | Una vez |
| Lunas tintadas | 300 € | Una vez (cambiar el nivel, gratis) |
| Alerón labio / deportivo / GT | 600 / 900 / 1.400 € (GT: nivel 15) | Una vez |
| Parachoques deportivo (delantero o trasero) | 700 € cada uno | Una vez |
| Faldones | 600 € | Una vez |
| Capó con toma / franjas | 500 / 400 € | Una vez |
| Faros xenón / ámbar | 500 € | Una vez |
| Escape doble / deportivo | 350 / 700 € | Una vez |
| Vinilo | 400–900 € | Una vez (color del vinilo: 100 €) |
| Neón bajo | 1.200 € (+150 € por cambiar de color) | Una vez |
| Matrícula personalizada | 500 € la primera, 150 € cada cambio | Cada cambio |
| Carrocería compacto / todoterreno | 2.000 € | Una vez |

- Multiplicador por tipo: moto ×0,6, bici/patinete/monopatín ×0,3 (redondeado a 10 €).
- Coche completo «de ensueño»: ~8.000–10.000 €. Pintar solo: 10 minutos de trabajo. Buen objetivo a largo plazo y **sumidero** constante (pinturas y matrículas se pagan cada vez).
- Probar en la vista 3D siempre es gratis. Cambiar entre piezas que ya tienes: gratis.
- Si la gasolinera es de un jugador (`BusinessService`), el taller puede darle una comisión pequeña (5 %) más adelante; en la v1 todo el dinero sale del juego.
- **Nada por Robux**: `GarageService` no usa `MarketplaceService`; la prueba lo comprueba buscando en el código.
- **Sin ventaja**: no se tocan `Gameplay.Vehicles` ni `Gameplay.Tuning`. Recomendación: ningún «tuning» de rendimiento. Si el dueño lo quiere algún día: como mucho ±3 % de aceleración, con tope, solo ganado jugando (nunca comprado ni del premium), y subiendo también el margen del detector de saltos (`jumped`).

### C5. Catálogo propuesto para la v1

**20 pinturas** (ids `P_…`): Blanco Glaciar, Negro Noche, Gris Plata, Grafito, Rojo Valmar, Granate, Naranja Atardecer, Amarillo Limón, Verde Villaverde, Verde Menta, Turquesa Brisa, Azul Puerto, Azul Marino, Celeste, Morado Uva, Rosa Chicle, Arena de Playa Dorada, Café, Oro Viejo, Cobre. **4 acabados**: Brillante, Mate, Metalizado, Perlado (+ Cromo, solo del pase o de fichas). Especiales del pase: Brisa Marina, Verde Villaverde (bici), Brisa de Playa Dorada, Perla Faro.

**12 llantas** (`Rims_…`): Serie (5 radios, gratis), Clásica 5, Estrella 6, Deportiva 10, Radios finos en Y, Malla cruzada, Turbina, Monobloque (disco liso), Hélice, Tapacubos retro, Todoterreno (con tornillería), Faro dorada (pase). **6 colores de llanta**: Cromo, Negro, Grafito, Bronce, Blanco, Color carrocería.

**3 neumáticos**: Normal, Letras blancas, Banda blanca clásica.

**3 alerones** (Berlina): Labio, Deportivo, GT. Compacto: Labio. Todoterreno: Baca (en el techo) y Aleta de tiburón.

**2 parachoques por carrocería** (delantero y trasero): Serie / Deportivo (Berlina y Compacto), Serie / Defensa (Todoterreno).

**Lunas**: 4 niveles (sin, claro, medio, oscuro). **Neón**: 8 colores (cian, azul, rosa, morado, verde, rojo, blanco, ámbar). **Faros**: normal, xenón, ámbar. **Matrícula**: texto libre filtrado. **Vinilos** (fase 2): franja central doble, franja lateral, llamas, número de carreras, «Valmar» retro, puesta de sol. **Moto**: baúl, parabrisas alto, 4 llantas. **Bici**: cesta, 4 colores de timbre. **Monopatín**: 6 dibujos de tabla.

**Qué hacer primero (MVP, en este orden):**
1. Pintura + acabado + secundaria del coche (lo más visible, cero piezas nuevas: solo recolorear).
2. Matrícula personalizada (y matrícula fija por jugador, que hoy cambia cada vez).
3. Llantas (6 diseños + color) — lo que pide el dueño.
4. Lunas tintadas.
5. Alerón (3) y neón.
6. Pintura y llantas de moto, bici, patinete y monopatín.

### C6. Plan por fases

#### Fase 0 — ✅ HECHA (solo archivos nuevos, sin tocar código de vehículos)

| Archivo nuevo | Qué | Estado |
|---|---|---|
| `src/shared/VehicleParts.luau` | Solo datos + funciones puras: `Enabled = false`, `Kinds`, `Reserved`, `Zones` (piezas de serie por nombre), `Anchors` (medidas de CarModel/Rides), `Wheels`, `Reference` (pieza para saber dónde está el vehículo antes de `Rides.prepare`), `Budget`, `PriceFactor`, catálogo (`Parts`/`List`: id, nombre, `Slot`, `Attach`, `Price`, `Charge` Once/Each, `Unlock` Shop/Level/Pass, `Kinds`, `Bodies`, `Requires`), `Tints`, `Plate` + `plateText`, `fits`, `isOwned`, `isUsable`, `canBuy`, `price(kind, from, to, owned)`. | ✅ |
| `src/shared/VehicleBuild.luau` (en el diseño, «VehicleStyle») | Esquema `Build` versionado (`VERSION = 1`, `default`, `migrate[0]`), `validate(build, ownedParts, kind)`, `apply(model, build, options?)` (antes o después de `Rides.prepare`; si ya está preparado, suelda las piezas al `Chassis`) y `clear(model)` (deja el modelo exactamente como de serie). | ✅ |
| `scripts/test-vehicleparts.luau` | Pruebas con Lune sobre los modelos DE VERDAD (`Builder`, `Palette`, `CarModel`, `Rides` con instancias de Lune): catálogo, anclas contra el modelo, validación, JSON, precios, y aplicar/quitar cada pieza en berlina, compacto, todoterreno, moto, bici, patinete y monopatín. | ✅ |

Catálogo v1 que ya existe: 20 pinturas + 4 del pase (Brisa Marina, Verde Villaverde bici, Brisa de Playa Dorada, Perla Faro: se tienen si la recompensa `S1_…` está en `Cosmetics.Owned`), 4 acabados, 12 llantas (4 también en la moto) × 6 colores, 3 neumáticos, 3 alerones, 2 parachoques por carrocería y punta, lunas (kit + 4 niveles), neón (kit + 8 colores), carrocería (berlina/compacto/todoterreno; aplicarla espera a la fase 2) y matrícula (1–8 `[A-Z0-9 ]`).

Cómo lo hace (decisiones de la fase 0):
- **Nada de lo de serie se borra**: lo que se «sustituye» (llantas, parachoques deportivos) se **esconde** (`Transparency = 1`) y guarda cómo era en atributos `ModOrig*`. Así la colisión, los nombres y las soldaduras no cambian y `clear` lo devuelve todo. Piezas de serie: +0 piezas; las nuevas `Mod_` como mucho `Budget` (coche completo: 52 de 70; moto 17 de 30).
- Los nombres reservados (`Headlight*`, `Taillight`, `Indicator*`, `Reverse`, `ThirdBrake`, `Kickstand`, `Chassis`, `DriverSeat`, `RideSeat`…) no se tocan. **`Body` solo se pinta** (color, material, brillo), nunca se mueve, esconde ni cambia su colisión.
- Pintura, acabado, color de llanta y color de neón son **mano de obra** (`Charge = "Each"`): valen sin «tenerlos» y se cobran al aplicar (`price`). El resto se compra una vez por tipo de vehículo (`data.Garage.Parts["Coche:Rims_Turbina"] = true`).
- La matrícula va en la Build (`Plate`), **ya filtrada**: `validate`/`apply` solo miran el formato; el filtro de Roblox es cosa del servidor (fase 1).

#### Fase 1 — cuando terminen los agentes de vehículos (MVP jugable) — ⏳ pendiente

| Archivo | Cambio |
|---|---|
| `src/server/Services/DataService.luau` | `Garage` en `DEFAULT_DATA`. `newLife` no lo conserva (decisión del dueño, A4). |
| `src/server/Services/VehicleService.luau` | Gancho `StyleFor` en `mount` (≈ 5 líneas): `VehicleBuild.apply(model, build, { Kind = kind })` entre `Rides.build` y `Rides.prepare`. `rebuildParked(player)`. `LightColor` en `addHeadlight`. |
| `src/server/Services/GarageService.luau` (nuevo) | Remoto `Garage` (`Get`, `Buy`, `Apply`, `SetPlate`) con límite de peticiones; comprueba que estás en un `VehicleWorkshop`; recalcula precios; `DataService.spend`; filtro de texto; `styleFor`; `GaragePreviews`. Evento `StoryEvents.emit(player, "VehicleStyled")` (misiones del pase). Arranca en `Main.server.luau`. |
| `src/server/World/Kit/Civic.luau` | Nave del taller en `gasStation` + tag `VehicleWorkshop`. |
| `src/shared/MapInfo.luau` / `LifeStory/Locations.luau` | «🔧 Taller» en el mapa y el GPS. |
| `src/client/UI/GarageUI.luau`, `UI/GarageLayout.luau`, `UI/ModelViewport.luau` (nuevos) | Ventana, medidas, vista 3D común (sacada de `BattlePassPreview`). |
| `src/client/Controllers/Vehicles.luau` | Botón «🔧 Ver en el taller» (solo vista previa). |
| `src/client/Controllers/…` (nuevo `VehicleNeon.luau`) | Neón y color de faros de noche, por distancia. |
| `src/server/Services/TesterService.luau` + `UI/TesterPanel.luau` | Acción «Taller»: desbloquear todo, dinero, forzar noche. |

#### Fase 2 — ⏳ pendiente

`CarModel.luau` (atributo `Zone` en cada pieza, variante `Descapotable`), `Rides.luau` (`coche` con variante), parachoques, faldones, capó, escape, vinilos, faros, carrocería; `BattlePass/Types` + `BattlePassRewardService` (tipo `VehiclePart`, kit «Faro de Valmar», `Equip` de `VehicleSkin` → build); tienda de fichas con piezas.

#### Fase 3 — ⏳ pendiente

Bocina (cuando la tenga `Driving`), altura de suspensión (cuando el choque no dependa de `Body`), barcos (franja, cojines, nombre en la popa de la lancha normal, luz bajo el agua) en `BoatService`, variedad en el tráfico usando el catálogo, 3 «estilos guardados» por vehículo.

#### Pruebas que hay que escribir (`scripts/test-vehicleparts.luau`, sin Roblox, con Lune)

Hechas en la fase 0: **1** (catálogo y anclas), **2** (validación), **3** (aplicar y quitar), **4** (sin cambio de rendimiento: chasis, asientos y colisión iguales; ninguna pieza con campos de rendimiento; los módulos no cargan `Gameplay`), **5** en parte (JSON como el DataStore y tamaño < 400 bytes; falta `reconcile`/«Vida nueva», fase 1) y **6** en parte (determinista en dos modelos; falta el atributo `Style`, fase 1). Faltan 7, 8 y 9 (fases 1–2).

1. **Catálogo:** ids únicos; cada pieza tiene hueco, tipos válidos, precio ≥ 0 o `Pass = true`; ningún campo de Robux; textos en español; todas las anclas existen para cada tipo/carrocería y **coinciden con el modelo construido** (ruedas, parachoques, matrícula a < 0,1 studs).
2. **Validación:** ids desconocidos → se ignoran; pieza de otro tipo o carrocería → fuera; pieza bloqueada → fuera; `Tint = 99` → 3; tipos basura (texto en vez de número, tablas anidadas, 10.000 campos) no rompen; migración `V0 → V1`; `V` futura se conserva; matrícula con símbolos o larga → rechazada.
3. **Aplicar y quitar:** para cada tipo × carrocería × cada pieza: `Rides.build` + `apply` + `Rides.prepare` sin errores; piezas extra dentro del presupuesto; todas las `Mod_` con `CanCollide/CanQuery/CanTouch = false` y `Massless` tras `prepare`; ninguna usa un nombre reservado; todas dentro de la caja del chasis + 0,3; `Headlight`, `Taillight`, `Indicator*`, `Kickstand`, `Body` siguen existiendo; build vacía = mismo modelo que sin taller (mismos nombres, tamaños y posiciones).
4. **Sin cambio de rendimiento:** tras aplicar cualquier build, `Chassis.Size`, CFrame de `DriverSeat` y de cada `RideSeat`, y el conjunto de piezas con `Collide = true` (nombre, tamaño, posición) son idénticos al modelo de serie; `Gameplay.Vehicles` y `Gameplay.Tuning` son iguales a una copia tomada antes.
5. **Guardar y cargar:** comprar → aplicar → `JSONEncode`/`JSONDecode` (como el DataStore) → `validate` = misma build; `reconcile` añade `Garage` a una partida vieja; «Vida nueva» borra lo comprado y conserva lo del pase (`Cosmetics`).
6. **Réplica / determinismo:** el atributo `Style` del modelo, decodificado y aplicado en el cliente a `GaragePreviews`, da exactamente las mismas piezas `Mod_` que en el servidor.
7. **Economía y remoto:** comprar resta el precio una vez; comprar dos veces no cobra dos veces; sin dinero no cambia nada; `Buy/Apply` lejos del taller → rechazado; ráfaga de peticiones → limitada; precio del cliente distinto al del servidor → rechazado; ningún `require` de `MarketplaceService` en `GarageService`.
8. **Pase:** una recompensa `VehiclePart` se entrega en `Cosmetics.Owned` y aparece desbloqueada; el `VehicleSkin` equipado sale como pintura; `Faro de Valmar` aplica su kit; con el pase apagado nada de esto aparece. (Ampliar `scripts/test-battlepass.luau`.)
9. **Interfaz:** `GarageLayout` en 10 tamaños de pantalla sin solapes (como `test-battlepassui.luau`).

Y en el `test-compile.luau` / `test-clientboot.luau` que ya existen: que los módulos nuevos compilan y el cliente arranca con el taller apagado.

#### Riesgos

- **Choque con el trabajo en curso:** hay agentes cambiando ahora colisiones, semáforos, mandos/luces del coche y el modo pruebas. Cualquier cambio en `Rides.luau`, `CarModel.luau`, `VehicleService.luau`, `Driving.luau`, `Traffic.luau`, `VehicleHud.luau`, `TesterService.luau`/`TesterPanel.luau`, `test-ride`/`test-gameplay` **tiene que esperar** a que terminen.
- **Nombres:** si el agente de luces cambia cómo se buscan los faros (`Headlight`…) o el de colisiones decide que el choque sale de `Body`/`Collide`, hay que ajustar las zonas y la regla de «no colisión». Las pruebas 3 y 4 lo detectan.
- **Rendimiento en móvil:** muchas piezas por coche × muchos jugadores. Mitigación: presupuesto de piezas, detalles sin sombra, neón con una sola luz y solo cerca, llantas ≤ 8 piezas por rueda.
- **Texto de la matrícula:** es texto de jugador visible para todos: filtro de Roblox obligatorio; si falla, no se cambia.
- **Remoto:** el cliente nunca dice el precio final ni el color: solo ids; el servidor valida y cobra.
- **Datos:** migraciones por versión; nunca borrar una build por un id desconocido (se ignora al aplicar, pero se puede conservar hasta que el catálogo lo vuelva a tener, si se prefiere).
- **Pase:** hoy `VehicleSkin` solo lleva `Color`; al pasar a kit hay que mantener `PaintFor` como plan B mientras el taller esté apagado.
- **Soldadura:** todo lo nuevo debe crearse **antes** de `Rides.prepare` (o soldarse igual que él en `rebuildParked`); una pieza sin soldar se quedaría flotando en el sitio de salida.
- **Coherencia con diseños antiguos:** `docs/diseno/10` y `14` hablan de monetizar matrícula y coches premium; hay que corregirlos para que no se implemente por error.

#### Qué tiene que esperar a los agentes de vehículos

Todo lo de las fases 1–3 que toca `Rides.luau`, `CarModel.luau`, `VehicleService.luau` (gancho `StyleFor`, `rebuildParked`, color de faros), `Driving`/`Traffic`/`VehicleHud` (neón, bocina), `TesterService`/`TesterPanel` y las pruebas existentes de vehículos. La **fase 0** (módulos compartidos nuevos + su prueba) se puede empezar ya, pero las anclas se deben volver a comprobar cuando terminen los arreglos de colisiones.
