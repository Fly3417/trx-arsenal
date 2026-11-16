#!/usr/bin/env python3
import os
import sys
import urllib.request

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORDLIST_DIR = os.path.join(BASE_DIR, "weapons", "wordlists")
SECLISTS_BASE = "https://raw.githubusercontent.com/danielmiessler/SecLists/master/"

def download_wordlist(name, path):
    if not os.path.exists(WORDLIST_DIR):
        os.makedirs(WORDLIST_DIR)
    out_path = os.path.join(WORDLIST_DIR, name)
    if os.path.exists(out_path):
        print(f"[-] File {name} sudah ada.")
        return
    print(f"[*] Mendownload {name}...")
    try:
        urllib.request.urlretrieve(SECLISTS_BASE + path, out_path)
        print(f"[+] Berhasil: {out_path}")
    except Exception as e:
        print(f"[-] Gagal: {e}")

def get_size_format(b):
    for unit in ['B', 'KB', 'MB', 'GB']:
        if b < 1024.0: return f"{b:.2f} {unit}"
        b /= 1024.0
    return f"{b:.2f} TB"

def list_wordlists():
    if not os.path.exists(WORDLIST_DIR): os.makedirs(WORDLIST_DIR)
    files = [f for f in os.listdir(WORDLIST_DIR) if os.path.isfile(os.path.join(WORDLIST_DIR, f))]
    
    while True:
        print("\033[0;36m=== WORDLIST MANAGER ===\033[0m")
        print("-" * 50)
        if not files:
            print("  (Belum ada wordlist lokal)")
        for i, filename in enumerate(files):
            filepath = os.path.join(WORDLIST_DIR, filename)
            print(f"  [{i+1}] {filename} ({get_size_format(os.path.getsize(filepath))})")
        print("-" * 50)
        print("  [D] Download Wordlist Baru")
        print("  [0] Kembali")
        
        choice = input("Pilih nomor / opsi: ").strip().upper()
        if choice == '0': break
        elif choice == 'D':
            print("\n--- Pilihan Download ---")
            print(" 1. Directory Fuzzing (common.txt)")
            print(" 2. Directory Medium (directory-list-2.3-medium.txt)")
            print(" 3. Subdomain (subdomains-top1million-5000.txt)")
            dl = input("Pilih [1-3]: ").strip()
            if dl == '1': download_wordlist("common.txt", "Discovery/Web-Content/common.txt")
            elif dl == '2': download_wordlist("directory-list-2.3-medium.txt", "Discovery/Web-Content/directory-list-2.3-medium.txt")
            elif dl == '3': download_wordlist("subdomains-top1million-5000.txt", "Discovery/DNS/subdomains-top1million-5000.txt")
            else: print("[-] Pilihan tidak valid.")
            files = [f for f in os.listdir(WORDLIST_DIR) if os.path.isfile(os.path.join(WORDLIST_DIR, f))]
        else:
            try:
                idx = int(choice) - 1
                if 0 <= idx < len(files):
                    print(f"\n\033[0;32m[+] Path Wordlist:\033[0m")
                    print(f"    {os.path.join(WORDLIST_DIR, files[idx])}\n")
                else: print("[-] Pilihan tidak valid.")
            except ValueError: print("[-] Input tidak valid.")

if __name__ == "__main__":
    list_wordlists()
