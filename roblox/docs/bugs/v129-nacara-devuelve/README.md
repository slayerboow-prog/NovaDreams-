# Bug (dueño, v129): al acercarse a este barrio oscuro bajo el mar le devuelve a Nácara

Captura: captura.png (Llanura Sumergida, 35 m, Hondario con branquias). Cada vez que se acerca a las casas oscuras con ventanas amarillas, aparece otra vez en la ciudad del mar.

Pista: HondarioService.goHome se llama tras morir (watch → Died). Comprobar si algo le mata o le saca al acercarse (zona prohibida, presión, colisión, CityBounds/rescate, teletransporte de distrito de Nácara, StreamingEnabled), y por qué el barrio se ve negro (sin texturas/luz). Pendiente para el lunes.
