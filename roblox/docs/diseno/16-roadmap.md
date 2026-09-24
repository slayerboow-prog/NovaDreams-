# Fase 16 — Roadmap de desarrollo

## 16.1 Filosofía

- **Hitos jugables.** Cada hito termina con algo que se puede jugar y probar, no con "código a medias".
- **Cimientos primero, contenido después.** Los hitos M0–M2 construyen la base sobre la que todo lo demás crece sin rehacer.
- **Lanzar pronto y mejorar con datos.** Una alfa pública con la vida adulta nos dirá qué gusta antes de invertir meses en lo demás.
- **El arte va en paralelo, hecho por código.** Kits de calle, fachadas y viviendas generados siguiendo los estándares de arte, mejorados distrito a distrito.

Las duraciones son orientativas (semanas de trabajo conjunto: yo programo y tú pruebas en Studio y decides). El arte se hace por código a la vez que los sistemas.

## 16.2 Hitos

### M0 — Cimientos técnicos (2–3 semanas)
- Núcleo: ServiceLoader, Net (validación y límites), EventBus, GameClock, Localización ES/EN.
- Datos: ProfileStore, esquema de Cuenta y Personaje v1, migraciones, admin de datos.
- Registros de contenido con validación.
- Herramientas: Wally, Selene, StyLua, tests y GitHub Actions que genera el `.rbxlx`.
- Panel de administrador y comandos de depuración.
- **Resultado:** una base vacía pero sólida. Se reaprovecha lo útil de la v0.1.

### M1 — Esqueleto del mundo: Valmar núcleo (3–4 semanas)
- Layout en datos de la región completa (distritos marcados) y **generación en gris** de Centro, Los Pinos y San Roque.
- Grafo de carreteras y aceras. Terreno, costa y montes lejanos.
- Parcelas estándar, zonas ("Estás en: San Roque") y streaming configurado.
- Sistema de interacciones unificado.
- Teléfono v1 (estructura y app Mapa/GPS).
- **Resultado:** puedes recorrer una ciudad grande en gris con GPS.

### M2 — Rebanada vertical: "Una vida" (6–7 semanas) → **ALFA**
- Vida: nacer en una familia NPC, etapas con edad por tiempo jugado. Infancia y adolescencia en versión **simplificada** (colegio e instituto básicos) para llegar a la vida adulta, que es el foco de este hito.
- Necesidades (hambre, energía, higiene, diversión) y habilidades.
- Economía: libro contable, banco, tarjeta, facturas semanales e impuesto simple.
- Motor de actividades con 4 módulos: Ruta, Atención al cliente, Cocina y Reparación.
- 6 profesiones: Repartidor, Dependiente, Camarero, Cocinero, Mecánico, Taxista.
- Viviendas: habitación, estudio (interior instanciado) y casa, en alquiler y compra.
- Vehículos básicos: bici y 3 coches, garaje, gasolina y carnet B.
- Teléfono: Banco, Empleo, Propiedades, Vehículos y Perfil.
- Monetización básica (VIP rebalanceado, garaje).
- **Resultado:** primer juego publicable. Alfa con amigos y probadores.

### M3 — Educación, infancia y adolescencia completas (4–5 semanas)
- Sistema de cursos completo: primaria, instituto, bachilleratos, FP y 4 grados universitarios.
- Carnets y cursos especiales. Distrito Universitario en gris.
- Etapas bebé, niño y adolescente con escala, límites y colegio jugable.
- Nacer en una familia de jugadores (con el sistema de hogares básico).
- Profesiones con título: Enfermero, Médico, Profesor, Programador.

### M4 — Ciudad viva (5–6 semanas) → **BETA PÚBLICA**
- Ciudadanos virtuales, peatones en el cliente y NPC de servicio.
- Tráfico NPC y semáforos. Autobuses y tren L1.
- Clima y estaciones.
- Director de eventos y emergencias. Policía, Bomberos y Sanitarios jugables.
- Noticias.
- Distrito Empresarial.

### M5 — Social y familias (4 semanas)
- Amigos, contactos y mensajería entre servidores.
- Hogares, roles y casa compartida (según las normas de Roblox).
- Hijos jugadores y NPC, cuidado de bebés.
- "Ir con mi familia" y servidores privados.
- Arte final del Centro y Los Pinos.

### M6 — Construcción y mercado (5–6 semanas)
- Modo construcción y catálogo de muebles (con la línea NovaDreams).
- Terrenos urbanizables, compraventa y alquiler entre jugadores (contratos).
- Hipotecas y préstamos completos.
- Arquitecto, Constructor y Agente inmobiliario.
- Colinas del Mirador (lujo) y Valmar Norte.

### M7 — Negocios (5–6 semanas)
- Crear empresa, local, empleados (jugadores y NPC) y clientes.
- Contabilidad, reputación y beneficios pasivos con tope.
- Polígono Industrial y Playa Dorada.
- Resto de profesiones de servicios.

### M8 — Legado y profundidad (5 semanas)
- Envejecimiento completo hasta adulto mayor, jubilación y pensión.
- Legado, herencia, árbol genealógico y generaciones.
- Bolsa de Valmar e inversiones.
- Valle Verde, Villaverde y granjas (Agricultor, Veterinario).

### M9+ — Operación continua
- Aeropuerto y viajes (places de destino), Piloto.
- Nuevos distritos y segunda región.
- Eventos de temporada mensuales, nuevas profesiones y vehículos.
- Equilibrado de la economía con datos reales.

## 16.3 Calendario resumido

```
Semanas:  0    4    8    12   16   20   24   28   32   36   40   44   48
M0 ██
M1    ████
M2        ██████ ◆ ALFA
M3              █████
M4                   ██████ ◆ BETA PÚBLICA
M5                         ████
M6                             ██████
M7                                   ██████
M8                                         █████ ◆ VERSIÓN 1.0
Arte  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ (en paralelo, continuo)
```

Aproximadamente **un año hasta una 1.0 completa**, con juego público desde la beta (~semana 20). Es una estimación: dependerá del ritmo de pruebas y del arte.

## 16.4 Lo que necesito de ti en cada hito

- **Probar** cada entrega en Studio y contarme qué falla o qué no te gusta.
- **Decidir** en los puntos de diseño abiertos (ver el índice).
- **Publicar** y gestionar la experiencia en Roblox (cuenta, grupo, monetización).
- **Arte:** importar en Studio las mallas 3D que te prepare (un clic por lote) y darme tu opinión sobre el aspecto visual.
