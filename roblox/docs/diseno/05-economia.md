# Fase 5 — Economía

## 5.1 Objetivo

Que ganar dinero tenga sentido porque hay que **tomar decisiones**: vivir cerca del trabajo o pagar transporte, alquilar o comprar, estudiar (sin ganar dinero) o trabajar ya, ahorrar o invertir.

Moneda: **Nova Dólar (N$)**.

## 5.2 El libro contable (Ledger): la pieza central

**Ningún sistema suma o resta dinero directamente.** Todo pasa por:

```lua
Ledger.transfer({
	From = "char:c_123:Main",       -- cuenta de origen (o "system:Salaries")
	To = "char:c_456:Main",         -- cuenta de destino (o "system:Taxes")
	Amount = 250,
	Reason = "Salary",              -- tipo de operación (para analítica y extracto)
	Ref = "career:Medico:shift_88", -- referencia
})
```

Ventajas:
- Un único lugar para validar (fondos suficientes, límites, anti-duplicación).
- **Extracto bancario** gratis para la app del banco.
- **Analítica de economía:** cuánto dinero entra y sale del juego y por dónde.
- Detección de anomalías (un jugador que gana 100 veces más que la media en una hora).

## 5.3 Dinero y cuentas

| Elemento | Detalle |
|---|---|
| **Efectivo** | Pequeñas compras, propinas y pagos en mano entre jugadores. Límite de efectivo encima |
| **Cuenta corriente** | Nómina, facturas, tarjeta |
| **Cuenta de ahorro** | Interés semanal bajo |
| **Tarjeta** | Pagar en tiendas desde la cuenta (el TPV del mostrador) |
| **Cajeros** | Sacar e ingresar efectivo |
| **Transferencias** | Entre jugadores, con confirmación, límite diario y retención de 24 h para cantidades grandes (anti-estafa) |
| **Historial crediticio** | Sube pagando a tiempo y baja con impagos. Determina préstamos e hipotecas |

## 5.4 Tiempo económico

- **1 día de juego = 24 minutos reales** (1 hora de juego = 1 minuto real).
- **1 semana de juego = 7 días = 2 h 48 min de juego real.** Es el ciclo de facturas.
- **Los gastos se cobran por tiempo JUGADO, no por tiempo real.** Si un jugador no entra en un mes, no vuelve arruinado. Es esencial para no perder jugadores.

## 5.5 Entradas de dinero (grifos)

| Grifo | Notas |
|---|---|
| Salarios de profesiones | Principal. Pago por turno completado con bonus por rendimiento |
| Beneficios de negocios | Con clientes NPC y jugadores |
| Alquileres cobrados | A inquilinos (jugadores o NPC) |
| Intereses e inversiones | Pequeños y con riesgo |
| Venta de bienes | A jugadores (neutral para la economía global) o al sistema (con pérdida) |
| Pensión | Adulto mayor, según la carrera laboral |
| Recompensa diaria y logros | Pequeñas |
| Compras con Robux | Limitadas para no romper la economía (Fase 14) |

## 5.6 Salidas de dinero (sumideros)

| Sumidero | Notas |
|---|---|
| Alquiler / hipoteca | El gasto más importante |
| Facturas (luz, agua, internet) | Según el tamaño de la vivienda |
| Comida y ocio | Diario |
| Transporte | Gasolina, billetes, mantenimiento, seguro |
| Educación | Matrículas (con becas por buenas notas) |
| Impuestos | IRPF progresivo retenido en nómina, impuesto sobre la propiedad (crece con el patrimonio), IVA en compras |
| Multas | Tráfico y otras infracciones |
| Compras de patrimonio | Casas, coches, muebles, ropa |
| Materiales de construcción | Para construir en parcelas |

**Impuesto sobre la propiedad y mantenimiento de lujo:** las mansiones y los coches de lujo cuestan dinero cada semana. Así los jugadores ricos siguen gastando y la economía no se infla hasta que el dinero no valga nada.

## 5.7 Equilibrio de referencia (a ajustar con datos reales)

| Perfil | Ingreso semanal | Gasto típico | Queda para ahorrar |
|---|---|---|---|
| Estudiante con trabajo parcial | 1.500 | Habitación 600 + comida 400 + transporte 150 | ~350 |
| Primer empleo (dependiente) | 3.000 | Estudio 1.200 + gastos 900 | ~900 |
| Profesional (enfermero) | 7.000 | Apartamento 2.500 + coche 800 + gastos 1.500 | ~2.200 |
| Alto (médico especialista) | 18.000 | Casa con hipoteca 6.000 + gastos 4.000 + impuestos | ~5.000 |
| Empresario de éxito | variable | Mansión 15.000 + lujo | variable |

Regla de diseño: **el alquiler de la vivienda "normal" de cada nivel ≈ 35–45% del sueldo de ese nivel.** Los sueldos y los precios viven en los registros y se ajustan sin tocar código.

## 5.8 Préstamos e hipotecas

- **Préstamo personal:** cantidad según historial crediticio y sueldo, interés semanal y plazo en semanas de juego.
- **Hipoteca:** entrada del 20% y cuotas semanales. Si no pagas: aviso, recargo, embargo tras 3 impagos (la propiedad sale a subasta y recuperas parte).
- **Préstamo de estudios:** sin interés mientras estudias. Se devuelve con el primer empleo.

## 5.9 Mercado e inversiones (fase avanzada)

- **Mercado inmobiliario:** precio base por distrito y tipo de parcela, más un índice de demanda global (se recalcula cada hora de juego con las compraventas reales entre servidores).
- **Bolsa Nova:** empresas ficticias y un índice de los negocios de jugadores. Precios simulados por un único servidor "líder" (cerrojo en MemoryStore) cada pocos minutos. El resto de servidores solo los lee.
- **Nada de azar con dinero comprado con Robux:** no hay casino ni tragaperras. Las inversiones son riesgo económico, no azar puro.

## 5.10 Anti-exploit específico de la economía

- El cliente nunca envía precios ni cantidades de dinero. Solo envía "quiero comprar el objeto X".
- Límites de frecuencia en todas las acciones de dinero.
- Registro de todas las operaciones grandes y alertas por anomalías.
- Transferencias grandes retenidas y revisables.
