# revisar-mallas.sh: la revisión de moderación ANTES de subir mallas (docs/bugs/moderacion/).
# Lo cargan (source) scripts/upload-{mar,puerto,invasion,asteroides,nave}.sh.
#
#   revisar_mallas <archivo.fbx>…   revisa con scripts/audit/moderacion-mallas.py --check las mallas que se
#                                   van a subir; si alguna está marcada (o no se puede revisar), el script
#                                   de subida PARA sin subir ninguna malla.
#
# El 20 oct 2026 Roblox retiró por «Contenido sexual» dos mallas de la v124 (un antebrazo y una pierna
# sueltos de los Vórtidos de cristal): cada aviso es una falta en la cuenta del dueño. No hay un «saltarse
# la revisión» general: tras mirar a mano la imagen de una malla marcada (docs/bugs/moderacion/revision/),
# se puede permitir ESA malla nombrando su archivo:  MODERACION_PERMITIR="Pilote,Fuselaje" bash scripts/…
revisar_mallas() {
	if [ "$#" -eq 0 ]; then
		echo "🔎 Revisión de moderación: no hay mallas nuevas que subir"
		return 0
	fi
	echo "🔎 Revisión de moderación de $# malla(s) antes de subir (scripts/audit/moderacion-mallas.py)"
	local code=0 log
	log="$(mktemp)"
	python3 scripts/audit/moderacion-mallas.py --check "$@" >"$log" 2>&1 || code=$?
	grep -v '^FBX version\|^$' "$log" || true
	rm -f "$log"
	case "$code" in
		0) echo "  ✅ nada que pare la subida" ;;
		2)
			echo "❌ Hay mallas marcadas: NO se sube ninguna malla (docs/bugs/moderacion/)."
			echo "   Arregla su forma en el script de Blender o, si tras mirar su imagen a mano no hay problema,"
			echo "   permítela por su nombre: MODERACION_PERMITIR=\"<Nombre>\" (sin un «permitir todo»)."
			exit 1
			;;
		*)
			echo "❌ No se han podido revisar las mallas (hace falta: pip install bpy==4.2.0 numpy). No se sube nada."
			exit 1
			;;
	esac
}
