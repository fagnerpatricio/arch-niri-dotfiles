#
# ~/.bashrc
#

# ============================================================
# BASH - INTERATIVO
# ============================================================

# Só continua em shells interativos
[[ $- != *i* ]] && return

# Histórico
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=100000
HISTFILESIZE=200000
HISTTIMEFORMAT='%F %T  '

shopt -s histappend
shopt -s checkwinsize
shopt -s autocd
shopt -s dirspell
shopt -s cmdhist
shopt -s lithist

# Salva histórico a cada comando
PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# Editor
export EDITOR=micro
export VISUAL=micro

# Pager
export PAGER=less
export LESS='-R --mouse'

# ============================================================
# COMPLETION
# ============================================================

if [[ -r /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
fi

# ============================================================
# FZF
# ============================================================

if [[ -f /usr/share/fzf/key-bindings.bash ]]; then
    source /usr/share/fzf/key-bindings.bash
fi

if [[ -f /usr/share/fzf/completion.bash ]]; then
    source /usr/share/fzf/completion.bash
fi

# ============================================================
# ZOXIDE
# ============================================================

eval "$(zoxide init bash)"

# ============================================================
# STARSHIP
# ============================================================

eval "$(starship init bash)"

# ============================================================
# ALIASES
# ============================================================

alias ls='eza --group-directories-first'
alias ll='eza -lah --group-directories-first --git'
alias la='eza -a --group-directories-first'
alias lt='eza --tree --level=2 --group-directories-first'

alias bat='bat'
alias rg='rg'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias cls='clear'
alias c='clear'

alias df='df -h'
alias du='du -h'
alias free='free -h'

alias ip='ip -c'

alias pac='sudo pacman'
alias pacs='pacman -Ss'
alias paci='sudo pacman -S'
alias pacr='sudo pacman -Rns'
alias pacu='sudo pacman -Syu'

# ============================================================
# FUNÇÕES ÚTEIS
# ============================================================

mkcd() {
    mkdir -p "$1" && cd "$1"
}

extract() {
    if [[ ! -f "$1" ]]; then
        echo "Arquivo não encontrado: $1"
        return 1
    fi

    case "$1" in
        *.tar.bz2) tar xjf "$1" ;;
        *.tar.gz)  tar xzf "$1" ;;
        *.tar.xz)  tar xJf "$1" ;;
        *.tar.zst) tar --zstd -xf "$1" ;;
        *.bz2)     bunzip2 "$1" ;;
        *.gz)      gunzip "$1" ;;
        *.zip)     unzip "$1" ;;
        *.7z)      7z x "$1" ;;
        *.rar)     unrar x "$1" ;;
        *) echo "Formato não suportado: $1" ;;
    esac
}

# If not running interactively, don't do anything
#[[ $- != *i* ]] && return

#alias ls='ls --color=auto'
#alias grep='grep --color=auto'
#PS1='[\u@\h \W]\$ '
