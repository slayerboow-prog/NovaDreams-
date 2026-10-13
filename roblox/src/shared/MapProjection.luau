-- MapProjection: GENERADO por scripts/map/blender_render.py (no editar a mano).
-- La cámara con la que se hizo la imagen de la isla (textures/mapa/isla_*): ortográfica, inclinada Tilt
-- grados mirando al norte. Del mundo (X, Y, Z) al píxel de la imagen: shared/MapScreen.toArt (exacto).
return {
	Tilt = 40.0, -- grados desde la vertical
	OrthoWidth = 13000.0, -- studs que caben a lo ancho de la imagen
	CX = 50.0, -- X del mundo en el centro de la imagen
	CS = 200.0, -- «arriba» de la pantalla (-Z·cos + Y·sen) en el centro de la imagen
	Width = 4096,
	Height = 2556,
	Cols = 4,
	Rows = 3,
	Sea = { 0, 81, 162 }, -- color del mar en el borde (fondo de la pantalla)
	IslandBox = { X0 = 565, Y0 = 302, X1 = 3518, Y1 = 2228 }, -- la isla en la imagen
}
