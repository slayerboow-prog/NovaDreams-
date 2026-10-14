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

## Tercer encargo: mundos planetarios únicos

Imagen de referencia: `referencia-planetas.png`.

Cada planeta tiene que ser un mundo completamente diferente. Cada uno tiene:

- su ecosistema, clima, ciclo de día y noche y biomas;
- sus recursos, fauna y flora;
- sus zonas de interés y misiones exclusivas;
- sus efectos visuales y sonidos propios.

Regla del dueño: **todo lo que se haga en Valmar tiene que existir también en cada planeta**, pero de forma totalmente distinta. Por ejemplo, el mundo marino, la ciudad, los trabajos y el transporte. Cada planeta debe sentirse como un sitio nuevo.

Tipos de la imagen:

- desértico: dunas, tormentas de arena y ruinas;
- helado: glaciares, auroras y fauna del frío;
- tóxico: atmósfera peligrosa y criaturas alienígenas;
- oceánico: islas flotantes y ciudades submarinas;
- volcánico: lava, terremotos y minerales raros;
- selvático: vegetación densa y cascadas;
- urbano: ciudades futuristas y tráfico;
- espacial: asteroides, anillos y estaciones mineras.

## Decisiones del dueño (nombres y alcance de los planetas)

### Nombres nuevos, más adultos

Cambia el nombre del planeta y de su ciudad:

| Antes | Planeta | Ciudad | Tipo de mundo | Estilo de ciudad |
|---|---|---|---|---|
| Lontana / Redonda | **Tefra** | **Bastión Ceniza** | Volcánico, ceniza | Fortaleza industrial y militar, entre lava |
| Ocrea / Rampa Mayor | **Siroco** | **Puerto Calcina** | Desierto, tormentas, ruinas | Ciudad de adobe y chatarra, con circuitos de carreras |
| Marena / Pleamar | **Tálasa** | **Abisalia** | Océano, islas flotantes | Futurista y muy tecnológica, en parte submarina |
| Velaria / Nevalumbre | **Nivalis** | **Fortaleza Albor** | Helado, glaciares, auroras | Ciudad antigua de piedra y hielo |
| Fronda / Copalta | **Umbría** | **Raíz Honda** | Selva, cascadas | Ciudad orgánica en los árboles gigantes |
| Zéfira / Volandera | **Miasma** | **Anclaje Siete** | Tóxico, nubes venenosas | Plataformas tecnológicas por encima de la niebla |
| Mercadia / Ciudad Saldo | **Vértice** | **Distrito Cero** | Urbano | Megaciudad futurista con tráfico aéreo |

Zonas del mar de Valmar:

- Arrecife Escarlata
- Laberinto de Kelp
- Llanura Sumergida
- Talud del Naufragio
- Garganta Negra
- Abismo Silente
- Sima del Kraken

### Alcance de cada planeta

- Que no sean todos iguales: unas ciudades futuristas y muy tecnológicas, otras de selva y otras volcánicas.
- **Mínimo 10 horas de juego por planeta.** En cada uno hay que poder:
  - explorar, recolectar y minar;
  - **crear objetos**, con un sistema de fabricación;
  - **crear naves**, con un astillero o constructor;
  - y además hacer todo lo que ya se puede hacer en Valmar: ciudad, trabajos, tiendas, transporte, mar o su equivalente, ocio…

### Trabajos, forma de vida y misiones de cada planeta

- **Trabajos comunes en todos los planetas.** Son los trabajos básicos de la galaxia: piloto, minero, mecánico de naves, comerciante, médico, seguridad, etc.
- **Cada planeta tiene además su identidad:**
  - su forma de juego y su forma de vida;
  - peculiaridades y características propias;
  - **desventajas propias**, como el calor, el frío, el veneno, la escasez o la ley.
- **Misiones de calidad AAA**, no simples: con trasfondo y una historia muy entretenida, personajes memorables, giros, decisiones con consecuencias y momentos espectaculares.
- **Misiones premium del pase de batalla en cada planeta.**
  - Respetan las normas: nada de pagar para ganar (las recompensas premium son estéticas o de comodidad) y siempre sin contenido +17.
