---
name: experts
description: Convene a council of expert agents to research, debate, and recommend solutions for any topic.
---

Convene a council of expert agents to research, debate, and recommend solutions for any topic.

## Process

### Phase 1: Clarification (Required)

**Before spawning any agents**, determine what information is needed:

1. **Analyze the topic** from conversation context or user's args
2. **Identify 1-4 critical questions** that would change the expert analysis
3. **Use AskUserQuestion modal** to gather answers
   - Multiple choice options (2-4 per question)
   - Always allow "Other" for custom input (automatic)
   - Ask all questions in ONE modal call (not sequential)

**If the topic is already fully specified** (includes constraints, context, requirements), skip clarification and proceed to Phase 2.

### Phase 2: Determine Council Composition

Based on topic complexity and scope, decide:

**Number of experts: 4-10**
- **4 experts** — Simple topic with clear domain (e.g., "which JS framework")
- **5-7 experts** — Moderate complexity, multiple perspectives
- **8-10 experts** — Complex topic requiring diverse expertise

**Expert selection criteria:**
- Cover all relevant domains (technical, business, user experience, security, operations)
- Include contrarian/skeptical perspectives (prevent groupthink)
- Match expertise to the actual question

### Phase 3: Research & Initial Positions

**Spawn all experts in parallel** using Agent tool (or Workflow if 8+ experts).

**CRITICAL: Each expert MUST do deep research BEFORE forming opinions.**

**Each expert's prompt should:**
1. State their role and perspective
2. Include all clarification answers from Phase 1
3. **REQUIRE web search/research tools usage** — experts must cite current data, not training knowledge
4. Request deep research on their domain (as many sources as needed)
5. Ask for initial position with supporting evidence
6. Include instruction to output structured findings with citations

**Research requirements for each expert:**
- Must use WebSearch and WebFetch tools as extensively as needed for accuracy
- Must cite ALL sources with URLs where evidence comes from
- Must include publication dates for ALL time-sensitive claims
- Must verify key claims across multiple independent sources
- Must prioritize recent sources (prefer <6 months old, flag anything >2 years)
- Must distinguish between "industry standard" (cite survey/report) vs "my opinion"
- Must note if research turned up conflicting information

**Accuracy verification:**
- Critical claims (performance numbers, security issues, costs) require 2+ independent sources minimum
- Prefer primary sources (official docs, benchmarks) over secondary (blog posts, Reddit)

**Example expert prompt template:**
```
You are a [ROLE] with [X] years of experience. Analyze [TOPIC] from the [PERSPECTIVE] perspective.

Context from user:
- [Answer 1]: [Value]
- [Answer 2]: [Value]

Your task:
1. **RESEARCH FIRST** - Use web search and fetch tools extensively:
   - Current best practices for [TOPIC] (prefer sources <6 months old)
   - Recent benchmarks, case studies, or comparisons (official sources preferred)
   - Known issues, gotchas, or limitations
   - Cost/performance data if relevant
   - Cross-reference critical claims across 2+ independent sources

2. After thorough research, identify 3-5 viable approaches from your domain perspective

3. Analyze tradeoffs for each approach using your research findings (cite specific data)

4. Form an initial position on which approach is best and why (evidence-based only)

Provide structured output:
- Your recommended approach
- Key advantages (3-5 bullet points with evidence + citations + dates)
- Key disadvantages (3-5 bullet points with evidence + citations + dates)
- Deal-breakers (what would make this approach wrong)
- Open questions that other experts should address
- Sources consulted (list ALL URLs with publication dates)
- Conflicting findings (if any sources disagreed, explain the discrepancy)

**IMPORTANT:** Base your analysis ONLY on current research data, not training knowledge.
```

**Quality check:** Before proceeding to Phase 4, verify each expert's output includes:
- At least 5+ source citations
- Specific data points with verification
- Publication dates for ALL sources
- Acknowledgment of any conflicting research findings

**If any expert fails quality check:** Reject their output and require re-research before debate begins.

### Phase 4: Cross-Examination & Debate

**Spawn synthesis agents** (2-3 agents) to cross-examine the initial positions:

```
You are a technical moderator facilitating an expert debate on [TOPIC].

You have [N] expert positions (attached below). Your task:
1. Identify areas of agreement and disagreement
2. Spot flawed reasoning, missing evidence, or unsupported claims
3. Challenge weak arguments
4. Synthesize overlapping recommendations
5. Extract the top 3-5 distinct viable options

For each viable option, document:
- Which experts support it (by name/role)
- Which experts oppose it (by name/role + why)
- Factual evidence supporting it
- Factual evidence against it
- What conditions make it the right choice
- What conditions make it the wrong choice

[EXPERT POSITIONS ATTACHED]
```

### Phase 5: Final Recommendation

**You (Claude) synthesize the synthesis** into final deliverable:

1. **Distill to Top 3 Options** — rank by viability, expert consensus, evidence strength
2. **For each of Top 3:**
   - Option Name, What it is, Pros, Cons, Best for, Avoid if, Expert support
3. **Council's Recommendation:**
   - Recommended option, Confidence level + why
   - Key deciding factors
   - Risks to watch + mitigations
   - Decision factors: when to choose differently

### Phase 6: Present to User

```markdown
# Expert Council: [Topic]

**Council composition:** [N] experts — [list roles]
**Deliberation summary:** [2-3 sentences]

---

## Top 3 Options

### Option 1: [Name]
[What it is]

**Pros:**
- [Pro 1 with evidence]

**Cons:**
- [Con 1 with evidence]

**Best for:** [Conditions]
**Avoid if:** [Conditions]
**Expert support:** [Names] recommended | [Names] opposed

---

### Option 2: [Name]
[Same structure]

---

### Option 3: [Name]
[Same structure]

---

## Council's Recommendation

**We recommend: Option [N] — [Name]**
**Confidence: [High/Medium/Low]**

**Why this option:**
[2-3 paragraphs]

**Key deciding factors:**
- [Factor 1]
- [Factor 2]

**Risks to watch:**
- [Risk 1] — Mitigation: [How to handle]

**You should choose differently if:**
- [Condition 1] → Choose Option [N] instead

---

## Expert Perspectives (Summary)

[2-3 paragraphs capturing key debates, disagreements, and consensus points]
```

## Rules

1. **ALWAYS ask clarifying questions first** unless the topic is fully specified
2. **Use AskUserQuestion modal** for all clarification (never text-based questions)
3. **Council size based on complexity:** 4 (simple) to 10 (complex)
4. **Include contrarian perspectives** to avoid groupthink
5. **Evidence-based only** — every claim needs supporting facts from expert research
6. **Top 3 must be distinct** — not minor variations of the same approach
7. **Recommendation must explain WHY** — not just state the winner
8. **Show expert disagreement** — if experts split 50/50, say so
9. **Conditional guidance** — tell user when to choose differently based on their situation
10. **Use Workflow tool for 8+ experts** — better orchestration for large councils

## Topic Detection

**From args:** `/experts which authentication method to use`

**From conversation context:** User discusses a topic, then says `/experts` — infer from last 3-5 turns

**Fully specified:** `/experts recommend database for 100M rows, heavy writes, <$500/mo, team knows Postgres` — skip clarification

## Quality Checks

Before presenting final output, verify:
- [ ] Top 3 options are meaningfully different
- [ ] Each option has concrete pros/cons with evidence
- [ ] Recommendation explains WHY it won
- [ ] Conditional guidance included
- [ ] Expert disagreements acknowledged
- [ ] No groupthink (at least one contrarian perspective)

## Token Budget

- 4 experts (with deep research): ~80-100k tokens
- 7 experts (with deep research): ~150-200k tokens
- 10 experts (with deep research): ~250-300k tokens

**Duration:** 10-25 minutes depending on council size and research depth
