---
name: pre-review
description: Self pre-review a PR before requesting review from teammates
---

Self pre-review a PR before requesting human review.

<given-input>
$ARGUMENTS
</given-input>

If the given input includes a PR number or repo, use that. Otherwise, work with the current branch's PR.

## Steps

1. Run `gh pr view --json title,body,state,url,baseRefName,headRefName,author` to get PR metadata.
2. Run `gh pr diff` (or with PR number/repo if specified) to get the full diff.
3. If an `agents/` directory exists in the repository, invoke `/check-agents-rules` to check compliance against the team's rules. Then review the diff focusing on things the agents rules would NOT catch: bugs, logic errors, security issues, and whether the PR description matches the changes.
4. If NO `agents/` directory exists, review the diff against these baseline rules:
   - **Correctness**: Bugs, logic errors, off-by-one, race conditions, null/undefined handling
   - **Security**: Injection, hardcoded secrets, improper auth checks
   - **Deferred quality**: TODO/FIXME/HACK in new code that should be addressed now; "follow-up PR" markers for small fixable things
   - **PR hygiene**: Does the description match the changes? Is the PR focused on a single concern? Should large changes be split?
   - **Simplicity**: Over-engineering, unnecessary abstractions, cleverness over clarity, magic numbers
   - **Test coverage**: Are new code paths tested? Are tests meaningful?
5. Output a concise report in markdown (no preamble):

```markdown
# Pre-Review: <PR Title>

**URL**: <url> | **Branches**: `<source>` → `<target>`

## Agents Rules Compliance

<Include findings from /check-agents-rules, or "No agents/ folder found — skipped.">

## Issues Found

### 🔴 Must Fix
- **<file:line>**: <issue and fix>

### 🟡 Should Fix
- **<file:line>**: <issue and fix>

## Verdict: <✅ Ready for Review / 🟡 Minor Issues / 🔴 Needs Work>

<One sentence: what's the #1 thing to address>
```

Keep the report short. Skip empty sections. Don't repeat what the agents rules compliance section already covers.
