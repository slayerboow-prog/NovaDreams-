# Heroes of History — Historia principal (≈15 h)

Encargo del dueño (18-11-2026): «15 h de historia principal. El objetivo es convertirse en guerrero espacial y, una vez
lo seamos, salvar el universo de los monstruos y devolver la paz a cada planeta. Muy entretenida: suspense, acción,
tragedias, risas, alegrías. Para +17: público adulto (25-40 años) con capacidad de gasto.»

## Tono
- Drama de ciencia ficción adulto. Pérdidas reales, decisiones grises, consecuencias. Sin gore (normas de Roblox).
- Humor seco y de personaje (Cosme, la IA de la nave), nunca de chiste infantil.
- Cada misión se JUEGA (objetos, decisiones, combates, minijuegos, huidas, terreno hostil) y termina en gancho.
- Decisiones que se recuerdan (Flags/Choices) y cambian escenas posteriores.

## Estructura y duración
| Acto | Capítulo | Misiones | Duración |
|---|---|---|---|
| I · Valmar | Academia de Guerreros | 5 | 50–75 min |
| | Guerrero espacial | 5 | 35–55 min |
| | La Reconquista | 5 | 85–115 min |
| | La Grieta: Proyecto Umbral | 6 | 90–125 min |
| II · La Coalición | La Marea Gris (Valmar) | 2 | 35–45 min |
| | Tefra · la guerra | 3 | 60–75 min |
| | Miasma · la niebla | 3 | 60–75 min |
| | Siroco · la sed | 3 | 60–75 min |
| | Nivalis · la oscuridad | 3 | 60–75 min |
| | Umbría · la raíz | 3 | 60–75 min |
| | Tálasa · el mar | 3 | 60–75 min |
| | Vértice · el Consorcio | 3 | 60–75 min |
| III · El Universo | La última noche | 3 | 60–80 min |
| | **Total** | **52** | **≈14–18 h** |

Los episodios de planeta que ya existían (Tefra, Miasma, Siroco…) quedan como contenido secundario de cada planeta.

## La amenaza
- **La Marea Gris**: algo que consume mundos despacio, convirtiendo la vida en ceniza. No piensa como nosotros. Avanza
  hacia la luz de las grietas.
- **El Consorcio Umbral** abrió grietas en siete mundos para sacar energía del «otro lado». Cada grieta es una puerta
  para la Marea. Sus bestias son refugiados que huyen de ella. En Vértice, el Consorcio se llama MegaVerso.
- **Los Hijos de la Ceniza**: humanos que creen que rendirse a la Marea es la única salvación. Su profeta: **Varn**,
  que escapó del Consejo de Valmar (vuelve como villano de rostro humano).

## Reparto principal
- **Kael** — comandante. Mentora. Muere en el Acto III cubriendo la retirada (tragedia central).
- **Sorel** — tu compañera desde el primer día. Corazón del grupo.
- **Brenn** — el que perdió a su hermano. Arco de redención: del odio a líder.
- **Ilse Maren** — la ingeniera que abrió la Grieta. Culpa y genio.
- **Halden** — solo si la rescataste (GrietaHalden): sabe cómo se comunica la Marea.
- **Cosme** — anciano tefrano que cruzó una grieta de niño hace 38 años. Navegante. Humor negro. Vuelve a su mundo.
- **ILEN** — la IA de tu nave, entrenada con las grabaciones de la segunda de Kael, muerta en Tefra. Sarcástica, leal,
  a veces dice cosas que Ilen diría y Kael no soporta oírlas.
- **Varn** — el consejero que dejó morir el Sur. Ahora predica la rendición.

## Acto II · La Coalición (resumen)
1. **La Marea Gris** (Valmar): consecuencias de la decisión del Umbral; llega la primera señal de la Marea; conoces a
   Cosme y a ILEN; Kael funda la Coalición: hay que cerrar las siete grietas del Consorcio.
2. **Tefra** — guerra entre el Dominio y la resistencia por la forja que alimenta la grieta. Dalia Renn. Cosme vuelve a
   casa y no queda casa. Liberación: cerrar la grieta de la Lanza.
3. **Miasma** — ciudades colgadas sobre niebla tóxica; el Anclaje Seis vive debajo. Mara Solis. Liberación: bajar a la
   niebla y cerrar la grieta del fondo.
4. **Siroco** — desierto, deudas de agua, un pozo que es una grieta. Liberación: la tormenta de fuego y el pozo.
5. **Nivalis** — noche eterna, faroles que mantienen fuera a lo que vive en la oscuridad. Liberación: encender el sol
   artificial apagado por el Consorcio.
6. **Umbría** — bosque podrido desde la raíz por la grieta. Liberación: el corazón del árbol madre.
7. **Tálasa** — océano; la grieta está en una fosa. Liberación: la estación del fondo.
8. **Vértice** — la sede del Consorcio. Varn y los Hijos de la Ceniza. La verdad: el Consorcio quiere abrirle paso a la
   Marea a cambio de sobrevivir. Liberación: tomar la torre MegaVerso.

## Acto III · La última noche
- La Marea llega a la Grieta de Valmar. La flota de la Coalición. Kael muere. Brenn toma el mando. La decisión final
  (cerrar todas las grietas a la vez con el generador del Umbral, con un coste), y el epílogo: la paz vuelve a cada
  planeta y el universo se recupera.

## Reglas técnicas
- Cada planeta empieza con `Event PlanetLanded Match { Planet = … }` (hay que volar allí) y luego usa los sitios
  «<Planeta>_…» (shared/Cosmos/<Planeta>City.StorySpots).
- Validar siempre: `lune run scripts/validar-misiones.luau`.
