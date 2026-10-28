# Snowflake Integration

**Status:** Phase 1 (Setup & Discovery) - In Progress  
**Date:** 2026-06-16

---

## What Was Built

### Files Created

1. **`scripts/snowflake_auth.py`** - Authentication setup
   - Stores Snowflake credentials in OS-native secure storage
   - Prompts for: account, username, password, warehouse, database, schema, role
   - Tests connection and displays version info

2. **`scripts/snowflake_query.py`** - Query utilities
   - `get_connection()` - Connect to Snowflake
   - `query(sql)` - Execute SQL and return results as dicts
   - `discover_databases()` - List all accessible databases
   - `discover_schemas(database)` - List schemas in a database
   - `discover_tables(database, schema)` - List tables in a schema
   - `get_table_columns(database, schema, table)` - Describe table structure
   - `find_account_linkage(database, schema)` - Search for Salesforce account ID columns
   - `get_consumption_data(account_id)` - Get consumption metrics (placeholder)

---

## Setup Instructions

### Step 1: Install Dependencies

```bash
pip3 install --user snowflake-connector-python
```

### Step 2: Configure Snowflake Connection

```bash
cd ~/.claude/skills/work-vault
python3 scripts/snowflake_auth.py
```

**You'll be prompted for:**
- Snowflake Account (e.g., `abc12345.us-east-1`)
- Username
- Password (stored securely in OS keychain)
- Default Warehouse (optional)
- Default Database (optional)
- Default Schema (optional)
- Default Role (optional)

**Example:**
```
Snowflake Account: xy12345.us-west-2
Username: ryan.jacke@salesforce.com
Password: ********
Default Warehouse: COMPUTE_WH
Default Database: CUSTOMER_DATA
Default Schema: PUBLIC
Default Role: CSM_ROLE
```

### Step 3: Test Connection

Script automatically tests connection and shows:
- Snowflake version
- Current user
- Current role

---

## Discovery Phase

### Step 1: Discover Your Data

```bash
cd ~/.claude/skills/work-vault
python3 scripts/snowflake_query.py
```

**This will:**
1. List all accessible databases
2. List schemas in the first database
3. Search for account linkage columns (account_id, org_id, salesforce_account_id, etc.)

### Step 2: Find Account Linkage

**The integration needs to link Snowflake data to your Salesforce accounts.**

**Common patterns:**
- `ACCOUNT_ID` column with Salesforce Account ID (001...)
- `ORG_ID` column with custom organization ID
- `CUSTOMER_NAME` column with account name (fuzzy match)
- `SALESFORCE_ACCOUNT_ID` explicit column

**What to look for:**
- Tables with consumption metrics (usage, credits, compute time)
- Tables with customer/account identifiers
- Join tables that map custom IDs to Salesforce IDs

---

## Integration Architecture

### Goal
When you capture notes or view dashboard, pull Snowflake consumption data for each customer account.

### Data Flow
```
User opens dashboard
       ↓
Load tracked accounts from config
       ↓
For each account:
  ├─ Query Org62 (Opportunities, Contacts, Cases)
  ├─ Query OrgCS (Success Plans, Scores, Engagements)
  └─ Query Snowflake (Consumption, Usage, Credits)
       ↓
Cache all data locally
       ↓
Dashboard shows unified view
```

### Account Matching Strategy

**Option A: Direct ID Match (Best)**
```sql
SELECT 
  usage_date,
  compute_credits,
  storage_tb,
  query_count
FROM consumption_metrics
WHERE salesforce_account_id = '00130000000H6T4AAK'
ORDER BY usage_date DESC
LIMIT 30
```

**Option B: Name Match (Fallback)**
```sql
SELECT *
FROM consumption_metrics
WHERE customer_name ILIKE '%Hagerty%'
```

**Option C: Mapping Table**
```sql
SELECT cm.*
FROM consumption_metrics cm
JOIN account_mapping am ON cm.org_id = am.internal_org_id
WHERE am.salesforce_account_id = '00130000000H6T4AAK'
```

---

## Next Steps

### Phase 2: Schema Discovery (30min)

**Need from you:**
1. Run `python3 scripts/snowflake_auth.py` with your credentials
2. Run `python3 scripts/snowflake_query.py` to discover schema
3. Share output - which databases/schemas have customer data?
4. Identify how Snowflake links to Salesforce accounts

### Phase 3: Query Implementation (2h)

**Once schema is known:**
- Build consumption metrics queries
- Build usage statistics queries
- Implement account matching logic
- Cache results locally

### Phase 4: Dashboard Integration (1h)

- Update dashboard to show Snowflake data
- Display consumption trends
- Show usage metrics
- Add refresh button

### Phase 5: Background Sync (1h)

- Add Snowflake to existing SFDC sync job
- Pull consumption data every 2 hours
- Cache for fast dashboard loading

---

## What Data to Pull

**Consumption Metrics:**
- Compute credits used (daily/monthly)
- Storage usage (TB)
- Query count
- Active users
- Warehouse utilization

**Usage Statistics:**
- Login frequency
- Query patterns
- Feature adoption
- Data volume trends

**Cost/Billing (if accessible):**
- Monthly spend
- Credit consumption rate
- Cost per query/compute

**Health Indicators:**
- Query performance trends
- Error rates
- Failed job counts

---

## Security Notes

**Credentials Storage:**
- Snowflake password stored in OS-native secure storage only
- macOS: Keychain (hardware-encrypted)
- Windows: Credential Manager (DPAPI)
- Linux: Secret Service (libsecret)

**Access Scope:**
- Uses your Snowflake credentials (not service account)
- Read-only queries (no INSERT/UPDATE/DELETE)
- Limited to databases/schemas your role can access

**Data Privacy:**
- Consumption data cached locally (`~/.work-vault/03-SYSTEM/snowflake-cache/`)
- No Snowflake data sent to AI (only used for display)
- Customer data never leaves your laptop

---

## Troubleshooting

**Connection fails:**
```
❌ Connection failed: 250001: Could not connect to Snowflake backend
```
- Check account name format (should be `account.region.cloud`)
- Verify network connectivity
- Check if firewall blocking Snowflake

**Authentication fails:**
```
❌ Connection failed: Incorrect username or password
```
- Verify username (usually email)
- Check password (may need to reset)
- Verify role has access to specified warehouse

**No databases visible:**
```
Found 0 databases
```
- Check role permissions
- User may not have access to any databases
- Try specifying different role during setup

---

## Ready to Connect?

**Run this to start:**
```bash
cd ~/.claude/skills/work-vault
python3 scripts/snowflake_auth.py
```

**I'll need from you:**
- Snowflake account identifier
- Your username and password
- Default warehouse/database (if you know them)

**Then we'll run discovery to:**
- List all accessible data
- Find account linkage
- Build consumption queries
- Integrate into dashboard

Let me know when you're ready to connect!
