#!/usr/bin/env python3
"""
Validates content fetched from the GitHub config repo and, if it's
well-formed, writes it over the local mirror file (domains.json or
settings.json). Used by the scheduled task after it fetches those files
from GitHub via web_fetch (bash in this sandbox can't reach GitHub
directly, so the caller fetches the text and hands it to this script via
a file, rather than passing it inline on the command line).

This exists so a bad fetch (404 page, empty body, malformed JSON) can't
clobber the local config with garbage -- if validation fails, the local
file is left untouched and this prints why.

Usage:
    python3 sync_from_github.py domains  <path-to-fetched-text-file> [folder]
    python3 sync_from_github.py settings <path-to-fetched-text-file> [folder]

folder defaults to the script's own directory.
"""
import json
import sys
from pathlib import Path

if len(sys.argv) < 3:
    print("Usage: sync_from_github.py <domains|settings> <fetched-file> [folder]", file=sys.stderr)
    sys.exit(1)

kind = sys.argv[1]
fetched_path = Path(sys.argv[2])
folder = Path(sys.argv[3]) if len(sys.argv) > 3 else Path(__file__).parent

targets = {
    "domains": folder / "domains.json",
    "settings": folder / "settings.json",
}
target = targets.get(kind)
if target is None:
    print(f"Unknown kind '{kind}', expected 'domains' or 'settings'.", file=sys.stderr)
    sys.exit(1)

if not fetched_path.exists():
    print(f"No fetched file at {fetched_path} -- leaving {target.name} untouched.")
    sys.exit(0)

raw = fetched_path.read_text().strip()
if not raw:
    print(f"Fetched content for {kind}.json was empty (likely 404 on GitHub) -- leaving {target.name} untouched.")
    sys.exit(0)

try:
    parsed = json.loads(raw)
except json.JSONDecodeError as e:
    print(f"Fetched content for {kind}.json isn't valid JSON ({e}) -- leaving {target.name} untouched.")
    sys.exit(0)

if kind == "domains" and not isinstance(parsed, list):
    print(f"domains.json from GitHub is not a JSON array -- leaving {target.name} untouched.")
    sys.exit(0)
if kind == "settings" and not isinstance(parsed, dict):
    print(f"settings.json from GitHub is not a JSON object -- leaving {target.name} untouched.")
    sys.exit(0)

target.write_text(json.dumps(parsed, indent=2))
print(f"Synced {target.name} from GitHub ({len(parsed) if kind == 'domains' else len(parsed)} top-level entries).")
