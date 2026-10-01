# Where this project stands

Last updated: 2026-10-01 (M10 closed). Read this first when picking the work back up.

## Done and tested

| Milestone | What | Proven by |
|---|---|---|
| M1 | Accounts, credentials, Sheet, criteria Doc | HubSpot/Telegram/Groq APIs answered; 6 custom fields created |
| M2 | Quarantine workflow (deliberate + crash paths) | Rows written, alerts delivered; it caught real crashes during later work |
| M3 | AI scoring from the criteria Doc | Hot/warm/cold scored correctly; editing the Doc moved a lead warm 6 → hot 8 |
| M4 | HubSpot create-or-update + Lead Log | Two submissions → one contact; CRM failure → quarantine with HubSpot's own reason |
| M5 | Routing | Hot → Telegram with a HubSpot deep link; cold → silence |
| M6 | Webhook source | 403 without the key, 202 with it, 400 + quarantine for an unusable payload |
| M7 | Website form source | Daniel's own submission scored cold 2, correctly, because Herzliya is outside the service area |
| M8 | Email source | A fresh email to `+leads` (2026-09-28) was read in full: Priya Raman (from the signature), "three evenings a week", Tigard, 4,200 sq ft, hot 9/10 alert with HubSpot link. The From-address fallback now works when the email body has no address (it failed at 12:32 and was fixed; the regex was tested against the real `from` object) |
| M9 | Weekly summary | Test run on 2026-09-29 posted a real digest to Telegram: 10 leads for Sep 21–27 (7 hot, 3 cold; Form 4, Facebook Ads 3, Email 2, Google Ads 1), top 3 hot leads, 12 Quarantine items. Temporary test webhook removed afterwards |
| M10 | Export + fresh-instance import | 2026-10-01: `n8n import:workflow` into an empty n8n 2.35 (new data folder, port 5680): 6/6 imported with the same IDs, 0 broken links between workflows, 0 validation errors, started cleanly. Published 20 → 10 → 01 with no credentials, and the form served `Get a cleaning quote` (HTTP 200). Only missing piece: the 7 credentials. Install steps are in the README |

## Still to build

Next up is **Phase 4**, which needs Daniel's approval before it starts.

- **Phase 4** - DEMO.md, a reset script, HANDOFF.md.

## Things to remember

- n8n will not publish a workflow whose sub-workflow is unpublished: switch on 20, then
  10, then the rest.
- The Sheet and Telegram IDs are written into 5 and 3 nodes; a new client means editing
  each (listed in the README). Could be moved into one Settings node per workflow.
- Port 5679 is not free on this Mac: the main n8n uses it for its task runners.
- The Google credentials expire every **7 days** while the OAuth consent screen is in
  testing mode. Reconnect Gmail, Sheets and Docs in n8n before recording.
- HubSpot rejects `.example` email domains. The sample leads use `*-demo.com`.
- Test contacts are in the demo HubSpot: Northwind Legal, Meridian Partners,
  Harbourview Offices, Cedar Park. Clear them before recording.
- The Lead Log and Quarantine tabs hold test rows. Same. (The weekly digest counts
  them, so clear them before recording it.)
- Test emails sent from novizkidaniel@gmail.com show as RETURNING LEAD, because that
  address is already a HubSpot contact. For the recording, send from an address that
  isn't in HubSpot, or clear the contact first.
- Claude's own Google Sheets connector needed re-authorising on 2026-09-24; if reading
  the sheet fails, that is why.
