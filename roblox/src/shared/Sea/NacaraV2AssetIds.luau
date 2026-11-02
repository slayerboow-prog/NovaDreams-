-- NacaraV2AssetIds: GENERADO por scripts/upload-nacara-v2.sh (no editar a mano).
-- Los ids de las texturas y los ornamentos de Nácara v2 (assets/nacara-v2):
--   Mallas    "<Ornamento>" -> Model de cada FBX (una MeshPart dentro); Ornamento = shared/Sea/NacaraV2.Ornaments
--   Texturas  "<textura>_<mapa>" -> imagen (color, normal, roughness, metalness) y "ornamentos_<mapa>" (el atlas)
-- Vacío hasta que se suban: mientras tanto Nácara v2 usa los colores lisos y las piezas de respaldo.
return {
	Mallas = {},
	Texturas = {},
} :: { Mallas: { [string]: string }, Texturas: { [string]: string } }
