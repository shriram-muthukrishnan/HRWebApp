---
name: update-plan-with-clarifications
description: Update an existing modernization plan using answered clarification questions
---

# Update modernization plan with clarifications

This skill refines an existing modernization plan by incorporating the user's answers to
clarification questions. It rewrites `plan.md` and `tasks.json` in place using the same
template conventions as `create-modernization-plan`.

## User Input

modernization-work-folder (Mandatory): The folder containing the existing plan files (plan.md, tasks.json, clarifications.json)
plan-name (Mandatory): The name of the plan
modernization-prompt (Optional): A new prompt from the user describing additional changes or direction for the updated plan. May be empty.
language (Mandatory): The programming language of the project (java or dotnet)

## Workflow

1. **Read existing artifacts**: Read the following files from `modernization-work-folder`:
   - `plan.md` — existing high-level modernization plan
   - `tasks.json` — existing structured task list
   - `clarifications.json` — array of `{ "question": "...", "answer": "..." }` objects (may be absent or empty)

2. **Determine update context**: Collect all refinement inputs:
   - Answered entries from `clarifications.json` (entries where `answer` is non-empty). Unanswered entries (empty `answer`) should be ignored.
   - The new user prompt from `modernization-prompt`, if provided and non-empty.
   - Both inputs may be absent or empty; in that case preserve the existing plan without changes.

3. **Rewrite plan.md**: Update the plan overview to reflect any changes in scope, approach, or
   design decisions introduced by the answered clarifications and/or the new prompt. Follow the
   same **Template Selection** and **Plan Generation** rules defined in `create-modernization-plan`:
   preserve the existing template structure (Technical Framework, Overview, Migration Impact
   Summary) and do **not** include detailed task breakdowns in plan.md — those go in tasks.json.

4. **Rewrite tasks.json**: Update the task list to reflect any changes in task scope, requirements,
   ordering, or newly required tasks implied by the clarification answers and/or the new prompt.
   Follow the same **Task Breakdown Rules** defined in `create-modernization-plan`:
   - Preserve the existing schema and metadata structure. Keep task IDs stable where the task is
     unchanged.
   - Match tasks to skills/patterns using the same priority order (project skills → supported
     patterns → user prompt). Do **not** use pattern names as skill names.
   - Each task must remain independently testable.
   - Consult `java-upgrade-guideline.md` or `dotnet-upgrade-guideline.md` as applicable when
     updating upgrade tasks.

   **Updating vs adding tasks — critical rule**: When a clarification answer changes *how* an
   existing task is done (for example: which authentication method to use, which region to target,
   which configuration approach to follow), **update that task's `requirements` or `description`
   field in place**. Do **not** create a separate new task for an implementation detail that
   belongs to an existing task's scope. Only add a genuinely new task when the clarification
   introduces an entirely new migration goal or capability that has no corresponding task in the
   existing list. **The total number of tasks must not increase as a result of answering
   clarifications unless the answers introduce genuinely new migration scope.**

   Example — correct behaviour:
   - Existing task: `{ "id": "task-001", "title": "Migrate blob storage", "requirements": ["configure storage connection"] }`
   - Clarification answer: "Use managed identity instead of connection strings"
   - ✅ Update task-001: set `requirements` to `["configure managed identity for Azure Storage"]`
   - ❌ Do NOT add a new task-002 "Configure managed identity" alongside the unchanged task-001

5. **Write updated files**: Save the updated `plan.md` and `tasks.json` back to `modernization-work-folder`.
   Do not modify `clarifications.json`.

## Important Notes

- Only modify tasks that are genuinely affected by the clarification answers.
- Do not remove tasks unless the clarification explicitly indicates they are no longer needed.
- Keep the `metadata` block in `tasks.json` unchanged (same `planName`, `createdAt`, etc.).
- Do not add new tasks for implementation details (auth method, region choice, config format, etc.);
  incorporate those details into the `requirements` of the relevant existing task.
