# Encargo del dueño: vuelo y combate espacial «AAA»

Imagen de referencia: `referencia-hud.png`. Es la referencia visual principal de la interfaz, la nave, el radar, las misiones, el salto cuántico y las habilidades.

Resumen del encargo, escrito por el dueño con ayuda de otra IA. El juego se llama **Heroes of History**. En el juego no se usa el nombre «NovaLife» ni la palabra «Nova».

## Regla fundamental

- No destruir nada. Primero hay que auditar los sistemas que ya existen:
  - vuelo, vehículos y combate;
  - misiones, inventario, interfaz;
  - economía y guardado.
- Ampliar lo que ya hay, sin duplicar ni simplificar.
- No borrar progresión, naves, monedas, misiones ni inventario.
- Arquitectura modular. Las APIs existentes tienen que seguir siendo compatibles.

## HUD (por zonas, como la imagen)

| Zona | Qué muestra |
|---|---|
| A. Arriba a la izquierda | Perfil del piloto: avatar, nombre, nivel, dinero real y recursos reales. |
| B. Arriba en el centro | Navegación: brújula que gira con la nave real, sistema, planeta o zona, distancia al destino y estado del salto cuántico. |
| C. Centro, debajo de la navegación | Estado de la nave en tiempo real: velocidad, impulso, energía, escudo, estructura, misiles, armas (recargando) y alertas. |
| D. Arriba a la derecha | Radar funcional (ver detalle abajo). |
| E. Lateral derecho | Misiones reales: principal, secundaria, eventos y alertas, con distancia y progreso. |
| F. Centro | Combate (ver detalle abajo). |
| G. Abajo a la izquierda | Joystick táctil solo en móvil. En PC y mando, sus controles. |
| H. Abajo en el centro | Barra de 8 ranuras (ver detalle abajo). |
| I. Abajo a la derecha | Botones grandes: IMPULSO, FRENO, MISIL, DISPARO (el más destacado), ESQUIVA y CAMUFLAJE (cuando esté disponible). Muestran su recarga. |
| J. Secundaria | Solo cuando haga falta: modo combate, daños, proximidad, nave, motor, comunicaciones y eventos. |

- **D. Radar:**
  - Muestra al jugador y su orientación, enemigos, aliados, estaciones, planetas, puntos de interés, objetivos y marcadores de salto.
  - Cada cosa con su icono y su color.
  - Solo aparece lo que esté dentro del alcance de detección.
- **F. Combate:**
  - Punto de mira, fijado de objetivo, distancia y marcadores de enemigos.
  - Estado del bloqueo, trayectoria estimada, avisos de amenaza e impactos.
  - El punto de mira no debe tapar al enemigo.
- **H. Barra de 8 ranuras:** arma principal, misiles, láser, escudo especial, camuflaje, salto cuántico, hipervelocidad y dron.
  - Cada ranura muestra icono, tecla, cantidad, recarga, estado y selección.
  - Están conectadas al equipamiento real.

## Vuelo

Controlador real con:

- aceleración, frenado, velocidad máxima e impulso;
- giro, alabeo, movimiento lateral, subir y bajar;
- freno de emergencia y modo combate o modo normal;
- asistencia de vuelo e inercia controlada;
- colisiones y recuperación tras las maniobras.

Un solo controlador mueve la nave.

## Habilidades

- **Esquiva:** hacia la izquierda, la derecha, arriba o abajo, según la entrada del jugador.
  - Desplazamiento real y estela.
  - Recarga, con aviso si se intenta usar mientras se recarga.
  - Invulnerabilidad corta o ninguna, siempre validada por el servidor.
- **Impulso:** aceleración corta para el combate.
- **Hipervelocidad:** viaje largo de verdad, en 4 fases:
  1. Preparación: comprobar energía y obstáculos.
  2. Activación: estelas, campo de visión y distorsión.
  3. Viaje: consume energía, avisa de obstáculos y se puede cortar.
  4. Desaceleración.
  - Normas:
    - No se puede atravesar sólidos; hay que detectar los choques antes.
    - Está bloqueada cerca de estaciones, en combate o con tráfico, y el juego explica por qué.
- **Salto cuántico:** lleva la nave de verdad a un destino válido: planeta, estación, punto de interés, baliza, lugar descubierto o misión.
  - Antes del salto: validar destino, estado, energía, alcance, combate y seguridad, y mostrar coste y distancia.
  - Secuencia: carga, portal, distorsión y salida.
  - Llegada a una posición segura, validada y sincronizada por el servidor.
  - Si falla, explica el motivo, no gasta nada y no bloquea la nave.
- **Camuflaje:** apariencia distorsionada y menos visibilidad para los sistemas de detección que existan (radar y enemigos).
  - No es invisibilidad total.
  - Gasta energía y tiene duración y recarga validadas por el servidor.
- **Drones:** un sistema modular de combate, defensa, exploración y reparación.
  - Solo los que estén desbloqueados.
  - Cada dron tiene estado, energía o duración, límite de distancia y destrucción, y su estado sale en el HUD.

## Combate

- **Armas:**
  - Cañones de energía y láser.
  - Misiles guiados con munición, objetivo, recarga, velocidad, alcance y reglas de impacto; se pueden esquivar.
- **Defensa:** escudo y estructura, con estados críticos.
- **Objetivos:** se pueden seleccionar y muestran nivel, salud y bloqueo.
- **Servidor:** valida disparos, impactos y daño.

## Controles

- **PC:**

  | Tecla | Acción |
  |---|---|
  | WASD | Dirección |
  | Espacio | Acelerar o subir |
  | Shift | Impulso o hipervelocidad |
  | Ctrl | Freno |
  | Q / E | Giros |
  | C | Esquiva |
  | X | Salto |
  | Z | Camuflaje |
  | R | Recargar |
  | F | Interactuar |
  | Ratón | Apuntar |
  | Clic izquierdo | Disparar |
  | Clic derecho | Precisión |

  - Revisar que no choquen con los controles actuales.
  - Que se puedan reasignar en el futuro.
  - No capturar las teclas mientras se escribe en el chat.
- **Móvil:**
  - Joystick a la izquierda y zona de apuntado a la derecha.
  - Botones grandes: disparo, misil, impulso, freno y esquiva.
  - Botones secundarios: salto, camuflaje y habilidades.
  - Admitir varios dedos a la vez y ajustar la sensibilidad.
  - No llenar la pantalla.
- **Mando:** todo con sus iconos.

## Efectos y sonido

- Cada habilidad con su señal clara: esquiva, impulso, hipervelocidad, salto, camuflaje, escudos y misiles.
- Pocas partículas, escaladas según la calidad gráfica.
- Solo recursos de Roblox o gratuitos.

## Arquitectura

- **Cliente:** HUD, entradas, cámara y efectos.
- **Servidor:** estado autorizado, consumo, munición, daño, recargas, habilidades, teletransportes y recompensas.
- **Red:** remotos validados y con límite de frecuencia.
- **Física:** un solo controlador y propiedad de red bien gestionada.

## Integración

- Inventario, vehículos, economía, progresión, misiones, exploración, guardado y multijugador.
- Desbloquear o mejorar naves con la economía del juego.
- Nada de pagos obligatorios ni ventajas que solo se consigan con Robux.

## Calidad y rendimiento

- Calidad visual máxima razonable, pero el HUD tiene que ser legible.
- Optimizado para móvil:
  - partículas, frecuencia del HUD y proyectiles;
  - red, radar y drones.

## Pruebas

- Probar cada función de la lista de verificación del encargo:
  - vuelo, impulso, hipervelocidad, esquiva y salto;
  - radar, apuntado, misiles, daño y camuflaje;
  - HUD, misiones y controles táctiles;
  - servidor y multijugador;
  - que no se rompa nada, que no haya errores, el rendimiento y las resoluciones.
- No dar por terminado lo que no se haya probado. Decir qué hay que comprobar a mano en Roblox.

## Fases

1. Auditoría.
2. Vuelo.
3. HUD y controles.
4. Impulso, freno y esquiva.
5. Hipervelocidad.
6. Salto cuántico.
7. Combate.
8. Camuflaje, drones y extras.
9. Integración.
10. Efectos y pulido.
11. Pruebas y optimización.

## Segundo encargo

El dueño mandó un segundo mensaje con el mismo objetivo (el espacio «AAA» de `referencia-hud.png`), para
la segunda tanda (fases 7 a 11). Resumen de lo que añade:

- **Contramedidas antimisil** (bengalas / señuelos): pueden romper el fijado de un misil, cargas
  limitadas y recarga.
- **Sobrecarga del escudo** (el escudo especial): refuerzo temporal del escudo que gasta energía, tiene
  recarga y, al acabar, se recalienta (un rato sin regenerar).
- **Modos de vuelo**: normal/crucero, **exploración** y combate. En exploración: pulsos del escáner,
  más alcance del radar, descubrir puntos de interés y armas reducidas.
- Lo demás, como en el primer encargo: combate completo (cañones de energía, láser y misiles guiados
  con colisión real, munición, recargas, alcance y maniobrabilidad, que se pueden esquivar o engañar;
  enemigos seleccionables con nivel, categoría y salud; cambiar de objetivo; reglas de fijado con
  distancia, ángulo y línea de visión; avisos de amenaza con la dirección del misil; escudo y casco con
  estados críticos; la IA enemiga con las mismas reglas, también con misiles), camuflaje (no es
  invisibilidad total), drones modulares (combate, defensa, exploración y reparación; solo los
  desbloqueados, con la economía del juego y sin Robux), integración (mejoras de la nave con Chispas y
  dinero, guardado, misiones, inventario, multijugador), efectos y sonidos de cada habilidad, y
  rendimiento, pruebas y documentación.
