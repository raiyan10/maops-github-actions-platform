# Roadmap — MAOps P5

P5 runs as a three-session (three-day) envelope. Status values below reflect the repository as of
Day 1 local completion. See [architecture](architecture.md) for design detail.

Status key: **Completed (local)** · **Pending** · **PLANNED**

## Day 1 — CI foundation

| Item | Status |
| --- | --- |
| Python 3.13 standard-library service (`/healthz`, `/info`) | Completed (local) |
| `APP_BUILD_ID` source/build identity | Completed (local) |
| Container image, non-root user `10001` | Completed (local) |
| Make interface: `test`, `image`, `smoke`, `validate` | Completed (local) |
| `make validate` (8/8 tests, image build, smoke) with Python 3.13.15 | Completed (local) |
| `.github/workflows/ci.yml` authored | Completed (local) |
| Claude Code agents and `workflow-validation` Skill | Completed (local) |
| Independent review, targeted remediation, targeted re-review | Completed (local) — see [final adjudication](engineering-reviews/day-01-final-adjudication.md) |
| Commit, push and pull request (user Git sequence) | Pending |
| First GitHub Actions run on PR and on `main` | Pending |
| Branch protection / required-check configuration | Pending |
| First real failed CI gate and corrected rerun | Pending |

## Day 2 — Reusable workflow and artifact identity (PLANNED)

- Reusable workflow (`workflow_call`) with a defined input/output interface.
- Immutable artifact identity (digest bound to source SHA).
- GHCR publication on trusted events with scoped permissions.
- Promotion of existing digests, with its own serialization design.
- Local delivery of a promoted artifact.

## Day 3 — Failure, recovery and release (PLANNED)

- Deliberate failure and recovery exercises.
- Pipeline event records.
- Platform review and release.

## Tekton comparison (PLANNED, bounded)

A bounded coverage task comparing the same pipeline concepts in Tekton. It is not a second
delivery platform and does not change P5's GitHub Actions design.

## Ownership boundaries

P5 owns the CI/CD capability: workflows, the Make-based validation contract, artifact identity and
promotion mechanics. It does not take over other MAOps projects' scope.

| Project | Boundary with P5 |
| --- | --- |
| P6, P8, P9, P10 | Own their own scope as defined in their repositories. P5 does not modify them and does not absorb their responsibilities; any integration is through an agreed interface. |
| P12 | AI inference workload. PLANNED caller of the P5 reusable workflow; P12 owns its model and serving logic. |
| P14 | Portal. PLANNED consumer of P5's workflow interface and outcome records; P14 owns the portal. |

Released sibling MAOps projects are not modified from this repository.
