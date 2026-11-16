#!/usr/bin/env python3
import sys
import subprocess
import os
from datetime import datetime

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGETS_DIR = os.path.join(BASE_DIR, "targets")
PROXY_STATUS_FILE = os.path.join(BASE_DIR, "engine", ".proxy_status")

def get_proxy_status():
    if os.path.exists(PROXY_STATUS_FILE):
        with open(PROXY_STATUS_FILE, "r") as f:
            return f.read().strip()
    return "on"

def set_proxy_status(status):
    with open(PROXY_STATUS_FILE, "w") as f:
        f.write(status)

def run_command(cmd, out_file, step_name):
    print(f"\033[0;36m[*] [{step_name}] Menjalankan: {' '.join(cmd)}\033[0m")
    try:
        with open(out_file, "w") as f:
            process = subprocess.Popen(cmd, stdout=f, stderr=subprocess.PIPE, text=True)
            _, stderr = process.communicate()
            
            if process.returncode != 0:
                print(f"\033[0;31m[-] Error {step_name}: {stderr}\033[0m")
                return False
                
        with open(out_file, "r") as f:
            count = len(f.readlines())
        print(f"\033[0;32m[+] [{step_name}] Selesai. Ditemukan {count} hasil.\033[0m")
        return True
    except FileNotFoundError:
        print(f"\033[0;31m[-] Error: Tool '{cmd[0]}' tidak ditemukan.\033[0m")
        return False
    except Exception as e:
        print(f"\033[0;31m[-] Error {step_name}: {e}\033[0m")
        return False

def run_recon(domain):
    if not os.path.exists(TARGETS_DIR):
        os.makedirs(TARGETS_DIR)
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    recon_file = os.path.join(TARGETS_DIR, f"recon_{domain}_{timestamp}.txt")
    live_file = os.path.join(TARGETS_DIR, f"live_{domain}_{timestamp}.txt")
    urls_file = os.path.join(TARGETS_DIR, f"urls_{domain}_{timestamp}.txt")
    
    original_status = get_proxy_status()
    if original_status == "on":
        print("\033[0;33m[!] Proxy ON terdeteksi. Mematikan sementara untuk stabilitas Pipeline...\033[0m")
        set_proxy_status("off")
    
    # 1. SUBFINDER
    if not run_command(["subfinder", "-d", domain, "-silent"], recon_file, "Subfinder"): return
    if os.path.getsize(recon_file) == 0:
        print("\033[0;31m[-] Tidak ada subdomain ditemukan. Pipeline berhenti.\033[0m"); return

    # 2. HTTPX
    if not run_command(["httpx", "-l", recon_file, "-silent", "-o", live_file], live_file, "Httpx"): return
    if os.path.getsize(live_file) == 0:
        print("\033[0;31m[-] Tidak ada subdomain hidup. Pipeline berhenti.\033[0m"); return
        
    # 3. KATANA
    run_command(["katana", "-list", live_file, "-silent", "-o", urls_file], urls_file, "Katana")

    print("\n\033[0;33m[*] Pipeline Selesai!\033[0m")
    print(f"    - Subdomain : {recon_file}")
    print(f"    - Live URL  : {live_file}")
    print(f"    - Endpoints : {urls_file}")
    print(f"\n[*] Scan vuln: nuclei -l {urls_file}")

    if original_status == "on":
        print("\n\033[0;36m[*] Mengembalikan status Proxy ke ON...\033[0m")
        set_proxy_status("on")
        print("\033[0;32m[+] Proxy kembali aktif. (Restart Launcher untuk menerapkan)\033[0m")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 auto_recon.py <domain.com>")
        sys.exit(1)
    run_recon(sys.argv[1])
