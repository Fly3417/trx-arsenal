#!/usr/bin/env python3
import sqlite3
import os
import sys

DB_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "targets", "trx.db")

def init_db():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS recon 
                 (id INTEGER PRIMARY KEY, domain TEXT, subdomain TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)''')
    c.execute('''CREATE TABLE IF NOT EXISTS vulnerabilities 
                 (id INTEGER PRIMARY KEY, target TEXT, vuln_type TEXT, severity TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)''')
    conn.commit()
    conn.close()

def query_vulns(severity=None, search=None):
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    query = "SELECT target, vuln_type, severity FROM vulnerabilities"
    params = []
    
    if severity or search:
        query += " WHERE"
        conditions = []
        if severity:
            conditions.append("severity = ?")
            params.append(severity.upper())
        if search:
            conditions.append("(target LIKE ? OR vuln_type LIKE ?)")
            params.extend([f"%{search}%", f"%{search}%"])
        query += " AND ".join(conditions)
    
    query += " ORDER BY id DESC"
    c.execute(query, params)
    rows = c.fetchall()
    conn.close()
    
    print("-" * 65)
    print(f"{'TARGET':<25} | {'VULN TYPE':<20} | {'SEVERITY'}")
    print("-" * 65)
    if not rows:
        print("  (Tidak ada data)")
    for row in rows:
        target = row[0][:23] + ".." if len(row[0]) > 25 else row[0]
        vuln = row[1][:18] + ".." if len(row[1]) > 20 else row[1]
        print(f"{target:<25} | {vuln:<20} | {row[2]}")
    print("-" * 65)

if __name__ == "__main__":
    init_db()
    if len(sys.argv) > 1:
        if sys.argv[1] == "init":
            print("[+] Database initialized.")
        elif sys.argv[1] == "query":
            query_vulns(severity=sys.argv[2] if len(sys.argv) > 2 else None, 
                        search=sys.argv[3] if len(sys.argv) > 3 else None)
    else:
        query_vulns()
