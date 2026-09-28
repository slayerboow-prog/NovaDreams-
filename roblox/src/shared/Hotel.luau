-- Hotel: habitaciones, precios y sueldo del recepcionista (HotelService).

local Hotel = {}

Hotel.Types = {
	{ Id = "Individual", Name = "Individual", Icon = "🛏️", Price = 20, Rooms = { 101, 102, 103, 104 } },
	{ Id = "Doble", Name = "Doble", Icon = "🛏️🛏️", Price = 35, Rooms = { 201, 202, 203, 204 } },
	{ Id = "Suite", Name = "Suite con vistas", Icon = "👑", Price = 70, Rooms = { 301, 302, 303 } },
}
Hotel.typeById = {}
Hotel.typeOfRoom = {} :: { [number]: string }
for _, t in Hotel.Types do
	Hotel.typeById[t.Id] = t
	for _, room in t.Rooms do
		Hotel.typeOfRoom[room] = t.Id
	end
end

Hotel.KeyItem = "LlaveHotel"
Hotel.RestSeconds = 4 -- lo que se tarda en descansar en la habitación
Hotel.StayMin, Hotel.StayMax = 150, 300 -- lo que se quedan los huéspedes NPC (segundos)

Hotel.Job = {
	Name = "Recepcionista",
	Icon = "🛎️",
	PerCheckIn = 8, -- por cada entrada bien hecha
	PerCheckOut = 6, -- por cada salida bien cobrada
	Tip = 3, -- propina si se atiende rápido
	FastSeconds = 40,
	EnergyCost = 2,
}
Hotel.MaxNpc = 3

return Hotel
