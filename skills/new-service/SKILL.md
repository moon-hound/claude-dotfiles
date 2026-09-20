---
name: new-service
description: Scaffold a new self-hosted Docker Compose service for spacedog. Generates a compose snippet, Traefik labels, Authelia middleware config, .env.example, and a vault stub. Use whenever adding a new containerized service to dojoNAS.
---

# New Service Scaffold

You are scaffolding a new Docker Compose service for the spacedog home lab on dojoNAS.

## Gather Requirements

Ask for (or infer from context):
- **Service name** — used for container name, label prefix, and subdomain
- **Subdomain** — e.g. `karakeep.spacedog.lu` (assume `<name>.spacedog.lu` if not specified)
- **Docker image + version** — never use `:latest`
- **Port** — internal container port to proxy
- **Auth required?** — yes (Authelia SSO) or no (public)
- **Netbird-only or public?** — Netbird-only = NextDNS rewrite, no CF tunnel entry
- **Data volumes?** — persistent storage paths under `/share/docker-data/<name>/`
- **Env vars needed?** — list of required env vars for .env.example

## Output

Generate all of the following:

### 1. Docker Compose snippet

```yaml
  <name>:
    image: <image>:<version>
    container_name: <name>
    restart: unless-stopped
    networks:
      - proxy
    volumes:
      - /share/docker-data/<name>/data:/data  # adjust as needed
    env_file:
      - .env
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.<name>.rule=Host(`<subdomain>`)"
      - "traefik.http.routers.<name>.entrypoints=websecure"
      - "traefik.http.routers.<name>.tls=true"
      - "traefik.http.routers.<name>.middlewares=secure-headers@file,authelia@file"  # remove authelia if public
      - "traefik.http.services.<name>.loadbalancer.server.port=<port>"

networks:
  proxy:
    external: true
```

### 2. .env.example

```env
# <SERVICE_NAME> config
VAR_ONE=
VAR_TWO=
```

### 3. Authelia OIDC client block (if auth required)

```yaml
- client_id: <name>
  client_name: <Service Name>
  client_secret: GENERATE_WITH_AUTHELIA_CRYPTO
  public: false
  authorization_policy: one_factor
  token_endpoint_auth_method: client_secret_post
  redirect_uris:
    - https://<subdomain>/oauth2/callback
  scopes:
    - openid
    - profile
    - email
    - groups
```

### 4. Vault stub

Create `~/.claude/workspaces/spacedog/vault/02-Areas/computer-projects/spacedog/<name>.md`:

```markdown
# <Service Name>

**URL:** https://<subdomain>
**Auth:** Authelia SSO / Public
**Stack:** <image>:<version>
**Data:** `/share/docker-data/<name>/`
**Deployed:** <YYYY-MM-DD>

## Notes

- ...
```

### 5. Deployment checklist

Print this checklist after generating the above:

- [ ] Copy compose snippet into `/share/docker-data/<stack>/docker-compose.yml`
- [ ] Create `.env` from `.env.example`, fill in values, `chmod 600 .env`
- [ ] Create data directory: `mkdir -p /share/docker-data/<name>/data`
- [ ] Add Authelia OIDC client to `users_database.yml` (if auth required)
- [ ] Add CF DNS CNAME → tunnel (if public) — or NextDNS rewrite (if Netbird-only)
- [ ] `docker compose up -d <name>`
- [ ] Verify at `https://<subdomain>`
- [ ] ⚠️ Save any generated secrets to Bitwarden

## Spacedog Security Defaults (always apply)

- No `:latest` tags — pin exact version
- No direct port exposure — all traffic via `proxy` network + Traefik
- All public routers: `entrypoints=websecure` + `tls=true`
- Middleware: `secure-headers@file,authelia@file` (never `authelia@docker`)
- Secrets in `.env` only (chmod 600) — never inline in compose
- Non-root user if image supports it
- Read-only mounts where write access not needed
