-- Cinema: la cartelera de los cines, los horarios de las sesiones y la barra (CinemaService).
--
-- Las sesiones van seguidas y son iguales para todos (se calculan con la hora del servidor):
--   Entrada (se puede entrar a la sala) -> Película (en la pantalla) -> Descanso
-- La película de cada sesión va rotando por la cartelera.

local Cinema = {}

local rgb = Color3.fromRGB

export type Scene = { Icon: string, Text: string, Color: Color3 }
export type Film = { Id: string, Title: string, Genre: string, Icon: string, Poster: Color3, Scenes: { Scene } }

Cinema.Films = {
	{
		Id = "Galaxia",
		Title = "Más allá de la galaxia",
		Genre = "Ciencia ficción",
		Icon = "🚀",
		Poster = rgb(40, 50, 120),
		Scenes = {
			{ Icon = "🌍", Text = "Año 2350. La Tierra se queda sin energía.", Color = rgb(20, 30, 70) },
			{ Icon = "🚀", Text = "La nave Esperanza despega hacia lo desconocido.", Color = rgb(10, 10, 30) },
			{ Icon = "☄️", Text = "¡Una lluvia de meteoritos! Todos a sus puestos.", Color = rgb(80, 30, 20) },
			{ Icon = "👽", Text = "—Venimos en son de paz… ¿Tenéis galletas?", Color = rgb(30, 80, 40) },
			{ Icon = "✨", Text = "Una estrella nueva ilumina el camino a casa.", Color = rgb(60, 50, 110) },
			{ Icon = "🏁", Text = "FIN. La humanidad tiene un nuevo hogar.", Color = rgb(10, 10, 20) },
		},
	},
	{
		Id = "Abuela",
		Title = "La abuela contraataca",
		Genre = "Comedia",
		Icon = "👵",
		Poster = rgb(200, 90, 60),
		Scenes = {
			{ Icon = "👵", Text = "Doña Rosario tiene 84 años y un plan.", Color = rgb(120, 70, 40) },
			{ Icon = "🛵", Text = "Roba la moto de su nieto… para ir a bingo.", Color = rgb(40, 90, 140) },
			{ Icon = "🎲", Text = "¡BINGO! Y el premio es… un viaje a Valmar.", Color = rgb(140, 40, 90) },
			{ Icon = "🏖️", Text = "Todo el pueblo la sigue hasta la playa.", Color = rgb(40, 140, 170) },
			{ Icon = "💃", Text = "Baile final en el paseo marítimo.", Color = rgb(170, 60, 120) },
			{ Icon = "🏁", Text = "FIN. Nunca subestimes a una abuela.", Color = rgb(20, 20, 20) },
		},
	},
	{
		Id = "Bosque",
		Title = "El secreto del bosque",
		Genre = "Aventura",
		Icon = "🌲",
		Poster = rgb(40, 110, 60),
		Scenes = {
			{ Icon = "🗺️", Text = "Un mapa antiguo aparece en el desván.", Color = rgb(110, 80, 40) },
			{ Icon = "🌲", Text = "Tres amigos se adentran en el bosque de Montes.", Color = rgb(20, 70, 30) },
			{ Icon = "🐺", Text = "¡Algo se mueve entre los árboles!", Color = rgb(30, 30, 40) },
			{ Icon = "🐕", Text = "…era un perro perdido. Le llaman Tesoro.", Color = rgb(80, 110, 60) },
			{ Icon = "💎", Text = "El tesoro de verdad era la amistad (y un cofre).", Color = rgb(60, 120, 140) },
			{ Icon = "🏁", Text = "FIN. Tesoro vive feliz con su nueva familia.", Color = rgb(20, 20, 20) },
		},
	},
} :: { Film }

Cinema.byId = {} :: { [string]: Film }
for _, film in Cinema.Films do
	Cinema.byId[film.Id] = film
end

-- Horario de cada sesión (segundos)
Cinema.EntrySeconds = 40 -- se puede entrar a la sala
Cinema.FilmSeconds = 90 -- la película (se reparte entre sus escenas)
Cinema.BreakSeconds = 20 -- descanso
Cinema.Cycle = Cinema.EntrySeconds + Cinema.FilmSeconds + Cinema.BreakSeconds

-- Qué película toca y en qué parte está la sesión en un momento dado
function Cinema.session(now: number): (Film, string, number)
	local index = math.floor(now / Cinema.Cycle)
	local film = Cinema.Films[index % #Cinema.Films + 1]
	local t = now % Cinema.Cycle
	if t < Cinema.EntrySeconds then
		return film, "Entry", Cinema.EntrySeconds - t
	elseif t < Cinema.EntrySeconds + Cinema.FilmSeconds then
		return film, "Film", t - Cinema.EntrySeconds
	end
	return film, "Break", Cinema.Cycle - t
end

Cinema.TicketPrice = 6
Cinema.TicketItem = "EntradaCine"

Cinema.Snacks = {
	{ Id = "Palomitas", Name = "Palomitas", Icon = "🍿", Price = 4, Hunger = 18, Energy = 0, Station = "Palomitas" },
	{ Id = "Refresco", Name = "Refresco", Icon = "🥤", Price = 3, Hunger = 2, Energy = 10, Station = "Refresco" },
	{ Id = "Nachos", Name = "Nachos con queso", Icon = "🧀", Price = 5, Hunger = 25, Energy = 0, Station = "Nachos" },
}
Cinema.snackById = {}
for _, snack in Cinema.Snacks do
	Cinema.snackById[snack.Id] = snack
end

Cinema.Job = {
	Name = "Taquillero/a",
	Icon = "🎟️",
	PerSale = 6, -- por cada cliente atendido
	PerTicket = 2, -- y por cada entrada
	PerSnack = 2, -- y por cada cosa de la barra
	EnergyCost = 2,
}
Cinema.MaxNpc = 4

return Cinema
