# Auditoría: disparar a pie (móvil primero; también ordenador y mando)

Lo que dijo Sebastián (juega en el **móvil**): «el sistema de disparos también va mal» y, antes,
«disparar malísima». Captura: `docs/bugs/invasion-luminidos-banner.png` (invasión de los Lumínidos en
Valmar de noche, botones Atacar / Defensa / Esquivar / Agacharse / Correr / Saltar).

Cómo se ha probado: leyendo todo el camino de un disparo (botón → `WeaponController` → remoto
`Weapons` → `WeaponService` → `CombatService.applyHit` → `InvasionService` → «acierto» de vuelta) y
haciendo las cuentas con Lune (`scripts/test-shooter`, `test-weapons`, `test-combat`, `test-invasion`).
Los números de abajo salen de esas cuentas.

Piezas que intervienen:

| Qué | Dónde |
| --- | --- |
| Armas (daño, dispersión, retroceso, cadencia) | `src/shared/Weapons.luau` |
| Ayuda al apuntar (fricción, imán, imán de la bala) | `src/shared/AimAssist.luau`, ajustes en `src/shared/ShooterPrefs.luau` |
| Compensación de lag contra alienígenas | `src/shared/Invasion/HitCheck.luau`, `InvasionService.rewindHit` |
| Cliente: mira, botones del móvil, cámara al hombro, trazos, aspa, números | `src/client/Controllers/WeaponController.luau`, `WeaponFx.luau`, `FootCamera.luau` |
| Servidor: decide si el disparo cuenta | `src/server/Services/WeaponService.luau` (`fire`) |

## Bugs confirmados (arreglados)

Ordenados de más a menos importantes. Los números de línea son los de antes del arreglo.

1. **El trazo que ves no es la bala de verdad** (alta). El cliente dibuja el trazo con su propio
   `math.random()` (`WeaponController.luau:531`) y el servidor tira **otro** dado distinto para la bala
   (`WeaponService.luau:597`). Resultado: veías el trazo dar al alienígena y el servidor fallaba (sin
   aspa ni número), o al revés. Es justo la sensación de «disparo malísimo».
   **Arreglo**: los dos usan los mismos dados. El servidor pone una semilla por jugador (atributo
   `WeaponSeed`) y cada disparo lleva su número (`Weapons.shotRoll(semilla, número, perdigón)`). El
   cliente manda el número; el servidor lo acepta solo si es el siguiente o poco más
   (`Weapons.nextShotNumber`, como mucho 3 por delante), nunca hacia atrás. Sigue decidiendo él.

2. **La dispersión no era «más cerca del centro»** (alta). El comentario lo decía, pero el radio usaba
   la raíz (`Weapons.luau:586`), que reparte las balas **por igual** en todo el círculo: la mitad iban al
   30 % de fuera. **Arreglo**: el radio crece con el dado (más balas cerca del centro). En la prueba,
   la mitad de dentro del cono se lleva el 50 % de las balas (antes, el 25 %).

3. **Desde la cadera y andando, casi no se acertaba** (alta). En el móvil se dispara siempre andando
   con el joystick y sin apuntar. Cono de la pistola andando: unos 4,3°; del fusil: unos 6,2°, **también
   el primer tiro**. Contra un soldado (radio ~1,3 studs) a 25 studs, el fusil daba ~30 % de las veces.
   Además, correr deprisa abría hasta 1,5 veces (`Weapons.luau:555`).
   **Arreglo**: el **primer disparo** tras una pausa (en el suelo, sin correr) va casi recto a la mira
   (`Weapons.FirstShot` = 30 % de la dispersión; no en las escopetas), y moverse abre como mucho lo de
   andar. En la prueba: pistola andando a 50 studs, el primer tiro da el 100 % de las veces; los
   siguientes, 69 % (antes 50 %).

4. **Las balas de la pantalla iban con retraso y nunca salía «RECARGANDO…»** (media). El contador
   «12 / 36» solo se repintaba cuando llegaba el atributo del servidor (`WeaponController.luau:1364`);
   la bala que gastabas tú no se veía hasta tu ping, y como `reloadingUntil` (línea 699) no repintaba,
   el texto «RECARGANDO…» casi nunca aparecía. **Arreglo**: se repinta 12 veces por segundo con el arma
   en la mano.

5. **En el móvil, mantener Disparar con una pistola solo daba un tiro** (media). La ráfaga al mantener
   era solo para armas en automático (`WeaponController.luau:1284`). **Arreglo**
   (`Weapons.holdRepeats`): en el móvil, mantener Disparar con un arma que solo es semiautomática
   (pistola, revólver, escopeta…) repite a su cadencia (el servidor la sigue mirando). Si el arma tiene
   Auto y Semi y eliges Semi, sigue tiro a tiro. Con ratón, igual que antes.

6. **Sin recarga automática** (media). Al gastar la última bala había que volver a pulsar (clic en
   seco, línea 457) para que recargase. **Arreglo**: recarga sola 0,25 s después de la última bala si
   te quedan en la mochila.

7. **La cápsula de la compensación de lag usaba números fijos** (media). `InvasionService.rewindHit`
   (línea 1106) usaba el alto y el radio de las reglas, no el modelo. Si cambian los modelos de los
   alienígenas (otro agente los está cambiando), la cápsula ya no coincide. **Arreglo**:
   `HitCheck.shape` saca el alto, el ancho y dónde empieza la caja del **raíz del modelo** (la caja del
   tamaño del alienígena, en los de piezas y en los de malla); sin raíz, los números de siempre.
   Además, un **imán de la bala del servidor** pequeño (`HitCheck.Slack` = 1,2°, solo alienígenas): un
   disparo que pasa rozando a uno lejano también cuenta.

8. **La ayuda al apuntar podía quedarse en un caído** (baja). La lista de enemigos se renueva cada
   0,2 s, pero entre medias no se miraba si el alienígena se había quedado sin vida o el enemigo de
   misión estaba en el suelo (`WeaponController.luau:377`). **Arreglo**: `AimAssist.pick` ignora a los
   caídos (`Dead`) y a los que están fuera de alcance.

9. **La mira saltaba de golpe con cada disparo** (baja, `WeaponController.luau:888`). **Arreglo**: se
   abre rápido y se cierra suave (`Weapons.reticleEase`).

Lo que ya estaba bien y se ha comprobado: el disparo sale hacia la **mira del centro** (rayo de la
cámara → punto del mundo → la bala de la cabeza a ese punto; el trazo, de la boca del arma), el
servidor decide el daño (el cliente solo manda un punto y un número), compensación de lag con tope de
0,4 s, nunca a través de paredes ni más allá del alcance, ayuda al apuntar solo hacia alienígenas y
enemigos de misión y solo en móvil y mando (con ratón no, salvo que la enciendas), la cámara nunca da
saltos sola, aspa (amarilla en la cabeza, roja si cae), chasquido distinto, números de daño, respingo
del alienígena, impactos de chispas de luz (nada de sangre).

## Hipótesis (sin confirmar; no se han tocado)

1. **En la captura no lleva ningún arma.** La barra rápida tiene teléfono, gorra, bici, coche, motos,
   tarjetas…; el botón grande pone «Atacar» (puñetazos), no «Disparar». Puede que parte de «disparar
   malísima» sea que esperaba disparar sin arma. Idea: durante la invasión, si no llevas arma, un
   aviso «Coge un arma (Armería o las que sueltan los alienígenas)» o un arma de préstamo.
2. **El dedo de Disparar no gira la cámara** (decisión de la v101 tras quejas de la v98). Con un solo
   pulgar a la derecha no se puede disparar y girar a la vez. Se podría probar como opción en ⚙️.
3. **Los alienígenas de malla se animan solo en el cliente** (Motor6D): el servidor ve la pose de
   reposo. Un tiro a un brazo que se mueve puede fallar en el servidor; lo cubre en parte la cápsula
   del cuerpo con el imán de 1,2°.
4. **Un alienígena pegado a tu lado** (a menos de 1 stud del plano de tu cabeza) puede quedar detrás
   del principio del rayo de la mira (`Weapons.aimStart`) y no ponerse roja la mira.
5. **El imán de la bala del cliente se dispersa en el servidor**: el cliente manda el punto del
   enemigo, pero el servidor le sigue poniendo la dispersión. Ahora casi no se nota (primer tiro
   preciso, reparto al centro, imán del servidor), pero no se ha quitado para no fiarse del cliente.
6. **Corriendo, la mira se dibuja el doble de grande** que la dispersión real (el servidor te pone a
   andar al disparar). Solo es la mira.
7. **Apuntar**: el servidor pone «apuntando» al momento y la cámara tarda 0,17 s; los primeros tiros
   de esa transición pueden ir con algo menos de dispersión de la que ves.
8. Los **números de daño** solo salen con los alienígenas (no con los enemigos de las misiones).
9. `HitCheck.push`: con pasos de justo 0,05 s, a veces sobrescribe la última posición en vez de
   añadir otra (redondeo). En el servidor no pasa nada (los pasos varían), solo en pruebas.

## Pruebas

- `test-weapons`: reparto hacia el centro, primer disparo preciso (no en escopetas ni en el aire),
  tope de moverse, mismos dados en cliente y servidor, números de disparo que valen y que no,
  mantener Disparar en el móvil, mira suave.
- `test-shooter`: un alienígena puesto en el centro de la pantalla con la cámara al hombro: el rayo de
  la cámara lo encuentra y el servidor (de la cabeza a ese punto) le da; hacia donde mira el cuerpo
  habría fallado; tasas de acierto antes y ahora; la ayuda ignora caídos y lejanos; el «acierto»
  enciende aspa, chasquido y número.
- `test-invasion`: `InvasionService.rewindHit` de verdad con **150 ms de ping** contra un alienígena
  que corre: cuenta; sin compensación habría fallado; imposibles que no cuentan (6 studs al lado, con
  pared delante, fuera de alcance, «ping» de 1 s para dar donde estaba hace más de medio segundo); la
  cápsula sale de la caja del modelo.
- `test-combat`: el servidor pone la semilla, usa el número de disparo del cliente (y no uno que salta
  lejos), manda el «acierto» al dar y nada al fallar.
