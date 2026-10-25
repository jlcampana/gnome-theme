#!/usr/bin/env bash
# Evilnagi GNOME Team — instalar o actualizar componentes sueltos.
#
#   curl -fsSL https://raw.githubusercontent.com/jlcampana/evilnagi-gnome-team/main/componente.sh | bash -s -- transparencias
#   curl -fsSL https://raw.githubusercontent.com/jlcampana/evilnagi-gnome-team/main/componente.sh | bash   (pregunta cuáles)
#
# Dentro de un clon ejecuta bin/componente.sh; si no, descarga el repo igual que install.sh
# (que se encarga de eso) y lo ejecuta. Todo dentro de main(), como install.sh, para que
# funcione con `curl | bash`.
set -euo pipefail

REPO="${EVILNAGI_REPO:-jlcampana/evilnagi-gnome-team}"
RAMA="${EVILNAGI_RAMA:-main}"

main() {
    local aqui=""
    if [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]]; then
        aqui="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi
    if [[ -n $aqui && -f "$aqui/bin/componente.sh" ]]; then
        bash "$aqui/bin/componente.sh" "$@"
        return
    fi
    command -v curl >/dev/null 2>&1 ||
        { echo "ERROR: hace falta curl para descargar el instalador." >&2; exit 1; }
    local instalador
    instalador="$(curl -fsSL --retry 3 --retry-delay 2 "https://raw.githubusercontent.com/$REPO/$RAMA/install.sh")" ||
        { echo "ERROR: no se pudo descargar https://github.com/$REPO" >&2; exit 1; }
    EVILNAGI_ENTRADA=componente.sh bash -c "$instalador" install.sh "$@"
}

main "$@"
