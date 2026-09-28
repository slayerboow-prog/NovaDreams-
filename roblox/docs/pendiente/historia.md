# Traspaso de la sesión de HISTORIA (rama `claude/historia`)

Estado al cerrar: todo commiteado y subido. Nada a medias. Últimas pruebas en verde
(test-compile, test-clientboot, test-gameplay y test-lifestory: 450 ✅, 0 fallos).

## Qué estaba haciendo

Contenido de la historia y su continuidad (solo datos de misiones + tests), trabajando sobre lo último de
`origin/claude/roblox-game-d98vy8` (merge antes de cada bloque).

## Hecho en esta sesión (resumen)

- **Saga de la Grieta completa (24 misiones canónicas)**: `src/shared/LifeStory/Misiones/Saga_Acto1..4.luau`.
  Doc: `docs/historia/13-saga-de-la-grieta.md`. Test: sección «Saga de la Grieta · Actos II, III y IV».
- **Rarezas de la Grieta: 16 secundarias (4 por etapa)**: `Misiones/Rarezas.luau`. Cada una da una pieza
  (Items.luau) y un recuerdo (Memories.luau). Test: sección «Rarezas de la Grieta».
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

1. **Misiones de aliados** (1–2 por aliado: Bigotes, Rex, Ratón Pérez, gnomos, Cronos, tu yo malvado, Ñoz),
   para que vuelvan con sentido antes del final (saga 20). Documentado como pendiente en el doc 13.
2. **Más rarezas** hasta 6–8 por etapa (ahora 4). Recordar: Memory nueva → lista `RESTOS` en Saga_Acto4.
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
