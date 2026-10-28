# Snowflake MCP Setup

**Date:** 2026-06-16  
**Method:** Snowflake Managed MCP (Official)

---

## Step 1: Generate Snowflake PAT Token

1. Login to Snowflake web UI
2. Click your username (top right) → Account Settings
3. Navigate to "Security" or "API Access" section
4. Click "Generate New Token" or "Programmatic Access Token"
5. Give it a name: `claude-code-mcp`
6. Copy the token (only shown once)

**⚠️ SAVE TO BITWARDEN:** Snowflake PAT token for Claude Code MCP access

---

## Step 2: Get Your Connection Details

**Find these in Snowflake UI:**

1. **Account URL**: Look at browser address bar when logged in
   - Format: `https://[account].snowflakecomputing.com`
   - Example: `https://xy12345.us-west-2.snowflakecomputing.com`
   - **Your account identifier:** `[account]` (the part before `.snowflakecomputing.com`)

2. **Database**: The database you want to query
   - Check: Databases → Show available databases
   - Likely: `CUSTOMER_DATA`, `ANALYTICS`, `PROD`, etc.

3. **Schema**: Schema within that database
   - Check: Select database → Schemas tab
   - Default: `PUBLIC`
   - May be: `CSM_DATA`, `CONSUMPTION`, etc.

4. **MCP Server Name** (if already created):
   - Check: Databases → [DB] → Schemas → [SCHEMA] → MCP Servers
   - If none exist, Snowflake auto-creates one when you connect

---

## Step 3: Add MCP Server to Claude Code

**Once you have:**
- ✅ PAT token
- ✅ Account identifier
- ✅ Database name
- ✅ Schema name

**Run this command:**

```bash
claude mcp add \
  --header "Authorization: Bearer YOUR_PAT_TOKEN_HERE" \
  --transport http snowflake \
  https://YOUR_ACCOUNT.snowflakecomputing.com/api/v2/databases/YOUR_DATABASE/schemas/YOUR_SCHEMA/mcp-servers/default
```

**Example:**
```bash
claude mcp add \
  --header "Authorization: Bearer eyJhbGc..." \
  --transport http snowflake \
  https://xy12345.us-west-2.snowflakecomputing.com/api/v2/databases/CUSTOMER_DATA/schemas/PUBLIC/mcp-servers/default
```

---

## Step 4: Restart Claude Code

```bash
# If running in terminal
exit

# Relaunch Claude Code
# MCP server will be available automatically
```

---

## Step 5: Verify Connection

After restart, Claude Code will have Snowflake MCP tools available:
- `mcp__snowflake__listTables`
- `mcp__snowflake__describeTable`
- `mcp__snowflake__query`
- `mcp__snowflake__listSchemas`
- `mcp__snowflake__listDatabases`

Test with:
```
List all tables in my Snowflake database
```

---

## Troubleshooting

**401 Unauthorized:**
- PAT token expired or invalid
- Regenerate token and update MCP config

**404 Not Found:**
- Account URL wrong (check format)
- Database or schema doesn't exist
- MCP server name incorrect (try `default` if unsure)

**403 Forbidden:**
- Your Snowflake role lacks permissions
- Check role has access to specified database/schema

**Connection timeout:**
- Account identifier wrong
- Network/firewall blocking
- VPN required?

---

## What You'll Need to Provide

Tell me these 4 things and I'll build the command for you:

1. **Account identifier**: (from `https://[THIS-PART].snowflakecomputing.com`)
2. **Database name**: (which database has your customer consumption data?)
3. **Schema name**: (usually `PUBLIC` or specific like `CSM_DATA`)
4. **PAT token**: (generate in Snowflake → Account Settings → Security)

Example:
```
Account: xy12345.us-west-2
Database: CUSTOMER_DATA
Schema: PUBLIC
Token: eyJhbGc...
```

Then I'll give you the exact `claude mcp add` command to run.

---

## Alternative: If PAT Generation is Blocked

If your org doesn't allow PAT tokens, we can try:
- **Option 2**: SSO-based connector (more complex setup)
- **Option 3**: Composio (third-party, handles OAuth)

Let me know what info you can get and we'll proceed from there.
