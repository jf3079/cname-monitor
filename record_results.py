#!/usr/bin/env python3
"""
Records fresh CNAME lookup results into history.json, computes status
for each domain (ok / changed / new / unresolved), regenerates
dashboard.html, and prints a summary so the caller knows what to
report back to the user.

Usage:
    python3 record_results.py '<results_json>' [folder]

<results_json> is a JSON object mapping domain -> resolved CNAME target
(a string with no trailing dot) or null if the domain did not resolve
to a CNAME. Example:
    '{"app.example.com": "target.hosting.com", "old.example.com": null}'

folder defaults to the script's own directory.
"""
import json
import sys
import subprocess
import datetime
from pathlib import Path

if len(sys.argv) < 2:
    print("Usage: record_results.py '<results_json>' [folder]", file=sys.stderr)
    sys.exit(1)

results = json.loads(sys.argv[1])
folder = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(__file__).parent

domains_path = folder / "domains.json"
history_path = folder / "history.json"

domains = json.loads(domains_path.read_text()) if domains_path.exists() else []
history = json.loads(history_path.read_text()) if history_path.exists() else {}

name_by_domain = {d["domain"]: d.get("name") for d in domains}
now = datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")

summary = []  # list of dicts describing anything notable this run

for domain, target in results.items():
    prior_entries = history.get(domain, [])
    prior_target = prior_entries[-1]["target"] if prior_entries else None

    if target is None:
        status = "unresolved"
    elif not prior_entries:
        status = "new"
    elif target != prior_target:
        status = "changed"
    else:
        status = "ok"

    entry = {"timestamp": now, "target": target, "status": status}
    history.setdefault(domain, []).append(entry)
    # keep history bounded per domain
    history[domain] = history[domain][-200:]

    if status in ("changed", "unresolved"):
        summary.append({
            "domain": domain,
            "name": name_by_domain.get(domain),
            "status": status,
            "previous": prior_target,
            "current": target,
        })

history_path.write_text(json.dumps(history, indent=2))

# regenerate dashboard.html
subprocess.run(
    [sys.executable, str(folder / "generate_dashboard.py"), str(folder)],
    check=True,
)

print(json.dumps({"checked": len(results), "notable": summary}, indent=2))
