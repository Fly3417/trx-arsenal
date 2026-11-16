#!/usr/bin/env python3
import subprocess
import sys
import os

def update_templates():
    print("[*] Mengupdate Nuclei Templates...")
    subprocess.run(["nuclei", "-update-templates"])

def list_templates():
    path = os.path.expanduser("~/nuclei-templates")
    if not os.path.exists(path):
        print("[-] Folder templates tidak ditemukan.")
        return
    total = sum(len(files) for _, _, files in os.walk(path))
    print(f"[*] Total template lokal: {total} file")

def run_nuclei_severity(target, severity):
    print(f"[*] Menjalankan Nuclei ke {target} (Severity: {severity})...")
    # Output otomatis disimpan lewat weapons.sh, tapi di sini kita panggil langsung
    subprocess.run(["nuclei", "-u", target, "-severity", severity])

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 nuclei_manager.py <update|list|scan>")
        sys.exit(1)
    if sys.argv[1] == "update": update_templates()
    elif sys.argv[1] == "list": list_templates()
    elif sys.argv[1] == "scan":
        target = sys.argv[2]
        severity = sys.argv[3] if len(sys.argv) > 3 else "critical,high"
        run_nuclei_severity(target, severity)
