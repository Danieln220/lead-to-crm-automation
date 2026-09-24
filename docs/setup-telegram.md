# Setting up the alerts bot

Five minutes. This is the bot that buzzes the owner's phone when a hot lead arrives -
the moment that sells the whole thing on camera.

Use a **separate bot** from the document assistant's. One bot per job keeps the demos
independent, and a client should never share a bot with another client.

## 1. Create the bot

1. In Telegram, search for **@BotFather** (the one with the blue tick - there are fakes).
2. Send `/newbot`.
3. Display name: `Clearwater Leads`
4. Username: `clearwater_leads_bot` (add a number if it is taken - it must end in `bot`).
5. BotFather replies with a **token** like `123456789:AA...`.

**Put the token straight into `.env`** on the `TELEGRAM_BOT_TOKEN=` line. Not into
`.env.example`, and not into a chat.

## 2. Say hello to it

Open your new bot and send it any message, e.g. `hi`.

A bot cannot start a conversation - Telegram only lets it reply to someone who has
messaged it first. Until you do this, alerts have nowhere to go.

## 3. Find your chat ID

Claude reads it from Telegram and puts it in the n8n Config node. If you want to check
it yourself:

```
! curl -s "https://api.telegram.org/bot<TOKEN>/getUpdates" | head -c 400
```

Look for `"chat":{"id":636094075` - that number is the destination for alerts.

## What the alerts look like

**A hot lead:**

> 🔥 **HOT LEAD - 9/10**
> Maria Lopez, Northwind Legal
> 12,000 sq ft office, nightly cleaning, starting in 4 weeks
> **Why:** large recurring contract in the service area, ready to start
> **Next:** call today and offer a walkthrough
> [Open in HubSpot]

**A returning lead** carries a `RETURNING LEAD` line: someone coming back is a strong
buying signal, so it is never silenced.

**A quarantined lead:**

> ⚠️ **Lead needs attention**
> A lead could not be processed and is waiting in the Quarantine sheet.
> Step: HubSpot · Error: 401 Unauthorized

Warm and cold leads send nothing. That restraint is the point: an alert that fires for
everything gets muted within a week, and then the hot ones are missed too.

## Worth knowing for real clients

- Several people can receive alerts: each messages the bot once, and their chat IDs go
  into the Config node.
- For a team, create a Telegram **group**, add the bot, and alert the group instead -
  then anyone can reply "I've got this one".
- Telegram is free and instant, with no per-message cost. For a client who lives in
  email or Slack, the alert step is the only thing that changes.
