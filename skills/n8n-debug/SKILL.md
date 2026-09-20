---
name: n8n-debug
description: Diagnose n8n workflow failures on dojoNAS. SSHes into dojoNAS, reads n8n container logs, inspects workflow files and JS nodes, and reports root cause with fix recommendation.
disable-model-invocation: true
---

# n8n Debug

Diagnose n8n workflow failures on dojoNAS systematically.

## Workflow

### 1. Collect logs

SSH into dojoNAS and tail n8n container logs:

```bash
ssh dojonas-exec "export PATH=/share/CACHEDEV2_DATA/.qpkg/container-station/bin:\$PATH && docker logs n8n --tail 100 2>&1"
```

Look for: `ERROR`, `WARN`, uncaught exceptions, HTTP 4xx/5xx from external calls, node execution failures.

### 2. Check workflow execution history

```bash
ssh dojonas-exec "export PATH=/share/CACHEDEV2_DATA/.qpkg/container-station/bin:\$PATH && docker exec n8n sh -c 'ls /home/node/.n8n/'"
```

### 3. Inspect the failing JS node

For briefing/signal bot workflows, the main gather script is at:
```
/share/docker-data/n8n/db_v5_gather.js
```

Read it directly:
```bash
ssh dojonas-exec "cat /share/docker-data/n8n/db_v5_gather.js"
```

### 4. Check n8n database for recent executions

```bash
ssh dojonas-exec "export PATH=/share/CACHEDEV2_DATA/.qpkg/container-station/bin:\$PATH && docker exec n8n sh -c 'ls /home/node/.n8n/database.sqlite 2>/dev/null && echo exists || echo missing'"
```

### 5. Test external data sources manually

For weather/NHL/sports data issues, exec into n8n container and run the fetch inline:
```bash
ssh dojonas-exec "export PATH=/share/CACHEDEV2_DATA/.qpkg/container-station/bin:\$PATH && docker exec n8n node -e \"[paste minimal fetch snippet here]\""
```

### 6. Report findings

Structure output as:
- **Root cause**: What failed and why
- **Affected node**: Which workflow node / JS function
- **Fix**: Exact code change or config change needed
- **Verify**: How to confirm fix worked (re-run workflow, check output)

## Known Gotchas

- dojoNAS has no `python3`, `curl`, or `wget` in host shell — use `docker exec` for anything inside containers
- Docker not in PATH without export: `export PATH=/share/CACHEDEV2_DATA/.qpkg/container-station/bin:$PATH`
- n8n data dir: `/share/docker-data/n8n/` (use symlink path, not CACHEDEV2_DATA path)
- For briefing issues: check weather numeric values, NHL playoff detection, and game date logic in `db_v5_gather.js`
- Signal bot (Lui) runs as n8n workflow — check workflow named "Lui" or "Signal" in execution history
