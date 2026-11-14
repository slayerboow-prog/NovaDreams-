# Revisión de coherencia de la historia (14 de noviembre de 2026)

Revisión de toda la historia de Valmar mirada como guionista de videojuegos: ¿encaja todo? ¿Tiene sentido?
¿Hay errores? ¿Está entrelazada (lo que haces vuelve más tarde)?

Herramientas usadas (todas sin arrancar el juego):

- `scripts/validate-report.luau`: datos de las misiones.
- `scripts/audit/narrativa.luau`: continuidad, puesta en escena y voces.
- `scripts/audit/cine-revision.luau`: ritmo de las escenas.
- `scripts/test-reescritura.luau`: guiones.

También se leyeron los guiones del principio y del final de cada saga.

## Cómo está construida la historia (y por qué funciona)

| Tramo | Qué cuenta | Lo que lo une al resto |
|---|---|---|
| **Prólogo** (el sueño) | Cosme, la Grieta y el tornillo | Presenta a Cosme y la Grieta, que son el hilo de la Saga 1. Ahora también pregunta chico o chica, y todo el juego habla bien al jugador. |
| **Bebé → Colegio (Cole01–12)** | El grupo de amigos (Omar, Nico, Sara, Hugo, Leire, Bruno), Lucía, el gato, el festival, el proyecto | Las decisiones del colegio vuelven de adulto, en el reencuentro (Adu03). |
| **Instituto, Universidad, Adulto joven** | Clubes, primer empleo, el rumor, la gran decisión, el piso, la graduación | La carrera y el sueño de niño vuelven con Lucía (Adu03). |
| **Saga 1 «La Grieta» (Saga_01–24)** | Cosme y Cósimo, Pip, MegaVerso, el Ancla, la Gran Fusión | Termina con «Cosiste el cielo para siempre» y una lucecita en el cielo. |
| **Saga 2 «Ragnarock»** | El prólogo del espacio (Varkun, «La costura negra») y 7 planetas | El hilo negro y el «quien sabe coser, sabe descoser» siguen el tema de la Saga 1. Ahora Cosme se acuerda de aquella lucecita. |

La columna vertebral es sólida. Cosme recorre todo el juego, el tema de **coser y descoser** une las dos sagas
y los amigos del colegio vuelven de adultos.

## Lo que se ha arreglado en esta revisión

1. **Decisiones que nadie recordaba.** Había 12 decisiones del jugador sin ninguna consecuencia. Ahora 6 tienen eco:
   - **El gato del colegio (Cole03):** de adulto, Omar te cuenta qué fue del gato. Hay una versión si lo buscaste y otra si no.
   - **Nina, la niña perdida del festival (Cole10):** Lucía, ya directora, te cuenta que Nina es monitora de campamento, por lo que hiciste tú.
   - **Tu papel en el proyecto (Cole11):** si fuiste jefe o jefa, Omar guarda tu chapa de cartón; si lo presentaste, te toca el discurso de la inauguración.
   - **Las góndolas de Miasma, la doctora Ferrán de Tálasa y la etiqueta de Vértice:** vuelven en las misiones nuevas de peligros de cada planeta.
2. **Hablar al jugador con el género correcto.** Frases fijas en masculino dirigidas al jugador:
   - «forastero» (Miasma ×3, Tefra ×3), «Bienvenido a existir» (Tefra), «¿Contento?» (Cole04), «el de la nave» (Siroco ×2, Nivalis, Miasma) y «Bienvenido, forastero» (Miasma).
   - Ahora cambian según lo que eliges en el sueño.
3. **El paso de la Saga 1 a la Saga 2.** La Saga 1 termina con una lucecita en el cielo, a propósito y sin explicarla. La Saga 2 empezaba sin acordarse de ella. Ahora Cosme la recuerda al ver el hilo negro: «Pensé que era una estrella. Ya no lo pienso.»
4. **Ritmo de las escenas de los planetas.**
   - Pausa después de los golpes en Nivalis, Siroco y Umbría.
   - La frase ya no sale encima del título en la llegada a Umbría.
5. **Cada planeta, su problema propio.** 12 peligros nuevos del terreno, cada uno con su misión y su escena:
   - **Siroco:** arenas movedizas y ráfagas.
   - **Tálasa:** coral negro y rayos.
   - **Nivalis:** hielo fino y ventisca.
   - **Umbría:** ciénaga y ramas que caen.
   - **Miasma:** rayos, lodo ácido y viento.
   - **Vértice:** charcos con corriente y paneles de la Cúpula.

## Lo que queda (por orden de importancia)

1. **Frases repetidas entre etapas.** El comedor de niño (Nino_Jornada) y el de adolescente (Adol_Jornada) comparten 43 frases iguales. Quien juega las dos etapas las oye dos veces. La de adolescente necesita frases propias.
2. **Decisiones que todavía no vuelven.**
   - Hay 6 sin eco: Despido (Adu_Profesion), Discusión (Cole11), Organización (Uni02), Asiento del bus (Cole07), el juicio y Sargo (el mar).
   - Las del mar y las de los planetas tendrán su eco natural en los siguientes episodios.
3. **Apuestas en Siroco.** Hay apuestas de la Tía Cifra y «diez a uno» en las carreras. El principio 5 del juego dice «ni apuestas». Son con dinero del juego y forman parte del mundo, pero conviene decidir si se quedan o se cambian por «retos».
4. **Orden de la Saga 2.** Los planetas solo piden haber terminado la Saga 1, no el prólogo del espacio. Se puede llegar a Tefra sin haber visto «La costura negra». No rompe nada, pero el gancho llega más tarde.
5. **Puesta en escena.**
   - En 21 conversaciones habla alguien que no está en la escena; su frase sale solo en la caja.
   - Hay 15 saltos de sitio sin fundido.
   - Hay 61 acotaciones escritas en el texto.
6. **Marcas y recuerdos que nadie lee.** 106 marcas y 86 recuerdos se guardan y ningún dato los usa después. Muchos son a propósito: los recuerdos salen en la biografía. Pero las marcas son material para nuevos ecos, como los de este informe.
7. **Episodios de los planetas a medias.**
   - Cada planeta tiene sus 5 primeras misiones principales, de las 7 del diseño.
   - Tefra tiene 3 de sus 7 cadenas secundarias; los demás planetas, ninguna (aparte de la de peligros).
