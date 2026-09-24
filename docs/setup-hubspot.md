# Setting up HubSpot (free)

About 15 minutes. You need this before the pipeline can write a single lead.

HubSpot's menus move around, so if a screen does not look exactly like this, search
their knowledge base for "private app access token" rather than hunting through menus.

## 1. Create the free account

1. Go to **hubspot.com** and choose **Get free CRM**.
2. Sign up with the **demo Gmail account** (see `setup-google.md`), not your personal
   address. It keeps the demo self-contained, and you can hand the whole account to
   nobody - it is fictional.
3. When it asks about your company, use the demo company:
   - Company name: **Clearwater Commercial Cleaning**
   - Website: you can skip it
   - Industry: Facilities / Business Services
   - Size: 1-5

No card is needed. The free CRM has no time limit.

## 2. Create a private app and copy its token

A "private app" is HubSpot's name for an API key tied to one integration.

1. In HubSpot, click the **settings cog** (top right).
2. In the left menu, go to **Integrations → Private apps**.
   *(If it is not there, look for **Data Management → Integrations**, or search
   "private apps" in the settings search box.)*
3. Click **Create a private app**.
4. **Basic info** tab: name it `Lead pipeline (n8n)`.
5. **Scopes** tab - this is the part that matters. Tick:
   - `crm.objects.contacts.read`
   - `crm.objects.contacts.write`
   - `crm.schemas.contacts.read`
   - `crm.schemas.contacts.write`   ← needed to create the custom fields

   If you also see `crm.objects.notes.read` / `.write`, you can tick them, but the
   pipeline does not need them: the lead's own words go into a `lead_message` field
   on the contact instead. Not every free portal offers the notes scopes.
6. Click **Create app**, then **Continue creating**.
7. Copy the **access token**. It looks like `pat-eu1-...` or `pat-na1-...`.

**Put it straight into `.env`** in this project, on the `HUBSPOT_TOKEN=` line.
Don't paste it into a chat, and don't put it in `.env.example`.

## 3. What happens next (Claude does this part)

Running `scripts/create-hubspot-properties.sh` adds six custom fields to the contact
record, so a lead's score is visible in HubSpot itself rather than hidden in n8n:

| Field | What it holds |
|---|---|
| `lead_tier` | hot / warm / cold / unscored |
| `lead_score` | 1-10 |
| `lead_score_reason` | why the AI scored it that way |
| `lead_next_action` | what to do next |
| `lead_source` | form / email / webhook, and which platform |
| `lead_message` | what the lead actually wrote |

They appear in HubSpot under **Settings → Properties**, and on every contact record.

## If something goes wrong

| What you see | What it means |
|---|---|
| `401 Unauthorized` | The token is wrong, or was copied with a space at the end |
| `403 Forbidden` with a scope name | That scope was not ticked - edit the private app and add it |
| The custom fields do not appear | `crm.schemas.contacts.write` is missing |
| There is no "notes" scope in the list | Expected on some portals. The pipeline does not use notes. |
| Two contacts with the same email | Should be impossible; HubSpot keys contacts on email |

## Worth knowing for real clients

- The free tier allows **1,000,000 contacts** and roughly **100 API calls per 10
  seconds**, which is far beyond what a lead pipeline needs.
- A client with an existing HubSpot account creates the private app themselves and
  sends you only the token. You never need their password.
- If a client uses Pipedrive, Zoho or Salesforce instead, only the CRM step of the
  pipeline changes. Everything else - the scoring, the routing, the quarantine - stays.
