-- Build: monta la casa de Cosme entera en su parcela (la llama World/Kit/Blocks al construir la
-- ciudad, también desde scripts/build-place.luau). Cada parte en su módulo:
--   Exterior (parcela, fachadas, jardines, torre-portal) · Interior (plantas baja y alta) ·
--   Laboratory (sótano) · Garage · Observatory (torre, ático y azotea) · SecretRoom · QuestHooks (marcas)
-- Lo que se mueve y se usa lo arranca CosmeHouse/Start al iniciar el servidor.
--
-- site: CFrame del centro de la manzana a ras de suelo, con la fachada mirando a -Z (Layout).

local Builder = require(script.Parent.Parent.Builder)
local Kit = require(script.Parent.Kit)
local Exterior = require(script.Parent.Exterior)
local Interior = require(script.Parent.Interior)
local Laboratory = require(script.Parent.Laboratory)
local Garage = require(script.Parent.Garage)
local Observatory = require(script.Parent.Observatory)
local SecretRoom = require(script.Parent.SecretRoom)
local QuestHooks = require(script.Parent.QuestHooks)

local Build = {}

Build.Name = "CasaCosme"

function Build.build(parent: Instance, site: CFrame): Model
	local model = Builder.model(Build.Name, parent)
	model:AddTag("CosmeHouse")
	model:SetAttribute("Site", site)
	-- (las luces y los interruptores de la casa funcionan como en los interiores: InteractService)
	model:SetAttribute("InteractRoot", true)
	local ctx = Kit.new(model, site, "CasaCosme")
	Exterior.build(ctx, model)
	Interior.build(ctx, model)
	Laboratory.build(ctx, model)
	Garage.build(ctx, model)
	Observatory.build(ctx, model)
	SecretRoom.build(ctx, model)
	QuestHooks.marks(ctx, model)
	model:SetAttribute("Lights", ctx.Lights)
	return model
end

return Build
