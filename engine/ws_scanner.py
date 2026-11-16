#!/usr/bin/env python3
# ==============================================================================
# TRX WEBSOCKET SCANNER (Handshake, Header, & Basic Probe)
# ==============================================================================

import socket
import ssl
import sys
import urllib.parse

def scan_websocket(url):
    parsed = urllib.parse.urlparse(url)
    host = parsed.hostname
    port = parsed.port or (443 if parsed.scheme == 'wss' else 80)
    path = parsed.path or '/'
    if parsed.query:
        path += '?' + parsed.query

    print(f"[*] Target: {host}:{port}")
    print(f"[*] Path  : {path}")
    print(f"[*] Protokol: {parsed.scheme.upper()}")

    headers = [
        f"GET {path} HTTP/1.1",
        f"Host: {host}",
        "Upgrade: websocket",
        "Connection: Upgrade",
        "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==",
        "Sec-WebSocket-Version: 13",
        "User-Agent: TRX-Arsenal-WSScanner/1.0",
        "\r\n"
    ]
    payload = "\r\n".join(headers).encode()

    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        if parsed.scheme == 'wss':
            context = ssl.create_default_context()
            sock = context.wrap_socket(sock, server_hostname=host)
        
        print("[*] Mengirim handshake...")
        sock.connect((host, port))
        sock.send(payload)
        
        response = sock.recv(4096).decode('utf-8', errors='ignore')
        sock.close()

        if "101 Switching Protocols" in response:
            print("\033[0;32m[+] WebSocket Terdeteksi! (101 Switching Protocols)\033[0m")
            print("[*] Response Headers:")
            for line in response.split('\r\n'):
                if line:
                    print(f"    {line}")
        else:
            print("\033[1;33m[!] Bukan WebSocket (Tidak ada 101 Switching Protocols).\033[0m")
            print("[*] Response mentah (100 char pertama):")
            print(f"    {response[:100]}...")

    except socket.timeout:
        print("\033[0;31m[-] Timeout. Server tidak merespon.\033[0m")
    except ssl.SSLError as e:
        print(f"\033[0;31m[-] SSL Error: {e}\033[0m")
    except Exception as e:
        print(f"\033[0;31m[-] Error: {e}\033[0m")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 ws_scanner.py <ws://target.com/path> atau <wss://target.com/path>")
        sys.exit(1)
    scan_websocket(sys.argv[1])
