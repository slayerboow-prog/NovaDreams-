-- StoryFxCatalog: el CATÁLOGO DE EFECTOS (VFX) de la historia, como datos. Cada receta dice qué tipo
-- de efecto es (Kind: lo construye shared/StoryFxBuild y lo mueve Controllers/StoryFx), sus colores,
-- tamaños, tiempos, sonidos y cuánto gasta. Todo por código con texturas internas de Roblox
-- (rbxasset://, nada de internet). Puro: lo prueba scripts/test-vfx.luau.
--
-- Presupuesto por nivel gráfico (shared/Graphics; el del jugador está en su atributo GraphicsTier):
--   Particles  multiplica cuántas partículas salen   (Bajo 0,35 · Medio 0,7 · Alto 1)
--   Debris     cuántos escombros con física como mucho
--   Lights     luces del efecto (Bajo: una, sin sombra)
--   Shadows    si la luz principal echa sombra (solo Alto)
--   Extras     capas de adorno (halo, onda secundaria, chispas extra): no en Bajo
-- Y un tope GLOBAL de partículas a la vez por nivel (MaxRate): StoryFx recorta si se pasa.
--
-- Uso desde una escena (pista Fx): { At = 2, Play = "Meteor", Anchor = "Rift", To = { "Parque" }, Seconds = 2.6 }
-- o desde código del cliente: StoryFx.play("Explosion", cframe, { Scale = 2 })

local StoryFxCatalog = {}

local rgb = Color3.fromRGB

-- Texturas internas de Roblox (vienen con el motor)
StoryFxCatalog.Textures = {
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
	Fire = "rbxasset://textures/particles/fire_main.dds",
	Sparkles = "rbxasset://textures/particles/sparkles_main.dds",
	Spark = "rbxasset://textures/particles/fire_sparks_main.dds",
	Glow = "rbxasset://textures/particles/forcefield_glow_main.dds",
	Vortex = "rbxasset://textures/particles/forcefield_vortex_main.dds",
	Shock = "rbxasset://textures/particles/explosion01_shockwave_main.dds",
	Core = "rbxasset://textures/particles/explosion01_core_main.dds",
}
-- Sonidos internos (se retocan de tono: collide grave = estruendo, swoosh grave = silbido)
StoryFxCatalog.Sounds = {
	Boom = { Id = "rbxasset://sounds/collide.wav", Pitch = 0.32, Volume = 1 },
	Rumble = { Id = "rbxasset://sounds/collide.wav", Pitch = 0.22, Volume = 0.8 },
	Whoosh = { Id = "rbxasset://sounds/swoosh.wav", Pitch = 0.45, Volume = 0.8 },
	Hum = { Id = "rbxasset://sounds/electronicpingshort.wav", Pitch = 0.35, Volume = 0.45 },
	Ping = { Id = "rbxasset://sounds/electronicpingshort.wav", Pitch = 1.4, Volume = 0.5 },
	Thunder = { Id = "rbxasset://sounds/collide.wav", Pitch = 0.18, Volume = 1 },
	Crack = { Id = "rbxasset://sounds/action_jump_land.mp3", Pitch = 0.45, Volume = 0.9 },
	Poof = { Id = "rbxasset://sounds/swoosh.wav", Pitch = 1.6, Volume = 0.5 },
	Rain = { Id = "rbxasset://sounds/impact_water.mp3", Pitch = 0.5, Volume = 0.25 },
	Zap = { Id = "rbxasset://sounds/switch.wav", Pitch = 0.6, Volume = 0.6 },
}

export type TierName = "Low" | "Medium" | "High"
export type Budget = { Particles: number, Debris: number, Lights: number, Shadows: boolean, Extras: boolean, MaxRate: number }

StoryFxCatalog.Budgets = {
	Low = { Particles = 0.35, Debris = 3, Lights = 1, Shadows = false, Extras = false, MaxRate = 250 },
	Medium = { Particles = 0.7, Debris = 8, Lights = 2, Shadows = false, Extras = true, MaxRate = 700 },
	High = { Particles = 1, Debris = 14, Lights = 3, Shadows = true, Extras = true, MaxRate = 1500 },
} :: { [TierName]: Budget }

-- Las recetas. Seconds = cuánto dura (0 = hasta que se pare: portal abierto, cráter, aura…).
StoryFxCatalog.Recipes = {
	-- Meteorito / estrella fugaz: sale de un punto (la Grieta o el cielo), cae con estela de fuego y
	-- humo y, al llegar, lanza su Impact.
	Meteor = {
		Kind = "Meteor",
		Seconds = 2.6,
		Size = 2.4,
		Core = rgb(255, 250, 220),
		Fire = { rgb(255, 230, 120), rgb(255, 120, 30) },
		Trail = rgb(150, 255, 190),
		SmokeColor = rgb(90, 90, 90),
		Rate = { Fire = 90, Smoke = 40, Sparks = 30 },
		Light = { Color = rgb(170, 255, 200), Range = 30, Brightness = 4 },
		Sound = "Whoosh",
		Impact = "MeteorImpact",
		Arc = 0.12, -- curva de la caída (0 = recta)
	},
	-- Impacto: destello, onda expansiva, humo, fuego, escombros con física, temblor y estruendo. Deja
	-- una mancha quemada temporal (el cráter que se QUEDA lo pone la memoria del mundo: StageSets).
	MeteorImpact = {
		Kind = "Impact",
		Seconds = 6,
		Radius = 7,
		Flash = { Color = rgb(220, 255, 230), Range = 60, Brightness = 10, Seconds = 0.35 },
		Shock = { Color = rgb(200, 255, 220), From = 2, To = 34, Seconds = 0.7 },
		Fireball = { Color = rgb(255, 170, 60), Size = 9, Seconds = 0.6 },
		Smoke = { Color = rgb(70, 74, 70), Rate = 70, Seconds = 4.5, Size = 6 },
		Fire = { Color = rgb(255, 140, 40), Rate = 45, Seconds = 3 },
		Sparks = { Color = rgb(170, 255, 190), Rate = 80, Seconds = 1 },
		Debris = { Count = 14, Color = rgb(90, 82, 74), Speed = 55, Life = 4 },
		Shake = { Strength = 1.2, Seconds = 1.1, Radius = 160 },
		Scorch = { Color = rgb(30, 28, 26), Size = 12, Seconds = 6 },
		Sound = "Boom",
	},
	-- Explosión (garaje, laboratorio…): bola de fuego, humo negro, chispas, escombros, onda y temblor
	Explosion = {
		Kind = "Impact",
		Seconds = 7,
		Radius = 9,
		Flash = { Color = rgb(255, 220, 160), Range = 70, Brightness = 12, Seconds = 0.4 },
		Shock = { Color = rgb(255, 210, 150), From = 3, To = 40, Seconds = 0.8 },
		Fireball = { Color = rgb(255, 120, 30), Size = 14, Seconds = 0.9 },
		Smoke = { Color = rgb(40, 38, 36), Rate = 90, Seconds = 6, Size = 9 },
		Fire = { Color = rgb(255, 100, 20), Rate = 70, Seconds = 3.5 },
		Sparks = { Color = rgb(255, 200, 90), Rate = 120, Seconds = 1.2 },
		Debris = { Count = 16, Color = rgb(70, 66, 62), Speed = 70, Life = 4.5 },
		Shake = { Strength = 1.5, Seconds = 1.3, Radius = 200 },
		Scorch = { Color = rgb(20, 18, 16), Size = 16, Seconds = 7 },
		Sound = "Boom",
	},
	-- Portal: se abre girando (anillo que crece), remolino dentro, chispas que entran; atravesarlo
	-- teletransporta (si la escena le da destino: Params.Teleport) con un tirón y un destello.
	Portal = {
		Kind = "Portal",
		Seconds = 0,
		Radius = 4,
		Open = 1.2,
		Close = 0.8,
		Ring = rgb(120, 255, 170),
		Inner = rgb(30, 90, 60),
		Swirl = rgb(170, 255, 210),
		Rate = { Swirl = 60, Sparks = 25 },
		Light = { Color = rgb(140, 255, 190), Range = 22, Brightness = 3 },
		Sound = "Hum",
		EnterSound = "Whoosh",
	},
	-- Grieta en el suelo: se abre a trompicones, con luz dentro, polvo y temblor
	GroundCrack = {
		Kind = "Crack",
		Seconds = 0,
		Length = 30,
		Width = 2.2,
		Open = 2.5,
		Segments = 9,
		Glow = rgb(140, 255, 180),
		Edge = rgb(40, 34, 30),
		Rate = { Dust = 50 },
		Light = { Color = rgb(140, 255, 180), Range = 18, Brightness = 2.5 },
		Shake = { Strength = 0.6, Seconds = 2.5, Radius = 120 },
		Sound = "Rumble",
	},
	-- Luz misteriosa / orbe de energía: brilla, late y suelta chispas; puede subir (Params.Rise)
	MysticOrb = {
		Kind = "Orb",
		Seconds = 0,
		Size = 1.6,
		Color = rgb(150, 255, 200),
		Halo = rgb(90, 220, 150),
		Pulse = 1.6, -- latidos por segundo
		Rate = { Sparks = 20 },
		Light = { Color = rgb(150, 255, 200), Range = 18, Brightness = 2.5 },
		Sound = "Hum",
	},
	-- Aura de poder: rodea a un personaje (contorno que late, partículas que suben, luz)
	EnergyAura = {
		Kind = "Aura",
		Seconds = 0,
		Color = rgb(120, 255, 170),
		Pulse = 1.2,
		Rate = { Rise = 30 },
		Light = { Color = rgb(120, 255, 170), Range = 12, Brightness = 2 },
		Sound = "Zap",
	},
	-- Tormenta local: nubes oscuras sobre una zona, lluvia solo ahí, rayos que caen y cielo plomizo
	LocalStorm = {
		Kind = "Storm",
		Seconds = 0,
		Radius = 60,
		Height = 70,
		Clouds = 9,
		CloudColor = rgb(56, 58, 66),
		Rain = { Rate = 400, Color = rgb(190, 200, 215) },
		Lightning = { Every = { 1.8, 4.5 }, Color = rgb(225, 235, 255), Segments = 7 },
		SkyMood = "Tormenta",
		Sound = "Thunder",
	},
	-- Cambio de cielo puntual (capa de shared/SkyMoods mientras dura)
	SkyShift = {
		Kind = "Sky",
		Seconds = 6,
		Mood = "GrietaVerde",
		Fade = 1.5,
	},
	-- Cráter (el que se queda): mismo dibujo que el de la memoria del mundo (StoryFxBuild.crater)
	Crater = {
		Kind = "Crater",
		Seconds = 0,
		Radius = 5,
		Depth = 1.2,
		Rim = rgb(96, 86, 74),
		Floor = rgb(34, 30, 28),
		Glow = rgb(120, 255, 170),
		Smoke = true,
	},
	-- Pequeños: nube de humo con chispas (alguien aparece o desaparece), destello y chispas verdes
	Poof = {
		Kind = "Burst",
		Seconds = 1.6,
		Color = rgb(235, 240, 235),
		Sparkle = rgb(170, 255, 200),
		Rate = { Smoke = 60, Sparks = 40 },
		Sound = "Poof",
	},
	GreenSparks = {
		Kind = "Burst",
		Seconds = 1.4,
		Color = rgb(170, 255, 190),
		Sparkle = rgb(200, 255, 140),
		Rate = { Smoke = 0, Sparks = 80 },
		Sound = "Ping",
	},
	Flash = {
		Kind = "Flash",
		Seconds = 0.5,
		Color = rgb(255, 255, 255),
		Amount = 0.8,
	},
}

StoryFxCatalog.Kinds = {
	Meteor = true,
	Impact = true,
	Portal = true,
	Crack = true,
	Orb = true,
	Aura = true,
	Storm = true,
	Sky = true,
	Crater = true,
	Burst = true,
	Flash = true,
}

function StoryFxCatalog.get(name: any): { [string]: any }?
	return if type(name) == "string" then StoryFxCatalog.Recipes[name] else nil
end

function StoryFxCatalog.names(): { [string]: boolean }
	local set = {}
	for name in StoryFxCatalog.Recipes do
		set[name] = true
	end
	return set
end

function StoryFxCatalog.tierName(value: any): TierName
	return if value == "Low" or value == "High" then value else "Medium"
end

function StoryFxCatalog.budget(tier: any): Budget
	return StoryFxCatalog.Budgets[StoryFxCatalog.tierName(tier)]
end

-- Partículas por segundo de una capa del efecto con el presupuesto del nivel (y la escala del efecto)
function StoryFxCatalog.rate(base: number?, tier: any, scale: number?): number
	local b = StoryFxCatalog.budget(tier)
	return math.floor((base or 0) * b.Particles * math.clamp(scale or 1, 0.2, 4) + 0.5)
end

-- Cuántos escombros (con el tope del nivel)
function StoryFxCatalog.debris(count: number?, tier: any): number
	return math.min(count or 0, StoryFxCatalog.budget(tier).Debris)
end

-- Si el total de partículas activas se pasa del tope del nivel, por cuánto hay que multiplicar las nuevas
function StoryFxCatalog.squeeze(activeRate: number, newRate: number, tier: any): number
	local cap = StoryFxCatalog.budget(tier).MaxRate
	if newRate <= 0 or activeRate + newRate <= cap then
		return 1
	end
	return math.clamp((cap - activeRate) / newRate, 0, 1)
end

-- Errores de una receta (pruebas)
function StoryFxCatalog.check(name: string, recipe: { [string]: any }): { string }
	local errors = {}
	local function err(fmt: string, ...)
		table.insert(errors, ("efecto %s: " .. fmt):format(name, ...))
	end
	if not StoryFxCatalog.Kinds[recipe.Kind] then
		err("tipo desconocido '%s'", tostring(recipe.Kind))
	end
	if type(recipe.Seconds) ~= "number" or recipe.Seconds < 0 then
		err("Seconds tiene que ser un número >= 0")
	end
	if recipe.Sound and not StoryFxCatalog.Sounds[recipe.Sound] then
		err("sonido desconocido '%s'", tostring(recipe.Sound))
	end
	if recipe.EnterSound and not StoryFxCatalog.Sounds[recipe.EnterSound] then
		err("sonido de entrada desconocido '%s'", tostring(recipe.EnterSound))
	end
	if recipe.Impact and not StoryFxCatalog.Recipes[recipe.Impact] then
		err("impacto desconocido '%s'", tostring(recipe.Impact))
	end
	return errors
end

return StoryFxCatalog
