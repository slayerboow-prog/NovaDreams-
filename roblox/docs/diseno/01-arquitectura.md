# Fase 1 — Arquitectura completa del juego

## 1.1 Principios que no se negocian

1. **El servidor manda.** Dinero, edad, estudios, propiedades, vehículos, inventario y progreso se calculan y guardan solo en el servidor. El cliente pide ("quiero comprar X") y el servidor decide.
2. **Todo el contenido son datos.** Profesiones, cursos, objetos, vehículos, edificios, distritos y precios se definen en tablas (registros) y no dentro del código. Añadir una profesión nueva debe significar añadir una entrada de datos y, como mucho, un minijuego.
3. **Sistemas independientes con contratos claros.** Cada sistema expone una API pequeña y emite eventos. Ningún sistema toca los datos internos de otro.
4. **El mundo es modular.** El mapa se divide en casillas y parcelas estándar. Cualquier ampliación encaja sin rehacer lo anterior.
5. **Primero la vida adulta, luego lo demás.** La mayor parte del tiempo de juego ocurre de adulto. Esa experiencia debe ser buena antes de construir la infancia o las generaciones.
6. **Diseñado para móvil.** La mayoría de jugadores de Roblox juegan en móvil. Rendimiento, interfaz y controles se piensan para móvil desde el día 1.

## 1.2 Estructura de la experiencia (Universe)

Una experiencia de Roblox puede tener varios *places* (mundos) conectados con `TeleportService`.

| Place | Función | Cuándo |
|---|---|---|
| **Región de Valmar** (principal) | El mundo persistente: ciudades, distritos, toda la vida diaria | Desde el inicio |
| **Destinos de viaje** (ej. Isla Resort) | Vacaciones, eventos especiales. Se llega desde el aeropuerto o el puerto | Fase de expansión |
| **Segunda región** (ej. "Capital") | Nueva ciudad grande cuando la Región de Valmar esté llena | Largo plazo |

No habrá lobby separado. El jugador entra directamente en la Región de Valmar y elige su personaje en una pantalla superpuesta. Cada teletransporte cuesta 5–15 segundos de carga y hace perder jugadores, así que solo se usa cuando tiene sentido narrativo (viajar).

## 1.3 Capas del código

```
┌──────────────────────────────────────────────────────────────┐
│ PRESENTACIÓN   UI (teléfono + HUD) · cámara · audio · VFX     │  cliente
├──────────────────────────────────────────────────────────────┤
│ META           Monetización · Analítica · Moderación · Admin  │
├──────────────────────────────────────────────────────────────┤
│ SIMULACIÓN     Calendario · Clima · Director de eventos ·     │
│ DEL MUNDO      Población NPC · Tráfico · Emergencias          │
├──────────────────────────────────────────────────────────────┤
│ SOCIAL         Relaciones · Hogares/Familias · Mensajería     │
├──────────────────────────────────────────────────────────────┤
│ ACTIVIDADES    Motor de actividades → Profesiones · Educación │
│                · Negocios · Deportes · Ocio                   │
├──────────────────────────────────────────────────────────────┤
│ PATRIMONIO     Propiedades · Construcción · Vehículos ·       │
│                Inventario                                     │
├──────────────────────────────────────────────────────────────┤
│ ECONOMÍA       Libro contable (ledger) · Banco · Facturas ·   │
│                Impuestos · Préstamos · Mercado                │
├──────────────────────────────────────────────────────────────┤
│ PERSONAJE      Vida (edad/etapa) · Necesidades · Habilidades ·│
│                Apariencia · Logros                            │
├──────────────────────────────────────────────────────────────┤
│ MUNDO          Layout (distritos, casillas, parcelas) · Grafo │
│                de carreteras · Zonas · Interacciones          │
├──────────────────────────────────────────────────────────────┤
│ NÚCLEO         Cargador de servicios · Red segura · Datos     │
│                (perfiles) · Registros · Bus de eventos ·      │
│                Reloj del juego · Configuración · Localización │
└──────────────────────────────────────────────────────────────┘
```

Una capa solo puede depender de las capas de **debajo**. Si Economía necesita avisar a Profesiones, no la llama directamente: emite un evento (`Economy.TransactionCompleted`) y Profesiones se suscribe si le interesa.

## 1.4 El núcleo (lo primero que se construye)

| Módulo | Responsabilidad |
|---|---|
| **ServiceLoader** | Arranca los servicios en orden, con fases `init` (preparar) y `start` (conectar). Detecta dependencias circulares |
| **Net** | Capa sobre RemoteEvents y RemoteFunctions: valida tipos, limita frecuencia (rate limit) por jugador y registra abusos. Ningún servicio usa Remotes "a pelo" |
| **Data** | Perfiles de jugador con bloqueo de sesión, versiones de esquema y migraciones (ver Fase 4) |
| **Registry** | Carga y valida todas las tablas de contenido al arrancar. Si una profesión apunta a un curso que no existe, el servidor avisa |
| **EventBus** | Eventos internos del servidor (`Life.StageChanged`, `Career.Promoted`…) |
| **GameClock** | Hora y calendario del juego (día, semana, mes, estación). Todo lo que depende del tiempo lo usa |
| **Localization** | Todos los textos por clave (`jobs.medico.name`), en español e inglés desde el inicio |
| **Admin/Debug** | Comandos de administrador (dar dinero, cambiar edad, saltar el tiempo…), imprescindibles para probar |
| **Analytics** | Eventos de juego (`AnalyticsService` de Roblox + propios): embudos, economía, retención |

## 1.5 Estructura de carpetas (Rojo)

```
roblox/
├── default.project.json
├── wally.toml                  ← librerías externas (gestor de paquetes Wally)
├── src/
│   ├── shared/                 ← ReplicatedStorage.Shared
│   │   ├── Registry/           ← CONTENIDO como datos
│   │   │   ├── Careers/        (una tabla por profesión)
│   │   │   ├── Courses/        (cursos y titulaciones)
│   │   │   ├── Items/          (comida, muebles, ropa…)
│   │   │   ├── Vehicles/
│   │   │   ├── Properties/     (tipos de vivienda y parcela)
│   │   │   ├── Districts/      (identidad y reglas de cada distrito)
│   │   │   └── LifeStages.luau
│   │   ├── Types/              ← tipos Luau compartidos (el "contrato" de datos)
│   │   ├── Net/                ← definición de todos los mensajes cliente↔servidor
│   │   └── Util/
│   ├── server/                 ← ServerScriptService
│   │   ├── Core/               (ServiceLoader, Data, Net, EventBus, GameClock, Admin)
│   │   ├── World/              (Layout, RoadGraph, Zones, Interactions)
│   │   ├── Character/          (Life, Needs, Skills, Appearance)
│   │   ├── Economy/            (Ledger, Bank, Bills, Taxes, Loans, Market)
│   │   ├── Assets/             (Properties, Building, Vehicles, Inventory)
│   │   ├── Activities/         (ActivityEngine + módulos de minijuego)
│   │   ├── Careers/  Education/  Business/
│   │   ├── Social/             (Relationships, Households, Messaging)
│   │   ├── Simulation/         (Weather, EventDirector, Population, Traffic, Emergencies)
│   │   └── Meta/               (Monetization, Analytics, Moderation)
│   └── client/                 ← StarterPlayerScripts
│       ├── Controllers/        (cámara, vehículos, construcción, NPC ambiente…)
│       └── UI/                 (Teléfono y apps, HUD, pantallas)
├── assets/                     ← modelos exportados (.rbxm) de edificios y vehículos
└── docs/diseno/                ← este documento
```

## 1.6 Herramientas

| Herramienta | Para qué |
|---|---|
| **Rojo** | Sincronizar el código de GitHub con Studio |
| **Wally** | Librerías de la comunidad: ProfileStore (guardado), una librería de UI declarativa, utilidades de tipos y señales |
| **Selene + StyLua** | Revisión de errores y formato automático |
| **Tests** (Jest-Lua) | Tests automáticos de la lógica pura: economía, edades, requisitos |
| **GitHub Actions** | En cada cambio: revisar el código, pasar los tests y generar el `.rbxl` automáticamente |
| **Studio** | Pruebas, importar mallas y publicación |

## 1.7 Qué pasa con la versión 0.1 que ya existe

La versión 0.1 era un **prototipo** para ver algo funcionando. Con esta arquitectura:

| Parte 0.1 | Destino |
|---|---|
| `DataService` | Se sustituye por el módulo Data (ProfileStore + esquema versionado) |
| `Config.luau` | Se reparte en registros de datos |
| `TownBuilder` | Se sustituye por el generador del mundo basado en layout (Fase 2) |
| Trabajos 0.1 | Se convierten en el primer módulo del Motor de actividades ("Rutas") |
| HUD 0.1 | Se reduce al mínimo. Casi todo pasa al teléfono |
| `MonetizationService` | Se mantiene casi igual (recibos idempotentes) |
| Day/Night | Pasa a formar parte de GameClock + Weather |

Rehacer esto ahora cuesta muy poco. Rehacerlo cuando haya 50 sistemas encima sería carísimo.
