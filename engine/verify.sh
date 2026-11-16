#!/bin/bash

# ==============================================================================
# VERIFY.SH V11 (Final Check: Proxy & Language)
# ==============================================================================

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ ! -d "$BASE_DIR/engine" ]; then
    echo -e "\033[0;31m[-] Error: Tidak bisa menemukan folder 'engine' di $BASE_DIR\033[0m"
    exit 1
fi

TOOLS_DIR="$BASE_DIR/tools"
ENGINE_DIR="$BASE_DIR/engine"
GO_BIN_DIR="$HOME/go/bin"

C_GREEN='\033[0;32m'
C_CYAN='\033[0;36m'
C_YELLOW='\033[1;33m'
C_RED='\033[0;31m'
C_NC='\033[0m'

log_info() { echo -e "${C_CYAN}[*] $1${C_NC}"; }
log_success() { echo -e "${C_GREEN}[+] $1${C_NC}"; }
log_warn() { echo -e "${C_YELLOW}[!] $1${C_NC}"; }
log_error() { echo -e "${C_RED}[-] $1${C_NC}"; }

echo "[*] Memulai Verifikasi Universal..."
echo "[*] Root Project: $BASE_DIR"
termux-wake-lock

# 1. CEK FOLDER TOOLS/
log_info "Mengecek folder 'tools/' dan dependensinya..."
if [ -d "$TOOLS_DIR" ]; then
    for dir in "$TOOLS_DIR"/*/; do
        tool_name=$(basename "$dir")
        if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
            log_error "$tool_name (Folder kosong/korup)."
        else
            log_success "$tool_name (Folder Aman)"
            if [ -f "$dir/requirements.txt" ]; then
                log_info "  -> Cek dependensi Python untuk $tool_name..."
                if ! pip check >/dev/null 2>&1; then
                    ( cd "$dir" && pip install -r requirements.txt )
                else
                    log_success "  -> Dependensi Python Aman."
                fi
            fi
            if [ -f "$dir/package.json" ]; then
                if [ ! -d "$dir/node_modules" ]; then ( cd "$dir" && npm install ); fi
            fi
            if [ -f "$dir/composer.json" ]; then
                if [ ! -d "$dir/vendor" ]; then ( cd "$dir" && composer install ); fi
            fi
        fi
    done
else
    log_warn "Folder 'tools/' belum ada."
fi

# 2. GO BINARIES
log_info "Mengecek Go Binaries ($HOME/go/bin)..."
if [ -d "$GO_BIN_DIR" ]; then
    count=0
    for bin in "$GO_BIN_DIR"/*; do
        if [ -f "$bin" ] && [ -x "$bin" ]; then
            tool_name=$(basename "$bin")
            if "$bin" --version >/dev/null 2>&1 || "$bin" -h >/dev/null 2>&1 || "$bin" -version >/dev/null 2>&1; then
                log_success "$tool_name (Go Binary OK)"
            else
                log_warn "$tool_name (Binary gagal --version)"
            fi
            ((count++))
        fi
    done
    if [ $count -eq 0 ]; then log_warn "Tidak ada Go Binary."; fi
else
    log_warn "Folder '$GO_BIN_DIR' belum ada."
fi

# 3. SYSTEM TOOLS & PIP
log_info "Mengecek Tools via PATH (System & PIP)..."
SYSTEM_TOOLS=("python" "git" "curl" "wget" "ruby" "go" "nmap" "dig" "arjun" "ansi2txt")
for tool in "${SYSTEM_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        log_success "$tool (System Aman)"
    else
        log_warn "$tool tidak ditemukan di PATH."
    fi
done

# 4. FILE PENTING (ENGINE & PROXY)
log_info "Mengecek file khusus di folder engine/..."
if [ -f "$ENGINE_DIR/setup.sh" ] && [ -f "$ENGINE_DIR/verify.sh" ] && [ -f "$ENGINE_DIR/weapons.sh" ]; then
    log_success "engine/ (setup.sh, verify.sh, weapons.sh) Aman"
else
    log_warn "engine/ isinya tidak lengkap."
fi

if [ -f "$ENGINE_DIR/proxy_rotator.py" ]; then
    log_success "engine/proxy_rotator.py Aman"
else
    log_warn "engine/proxy_rotator.py belum ada."
fi

if [ -f "$ENGINE_DIR/lang/id.sh" ] && [ -f "$ENGINE_DIR/lang/en.sh" ]; then
    log_success "engine/lang/ (id.sh, en.sh) Aman"
else
    log_warn "engine/lang/ belum lengkap."
fi

if [ -f "$BASE_DIR/weapons/proxies_valid.txt" ]; then
    log_success "Proxy valid tersedia ($(wc -l < "$BASE_DIR/weapons/proxies_valid.txt") IP)"
else
    log_warn "Belum ada proxy valid (Jalankan Menu 8)."
fi

# 5. CEK TOOL BAWAAN LAINNYA
if [ -f "$BASE_DIR/archives/exploitdb/searchsploit" ]; then log_success "ExploitDB Aman"; else log_warn "ExploitDB belum ada."; fi
if [ -f "$BASE_DIR/weapons/linpeas.sh" ]; then log_success "LinPEAS Aman"; else log_warn "LinPEAS belum ada."; fi
if [ -f "$BASE_DIR/weapons/wordlists/rockyou.txt" ]; then log_success "Rockyou.txt Aman"; else log_warn "Rockyou.txt belum ada."; fi
if [ -f "$BASE_DIR/weapons/wordlists/common.txt" ]; then log_success "common.txt Aman"; else log_warn "common.txt belum ada."; fi

if [ -d "$TOOLS_DIR/CloudFail" ] && [ -f "$TOOLS_DIR/CloudFail/cloudfail/__init__.py" ]; then log_success "CloudFail v2 Aman"; else log_warn "CloudFail belum ada / bukan v2."; fi
if [ -d "$TOOLS_DIR/CloudRecon" ] && [ -f "$TOOLS_DIR/CloudRecon/recon.py" ]; then log_success "CloudRecon Aman"; else log_warn "CloudRecon belum ada."; fi
if command -v origindive &> /dev/null; then log_success "origindive Aman"; else log_warn "origindive belum ada."; fi
if command -v subzy &> /dev/null; then log_success "subzy Aman"; else log_warn "subzy belum ada."; fi

echo -e "\n========================================="
log_success "VERIFIKASI SELESAI!"
echo "========================================="
termux-wake-unlock
