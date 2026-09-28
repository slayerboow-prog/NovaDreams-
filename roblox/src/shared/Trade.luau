-- Trade: reglas del intercambio entre jugadores y del mercadillo (TradeService y TradeUI).
--
-- Qué se puede pasar a otro jugador: lo normal de la mochila (comida y objetos) y dinero.
-- No se pasan vehículos, premios, carnets, títulos, recuerdos de la historia ni llaves de hotel.
--
-- Robux: el dinero del juego se puede comprar con Robux (paquetes de dinero), así que cuenta como
-- "objeto de pago". En los países donde la ley no lo permite (PolicyService →
-- IsPaidItemTradingAllowed = false) el intercambio y el mercadillo están cerrados para ese jugador.

local Items = require(script.Parent.Items)
local Hotel = require(script.Parent.Hotel)

local Trade = {}

Trade.MaxKinds = 6 -- distintos objetos por oferta
Trade.MaxMoney = 1000000
Trade.Range = 14 -- hay que estar cerca para empezar
Trade.KeepRange = 45 -- si os alejáis más, se cancela
Trade.InviteSeconds = 20
Trade.ConfirmSeconds = 3 -- cuenta atrás cuando los dos aceptan (para ver bien lo que te dan)

Trade.Market = {
	MaxListings = 5, -- anuncios por jugador
	MinPrice = 1,
	MaxPrice = 100000,
	Fee = 0.05, -- el mercadillo se queda un 5 % (el vendedor recibe el resto)
}

local KINDS = { Food = true, Thing = true }
local BLOCKED = { [Hotel.KeyItem] = true }

function Trade.tradeable(id: any): boolean
	if typeof(id) ~= "string" or BLOCKED[id] then
		return false
	end
	local item = Items.get(id)
	return item ~= nil and KINDS[item.Kind] == true
end

-- Lo que recibe el vendedor por una venta
function Trade.sellerGets(price: number): number
	return price - math.ceil(price * Trade.Market.Fee)
end

return Trade
