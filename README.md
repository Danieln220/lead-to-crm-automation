# Lead-to-CRM Automation

Leads from forms, emails and webhooks are deduplicated, scored by AI against editable criteria, written to the CRM, and routed to the right alert within seconds.

> Status: in progress. M1 (accounts) and M2 (quarantine) done. Next: M3, AI scoring. See `PLAN.md` for the full plan.

Demo company: **Clearwater Commercial Cleaning**, Portland, Oregon — sells recurring office-cleaning contracts to other businesses.

## How it works

Three thin source workflows convert whatever arrives into one standard lead, then hand it to a single core workflow. Adding a fourth source means writing one small workflow, not copying the logic.

```
Form ─┐
Gmail ─┼→ normalise → validate → score (AI) → dedupe → HubSpot → log → route
Webhook ┘                   ↓ any failure                              ├ hot  → Telegram alert
                        quarantine sheet + alert                       ├ warm → CRM tag
                                                                       └ cold → CRM only
```

- **Scoring criteria live in a Google Doc**, read on every run, so the owner changes the rules from a phone without touching n8n.
- **Dedupe is real**: HubSpot's create-or-update is keyed on email, so two simultaneous submissions cannot create two contacts.
- **Nothing is lost.** Every external step has an error branch to a quarantine sheet that keeps the raw payload, plus an alert. If only the scoring fails, the lead still reaches the CRM as "unscored".

## Setup

Three accounts, each with its own guide:

| Guide | What it sets up | Time |
|---|---|---|
| [`docs/setup-hubspot.md`](docs/setup-hubspot.md) | Free HubSpot account, private app token, the five custom fields | 15 min |
| [`docs/setup-google.md`](docs/setup-google.md) | Demo Gmail inbox, the `Leads` label, OAuth for n8n, the Sheet and criteria Doc | 25 min |
| [`docs/setup-telegram.md`](docs/setup-telegram.md) | The alerts bot | 5 min |

Then:

```bash
cp .env.example .env         # add the HubSpot token and a webhook key
./scripts/create-hubspot-properties.sh          # adds the 5 custom fields
./scripts/create-hubspot-properties.sh --check  # lists them, changes nothing
```

`config/ids.md` records the Sheet and Doc IDs that go into each workflow's Config node.

## The workflows

| File | What it does | Built |
|---|---|---|
| `10-process-lead.json` | The core. Normalises, scores, deduplicates into HubSpot, logs, and routes the alert. | M3-M5 |
| `20-quarantine-and-alert.json` | The safety net. Catches a failed lead, writes it to the Quarantine tab with its raw payload, and alerts Telegram. | M2 |

It has **two ways in**, which is the point:

- **Called on purpose** by the pipeline when it knows a lead cannot continue — no email address, scoring failed, HubSpot refused. This path carries the lead itself, so the row holds enough to replay it by hand.
- **The Error Trigger**, set as the Error Workflow on every other Clearwater workflow. It catches anything unexpected — a crashed node, a dead API — and records which workflow, which step, and a link straight to the failed execution.

Built first on purpose: every later milestone wires its failures into this, rather than bolting error handling on at the end. It earned its place immediately — while building the scoring step, it caught two of my own crashes and recorded the failing node and a link to the execution.

### How the scoring is kept honest

- **The criteria are read on every lead**, straight from the Google Doc. The owner edits it in plain English and the next lead follows the new rules.
- **The shape is enforced, not requested.** A structured output parser holds the model to a JSON schema, with one automatic repair attempt.
- **The tier is recalculated from the score** in code. A model that says "score 9, tier cold" cannot quietly drop a hot lead, and the disagreement is recorded.
- **A scoring failure never costs a lead.** If Groq is down or the reply is unusable, the lead continues as `unscored` and still reaches the CRM — with an alert — rather than stopping the pipeline.
- **Temperature 0**, so the same lead always gets the same score.

### How the deduplication is guaranteed

The lead is written with HubSpot's **create-or-update, keyed on email**. HubSpot treats the email address as the contact's identity, so two submissions arriving at the same moment cannot become two contacts — the guarantee is HubSpot's, not a check of ours that could race.

A separate search runs first, but only to answer a different question: *have we heard from this person before?* A returning lead is a buying signal, so it is flagged rather than quietly merged. That search is deliberately **not** the dedupe, because HubSpot's search index lags a few seconds behind writes.

### Who gets interrupted

Only two things reach a phone: a **hot** lead, and a lead the AI **could not score**. Warm and cold sit in the CRM with their tier and reason.

That restraint is the design. An alert that fires for every lead is muted within a week, and then the hot ones are missed too.

A hot alert carries everything needed to decide whether to pick up the phone, without opening anything else:

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

A returning lead gets a **🔁 RETURNING LEAD** line above that, because someone who asks twice is more interested, not less.

If HubSpot refuses a contact, the lead does not vanish: the error output carries it — **with its score**, so the AI is not asked twice — into the quarantine sheet, and the row says exactly what HubSpot objected to.

```bash
./scripts/export-workflows.sh    # pull the workflows out of n8n into workflows/
```

## What's in here

| Folder | What it is |
|---|---|
| `workflows/` | The n8n workflows, exported as JSON |
| `config/` | The scoring criteria template, the lead schema, and where things live |
| `sample_data/` | Test leads (hot, warm, cold, broken) and two lead emails |
| `scripts/` | One-time setup and test helpers |
| `docs/` | The account setup guides |
