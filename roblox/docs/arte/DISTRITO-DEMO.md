# Distrito de demostración — "Valmar Sur"

Objetivo: **un distrito pequeño con la calidad visual final**, que sirva de estándar para el resto del mapa.
Primero calidad, después cantidad.

## 1. Análisis del estado actual

| Parte | Valor | Qué hacemos |
|---|---|---|
| Guardado de datos, compras con Robux, trabajos, comida, casas, necesidades | ✅ Sistemas funcionales | **Se conservan** tal cual |
| Día/noche, farolas, ventanas nocturnas, curva de iluminación por horas | ✅ Funcional | Se conserva y se ajusta |
| Etiquetas de juego (JobBoard, FoodStand, Plot…) | ✅ Contrato entre mapa y sistemas | Se conservan: los edificios nuevos llevan las mismas etiquetas |
| Generador de calles (aceras, bordillos, cruces, pasos de cebra) | 🟡 Útil como base | Se amplía: rotondas, medianas arboladas, aparcamientos, calles de distinto ancho |
| Generador de edificios por código | 🟡 Placeholder | Queda solo como **respaldo** y para edificios lejanos (skyline) |
| Árboles, farolas, bancos y coches por código | 🟡 Placeholder | Se sustituyen automáticamente por modelos de Synty (ya implementado) |
| Trazado actual (cuadrícula recta) | ❌ Placeholder | Se rediseña (sección 3) |

## 2. Dirección visual

- **Base de arte: los packs gratuitos y oficiales de Synty** (City y Nature), publicados por Roblox en la Creator Store. Son de un estudio profesional y **todos comparten el mismo estilo**, así que la ciudad se ve coherente.
- **Estilo resultante:** *low-poly estilizado moderno*. Limpio, colorido y muy optimizado para móvil. **No es fotorrealista.** Es el estilo de muchos juegos de éxito en Roblox y envejece bien.
- Lo que falte en los packs se genera por código **con la misma paleta** de Synty (colores planos, pocas texturas), para que no desentone.
- **Regla:** no se mezclan packs de estilos distintos sin revisarlo antes.

## 3. Diseño urbano del distrito

Tamaño: ~640 × 640 studs (≈ 180 m × 180 m). Norte arriba.

```
                     SKYLINE (torres lejanas de bajo detalle: profundidad)
  ┌─────────────────────────────────────────────────────────────────────┐
  │ Torres   Hotel   Oficinas        │ Apartamentos   Apartamentos       │
  │  CENTRO: tiendas, banco, bares   │  (bloques con patio y parking)    │
  │ ─ ─ ─ calle peatonal comercial ─ ┼───── Calle del Mercado ───────────│
  │ Plaza con fuente + terrazas      │ Supermercado + PARKING            │
  ╞══════ AVENIDA DEL MAR (2+2, mediana con palmeras) ═══(O)═════════════╡ ← (O) = ROTONDA
  │ Gasolinera │ Comisaría │ Bomberos │    PARQUE: lago, parque infantil, │
  │            │           │          │    pista deportiva, caminos       │
  │────────── Calle Escuela ──────────│───────────────────────────────────│
  │ Colegio + patio + pista │ Centro de salud + ambulancias │ Adosados   │
  │─────────────────────────┴─ Calle curva residencial ────── (fondo de saco)
  │ Casas con jardín, piscinas y garajes (parcelas de jugadores)          │
  └─────────────────────────────────────────────────────────────────────┘
```

**Jerarquía de calles:** avenida 2+2 con mediana arbolada → calles de 1+1 → calle peatonal → calle residencial curva con fondo de saco.
**Nada de cuadrícula perfecta:** la rotonda, la calle curva, la peatonal y los fondos de saco rompen la retícula.

## 4. Capas de profundidad (qué ve el jugador en cualquier dirección)

calzada → bordillo → acera con farolas, árboles y bancos → aparcamiento en línea → fachadas con escaparates y toldos → segunda línea de edificios más altos → **skyline** lejano → colinas del horizonte.

Reglas:
- Ninguna vista termina en césped vacío: detrás de cada manzana hay otra, o skyline.
- La vegetación se **diseña**: alineaciones en aceras, setos en parcelas, macizos en plazas, masas de árboles en el parque. No se reparte al azar.

## 5. Iluminación (ya implementada, se ajustará con capturas reales)

| Momento | Carácter |
|---|---|
| Amanecer (6-8 h) | Luz cálida y rosada, niebla ligera |
| Día (10-16 h) | Sol blanco, sombras nítidas, cielo limpio |
| **Hora dorada** (18-19 h) | Naranja cálido, sombras largas, más saturación |
| Anochecer (20 h) | Azul violáceo, se encienden farolas |
| Noche | Azul frío + farolas, ventanas y **escaparates iluminados**, brillo en los neones |

## 6. Ciudad viva (fase siguiente del distrito)

- **Peatones** NPC por las aceras (generados en el cliente, baratos).
- **Tráfico** NPC por la avenida y la rotonda.
- Clientes en el súper, alumnos en el colegio, ambulancia en el centro de salud.

## 7. Rendimiento

- StreamingEnabled activado. Cada manzana es un modelo independiente.
- Los modelos de Synty son de bajo número de polígonos y comparten texturas.
- Sin scripts dentro de los modelos: se eliminan al colocarlos.
- Presupuesto orientativo del distrito: < 15.000 instancias.

## 8. Pasos

1. ✅ Biblioteca de assets con sustitución automática y limpieza de scripts.
2. ✅ Curva de iluminación por horas y escaparates nocturnos.
3. ⏳ **Importar los packs de Synty** (lo haces tú en Studio, ver la guía en el README).
4. Catalogar los modelos del pack y construir el distrito con ellos.
5. Peatones y tráfico básicos.
6. Revisión con capturas reales de Studio y ajustes.
7. Cuando el distrito tenga la calidad final → se usa como plantilla para el resto de Valmar.
