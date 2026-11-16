#!/usr/bin/env python3
import requests, random, sys, os, concurrent.futures

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROXY_FILE = os.path.join(BASE_DIR, "weapons", "proxies.txt")
VALID_PROXY_FILE = os.path.join(BASE_DIR, "weapons", "proxies_valid.txt")
SRC_FILE = os.path.join(BASE_DIR, "weapons", "proxy_sources.txt")

DEFAULT_SOURCES = [
    "https://raw.githubusercontent.com/TheSpeedX/PROXY-List/master/http.txt",
    "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/http.txt",
    "https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/http.txt"
]

def get_sources():
    if os.path.exists(SRC_FILE):
        with open(SRC_FILE, 'r') as f:
            sources = [line.strip() for line in f if line.strip()]
            if sources: return sources
    return DEFAULT_SOURCES

def fetch_proxies():
    sources = get_sources()
    print(f"[*] Mengambil proxy dari {len(sources)} sumber...")
    proxies = set()
    for url in sources:
        try:
            r = requests.get(url, timeout=10)
            if r.status_code == 200:
                for line in r.text.strip().split('\n'):
                    if line and ':' in line:
                        proxies.add(line.strip())
            print(f"  [+] {url.split('/')[4]} -> {len(proxies)} proxy terkumpul")
        except Exception as e:
            print(f"  [-] Gagal fetch dari {url}: {e}")
    with open(PROXY_FILE, 'w') as f:
        for p in proxies: f.write(p + '\n')
    return list(proxies)

def check_proxy(proxy):
    try:
        test_url = "http://httpbin.org/ip"
        if '@' in proxy: # Format user:pass@ip:port
            auth, ip = proxy.split('@')
            proxies = {"http": f"http://{auth}@{ip}", "https": f"http://{auth}@{ip}"}
        else:
            proxies = {"http": f"http://{proxy}", "https": f"http://{proxy}"}
        r = requests.get(test_url, proxies=proxies, timeout=5)
        if r.status_code == 200: return proxy
    except: pass
    return None

def validate_proxies(proxy_list):
    print(f"[*] Memvalidasi {len(proxy_list)} proxy...")
    valid = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
        for res in executor.map(check_proxy, proxy_list):
            if res:
                valid.append(res)
                print(f"  [+] Valid: {res}")
    with open(VALID_PROXY_FILE, 'w') as f:
        for p in valid: f.write(p + '\n')
    return valid

def get_random_proxy():
    if not os.path.exists(VALID_PROXY_FILE): return None
    with open(VALID_PROXY_FILE, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]
    return random.choice(lines) if lines else None

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--export":
        p = get_random_proxy()
        print(p if p else "")
        sys.exit(0)
    raw = fetch_proxies()
    if raw: validate_proxies(raw)
