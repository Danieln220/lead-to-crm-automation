# Where things live

Created 2026-09-23, in the account **novizkidaniel@gmail.com**.

These IDs go into the **Config node** at the top of each n8n workflow, not into `.env`:
n8n 2.x blocks environment variables inside nodes by default, and one visible node is
easier to hand over than a hidden file.

| What | ID | Open it |
|---|---|---|
| Google Sheet `Clearwater Lead Ops` | `1dxbgI6ncxODw_r9DmxpMldxNSMuTtSyL1GNc976tQ8o` | https://docs.google.com/spreadsheets/d/1dxbgI6ncxODw_r9DmxpMldxNSMuTtSyL1GNc976tQ8o/edit |
| Google Doc `Clearwater — Lead Scoring Criteria` | `17x07fwgUzT3-4DgVGyFl998HxUs8yK-0pTqVmkHF3Ho` | https://docs.google.com/document/d/17x07fwgUzT3-4DgVGyFl998HxUs8yK-0pTqVmkHF3Ho/edit |
| Telegram chat for alerts | `636094075` (bot `@clearwater_leads_bot`) | |
| HubSpot portal | signed up as `clearwater.leads.demo15@gmail.com`, domain `clearwatercleanin.com` | https://app.hubspot.com |
| Demo inbox | `clearwater.leads.demo15@gmail.com` (leads arrive at the `+leads` address) | https://mail.google.com |
| n8n project | `NU8oxZeuhGhynCnG` (personal) | |
| n8n folder `Clearwater Leads` | `qXFnva9cOJeO8oGx` | http://localhost:5678/projects/NU8oxZeuhGhynCnG/folders/qXFnva9cOJeO8oGx/workflows |

## The Sheet

**Lead Log** — one row per lead, and the source the weekly summary counts from:

`received_at, lead_id, source, source_detail, first_name, last_name, email, phone,
company, city, office_size_sqft, tier, score, reason`

**Quarantine** — leads that failed, kept so none is ever lost:

`failed_at, source, email, company, failed_step, error, raw_payload, status`

## A note on the criteria Doc

It holds business rules only. The JSON shape the AI must return lives in the
workflow's prompt, so a client editing their own criteria cannot break the format and
stop the pipeline. `config/scoring-criteria.txt` is the starting text to copy for the
next client.

## n8n credentials

Created 2026-09-23 in the personal project. n8n keeps the secrets encrypted in its own
store; nothing here is a secret.

| Credential | Type | ID |
|---|---|---|
| Clearwater HubSpot | `hubspotAppToken` | `ooIoh2bwqMD5I2wV` |
| Clearwater Leads Bot | `telegramApi` | `tZiGZMjTYIbr0rEc` |
| Groq (Clearwater) | `groqApi` | `t3nHYVkwfyTP9BII` |
| Clearwater Gmail (demo inbox) | `gmailOAuth2` | `grxznneZKC9dle4t` |
| Clearwater Google Sheets | `googleSheetsOAuth2Api` | `8eI3u6QwX5piR4pR` |
| Clearwater Google Docs | `googleDocsOAuth2Api` | `vFRyMHolrZmKj4Fg` |

The Groq key is shared with Project 1: one free account, one key to rotate.

All six are signed in as the demo account, except HubSpot and Telegram, which use
tokens rather than a sign-in. The three Google ones share one OAuth client in the
`Clearwater Leads` Google Cloud project - which is why its consent screen expires
every 7 days while it is in testing mode.
