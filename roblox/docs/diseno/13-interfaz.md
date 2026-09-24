# Fase 13 — Interfaz

## 13.1 Principios

1. **Pantalla limpia.** Solo se ve lo imprescindible. Todo lo demás vive en el teléfono.
2. **Contextual.** Las acciones aparecen donde tienen sentido (al acercarte a un mostrador, "Pedir"; al subir a un coche, el velocímetro).
3. **Móvil primero.** Botones grandes, alcanzables con el pulgar, legibles en pantallas pequeñas. En PC con atajos de teclado y en consola con mando.
4. **Coherente.** Un solo sistema de diseño (colores, tipografía, componentes) para todo.
5. **Bilingüe desde el inicio** (español e inglés) con `LocalizationService`. Ningún texto se escribe directamente en el código de la interfaz.

## 13.2 HUD (lo que siempre se ve)

```
┌─────────────────────────────────────────────────────────────┐
│ N$ 12.450          ☀ 14:35 · Lun · Día 12          🔔        │
│                                                             │
│                                                             │
│                                         ┌─────────────────┐ │
│                                         │ 💼 Turno: 06:20 │ │  ← objetivo actual
│                                         │ Atiende a la    │ │    (solo si hay)
│                                         │ paciente de 3B  │ │
│                                         └─────────────────┘ │
│                                                             │
│ ◔ ◔ ◔ ◔  (anillos de necesidades,                    [📱]   │
│           se muestran solo si alguna está baja)             │
└─────────────────────────────────────────────────────────────┘
```

- Dinero, hora y notificaciones arriba.
- **Necesidades:** anillos pequeños que solo aparecen cuando alguna baja del 40% (el resto del tiempo, en el teléfono).
- **Tarjeta de objetivo:** trabajo, clase o misión actual, con la línea guía en el mundo.
- **Botón del teléfono** (tecla `P` / botón en móvil).

## 13.3 El teléfono (interfaz principal)

Pantalla de inicio con apps (se desbloquean según la etapa: un niño tiene un teléfono simplificado):

| App | Función |
|---|---|
| 🗺️ **Mapa / GPS** | Mapa de la región por distritos, lugares, ruta hasta el destino (grafo de carreteras) y transporte público |
| 🏦 **Banco** | Saldo, cuentas, extracto, transferencias, préstamos, hipoteca, facturas |
| 💼 **Empleo** | Ofertas (con requisitos), tu carrera, turnos, rendimiento, ascensos |
| 🎓 **Estudios** | Cursos disponibles y en curso, notas, próximas clases, títulos y licencias |
| 🏠 **Inmobiliaria / Propiedades** | Buscar vivienda, tus propiedades, inquilinos, construir |
| 🚗 **Vehículos** | Tus vehículos, estado, seguro, llamar desde el parking |
| 🎒 **Inventario** | Lo que llevas y lo que hay en casa |
| 👤 **Perfil / Vida** | Edad, etapa, habilidades, logros, estadísticas, cumpleaños |
| 👨‍👩‍👧 **Familia** | Hogar, miembros (dónde están), árbol genealógico, "Ir con…" |
| 💬 **Mensajes / Contactos** | Chat con amigos y familia entre servidores (filtrado) |
| 📰 **Noticias** | Noticias del mundo (eventos, emergencias, festivales, artículos de periodistas jugadores) |
| 🏢 **Empresa** | Gestión de tu negocio (si tienes) |
| 🛒 **Tienda Nova** | Pases y productos con Robux |
| ⚙️ **Ajustes** | Gráficos, sonido, idioma, pausar edad, privacidad, controles |

## 13.4 Otras pantallas

- **Creación de personaje / selección de vida** al entrar.
- **Modo construcción** (herramientas propias a pantalla completa).
- **Tiendas y concesionarios:** vista de catálogo con vista previa 3D.
- **Resúmenes** de turno, examen, cumpleaños y ascenso: momentos de celebración con animación y sonido.

## 13.5 Técnica

- **Librería de UI declarativa** (React-Luau, la que usa la propia Roblox, instalada con Wally) con componentes reutilizables (Botón, Tarjeta, Lista, Pestañas, Modal…). Evita el código de interfaz "espagueti" cuando haya 15 apps.
- **Estado de UI** alimentado por réplicas de solo lectura del perfil (el servidor envía los cambios y el cliente los muestra). La interfaz nunca modifica datos: solo envía peticiones.
- **Escalado adaptativo** y zonas seguras de pantalla (muescas de móvil).
