# Biblia Maestra · Índice y Registro central de continuidad

> HEROES OF HISTORY · «Los Ocho Mundos».
> **Este registro es la fuente de verdad sobre los hechos.** Los seis volúmenes y las misiones se comprueban contra él.
> Ningún nombre, edad, fecha, relación, acontecimiento ni regla del universo cambia sin una entrada en el §4.

---

## 1. Índice de la Biblia Maestra

| Volumen | Archivo | Estado |
|---|---|---|
| 0 · Índice y registro | `00-registro-continuidad.md` | Vivo (se actualiza siempre) |
| I · El universo | `01-universo.md` | v1 · 18-11-2026 |
| II · Los personajes | `02-personajes.md` | v1 · 18-11-2026 |
| III · Las campañas | `03-campanas.md` | v1 · 18-11-2026 |
| IV · Los mundos (un archivo por planeta) | `04-mundos/` | v1 · 18-11-2026: principios y traducción a Roblox; Valmar y Tefra **construibles, para aprobar**; los otros seis, concepto preliminar |
| V · El cine | `05-cine.md` | v1 · 18-11-2026: auditoría del motor, gramática y las 15 grandes secuencias |
| V-b · Estándar cinematográfico | `05b-estandar-cinematografico.md` | v1 · 18-11-2026: las seis referencias del dueño convertidas en reglas (lentes, luz, actuación, montaje, enganche a jugabilidad) |
| VI · MMO, producción y calidad | `06-mmo-y-calidad.md` | Pendiente |
| Reglas del universo (R1-R12) | `reglas-universo.md` | Cierre · 18-11-2026 (fuente de las reglas) |
| Cronología completa | `cronologia.md` | Cierre · 18-11-2026 (fuente de las fechas) |
| Matriz de decisiones y flags | `matriz-decisiones.md` | Cierre · 18-11-2026 (sustituye a Vol. III §5.1-5.2) |
| Matriz de personajes, edades y relaciones | `matriz-personajes.md` | Cierre · 18-11-2026 (sustituye al §6.1) |
| Auditoría de contradicciones y plan de aplicación | `auditoria-cierre.md` | Cierre · 18-11-2026 |
| Auditoría documental final | `auditoria-final.md` | 18-11-2026 (sustituye a la anterior salvo su plan de aplicación) |

**Documentos de trabajo de las decisiones** (historia de cómo se decidió; el canon es lo que recoge este registro):
`auditoria-definitiva.md`, `aprobacion-H1-H14.md`, `revision-final-decisiones.md`.

**Documentos anteriores** (se conservan como historia, pero no son canon cuando contradicen este registro):
- `docs/historia/biblia-narrativa.md` (v1);
- `docs/historia/auditoria-biblia-v1.md`;
- `docs/historia/choques-y-estructura-biblia-maestra.md`;
- `docs/historia/historia-principal-15h.md`.

---

## 2. Jerarquía de fuentes (quién manda si dos cosas chocan)

1. **El texto de las misiones publicadas** (`src/shared/LifeStory/Misiones/`): lo que el jugador ya ha visto. Solo se
   cambia con una entrada en el registro y la aprobación del dueño.
2. **Las decisiones expresas del dueño** (§5).
3. **Este registro.**
4. **Los volúmenes de la Biblia Maestra.**
5. **Las fichas del reparto** (`Cast.luau`). Varias son de antes del cambio de rumbo; si chocan con lo anterior, se
   corrige la ficha (§6).
6. Los documentos antiguos y las misiones retiradas: sirven de material, no obligan.

---

## 3. Procedimiento de cambio (obligatorio)

Antes de cambiar o añadir un hecho:
1. **Buscarlo** en este registro y en los volúmenes (`grep` del nombre o la fecha en `docs/historia/biblia-maestra/`).
2. **Buscarlo en las misiones**: `grep` en `src/shared/LifeStory/Misiones/` y en `Cast.luau`.
3. **Escribir la entrada** en el §4 con: identificador, qué cambia, por qué, fuentes comprobadas, volúmenes afectados y
   misiones afectadas.
4. **Actualizar** los volúmenes afectados en el mismo cambio.
5. Si afecta a lo que el jugador ya vio (misiones publicadas), **pedir aprobación del dueño** antes de tocarlo.
6. **Al terminar cada volumen o planeta:** pasar la lista de comprobación del §7.

---

## 4. Registro de cambios

| ID | Fecha | Cambio | Motivo | Fuentes comprobadas | Afecta a |
|---|---|---|---|---|---|
| RC-001 | 18-11 | **Cosme**: 47 años en el calendario y cuerpo de 70 (regla R4: cruzar cuesta años; **precisado por RC-074:** cuerpo de 71, como dice él) | Choque 1: «nueve años» + «treinta y ocho» frente a 71 en la biblia v1 | `Coalicion_Marea` | Vol. I R4; Vol. II §4.5 |
| RC-002 | 18-11 | **Lía**, hermana de Cosme, es la Velada de Tefra. La abuela se queda como pista. | Choque 2 | `Coalicion_Marea` (lista «esperando a Cosme») | Vol. II §4.5; Vol. III Tefra IV |
| RC-003 | 18-11 | **Kael: dos pérdidas.** 1.194 expedición (secreta) y 1.211 Tefra (escuadra de once, salvó a 2, Ilen muere; **precisado por RC-049:** doce en total, Kael y once). **Corrige la propuesta C3** de la auditoría, que era errónea. | Choque 2 | `Academia` («salvé a dos de once»), `Coalicion_Marea` («hace tres años»), `Guerrero` (foto) | Vol. I §4; Vol. II §4.1 |
| RC-004 | 18-11 | **El voto de Kael:** salió de Valmar para la misión de Tefra (1.211) y después se negó a cualquier expedición fuera de su planeta. Lo rompe en Tálasa III. «Kael nunca sale de Valmar» describe lo que se ve desde Tefra. | Petición del dueño (punto 1) | `Coalicion_Mundos2` («Kael nunca sale de Valmar») | Vol. II §4.1; Vol. III Tálasa III |
| RC-005 | 18-11 | **Irene Ferran**: iba en la expedición de 1.194, volvió por el Ancla en 1.196 (R5), el Consorcio la escondió en la Estación Abisal «Umbral» y revela el secreto de Kael | Choque 3 | `Coalicion_Mundos2` (estación, «mujer mayor», cápsula cedida) | Vol. I §4; Vol. II §7; Vol. III Tálasa III |
| RC-006 | 18-11 | **Valmar cayó en 1.212** y el juego empieza en 1.214 | Choque 4 | `Acad01` («dos años después de la Caída»), `Gri06` («por primera vez en dos años») | Vol. I §4 |
| RC-007 | 18-11 | **Definición de «último bastión»:** Valmar fue el primero en recibir la herida completa y es el único que no se ha rendido (gobierno propio, ningún Heraldo en el poder, fuerza armada, Sello vivo). No es el último en caer. **Ninguna fecha de misión cambia.** | Petición del dueño (punto 2) | `Gri03` («Primera apertura»), `Fin01` («la primera») | Vol. I §4.1 |
| RC-008 | 18-11 | **El Anclaje Seis cayó en 1.203** (once años), no hace 40. La pista de los 40 años pasa al contrato («prueba 6»). | Choque 5 | `Mia02` («once años», «nueve años aquí abajo») | Vol. I §4 y §7; Vol. III Miasma |
| RC-009 | 18-11 | **Andrés** es el exmarido de Mara y quedó abajo cuando el padre de ella cortó el cable | Choque 5 | `Mia02`; `Cast` (Leo, hijo de Mara y Andrés) | Vol. II §2.3 |
| RC-010 | 18-11 | **La falsa victoria:** las grietas del Acto I se cierran, pero los Sellos siguen apagados. Las llamadas hacia el siguiente planeta pasan al Acto V. | Choque 6 | Las 21 misiones de la Coalición | Vol. III §1.3 |
| RC-011 | 18-11 | **Dos tipos de Heraldo:** ya eran del Coro (Tomás, Casimir, ÁGORA) o caen durante la campaña (Corvo, Andrés, Luz Pozo, Savia, Coria) | Choque 7 | Finales de las misiones de la Coalición | Vol. II §2 |
| RC-012 | 18-11 | **Nivalis:** el rey **Osric** firmó y **Casimir Varga**, su hermano y regente, negoció. Desarrollo completo con Ámbar y la caída. | Choque 7 + petición del dueño (punto 3) | `Niv01`-`Niv03` («Mi padre firmó», la torre, el balcón) | Vol. II §2.5 |
| RC-013 | 18-11 | Tomás (el «Teo» de la v1) dijo que sí muriendo; ÁGORA eligió por cálculo; **Halvek** es antagonista humano, no Heraldo | Choque 8 | Biblia v1 | Vol. II §2.1, §2.8, §2.9 |
| RC-014 | 18-11 | **Ithar en Vértice** aparece con un cuerpo de ceniza (R8); en carne solo en Oren. **Lys** está escondida en la Semilla de Umbría. | Choque 9 | `Umb03` (la semilla verde) | Vol. I R8; Vol. II §1.3, §4.8 |
| RC-015 | 18-11 | El final implementado se reparte: la flota pasa a «La puerta» y la muerte de Kael a Tálasa. Finales personales; mundo canónico. | Choque 10 | `Fin01`-`Fin03` | Vol. III §2.9 y §6 |
| RC-016 | 18-11 | **Decisiones personales y mundo compartido**: confirmado. **La muerte de Kael es un hecho fijo**; las decisiones cambian circunstancias y consecuencias, nunca el sacrificio. | Petición del dueño (punto 4) | — | Vol. II §4.1; Vol. III §6.3 |
| RC-017 | 18-11 | Princesa de Nivalis: **Ámbar** (antes Ilse) | Anexo de choques: nombres | `Cast.PrincesaIlse` | Vol. II §2.5 |
| RC-018 | 18-11 | **El hermano de Brenn se llama Tomás**, no «Teo». La decisión del dueño se mantiene: el hermano de Brenn es el Heraldo de Valmar. Solo cambia el nombre, al que ya tiene en el juego. | **Choque nuevo** al escribir el Vol. II: el juego ya le nombra | `Gri04` («B. y T.: Brenn y Tomás», «Del Sur, de Tomás»); el balón «Teo» de `Saga_Acto1` es de una misión antigua retirada | Vol. I §7; Vol. II §2.1; Vol. III Valmar |
| RC-019 | 18-11 | **El Heraldo de Siroco es Luz Pozo**, no Marisa Duna. La biblia v1 mezcló a las dos: la madre muerta de sed y la dueña del agua son de Luz. **Marisa se conserva** como secundaria (Cholo, la Gran Vuelta). | **Choque nuevo** | `Sir01`-`Sir03` (tumba de Ana Pozo, «Mi madre murió de sed», «la dueña del agua»); `Siroco_Episodio` (retirado: Marisa y Cholo) | Vol. II §2.4 y §7; Vol. III Siroco |
| RC-020 | 18-11 | **La voz de las 3:12 es Halden.** El pulso de once segundos es el Coro. La voz de Adrián, el hijo de Ilse, llega por el pulso, no por las 3:12. | **Choque nuevo**: la biblia v1 decía que las 3:12 eran la voz de Ithar o del hijo | `Gri01` («Aquí Halden»), `Mar01` (once segundos) | Vol. I §3.5; Vol. II §6 |
| RC-021 | 18-11 | **El hijo de Ilse: Adrián Maren**, 19 años, voluntario del hospital del Sur, murió en la Caída. Es un personaje nuevo: el juego no lo menciona. | Hacía falta para la escalera de Ilse | grep de «hijo» con Maren: sin resultados | Vol. II §4.4 y §6 |
| RC-022 | 18-11 | **Tocar el Sello en el Umbral:** el generador del Umbral está construido sobre las raíces del Árbol Ancestral; accionarlo es tocar el Sello (R7). No cambia ningún texto. | **Choque nuevo**: la biblia v1 decía «toca el Sello», y en el juego se acciona el generador | `Gri06` | Vol. I R7; Vol. II §3.1 |
| RC-023 | 18-11 | **«Primera apertura»:** el Umbral de Valmar fue la primera apertura **completa**. Las anteriores (1.174-1.211) eran perforaciones pequeñas, las «anclas». | **Choque nuevo**: la pancarta «Primera apertura» y «la primera grieta» frente a los 40 años del Consorcio | `Gri01`, `Fin01`, `Ver02` | Vol. I §3.3 y §4 |
| RC-024 | 18-11 | **Cláusula 19 en 1.207** (siete años de noche), no en 1.208 | **Choque nuevo** | `Niv01` («siete años de noche») | Vol. I §4; Vol. II §2.5 |
| RC-025 | 18-11 | **Abril Cruz** es conservadora del museo, no periodista | **Choque nuevo** | `Ver01` | Vol. II §7 |
| RC-026 | 18-11 | **Nilo**, hermano de Tila: su farol se apagó, le «encontraron» tocado y la guardia de Casimir se lo llevó a los sótanos | **Choque nuevo**: la misión dice que «le encontramos» y la ficha que «se lo llevó la guardia» | `Niv02`, `Cast.Tila` | Vol. II §2.5 y §7 |
| RC-027 | 18-11 | **Kael fundó la Academia en 1.213**, no «años después de la expedición» | **Choque nuevo** | `Fin01` («hace un año esto era un colegio») | Vol. I §4; Vol. II §4.1 |
| RC-028 | 18-11 | Valmar IV-V va entre `Mar01` y `Mar02`. La Coalición se funda tras la muerte de Tomás. | Orden de la campaña | `Mar01` («una semana después del Umbral»), `Mar02` («Primera parada: Tefra») | Vol. III §2.1 |
| RC-029 | 18-11 | **Varn: «Amadeo»** (firma «A. Varn»). **El rey de Nivalis: Osric.** La reina: Liv. La madre de Savia: Hiedra. Los hijos de Corvo: Darío y Marco. | Nombres nuevos, comprobados contra el reparto para que no se repitan | `Cast` | Vol. II |
| RC-030 | 18-11 | **El sol de Nivalis** se enciende en el Acto I con la reserva, sin el Sello. Casimir lo vuelve a apagar en el Acto II. El corazón del Sello se enciende en el Acto V. | Falsa victoria aplicada a Nivalis | `Niv03` | Vol. II §2.5; Vol. III Nivalis |
| RC-031 | 18-11 | **El Sello de Valmar es el Árbol Ancestral** del Santuario del Bosque (Bosque Etéreo), (la biblia v1 usaba otro nombre, retirado: ver RC-053). Su **Raíz Mayor** recorre el subsuelo hasta el Distrito Central. | Nombre ya en el juego | `Kit/ForestSanctuary`, `Kit/AncientTree`, `SanctuaryService` | Vol. I §3.3; Vol. IV Valmar |
| RC-032 | 18-11 | **La guerra de noventa años de Tefra** es entre el Dominio de Bastión y su luna **Ovilla**. La resistencia de Dalia son los **Desertores del Ovillo**. Tobi Renn es capitán de la Milicia de Ovilla. | Choque nuevo: la v1 decía «Dominio contra resistencia» | `Tef01` («los que no quieren luchar en su guerra»), `Tef02` («noventa años»), `docs/planetas/diseno-mundos.md` §3.1 | Vol. I §4; Vol. II §7; Vol. IV Tefra |
| RC-033 | 18-11 | **La abuela de Cosme es Nilda**, maestra (Campus Nilda, estatua del Mirador). El **Huerto de Nilda** es donde se abrió el agujero de 1.176; ya no es «el experimento de Cosme». | Choque nuevo con el diseño antiguo | `TefraCity` (estatua, campus), `diseno-mundos.md` | Vol. II §4.5; Vol. IV Tefra |
| RC-034 | 18-11 | **Valmar en tres capas:** el Jardín de los Tejedores, la Valmar moderna (la ciudad existente, que vuelve en el epílogo) y el asentamiento. La **Sala del Corte** está bajo el edificio del Consejo, con el generador del Umbral en su centro. | Dirección de arte | `Gri03`, `Gri06` | Vol. IV Valmar |
| RC-035 | 18-11 | **Nombres de ciudad conservados** del diseño antiguo: Bastión Ceniza, Anclaje Siete, Puerto Calcina, Fortaleza Albor, Raíz Honda, Abisalia y Distrito Cero | Continuidad con lo construido | `docs/planetas/*` | Vol. IV |
| RC-036 | 18-11 | **Reinterpretaciones del diseño antiguo:** el coral negro de Tálasa es el Coro bajo el agua; el Enjambre de Umbría son las máquinas de la Compañía Torca; la «invasión del Dominio Talar» de Miasma se retira (la sustituye la Calma) | Choque nuevo | `docs/planetas/resumen.md` | Vol. IV |
| RC-037 | 18-11 | **«Teo» eliminado** de la biblia y de los documentos (biblia v1, auditoría, choques). Los «Teo» que quedan en el código son **otros personajes**: el hermano de Nico en la saga antigua retirada (`Saga_Acto1`, `Guiones/Saga_05_Perdidas`) y nombres de prueba en los tests. No se refieren al hermano de Brenn. | Orden del dueño | grep de «Teo» en todo el repositorio | Todos |
| RC-038 | 18-11 | **Luz Pozo y Marisa Duna, separadas:** Luz es la hija que perdió a su madre, Ana, por la sed, y la dueña del agua. Marisa es la madre que perdió a su hijo, Cholo, en la Gran Vuelta, una carrera por agua. No se mezclan. | Aclaración: el mensaje del dueño atribuía a Luz «la madre que perdió a su hijo», que en el juego es de Marisa | `Sir02`, `Siroco_Episodio` | Vol. II §2.4 y §7; documentos antiguos corregidos |
| RC-039 | 18-11 | **La reina de Nivalis:** la Estatua Rota de la Plaza de los Faroles es la de la **reina Liv** | Diseño antiguo (Fortaleza Albor) | `docs/planetas/nivalis-umbria.md` | Vol. II §2.5; Vol. IV Nivalis |
| RC-040 | 18-11 | **El Palacio de Escarcha** (ladera norte) es la corte de Casimir; los tocados van a sus sótanos. El gancho antiguo «Nilo vivo en las Minas» (episodio retirado) se sustituye. | Continuidad | `nivalis-umbria.md` | Vol. II §2.5; Vol. IV Nivalis |
| RC-041 | 18-11 | ✅ **Siroco (H2):** Luz Pozo sigue siendo Heraldo (cae en el Acto III, es la jefa del Acto V y conserva la pista «la voz no recuerda mi nombre»). **Marisa Duna**, unos 60 años, es la antagonista humana: jefa del Cártel de las Cisternas. | Aprobación del dueño | `Sir01`-`Sir03`, `Cast` | Vol. II §2.4 y §7; Vol. III Siroco; matriz de decisiones §5 |
| RC-042 | 18-11 | ✅ **Luz es exmujer de Rafa** (dato del reparto) y **su hija es común** (decisión del dueño). Es **Nina Quiroga**, 17 años, que ya existe en el reparto (`Cast.luau:433`). Es menor: tiene postura propia y su supervivencia no depende de ninguna decisión sobre Rafa. | Choque N3 + decisión D10 | `Cast.luau:432, 433, 434` | Matriz de personajes §4.4 |
| RC-043 | 18-11 | ✅ La matriz de consecuencias de Siroco. ✅ **La recuperación de Luz** exige tres condiciones (identidad, alguien que la conoce, vínculo abierto): el nombre detona, no salva. | D9 con corrección del dueño | — | Matriz de decisiones §5.1 |
| RC-044 | 18-11 | **Rafa Quiroga tiene 47 años** (no «~50») | Choque nuevo: el §6.1 contradecía al reparto | `Cast.luau:432` | Matriz de personajes |
| RC-045 | 18-11 | ✅ **Nela** (25), hija de Lía (45) y de Ulises († 1.201), sobrina de Cosme. La reconciliación se gana. | H3 | `Coalicion_Marea`, RC-001, RC-033 | Vol. II §4.5; matriz de personajes |
| RC-046 | 18-11 | ✅ **Cronología de Kael e Irene** con fechas fijas: la expedición, el **9-10-1.194**; el juego empieza en **primavera de 1.214**; Tálasa, en **noviembre de 1.214**; La puerta, en **1.215**. Kael sale hacia Tálasa **«por primera vez desde que volvió de Tefra»** (sustituye a «por primera vez en tres años»). | D1 con corrección del dueño | Ver cronología §6 | Cronología; Vol. II §4.1; Vol. III Tálasa |
| RC-047 | 18-11 | ✅ **La expedición de 1.194 eran nueve:** Kael, Irene y siete más. Kael dejó a ocho; murieron siete; Irene sobrevivió. **Kael cree muertos a los ocho** y no sabe que Irene vive hasta Tálasa III. | D3, D4 | Vol. II («nueve», corregido), auditoría («siete») | Vol. I §4; Vol. II §4.1 |
| RC-048 | 18-11 | ✅ **Cómo sobrevivió Irene:** apagó la luz y se dejó llevar por los Hilos hasta el Ancla (R5); salió en 1.196 envejecida (R4); el Consorcio la recogió y la silenció a cambio de la custodia de Noa | Corrección pedida por el dueño | R4, R5, RC-005 | Cronología §5.1 |
| RC-049 | 18-11 | ✅ **Tefra, 1.211:** escuadra de doce; dos salvados; Ilen muere sosteniendo la plataforma; Kael vuelve después de la Caída; los dos salvados mueren en la Caída por la orden de Varn. ✅ **Logística** (aprobada como propuesta de canon y comprobada en la auditoría final): los salvados se llaman **Oriol** (navegante, pilota la nave de vuelta con el retorno asistido) y **Renata** (sanitaria); los otros ocho mueren en la Lanza; los Desertores del Ovillo sacan a Kael de Tefra en 1.212; el Consejo le negó el rescate. | D2 con corrección del dueño | `Academia`, `Guerrero`, `Coalicion_Marea`, `Fin02` | Cronología §5.2; Vol. II §4.1 |
| RC-050 | 18-11 | ✅ **Ilen ≠ ILEN:** Ilen es la persona († 1.211); ILEN es la IA entrenada con su caja negra | Norma del dueño | `Cast.luau:261` | Todos |
| RC-051 | 18-11 | ✅ **Las veinte cartas** (1.195-1.214): hablan del presente; la de 1.211, escrita en Tefra, se queda **sin terminar** y no explica nada; solo la última habla de la compuerta. Kael **no entrega el fajo** cuando Irene lo pide; la entrega, tras su muerte, la decide el jugador. | D1 con corrección del dueño | — | Vol. II §4.1 |
| RC-052 | 18-11 | ✅ **R11, la raíz profunda**, con la redacción y los cinco límites del dueño. Ithar salvó la **conciencia** de Lys, no su cuerpo. | D5 | R2, R8, R9, R10 | `reglas-universo.md` §2; Vol. I §3.4 y §5.5 |
| RC-053 | 18-11 | ✅ El árbol joven **«Garza»** es **descendiente directo** del árbol madre de Umbría, conectado por la raíz; **no es un árbol-Sello**. ✅ **Nombre oficial del Sello de Valmar: «Árbol Ancestral»**, el de las 8 apariciones del juego. No tiene segundo nombre. | D5 + comprobación | `Umb03`; `Kit/AncientTree`, `SanctuaryService` | `reglas-universo.md` §2 |
| RC-054 | 18-11 | ✅ **Los tres finales con postura propia:** Cerrar = la supervivencia nacida del miedo; Liberar = dejar ir (canónico); Ocupar = sostener. Lys: sola en la Semilla en «Cerrar»; descansa con Ithar en «Liberar»; en «Ocupar», **guía a los olvidados sin salir de su anclaje** y descansa, siempre que el nuevo Pastor lo **autorice voluntariamente**. | D6, D7 con corrección del dueño | R6, R9, R11 | Vol. III §6 |
| RC-055 | 18-11 | ✅ **R12, la corona:** solo pasa por entrega voluntaria y con **aceptación consciente** de quien la recibe; nunca es automática. El cuerpo de ceniza de Ithar se deshace al cederla. El jugador conserva cuerpo, personaje y continuidad en el MMO. ✅ Encaje de cada candidato con R7 (Ilse dentro del Coro por la Consola; Sorel en la tercera fase y con consentimiento lúcido; el jugador por el Umbral). | D8 con corrección del dueño | R7, R8 | `reglas-universo.md` §3; Vol. III §6 |
| RC-056 | 18-11 | ✅ La confianza de Lys se puede recuperar en Oren **con una acción significativa**, nunca con una frase. ✅ La acción: sostener la luz del Árbol Primero mientras Lys habla con su padre. | Corrección del dueño | — | Matriz de decisiones §10 |
| RC-057 | 18-11 | ✅ **«Reavivar el Sello» (H8):** estabiliza sin borrar decisiones, puntos ni consecuencias. Ningún Sello bloquea contenido, progresión ni el final canónico. **El punto A de Valmar es el cierre de `Gri06`**, no el Árbol. | H8 | `Gri06` | Vol. III §5.3; matriz de decisiones §1 |
| RC-058 | 18-11 | ✅ (idea) / ✅ (detalle) **Política de Valmar:** Greta Albar (secretaria de actas: certificó en el libro de actas la orden de las 23:40, que en la copia publicada solo firma Varn; tramitó la denegación del rescate de 1.211; estaba en la lista del refugio blindado); **la puerta sur es una única decisión central del asedio**; el juicio depende de las pruebas reunidas (0-4). | D11 con corrección del dueño | `EncOrtal`, `GriVerdad` | Matriz de decisiones §2; matriz de personajes §4.1 |
| RC-059 | 18-11 | ✅ **Miasma:** `MiaSeis` (logística, publicada), `MiaVoto` (consentimiento) y `MiaCalma` (método) son tres ejes distintos y no duplican la decisión | Corrección del dueño | `Coalicion_Mundos1:107` | Matriz de decisiones §4 |
| RC-060 | 18-11 | ✅ **Nivalis:** la Casa elegida condiciona los recursos del reinado de Ámbar; el desenlace depende también de Casimir, de Osric y de la confianza de Ámbar; **la que elige qué reina ser es Ámbar** | Corrección del dueño | — | Matriz de decisiones §6 |
| RC-061 | 18-11 | ✅ **Vértice:** ILEN puede administrar sistemas técnicos limitados (tráfico, agua, mantenimiento), **nunca sustituir la voluntad ciudadana**. ✅ Octavia Prill y Ciro Mallo, pendientes de comprobación final. | Corrección del dueño | — | Matriz de decisiones §9 |
| RC-062 | 18-11 | ✅ **Ada → Lía (H14):** Ada es el nombre antiguo de la misma hermana (episodio retirado). Cambian **siete** textos (seis visibles y la ficha de Ernesto); los identificadores internos se conservan. **Aplicación pendiente del plan de `auditoria-cierre.md`.** | H14 / D12 | Búsqueda global (7 apariciones vigentes) | Vol. IV Tefra; P-8 |
| RC-063 | 18-11 | ✅ **Criosueño de emergencia:** ralentiza el envejecimiento a tres cuartas partes. El chico tiene 21 años de calendario y un cuerpo de 19-20: adulto, sin cambiar el texto de `Tal02`. | N6 | `Tal02` | Cronología §5.3 |
| RC-064 | 18-11 | ✅ **P3 · Reubicación:** las frases de Kael de `Fin01` y el mensaje de Ilen de `Fin02` pasan a Tálasa III; «¿Sabes por qué nunca salía de Valmar?» pasa a Tálasa V. **Aplicación pendiente del plan.** | D13 | `Fin01`, `Fin02` | Vol. III Tálasa y §2.9 |
| RC-065 | 18-11 | ✅ **Cine:** tres modalidades (completa, dinámica y ambiental); una cinemática completa por acto como criterio general, con excepciones justificadas | Aprobación del dueño | — | Vol. V y V-b |
| RC-066 | 18-11 | ✅ **Calendario de campañas 1.214-1.215**, comprobado contra todos los «hace X años» publicados | Comprobación pedida por el dueño | Cronología §4 y §6 | Cronología |
| RC-067 | 18-11 | **Choque nuevo:** el epílogo publicado de `Fin03` dice «En Siroco… nadie paga por el agua», lo que choca con el desenlace del Cártel; también da por hecho «una madre y una hija bucean juntas». Necesita variantes por decisión al reescribir el final. | Detectado en la auditoría de cierre | `Fin03` | P-10 |
| RC-068 | 18-11 | ✅ **R4 ampliada:** envejece atravesar sin Sello una anomalía temporal (una grieta, una perforación o un tramo de los Hilos expuesto, inestable o cortado). Las rutas estables por los Hilos no envejecen, salvo excepción documentada. | Decisión del dueño | Cosme, Halden, Irene, Kael (1.194) | `reglas-universo.md`; Vol. I §3.4 |
| RC-069 | 18-11 | ✅ **Nina Quiroga** (17): su primera carrera es corta, local y segura; nunca la Gran Vuelta; tiene agencia y objetivos propios | Decisión del dueño | `Cast.luau:433`; Nina solo aparece en contenido retirado (`Siroco_Episodio`, `Guiones/Siroco_01`) | Vol. III §4; matriz de personajes |
| RC-070 | 18-11 | ✅ **En «Cerrar», la raíz profunda se rompe** con el Árbol Primero: Lys queda limitada a su propio árbol (la Semilla, «Garza» y el árbol madre) | Hueco detectado en la auditoría final | R11 | `reglas-universo.md` §2 |
| RC-071 | 18-11 | **Nombres cambiados para evitar parecidos:** la sanitaria de Tefra pasa de «Mirta» a **Renata** (había una «Marta» en el reparto) y la cabeza de la Casa Orvane, de «Irsa» a **Celia** (parecido a Irene). Aprobados por el dueño. | Auditoría final | `Cast.luau:103` (Marta) | Cronología; matrices |
| RC-072 | 18-11 | **La prueba 1 del juicio es el libro de actas**, no la orden: la orden publicada solo la firma Varn. Greta estaba en la lista del refugio blindado. | Choque detectado con `Gri03` | `Grieta_Umbral` (Orden, Lista) | Matriz de decisiones §2.1; matriz de personajes §4.1 |
| RC-073 | 18-11 | ✅ **Q1, opción A · «Ocupar»:** el nuevo Pastor deja volver a las mentes con cuerpo e identidad propia (R9); conserva a su cargo a las que recuerdan sin cuerpo; los olvidados descansan con Lys; no alimenta el Coro con mentes nuevas. **No es «Liberar»:** allí el Coro termina; aquí se conserva una parte bajo una responsabilidad nueva. | Decisión del dueño | R9, R11, R12 | Vol. III §6.2; Vol. V; reglas §3; matriz de decisiones §10 (`OcupadoCoro`) |
| RC-074 | 18-11 | ✅ **R4 calibrada:** desgaste según la intensidad y el tiempo subjetivo dentro, distinto del desfase de calendario. **Irene:** 11 días subjetivos en un tramo cortado (≈ 1,6 años por día) = +18; dos años de desfase por R5; 44 de cuerpo en 1.196 y ≈ 60 en 1.214. **Kael:** una hora en el tramo = 3-4 semanas. **Cosme:** pago único de +24 en una grieta naciente (cuerpo de 71, 📜). **Halden:** +1-2. | Aclaración obligatoria del dueño | `Coalicion_Marea` («setenta y un años»), `Tal02` («mujer mayor»), R5 | `reglas-universo.md` §3 bis; cronología §5; matriz de personajes |
| RC-075 | 18-11 | ✅ **Recuperación de Luz con flags verificables:** `SirLuzIdentidad`, `SirLuzAncla`, `SirLuzVinculo`, `SirLuzProtegida` y `SirNinaBiblioteca` deciden `SirLuzVuelve` / `SirLuzVelada` | Y5 con condición del dueño | — | Matriz de decisiones §5.1 |
| RC-076 | 18-11 | ✅ **La confianza de Lys es un recorrido** (`LysConfianza`) que culmina en `LysRelevo`; siempre se puede completar | Y4 con condición del dueño | — | Matriz de decisiones §10 |
| RC-077 | 18-11 | **La cronología no da por hecho el nombre «Ensayo»** mientras H7 esté sin decidir | Auditoría de cierre | — | Cronología §2 |

---

## 5. Decisiones del dueño (no se cambian sin él)

| Fecha | Decisión |
|---|---|
| 18-11 | Dirección general aprobada: ópera espacial de fantasía oscura, adulta, una película interactiva dentro de un MMORPG |
| 18-11 | **Unas 88 h** de campaña, sin recortar profundidad, secundarias importantes, cinemáticas, personajes, exploración ni enfrentamientos |
| 18-11 | **Kael muere en Tálasa sosteniendo la compuerta** (hecho fijo) |
| 18-11 | **Ilse Maren traiciona al grupo** |
| 18-11 | **Tomás**, el hermano de Brenn, es el Heraldo y jefe de Valmar (confirmado: sustituye definitivamente a «Teo») |
| 18-11 | **Luz Pozo** es la jefa de Siroco; **Marisa** es secundaria independiente (confirmado) |
| 18-11 | **La voz de las 3:12 es Halden**; el Coro habla por el pulso de once segundos (confirmado) |
| 18-11 | **Antes de construir cada planeta**, el dueño aprueba su concepto visual, arquitectura, materiales, distribución y edificios emblemáticos |
| 18-11 | La Biblia Maestra y este registro son la **referencia oficial** de HEROES OF HISTORY |
| 18-11 | Semillas muy tempranas de la traición de Ilse y del deterioro de Sorel |
| 18-11 | **Arquitectura propia en cada planeta**, como proyecto específico que empieza por Valmar y Tefra. Innegociable: nada de un generador común con otros colores. |
| 18-11 | Seis volúmenes conectados por este registro |
| 18-11 | No se toca código ni se construyen misiones hasta que la Biblia Maestra esté sólida |
| 18-11 | No se modifican sistemas que funcionan sin auditarlos antes |
| 18-11 | **Aprobados:** H2 (Siroco), H3 (Nela), H8 (Reavivar), H11 (política, para desarrollo), las tres modalidades de cine, D3, D4, D6, D7, D10 (hija común de Rafa y Luz) y D12 (Ada → Lía). **Aprobados con correcciones:** D1, D2, D5, D8, D9, D11, D13 y N6 (ver RC-041 a RC-067). |
| 18-11 | **Rechazado:** que Lys herede la corona (la propuesta B′) |
| 18-11 | **Aprobados** C1-C9, Y1-Y11 y Q1 (opción A). Queda cerrado todo lo marcado 🟡 hasta RC-072. **Pendientes:** solo H5, H6, H7, H10, H12 y H13 (P-11). |
| 18-11 | **Las reglas del universo no se adaptan a cada escena** |
| 18-11 | Aprobar una historia **no autoriza a implementarla:** todo cambio de contenido publicado o de código necesita antes un plan (archivos, IDs y flags conservados, partidas guardadas, pruebas de regresión y reversión) |

---

## 6. Hechos fijos (la tabla que todo el mundo consulta)

### 6.1 Personas (edad en 1.214)
La tabla completa está en **`matriz-personajes.md`**, que es la fuente de edades, fechas de nacimiento, estados y
relaciones. Correcciones de esta versión: Rafa tiene 47 años (RC-044); personas nuevas: Nela, Ulises, Greta
Albar, Oriol, Renata, Celia Orvane, Bertil Selm, Edda Ivel, Octavia Prill y Ciro Mallo.

### 6.2 Fechas clave
- 0: Gran Corte.
- 1.124: empieza la guerra de Tefra.
- 1.174: nace el Consorcio.
- 1.176: Cosme cae por la grieta.
- 1.194: la expedición.
- 1.196: vuelve Irene.
- ~1.200: la Cúpula Honda.
- 1.203: cae el Seis.
- 1.204: muere Cholo.
- 1.207: Cláusula 19.
- 1.208: el Glaciar y la Estación Abisal.
- 1.211: Kael en Tefra.
- 1.212: la Caída de Valmar y la cascada.
- 1.213: caen los demás mundos y se funda la Academia.
- 9-10-1.194: la expedición de nueve.
- 1.211 (noviembre): Tefra; muere Ilen.
- 1.214 (primavera): empieza el juego.
- 9-10-1.214: la vigésima carta de Kael.
- 1.214 (noviembre): Tálasa; muere Kael.
- 1.215: La puerta.

Detalle completo en **`cronologia.md`**, que manda sobre el Vol. I §4.

### 6.3 Reglas del universo
R1-R12 en **`reglas-universo.md`** (R11, la raíz profunda; R12, la corona). **No se añade ni se cambia una regla sin una entrada en el registro aprobada por el dueño. Las reglas no se adaptan a la escena.**

### 6.4 Hechos fijos que ninguna decisión cambia
- Kael muere en Tálasa V sosteniendo la compuerta.
- Tomás muere en Valmar V.
- Ilse abre el Nudo en Tálasa IV.
- Sorel toca el Coro en Nivalis V.
- Ithar muere en los tres finales.
- Halvek huye en el Arca.
- El mundo compartido termina liberado y vuelve la ciudad de antes.

---

## 7. Lista de comprobación de continuidad

Se pasa al terminar cada volumen o cada planeta:
- [ ] ¿Cada nombre nuevo se ha buscado en `Cast.luau` y en las misiones, sin repetir otro?
- [ ] ¿Cada edad cuadra con las fechas del §6.2?
- [ ] ¿Cada fecha respeta lo que dicen las misiones publicadas?
- [ ] ¿Cada relación coincide con el §6.1 y con el mapa (Vol. II §8)?
- [ ] ¿Cada regla usada está en R1-R12 y se respetan sus límites?
- [ ] ¿Cada giro tiene al menos dos pistas sembradas antes (Vol. I §7)?
- [ ] ¿Algún hecho fijo (§6.4) queda en entredicho?
- [ ] ¿Todo cambio tiene su entrada en el §4?

**Resultado de la pasada del 18-11-2026 (volúmenes I-III):** se comprobaron contra las misiones de Academia,
Guerrero, Reconquista, Grieta-Umbral, las de la Coalición, el final y `Cast.luau`. Aparecieron los choques nuevos
RC-018 a RC-027, que ya están resueltos en los volúmenes.

---

## 8. Pendientes de continuidad (vigilados)

| # | Pendiente | Qué hacer | Cuándo |
|---|---|---|---|
| P-1 | **Fichas antiguas del reparto:** Cosme («vecino inventor», «investigador de la Grieta»), Lía («midió la Grieta… desapareció la noche de la Caída»), Andrés («Anclaje Siete»), Noa («Estación Meridiana, coral negro»), Brenn y Sorel marcados como adolescentes | Reescribir sus `Bio` en `Cast.luau` | Al empezar la producción (paso 4), con auditoría previa |
| P-2 | **Nombres repetidos en el reparto:** dos «Tavo» (guardia de Valmar y aguador de Siroco); dos «Lía» (la hermana de Cosme y una farolera antigua de Nácara); dos «Bruma» (la vieja Bruma de Miasma y la buceadora de Tálasa); «Irene» la entrenadora (vida antigua) e Irene Ferran | Proponer al dueño: aguador → «Telmo», la vieja Bruma → «la vieja Ceniza»; la farolera y la entrenadora son de contenido retirado | Antes de Siroco y Miasma |
| P-3 | **Escala de Rel:** los umbrales del Vol. II §8.3 (≥ 20 / ≤ −10) están sin calibrar contra los valores reales del juego | Auditar la escala de Rel en el código | Antes de escribir variantes |
| P-4 | **«La Marea ha tocado este mundo primero»** (Umbría, `Umb01`) | Canon: Umbría es el primer mundo donde la ceniza de la Marea aparece físicamente. Los demás cayeron por grietas, bestias y Heraldos. | Vol. IV Umbría |
| P-5 | **El mundo de `Gue04` y `Gri05`** («el planeta más cercano a la Grieta») | Canon provisional: el **Mundo Ceniza**, un mundo ya devorado del Otro Lado | Vol. IV |
| P-6 | **Monetización del diseño antiguo:** el pase premium con multiplicadores (XP ×1,15, recolectar ×1,2…) choca con «sin pay-to-win» | Revisar en el Vol. VI antes de tocar `BattlePass*` | Vol. VI |
| P-7 | **Clasificación:** el diseño antiguo dice «13+ Moderado»; el público es 17+ | Fijar en el Vol. VI y en el cuestionario de Roblox | Vol. VI |
| P-8 | **Ada → Lía en Tefra** (texto del juego construido): el marco de la puerta «Cosme 8 · Ada 6» (`TefraCityBuilder`), el «Mirar» de `TefraCity`, el recuerdo `CasaDeCosme` y `CandadoDeAda` (`Memories`) y los objetos `BufandaAda` y `CandadoAda` (`Items`). La historia publicada llama **Lía** a la hermana de Cosme. | ✅ **Aprobado por el dueño** (RC-062): siete textos, identificadores intactos. Se aplica solo con el plan de `auditoria-cierre.md`. | Antes de construir Tefra |
| P-9 | **Mazmorras instanciadas** y **jefes por fases**: no existe el sistema (auditado: no hay servicio de mazmorras) | Auditoría técnica y diseño en el Vol. VI | Antes de la producción de Valmar V |
| P-10 | **El epílogo de `Fin03`** da por hecho un resultado único («en Siroco nadie paga por el agua», «una madre y una hija bucean juntas») | Variantes por decisión al reescribir los finales (RC-015, RC-067) | Con P3 |
| P-11 | **Propuestas sin decidir:** H5 (Halvek pelea para huir), H6 (registro de revelaciones), H7 («Ensayos»), H9 (resto de reglas del Pastor, cubiertas en parte por RC-054 y RC-055), H10 (capas personal, compartida y canónica), H12 (psicología y regla de menores) y H13 (clasificación) | El dueño las aprueba o las rechaza | Antes de la producción de Valmar |
| P-12 | ~~Nombre del Sello de Valmar~~ | **Cerrado** (RC-053): «Árbol Ancestral» | — |
