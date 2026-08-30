#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${REPO_DIR}/home"
BACKUP_ROOT="${HOME}/.dotfiles-backup"
BACKUP_DIR="${BACKUP_ROOT}/$(date +%Y%m%d-%H%M%S)"
ENABLE_AUTOLOGIN="${ENABLE_AUTOLOGIN:-0}"

if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; RESET='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; RESET=''
fi

info(){ printf "${BLUE}==>${RESET} %s\n" "$*"; }
success(){ printf "${GREEN}==>${RESET} %s\n" "$*"; }
warning(){ printf "${YELLOW}Aviso:${RESET} %s\n" "$*"; }
error(){ printf "${RED}Erro:${RESET} %s\n" "$*" >&2; }
die(){ error "$*"; exit 1; }

BASE_PACKAGES=(
    base-devel git curl wget rsync openssh sudo pciutils
    niri noctalia xwayland-satellite
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome
    xdg-user-dirs xdg-utils shared-mime-info
    networkmanager
    bluez bluez-utils
    pipewire pipewire-alsa pipewire-pulse wireplumber
    upower power-profiles-daemon brightnessctl
    polkit gnome-keyring
    kitty starship bash-completion fzf zoxide
    eza bat ripgrep less
    micro
    ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
    firefox nautilus fuzzel swaylock playerctl
    gvfs gvfs-mtp udisks2
    wl-clipboard cliphist
    unzip 7zip unrar
    cups cups-filters ghostscript
    avahi nss-mdns
)

GRAPHICS_BASE_PACKAGES=(mesa vulkan-icd-loader)

validate_system(){
    [[ -f /etc/arch-release ]] || die "Este instalador foi criado para Arch Linux."
    command -v pacman >/dev/null 2>&1 || die "pacman não encontrado."
    [[ ${EUID} -ne 0 ]] || die "Execute este script como usuário normal, não como root."
    command -v sudo >/dev/null 2>&1 || die "sudo não está instalado. Instale/configure sudo antes de executar este script."
    sudo -v || die "Não foi possível obter privilégios com sudo."
    [[ -d "$DOTFILES_DIR" ]] || die "Diretório de dotfiles não encontrado: $DOTFILES_DIR"
    [[ -f "${DOTFILES_DIR}/.bashrc" ]] || die "Dotfile obrigatório ausente: home/.bashrc"
    [[ -f "${DOTFILES_DIR}/.bash_profile" ]] || die "Dotfile obrigatório ausente: home/.bash_profile"
}

update_system(){
    info "Atualizando o Arch Linux..."
    sudo pacman -Syu --noconfirm
    success "Sistema atualizado."
}

install_packages(){
    local packages=("$@") missing=() package
    for package in "${packages[@]}"; do
        pacman -Q "$package" >/dev/null 2>&1 || missing+=("$package")
    done
    (( ${#missing[@]} == 0 )) && return 0
    info "Instalando ${#missing[@]} pacote(s)..."
    printf '  %s\n' "${missing[@]}"
    sudo pacman -S --needed --noconfirm "${missing[@]}"
}

install_base(){
    info "Instalando a base do desktop..."
    install_packages "${BASE_PACKAGES[@]}"
    install_packages "${GRAPHICS_BASE_PACKAGES[@]}"
    success "Base do desktop instalada."
}

install_microcode(){
    local vendor
    vendor="$(grep -m1 '^vendor_id' /proc/cpuinfo 2>/dev/null | awk '{print $3}' || true)"
    case "$vendor" in
        GenuineIntel) info "CPU Intel detectada: instalando intel-ucode."; install_packages intel-ucode ;;
        AuthenticAMD) info "CPU AMD detectada: instalando amd-ucode."; install_packages amd-ucode ;;
        *) warning "Fabricante da CPU não identificado; microcode não foi alterado." ;;
    esac
}

install_graphics_driver(){
    local gpu_info
    local extra_packages=()
    gpu_info="$(lspci -nnk 2>/dev/null | grep -Ei 'VGA|3D|Display' || true)"
    if [[ -z "$gpu_info" ]]; then
        warning "Não foi possível identificar a GPU."
        return 0
    fi
    echo
    info "GPU(s) detectada(s):"
    printf '%s\n' "$gpu_info"
    echo
    grep -qiE 'Intel Corporation' <<< "$gpu_info" && extra_packages+=(vulkan-intel)
    grep -qiE 'AMD|ATI' <<< "$gpu_info" && extra_packages+=(vulkan-radeon)
    if grep -qiE 'NVIDIA' <<< "$gpu_info"; then
        warning "GPU NVIDIA detectada."
        warning "Instalando nvidia-open + nvidia-utils (adequado para Turing ou mais nova)."
        warning "Se a GPU for anterior a Turing, ajuste o driver manualmente."
        extra_packages+=(nvidia-open nvidia-utils)
    fi
    if (( ${#extra_packages[@]} > 0 )); then
        install_packages "${extra_packages[@]}"
        success "Drivers gráficos instalados."
    else
        warning "Nenhum driver Vulkan específico foi selecionado automaticamente."
    fi
}

install_paru(){
    if command -v paru >/dev/null 2>&1; then success "Paru já está instalado."; return 0; fi
    info "Instalando Paru..."
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru.git "${tmp_dir}/paru"
    ( cd "${tmp_dir}/paru" && makepkg -si --noconfirm )
    rm -rf "$tmp_dir"
    success "Paru instalado."
}

enable_service(){
    local service="$1"
    if systemctl list-unit-files "$service" >/dev/null 2>&1; then
        sudo systemctl enable --now "$service"
        success "Serviço ativo: $service"
    else
        warning "Unidade systemd não encontrada: $service"
    fi
}

enable_services(){
    info "Habilitando serviços do sistema..."
    enable_service NetworkManager.service
    enable_service bluetooth.service
    enable_service cups.service
    enable_service avahi-daemon.service
    enable_service power-profiles-daemon.service
    if systemctl list-unit-files fstrim.timer >/dev/null 2>&1; then
        sudo systemctl enable --now fstrim.timer
        success "Timer ativo: fstrim.timer"
    fi
}

setup_xdg_dirs(){
    if command -v xdg-user-dirs-update >/dev/null 2>&1; then
        info "Criando/atualizando diretórios padrão do usuário..."
        xdg-user-dirs-update
    fi
}

backup_path(){
    local destination="$1"
    [[ -e "$destination" || -L "$destination" ]] || return 0
    local relative_path backup_destination
    relative_path="${destination#"$HOME"/}"
    backup_destination="${BACKUP_DIR}/${relative_path}"
    mkdir -p "$(dirname "$backup_destination")"
    info "Backup: ${destination}"
    mv "$destination" "$backup_destination"
}

link_file(){
    local source="$1" destination="$2"
    if [[ ! -e "$source" ]]; then warning "Arquivo não encontrado no repositório: ${source}"; return 0; fi
    mkdir -p "$(dirname "$destination")"
    if [[ -L "$destination" ]]; then
        local source_real destination_real
        source_real="$(readlink -f "$source")"
        destination_real="$(readlink -f "$destination" 2>/dev/null || true)"
        if [[ "$source_real" == "$destination_real" ]]; then success "Já configurado: ${destination}"; return 0; fi
    fi
    backup_path "$destination"
    ln -s "$source" "$destination"
    success "${destination} -> ${source}"
}

install_dotfiles(){
    info "Aplicando dotfiles..."
    link_file "${DOTFILES_DIR}/.bashrc" "${HOME}/.bashrc"
    link_file "${DOTFILES_DIR}/.bash_profile" "${HOME}/.bash_profile"
    link_file "${DOTFILES_DIR}/.config/starship.toml" "${HOME}/.config/starship.toml"
    link_file "${DOTFILES_DIR}/.config/niri/config.kdl" "${HOME}/.config/niri/config.kdl"
    link_file "${DOTFILES_DIR}/.config/kitty/kitty.conf" "${HOME}/.config/kitty/kitty.conf"
    link_file "${DOTFILES_DIR}/.config/kitty/current-theme.conf" "${HOME}/.config/kitty/current-theme.conf"
}

configure_autologin(){
    if [[ "$ENABLE_AUTOLOGIN" != "1" ]]; then info "Autologin no tty1 permanece desabilitado."; return 0; fi
    local override_dir="/etc/systemd/system/getty@tty1.service.d"
    local override_file="${override_dir}/autologin.conf"
    info "Habilitando autologin de ${USER} no tty1..."
    sudo mkdir -p "$override_dir"
    sudo tee "$override_file" >/dev/null <<AUTLOGIN
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin ${USER} --noclear %I \$TERM
AUTLOGIN
    sudo systemctl daemon-reload
    success "Autologin configurado para ${USER} no tty1."
}

verify_command(){ command -v "$1" >/dev/null 2>&1 && printf '  [OK] %-24s\n' "$1" || printf '  [--] %-24s\n' "$1"; }
verify_service(){ systemctl is-enabled "$1" >/dev/null 2>&1 && printf '  [OK] %-24s\n' "$1" || printf '  [--] %-24s\n' "$1"; }

verify_installation(){
    echo; info "Verificando comandos principais..."
    local commands=(niri niri-session noctalia kitty starship micro paru nmcli bluetoothctl wpctl playerctl brightnessctl wl-copy cliphist firefox nautilus)
    local cmd
    for cmd in "${commands[@]}"; do verify_command "$cmd"; done
    echo; info "Verificando serviços..."
    local services=(NetworkManager.service bluetooth.service cups.service avahi-daemon.service power-profiles-daemon.service)
    local service
    for service in "${services[@]}"; do verify_service "$service"; done
}

show_summary(){
    echo
    echo "============================================================"
    echo " Arch Linux -> Niri + Noctalia concluído"
    echo "============================================================"
    echo
    echo "Base instalada: Niri, Noctalia, XWayland, portals, rede, Bluetooth,"
    echo "PipeWire, energia, Kitty, Starship, JetBrains Mono Nerd Font,"
    echo "Firefox, Nautilus, clipboard Wayland, impressão e Paru."
    echo
    if [[ -d "$BACKUP_DIR" ]]; then echo "Backup: ${BACKUP_DIR}"; echo; fi
    if [[ "$ENABLE_AUTOLOGIN" == "1" ]]; then
        echo "Autologin no tty1: habilitado para ${USER}"
    else
        echo "Autologin no tty1: desabilitado"
        echo "Faça login normalmente no tty1."
    fi
    echo
    echo "O ~/.bash_profile iniciará /usr/bin/niri-session -l no tty1."
    echo "Recomenda-se reiniciar o computador após a instalação."
}

on_error(){
    local exit_code=$?
    local line_number="${BASH_LINENO[0]:-desconhecida}"
    echo
    error "A instalação foi interrompida (código ${exit_code}, linha aproximada ${line_number})."
    error "Corrija o problema e execute novamente; o script foi feito para tolerar reexecução."
    exit "$exit_code"
}
trap on_error ERR

main(){
    echo
    echo "============================================================"
    echo " Arch Linux mínimo -> Niri + Noctalia"
    echo "============================================================"
    echo
    validate_system
    update_system
    install_base
    install_microcode
    install_graphics_driver
    install_paru
    enable_services
    setup_xdg_dirs
    install_dotfiles
    configure_autologin
    verify_installation
    show_summary
}

main "$@"
