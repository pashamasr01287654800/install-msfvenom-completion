#!/bin/bash
# Installer/Updater for msfvenom autocomplete

INSTALL_PATH="/etc/bash_completion.d/msfvenom"
CACHE_DIR="/var/cache/msfvenom_completion"

# Write the completion script
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
    msfvenom --list platforms 2>/dev/null | awk '{print $1}' | grep -v "Name" > "$PLATFORMS"
    msfvenom --list archs 2>/dev/null | awk '{print $1}' | grep -v "Name" > "$ARCHS"

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
EOL
}

_init_cache() {
    if [[ ! -s "$PAYLOADS" || ! -s "$ENCODERS" || ! -s "$FORMATS" || ! -s "$PLATFORMS" || ! -s "$ARCHS" || ! -s "$OPTIONS" ]]; then
        _build_cache
    fi
}

_msfvenom_completion() {
    local cur prev cur_lc
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    cur_lc=$(echo "$cur" | tr '[:upper:]' '[:lower:]')

    # LHOST autocomplete with '='
    if [[ ${cur_lc} == lhost* ]]; then
        COMPREPLY=( "LHOST=" )
        return 0
    fi

    # LPORT autocomplete with '='
    if [[ ${cur_lc} == lport* ]]; then
        COMPREPLY=( "LPORT=" )
        return 0
    fi

    # Other options
    if [[ ${cur} == -* ]]; then
        COMPREPLY=( $(compgen -W "$(cat $OPTIONS)" -- ${cur}) )
        return 0
    fi

    # Payloads
    if [[ ${prev} == "-p" ]]; then
        COMPREPLY=( $(compgen -W "$(cat $PAYLOADS)" -- ${cur}) )
        return 0
    fi

    # Formats
    if [[ ${prev} == "-f" ]]; then
        COMPREPLY=( $(compgen -W "$(cat $FORMATS)" -- ${cur}) )
        return 0
    fi

    # Encoders
    if [[ ${prev} == "-e" ]]; then
        COMPREPLY=( $(compgen -W "$(cat $ENCODERS)" -- ${cur}) )
        return 0
    fi

    # Platforms
    if [[ ${prev} == "--platform" ]]; then
        COMPREPLY=( $(compgen -W "$(cat $PLATFORMS)" -- ${cur}) )
        return 0
    fi

    # Archs
    if [[ ${prev} == "--arch" ]]; then
        COMPREPLY=( $(compgen -W "$(cat $ARCHS)" -- ${cur}) )
        return 0
    fi

    # Partial payload completion
    if [[ ${cur} == */* ]]; then
        COMPREPLY=( $(compgen -W "$(cat $PAYLOADS)" -- ${cur}) )
        return 0
    fi
}

msfvenom-completion-update() {
    echo "[*] Updating msfvenom autocomplete cache..."
    _build_cache
    echo "[+] Done. Cache updated in $CACHE_DIR"
}

_init_cache
complete -F _msfvenom_completion msfvenom
EOF

# Install/update message
echo "[*] Installing/Updating msfvenom-completion..."
bash -c "source $INSTALL_PATH; msfvenom-completion-update"
echo "[+] Installation complete. Restart your shell to enable autocomplete."
