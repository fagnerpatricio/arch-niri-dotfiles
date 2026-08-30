# Arch Linux + Niri + Noctalia --- Dotfiles

Configuração pessoal para padronizar minhas instalações do **Arch
Linux** usando **Niri**, **Noctalia**, **Kitty**, **Bash** e
**Starship**.

O objetivo deste repositório é manter uma base comum entre minhas
máquinas. As configurações ficam versionadas no Git e o `install.sh`
instala os componentes comuns e cria links simbólicos para os dotfiles.

> Pacotes e aplicações específicos de cada computador não fazem parte
> deste repositório. O **Paru** é instalado como helper do AUR, mas
> nenhum pacote AUR adicional é instalado automaticamente.

------------------------------------------------------------------------

## Stack

A configuração base utiliza:

-   **Arch Linux**
-   **Niri** --- compositor Wayland
-   **Noctalia** --- shell/interface do desktop
-   **Kitty** --- terminal
-   **Bash** --- shell
-   **Starship** --- prompt
-   **JetBrains Mono Nerd Font** --- fonte do terminal
-   **Micro** --- editor de texto
-   **Paru** --- helper para o AUR

Ferramentas de terminal utilizadas pelo `.bashrc`:

-   `bash-completion`
-   `fzf`
-   `zoxide`
-   `eza`
-   `bat`
-   `ripgrep`

Integrações utilizadas pelos atalhos do Niri incluem ferramentas como:

-   Firefox
-   Nautilus
-   WirePlumber (`wpctl`)
-   Playerctl
-   Brightnessctl

------------------------------------------------------------------------

## Estrutura do repositório

``` text
arch-niri-dotfiles/
├── install.sh
├── .gitignore
├── README.md
└── home/
    ├── .bashrc
    ├── .bash_profile
    └── .config/
        ├── niri/
        │   └── config.kdl
        ├── kitty/
        │   ├── kitty.conf
        │   └── current-theme.conf
        └── starship.toml
```

O Micro não possui configuração personalizada relevante neste
repositório.

------------------------------------------------------------------------

## Como funciona

O repositório funciona como a fonte principal das configurações.

O `install.sh`:

1.  verifica se o sistema é Arch Linux;
2.  atualiza o sistema;
3.  instala os pacotes oficiais necessários;
4.  instala o Paru, caso ainda não esteja disponível;
5.  preserva configurações existentes em um diretório de backup;
6.  cria links simbólicos entre `$HOME` e os arquivos deste repositório;
7.  verifica os principais comandos após a instalação.

Por exemplo:

``` text
~/.config/niri/config.kdl
        ↓
~/WorkSpace/arch-niri-dotfiles/home/.config/niri/config.kdl
```

Dessa forma, editar normalmente:

``` bash
micro ~/.config/niri/config.kdl
```

também altera o arquivo versionado pelo Git.

------------------------------------------------------------------------

## Instalação em uma nova máquina

### 1. Instalar o Git

Em uma instalação nova do Arch:

``` bash
sudo pacman -S git
```

### 2. Configurar o Git

Caso ainda não tenha configurado sua identidade:

``` bash
git config --global user.name "Seu Nome"
git config --global user.email "seu-email@example.com"
```

Confira:

``` bash
git config --global --list
```

------------------------------------------------------------------------

## Configurar acesso SSH ao GitHub

Recomenda-se usar uma chave **Ed25519** diferente para cada máquina.

Crie a chave:

``` bash
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519 -C "seu-email@example.com"
```

É recomendável proteger a chave privada com uma passphrase.

Mostre a chave pública:

``` bash
cat ~/.ssh/id_ed25519.pub
```

Adicione o conteúdo da chave pública à sua conta do GitHub em:

**Settings → SSH and GPG keys → New SSH key**

Use um título que identifique a máquina, por exemplo:

``` text
arch-papagaio
```

Teste a autenticação:

``` bash
ssh -T git@github.com
```

Uma autenticação bem-sucedida retorna uma mensagem semelhante a:

``` text
Hi usuario! You've successfully authenticated, but GitHub does not provide shell access.
```

------------------------------------------------------------------------

## Clonar o repositório

Crie o diretório de trabalho, se necessário:

``` bash
mkdir -p ~/WorkSpace
cd ~/WorkSpace
```

Clone:

``` bash
git clone git@github.com:fagnerpatricio/arch-niri-dotfiles.git
```

Entre no repositório:

``` bash
cd arch-niri-dotfiles
```

------------------------------------------------------------------------

## Executar a instalação

Garanta que o script seja executável:

``` bash
chmod +x install.sh
```

Execute como **usuário normal**:

``` bash
./install.sh
```

Não execute:

``` bash
sudo ./install.sh
```

O próprio script utiliza `sudo` somente nas operações que precisam de
privilégios administrativos.

------------------------------------------------------------------------

## Paru

O Paru faz parte da configuração base e é instalado automaticamente caso
não exista.

O instalador prepara as dependências necessárias, obtém o PKGBUILD do
AUR e compila o Paru.

Nenhum outro pacote AUR é instalado automaticamente.

Depois da instalação, cada máquina pode ter seu próprio conjunto de
aplicações:

``` bash
paru -S nome-do-pacote
```

Para atualizar os pacotes oficiais e os pacotes instalados pelo AUR:

``` bash
paru -Syu
```

------------------------------------------------------------------------

## Bash

Os arquivos versionados são:

``` text
~/.bashrc
~/.bash_profile
```

O `.bashrc` configura, entre outras coisas:

-   histórico persistente;
-   Bash Completion;
-   FZF;
-   Zoxide;
-   Starship;
-   aliases com `eza`;
-   ferramentas CLI;
-   funções auxiliares.

O editor padrão é o Micro:

``` bash
export EDITOR=micro
export VISUAL=micro
```

------------------------------------------------------------------------

## Starship

A configuração fica em:

``` text
~/.config/starship.toml
```

O prompt exibe informações como:

-   diretório atual;
-   branch e estado do Git;
-   Rust;
-   Python;
-   Node.js;
-   duração de comandos;
-   estado do último comando.

O prompt utiliza glifos de Nerd Fonts.

------------------------------------------------------------------------

## JetBrains Mono Nerd Font

O terminal utiliza **JetBrains Mono Nerd Font**.

No Kitty:

``` conf
font_family JetBrainsMono Nerd Font
```

A variante Nerd Font é importante porque o Starship utiliza vários
símbolos especiais no prompt.

------------------------------------------------------------------------

## Kitty

Arquivos versionados:

``` text
~/.config/kitty/kitty.conf
~/.config/kitty/current-theme.conf
```

O Kitty possui configurações para:

-   JetBrains Mono Nerd Font;
-   tamanho da fonte;
-   cursor;
-   padding;
-   scrollback;
-   abas;
-   layouts;
-   atalhos;
-   tema.

Os atalhos padrão de copiar e colar do terminal são preservados,
inclusive o comportamento tradicional de `Ctrl+C` para enviar `SIGINT`.

------------------------------------------------------------------------

## Niri

A configuração principal fica em:

``` text
~/.config/niri/config.kdl
```

Entre as configurações mantidas estão:

-   teclado brasileiro ABNT2;
-   Num Lock;
-   touchpad;
-   layout das janelas;
-   atalhos;
-   integração com Noctalia;
-   terminal Kitty;
-   controle de volume;
-   controle de mídia;
-   controle de brilho;
-   regras de janelas;
-   screenshots;
-   inicialização do Noctalia.

------------------------------------------------------------------------

## Inicialização automática do Niri

O `.bash_profile` carrega o `.bashrc`:

``` bash
[[ -f ~/.bashrc ]] && . ~/.bashrc
```

E inicia o Niri automaticamente quando o login ocorre no `tty1` e ainda
não existe uma sessão Wayland:

``` bash
if [[ "$(tty)" == "/dev/tty1" ]] && [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
    exec /usr/bin/niri-session -l
fi
```

Assim, o Niri é iniciado a partir da sessão do usuário no TTY1.

> O mecanismo responsável por realizar ou solicitar o login no TTY1 é
> uma configuração separada do sistema e não é criado apenas por este
> `.bash_profile`.

------------------------------------------------------------------------

## Backups

Antes de substituir uma configuração existente, o instalador cria um
backup em:

``` text
~/.dotfiles-backup/
```

Cada execução que precisar preservar arquivos utiliza um diretório com
data e hora, por exemplo:

``` text
~/.dotfiles-backup/20260830-103000/
```

Isso permite recuperar configurações anteriores caso seja necessário.

------------------------------------------------------------------------

## Atualizando as configurações

Como os arquivos em `$HOME` são links simbólicos para o repositório,
basta editar normalmente.

Exemplo:

``` bash
micro ~/.config/niri/config.kdl
```

Depois:

``` bash
cd ~/WorkSpace/arch-niri-dotfiles

git status
git add .
git commit -m "Atualiza configuração do Niri"
git push
```

------------------------------------------------------------------------

## Atualizando outra máquina

Na outra máquina:

``` bash
cd ~/WorkSpace/arch-niri-dotfiles
git pull
```

Como os dotfiles estão ligados simbolicamente ao repositório, as
alterações entram em vigor diretamente nos arquivos versionados.

Dependendo do programa, pode ser necessário recarregar a configuração ou
reiniciar a sessão.

------------------------------------------------------------------------

## Fluxo de trabalho

### Máquina onde a configuração foi alterada

``` bash
cd ~/WorkSpace/arch-niri-dotfiles

git status
git add .
git commit -m "Descrição da alteração"
git push
```

### Demais máquinas

``` bash
cd ~/WorkSpace/arch-niri-dotfiles

git pull
```

------------------------------------------------------------------------

## O que não pertence à base comum

Este repositório não tenta deixar todas as máquinas absolutamente
idênticas.

Aplicações específicas de cada computador podem ser instaladas
separadamente.

Em especial:

-   nenhum pacote AUR adicional é imposto pelo repositório;
-   históricos e caches não são versionados;
-   o histórico do Micro não é versionado;
-   configurações sem personalização não precisam ser copiadas;
-   software específico de trabalho, jogos ou hardware pode variar entre
    as máquinas.

A ideia é padronizar o **ambiente base**, sem impedir que cada
computador tenha sua própria função.

------------------------------------------------------------------------

## Manutenção

Antes de enviar alterações:

``` bash
git status
```

Para visualizar diferenças:

``` bash
git diff
```

Para registrar:

``` bash
git add .
git commit -m "Descrição da alteração"
git push
```

Para receber alterações feitas em outra máquina:

``` bash
git pull
```

------------------------------------------------------------------------

## Objetivo

Manter uma instalação Arch Linux simples, reproduzível e consistente,
com:

``` text
Arch Linux
   │
   ├── Niri
   │    └── Noctalia
   │
   └── Kitty
        └── Bash
             ├── Starship
             ├── Zoxide
             ├── FZF
             ├── Eza
             ├── Bat
             └── Ripgrep
```

Com os dotfiles centralizados no Git, uma nova máquina pode receber a
mesma base de configuração executando o `install.sh`, enquanto
diferenças específicas de hardware ou finalidade permanecem
independentes.
