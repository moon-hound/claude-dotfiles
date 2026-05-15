# Auto-Detect Mode Flow

When user runs `/ssh` with no machine specified, follow this process:

## 1. Quick Health Check (Parallel)

Test all three machines simultaneously:

```bash
# From Mac - tests all in parallel
(ssh thxii 'Write-Host "ok"' 2>&1 | sed 's/^/[thxii] /') &
(ssh dojonas-exec 'echo "ok"' 2>&1 | sed 's/^/[dojonas] /') &
(ssh luiha 'echo "ok"' 2>&1 | sed 's/^/[luiha] /') &
wait
```

Capture stdout/stderr for each with machine prefix.

## 2. Parse Results

**Working machine output:** `[machine] ok`

**Broken machine output:** Contains error:
- `Connection refused` → service down
- `Connection timed out` → network/power issue
- `Connection reset` → keep-alive/stability issue
- `No route to host` → network down
- `Permission denied` → auth issue

## 3. For Each Broken Machine

Load context → diagnose → fix → verify

**Example flow for THXII timeout:**
1. Read `~/.claude/skills/ssh/thxii-fixes.md`
2. Match "Connection timed out" → Scenario 2 (adapter powered down)
3. Provide PowerShell commands to jachzy
4. After jachzy runs them, verify with `ssh thxii 'Write-Host "verified"'`

## 4. Final Report Format

**If all working:**
```
✓ All SSH connections healthy
  - thxii (192.168.1.27)
  - dojonas (192.168.1.234)
  - luiha (192.168.3.210)
```

**If one broken:**
```
⚠ 1 connection issue found

THXII (192.168.1.27) — FIXED
  Issue: Network adapter powered down
  Fix: Enabled Ethernet 7 adapter
  Status: ✓ Verified working

✓ dojonas (192.168.1.234) — healthy
✓ luiha (192.168.3.210) — healthy
```

**If multiple broken:**
```
⚠ 2 connection issues found

THXII (192.168.1.27) — NEEDS CONSOLE ACCESS
  Issue: SSH service stopped
  Fix required (at THXII console):
  
🖥️ THXII (PowerShell)
  
Start-Service sshd
Get-Service sshd

luiHA (192.168.3.210) — NEEDS NETBIRD
  Issue: Connection timed out (not on VPN)
  Fix: Connect Netbird VPN first
  
netbird up
ssh luiha 'echo verified'

✓ dojonas (192.168.1.234) — healthy
```

## 5. Edge Cases

**All three broken:**
- Likely Mac network issue or Netbird down
- Check Mac connectivity first
- Provide commands for all three once connectivity restored

**luiHA always requires Netbird:**
- If timeout from Mac, check `netbird status` first
- Don't report as "broken" if just Netbird disconnected
- Report: "luiHA requires Netbird VPN (currently disconnected)"

**dojoNAS routing via THXII:**
- If both THXII and dojonas-exec fail, try `dojonas-via-thxii`
- If that works, THXII is up but direct dojoNAS route is down
- Report routing issue, not machine down
