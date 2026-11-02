---
alwaysApply: true
---

# Adopt Before Build (FOSS-First)

Before embarking on building any net-new capability, tool, service, workflow, or custom script:

1. **Research Pre-Built Solutions First:**
   - Search for existing open-source (FOSS) and free solutions before writing custom code.
   - Check the Spacedog homelab fleet first: does an existing deployed service already do this? (e.g., n8n, SearXNG, Home Assistant, Authelia, Jellyfin, Calibre, Mealie, Kuma).
   - Search GitHub, Docker Hub, and FOSS registries for mature, maintained, free tools.

2. **Evaluation Hierarchy:**
   - **Tier 1:** Native feature of an existing Spacedog service (e.g., n8n workflow, HA automation, Open WebUI tool).
   - **Tier 2:** Self-hosted open-source container (FOSS, active maintenance, lightweight, Docker Compose-ready).
   - **Tier 3:** Mature open-source library/CLI (tested, actively maintained, pip/npm/go).
   - **Tier 4 (Last Resort Only):** Custom bespoke implementation. Requires explicit justification why Tiers 1–3 cannot meet the requirements.

3. **Bias for Leverage:**
   - Zero-maintenance pre-built beats hundreds of lines of custom code every time.
   - If a pre-built tool covers 80%+ of the requirement, adopt and configure rather than building bespoke from scratch.
