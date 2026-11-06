---
name: verify
description: "Run live verification harness for the current project, test services and routes, and record empirical evidence to tests/evidence/."
---

# In-Session Verification Harness

Executes the repository's registered verification skill or test suite, validates running service health, and writes timestamped proof to `tests/evidence/`.

## How It Works

1. **Auto-Detect Harness**:
   - In `lui2`: Runs `python tests/verify_lui2.py`.
   - In `spacedog`: Runs `python scripts/test_all.py` or `pytest`.
   - Other repos: Auto-detects `tests/verify-*.py`, `pytest`, or `npm test`.
2. **Execute & Observe**:
   - Executes doctor checks (health endpoints, database connection).
   - Runs unit and integration suites.
   - Saves evidence JSON/screenshots to `tests/evidence/evidence_<timestamp>.json`.
3. **Report**:
   Outputs a concise one-line status:
   `✅ Verification passed (11/11 tests, dojoNAS Gate ok). Evidence: tests/evidence/evidence_20261105_230558.json`

