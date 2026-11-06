---
name: pstack
description: >-
  Lauren Tan (@poteto)'s pstack engineering suite for eliminating AI slop, enforcing
  rigorous workflows, deep architectural investigation, multi-agent arenas, and strict verification.
  Use for "pstack", "/pstack", "poteto mode", or high-discipline engineering.
---

# PStack Engineering Suite

PStack is an opinionated collection of agent skills, playbooks, and engineering principles created by Lauren Tan (@poteto) to combat AI slop and enforce deep verification before code is shipped.

## Core Entry Points & Modes

- **`/poteto-mode`**: Master orchestrator mapping requests to specific disciplined workflows (bug fixes, feature build, refactoring, research).
- **`/setup-pstack`**: Configure model assignments per role (Cursor, Claude Code, Codex, Antigravity) and set reasoning budgets.
- **`/unslop`**: Strips AI-generated conversational tells, corporate fluff, and unnecessary prose.
- **`/arena`**: Spawns parallel candidates to solve the same problem, selecting the best base and grafting the strongest parts.
- **`/architect`**: Sketches types, signatures, and module structure before writing implementation.
- **`/how`**: Subsystem walkthroughs, runtime flow, placement, and architecture boundaries before touching code.
- **`/why`**: Root-cause analysis, design rationale, postmortems, and tradeoffs backed by evidence.
- **`/interrogate`**: Multi-model adversarial review to stress-test designs and break flawed assumptions.
- **`/blast-radius`**: Explores what a change could break outside the diff before shipping.
- **`/swarm`**: Fans out parallel worker agents for benchmarks, sweeps, gauntlets, and races.

## Core Rules & Non-Negotiables

1. **State the Goal First**: Tell the user their goal and the smallest change needed before editing code.
2. **Model the Domain**: Define domain types and boundaries before writing logic.
3. **Subtract Before You Add**: Delete dead weight and simplify the base first.
4. **Prove It Works**: Test against the real artifact/runtime, never rely on "it compiles".
5. **No AI Fluff**: Write crisp, direct human prose with high signal-to-noise ratio.
