#!/bin/bash
# Installer/Updater for msfvenom autocomplete (Final improved version)

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

    # Cache payloads, encoders, formats, platforms, archs
    msfvenom -l payloads 2>/dev/null | awk '{print $1}' | grep '/' > "$PAYLOADS"
    msfvenom -l encoders 2>/dev/null | awk '{print $1}' > "$ENCODERS"
    msfvenom -l formats 2>/dev/null | awk '{print $1}' > "$FORMATS"
    msfvenom --list platforms 2>/dev/null | awk 'NR>1 {print $1}' > "$PLATFORMS"
    msfvenom --list archs 2>/dev/null | awk 'NR>1 {print $1}' > "$ARCHS"

    # Common options including only host/port without '-'
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
LHOST=
LPORT=
lhost=
lport=
EOL
}

_init_cache() {
    [[ ! -s "$PAYLOADS" || ! -s "$ENCODERS" || ! -s "$FORMATS" || ! -s "$PLATFORMS" || ! -s "$ARCHS" || ! -s "$OPTIONS" ]] && _build_cache
}

_msfvenom_completion() {
    local cur cur_lc COMPREPLY used available opts
    cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=()
    cur_lc="${cur,,}"   # lowercase

    # Gather already used words
    used=("${COMP_WORDS[@]:1}")

    # Read options from cache
    opts=( $(cat "$OPTIONS") )

    # Only suggest unused options
    available=()
    for o in "${opts[@]}"; do
        if ! [[ " ${used[*]} " =~ " $o " ]]; then
            available+=("$o")
        fi
    done

    # If current word starts with dash, suggest standard options only
    if [[ $cur == -* ]]; then
        COMPREPLY=( $(compgen -W "${available[*]}" -- "$cur") )
        return 0
    fi

    # If current word looks like LHOST/LPORT without dash
    if [[ $cur_lc == lh* || $cur_lc == lp* ]]; then
        COMPREPLY=( $(compgen -W "LHOST= LPORT= lhost= lport=" -- "$cur") )
        return 0
    fi

    # Suggest payloads, formats, encoders, platforms, archs based on previous words
    for ((i=1;i<=COMP_CWORD;i++)); do
        case "${COMP_WORDS[i-1]}" in
            -p) COMPREPLY=( $(compgen -W "$(cat "$PAYLOADS")" -- "$cur") ) ;;
            -f) COMPREPLY=( $(compgen -W "$(cat "$FORMATS")" -- "$cur") ) ;;
            -e) COMPREPLY=( $(compgen -W "$(cat "$ENCODERS")" -- "$cur") ) ;;
            --platform) COMPREPLY=( $(compgen -W "$(cat "$PLATFORMS")" -- "$cur") ) ;;
            --arch) COMPREPLY=( $(compgen -W "$(cat "$ARCHS")" -- "$cur") ) ;;
        esac
    done

    # If typing a partial payload with slash, suggest from payloads directly
    if [[ $cur == */* ]]; then
        COMPREPLY=( $(compgen -W "$(cat "$PAYLOADS")" -- "$cur") )
    fi
}

# Command to manually update the cache
msfvenom-completion-update() {
    echo "[*] Updating msfvenom autocomplete cache..."
    _build_cache
    echo "[+] Cache updated in $CACHE_DIR"
}

_init_cache
complete -F _msfvenom_completion msfvenom
EOF

# Install/update message
echo "[*] Installing/Updating msfvenom-completion..."
bash -c "source $INSTALL_PATH; msfvenom-completion-update"
echo "[+] Installation complete. Restart your shell to enable autocomplete."
