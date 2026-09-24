# Fase 8 — Educación

## 8.1 Cómo funciona un curso

Todo lo educativo (colegio, instituto, universidad, FP, carnet de conducir, academia de policía) usa **el mismo sistema de cursos**:

```lua
Courses.Grado_Medicina = {
	Level = "Universidad",
	Requirements = { MinStage = "AdultoJoven", Completed = { "Bachillerato_Ciencias" }, MinGrade = 7.0 },
	Fee = 4000,                 -- por "año académico" (hay becas y préstamos de estudios)
	Sessions = 24,              -- clases a completar
	SessionActivity = "Clase_Medicina",  -- minijuego de la clase (quiz, práctica…)
	Exams = { 8, 16, 24 },      -- en qué sesiones hay examen
	Practicum = { Career = "Medico", Shifts = 3 },  -- prácticas en el hospital
	Grants = { Degree = "Grado_Medicina", SkillXP = { Medicina = 1500 } },
	Location = "Universidad_FacultadMedicina",
}
```

- **Sesión de clase = 5–8 minutos reales.** Es una actividad jugable: preguntas, prácticas (poner una vía en un maniquí, montar un circuito, conducir en la autoescuela…) y trabajo en grupo con otros estudiantes presentes.
- Las clases empiezan con frecuencia (cada pocos minutos) y **no a horas fijas reales**. Esperar a que empiece una clase no puede costar más de 1–2 minutos.
- **Profesor:** si hay un jugador profesor en el servidor, puede dar la clase (gana sueldo y los alumnos ganan un bonus). Si no, la da un NPC.
- **Nota final** = asistencia + exámenes + prácticas. La nota abre puertas (mejores ofertas de empleo, becas, acceso a másteres).

## 8.2 Itinerarios

```
BEBÉ ─ Guardería (opcional, habilidades base)
  │
NIÑO ─ Primaria (6 cursos cortos) ── habilidades básicas: lectura, mates, deporte, arte
  │
ADOLESCENTE ─ ESO / Instituto ──┬── Bachillerato Ciencias ──┐
  │                             ├── Bachillerato Letras ────┤
  │                             ├── Bachillerato Artes ─────┤
  │                             └── FP Grado Medio ─────────┤
  │                                                        │
ADULTO JOVEN (18) — DECISIÓN ───────────────────────────────┘
  ├── A) Universidad: Medicina · Enfermería · Derecho · Ingeniería · Informática · Arquitectura
  │                   · Empresa · Periodismo · Educación · Veterinaria · Bellas Artes · CC. del Deporte
  │        └── Máster / Especialidad / Residencia
  ├── B) FP Grado Superior: Mecánica · Electricidad · Fontanería · Cocina · Administración
  │                         · Imagen y Sonido · Sanitario (técnico de emergencias)
  ├── C) Buscar trabajo directamente (profesiones sin título)
  ├── D) Crear negocio (con préstamo o ahorros)
  └── E) Tomarse un tiempo (viajar, trabajos temporales, descubrir habilidades)

EN CUALQUIER MOMENTO (adulto): Cursos especializados
  · Carnets: B (coche), A (moto), C (camión), D (autobús)
  · Academia de Policía · Oposición de Bomberos · Licencia de piloto · Licencia de taxi
  · Curso inmobiliario · Entrenador personal · Programación intensiva · Idiomas (bonus de sueldo)
```

Principios:
- **Ningún camino es el correcto.** Sin universidad también se puede llegar lejos (negocio, oficios que pagan bien, creador de contenido).
- **Se puede volver a estudiar de adulto.** Un mecánico de 35 años puede hacer Ingeniería, más despacio si trabaja a la vez (menos sesiones por semana).
- **Quien empieza a los 18** elige un "pasado" que incluye el instituto terminado con una nota media.

## 8.3 Ejemplo: camino a médico

| Paso | Qué hace el jugador | Tiempo jugado aprox. |
|---|---|---|
| Bachillerato de Ciencias con nota ≥ 7 | Instituto (o pasado elegido) | 3–4 h (o 0) |
| Grado en Medicina | 24 sesiones + 3 exámenes | 4–5 h |
| Prácticas | 3 turnos en el hospital como estudiante | 40 min |
| Graduación | Ceremonia (evento social) | — |
| Residencia (MIR) | Trabaja como MIR cobrando menos y hace la especialidad | 6–8 h |
| Médico titular | Rango completo | — |

Es largo a propósito: ser médico debe sentirse como un logro. Mientras tanto se puede trabajar a tiempo parcial en otras cosas para pagar la matrícula o usar becas y préstamos de estudios.

## 8.4 Infancia en el colegio (que no aburra)

- Clases muy cortas (3–4 min) y muy jugables: minijuegos de mates, deporte en el patio, música, manualidades.
- Recreo con juegos (pilla-pilla, fútbol) y amistades.
- Las notas de primaria y el instituto afectan a las **habilidades de base** y a las becas, no a lo que puedes elegir. Nadie se queda sin futuro por haber sido niño en el juego.
