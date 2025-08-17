#!/bin/bash
# Installer/Updater for sqlmap autocomplete (dynamic version with tamper support)

INSTALL_PATH="/etc/bash_completion.d/sqlmap"
CACHE_DIR="$HOME/.cache/sqlmap_completion"

mkdir -p "$CACHE_DIR"

cat > "$INSTALL_PATH" <<'EOF'
CACHE_DIR="$HOME/.cache/sqlmap_completion"
OPTIONS="$CACHE_DIR/options.txt"
TAMPERS="$CACHE_DIR/tampers.txt"

# Detect tamper directory (default: same as sqlmap install)
_detect_tamper_dir() {
    local tamper_dir=""
    tamper_dir=$(python3 -c "import sqlmap, os; print(os.path.join(os.path.dirname(sqlmap.__file__), 'tamper'))" 2>/dev/null)
    [[ -d "$tamper_dir" ]] && echo "$tamper_dir"
}

_build_cache() {
    mkdir -p "$CACHE_DIR"

    # Extract options dynamically from sqlmap --help
    sqlmap --help 2>/dev/null | \
        awk '/^  -/ {print $1} /^  --/ {print $1}' | sort -u > "$OPTIONS"

    # Add special ones if missed
    cat >> "$OPTIONS" <<EOL
--technique
--level
--risk
--tamper
EOL

    # Build tamper list
    local tdir
    tdir=$(_detect_tamper_dir)
    if [[ -n "$tdir" ]]; then
        ls "$tdir"/*.py 2>/dev/null | xargs -n1 basename | sed 's/\.py$//' > "$TAMPERS"
    fi
}

_init_cache() {
    [[ ! -s "$OPTIONS" ]] && _build_cache
}

_sqlmap_completion() {
    local cur
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    # Autocomplete options
    if [[ $cur == -* ]]; then
        local opts
        opts=$(cat "$OPTIONS")
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return 0
    fi

    # Techniques
    if [[ " ${COMP_WORDS[*]} " == *"--technique "* ]]; then
        COMPREPLY=( $(compgen -W "B E U S T Q" -- "$cur") )
        return 0
    fi

    # Levels and risks
    if [[ " ${COMP_WORDS[*]} " == *"--level "* ]] || [[ " ${COMP_WORDS[*]} " == *"--risk "* ]]; then
        COMPREPLY=( $(compgen -W "1 2 3 4 5" -- "$cur") )
        return 0
    fi

    # Tamper scripts
    if [[ " ${COMP_WORDS[*]} " == *"--tamper "* ]]; then
        [[ -f "$TAMPERS" ]] && COMPREPLY=( $(compgen -W "$(cat "$TAMPERS")" -- "$cur") )
        return 0
    fi
}

sqlmap-completion-update() {
    echo "[*] Updating sqlmap autocomplete cache..."
    _build_cache
    echo "[+] Cache updated in \$CACHE_DIR"
}

_init_cache
complete -F _sqlmap_completion sqlmap
EOF

echo "[*] Installing/Updating sqlmap-completion..."
bash -c "source $INSTALL_PATH; sqlmap-completion-update"
echo "[+] Installation complete. Restart your shell to enable autocomplete."
