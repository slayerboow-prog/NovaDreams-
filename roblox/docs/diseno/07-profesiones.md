# Fase 7 — Profesiones

## 7.1 La clave: un Motor de actividades reutilizable

Hacer 40 profesiones con 40 sistemas distintos es inviable. En su lugar hay **~10 tipos de actividad** (minijuegos jugables) y cada profesión combina varios, con su propia ambientación, lugar, herramientas y dificultad.

| Módulo de actividad | Cómo se juega | Profesiones que lo usan |
|---|---|---|
| **Ruta** | Recoger → llevar → entregar, con tiempo y calidad | Repartidor, camionero, taxista, conductor de autobús, piloto, técnico de ambulancia |
| **Atención al cliente** | Clientes (NPC o jugadores) piden. Preparas y sirves con el orden y el tiempo correctos | Camarero, dependiente, cajero, recepcionista, barista |
| **Cocina / producción** | Recetas por pasos (cortar, cocinar, emplatar) | Cocinero, panadero, trabajador de fábrica |
| **Reparación** | Diagnosticar la avería, elegir la pieza y hacer el minijuego de reparación | Mecánico, electricista, fontanero, técnico |
| **Diagnóstico y tratamiento** | Paciente con síntomas → pruebas → diagnóstico → tratamiento | Médico, enfermero, veterinario, cirujano (con un minijuego de quirófano propio) |
| **Emergencia** | Aviso del director de eventos → llegar → resolver (apagar, rescatar, atender, controlar) | Policía, bombero, sanitario |
| **Construcción** | Seguir un plano: colocar estructura y materiales por fases | Constructor, arquitecto (diseña planos), ingeniero (valida) |
| **Oficina / casos** | Puzzles y decisiones: casos legales, código, planificación | Abogado, programador, gerente, agente inmobiliario, periodista (redactar) |
| **Creativo** | Producir contenido que otros ven y valoran: fotos, música, directos, diseños | Fotógrafo, streamer, creador de contenido, músico, artista, diseñador |
| **Enseñanza / entrenamiento** | Dar sesiones a otros jugadores o NPCs | Profesor, entrenador personal, instructor de autoescuela |
| **Cultivo / cuidado** | Ciclos de tiempo: sembrar, regar, cosechar, cuidar animales | Agricultor, ganadero |
| **Deporte** | Entrenamientos y partidos | Deportista |

Cada módulo recibe parámetros desde la definición de la profesión (dificultad, tiempos, recompensas) y devuelve un **resultado de rendimiento** (0–100%) que se usa para calcular el sueldo, la XP y los ascensos.

## 7.2 Definición de una profesión (datos)

```lua
Careers.Medico = {
	Category = "Salud",
	Requirements = {
		MinStage = "AdultoJoven",
		Degrees = { "Grado_Medicina" },          -- estudios necesarios
		Licenses = {},
		Skills = { Medicina = 3 },
	},
	Workplaces = { "Hospital_LosPinos", "Clinica_Centro" },
	Uniform = "Uniforme_Medico",
	Ranks = {
		{ Id = "MIR",          Pay = 180, XPToNext = 2000 },
		{ Id = "Medico",       Pay = 320, XPToNext = 6000, Requires = { Courses = { "Residencia" } } },
		{ Id = "Especialista", Pay = 520, XPToNext = 15000 },
		{ Id = "JefeServicio", Pay = 800 },
	},
	Activities = { "Diagnostico", "Tratamiento", "Emergencia" },
	Shift = { LengthMinutes = 12, NightBonus = 0.25 },  -- minutos reales por turno
	Perks = { "DescuentoFarmacia" },
}
```

`Pay` es el sueldo por turno completado, que se multiplica por el rendimiento.

## 7.3 Ciclo de un turno

1. **Buscar empleo:** app "Empleo" del teléfono u oficina de empleo. Solo aparecen las ofertas cuyos requisitos cumples. Las demás aparecen bloqueadas con el motivo ("Necesitas: Grado en Medicina").
2. **Fichar** en el lugar de trabajo. Te pones el uniforme automáticamente.
3. **Jugar las actividades** durante el turno.
4. **Fin del turno:** resumen con rendimiento, sueldo, propinas, XP y habilidades ganadas.
5. **Ascensos:** con suficiente XP y requisitos llega una evaluación (a veces un curso o examen). Si la superas, subes de rango.

**Horarios:** los turnos se pueden empezar a cualquier hora (los jugadores no pueden cumplir horarios reales), pero la hora del juego importa: turno de noche con plus, cafetería con más clientes por la mañana y discoteca solo de noche.

## 7.4 Catálogo inicial y requisitos

| Profesión | Requisitos | Rangos (resumen) | Lugar |
|---|---|---|---|
| Repartidor | Adolescente + (moto: carnet A1) | Repartidor → jefe de ruta | Correos, restaurantes |
| Dependiente | Adolescente | Dependiente → encargado → gerente | Tiendas, súper |
| Camarero | Adolescente | Camarero → jefe de sala → maître | Restaurantes, hoteles |
| Cocinero | FP Cocina | Ayudante → cocinero → jefe de cocina | Restaurantes |
| Mecánico | FP Mecánica | Aprendiz → oficial → jefe de taller | Talleres |
| Electricista / Fontanero | FP correspondiente | Aprendiz → oficial → autónomo | A domicilio (casas de jugadores y NPC) |
| Constructor | Adulto joven | Peón → oficial → encargado de obra | Obras, parcelas de jugadores |
| Camionero | Carnet C | Local → larga distancia | Polígono, puerto |
| Conductor de autobús | Carnet D | Urbano → interurbano | Líneas de autobús |
| Taxista | Carnet B + licencia de taxi | Taxista → dueño de flota | Toda la región |
| Policía | Academia de Policía (curso) + forma física | Agente → cabo → sargento → inspector → comisario | Comisarías |
| Bombero | Oposición de bombero (curso) + forma física | Bombero → cabo → jefe de parque | Parques de bomberos |
| Enfermero | Grado en Enfermería | Enfermero → supervisor | Hospital |
| Médico / Cirujano | Grado en Medicina + Residencia (+ especialidad en Cirugía) | MIR → médico → especialista → jefe | Hospital |
| Veterinario | Grado en Veterinaria | Veterinario → clínica propia | Clínica, Valle Verde |
| Abogado | Grado en Derecho + máster | Pasante → asociado → socio | Bufetes (Empresarial) |
| Profesor | Grado + máster docente | Profesor → jefe de estudios → director | Colegio, instituto, universidad |
| Ingeniero | Grado en Ingeniería | Junior → senior → director técnico | Oficinas, obras, fábricas |
| Arquitecto | Grado en Arquitectura | Junior → titular → estudio propio | Estudio (diseña planos que usan otros) |
| Programador | Grado en Informática o curso intensivo | Junior → senior → CTO | Empresas tecnológicas |
| Piloto | Licencia de piloto (curso largo y caro) | Copiloto → comandante | Aeropuerto (expansión) |
| Periodista | Grado en Periodismo | Redactor → editor → director | Periódico (escribe las **noticias reales** del juego) |
| Fotógrafo / Streamer / Creador | Ninguno | Por seguidores y reputación | Libre |
| Deportista / Entrenador personal | Habilidad física / curso de entrenador | Amateur → profesional → estrella | Estadio, gimnasios |
| Agricultor | Terreno rural | Pequeño → cooperativa | Valle Verde |
| Agente inmobiliario | Curso inmobiliario | Agente → agencia propia | Inmobiliarias (vende propiedades de jugadores) |
| Empresario | Dinero + (según el negocio) | Ver Negocios | Su empresa |

Las profesiones de toda la lista del concepto caben en estos módulos. Añadir una nueva es crear su entrada de datos, su uniforme, su lugar de trabajo y, como mucho, variantes de un módulo existente.

## 7.5 Profesiones que interactúan con otros jugadores

Son las que hacen que el mundo tenga vida: el mecánico arregla **tu** coche, el médico te atiende **a ti** y el arquitecto diseña **tu** casa.

- Si hay un jugador con esa profesión de servicio en el servidor, las peticiones de los jugadores le llegan a él. Si no hay ninguno, las atiende un NPC (más lento o más caro). Nunca te quedas bloqueado por falta de jugadores.
- **Policía y jugadores:** para evitar acoso, la policía no puede "detener" libremente a jugadores. Actúa sobre infracciones detectadas por el sistema (multas por velocidad o aparcamiento), incidentes NPC (robos a tiendas, accidentes) y emergencias. Los delitos entre jugadores quedan fuera del lanzamiento. Si se añaden, será en servidores o modos opcionales.
