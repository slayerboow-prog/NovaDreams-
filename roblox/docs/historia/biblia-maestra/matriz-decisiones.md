# HEROES OF HISTORY — Matriz de decisiones y flags

> Documento de referencia. Versión de cierre del 18-11-2026. Sustituye a las tablas §5.1 y §5.2 del Vol. III.
> 📜 existe en el juego publicado (la clave y los flags no se renombran nunca) · ✅ aprobado · 🟡 propuesta pendiente de
> visto bueno.
> Las claves nuevas son **propuestas de nombre**: no existen en el código hasta su implementación.

## 0. Reglas de la matriz
1. **Ninguna decisión bloquea contenido, progresión ni el final canónico** (garantía de H8). Puede cambiar quién vive,
   cómo se ve un mundo, qué secundarias se abren y el estado de un Sello. Un Sello Herido siempre se puede estabilizar
   con «Reavivar», sin borrar la decisión.
2. **No hay decisiones duplicadas:** si dos decisiones parecen la misma, la tabla explica qué eje distinto toca cada
   una (por ejemplo, Miasma, §4).
3. **Las claves publicadas se conservan.** Si una escena publicada se mueve (P3), su flag se migra (§11), nunca se
   borra.

## 1. Sellos (todas las campañas)

| Punto | Qué es | Flags |
|---|---|---|
| A | Cierre técnico del Acto I. **En Valmar, el cierre de `Gri06`**, no el Árbol (corrección de H8). | 📜 `<Planeta>CierreLimpio` / `CierreSucio`; en Valmar, `GrietaCerrada` + `GriFinal` |
| B | Ritual del Acto V (minijuego) | 🟡 `<Planeta>RitualLimpio` |
| C | La «puerta abierta»: una decisión moral por planeta (en las secciones) | Según el planeta |
| Estado | Pleno (3) / Encendido (2) / Encendido estabilizado (tras «Reavivar») / Herido (0-1) | ✅ `<Planeta>Sello` = Pleno / Encendido / Estabilizado / Herido |

## 2. Valmar

| Clave | Acto | Opciones → Flags | Estado | Consecuencias |
|---|---|---|---|---|
| `AcadManoBrenn` | Academia | Mano / Esperar / Burla | 📜 | Respeto de Brenn (Valmar IV); su discurso como líder |
| `AcadDara` | Academia | `DaraSalvada` / `DaraBengala` | 📜 | Dara en la muralla durante el asedio |
| `GuePatrulla` | Guerrero | `GueGuardiaHueco` / `GueAvisoHueco` | 📜 | Relación con la Guardia |
| `RecAgua` | Reconquista | `AguaHospital` / `AguaReparto` / `AguaGuardia` | 📜 | Quién defiende la muralla en el asedio |
| `RecDiario` | Reconquista | `DiarioSorel` / `DiarioGuardado` | 📜 | Ancla de memoria para la salvación de Sorel |
| `EncOrtal` | Encargos | `OrtalVerdad` / `OrtalMentira` | 📜 | **Prueba 3 del juicio** (Ortal testifica solo si se le dijo la verdad) |
| `EncMedicinas`, `EncTunel`, `EncTavo` | Encargos | (ver misión) | 📜 | Secundarias del asentamiento |
| `GriMaren` | Umbral | `MarenConfia` / `MarenDelatada` | 📜 | Confianza de Ilse (peldaño 1) |
| `GriCajaNegra` | Umbral | `CajaKael` / `CajaMaren` | 📜 | Quién descifra el símbolo del piloto |
| `GriVerdad` | Umbral | `UmbralPublico` / `UmbralKael` / `UmbralPresion` | 📜 | Si es `UmbralPublico`, el asentamiento exige el juicio del Consejo |
| `GriBrenn` | Umbral | `BrennDetenido` / `BrennConvencido` / `BrennLibre` | 📜 | Tono de la deserción de Brenn |
| `GriFinal` | Umbral | `GrietaCerrada` / `GrietaAbierta` / `GrietaHalden` | 📜 | Todo Valmar IV; punto A |
| `ValGreta` | II | Apoyar a la Academia en el Consejo / callar | 🟡 | Tono de Greta durante la campaña |
| `ValPruebas` | II-V | Contador de 0 a 4 pruebas | 🟡 | Ver el juicio |
| **`ValPuertaSur`** | **IV, el asedio** | **Abrir / Cerrar** (decisión única y central) | ✅ (idea) / 🟡 (detalle) | **Abrir:** los refugiados entran detrás de los Velados que dejaron pasar los Hijos de la Ceniza; mueren defensores con nombre; **gana legitimidad la Academia** y pierde el Consejo. **Cerrar:** la muralla aguanta, Ortal mira desde arriba, **el Consejo gana legitimidad** y el Sur no vuelve a fiarse. **Punto C del Sello de Valmar:** abrir. |
| `ValTomas` | V | Brenn termina con él / el jugador / la luz del Árbol | ✅ (Vol. III) | Arco de Brenn |
| `ValJuicio` | V | Juicio público / reforma pactada | 🟡 | **Depende de las pruebas** (§2.1) |

### 2.1 El juicio del Consejo, según las pruebas 🟡

| Prueba | Dónde se consigue |
|---|---|
| 1 · El acta de la orden de las 23:40, con la firma de Greta como testigo | Mazmorra 1, las cloacas del Consejo (Valmar IV) |
| 2 · La denegación del rescate de Kael en 1.211 | El archivo del Consejo, contrastado con el libro de Vossa |
| 3 · El testimonio de Ortal | Solo con `OrtalVerdad` (📜) |
| 4 · El precedente de `UmbralPublico` | Solo si se publicó la verdad del Umbral (📜) |

| Pruebas | Juicio público | Reforma pactada |
|---|---|---|
| 2 o más | Greta es condenada. Valmar queda dividida (pintadas, patrullas), pero la ley ha funcionado. | Greta dimite y la Academia vigila al Consejo |
| 0-1 | El juicio fracasa: Greta queda absuelta y el Sur se subleva | El Consejo sigue igual y el Sur se queda resentido |

## 3. Tefra

| Clave | Acto | Opciones → Flags | Estado | Consecuencias |
|---|---|---|---|---|
| `MarILEN` | Marea | `ILENVoz` / `ILENNeutra` | 📜 | ILEN en Tálasa y Vértice |
| `TefTregua` | I | `TreguaAmbos` / `TreguaCorvo` / `TreguaDalia` | 📜 | Confianza de Dalia o de Corvo |
| `TefCorvo` | I | `TefraVerdad` / `TefraPromesa` | 📜 | La promesa obliga a la Coalición |
| `TefLia` | IV | Traerla / dejarla descansar (decide Cosme, el jugador aconseja y Nela opina) | ✅ | Epílogo de la panadería (H3) |
| `TefNela` | II-V | Relación con Nela (se gana con actos: ninguna frase la arregla) | ✅ | La reconciliación con Cosme |
| `TefCorvoFin` | V | Perdón / entregarlo a Dalia | ✅ (Vol. III) | Dominio unido o partido |

## 4. Miasma: tres decisiones, tres ejes distintos

| Clave | Acto | Eje | Qué se decide | Opciones → Flags | Estado |
|---|---|---|---|---|---|
| `MiaSeis` | I | **Logística:** quién sube primero | Cómo se evacua el Seis | `SeisSube` (todos, poco a poco) / `SeisPrioridad` (primero enfermos y críos) | 📜 |
| `MiaVoto` | III | **Consentimiento:** ¿se respeta lo que vota una comunidad? | El Seis vota si acepta el antídoto | Respetar el voto / imponer el antídoto | 🟡 |
| `MiaCalma` | V | **Método:** cómo se quita la Calma al resto del planeta | Velocidad frente a coste | De golpe / poco a poco | ✅ (Vol. III) |

**Cómo se encadenan** 🟡:
1. **`MiaSeis` decide quién vota.**
   - Con `SeisPrioridad`, los críos y los enfermos ya están arriba: votan los adultos que llevan once años en la niebla, y
     gana quedarse con claridad.
   - Con `SeisSube`, hay familias repartidas entre arriba y abajo: la votación es ajustada y Mara puede hablar antes de
     votar.
2. **La votación es política de verdad:** el resultado depende de `MiaSeis` y de lo que el jugador haya hecho en el Seis
   en los Actos I-II. Puede ganar quedarse o, por poco, aceptar.
3. **`MiaVoto`** solo se pregunta si gana quedarse.
   - **Respetar:** el Seis conserva la Calma y cada persona puede dejarla cuando quiera. El epílogo muestra a la gente
     dejándola poco a poco.
   - **Imponer:** el antídoto va al agua. Las familias del Seis no lo perdonan: es un resentimiento permanente en el
     epílogo y Andrés lo usa en su combate. Es la decisión de más peso moral de Miasma: aunque salga bien, el jugador
     ha decidido por otros.
4. **`MiaCalma` no toca al Seis si se respetó el voto:** se aplica al resto del planeta. No se vuelve a decidir lo mismo.

**Punto C del Sello de Miasma:** `SeisSube` (📜, como estaba previsto).

## 5. Siroco

| Clave | Acto | Opciones → Flags | Estado | Consecuencias |
|---|---|---|---|---|
| `SirLuz` | I | `LuzTrato` / `LuzExpuesta` | 📜 | **Trato:** la Coalición promete proteger a Luz y no llega a tiempo, y Luz cae traicionada. **Público:** Luz cae humillada. Cambia su frase como jefa. |
| `SirBando` | II | Aguadores / Cártel | ✅ | Misiones distintas. Con el Cártel, la alianza de Marisa llega antes; Rafa desconfía. |
| `SirAlianza` | III | Aceptar / rechazar a Marisa | ✅ | Ruta del Acto IV: galerías con sigilo o asalto frontal |
| `SirCarrera` | IV | Corre Rafa / corre el jugador / ruptura | ✅ | Ver abajo |
| `SirRafaVivo` | IV | Resultado (si corre Rafa, depende de la escolta) | ✅ | Rafa herido o muerto |
| `SirNina` | II-V | Relación del jugador con Nina | 🟡 | Si Nina decide ir a la Biblioteca (su decisión) |
| `SirLuzAncla` | V | Resultado (§5.1) | 🟡 | Luz vuelve o se queda Velada |
| `SirMarisa` | V | Juicio / perdón por el acuífero / dejar el Cártel | ✅ | **Juicio:** consejo de aldeas. **Perdón:** Cisternas devueltas. **Cártel:** agua con guardias, deudas y mercenarios en Oren, y **pierde el punto C**. |

### 5.1 Recuperar a Luz: el nombre detona, no salva 🟡

**El nombre es el detonante emocional, no una contraseña.** Luz vuelve (R9) solo si se cumplen **las tres condiciones**:

| Condición | Cómo se cumple |
|---|---|
| **1 · Queda algo de su identidad** | El jugador encuentra en el Archivo de la Biblioteca el registro de racionamiento de Ana Pozo, con el nombre de su hija escrito por ella. Es exploración del Acto V. |
| **2 · Llega alguien que la conoce** | **Rafa**, si vive y está presente; o **Nina**, si ella decide ir (su decisión, según su relación con el jugador, nunca según lo que pasó con Rafa; es menor, así que está en la escena sin combatir ni sufrir daño); o **el jugador**, si tiene un vínculo alto con Luz |
| **3 · Las decisiones del jugador dejaron el vínculo abierto** | Relación con Luz por encima del umbral. Suben esa relación `LuzTrato`, el intento de protegerla en el Acto II y la escena de la lluvia. |

**Si falta cualquiera de las tres**, Luz entrega la llave del Archivo y **se queda Velada**. Puede despertar en
«Liberar» por R9 (tiene cuerpo), si el jugador la recuerda en «La puerta».

**Nina no depende de Rafa:** su supervivencia no depende de ninguna decisión sobre su padre. Es menor (17): nunca sufre daño en pantalla.

### 5.2 Punto C y no bloqueo
- **Punto C del Sello de Siroco:** las válvulas, más no dejar que se quede el Cártel.
- Si al perderlo el Sello queda Herido, **«Reavivar»** lo estabiliza.
- El Cártel sigue en el epílogo de ese jugador y la decisión no se borra.

## 6. Nivalis

| Clave | Acto | Opciones → Flags | Estado | Consecuencias |
|---|---|---|---|---|
| `NivTila` | I | `TilaFarol` / `SorelFarol` | 📜 | Vínculo de Sorel con Tila |
| `NivTocados` | II y IV | Sacarlos / dejarlos para salvar el asalto | ✅ (Vol. III) | Nilo vive o no; punto C |
| `NivBanquete` | III | Desenmascarar a Irsa Orvane / dejarla creer que ha ganado | 🟡 | Orvane se va con Casimir, o su traición se usa más tarde |
| `NivCasa` | IV | Orvane / Selm / Ivel | ✅ (idea) | **Recursos y dificultades** del reinado de Ámbar |
| `NivCasimir` | V | Último farolero / juicio / exilio (decide Ámbar; el jugador opina) | ✅ (Vol. III) | — |
| `NivOsric` | III-V | Apoyarle tras la confesión / dejarle caer | 🟡 | Abdica siempre. Con apoyo, se queda como consejero; sin él, se encierra en su torre. |
| `NivAmbar` | V | **La decide Ámbar**, no el jugador | 🟡 | Ver abajo |

**El reinado de Ámbar** 🟡: lo condicionan cuatro factores, y **elige ella** qué reina quiere ser.

| Factor | Qué aporta |
|---|---|
| `NivCasa` | Con qué recursos y con qué deudas empieza: soldados de Orvane, faroleros de Selm o la lealtad de Ivel |
| `NivCasimir` | Lo que hizo con su tío la define ante la corte |
| `NivOsric` | Si tiene a su padre al lado o en la torre |
| Confianza de Ámbar en el jugador | Con confianza alta, le pide consejo en la coronación. Con confianza baja, decide sola. |

**Desenlaces posibles** (caminos, no castigos automáticos):
- una reina endeudada que paga sus deudas;
- una reina de los faroles;
- una reina pobre y libre;
- combinaciones entre ellas.

## 7. Umbría

| Clave | Acto | Opciones → Flags | Estado | Consecuencias |
|---|---|---|---|---|
| `UmbVarn` | I | `VarnSeguidores` / `VarnAtacado` | 📜 | Cuántos Hijos de la Ceniza vuelven |
| `UmbQuema` | IV | El Vivero / Raíz Honda / el bosque viejo | ✅ (Vol. III) | Qué se pierde; punto C |
| `UmbLysPacto` | V | Prometer no matar a Ithar / negarse | ✅ (auditoría §E) | Confianza de Lys (se puede recuperar en Oren, §10) |

## 8. Tálasa

| Clave | Acto | Opciones → Flags | Estado | Consecuencias |
|---|---|---|---|---|
| `TalCapsula` | II | `MadreNoaDespierta` / `MadreNoaCapsula` | 📜 | Cuándo despierta Irene del todo |
| `TalIrene` | III | Interceder / callar | ✅ | Irene perdona o no a Kael |
| `TalBalsas` | IV | Mantener abiertas las compuertas para los refugiados / cerrarlas | ✅ (H8) | Punto C |
| `TalCompuerta` | V | Intentar ocupar el sitio de Kael / dejarla | ✅ | Variante de su muerte (nunca la evita). **Migra `FinKael` (§11).** |
| `TalCartas` | Tras la muerte | Irene / Noa / guardarlas | ✅ | Epílogo de las cartas |

## 9. Vértice

| Clave | Acto | Opciones → Flags | Estado | Consecuencias |
|---|---|---|---|---|
| `VerVarn` | I | `VarnJuzgado` / `VarnMultitud` | 📜 | Destino de Varn |
| `VerArca` | II | Rechazar las plazas de Octavia / aceptarlas y darlas al Rastro | 🟡 | Quién vive arriba en el epílogo |
| `VerIlse` | III | Buscarla / dejarla ir | ✅ (Vol. III) | Redención o caída: candidata a Pastora |
| `HalvekMarcado` | IV | Marcar la nave de Halvek | Pendiente (H5) | Gancho del Consorcio |
| `VerAgora` | V | Apagarla / aislarla / que ILEN aprenda | ✅ | Ciudad después |
| `VerPeticion` | Tras ÁGORA | Referéndum / ignorar la petición / delegar en ILEN **solo lo técnico** (si aprendió) | 🟡 | **ILEN nunca sustituye la voluntad ciudadana:** gestiona tráfico, agua y mantenimiento. «Les ayudo a elegir. No elijo.» |

## 10. La puerta (Oren)

| Clave | Opciones | Estado | Notas |
|---|---|---|---|
| `LysConfianza` | Se gana en Umbría V. **Se puede recuperar en Oren con una acción significativa**, nunca con una frase: el jugador **sostiene la luz del Árbol Primero** mientras Lys habla con su padre (cinemática dinámica, repetible hasta lograrlo), el mismo gesto que hizo Lys hace 1.214 años. | ✅ (idea) / 🟡 (acción) | Garantiza que «Liberar» nunca quede bloqueado |
| `FinalElegido` | Cerrar / Liberar / Ocupar | ✅ | Requisitos en el Vol. III §6 |
| `PastorElegido` | Jugador / Ilse / Sorel | ✅ / 🟡 | Solo candidatos válidos según R12 y siempre con su aceptación |

## 11. Migración de flags publicados (para P3, no se aplica todavía)

| Flag publicado | Dónde estaba | A dónde pasa | Compatibilidad |
|---|---|---|---|
| `KaelSacrificio` / `KaelSacrificioForzado` (`FinKael`) | `Fin02` | Equivalen a `TalCompuerta` = dejarla / intentarlo | Quien ya los tenga se considera con `TalCompuerta` decidido; no se le vuelve a preguntar |
| `FinalLimpio` / `FinalAPelo` | `Fin02` | Se conservan como variante del epílogo | Sin cambios |
