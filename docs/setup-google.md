# Setting up Google (demo inbox, Sheet and criteria Doc)

About 25 minutes, and the fiddliest part of the whole project - almost entirely
because Gmail needs OAuth rather than a simple key. Do it once and it is done.

## Why a separate Gmail account

The pipeline reads a mailbox. Pointing it at your personal inbox during a demo means
your real email is one click from the camera. A free throwaway account also mirrors
what a client has: a `sales@` or `info@` address that leads arrive at.

## 1. Create the demo account

1. Go to **accounts.google.com/signup**.
2. Something like `clearwater.leads.demo@gmail.com` (you may need a number on the end).
3. Write the address and password in your own password manager - not in this repo.

## 2. Make lead email identifiable

Real companies have a dedicated address. We copy that with a **plus address**, which
Gmail supports for free: anything sent to `clearwater.leads.demo+leads@gmail.com`
arrives in the same inbox, and can be filtered.

In the demo account:

1. **Settings (cog) → See all settings → Filters and Blocked Addresses**.
2. **Create a new filter**.
3. In **To**, put `clearwater.leads.demo+leads@gmail.com` (your actual address).
4. **Create filter** → tick **Apply the label** → **New label** → `Leads` → **Create filter**.

Now anything sent to the `+leads` address is labelled automatically, and the pipeline
only ever looks at that label. Nothing else in the inbox is touched.

## 3. Let n8n read that inbox (OAuth)

Google will not let a program read Gmail with a simple key, so this needs an OAuth
client. It is free.

1. Go to **console.cloud.google.com** signed in as the **demo account**.
2. **Create a project** called `Clearwater Leads`.
3. **APIs & Services → Library**, search **Gmail API**, click **Enable**.
   Do the same for **Google Sheets API** and **Google Docs API**.
4. **APIs & Services → OAuth consent screen**:
   - User type: **External**
   - App name: `Clearwater Leads`, support email: the demo address
   - **Test users**: add the demo address. *(Skipping this is the usual cause of
     "app not verified" failures later.)*
5. **APIs & Services → Credentials → Create credentials → OAuth client ID**:
   - Application type: **Web application**
   - Name: `n8n`
   - **Authorised redirect URI**: paste the one n8n shows you. In n8n, start creating
     a **Gmail OAuth2** credential and it displays the URL - usually
     `http://localhost:5678/rest/oauth2-credential/callback`.
6. Copy the **Client ID** and **Client secret** into the n8n credential, then press
   **Sign in with Google** in n8n and approve as the demo account.

**The 7-day catch:** while the consent screen is in "Testing", Google expires the
connection every 7 days and n8n will stop reading the inbox. For a demo, reconnect
before you record. For a real client, either publish the app or use their Google
Workspace account, where this limit does not apply. Put this in the handover.

## 4. The Sheet and the criteria Doc

Claude creates both. What they are:

**`Clearwater Lead Ops` (Google Sheet)** - two tabs:
- **Lead Log**: one row per lead. The audit trail, and where the weekly summary counts from.
- **Quarantine**: leads that failed. Raw payload, which step failed, and the error.

**`Clearwater - Lead Scoring Criteria` (Google Doc)** - the rules the AI scores against,
in plain English. The owner edits this; the next lead uses the new rules. A copy of the
starting text is in `config/scoring-criteria.txt`.

Both are shared with your main account so you can open them while recording.

## If something goes wrong

| What you see | What it means |
|---|---|
| "This app isn't verified" | The demo address is not in **Test users** |
| n8n reads nothing after a week | The 7-day testing-mode expiry - reconnect the credential |
| `invalid_grant` | Same thing, or the clock on the machine is wrong |
| Redirect URI mismatch | The URI in Google Cloud must match n8n's exactly, including `http` and the port |
| The Gmail trigger sees nothing | Check the filter is labelling mail `Leads`, and that the test email went to the **+leads** address |

## Worth knowing for real clients

- A client on **Google Workspace** can authorise this in a minute and has no 7-day limit.
- The pipeline only ever reads mail carrying one label. Say that out loud in the sales
  call - "it never sees the rest of your inbox" answers a question people are too
  polite to ask.
- Gmail is polled about once a minute, so email leads are not instant. Form and webhook
  leads are.
