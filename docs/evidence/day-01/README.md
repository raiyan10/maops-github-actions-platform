# Day 1 Evidence Index

**No GitHub Actions run, pull request, screenshot, tag or release exists yet.** This index lists
only what has been established locally and what remains to be proven on GitHub.

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

## Pending from GitHub

- Pinned actions execute successfully on GitHub-hosted `ubuntu-24.04`.
- `setup-python` `python-path` works with the fresh venv flow.
- pip cache save/restore behavior.
- Actual PR cancellation behavior.
- Actual `main` per-SHA concurrency behavior.
- Workflow pass and fail logs.
- Fork PR / repository policy behavior.
- Branch protection / required-check configuration.
- First real failed CI gate and corrected rerun.

When these exist, record them here by reference (run URL, commit SHA, PR number).

## Raw logs

Large raw logs should not be committed without a concrete reason. GitHub retains run logs; link to
the run and quote only the lines that support a specific claim.
