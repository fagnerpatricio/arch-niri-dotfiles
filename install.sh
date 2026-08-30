#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# ARCH + NIRI + NOCTALIA
# Instalador da configuração pessoal
# ============================================================

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${REPO_DIR}/home"

BACKUP_ROOT="${HOME}/.dotfiles-backup"
BACKUP_DIR="${BACKUP_ROOT}/$(date +%Y%m%d-%H%M%S)"

# ============================================================
# CORES
# ============================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    RESET=''
fi

info() {
    printf "${BLUE}==>${RESET} %s\n" "$*"
}

success() {
    printf "${GREEN}==>${RESET} %s\n" "$*"
}

warning() {
    printf "${YELLOW}Aviso:${RESET} %s\n" "$*"
}

error() {
    printf "${RED}Erro:${RESET} %s\n" "$*" >&2
}

# ============================================================
# PACOTES OFICIAIS
# ============================================================

PACKAGES=(
    # --------------------------------------------------------
    # Base
    # --------------------------------------------------------
    git
    base-devel

    # --------------------------------------------------------
    # Ambiente gráfico
    # --------------------------------------------------------
    niri
    noctalia

    # --------------------------------------------------------
    # Terminal / Shell
    # --------------------------------------------------------
    kitty
    starship
    bash-completion
    fzf
    zoxide

    # --------------------------------------------------------
    # Ferramentas CLI
    # --------------------------------------------------------
    eza
    bat
    ripgrep

    # --------------------------------------------------------
    # Editor
    # --------------------------------------------------------
    micro

    # --------------------------------------------------------
    # Fonte
    # --------------------------------------------------------
    ttf-jetbrains-mono-nerd

    # --------------------------------------------------------
    # Aplicações usadas pelo config.kdl
    # --------------------------------------------------------
    firefox
    nautilus
    fuzzel
    swaylock

    # --------------------------------------------------------
    # Áudio / multimídia / brilho
    # --------------------------------------------------------
    wireplumber
    playerctl
    brightnessctl

    # --------------------------------------------------------
    # Ferramentas usadas pela função extract() do .bashrc
    # --------------------------------------------------------
    unzip
    7zip
    unrar
)

# ============================================================
# VALIDAÇÕES
# ============================================================

validate_system() {
    if [[ ! -f /etc/arch-release ]]; then
        error "Este instalador foi criado exclusivamente para Arch Linux."
        exit 1
    fi

    if ! command -v pacman >/dev/null 2>&1; then
        error "pacman não encontrado."
        exit 1
    fi

    if [[ ${EUID} -eq 0 ]]; then
        error "Não execute este script como root."
        error "Execute como usuário normal; sudo será usado quando necessário."
        exit 1
    fi
}

# ============================================================
# ATUALIZAÇÃO DO SISTEMA
# ============================================================

update_system() {
    info "Atualizando o sistema..."

    sudo pacman -Syu --noconfirm

    success "Sistema atualizado."
}

# ============================================================
# PACOTES PACMAN
# ============================================================

install_packages() {
    local missing=()

    info "Verificando pacotes oficiais..."

    for package in "${PACKAGES[@]}"; do
        if ! pacman -Q "$package" >/dev/null 2>&1; then
            missing+=("$package")
        fi
    done

    if (( ${#missing[@]} == 0 )); then
        success "Todos os pacotes oficiais já estão instalados."
        return
    fi

    echo
    info "Pacotes que serão instalados:"

    printf '  %s\n' "${missing[@]}"

    echo

    sudo pacman -S --needed --noconfirm "${missing[@]}"

    success "Pacotes oficiais instalados."
}

# ============================================================
# PARU
# ============================================================

install_paru() {
    if command -v paru >/dev/null 2>&1; then
        success "Paru já está instalado."
        return
    fi

    info "Instalando Paru..."

    # git e base-devel já fazem parte dos pacotes básicos,
    # mas garantimos novamente para permitir uso isolado
    # desta função.
    sudo pacman -S --needed --noconfirm git base-devel

    local tmp_dir

    tmp_dir="$(mktemp -d)"

    cleanup_paru() {
        rm -rf "$tmp_dir"
    }

    trap cleanup_paru RETURN

    git clone https://aur.archlinux.org/paru.git "${tmp_dir}/paru"

    (
        cd "${tmp_dir}/paru"

        makepkg -si --noconfirm
    )

    success "Paru instalado."
}

# ============================================================
# BACKUP
# ============================================================

backup_path() {
    local destination="$1"

    if [[ ! -e "$destination" && ! -L "$destination" ]]; then
        return
    fi

    local relative_path
    local backup_destination

    relative_path="${destination#"$HOME"/}"
    backup_destination="${BACKUP_DIR}/${relative_path}"

    mkdir -p "$(dirname "$backup_destination")"

    info "Backup: ${destination}"

    mv "$destination" "$backup_destination"
}

# ============================================================
# LINKS SIMBÓLICOS
# ============================================================

link_file() {
    local source="$1"
    local destination="$2"

    if [[ ! -e "$source" ]]; then
        warning "Arquivo não encontrado:"
        warning "  ${source}"
        return
    fi

    mkdir -p "$(dirname "$destination")"

    # --------------------------------------------------------
    # Já existe o link correto
    # --------------------------------------------------------

    if [[ -L "$destination" ]]; then
        local source_real
        local destination_real

        source_real="$(readlink -f "$source")"
        destination_real="$(readlink -f "$destination" 2>/dev/null || true)"

        if [[ "$source_real" == "$destination_real" ]]; then
            success "Já configurado: ${destination}"
            return
        fi
    fi

    # --------------------------------------------------------
    # Faz backup do arquivo existente
    # --------------------------------------------------------

    backup_path "$destination"

    # --------------------------------------------------------
    # Cria link
    # --------------------------------------------------------

    ln -s "$source" "$destination"

    success "${destination}"
}

# ============================================================
# DOTFILES
# ============================================================

install_dotfiles() {
    info "Instalando dotfiles..."

    # --------------------------------------------------------
    # Bash
    # --------------------------------------------------------

    link_file \
        "${DOTFILES_DIR}/.bashrc" \
        "${HOME}/.bashrc"

    link_file \
        "${DOTFILES_DIR}/.bash_profile" \
        "${HOME}/.bash_profile"

    # --------------------------------------------------------
    # Starship
    # --------------------------------------------------------

    link_file \
        "${DOTFILES_DIR}/.config/starship.toml" \
        "${HOME}/.config/starship.toml"

    # --------------------------------------------------------
    # Niri
    # --------------------------------------------------------

    link_file \
        "${DOTFILES_DIR}/.config/niri/config.kdl" \
        "${HOME}/.config/niri/config.kdl"

    # --------------------------------------------------------
    # Kitty
    # --------------------------------------------------------

    link_file \
        "${DOTFILES_DIR}/.config/kitty/kitty.conf" \
        "${HOME}/.config/kitty/kitty.conf"

    link_file \
        "${DOTFILES_DIR}/.config/kitty/current-theme.conf" \
        "${HOME}/.config/kitty/current-theme.conf"
}

# ============================================================
# VERIFICAÇÕES
# ============================================================

verify_installation() {
    echo
    info "Verificando instalação..."

    local commands=(
        niri
        noctalia
        kitty
        starship
        micro
        paru
        fzf
        zoxide
        eza
        bat
        rg
        playerctl
        brightnessctl
    )

    local command_name

    for command_name in "${commands[@]}"; do
        if command -v "$command_name" >/dev/null 2>&1; then
            printf "  [OK] %-20s\n" "$command_name"
        else
            printf "  [--] %-20s\n" "$command_name"
        fi
    done
}

# ============================================================
# RESUMO
# ============================================================

show_summary() {
    echo
    echo "============================================================"
    echo " Instalação concluída"
    echo "============================================================"
    echo

    echo "Dotfiles:"
    echo
    echo "  ~/.bashrc"
    echo "  ~/.bash_profile"
    echo "  ~/.config/starship.toml"
    echo "  ~/.config/niri/config.kdl"
    echo "  ~/.config/kitty/kitty.conf"
    echo "  ~/.config/kitty/current-theme.conf"
    echo

    echo "Paru:"
    echo
    echo "  Instalado como helper AUR."
    echo "  Nenhum pacote AUR adicional foi instalado."
    echo

    if [[ -d "$BACKUP_DIR" ]]; then
        echo "Backup:"
        echo
        echo "  ${BACKUP_DIR}"
        echo
    fi

    echo "Niri:"
    echo
    echo "  O ~/.bash_profile inicia automaticamente:"
    echo
    echo "      /usr/bin/niri-session -l"
    echo
    echo "  quando o login ocorre no TTY1."
    echo
}

# ============================================================
# MAIN
# ============================================================

main() {
    echo
    echo "============================================================"
    echo " Arch Linux + Niri + Noctalia"
    echo "============================================================"
    echo

    validate_system

    update_system

    install_packages

    install_paru

    install_dotfiles

    verify_installation

    show_summary
}

main "$@"
