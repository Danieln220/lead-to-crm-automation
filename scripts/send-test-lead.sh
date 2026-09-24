#!/usr/bin/env bash
# Post a sample lead to the webhook, the way an ad platform would.
#
#   ./scripts/send-test-lead.sh                 # a hot lead
#   ./scripts/send-test-lead.sh warm            # or: hot | warm | cold | broken
#   ./scripts/send-test-lead.sh hot --no-key    # prove the endpoint is protected
#
# Useful for a demo take, and for checking a client's pipeline after install.

set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
set -a; source .env; set +a

WHICH="${1:-hot}"
shift || true
USE_KEY=1
[ "${1:-}" = "--no-key" ] && USE_KEY=0

case "$WHICH" in
  hot)    FILE=sample_data/leads/hot-northwind-legal.json ;;
  warm)   FILE=sample_data/leads/warm-bright-smile-dental.json ;;
  cold)   FILE=sample_data/leads/cold-apartment-moveout.json ;;
  broken) FILE=sample_data/leads/broken-no-email.json ;;
  *) echo "Usage: ./scripts/send-test-lead.sh [hot|warm|cold|broken] [--no-key]"; exit 1 ;;
esac

URL="${N8N_URL:-http://localhost:5678}/webhook/${WEBHOOK_PATH:-clearwater-lead}"
echo "Posting the $WHICH lead to $URL"

# The sample files use the standard lead shape; a real platform would use its
# own field names, which the workflow's "Read the lead" node maps.
BODY=$(python3 -c "
import json, sys
lead = json.load(open('$FILE'))
print(json.dumps({
    'source': lead.get('source_detail', 'test'),
    'first_name': lead.get('first_name', ''),
    'last_name': lead.get('last_name', ''),
    'email': lead.get('email', ''),
    'phone': lead.get('phone', ''),
    'company': lead.get('company', ''),
    'square_feet': lead.get('office_size_sqft') or '',
    'how_often': lead.get('cleaning_frequency', ''),
    'city': lead.get('city', ''),
    'message': lead.get('message', ''),
}))")

if [ "$USE_KEY" = "1" ]; then
  curl -s -w '\nHTTP %{http_code}\n' -X POST "$URL" \
    -H 'Content-Type: application/json' -H "X-Webhook-Key: $WEBHOOK_KEY" -d "$BODY"
else
  echo "(sending WITHOUT the secret header - expect 403)"
  curl -s -w '\nHTTP %{http_code}\n' -X POST "$URL" -H 'Content-Type: application/json' -d "$BODY"
fi
