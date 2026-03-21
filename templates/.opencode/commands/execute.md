---
agent: build
description: Use this command to execute the implementation plan created in the previous phase.
---

# PHASE 2: EXECUTION

## Input

$ARGUMENTS

## Objective

Execute the implementation steps via sub-agents.

For each step in the plan:
1. Generate a self-contained implementation-only prompt for the step, including all necessary context and references for implementation;
2. Run the implementation sub-agent with the generated prompt;
3. Halt/skip/remediate correctly on failures (per rules below);
4. Aggregate results with full traceability to the original plan;

## Global Execution Rules

- You MUST execute in dependency order; a step runs only if all dependencies succeeded;
- Each sub-agent objective MUST be implementation-only (no research, no planning);
- Sub-agents MAY read additional repository files as needed to implement, BUT they MUST implement ONLY what their prompt objective requests;
- If a step is `failed` or `blocked` for reasons resolvable by repository changes, do NOT execute downstream dependents. Add intermediate remediation steps (e.g., `S1.1`, `S1.2`) and resume from the original failed/blocked step after remediation succeeds;
- If you've noticed sub-agent drifting from the original step objective, insert a remediation step to fix the drift before resuming;
- Each inserted remediation step MUST declare: (a) parent step ID, (b) blocker being resolved, (c) minimal scope strictly limited to unblocking the parent step;
- Inserted remediation steps MUST NOT introduce unrelated feature work or refactors;
- Aggregate outputs after all runnable steps complete;

## Sub-Agent Prompt Template

### Inputs for This Prompt

- Step ID: ${STEP_ID};
- Step Title: ${TITLE};
- Scope: ${SCOPE};

### Context

- You MUST read all `AGENTS.md` files — project conventions and coding standards;
- You MUST read all references explicitly provided: ${STEP_REFERENCES};

### Objective

Implement exactly this step: ${TITLE}

#### Intent

${INTENT}

#### Affected Area

${AFFECTED_AREA}

#### Acceptance Criteria

${ACCEPTANCE_CRITERIA}

#### Source Trace

${SOURCE_TRACE}

### Non-Negotiable Rules

- Implementation ONLY: do NOT do research, do NOT do planning, do NOT propose alternative designs;
- Do NOT modify anything outside the stated scope;
- Do NOT introduce new abstractions unless explicitly required by the scope and justified;
- Do NOT redesign systems;
- Satisfy ALL acceptance criteria; if any item cannot be met, set `Status: failed` with explanation (no partial success labeling);

### Execution Context

#### Step Identity

- Step ID: ${STEP_ID};
- Depends On: ${DEPENDENCIES};
- Steps Index: ${STEPS_INDEX};
- Execution Order: ${STEPS_INDEX};

#### Dependency Context

*List upstream IDs/titles only, no duplication*
```
${UPSTREAM_ID_TITLE_LIST}
```

### Output Format

Status: `success` \| `failed` \| `blocked`
Result: What was done (concise, verifiable)
Files Modified: [explicit list or empty]

Missing Context:
- *List missing items here*

Source Trace:
- *Cite which provided references justify the changes*

Open Issues:
- *Unresolved problems or follow-ups*

---

## Orchestration Output Format

```markdown
### Execution Summary

### Execution Plan Updates
- Inserted Steps: [list or empty]
- Dependency Changes: [list or empty]

#### Step S1: ${TITLE}
- Status: ...
- Files Modified: [list]
- Notes: [any issues or assumptions made]

#### Step S2: ...
...

### Final Result
[Aggregated outcome across successful steps]
```
