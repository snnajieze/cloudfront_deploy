#!/usr/bin/env bash
#
# Configures branch protection for `devel` and `stage` to satisfy the
# challenge's branching strategy:
#
#   - Direct pushes to devel/stage are prohibited (PRs required).
#   - PRs into devel/stage must pass CI (ci.yml) and the branch policy
#     check (branch-policy.yml), which is what actually enforces
#     "only devel may merge into stage".
#   - At least one approving review is required before merge.
#
# Requirements:
#   - GitHub CLI (`gh`) installed and authenticated: gh auth login
#   - Run from the root of the repository, after devel/stage exist and
#     after the CI and branch-policy workflows have run at least once
#     (so their check names are known to GitHub).
#
# Usage:
#   ./scripts/setup-branch-protection.sh <owner>/<repo>

set -euo pipefail

REPO="${1:?Usage: $0 <owner>/<repo>}"

protect_branch() {
  local branch="$1"

  echo "Configuring protection for '${branch}' on ${REPO}..."

  gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    "repos/${REPO}/branches/${branch}/protection" \
    -f "required_status_checks[strict]=true" \
    -f "required_status_checks[contexts][]=CI Summary" \
    -f "required_status_checks[contexts][]=Validate source/target branch combination" \
    -F "enforce_admins=true" \
    -f "required_pull_request_reviews[required_approving_review_count]=1" \
    -F "required_pull_request_reviews[dismiss_stale_reviews]=true" \
    -F "required_conversation_resolution=true" \
    -F "required_linear_history=false" \
    -F "allow_force_pushes=false" \
    -F "allow_deletions=false" \
    -F "block_creations=false" \
    -F "restrictions=null"

  echo "Done: ${branch}"
}

protect_branch "devel"
protect_branch "stage"

echo ""
echo "Branch protection applied. Note: 'enforce_admins=true' means even"
echo "repository admins must go through a PR - this matches the challenge"
echo "requirement that direct merges into devel/stage are prohibited."
echo ""
echo "The 'only devel may merge into stage' rule is enforced by the"
echo "'branch-policy.yml' workflow's required status check, not by a"
echo "native GitHub branch-protection field (GitHub does not expose a"
echo "'restrict by source branch' setting), so make sure that workflow"
echo "stays enabled."
