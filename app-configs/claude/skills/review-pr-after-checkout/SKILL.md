---
name: review-pr-after-checkout
description: Review pull requests and provide feedback
---

Check out to the branch of this PR and review it: $ARGUMENTS

Commands to use:

- gh pr checkout {<number> | <url> | <branch>} [flags]
- gh pr diff <PR_NUMBER> --repo <OWNER>/<REPO>

Review and analyze the PR with detailed insights using the task information and diff provided above. Output the analysis in markdown without messages like "Here's the analysis."

## Guidelines

1. **Analyze the PR**:
   - Draft a concise, human-readable description that answers:
     1. What does the PR do (plain-language)?
     2. Why does it matter (impact or risk)?
     3. What should a reviewer focus on (2-4 bullets)?
   - Keep it short (1 paragraph + bullets).
   - In the Summary, add an easy, example-based explanation of what the PR does and explain how
     the behavior was different before this PR ("before vs now" in plain language).
   - When drafting the Summary section, lead with a plain-language sentence that explains what
     the PR does, keep follow-ups short and clear, and add a short example when the change is complicated.

2. **Output Format**:

```markdown
# PR Review: <PR Title>

**Author**: <author>
**Branches**: `<source>` → `<target>`
**URL**: <url>

---

## Summary

Start with one plain-language sentence that says what this PR does in the simplest terms, then add up to two short follow-up sentences that clarify the intent or impact. When the PR is complex, add a brief example (e.g., "This wires the new billing flow so invoices auto-generate when a subscription activates.") so the reviewer can grasp the purpose quickly.

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

### 🔴 Potential Issues
- <Issue 1>
- <Issue 2>

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
