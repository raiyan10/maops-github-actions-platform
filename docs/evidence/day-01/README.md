# Day 1 Evidence Index

Pull request **#1** now has real GitHub Actions evidence, including an initial successful run,
a controlled failed gate and a successful recovery. No screenshot, tag or release exists yet.
Post-merge `main` validation remains pending.

## Established locally

| Evidence | Source |
| --- | --- |
| 8/8 tests passed | `make test` |
| Authoritative `make validate` passed with Python 3.13.15 | test + image + smoke |
| Image `maops-p5-app:local` built | `make image` |
| `/healthz` and `/info` smoke checks passed | `make smoke` |
| Deliberate `BUILD_ID` mismatch failed correctly | `make smoke` negative path |
| Smoke-test failure-path checks (early exit, unreachable health, port conflict, missing image, no leftover containers) | [remediation log](../../engineering-reviews/day-01-remediation-log.md#focused-validation) |
| Independent review, remediation and targeted re-review | [final adjudication](../../engineering-reviews/day-01-final-adjudication.md) |

These are local results; their raw console output is not stored in the repository.

## GitHub PR evidence

See [GitHub Actions PR gate evidence](github-actions-pr-gate.md).

The PR sequence is:

1. run `37952275253` — initial candidate — **SUCCESS**
2. run `37958478152` — controlled `/healthz` regression — **FAILURE**
3. run `37960799333` — regression reverted — **SUCCESS**

The failed run stopped at `Run tests` with 2 failed and 6 passed; image build and smoke testing were not executed.

## Pending from GitHub

- Post-merge `push` → `main` workflow execution.
- pip cache save/restore behavior.
- Actual PR cancellation behavior.
- Actual `main` per-SHA concurrency behavior.
- Fork PR / repository policy behavior.
- Branch protection / required-check configuration.

When these exist, record them here by reference (run URL, commit SHA, PR number).

## Raw logs

Large raw logs should not be committed without a concrete reason. GitHub retains run logs; link to
the run and quote only the lines that support a specific claim.
