# Day 1 — GitHub Actions PR Gate Evidence

Pull request: **#1 — feat: establish Day 1 CI foundation**

This record captures the first real GitHub-hosted CI validation of the Day 1 platform and a controlled failure/recovery exercise performed before merge.

## 1. Initial successful PR validation

- Source branch head: `c4e6e3dbfe201f3168b0d4dfdd120af875136b83`
- Workflow event: `pull_request`
- GitHub Actions run: `37952275253`
- Result: **SUCCESS**
- Workflow job: `Test, build and smoke-test`
- Runtime: approximately 21 seconds

The unmodified Day 1 candidate passed the complete CI path on a GitHub-hosted `ubuntu-24.04` runner.

## 2. Controlled failed gate

A deliberate workload regression changed the `/healthz` response from:

~~~json
{"status": "ok"}
~~~

to:

~~~json
{"status": "degraded"}
~~~

The regression was committed only on the feature branch for the failure drill.

- Regression branch head: `02639b70e340cc329b281a6d0bd4d44f21903c44`
- GitHub Actions run: `37958478152`
- Result: **FAILURE**
- Failed stage: `Run tests`
- Test result: **2 failed, 6 passed**

The following tests detected the regression:

- `tests/test_app.py::test_healthz_ok`
- `tests/test_app.py::test_http_healthz_and_info`

Because the test stage failed, the workflow did not proceed to:

- `Build container image`
- `Smoke-test container`

This demonstrates the intended fail-closed delivery gate: a workload regression prevents later build/delivery stages.

For the `pull_request` workflow, the `BUILD_ID` shown inside the run was the GitHub-generated PR merge SHA rather than the feature-branch head SHA. This is the intended Day 1 behavior.

## 3. Recovery

The controlled regression commit was reverted rather than removed from history.

- Recovery branch head: `35d68768ae1bd0b1da7ea451397839519e0f6038`
- GitHub Actions run: `37960799333`
- Result: **SUCCESS**
- Workflow job: `Test, build and smoke-test`
- Runtime: approximately 24 seconds

A diff of `src/maops_p5_app/server.py` between the original Day 1 implementation commit and the recovery head was empty, confirming that the workload was restored to the known-good implementation.

## Evidence sequence

| Stage | Branch head | Run | Result |
| --- | --- | --- | --- |
| Initial Day 1 candidate | `c4e6e3dbfe201f3168b0d4dfdd120af875136b83` | `37952275253` | SUCCESS |
| Controlled health regression | `02639b70e340cc329b281a6d0bd4d44f21903c44` | `37958478152` | FAILURE |
| Reverted / recovered | `35d68768ae1bd0b1da7ea451397839519e0f6038` | `37960799333` | SUCCESS |

## Still pending

The PR evidence proves the GitHub-hosted PR validation path and real fail/recovery behavior. It does not yet prove:

- `push` → `main` workflow execution after merge;
- per-SHA `main` concurrency behavior with multiple closely spaced pushes;
- branch-protection / required-check policy;
- release behavior.

Those remain pending until the corresponding stages are exercised.
