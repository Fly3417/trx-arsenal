import json
import os
import requests
import sys
from crypto_utils import decrypt

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.json")

def send_telegram(msg):
    if not os.path.exists(CONFIG_PATH):
        return
    with open(CONFIG_PATH, 'r') as f:
        cfg = json.load(f)
    
    if not cfg["telegram"]["enabled"]:
        return

    token = decrypt(cfg["telegram"]["bot_token_encrypted"])
    chat_id = decrypt(cfg["telegram"]["chat_id_encrypted"])
    
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    payload = {"chat_id": chat_id, "text": msg, "parse_mode": "Markdown"}
    try:
        requests.post(url, json=payload, timeout=5)
    except:
        pass

if __name__ == "__main__":
    if len(sys.argv) > 1:
        send_telegram(" ".join(sys.argv[1:]))
