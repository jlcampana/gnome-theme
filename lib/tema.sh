#!/usr/bin/env bash
# Aplicación del tema GNOME (iconos, GTK, Nautilus, extensiones y ajustes).
# Requiere lib/comun.sh cargado.
#
# Cada pieza del tema es una función tema_<pieza>. aplicar_tema las llama todas; componente.sh
# (lib/componentes.sh) las llama sueltas para instalar o actualizar una sola. Las piezas no
# vuelven a poner los valores por defecto de lo que el usuario ajusta luego (como el blur):
# eso solo lo hace aplicar_tema.

ejecutar() { # ejecutar <script> [argumentos...]
    local script="$1"; shift
    local ruta="$RAIZ/scripts/tema/$script"
    [[ -f $ruta ]] || { aviso "falta $ruta"; return 0; }
    if bash "$ruta" "$@"; then
        return 0
    fi
    aviso "$script terminó con errores (se continúa)"
    return 0
}

hay_1password() {
    [[ -f /usr/share/applications/1password.desktop ]] ||
    [[ -f "$HOME/.local/share/applications/1password.desktop" ]] ||
    command -v 1password >/dev/null 2>&1
}

hay_gtk_tweaks() {
    [[ -f /usr/share/applications/org.gnome.tweaks.desktop ]] ||
    [[ -f /var/lib/flatpak/exports/share/applications/org.gnome.tweaks.desktop ]] ||
    [[ -f "$HOME/.local/share/flatpak/exports/share/applications/org.gnome.tweaks.desktop" ]]
}

hay_dock() {
    extension_instalada dash-to-dock@micxgx.gmail.com ||
    extension_instalada ubuntu-dock@ubuntu.com ||
    gsettings list-schemas 2>/dev/null | grep -qx org.gnome.shell.extensions.dash-to-dock
}

copiar_scripts_tema() { # copiar_scripts_tema [script.sh...]  (sin argumentos, todos)
    local f
    mkdir -p "$HOME/scripts"
    if (( $# )); then
        for f in "$@"; do
            [[ -f "$RAIZ/scripts/tema/$f" ]] && poner "$RAIZ/scripts/tema/$f" "$HOME/scripts/$f"
        done
    else
        for f in "$RAIZ"/scripts/tema/*.sh; do
            poner "$f" "$HOME/scripts/$(basename "$f")"
        done
    fi
    chmod +x "$HOME"/scripts/*.sh 2>/dev/null || true
}

# --- Piezas del tema ------------------------------------------------------

tema_gtk() {
    info "GTK compacto y diálogos de confirmación…"
    ejecutar gtk-compacto.sh
    ejecutar dialogos-confirmacion.sh
}

tema_nautilus() {
    info "Nautilus compacto y sus extensiones (Abrir con gThumb, panel lateral estrecho)…"
    ejecutar nautilus-compacto.sh
    mkdir -p "$NPY_DIR"
    local f
    for f in abrir-con-gthumb.py panel-lateral-estrecho.py; do
        [[ -f "$RAIZ/tema/nautilus-python/$f" ]] && poner "$RAIZ/tema/nautilus-python/$f" "$NPY_DIR/$f"
    done
    ok "Extensiones de Nautilus: Abrir con gThumb y panel lateral estrecho"
}

tema_iconos() {
    info "Iconos MoreWaita y papelera de Tela-circle…"
    ejecutar instalar-morewaita.sh
    ejecutar papelera-tela.sh
    if hay_gtk_tweaks; then
        ejecutar icono-app.sh --retoques
    else
        info "Retoques no está instalado; se omite su icono"
    fi
    if hay_1password; then
        ejecutar icono-app.sh --1password-bandeja
    fi
}

# Transparencias trae su propio instalador: la extensión, opacidad-nautilus.py y nautilus-python
# si falta. Sus ajustes (opacidad, blur y nivel) van en dconf y se conservan.
tema_transparencias() {
    info "Extensión Transparencias (opacidad y blur de Nautilus y Ptyxis)…"
    ejecutar instalar-transparencias.sh
}

tema_reborde() {
    info "Reborde de ventanas (P7 Borders)…"
    ejecutar reborde-ventanas.sh
}

tema_barra_dock() {
    info "Barra superior y dock grises…"
    ejecutar barra-dock-gris.sh
}

tema_botones() {
    info "Botones de sesión y confirmación en rojo…"
    ejecutar botones-sesion-rojos.sh
}

tema_boton_aplicaciones() {
    if hay_dock; then
        info "Botón de aplicaciones con imagen en el dock…"
        ejecutar boton-aplicaciones.sh
    else
        info "No hay Dash to Dock/Ubuntu Dock; se omite el botón de aplicaciones"
    fi
}

tema_clic_bandeja() {
    if hay_1password; then
        info "Clic en el icono de 1Password de la bandeja…"
        ejecutar clic-bandeja.sh
    else
        info "1Password no está instalado; se omite el clic en la bandeja"
    fi
}

tema_terminal() {
    info "Terminal con el perfil MSX…"
    ejecutar terminal-msx.sh
}

# --- Todo el tema ---------------------------------------------------------

aplicar_tema() {
    paso "Tema de GNOME"
    tema_gtk
    tema_nautilus
    tema_iconos
    tema_transparencias
    # Valores por defecto de Transparencias: solo aquí (al actualizarla suelta no se vuelve a
    # poner el blur si el usuario lo quitó).
    info "Blur en Nautilus y Ptyxis…"
    ejecutar blur-ventanas.sh
    tema_reborde
    tema_barra_dock
    tema_botones
    tema_boton_aplicaciones
    if hay_1password; then
        tema_clic_bandeja
    fi
    tema_terminal

    copiar_scripts_tema
    ok "Scripts del tema instalados en ~/scripts"
    ok "Tema aplicado (cierra sesión para cargar las extensiones nuevas)"
}

instalar_extensiones_gnome() {
    paso "Extensiones de GNOME"
    ejecutar extensiones.sh "--$EQUIPO"
}
