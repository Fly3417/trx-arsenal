#!/usr/bin/env python3
import os
import sqlite3
import markdown
from flask import Flask, render_template_string, request

app = Flask(__name__)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(BASE_DIR, "targets", "trx.db")
REPORTS_DIR = os.path.join(BASE_DIR, "reports")

HTML_TEMPLATE = """
<!DOCTYPE html>
<html>
<head>
    <title>TRX Arsenal Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body { background-color: #0d1117; color: #c9d1d9; }
        .card { background-color: #161b22; border: 1px solid #30363d; }
        .table { color: #c9d1d9; }
        .table-hover tbody tr:hover { color: #58a6ff; background-color: #1f2428; }
        .badge-CRITICAL { background-color: #da3633; }
        .badge-HIGH { background-color: #d29922; }
        .badge-MEDIUM { background-color: #3fb950; }
        .badge-LOW { background-color: #58a6ff; }
        a { text-decoration: none; }
        @media print {
            body { background-color: white; color: black; }
            .card { border: 1px solid #ccc; background-color: white; }
            .table { color: black; }
            .badge { border: 1px solid #000; color: black; background-color: transparent !important; }
            .no-print { display: none; }
        }
    </style>
</head>
<body class="p-4">
    <div class="container">
        <h2 class="text-center mb-4">🛡️ TRX Arsenal Dashboard</h2>
        
        <form method="GET" action="/" class="row g-3 mb-4 no-print">
            <div class="col-md-5">
                <input type="text" name="search" class="form-control" placeholder="Cari Target/URL..." value="{{ search }}">
            </div>
            <div class="col-md-4">
                <select name="severity" class="form-select">
                    <option value="">Semua Severity</option>
                    <option value="CRITICAL" {% if severity == 'CRITICAL' %}selected{% endif %}>Critical</option>
                    <option value="HIGH" {% if severity == 'HIGH' %}selected{% endif %}>High</option>
                    <option value="MEDIUM" {% if severity == 'MEDIUM' %}selected{% endif %}>Medium</option>
                    <option value="LOW" {% if severity == 'LOW' %}selected{% endif %}>Low</option>
                </select>
            </div>
            <div class="col-md-3 d-flex gap-2">
                <button type="submit" class="btn btn-primary w-100">Filter</button>
                <button type="button" class="btn btn-secondary w-100" onclick="window.print()">Print</button>
            </div>
        </form>

        <div class="card p-3">
            <table class="table table-hover">
                <thead>
                    <tr><th>Target</th><th>Vulnerability</th><th>Severity</th><th>Tanggal</th></tr>
                </thead>
                <tbody>
                    {% for row in results %}
                    <tr>
                        <td><a href="/report/{{ row[1] }}" class="text-info">{{ row[0] }}</a></td>
                        <td>{{ row[1] }}</td>
                        <td><span class="badge badge-{{ row[2] }}">{{ row[2] }}</span></td>
                        <td>{{ row[3] }}</td>
                    </tr>
                    {% else %}
                    <tr><td colspan="4" class="text-center text-muted">Tidak ada data ditemukan.</td></tr>
                    {% endfor %}
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
"""

@app.route('/')
def index():
    search = request.args.get('search', '')
    severity = request.args.get('severity', '')
    query = "SELECT target, vuln_type, severity, timestamp FROM vulnerabilities WHERE 1=1"
    params = []
    if search:
        query += " AND (target LIKE ? OR vuln_type LIKE ?)"
        params.extend([f"%{search}%", f"%{search}%"])
    if severity:
        query += " AND severity = ?"
        params.append(severity)
    query += " ORDER BY timestamp DESC"
    
    results = []
    if os.path.exists(DB_PATH):
        try:
            conn = sqlite3.connect(DB_PATH)
            c = conn.cursor()
            c.execute(query, params)
            results = c.fetchall()
            conn.close()
        except Exception as e:
            print(f"DB Error: {e}")
    return render_template_string(HTML_TEMPLATE, results=results, search=search, severity=severity)

@app.route('/report/<path:filename>')
def get_report(filename):
    for f in os.listdir(REPORTS_DIR):
        if filename in f and f.endswith('.md'):
            with open(os.path.join(REPORTS_DIR, f), 'r') as file:
                content = file.read()
                html_content = markdown.markdown(content)
                return f"""
                <html><head><link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
                <style>
                    body {{ background-color: #0d1117; color: #c9d1d9; padding: 20px; }}
                    @media print {{ body {{ background-color: white; color: black; }} }}
                </style></head>
                <body><div class="container card p-4">{html_content}</div>
                <div class="mt-3 no-print"><button onclick="window.print()" class="btn btn-secondary">Print to PDF</button></div>
                </body></html>
                """
    return "Report tidak ditemukan.", 404

if __name__ == "__main__":
    print(f"[*] Web Dashboard aktif di: http://localhost:8080")
    app.run(host="0.0.0.0", port=8080, debug=False)
