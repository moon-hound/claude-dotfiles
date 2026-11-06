---
name: simplify
description: "Run multi-pass simplification on active code edits: enforces Ponytail YAGNI standards, strips AI fluff with unslop, removes redundant comments, and verifies tests still pass."
---

# In-Session Multi-Pass Simplification

Applies the Thomas Kim Episode 5 de-bloat protocol to active uncommitted git changes before commits or PRs.

## The Simplification Ladder

1. **Pass 1 — Ponytail Audit (`/ponytail-review`)**:
   - Smallest working diff wins.
   - Standard library and platform native features over extra dependencies.
   - Delete dead weight, redundant wrappers, and speculative abstractions.
2. **Pass 2 — Unslop (`/unslop`)**:
   - Strips AI conversational tells and sycophantic docstrings.
   - Eliminates unnecessary defensive type guards on internal boundaries.
3. **Pass 3 — Redundant Comments (`/no-comments`)**:
   - Removes trivial inline comments (`// loop through items`, `// call API`).
   - Keeps only the essential *why* that code cannot express.
4. **Pass 4 — Safety Re-Test**:
   - Reruns the project's verification suite (`/verify`) to ensure simplification caused zero regressions.

