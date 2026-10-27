-- FaceKit: UNA sola cara (y una sola boca) en la cabeza de cada personaje de la historia.
--
-- Por qué existe (bug «Cosme tiene dos bocas», oct 2026): los actores se crean con
-- Players:CreateHumanoidModelFromDescription y una HumanoidDescription vacía. Roblox ya da por defecto
-- una CABEZA DINÁMICA: la cara (ojos, cejas y BOCA) va pintada en la textura de la malla de la cabeza
-- (MeshPart.TextureID o un SurfaceAppearance) y se mueve con FaceControls; ya no hay Decal «face».
-- Encima de esa cabeza, CosmeLook ponía su Decal «face» (o su cara dibujada con marcos): dos caras
-- superpuestas = dos bocas. Y al hablar, ActorLife abría la mandíbula de la cabeza dinámica (JawDrop):
-- la boca de debajo se movía sola, aún más visible.
--
--   FaceKit.cleanHead(head)          deja la cabeza lisa, del color de la piel: quita FaceControls, la
--                                    textura pintada de la malla (TextureID), los SurfaceAppearance y
--                                    cualquier Decal que no sea el único «face». Devuelve cuántas cosas
--                                    ha quitado. Se llama SIEMPRE antes de poner una cara propia.
--   FaceKit.decal(head)              el único Decal «face» (Front) de la cabeza; lo crea si no hay y
--                                    borra los repetidos.
--   FaceKit.set(model, image, talk?) cabeza limpia + Decal «face» con `image`; `talk` = la misma cara con
--                                    la boca abierta (para hablar). Guarda los dos en atributos del modelo
--                                    (FaceImage, FaceTalk) para que el cliente mueva la boca.
--   FaceKit.flap(model, open)        boca abierta o cerrada mientras habla (cambia la imagen del MISMO
--                                    Decal: nunca añade otra boca). Solo en la pantalla de quien lo llama.
--   FaceKit.mouths(model)            (pruebas y diagnóstico) cuántas cosas pintan una boca en la cabeza:
--                                    Decals visibles, cara dibujada (SurfaceGui) visible, cabeza con la
--                                    cara pintada en la malla y FaceControls. Debe ser exactamente 1.
--
-- Estilo bloque (World/EstiloBloqueLoader): la cabeza que se ve es un accesorio (la «cabeza de bloque» o
-- la pantalla de Pip; atributo CaraEn del personaje = su nombre dentro de la carpeta EstiloBloque) y la
-- cara va ahí, en el MISMO único Decal «face»; la Head del R15 queda invisible y sin caras.
--   FaceKit.host(model)              la pieza donde va la cara (esa o la Head)
--   FaceKit.expressBlock(model, e)   pone la cara de la expresión e (atributos CaraBloque_<e>, si no la
--                                    tiene la de CaraBloque_Neutral o la primera); false si no es de bloque

local FaceKit = {}

FaceKit.DECAL = "face"
FaceKit.ATTR_IMAGE = "FaceImage"
FaceKit.ATTR_TALK = "FaceTalk"
FaceKit.ATTR_HOST = "CaraEn"
FaceKit.ATTR_BLOCK = "CaraBloque_"
FaceKit.FOLDER = "EstiloBloque"

local function isDecal(d: Instance): boolean
	return d:IsA("Decal") and not d:IsA("Texture")
end

-- Cabeza lisa: sin la cara de la cabeza dinámica ni caras repetidas
function FaceKit.cleanHead(head: Instance?): number
	if not head or not head:IsA("BasePart") then
		return 0
	end
	local removed = 0
	local keep: Instance? = nil
	for _, child in head:GetChildren() do
		if child:IsA("FaceControls") or child:IsA("SurfaceAppearance") then
			child:Destroy()
			removed += 1
		elseif isDecal(child) then
			if child.Name == FaceKit.DECAL and keep == nil then
				keep = child
			else
				child:Destroy()
				removed += 1
			end
		end
	end
	if head:IsA("MeshPart") then
		local ok, texture = pcall(function()
			return (head :: any).TextureID
		end)
		if ok and type(texture) == "string" and texture ~= "" then
			pcall(function()
				(head :: any).TextureID = ""
			end)
			removed += 1
		end
	end
	head:SetAttribute("FaceClean", true)
	return removed
end

-- El único Decal «face» de la cabeza
function FaceKit.decal(head: BasePart): Decal
	local found: Decal? = nil
	for _, child in head:GetChildren() do
		if isDecal(child) and child.Name == FaceKit.DECAL then
			if found then
				child:Destroy()
			else
				found = child :: Decal
			end
		end
	end
	if found then
		return found
	end
	local d = Instance.new("Decal")
	d.Name = FaceKit.DECAL
	d.Face = Enum.NormalId.Front
	d.Parent = head
	return d
end

-- La pieza que lleva la cara: la cabeza de bloque del estilo bloque o, si no hay, la Head
function FaceKit.host(model: Instance?): BasePart?
	if not model then
		return nil
	end
	local name = model:GetAttribute(FaceKit.ATTR_HOST)
	if type(name) == "string" then
		local folder = model:FindFirstChild(FaceKit.FOLDER)
		local part = folder and folder:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	local head = model:FindFirstChild("Head")
	return if head and head:IsA("BasePart") then head else nil
end

-- Esconde todas las caras de una pieza (la Head del R15 cuando la cara va en la cabeza de bloque)
local function hideFaces(part: Instance)
	for _, child in part:GetChildren() do
		if isDecal(child) then
			(child :: Decal).Transparency = 1
		elseif child:IsA("SurfaceGui") then
			(child :: SurfaceGui).Enabled = false
		elseif child:IsA("FaceControls") then
			child:Destroy()
		end
	end
end

-- La cara de la expresión en el estilo bloque. false si el personaje no es de bloque o no tiene caras.
function FaceKit.expressBlock(model: Model?, expression: string?): boolean
	if not model or type(model:GetAttribute(FaceKit.ATTR_HOST)) ~= "string" then
		return false
	end
	local image = model:GetAttribute(FaceKit.ATTR_BLOCK .. (expression or "Neutral"))
	if type(image) ~= "string" then
		image = model:GetAttribute(FaceKit.ATTR_BLOCK .. "Neutral")
	end
	if type(image) ~= "string" then
		image = model:GetAttribute(FaceKit.ATTR_BLOCK .. "Defecto")
	end
	if type(image) ~= "string" then
		return false
	end
	local talk = model:GetAttribute(FaceKit.ATTR_BLOCK .. "Talk")
	return FaceKit.set(model, image, if type(talk) == "string" then talk else nil) ~= nil
end

-- Pone la cara `image` (y la de hablar, si la hay)
function FaceKit.set(model: Model, image: string, talk: string?): Decal?
	local head = FaceKit.host(model)
	if not head then
		return nil
	end
	local real = model:FindFirstChild("Head")
	if real and real ~= head then
		FaceKit.cleanHead(real)
		hideFaces(real) -- (estilo bloque: la Head del R15 no se ve ni lleva cara)
	end
	FaceKit.cleanHead(head)
	local d = FaceKit.decal(head)
	d.Texture = image
	d.Transparency = 0
	model:SetAttribute(FaceKit.ATTR_IMAGE, image)
	model:SetAttribute(FaceKit.ATTR_TALK, if talk and talk ~= "" then talk else nil)
	return d
end

-- Boca abierta/cerrada al hablar (el mismo Decal; si no hay cara de hablar, no hace nada)
function FaceKit.flap(model: Model, open: boolean): boolean
	local image = model:GetAttribute(FaceKit.ATTR_IMAGE)
	local talk = model:GetAttribute(FaceKit.ATTR_TALK)
	if type(image) ~= "string" or type(talk) ~= "string" then
		return false
	end
	local head = FaceKit.host(model)
	local d = head and head:FindFirstChild(FaceKit.DECAL)
	if not d or not d:IsA("Decal") then
		return false
	end
	local want = if open then talk else image
	if d.Texture ~= want then
		d.Texture = want
	end
	return true
end

-- Cuántas bocas se ven en la cabeza (deben ser 1)
function FaceKit.mouths(model: Model): (number, { string })
	local list = {}
	local parts = {}
	local head = model:FindFirstChild("Head")
	if head then
		table.insert(parts, head)
	end
	local host = FaceKit.host(model)
	if host and host ~= head then
		table.insert(parts, host) -- (estilo bloque: la cara va en la cabeza de bloque)
	end
	for _, part in parts do
		for _, child in part:GetChildren() do
			if isDecal(child) then
				local d = child :: Decal
				if d.Transparency < 0.99 and d.Texture ~= "" then
					table.insert(list, part.Name .. "/Decal:" .. d.Name)
				end
			elseif child:IsA("FaceControls") then
				table.insert(list, "FaceControls")
			elseif child:IsA("SurfaceAppearance") and part == head then
				table.insert(list, "SurfaceAppearance")
			elseif child:IsA("SurfaceGui") and (child :: SurfaceGui).Enabled then
				for _, frame in child:GetChildren() do
					if frame:IsA("GuiObject") and frame.Visible and frame:FindFirstChild("Boca", true) then
						table.insert(list, "SurfaceGui:" .. child.Name .. "/" .. frame.Name)
					end
				end
			end
		end
	end
	if head and head:IsA("MeshPart") then
		local ok, texture = pcall(function()
			return (head :: any).TextureID
		end)
		if ok and type(texture) == "string" and texture ~= "" then
			table.insert(list, "TextureID")
		end
	end
	return #list, list
end

return FaceKit
