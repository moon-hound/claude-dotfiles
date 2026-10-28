# App Home Setup Guide

## What You'll See

After setup, you'll have a **"Personal Assistant"** tab in your Slack sidebar that shows:

```
┌─────────────────────────────────────────┐
│  📊 Personal Assistant Dashboard                │
│                                         │
│  ☀️ Today's Briefing                    │
│  Last updated: 8:03 AM                  │
│                                         │
│  📊 Active Projects (3)                 │
│  • Sales Pipeline Review - Next: ...   │
│  • Customer Migration - Next: ...      │
│  • Docs Refresh - Next: ...            │
│                                         │
│  📥 Capture Queue: 12 items             │
│                                         │
│  ⚡ Quick Capture                       │
│  Use /cap <text> to capture items      │
│                                         │
│  🎯 System Status                       │
│  ✅ All systems healthy                 │
│  Active projects: 3 | Queue: 12        │
│                                         │
│  [📊 Status] [🔄 Refresh]               │
└─────────────────────────────────────────┘
```

## Setup Steps (5 minutes)

### 1. Go to Your Slack App Settings

1. Open https://api.slack.com/apps
2. Click your "Personal Assistant" app (or create one if you haven't yet)

### 2. Enable App Home

1. In the left sidebar, click **"App Home"**
2. Scroll to **"Show Tabs"** section
3. Toggle ON: **"Home Tab"**
4. Toggle OFF: "Messages Tab" (we don't use DMs anymore)

### 3. Add Event Subscriptions

1. In the left sidebar, click **"Event Subscriptions"**
2. Toggle ON: **"Enable Events"**
3. Under **"Subscribe to bot events"**, click **"Add Bot User Event"**
4. Add: `app_home_opened`
5. Click **"Save Changes"**

### 4. Verify Scopes (Should Already Have These)

1. In the left sidebar, click **"OAuth & Permissions"**
2. Under **"Scopes" > "Bot Token Scopes"**, verify you have:
   - `chat:write` (for slash command responses)
   - `commands` (for slash commands)
   - `app_mentions:read` (optional)

### 5. Reinstall App (If Needed)

If you just enabled App Home:

1. Click **"Install App"** in the left sidebar
2. Click **"Reinstall to Workspace"**
3. Click **"Allow"**

### 6. Restart slack-listener.py

If it's already running:

```bash
# Kill the existing process
pkill -f slack-listener.py

# The LaunchAgent will restart it automatically
# Or start manually:
python3 ~/.claude/skills/work-vault/scripts/slack-listener.py
```

### 7. Open App Home in Slack

1. Open Slack
2. In the left sidebar, look for **"Apps"**
3. Click **"Personal Assistant"** (your app name)
4. You should see the dashboard!

## Troubleshooting

### "Personal Assistant doesn't appear in sidebar"

- Make sure App Home is enabled (Step 2)
- Make sure you've added the bot to your workspace
- Try clicking "+ Add apps" in the Apps section

### "Dashboard shows 'Briefing unavailable'"

- Run `/briefing` once to generate initial data
- Check that `briefing.py` script works: `/work-vault briefing`

### "Buttons don't work"

- Make sure `app_home_opened` event is subscribed (Step 3)
- Check slack-listener.py logs for errors
- Restart the listener process

### "Still seeing old slash command responses in channel"

- This is expected! Slash commands now respond "only visible to you"
- App Home is the new primary interface

## What Changed

**Before:**
- Slash commands posted visible messages in channels/DMs
- No persistent dashboard

**After:**
- Slash commands respond ephemerally (only you see them)
- App Home provides persistent dashboard
- Click "Personal Assistant" in sidebar anytime to see current state

## Next Steps

Once App Home is working:

1. **Use the dashboard** - Click "Personal Assistant" to see live briefing
2. **Keep using slash commands** - `/cap`, `/briefing`, `/status` still work
3. **Auto-refresh** - Dashboard updates when you open it
4. **Manual refresh** - Click the "🔄 Refresh" button anytime

## Future Enhancements (Optional)

- Add Canvas integration for weekly reviews (persistent documents)
- Add interactive capture form (no slash command needed)
- Add project cards with expandable details
- Add recent documents section with links to Canvases
