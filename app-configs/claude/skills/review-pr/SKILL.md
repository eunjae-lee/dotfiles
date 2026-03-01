---
name: review-pr
description: Review pull requests and provide feedback
context: fork
---

Review a PR.

If the argument is given in the following block, read the diff by `gh pr diff <PR_NUMBER> --repo <OWNER>/<REPO>`.

<given-input>
$ARGUMENTS
</given-input>

If the given input is empty, use `gh pr diff` for the current branch's PR, and also can possibly get more info with something like `gh pr view --json title,body,state,url,author`.

Review and analyze the PR with detailed insights using the task information and diff provided above. Output the analysis in markdown without messages like "Here's the analysis."

## Steps

1. If an `agents/` directory exists in the repository, invoke `/check-agents-rules` to check compliance against the team's rules.
2. Review the diff against these baseline rules:
   - **Correctness**: Bugs, logic errors, off-by-one, race conditions, null/undefined handling
   - **Security**: Injection, hardcoded secrets, improper auth checks
   - **Deferred quality**: TODO/FIXME/HACK in new code that should be addressed now; "follow-up PR" markers for small fixable things
   - **PR hygiene**: Does the description match the changes? Is the PR focused on a single concern? Should large changes be split?
   - **Simplicity**: Over-engineering, unnecessary abstractions, cleverness over clarity, magic numbers
   - **Test coverage**: Are new code paths tested? Are tests meaningful?
3. Analyze the PR:
   - Draft a concise, human-readable description that answers:
     1. What does the PR do (plain-language)?
     2. Why does it matter (impact or risk)?
     3. What should a reviewer focus on (2-4 bullets)?
   - Keep it short (1 paragraph + bullets).
   - In the Summary, add an easy, example-based explanation of what the PR does and explain how
     the behavior was different before this PR ("before vs now" in plain language).
   - When drafting the Summary section, lead with a plain-language sentence that explains what
     the PR does, keep follow-ups short and clear, and add a short example when the change is complicated.

## Output Format

```markdown
# PR Review: <PR Title>

**Author**: <author>
**Branches**: `<source>` → `<target>`
**URL**: <url>

---

## Summary

Start with one plain-language sentence that says what this PR does in the simplest terms, then add up to two short follow-up sentences that clarify the intent or impact. When the PR is complex, add a brief example (e.g., "This wires the new billing flow so invoices auto-generate when a subscription activates.") so the reviewer can grasp the purpose quickly.

---

## Agents Rules Compliance

<Include findings from /check-agents-rules, or "No agents/ folder found — skipped.">

---

## Key Changes

### 1. <Change Category>

<Explanation of the change>

**Example:**
```<language>
// Before or relevant code snippet
```

### 2. <Another Change Category>

...

---

## Review Comments

### 🔴 Must Fix
- **<file:line>**: <issue and fix>

### 🟡 Should Fix
- **<file:line>**: <issue and fix>

### 💡 Suggestions
- <Suggestion 1>
- <Suggestion 2>

### ❓ Questions
- <Question 1>
- <Question 2>

### ✅ Strengths
- <Positive 1>
- <Positive 2>

---

## Recommended Review Order

1. **<file1.ext>** - <why review first>
2. **<file2.ext>** - <what to focus on>
3. **<file3.ext>** - <context>
...

---

### Overall Assessment

<High-level conclusion about the PR quality, readiness, and any blockers>
```

Keep the report short. Skip empty sections. Don't repeat what the agents rules compliance section already covers.
