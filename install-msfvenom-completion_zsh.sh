#!/bin/bash
# install-msfvenom-completion_zsh_with_updater.sh
# Run with sudo

INSTALL_PATH="/usr/share/zsh/site-functions/_msfvenom"
CACHE_DIR="/var/cache/msfvenom_completion"
UPDATER_BIN="/usr/local/bin/msfupdate-completion-update"
ZSH_RC="/etc/zsh/zshrc"   # will append small helper function here if writable

# write zsh completion file
cat > "$INSTALL_PATH" <<'EOF'
#compdef msfvenom

CACHE_DIR="/var/cache/msfvenom_completion"
PAYLOADS="$CACHE_DIR/payloads.txt"
ENCODERS="$CACHE_DIR/encoders.txt"
FORMATS="$CACHE_DIR/formats.txt"
PLATFORMS="$CACHE_DIR/platforms.txt"
ARCHS="$CACHE_DIR/archs.txt"
OPTIONS="$CACHE_DIR/options.txt"

_msfin_words_from_file() {
  local file=$1
  if [[ -r $file ]]; then
    compadd -- ${(f)$(<"$file")}
  fi
}

_msfin_payloads() { _msfin_words_from_file "$PAYLOADS" }
_msfin_encoders()  { _msfin_words_from_file "$ENCODERS"  }
_msfin_formats()   { _msfin_words_from_file "$FORMATS"   }
_msfin_platforms() { _msfin_words_from_file "$PLATFORMS" }
_msfin_archs()     { _msfin_words_from_file "$ARCHS"     }

_msfin_generic_opts() {
  if [[ -r "$OPTIONS" ]]; then
    compadd -- ${(f)$(<"$OPTIONS")}
  fi
}

_arguments \
  '(-p --payloads)'{-p+,--payload=}'[payload]:payload:_msfin_payloads' \
  '(-e --encoders)'{-e+,--encoder=}'[encoder]:encoder:_msfin_encoders' \
  '(-f --formats)'{-f+,--format=}'[format]:format:_msfin_formats' \
  '(-a --arch)'{-a+,--arch=}'[arch]:arch:_msfin_archs' \
  '(--platform)'{--platform=}'[platform]:platform:_msfin_platforms' \
  '(-o --out)'{-o+,--out=}'[write output file]' \
  '*: :->rest' || _msfin_generic_opts
EOF

# function to build cache (used by installer and updater binary)
_build_cache_content='#!/bin/bash
CACHE_DIR="/var/cache/msfvenom_completion"
mkdir -p "$CACHE_DIR"

# collect lists. If msfvenom not present, produce empty files.
if command -v msfvenom >/dev/null 2>&1; then
  msfvenom -l payloads 2>/dev/null | awk "{print \$1}" | grep "/" > "$CACHE_DIR/payloads.txt" || true
  msfvenom -l encoders 2>/dev/null | awk "{print \$1}" > "$CACHE_DIR/encoders.txt" || true
  msfvenom -l formats 2>/dev/null | awk "{print \$1}" > "$CACHE_DIR/formats.txt" || true
  msfvenom --list platforms 2>/dev/null | awk "NR>1 {print \$1}" > "$CACHE_DIR/platforms.txt" || true
  msfvenom --list archs 2>/dev/null | awk "NR>1 {print \$1}" > "$CACHE_DIR/archs.txt" || true
fi

cat > "$CACHE_DIR/options.txt" <<-OPTS
--payload
-p
--encoder
-e
--format
-f
--platform
--arch
-a
--out
-o
--list
--smallest
--var-name
--add-code
--help
OPTS

chmod -R a+r "$CACHE_DIR"
echo "Cache rebuilt at $CACHE_DIR"
'

# write updater binary
echo "$_build_cache_content" > "$UPDATER_BIN"
chmod a+rx "$UPDATER_BIN"
chown root:root "$UPDATER_BIN"

# run build once now
/bin/bash "$UPDATER_BIN"

# try append helper function to global zshrc for convenience
if [ -w "$ZSH_RC" ] || [ ! -e "$ZSH_RC" -a -w "$(dirname "$ZSH_RC")" ]; then
  cat >> "$ZSH_RC" <<'FUNC'
# msfvenom completion update helper
msfupdate-completion-update() {
  echo "[*] Updating msfvenom autocomplete cache..."
  if [ "$(id -u)" -ne 0 ]; then
    sudo /usr/local/bin/msfupdate-completion-update
  else
    /usr/local/bin/msfupdate-completion-update
  fi
  echo "[+] Cache updated in /var/cache/msfvenom_completion"
}
FUNC
  echo "Added helper function msfupdate-completion-update() to $ZSH_RC"
else
  echo "Could not append helper to $ZSH_RC. You can call sudo /usr/local/bin/msfupdate-completion-update manually or add the shell function to your zshrc."
fi

echo "Installed zsh completion to $INSTALL_PATH"
echo "Cache located at $CACHE_DIR"
echo "Updater binary at $UPDATER_BIN"
echo "Reload zsh with: autoload -U compinit && compinit"_msfvenom "$@"
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
