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
