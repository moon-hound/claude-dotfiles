# Personal Assistant Slack App - Approval Request Summary

## App Overview
**Name:** Personal Assistant  
**Purpose:** Personal productivity tool for organizing work notes, tracking projects, and maintaining structured knowledge  
**Type:** Individual productivity assistant (each user runs their own instance)  
**Deployment Model:** Pilot (Ryan Jacke) → Team rollout once validated  
**Architecture:** Local-first (data stored on each user's machine, not in Slack infrastructure)

---

## Configuration Complete

All app configuration has been completed and is ready for approval:

✅ **Socket Mode enabled** - Secure WebSocket connection (no public webhooks)  
✅ **App Home configured** - Personal dashboard tab in Slack sidebar  
✅ **5 Slash commands created:**
- `/cap` - Capture a work item
- `/briefing` - Show today's briefing
- `/project-status` - Show project status
- `/health` - Check project health
- `/research` - Queue a research task

✅ **Event subscriptions configured:**
- `app_home_opened` - Updates dashboard when opened
- `file_shared` - Receives file uploads for AI classification and vault storage

✅ **Bot scopes configured:**
- `chat:write` - Send ephemeral responses (visible only to user)
- `commands` - Handle slash commands
- `files:read` - Download files uploaded by user for classification
- `app_mentions:read` - Optional scope for future enhancements

---

## Security & Privacy Summary

**Data Storage:**
- All work content stored locally at `~/work-vault/` on user's Mac
- No data persisted in Slack infrastructure beyond OAuth tokens
- Slack app sees only:
  - Content explicitly sent via slash commands
  - Files explicitly uploaded/shared with the app
  - Email summaries (if Google OAuth configured)
  - Calendar events (if Google OAuth configured)

**Token Security:**
- OAuth tokens stored in OS-native secure storage only (no fallbacks):
  - **macOS:** Keychain with hardware-backed encryption (Secure Enclave on supported hardware)
  - **Windows:** Credential Manager with DPAPI encryption
  - **Linux:** Secret Service (GNOME Keyring / KDE Wallet) - requires `libsecret-tools`
- OS-managed encryption (no self-managed cryptography)
- Access restricted to user account only
- No plaintext credentials in filesystem
- Installation fails if native storage unavailable (security by design)

**Network Access:**
- Socket Mode connection (secure WebSocket, no exposed endpoints)
- AI classification via AWS Bedrock (user's own credentials)
- **Optional:** Google Workspace APIs (Gmail, Calendar) via user's OAuth consent
  - User must explicitly authorize via OAuth 2.0 flow
  - Scopes: `gmail.readonly`, `gmail.modify`, `calendar.readonly`, `calendar.events`
  - Tokens stored in OS-native secure storage only
  - Can be revoked anytime at myaccount.google.com/permissions
- No third-party data sharing beyond user-authorized Google APIs

**Workspace Impact:**
- Single-user tool - no access to team channels, messages, or other users' data
- Ephemeral responses (only command user sees output)
- Personal App Home tab (not visible to others)
- No workspace-wide settings or configurations

**Permissions Requested:**
- `chat:write` - Send responses visible only to user
- `commands` - Receive slash command text
- `files:read` - Download files uploaded by user (50MB limit enforced)
- `connections:write` - Maintain Socket Mode connection
- No message history, no channel reading, no access to other users' files

---

## What Happens After Approval

Once the app is approved and installed:

### 1. You'll receive Bot Tokens
- **Bot User OAuth Token** (starts with `xoxb-...`)
- **App-Level Token** (starts with `xapp-...`) - already generated

### 2. Install dependencies:
```bash
pip3 install -r ~/.claude/skills/work-vault/requirements.txt
```

**Linux users also need:**
```bash
# Ubuntu/Debian
sudo apt-get install libsecret-tools

# Fedora/RHEL
sudo dnf install libsecret

# Arch
sudo pacman -S libsecret
```

### 3. Save tokens to secure storage (native only):
```bash
python3 ~/.claude/skills/work-vault/scripts/save-tokens.py
```

This script checks for OS-native secure storage and fails if unavailable:
- **macOS:** Keychain (hardware-backed)
- **Windows:** Credential Manager (DPAPI)
- **Linux:** Secret Service (requires libsecret-tools)

### 4. Start the listener:
```bash
python3 ~/.claude/skills/work-vault/scripts/slack-listener.py
```

### 5. (Optional) Configure Google OAuth for Email & Calendar:

**Skip this step if you only want Slack note capture.** Email/calendar features will show "Not connected" in dashboard.

**If you want email/calendar integration:**

**5a. Create Google Cloud OAuth credentials:**
1. Go to https://console.cloud.google.com/
2. Create new project: "Personal Assistant"
3. Enable APIs: Gmail API, Google Calendar API
4. Create OAuth 2.0 Client ID (Desktop app type)
5. Download credentials JSON file

**5b. Save credentials to secure storage:**
```bash
python3 ~/.claude/skills/work-vault/scripts/google_oauth.py setup
```

Paste Client ID and Client Secret when prompted (from credentials JSON file).

**5c. Authorize access:**
```bash
python3 ~/.claude/skills/work-vault/scripts/google_oauth.py authorize
```

This opens browser for OAuth consent. Approve access to Gmail (read/modify) and Calendar (read/write).

**Scopes requested:**
- `gmail.readonly` - Read email metadata and content
- `gmail.modify` - Mark emails as read, archive emails
- `calendar.readonly` - Read calendar events
- `calendar.events` - Create calendar events

**Data handling:**
- Email summaries (unread count, action items) shown in App Home dashboard
- Calendar events (today's schedule, next meeting countdown) shown in dashboard
- No emails or events stored permanently - only live API queries
- Refresh token stored in OS-native secure storage only
- Can revoke access anytime at https://myaccount.google.com/permissions

**5d. Test connection:**
```bash
python3 ~/.claude/skills/work-vault/scripts/google_oauth.py test
```

### 6. Use the app:
- Open Slack → Click "Personal Assistant" in sidebar → See dashboard with:
  - Today's briefing (active projects, capture queue)
  - Email summary (unread count, action items) - if Google OAuth configured
  - Calendar summary (next meeting, today's events) - if Google OAuth configured
  - Recent file uploads
- Type `/cap <text>` to capture items
- Type `/briefing` to see today's briefing
- Type `/project-status` for project status
- Type `/health` for project health check
- Type `/research <topic>` to queue research
- Upload files via Slack → AI classifies and stores in vault (50MB limit)

---

## How It Works (Technical)

### Capture Flow
```
User types /cap "meeting notes"
         ↓
Slack sends command to app (via Socket Mode WebSocket)
         ↓
slack-listener.py running on user's Mac receives it
         ↓
Calls capture.py script → writes to ~/work-vault/00-CAPTURE/
         ↓
Calls Claude AI via Bedrock to classify content
         ↓
Moves file to appropriate folder (e.g., 01-ACTIVE/projects/sales/)
         ↓
Responds to Slack (ephemeral - only user sees "✅ Captured to vault")
```

### File Upload Flow
```
User uploads file in Slack (drag & drop or attach)
         ↓
Slack sends file_shared event (via Socket Mode)
         ↓
slack-listener.py downloads file (<50MB only)
         ↓
Calls Claude AI via Bedrock to classify file
         ↓
Stores in ~/work-vault/01-ACTIVE/projects/{project}/files/ or 02-RESOURCES/files/
         ↓
Logs to recent-uploads.json for dashboard display
         ↓
Responds to Slack (ephemeral - shows classification reasoning)
```

### Email/Calendar Integration (Optional)
```
User opens App Home dashboard
         ↓
slack-listener.py calls Gmail API → get unread count
         ↓
slack-listener.py calls Claude AI → extract action items from recent emails
         ↓
slack-listener.py calls Calendar API → get today's events, next meeting
         ↓
Dashboard displays email summary + calendar summary
         ↓
No permanent storage - live API queries only
```

**Key Points:**
- All processing happens on user's Mac
- Slack only relays commands and responses
- No data stored in Slack infrastructure
- Socket Mode = no public webhooks, more secure
- Google APIs only accessed if user completes OAuth setup
- Email/calendar data queried live (not stored)

---

## Approval Checklist

What approvers should verify:

- [ ] App uses Socket Mode (no public webhooks) ✅
- [ ] Permissions are minimal (chat:write, commands, connections:write) ✅
- [ ] No access to team data (channels, messages, other users' files) ✅
- [ ] Responses are ephemeral (not visible to others) ✅
- [ ] Single-user tool (no multi-user features) ✅
- [ ] Data stored locally (not in Slack infrastructure) ✅
- [ ] Can be uninstalled without affecting workspace ✅

---

## Support & Questions

**Common Questions:**

**Q: Will this affect other users?**  
A: No. It's a personal productivity tool. Other users won't see it unless they install it themselves.

**Q: What data does the app collect?**  
A: Only content you explicitly provide:
- Text sent via slash commands
- Files you upload/share with the app (50MB limit)
- Email summaries (if you configure Google OAuth)
- Calendar events (if you configure Google OAuth)
No message history, no channel data, no access to other users' files.

**Q: Where is data stored?**  
A: Locally on your Mac at `~/work-vault/`. Nothing stored in Slack infrastructure.

**Q: Can workspace admins see my data?**  
A: No. App Home dashboard is personal (only you can see it). Slash command responses are ephemeral (only you see them).

**Q: What happens if I uninstall the app?**  
A: Local files at `~/work-vault/` remain intact. OAuth tokens are revoked. No impact on workspace or other users.

**Q: Does this require any server infrastructure?**  
A: No. Runs entirely on your Mac. No servers, no hosting, no maintenance.

**Q: Why does the app want email and calendar access?**  
A: Email/calendar integration is **optional**. It enables the dashboard to show:
- Unread email count + AI-extracted action items
- Next meeting countdown + today's schedule
You must explicitly authorize via Google OAuth (can skip if you only want Slack note capture).

**Q: What email/calendar data is stored?**  
A: None permanently. Dashboard queries Gmail/Calendar APIs live when opened. Email summaries and calendar events are not saved to disk - only displayed in real-time dashboard.

**Q: Can I revoke email/calendar access later?**  
A: Yes. Revoke at https://myaccount.google.com/permissions anytime. Dashboard will show "Not connected" after revocation.

---

## Next Steps

1. **Submit for approval** (if required by workspace admin)
2. **Wait for approval notification**
3. **After approval:**
   - Install app to workspace
   - Copy Bot User OAuth Token
   - Save tokens to config file
   - Start slack-listener.py
   - Open "Personal Assistant" in Slack sidebar

---

## Files & Documentation

All setup files are located at:
```
~/.claude/skills/work-vault/
├── APP_HOME_SETUP.md        - Complete setup guide
├── APPROVAL_REQUEST.md      - This document
├── SKILL.md                 - Full skill documentation (720 lines)
├── scripts/
│   ├── slack-listener.py    - Main Slack integration (500+ lines)
│   ├── capture.py           - Capture & classify
│   ├── briefing.py          - Generate briefings
│   ├── status.py            - Project status
│   └── health.py            - Health checks
└── prompts/                 - AI prompts for classification
```

**App Configuration URL:**  
https://api.slack.com/apps (search for "Personal Assistant" or "Personal Assistant")

---

## Contact

If approvers have questions about the app, they can:
- Review the app configuration at api.slack.com/apps
- Check the detailed technical description (provided during app creation)
- Review this document for architecture details

**No external support needed** - this is a self-contained, single-user tool with no ongoing maintenance or external dependencies.
