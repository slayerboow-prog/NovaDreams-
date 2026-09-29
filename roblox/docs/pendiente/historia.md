# Traspaso de la sesión de HISTORIA (rama `claude/historia`)

Estado al cerrar: todo commiteado y subido. Nada a medias. Últimas pruebas en verde
(test-compile, test-clientboot, test-gameplay y test-lifestory: 450 ✅, 0 fallos).

## Qué estaba haciendo

Contenido de la historia y su continuidad (solo datos de misiones + tests), trabajando sobre lo último de
`origin/claude/roblox-game-d98vy8` (merge antes de cada bloque).

## Hecho en esta sesión (resumen)

- **Saga de la Grieta completa (24 misiones canónicas)**: `src/shared/LifeStory/Misiones/Saga_Acto1..4.luau`.
  Doc: `docs/historia/13-saga-de-la-grieta.md`. Test: sección «Saga de la Grieta · Actos II, III y IV».
- **Rarezas de la Grieta: 24 secundarias (6 por etapa)**: `Misiones/Rarezas.luau`. Cada una da una pieza
  (Items.luau) y un recuerdo (Memories.luau). Test: sección «Rarezas de la Grieta».
- **Misiones de aliados: 7 (una por aliado)**: `Misiones/Aliados.luau` (Bigotes, Rex, Ratón Pérez, Cronos, Capitana Ñoz,
  gnomos, tu yo malvado). Cada una pide su misión loca o de la saga, da recuerdo y pieza, y añade una frase en la
  saga 20 (`If = { Completed = { "Aliado_…" } }`). Test: sección «Misiones de aliados».
- **La colección cuenta en el final**: condiciones nuevas `MemoriesAtLeast` / `MemoriesFewer`
  (`shared/LifeStory/Conditions.luau`). En `Saga_Acto4.luau`, lista `RESTOS`: con ≥4, escena «Restos» y
  Cósimo con 6 de vida en vez de 10. **Al añadir rarezas nuevas, añadir su Memory a `RESTOS`.**
- **Saludos según la hora**: `{Saludo}` / `{saludo}` en `server/Services/DialogueService.luau` (argsFor).
- **Arreglos de motor pequeños** (en `LifeStoryService.luau`):
  - `canOffer`: solo las rutinas (DayPlan / Schedule) esperan al horario del sitio.
  - `activeSideCount`: las canónicas no cuentan para el límite de secundarias.
- **Continuidad**: Cosme secuestrado (saga 12→17) y sin memoria (17→19):
  U2 con frase para Cosme sin memoria; U3 sin tope de etapa y con NotFlags CosmeSecuestrado/CosmeSinMemoria;
  D2 y D3 requieren `CON_COSME` (Loco_Adulto.luau). Bigotes (saga 14) y tu yo malvado (D5) hablan según si ya
  los conoces.

## Pendiente / ideas siguientes (por prioridad)

1. (Opcional) Una segunda misión por aliado, y dos rarezas más por etapa (hasta 8). Recordar: Memory nueva de rareza →
   lista `RESTOS` en Saga_Acto4 (el test comprueba que no falte ninguna).
2. Revisar en Studio los props nuevos de rarezas y aliados (lavadora, cajero, taquilla, gnomos espía, cámaras de la promo).
3. Frase muerta: en Saga_19 (Saga_Acto4.luau, diálogo con Don Escamas) hay una línea con
   `If = { Completed = { "Loco_D3_Tostadora" } }` que ya no puede salir (D3 ahora va después de la saga 19).
   Reescribirla o quitar la condición.
4. Revisar en **Roblox Studio** (NO PUEDO VERIFICARLO desde el entorno): persecuciones (Escape), peleas (Fight)
   y cinemáticas Saga_Fusion / Saga_Final en CimaMonte y Patio; colocación de los props de las rarezas
   (columpio, espejo, caja del gato, buzón de Correos).
5. Estimación de duración: saga ≈ 10–15 h, secundarias (locas + universidad + rarezas) aún por debajo de 15 h.

## Notas para quien siga

- Prueba parcial rápida: `scripts/_loco.luau` se genera con cabecera del test + sección; el contador de fallos
  ahora es `H.failures` (no `failures`).
- Las ofertas se comprueban mejor por `Payload.QuestId` que por título.
- No toqué `server/World/` ni `RealLifeSimulator.rbxl`.
