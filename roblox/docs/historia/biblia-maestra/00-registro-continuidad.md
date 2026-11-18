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
| RC-001 | 18-11 | **Cosme**: 47 años en el calendario y cuerpo de 70 (regla R4: cruzar cuesta años) | Choque 1: «nueve años» + «treinta y ocho» frente a 71 en la biblia v1 | `Coalicion_Marea` | Vol. I R4; Vol. II §4.5 |
| RC-002 | 18-11 | **Lía**, hermana de Cosme, es la Velada de Tefra. La abuela se queda como pista. | Choque 2 | `Coalicion_Marea` (lista «esperando a Cosme») | Vol. II §4.5; Vol. III Tefra IV |
| RC-003 | 18-11 | **Kael: dos pérdidas.** 1.194 expedición (secreta) y 1.211 Tefra (escuadra de once, salvó a 2, Ilen muere). **Corrige la propuesta C3** de la auditoría, que era errónea. | Choque 2 | `Academia` («salvé a dos de once»), `Coalicion_Marea` («hace tres años»), `Guerrero` (foto) | Vol. I §4; Vol. II §4.1 |
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
| RC-031 | 18-11 | **El Sello de Valmar es el Árbol Ancestral** del Santuario del Bosque (Bosque Etéreo), el «Árbol Antiguo» de la v1. Su **Raíz Mayor** recorre el subsuelo hasta el Distrito Central. | Nombre ya en el juego | `Kit/ForestSanctuary`, `Kit/AncientTree`, `SanctuaryService` | Vol. I §3.3; Vol. IV Valmar |
| RC-032 | 18-11 | **La guerra de noventa años de Tefra** es entre el Dominio de Bastión y su luna **Ovilla**. La resistencia de Dalia son los **Desertores del Ovillo**. Tobi Renn es capitán de la Milicia de Ovilla. | Choque nuevo: la v1 decía «Dominio contra resistencia» | `Tef01` («los que no quieren luchar en su guerra»), `Tef02` («noventa años»), `docs/planetas/diseno-mundos.md` §3.1 | Vol. I §4; Vol. II §7; Vol. IV Tefra |
| RC-033 | 18-11 | **La abuela de Cosme es Nilda**, maestra (Campus Nilda, estatua del Mirador). El **Huerto de Nilda** es donde se abrió el agujero de 1.176; ya no es «el experimento de Cosme». | Choque nuevo con el diseño antiguo | `TefraCity` (estatua, campus), `diseno-mundos.md` | Vol. II §4.5; Vol. IV Tefra |
| RC-034 | 18-11 | **Valmar en tres capas:** el Jardín de los Tejedores, la Valmar moderna (la ciudad existente, que vuelve en el epílogo) y el asentamiento. La **Sala del Corte** está bajo el edificio del Consejo, con el generador del Umbral en su centro. | Dirección de arte | `Gri03`, `Gri06` | Vol. IV Valmar |
| RC-035 | 18-11 | **Nombres de ciudad conservados** del diseño antiguo: Bastión Ceniza, Anclaje Siete, Puerto Calcina, Fortaleza Albor, Raíz Honda, Abisalia y Distrito Cero | Continuidad con lo construido | `docs/planetas/*` | Vol. IV |
| RC-036 | 18-11 | **Reinterpretaciones del diseño antiguo:** el coral negro de Tálasa es el Coro bajo el agua; el Enjambre de Umbría son las máquinas de la Compañía Torca; la «invasión del Dominio Talar» de Miasma se retira (la sustituye la Calma) | Choque nuevo | `docs/planetas/resumen.md` | Vol. IV |
| RC-037 | 18-11 | **«Teo» eliminado** de la biblia y de los documentos (biblia v1, auditoría, choques). Los «Teo» que quedan en el código son **otros personajes**: el hermano de Nico en la saga antigua retirada (`Saga_Acto1`, `Guiones/Saga_05_Perdidas`) y nombres de prueba en los tests. No se refieren al hermano de Brenn. | Orden del dueño | grep de «Teo» en todo el repositorio | Todos |
| RC-038 | 18-11 | **Luz Pozo y Marisa Duna, separadas:** Luz es la hija que perdió a su madre, Ana, por la sed, y la dueña del agua. Marisa es la madre que perdió a su hijo, Cholo, en la Gran Vuelta, una carrera por agua. No se mezclan. | Aclaración: el mensaje del dueño atribuía a Luz «la madre que perdió a su hijo», que en el juego es de Marisa | `Sir02`, `Siroco_Episodio` | Vol. II §2.4 y §7; documentos antiguos corregidos |
| RC-039 | 18-11 | **La reina de Nivalis:** la Estatua Rota de la Plaza de los Faroles es la de la **reina Liv** | Diseño antiguo (Fortaleza Albor) | `docs/planetas/nivalis-umbria.md` | Vol. II §2.5; Vol. IV Nivalis |
| RC-040 | 18-11 | **El Palacio de Escarcha** (ladera norte) es la corte de Casimir; los tocados van a sus sótanos. El gancho antiguo «Nilo vivo en las Minas» (episodio retirado) se sustituye. | Continuidad | `nivalis-umbria.md` | Vol. II §2.5; Vol. IV Nivalis |

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

---

## 6. Hechos fijos (la tabla que todo el mundo consulta)

### 6.1 Personas (edad en 1.214)

| Persona | Edad | Hecho clave | Fuente |
|---|---|---|---|
| Kael | 46 | Valmaresa; 1.194 expedición; 1.211 Tefra; 1.213 Academia; muere en Tálasa V | RC-003, 004, 027 |
| Sorel | 19 | Del Sur, calle del mercado; su padre murió en el refugio del campus; toca el Coro en Nivalis V | `Acad01`, `Rec04` |
| Brenn | 20 | Hermano de Tomás; llamada de las 23:52; espada «B. y T.» | `Gri03`, `Gri04` |
| Tomás | † a los 17 (1.212) | Heraldo de Valmar | RC-018 |
| Ilse Maren | 52 | Dirigió el Umbral; madre de Adrián | `Gri01`, RC-021 |
| Adrián Maren | † a los 19 (1.212) | Voluntario del hospital del Sur | RC-021 |
| Halden | ~40 | Compañera de Ilse; 2 años al otro lado; voz de las 3:12 | `Gri01`, `Gri06` |
| Cosme | 47 (cuerpo de 70) | Calle del Horno; cayó en 1.176; hermana Lía | RC-001 |
| Lía | (Velada) | Hermana de Cosme | RC-002 |
| Ilen | † 1.211 | Segunda de Kael; su voz es la de ILEN | `Coalicion_Marea` |
| Amadeo Varn | ~56 | Orden de las 23:40; Plan Puerta; destino `VerVarn` | `Gri03`, `Ver02` |
| Augusto Halvek | ~75 | Primer contacto de Ithar en 1.174; huye en el Arca | Vol. II §2.9 |
| Bastián Corvo | ~60 | Dominio; hijos Darío y Marco | `Tef02` |
| Andrés | ~45 | Exmarido de Mara; once años en el Seis | RC-009 |
| Mara Solis | 41 | Madre de Leo | `Cast` |
| Leo Solis | 15 | Hijo de Mara y Andrés | `Cast` |
| Luz Pozo | 42 | Heraldo de Siroco; su madre Ana murió de sed cuando Luz tenía 12 años | RC-019 |
| Rafa Quiroga | ~50 | Aguador; Cholo murió por su culpa | `Sir01`, `Siroco_Episodio` |
| Osric Varga | 61 | Rey de Nivalis; firmó la Cláusula 19; mudo desde 1.207 | RC-012 |
| Casimir Varga | 56 | Regente; Heraldo de Nivalis | RC-012 |
| Ámbar Varga | 23 | Heredera; «muerta» en 1.208 | RC-017; `Cast` |
| Tila | 16 | Farolera; hermano Nilo | `Cast`, `Niv02` |
| Savia | ~50 | Alcaldesa y después Madre Savia; hija Nía; madre Hiedra | RC-011, 029 |
| Nía | 10 | Hija de Savia; Dron 7 | `Umb02`; `Cast` |
| Coria | ~58 | Cúpula Honda (~1.200) | Vol. II §2.7 |
| Noa Ferran | ~26 | Hija de Irene | `Tal01` |
| Irene Ferran | 46 (cuerpo mayor) | Expedición de 1.194; Estación Abisal | RC-005 |
| Abril Cruz | ~35 | Conservadora del museo | RC-025 |
| Gil | ~30 | Ayudó a construir ÁGORA | Vol. II §2.8 |
| Ithar | >1.260 | Rey-tejedor de Oren | Vol. I §5 |
| Lys | (mente) | Hija de Ithar; en la Semilla | RC-014 |

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
- 1.214: empieza el juego.

Detalle completo en Vol. I §4.

### 6.3 Reglas del universo
R1-R10 (Vol. I §3.4). **No se añade una regla sin una entrada en el registro.**

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
- [ ] ¿Cada regla usada está en R1-R10?
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
| P-8 | **Ada → Lía en Tefra** (texto del juego construido): el marco de la puerta «Cosme 8 · Ada 6» (`TefraCityBuilder`), el «Mirar» de `TefraCity`, el recuerdo `CasaDeCosme` y `CandadoDeAda` (`Memories`) y los objetos `BufandaAda` y `CandadoAda` (`Items`). La historia publicada llama **Lía** a la hermana de Cosme. | **Necesita aprobación del dueño** (texto que el jugador ve). Propuesta: cambiar a «Lía» en el texto visible y mantener los identificadores internos. | Antes de construir Tefra |
| P-9 | **Mazmorras instanciadas** y **jefes por fases**: no existe el sistema (auditado: no hay servicio de mazmorras) | Auditoría técnica y diseño en el Vol. VI | Antes de la producción de Valmar V |
