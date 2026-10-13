# HUD compacto en el móvil

Queja del dueño (móvil apaisado, ~932x430 pt): «aparece mucha información en pantalla que apenas deja
ver el juego». Después: «No agrupes todos los botones ni los hagas más pequeños si así van a
perjudicar a la hora de jugar» y «vigila el hacer más pequeña la interfaz… No debemos excedernos en
achicar las cosas».

Reglas:

- **El centro de la pantalla, libre**: lo que solo informa se **recoloca** (a los lados y arriba) y se
  recoge, sin quedar diminuto.
- **Los mandos no cambian**: joystick, racimo, ◀ ▶, FRENO / ACELERAR, Luces, claxon (Timbre),
  Bajarse, Interactuar, Acciones y la **barra rápida** tienen el mismo tamaño y el mismo sitio en
  todos los modos (a pie, bici, patinete, coche).
- **Suelos** en el móvil del dueño (escala del HUD 0.548): lo que se toca ≥ 44x44 pt, textos ≥ 14 pt
  (nivel y dinero ≥ 16 pt), barras ≥ 6 pt de grueso. `scripts/test-hud.luau` comprueba los de las
  piezas nuevas.
- Solo en pantallas táctiles sin teclado (`HudLayout.compute(..., { Touch = true })`); el ordenador no
  cambia.

## Antes / después (932x430 pt, montado en el patinete eléctrico)

Medido con `HudLayout.compute` (antes = la versión anterior del archivo). Porcentaje = parte de la
pantalla que tapa cada pieza. Los carteles de la estación de bicis y la tarjeta «¿Qué hago?» son una
estimación sacada de las capturas.

| Pieza | Antes (pt) | Antes | Después (pt) | Después | Qué cambia |
|---|---|---|---|---|---|
| Tu estado | 241x92 | 5,5 % | 214x57 | 3,0 % | foto, nivel y dinero (≥ 16 pt), 4 barras con icono (6,6 pt); el número sale si una barra está baja; tocar = desplegar 6 s |
| Hora, fecha y tiempo | 329x35 | 2,9 % | 241x31 | 1,8 % | una fila: la hora grande (~30 pt), tiempo, grados y «mié 3 ene» |
| Minimapa | 115x128 | 3,7 % | 98x109 | 2,7 % | x0,85 desde la esquina |
| ValPhone al volante | 61x77 | 1,2 % | 44x55 | 0,6 % | icono junto a tu estado (≥ 44 pt) |
| Barra rápida | 394x47 | 4,6 % | 394x47 | 4,6 % | igual: es juego (objetos, vehículos, teléfono) |
| Cuadro de mandos (bici, patinete, monopatín) | 368x89 | 8,2 % | 175x44 | 1,9 % | km/h grandes (~38 pt) y batería; sin P R N D ni esferas |
| Cuadro de mandos (coche) | 368x89 | 8,2 % | 307x75 | 5,7 % | el mismo a x1 (antes x1,2 en el móvil) |
| Consejo del vehículo | 351x82 (centro) | 7,2 % | 296x77 (izquierda) | 5,7 % | a un lado, letra ≥ 14 pt, se va solo a los 5 s, una vez por jugador |
| Carteles de la estación de bicis (est.) | 3 × 168x33 | 4,2 % | 1 × 168x33 | 1,4 % | solo el del botón grande (o el más cercano), a su tamaño |
| **Total en el patinete** | | **37,6 %** | | **21,8 %** | **42 % menos, y el centro libre** |
| «¿Qué hago ahora?» (al tocar ❓, est.) | 508x128 (centro) | 16,2 % | ~370x150 (derecha) | ~13,8 % | arriba a la derecha, bajo el minimapa |

Esquemas (mismos rectángulos, a escala): [antes](hud-movil/before.png) · [después](hud-movil/after.png)

![Antes](hud-movil/before.png)
![Después](hud-movil/after.png)

## Dónde está cada cosa

- `UI/HudLayout.luau`: `HudLayout.Compact` (medidas del móvil) y `Placement.Shrink`: la pieza se dibuja
  a su tamaño de diseño y se encoge con el UIScale «PressScale» (el de `Theme.pressable`, con su
  atributo `Base`), así el minimapa y el ValPhone no se rehacen por dentro. `rect()` ya da el
  rectángulo encogido. Piezas nuevas: `StatusOpen`, `DashCompact`, `GuideNote`, `HelpCard`.
- `UI/Hud.luau`: tu estado plegado (`buildCompactStatus`, botón «Expand»; se despliega solo unos
  segundos si una barra baja de 25 %) y la cápsula de la hora en una fila (`ShortDate`).
- `UI/Phone.luau`: `Phone.bannerShowing()`. En el móvil el aviso del ValPhone va en el hueco de las
  notas (debajo de tu estado) y se turnan: mientras se ve el aviso, la nota espera.
- `Controllers/VehicleHud.luau`: «SpeedChip» para lo que no tiene intermitentes (`VehicleControls`).
- `Controllers/Guide.luau`: tarjeta de los primeros pasos y notas a la izquierda (`Items.Guide` /
  `Items.GuideNote`), letra de 26 en el lienzo (≥ 14 pt), «Saltar» y la × de 80 (≥ 44 pt). En el móvil
  toda la nota es el botón («👆 Toca para ir» al final del texto) y los consejos son la versión corta
  (`Onboarding.TipsTouch`). Los consejos ya se guardaban por jugador (`TipsSeen`, OnboardingService).
- `Controllers/HelpUI.luau`: tarjeta en `Items.HelpCard` (móvil: arriba a la derecha, 480 de ancho).
- `Controllers/Prompts.luau`: en el móvil, un solo cartel (el del foco o el más cercano), a su tamaño.
- Glifos que el móvil pintaba como «▯»: `✕` → `×` y `✓` → `✔` (p. ej. «Toca × para cerrar»).

Pruebas: `lune run scripts/test-hud.luau` (apartado «HUD compacto del móvil», en 932x430) y
`scripts/test-metro.luau`.
