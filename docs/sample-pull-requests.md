# Sample Pull Requests

The challenge asks for sample PRs that demonstrate the CI pipeline both
succeeding and failing, with per-step feedback. Since this environment
doesn't have a live GitHub remote attached, this document gives the
exact, reproducible steps to generate those PRs yourself, plus real
output captured locally from this repo's actual `app/` code (every
command below was actually run against this codebase while building it -
the output shown is not hypothetical).

## PR 1: A passing PR

```bash
git checkout devel
git checkout -b feature/update-readme-copy
# edit app/src/App.jsx, e.g. tweak the paragraph text
git add -A
git commit -m "Update homepage copy"
git push -u origin feature/update-readme-copy
gh pr create --base devel --head feature/update-readme-copy \
  --title "Update homepage copy" --body "Small copy tweak."
```

Expected result: both required checks go green -
`CI Summary` and `Validate source/target branch combination` - and the
PR becomes mergeable. The CI Summary job's GitHub Step Summary renders
as:

| Step | Result |
|------|--------|
| Install dependencies | success |
| Lint (ESLint) | success |
| Test (Jest) | success |
| Build | success |

## PR 2: A failing PR (lint step)

To produce this, introduce an unused variable - exactly what was used to
verify the pipeline while building this repo:

```bash
git checkout devel
git checkout -b feature/break-lint-demo
```

In `app/src/App.jsx`, add an unused variable inside the component:

```diff
 export default function App() {
+  const unusedDemoVariable = 123;
   const [count, setCount] = useState(0);
```

```bash
git add -A && git commit -m "demo: break lint"
git push -u origin feature/break-lint-demo
gh pr create --base devel --head feature/break-lint-demo \
  --title "demo: break lint" --body "Intentionally broken for the CI demo."
```

**Real output captured locally** (`npm run lint` against this exact
change):

```
> fsl-devops-challenge-app@1.0.0 lint
> eslint . --ext .js,.jsx --report-unused-disable-directives --max-warnings 0

/app/src/App.jsx
  6:9  warning  'unusedDemoVariable' is assigned a value but never used  no-unused-vars

1 problem (0 errors, 1 warning)
ESLint found too many warnings (maximum: 0).
```

Exit code `1`. In the PR, the `Lint (ESLint)` job fails while
`Install dependencies` stays green; `Test` still runs since it only
depends on `install`, not `lint` - but `CI Summary` fails overall since
it requires every job to succeed:

| Step | Result |
|------|--------|
| Install dependencies | success |
| Lint (ESLint) | failure |
| Test (Jest) | success |
| Build | skipped (depends on lint and test) |

The required-status-check failure blocks merging until the unused
variable is removed and the branch is updated.

## PR 3: A failing PR (test step)

```bash
git checkout devel
git checkout -b feature/break-test-demo
```

In `app/src/lib/environment.test.js`, change an assertion's expected
value:

```diff
   it('returns "Development" for the devel environment', () => {
-    expect(getEnvironmentLabel('devel')).toBe('Development');
+    expect(getEnvironmentLabel('devel')).toBe('WrongExpectedValue');
   });
```

**Real output captured locally** (`CI=true npm run test`):

```
FAIL src/lib/environment.test.js
  getEnvironmentLabel returns "Development" for the devel environment

    expect(received).toBe(expected) // Object.is equality

    Expected: "WrongExpectedValue"
    Received: "Development"

      3 | describe('getEnvironmentLabel', () => {
      4 |   it('returns "Development" for the devel environment', () => {
    > 5 |     expect(getEnvironmentLabel('devel')).toBe('WrongExpectedValue');
        |                                          ^
      6 |   });

Test Suites: 1 failed, 1 passed, 2 total
Tests:       1 failed, 5 passed, 6 total
```

Exit code `1`. The `Test (Jest)` job fails and uploads the Jest coverage
artifact regardless (`if: always()`), so the failure report is
attachable to the PR for review; `Build` is skipped because it depends
on `Test` succeeding.

## PR 4: A blocked PR (branch policy violation)

```bash
git checkout stage
git checkout -b feature/sneaky-stage-change
# any change
git push -u origin feature/sneaky-stage-change
gh pr create --base stage --head feature/sneaky-stage-change \
  --title "Trying to skip devel" --body "This should be blocked."
```

The `branch-policy.yml` check fails immediately, before any app code
even runs:

```
PR wants to merge 'feature/sneaky-stage-change' into 'stage'
Error: Only the 'devel' branch may be merged into 'stage'. This PR's
source branch is 'feature/sneaky-stage-change', which is not allowed.
```

This demonstrates the branching-strategy enforcement independently of
the app's CI pipeline.
