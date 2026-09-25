# Etiquetas del mapa (para la historia)

Referencia de lo que el mapa deja preparado para `LifeStory`. Todo son partes invisibles
(`Transparency = 1`, sin colisión) salvo que se diga lo contrario.

## Casa del bebé — `Kit/Home.luau`
8 casas `CasaFamiliar` en la fila norte de **Los Pinos** (tag `FamilyHome`, atributo `HomeId`).

| Tag | Atributos | Qué es |
|---|---|---|
| `Room` | `Room` = `Salon` / `Cocina` / `Dormitorio`, `HomeId` | Volumen de cada habitación |
| `LookOutside` | `HomeId` | Ventanal del salón; `LookVector` mira hacia la ciudad |
| `BabySpawn` | `HomeId` | Junto a la cuna, en el dormitorio |
| `FamilySpot` | `Npc` = `Familia_Abu` (salón) / `Familia_Padre` (cocina), `HomeId` | Dónde van los NPC |

## Colegio — `Kit/Civic.luau` (`Civic.school`)
En los 6 pueblos con `Colegio`.

| Tag | Atributos | Qué es |
|---|---|---|
| `SchoolEntrance` | — | Delante de la puerta |
| `Classroom` | `ClassroomId` | Volumen del aula (A y B) |
| `Desk` | `ClassroomId` | Pupitres (parte visible) |
| `Board` | `ClassroomId` | Pizarra (parte visible) |
| `TeacherSpot` | `ClassroomId` | Sitio del profe |
| `MusicRoom` | — | Volumen del aula de música |
| `RecessArea` | — | Volumen del patio |
| `PEArea` | — | Pista y campo de deporte (partes visibles) |

## Universidad
- Cada modelo `Facultad` tiene atributo `Faculty` = `Medicina` / `Ingenieria` / `Derecho` / `Economia`.
- La biblioteca tiene el tag `Library` (en el modelo).

## Tiendas
Tag `Shop` + atributo `ShopId` en una parte `ShopEntrance` delante de la puerta (el modelo
también lleva `ShopId`). El id es la primera palabra del rótulo sin tildes:
`Cafeteria`, `Supermercado`, `Hamburgueseria`, `Panaderia`, `Banco`, `CentroComercial`,
`Gasolinera`, `Cine`, `Recreativos`, `Gimnasio`…

## Vehículos, autoescuela, recreativos y restaurante
| Tag | Atributos | Dónde |
|---|---|---|
| `RentalStation` | — | Bici pública junto a cada parada de bus y en la plaza (9) |
| `DrivingSchool` | `Town` | Autoescuela de cada calle de ocio (8) |
| `ArcadeMachine` | `GameId` = `Bolas` / `Canasta` | Dentro de los recreativos (3 por local) |
| `PrizeCounter`, `ArcadeScoreboard` | — | Recreativos |
| `RestaurantBoard`, `RestaurantBar`, `RestaurantPass`, `RestaurantDoor`, `RestaurantWaiterSpot`, `RestaurantBarmanSpot` | — | Restaurante Valmar (Valmar Centro, avenida) |
| `RestaurantTable`, `RestaurantSeat` | `TableId` | 6 mesas con 2 sillas |

Eventos nuevos para la historia (`StoryEvents`): `VehicleMounted`, `VehicleBought`, `LicenseEarned`,
`LicenseFailed`, `ArcadePlayed`, `PrizeRedeemed` y `JobTaskDone` con `JobId` = `Camarero` / `Barman`.
Atributos del jugador: `Riding`, `OwnedVehicles`, `Licenses`, `Tickets`.

## Misiones del colegio (01 "El primer día", 02 "La mochila desaparecida", 03 "El grupo")
Tres etiquetas genéricas (`Kit/StoryMarks.luau`), todas piezas invisibles. Con `LocationService`
se usan así, sin tocar el mapa: `{ Tag = "StoryArea", Attribute = { AreaId = "Biblioteca" }, Zone = "Home", Inside = true }`.

| Etiqueta | Atributo | Contexto |
|---|---|---|
| `StoryProp` (objeto con el que se interactúa) | `PropId` | `HomeId` (casa) o `School` / `Town` (nombre del pueblo) |
| `StoryArea` (volumen de una zona) | `AreaId` | `School` / `Town` |
| `StorySpot` (punto para un NPC o un evento; `LookVector` = hacia dónde mira) | `SpotId` | `HomeId` o `School` / `Town` |

**Casa familiar** (las 8 de Los Pinos, con `HomeId`)
- StoryProp: `Cama`, `Armario`, `Espejo`, `Mochila` (junto a la cama), `Desayuno` (mesa de la cocina)
- StorySpot: `Despertar` (al lado de la cama, para quien te despierta), `SalirCasa` (delante de la puerta)

**Colegio** (atributo `School` = pueblo; 6 colegios; el del Campus no tiene pabellón ni comedor por falta de sitio)
- StoryArea: `Pasillo`, `Patio`, `Gimnasio`, `Almacen` (al fondo del gimnasio, poca luz), `Comedor`, `Biblioteca`
- StoryProp: `Taquilla` (6, atributo `LockerId` 1-6, en el pasillo), `Canasta` (dentro del gimnasio, desde donde se tira),
  `MochilaAlmacen` (5 mochilas en el almacén, atributo `Index` 1-5), `BarraComedor`, `Apuntes` (mesa de la biblioteca)
- StorySpot:
  - Llegada: `Balon_Camino` (acera antes del cole), `Autobus` (autobús escolar amarillo aparcado), `Padres_1..3`, `Profesor_Entrada`
  - Dentro: `Informante_Pasillo`, `Informante_Comedor`, `Informante_Biblioteca`, `Bibliotecaria`, `Libros` (en el pasillo)
  - Recreo: `Grupo_Deportistas` (pista), `Grupo_Artistas` (tizas y caballete), `Grupo_Estudiantes` (banco junto al edificio)
  - Pistas de la mochila: `Pista_Papel`, `Pista_Pegatina` (patio), `Pista_Huella`, `Pista_Objeto` (camino al gimnasio)
  - Gimnasio: `Gimnasio_Grupo`, `Gimnasio_Puerta`, `Almacen_NPC`
  - Fútbol: `Futbol_Centro`, `Futbol_PorteriaA`, `Futbol_PorteriaB` (campo de fútbol)
  - Persecución: `Escondite` (muro bajo y cajas en el patio), `Atajo_Musica` (dentro del aula de música, junto a
    su puerta trasera) y `Atajo_Musica_Salida` (fuera, en el patio, camino del gimnasio). La puerta es decorativa:
    la historia lleva al jugador de un punto al otro.
- Ya existían: `SchoolEntrance`, `Classroom`/`Desk`/`Board`/`TeacherSpot` (+`ClassroomId`), `MusicRoom`, `RecessArea`, `PEArea`

**Parques** (atributo `Town`; 8 parques)
- StoryArea: `Parque` · StoryProp: `Canasta`, `Fuente`, `Columpios` · Tienda: `Shop` con `ShopId = "Quiosco"`
- StorySpot: `Parque_Reunion`, `Parque_Canasta`, `Parque_Fuente`, `Parque_Tienda`

Ruta del primer día en Los Pinos: las casas familiares (fila norte) → cruzar la calle → colegio (fila 2, columna 2);
el parque está justo al lado (fila 2, columna 3).
