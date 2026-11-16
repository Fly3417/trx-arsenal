#!/usr/bin/env python3
import requests
import time
import subprocess
import os
import json
import shlex
from crypto_utils import decrypt

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.json")
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def get_config():
    if not os.path.exists(CONFIG_PATH): return None
    with open(CONFIG_PATH, 'r') as f:
        cfg = json.load(f)
    if not cfg["telegram"]["enabled"]: return None
    token = decrypt(cfg["telegram"]["bot_token_encrypted"])
    chat_id = decrypt(cfg["telegram"]["chat_id_encrypted"])
    return token, chat_id

def send_msg(token, chat_id, text):
    # Telegram punya limit 4096 char, kita potong kalau kepanjangan
    if len(text) > 4000:
        text = text[:4000] + "\n\n[Output dipotong karena terlalu panjang]"
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    payload = {"chat_id": chat_id, "text": text, "parse_mode": "Markdown"}
    try:
        requests.post(url, json=payload, timeout=10)
    except Exception as e:
        print(f"Gagal kirim pesan: {e}")

def execute_command(cmd):
    try:
        # Jalanin command di folder root TRX
        result = subprocess.run(
            cmd, shell=True, cwd=BASE_DIR,
            capture_output=True, text=True, timeout=60
        )
        output = result.stdout
        if result.stderr:
            output += "\n[STDERR]\n" + result.stderr
        if not output.strip():
            output = "[Command dieksekusi, tapi tidak ada output]"
        return output
    except subprocess.TimeoutExpired:
        return "[-] Timeout: Perintah memakan waktu lebih dari 60 detik."
    except Exception as e:
        return f"[-] Error: {e}"

def start_bot():
    cfg = get_config()
    if not cfg:
        print("[-] Telegram Bot belum di-setup atau dinonaktifkan.")
        return
    token, chat_id = cfg
    print("[*] Telegram Bot Remote Shell aktif. Menunggu perintah...")
    print("[*] Kirim perintah apa saja ke bot (contoh: curl ifconfig.me)")
    print("[*] Tekan Ctrl+C untuk berhenti.")
    last_update_id = 0

    while True:
        try:
            url = f"https://api.telegram.org/bot{token}/getUpdates?offset={last_update_id+1}&timeout=30"
            r = requests.get(url, timeout=35).json()
            for item in r.get("result", []):
                last_update_id = item["update_id"]
                msg = item.get("message", {}).get("text", "")
                if not msg: continue
                
                print(f"[*] Perintah diterima: {msg}")
                send_msg(token, chat_id, f"⏳ Menjalankan: `{msg}`...")
                
                # Eksekusi
                output = execute_command(msg)
                send_msg(token, chat_id, f"```\n{output}\n```")
                
        except KeyboardInterrupt:
            print("\n[*] Bot dihentikan.")
            break
        except Exception as e:
            time.sleep(5)

if __name__ == "__main__":
    start_bot()
