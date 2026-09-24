#!/usr/bin/env bash
# Add the five custom fields the pipeline writes onto a HubSpot contact.
#
#   ./scripts/create-hubspot-properties.sh
#   ./scripts/create-hubspot-properties.sh --check    # list them, change nothing
#
# Run this once per HubSpot account, before the first lead. Without the fields, the
# score and the reason have nowhere to live and the contact is just a name.
#
# Safe to run twice: a field that already exists is reported and skipped, not
# duplicated or overwritten.

set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "No .env file. Copy .env.example to .env and put your HubSpot token in it."
  exit 1
fi

# shellcheck disable=SC1091
set -a; source .env; set +a

if [ -z "${HUBSPOT_TOKEN:-}" ]; then
  echo "HUBSPOT_TOKEN is empty in .env. See docs/setup-hubspot.md."
  exit 1
fi

API="https://api.hubapi.com/crm/v3/properties/contacts"
AUTH="Authorization: Bearer $HUBSPOT_TOKEN"
GROUP="contactinformation"   # where the fields appear on the contact record

# name|label|type|fieldType|description
PROPERTIES=(
  "lead_tier|Lead tier|enumeration|select|Set by the lead pipeline: hot, warm, cold, or unscored when the AI could not score it."
  "lead_score|Lead score|number|number|1-10, scored against the criteria document."
  "lead_score_reason|Why this score|string|textarea|The AI's one-sentence reason, so a salesperson can judge the lead without opening anything else."
  "lead_next_action|Suggested next action|string|text|What the pipeline suggests doing next."
  "lead_source|Lead source (pipeline)|string|text|Which source the lead came from: form, email or webhook, and which platform."
  # The lead's own words. HubSpot Notes would be the tidier home for this, but the
  # notes scopes are not offered on every free portal, and a field on the contact
  # needs no extra scope, no extra API call, and shows in the same place.
  "lead_message|Lead message|string|textarea|What the lead actually wrote, in their own words."
)

# The only field with a fixed list of values.
TIER_OPTIONS='[
  {"label":"Hot","value":"hot","displayOrder":0},
  {"label":"Warm","value":"warm","displayOrder":1},
  {"label":"Cold","value":"cold","displayOrder":2},
  {"label":"Unscored","value":"unscored","displayOrder":3}
]'

check_token() {
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" -H "$AUTH" "$API?limit=1")
  case "$code" in
    200) ;;
    401) echo "HubSpot rejected the token (401). Check HUBSPOT_TOKEN in .env."; exit 1 ;;
    403) echo "The token is valid but missing a scope (403). Add crm.schemas.contacts.write"
         echo "to the private app - see docs/setup-hubspot.md."; exit 1 ;;
    *)   echo "Unexpected reply from HubSpot (HTTP $code)."; exit 1 ;;
  esac
}

list_existing() {
  curl -s -H "$AUTH" "$API" | grep -o '"name":"lead_[a-z_]*"' | cut -d'"' -f4 | sort -u
}

check_token

if [ "${1:-}" = "--check" ]; then
  echo "Custom fields already on this HubSpot account:"
  found=$(list_existing || true)
  [ -n "$found" ] && echo "$found" | sed 's/^/  /' || echo "  (none yet)"
  exit 0
fi

echo "Adding custom contact fields to HubSpot"
existing=$(list_existing || true)

for row in "${PROPERTIES[@]}"; do
  IFS='|' read -r name label type field_type description <<< "$row"

  if echo "$existing" | grep -qx "$name"; then
    echo "  = $name already exists, leaving it alone"
    continue
  fi

  if [ "$name" = "lead_tier" ]; then
    payload=$(printf '{"name":"%s","label":"%s","type":"%s","fieldType":"%s","groupName":"%s","description":"%s","options":%s}' \
      "$name" "$label" "$type" "$field_type" "$GROUP" "$description" "$TIER_OPTIONS")
  else
    payload=$(printf '{"name":"%s","label":"%s","type":"%s","fieldType":"%s","groupName":"%s","description":"%s"}' \
      "$name" "$label" "$type" "$field_type" "$GROUP" "$description")
  fi

  response=$(curl -s -w '\n%{http_code}' -X POST "$API" \
    -H "$AUTH" -H "Content-Type: application/json" -d "$payload")
  code=$(echo "$response" | tail -1)

  if [ "$code" = "201" ]; then
    echo "  + $name created ($label)"
  else
    echo "  ! $name failed (HTTP $code)"
    echo "$response" | head -1 | cut -c1-200 | sed 's/^/      /'
  fi
done

echo
echo "Done. In HubSpot they appear under Settings -> Properties, and on every contact."
