#!/bin/bash

# ==============================================================================
# SETUP SCRIPT V19 (Flask & Markdown Support)
# Base: setup.sh V18
# Changes:
#   - Tambah flask & markdown ke pip install
# ==============================================================================

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="$BASE_DIR/tools"
ARCHIVES_DIR="$BASE_DIR/archives"
WEAPONS_DIR="$BASE_DIR/weapons"
ENGINE_DIR="$BASE_DIR/engine"

trap 'termux-wake-unlock 2>/dev/null' EXIT

echo "[*] Memulai Setup TRX Arsenal di: $BASE_DIR"
termux-wake-lock

# 1. STRUKTUR FOLDER
echo "[*] Membuat struktur folder..."
mkdir -p "$TOOLS_DIR" "$ARCHIVES_DIR" "$WEAPONS_DIR" "$WEAPONS_DIR/wordlists" "$WEAPONS_DIR/payloads" "$BASE_DIR/dumps" "$BASE_DIR/targets" "$BASE_DIR/reports" "$ENGINE_DIR"

# 2. DEPENDENSI DASAR
echo "[*] Update repo & install dependensi dasar..."
pkg update -y
pkg install python golang ruby git clang make curl wget netcat-openbsd nmap dnsutils colorized-logs termux-api -y
pip install playwright requests
playwright install chromium

# 3. PIP TOOLS (Tambah Flask & Markdown)
echo "[*] Menginstall tools via pip..."
pip install --upgrade dirsearch git-dumper theHarvester wafw00f wappalyzer-python3 caniscrape arjun flask markdown 2>/dev/null

# 4. GIT CLONE
echo "[*] Menginstall tools via Git..."
cd "$TOOLS_DIR" || exit
for repo in "sqlmap:https://github.com/sqlmapproject/sqlmap.git" \
            "WhatWeb:https://github.com/urbanadventurer/WhatWeb.git" \
            "dirsearch:https://github.com/maurosoria/dirsearch.git" \
            "commix:https://github.com/commixproject/commix.git" \
            "XSStrike:https://github.com/s0md3v/XSStrike.git" \
            "CloudFail:https://github.com/anmolksachan/CloudFail.git" \
            "CloudRecon:https://github.com/intspired/CloudRecon.git" \
            "wafw00f:https://github.com/EnableSecurity/wafw00f.git"; do
    name=$(echo "$repo" | cut -d':' -f1)
    url=$(echo "$repo" | cut -d':' -f2-)
    if [ ! -d "$name" ]; then
        git clone --depth=1 "$url" "$name"
    else
        ( cd "$name" && git pull )
    fi
done

( cd "$TOOLS_DIR/WhatWeb" && gem install bundler && bundle install )
( cd "$TOOLS_DIR/dirsearch" && pip install -r requirements.txt )
( cd "$TOOLS_DIR/commix" && pip install -r requirements.txt )
( cd "$TOOLS_DIR/XSStrike" && pip install -r requirements.txt )
( cd "$TOOLS_DIR/CloudFail" && pip install -r requirements.txt )
( cd "$TOOLS_DIR/wafw00f" && python setup.py install )

# 5. GO TOOLS
echo "[*] Menginstall / Update tools via Go..."
install_go_tool() {
    local tool_name=$1
    local install_cmd=$2
    if ! command -v "$tool_name" &> /dev/null; then
        eval "$install_cmd"
    else
        eval "$install_cmd"
    fi
}
install_go_tool "nuclei" "go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
install_go_tool "dalfox" "go install -v github.com/hahwul/dalfox/v2@latest"
install_go_tool "ffuf" "go install github.com/ffuf/ffuf/v2@latest"
install_go_tool "gobuster" "go install github.com/OJ/gobuster/v3@latest"
install_go_tool "subfinder" "go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
install_go_tool "httpx" "go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
install_go_tool "katana" "go install github.com/projectdiscovery/katana/cmd/katana@latest"
install_go_tool "interactsh-client" "go install -v github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest"
install_go_tool "amass" "go install -v github.com/owasp-amass/amass/v4/...@latest"
install_go_tool "trufflehog" "go install github.com/trufflesecurity/trufflehog/v3@latest"
install_go_tool "origindive" "go install github.com/jhaxce/origindive/cmd/origindive@latest"
install_go_tool "subzy" "go install -v github.com/rix4uni/subzy@latest"

# 6. EXPLOITDB
echo "[*] Menginstall Exploit-DB dari GitLab..."
cd "$ARCHIVES_DIR" || exit
if [ ! -d "exploitdb" ]; then
    git clone --depth=1 https://gitlab.com/exploit-database/exploitdb.git
    chmod +x exploitdb/searchsploit
else
    ( cd exploitdb && git pull )
fi
cd "$BASE_DIR" || exit

# 7. HASHCAT & LINPEAS
if ! command -v hashcat &> /dev/null; then
    curl -sL https://github.com/Anon4You/hashcat-in-termux/raw/main/hashcat.sh | bash
fi

if [ ! -f "$WEAPONS_DIR/linpeas.sh" ]; then
    curl -L https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh -o "$WEAPONS_DIR/linpeas.sh"
    chmod +x "$WEAPONS_DIR/linpeas.sh"
fi

# 8. WORDLIST
if [ ! -f "$WEAPONS_DIR/wordlists/rockyou.txt" ]; then
    curl -L https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt -o "$WEAPONS_DIR/wordlists/rockyou.txt"
fi
if [ ! -f "$WEAPONS_DIR/wordlists/common.txt" ]; then
    curl -sL https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -o "$WEAPONS_DIR/wordlists/common.txt"
fi
if [ ! -f "$WEAPONS_DIR/wordlists/directory-list-2.3-medium.txt" ]; then
    curl -sL https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-2.3-medium.txt -o "$WEAPONS_DIR/wordlists/directory-list-2.3-medium.txt"
fi

# 9. NUCLEI TEMPLATES
if command -v nuclei &> /dev/null; then
    nuclei -update-templates
fi

# 10. CUSTOM REPO
echo -e "\n[*] Instalasi Dasar Selesai."
read -p "Ada repo tambahan? (URL/Kosongkan): " custom_repo
if [ -n "$custom_repo" ]; then
    read -p "Simpan di folder mana? (contoh: tools/nikto): " target_dir
    mkdir -p "$BASE_DIR/$target_dir"
    cd "$BASE_DIR/$target_dir" || exit
    git clone "$custom_repo" . 2>/dev/null
    if [ -d ".git" ]; then
        if [ -f "requirements.txt" ]; then pip install -r requirements.txt; fi
        if [ -f "package.json" ]; then npm install; fi
        if [ -f "go.mod" ]; then go build -o "$(basename "$target_dir")"; fi
        if [ -f "composer.json" ]; then composer install; fi
        if [ -f "setup.sh" ]; then chmod +x setup.sh && bash setup.sh; fi
    fi
    cd "$BASE_DIR" || exit
fi

# 11. GENERATE WEAPONS.SH
echo "[*] Membuat file engine/weapons.sh..."
cat > "$ENGINE_DIR/weapons.sh" << 'WEOF'
#!/bin/bash
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="$BASE_DIR/tools"
ARCHIVES_DIR="$BASE_DIR/archives"
REPORTS_DIR="$BASE_DIR/reports"
PROXY_SCRIPT="$BASE_DIR/engine/proxy_rotator.py"

if [ -z "$1" ]; then echo "Usage: ./weapons.sh <tool_name> [args...]"; exit 1; fi
TOOL_NAME=$1
shift
TOOL_PATH="$TOOLS_DIR/$TOOL_NAME"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
mkdir -p "$REPORTS_DIR"
LOG_FILE="$REPORTS_DIR/scan_${TOOL_NAME}_${TIMESTAMP}.log"

if [ -f "$PROXY_SCRIPT" ] && [ -f "$BASE_DIR/weapons/proxies_valid.txt" ]; then
    RANDOM_PROXY=$(python3 "$PROXY_SCRIPT" --export)
    if [ -n "$RANDOM_PROXY" ]; then
        export HTTP_PROXY="http://$RANDOM_PROXY"; export HTTPS_PROXY="http://$RANDOM_PROXY"
        echo -e "\n[*] Proxy aktif: $RANDOM_PROXY"
    fi
fi

write_log_header() {
    echo "==================================================" >> "$LOG_FILE"
    echo "TRX Arsenal Scan Log" >> "$LOG_FILE"
    echo "Waktu   : $(date +"%Y-%m-%d %H:%M:%S")" >> "$LOG_FILE"
    echo "Tool    : $TOOL_NAME" >> "$LOG_FILE"
    echo "Command : $TOOL_NAME $@" >> "$LOG_FILE"
    echo "==================================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

execute_with_log() {
    local cmd_array=("$@")
    stdbuf -oL "${cmd_array[@]}" 2>&1 | tee >(sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' >> "$LOG_FILE")
    local exit_code=${PIPESTATUS[0]}
    echo "" >> "$LOG_FILE"
    echo "--- Scan Selesai (Exit Code: $exit_code) ---" >> "$LOG_FILE"
    echo -e "\n[+] Log tersimpan di: $LOG_FILE"
    
    if command -v termux-notification &> /dev/null; then
        if [ $exit_code -eq 0 ]; then
            termux-notification --title "TRX Scan Selesai" --content "$TOOL_NAME berhasil dijalankan." --priority low
        else
            termux-notification --title "TRX Scan Gagal" --content "$TOOL_NAME gagal (Exit Code: $exit_code)." --priority high
        fi
    fi
    return $exit_code
}

show_help() {
    local tool_path=$1
    local tool_name=$2
    echo -e "\n[*] Dokumentasi untuk $tool_name..."
    if [ -f "$tool_path/README.md" ]; then head -n 50 "$tool_path/README.md"; return
    elif [ -f "$tool_path/README.txt" ]; then head -n 50 "$tool_path/README.txt"; return; fi
}

write_log_header "$@"

if command -v "$TOOL_NAME" &> /dev/null && [ ! -d "$TOOL_PATH" ]; then
    execute_with_log "$TOOL_NAME" "$@"; exit $?
fi

if [ -d "$TOOL_PATH" ]; then
    echo "[*] Menjalankan $TOOL_NAME dari folder tools/..."
    if [ $# -eq 0 ]; then show_help "$TOOL_PATH" "$TOOL_NAME"; exit 0; fi
    if [ "$TOOL_NAME" == "CloudFail" ]; then ( cd "$TOOL_PATH" && execute_with_log python3 -m cloudfail "$@" ); exit $?; fi
    if [ "$TOOL_NAME" == "CloudRecon" ]; then ( cd "$TOOL_PATH" && execute_with_log python3 recon.py "$@" ); exit $?; fi
    PY_FILE=$(find "$TOOL_PATH" -maxdepth 1 -iname "*.py" | head -n 1)
    if [ -n "$PY_FILE" ]; then execute_with_log python3 "$PY_FILE" "$@"; exit 0; fi
    RB_FILE=$(find "$TOOL_PATH" -maxdepth 1 -iname "*.rb" | head -n 1)
    if [ -n "$RB_FILE" ]; then execute_with_log ruby "$RB_FILE" "$@"; exit 0; fi
    SH_FILE=$(find "$TOOL_PATH" -maxdepth 1 -iname "*.sh" | head -n 1)
    if [ -n "$SH_FILE" ]; then execute_with_log bash "$SH_FILE" "$@"; exit 0; fi
    if [ "$TOOL_NAME" == "WhatWeb" ] && [ -f "$TOOL_PATH/whatweb" ]; then execute_with_log ruby "$TOOL_PATH/whatweb" "$@"; exit 0; fi
    if [ "$TOOL_NAME" == "wafw00f" ] && [ -f "$TOOL_PATH/wafw00f/main.py" ]; then execute_with_log python3 "$TOOL_PATH/wafw00f/main.py" "$@"; exit 0; fi
    EXE_FILE=$(find "$TOOL_PATH" -maxdepth 1 -type f -executable | head -n 1)
    if [ -n "$EXE_FILE" ]; then execute_with_log "$EXE_FILE" "$@"; exit 0; fi
fi

if [ "$TOOL_NAME" == "searchsploit" ] && [ -f "$ARCHIVES_DIR/exploitdb/searchsploit" ]; then
    execute_with_log "$ARCHIVES_DIR/exploitdb/searchsploit" "$@"; exit 0
fi

echo "[-] Tool '$TOOL_NAME' tidak ditemukan."
rm -f "$LOG_FILE"
exit 1
WEOF
chmod +x "$ENGINE_DIR/weapons.sh"

echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
echo "========================================="
echo "   INSTALASI SELESAI & STRUKTUR SIAP!    "
echo "========================================="
