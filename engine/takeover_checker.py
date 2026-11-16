import subprocess
import sys
import os
from notify import send_telegram

def check_takeover(subdomain_file):
    if not os.path.exists(subdomain_file):
        print("[-] File tidak ditemukan.")
        return
    
    print(f"[*] Memulai pengecekan Subdomain Takeover pada {subdomain_file}...")
    out_file = "reports/takeover_result.txt"
    os.makedirs("reports", exist_ok=True)
    
    try:
        with open(out_file, "w") as f:
            subprocess.run(["subzy", "run", "--targets", subdomain_file], stdout=f, stderr=subprocess.DEVNULL)
        
        # Cek apakah ada hasil (Vulnerable)
        with open(out_file, "r") as f:
            content = f.read()
            if "VULNERABLE" in content.upper():
                send_telegram(f"🚨 *Subdomain Takeover Found!*\nCek report: {out_file}")
                print("[+] Vulnerability ditemukan! Cek reports/")
            else:
                print("[*] Tidak ada takeover yang ditemukan.")
    except FileNotFoundError:
        print("[-] 'subzy' tidak ditemukan. Jalankan setup.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 takeover_checker.py <subdomain_list.txt>")
        sys.exit(1)
    check_takeover(sys.argv[1])
