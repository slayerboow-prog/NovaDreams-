# Edificios, viviendas y vecinos

Cómo funcionan los edificios por dentro y qué queda por hacer.

## Piezas

| Pieza | Qué hace |
|---|---|
| `server/Services/InteriorService` | Encuentra cada edificio del mapa y le pone puerta. Monta su interior al entrar y lo quita cuando se queda vacío. En los bloques de varias plantas solo están montadas las plantas a ±2 de algún jugador. |
| `server/World/Tower` + `shared/Floors` | Cada planta de un bloque: portal (buzones, portero, portero automático), escalera que se sube andando, pasillo con puertas numeradas, ascensor, escalera de emergencia y detalles (detectores de humo, cámara, cuadro eléctrico, plano de evacuación, cuadros, papelera). Además, el estilo del distrito (`Tower.Themes`, `Floors.themeFor`) y el camino andando por la escalera (`Floors.stairPath`, `Tower.stairRoute`). |
| `server/World/Lift` + `shared/LiftMath` + `client/Controllers/LiftRide` | El ascensor de verdad: hueco, cabina, puertas de cabina y de rellano, botón de llamada, pantalla de planta y viaje. El servidor mueve la cabina; el cliente la mueve fluida con las mismas cuentas. |
| `server/Services/PropertyService` + `shared/Properties` | Quién es el dueño de cada vivienda: un registro por edificio en el DataStore, cambiado con `UpdateAsync`, así nunca hay dos dueños. Además: comprar, alquilar, vender o dejar, vecinos dentro de las viviendas y el nombre en la placa. |
| `shared/Housing` | La ficha de cada vivienda: ID `D03-E014-0402`, tipo (estudio, piso, piso grande, ático, casa, chalet), habitaciones, baños, metros, extras, precio y alquiler. |
| `server/Services/HousingService` | Vivienda al llegar, cobro del alquiler (con deuda y avisos), llaves, privacidad, echar visitas, timbre, vecinos con horario, vida en el portal y en los pasillos (vecinos que suben y bajan por la escalera o en el ascensor) y encargos de los vecinos. |
| `shared/Residents` | La vida de cada vecino: nombre, edad, trabajo, lugar y horario. Así, si llamas a su puerta y está trabajando o durmiendo, no te abre. |
| `shared/Errands` | Los encargos de los vecinos: cuándo toca pedir uno, cuál (entrega o visita), los textos, si el vecino está en casa y la recompensa. |
| `client/Controllers/HousingUI` | El aviso del timbre (Abrir / No abrir), el panel de llaves y visitas, el aviso de un encargo (Aceptar / Ahora no) y el cartelito del encargo en marcha. |

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
- **Vecinos que suben y bajan de verdad.**
  - Con alguien en el portal: el vecino que llega mira el buzón (va por debajo de la escalera, no a través del muro) y sube a su casa por la escalera (andando por los escalones) o en el ascensor de verdad (lo llama, entra y viaja dentro de la cabina). Luego abre su puerta y entra.
  - Con alguien en las plantas de arriba (`HousingService.floorScene`): un vecino sale de su casa y baja, o llega desde la planta montada más baja y sube a la suya.
  - Solo por plantas montadas (±2 de algún jugador). Un viaje del ascensor solo con vecinos no monta plantas (`InteriorService`: solo se monta la planta de llegada si va un jugador dentro).
  - Nunca cogen el ascensor si hay un jugador dentro de la cabina (se lo llevarían).
  - Ningún vecino aparece a menos de 5 studs de un jugador (`HousingService.SpawnClear`); como mucho 4 a la vez por edificio (`HousingService.MaxNpcs`).
- **Encargos de los vecinos** (`shared/Errands`).
  - Solo en tu casa o en tu portal, no nada más llegar (25 s), como mucho uno cada 7 minutos (aunque digas que no) y nunca con otro en marcha.
  - Te llaman a la puerta o te paran en el portal. Sale el aviso con «Aceptar» y «Ahora no».
  - *Entrega en el 5ºB*: «Recoger paquete» en los buzones del portal y «Entregar paquete» en su puerta. Si no está, lo dejas en el felpudo.
  - *Busca a Carlos en su piso*: «Buscar a Carlos» en su puerta. Solo cuenta si está en casa según su horario (`shared/Residents`); si no, te dicen dónde anda y cuándo volver.
  - Los carteles del encargo solo los ve quien lo tiene (`OwnerUserId`) y vuelven a salir cada vez que se monta la planta.
  - Recompensa: dinero (`DataService.addMoney`) y experiencia (`ProgressionService.addXp`). Caduca a los 15 minutos. No se guarda al salir del juego.
- **Estilo por distrito** (al montar cada planta).
  - Oeste: lujo (mármol, barandillas doradas, alfombra, lámpara de araña y espejo en el portal).
  - Centro: clásico (madera y zócalo alto) o moderno.
  - Este: moderno (gris claro, tira de luz) o familiar.
  - Norte: familiar (colores cálidos, macetas, tablón de la comunidad).
  - Universitario: joven (paredes de color, tablón con carteles, aparcabicis).
  - Sur: obrero (terrazo, pared pintada a media altura, tablón).
  - Las oficinas tienen siempre su estilo. Son pocas piezas y sin colisión.

## Pruebas

- `scripts/test-gameplay.luau` tiene cuatro secciones sobre esto:
  - *Edificios de varias plantas*;
  - *Viviendas de verdad*;
  - *El ascensor de verdad*;
  - *Edificios, segunda fase*: estilo por distrito, el camino por la escalera, vecinos que suben y bajan (escalera y ascensor), que nadie aparezca encima de un jugador y los encargos.
- `scripts/test-clientboot.luau` comprueba el timbre, el panel de llaves y el aviso y el cartelito de los encargos en pantalla.

## Pendiente

- **Interiores dentro de la ciudad.** Hoy los interiores se montan en una zona aparte y se entra con un salto. Para meterlos dentro de la fachada hace falta medir bien el rendimiento en móvil.
- **Vecinos que salen a la calle y vuelven según su horario.** Hoy suben y bajan por dentro del edificio; en la calle todavía no se les sigue.
- **Guardar los encargos** al salir del juego (hoy se pierden: son cortos).
- **Negocios en locales** (ver abajo).

### Negocios en locales: cómo encaja con `BusinessService`

Ya hecho en `BusinessService`: la planta baja de los edificios de comercio (`Kind = "Local"`, la «Tienda» que da a la calle) es un local en venta. Se compra, se elige el negocio (tienda, cafetería, restaurante…) y se lleva con caja, existencias, precios, empleados y clientes NPC. Su clave es `"L:" .. building.Key`.

Lo que falta y cómo hacerlo sin romper nada:

1. **Alquilar el local** (además de comprarlo).
   - En `Business.Record`, un campo `Contract = "Alquiler"` con `Rent` y `RentDue`.
   - El alquiler de un día de juego sería `Business.premisePrice / 40`, como `Housing.rent`.
   - Cada día se cobra de la caja del negocio y, si no llega, del dinero del dueño. Se reutiliza `Housing.rentStep`: deuda, avisos y al tercer impago se pierde el local.
   - El cobro tiene que ir dentro de `Business.simulate`. Así funciona también con el dueño desconectado (hasta `MaxOfflineHours`).
   - Al perder el local se borra su entrada del índice con `writeIndex(key, nil)`.
   - En el panel del local (`premisePanel`), un botón «Alquilar» junto a «Comprar».
2. **Locales de arriba** (los «Local 102» del centro comercial y los comercios de varias plantas).
   - Cada uno sería un `Premise` con la clave `"L:" .. building.Key .. "#" .. unitId`.
   - El «Gestionar» y el mostrador irían en la sala de la unidad. Se engancharían con `InteriorService.onBuilt`, igual que la tienda de la calle.
3. **Portales de viviendas con bajo comercial.** Los bloques `Portal` no tienen tienda en la planta baja. Para tenerla habría que cambiar `Floors.units` (planta 0 con una unidad `Local`), y eso cambia los IDs de las viviendas de la planta baja.

No se ha hecho en esta fase porque el alquiler tiene que ir dentro de la simulación que funciona sin el dueño conectado, y el índice de `Negocios_v1` se comparte entre servidores. Hacerlo a medias podría dejar locales con dueño y sin nadie que pague.
