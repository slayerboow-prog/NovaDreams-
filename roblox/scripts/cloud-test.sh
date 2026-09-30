#!/usr/bin/env bash
# Pruebas del juego en los servidores de Roblox (motor de verdad), con la API de Open Cloud
# "Luau execution" (luau-execution-session-tasks). Cada prueba es un script de scripts/cloud/ que
# Roblox ejecuta en un servidor con la ÚLTIMA versión publicada del juego; devuelve una lista de
# comprobaciones y aquí se enseñan en castellano. Explicación: docs/pruebas-en-roblox.md
#
# Hace falta (variables de entorno):
#   ROBLOX_API_KEY      clave de Open Cloud con el permiso "luau-execution-sessions" (escritura)
#                       para este juego (no se enseña nunca)
#   ROBLOX_UNIVERSE_ID  (opcional) por defecto el de scripts/publish.sh
#   ROBLOX_PLACE_ID     (opcional) por defecto el de scripts/publish.sh
#
# Uso (desde la carpeta roblox/):
#   bash scripts/cloud-test.sh                  todas las pruebas de scripts/cloud/
#   bash scripts/cloud-test.sh mundo fisica     solo esas
#   bash scripts/cloud-test.sh -v arranque      enseña también todo lo que sale en la consola
#   bash scripts/cloud-test.sh --version 812 …  contra esa versión del lugar (no la última)
#   bash scripts/cloud-test.sh --list           qué pruebas hay
#
# Sale con 0 si todo va bien, 1 si alguna prueba falla y 2 si no se ha podido probar (clave,
# permisos, red…). Los registros completos quedan en ${TMPDIR:-/tmp}/cloud-test/<prueba>.log
set -euo pipefail
set +x # (la clave no se enseña nunca)
cd "$(dirname "$0")/.."

UNIVERSE="${ROBLOX_UNIVERSE_ID:-10767975237}" # Real Life Simulator (el mismo que scripts/publish.sh)
PLACE="${ROBLOX_PLACE_ID:-113359543879512}"
API="https://apis.roblox.com/cloud/v2"
DIR="scripts/cloud"
POLL_MAX="${CLOUD_TEST_WAIT:-480}" # segundos esperando a cada prueba (en cola + 5 min de ejecución)

VERBOSE=0
VERSION=""
NAMES=()
while [ $# -gt 0 ]; do
	case "$1" in
		-v | --verbose) VERBOSE=1 ;;
		--version)
			shift
			VERSION="${1:-}"
			[[ "$VERSION" =~ ^[0-9]+$ ]] || { echo "❌ --version necesita un número de versión del lugar"; exit 2; }
			;;
		--list)
			for f in "$DIR"/*.luau; do
				n="$(basename "$f" .luau)"
				[ "${n:0:1}" = "_" ] && continue
				printf '  %-12s %s\n' "$n" "$(sed -n '1s/^-- *//p' "$f")"
			done
			exit 0
			;;
		-h | --help) sed -n '2,24p' "$0"; exit 0 ;;
		-*) echo "❌ Opción desconocida: $1 (mira: bash scripts/cloud-test.sh --help)"; exit 2 ;;
		*) NAMES+=("${1%.luau}") ;;
	esac
	shift
done

# Qué pruebas (los archivos que empiezan por _ son ayudas, no pruebas)
if [ "${#NAMES[@]}" -eq 0 ]; then
	for f in "$DIR"/*.luau; do
		n="$(basename "$f" .luau)"
		[ "${n:0:1}" = "_" ] || NAMES+=("$n")
	done
fi
for n in "${NAMES[@]}"; do
	[ -f "$DIR/$n.luau" ] || { echo "❌ No existe la prueba '$n' ($DIR/$n.luau). Hay: $(cd "$DIR" && ls [!_]*.luau | sed 's/\.luau$//' | tr '\n' ' ')"; exit 2; }
done

# ---------------------------------------------------------------------------
# Clave y herramientas
# ---------------------------------------------------------------------------
if [ -z "${ROBLOX_API_KEY:-}" ]; then
	echo "❌ Falta ROBLOX_API_KEY (la clave de Open Cloud)."
	echo "   Hace falta una clave con el permiso «luau-execution-sessions» (escritura) para este juego."
	echo "   Créala o edítala en create.roblox.com → Open Cloud → API Keys y ponla así:  export ROBLOX_API_KEY=…"
	exit 2
fi
command -v curl >/dev/null 2>&1 || { echo "❌ Hace falta curl"; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Hace falta python3 (para leer las respuestas de Roblox)"; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
LOGDIR="${TMPDIR:-/tmp}/cloud-test"
mkdir -p "$LOGDIR"

# La clave va en un archivo de cabeceras (así no sale en la lista de procesos ni en ningún mensaje)
HEADERS="$WORK/headers"
( umask 077 && printf 'x-api-key: %s\n' "$ROBLOX_API_KEY" > "$HEADERS" )

# Ayudante en Python: montar el script, leer las respuestas de Roblox y enseñar el resultado
HELPER="$WORK/helper.py"
cat > "$HELPER" <<'PY'
import json, re, sys

def load(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None

def compose(prelude, main_server, test, out):
    # El orden de arranque de los servicios sale de la lista "order" de Main.server.luau
    src = open(main_server, encoding="utf-8").read()
    order = []
    m = re.search(r"local\s+order\s*=\s*\{(.*?)\n\}", src, re.S)
    if m:
        order = re.findall(r'^\s*"([A-Za-z0-9_]+)"', m.group(1), re.M)
    pre = open(prelude, encoding="utf-8").read()
    if order:
        lua_list = "{ " + ", ".join('"%s"' % n for n in order) + " }"
        pre, n = re.subn(r"^Cloud\.ORDEN_SERVICIOS = .*@@ORDEN_SERVICIOS@@.*$",
                         lambda _: "Cloud.ORDEN_SERVICIOS = %s :: { string }?" % lua_list, pre, flags=re.M)
        if n != 1:
            sys.stderr.write("⚠️  No se pudo poner el orden de los servicios en _comun.luau (se usa el alfabético)\n")
    else:
        sys.stderr.write("⚠️  No encuentro la lista 'order' en Main.server.luau (se arranca en orden alfabético)\n")
    body = "local Cloud = (function()\n" + pre.rstrip("\n") + "\nend)()\n" + open(test, encoding="utf-8").read()
    with open(out, "w", encoding="utf-8") as f:
        f.write(body)
    print(len(order))

def body(script, out):
    with open(script, encoding="utf-8") as f:
        text = f.read()
    with open(out, "w", encoding="utf-8") as f:
        json.dump({"script": text}, f)

def field(path, key):
    data = load(path)
    for k in key.split("."):
        data = data.get(k) if isinstance(data, dict) else None
    print("" if data is None else data)

def api_error(path):
    # Mensaje de error de Roblox (formato v2: {"code":..,"message":..} o v1: {"errors":[{"message":..}]})
    data = load(path)
    if isinstance(data, dict):
        msg = data.get("message") or ""
        if not msg and isinstance(data.get("errors"), list) and data["errors"]:
            msg = data["errors"][0].get("message", "")
        code = data.get("code") or ""
        print(("%s %s" % (code, msg)).strip()[:400])
    else:
        try:
            print(open(path, encoding="utf-8", errors="replace").read()[:300].replace("\n", " "))
        except Exception:
            print("")

def logs(path, out, token_out):
    data = load(path) or {}
    lines = []
    for chunk in data.get("luauExecutionSessionTaskLogs") or []:
        for m in chunk.get("structuredMessages") or []:
            kind = (m.get("messageType") or "OUTPUT").replace("MESSAGE_TYPE_UNSPECIFIED", "OUTPUT")
            lines.append("[%s] %s" % (kind, m.get("message", "")))
        for m in chunk.get("messages") or []:
            lines.append("[OUTPUT] %s" % m)
    with open(out, "a", encoding="utf-8") as f:
        for line in lines:
            f.write(line.replace("\n", "\n    ") + "\n")
    with open(token_out, "w") as f:
        f.write(data.get("nextPageToken") or "")

ERRORES = {
    "SCRIPT_ERROR": "la prueba dio un error de Luau que no se capturó",
    "DEADLINE_EXCEEDED": "se pasó del tiempo máximo de Roblox (5 minutos)",
    "OUTPUT_SIZE_LIMIT_EXCEEDED": "devolvió demasiados datos (máximo 4 MB)",
    "INTERNAL_ERROR": "fallo interno de Roblox (vuelve a lanzarla)",
}

def report(name, task_path, log_path, verbose, offset="0"):
    task = load(task_path) or {}
    state = task.get("state", "?")
    failed = False
    print()
    if state != "COMPLETE":
        err = task.get("error") or {}
        code = err.get("code", "")
        print("  ❌ La prueba no terminó bien (%s): %s" % (state, ERRORES.get(code, code or "sin detalles")))
        if err.get("message"):
            print("     " + err["message"].strip().replace("\n", "\n     ")[:1500])
            print("     (en los números de línea, la prueba %s.luau empieza en la línea %s: resta %d)" % (name, int(offset) + 1, int(offset)))
        failed = True
    else:
        results = (task.get("output") or {}).get("results") or []
        res = results[0] if results else None
        if not isinstance(res, dict) or not isinstance(res.get("checks"), list):
            print("  ❌ La prueba no devolvió la lista de comprobaciones (devolvió: %s)" % json.dumps(results)[:300])
            failed = True
        else:
            counts = {"ok": 0, "mal": 0, "aviso": 0, "salta": 0}
            for c in res["checks"]:
                nivel = c.get("nivel")
                if nivel == "salta":
                    icon, key = "⏭️ ", "salta"
                elif c.get("ok"):
                    icon, key = "✅", "ok"
                elif nivel == "aviso":
                    icon, key = "⚠️ ", "aviso"
                else:
                    icon, key = "❌", "mal"
                counts[key] += 1
                detail = (c.get("detail") or "").strip()
                print("  %s %s" % (icon, c.get("name", "?")))
                if detail:
                    for part in detail.split("; "):
                        print("       " + part)
            info = res.get("info") or {}
            if info:
                print("  ℹ️  " + ", ".join("%s: %s" % (k.replace("_", " "), info[k]) for k in sorted(info)))
            if not res.get("ok"):
                failed = True
            print("  → %d bien, %d mal, %d avisos, %d sin comprobar" % (counts["ok"], counts["mal"], counts["aviso"], counts["salta"]))
    # Consola del servidor: errores y avisos (todo con -v)
    try:
        lines = open(log_path, encoding="utf-8").read().splitlines()
    except Exception:
        lines = []
    if verbose == "1":
        shown = [l for l in lines if l.strip()]
    else:
        shown = [l for l in lines if l.startswith("[ERROR]") or l.startswith("[WARNING]")]
    if shown:
        print("  Consola del servidor%s:" % ("" if verbose == "1" else " (errores y avisos)"))
        limit = 400 if verbose == "1" else 25
        for l in shown[:limit]:
            l = l.replace("[ERROR]", "🟥").replace("[WARNING]", "🟨").replace("[OUTPUT]", "  ").replace("[INFO]", "ℹ️")
            print("    " + l[:300])
        if len(shown) > limit:
            print("    … y %d líneas más" % (len(shown) - limit))
    print("  (registro completo: %s)" % log_path)
    sys.exit(1 if failed else 0)

cmd = sys.argv[1]
if cmd == "compose":
    compose(*sys.argv[2:6])
elif cmd == "body":
    body(sys.argv[2], sys.argv[3])
elif cmd == "field":
    field(sys.argv[2], sys.argv[3])
elif cmd == "error":
    api_error(sys.argv[2])
elif cmd == "logs":
    logs(sys.argv[2], sys.argv[3], sys.argv[4])
elif cmd == "report":
    report(*sys.argv[2:7])
PY

# ---------------------------------------------------------------------------
# Llamadas a Roblox
# ---------------------------------------------------------------------------
# http <método> <url> <salida> [archivo del cuerpo] -> escribe el código HTTP (000 si no hay red)
http() {
	local method="$1" url="$2" out="$3" data="${4:-}" code
	if [ -n "$data" ]; then
		code="$(curl -sS -o "$out" -w '%{http_code}' -X "$method" "$url" -H "@${HEADERS}" \
			-H 'Content-Type: application/json' --data-binary @"$data" 2>"$WORK/curl.err" || true)"
	else
		code="$(curl -sS -o "$out" -w '%{http_code}' -X "$method" "$url" -H "@${HEADERS}" 2>"$WORK/curl.err" || true)"
	fi
	echo "${code:-000}"
}

# Explica en castellano un error HTTP de Roblox y dice si merece la pena reintentar (código 0)
explain() { # explain <código> <respuesta> <qué se hacía>
	local code="$1" out="$2" what="$3" msg
	msg="$(python3 "$HELPER" error "$out")"
	case "$code" in
		000) echo "  ❌ Sin conexión con apis.roblox.com al $what ($(head -c 200 "$WORK/curl.err" 2>/dev/null))." ;;
		400) echo "  ❌ Roblox no acepta la petición al $what: $msg" ;;
		401) echo "  ❌ La clave ROBLOX_API_KEY no vale (caducada, borrada o mal copiada): $msg" ;;
		403)
			echo "  ❌ La clave no tiene permiso para ejecutar Luau en este juego ($msg)."
			echo "     Arréglalo en create.roblox.com → Open Cloud → API Keys → tu clave → Access Permissions:"
			echo "       • API System «luau-execution-sessions» → experiencia «Real Life Simulator» (universo $UNIVERSE)"
			echo "         → operación «write» (en la documentación: universe.place.luau-execution-session:write)."
			echo "       • Si la clave tiene «Accepted IP Addresses», añade la IP de esta máquina (o 0.0.0.0/0)."
			echo "     Guarda la clave (los cambios pueden tardar unos minutos) y vuelve a lanzar este script."
			;;
		404) echo "  ❌ Roblox no encuentra el juego o la versión (universo $UNIVERSE, lugar $PLACE${VERSION:+, versión $VERSION}): $msg" ;;
		429) echo "  ⏳ Roblox dice que hay demasiadas pruebas a la vez (máximo 10 sin terminar por lugar): $msg" ;;
		5*) echo "  ⏳ Roblox ha fallado ($code) al $what: $msg" ;;
		*) echo "  ❌ Respuesta inesperada ($code) al $what: $msg" ;;
	esac
}

retryable() { [ "$1" = "000" ] || [ "$1" = "429" ] || [ "${1:0:1}" = "5" ]; }

if [ -n "$VERSION" ]; then
	CREATE_URL="$API/universes/$UNIVERSE/places/$PLACE/versions/$VERSION/luau-execution-session-tasks"
	TARGET="versión $VERSION"
else
	CREATE_URL="$API/universes/$UNIVERSE/places/$PLACE/luau-execution-session-tasks"
	TARGET="última versión publicada"
fi

# run_test <nombre> -> 0 bien, 1 falla, 2 no se pudo probar, 3 no se puede probar ninguna (clave, permiso o red)
run_test() {
	local name="$1" script="$WORK/$1.luau" body="$WORK/$1.json" out="$WORK/$1.out" task="$WORK/$1.task"
	local log="$LOGDIR/$1.log" code path state tries start elapsed dots token
	echo
	echo "━━━ $name ($TARGET) ━━━"
	python3 "$HELPER" compose "$DIR/_comun.luau" src/server/Main.server.luau "$DIR/$name.luau" "$script" >/dev/null
	local size
	size="$(wc -c < "$script")"
	if [ "$size" -gt 4000000 ]; then
		echo "  ❌ El script ocupa $size bytes (Roblox acepta hasta 4 MB)."
		return 2
	fi
	# Si está Lune, se comprueba antes que el script compila (así no se gasta una prueba en Roblox)
	if command -v lune >/dev/null 2>&1; then
		mkdir -p "$WORK/check-$name" && cp "$script" "$WORK/check-$name/"
		if ! lune run scripts/test-compile.luau "$WORK/check-$name" > "$WORK/check.out" 2>&1; then
			echo "  ❌ El script no compila (líneas desplazadas $(($(wc -l < "$DIR/_comun.luau") + 2)) por _comun.luau):"
			sed -n 's|^.*\.luau: |     |p' "$WORK/check.out" | head -5
			return 1
		fi
	fi
	python3 "$HELPER" body "$script" "$body"

	# 1) Crear la tarea (con reintentos si Roblox está ocupado)
	tries=0
	while :; do
		code="$(http POST "$CREATE_URL" "$out" "$body")"
		[ "${code:0:1}" = "2" ] && break
		explain "$code" "$out" "crear la prueba"
		{ [ "$code" = "401" ] || [ "$code" = "403" ]; } && return 3
		tries=$((tries + 1))
		if [ "$code" = "000" ] && [ "$tries" -ge 2 ]; then
			return 3 # sin red: tampoco irán las demás
		fi
		if retryable "$code" && [ "$tries" -lt 6 ]; then
			echo "     Reintento en $((tries * 10)) s…"
			sleep $((tries * 10))
			continue
		fi
		return 2
	done
	path="$(python3 "$HELPER" field "$out" path)"
	if [ -z "$path" ]; then
		echo "  ❌ Roblox no ha devuelto la tarea: $(head -c 300 "$out")"
		return 2
	fi

	# 2) Esperar a que termine
	printf '  En marcha en Roblox'
	start="$(date +%s)"
	state=""
	dots=0
	while :; do
		sleep 3
		code="$(http GET "$API/$path" "$task")"
		if [ "${code:0:1}" = "2" ]; then
			state="$(python3 "$HELPER" field "$task" state)"
			case "$state" in COMPLETE | FAILED | CANCELLED) break ;; esac
		elif ! retryable "$code"; then
			echo
			explain "$code" "$task" "consultar la prueba"
			return 2
		fi
		elapsed=$(($(date +%s) - start))
		if [ "$elapsed" -ge "$POLL_MAX" ]; then
			echo
			echo "  ⏰ La prueba lleva ${elapsed} s sin terminar (estado: ${state:-desconocido}); se deja de esperar."
			echo "     Roblox la corta sola a los 5 minutos. Mírala luego en: $API/$path (con la misma clave)"
			return 2
		fi
		dots=$((dots + 1))
		[ $((dots % 5)) -eq 0 ] && printf ' %ss' "$elapsed" || printf '.'
	done
	echo " → $state en $(($(date +%s) - start)) s"

	# 3) Registros (lo que salió en la consola del servidor)
	: > "$log"
	token=""
	for _ in $(seq 1 20); do
		local url="$API/$path/logs?view=STRUCTURED&maxPageSize=10000"
		[ -n "$token" ] && url="$url&pageToken=$token"
		code="$(http GET "$url" "$out")"
		if [ "${code:0:1}" != "2" ]; then
			echo "  (no se han podido leer los registros: HTTP $code)" >> "$log"
			break
		fi
		python3 "$HELPER" logs "$out" "$log" "$WORK/token"
		token="$(cat "$WORK/token")"
		[ -z "$token" ] && break
	done

	# 4) Resultado
	# (la prueba va detrás de _comun.luau y de una línea: sus líneas van desplazadas)
	python3 "$HELPER" report "$name" "$task" "$log" "$VERBOSE" "$(($(wc -l < "$DIR/_comun.luau") + 2))"
}

echo "🧪 Pruebas en los servidores de Roblox: ${NAMES[*]}"
echo "   Juego: universo $UNIVERSE, lugar $PLACE ($TARGET). Cada prueba tarda de 1 a 5 minutos."
FAILED=()
BROKEN=()
PASSED=()
for name in "${NAMES[@]}"; do
	set +e
	run_test "$name"
	rc=$?
	set -e
	case "$rc" in
		0) PASSED+=("$name") ;;
		1) FAILED+=("$name") ;;
		3)
			# Sin clave válida, sin permiso o sin red no tiene sentido seguir con las demás
			BROKEN+=("$name")
			break
			;;
		*) BROKEN+=("$name") ;;
	esac
done

echo
echo "━━━ Resumen ━━━"
[ "${#PASSED[@]}" -gt 0 ] && echo "  ✅ Bien: ${PASSED[*]}"
[ "${#FAILED[@]}" -gt 0 ] && echo "  ❌ Fallan: ${FAILED[*]}"
[ "${#BROKEN[@]}" -gt 0 ] && echo "  ⛔ No se han podido probar: ${BROKEN[*]}"
if [ "${#BROKEN[@]}" -gt 0 ]; then
	exit 2
elif [ "${#FAILED[@]}" -gt 0 ]; then
	exit 1
fi
echo "  Todo correcto."
