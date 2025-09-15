#!/usr/bin/env zsh
# Installer/Updater for msfvenom zsh autocomplete
# Save as install-msfvenom-completion_zsh.sh and run with:
# sudo zsh install-msfvenom-completion_zsh.sh

INSTALL_PATH="/usr/share/zsh/site-functions/_msfvenom"
CACHE_DIR="/var/cache/msfvenom_completion"
PAYLOADS="$CACHE_DIR/payloads.txt"
ENCODERS="$CACHE_DIR/encoders.txt"
FORMATS="$CACHE_DIR/formats.txt"
PLATFORMS="$CACHE_DIR/platforms.txt"
ARCHS="$CACHE_DIR/archs.txt"
OPTIONS="$CACHE_DIR/options.txt"

_build_cache() {
  mkdir -p "$CACHE_DIR"
  msfvenom -l payloads 2>/dev/null | awk '{print $1}' | grep '/' >| "$PAYLOADS" 2>/dev/null || true
  msfvenom -l encoders 2>/dev/null | awk '{print $1}' >| "$ENCODERS" 2>/dev/null || true
  msfvenom -l formats 2>/dev/null | awk '{print $1}' >| "$FORMATS" 2>/dev/null || true
  msfvenom --list platforms 2>/dev/null | awk 'NR>1 {print $1}' >| "$PLATFORMS" 2>/dev/null || true
  msfvenom --list archs 2>/dev/null | awk 'NR>1 {print $1}' >| "$ARCHS" 2>/dev/null || true
  cat >| "$OPTIONS" <<'EOL'
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
    if [[ ! -s "$f" ]]; then
      _build_cache
      break
    fi
  done
}

mkdir -p "$(dirname "$INSTALL_PATH")"

cat >| "$INSTALL_PATH" <<'EOF'
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

  if [[ $prev == "-p" ]]; then
    [[ -s "$PAYLOADS" ]] && compadd -- ${(f)"$(cat -- "$PAYLOADS" 2>/dev/null)"}
    return
  fi

  if [[ $prev == "-f" ]]; then
    [[ -s "$FORMATS" ]] && compadd -- ${(f)"$(cat -- "$FORMATS" 2>/dev/null)"}
    return
  fi

  if [[ $prev == "--platform" ]]; then
    [[ -s "$PLATFORMS" ]] && compadd -- ${(f)"$(cat -- "$PLATFORMS" 2>/dev/null)"}
    return
  fi

  if [[ $prev == "--arch" ]]; then
    [[ -s "$ARCHS" ]] && compadd -- ${(f)"$(cat -- "$ARCHS" 2>/dev/null)"}
    return
  fi

  if [[ $prev == "-e" ]]; then
    [[ -s "$ENCODERS" ]] && compadd -- ${(f)"$(cat -- "$ENCODERS" 2>/dev/null)"}
    return
  fi

  # LHOST/LPORT completion without space
  case "$cur" in
    LHOST*|lhost*|LPORT*|lport*)
      compadd -S '' LHOST= lhost= LPORT= lport=
      return
      ;;
  esac

  if [[ " ${words[*]} " == *" -p "* ]]; then
    [[ -s "$PAYLOADS" ]] && compadd -- ${(f)"$(cat -- "$PAYLOADS" 2>/dev/null)"}
    return
  fi

  [[ -s "$OPTIONS" ]] && compadd -- ${(f)"$(cat -- "$OPTIONS" 2>/dev/null)"}
}
compdef _msfvenom_completion msfvenom
EOF

chmod 644 "$INSTALL_PATH"

_init_cache

if [[ -n $ZSH_VERSION ]]; then
  autoload -U compinit >/dev/null 2>&1 || true
  compinit >/dev/null 2>&1 || true
  [[ -f "$INSTALL_PATH" ]] && source "$INSTALL_PATH" >/dev/null 2>&1 || true
fi

msfupdate-completion-update() {
  echo "[*] Updating msfvenom autocomplete cache..."
  _build_cache
  echo "[+] Cache updated in $CACHE_DIR"
}

echo "[*] Installing/Updating msfvenom-completion (zsh)..."
msfupdate-completion-update
echo "[+] Installation complete. Restart your shell to enable autocomplete."
