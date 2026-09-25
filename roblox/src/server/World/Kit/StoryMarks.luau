-- StoryMarks: marcas invisibles que el mapa deja para las misiones de la historia.
-- Tres etiquetas genéricas (ver docs/mapa/ETIQUETAS.md), así una misión nueva no necesita código de mapa:
--   StoryProp (+PropId)  -> objeto con el que se interactúa (cama, armario, taquilla, canasta…)
--   StoryArea (+AreaId)  -> volumen de una zona (pasillo, biblioteca, comedor, gimnasio, almacén…)
--   StorySpot (+SpotId)  -> punto donde la historia pone un NPC o un evento (grupos del recreo, pistas…)
-- Todas llevan además el contexto que las ubica: HomeId (casa familiar) o School (nombre del pueblo).

local Builder = require(script.Parent.Parent.Builder)

local StoryMarks = {}

local function mark(tag: string, key: string, id: string, parent: Instance, cf: CFrame, size: Vector3, attrs: { [string]: any }?)
	local attributes = { [key] = id }
	for k, v in attrs or {} do
		attributes[k] = v
	end
	return Builder.part({
		Name = tag .. "_" .. id,
		Size = size,
		CFrame = cf,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Tags = { tag },
		Attributes = attributes,
		Parent = parent,
	})
end

-- Objeto interactivo: la pieza invisible envuelve al objeto visible (el aviso de proximidad va aquí)
function StoryMarks.prop(parent: Instance, id: string, cf: CFrame, size: Vector3, attrs: { [string]: any }?): BasePart
	return mark("StoryProp", "PropId", id, parent, cf, size, attrs)
end

-- Zona: hay que estar DENTRO del volumen
function StoryMarks.area(parent: Instance, id: string, cf: CFrame, size: Vector3, attrs: { [string]: any }?): BasePart
	return mark("StoryArea", "AreaId", id, parent, cf, size, attrs)
end

-- Punto de aparición (a la altura de los pies + 2.5; LookVector = hacia dónde mira el NPC)
function StoryMarks.spot(parent: Instance, id: string, cf: CFrame, attrs: { [string]: any }?): BasePart
	return mark("StorySpot", "SpotId", id, parent, cf, Vector3.new(2, 5, 2), attrs)
end

return StoryMarks
