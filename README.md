# FSL DevOps Challenge

A working CI/CD + Terraform implementation of the FSL DevOps challenge: a
sample app, a CI pipeline gating every pull request, and a CD pipeline
that provisions isolated `devel` and `stage` environments on AWS (S3 +
CloudFront, behind an enforced branching strategy).

## Contents

```
app/                          Sample static application (Vite + React)
infra/
  bootstrap/                  One-time setup: TF state bucket + GitHub OIDC role
  modules/
    logging_bucket/           Private S3 bucket for CloudFront access logs
    s3_website/                Private S3 bucket for the built app
    cloudfront/                CloudFront distribution + Origin Access Control
    static_site/                Composes the three modules above per environment
  environments/
    devel/                     Root config for the devel environment
    stage/                     Root config for the stage environment
.github/workflows/
  ci.yml                       Part 1: install -> lint -> test -> build, on every PR
  cd.yml                       Part 2: terraform apply + deploy, on merge to devel/stage
  branch-policy.yml            Enforces "only devel may merge into stage"
  teardown.yml                 Manual disable/destroy for the recording-period requirement
scripts/
  bootstrap-repo.sh            Creates devel/stage branches, prints setup steps
  setup-branch-protection.sh   Configures GitHub branch protection via gh CLI
docs/
  branch-protection.md         What's enforced and how
  accessibility-window.md      How the "recording period only" requirement is handled
  aws-oidc-setup.md            How CI authenticates to AWS (no static keys)
```

## How this maps to the challenge

### Part 1 - Continuous Integration

- **Repository + CI tool**: GitHub + GitHub Actions.
- **Trigger**: `ci.yml` runs `on: pull_request` for `opened`, `synchronize`,
  and `reopened`, targeting `devel` and `stage` - i.e. any PR created or
  updated against either protected branch.
- **Steps**, each a separate job so pass/fail feedback is per-step rather
  than one opaque job:
  1. `npm install`
  2. `npm run lint` (ESLint)
  3. `CI=true npm run test` (Jest)
  4. `npm run build`
- A final `CI Summary` job aggregates the four results into one required
  status check (GitHub Step Summary table + non-zero exit if anything
  failed), which is what branch protection actually requires.
- PRs cannot merge into `devel` or `stage` unless this check passes (see
  `docs/branch-protection.md`).

### Part 2 - Continuous Deployment

- **CD tool**: GitHub Actions (`cd.yml`), triggered `on: push` to `devel`
  or `stage` - which, because both branches are protected, only ever
  happens as the result of a merged PR.
- **Terraform** provisions, per environment:
  - A private S3 bucket for the built app (no public access; encrypted;
    versioned).
  - A private S3 bucket for CloudFront access logs.
  - A CloudFront distribution in front of the app bucket, using Origin
    Access Control (OAC - the current, non-deprecated mechanism) so the
    app bucket is never directly reachable from the internet.
- **Environments**: `infra/environments/devel` and
  `infra/environments/stage` are independent Terraform root modules with
  separate state files, so they can be planned/applied/destroyed without
  affecting each other.
- **Accessibility**: anyone with the CloudFront URL can reach the app
  (HTTPS, no auth) - see `docs/accessibility-window.md` for how the
  "only during the recording period" requirement is handled.
- **Branching strategy**: enforced by branch protection + a dedicated
  status check - see `docs/branch-protection.md`.

## Getting started

```bash
# 1. Try the app locally
cd app
npm install
npm run lint
CI=true npm run test
npm run build
npm run preview   # serves dist/ locally

# 2. Bootstrap the repository (creates devel/stage branches)
./scripts/bootstrap-repo.sh

# 3. One-time AWS setup (state bucket + GitHub OIDC role)
cd infra/bootstrap
terraform init
terraform apply \
  -var="project_name=fsl-devops-challenge" \
  -var="github_repository=<your-org-or-user>/<your-repo>"

# Note the two outputs: state_bucket_name and github_actions_role_arn.

# 4. Point each environment's backend at the state bucket
#    (edit infra/environments/devel/backend.hcl and
#     infra/environments/stage/backend.hcl, replacing <ACCOUNT_ID>)

# 5. Add GitHub environment secrets
#    Settings > Environments > devel/stage > AWS_DEPLOY_ROLE_ARN
#    = the github_actions_role_arn output from step 3

# 6. Lock down devel and stage
./scripts/setup-branch-protection.sh <owner>/<repo>

# 7. Open a PR: feature/my-change -> devel, watch CI run, merge, watch CD deploy
```

## Local verification of the CI steps

Every step the CI pipeline runs can be reproduced exactly, locally:

```bash
cd app
npm install
npm run lint
CI=true npm run test
npm run build
```

All four passed cleanly during development of this repo (6/6 Jest tests,
0 ESLint warnings/errors, successful Vite production build).

## Design notes

- **OAC over OAI**: the deprecated Origin Access Identity is not used
  anywhere; Origin Access Control is the current AWS-recommended
  mechanism for letting CloudFront read a private S3 bucket.
- **S3-native state locking**: `use_lockfile = true` in each backend
  config, no DynamoDB table required (Terraform >= 1.10).
- **No static AWS credentials in CI**: GitHub Actions authenticates via
  OIDC (`aws-actions/configure-aws-credentials` + an IAM role scoped to
  this repository's `devel`/`stage` branches only).
- **SPA-friendly routing**: CloudFront's `custom_error_response` rewrites
  403/404 to `/index.html` so client-side routes resolve correctly
  even though the S3 origin has no static-website hosting config.

  # Check deployment...
