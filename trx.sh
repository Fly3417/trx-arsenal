#!/bin/bash
# TRX ARSENAL LAUNCHER V35 (Final: Remote Shell & Dynamic Bot)

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_DIR="$BASE_DIR/engine"
TOOLS_DIR="$BASE_DIR/tools"
TARGETS_DIR="$BASE_DIR/targets"
REPORTS_DIR="$BASE_DIR/reports"
LANG_DIR="$ENGINE_DIR/lang"
PROXY_SCRIPT="$ENGINE_DIR/proxy_rotator.py"
PROXY_VALID_FILE="$BASE_DIR/weapons/proxies_valid.txt"
PROXY_SRC_FILE="$BASE_DIR/weapons/proxy_sources.txt"
PROXY_STATUS_FILE="$ENGINE_DIR/.proxy_status"

if [ ! -f "$PROXY_SRC_FILE" ]; then
    cat << 'SRC' > "$PROXY_SRC_FILE"
https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt
https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/http.txt
https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/http.txt
SRC
fi

LANG_CONF="$ENGINE_DIR/.lang"
CURRENT_LANG="id"
if [ -f "$LANG_CONF" ]; then CURRENT_LANG=$(cat "$LANG_CONF"); fi
if [ -f "$LANG_DIR/$CURRENT_LANG.sh" ]; then source "$LANG_DIR/$CURRENT_LANG.sh"; else source "$LANG_DIR/id.sh"; fi

C_GREEN='\033[0;32m'; C_CYAN='\033[0;36m'; C_YELLOW='\033[1;33m'; C_RED='\033[0;31m'
C_MAGENTA='\033[0;35m'; C_BLUE='\033[0;34m'; C_WHITE='\033[1;37m'; C_GRAY='\033[0;90m'; C_NC='\033[0m'

TOOLS_DATA=(
    "sqlmap|py|https://github.com/sqlmapproject/sqlmap.git"
    "dirsearch|py|https://github.com/maurosoria/dirsearch.git"
    "commix|py|https://github.com/commixproject/commix.git"
    "XSStrike|py|https://github.com/s0md3v/XSStrike.git"
    "WhatWeb|ruby|https://github.com/urbanadventurer/WhatWeb.git"
    "wafw00f|py|https://github.com/EnableSecurity/wafw00f.git"
    "searchsploit|git|https://gitlab.com/exploit-database/exploitdb.git"
    "CloudFail|py|https://github.com/anmolksachan/CloudFail.git"
    "CloudRecon|py|https://github.com/intspired/CloudRecon.git"
    "origindive|go|https://github.com/jhaxce/origindive"
)

if [ ! -f "$PROXY_STATUS_FILE" ]; then echo "on" > "$PROXY_STATUS_FILE"; fi
PROXY_STATUS=$(cat "$PROXY_STATUS_FILE")

unset HTTP_PROXY; unset HTTPS_PROXY; unset ALL_PROXY

if [ "$PROXY_STATUS" == "on" ] && [ -f "$PROXY_VALID_FILE" ]; then
    RANDOM_PROXY=$(python3 "$PROXY_SCRIPT" --export 2>/dev/null)
    if [ -n "$RANDOM_PROXY" ]; then
        if [[ "$RANDOM_PROXY" == *"@"* ]]; then
            AUTH="${RANDOM_PROXY%%@*}"; IP="${RANDOM_PROXY##*@}"
            export HTTP_PROXY="http://$AUTH@$IP"; export HTTPS_PROXY="http://$AUTH@$IP"; export ALL_PROXY="http://$AUTH@$IP"
        else
            export HTTP_PROXY="http://$RANDOM_PROXY"; export HTTPS_PROXY="http://$RANDOM_PROXY"; export ALL_PROXY="http://$RANDOM_PROXY"
        fi
    fi
fi

draw_line() {
    local cols=$(tput cols 2>/dev/null || echo 50)
    if [ "$cols" -gt 60 ]; then cols=60; fi
    printf "${C_GRAY}%*s${C_NC}\n" "$cols" | tr ' ' '-'
}

load_device_info() {
    DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null | cut -c1-25)
    if [ -z "$DEVICE_MODEL" ]; then DEVICE_MODEL="Android Device"; fi
    local bat="N/A"
    if command -v termux-battery-status &> /dev/null; then
        local bj=$(termux-battery-status 2>/dev/null)
        if [ -n "$bj" ]; then
            local bp=$(echo "$bj" | grep -o '"percentage": [0-9]*' | awk '{print $2}')
            local bs=$(echo "$bj" | grep -o '"status": "[^"]*"' | cut -d'"' -f4)
            if [ -n "$bp" ]; then bat="${bp}% (${bs})"; fi
        fi
    fi
    if [ "$bat" == "N/A" ] && [ -f "/sys/class/power_supply/battery/capacity" ]; then
        bat="$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)% (Sysfs)"
    fi
    BAT_INFO="$bat"
    RAM_INFO=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3 " / " $2}')
    if [ -z "$RAM_INFO" ]; then RAM_INFO="N/A"; fi
    STORAGE_INFO=$(df -h /data 2>/dev/null | awk 'NR==2 {print $3 " / " $2}')
    if [ -z "$STORAGE_INFO" ]; then STORAGE_INFO="N/A"; fi
}

load_device_info

print_banner() {
    printf '\033[2J\033[H'
    echo -e "${C_CYAN}"
    cat << "BANNER"
  ████████╗██████╗ ██╗  ██╗
  ╚══██╔══╝██╔══██╗╚██╗██╔╝
     ██║   ██████╔╝ ╚███╔╝ 
     ██║   ██╔══██╗ ██╔██╗ 
     ██║   ██║  ██║██╔╝ ██╗
     ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝
BANNER
    echo -e "${C_NC}"
    echo -e "${C_YELLOW}  TRX ARSENAL LAUNCHER${C_NC}"
    echo -e "  ${C_RED}v1.8 (Remote Shell)${C_NC} | ${C_MAGENTA}by SevenByte${C_NC}"
    draw_line
    echo -e "  ${C_BLUE}Device   :${C_NC} $DEVICE_MODEL"
    echo -e "  ${C_BLUE}Baterai  :${C_NC} $BAT_INFO"
    echo -e "  ${C_BLUE}RAM      :${C_NC} $RAM_INFO"
    echo -e "  ${C_BLUE}Storage  :${C_NC} $STORAGE_INFO"
    if [ -n "$HTTP_PROXY" ]; then echo -e "  ${C_BLUE}Proxy    :${C_NC} ${C_GREEN}$HTTP_PROXY${C_NC}"; else echo -e "  ${C_BLUE}Proxy    :${C_NC} ${C_RED}Nonaktif (Direct IP)${C_NC}"; fi
    draw_line
    echo ""
}

render_menu() {
    local title=$1
    shift
    local items=("$@")
    echo -e "  ${C_WHITE}${title}${C_NC}"
    draw_line
    for item in "${items[@]}"; do
        local key=$(echo "$item" | cut -d'|' -f1)
        local label=$(echo "$item" | cut -d'|' -f2)
        local desc=$(echo "$item" | cut -d'|' -f3)
        if [ "$key" == "0" ]; then echo -e "  ${C_RED}[$key]${C_NC} ${C_GRAY}${label}${C_NC}"; else echo -e "  ${C_GREEN}[$key]${C_NC} ${C_WHITE}${label}${C_NC} ${C_GRAY}- ${desc}${C_NC}"; fi
    done
    draw_line
    echo ""
}

log_info() { echo -e "${C_CYAN}[*] $1${C_NC}"; }
log_success() { echo -e "${C_GREEN}[+] $1${C_NC}"; }
log_warn() { echo -e "${C_YELLOW}[!] $1${C_NC}"; }
log_error() { echo -e "${C_RED}[-] $1${C_NC}"; }
pause() { read -p "  $L_BACK"; }

is_known_tool() {
    local name=$1
    local entry
    for entry in "${TOOLS_DATA[@]}"; do
        if [ "$(echo "$entry" | cut -d'|' -f1)" == "$name" ]; then return 0; fi
    done
    return 1
}

get_all_tools() {
    local tools=()
    if [ -d "$TOOLS_DIR" ]; then for dir in "$TOOLS_DIR"/*/; do if [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then tools+=("$(basename "$dir")"); fi; done; fi
    if [ -d "$HOME/go/bin" ]; then for bin in "$HOME/go/bin"/*; do if [ -f "$bin" ] && [ -x "$bin" ]; then tools+=("$(basename "$bin")"); fi; done; fi
    echo "${tools[@]}"
}

execute_tool() {
    local tool_name=$1
    shift
    local -a tool_args=("$@")
    if [ -d "$TOOLS_DIR/$tool_name" ] || command -v "$tool_name" &> /dev/null; then
        log_info "$L_SCAN_START $tool_name ${tool_args[*]}"
        bash "$ENGINE_DIR/weapons.sh" "$tool_name" "${tool_args[@]}"
    else log_error "$L_NOT_FOUND '$tool_name'"; fi
    pause
}

# ==============================================================================
# SUBMENU 1: SYSTEM & INSTALLER
# ==============================================================================
menu_system() {
    while true; do
        print_banner
        render_menu "$L_SYS_TITLE" \
            "1|$L_SYS_1|$L_SYS_1_DESC" \
            "2|$L_SYS_2|$L_SYS_2_DESC" \
            "3|$L_SYS_3|$L_SYS_3_DESC" \
            "0|$L_SYS_0|"
        read -p "  $L_PROMPT_MENU " sys_choice
        case $sys_choice in
            1) menu_install_sub ;; 2) menu_github ;; 3) menu_settings_network ;; 0) return ;; *) log_error "$L_ERR_INVALID"; sleep 1 ;;
        esac
    done
}

menu_install_sub() {
    clear; print_banner
    render_menu "SETUP & VERIFY" "1|Setup Full|Instalasi Total" "2|Verify & Repair|Cek file korup" "0|$L_SYS_0|"
    read -p "  $L_PROMPT_MENU " choice
    case $choice in 1) bash "$ENGINE_DIR/setup.sh" ;; 2) bash "$ENGINE_DIR/verify.sh" ;; 0) return ;; esac
    pause
}

menu_github() {
    while true; do
        clear; print_banner
        render_menu "REPO & GIT AUTO-INSTALLER" "1|Clone Repo|Install tool baru" "2|Dump .git|Source code leak" "0|$L_SYS_0|"
        read -p "  $L_PROMPT_MENU " git_choice
        if [ "$git_choice" == "1" ]; then
            clear; read -p "URL Repo GitHub: " repo_url
            repo_name=$(basename "$repo_url" .git)
            read -p "Simpan di folder (Enter default: tools/$repo_name): " target_dir
            if [ -z "$target_dir" ]; then target_dir="tools/$repo_name"; fi
            mkdir -p "$BASE_DIR/$target_dir"; cd "$BASE_DIR/$target_dir" || continue
            git clone "$repo_url" . 2>/dev/null
            if [ ! -d ".git" ]; then log_error "Gagal clone repo."; cd "$BASE_DIR"; pause; continue; fi
            log_success "Repo di-clone. Cek dependencies..."
            if [ -f "requirements.txt" ]; then pip install -r requirements.txt; elif [ -f "package.json" ]; then npm install; elif [ -f "go.mod" ]; then go build -o "$repo_name"; elif [ -f "composer.json" ]; then composer install; fi
            if [ -f "setup.sh" ]; then chmod +x setup.sh && bash setup.sh; elif [ -f "install.sh" ]; then chmod +x install.sh && bash install.sh; fi
            if [[ ! "$target_dir" == tools/* ]]; then mkdir -p "$BASE_DIR/tools"; mv "$BASE_DIR/$target_dir" "$BASE_DIR/tools/$repo_name"; fi
            cd "$BASE_DIR"; log_success "Instalasi selesai!"; pause
        elif [ "$git_choice" == "2" ]; then
            clear; read -p "$L_ENTER" target_url
            if [ -z "$target_url" ]; then log_error "$L_ERR_URL"; pause; continue; fi
            target_url="${target_url%/}"; domain_name=$(echo "$target_url" | sed -E 's~https?://~~' | cut -d'/' -f1)
            dump_dir="$TARGETS_DIR/dump_${domain_name}_$(date +%s)"; mkdir -p "$dump_dir"
            git-dumper "$target_url" "$dump_dir"
            if [ $? -eq 0 ]; then log_success "Dump berhasil! $dump_dir"; else log_error "Gagal dump."; fi
            pause
        elif [ "$git_choice" == "0" ]; then return; fi
    done
}

menu_settings_network() {
    while true; do
        clear; print_banner
        render_menu "$L_SYS_3" \
            "1|Ganti Bahasa|ID / EN" \
            "2|Proxy Manager|Rotator / Direct / Auth" \
            "3|Refresh Device Info|Update RAM/Baterai" \
            "4|Set Telegram Bot|Token & Chat ID (Encrypted)" \
            "0|$L_SYS_0|"
        read -p "  $L_PROMPT_MENU " settings_choice
        case $settings_choice in
            1) clear; echo -e "${C_CYAN}=== GANTI BAHASA ===${C_NC}"; echo "1. Indonesia"; echo "2. English"; read -p "  Pilih [1-2]: " lang_choice
               if [ "$lang_choice" == "1" ]; then echo "id" > "$LANG_CONF"; log_success "Bahasa diubah ke ID."; sleep 2; elif [ "$lang_choice" == "2" ]; then echo "en" > "$LANG_CONF"; log_success "Language changed to EN."; sleep 2; else log_error "$L_ERR_INVALID"; sleep 1; fi ;;
            2) 
                while true; do
                    clear; PROXY_STATUS=$(cat "$PROXY_STATUS_FILE" 2>/dev/null || echo "on"); echo -e "${C_CYAN}=== PROXY MANAGER ===${C_NC}"; echo -e "  Status Proxy: ${C_YELLOW}${PROXY_STATUS^^}${C_NC}"; draw_line
                    echo "  1. Update & Validasi (Tarik dari Link)"; echo "  2. Lihat Daftar Proxy Valid"; echo "  3. Kelola Link Sumber Proxy"
                    if [ "$PROXY_STATUS" == "on" ]; then echo "  4. Matikan Proxy (Direct IP)"; else echo "  4. Aktifkan Proxy (Rotator)"; fi
                    echo -e "  ${C_YELLOW}[0]${C_NC} Kembali"; read -p "  Pilih [0-4]: " proxy_choice
                    case $proxy_choice in
                        1) python3 "$PROXY_SCRIPT" ;;
                        2) if [ -f "$PROXY_VALID_FILE" ] && [ -s "$PROXY_VALID_FILE" ]; then nl -w2 -s". " "$PROXY_VALID_FILE" | head -n 20; else log_warn "Belum ada."; fi ;;
                        3) 
                            while true; do
                                clear; echo -e "${C_CYAN}=== LINK SUMBER PROXY ===${C_NC}"; draw_line
                                if [ -f "$PROXY_SRC_FILE" ]; then nl -w2 -s". " "$PROXY_SRC_FILE"; else log_warn "Belum ada link."; fi
                                draw_line; echo "  1. Tambah Link"; echo "  2. Hapus Link"; echo -e "  ${C_YELLOW}[0]${C_NC} Kembali"
                                read -p "  Pilih [0-2]: " src_choice
                                case $src_choice in 1) read -p "  URL: " new_src; if [ -n "$new_src" ]; then echo "$new_src" >> "$PROXY_SRC_FILE"; fi ;; 2) read -p "  Nomor: " del_idx; if [[ "$del_idx" =~ ^[0-9]+$ ]]; then sed -i "${del_idx}d" "$PROXY_SRC_FILE"; fi ;; 0) break ;; *) log_error "Invalid"; sleep 1 ;; esac
                                pause
                            done ;;
                        4) if [ "$PROXY_STATUS" == "on" ]; then echo "off" > "$PROXY_STATUS_FILE"; else echo "on" > "$PROXY_STATUS_FILE"; fi; sleep 1; exec bash "$BASE_DIR/trx.sh" ;;
                        0) break ;; *) log_error "Invalid"; sleep 1 ;;
                    esac
                    pause
                done
                ;;
            3) load_device_info; log_success "Data device di-refresh!"; sleep 1 ;;
            4)
                clear; echo -e "${C_CYAN}=== SET TELEGRAM BOT ===${C_NC}"
                read -p "  Bot Token: " bot_token; read -p "  Chat ID: " chat_id
                if [ -n "$bot_token" ] && [ -n "$chat_id" ]; then python3 "$ENGINE_DIR/config_manager.py" set_token "$bot_token" "$chat_id"; else log_error "Kosong."; fi
                pause ;;
            0) return ;; *) log_error "$L_ERR_INVALID"; sleep 1 ;;
        esac
    done
}

# ==============================================================================
# SUBMENU 2: EXPLOITATION & TOOLS
# ==============================================================================
menu_exploitation() {
    while true; do
        print_banner
        render_menu "$L_EXP_TITLE" \
            "1|$L_EXP_1|$L_EXP_1_DESC" \
            "2|$L_EXP_2|$L_EXP_2_DESC" \
            "0|$L_EXP_0|"
        read -p "  $L_PROMPT_MENU " exp_choice
        case $exp_choice in 1) menu_tools ;; 2) menu_shell ;; 0) return ;; *) log_error "$L_ERR_INVALID"; sleep 1 ;; esac
    done
}

menu_tools() {
    while true; do
        clear; echo -e "${C_CYAN}=== DAFTAR TOOLS TERINSTALL ===${C_NC}"
        INSTALLED_TOOLS=($(get_all_tools | tr ' ' '\n' | sort | uniq))
        if [ ${#INSTALLED_TOOLS[@]} -eq 0 ]; then log_warn "Belum ada tools."; pause; return; fi
        for i in "${!INSTALLED_TOOLS[@]}"; do echo -e "  [$((i+1))] ${INSTALLED_TOOLS[$i]}"; done
        echo -e "  ${C_YELLOW}[0]${C_NC} Kembali"
        read -p "  Pilih nomor: " idx
        if [ "$idx" == "0" ]; then return; fi
        if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 1 ] && [ "$idx" -le "${#INSTALLED_TOOLS[@]}" ]; then
            local selected_tool=${INSTALLED_TOOLS[$((idx-1))]}
            local SWITCH_TOOL=""
            clear; echo -e "${C_CYAN}=========================================${C_NC}"; echo -e "     ${C_YELLOW}TOOL: ${selected_tool}${C_NC}"; echo -e "     Ketik 'cd [tool]' untuk pindah."; echo -e "     Ketik '0' untuk kembali."; echo -e "${C_CYAN}=========================================${C_NC}"
            while true; do
                local cwd_short=$(echo "$PWD" | sed "s|$HOME|~|g"); local prompt_top="${C_GREEN}┌──(${C_CYAN}root㉿${selected_tool}${C_GREEN})-[${C_YELLOW}${cwd_short}${C_GREEN}]${C_NC}"; local prompt_bot="${C_GREEN}└─${C_RED}\$${C_NC} "
                read -e -p "$(echo -e "${prompt_top}\n${prompt_bot}")" -a args_array
                if [ "${args_array[0]}" == "0" ] || [ "${args_array[0]}" == "exit" ]; then break; fi
                if [ -z "${args_array[*]}" ]; then continue; fi
                if [ "${args_array[0]}" == "cd" ]; then
                    local target_tool="${args_array[1]}"
                    if [[ " ${INSTALLED_TOOLS[*]} " =~ " ${target_tool} " ]]; then SWITCH_TOOL="$target_tool"; break; else log_error "Tool tidak ada."; continue; fi
                fi
                execute_tool "$selected_tool" "${args_array[@]}"
            done
            if [ -n "$SWITCH_TOOL" ]; then
                clear; echo -e "${C_CYAN}=========================================${C_NC}"; echo -e "     ${C_YELLOW}TOOL: ${SWITCH_TOOL}${C_NC}"; echo -e "     Ketik '0' untuk kembali."; echo -e "${C_CYAN}=========================================${C_NC}"
                while true; do
                    local cwd_short=$(echo "$PWD" | sed "s|$HOME|~|g"); local prompt_top="${C_GREEN}┌──(${C_CYAN}root㉿${SWITCH_TOOL}${C_GREEN})-[${C_YELLOW}${cwd_short}${C_GREEN}]${C_NC}"; local prompt_bot="${C_GREEN}└─${C_RED}\$${C_NC} "
                    read -e -p "$(echo -e "${prompt_top}\n${prompt_bot}")" -a args_array
                    if [ "${args_array[0]}" == "0" ] || [ "${args_array[0]}" == "exit" ]; then break; fi
                    if [ -z "${args_array[*]}" ]; then continue; fi
                    execute_tool "$SWITCH_TOOL" "${args_array[@]}"
                done
            fi
        else log_error "$L_ERR_INVALID"; sleep 2; fi
    done
}

menu_shell() {
    clear; echo -e "${C_CYAN}=========================================${C_NC}"; echo -e "      TRX ARSENAL :: QUICK EXECUTOR      ${C_NC}"; echo -e "${C_CYAN}=========================================${C_NC}"
    ALL_TOOLS=($(get_all_tools | tr ' ' '\n' | sort | uniq))
    for name in "${ALL_TOOLS[@]}"; do echo -e "  ${C_GREEN}[+] $name${C_NC}"; done
    echo -e "${C_CYAN}-----------------------------------------${C_NC}"
    local ACTIVE_TOOL=""
    while true; do
        local cwd_short=$(echo "$PWD" | sed "s|$HOME|~|g")
        local prompt_user="root㉿trx"
        if [ -n "$ACTIVE_TOOL" ]; then prompt_user="root㉿${ACTIVE_TOOL}"; fi
        local prompt_top="${C_GREEN}┌──(${C_CYAN}${prompt_user}${C_GREEN})-[${C_YELLOW}${cwd_short}${C_GREEN}]${C_NC}"
        local prompt_bot="${C_GREEN}└─${C_RED}\$${C_NC} "
        read -e -p "$(echo -e "${prompt_top}\n${prompt_bot}")" input
        if [ "$input" == "0" ] && [ -z "$ACTIVE_TOOL" ]; then break; fi
        if { [ "$input" == "0" ] || [ "$input" == "exit" ]; } && [ -n "$ACTIVE_TOOL" ]; then ACTIVE_TOOL=""; continue; fi
        if [ -z "$input" ]; then continue; fi
        if [[ "$input" == cd* ]]; then
            local target_tool=$(echo "$input" | awk '{print $2}')
            if [[ " ${ALL_TOOLS[*]} " =~ " ${target_tool} " ]]; then ACTIVE_TOOL="$target_tool"; else log_error "Tool tidak ada."; fi
            continue
        fi
        if [ -n "$ACTIVE_TOOL" ]; then
            eval "ARGS_ARRAY=($input)"; execute_tool "$ACTIVE_TOOL" "${ARGS_ARRAY[@]}"
        else
            TOOL_NAME=$(echo "$input" | awk '{print $1}'); ARGS=$(echo "$input" | cut -d' ' -f2-)
            if [[ " ${ALL_TOOLS[*]} " =~ " ${TOOL_NAME} " ]]; then eval "ARGS_ARRAY=($ARGS)"; execute_tool "$TOOL_NAME" "${ARGS_ARRAY[@]}"; else eval "$input"; pause; fi
        fi
    done
}

# ==============================================================================
# SUBMENU 3: UTILITIES & REPORTING
# ==============================================================================
menu_utilities() {
    while true; do
        print_banner
        render_menu "$L_UTIL_TITLE" \
            "1|$L_UTIL_1|$L_UTIL_1_DESC" \
            "2|$L_UTIL_2|$L_UTIL_2_DESC" \
            "3|$L_UTIL_3|$L_UTIL_3_DESC" \
            "4|$L_UTIL_4|$L_UTIL_4_DESC" \
            "5|$L_UTIL_5|$L_UTIL_5_DESC" \
            "6|$L_UTIL_6|$L_UTIL_6_DESC" \
            "7|$L_UTIL_7|$L_UTIL_7_DESC" \
            "8|$L_UTIL_8|$L_UTIL_8_DESC" \
            "9|$L_UTIL_9|$L_UTIL_9_DESC" \
            "10|$L_UTIL_10|$L_UTIL_10_DESC" \
            "11|Telegram Remote Shell|Kontrol terminal via Bot" \
            "0|$L_UTIL_0|"
        read -p "  Pilih [0-11]: " util_choice
        case $util_choice in
            1) menu_recon ;; 
            2) menu_report ;; 
            3) clear; echo -e "${C_CYAN}=== LOG TO REPORT ===${C_NC}"; read -p "  Path file log: " log_path; if [ -f "$BASE_DIR/$log_path" ]; then python3 "$ENGINE_DIR/log_to_report.py" "$BASE_DIR/$log_path"; elif [ -f "$log_path" ]; then python3 "$ENGINE_DIR/log_to_report.py" "$log_path"; else log_error "File tidak ditemukan."; fi; pause ;;
            4) clear; python3 "$ENGINE_DIR/wordlist_manager.py"; pause ;;
            5) clear; echo -e "${C_CYAN}=== AUTO RECON (SUBFINDER) ===${C_NC}"; read -p "  Domain: " target_domain; if [ -n "$target_domain" ]; then python3 "$ENGINE_DIR/auto_recon.py" "$target_domain"; else log_error "Kosong."; fi; pause ;;
            6) clear; echo -e "${C_CYAN}=== JS SECRET ANALYZER ===${C_NC}"; read -p "  URL File JS: " js_url; if [ -n "$js_url" ]; then python3 "$ENGINE_DIR/js_analyzer.py" "$js_url"; else log_error "Kosong."; fi; pause ;;
            7) clear; echo -e "${C_CYAN}=== TAKEOVER CHECKER ===${C_NC}"; read -p "  Path file subdomain: " sub_file; if [ -f "$BASE_DIR/$sub_file" ]; then python3 "$ENGINE_DIR/takeover_checker.py" "$BASE_DIR/$sub_file"; elif [ -f "$sub_file" ]; then python3 "$ENGINE_DIR/takeover_checker.py" "$sub_file"; else log_error "File tidak ada."; fi; pause ;;
            8) 
                clear; echo -e "${C_CYAN}=== DATABASE VIEWER ===${C_NC}"
                echo "  1. Tampilkan Semua"; echo "  2. Filter Critical"; echo "  3. Filter High"; echo "  4. Filter Medium"; echo "  5. Filter Low"; echo "  6. Cari Target/URL"; echo -e "  ${C_YELLOW}[0]${C_NC} Kembali"
                read -p "  Pilih [0-6]: " db_choice
                case $db_choice in 1) python3 "$ENGINE_DIR/db_manager.py" query ;; 2) python3 "$ENGINE_DIR/db_manager.py" query CRITICAL ;; 3) python3 "$ENGINE_DIR/db_manager.py" query HIGH ;; 4) python3 "$ENGINE_DIR/db_manager.py" query MEDIUM ;; 5) python3 "$ENGINE_DIR/db_manager.py" query LOW ;; 6) read -p "  Masukkan kata kunci: " db_search; python3 "$ENGINE_DIR/db_manager.py" query "" "$db_search" ;; 0) continue ;; esac; pause ;;
            9) clear; echo -e "${C_CYAN}=== NUCLEI MANAGER ===${C_NC}"; echo "  1. Update Templates"; echo "  2. Lihat Total Templates"; echo "  3. Scan Target (Severity Filter)"; read -p "  Pilih [1-3]: " nucl_choice; if [ "$nucl_choice" == "1" ]; then python3 "$ENGINE_DIR/nuclei_manager.py" update; elif [ "$nucl_choice" == "2" ]; then python3 "$ENGINE_DIR/nuclei_manager.py" list; elif [ "$nucl_choice" == "3" ]; then read -p "  Target URL: " nucl_target; read -p "  Severity (critical,high): " nucl_sev; python3 "$ENGINE_DIR/nuclei_manager.py" scan "$nucl_target" "$nucl_sev"; fi; pause ;;
            10) clear; echo -e "${C_CYAN}=== WEB DASHBOARD ===${C_NC}"; python3 "$ENGINE_DIR/web_dashboard.py"; pause ;;
            11) clear; echo -e "${C_CYAN}=== TELEGRAM REMOTE SHELL ===${C_NC}"; echo "  Bot ini bisa mengeksekusi perintah terminal dari HP/PC lain."; echo "  Contoh perintah: curl ifconfig.me, ls -la, python3 engine/auto_recon.py target.com"; python3 "$ENGINE_DIR/telegram_bot.py"; pause ;;
            0) return ;; *) log_error "$L_ERR_INVALID"; sleep 1 ;; 
        esac
    done
}
menu_recon() {
    while true; do
        clear; print_banner
        render_menu "RECON & FINGERPRINT" "1|Tech Stack & WAF|Wappalyzer + Caniscrape" "2|WebSocket Scanner|Cek handshake WSS/WS" "0|Kembali|"
        read -p "  Pilih [0-2]: " recon_choice
        case $recon_choice in
            1) clear; read -p "$L_ENTER" target_url; if [ -z "$target_url" ]; then log_error "$L_ERR_URL"; pause; continue; fi
               python3 -c "import sys; from Wappalyzer import Wappalyzer, WebPage; w = Wappalyzer.latest(); p = WebPage.new_from_url(sys.argv[1]); print(w.analyze_with_versions_and_categories(p))" "$target_url"
               if command -v caniscrape &> /dev/null; then caniscrape "$target_url"; fi; pause ;;
            2) clear; read -p "Masukkan URL WebSocket (ws:// atau wss://): " ws_url; python3 "$ENGINE_DIR/ws_scanner.py" "$ws_url"; pause ;;
            0) return ;; *) log_error "$L_ERR_INVALID"; sleep 1 ;;
        esac
    done
}
menu_report() {
    clear; echo -e "${C_CYAN}=== GENERATE BUG REPORT ===${C_NC}"
    read -p "  Nama Target: " r_target; read -p "  Jenis Kerentanan: " r_vuln; read -p "  Endpoint Rentan: " r_endpoint; read -p "  Payload / PoC: " r_payload; read -p "  Impact: " r_impact
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S"); REPORT_DIR="$BASE_DIR/reports"; mkdir -p "$REPORT_DIR"; REPORT_FILE="$REPORT_DIR/${TIMESTAMP}_${r_target}.md"
    cat << REOF > "$REPORT_FILE"
# Vulnerability Report: $r_target
**Tanggal:** $(date +"%Y-%m-%d %H:%M:%S")
**Target:** $r_target
**Jenis Kerentanan:** $r_vuln
**Impact:** $r_impact
---
## Executive Summary
Ditemukan kerentanan **$r_vuln** pada target **$r_target**.
## Technical Details
- **Endpoint:** \`$r_endpoint\`
- **Payload:** \`$r_payload\`
---
*Generated by TRX Arsenal*
REOF
    log_success "Laporan dibuat: $REPORT_FILE"; pause
}

# ==============================================================================
# MAIN LOOP
# ==============================================================================
while true; do
    print_banner
    render_menu "$L_MAIN_TITLE" "1|$L_MAIN_1|$L_MAIN_1_DESC" "2|$L_MAIN_2|$L_MAIN_2_DESC" "3|$L_MAIN_3|$L_MAIN_3_DESC" "0|$L_MAIN_0|"
    read -p "  $L_PROMPT_MENU " menu
    case $menu in 1) menu_system ;; 2) menu_exploitation ;; 3) menu_utilities ;; 0) log_success "$L_EXIT"; exit 0 ;; *) log_error "$L_ERR_INVALID"; sleep 1 ;; esac
done
