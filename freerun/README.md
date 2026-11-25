# Project Freerun

Juego móvil de parkour, freerunning, tricking y water tricks. Motor: **Godot 4.4** (renderer Compatibility / OpenGL ES 3, Android e iOS).

## Jugar en el móvil

- **Web (iPhone y Android)**: https://slayerboow-prog.github.io/NovaDreams-/ — gira el móvil en horizontal. En iPhone: Compartir → *Añadir a pantalla de inicio* para jugar a pantalla completa como una app.
- **Android (APK)**: Actions → última ejecución de "Freerun" → Artifacts → `ProjectFreerun-android`.

## Ejecutar en PC

1. Instala [Godot 4.4.x](https://godotengine.org/download) (estándar, no hace falta .NET).
2. Abre `freerun/project.godot` y pulsa F5.

Atajos: `godot --path freerun -- --mode=freerun` salta el menú (`tricking`, `water`, `challenge`, `freestyle`); `-- --touch` fuerza los controles táctiles en escritorio.

## Controles

**Móvil (iPhone / Android) — BOTONERA (por defecto)**: abajo a la derecha, **SALTO grande en el centro** y un **arco de 3/4 de círculo con 8 botones grandes por página y CAMBIAR**, que se puede girar. VAULT y AGARRAR van en una fila abajo, entre el joystick de movimiento y el joystick GIRO (no tapan al atleta). Páginas:
- **Modo por defecto: Gestos con tres joysticks** (azul = movimiento **y parkour**, morado = giros y complementos, dorado = SALTO y acrobacias, con los botones de mortal al lado).
- **Parkour en el joystick dorado (SALTO)**: el joystick de movimiento solo mueve (dibujar mientras te mueves era imposible). En el dorado:
  - U invertida = **vault** (elige solo: speed, step, lazy, dash o kong según carrera y obstáculo)
  - M en punta = **kong (monkey)** · tres picos = **doble kong** · V que sube al final (✓) = **kash vault**
  - V y otra bajada = **thief vault** · de arriba abajo rodeando por un lado = **turn vault**
  - Γ = **pasavallas** · de abajo arriba rodeando por un lado = **reverso**
  - zigzag de tres tramos = **escalada** · de dos tramos = **wall climb** · diagonal curvada = **wall run** (pared al lado)
  - un círculo solo = **cat leap** (pared delante)
  Si dibujas un vault un poco antes de llegar al obstáculo, queda en espera ~1 s y sale al llegar; dibujado andando o parado delante del obstáculo también sale (con un par de pasos de impulso). La M vale ancha, estrecha, con el valle hondo o como la letra M con los lados rectos.
- **SALTO + joystick hacia delante**: **parado = salto de precisión** (pies juntos, brazos al frente, recepción clavada); **en carrera = salto de longitud** (despegue a un pie, pedaleo en el aire y caída con los dos pies). Puedes dirigir al atleta en el aire en los dos (cambiar de dirección o frenar, sin acelerar). Los dos detectan el borde al que llegan (muro, bordillo, otra plataforma o la parte de arriba de un obstáculo) y ajustan el salto para caer justo en él y clavarlo; sin borde delante, la precisión es de ~1,8 m.
- **Botón 1 PIE**: abajo a la izquierda, junto al joystick de movimiento. Cada joystick tiene su zona: un dedo que empieza en uno nunca activa otro, y los tres funcionan a la vez (correr + mortal + tirabuzón). Mientras dibujas se ve una estela que sigue al dedo; al reconocer el gesto el joystick se ilumina y su nombre aparece encima del joystick (sin tapar al atleta). Reconocedor: `scripts/input/gesture_recognizer.gd` (plantillas normalizadas al radio del joystick, umbrales configurables).
- **Botones de mortal ATRÁS · ADELANTE · LATERAL** (encima de SALTO): pulsar = **agruparse** para hacer ese mortal; se abre solo al completarlo para caer. Primero SALTO y luego el botón en el aire; sin SALTO solo hay un saltito sin impulso y, sin altura, lo normal es no caer de pie. **Dobles**: cada pulsación más en el aire, en cualquier momento del mortal (o antes de despegar), es **una vuelta más** y sigue agrupado: dos pulsaciones = doble, tres = triple. **Mantener el botón** = agrupado y girando todo el rato: tantas vueltas como quepan en el vuelo a un ritmo que se aprecia (~0,57 s por vuelta; desde el suelo una, desde una altura dobles o más); al soltar termina la vuelta en curso y se abre. Los mortales giran a una velocidad que se ve: la vuelta ocupa casi todo el vuelo. Gira lo que haga falta hasta un tope físico: sin altura no se completa. Tras un tirabuzón también vale: SALTO → ADELANTE → GIRO hasta el medio tirabuzón → ATRÁS = Double Arabian. LATERAL va hacia la izquierda si empujas el azul a la izquierda. El **impulso** es del botón SALTO: mantenerlo un instante antes de soltar = salto más alto.
- **GIRO en el aire = tirabuzón, nunca más mortal**: al girar el cuerpo se estira (con las piernas un poco flexionadas, natural y listo para agruparse) y gana giro sobre el eje largo; el mortal va más lento. Agrupado el tirabuzón cuesta. Mantener GIRO = más tirabuzón (Piru 720, 1080...).
- **CHUTADA** (mortal chutado): en el joystick dorado, **diagonal recta hacia arriba** (hacia el lado de la pierna de patada). Patada como a un balón para despegar y después un **backflip normal** (agrupado, sin tirabuzón). Con GIRO durante el mortal se convierte en cork (360, 540, 720 según lo mantengas). La diagonal con un círculo al final sigue siendo el cork.
- **Joystick dorado (SALTO)**: tocar = salto. Solo gestos de acrobacias complejas y parkour:
  - aerial (arco lateral) · aerial twist (arco + círculo) · cork (diagonal arriba + círculo; dos = cork 720) · webster · gainer (abajo + vuelta ovalada).
  - Con pared delante: **palm flip** (línea arriba + círculo: manos a la pared y mortal atrás; con el morado inclinado sale **palm half / palm full / palm double full**), wall flip, wall run, escalada, wall climb, cat leap, agarre de borde.
  - Con obstáculo delante: vault (U invertida) · kong (dos arcos) · **pasavallas** (sube y pasa de lado, Γ) · **reverso** (de abajo arriba rodeando por un lado: entra de espaldas a una mano, media vuelta y sale mirando adelante).
  - Precisión (línea corta + toque) y rodar (curva hacia abajo y adelante).
- **Joystick morado (GIRO)**: **en el aire** es un joystick: izquierda = gira a la izquierda, derecha = a la derecha, sobre el eje del cuerpo en cualquier mortal (atrás = piru, adelante = front full, lateral = sideflip twist); al soltar termina en el cuarto de vuelta más cercano. **En el suelo** reconoce el trazo al soltar:
  - Líneas: ↑ rondada · ↓ flic-flac · ← → rueda.
  - **Desactivados por ahora** (se rehacen sus animaciones y volverán): macaco, touchdown raiz, scoot, scoot fuerte y pino.
  - Solo un círculo = salto con giro de 360.
- **Backflip de captura real** (desbloqueable con 20 backflips; Ajustes › Estilo de backflip): movimiento de un atleta real de la base de datos pública de captura de movimiento de Carnegie Mellon (CMU, uso libre también comercial), sincronizado con el giro del juego: flexión y braceo reales, agrupado y apertura. El backflip clásico sigue siendo el de por defecto. Conversión: `tools/mocap/cmu_to_clip.py`.
- **Botón 1 PIE** (abajo a la izquierda): es un interruptor. Púlsalo una vez y queda activado (el botón se ilumina): todos los mortales caen a un pie, alternando la pierna, hasta que lo vuelvas a pulsar. Los saltos sin voltereta siguen cayendo con los dos pies. En la recepción a un pie la pierna de apoyo queda flexionada y la otra estirada atrás, lista para lanzarse al siguiente mortal; durante ~0,8 s hay una ventana de enlace para encadenar el siguiente mortal o habilidad sin apoyar el otro pie (backflips o corks a un pie seguidos).
  - **Botón de mortal justo antes de caer** (últimos 0,3 s, ya bajando): ya no añade una vuelta que no cabe; queda para el siguiente mortal, que sale al recepcionar (a un pie si 1 PIE está activado, o con rebote si caes con los dos).
- **ATRÁS junto a un muro u obstáculo** (botón de mortal, sin SALTO):
  - **Plancha back**: parado y pegado a un muro bajo (hasta ~1,4 m), sin mover el personaje: manos al muro, patada arriba hasta la plancha, empuje de brazos hasta quedar de pie en el aire y mortal atrás, cayendo en el mismo lado.
  - **Plancha back pasando el muro**: igual, pero empujando el joystick hacia el muro: tras la plancha la cadera pasa por encima de las manos y el mortal atrás cae al otro lado (también saltando una valla con caída).
  - **Kong + mortal atrás (Kong Gainer)**: en carrera, a ~1 m del muro, ATRÁS mientras el personaje va hacia delante: apoyo de kong, rodillas al pecho y mortal atrás por encima del obstáculo, cayendo al otro lado. También durante la primera mitad del apoyo de cualquier kong, y corriendo hacia el borde de una altura (manos en el borde y mortal en la caída).
  - Muro demasiado alto para todo eso: parado = **palm flip**, en carrera = **wall flip** (nunca un saltito que se estrella contra el muro).
- **Bonus perfecto**: si caes un mortal en recepción perfecta y enlazas otro mortal antes de 0,9 s (sin pararte), el siguiente sale más alto (+0,9 m/s de impulso) y gira un 15 % más rápido, con aviso «RECEPCIÓN PERFECTA · +ALTURA +GIRO». Se acumula con cada recepción perfecta seguida, hasta x3; si fallas la recepción o te paras, vuelve a empezar.
- **Cámaras** (botón CÁMARA, arriba a la derecha): NORMAL · **POV** (cámara de acción en la cabeza, tipo GoPro) · **DRON** (alta y detrás, siguiendo con retraso).
- **Repetición** (botón REPETIR o Pausa › Ver repetición): reproduce los últimos 15 s con **cámara libre** (arrastra para girar alrededor del atleta, + / - para acercar), POV, dron o seguir, a velocidad x1, x0.5 o x0.25, con barra para buscar el momento. Para guardar el vídeo, usa la grabación de pantalla del móvil mientras se reproduce.
- **PRÁCTICA** (acceso rápido o Pausa › Práctica de gestos): todos los gestos uno a uno con su dibujo de ejemplo; marca los que haces bien y avisa de lo que has dibujado si no coincide.
- **Eliminados**: butterfly kick, crescent, crescent inversa, voltereta al pino (back extension roll), paloma (front handspring), valdez, back walkover, front walkover, hook y raiz.
- **1 · MORTALES**: atrás, adelante, lateral izq. y der., cork, aerial/mariposa, patada 360 (sin botón de piru: los tirabuzones van con el joystick GIRO).
- **2 · SUELO**: rondada, flic-flac, rueda, macaco, pino (se sostiene mientras mantienes el botón), atrás, cork.
- **3 · TRICKING**: hook, raiz, TD raiz, macaco, patada 360, cork.

**Girar la rueda**: toca CAMBIAR (siguiente página) o desliza el dedo sobre CAMBIAR hacia arriba (siguiente) o hacia abajo (anterior). Los botones entran girando por el arco y encima se ve el nombre de la página.

Cómo se usan:
- **Mantener pulsado el botón de un mortal = el atleta sigue agrupado y girando**: doble, triple o las vueltas que permita la altura. Al soltar se abre y aterriza en la siguiente vuelta completa; con ayuda Alta o Media se abre solo si ya no queda altura para otra vuelta.
- Corriendo, ATRÁS es gainer y ADELANTE, webster.
- **PIRU**: mortal atrás con tirabuzón de 360 suelto (ATRÁS + una vuelta de GIRO; con más GIRO, Piru 540 / 720).
- **CORK**: el mismo giro dentro de un combo (tras TD Raiz, raiz, hook, rondada/flic-flac) o con el botón **CORK**. En el suelo es un **cork quieto** (sin carrera): carga con la pierna de patada atrás y los brazos atrás, patada arriba en diagonal por delante del cuerpo con los brazos arriba, despegue vertical, primero la inversión hacia atrás y después el tirabuzón de 360 con piernas juntas y brazos cerrados al pecho; abre bajando primero la pierna de patada (GIRO en el mismo sentido lo alarga a 540 / 720; el joystick izquierdo elige el sentido). Si ya estás en el aire —por ejemplo, saltando desde el borde de una altura— pulsar CORK empieza el cork justo en ese punto.
- **Parkour + mortal**: pulsa un botón de mortal (o CORK / PATADA 360) durante cualquier vault y, al salir del obstáculo, el empuje de brazos te lanza para hacerlo antes de caer (Kong → mortal atrás, Speed → lateral...).
- **Dive Kong**: salta con carrera *lejos* del obstáculo. Las manos solo llegan si la trayectoria da: muy cerca es un kong normal, a media distancia el salto pasa por encima, demasiado lejos te quedas corto. Se mide la distancia del despegue al muro y se guarda tu récord para ir alargándola. El kong (y los demás vaults) **pasa el obstáculo**: los pies cruzan por encima de toda la caja y caes al otro lado. Si el obstáculo es **muy largo** (más de ~2,2 m), el kong termina **de pie encima** (Kong Up).
- **ST**: pulsa CORK durante un cork y caerá **a un pie**. El siguiente cork (o lo que quieras) lo enlazas tú con CORK + SALTO en la recepción: Cork › ST › Cork se hace movimiento a movimiento.
- **Sin botones de combo**: cada botón o gesto hace **un único movimiento**. Ningún botón encadena varios (nada de «rondada + flic-flac + mortal» de un toque): los combos salen de enlazar a mano, uno a uno, en la ventana de cada recepción.
- La rueda, la rondada y el macaco van hacia el lado al que empuja el joystick izquierdo.
- **Rueda, rondada y flic-flac con ritmo real** (≈1 s, 0,84 s y 0,76 s): la rotación sigue curvas suaves entre poses (sin tirones de velocidad en cada fase), el cuerpo se adapta a la altura del apoyo de manos en ~0,12 s en vez de en un fotograma, la mano se clava donde cae y, al pasar el peso de una mano a la otra, el cuerpo ya no da un salto.
- Pulsar un botón durante un movimiento lo deja en cola para la recepción. Por ejemplo, RONDADA → FLIC-FLAC → ATRÁS.
- **Joystick izquierdo**: movimiento. **Joystick GIRO**: todos los tirabuzones y giros (¼ híper, ½, 1, cork, 720…). En el suelo, el joystick GIRO también hace los gestos de abajo (raiz, hook, walkovers, pino…).
- El esquema anterior sigue disponible en Ajustes → Controles de trucos.

**Doble joystick (rueda)**: joystick izquierdo, **rueda de SALTO/MORTALES**, **joystick GIRO** y VAULT, AGARRAR, RODAR.
- **Joystick izquierdo** (abajo a la izquierda): moverse de forma analógica; a fondo = sprint (se acumula corriendo recto).
- **Rueda de SALTO** (encima del joystick derecho): el **centro** es SALTO (mantener junto a una pared = Wall Run; en el aire junto a una pared = Tic Tac). Las cuatro zonas de alrededor saltan y hacen su mortal: **ATRÁS** (Backflip; corriendo, Gainer), **ADELANTE** (Frontflip; corriendo, Webster) y **LATERAL ← →** (Sideflip, siempre encogido; **corriendo, el atleta se pone de lado antes de despegar y avanza girando, mirando al lado**). Mantener el dedo en la zona = agruparse (gira más rápido); soltarlo = abrirse y preparar el aterrizaje. Pulsar otra zona igual en el aire = otra vuelta (doble). **La rueda solo hace saltos y mortales: nunca gira** (ni el centro pulsado otra vez en el aire ni la zona LATERAL durante un mortal); los tirabuzones y giros son exclusivamente del joystick GIRO.
- **Joystick GIRO** (derecho): controla el tirabuzón de **todos** los mortales. Inclinado a un lado gira (más inclinado = más rápido); al soltarlo termina en el cuarto de vuelta más cercano: **¼ = Híper** (aterriza de lado), **½** (Back Half, Árabe, Raiz…), **1** (Back Full, Front Full…), 1½, 2… Corriendo, **ATRÁS + una vuelta de GIRO = Cork**; dos vueltas = Cork 720. Sin mortal, en el aire = pirueta / patada giratoria; tocarlo sin inclinar = un giro completo.
  - **En el suelo** (sin saltar) el joystick derecho reconoce gestos y contexto (`scripts/input/gesture_interpreter.gd`):
    - **Inclinar y soltar** (flick): ← → **Rueda** · ↙ ↘ **Rondada** · ↓ **Flic-flac** · ↗ 360 Kick / Tornado · ↖ Aerial (parado) / Butterfly (con carrera).
    - **Mantener** (0,5 s): ↑ **Pino** (se sostiene mientras no sueltes; al soltar o con SALTO, **Handstand Push-off / snap down**) · ← → **Raiz** · ↖ ↗ **Touchdown Raiz** · ↙ ↘ **Macaco**.
    - **Arco** (girar el joystick ≥ 135°): por abajo = **Hook Kick**.
    - **Cambio de dirección** (← y enseguida →): **Scoot**.
    - **Tumbado tras una caída**: SALTO o ↑ = **Kip-up**.
  - **Enlaces**: cada habilidad abre una **ventana de enlace** al recibir con los pies (el HUD muestra «¡ENLAZA!»). Un gesto hecho durante la habilidad queda en cola y sale en la recepción; la rueda salta con el rebote. Ejemplos: Rondada → Flic-flac → Backflip / Double Backflip / Cork / Double Cork, Flic-flac → Flic-flac, Macaco → Flic-flac o Backflip, Hook → Cork, Raiz → Cork, TD Raiz → Butterfly Twist, Scoot → B-Twist, Aerial → Butterfly, Rueda → Backflip. SALTO sin mortal en la recepción = *Rebound* (rebote vertical).
- **VAULT**: supera el obstáculo con la técnica viable según velocidad, ángulo y forma (Step, Speed, Lazy, Kong, Dash, Step Up). Con el joystick derecho inclinado elige variante: ← → Reverse Vault, ↑ Double Kong, ↓ Kash Vault, ↖ ↗ Thief Vault (obstáculo estrecho y con carrera), ↙ ↘ Turn Vault (cae frenado de cara al obstáculo). Si el obstáculo no permite la variante, hace la técnica normal. Ante una pared alta, trepa.
- **AGARRAR**: junto a una pared alta, trepar; en el aire, agarrar el borde (si ya estás casi vertical); colgado se convierte en **SOLTAR**.
- **Rodar es automático**: al caer desde una altura alta (~4 m o más) cayendo de pie, rueda solo (Safety Roll) y no hay recepción dura. En la botonera ya no hay botón RODAR (en teclado sigue Ctrl y en el dorado el gesto de rodar).
- **En la pared** (wall run, wall climb o colgado): rueda ATRÁS = Wall Flip / Wall Gainer · ADELANTE = Wall Front · LATERAL = Wall Sideflip.
- **Cámara**: arrastra en cualquier zona libre de la pantalla (arriba, entre el centro y SALTO, donde pone CÁMARA, o la franja superior izquierda) para girarla mientras corres con el otro pulgar. **Doble toque** en esa zona = cámara detrás del atleta. Es híbrida: sigue al atleta y se alinea detrás del movimiento, pero respeta durante 1,2 s lo que hayas movido a mano; tras un tirabuzón vuelve sola detrás. Mando: stick derecho y clic del stick izquierdo para recentrar; teclado: Q/E y T.
- **Parkour con ritmo pausado**: cada vault tiene una duración mínima (speed ~0,6 s, kong ~0,75 s, doble kong ~1 s, kash/reverso ~0,8 s...) y las subidas a bordes son más lentas (subida 0,6 s, mantle 0,45 s): da tiempo a ver y encadenar; la velocidad de salida se mantiene.
- **Rondada o flic-flac dibujados en el aire** (trazo vertical en el morado durante un salto o mortal: arriba = rondada, abajo = flic-flac; vale torcido hasta ~40° y algo curvo): salen al tocar el suelo. Se pueden dibujar varios seguidos (hasta 3) y salen encadenados en el mismo orden: frontflip › rondada › flic-flac. Los trazos verticales no hacen girar el mortal. Un botón de mortal pulsado durante la rondada queda en cola hasta la recepción: frontflip › rondada › backflip.
- **Cámara rediseñada para parkour** (`scripts/camera/camera_rig.gd`): todo se mueve con muelles críticamente amortiguados (sin tirones ni rebotes); anticipa un poco hacia donde corres; en el aire **no gira sola** y la anticipación se congela (calculas la trayectoria con un encuadre fijo); en los saltos sube poco para que veas dónde caes y al caer desde alto acompaña de cerca; sin giros ni zooms durante los mortales. **Colisiones**: barre con una esfera desde el pecho del atleta (nunca atraviesa paredes ni pierde de vista al atleta), con un barrido más ancho que ve venir la pared y se acerca con suavidad; si una pared la empujaría demasiado cerca, sube por encima o se desliza hacia un lado libre en vez de meterse en la cabeza del personaje, y recupera la distancia despacio. Inclinación limitada (nunca mira al cielo).
- **FLOW** (barra arriba en el centro): sube con movimientos distintos, dificultad, uso del entorno (vaults, paredes, agarres, precisión), aterrizajes limpios y continuidad; baja al repetir el mismo truco, aterrizar forzado o duro, pararse o caerse. Por encima de 60 (EN FLOW) da un extra pequeño: velocidad punta +6 %, salto +4 % y recuperación más rápida.
- **Carrera acumulada**: el sprint completo se gana corriendo recto (~1 s); un giro cerrado, frenar o una mala recepción lo reducen. Desde parado hacia atrás, el atleta gira sobre sí mismo antes de acelerar.
- **Menú de pausa**: Reaparecer, **Movimientos** (biblioteca con más de 100 técnicas por categoría, su entrada y su estado) y **Tutorial de controles** (16 pasos que avanzan al hacer cada movimiento de verdad).

**Otros modos (Ajustes → Controles de trucos)**: *Solo gestos*, *Solo cruceta* y *Gestos + cruceta*.
- Gestos: pulsa SALTO y, sin levantar el dedo, deslízalo (mismas direcciones que el joystick derecho). Deslizar dos veces igual = doble. En el aire, la zona derecha también acepta gestos.
- Cruceta TRUCOS: pulsar = truco, mantener = agruparse, tocar LATERAL durante un mortal = tirabuzón, centro = GIRO. Las direcciones principales tienen zonas más grandes que las diagonales.
- Volver a pulsar SALTO en el aire: sin mortal = patada giratoria (360 Kick / Tornado Kick, cada toque suma media vuelta: 540, 720 / Cheat 720, 900, 1080); durante un mortal = tirabuzón completo.
- Gesto justo antes de un vault: lateral = Reverse Vault; en caja de kong ↑ = Double Kong, ↓ = Kash Vault. Gesto durante el vault = mortal al salir (Kong Gainer, Dash Bomb, Kong Front...).

**Teclado**: WASD + Shift · Espacio salto (mantener: wall run; otra vez en el aire = giro) · Flechas = mortales (mantener = agrupado; tricking de suelo si las mantienes sin saltar) · U / O = GIRO izquierda / derecha · V vault · G agarrar · Ctrl rodar · R reaparecer. Mando: gatillos = GIRO.

Ajustes: ayuda de rotación (Alta / Media / Pro), controles de trucos (doble joystick / solo gestos / solo cruceta / gestos + cruceta), tamaño de controles, cámara (híbrida / manual / automática), distancia y altura de cámara, opacidad, sensibilidad de cámara y del joystick derecho / gestos, y modo zurdo.

**Habilidades con apoyo** (`scripts/player/skill_library.gd`): rondada, flic-flac, rueda, macaco, kip-up, pino y snap down, hook, raiz, touchdown raiz y scoot. Cada una tiene **fases con nombre**, la orientación del cuerpo, la altura del centro de masas, una forma corporal por fase y qué manos o pies apoyan. El rig **clava la mano en un punto del suelo** y resuelve brazo y pierna con **IK de dos huesos** mientras el cuerpo gira por encima. Ninguna mano ni pie puede quedar por debajo del suelo en ningún estado. En los **vaults** las manos se apoyan sobre el obstáculo con la misma IK: dos manos en Kong, Double Kong, Kash y Turn Vault; la mano del lado bajo en Speed, Lazy, Reverse, Step y Thief Vault. El cuerpo se coloca con los hombros sobre las manos. El backflip no apoya las manos; el flic-flac sí.

**Potencia** (`SkillLibrary.power` + `scripts/player/chain_system.gd`). Cada técnica define estos parámetros:
- velocidad de desplazamiento: mínima/máxima y fracción conservada de la velocidad de entrada;
- impulso de piernas y bloqueo de brazos;
- conversión de velocidad horizontal en vertical;
- caída del centro de masas en la recepción (de ahí sale la velocidad de recepción);
- elasticidad (rebote disponible);
- estabilidad;
- giro de salida.

Al enlazar, el siguiente movimiento hereda:
- **rebote**: altura que sale de la recepción, no un multiplicador; tope de 3,2 m/s;
- **giro**: un hook, raiz o scoot acelera el tirabuzón con GIRO un 30 %;
- **barrido**: la pierna lanzada da la rotación de un butterfly o un gainer;
- **velocidad de salida**.

El timing cuenta: el rebote completo solo existe al principio de la ventana. Una transición incoherente no hereda nada.

El personaje es una **malla continua con piel** (tronco, cuello, brazos y piernas) generada por código con un esqueleto que sigue a las articulaciones de la animación: hombros, codos, caderas y rodillas se doblan con volumen, sin piezas que se separen. La ropa usa colores por zona (sudadera, puños, pantalón, calcetín) y relieve de tejido. El atleta realista usa materiales opacos ajustados (piel mate natural, ropa negra que muestra sus pliegues, zapatillas sin brillo plástico), manos relajadas con los dedos algo curvados y brazos que caen junto al cuerpo en reposo. Las poses se mezclan con un muelle amortiguado por articulación (las extremidades llegan un instante después que el tronco), la carrera tiene la rodilla casi recta en el apoyo y muy doblada en el balanceo, y en los mortales la cabeza busca el suelo al final del giro.

Cada acrobacia tiene su propio ritmo de giro (backflip explosivo; aerial y butterfly más amplios), el doble mortal gira más rápido que el simple, y se anima por fases a partir del giro real: preparación (flexión antes de despegar), impulso, agrupación, rotación, apertura y recepción, con una forma corporal propia para Backflip, Frontflip, Sideflip, Gainer, Webster, Butterfly Kick, Cork y tirabuzones.

## Cámara lenta

Al empezar cualquier mortal, el tiempo va más despacio durante 1,5 s reales: entra en 0,12 s hasta el 35 % de la velocidad, se mantiene hasta el primer segundo y vuelve suavemente a la normalidad. La cámara se acerca un poco (el campo de visión se cierra 9°) mientras dura. Se puede desactivar en Ajustes → «Cámara lenta al empezar un mortal».

## Zonas

- **Parque de obstáculos** (en la ciudad, al fondo a la derecha del callejón de wall run). Tiene cuatro calles con alturas distintas:
  - **Vaults**: barandilla baja de 0,8 m, caja de 1,1 m, caja larga de 2,6 m, murete de 0,6 m y barandilla con postes.
  - **Muros**: 0,7 m, 1,3 m, 1,9 m, 2,6 m y 3,4 m, para step up, kong up, climb up, colgarse y escalar.
  - **Precisiones**: pilares de 0,6 a 1,4 m de alto y dos plataformas separadas 3 m para el salto de longitud.
  - **Muro de 4,5 m**: para wall run, con un muro corto junto a una caja (tic-tac) y una pared con borde (cat leap).
  - **Torre de caídas** de 4,5 m con escalera.
- **Plaza de movimientos** (junto al parque): muro bajo para la plancha back, plataforma de 1,6 m con escalera y valla en el borde (kong gainer desde parado cayendo de altura), borde abierto (kong gainer en el borde) y valla de 1 m a ras de suelo (kong gainer corriendo).
- **Playa** (modo propio en el menú): un arenal con una boya de barco roja grande (2,3 m de diámetro) medio enterrada en el centro.
  - Llegar a la boya corriendo (andando no rebota), o caer encima de ella, te lanza mucho más alto que un salto normal.
  - **Impulso perfecto**: pulsa SALTO justo al pisarla (hasta 0,12 s antes, o un instante después) y subes mucho más. Si lo pulsas algo antes (hasta 0,3 s), el impulso es menor.
  - Los saltos de precisión y de longitud detectan la boya, corrigen la dirección y caen encima. Cayendo cerca, el cuerpo se dirige un poco hacia su centro.
  - En el aire, los mortales se hacen con los botones de siempre.
  - La arena amortigua las recepciones.

## Pruebas

Aceptación de acrobacias por la ruta táctil real (gestos sobre SALTO y doble joystick, multitáctil), criterio a criterio (`-- --only=joystick` para una parte, `-- --capture=dir` para grabar):
```
godot --headless --fixed-fps 60 --path freerun res://tests/acceptance_tricks.tscn
```

```
godot --headless --fixed-fps 60 --path freerun res://tests/test_runner.tscn
```
Un bot conduce al personaje con el mismo `InputIntent` que los controles reales y valida carrera, salto, mortales, sobre-rotación, vaults, wall run, bordes, caídas con y sin rodar, precisión, agua, gestos táctiles, combos, reaparición y modos.

Capturas (necesita pantalla o Xvfb): `xvfb-run godot --rendering-driver opengl3 --path freerun res://tests/screenshots.tscn -- --out=/tmp/shots`

## Arquitectura

```
scripts/
  core/      game.gd (orquestador), settings.gd y save_data.gd (autoloads)
  input/     InputIntent + InputRouter: teclado, mando, táctil y bots → una intención por frame;
             GestureInterpreter (flick, mantener, arco, cambio de dirección, doble, soltar)
  player/    PlayerController (núcleo único de movimiento), MoveTuning, ObstacleSensor,
             TrickSystem (rotaciones aéreas), SkillLibrary (habilidades de suelo por fases),
             ChainSystem (ventanas de enlace y transferencia de potencia),
             BodyRig (personaje, animación procedural e IK de apoyos)
  camera/    CameraRig
  combo/     ComboSystem (puntuación: multiplicador, variedad, repetición, velocidad, continuidad)
             FlowSystem (medidor FLOW 0-100 y su pequeño extra al atleta)
  modes/     GameModes: Freerun, Tricking, Water, Challenge (con ghost), Freestyle
  level/     LevelBuilder (escenario de pruebas) + shaders/world_grid
  ui/        GameUI (HUD, menús, ajustes), TouchControls
```
El `InputIntent` es la frontera entre dispositivos y personaje: replays, ghosts y un futuro multijugador pueden alimentar al mismo controlador.

## Exportar

- **Android**: Godot → Editor → Manage Export Templates; configura el SDK de Android y JDK 17 en Editor Settings; Project → Export → Android.
- **Web**: preset "Web" sin hilos (compatible con Safari/iOS y GitHub Pages). Se publica sola al subir cambios a `main`.
- **iOS**: requiere macOS con Xcode. Project → Export → iOS genera un proyecto Xcode que se firma y compila en el Mac.

## Biblioteca de movimientos

En el juego los nombres se muestran en español (Mortal atrás, Rondada, Flic-flac, Salto de gato…); `scripts/core/move_names.gd` guarda la traducción y por dentro se usa el nombre original.

`scripts/core/move_library.gd` (en el juego: Pausa → Movimientos) cataloga 125 técnicas en 18 categorías: vaults, precision, paredes, escalada, barras, rolls, mortales, laterales, aerials y websters, gainers, corks, butterfly y patadas, tricking, handsprings, ruedas y rondadas, suelo, combos y avanzados.

- **Estado**: 90 hechas (impulso, trayectoria y postura propias, con prueba), 12 parciales (se reconocen y rotan bien, pero comparten postura con su familia) y 23 pendientes (Master Scoot incluido: no he podido verificar su técnica) (cada una con el motivo; las de barra necesitan barras en el mapa).
- **Validación en 5 niveles** (no se confunden): 1 documentado · 2 implementado · 3 probado técnicamente · 4 inspeccionado visualmente · 5 validado en móvil. Ninguno está en 5 hasta que se confirme en un iPhone.
- **Fuentes**: nombres, variantes y niveles de [pkfr.world/tutorials](https://pkfr.world/tutorials/) y [trickipedia.app](https://www.trickipedia.app/). Ninguna describe la técnica en texto y sus vídeos no se han podido ver, así que la biomecánica del juego se basa en la técnica deportiva estándar.

## Referencia de diseño: STORROR Parkour PRO

Se usa como referencia de filosofía (control del cuerpo, timing, continuidad, flow), no de código ni recursos.
- **Comprobado públicamente**: la página de Steam (capturas de movimiento combinadas con movimiento por físicas, libertad para elegir qué y cuándo) y las notas de parche visibles en Steam (existe un estado *flow*, dive roll, detección de bordes, retícula de escalada/dyno, físicas del balanceo). Esas notas no explican cómo se construye el flow, la cámara ni los controles en detalle.
- **No comprobado**: los vídeos de YouTube y las notas de parche más antiguas no se han podido ver desde este entorno. Lo que aquí se implementa (flow, cámara híbrida, carrera acumulada) es diseño propio inspirado en esos principios.

## Trucos reconocidos

- **Mortales atrás**: Backflip, Gainer, Double Backflip/Gainer, Triple Backflip, Back Half, Cheat Gainer, Back Full, Gainer Full, Back 1.5, Double Full, Full In, Cork, Cork 540, Cork 720, Cork 1080, Double Cork, Triple Cork.
- **Mortales adelante**: Frontflip, Webster, Double/Triple Front, Arabian, Front Full, Rudi, Front Double Full, Double Arabian.
- **Laterales**: Sideflip (bola cerrada, con o sin carrera), Double Sideflip, Raiz, Aerial Twist, Aerial Double Twist.
- **Butterfly**: Butterfly Kick, Double Butterfly, Butterfly Twist, Butterfly Twist 720.
- **Patadas giratorias**: 360 Kick, Tornado Kick, 540 Kick, 720 Kick, Cheat 720, 900 Kick, 1080 Kick.
- **Desde pared y vault**: Wall Flip, Wall Gainer, Wall Front, Wall Full, Wall Half, Wall Sideflip, Kong Gainer, Dash Gainer, Vault Gainer, Dash Bomb, Kong Front, Ledge Backflip.
- **Parkour**: Speed, Kong, Double Kong, Kash, Dash, Lazy, Reverse, Step Vault, Step Up, Climb Up, Wall Run, Tic Tac, Wall Climb, Cat Leap, Mantle, Shimmy, Precision Jump, Drop Landing, Safety Roll.
