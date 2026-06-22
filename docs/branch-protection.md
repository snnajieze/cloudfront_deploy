# Branching Strategy & Branch Protection

## The required strategy

| Rule | Requirement |
|---|---|
| Direct pushes to `devel` / `stage` | Prohibited - PRs only |
| Merges into `stage` | Only from `devel` |
| Merges into `devel` | Only from `feature/*` or `bugfix/*` branches |
| New work | Always in a `feature/*` or `bugfix/*` branch, branched off `devel` |

## How each rule is enforced

### "Direct pushes are prohibited"

Native GitHub branch protection, applied by `scripts/setup-branch-protection.sh`:

- `required_pull_request_reviews` with at least 1 approving review.
- `enforce_admins = true`, so even repository admins must go through a
  PR (this is what makes "prohibited," not "discouraged").
- No `restrictions` bypass list - nobody is exempted.

This alone stops anyone from pushing a commit straight to `devel` or
`stage`, regardless of which branch it came from.

### "Only devel may merge into stage" / "Only feature/bugfix may merge into devel"

GitHub's native branch protection has no field for "restrict which
source branch can open a PR into this target" - the closest native
feature is restricting who can push, not which branch they push from.
So this is enforced with a small, explicit check instead:

`.github/workflows/branch-policy.yml` runs on every PR targeting `devel`
or `stage` and inspects `github.event.pull_request.base.ref` /
`head.ref`:

- base = `stage` and head != `devel` -> fails the check.
- base = `devel` and head is not `feature/*` or `bugfix/*` (and isn't
  `stage` trying to merge backwards) -> fails the check.

The job's name (`Validate source/target branch combination`) is then
added as a **required status check** in branch protection, exactly like
the CI Summary check. A PR cannot merge until both checks pass, so the
source-branch restriction is enforced with the same strength as a native
setting - it's just implemented in code instead of a checkbox.

### "All new work happens in feature/bugfix branches"

This is encouraged by the repo layout and enforced transitively: since
`branch-policy.yml` only allows `feature/*` and `bugfix/*` branches to
merge into `devel`, there's no path for ad-hoc branch names to land
changes at all - they're stuck unable to open a mergeable PR into either
protected branch.

## Applying the configuration

```bash
./scripts/setup-branch-protection.sh <owner>/<repo>
```

Requires the [GitHub CLI](https://cli.github.com/) authenticated with
admin access to the repository. Run this once `ci.yml` and
`branch-policy.yml` have executed at least once (so GitHub has seen the
check names referenced in the script).

## Demonstrating it

To produce sample PRs that show this working end-to-end:

1. `git checkout devel && git checkout -b feature/sample-change`
2. Make a small change (e.g. tweak `app/src/App.jsx`), commit, push.
3. Open a PR `feature/sample-change -> devel`. CI runs; branch-policy
   passes (head is `feature/*`, base is `devel`). Merge.
4. `git checkout stage && git checkout -b feature/oops` and try to PR
   directly into `stage`. The branch-policy check fails immediately
   ("Only the 'devel' branch may be merged into 'stage'"), giving a
   concrete example of a blocked, non-compliant PR.
5. Open a PR `devel -> stage`. branch-policy passes; CI runs against the
   merged result; merge it to trigger the stage deploy.
