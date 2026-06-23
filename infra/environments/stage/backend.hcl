# Partial backend configuration for the stage environment.
#
# Usage:
#   terraform init -backend-config=backend.hcl
#
# Replace <ACCOUNT_ID> with your AWS account ID (or hardcode the bucket
# name output by `infra/bootstrap`). This file is intentionally checked
# into version control - it contains no secrets, only the location of
# the (already access-controlled) state bucket.

bucket       = "fsl-devops-challenge-tfstate-399021807094"
key          = "environments/stage/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
