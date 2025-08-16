# install-msfvenom-completion.sh

# msfvenom Autocomplete Installer

A simple Bash installer that enables **autocomplete (tab completion)** for the `msfvenom` tool from the Metasploit Framework.  
It generates a local cache containing **payloads, encoders, formats, platforms, archs, and options**,  
so you can easily use the `Tab` key instead of typing them manually.

---

## 🚀 Features
- Autocompletion support for `msfvenom`.
- Automatically builds and initializes a local cache.
- No extra space added after options like `LHOST=` or `LPORT=`.
- Provides a manual cache update command:
  ```bash
  msfvenom-completion-update


---

📦 Requirements

Linux (bash shell)

Metasploit Framework (with msfvenom available in PATH).

sudo privileges (to create the cache directory).



---

🔧 Installation

Clone the repository and run the installer:

git clone https://github.com/pashamasr01287654800/install-msfvenom-completion.git
cd install-msfvenom-completion
chmod +x install-msfvenom-completion.sh
sudo ./install-msfvenom-completion.sh

Restart your shell afterwards:

exec bash


---

🛠️ Usage

Type msfvenom and press Tab to see available completions.

Update the cache manually at any time:

msfvenom-completion-update



---

📂 File Locations

Completion script is installed in:

/etc/bash_completion.d/msfvenom

Cache files are stored in:

/var/cache/msfvenom_completion



---

⚠️ Notes

The installer must be run with sudo privileges.

If autocomplete does not work, try:

source /etc/bash_completion
source /etc/bash_completion.d/msfvenom

