# 14 · La universidad de verdad

La etapa universitaria sigue el ciclo de una carrera real: la nota decide a qué carreras puedes entrar,
vives en la residencia compartiendo habitación con compañeros de tu clase, te haces la compra y la comida,
eliges carrera el primer día y te gradúas aprobando los exámenes (teóricos y físicos) de esa carrera.

## De la selectividad a la matrícula

1. **Selectividad** (`Ins06_LaGranDecision`). Según la nota del examen, se ponen unas marcas:

   | Nota | Marcas | Carreras |
   |---|---|---|
   | 8 o más | `Acceso8`, `Acceso7`, `Acceso6`, `Acceso5` | Todas |
   | 7 | `Acceso7`, `Acceso6`, `Acceso5` | Ingeniería, Derecho y Economía |
   | 6 | `Acceso6`, `Acceso5` | Derecho y Economía |
   | 5 | `Acceso5` | Economía |
   | Menos de 5 | `SuspendeSelectividad` | Convocatoria de **julio**: se estudia y se repite el examen |

   Si en julio vuelve a salir mal, este año solo queda trabajar.
2. **Universidad o trabajar**: la opción «Ir a la universidad» solo aparece si tienes `Acceso5`.
   Las opciones de una decisión ya pueden tener `If`, y el motor solo enseña las que se cumplen.
3. **Matrícula el primer día** (`Uni01_PrimerDia`): en secretaría eliges la carrera. Solo salen las que
   permite tu nota:

   | Carrera | Nota de corte |
   |---|---|
   | Medicina | 8 |
   | Ingeniería | 7 |
   | Derecho | 6 |
   | Economía | 5 |

   La primera noche la pasas ya en la residencia.

La Universidad de Valmar es la única del mapa. Si el mapa añade más campus, cada uno puede pedir su propia
nota de corte con la misma fórmula.

## La vida en la residencia (`Uni01b_Residencia`)

- **Doña Pilar**, la conserje, te da la llave de la habitación 214.
- **Tus compañeros de cuarto son de tu misma clase**:
  - **Iván**: caótico, de Villaverde, obsesionado con el zumo de mora de su abuela.
  - **Candela**: organizadísima, con etiquetas de colores y un Excel para todo.
- **Normas de la nevera** (decisión): etiquetas, nevera compartida o compra por turnos.
- **La comida ya depende de ti**:
  - El supermercado ya vende la **bolsa de la compra** (15, quita mucha hambre).
  - Compras dos bolsas, las guardas en la nevera de la residencia, cenas y duermes en tu cama.
  - Desde aquí, si no compras, no comes (el sistema de hambre de siempre).
- En cuarto curso, «Tu primer piso» (`Uni05`) cuenta que dejas la residencia. Puedes irte a vivir con
  Iván y Candela.

## El ciclo de la carrera (misiones principales, en orden)

| Curso | Misión | Qué pasa |
|---|---|---|
| 1.º | `Uni01_PrimerDia` | Matrícula, facultad, primera clase y primera noche en la residencia |
| 1.º | `Uni01b_Residencia` | Compañeros, normas, compra, nevera y cena |
| 1.º | `Uni02_ElProyecto` | Trabajo en grupo |
| 1.º | **`UniEx1_Enero`** | Exámenes de enero. Método de estudio (horario de Candela, biblioteca o la noche antes con Iván), examen teórico, **prueba física** y recuperación si suspendes |
| 1.º | `Uni03_PrimerTrabajo` | Trabajar y estudiar a la vez |
| 1.º | **`UniEx2_Junio`** | Final de junio, prueba física y **convocatoria de julio** si suspendes |
| 3.º | `Uni04_Practicas` | Prácticas de tu carrera |
| 3.º | **`UniEx3_Parcial`** | El parcial imposible de Beltrán: tutoría, estudio, examen, la prueba física más dura y segunda oportunidad |
| 4.º | `Uni05_PrimerPiso` | Dejas la residencia |
| 4.º | **`UniEx4_TFG`** | Tema del TFG, escribirlo, corregirlo, ensayo con tus compañeros, defensa ante el tribunal y última prueba física |
| 4.º | `Uni06_Graduacion` | La graduación |

**Exámenes de tu carrera**:

- Los teóricos usan `$Carrera.Asignatura1` y `$Carrera.Asignatura2`.
- Las **pruebas físicas** usan `$Carrera.Fisico`: un circuito a tiempo por el estadio. Cada carrera tiene
  el suyo:

  | Carrera | Prueba física |
  |---|---|
  | Medicina | El circuito de urgencias |
  | Ingeniería | La visita de obra |
  | Derecho | La carrera de los juzgados |
  | Economía | El cierre de la bolsa |

La etapa universitaria dura ahora 8 h de juego (`Config.LifeStory.StageHours.AdultoJoven`) en lugar de 5.

## Secundarias con tus compañeros (`Misiones/Uni_Secundarias.luau`)

| Misión | Dónde | Historia | Enlace con la saga |
|---|---|---|---|
| **La guerra del zumo de mora** | Cocina de la residencia | Iván acusa a Candela de beberse su zumo sagrado. La cocina se divide con cinta aislante. Investigas: era Iván, sonámbulo, porque las moras del Monte del Silencio dan sonambulismo. | `MorasDelMonte` |
| **Fiesta en casa de Adrián** | Campus, por la tarde | Compra, baile, el vecino de abajo (que acaba enseñando twist) y la agente Inés. | — |
| **Acampada en el monte** | Residencia | Tienda al revés, moras que brillan, historias de miedo y Blorp (el alienígena del reality), que viene a por moras: la abuela de Iván le vende zumo. | Misión loca U1 |
| **Día de playa** | Playa Dorada | Voley, castillos de arena y Don Pinzas, cangrejo abogado, con un tratado de 1734. | — |
| **El pabellón que no sale en los mapas** | Biblioteca | Un edificio olvidado del campus: el laboratorio del «Proyecto Costura», la máquina que explotó y una foto de Cosme y Cósimo jóvenes. Te persigue un agente gris. | `VioPabellon0` (Acto III) |
| **Una cita (o algo así)** | Residencia | **Opcional y suave**, siempre con un personaje del juego, nunca con otro jugador. Eliges a quién invitar (Julia, Adrián, Luca o Carla), compráis helado y veis el atardecer en la playa. Puedes declararte (os cogéis de la mano), quedar como amistad especial o tirarte el helado encima. | — |
| **El compañero que no existe** | Residencia | Tito sale en todas vuestras fotos, pero no existe: es un espía del Consorcio buscando «al Ancla». Iván y Candela descubren lo de la Grieta si se lo cuentas. | `TitoDescubierto`, `CompisSabenGrieta` |

**Pendientes para la universidad**:

- Más secundarias de campus: el viaje de fin de curso, la novatada que te niegas a hacer, la máquina de
  café que da consejos, el maratón de estudio con alucinaciones.
- Misiones locas con Iván y Candela como compañeros de aventura en la saga (Acto III).
