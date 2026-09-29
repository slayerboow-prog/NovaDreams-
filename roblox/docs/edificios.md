# Edificios, viviendas y vecinos

Cómo funcionan los edificios por dentro y qué queda por hacer.

## Piezas

| Pieza | Qué hace |
|---|---|
| `server/Services/InteriorService` | Encuentra cada edificio del mapa y le pone puerta. Monta su interior al entrar y lo quita cuando se queda vacío. En los bloques de varias plantas solo están montadas las plantas a ±2 de algún jugador. |
| `server/World/Tower` + `shared/Floors` | Cada planta de un bloque: portal (buzones, portero, portero automático), escalera que se sube andando, pasillo con puertas numeradas, ascensor, escalera de emergencia y detalles (detectores de humo, cámara, cuadro eléctrico, plano de evacuación, cuadros, papelera). |
| `server/World/Lift` + `shared/LiftMath` + `client/Controllers/LiftRide` | El ascensor de verdad: hueco, cabina, puertas de cabina y de rellano, botón de llamada, pantalla de planta y viaje. El servidor mueve la cabina; el cliente la mueve fluida con las mismas cuentas. |
| `server/Services/PropertyService` + `shared/Properties` | Quién es el dueño de cada vivienda: un registro por edificio en el DataStore, cambiado con `UpdateAsync`, así nunca hay dos dueños. Además: comprar, alquilar, vender o dejar, vecinos dentro de las viviendas y el nombre en la placa. |
| `shared/Housing` | La ficha de cada vivienda: ID `D03-E014-0402`, tipo (estudio, piso, piso grande, ático, casa, chalet), habitaciones, baños, metros, extras, precio y alquiler. |
| `server/Services/HousingService` | Vivienda al llegar, cobro del alquiler (con deuda y avisos), llaves, privacidad, echar visitas, timbre, vecinos con horario y vida en el portal. |
| `shared/Residents` | La vida de cada vecino: nombre, edad, trabajo, lugar y horario. Así, si llamas a su puerta y está trabajando o durmiendo, no te abre. |
| `client/Controllers/HousingUI` | El aviso del timbre (Abrir / No abrir) y el panel de llaves y visitas. |

## Reglas

- **Vivienda al llegar.**
  - A cada jugador nuevo le toca un piso libre al azar de un bloque de pisos.
  - Se reserva igual que al comprar. Si otro jugador se adelanta, se prueba con otro piso.
  - Se guarda en `Housing.Assigned`. No cuenta para el máximo de viviendas.
- **Alquiler.**
  - Se cobra cada día de juego, solo mientras juegas.
  - Si no hay dinero, se suma a la deuda y te llega un aviso.
  - Al tercer impago seguido se pierde el contrato y la deuda queda en `Housing.Debt`.
- **Llaves y privacidad.**
  - Se guardan en el registro de la vivienda, así valen aunque el dueño no esté.
  - Privacidad posible:
    - `Grupo`: entran su grupo y los que tienen llave.
    - `Llaves`: solo los que tienen llave.
    - `Cerrada`: no entra nadie más.
- **Timbre.** Si abres a alguien desde el timbre, esa persona puede entrar durante 2 minutos.

## Pruebas

- `scripts/test-gameplay.luau` tiene tres secciones sobre esto:
  - *Edificios de varias plantas*;
  - *Viviendas de verdad*;
  - *El ascensor de verdad*.
- `scripts/test-clientboot.luau` comprueba el timbre y el panel de llaves en pantalla.

## Pendiente (segunda fase)

- **Negocios en locales.** Comprar o alquilar un local de planta baja y montar un negocio propio (cafetería, peluquería, oficina…) con `BusinessService`.
- **Interiores dentro de la ciudad.** Hoy los interiores se montan en una zona aparte y se entra con un salto. Para meterlos dentro de la fachada hace falta medir bien el rendimiento en móvil.
- **Vecinos que suben de verdad por la escalera y el ascensor**, y que salen a la calle y vuelven según su horario (hoy la vida es solo en el portal).
- **Misiones que usen las viviendas.** Por ejemplo, «entrega en el 502» o «busca a Carlos en su piso». La ficha y el ID ya lo permiten.
- **Estilo por distrito.** Que cada distrito tenga su tipo de portal y pasillo (lujo, obrero, moderno…).
