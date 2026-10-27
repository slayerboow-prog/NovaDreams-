-- EstiloBloqueLOD (cliente): la versión lejana de los accesorios grandes del estilo bloque (pelo, bata,
-- mochila…: World/EstiloBloqueLoader las monta invisibles con el atributo LodDe = el accesorio que
-- sustituyen). De lejos se ve la sencilla y no la detallada; de cerca, al revés. Solo en esta pantalla
-- (Transparency local). Además, muy lejos se esconden los accesorios pequeños (menos que dibujar en el
-- móvil). Nada más: los accesorios van soldados y se mueven con el cuerpo.

local CollectionService = game:GetService("CollectionService")

local EstiloBloqueLOD = {}

EstiloBloqueLOD.TAG = "EstiloBloque"
EstiloBloqueLOD.Near = 55 -- más lejos: la versión lejana
EstiloBloqueLOD.Far = 220 -- más lejos: sin accesorios pequeños
EstiloBloqueLOD.SmallTris = 200
EstiloBloqueLOD.Every = 0.5 -- segundos entre repasos

type Pair = { Detail: BasePart, Lod: BasePart }
type Rec = { Model: Model, Pairs: { Pair }, Small: { BasePart }, State: string }

local recs: { [Model]: Rec } = {}

function EstiloBloqueLOD.track(model: Model): Rec?
	local folder = model:FindFirstChild("EstiloBloque")
	if not folder then
		return nil
	end
	local pairs_ = {}
	local small = {}
	for _, p in folder:GetChildren() do
		if p:IsA("BasePart") then
			local base = p:GetAttribute("LodDe")
			if type(base) == "string" then
				local d = folder:FindFirstChild(base)
				if d and d:IsA("BasePart") then
					table.insert(pairs_, { Detail = d, Lod = p })
				end
			elseif p.Size.Magnitude < 1.2 and p.Name ~= "CabezaBloque" and p.Name ~= "Pantalla" then
				table.insert(small, p)
			end
		end
	end
	local rec: Rec = { Model = model, Pairs = pairs_, Small = small, State = "" }
	recs[model] = rec
	return rec
end

-- Lo que toca a esa distancia: "cerca", "lejos" o "muy lejos"
function EstiloBloqueLOD.stateFor(dist: number): string
	if dist > EstiloBloqueLOD.Far then
		return "muy lejos"
	elseif dist > EstiloBloqueLOD.Near then
		return "lejos"
	end
	return "cerca"
end

function EstiloBloqueLOD.apply(rec: Rec, state: string)
	if rec.State == state then
		return
	end
	rec.State = state
	local far = state ~= "cerca"
	for _, p in rec.Pairs do
		p.Detail.Transparency = if far then 1 else 0
		p.Lod.Transparency = if far then 0 else 1
	end
	for _, s in rec.Small do
		s.LocalTransparencyModifier = if state == "muy lejos" then 1 else 0
	end
end

function EstiloBloqueLOD.step()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local eye = cam.CFrame.Position
	for model, rec in recs do
		if not model.Parent then
			recs[model] = nil
			continue
		end
		local root = model:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			EstiloBloqueLOD.apply(rec, EstiloBloqueLOD.stateFor((root.Position - eye).Magnitude))
		end
	end
end

function EstiloBloqueLOD.init()
	local function add(m: Instance)
		if m:IsA("Model") then
			task.defer(function()
				pcall(EstiloBloqueLOD.track, m)
			end)
		end
	end
	for _, m in CollectionService:GetTagged(EstiloBloqueLOD.TAG) do
		add(m)
	end
	CollectionService:GetInstanceAddedSignal(EstiloBloqueLOD.TAG):Connect(add)
	CollectionService:GetInstanceRemovedSignal(EstiloBloqueLOD.TAG):Connect(function(m)
		recs[m :: Model] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(EstiloBloqueLOD.Every)
			pcall(EstiloBloqueLOD.step)
		end
	end)
end

return EstiloBloqueLOD
