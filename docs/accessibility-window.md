# Accessibility Window ("only during the challenge recording period")

## The requirement

> The application should be accessible to anyone with Internet access,
> but only during the challenge recording period.

## Why this isn't baked into Terraform directly

Terraform is declarative and idempotent by design - a configuration is
meant to converge to the same state every time it's applied, regardless
of when. Encoding a wall-clock expiry directly into a resource (e.g. a
cron-like "destroy yourself at 5pm" condition) fights that model: state
would drift from configuration the moment time passes, and every
`plan`/`apply` after the window closes would show unexplained diffs.

Instead, this repo treats "stop being accessible" as a deployment
action, not an infrastructure property - the same way you wouldn't
encode "stop the EC2 instance at 5pm" inside the instance's own resource
block.

## How it's implemented: `teardown.yml`

A manually-triggered workflow (`.github/workflows/teardown.yml`,
`workflow_dispatch`) with two modes, run separately per environment:

### `mode: disable`

```bash
terraform apply -var="enabled=false"
```

Flips the CloudFront distribution's `enabled` attribute to `false`.
Within a few minutes, CloudFront returns `403` for all requests. The
distribution, both S3 buckets, and all Terraform state are left intact -
flipping `enabled` back to `true` (the default) and re-applying restores
access immediately, with no waiting for a fresh CloudFront rollout
("create distribution" can take 15-20 minutes; toggling `enabled` is
much faster).

This is the recommended mode for **after a recording session ends but
before the challenge is fully wrapped up** - you may want to demo the
same environment again later.

### `mode: destroy`

```bash
terraform destroy
```

Tears down the CloudFront distribution and both S3 buckets for that
environment entirely. Use this once the environment is no longer needed
at all, to stop any further AWS cost.

## Recommended sequence around an actual recording

1. Before recording: run the CD pipeline (merge a PR) to deploy/refresh
   `devel` and/or `stage`. Confirm the `site_url` output loads in a
   browser.
2. Record the challenge walkthrough, using the live CloudFront URL.
3. Immediately after recording: run `teardown.yml` with
   `mode: disable` for both environments.
4. Once you're confident no further review/re-recording is needed: run
   `teardown.yml` with `mode: destroy` to remove the resources and avoid
   ongoing cost.

## Why not a scheduled (cron) auto-teardown?

A `schedule:` trigger that auto-disables the environment at a fixed time
was considered but deliberately left out of the default setup: recording
sessions slip, get rescheduled, or run long, and an unattended teardown
firing mid-recording would be worse than a manual one being a few minutes
late. If a hard deadline is genuinely required, the same `disable`/
`destroy` jobs in `teardown.yml` can be wrapped in a second workflow with
a `schedule:` trigger and a date check, but that is left as an explicit,
opt-in extension rather than a default.
