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

local FaceKit = {}

FaceKit.DECAL = "face"
FaceKit.ATTR_IMAGE = "FaceImage"
FaceKit.ATTR_TALK = "FaceTalk"

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

-- Pone la cara `image` (y la de hablar, si la hay)
function FaceKit.set(model: Model, image: string, talk: string?): Decal?
	local head = model:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then
		return nil
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
	local head = model:FindFirstChild("Head")
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
	local head = model:FindFirstChild("Head")
	local list = {}
	if not head then
		return 0, list
	end
	for _, child in head:GetChildren() do
		if isDecal(child) then
			local d = child :: Decal
			if d.Transparency < 0.99 and d.Texture ~= "" then
				table.insert(list, "Decal:" .. d.Name)
			end
		elseif child:IsA("FaceControls") then
			table.insert(list, "FaceControls")
		elseif child:IsA("SurfaceAppearance") then
			table.insert(list, "SurfaceAppearance")
		elseif child:IsA("SurfaceGui") and (child :: SurfaceGui).Enabled then
			for _, frame in child:GetChildren() do
				if frame:IsA("GuiObject") and frame.Visible and frame:FindFirstChild("Boca", true) then
					table.insert(list, "SurfaceGui:" .. child.Name .. "/" .. frame.Name)
				end
			end
		end
	end
	if head:IsA("MeshPart") then
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
