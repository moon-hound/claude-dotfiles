# /ssh — Diagnose and Fix SSH Connection Issues

Quick diagnostics and fixes for SSH connection problems to THXII and other machines.

## Usage

```
/ssh [machine]
```

**No machine specified (recommended):** Tests all machines, identifies and fixes broken ones automatically

**Machine specified:** Only diagnose/fix that specific machine (`thxii`, `dojonas`, `luiha`)

## Process

### If no machine specified (auto-detect mode):

1. **Test all machines in parallel:**
   ```bash
   ssh thxii 'Write-Host "ok"' &
   ssh dojonas-exec 'echo "ok"' &
   ssh luiha 'echo "ok"' &
   wait
   ```
   Capture which ones failed and with what error

2. **For each broken machine:**
   - Load context (configs + fix docs)
   - Diagnose failure mode
   - Apply fix
   - Verify working

3. **Report:**
   - Which machines were broken
   - What was wrong with each
   - What fixes were applied
   - Final status of all three

### If machine specified:

1. **Load context for target machine:**
   - Read `~/.ssh/config` — get hostname, user, special settings
   - Read machine-specific fix doc:
     - THXII → `~/.claude/skills/ssh/thxii-fixes.md`
     - dojoNAS → `~/.claude/skills/ssh/dojonas-fixes.md`
     - luiHA → `~/.claude/skills/ssh/luiha-fixes.md`
   - Read vault doc: `~/spacedog-vault/hubs/research/graphify-output/THXII SSH Connection Drops Daily.md` for THXII historical context

2. **Test connection** — attempt SSH, capture exact error:
   - `thxii` → 192.168.1.27 (Windows, OpenSSH)
   - `dojonas-exec` → 192.168.1.234 (QNAP, use this for commands)
   - `luiha` → 192.168.3.210 (Raspberry Pi, Netbird required)

3. **Quick diagnostics** — check common failure points:
   - Is service running on target?
   - Network reachable? (ping test)
   - For luiHA: Is Netbird VPN connected?
   - For dojoNAS: Using correct alias?
   - Known issue pattern?

4. **Apply fix based on symptom:**

   **If "Connection refused" (port closed):**
   - Target machine: Check if SSH service running, start if stopped
   - Show command to restart service

   **If "Connection timed out" (network/firewall):**
   - For luiHA: Check Netbird connection status first
   - For THXII: Check if network adapter powered down (common issue)
   - Otherwise: Check network connectivity (ping)

   **If "Connection reset" or "Broken pipe":**
   - Check SSH keep-alive settings both sides
   - For THXII: Verify power management still disabled
   - For luiHA: Check SD card health (common corruption issue)

4. **Machine-specific quick fixes:**

   **THXII (Windows):**
   ```powershell
   # If SSH service stopped
   Start-Service sshd
   
   # If network adapter powered down
   Enable-NetAdapter -Name "Ethernet 7"
   
   # Verify power management still disabled
   $deviceID = "PCI\VEN_8086&DEV_15F3&SUBSYS_7D251462&REV_03\D8BBC1FFFFD87D2100"
   Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\$deviceID\Device Parameters" -Name PnPCapabilities
   ```

   **dojoNAS (QNAP via SSH):**
   ```bash
   # Check if sshd is running
   ps | grep sshd
   
   # Check if using correct alias (not dojonas which blocks CLI)
   # Use: dojonas-exec, dojonas-shell, or dojonas-via-thxii
   
   # Check if config file locked
   lsof 2>&1 | grep -i ssh
   ```

   **luiHA (Raspberry Pi via SSH):**
   ```bash
   # Check sshd service status
   sudo systemctl status sshd
   
   # Restart if needed
   sudo systemctl restart sshd
   
   # Check network interface
   ip addr show
   ```

5. **Run diagnostics remotely if possible:**
   - For THXII: Can SSH via console if needed
   - For dojoNAS: Can route via `dojonas-via-thxii` if direct fails
   - For luiHA: Must have Netbird or physical access

6. **Report back:**
   - What the issue was
   - What fix was applied (or commands for jachzy to run if needs console access)
   - Whether connection is now working
   - Reference to specific fix doc if applicable (thxii-fixes.md, dojonas-fixes.md, luiha-fixes.md)

## Output Format

Always provide commands in single copy-pasteable blocks per machine:

🐚 **dojoNAS (SSH)** or 🖥️ **THXII (PowerShell)**

```
[all commands here]
```

## Known Issue Patterns

**THXII:**
- **Daily drops** (fixed 2026-05-13 but may recur): Connection times out, was working yesterday → Network adapter power management → See `THXII SSH Connection Drops Daily.md`
- **Service stopped after Windows Update**: Connection refused → SSH service disabled by update → `Start-Service sshd`

**dojoNAS:**
- **"Config file in use"**: Commands hang or error with lock message → Multiple processes accessing config → Identify and kill conflicting process
- **Wrong alias blocks CLI**: Using `dojonas` SSH alias → Blocks Container Station CLI commands → Use `dojonas-exec`, `dojonas-shell`, or `dojonas-via-thxii` instead
- **No curl/wget/python3**: Commands fail with "not found" → QNAP host shell limitations → Use Docker container with `--network proxy` for network tools

**luiHA:**
- **Netbird required**: Connection times out from outside network → Not exposed via Cloudflare tunnel → Must connect via Netbird VPN first
- **SD card corruption**: Service fails to start, logs show I/O errors → SD card failure (common on RPi) → Check `dmesg` for filesystem errors

## Rules

- **Auto-detect mode is primary use case** — test all machines, fix what's broken, report summary
- **ALWAYS read the machine-specific fix doc first** — all known issues and fixes are documented there
- **Read vault docs if referenced** — historical context and incident details
- **Don't make jachzy repeat themselves** — read error output directly where possible
- **Single code block per machine** — never split commands unless user input required between
- **No explanatory text inside code blocks** — commands only
- **Test after fix** — always verify connection works before claiming success
- **If issue not in docs** — troubleshoot from scratch, then ADD the new issue to the appropriate fix doc for next time
- **If all machines working** — report "All SSH connections healthy" and exit quickly

## Self-Updating

When encountering a NEW issue not in the fix docs:
1. Troubleshoot and fix it
2. **Update the appropriate fix doc** with new scenario
3. **Update vault if significant** (add to existing doc or create new)
4. Report to jachzy what was added

This ensures the skill gets smarter over time and future sessions have complete context.

## Context Files to Load

**On every `/ssh` invocation:**
- `~/.ssh/config` — connection details for all machines
- `~/.claude/skills/ssh/AUTO-DETECT.md` — auto-detect flow and report format

**For each broken machine (after health check):**
- `~/.claude/skills/ssh/{machine}-fixes.md` — known issues for that machine
- Vault docs (if applicable):
  - THXII: `~/spacedog-vault/hubs/research/graphify-output/THXII SSH Connection Drops Daily.md`
  - Others: Search vault for `{machine}` + `ssh` keywords

**After loading context, you have:**
- All past troubleshooting sessions
- Known failure modes and exact fixes
- Machine-specific gotchas and workarounds
- Command syntax that has worked before
- Auto-detect flow with proper report formatting
