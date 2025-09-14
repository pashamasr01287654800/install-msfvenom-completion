#!/bin/bash
# Installer/Updater for msfvenom autocomplete (bash + zsh)
# Requires sudo

CACHE_DIR="/var/cache/msfvenom_completion"
INSTALL_BASH="/etc/bash_completion.d/msfvenom"
INSTALL_ZSH="/usr/share/zsh/site-functions/_msfvenom"

_build_cache() {
    mkdir -p "$CACHE_DIR"

    msfvenom -l payloads 2>/dev/null | awk '{print $1}' | grep '/' > "$CACHE_DIR/payloads.txt" 2>/dev/null || true
    msfvenom -l encoders 2>/dev/null | awk '{print $1}' > "$CACHE_DIR/encoders.txt" 2>/dev/null || true
    msfvenom -l formats 2>/dev/null | awk '{print $1}' > "$CACHE_DIR/formats.txt" 2>/dev/null || true
    msfvenom --list platforms 2>/dev/null | awk 'NR>1 {print $1}' > "$CACHE_DIR/platforms.txt" 2>/dev/null || true
    msfvenom --list archs 2>/dev/null | awk 'NR>1 {print $1}' > "$CACHE_DIR/archs.txt" 2>/dev/null || true

    cat > "$CACHE_DIR/options.txt" <<EOL
-p
-f
-e
-h
-l
--list
--platform
--arch
--payload-options
--help
LHOST
LPORT
lhost
lport
EOL
}

_init_cache() {
    for f in payloads.txt encoders.txt formats.txt platforms.txt archs.txt options.txt; do
        [[ ! -s "$CACHE_DIR/$f" ]] && _build_cache && break
    done
}

_install_bash() {
    cat > "$INSTALL_BASH" <<'EOF'
CACHE_DIR="/var/cache/msfvenom_completion"
PAYLOADS="$CACHE_DIR/payloads.txt"
ENCODERS="$CACHE_DIR/encoders.txt"
FORMATS="$CACHE_DIR/formats.txt"
PLATFORMS="$CACHE_DIR/platforms.txt"
ARCHS="$CACHE_DIR/archs.txt"
OPTIONS="$CACHE_DIR/options.txt"

_msfvenom_completion() {
    local cur
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    if [[ $cur == -* || $cur == lh* || $cur == lp* || $cur == LH* || $cur == LP* ]]; then
        local opts=$(cat "$OPTIONS")
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        for i in "${!COMPREPLY[@]}"; do
            case "${COMPREPLY[$i]}" in
                LHOST|lhost|LPORT|lport) COMPREPLY[$i]="${COMPREPLY[$i]}=" ;; 
            esac
        done
        compopt -o nospace
        return 0
    fi

    if [[ " ${COMP_WORDS[*]} " == *" -p "* ]]; then
        COMPREPLY=( $(compgen -W "$(cat "$PAYLOADS")" -- "$cur") )
    elif [[ " ${COMP_WORDS[*]} " == *" -f "* ]]; then
        COMPREPLY=( $(compgen -W "$(cat "$FORMATS")" -- "$cur") )
    elif [[ " ${COMP_WORDS[*]} " == *"--platform "* ]]; then
        COMPREPLY=( $(compgen -W "$(cat "$PLATFORMS")" -- "$cur") )
    elif [[ " ${COMP_WORDS[*]} " == *"--arch "* ]]; then
        COMPREPLY=( $(compgen -W "$(cat "$ARCHS")" -- "$cur") )
    elif [[ " ${COMP_WORDS[*]} " == *"-e "* ]]; then
        COMPREPLY=( $(compgen -W "$(cat "$ENCODERS")" -- "$cur") )
    fi
}

complete -F _msfvenom_completion msfvenom
EOF
}

_install_zsh() {
    cat > "$INSTALL_ZSH" <<'EOF'
#compdef msfvenom
CACHE_DIR="/var/cache/msfvenom_completion"
PAYLOADS="$CACHE_DIR/payloads.txt"
ENCODERS="$CACHE_DIR/encoders.txt"
FORMATS="$CACHE_DIR/formats.txt"
PLATFORMS="$CACHE_DIR/platforms.txt"
ARCHS="$CACHE_DIR/archs.txt"
OPTIONS="$CACHE_DIR/options.txt"

_msfvenom_completion() {
    typeset -A opt_args
    local -a expl
    local cur prev
    cur=${words[CURRENT]}
    prev=${words[CURRENT-1]}

    if [[ $prev == "-p" ]]; then compadd -- ${(f)"$(cat -- "$PAYLOADS" 2>/dev/null)"}; return; fi
    if [[ $prev == "-f" ]]; then compadd -- ${(f)"$(cat -- "$FORMATS" 2>/dev/null)"}; return; fi
    if [[ $prev == "--platform" ]]; then compadd -- ${(f)"$(cat -- "$PLATFORMS" 2>/dev/null)"}; return; fi
    if [[ $prev == "--arch" ]]; then compadd -- ${(f)"$(cat -- "$ARCHS" 2>/dev/null)"}; return; fi
    if [[ $prev == "-e" ]]; then compadd -- ${(f)"$(cat -- "$ENCODERS" 2>/dev/null)"}; return; fi

    if [[ "$cur" == (LHOST|lhost|LPORT|lport)* ]]; then compadd 'LHOST=' 'lhost=' 'LPORT=' 'lport='; return; fi
    if [[ " ${words[*]} " == *" -p "* ]]; then compadd -- ${(f)"$(cat -- "$PAYLOADS" 2>/dev/null)"}; return; fi
    if [[ -s "$OPTIONS" ]]; then compadd -- ${(f)"$(cat -- "$OPTIONS" 2>/dev/null)"}; fi
}
compdef _msfvenom_completion msfvenom
EOF
}

_add_source_to_rc() {
    local user_home shell_type rc_file source_line
    for user_home in /home/*; do
        shell_type=$(basename "$(getent passwd $(basename "$user_home") | cut -d: -f7)")
        case "$shell_type" in
            bash) rc_file="$user_home/.bashrc"; source_line="source $INSTALL_BASH" ;;
            zsh) rc_file="$user_home/.zshrc"; source_line="source $INSTALL_ZSH" ;;
            *) continue ;;
        esac
        [[ -f "$rc_file" ]] || touch "$rc_file"
        grep -qxF "$source_line" "$rc_file" || echo "$source_line" >> "$rc_file"
    done
}

echo "[*] Installing/Updating msfvenom autocomplete..."
_init_cache

case "$(basename "$SHELL")" in
    bash) _install_bash ;;
    zsh) _install_zsh ;;
    *) echo "[!] Unsupported shell: $SHELL. Installing bash autocomplete by default."; _install_bash ;;
esac

_add_source_to_rc

echo "[+] Installation complete. Autocomplete will work on every new terminal session."