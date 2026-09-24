-- Format: funciones para mostrar números y horas bonitos en pantalla.

local Format = {}

-- 1234567 -> "$1.234.567"
function Format.money(amount: number): string
	local negative = amount < 0
	local digits = tostring(math.floor(math.abs(amount)))
	local withDots = digits:reverse():gsub("(%d%d%d)", "%1."):reverse()
	if withDots:sub(1, 1) == "." then
		withDots = withDots:sub(2)
	end
	return (if negative then "-$" else "$") .. withDots
end

-- 13.5 -> "13:30"
function Format.clock(clockTime: number): string
	local hours = math.floor(clockTime) % 24
	local minutes = math.floor((clockTime - math.floor(clockTime)) * 60)
	return string.format("%02d:%02d", hours, minutes)
end

return Format
