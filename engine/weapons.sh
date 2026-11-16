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
        export HTTP_PROXY="http://$RANDOM_PROXY"
        export HTTPS_PROXY="http://$RANDOM_PROXY"
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
    execute_with_log "$TOOL_NAME" "$@"
    exit $?
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
    execute_with_log "$ARCHIVES_DIR/exploitdb/searchsploit" "$@"
    exit 0
fi

echo "[-] Tool '$TOOL_NAME' tidak ditemukan."
rm -f "$LOG_FILE"
exit 1
