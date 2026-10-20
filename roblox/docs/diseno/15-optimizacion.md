# Fase 15 — Optimización y seguridad

## 15.1 Objetivos de rendimiento

| Plataforma | Objetivo |
|---|---|
| PC | 60 FPS estables |
| Móvil de gama media | 30+ FPS, memoria contenida, sin cierres por falta de memoria |
| Servidor | Latido (Heartbeat) de 60 Hz sin picos. Tiempo de script por frame dentro de presupuesto |
| Red | < 50 KB/s por jugador en situaciones normales |

## 15.2 Mundo y streaming

- **StreamingEnabled** con radio de streaming ajustado (≈ 512–1.024 studs) y radio mínimo para las zonas cercanas.
- **ModelStreamingMode:** edificios como modelos `Atomic` (llegan completos). Elementos clave (estaciones, grafo visual) `Persistent` solo si es imprescindible.
- El código del cliente **nunca asume** que una parte del mapa existe: espera a que llegue por streaming o usa datos del registro (por ejemplo, el GPS usa el grafo en datos, no las piezas).
- **Presupuesto por casilla:** máximo de piezas, mallas y luces por casilla de 512 studs. Un script de validación lo comprueba en cada build.
- **Interiores:** se cargan por streaming o se instancian bajo demanda (apartamentos).

## 15.3 Geometría y arte

- **Mallas reutilizadas:** la misma farola, árbol o ventana es la misma malla en todo el mapa (Roblox la agrupa al dibujar).
- **Menos piezas, más mallas:** un edificio final debe ser pocas mallas y no cientos de Parts.
- `CollisionFidelity = Box` en decoración. `CanCollide`, `CanTouch` y `CanQuery` desactivados donde no se necesiten.
- Texturas de 1024 px como máximo, salvo excepciones. Materiales estándar y `MaterialVariant` reutilizables.
- **Luces:** pocas luces con sombra. Las farolas lejanas se apagan o se simplifican (LOD de luces), porque en móvil las luces cuestan mucho.

## 15.4 Código

- **Una sola arquitectura de servicios** (sin scripts sueltos en cada objeto). Cero `while true` sin espera y cero `Touched` masivos.
- **Bucles por frecuencia:** necesidades cada 1 s, NPC de ambiente cada 0,1–0,5 s y economía por eventos. Nada pesado en cada frame del servidor.
- **Red por lotes:** los cambios de estado se agrupan. Movimientos de alta frecuencia (tráfico) por `UnreliableRemoteEvent`.
- **Datos replicados mínimos:** el cliente recibe solo lo que necesita ver (su perfil, datos públicos de los jugadores cercanos).
- **Profiling:** MicroProfiler y la consola de desarrollador en cada hito. Medir antes de optimizar.

## 15.5 NPCs y vehículos

Ver Fases 10 y 11: peatones en el cliente con LOD, tráfico cinemático sin físicas, chasis ligero y presupuestos dinámicos.

## 15.6 Seguridad contra exploits (trampas)

| Riesgo | Protección |
|---|---|
| Dar dinero, objetos o XP falsos | Toda la lógica en el servidor. El cliente solo pide acciones y el servidor las valida (distancia, requisitos, coste, frecuencia) |
| Spam de RemoteEvents | Capa `Net` con validación de tipos y límites de frecuencia por jugador y por acción |
| Teletransporte y velocidad | Validación de movimiento en el servidor (distancias imposibles, velocidad máxima según vehículo o etapa) |
| Duplicación entre servidores | Bloqueo de sesión (ProfileStore) y contratos atómicos para intercambios |
| Duplicar compras con Robux | Recibos idempotentes y guardado inmediato |
| Texto inapropiado | `TextService` filtra todo texto de jugadores (nombres de negocio, carteles, mensajes) |
| Abuso económico | Registro de operaciones, alertas de anomalías y herramientas de administrador para revisar y revertir |

## 15.7 Calidad

- **Tests automáticos** de la lógica pura (economía, requisitos, edades, migraciones de datos).
- **GitHub Actions:** revisión de código, tests y generación del `.rbxl` en cada cambio.
- **Entorno de pruebas:** un place de pruebas separado del de producción, con su propio DataStore. Nunca se prueba con los datos reales de los jugadores.
- **Actualizaciones seguras:** migraciones de datos probadas y "feature flags" (activar o desactivar sistemas sin publicar de nuevo) para poder apagar algo que falla.
