#!/usr/bin/env bash
# Export the Clearwater workflows from n8n into workflows/, ready to commit.
#
#   ./scripts/export-workflows.sh
#
# Exports only what belongs to this project (names starting "Clearwater"), and
# strips the fields that are specific to this machine - ids, timestamps, the
# shared/owner block - so a diff shows real changes rather than noise.
#
# Credential IDs are kept: on a fresh n8n the nodes show "credential not found"
# and you pick the new ones once, which is expected and documented in the README.

set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p workflows

KEY=$(python3 - <<'PY'
import re, pathlib
p = pathlib.Path.home() / ".claude.json"
m = re.search(r'"N8N_API_KEY"\s*:\s*"([^"]+)"', p.read_text()) if p.exists() else None
print(m.group(1) if m else "")
PY
)
: "${N8N_URL:=http://localhost:5678}"

if [ -z "$KEY" ]; then
  echo "No n8n API key found. Set one in n8n (Settings -> n8n API) and export N8N_API_KEY."
  exit 1
fi

# The workflows are fetched into a variable rather than piped: a heredoc below
# takes over stdin, so a pipe here would arrive empty.
WORKFLOWS=$(curl -s -H "X-N8N-API-KEY: $KEY" "$N8N_URL/api/v1/workflows?limit=100")

WORKFLOWS="$WORKFLOWS" python3 - <<'PY'
import json, os, re, pathlib

data = json.loads(os.environ["WORKFLOWS"]).get("data", [])
out = pathlib.Path("workflows")
kept = 0

for wf in data:
    if not wf["name"].startswith("Clearwater"):
        continue
    # Machine-specific noise: nothing here describes the workflow's behaviour.
    for field in ("shared", "createdAt", "updatedAt", "versionId", "activeVersionId",
                  "activeVersion", "versionCounter", "triggerCount", "meta", "staticData",
                  "pinData", "isArchived", "sourceWorkflowId", "description"):
        wf.pop(field, None)

    # "Clearwater · 20 Quarantine and alert" -> "20-quarantine-and-alert.json"
    slug = re.sub(r"^Clearwater\s*[·.-]\s*", "", wf["name"]).lower()
    slug = re.sub(r"[^a-z0-9]+", "-", slug).strip("-")
    path = out / f"{slug}.json"
    path.write_text(json.dumps(wf, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"  {path}  ({len(wf['nodes'])} nodes)")
    kept += 1

print(f"\n{kept} workflow(s) exported.")
PY
