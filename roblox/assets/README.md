# Biblioteca de assets

Cada archivo `.rbxm` de esta carpeta entra en el juego como una carpeta dentro de
`ServerStorage.AssetLibrary` (lo hace Rojo al generar el archivo del juego).

La ciudad usa estos modelos automáticamente cuando encuentra uno adecuado
(árboles, farolas, bancos, coches…). Si no hay, usa su versión hecha por código.
Qué nombre corresponde a qué elemento se define en
`src/server/World/Kit/AssetLibrary.luau`.

## Packs previstos (gratuitos y oficiales)
- `SyntyCity.rbxm`   — Synty City Pack (Creator Store, gratuito)
- `SyntyNature.rbxm` — Synty Nature Pack (Creator Store, gratuito)

## Reglas
- Solo assets gratuitos con uso permitido en experiencias de Roblox.
- Los scripts que traigan se eliminan automáticamente al colocarlos.
- Un único estilo visual: no mezclar packs de estilos distintos sin revisarlo antes.
