#!/usr/bin/env bash
# Instala o actualiza componentes sueltos de Evilnagi GNOME Team.
#
#   curl -fsSL https://raw.githubusercontent.com/jlcampana/evilnagi-gnome-team/main/componente.sh | bash -s -- transparencias
#
# Este archivo es el que se ejecuta dentro del repo (componente.sh solo lo descarga y lo
# llama). También se puede lanzar desde un clon: ./bin/componente.sh transparencias
set -euo pipefail

RAIZ="$(cd "$(dirname "$(realpath "$0")")/.." && pwd)"
# shellcheck source=../lib/comun.sh
. "$RAIZ/lib/comun.sh"
# shellcheck source=../lib/paquetes.sh
. "$RAIZ/lib/paquetes.sh"
# shellcheck source=../lib/tema.sh
. "$RAIZ/lib/tema.sh"
# shellcheck source=../lib/ajustes-gnome.sh
. "$RAIZ/lib/ajustes-gnome.sh"
# shellcheck source=../lib/descargas.sh
. "$RAIZ/lib/descargas.sh"
# shellcheck source=../lib/componentes.sh
. "$RAIZ/lib/componentes.sh"

uso() {
    cat <<EOF
Evilnagi GNOME Team — instalar o actualizar componentes sueltos

Uso:
  curl -fsSL $RAW/componente.sh | bash -s -- <componente>...
  ./bin/componente.sh <componente>...        (desde un clon)

Sin componentes, enseña la lista y pregunta cuáles.

Opciones:
  --si                no preguntar (hace falta decir los componentes)
  --lista             enseña los componentes y sale
  --portatil          equipo portátil (para «extensiones»: sin Soft Brightness Plus)
  --sobremesa         equipo de sobremesa
  -h, --ayuda         esta ayuda

Componentes:
$(listar_componentes)

Cada componente instala también lo que necesita. Lo que sobrescribe se guarda antes en
~/backups/evilnagi-gnome-team-<fecha>/.
EOF
}

ELEGIDOS=()
while (( $# )); do
    case "$1" in
        --si|-y)           ASUMIR=1 ;;
        --lista)           listar_componentes; exit 0 ;;
        --portatil)        EQUIPO=portatil ;;
        --sobremesa)       EQUIPO=sobremesa ;;
        -h|--ayuda|--help) uso; exit 0 ;;
        -*) morir "opción desconocida: $1 (usa --ayuda)" ;;
        *)  IFS=', ' read -ra trozos <<<"$1"; ELEGIDOS+=("${trozos[@]}") ;;
    esac
    shift
done

(( EUID == 0 )) && [[ ${HOME:-} == /root ]] &&
    morir "no lo ejecutes con sudo: pide permisos solo cuando hace falta"

export PATH="$HOME/.local/bin:$HOME/scripts:$PATH"

paso "Evilnagi GNOME Team · componentes"
detectar_sistema

# Sin componentes: lista y pregunta (por número o por nombre).
if (( ${#ELEGIDOS[@]} == 0 )); then
    (( ASUMIR )) && morir "con --si hay que decir qué componentes (usa --lista)"
    echo
    listar_componentes
    echo
    leer_tty respuesta "Componentes a instalar o actualizar (números o nombres, separados por espacios): " ""
    mapfile -t nombres < <(nombres_componentes)
    for r in ${respuesta//,/ }; do
        if [[ $r =~ ^[0-9]+$ ]] && (( r >= 1 && r <= ${#nombres[@]} )); then
            ELEGIDOS+=("${nombres[r - 1]}")
        else
            ELEGIDOS+=("$r")
        fi
    done
    (( ${#ELEGIDOS[@]} )) || { echo "Nada que hacer."; exit 0; }
fi

for c in "${ELEGIDOS[@]}"; do
    existe_componente "$c" || morir "componente desconocido: $c (usa --lista)"
done

if (( ASUMIR == 0 )); then
    echo
    info "Se va a instalar o actualizar: ${ELEGIDOS[*]}"
    preguntar_si "¿Continuar? [S/n]" s || { echo "Cancelado."; exit 0; }
fi

fallos=() shell=0
for c in "${ELEGIDOS[@]}"; do
    instalar_componente "$c" || fallos+=("$c")
    [[ $COMPONENTES_SHELL == *" $c "* ]] && shell=1
done

paso "Listo"
[[ -d $BACKUP ]] && info "Copia de lo anterior: $BACKUP"
(( ${#fallos[@]} )) && aviso "con errores: ${fallos[*]}"
(( shell )) && info "Cierra sesión y vuelve a entrar para que GNOME cargue los cambios de sus extensiones."
exit 0
