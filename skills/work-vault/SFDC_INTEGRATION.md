# Salesforce Integration - Phase 1 Complete

**Status:** Phase 1 (Account Setup) complete, ready for testing  
**Date:** 2026-06-12

---

## What Was Built (Phase 1)

### Files Created

1. **`scripts/setup-accounts.py`** - Account configuration script
   - Prompts user for Salesforce Account IDs (Org IDs)
   - Validates ID format (001 + 15/18 chars)
   - Stores tracked accounts in `~/.work-vault-config/tracked-accounts.json`
   - Supports nicknames for accounts

2. **`scripts/sfdc_auth.py`** - Authentication setup
   - Org62: Uses Salesforce DX CLI (sf org login web)
   - OrgCS: Uses OAuth via MCP server (browser flow)
   - Stores org aliases in OS-native secure storage

3. **`scripts/sfdc_query.py`** - Query helper module
   - Wrapper functions for SOQL queries
   - `query_org62()` - Query Org62
   - `query_orgcs()` - Query OrgCS
   - `get_account_by_id()` - Get Account record
   - `check_account_team()` - Check if user is on Account Team

---

## How to Use (Testing Phase 1)

### Step 1: Authenticate to Salesforce

**Org62 (via Salesforce DX CLI):**
```bash
# Login to Org62
sf org login web --alias org62

# Verify connection
sf org display --target-org org62

# Run auth setup
python3 ~/.claude/skills/work-vault/scripts/sfdc_auth.py
```

**OrgCS:**
- Authentication happens via MCP server on first use
- Will prompt for OAuth in browser

---

### Step 2: Configure Tracked Accounts

```bash
python3 ~/.claude/skills/work-vault/scripts/setup-accounts.py
```

**Example session:**
```
============================================================
Personal Assistant - Salesforce Account Setup
============================================================

Configure which customer accounts you want to track.
You'll need Salesforce Account IDs (Org IDs).

💡 Find Account ID in Salesforce URL:
   https://[instance].salesforce.com/001Dn00000ABC123
                                       ^^^^^^^^^^^^^^^^^^^

Add new accounts (press Enter without input to finish):

Enter Salesforce Account ID (001...): 001Dn00000ABC123
  Account nickname (optional): Acme Corp
  Querying Org62...
  ⚠️  SFDC query not yet implemented
  Will query org62 for Account: 001Dn00000ABC123
  Querying OrgCS...
  ⚠️  SFDC query not yet implemented
  Will query orgcs for Account: 001Dn00000ABC123
✓ Added: Acme Corp (001Dn00000ABC123)

Enter Salesforce Account ID (001...): [Enter to finish]

Saving 1 tracked accounts...
✓ Setup complete!
```

**Output file:** `~/.work-vault-config/tracked-accounts.json`
```json
[
  {
    "org_id": "001Dn00000ABC123",
    "nickname": "Acme Corp",
    "added_date": "2026-06-12T19:30:00",
    "org62": {
      "Id": "001Dn00000ABC123",
      "Name": "Account 001Dn00...",
      "Type": "Customer",
      "status": "pending_validation"
    },
    "orgcs": {
      "Id": "001Dn00000ABC123",
      "Name": "Account 001Dn00...",
      "status": "pending_validation"
    }
  }
]
```

---

## What's NOT Working Yet (Needs Implementation)

### SOQL Queries Not Implemented

**Current state:**
- `sfdc_query.py` has placeholder functions
- Returns `{"status": "not_implemented"}` instead of real data
- Cannot actually query Salesforce yet

**Why:**
- Python scripts cannot directly call MCP tools
- MCP tools only accessible from Claude Code context
- Need to refactor: Python → Claude Code → MCP tool → Python

**Two approaches to fix:**

#### Option A: Agent-based queries
```python
# Python script asks Claude Code agent to run query
from claude_code import Agent

def query_org62(soql_query):
    agent = Agent(
        prompt=f"Query Org62 with SOQL: {soql_query}",
        tools=["mcp__Salesforce_DX__run_soql_query"]
    )
    result = agent.run()
    return result
```

#### Option B: Direct MCP integration (if SDK available)
```python
# Use Salesforce DX CLI directly
import subprocess

def query_org62(soql_query):
    result = subprocess.run([
        'sf', 'data', 'query',
        '--query', soql_query,
        '--target-org', 'org62',
        '--json'
    ], capture_output=True, text=True)
    return json.loads(result.stdout)
```

**Recommendation:** Option B (CLI) is simpler and doesn't require Agent tool access.

---

## Next Steps (Phase 2-6)

### Phase 2: Org62 Integration (~4h)
- [ ] Implement actual SOQL queries via CLI
- [ ] Query Account + all related objects
- [ ] Discover custom objects via Metadata API
- [ ] Cache results locally in `~/.work-vault/03-SYSTEM/sfdc-cache/`

### Phase 3: OrgCS Integration (~4h)
- [ ] Authenticate via OrgCS MCP (get OAuth token)
- [ ] Discover OrgCS schema (what objects exist?)
- [ ] Query success plans, groups, engagements
- [ ] Match to Org62 Account ID

### Phase 4: Capture Integration (~3h)
- [ ] Update `capture.py` to extract customer names from text
- [ ] Query SFDC on capture to link notes to accounts
- [ ] Handle ambiguity (multiple matches → show list)
- [ ] Store note with Account ID reference

### Phase 5: Background Sync (~2h)
- [ ] Create cron job: `cron-sfdc-sync.py`
- [ ] Schedule every 2 hours
- [ ] Pull all configured accounts from Org62 + OrgCS
- [ ] Update cache

### Phase 6: Dashboard Integration (~3h)
- [ ] Update `slack-listener.py` App Home dashboard
- [ ] Show SFDC data per account:
  - Open Opportunities (count, total value)
  - Health/Success scores from OrgCS
  - Recent activity
  - Your note count for that account
- [ ] Add [🔄 Refresh] button to trigger on-demand sync

---

## Testing Phase 1

**What works now:**
- ✅ Account setup script runs
- ✅ Accepts Account IDs and nicknames
- ✅ Validates ID format
- ✅ Saves to JSON config file
- ✅ Loads existing accounts on re-run

**What doesn't work yet:**
- ❌ SFDC validation (returns placeholder)
- ❌ Account Team check (not implemented)
- ❌ Owner check (not implemented)
- ❌ Account name lookup (not implemented)

**Test it:**
```bash
# Run setup
python3 ~/.claude/skills/work-vault/scripts/setup-accounts.py

# Add a test account ID: 001000000000000
# Give it nickname: "Test Account"

# Check output file
cat ~/.work-vault-config/tracked-accounts.json
```

---

## Questions for User

Before building Phase 2-6:

1. **Salesforce DX CLI available?**
   - Run: `sf --version`
   - If not installed: https://developer.salesforce.com/tools/salesforcecli

2. **Org62 alias correct?**
   - Default is `org62`
   - Can change in `sfdc_auth.py` setup

3. **Do you know OrgCS object names?**
   - SuccessPlan, SuccessGroup, Engagement?
   - Or should Phase 3 discover schema first?

4. **Account Team membership:**
   - Is `AccountTeamMember` object available in your org?
   - Or custom object?

5. **Priority for Phase 2:**
   - Implement Org62 queries via CLI (simple, works immediately)?
   - Or build Agent-based approach (more complex, uses MCP tools)?

---

## Architecture Decision

**Current design: Local-first with periodic sync**

```
User captures note
       ↓
Extract customer name
       ↓
Query SFDC (Org62 + OrgCS)
       ↓
Link note to Account ID
       ↓
Cache SFDC data locally
       ↓
Dashboard shows cached data
       ↓
Background sync every 2h keeps cache fresh
```

**Alternative: Real-time queries**
- No cache, query SFDC on every dashboard view
- Simpler (no sync job)
- Slower (API latency on every view)
- Recommended: Stick with cache approach

---

## Ready to Proceed?

Phase 1 complete. Ready for Phase 2 (Org62 integration)?

Run: `python3 ~/.claude/skills/work-vault/scripts/setup-accounts.py` to test.
