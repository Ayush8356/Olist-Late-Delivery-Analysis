"""Run sql/02..08 against MySQL and write every '-- @out: path' query to CSV. Usage: python run_queries.py"""
import csv, glob, re, sys, mysql.connector
cn = mysql.connector.connect(user="root", database="olist", unix_socket="/var/run/mysqld/mysqld.sock")
cur = cn.cursor()
for f in sorted(glob.glob("sql/0[2-8]_*.sql")):
    text = open(f).read()
    for stmt in re.split(r";\s*\n", text):
        out = re.search(r"--\s*@out:\s*(\S+)", stmt)
        body = "\n".join(l for l in stmt.splitlines() if not l.strip().startswith("--")).strip().rstrip(";")
        if not body: continue
        cur.execute(body)
        if out:
            rows = cur.fetchall()
            with open(out.group(1), "w", newline="") as fh:
                w = csv.writer(fh); w.writerow([d[0] for d in cur.description]); w.writerows(rows)
            print(f"{f} -> {out.group(1)} ({len(rows)} rows)")
        elif cur.with_rows: cur.fetchall()
cn.close()
