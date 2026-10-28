# Post-Approval Setup (5 minutes)

## When Your App Gets Approved

You'll receive a notification. Here's what to do:

---

## Step 1: Install App to Workspace

1. Go to https://api.slack.com/apps
2. Click your "Personal Assistant" app
3. Left sidebar → **"Install App"**
4. Click **"Install to Workspace"**
5. Click **"Allow"**

---

## Step 2: Copy Bot Token

After installation, you'll see:
- **Bot User OAuth Token** - starts with `xoxb-...`

**Copy this token!** You'll need it in the next step.

---

## Step 3: Install Dependencies

```bash
pip3 install -r ~/.claude/skills/work-vault/requirements.txt
```

This installs:
- `slack-bolt` - Slack Socket Mode library
- `boto3` - AWS Bedrock SDK
- `cryptography` - Secure storage fallback (Linux/unknown platforms)

---

## Step 4: Save Tokens to Secure Storage (Native Only)

**Linux users:** Install `libsecret-tools` first (if not already installed):
```bash
# Ubuntu/Debian
sudo apt-get install libsecret-tools

# Fedora/RHEL
sudo dnf install libsecret

# Arch
sudo pacman -S libsecret

# openSUSE
sudo zypper install libsecret-tools
```

**All platforms:** Run the interactive setup script:

```bash
python3 ~/.claude/skills/work-vault/scripts/save-tokens.py
```

The script will:
1. Check native storage availability (fails if unavailable)
2. Prompt for **Bot User OAuth Token** (`xoxb-...`)
3. Prompt for **App-Level Token** (`xapp-...`)
4. Save to OS-native secure storage

**Example output:**
```
Personal Assistant - Slack Token Setup
==================================================
Platform detected: macos

✅ Native secure storage available:
  • macOS Keychain (hardware-backed encryption)

Step 1: Bot User OAuth Token
  (starts with 'xoxb-')

Paste Bot Token: xoxb-123456789...

Step 2: App-Level Token
  (starts with 'xapp-')

Paste App Token: xapp-1-A123B456...

Saving tokens to secure storage...

✅ Bot token saved
✅ App token saved

==================================================
✅ Setup complete!

Tokens stored securely in macos native storage.
Encrypted at rest, accessible only to your user account.
```

**Storage by platform:**
- **macOS:** Keychain (hardware-backed encryption via Secure Enclave)
- **Windows:** Credential Manager (DPAPI encryption)
- **Linux:** Secret Service (GNOME Keyring / KDE Wallet)

**Security guarantees:**
- ✅ OS-managed encryption (no self-managed crypto)
- ✅ Hardware-backed where supported (macOS Secure Enclave)
- ✅ Access restricted to your user account
- ✅ No plaintext files anywhere
- ✅ Survives system reboots
- ✅ No password prompts (native storage handles authentication)

---

## Step 5: Configure Google OAuth (Email & Calendar Integration)

**This step is optional but recommended for full Personal Assistant features.**

### 5a. Create Google Cloud Project & Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or use existing):
   - Click project dropdown → "New Project"
   - Name: "Personal Assistant"
   - Click "Create"

3. Enable APIs:
   - [Gmail API](https://console.cloud.google.com/apis/library/gmail.googleapis.com) → Enable
   - [Calendar API](https://console.cloud.google.com/apis/library/calendar-json.googleapis.com) → Enable

4. Create OAuth credentials:
   - Go to [Credentials](https://console.cloud.google.com/apis/credentials)
   - Click "Create Credentials" → "OAuth client ID"
   - Application type: **Desktop app**
   - Name: "Personal Assistant"
   - Click "Create"
   - **Copy Client ID and Client Secret**

### 5b. Save Google Credentials

```bash
python3 ~/.claude/skills/work-vault/scripts/google_oauth.py setup
```

Paste your Client ID and Client Secret when prompted.

### 5c. Authorize Google Access

```bash
python3 ~/.claude/skills/work-vault/scripts/google_oauth.py authorize
```

This will:
1. Open browser for Google consent
2. Ask permission for Gmail (read + modify) and Calendar (read + write)
3. Save refresh token to secure storage

**Test it:**
```bash
python3 ~/.claude/skills/work-vault/scripts/google_oauth.py test
```

Should show:
```
✅ Gmail connected: your-email@example.com
✅ Calendar connected: 3 calendars found
```

**Skip this step?** Slack integration will still work, but email/calendar sections in dashboard will show "Not connected".

---

## Step 6: Start the Slack Listener

```bash
python3 ~/.claude/skills/work-vault/scripts/slack-listener.py
```

You should see:
```
✅ Starting Slack listener for work-vault...
📊 App Home: Open 'Personal Assistant' in sidebar to see dashboard
⚡ Commands: /cap, /research, /project-status, /briefing, /health
Press Ctrl+C to stop
```

---

## Step 7: Test in Slack

### Test 1: App Home Dashboard
1. Open Slack
2. In the left sidebar, look for **"Apps"** section
3. Click **"Personal Assistant"**
4. You should see your dashboard!

### Test 2: Slash Commands
Type in any Slack channel or DM:
```
/cap test message
```

You should see (only visible to you):
```
✅ Captured to vault
```

### Test 3: Other Commands
```
/briefing           # Shows today's briefing
/project-status     # Shows project status
/health             # Checks project health
/research API docs  # Queues research task
```

---

## Step 8: Set Up Auto-Start (Optional)

The setup script already created a LaunchAgent, but you need to enable it:

```bash
# Load the LaunchAgent
launchctl load ~/Library/LaunchAgents/com.work-vault.slack-listener.plist

# Verify it's running
launchctl list | grep work-vault
```

Now it will start automatically when you log in!

---

## Troubleshooting

### "Personal Assistant doesn't appear in sidebar"
- Make sure you installed the app (Step 1)
- Try clicking "+ Add apps" in the Apps section
- Restart Slack

### "Slash commands don't work"
- Make sure slack-listener.py is running
- Check for errors in the terminal
- Verify tokens are in secure storage:
  - **macOS:** `security find-generic-password -s personal-assistant-slack -a bot-token -w`
  - **Windows:** `cmdkey /list | findstr personal-assistant`
  - **Linux:** `secret-tool lookup service personal-assistant-slack account bot-token`

### "Dashboard shows 'Briefing unavailable'"
- Run `/briefing` once to generate initial data
- Check that briefing.py script works:
  ```bash
  /work-vault briefing
  ```

### "ERROR: Token not found in secure storage"
- Re-run the token setup script:
  ```bash
  python3 ~/.claude/skills/work-vault/scripts/save-tokens.py
  ```

### Linux: "secret-tool not found"
Install libsecret-tools:
- **Ubuntu/Debian:** `sudo apt-get install libsecret-tools`
- **Fedora/RHEL:** `sudo dnf install libsecret`
- **Arch:** `sudo pacman -S libsecret`
- **openSUSE:** `sudo zypper install libsecret-tools`

The app requires native secure storage and will not run without it.

---

## Success!

Once everything is working:
- ✅ App Home shows your dashboard
- ✅ Slash commands respond (only visible to you)
- ✅ Data saves to `~/work-vault/`
- ✅ Cron jobs run automatically (briefing at 6:57am, etc.)

You're ready to use Personal Assistant!

---

## Quick Reference

**View vault:**
```bash
ls ~/work-vault/
```

**Manual commands:**
```bash
/work-vault capture "text"
/work-vault briefing
/work-vault status
/work-vault health
```

**Slack commands:**
```
/cap <text>
/briefing
/project-status
/health
/research <topic>
```

**Stop listener:**
```bash
pkill -f slack-listener.py
```

**Restart listener:**
```bash
python3 ~/.claude/skills/work-vault/scripts/slack-listener.py
```

**View logs:**
```bash
tail -f ~/.work-vault-config/slack-listener.log
```
