#!/usr/bin/env python3
"""
Regenerates dashboard.html by embedding the current contents of
domains.json and history.json into dashboard_template.html.

Usage:
    python3 generate_dashboard.py [folder]

folder defaults to the script's own directory.
"""
import json
import sys
import datetime
from pathlib import Path

folder = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent

domains_path = folder / "domains.json"
history_path = folder / "history.json"
settings_path = folder / "settings.json"
template_path = folder / "dashboard_template.html"
output_path = folder / "dashboard.html"

domains = json.loads(domains_path.read_text()) if domains_path.exists() else []
history = json.loads(history_path.read_text()) if history_path.exists() else {}
settings = json.loads(settings_path.read_text()) if settings_path.exists() else {}

# lastRun = the most recent timestamp across all history entries
last_run = None
for entries in history.values():
    if entries:
        ts = entries[-1].get("timestamp")
        if ts and (last_run is None or ts > last_run):
            last_run = ts

embedded = {
    "domains": domains,
    "history": history,
    "settings": settings,
    "lastRun": last_run,
}

template = template_path.read_text()
data_js = "const EMBEDDED = " + json.dumps(embedded, indent=2) + ";"
output = template.replace("/*__EMBEDDED_DATA__*/", data_js)
output_path.write_text(output)
print(f"Wrote {output_path} (domains={len(domains)}, last_run={last_run})")
