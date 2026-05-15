# dojoNAS SSH Quick Fixes

## Scenario 1: Using Wrong SSH Alias

**Symptom:** Commands hang or Container Station CLI commands fail with "command not found"

**Cause:** The `dojonas` alias has special PATH that blocks Container Station binaries

**Fix:** Use correct alias for your task:
- **dojonas-exec** — Full PATH, Docker/Container Station available
- **dojonas-shell** — Interactive shell with full environment
- **dojonas-via-thxii** — Route through THXII (useful if direct connection blocked)

**Test from Mac:**
```bash
ssh dojonas-exec 'docker ps --format "table {{.Names}}\t{{.Status}}"'
```

## Scenario 2: Config File Locked

**Symptom:** `Config file is in use by another instance` or commands hang

**Check what's locking:**
```bash
ssh dojonas-exec 'ps | grep -E "signal|container"'
```

**Kill conflicting process:**
```bash
ssh dojonas-exec 'kill <PID>'
```

## Scenario 3: Need Network Tools (curl/wget)

**Symptom:** `curl: command not found` or `wget: not found`

**Workaround:** Use Docker container with curl:
```bash
ssh dojonas-exec 'docker run --rm --network proxy curlimages/curl:latest curl http://example.com'
```

## Scenario 4: File Permission Denied

**Symptom:** Cannot write to `/share/docker-data/` directory

**Cause:** Path owned by different user (e.g., `admin` instead of `dojoadmin`)

**Workaround:** Use Docker container as root:
```bash
ssh dojonas-exec 'docker run --rm -v /share/docker-data/target:/mnt alpine sh -c "echo content > /mnt/file.txt"'
```

## Scenario 5: Docker Not in PATH

**Symptom:** `docker: command not found` when using direct SSH (not alias)

**Fix:** Export PATH first:
```bash
export PATH=/share/CACHEDEV2_DATA/.qpkg/container-station/bin:$PATH
docker ps
```

## Full Diagnostic Check

**Run from Mac:**
```bash
ssh dojonas-exec '
echo "=== SSH Connection: OK ==="
echo ""
echo "=== Container Station Docker ==="
docker version --format "{{.Server.Version}}"
echo ""
echo "=== Running Containers ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | head -10
echo ""
echo "=== Disk Space ==="
df -h /share/CACHEDEV2_DATA | tail -1
echo ""
echo "=== Network Interfaces ==="
ip addr show | grep -E "^[0-9]|inet "
'
```
