# /experts — Expert Council Deliberation

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
   - Examples:
     - "What's your budget range?" → [$0-1k, $1k-5k, $5k-10k, $10k+]
     - "What's your timeline?" → [Urgent (1 week), Normal (1 month), Flexible (3+ months)]
     - "What's your technical skill level?" → [Beginner, Intermediate, Advanced]

**If the topic is already fully specified** (includes constraints, context, requirements), skip clarification and proceed to Phase 2.

### Phase 2: Determine Council Composition

Based on topic complexity and scope, decide:

**Number of experts: 4-10**
- **4 experts** — Simple topic with clear domain (e.g., "which JS framework")
- **5-7 experts** — Moderate complexity, multiple perspectives (e.g., "design authentication system")
- **8-10 experts** — Complex topic requiring diverse expertise (e.g., "scale infrastructure for 10 users")

**Expert selection criteria:**
- Cover all relevant domains (technical, business, user experience, security, operations)
- Include contrarian/skeptical perspectives (prevent groupthink)
- Match expertise to the actual question (don't add experts for completeness if they won't contribute)

**Example councils:**
- Database choice → [DB architect, Backend engineer, DBA, Performance engineer, Cost analyst]
- Feature design → [UX designer, Frontend dev, Backend dev, Product strategist, Accessibility expert, QA engineer]
- Infrastructure scaling → [Systems architect, SRE, Database expert, Security engineer, Cost optimizer, DevOps engineer, Network engineer]

### Phase 3: Research & Initial Positions

**Spawn all experts in parallel** using Agent tool (or Workflow if 8+ experts).

**CRITICAL: Each expert MUST do deep research BEFORE forming opinions.**

**Each expert's prompt should:**
1. State their role and perspective
2. Include all clarification answers from Phase 1
3. **REQUIRE web search/research tools usage** - experts must cite current data, not training knowledge
4. Request deep research on their domain (as many sources as needed for truth/accuracy)
5. Ask for initial position with supporting evidence
6. Include instruction to output structured findings with citations

**Research requirements for each expert:**
- Must use WebSearch and WebFetch tools as extensively as needed for accuracy
- Quality over quantity - research until confident in findings, not to hit a number
- Must cite ALL sources with URLs where evidence comes from
- Must include publication dates for ALL time-sensitive claims
- Must verify key claims across multiple independent sources (cross-reference until confident)
- Must prioritize recent sources (prefer <6 months old, flag anything >2 years)
- Must distinguish between "industry standard" (cite survey/report) vs "my opinion"
- Must note if research turned up conflicting information
- Must discard or flag outdated information
- Continue researching until expert can speak from verified source of truth

**Accuracy verification:**
- Critical claims (performance numbers, security issues, costs) require 2+ independent sources minimum
- If sources disagree, expert must investigate further until resolved or note the disagreement explicitly
- Prefer primary sources (official docs, benchmarks) over secondary (blog posts, Reddit)
- If verification requires more research, do it - no limit on search depth

**Example expert prompt template:**
```
You are a [ROLE] with [X] years of experience. Analyze [TOPIC] from the [PERSPECTIVE] perspective.

Context from user:
- [Answer 1]: [Value]
- [Answer 2]: [Value]

Your task:
1. **RESEARCH FIRST** - Use web search and fetch tools extensively (as many as needed for accuracy):
   - Current best practices for [TOPIC] (prefer sources <6 months old)
   - Recent benchmarks, case studies, or comparisons (official sources preferred)
   - Known issues, gotchas, or limitations (check issue trackers, security advisories)
   - Cost/performance data if relevant (verify across multiple sources)
   - Community sentiment (GitHub stars, adoption trends, Stack Overflow surveys)
   - Cross-reference critical claims across 2+ independent sources
   - Flag any outdated information (>2 years old) or conflicting data

2. After thorough research, identify 3-5 viable approaches from your domain perspective

3. Analyze tradeoffs for each approach using your research findings (cite specific data)

4. Form an initial position on which approach is best and why (evidence-based only)

Provide structured output:
- Your recommended approach
- Key advantages (3-5 bullet points with evidence + citations + dates)
- Key disadvantages (3-5 bullet points with evidence + citations + dates)  
- Deal-breakers (what would make this approach wrong)
- Open questions that other experts should address
- Sources consulted (list ALL URLs with publication dates, note primary vs secondary)
- Conflicting findings (if any sources disagreed, explain the discrepancy)

**IMPORTANT:** 
- Base your analysis ONLY on current research data, not training knowledge
- Verify critical claims across multiple sources before citing them
- Prefer official documentation and primary sources over blog posts
- If you can't find recent data, say so explicitly rather than using old information
```

**Expected output:** Each expert returns their position + reasoning (5-10 paragraphs) with extensive research citations.

**Quality check:** Before proceeding to Phase 4, verify each expert's output includes:
- At least 5+ source citations (no maximum)
- Specific data points with verification (not just generic claims)
- Publication dates for ALL sources
- Recency verification (prefer <6 months, flag >2 years)
- Cross-referencing for critical claims (2+ sources for key numbers)
- Acknowledgment of any conflicting research findings
- Distinction between primary sources (official docs) and secondary (blogs/posts)
- Explicit note if recent data unavailable

**If any expert fails quality check:** Reject their output and require re-research before debate begins.

### Phase 4: Cross-Examination & Debate

**Spawn synthesis agents** (2-3 agents) to cross-examine the initial positions:

**Synthesis agent prompt template:**
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

**Expected output:** Each synthesis agent returns their analysis of the debate.

### Phase 5: Final Recommendation

**You (Claude) synthesize the synthesis** into final deliverable:

1. **Distill to Top 3 Options**
   - Rank by: viability, expert consensus, evidence strength
   - If experts proposed >3 options, merge similar ones or eliminate weak ones
   - If experts proposed <3 options, include runner-up or "hybrid" option

2. **For each of Top 3:**
   - **Option Name** (clear, concise)
   - **What it is** (2-3 sentences)
   - **Pros** (3-5 bullet points with supporting evidence from experts)
   - **Cons** (3-5 bullet points with supporting evidence from experts)
   - **Best for** (what conditions/constraints make this the right choice)
   - **Avoid if** (what conditions/constraints make this the wrong choice)
   - **Expert support** (which experts recommended this, which opposed)

3. **Council's Recommendation**
   - **Recommended option:** [Option #N]
   - **Confidence level:** [High/Medium/Low] + why
   - **Reasoning:** 2-3 paragraphs explaining why this option won
   - **Key deciding factors:** What made this better than the other 2
   - **Risks to watch:** What could go wrong + mitigation strategies
   - **Decision factors for you:** What should make you choose differently (e.g., "If budget is actually <$1k, choose Option 2 instead")

### Phase 6: Present to User

**Output format:**

```markdown
# Expert Council: [Topic]

**Council composition:** [N] experts — [list roles]
**Deliberation summary:** [2-3 sentences on what the council analyzed and debated]

---

## Top 3 Options

### Option 1: [Name]

[What it is]

**Pros:**
- [Pro 1 with evidence]
- [Pro 2 with evidence]
- [Pro 3 with evidence]

**Cons:**
- [Con 1 with evidence]
- [Con 2 with evidence]

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
[2-3 paragraphs explaining the reasoning]

**Key deciding factors:**
- [Factor 1]
- [Factor 2]
- [Factor 3]

**Risks to watch:**
- [Risk 1] — Mitigation: [How to handle]
- [Risk 2] — Mitigation: [How to handle]

**You should choose differently if:**
- [Condition 1] → Choose Option [N] instead
- [Condition 2] → Choose Option [N] instead

---

## Expert Perspectives (Summary)

[2-3 paragraphs capturing the key debates, disagreements, and consensus points]
```

---

## Rules

1. **ALWAYS ask clarifying questions first** unless the topic is fully specified
2. **Use AskUserQuestion modal** for all clarification (never text-based questions)
3. **Council size based on complexity:** 4 (simple) to 10 (complex)
4. **Include contrarian perspectives** to avoid groupthink
5. **Evidence-based only** — every claim needs supporting facts from expert research
6. **Top 3 must be distinct** — not minor variations of the same approach
7. **Recommendation must explain WHY** — not just state the winner
8. **Show expert disagreement** — if experts split 50/50, say so in the recommendation
9. **Conditional guidance** — tell user when to choose differently based on their situation
10. **Use Workflow tool for 8+ experts** — better orchestration for large councils

---

## Examples

### Example 1: Simple Topic (4 experts)

**User:** `/experts which database for this project`

**Clarification questions:**
1. What's your expected data size? [<1GB, 1-10GB, 10-100GB, 100GB+]
2. What's your query pattern? [Mostly reads, Balanced, Mostly writes]
3. What's your team's SQL experience? [Expert, Comfortable, Prefer NoSQL]

**Council:** 4 experts
- Database architect
- Backend performance engineer
- DevOps engineer (operational concerns)
- Cost analyst

**Top 3:** Postgres, MongoDB, SQLite
**Recommendation:** Postgres (for this use case)

---

### Example 2: Complex Topic (9 experts)

**User:** `/experts how should I scale my infrastructure for 5-10 users`

**Clarification questions:**
1. What's your deployment model? [Self-hosted, Hybrid, Cloud-native]
2. What's your team size? [Solo, 2-3 people, 4+ people]
3. What's your priority? [Minimize cost, Maximize reliability, Easiest maintenance]
4. What's your timeline? [Next month, Next quarter, Planning ahead]

**Council:** 9 experts
- Systems architect
- Database scaling expert
- Container orchestration engineer
- Security engineer
- Network architect
- SRE (monitoring/alerting)
- Cost optimization specialist
- DevOps automation engineer
- Disaster recovery specialist

**Top 3:** Kubernetes approach, Serverless approach, Enhanced single-server approach
**Recommendation:** Enhanced single-server (for this scale + constraints)

---

## Topic Detection

**From args:** `/experts which authentication method to use`
- Topic: "which authentication method to use"

**From conversation context:** User discusses authentication in prior messages, then says `/experts`
- Infer topic from last 3-5 conversation turns
- If ambiguous, ask: "What specific aspect of [topic] should the council analyze?"

**Fully specified:** `/experts recommend database for 100M rows, heavy writes, <$500/mo, team knows Postgres`
- Skip clarification (constraints already provided)
- Proceed directly to council

---

## Skill Metadata

**When to use:**
- User explicitly calls `/experts`
- User asks "what should I..." or "how should I..." for complex decisions
- User asks "what do experts think about..."

**Token budget:** Typically 80k-300k depending on council size and research depth
- 4 experts (with deep research): ~80-100k tokens
- 7 experts (with deep research): ~150-200k tokens  
- 10 experts (with deep research): ~250-300k tokens
- Note: Extensive research (5+ sources per expert) increases token usage significantly

**Duration:** 10-25 minutes depending on council size and research depth
- Deep research phase adds 5-10 minutes (5+ sources per expert, verification, cross-referencing)

---

## Quality Checks

Before presenting final output, verify:
- [ ] Top 3 options are meaningfully different (not minor variations)
- [ ] Each option has concrete pros/cons with evidence (not generic claims)
- [ ] Recommendation explains WHY it won (not just "experts agreed")
- [ ] Conditional guidance included ("choose differently if X")
- [ ] Expert disagreements acknowledged if they exist
- [ ] All clarification answers incorporated into analysis
- [ ] No groupthink (at least one contrarian perspective included)
