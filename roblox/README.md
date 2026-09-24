# Real Life Simulator — simulador de vida para Roblox

Juego de vida real: trabaja, gana dinero, come, duerme, compra y mejora tu casa.
Todo el juego (mapa, sistemas e interfaz) está hecho con código, así que no hace
falta construir nada a mano en Roblox Studio.

## Qué hay ya en el juego (versión 0.1)

| Sistema | Qué hace |
|---|---|
| 🏙️ Ciudad (Valmar) | Estilo mediterráneo: edificios de varias plantas con balcones, contraventanas, escaparates y toldos; avenida con semáforos, pasos de cebra, farolas y paradas de bus; plaza con fuente y palmeras; coches aparcados; terreno real con colinas; 16 parcelas con casas de muestra |
| 💼 Trabajos | Barista, Reponedor, Basurero y Repartidor. Coges algo, lo llevas al punto marcado con una línea azul y cobras |
| 🍔 Necesidades | Hambre y energía bajan con el tiempo. Si están bajas caminas más lento y no puedes trabajar |
| 🏠 Casas | Reclamas una parcela gratis. Mejoras de Estudio → Casa familiar → Chalet → Mansión. Cama para dormir y nevera gratis |
| 🌗 Día y noche | Un día dura 20 minutos. De noche se encienden las farolas y las ventanas de los edificios. Iluminación "Future" con atmósfera, brillo y color |
| 💾 Guardado | Dinero, nivel de casa, hambre, energía y estadísticas. Con protección contra duplicar dinero entre servidores |
| 💰 Monetización | Tienda con Game Passes (VIP = doble sueldo, Metabolismo Pro) y paquetes de dinero con Robux |
| 📱 Interfaz | Dinero, reloj, barras de necesidades, panel del trabajo, avisos y tienda. Se adapta a móvil y PC |

---

## Guía para empezar (desde cero)

### 1. Instala Roblox Studio
1. Entra en https://create.roblox.com y pulsa **Start Creating** (o busca "Roblox Studio").
2. Descárgalo, instálalo e inicia sesión con tu cuenta de Roblox.

### 2. Abre el juego
1. En esta carpeta de GitHub descarga **`RealLifeSimulator.rbxlx`**: pulsa sobre el archivo y luego en el botón de descarga (⬇).
2. Haz doble clic en el archivo descargado. Se abre en Roblox Studio y ya verás la ciudad.
   También puedes abrir Studio y usar **File → Open from File**.

### 3. Pruébalo
1. Pulsa **Play** (arriba, el botón ▶). Aparecerás en la plaza.
2. Pruébalo todo:
   - Ve a un cartel azul de **SE BUSCA** y mantén **E** pulsada para trabajar.
   - Sigue la línea azul, recoge y entrega. Mira cómo sube tu dinero.
   - Ve a la zona de casas (al sur, cruzando la avenida). Busca un cartel **SE VENDE** y reclama tu casa.
   - Duerme en la cama y come en la cafetería o en la hamburguesería.
3. Pulsa **Stop** (■) para salir de la prueba.

> Consejo: en **View** activa la ventana **Output**. Ahí salen los mensajes del
> juego ("Servidor listo ✅") y los errores si algo falla.

### 4. Activa el guardado (cuando quieras probarlo)
El guardado solo funciona en un juego **publicado**:
1. **File → Publish to Roblox**. Ponle nombre (por ejemplo *Real Life Simulator*).
2. **Home → Game Settings → Security → Enable Studio Access to API Services** → ON.

Hasta que lo hagas, el juego funciona igual pero no guarda nada (te avisa en Output).

### 5. Activa la monetización (Robux)
1. Ve a https://create.roblox.com → tu experiencia → **Monetization**.
2. Crea los **Passes** (VIP, Metabolismo Pro) y los **Developer Products**
   (los 3 paquetes de dinero). Ponles imagen y precio.
3. Copia el **ID** de cada uno en `src/shared/Config.luau`, en la sección `MONETIZACIÓN`.
   Me los puedes pasar y lo hago yo.
4. Mientras el ID sea `0`, el artículo sale en la tienda como "Próximamente".


### 6. Packs gratuitos de Synty (mejora visual)
Al pulsar **Play**, el juego descarga solo los packs gratuitos y oficiales de Synty (City y Nature)
y reconstruye la ciudad con ellos. En **Output** verás una línea `[Assets] Packs disponibles: 2/2 …`.

Si pone `0/2`, la descarga automática no funcionó y hay que importarlos a mano (solo una vez):
1. Abre `RealLifeSimulator.rbxlx` en Studio.
2. **Vista → Caja de herramientas**. Busca **Synty City Pack** y comprueba que es el oficial (creado por Roblox / Synty).
   Haz clic para insertarlo.
3. En el **Explorador**, clic derecho sobre el pack insertado → **Guardar en archivo…** → `SyntyCity.rbxm`.
4. Repite con **Synty Nature Pack** → `SyntyNature.rbxm`.
5. Pásame los dos archivos (adjuntos en el chat o subidos a la carpeta `roblox/assets/` del repositorio).
   Yo los catalogo y construyo el distrito con ellos.

---

## Cómo está organizado el código

```
roblox/
├── default.project.json      ← describe cómo se monta el juego (lo usa Rojo)
├── RealLifeSimulator.rbxlx            ← el juego listo para abrir en Studio
└── src/
    ├── shared/               ← lo usan servidor y cliente
    │   ├── Config.luau       ← ⭐ TODOS los números del juego (sueldos, precios, IDs de Robux…)
    │   └── Format.luau
    ├── server/               ← corre en los servidores de Roblox (seguro contra trampas)
    │   ├── Main.server.luau  ← arranca todo
    │   ├── World/            ← construcción de la ciudad
    │   └── Services/         ← Datos, Trabajos, Necesidades, Comida, Casas, Mundo, Monetización
    └── client/               ← corre en el ordenador/móvil de cada jugador
        ├── UI/               ← interfaz (HUD, tienda)
        └── Controllers/      ← marcador del objetivo del trabajo
```

**Regla de oro:** el dinero y todo lo importante lo decide siempre el **servidor**.
El cliente solo dibuja. Así los tramposos no pueden darse dinero.

## Para programadores: trabajar con Rojo

Los scripts viven en esta carpeta y se sincronizan con Studio usando [Rojo](https://rojo.space):

```bash
rojo build default.project.json -o RealLifeSimulator.rbxlx   # genera el archivo del juego
lune run scripts/build-place.luau RealLifeSimulator.rbxlx    # mete la ciudad ya construida dentro (para verla en Studio)
rojo serve                                          # sincroniza en vivo con el plugin de Rojo en Studio
```

> ⚠️ Si editas scripts **dentro de Studio**, esos cambios no llegan a GitHub.
> Lo ideal es pedirme los cambios a mí (o editar los `.luau`) y regenerar `RealLifeSimulator.rbxlx`.

Ver el [documento de diseño](docs/diseno/README.md) y la [hoja de ruta](ROADMAP.md) para lo que viene después.
