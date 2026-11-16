import json
import os
import sys
from crypto_utils import encrypt

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.json")

def load_config():
    with open(CONFIG_PATH, 'r') as f:
        return json.load(f)

def save_config(cfg):
    with open(CONFIG_PATH, 'w') as f:
        json.dump(cfg, f, indent=4)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 config_manager.py <set_token> <token> <chat_id>")
        sys.exit(1)
    
    if sys.argv[1] == "set_token":
        token = sys.argv[2]
        chat_id = sys.argv[3]
        cfg = load_config()
        cfg["telegram"]["bot_token_encrypted"] = encrypt(token)
        cfg["telegram"]["chat_id_encrypted"] = encrypt(chat_id)
        cfg["telegram"]["enabled"] = True
        save_config(cfg)
        print("[+] Token dan Chat ID berhasil di-encrypt dan disimpan!")
