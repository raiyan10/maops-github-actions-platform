# Day 1 Remediation Log

> Repository record of targeted remediation for the Medium findings in the
> [final adjudication](day-01-final-adjudication.md). The validation below is focused remediation
> validation on a local workstation. It is not release validation and not GitHub CI evidence.

## Finding A — `/healthz` enforcement

**Finding:** a failing `curl` inside a command substitution used in `echo` could be ignored by
`set -e`, so `/healthz` was not genuinely fail-closed.

**Remediation (`scripts/smoke-test.sh`):**
- `/healthz` success is captured explicitly.
- Readiness failure is an explicit failure.
- The response must include `"status": "ok"`.
- A failed `/info` request is an explicit failure.

## Finding B — `main` concurrency

**Finding:** `main` runs shared a ref-based concurrency group, so GitHub could replace an older
pending `main` run even with `cancel-in-progress: false`.

**Remediation (`.github/workflows/ci.yml`):**
- PR concurrency remains grouped by PR ref; superseded PR runs remain cancellable.
- `main` pushes use `github.sha` in the concurrency group.
- `main` runs are not cancelled.

## Finding C — smoke-test diagnostics and cleanup

**Finding:** insufficient failure diagnostics; container failure and timeout paths needed clearer
diagnostics and cleanup.

**Remediation (`scripts/smoke-test.sh`):**
- `EXIT` trap preserves the original exit code.
- On failure, prints container inspect/state and logs.
- Readiness polling stops when the container exits.
- curl attempts are bounded.
- `--cidfile` ensures the container created by the script is removed even when startup fails.
- Cleanup is scoped to that container only.

## Focused validation

| Check | Expected | Result |
| --- | --- | --- |
| Bash syntax check | Pass | Passed |
| Positive smoke test | Pass | Passed |
| `BUILD_ID` mismatch | Fail | Failed as expected |
| Early container exit | Fail | Failed as expected |
| Unreachable health endpoint | Fail | Failed as expected |
| Host-port conflict | Fail | Failed as expected |
| Missing image | Fail | Failed as expected |
| Leftover smoke containers | None | Zero |

Finding B is a workflow concurrency change; its runtime behavior cannot be exercised locally and
remains pending a real GitHub Actions run (see [evidence index](../evidence/day-01/README.md)).

## Targeted re-review

| Finding | Result |
| --- | --- |
| A | CLOSED |
| B | CLOSED |
| C | CLOSED |

No new Critical, High or Medium findings. Verdict: **READY FOR USER GIT SEQUENCE**.
