#!/bin/bash
# Installer/Updater for msfvenom zsh autocomplete
# Save as install-msfvenom-completion_zsh.sh and run with: sudo zsh install-msfvenom-completion_zsh.sh

INSTALL_PATH="/usr/share/zsh/site-functions/_msfvenom"
CACHE_DIR="/var/cache/msfvenom_completion"

cat > "$INSTALL_PATH" <<'EOF'
#compdef msfvenom

# Ensure zsh completion system and helper functions are loaded
if (( ! ${+functions[_arguments]} )); then
  autoload -Uz compinit && compinit
  autoload -Uz _arguments _values compadd
fi

CACHE_DIR="/var/cache/msfvenom_completion"
PAYLOADS="$CACHE_DIR/payloads.txt"
ENCODERS="$CACHE_DIR/encoders.txt"
FORMATS="$CACHE_DIR/formats.txt"
PLATFORMS="$CACHE_DIR/platforms.txt"
ARCHS="$CACHE_DIR/archs.txt"
OPTIONS="$CACHE_DIR/options.txt"

_build_cache() {
    mkdir -p "$CACHE_DIR"

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

_msfvenom() {
    local -a opts payloads encoders formats plats archs
    _init_cache

    # read files into arrays (zsh-only expansions)
    opts=(${(f)"$(<"$OPTIONS")"})
    payloads=(${(f)"$(<"$PAYLOADS")"})
    encoders=(${(f)"$(<"$ENCODERS")"})
    formats=(${(f)"$(<"$FORMATS")"})
    plats=(${(f)"$(<"$PLATFORMS")"})
    archs=(${(f)"$(<"$ARCHS")"})

    # Special handling for LHOST/LPORT (append = and no space)
    case "$words[CURRENT]" in
        LHOST|lhost|LPORT|lport)
            compadd -S '' -qS '=' "$words[CURRENT]"
            return
            ;;
    esac

    _arguments \
        '-p+[Select payload]:payload:(${payloads[*]})' \
        '-e+[Select encoder]:encoder:(${encoders[*]})' \
        '-f+[Select format]:format:(${formats[*]})' \
        '--platform+[Select platform]:platform:(${plats[*]})' \
        '--arch+[Select architecture]:arch:(${archs[*]})' \
        '*::arg:->args'

    case $state in
        args)
            _values 'options' ${opts[*]}
            ;;
    esac
}

msfupdata-completion-update() {
    echo "[*] Updating msfvenom autocomplete cache..."
    _build_cache
    echo "[+] Cache updated in $CACHE_DIR"
}

_msfvenom "$@"
EOF

echo "[*] Installing/Updating msfvenom-completion for zsh..."

# Ensure compinit is enabled globally
if ! grep -q "autoload -Uz compinit && compinit" /etc/zsh/zshrc 2>/dev/null; then
    echo "[*] Adding compinit initialization to /etc/zsh/zshrc..."
    echo '' >> /etc/zsh/zshrc
    echo '# Enable completion system' >> /etc/zsh/zshrc
    echo 'autoload -Uz compinit && compinit' >> /etc/zsh/zshrc
fi

# Build cache once now using zsh (do NOT source zsh completion file with bash/sh)
zsh -lc "source $INSTALL_PATH; msfupdata-completion-update"

echo "[+] Installation complete. Restart your shell to enable autocomplete."