#!/usr/bin/env bash
set -euo pipefail

# ─── colors & symbols ───────────────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
RESET='\033[0m'
CHECK='✓'
CROSS='✗'
ARROW='▸'
DOT='○'
FILLED='●'

# ─── detect OS ───────────────────────────────────────────────────────────────
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_ID="${ID}"
        OS_LIKE="${ID_LIKE:-}"
    elif [[ "$(uname)" == "Darwin" ]]; then
        OS_ID="macos"
        OS_LIKE=""
    else
        OS_ID="unknown"
        OS_LIKE=""
    fi
}

is_debian() { [[ "$OS_ID" == "debian" || "$OS_ID" == "ubuntu" || "$OS_LIKE" == *"debian"* || "$OS_LIKE" == *"ubuntu"* ]]; }
is_fedora() { [[ "$OS_ID" == "fedora" || "$OS_LIKE" == *"fedora"* ]]; }
is_arch()   { [[ "$OS_ID" == "arch" || "$OS_LIKE" == *"arch"* ]]; }
is_macos()  { [[ "$OS_ID" == "macos" ]]; }

# ─── package list ────────────────────────────────────────────────────────────
# Format: "id|display_name|description|category"
PACKAGES=(
    "python|Python|Programming language (python3 + pip)|Dev Languages"
    "node|Node.js|JavaScript runtime (via NodeSource/Homebrew)|Dev Languages"
    "rust|Rust|Systems programming language (via rustup)|Dev Languages"
    "go|Go|Google's programming language|Dev Languages"
    "git|Git|Version control system|Dev Tools"
    "ruff|Ruff|Extremely fast Python linter & formatter|Dev Tools"
    "uv|uv|Blazing fast Python package manager|Dev Tools"
    "docker|Docker|Container platform|Dev Tools"
    "gh|GitHub CLI|GitHub on the command line|Dev Tools"
    "code|VS Code|Code editor by Microsoft|Editors"
    "neovim|Neovim|Hyperextensible Vim-based editor|Editors"
    "chrome|Google Chrome|Web browser by Google|Apps"
    "firefox|Firefox|Web browser by Mozilla|Apps"
    "curl|curl|Command-line HTTP client|CLI Utils"
    "wget|wget|Network downloader|CLI Utils"
    "jq|jq|JSON processor for the command line|CLI Utils"
    "ripgrep|ripgrep|Ultra-fast recursive search (rg)|CLI Utils"
    "fzf|fzf|Fuzzy finder for the terminal|CLI Utils"
    "tmux|tmux|Terminal multiplexer|CLI Utils"
    "htop|htop|Interactive process viewer|CLI Utils"
    "tree|tree|Directory listing as a tree|CLI Utils"
    "bat|bat|cat clone with syntax highlighting|CLI Utils"
    "eza|eza|Modern replacement for ls|CLI Utils"
    "zsh|Zsh|Z shell|CLI Utils"
)

NUM_PACKAGES=${#PACKAGES[@]}
declare -a SELECTED
for ((i = 0; i < NUM_PACKAGES; i++)); do SELECTED[$i]=0; done
CURSOR=0
SCROLL_OFFSET=0

# ─── terminal helpers ────────────────────────────────────────────────────────
get_term_height() { tput lines 2>/dev/null || echo 24; }

hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }
move_to() { printf '\033[%d;%dH' "$1" "$2"; }
clear_screen() { printf '\033[2J\033[H'; }
clear_line() { printf '\033[2K'; }

cleanup() {
    show_cursor
    stty sane 2>/dev/null
    tput rmcup 2>/dev/null
}
trap cleanup EXIT

# ─── TUI rendering ──────────────────────────────────────────────────────────
get_category() {
    local pkg="${PACKAGES[$1]}"
    echo "${pkg##*|}"
}

get_field() {
    local pkg="$1" idx="$2"
    echo "$pkg" | cut -d'|' -f"$idx"
}

draw_header() {
    move_to 1 1
    clear_line
    printf "${BOLD}${CYAN}"
    printf "  ┌─────────────────────────────────────────────────────────┐\n"
    clear_line
    printf "  │           ░█▀▄░█▀▄░▀█▀░█▀█░█▀▀░▀█▀░█▀█░█░░░█░░       │\n"
    clear_line
    printf "  │           ░█░█░█░█░░█░░█░█░▀▀█░░█░░█▀█░█░░░█░░       │\n"
    clear_line
    printf "  │           ░▀▀░░▀▀░░▀▀▀░▀░▀░▀▀▀░░▀░░▀░▀░▀▀▀░▀▀▀       │\n"
    clear_line
    printf "  └─────────────────────────────────────────────────────────┘${RESET}\n"
    clear_line
    printf "${DIM}   Use ${RESET}↑/↓${DIM} to move, ${RESET}Space${DIM} to select, ${RESET}a${DIM} to toggle all, ${RESET}Enter${DIM} to install, ${RESET}q${DIM} to quit${RESET}\n"
    printf "\n"
}

HEADER_LINES=8

draw_list() {
    local term_h
    term_h=$(get_term_height)
    local visible=$((term_h - HEADER_LINES - 3))
    if ((visible < 5)); then visible=5; fi

    if ((CURSOR < SCROLL_OFFSET)); then
        SCROLL_OFFSET=$CURSOR
    elif ((CURSOR >= SCROLL_OFFSET + visible)); then
        SCROLL_OFFSET=$((CURSOR - visible + 1))
    fi

    local prev_category=""
    local line_idx=0
    local drawn=0

    for ((i = SCROLL_OFFSET; i < NUM_PACKAGES && drawn < visible; i++)); do
        local pkg="${PACKAGES[$i]}"
        local id display desc category
        id=$(get_field "$pkg" 1)
        display=$(get_field "$pkg" 2)
        desc=$(get_field "$pkg" 3)
        category=$(get_field "$pkg" 4)

        local row=$((HEADER_LINES + drawn + 1))
        move_to "$row" 1
        clear_line

        if [[ "$category" != "$prev_category" ]]; then
            if ((drawn > 0)); then
                printf "\n"
                drawn=$((drawn + 1))
                row=$((HEADER_LINES + drawn + 1))
                move_to "$row" 1
                clear_line
                if ((drawn >= visible)); then break; fi
            fi
            printf "   ${BOLD}${MAGENTA}── %s ──${RESET}\n" "$category"
            drawn=$((drawn + 1))
            row=$((HEADER_LINES + drawn + 1))
            move_to "$row" 1
            clear_line
            prev_category="$category"
            if ((drawn >= visible)); then break; fi
        fi

        local marker="${DOT}"
        local color=""
        if ((SELECTED[i] == 1)); then
            marker="${FILLED}"
            color="${GREEN}"
        fi

        if ((i == CURSOR)); then
            printf "   ${BOLD}${CYAN}${ARROW}${RESET} ${color}${marker}${RESET}  ${BOLD}%-14s${RESET} ${DIM}%s${RESET}" "$display" "$desc"
        else
            printf "     ${color}${marker}${RESET}  %-14s ${DIM}%s${RESET}" "$display" "$desc"
        fi

        drawn=$((drawn + 1))
    done

    for ((j = drawn; j < visible; j++)); do
        local row=$((HEADER_LINES + j + 1))
        move_to "$row" 1
        clear_line
    done

    local count=0
    for ((i = 0; i < NUM_PACKAGES; i++)); do
        if ((SELECTED[i] == 1)); then count=$((count + 1)); fi
    done

    local status_row=$((HEADER_LINES + visible + 1))
    move_to "$status_row" 1
    clear_line
    printf "\n"
    clear_line
    if ((count > 0)); then
        printf "   ${GREEN}${BOLD}%d package(s) selected${RESET}  ${DIM}─  Press Enter to install${RESET}" "$count"
    else
        printf "   ${DIM}No packages selected${RESET}"
    fi
}

# ─── install functions ───────────────────────────────────────────────────────
need_sudo() {
    if [[ $EUID -ne 0 ]]; then
        echo "sudo"
    else
        echo ""
    fi
}

apt_update_done=false
ensure_apt_update() {
    if ! $apt_update_done && is_debian; then
        $(need_sudo) apt-get update -qq
        apt_update_done=true
    fi
}

install_python() {
    if is_macos; then
        brew install python3
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y python3 python3-pip python3-venv
    elif is_fedora; then
        $(need_sudo) dnf install -y python3 python3-pip
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm python python-pip
    fi
}

install_node() {
    if is_macos; then
        brew install node
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y ca-certificates curl gnupg
        curl -fsSL https://deb.nodesource.com/setup_lts.x | $(need_sudo) bash -
        $(need_sudo) apt-get install -y nodejs
    elif is_fedora; then
        $(need_sudo) dnf install -y nodejs npm
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm nodejs npm
    fi
}

install_rust() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env" 2>/dev/null || true
}

install_go() {
    if is_macos; then
        brew install go
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y golang
    elif is_fedora; then
        $(need_sudo) dnf install -y golang
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm go
    fi
}

install_git() {
    if is_macos; then
        brew install git
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y git
    elif is_fedora; then
        $(need_sudo) dnf install -y git
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm git
    fi
}

install_ruff() {
    curl -LsSf https://astral.sh/ruff/install.sh | sh
}

install_uv() {
    curl -LsSf https://astral.sh/uv/install.sh | sh
}

install_docker() {
    if is_macos; then
        brew install --cask docker
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y ca-certificates curl
        $(need_sudo) install -m 0755 -d /etc/apt/keyrings
        curl -fsSL "https://download.docker.com/linux/${OS_ID}/gpg" | $(need_sudo) gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
        $(need_sudo) chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${OS_ID} $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | $(need_sudo) tee /etc/apt/sources.list.d/docker.list > /dev/null
        $(need_sudo) apt-get update -qq
        $(need_sudo) apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    elif is_fedora; then
        $(need_sudo) dnf install -y dnf-plugins-core
        $(need_sudo) dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        $(need_sudo) dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        $(need_sudo) systemctl enable --now docker
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm docker docker-compose
        $(need_sudo) systemctl enable --now docker
    fi
}

install_gh() {
    if is_macos; then
        brew install gh
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y curl
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $(need_sudo) dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        $(need_sudo) chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $(need_sudo) tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        $(need_sudo) apt-get update -qq
        $(need_sudo) apt-get install -y gh
    elif is_fedora; then
        $(need_sudo) dnf install -y gh
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm github-cli
    fi
}

install_code() {
    if is_macos; then
        brew install --cask visual-studio-code
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y wget gpg
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
        $(need_sudo) install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | $(need_sudo) tee /etc/apt/sources.list.d/vscode.list > /dev/null
        $(need_sudo) apt-get update -qq
        $(need_sudo) apt-get install -y code
    elif is_fedora; then
        $(need_sudo) rpm --import https://packages.microsoft.com/keys/microsoft.asc
        printf "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n" | $(need_sudo) tee /etc/yum.repos.d/vscode.repo > /dev/null
        $(need_sudo) dnf install -y code
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm code
    fi
}

install_neovim() {
    if is_macos; then
        brew install neovim
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y neovim
    elif is_fedora; then
        $(need_sudo) dnf install -y neovim
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm neovim
    fi
}

install_chrome() {
    if is_macos; then
        brew install --cask google-chrome
    elif is_debian; then
        wget -q -O /tmp/google-chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
        $(need_sudo) apt-get install -y /tmp/google-chrome.deb
        rm -f /tmp/google-chrome.deb
    elif is_fedora; then
        $(need_sudo) dnf install -y "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
    fi
}

install_firefox() {
    if is_macos; then
        brew install --cask firefox
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y firefox
    elif is_fedora; then
        $(need_sudo) dnf install -y firefox
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm firefox
    fi
}

install_curl() {
    if is_macos; then
        brew install curl
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y curl
    elif is_fedora; then
        $(need_sudo) dnf install -y curl
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm curl
    fi
}

install_wget() {
    if is_macos; then
        brew install wget
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y wget
    elif is_fedora; then
        $(need_sudo) dnf install -y wget
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm wget
    fi
}

install_jq() {
    if is_macos; then
        brew install jq
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y jq
    elif is_fedora; then
        $(need_sudo) dnf install -y jq
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm jq
    fi
}

install_ripgrep() {
    if is_macos; then
        brew install ripgrep
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y ripgrep
    elif is_fedora; then
        $(need_sudo) dnf install -y ripgrep
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm ripgrep
    fi
}

install_fzf() {
    if is_macos; then
        brew install fzf
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y fzf
    elif is_fedora; then
        $(need_sudo) dnf install -y fzf
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm fzf
    fi
}

install_tmux() {
    if is_macos; then
        brew install tmux
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y tmux
    elif is_fedora; then
        $(need_sudo) dnf install -y tmux
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm tmux
    fi
}

install_htop() {
    if is_macos; then
        brew install htop
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y htop
    elif is_fedora; then
        $(need_sudo) dnf install -y htop
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm htop
    fi
}

install_tree() {
    if is_macos; then
        brew install tree
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y tree
    elif is_fedora; then
        $(need_sudo) dnf install -y tree
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm tree
    fi
}

install_bat() {
    if is_macos; then
        brew install bat
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y bat
    elif is_fedora; then
        $(need_sudo) dnf install -y bat
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm bat
    fi
}

install_eza() {
    if is_macos; then
        brew install eza
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y eza 2>/dev/null || cargo install eza
    elif is_fedora; then
        $(need_sudo) dnf install -y eza 2>/dev/null || cargo install eza
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm eza
    fi
}

install_zsh() {
    if is_macos; then
        brew install zsh
    elif is_debian; then
        ensure_apt_update
        $(need_sudo) apt-get install -y zsh
    elif is_fedora; then
        $(need_sudo) dnf install -y zsh
    elif is_arch; then
        $(need_sudo) pacman -S --noconfirm zsh
    fi
}

# ─── installation runner ────────────────────────────────────────────────────
run_installs() {
    clear_screen
    show_cursor

    local to_install=()
    for ((i = 0; i < NUM_PACKAGES; i++)); do
        if ((SELECTED[i] == 1)); then
            to_install+=("$i")
        fi
    done

    local total=${#to_install[@]}
    if ((total == 0)); then
        printf "\n  ${YELLOW}Nothing selected. Exiting.${RESET}\n\n"
        exit 0
    fi

    printf "\n"
    printf "  ${BOLD}${CYAN}┌────────────────────────────────────────────┐${RESET}\n"
    printf "  ${BOLD}${CYAN}│  Installing %d package(s)...               │${RESET}\n" "$total"
    printf "  ${BOLD}${CYAN}└────────────────────────────────────────────┘${RESET}\n"
    printf "\n"

    detect_os

    if is_macos; then
        if ! command -v brew &>/dev/null; then
            printf "  ${YELLOW}Installing Homebrew first...${RESET}\n"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
    fi

    local succeeded=0
    local failed=0
    local failed_names=()

    for idx in "${to_install[@]}"; do
        local pkg="${PACKAGES[$idx]}"
        local id display
        id=$(get_field "$pkg" 1)
        display=$(get_field "$pkg" 2)

        printf "  ${CYAN}[%d/%d]${RESET} Installing ${BOLD}%s${RESET}..." "$((succeeded + failed + 1))" "$total" "$display"

        if install_"$id" > /tmp/dd-install-log-"$id".txt 2>&1; then
            printf " ${GREEN}${CHECK} done${RESET}\n"
            succeeded=$((succeeded + 1))
        else
            printf " ${RED}${CROSS} failed${RESET} ${DIM}(see /tmp/dd-install-log-%s.txt)${RESET}\n" "$id"
            failed=$((failed + 1))
            failed_names+=("$display")
        fi
    done

    printf "\n"
    printf "  ${BOLD}${CYAN}────────────────────────────────────────────${RESET}\n"
    printf "  ${GREEN}${CHECK} %d succeeded${RESET}" "$succeeded"
    if ((failed > 0)); then
        printf "  ${RED}${CROSS} %d failed: %s${RESET}" "$failed" "${failed_names[*]}"
    fi
    printf "\n\n"

    if ((failed == 0)); then
        printf "  ${GREEN}${BOLD}All done! Happy coding.${RESET}\n\n"
    else
        printf "  ${YELLOW}Check the log files in /tmp for details on failures.${RESET}\n\n"
    fi
}

# ─── main TUI loop ──────────────────────────────────────────────────────────
main() {
    if [[ -t 0 ]]; then
        TTY=/dev/stdin
    elif [[ -e /dev/tty ]]; then
        TTY=/dev/tty
    else
        printf "${RED}Error: No terminal available for interactive mode.${RESET}\n" >&2
        exit 1
    fi

    detect_os
    tput smcup 2>/dev/null
    hide_cursor
    clear_screen
    draw_header
    draw_list

    while true; do
        IFS= read -rsn1 key < "$TTY"

        if [[ "$key" == $'\x1b' ]]; then
            read -rsn2 -t 0.1 rest < "$TTY" || true
            key+="$rest"
        fi

        case "$key" in
            $'\x1b[A' | k)  # up
                if ((CURSOR > 0)); then CURSOR=$((CURSOR - 1)); fi
                ;;
            $'\x1b[B' | j)  # down
                if ((CURSOR < NUM_PACKAGES - 1)); then CURSOR=$((CURSOR + 1)); fi
                ;;
            ' ')  # space = toggle
                if ((SELECTED[CURSOR] == 0)); then
                    SELECTED[$CURSOR]=1
                else
                    SELECTED[$CURSOR]=0
                fi
                ;;
            a)  # toggle all
                local any_unselected=0
                for ((i = 0; i < NUM_PACKAGES; i++)); do
                    if ((SELECTED[i] == 0)); then any_unselected=1; break; fi
                done
                local val=$((any_unselected ? 1 : 0))
                for ((i = 0; i < NUM_PACKAGES; i++)); do SELECTED[$i]=$val; done
                ;;
            ''|$'\n')  # enter = install
                tput rmcup 2>/dev/null
                run_installs
                exit 0
                ;;
            q)  # quit
                tput rmcup 2>/dev/null
                show_cursor
                printf "\n  ${DIM}Cancelled.${RESET}\n\n"
                exit 0
                ;;
        esac

        draw_list
    done
}

main "$@"
