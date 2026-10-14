# Fase 10 — Vehículos y transporte

## 10.1 Tipos

| Tipo | Requisito | Ejemplos |
|---|---|---|
| Bicicleta / patinete | Niño+ | Urbana, de montaña, eléctrica |
| Moto | Carnet A1 (16+) / A | Scooter, naked, deportiva |
| Coche | Carnet B | Utilitario, familiar, SUV, deportivo, lujo, eléctrico |
| Furgoneta / camión | Carnet B / C | Reparto, mudanzas, tráiler (profesión) |
| Autobús | Carnet D (profesión) | Urbano |
| Vehículos de servicio | Profesión | Patrulla, ambulancia, camión de bomberos, grúa, taxi |
| Tractor / maquinaria | Granja u obra | Tractor, excavadora |
| Barco (expansión) | Licencia náutica | Lancha, velero |

## 10.2 Datos de cada vehículo

```lua
Vehicle = {
	Id = "v_...", ModelId = "Utilitario_A", Owner = "c_123",
	Color = Color3, Mods = { Wheels = "...", Tint = 0.3, Spoiler = "..." },
	Fuel = 0.8,            -- 0..1 (o batería si es eléctrico)
	Condition = 0.95,      -- desgaste; baja con kilómetros y golpes
	Odometer = 12450,
	Insurance = { Plan = "TodoRiesgo", PaidUntilWeek = 42 },
	Garage = "p_..." ,     -- propiedad donde se guarda
}
```

## 10.3 Ciclo de vida

- **Compra:** concesionarios por gama (económico en San Roque, familiar en Valmar Norte, lujo en Colinas). Prueba de conducción antes de comprar. Financiación con préstamo.
- **Garaje:** tu vivienda tiene X plazas según el tipo. Se puede alquilar una plaza en un parking.
- **Sacar el coche:** en tu garaje o en cualquier **parking público** (con coste). No aparece en cualquier sitio, por realismo, pero hay parkings cerca de todo.
- **Combustible:** se gasta al conducir y se reposta en gasolineras (o se carga el eléctrico en puntos de carga).
- **Mantenimiento:** el estado baja con el uso. Con el estado bajo hay averías (menos velocidad, no arranca). Se repara en talleres, de mecánicos jugadores o NPC.
- **Seguro:** sin seguro, los golpes y robos NPC los pagas tú. Hay seguro básico y a todo riesgo.
- **Multas:** radares de velocidad y aparcamiento indebido (la policía jugadora también las pone).
- **Personalización:** color, llantas, tintado, alerones, matrícula personalizada (vía monetización), en talleres de tuning.

## 10.4 Implementación técnica

- **Chasis propio ligero** basado en raycasts (suspensión simulada) en vez de uno pesado con muchas piezas físicas. Rinde mejor en móvil y se comporta igual en todos los vehículos. Cada modelo solo cambia sus parámetros (velocidad, aceleración, agarre, peso).
- **Control de red (Network Ownership) al conductor:** la conducción es fluida porque la física la calcula su dispositivo.
- **Validación en el servidor:** velocidad máxima según el modelo, teletransportes imposibles y posición dentro del mapa. Si hay trampas, se corrige y se registra.
- **Límite de vehículos activos** por jugador (1) y por servidor. Los vehículos abandonados se guardan solos tras unos minutos.
- **Carreteras con sentido:** el grafo de carreteras (Fase 2) une todos los distritos. Las autopistas son la forma rápida de cruzar la región (conducir de Villaverde a Colinas del Mirador ≈ 2–3 minutos).

## 10.5 Transporte público

| Medio | Funcionamiento | Coste |
|---|---|---|
| **Tren ligero L1** | Movido por código sobre raíles, horario fijo cada ~2 min, 6 estaciones. Pasajeros sentados | Billete o abono semanal |
| **Autobuses** | NPC por el grafo o jugador conductor. Paradas con panel de "próximo bus" | Billete |
| **Taxi** | Llamada desde el teléfono. Taxista jugador si hay, si no, taxi NPC con viaje rápido | Por distancia |
| **Bicicletas públicas** | Estaciones en el Centro y en el Universitario | Por minutos |

El transporte público es la forma de moverse de quien no tiene coche (niños, estudiantes, jugadores nuevos). El mapa debe poder recorrerse entero sin coche, aunque sea más lento.
