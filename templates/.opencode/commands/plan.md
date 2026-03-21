---
agent: plan
description: Use this command to create an implementation plan
---

# PHASE 1: INVESTIGATION + PLANNING

## Context

- You MUST read all `AGENTS.md` files — project conventions and coding standards;
- You MUST read all references explicitly provided in the input;
- Investigation/research is allowed ONLY in this step;

## Input

$ARGUMENTS

## Objective

Produce an execution-ready implementation plan:

1. A dependency-ordered list of implementation steps (actionable, scoped);
2. A human-readable plan summary with dependency chains + rationale;

## Strict Rules

### Planning Boundaries

- Reuse existing architecture/mechanisms;
- Do NOT redesign systems unless strictly necessary and justified by current codebase constraints;
- Introduce new abstractions ONLY IF explicitly required by the scope and justified by the sources;

### Source Grounding

- Every step MUST be grounded in provided sources (`AGENTS.md` + referenced docs/code); no speculation;
- Assumptions MUST be explicit and minimal; prefer "Missing Context" over guessing;
- If any required context/reference is missing or inaccessible, REPORT "Missing Context" and HALT (no plan);

### Plan Quality and Failure Minimization

- Steps must be narrowly scoped.
- Each step must have a writable outcome (something concrete to implement);
- Each step must specify the exact dependency prerequisites;
- Each step must not allow finishing without passing lint or type checks;
- The order of steps must follow the order from smaller utils and sub-components to larger features and flows;
- No ambiguous verbs ("handle", "improve", "fix") without a concrete expected outcome;

## Output Format

```markdown
### Missing Context
- *List missing items here*

---

### Implementation Steps

#### Step: S1

Title: Short, specific title
Intent: Implementation intent (what will be built/changed)
Affected Area: Domain / system / repo area impacted
Dependencies: Step IDs and/or external prerequisites

In Scope:
- *explicit bullets*

Out of Scope:
- *explicit bullets*

Acceptance Criteria:
- *explicit bullets*

Implementation Notes
- *Include file pointers if strongly supported by sources*
- *If file targets are uncertain, state that explicitly*

Source Trace
*Cite the exact references that justify this step; include paths/links/sections*

---

### Plan Summary

#### Dependency Chains

*Structured list of each dependency chain with step IDs, titles, relationships and rationale*
```
