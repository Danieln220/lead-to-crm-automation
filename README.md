# Lead-to-CRM Automation

An n8n pipeline that captures leads from a website form, email and ad platforms, scores each one with AI against criteria the business writes in plain English, saves it to HubSpot without duplicates, and alerts the owner on Telegram the moment a hot lead arrives.

Demo client: **Clearwater Commercial Cleaning**, a Portland office-cleaning company that sells recurring contracts to other businesses.

## Features

- **Three lead sources:** a hosted website form, a Gmail inbox, and a secured webhook for Facebook Ads, Google Ads, Typeform or any other tool that sends JSON.
- **AI scoring from a Google Doc.** The owner edits the criteria in plain English, and the next lead is scored by the new rules. No changes in n8n are needed.
- **No duplicate contacts.** HubSpot's create-or-update is keyed on email, and returning contacts are flagged as a buying signal.
- **Alerts only when they matter.** Hot leads go to Telegram with the reason, a suggested next step and a link to HubSpot. Warm and cold leads go to the CRM quietly.
- **Nothing is lost.** Any lead that cannot be processed lands in a Quarantine sheet with its original data, and the owner is alerted.
- **Weekly summary.** Every Monday morning the owner gets lead counts by tier and source, plus the top hot leads.

## How it works

```
Form ────┐
Gmail ───┼→ normalise → validate → AI score → HubSpot → Lead Log → route
Webhook ─┘                 │                                       ├ hot  → Telegram alert
                           ▼                                       ├ warm → CRM
                  Quarantine + alert                               └ cold → CRM
```

Each source converts its input into one standard lead format and hands it to a single core workflow. Adding a new source means adding one small workflow; the core logic is never copied.

### Hot lead alert

```
🔥 HOT LEAD - 10/10

James Carter, Meridian Partners
12,000 sq ft · nightly · Portland

Why: Meridian Partners wants nightly cleaning for a 12,000 sq ft floor in
Portland starting next month and requests a walkthrough for a quote.
Next: Call today to schedule the walkthrough and discuss pricing.

📧 j.carter@meridian-partners-demo.com
📞 503-555-0142

Open in HubSpot →
```

### Weekly summary

```
📊 Weekly leads · Sep 21–27

10 leads: 🔥 7 hot · 0 warm · 3 cold
Form 4 · Facebook Ads 3 · Email 2 · Google Ads 1
🔁 4 from returning contacts

Top hot leads
1. Northwind Legal – 10/10 – 12,000 sq ft office in Portland, nightly cleaning…
2. Meridian Partners – 10/10 – nightly cleaning for a 12,000 sq ft floor…
3. Cedar Park Family Medicine – 9/10 – clinic in Tigard, three evenings a week…

⚠️ 12 items waiting in the Quarantine tab
```

## Workflows

| File | Purpose |
|---|---|
| `01-lead-source-website-form.json` | Website quote form, hosted by n8n |
| `02-lead-source-email.json` | Reads lead emails sent to the `+leads` address and extracts the details with AI |
| `03-lead-source-webhook.json` | Secured endpoint for ad platforms and form tools |
| `10-process-lead.json` | Core pipeline: validate, score, save to HubSpot, log, route |
| `20-quarantine-and-alert.json` | Error handling for failed leads and crashed workflows |
| `30-weekly-summary.json` | Monday 08:00 digest to Telegram |

## Design decisions

- **Scoring is reliable, not just plausible.** The model runs at temperature 0 behind a strict JSON schema. The tier is then recalculated from the score in code, so a mislabelled hot lead can't slip through. If scoring fails, the lead is still saved as "unscored" and flagged for a human.
- **Deduplication is HubSpot's guarantee, not a race-prone check.** Create-or-update keyed on email means two simultaneous submissions can't create two contacts.
- **Errors are designed in from the start.** Every external call has an error path to the Quarantine sheet. An Error Trigger workflow catches anything unexpected and records the failing step with a link to the execution.
- **The webhook is protected and fast.** A secret header is checked by n8n before any node runs. The sender gets `202` immediately, so ad platforms don't retry and create duplicates. An unusable payload gets `400`, so a broken integration is noticed rather than silently dropped.
- **The email source reads only one address.** Mail sent to `+leads` is processed; the rest of the inbox is never touched.
- **The weekly summary is counted, not generated.** The numbers come straight from the Lead Log, and a quiet week still sends a message, so silence never hides a fault.

## Tech stack

n8n 2.x · Groq (`gpt-oss-20b`) · HubSpot · Google Sheets, Docs and Gmail · Telegram

## Setup

### 1. Accounts

| Guide | Sets up | Time |
|---|---|---|
| [`docs/setup-hubspot.md`](docs/setup-hubspot.md) | HubSpot account, private app token, custom fields | 15 min |
| [`docs/setup-google.md`](docs/setup-google.md) | Gmail inbox, Google OAuth for n8n, the Sheet and criteria Doc | 25 min |
| [`docs/setup-telegram.md`](docs/setup-telegram.md) | Telegram alerts bot | 5 min |

```bash
cp .env.example .env                            # HubSpot token and webhook key
./scripts/create-hubspot-properties.sh          # create the custom HubSpot fields
./scripts/create-hubspot-properties.sh --check  # verify them
```

### 2. Import the workflows

```bash
n8n import:workflow --separate --input=workflows
```

Or use *Import from file* in the n8n editor. Workflow IDs are preserved, so the links between workflows keep working. Imported workflows arrive switched off.

### 3. Connect credentials

Create these in n8n, then select them in any node that shows a warning:

| Credential | Type | Used by |
|---|---|---|
| Clearwater Google Sheets | Google Sheets OAuth2 | 10, 20, 30 |
| Clearwater Google Docs | Google Docs OAuth2 | 10 |
| Clearwater Gmail (demo inbox) | Gmail OAuth2 | 02 |
| Clearwater HubSpot | HubSpot App Token | 10 |
| Clearwater Leads Bot | Telegram | 10, 20, 30 |
| Groq (Clearwater) | Groq | 02, 10 |
| Clearwater webhook key | Header Auth | 03 |

### 4. Activate in order

Switch on **20**, then **10**, then **01, 02, 03 and 30**. n8n won't activate a workflow until the sub-workflows it calls are active.

### Adapting for a new client

Replace the IDs in these nodes. The current values are listed in [`config/ids.md`](config/ids.md).

| ID | Nodes |
|---|---|
| Google Sheet | 10: *Settings*, *Write to the Lead Log* · 20: *Write to the Quarantine tab* · 30: *Read the Lead Log*, *Read the Quarantine tab* |
| Telegram chat | 10: *Settings* · 20: *Alert the owner* · 30: *Send the digest* |
| Criteria Doc, HubSpot portal | 10: *Settings* |

Then copy [`config/scoring-criteria.txt`](config/scoring-criteria.txt) into the client's own Google Doc and rewrite it for their business.

## Testing

```bash
./scripts/send-test-lead.sh               # hot | warm | cold | broken
./scripts/send-test-lead.sh hot --no-key  # confirm the webhook rejects unsigned requests
```

- **Website form:** `http://localhost:5678/form/clearwater-quote`
- **Email:** send one of the samples in `sample_data/emails/` to the `+leads` address. Gmail is checked about once a minute.

To pull the latest workflow versions out of n8n into `workflows/`:

```bash
./scripts/export-workflows.sh
```

## Repository structure

| Folder | Contents |
|---|---|
| `workflows/` | n8n workflows exported as JSON |
| `config/` | Scoring criteria template, lead schema, account IDs |
| `sample_data/` | Test leads (hot, warm, cold, broken) and sample emails |
| `scripts/` | Setup, test and export helpers |
| `docs/` | Account setup guides |
