---
name: ha-ultimate
description: >
  Manage a Home Assistant instance end-to-end: discover entities, write modern
  YAML (automations, scripts, scenes, templates, blueprints, MQTT), validate
  config before touching the instance, deploy via git or rapid scp, choose the
  right reload/restart, verify from logs and traces, and build Lovelace
  dashboards with visual validation. Works via SSH ha-cli, REST (ha-api),
  WebSocket (ha-ws), or MCP — whichever is available. Handles entity/device/area
  registry management, multi-location entity naming, and offline validation of
  config files against local registries.
triggers:
  - home assistant
  - homeassistant
  - automation
  - lovelace
  - dashboard
  - entity
  - ha config
  - yaml config
  - hass
  - ha-api
  - ha-ws
---

# Home Assistant — Ultimate Skill

Operate a Home Assistant instance precisely: make a change, validate it, get it
live, prove it worked. Optimise for the fewest safe round-trips.

<!-- SOURCE ORIGINS
  SKILL.md core: komal-SkyNET/claude-skill-homeassistant
  CLI tools (ha-api, ha-ws, lovelace-sync): danbuhler/claude-code-ha
  Validation system, entity explorer, naming convention: philippb/claude-homeassistant
-->

---

## Environment setup

### Required environment variables
```
HA_URL=https://homeassistant.local:8123   # or your external URL
HA_TOKEN=<long-lived access token>        # Settings → Profile → Long-Lived Access Tokens
```
Store in `.env` at `/config/.env` or `~/.ha-cli.env` (chmod 600). All bin/ tools
load these automatically from common locations:
`$HA_ENV_FILE` → `/config/.env` → `/homeassistant/.env` → `./.env` → `~/.ha-cli.env`

**hass-cli (legacy)** uses different names: `HASS_SERVER` + `HASS_TOKEN`. If
`hass-cli` errors with "localhost", check `[ -n "$HASS_TOKEN" ]` — if unset,
use `ha-api`, `ha-ws`, or SSH instead of retrying.

### SSH access
```bash
ssh root@homeassistant.local
```
SSH is always available and needs no env vars. Use it for `ha core
check|restart|logs|info`. Record the real user/host in the project CLAUDE.md
once resolved.

---

## Tool selection — pick the right one

| Task | Best tool | Why |
|------|-----------|-----|
| Core check / restart / logs | `ssh … "ha core check"` | Always works, no env |
| Quick state or attribute lookup | `ha-api state/attr` | Fastest REST call |
| Entity/device/area registry ops | `ha-ws entity/device/area` | WebSocket-only ops |
| Service calls with complex targets | `ha-ws call` | target/data separation |
| History query | `ha-api history` | REST history endpoint |
| Lovelace push (no restart) | `bin/lovelace-sync` | WebSocket, no restart |
| Entity discovery & search | `tools/entity_explorer.py` | Reads local registry |
| Pre-push YAML validation | `tools/yaml_validator.py` + `tools/reference_validator.py` | Offline, fast |
| Live state / control | MCP (preferred when present) | No env juggling |

**MCP**: when the `mcp_server` integration (HA ≥2025.2) or community `ha-mcp`
is wired up, prefer it over shelling out. Falls back gracefully to ha-api/ha-ws.

---

## The deploy pipeline (canonical flow)

Changes are **not live** until step 4.

1. **Edit** YAML locally.
2. **Validate offline**: `python tools/yaml_validator.py config/` then
   `python tools/reference_validator.py config/` — catches syntax errors and
   broken entity references before touching the instance.
3. **Validate on-instance** (before restart only):
   `ssh root@homeassistant.local "ha core check"` (~30–60 s). Skip for isolated
   domain edits where a reload will surface errors faster.
4. **Commit + push**: `git add … && git commit -m "…" && git push`
5. **Make live**: `ssh root@homeassistant.local "cd /config && git pull"`
6. **Apply**: reload or restart (table below).
7. **Verify** (section below).

**Rapid iteration** (dashboards, tight test loops): skip git, `scp` straight to
the instance, then reload. Commit once stable.
```bash
scp automations.yaml root@homeassistant.local:/config/
ha-api call automation reload
```

---

## Reload vs restart

Prefer reload. Never restart without a passing `ha core check`.

| Change | Action |
|--------|--------|
| automations, scripts, scenes, groups, template entities, themes | `ha-api call automation reload` (or domain-specific) |
| `configuration.yaml` core, new integrations, platform sensors, MQTT sensor/binary_sensor, `lovelace_dashboards` registry | `ssh … "ha core restart"` (~30 s) |

### Selective reload commands
```bash
ha-api call automation reload
ha-api call script reload
ha-api call scene reload
ha-api call group reload
ha-api call input_boolean reload
ha-api call input_number reload
ha-api call input_select reload
ha-api call input_text reload
ha-api call timer reload
ha-api call template reload
ha-api call homeassistant reload_all   # reload all YAML-configured domains
```
HomeKit picks up entity changes with a YAML reload — no integration reload or
restart needed.

### Snapshot before risky changes
```bash
ssh root@homeassistant.local "ha backups new --name pre-<change>"
```
Cheap insurance before `configuration.yaml` surgery or removing an integration.

---

## REST API CLI (`bin/ha-api`)

Fast read-only queries and simple service calls.

```bash
ha-api states [filter]            # list all entity IDs (optional grep filter)
ha-api state <entity_id>          # get current state
ha-api domains                    # count entities per domain
ha-api devices <device_class>     # find by device_class (motion, door, temperature…)
ha-api search <pattern>           # search entity IDs by pattern
ha-api call <domain> <service>    # call a service
ha-api attr <entity_id>           # show all attributes
ha-api history <entity_id> [hrs]  # history (default: 24 h)
ha-api get <endpoint>             # GET any /api/ endpoint
ha-api post <endpoint> [json]     # POST to any /api/ endpoint
```

Examples:
```bash
ha-api devices motion
ha-api search kitchen
ha-api state light.living_room
ha-api call light turn_on
ha-api post services/light/turn_on '{"entity_id":"light.living_room"}'
ha-api get error_log
```

---

## WebSocket CLI (`bin/ha-ws`)

Full registry management and richer queries. Prefer this over ha-api for entity
lookups — it returns registry, state, and related automations in one call.

```bash
# Entity registry
ha-ws entity list [filter]              # list (searchable by id, name, platform, area)
ha-ws entity get <entity_id>            # registry + state + related automations/scenes
ha-ws entity update <id> key=value...   # rename, set icon, clear name
ha-ws entity remove <entity_id>

# Device registry
ha-ws device list [filter]
ha-ws device get <device_id>            # device + all its entities + related automations
ha-ws device update <id> key=value...
ha-ws device remove <device_id>

# Area registry
ha-ws area list
ha-ws area create <name>
ha-ws area update <id> key=value...
ha-ws area delete <area_id>

# States & services
ha-ws state <entity_id>
ha-ws states [domain]
ha-ws call <domain>.<service> [data]    # entity_id=/device_id=/area_id= routed to target
ha-ws services [domain]

# Search / raw
ha-ws search <entity_id>               # find related entities
ha-ws raw <ws_type> [key=value...]     # raw WebSocket message
ha-ws batch                            # read commands from stdin

# Flags
ha-ws --json <command>                 # JSON output
ha-ws --quiet <command>                # minimal output
```

Value syntax for key=value args:
| Syntax | Type |
|--------|------|
| `key=value` | string |
| `key=123` | integer |
| `key=true` / `key=false` | boolean |
| `key=null` / `key=none` | None (clears field) |
| `key="quoted string"` | string with spaces |

Examples:
```bash
ha-ws entity get sensor.temperature
ha-ws entity update light.old new_entity_id=light.new
ha-ws entity update light.lamp icon=mdi:floor-lamp name=none
ha-ws device update abc123 area_id=kitchen name_by_user="Kitchen Light"
ha-ws call light.turn_on entity_id=light.kitchen brightness=255
ha-ws --json entity get sensor.temperature
```

---

## Lovelace dashboard sync (`bin/lovelace-sync`)

Pushes a local `.storage/lovelace*` file to HA via WebSocket **without a
restart**. Browser hard-refresh (Ctrl+Shift+R) shows the change immediately.

```bash
# Default: auto-discovers .storage/lovelace
lovelace-sync

# Explicit file
lovelace-sync /config/.storage/lovelace.control_center
```

> **Conflict note**: `philippb` convention treats `.storage/` as read-only (UI
> only). `danbuhler` and `komal` allow direct edits pushed via lovelace-sync.
> **Resolution**: WebSocket-push is the safer approach — HA's own API handles
> the update atomically. Use it; avoid raw `scp` of `.storage/` files when
> lovelace-sync is available.

Adding a **new** dashboard still requires registering it in
`.storage/lovelace_dashboards` and a **restart** for the sidebar entry to appear.

Validate JSON before pushing:
```bash
python3 -m json.tool .storage/lovelace.x > /dev/null
```

---

## Offline validation tools (`tools/`)

Run before any push. The hooks in `philippb` run these automatically on file
edits — wire them up if you want the same behaviour.

```bash
# 1. YAML syntax + structure (automations list, scripts dict, config keys)
python tools/yaml_validator.py config/

# 2. Entity / device / area reference check against local registries
python tools/reference_validator.py config/

# 3. Entity discovery and search (reads local .storage/ registries)
python tools/entity_explorer.py --search kitchen
python tools/entity_explorer.py --domain light
python tools/entity_explorer.py --area "living room"
python tools/entity_explorer.py --full
```

The validator handles HA-specific YAML tags: `!include`, `!include_dir_*`,
`!secret`, `!input`. Secrets are skipped. Blueprints are skipped (use `!input`
tags that aren't resolved locally).

**Pre-condition**: validators need a local `config/` dir with `.storage/` pulled
from the instance. Pull with:
```bash
rsync -avz --exclude='.storage/auth*' \
  root@homeassistant.local:/config/ config/
```

---

## Verify — don't assume it worked

1. Reload / restart the right domain (see table above).
2. For automations, **trigger manually** for instant feedback:
   ```bash
   ha-ws call automation.trigger entity_id=automation.<id>
   ```
   This **bypasses `conditions` by default** (`skip_condition` defaults to true).
   To test conditions too, pass `skip_condition=false` or fire the real trigger.
3. Read logs filtered to your change:
   ```bash
   ssh root@homeassistant.local \
     "ha core logs | grep -iE '<name>|error' | tail -20"
   ```
   Good: `Running automation actions`, `Executing step …`
   Bad: `Invalid data for call_service`, `TypeError`, `Template variable warning`
4. Confirm real outcome: `ha-ws state <entity>` or `ha-api state <entity>`.
5. On error: fix → re-pull/scp → reload → re-check. Loop until clean.

---

## Automations — modern syntax

HA 2024.10 renamed the keys. Write new automations with plural keys; legacy
still works but don't emit it:

| Legacy | Modern |
|--------|--------|
| `trigger:` / `condition:` / `action:` (top-level) | `triggers:` / `conditions:` / `actions:` |
| `platform: state` (inside trigger) | `trigger: state` |
| `service: light.turn_on` | `action: light.turn_on` |

Every automation needs a stable `id:` (never change once set — traces and UI
editing require it) and a human `alias`.

**Full reference** (mode table, blueprints, trace debugging, pitfalls) →
[`reference/automations.md`](reference/automations.md)

---

## Templates — precision rules

- Always coerce before comparing: `states('sensor.x') | int(0) < 7`
  Bare states are strings; `'5' < 7` raises `TypeError`. Default guards `None`
  at startup.
- `state_attr(...)` returns `None` if entity/attr missing — guard it.
- Test in **Developer Tools → Template** before committing.

---

## Entity naming convention (multi-location)

Format: `<location>_<room>_<device>_<sensor>`

Examples:
```
binary_sensor.home_basement_motion_tamper
media_player.home_kitchen_sonos
climate.office_living_room_heatpump
lock.home_front_door_august
vacuum.office_roborock
```

Follow this convention for new entities in multi-location setups. Use
`entity_explorer.py --search` before writing automations to confirm exact IDs.

---

## Quick reference
```bash
# Validate (offline)
python tools/yaml_validator.py config/
python tools/reference_validator.py config/

# Validate (on-instance, before restart)
ssh root@homeassistant.local "ha core check"

# Deploy
git add … && git commit -m "…" && git push
ssh root@homeassistant.local "cd /config && git pull"

# Rapid deploy (skip git)
scp automations.yaml root@homeassistant.local:/config/

# Apply
ha-api call automation reload
ssh root@homeassistant.local "ha core restart"

# Logs
ssh root@homeassistant.local "ha core logs | grep -iE 'error|<name>' | tail -20"

# State / services
ha-api state <entity>
ha-ws entity get <entity>
ha-ws call light.turn_on entity_id=light.kitchen brightness=255
ha-api call automation trigger entity_id=automation.<id>

# Lovelace
lovelace-sync
lovelace-sync /config/.storage/lovelace.custom_dashboard
```

---

## Conventions

- Surgical edits; preserve comments; 2-space indent.
- Only edit `.yaml` / `.yml` / `.md`. Never read/write secrets.yaml values;
  use `!secret`.
- Validate before restart; prefer reload; verify from logs.
- Use MCP (context7 or ha-mcp) for current HA docs before non-trivial or
  unfamiliar config.

---

## CHANGELOG / Source traceability

| Section / File | Source skill | Notes |
|----------------|-------------|-------|
| SKILL.md core structure, deploy pipeline, reload table, verify loop, template rules, MCP awareness | `komal-SkyNET/claude-skill-homeassistant` | Adopted as primary framework |
| `bin/ha-api`, `bin/ha-ws`, `bin/lovelace-sync`, install.sh | `danbuhler/claude-code-ha` | Scripts carried verbatim; env-discovery logic preserved |
| `tools/yaml_validator.py`, `tools/reference_validator.py`, `tools/entity_explorer.py` | `philippb/claude-homeassistant` | Scripts carried verbatim |
| Entity naming convention (`location_room_device_sensor`) | `philippb/claude-homeassistant` | Multi-location convention |
| Offline validation workflow, rsync architecture | `philippb/claude-homeassistant` | Adapted to be optional pre-condition |
| Lovelace conflict resolution (WebSocket push preferred over raw scp) | Merged decision | danbuhler WebSocket approach wins; philippb UI-only restriction relaxed |
| Visual dashboard validation (Claude-in-Chrome, shadow DOM, screenshot) | `komal-SkyNET/claude-skill-homeassistant` → reference/dashboards.md | Kept in reference |
| `reference/automations.md`, `reference/dashboards.md` | `komal-SkyNET/claude-skill-homeassistant` | Carried verbatim |
