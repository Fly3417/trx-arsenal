import sys
import re
import requests
import os
import json
from notify import send_telegram

PATTERNS = {
    "AWS Key": r"AKIA[0-9A-Z]{16}",
    "Google API": r"AIza[0-9A-Za-z-_]{35}",
    "Firebase": r"https://[a-z0-9-]+\.firebaseio\.com",
    "Bearer Token": r"Bearer\s+[A-Za-z0-9\-._~+/]+=*"
}

def scan_js(url):
    print(f"[*] Scanning: {url}")
    try:
        r = requests.get(url, timeout=5)
        text = r.text
        findings = []
        for name, pattern in PATTERNS.items():
            matches = re.findall(pattern, text)
            for m in matches:
                findings.append((name, m))
                print(f"  [!] Found {name}: {m[:20]}...")
        
        if findings:
            report_file = f"reports/js_secrets_{int(time.time())}.md"
            os.makedirs("reports", exist_ok=True)
            with open(report_file, "w") as f:
                f.write(f"# JS Secrets Found in {url}\n\n")
                for name, val in findings:
                    f.write(f"- **{name}**: `{val}`\n")
            
            send_telegram(f"🚨 *JS Secret Found!*\nURL: {url}\nTotal: {len(findings)} secret(s).")
    except Exception as e:
        print(f"  [-] Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 js_analyzer.py <url.js>")
        sys.exit(1)
    scan_js(sys.argv[1])
