# Architecture — MAOps P5 GitHub Actions CI/CD Platform

P5 builds reusable CI/CD capability. The application in `src/` is a deliberately small workload;
the pipeline platform is the project. This document describes what exists after Day 1 and labels
everything else as **PLANNED**. It is not a production-readiness claim.

Related: [roadmap](roadmap.md) · [Day 1 final adjudication](engineering-reviews/day-01-final-adjudication.md) ·
[Day 1 evidence index](evidence/day-01/README.md)

## Developer journey (Day 1)

1. Work on a feature branch and run `make validate` locally (test → image → smoke).
2. Open a pull request to `main`. CI runs the same Make targets on a GitHub-hosted runner, with
   `BUILD_ID` set to the PR merge commit SHA.
3. After merge, the push to `main` runs CI again with `BUILD_ID` set to the pushed `main` SHA.
4. Nothing is published or deployed at any step.

The pull-request path in step 2 has now been exercised on GitHub, including a controlled
failed gate and successful recovery. The post-merge `push` → `main` path in step 3 remains pending.
See the [Day 1 evidence index](evidence/day-01/README.md).

## Day 1 current architecture

```
developer workstation                         GitHub-hosted runner (ubuntu-24.04)
---------------------                         -----------------------------------
make test   ─┐                                checkout (SHA-pinned, no persisted creds)
make image   ├─ make validate                 setup-python 3.13 (SHA-pinned, pip cache)
make smoke  ─┘                                make test → make image → make smoke
      │                                               │
      ▼                                               ▼
local Docker: maops-p5-app:local              runner Docker: maops-p5-app:local
(built, smoke-tested, kept locally)           (built, smoke-tested, discarded with runner)
```

| Component | Day 1 state |
| --- | --- |
| Workload | Python 3.13 standard-library HTTP service; `GET /healthz`, `GET /info` |
| Container | `python:3.13-slim`, non-root user `10001`, `APP_BUILD_ID` build arg |
| Make interface | `test`, `image`, `smoke`, `validate` — the stable contract CI calls |
| Smoke test | `scripts/smoke-test.sh`: runs the image, checks `/healthz` and `/info`, removes the container |
| CI | `.github/workflows/ci.yml`, single job, calls the Make targets |
| Claude Code capabilities | agents `github-actions-architect`, `github-actions-security-reviewer`, `ci-test-engineer`; Skill `workflow-validation` |

Kubernetes/Kind resources are not part of Day 1.

## Trust boundaries

### GitHub-hosted runner

- Triggers: `pull_request` → `main` and `push` → `main`. No `pull_request_target`.
- Runner: GitHub-hosted `ubuntu-24.04` only. Self-hosted runners are not used for untrusted PR work.
- Token: `permissions: contents: read`. No secrets are referenced.
- Checkout uses `persist-credentials: false`.
- GitHub-maintained actions (`actions/checkout`, `actions/setup-python`) are pinned to full commit SHAs.
- pip download cache via `setup-python`, keyed on `pyproject.toml`.
- 15-minute job timeout.
- Concurrency: PR runs group by PR ref and superseded PR runs are cancelled; each pushed `main`
  head SHA gets its own group and `main` runs are not cancelled.
- Publication boundary: the image is built and tested on the runner only. No registry, GHCR,
  deployment or release step exists.

### Local Docker

- Local runs use `/usr/bin/docker` (overridable with `DOCKER=`).
- The smoke test binds the container to `127.0.0.1:<SMOKE_PORT>` only.
- The smoke script removes only the container it created (tracked via `--cidfile`).
- The image stays on the local daemon; it is not pushed anywhere.

## Source/build identity

- `BUILD_ID` is passed to `docker build` as `APP_BUILD_ID` and baked into the image environment.
- `GET /info` reports `service`, `version` and `build_id`.
- In CI, `BUILD_ID=${{ github.sha }}`: the PR merge commit, or the pushed `main` commit.
- Locally, `BUILD_ID` defaults to `local-dev` and can be set explicitly.
- The smoke test fails if `/info` does not report the expected `build_id`.

Day 1 identity is a build-time label, not an immutable artifact identity. The image tag is the
mutable `maops-p5-app:local`; no digest is recorded. Immutable identity is PLANNED for Day 2.

## Failure behavior

- Any failing Make target fails the CI job; no step masks a failure.
- Smoke test (`scripts/smoke-test.sh`, `set -euo pipefail`):
  - `/healthz` must succeed within a bounded readiness window and report `"status": "ok"`.
  - Readiness stops early if the container exits.
  - curl attempts are bounded by connect and total timeouts.
  - A failed `/info` request or a `build_id` mismatch fails the run.
  - On failure, container state and logs are printed; the original exit code is preserved.
  - The container the script created is always removed, including when startup fails.

## Current limitations

- No published artifact, digest or provenance; the image tag is mutable.
- Base image and Dockerfile frontend are not digest-pinned; dev dependencies are not locked or hashed.
- JSON response checks use bounded shell pattern matching, not a JSON parser.
- Generic Make `IMAGE`/`TAG` variable names are not yet shaped for a `workflow_call` interface.
- The venv stamp does not account for interpreter identity.
- `actionlint` has not been run.
- The PR workflow has run successfully on GitHub; post-merge `main` execution, main concurrency and repository-policy behavior remain unproven.
- Branch protection and required checks are not configured as part of this repository.

The full deferred list is in the [final adjudication](engineering-reviews/day-01-final-adjudication.md#deferred-lowinformational-items).

## Planned evolution — PLANNED, not implemented

### Day 2 (PLANNED)

- Reusable workflow (`workflow_call`) exposing the build/test/smoke capability to callers.
- Immutable artifact identity: image referenced by digest, linked to the source SHA.
- GHCR publication with explicitly scoped permissions, on trusted events only.
- Promotion of an already-built digest rather than rebuilding; promotion concurrency needs its own
  serialization design.
- Local delivery of a promoted artifact (target and mechanism to be agreed before implementation).

### Day 3 (PLANNED)

- Failure and recovery scenarios exercised deliberately.
- Event records for pipeline outcomes.
- Review and release of the P5 platform.

### Caller contracts (PLANNED, high level)

- **P12 AI inference caller.** P12 would call the P5 reusable workflow rather than copy it,
  supplying its own Make-style test/build/smoke entry points and receiving an immutable artifact
  identity. Inputs/outputs will be defined in Day 2; P5 does not own P12's model or serving logic.
- **P14 portal reuse.** P14 would consume P5's reusable workflow interface and its pipeline
  outcome records, not reimplement pipeline logic. P5 does not own the portal.

### Tekton

Tekton remains only a later, bounded comparison lab. It is not a second delivery platform for P5.
