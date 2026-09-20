---
name: mcp-research
description: Fetch live documentation for any tool or library in the spacedog stack (Traefik, Authelia, n8n, Ollama, Open WebUI, Docker, etc). Use when you need accurate current config syntax, API options, or version-specific behavior.
---

# MCP Research

Fetch live official documentation for a tool or library and return precise, actionable answers.

## Usage

User invokes with a tool name and optional topic:
- `/mcp-research traefik forwardAuth middleware`
- `/mcp-research authelia OIDC client config`
- `/mcp-research n8n HTTP Request node`
- `/mcp-research ollama API modelfile syntax`

## Workflow

### 1. Parse the request
Extract: **tool** + **specific topic** from the invocation args or the surrounding conversation.

### 2. Find the official docs URL
Use WebSearch to locate the canonical docs page:
```
site:<official-domain> <topic>
```

Priority sources by tool:
| Tool | Docs base |
|------|-----------|
| Traefik | doc.traefik.io |
| Authelia | www.authelia.com/configuration |
| n8n | docs.n8n.io |
| Ollama | github.com/ollama/ollama/blob/main/docs |
| Open WebUI | docs.openwebui.com |
| Docker / Compose | docs.docker.com |
| Cloudflare | developers.cloudflare.com |
| Netbird | docs.netbird.io |
| Home Assistant | www.home-assistant.io/docs |

### 3. Fetch and extract

Use WebFetch on the identified URL. Extract only the section relevant to the topic — skip nav, changelog, unrelated options.

### 4. Respond

Answer with:
- **Exact config syntax** (YAML/TOML/JSON block, copy-paste ready)
- **Required vs optional fields** called out
- **Version notes** if the behavior differs across versions
- **One gotcha** if there's a known trap (cross-reference with CLAUDE.md gotchas)

Keep it tight. No padding. If the docs page doesn't answer the question, say so and suggest the next best source.
