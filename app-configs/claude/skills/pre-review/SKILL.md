---
name: pre-review
description: Self pre-review a PR before requesting review from teammates
---

Perform a thorough self pre-review of a PR before it goes out for human review. This acts as a quality gate to catch issues early and respect reviewers' time.

## Input

<given-input>
$ARGUMENTS
</given-input>

If the given input includes a PR number or repo, use that. Otherwise, work with the current branch's PR.

## Steps

### 1. Gather PR context

- Run `gh pr view --json title,body,state,url,baseRefName,headRefName,author` to get PR metadata.
- Run `gh pr diff` (or `gh pr diff <PR_NUMBER> --repo <OWNER>/<REPO>` if specified) to get the full diff.
- Read the PR description to understand the stated intent.

### 2. Check against team rules (agents folder)

- If an `agents/` directory exists in the repository, invoke the `/check-agents-rules` skill to get a compliance report.
- Include the compliance report findings in your final output.

### 3. Review the diff with engineering best practices

Evaluate the PR against these principles:

**No deferred quality**
- Flag any TODO comments, "fix later", or "follow-up PR" markers for small things that should be done now.
- Small refactors that can be done in-place should not be deferred.

**Code quality and correctness**
- Look for bugs, logic errors, edge cases, race conditions, or off-by-one errors.
- Check error handling: are errors caught, logged, and handled appropriately?
- Check for security issues (injection, XSS, hardcoded secrets, improper auth checks).

**Simplicity**
- Flag over-engineering: unnecessary abstractions, premature generalization, feature flags for one-off things.
- Flag cleverness over clarity: dense one-liners, obscure patterns, magic numbers.
- Ask: is there a simpler way to achieve the same result?

**Test coverage**
- Are new code paths tested?
- Are edge cases covered?
- Are tests meaningful (not just testing that mocks return what they were told to return)?

**Consistency**
- Does the code follow the existing patterns in the codebase?
- Naming conventions, file organization, import ordering.

**PR hygiene**
- Is the PR focused on a single concern, or does it mix unrelated changes?
- Is the PR description clear and complete?
- Are there any large files or changes that should be split out?

### 4. Produce the self-review report

Output the analysis in markdown, starting directly without preamble.

```markdown
# Self Pre-Review: <PR Title>

**URL**: <url>
**Branches**: `<source>` → `<target>`

---

## PR Description Assessment

<Is the description clear? Does it explain what and why? Any improvements needed?>

---

## Agents Rules Compliance

<Include the compliance report from check-agents-rules if agents/ folder exists, otherwise note "No agents/ folder found in this repository — skipping rules check.">

---

## Code Review Findings

### 🔴 Must Fix Before Review
<Issues that would definitely be flagged by reviewers or could cause bugs>
- **<file:line>**: <issue and suggested fix>

### 🟡 Should Fix Before Review
<Things that a thorough reviewer would flag — nits, style issues, minor improvements>
- **<file:line>**: <issue and suggested fix>

### 💡 Consider
<Suggestions that could improve the PR but are optional>
- <suggestion>

### ✅ What Looks Good
<Briefly note well-done aspects to acknowledge good patterns>
- <positive observation>

---

## Deferred Quality Check

<List any TODO/FIXME/HACK comments or "follow-up PR" markers in the diff. For each, assess whether it should be addressed now or is genuinely better as a follow-up.>

---

## Checklist

- [ ] PR description is clear and complete
- [ ] No deferred quality for small fixable items
- [ ] Error handling is appropriate
- [ ] No security concerns
- [ ] Tests cover new code paths
- [ ] Code follows existing codebase patterns
- [ ] No unrelated changes mixed in
- [ ] No hardcoded secrets or credentials

---

## Overall Verdict

<One of: ✅ Ready for Review / 🟡 Minor Issues to Address / 🔴 Needs Work>

<Brief summary: what's the #1 thing to address, and overall quality assessment>
```
