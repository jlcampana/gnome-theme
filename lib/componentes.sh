#!/usr/bin/env bash
# Componentes que se pueden instalar o actualizar sueltos (componente.sh). Cada uno instala
# también lo que necesita (paquetes del sistema que falten) y copia a ~/scripts sus scripts.
# Requiere cargados lib/comun.sh, paquetes.sh, tema.sh, ajustes-gnome.sh y descargas.sh.

# nombre|descripción (en el orden en que se enseñan)
COMPONENTES=(
    "transparencias|Extensión Transparencias: opacidad y blur de Nautilus y Ptyxis (conserva sus ajustes)"
    "iconos|Iconos MoreWaita y papelera de Tela-circle"
    "gtk|GTK compacto estilo macOS y diálogos de confirmación"
    "nautilus|Nautilus compacto, Abrir con gThumb y panel lateral estrecho"
    "terminal|Ptyxis con el perfil MSX"
    "reborde|Reborde de 2 px en las ventanas (P7 Borders)"
    "barra-dock|Barra superior y dock grises"
    "botones|Botones de sesión y de confirmación en rojo"
    "boton-aplicaciones|Botón de aplicaciones con imagen en el dock"
    "clic-bandeja|Clic en el icono de 1Password de la bandeja"
    "extensiones|Extensiones de GNOME del tema y sus ajustes"
    "ajustes|Ajustes generales de GNOME (vuelve a poner los del tema)"
    "fondos|Fondos de pantalla en tu carpeta de imágenes"
    "fondos-animados|Fondos animados: vídeo de fondo, con su app y su extensión (gnome-animated-wallpaper)"
    "descargas|Scripts de descarga (ydl, yda, xdl, twitter, r34dl, allr34dl) y el reproductor tracker"
    "paquetes|Todos los paquetes del sistema del tema"
    "alias|Alias reload y open en ~/.bashrc"
)

# Los que cambian una extensión de GNOME Shell: hace falta cerrar sesión para verlos.
COMPONENTES_SHELL=" transparencias reborde barra-dock botones boton-aplicaciones clic-bandeja extensiones fondos-animados "

nombres_componentes() {
    local c
    for c in "${COMPONENTES[@]}"; do echo "${c%%|*}"; done
}

existe_componente() {
    nombres_componentes | grep -qx -- "$1"
}

listar_componentes() {
    local c i=1
    for c in "${COMPONENTES[@]}"; do
        printf '  %2d  %-19s %s\n' "$i" "${c%%|*}" "${c#*|}"
        i=$((i + 1))
    done
}

instalar_componente() { # instalar_componente <nombre>
    case "$1" in
        transparencias)
            paso "Transparencias"
            tema_transparencias
            copiar_scripts_tema instalar-transparencias.sh blur-ventanas.sh ;;
        iconos)
            paso "Iconos"
            asegurar_paquetes gtk-update-icon-cache
            tema_iconos
            copiar_scripts_tema instalar-morewaita.sh papelera-tela.sh icono-app.sh ;;
        gtk)
            paso "GTK"
            tema_gtk
            copiar_scripts_tema gtk-compacto.sh dialogos-confirmacion.sh ;;
        nautilus)
            paso "Nautilus"
            asegurar_paquetes "$(por_distro nautilus-python python3-nautilus)" gthumb
            tema_nautilus
            copiar_scripts_tema nautilus-compacto.sh
            nautilus -q 2>/dev/null || true ;;
        terminal)
            paso "Terminal"
            asegurar_paquetes ptyxis
            tema_terminal
            copiar_scripts_tema terminal-msx.sh ;;
        reborde)
            paso "Reborde de ventanas"
            tema_reborde
            copiar_scripts_tema reborde-ventanas.sh ;;
        barra-dock)
            paso "Barra y dock"
            tema_barra_dock
            copiar_scripts_tema barra-dock-gris.sh ;;
        botones)
            paso "Botones en rojo"
            tema_botones
            copiar_scripts_tema botones-sesion-rojos.sh ;;
        boton-aplicaciones)
            paso "Botón de aplicaciones"
            tema_boton_aplicaciones
            copiar_scripts_tema boton-aplicaciones.sh ;;
        clic-bandeja)
            paso "Clic en la bandeja"
            tema_clic_bandeja
            copiar_scripts_tema clic-bandeja.sh ;;
        extensiones)
            elegir_equipo
            instalar_extensiones_gnome
            copiar_scripts_tema extensiones.sh ;;
        ajustes)
            aplicar_ajustes_gnome ;;
        fondos)
            paso "Fondos de pantalla"
            instalar_wallpapers ;;
        fondos-animados)
            instalar_fondos_animados ;;
        descargas)
            if [[ $DISTRO == fedora ]]; then
                command -v ffmpeg >/dev/null 2>&1 || preparar_repos_fedora
                asegurar_paquetes ffmpeg openmpt123 python3-pip git
            else
                dpkg -s openmpt123 >/dev/null 2>&1 || preparar_repos_ubuntu
                asegurar_paquetes ffmpeg openmpt123 python3-pip python3-venv git
            fi
            instalar_descargas ;;
        paquetes)
            instalar_paquetes ;;
        alias)
            paso "Alias de ~/.bashrc"
            configurar_alias_bashrc
            ok "Alias listos" ;;
        *)
            error "componente desconocido: $1"
            return 1 ;;
    esac
}
