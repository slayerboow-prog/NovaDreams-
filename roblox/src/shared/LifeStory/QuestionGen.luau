-- QuestionGen: preguntas creadas con código, para que Matemáticas, Cálculo y Contabilidad
-- no se repitan nunca. Cada generador devuelve { Q = pregunta, A = { correcta, otra, otra, otra } }
-- (la primera es la correcta; el servidor baraja las respuestas antes de enseñarlas).
-- Recibe un Random para que se pueda probar con resultados fijos.

local QuestionGen = {}

type Question = { Q: string, A: { string } }

-- 21.000000001 -> "21", 12.5 -> "12,5" (coma decimal, como en España)
local function fmt(n: number): string
	n = math.round(n * 100) / 100
	if n == math.floor(n) then
		return tostring(math.floor(n))
	end
	local text = ("%.2f"):format(n):gsub("0+$", ""):gsub("%.$", "")
	return (text:gsub("%.", ","))
end

-- Tres respuestas incorrectas distintas y cercanas a la correcta
local function distractors(rng: Random, correct: number, spread: number, integer: boolean?): { string }
	local seen = { [fmt(correct)] = true }
	local out = {}
	local tries = 0
	while #out < 3 and tries < 60 do
		tries += 1
		local delta = rng:NextInteger(1, math.max(2, spread))
		local value = correct + (if rng:NextNumber() < 0.5 then -delta else delta)
		if integer then
			value = math.floor(value)
		end
		local text = fmt(value)
		if value >= 0 and not seen[text] then
			seen[text] = true
			table.insert(out, text)
		end
	end
	local extra = 1
	while #out < 3 do
		local text = fmt(correct + spread + extra)
		if not seen[text] then
			seen[text] = true
			table.insert(out, text)
		end
		extra += 1
	end
	return out
end

local function make(q: string, correct: number, rng: Random, spread: number, integer: boolean?): Question
	local wrong = distractors(rng, correct, spread, integer)
	return { Q = q, A = { fmt(correct), wrong[1], wrong[2], wrong[3] } }
end

-- Primaria: sumas, restas, tablas de multiplicar y divisiones exactas
function QuestionGen.Aritmetica(rng: Random): Question
	local kind = rng:NextInteger(1, 4)
	if kind == 1 then
		local a, b = rng:NextInteger(3, 60), rng:NextInteger(2, 40)
		return make(("¿Cuánto es %d + %d?"):format(a, b), a + b, rng, 6, true)
	elseif kind == 2 then
		local a = rng:NextInteger(10, 80)
		local b = rng:NextInteger(1, a - 1)
		return make(("¿Cuánto es %d − %d?"):format(a, b), a - b, rng, 6, true)
	elseif kind == 3 then
		local a, b = rng:NextInteger(2, 10), rng:NextInteger(2, 10)
		return make(("¿Cuánto es %d × %d?"):format(a, b), a * b, rng, 8, true)
	end
	local b, c = rng:NextInteger(2, 10), rng:NextInteger(2, 10)
	return make(("¿Cuánto es %d ÷ %d?"):format(b * c, b), c, rng, 3, true)
end

-- Instituto: ecuaciones de primer grado y porcentajes
function QuestionGen.Algebra(rng: Random): Question
	if rng:NextNumber() < 0.6 then
		local x = rng:NextInteger(1, 12)
		local a = rng:NextInteger(2, 9)
		local b = rng:NextInteger(1, 20)
		return make(("Resuelve: %dx + %d = %d. ¿Cuánto vale x?"):format(a, b, a * x + b), x, rng, 4, true)
	end
	local pct = ({ 10, 20, 25, 50, 75 })[rng:NextInteger(1, 5)]
	local base = rng:NextInteger(2, 20) * 20
	return make(("¿Cuánto es el %d %% de %d?"):format(pct, base), base * pct / 100, rng, 15, true)
end

-- Universidad (Ingeniería): derivadas sencillas, áreas y velocidades
function QuestionGen.Calculo(rng: Random): Question
	local kind = rng:NextInteger(1, 3)
	if kind == 1 then
		local a, n = rng:NextInteger(2, 9), rng:NextInteger(2, 5)
		local x = rng:NextInteger(1, 3)
		local value = a * n * x ^ (n - 1)
		return make(("Si f(x) = %dx^%d, ¿cuánto vale f'(%d)?"):format(a, n, x), value, rng, math.max(4, value // 4), true)
	elseif kind == 2 then
		local r = rng:NextInteger(2, 10)
		return make(("Área de un cuadrado de lado %d m (en m²)"):format(r), r * r, rng, 10, true)
	end
	local d, t = rng:NextInteger(2, 12) * 10, rng:NextInteger(2, 5)
	return make(("Un coche recorre %d km en %d h. ¿Velocidad media (km/h)?"):format(d * t, t), d, rng, 10, true)
end

-- Universidad (Economía): IVA, beneficios, intereses y variaciones de precio
function QuestionGen.Contabilidad(rng: Random): Question
	local kind = rng:NextInteger(1, 4)
	if kind == 1 then
		local price = rng:NextInteger(1, 20) * 100
		return make(("Un producto cuesta %d $ sin IVA. ¿Cuánto es el IVA del 21 %%?"):format(price), price * 0.21, rng, 30)
	elseif kind == 2 then
		local income = rng:NextInteger(20, 90) * 100
		local costs = rng:NextInteger(5, math.floor(income / 100) - 1) * 100
		return make(("Ingresos: %d $. Gastos: %d $. ¿Beneficio?"):format(income, costs), income - costs, rng, 400, true)
	elseif kind == 3 then
		local capital = rng:NextInteger(1, 10) * 1000
		local rate = rng:NextInteger(2, 6)
		return make(("%d $ al %d %% anual durante 1 año. ¿Intereses?"):format(capital, rate), capital * rate / 100, rng, 40, true)
	end
	local before = rng:NextInteger(4, 20) * 10
	local pct = ({ 10, 20, 25, 50 })[rng:NextInteger(1, 4)]
	return make(("Un precio de %d $ sube un %d %%. ¿Precio nuevo?"):format(before, pct), before * (1 + pct / 100), rng, 15)
end

return QuestionGen
