---
agent: build
description: Use this command for executing the code review of the implementation.
---

# PHASE 3: ONE-SHOT CODE REVIEW

## Objective

Run an independent code review via a dedicated sub-agent to verify:
1. No regressions introduced by executed changes;
2. Execution fidelity to the plan (no dropped requirements, no scope creep);
3. Acceptance criteria coverage and risk hotspots;

If the review identifies critical issues, the main agent should add new execution steps to fix them and re-run the review after those steps are executed.

If the review is clean, the main agent can proceed to declare completion and produce a structured review report with a clear verdict.

## Review Orchestration Rules

- Spawn exactly ONE review sub-agent;
- The reviewer MUST review only what was executed:
  - referenced steps; 
  - diff implied by:
    [changed files list]
- The reviewer MAY read any repository files needed to understand impacts;
- The reviewer MUST NOT do new planning or redesign; focus on correctness, safety, maintainability, and plan fidelity;

## Review Sub-Agent Prompt

### Context

Inputs available:
- Plan: ${PLAN_FROM_PHASE_1};
- Execution summary: ${EXECUTION_FROM_PHASE_2};
- Changed files list: ${CHANGED_FILES};

You MAY read repository code freely to assess impact.

### Objective

Perform a code review to detect regressions and confirm the implementation matches the plan.

### Non-Negotiable Rules

- Do NOT propose new features or expand scope;
- Do NOT assume tests exist; explicitly check whether tests were updated/added where risk indicates;
- Every concern MUST cite concrete evidence: file path + symbol/region + reasoning;
- Treat plan acceptance criteria as contract; verify each is met or explicitly not verifiable;

### Review Checks

#### Plan Fidelity
- For each planned action/step: verify it was completed as specified (scope + acceptance criteria);
- Detect omissions: planned items not implemented or partially implemented;
- Detect drift: changes implemented that are not justified by plan scope;

#### Regression Risk
- Check behavior changes at boundaries (APIs, state transitions, error paths);
- Check invariants and assumptions noted in the plan (are they enforced / still true?);
- Check backwards compatibility where relevant (callers, configs, persisted data);
- Check tests: coverage of new/changed behavior; risk-based test gaps;
- Check for "silent breaks": renamed exports, changed signatures, altered defaults;

#### Maintainability Sanity
- Obvious complexity spikes, unclear naming, hidden side effects, dead code introduced;
- Alignment with AGENTS.md conventions (only for the touched areas);

## Main Agent Post-processing

- If verdict is REQUEST_CHANGES:
  - Do NOT declare completion;
  - Add new execution steps to fix the identified issues (scope strictly limited to addressing review concerns);
  - Re-run the execution command for the new steps;
- Otherwise:
  - Append the review report to the final response as "Code Review";

## Final Output Format

```markdown
## Execution Summary
[Summary of execution results from Step 2]

## Code Review
[Structured review report from the review sub-agent]

### Proposed Commit Message
[Title no more than 70 characters, body - the list of changes made after all steps and review.]
```
