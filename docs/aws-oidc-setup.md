# AWS Authentication for GitHub Actions (OIDC, no static keys)

This repo's CD and teardown workflows authenticate to AWS using GitHub's
OIDC identity provider exchanged for a short-lived AWS IAM role session -
not long-lived `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` secrets.

## Why

- Static AWS keys in GitHub Secrets are long-lived and don't expire on
  their own; if leaked (logged accidentally, exfiltrated from a
  compromised dependency, etc.) they remain valid until someone notices
  and rotates them.
- OIDC-issued credentials are scoped to a single workflow run and expire
  automatically (typically within an hour), and the trust policy can pin
  exactly which repository and branch are allowed to assume the role.

## What's provisioned

`infra/bootstrap/main.tf` creates, once per AWS account:

1. `aws_iam_openid_connect_provider.github_actions` - tells AWS to trust
   JWTs issued by `https://token.actions.githubusercontent.com`.
2. `aws_iam_role.github_actions_deploy` - the role the CD/teardown
   workflows assume. Its trust policy (`StringLike` on the `sub` claim)
   only allows:
   - `repo:<owner>/<repo>:ref:refs/heads/devel`
   - `repo:<owner>/<repo>:ref:refs/heads/stage`
   - `repo:<owner>/<repo>:environment:devel`
   - `repo:<owner>/<repo>:environment:stage`

   No other branch, PR, or repository can assume this role.
3. An inline policy scoped to exactly what the pipeline needs: managing
   this project's own S3 buckets (`<project_name>-*`) and CloudFront
   distributions, plus read/write on the Terraform state bucket. It is
   deliberately **not** `AdministratorAccess`.

## One-time setup

```bash
cd infra/bootstrap
terraform init
terraform apply \
  -var="project_name=fsl-devops-challenge" \
  -var="github_repository=<your-org-or-user>/<your-repo>"
```

Copy the `github_actions_role_arn` output.

## Wiring it into GitHub

1. Repo Settings -> Environments -> create `devel` and `stage`.
2. In each environment, add a secret `AWS_DEPLOY_ROLE_ARN` with the
   value from `github_actions_role_arn`.
3. Workflows that need AWS access declare `permissions: id-token: write`
   and use:

   ```yaml
   - uses: aws-actions/configure-aws-credentials@v4
     with:
       role-to-assume: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
       aws-region: us-east-1
   ```

   This is already wired up in `cd.yml` and `teardown.yml`.

## Verifying

After the first successful CD run, check AWS CloudTrail for
`AssumeRoleWithWebIdentity` events on `github_actions_deploy` - the
`userIdentity` will show the GitHub OIDC subject claim, confirming which
repository/branch performed the action, with no static credentials
involved at any point.
