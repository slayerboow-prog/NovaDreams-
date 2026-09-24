# Fase 4 — Sistema de datos y persistencia

## 4.1 Qué servicio de Roblox se usa para qué

| Servicio | Características | Uso en Real Life Simulator |
|---|---|---|
| **DataStoreService** | Persistente, lento (~100-500 ms), con cuotas por minuto, máx. 4 MB por clave, historial de versiones | Perfiles, propiedades, familias, negocios, contratos |
| **OrderedDataStore** | Clasificaciones numéricas | Rankings (más rico, más ascensos, familia más grande) |
| **MemoryStoreService** | Muy rápido, compartido entre servidores, **temporal** (caduca), con cuotas | Anuncios del mercado en vivo, bolsa, registro de servidores, cerrojos globales, colas |
| **MessagingService** | Mensajes en tiempo real entre servidores, no garantizados, con límites de frecuencia | Noticias globales, avisos a familiares y amigos, eventos de toda la región |
| **TeleportService** | Llevar jugadores entre servidores y places, con datos de viaje | Unirse a la familia, viajar a otros destinos |

Regla: **MemoryStore y Messaging nunca son la fuente de verdad.** Si algo importa, acaba en un DataStore.

## 4.2 Stores y claves

| Store | Clave | Contenido | Tamaño esperado |
|---|---|---|---|
| `Account_v1` | `u_<UserId>` | Cuenta del jugador: ajustes, compras y recibos, huecos de personaje, linajes | < 20 KB |
| `Character_v1` | `c_<CharacterId>` | **Una vida**: edad, etapa, necesidades, habilidades, estudios, carrera, dinero, inventario, referencias a propiedades y vehículos | 20–200 KB |
| `Build_v1` | `b_<PropertyId>` | Construcción y muebles de una propiedad (comprimido) | hasta ~1 MB |
| `Household_v1` | `h_<HouseholdId>` | Miembros, roles, casa común, árbol familiar | < 50 KB |
| `Business_v1` | `biz_<BusinessId>` | Empresa: dueño, local, empleados, caja, precios, estadísticas | < 200 KB |
| `Contract_v1` | `k_<ContractId>` | Operaciones entre jugadores (venta, alquiler, préstamo) con estado | < 5 KB |
| `Global_v1` | por sistema | Estado del mundo: economía global, precios base, noticias guardadas | pequeño |
| `Ranking_*` (Ordered) | `<CharacterId>` | Valores de clasificación | — |

¿Por qué separar **Cuenta** y **Personaje**? Porque un jugador puede tener varias vidas (huecos de personaje, generaciones) y porque así cada clave se mantiene pequeña y rápida.

## 4.3 Esquema del personaje (resumen)

```lua
Character = {
	SchemaVersion = 1,
	Id = "c_...", OwnerUserId = 123, Lineage = "lin_...", Generation = 1,
	Identity = { FirstName, LastName, BirthDay (día del calendario del juego), Appearance = {...} },
	Life = { AgeYears, AgeProgress (0..1), Stage = "Adulto", AgingPaused = false, Alive = true },
	Needs = { Hunger, Energy, Hygiene, Fun, Health, Mood },
	Skills = { [SkillId] = { Level, XP } },
	Education = {
		Completed = { [CourseId] = { Grade, CompletedAt } },
		InProgress = { [CourseId] = { Sessions, Score } },
		Licenses = { CarB = true, ... },
	},
	Career = { Current = { CareerId, RankIndex, XP, HiredAt }, History = {...} },
	Economy = { Cash, Accounts = { Main = balance, Savings = balance }, CreditScore, Loans = {...}, Bills = {...}, Ledger = { últimas 100 operaciones } },
	Assets = { Properties = { PropertyId... }, Vehicles = { [VehicleId] = {...} }, Businesses = { BusinessId... } },
	Inventory = { [Slot] = { ItemId, Qty, Meta } },
	Social = { Friends = {...}, Household = "h_..." },
	Achievements = { ... },
	Stats = { PlaySeconds, MoneyEarned, ... },
}
```

## 4.4 Guardado seguro

- **ProfileStore** (librería de la comunidad, estándar de facto): bloqueo de sesión (evita duplicados entre servidores), autoguardado y liberación al salir o al cerrar. Sustituye al `DataService` casero de la versión 0.1.
- **Versiones de esquema y migraciones:** cada perfil lleva `SchemaVersion`. Al cargarlo se aplican en orden las migraciones pendientes (`migrations[1] → [2] → …`). Así se pueden cambiar los datos en futuras actualizaciones sin romper los perfiles antiguos.
- **Validación al cargar:** tipos y rangos (dinero ≥ 0, edad válida…). Si un perfil está corrupto se registra y se restaura la última versión válida.
- **Copias de seguridad:** DataStore guarda versiones de cada clave. Habrá un comando de administrador para restaurar el perfil de un jugador a una fecha concreta.
- **Guardado por eventos importantes:** además del autoguardado, se guarda inmediatamente tras compras con Robux, compras de propiedades y transferencias.

## 4.5 Operaciones entre jugadores (transacciones atómicas)

Roblox no tiene transacciones que abarquen dos claves. Para vender una casa de A a B se usa un **contrato con estados**:

```
CREADO → FONDOS_RETENIDOS (dinero de B apartado) → ACTIVO_TRANSFERIDO (casa pasa a B)
       → PAGADO (dinero a A) → CERRADO
```

- Cada paso es un `UpdateAsync` que solo avanza si el estado anterior es el esperado.
- Si un servidor cae a mitad, el siguiente servidor que cargue a A o a B **reanuda** los contratos pendientes.
- El resultado: el dinero nunca se duplica ni desaparece.

## 4.6 Cuotas y rendimiento

- Nunca se lee o escribe un DataStore en bucles por jugador cada pocos segundos. Los datos viven en memoria (perfil) y se guardan en lotes.
- Los datos globales frecuentes (precios de bolsa, anuncios del mercado) van en MemoryStore con caché local de 30–60 s.
- Todas las llamadas pasan por una cola con reintentos y espera progresiva que respeta las cuotas.

## 4.7 Privacidad y normas

- Roblox exige borrar los datos de un usuario cuando lo solicita (derecho al olvido). Habrá un script de administración que elimina las claves `u_`, `c_`, `b_`… de ese UserId.
- No se guarda ninguna información personal real.
