# Validación en el móvil: lista para Sebastián

Las fases 1–8 del cine están **probadas técnicamente** (pruebas automáticas con Lune, fuera de Roblox), pero
**nada se ha visto todavía en una pantalla de verdad**. Esta lista es para que lo mires tú en el móvil, con
la versión publicada, y me digas qué está bien y qué no. Mientras no lleguen tus capturas, en
`docs/cine/auditoria-sistema.md` todo sigue como **«Probado visualmente: pendiente»**.

Tiempo: unos **25 minutos** (más 10 si pruebas con un amigo).

## Antes de empezar

1. Abre el juego en el móvil con tu cuenta (eres el dueño: tienes el **modo pruebas**).
2. Escribe **`/pruebas`** en el chat (o el botón del modo pruebas del menú). Se abre el panel.
3. Baja hasta **🎬 CINE (ESCENAS PARA PROBAR)**. Cada botón lanza la escena **de verdad** y solo para ti
   (se cierra el panel y empieza). **⏭ Saltar la escena** la corta. **📊 Ver fallos de escena** dice cuántos
   fallos de escena han llegado al servidor.
4. Pon el móvil **en horizontal** y con el **volumen alto** (hay voces y silencios que mirar).
5. Para una captura: botones de bloqueo + volumen. Apunta el número de la prueba.

> Ojo: las escenas tienen sus consecuencias normales. «El meteorito» deja los cráteres y la valla rota en
> tu partida, como si lo jugaras. No pasa nada malo, pero tenlo en cuenta.

## Las pruebas

### 1. El meteorito y el silencio — botón **☄️ El meteorito**
Mira:
- Antes de que caiga nada: el medidor de Cosme pita cada vez más deprisa, tiembla un poco y **se callan los
  pájaros**.
- El cielo se pone verde; la cámara sigue a la primera estrella.
- **Tres impactos**, cada uno en su plano corto (parque, patio del cole, camino): luz, polvo, onda, humo,
  cascotes y temblor.
- Después del tercero: **unos 4 segundos de silencio** (sin música, sin ambiente, sin frases), solo el humo.
- Chispa sale del cráter y rompe el silencio («¡Bip!»); un vecino vuelve a ver si estáis bien.
- Al final: el rótulo «Han caído tres cosas del cielo».
- Al acabar: vuelven tu cámara, los controles y los botones.

### 2. Lo que se queda en el mundo — después de la prueba 1
- Ve andando al **patio del colegio**: la **valla de madera partida**, la mancha quemada y los cascotes.
- Los tres **cráteres humeantes** (parque, patio, camino al cole).
- Que la valla rota **no tape el camino** ni se meta en los columpios.
- (Los otros dos estados —«en obras» con vallas amarillas y «arreglado» con una placa— salen cuando se
  completan `Saga_02_Grieta` y `Saga_04_Ventanilla`; no hay botón para verlos ya.)

### 3. Gestos, cara y boca — botón **👶 El nacimiento** y **☕ Despedida con Abu**
- Los personajes **no se quedan quietos** al hablar: cabeza, manos, se inclinan, miran a quien habla.
- Abu en la despedida: se inclina y **pregunta con la cabeza**.
- Si la cara del personaje es de las que se mueven (caras dinámicas de Roblox), **la boca se abre y se
  cierra** mientras habla. **No es sincronización labial** (no sigue las sílabas): solo que no esté
  rígida. Si la cara es clásica, no se mueve la boca (es normal).
- Que ningún gesto se vea raro (brazos que atraviesan el cuerpo, alguien que se queda torcido al acabar).

### 4. La caja de diálogo — botón **💬 Conversación de prueba**
- A la izquierda, **el retrato** de quien habla (la cara de Cosme o Pip, o una insignia con su inicial).
- El texto sale **letra a letra** con un «tic» suave. **Un toque**: la frase sale entera. **Otro toque**: la
  siguiente. Un doble toque rápido **no se come** una frase.
- La frase muy larga **no se sale del recuadro** (crece hacia arriba).
- Hay un silencio («…») y al final **una pregunta**: la conversación **espera** a que elijas (no elige
  sola). Los botones de respuesta se pulsan bien con el dedo.
- Cambia la velocidad en **ValPhone → Ajustes → Juego → 💬 Velocidad del texto** (Lento / Normal / Rápido /
  Instantáneo) y repite: se nota en la frase siguiente.

### 5. Cámara y encuadre — botones **📸 La foto de grupo**, **🌅 El atardecer con Abu**, **🏫 Fin del colegio**, **🎓 Cabecera de la universidad**
- La cámara **nunca dentro de una pared**, de un árbol o de alguien.
- Quien habla **sale en el plano** (no cortado en el borde, no tapado).
- Ningún personaje metido dentro de otro o de un banco.
- Movimientos **suaves**, sin saltos bruscos; en «Fin del colegio» el primer plano del grupo **dura hasta
  el grito** (antes se quedaba quieto casi 2 s).
- En «El atardecer», el **primer plano de Abu** (antes podía cortarte a ti en el borde).
- En la cabecera de la universidad, la **rectora** habla con su nombre («Rectora Amaia Soler»).
- Rótulo grande y subtítulo **nunca a la vez**, y el subtítulo se lee entero en el móvil.

### 6. Saltar y volver — cualquier botón y **⏭ Saltar**
- Empieza una escena y pulsa **Saltar** (arriba a la derecha) a mitad: se corta enseguida y **todo vuelve**
  (cámara detrás de ti, controles, botones, música normal).
- Empieza otra y **ciérrate el juego** o **muere** a mitad (si es fácil): al volver, nada se queda raro.
- Pulsa **📊 Ver fallos de escena**: debería decir **0** o muy pocos. Si hay alguno, haz captura.

### 7. Con un amigo (multijugador)
Necesitas a otra persona en el mismo servidor, **a tu lado**.
- **A) Escena del mundo**: tú lanzas **☄️ El meteorito**; tu amigo, cerca (en el parque o junto al
  garaje), **sin tocar nada**. Él debe **ver caer los meteoritos y el cielo verde** pero **seguir
  moviéndose con su cámara** (no se le bloquea nada). Si va en coche, sigue conduciendo.
- **B) Escena personal**: tú lanzas **💬 Conversación de prueba** o **👶 El nacimiento**: tu amigo **no ve
  nada** de tu escena y sigue jugando; en tu pantalla, **tu amigo no sale en los planos** (se esconde).
- **C) Escena de grupo** (la foto, el festival, la graduación): solo pasa si los dos estáis en **el mismo
  paso de la historia** y cerca. Es difícil de preparar a propósito; si os pasa jugando, decídmelo.
- Que **nadie se teletransporte** por la escena del otro.

## Formulario (contesta así)

Copia esto y rellénalo: **OK** si está bien, **MAL** + una captura y una frase si no.

```
1. Meteorito (avisos, impactos, silencio, Chispa):      OK / MAL —
2. Valla rota y cráteres en el mundo:                    OK / MAL —
3. Gestos y boca (nacimiento, despedida con Abu):        OK / MAL —
4. Caja de diálogo (retrato, letra a letra, toques,
   frase larga, pregunta, velocidad):                    OK / MAL —
5. Cámara y encuadre (foto, atardecer, fin del cole,
   universidad):                                         OK / MAL —
6. Saltar y volver / fallos de escena (número: __):      OK / MAL —
7A. Meteorito visto por un amigo sin perder el control:  OK / MAL / no probado —
7B. Escena personal: el amigo no la ve ni sale en plano:  OK / MAL / no probado —
7C. Escena de grupo:                                     OK / MAL / no probado —
Móvil (modelo) y calidad gráfica:
Algo más que te haya parecido raro:
```

Con tus respuestas y capturas, cambio cada fase de «Probado visualmente: pendiente» a lo que hayas visto, y
arreglo lo que salga MAL.

## 🎞️ Cinemateca: ver TODAS las escenas, una por una

Para revisar el juego entero escena por escena (además de la lista de arriba):

1. `/pruebas` → **🎬 CINE** → **🎞️ Cinemateca: todas las escenas, una por una**.
2. Arriba: el **buscador** (id, misión, capítulo… sin tildes ni mayúsculas) y el **contador** («37 / 1211 ·
   revisadas 5»). Abajo, la lista **por grupos** (capítulos, colegio, instituto, universidad, vida adulta,
   montajes, la saga de la Grieta, Tefra, misiones locas, secundarias…): todas las escenas del motor (también
   las 21 de capítulo y las ligeras, sin cámara) y todas las conversaciones de las misiones. Toca una para
   elegirla.
3. Mandos: **⏮ Anterior · ▶ Ver · ⏭ Siguiente · ↺ Repetir**.
4. Al acabar cada una (o al saltarla con «Saltar»), sale la barra: **✅ Bien / ❌ Mal** y una **nota corta**
   opcional. Se guarda con la escena, el plano en que iba, el segundo, si la saltaste, tu móvil (tamaño de
   pantalla) y la hora. Las revisadas salen con ✅ / ❌ en la lista.
5. **📋 Ver revisiones** las enseña en la ventana y las escribe en el registro del servidor.

Es **seguro**: cada escena se ve en **modo sandbox**: no cambia tu historia, ni marcas, ni dinero, ni la
mochila, ni la memoria del mundo (el meteorito no deja cráteres), nadie más la ve y nadie se une. Te lleva a
su sitio y al acabar (o al cortarla) te devuelve donde estabas, con la cámara, los controles y los botones
como antes. Si su sitio no existe todavía (Tefra sin construir), se pone donde estás.

Lo que aún no hace: las conversaciones se ven con la caja y los personajes que haya cerca (no se crean
suplentes de pie para ellas); la invasión no está (no es una escena). Las revisiones viven en la memoria
del servidor (se pierden al cerrarlo): quedan en el registro como `[CINEMATECA] {…}` y `/cinemateca` en el
chat las vuelve a escribir todas.
