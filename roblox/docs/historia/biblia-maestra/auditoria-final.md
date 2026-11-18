# HEROES OF HISTORY — Auditoría final de coherencia · Biblia narrativa cerrada

> 18-11-2026. **Versión documental cerrada.** No queda ninguna decisión narrativa pendiente.
> Las auditorías anteriores (las primeras versiones de este archivo y `auditoria-cierre.md`) se conservan en el
> historial de git. De `auditoria-cierre.md` sigue vigente su §6: el plan de aplicación de Ada → Lía y de P3.
> **No se ha tocado el juego:** ni misiones, ni diálogos publicados, ni código, ni `Cast.luau`.

## 1. Documentos del canon cerrado

| Documento | Qué es la fuente de |
|---|---|
| `00-registro-continuidad.md` | Los hechos y el historial de cambios (RC-001 a RC-085) |
| `01-universo.md` (Vol. I) | Mitología, reglas resumidas, los Ensayos, la cronología resumida y las revelaciones |
| `02-personajes.md` (Vol. II) | Personajes, arcos, la regla de menores |
| `03-campanas.md` (Vol. III) | Campañas, finales y epílogo |
| `04-mundos/`, `05-cine.md`, `05b-estandar-cinematografico.md` | Mundos y cine |
| `reglas-universo.md` | R1-R12 con su redacción oficial y R4 calibrada |
| `cronologia.md` | Todas las fechas |
| `matriz-decisiones.md` | Todas las decisiones y flags |
| `matriz-personajes.md` | Edades, estados y relaciones |
| `capas-mmo.md` | Las tres capas del MMO |

## 2. Decisiones incorporadas en esta versión

| Decisión | RC | Dónde |
|---|---|---|
| H5 · Halvek lucha para escapar y siempre huye; marcar su nave no cambia nada | RC-078 | Vol. II, Vol. III Vértice IV, matriz §9, hechos fijos |
| H6 · Nueve revelaciones principales (REV-1 a REV-9) y giros secundarios (G-MUNDO-n) | RC-079 | Vol. I §7; referencias renumeradas en Vol. II, III y IV |
| H7 · Siete Ensayos (ENS-año-MUNDO); el Anclaje Seis es una instalación | RC-080 | Vol. I §3.6 y §4, Vol. III, Vol. IV Tefra, cronología |
| H10 · Las tres capas del MMO | RC-081 | `capas-mmo.md` |
| H12 · Deseo, decisión y desenlace propios; regla de menores | RC-082 | Vol. II §4.9-4.10 |
| H13 · Narrativa adulta sin contenido explícito; sin etiqueta prometida | RC-083 | Registro (P-7 cerrado) |
| R4 · Cifras definitivas con fórmula y unidades | RC-084 | Reglas §3 bis, cronología |
| Lys nunca entra en el Coro por la fuerza ni obliga a su padre | RC-085 | Vol. II §4.9 |

## 3. Comprobaciones

### 3.1 R4: los cuatro casos con la misma regla
D = I × t (años de cuerpo = a/h × horas subjetivas) y T = F × t (horas de calendario).

| Caso | I (a/h) | t (h) | D (años) | F | T | ¿Cuadra con lo publicado? |
|---|---|---|---|---|---|---|
| Irene | 0,068 | 264 | 0,068 × 264 = **18,0** | 66,5 | 17.556 h = **2,0 años** | «Una mujer mayor» (`Tal02`): ≈ 60 de cuerpo con 46 de calendario ✅ |
| Kael | 0,034 | 1 | **0,034 ≈ 12 días** | 33 | **33 h** | Ningún texto habla de su aspecto ✅ |
| Cosme | 8.640 | 0,00278 | **24,0** | ≈ 1 | ≈ 10 s | 9 + 24 + 38 = **71**: «setenta y un años» (`Coalicion_Marea`) ✅ |
| Halden | 9 | 0,167 | **1,5** | ≈ 1 | ≈ 10 min | «Lleva dos años» (`Gri05`) = calendario normal ✅ |

**Sin explicaciones retroactivas que contradigan lo publicado:**
- Kael «salió el 10-10» es un dato nuevo, pero no choca con nada publicado.
- «Cuarenta» años de Cosme frente a 38 es una forma de hablar del propio personaje.

### 3.2 Las nueve revelaciones

| Comprobación | Resultado |
|---|---|
| Una por mundo y Oren como novena y última | ✅ REV-1 Valmar … REV-8 Vértice, REV-9 Oren |
| Las principales están separadas de los giros secundarios | ✅ 11 giros G-MUNDO-n (Tomás, Lía, Andrés, Luz, Ámbar, Coria, Irene viva, Ilse, Halvek, Greta y la muralla) |
| No quedan referencias a la numeración antigua «giro n» | ✅ 0 en el canon (14 referencias renumeradas) |
| Cada revelación tiene pistas en campañas anteriores | ✅ (Vol. I §7.1) |
| Los identificadores REV y G no chocan con R1-R12 ni con el código | ✅ 0 coincidencias en `src` |

### 3.3 Los Ensayos

| Comprobación | Resultado |
|---|---|
| Son siete, como dice el juego («Siete grietas abiertas por el Consorcio») | ✅ |
| Fechas frente a los textos publicados | ✅ Miasma: «hace once años, cuando el Consorcio abrió la grieta» (1.203). Siroco: el estudio «de hace veinte años» (1.194) es posterior a ENS-1190. Nivalis: «sol artificial» (1.207). Tálasa: «por primera vez en seis años» (1.208). Umbría: «treinta años» (1.184). Tefra: Cosme (1.176). |
| El mismo identificador se escribe igual en todos los documentos | ✅ 7 identificadores, 30 apariciones, sin variantes |
| El Anclaje Seis conserva su nombre de instalación y su relación está documentada | ✅ (Vol. I §3.6) |
| No queda «prueba 6» en el canon | ✅ Solo en entradas históricas del Registro y en la frase que lo aclara |

### 3.4 Las tres capas y los tres finales

| Comprobación | Resultado |
|---|---|
| Ninguna decisión personal cambia el mundo de otros | ✅ (`capas-mmo.md` §1 y §3) |
| Estado neutral definido para planetas, personajes de destino variable, PNJ y cielos | ✅ §2 |
| Transiciones y juego en grupo definidos | ✅ §3 y §4 |
| «Cerrar», «Liberar» y «Ocupar» respetan las capas | ✅ §5 y §6. El final personal se vive entero y después se entra en el mundo canónico («Liberar»). |
| El jugador Pastor sigue jugando | ✅ R12 |

### 3.5 Identificadores, flags y nombres

| Comprobación | Resultado |
|---|---|
| Las 24 decisiones publicadas conservan su clave y sus flags | ✅ (matriz §2-§9) |
| Claves nuevas que coinciden con el código | ✅ 0 (45 claves y flags nuevos) |
| Claves definidas dos veces | ✅ 0 |
| `HalvekMarcado` no altera el resultado | ✅ |
| Nombres nuevos sin duplicados ni parecidos | ✅ (Renata, Celia y los demás comprobados) |
| Ningún 🟡 en el canon | ✅ Solo aparece en las leyendas, que dicen «hoy no queda ninguno» |

### 3.6 Sincronía entre documentos

| Hecho | Registro | Vol. I | Vol. II | Vol. III | Cronología | Matrices | Reglas | Capas |
|---|---|---|---|---|---|---|---|---|
| Kael, Irene y los doce de Tefra | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| R4 y sus cifras | ✅ | ✅ | ✅ (Cosme) | — | ✅ | ✅ | ✅ | — |
| R11, R12 y los finales con Q1 | ✅ | ✅ | ✅ | ✅ | — | ✅ | ✅ | ✅ |
| Revelaciones | ✅ | ✅ | ✅ | ✅ | — | — | — | — |
| Ensayos | ✅ | ✅ | — | ✅ | ✅ | — | — | — |
| Halvek | ✅ | — | ✅ | ✅ | — | ✅ | — | — |
| Menores | ✅ | — | ✅ | ✅ (Nina) | — | ✅ | — | — |
| Siroco, Luz y Nina | ✅ | — | ✅ | ✅ | ✅ | ✅ | — | — |

**Resultado: los documentos cuentan la misma historia.**

## 4. Lo que queda fuera del canon narrativo (no son decisiones narrativas)

| Tema | Dónde | Cuándo |
|---|---|---|
| Aplicar Ada → Lía (7 textos) y P3 (reubicar las frases de Kael e Ilen) | Plan en `auditoria-cierre.md` §6 | Cuando el dueño autorice la implementación |
| P-1 y P-2 (fichas antiguas y nombres repetidos de `Cast.luau`) | Registro §8 | Con la producción de Valmar |
| P-3 (calibrar la escala de relación) | Registro §8 | Antes de escribir variantes |
| P-9 (mazmorras y jefes por fases) y la auditoría técnica de las capas (`WorldState`, `StageSets`, `HappeningService`) | Registro §8; `capas-mmo.md` | Antes de programar Valmar |
| P-10 (variantes del epílogo de `Fin03`) | Registro §8 | Con P3 |
| La clasificación de Roblox | RC-083 | Con el contenido desarrollado |

## 5. Estado
- **Biblia narrativa: cerrada.** No queda ninguna decisión narrativa pendiente.
- **Juego, misiones, diálogos publicados y código: sin tocar.**
- El commit es local (ver el mensaje de cierre de la sesión). No se ha subido a ninguna rama remota ni se ha publicado.
