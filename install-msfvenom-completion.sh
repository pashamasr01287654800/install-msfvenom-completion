#!/bin/bash
# Installer/Updater for msfvenom autocomplete (no space after =)

INSTALL_PATH="/etc/bash_completion.d/msfvenom"
CACHE_DIR="/var/cache/msfvenom_completion"

cat > "$INSTALL_PATH" <<'EOF'
CACHE_DIR="/var/cache/msfvenom_completion"
PAYLOADS="$CACHE_DIR/payloads.txt"
ENCODERS="$CACHE_DIR/encoders.txt"
FORMATS="$CACHE_DIR/formats.txt"
PLATFORMS="$CACHE_DIR/platforms.txt"
ARCHS="$CACHE_DIR/archs.txt"
OPTIONS="$CACHE_DIR/options.txt"

_build_cache() {
    sudo mkdir -p "$CACHE_DIR"

    msfvenom -l payloads 2>/dev/null | awk '{print $1}' | grep '/' > "$PAYLOADS"
    msfvenom -l encoders 2>/dev/null | awk '{print $1}' > "$ENCODERS"
    msfvenom -l formats 2>/dev/null | awk '{print $1}' > "$FORMATS"
    msfvenom --list platforms 2>/dev/null | awk 'NR>1 {print $1}' > "$PLATFORMS"
    msfvenom --list archs 2>/dev/null | awk 'NR>1 {print $1}' > "$ARCHS"

    cat > "$OPTIONS" <<EOL
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
    for f in "$PAYLOADS" "$ENCODERS" "$FORMATS" "$PLATFORMS" "$ARCHS" "$OPTIONS"; do
        [[ ! -s "$f" ]] && _build_cache && break
    done
}

_msfvenom_completion() {
    local cur
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    # Options including LHOST/LPORT
    if [[ $cur == -* || $cur == lh* || $cur == lp* || $cur == LH* || $cur == LP* ]]; then
        local opts=$(cat "$OPTIONS")
        # Add = automatically for LHOST/LPORT
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        for i in "${!COMPREPLY[@]}"; do
            case "${COMPREPLY[$i]}" in
                LHOST|lhost|LPORT|lport)
                    COMPREPLY[$i]="${COMPREPLY[$i]}="
                    ;;
            esac
        done
        compopt -o nospace   # prevent adding extra space
        return 0
    fi

    # Payloads, encoders, formats, etc
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

msfvenom-completion-update() {
    echo "[*] Updating msfvenom autocomplete cache..."
    _build_cache
    echo "[+] Cache updated in $CACHE_DIR"
}

_init_cache
complete -F _msfvenom_completion msfvenom
EOF

echo "[*] Installing/Updating msfvenom-completion..."
bash -c "source $INSTALL_PATH; msfvenom-completion-update"
echo "[+] Installation complete. Restart your shell to enable autocomplete."



