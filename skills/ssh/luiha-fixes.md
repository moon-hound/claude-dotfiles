# luiHA SSH Quick Fixes

## Scenario 1: Connection Requires Netbird

**Symptom:** `Connection timed out` from Mac or external network

**Cause:** luiHA not exposed via Cloudflare tunnel, only accessible via Netbird VPN

**Fix:** Verify Netbird connected first:
```bash
# Check Netbird status
netbird status

# If disconnected, reconnect
netbird up

# Then test connection
ssh luiha 'hostname'
```

## Scenario 2: SSH Service Not Running

**Symptom:** `Connection refused` even when on Netbird

**Fix (requires physical access to RPi console or another method):**
```bash
# Check service status
sudo systemctl status sshd

# Start if stopped
sudo systemctl start sshd

# Enable to start on boot
sudo systemctl enable sshd
```

## Scenario 3: SD Card Corruption

**Symptom:** Random I/O errors, service fails to start, filesystem read-only

**Check filesystem health:**
```bash
# Check kernel logs for I/O errors
dmesg | tail -50

# Check filesystem status
mount | grep ' / '

# Check SD card health
sudo smartctl -a /dev/mmcblk0
```

**If read-only filesystem:**
```bash
# Remount read-write temporarily
sudo mount -o remount,rw /

# Back up critical data immediately
```

**Long-term fix:** Replace SD card, consider USB boot instead

## Scenario 4: Home Assistant Locked Up

**Symptom:** SSH works but system is slow, Home Assistant unresponsive

**Check system resources:**
```bash
# Check CPU/memory
top -b -n 1 | head -20

# Check disk I/O
iostat -x 2 5

# Check Home Assistant service
sudo systemctl status home-assistant
```

**Restart Home Assistant:**
```bash
sudo systemctl restart home-assistant
```

## Scenario 5: Network Interface Down

**Symptom:** SSH works via Netbird but local network access broken

**Check interfaces:**
```bash
# List all interfaces
ip addr show

# Check eth0/wlan0 status
ip link show eth0
ip link show wlan0

# Bring up if down
sudo ip link set eth0 up
```

## Scenario 6: SSH Key Invalid Format (CRLF)

**Symptom:** `Load key "C:/Users/Admin/.ssh/id_ed25519_ha": invalid format` → `Permission denied (publickey,password)`

**Cause:** `id_ed25519_ha` file has Windows CRLF line endings. Windows OpenSSH client rejects CRLF private keys.

**Fix (from Bash/Git Bash on THXII):**
```bash
sed -i 's/\r//' ~/.ssh/id_ed25519_ha
chmod 600 ~/.ssh/id_ed25519_ha
```

**Verify fix:**
```bash
ssh luiha 'echo ok'
```

**Note (2026-05-14):** Applied. Fix confirmed working.

## Full Diagnostic Check

**Run from Mac (via Netbird):**
```bash
ssh luiha '
echo "=== SSH Connection: OK ==="
echo ""
echo "=== System Info ==="
uname -a
echo ""
echo "=== Uptime ==="
uptime
echo ""
echo "=== Disk Space ==="
df -h / /boot
echo ""
echo "=== Memory ==="
free -h
echo ""
echo "=== Home Assistant Service ==="
sudo systemctl status home-assistant --no-pager | head -10
echo ""
echo "=== Network Interfaces ==="
ip addr show | grep -E "^[0-9]|inet "
echo ""
echo "=== Recent Errors ==="
dmesg | tail -20
'
```
