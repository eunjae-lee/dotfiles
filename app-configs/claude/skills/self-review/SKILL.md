---
name: self-review
description: Self-review your own PR before requesting review from teammates
---

Self pre-review a PR before requesting human review.

<given-input>
$ARGUMENTS
</given-input>

If the given input includes a PR number or repo, use that. Otherwise, work with the current branch's PR.

## Steps

1. Run `gh pr view --json title,body,state,url,baseRefName,headRefName,author` to get PR metadata.
2. Run `gh pr diff` (or with PR number/repo if specified) to get the full diff.
3. If an `agents/` directory exists in the repository, invoke `/check-agents-rules` to check compliance against the team's rules.
4. Review the diff against these baseline rules:
   - **Correctness**: Bugs, logic errors, off-by-one, race conditions, null/undefined handling
   - **Security**: Injection, hardcoded secrets, improper auth checks
   - **Deferred quality**: TODO/FIXME/HACK in new code that should be addressed now; "follow-up PR" markers for small fixable things
   - **PR hygiene**: Does the description match the changes? Is the PR focused on a single concern? Should large changes be split?
   - **Simplicity**: Over-engineering, unnecessary abstractions, cleverness over clarity, magic numbers
   - **Test coverage**: Are new code paths tested? Are tests meaningful?
   - **Observability**: Server-side code should use `logger` (not `console.log`) for relevant info. Meaningful user-facing actions should be tracked with PostHog events.
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

⏳ **Reminder**: Make sure CI passes before requesting review.
```

Keep the report short. Skip empty sections. Don't repeat what the agents rules compliance section already covers.

## Post-Report Actions

After outputting the report, use `AskUserQuestion` to prompt next steps based on what was found:

- **If PR description doesn't match the diff** (PR hygiene issue): Ask whether to update the PR description to reflect the actual changes.
- **If there are "Must Fix" or "Should Fix" issues**: Ask whether to auto-fix the issues now or leave them for manual fixing.
- **Always ask as a final step**: "Mark PR as ready for review?", "Fix issues first", or "Leave as draft?". Before offering "Mark PR as ready for review", run `gh pr checks` — if any checks are still pending or failing, do NOT offer that option and instead warn the user that CI must pass first.
