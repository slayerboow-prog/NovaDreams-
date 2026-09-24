# Fase 9 — Viviendas y propiedades

## 9.1 Tipos de vivienda

| Tipo | Cómo se obtiene | Zona típica | Construible | Notas |
|---|---|---|---|---|
| Casa familiar (de los padres) | Nacer o ser menor | Cualquiera | No (decorar tu cuarto) | Hasta independizarse |
| Habitación en piso compartido | Alquiler | San Roque, Universitario | Solo tu cuarto | Muy barata. Otros jugadores o NPCs de compañeros |
| Residencia de estudiantes | Alquiler (estudiantes) | Universitario | Tu cuarto | Incluye comida |
| Estudio / apartamento | Alquiler o compra | Centro, San Roque, Playa | Decorar | **Interior instanciado** en torres |
| Casa adosada / casa | Alquiler o compra | Los Pinos, Valmar Norte | Sí | Parcela P-S / P-M |
| Chalet | Compra | Valmar Norte, Colinas | Sí | P-L |
| Mansión | Compra | Colinas del Mirador | Sí | P-XL |
| Granja | Compra | Valle Verde | Sí + cultivos y animales | P-FARM |
| Terreno vacío | Compra | Todos los distritos | Construir desde cero | Base del mercado inmobiliario |

## 9.2 Cómo funciona la propiedad en un mundo con muchos servidores

Una propiedad es un **activo guardado en datos**, no un lugar fijo del mapa de un servidor:

```lua
Property = {
	Id = "p_...", Owner = "c_123", Type = "Casa", LotSize = "P-M",
	District = "LosPinos", Status = "Owned" | "Rented" | "Mortgaged",
	BuildRef = "b_p_...",        -- construcción y muebles (store Build_v1)
	Value = 85000, Tenants = {...},
}
```

Cuando entras en un servidor, tu casa se coloca en una **parcela libre del mismo tamaño y distrito**. Cada distrito tiene suficientes parcelas por tamaño para el máximo de jugadores del servidor.

- **Ventaja:** funciona con cualquier número de servidores, siempre tienes tu casa y nadie te "quita" el sitio.
- **Contrapartida:** la dirección exacta puede variar entre servidores (dentro del mismo barrio). Para la inmersión el GPS la llama siempre "Tu casa".
- **Casa familiar compartida:** en un hogar con varios jugadores se coloca la casa del cabeza de familia (o del miembro presente con la vivienda de mayor nivel) y el resto de miembros aparecen en ella.

## 9.3 Alquilar, comprar, hipotecar

| Acción | Detalle |
|---|---|
| Buscar vivienda | App "Inmobiliaria" del teléfono o visitar la zona. Se puede **visitar** antes de alquilar o comprar (aparece un "piso piloto") |
| Alquilar | Fianza de 1 semana + alquiler semanal (tiempo jugado). Sin compromiso de permanencia |
| Comprar al contado | Precio completo. Se puede revender |
| Hipoteca | Ver Economía (entrada del 20%, cuotas y riesgo de embargo) |
| Vender | Al sistema (80% del valor al instante) o a jugadores (precio libre, vía contrato) |
| Alquilar a otros | El dueño publica el alquiler y el inquilino recibe una **copia** del diseño de la casa en su servidor. El dueño cobra cada semana que el inquilino juega |

## 9.4 Construcción y decoración

- **Modo construcción** en tu parcela: paredes, suelos, techos, puertas, ventanas, escaleras y pisos, sobre una rejilla de 1 stud (con giro de 15°).
- **Catálogo de muebles** (Registro de Items) con precios, categorías y estilos. Incluye la línea **NovaDreams** con muebles reales de la tienda (sofás KOKE y EGEO…).
- **Límites:** número de objetos por tamaño de parcela (ej. P-M: 1.500) para el rendimiento y el tamaño de los datos.
- **Guardado comprimido:** lista de `{ItemId, posición, giro, color}` codificada en un store propio por propiedad.
- **Planos:** un arquitecto jugador puede diseñar un plano y venderlo. El comprador lo construye pagando materiales o contratando a un constructor jugador o NPC.
- **Construcción realista (opcional por parcela):** en vez de aparecer al instante, la obra tarda (tiempo jugado) y se ve el andamio. Los constructores jugadores la aceleran y cobran por ello. Esto crea trabajo real entre jugadores.

## 9.5 Mercado inmobiliario

- **Precio base** por distrito y tamaño, multiplicado por un **índice de demanda** global (compraventas recientes).
- **Anuncios** en MemoryStore (visibles en todos los servidores) y respaldados en DataStore.
- **Agentes inmobiliarios** (jugadores) pueden gestionar ventas ajenas y cobrar comisión.
- **Inversores:** comprar varios terrenos, construir y vender o alquilar. Es un estilo de vida posible.
- Impuesto sobre la propiedad semanal (sumidero de la economía, ver Fase 5).
