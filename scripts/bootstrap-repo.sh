#!/usr/bin/env bash
#
# One-time repository bootstrap: creates the `devel` and `stage` branches
# from the current default branch, pushes them, and prints the next
# steps (branch protection, AWS OIDC role, secrets).
#
# Usage (run once, right after `git init` / cloning a fresh empty repo
# with this project's files already committed to main):
#   ./scripts/bootstrap-repo.sh

set -euo pipefail

DEFAULT_BRANCH="$(git symbolic-ref --short HEAD)"
echo "Current branch: ${DEFAULT_BRANCH}"

for branch in devel stage; do
  if git show-ref --verify --quiet "refs/heads/${branch}"; then
    echo "Branch '${branch}' already exists locally, skipping creation."
  else
    echo "Creating branch '${branch}' from '${DEFAULT_BRANCH}'..."
    git branch "${branch}" "${DEFAULT_BRANCH}"
  fi
done

echo ""
echo "Pushing devel and stage to origin..."
git push -u origin devel
git push -u origin stage

cat <<'EOF'

Branches created. Next steps:

1. Set the repository default branch to 'devel' in GitHub repo settings,
   so new feature/bugfix branches are cut from devel by default.

2. Configure AWS OIDC trust + IAM role for GitHub Actions (no static
   AWS keys in CI). See docs/aws-oidc-setup.md.

3. Add repository secrets / environments:
     - Settings > Environments > "devel" and "stage", each with secret
       AWS_DEPLOY_ROLE_ARN set to the IAM role ARN from step 2.

4. Run the one-time Terraform bootstrap to create the remote state
   bucket:
     cd infra/bootstrap
     terraform init
     terraform apply -var="project_name=fsl-devops-challenge"

5. Update infra/environments/devel/backend.hcl and
   infra/environments/stage/backend.hcl with the real state bucket name
   output from step 4 (replace <ACCOUNT_ID>).

6. Run scripts/setup-branch-protection.sh <owner>/<repo> to lock down
   devel and stage.

7. Open a PR from a feature/* branch into devel to see the full CI
   pipeline run.
EOF
