# Estándares de arte

Reglas visuales y técnicas que debe cumplir **todo** lo que se ve en el juego: lo que genero por código, los modelos que importemos de la Tienda de creadores y las mallas 3D que añadamos más adelante.
Así el mundo se ve coherente y va bien en móvil.

---

## 1. Dirección de arte

**Estilo:** *realista estilizado*. Limpio, luminoso y con detalle creíble, pero no fotorrealista (tiene que rendir en móvil). Referencias de nivel: Berry Avenue, Bloxburg y Brookhaven en sus versiones más recientes.

**Identidad propia: una región mediterránea.** La mayoría de simuladores de vida de Roblox copian los suburbios de Estados Unidos. Nuestra región tiene ciudad moderna, barrios con balcones, costa con paseo marítimo y pueblo con plaza. Es reconocible y nos diferencia.

| Distrito | Paleta y materiales | Referencias |
|---|---|---|
| Centro | Cristal, piedra clara, acero. Neón y escaparates de noche | Gran Vía de Madrid, Paseo de Gracia de Barcelona |
| Distrito Empresarial | Torres de cristal, orden, plazas duras | Distrito financiero moderno |
| Los Pinos (residencial) | Ladrillo claro, tejados de teja, jardines | Barrio residencial europeo con casas unifamiliares |
| San Roque (económico) | Colores cálidos, fachadas gastadas, balcones con ropa tendida | Barrio popular mediterráneo |
| Colinas del Mirador (lujo) | Blanco, madera, piedra, piscinas, vistas | Villas modernas de la costa |
| Universitario | Ladrillo rojo, zonas verdes, arquitectura académica | Campus europeo |
| Polígono / Puerto | Naves de chapa, hormigón, grúas, contenedores | Polígono industrial |
| Playa Dorada | Blanco y azul, madera clara, toldos | Paseo marítimo mediterráneo |
| Valle Verde / Villaverde | Piedra, teja, campos, granjas | Pueblo rural de interior |

---

## 2. Requisitos técnicos (obligatorios)

### Escala y medidas
| Elemento | Medida |
|---|---|
| Personaje adulto | ~5 studs de alto |
| Altura por planta | 14 studs (suelo a suelo) |
| Puertas | 5 × 8 studs (dobles: 8 × 8) |
| Pasillos interiores | mínimo 6 studs de ancho |
| Escaleras | peldaños de 1 stud de alto, ancho ≥ 6 studs |
| Aceras | 8 studs, bordillo de 0,4 studs |

### Huellas y parcelas
Cada edificio debe caber **exactamente** en su parcela estándar (ver `docs/diseno/02-mapa.md`):

| Parcela | Tamaño (studs) |
|---|---|
| P-S / P-M / P-L / P-XL | 48×48 / 64×80 / 96×112 / 144×160 |
| C-S / C-M / C-L (comercial) | 48×64 / 80×96 / 128×160 |
| P-FARM | 256×256 |

- **Pivote (Pivot)** del modelo: en el centro de la parcela, a nivel del suelo (Y = 0), con la **fachada principal mirando a -Z** (el "LookVector" del pivote apunta hacia la calle).
- Nada sobresale de la huella, salvo toldos o balcones ≤ 2 studs sobre la acera.

### Rendimiento (el juego debe ir bien en móvil)
| Tipo de modelo | Límite orientativo |
|---|---|
| Casa P-S / P-M (con interior) | ≤ 400 instancias, ≤ 20k triángulos |
| Chalet / mansión | ≤ 900 instancias, ≤ 45k triángulos |
| Edificio singular (hospital, estación…) | ≤ 1.500 instancias, ≤ 70k triángulos |
| Prop (farola, banco, papelera) | ≤ 10 instancias, ≤ 1.500 triángulos |

- **MeshParts reutilizables** mejor que cientos de Parts. La misma ventana o farola debe ser la **misma malla** en todo el mapa.
- Texturas de **1024 px máximo** (512 si es posible). Preferir `MaterialVariant` compartidos.
- Decoración con `CanCollide`, `CanTouch` y `CanQuery` = false. `CollisionFidelity` = Box o Hull salvo que se pueda caminar encima.
- Pocas luces: como máximo 1 `PointLight` o `SpotLight` por estancia y **sin sombras** salvo en espacios grandes.
- Todo **anclado** (Anchored).

### Prohibido
- ❌ **Ningún script** dentro de los modelos (ni Script, ni LocalScript, ni ModuleScript).
- ❌ Modelos gratuitos de terceros sin permiso de uso comercial.
- ❌ Uniones, soldaduras o piezas sueltas que no sean necesarias.

### Puntos de interacción (para que el código funcione)
El código busca estos elementos por **nombre + etiqueta (Tag)**. Cada modelo lleva una Part invisible (Transparency 1, CanCollide false) con el nombre y la etiqueta indicados:

| Etiqueta (Tag) | Dónde | Ejemplo |
|---|---|---|
| `Door` | Cada puerta interactiva, en la hoja de la puerta | Entrada de la casa |
| `Seat` | Cada asiento (o usar `Seat` de Roblox) | Sillas, sofás, bancos |
| `Bed` | Colchón de cada cama | Dormitorios |
| `Counter` | Mostradores de venta/atención | Caja del súper, barra del bar |
| `WorkStation` + atributo `Kind` | Puestos de trabajo | Cafetera, camilla, ordenador, elevador de taller |
| `Spawn_NPC` | Donde se colocan empleados NPC | Detrás del mostrador |
| `Parking` | Plazas de aparcamiento | Garaje, parking |
| `Light_Interior` | Luces que se encienden y apagan | Lámparas |

---

## 3. Cómo conseguimos el arte (sin contratar)

| Vía | Qué aporta | Límites |
|---|---|---|
| **Generado por código** (principal) | Calles, aceras, fachadas modulares, casas, interiores, terreno, vegetación e iluminación, todo coherente y ampliable a todo el mapa | Estilo de piezas geométricas cuidadas. No llega a mallas orgánicas muy detalladas |
| **Mallas 3D generadas por mí** (más adelante) | Archivos `.obj`/`.fbx` sencillos (farolas, mobiliario, carrocerías) que tú importas en Studio con **Importar** una sola vez | Requiere un paso manual tuyo por cada lote |
| **Tienda de creadores** (opcional, puntual) | Detalles concretos (plantas, objetos) cuando convenga | Hay que revisarlos (ver abajo) |

### Orden de producción por código
1. **Kit de calle:** carreteras con bordillo, pasos de cebra, rotondas, farolas, semáforos, señales, bancos, marquesinas, árboles, setos y parterres.
2. **Terreno:** hierba con relieve, colinas, playa, mar y montes lejanos (Terrain de Roblox).
3. **Generador de fachadas por distrito:** plantas, ventanas con marco y cristal, balcones, cornisas, tejados de teja o planos y toldos.
4. **Generador de viviendas por tamaño de parcela**, con interiores amueblados.
5. **Edificios singulares:** hospital, colegio, estación, ayuntamiento, comisaría, bomberos, súper…
6. **Muebles y props** del catálogo (incluida la línea NovaDreams).
7. **Vehículos.**

### Reglas para modelos de la Tienda de creadores
- ❌ Borrar **cualquier script** que traigan: los modelos gratuitos a veces esconden scripts maliciosos o "virus".
- ✅ Revisar que cumplen la sección 2 (escala, rendimiento, anclado).
- ✅ Preferir modelos de creadores verificados o de la propia Roblox.
