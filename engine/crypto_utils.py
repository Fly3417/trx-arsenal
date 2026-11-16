import base64

KEY = "SevenByteSecretKey2026"

def encrypt(text):
    if not text: return ""
    xored = ''.join(chr(ord(c) ^ ord(KEY[i % len(KEY)])) for i, c in enumerate(text))
    return base64.b64encode(xored.encode()).decode()

def decrypt(encoded):
    if not encoded: return ""
    try:
        xored = base64.b64decode(encoded).decode()
        return ''.join(chr(ord(c) ^ ord(KEY[i % len(KEY)])) for i, c in enumerate(xored))
    except:
        return ""
