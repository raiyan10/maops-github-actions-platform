---
name: workflow-validation
description: Validate a GitHub Actions workflow in this repository against the MAOps P5 platform requirements (triggers, trust boundaries, permissions, pinning, runner, timeout, concurrency, caching, Make interface, failure propagation, no hidden publication). Use when adding or changing files under .github/workflows/.
---

# Workflow validation (MAOps P5)

Static, read-only review of one or more workflow files. Report results; do not change files
unless the user asks. Do not install tools for this check; use any that are already available.

## Inputs
- The workflow file(s) under `.github/workflows/` to validate (default: all).
- The current stage scope from the user or `CLAUDE.md` (e.g. whether publishing is in scope yet).

## Procedure
Read each workflow, plus the `Makefile` and every script it invokes. For each check, record
**PASS**, **FAIL** or **N/A** with the `file:line` evidence.

1. **Triggers** — `on:` lists only the intended events and branch filters (e.g.
   `pull_request` → `main`, `push` → `main`). No unexpected `schedule`, `workflow_dispatch`,
   `workflow_run` or wildcard branches.
2. **No privileged PR events** — no `pull_request_target`; no `workflow_run` that checks out or
   executes PR-supplied code.
3. **Least-privilege permissions** — explicit `permissions:` at workflow or job level; only the
   scopes actually used (Day 1 baseline: `contents: read`). Every write scope is justified and
   unreachable from untrusted events.
4. **Action pinning** — every `uses:` is a full 40-hex commit SHA with a `# vX.Y.Z` comment; no
   unneeded actions. Check with:
   `grep -nE '^\s*-?\s*uses:' .github/workflows/*.yml` and confirm each matches `@[0-9a-f]{40}`.
5. **Runner** — an explicit, supported GitHub-hosted label (e.g. `ubuntu-24.04`), not
   `*-latest` and never `self-hosted` for PR workloads.
6. **Timeout** — every job sets a bounded `timeout-minutes`.
7. **Concurrency** — a `concurrency.group` keyed on workflow and ref; `cancel-in-progress`
   cancels superseded PR runs without skipping validation of trusted branch pushes.
8. **Caching** — only if it matches the real install path (e.g. pip cache keyed on
   `pyproject.toml` when the Makefile installs with pip). Caches hold downloads only, never
   secrets or trusted build outputs. A missing `cache-dependency-path` is a FAIL when no
   default lock/requirements file exists.
9. **Make interface** — steps call the stable targets (`make test`, `make image`, `make smoke`,
   `make validate`) instead of re-implementing their commands in YAML. Inputs reach Make via
   variables (`PYTHON`, `BUILD_ID`) set from trusted values.
10. **Untrusted input and secrets** — no `${{ github.event.* }}` free-text interpolated into
    `run:`; values reach shells via `env:`. No `secrets.*` on PR events. Checkout uses
    `persist-credentials: false` unless a step must push.
11. **No hidden publication/deployment** — search for `docker push`, `docker login`,
    `gh release`, registry/package uploads, `upload-artifact`, `deploy`, `kubectl`, `helm`, and
    any write-scoped token use. Anything found must be in the current stage's scope and never on
    untrusted events.
12. **Failure propagation** — no `continue-on-error: true`, `|| true`, `|| :`, `set +e`, or
    `if: always()` steps that can turn a failure into a success. Shell steps use bash
    (`-eo pipefail`). Scripts called use `set -euo pipefail`, and cleanup traps do not override
    the exit status.
13. **Readable errors** — one named step per stage (test, build, smoke), so the failing stage is
    obvious; scripts print expected vs. actual values and diagnostics (e.g. container logs) on
    failure.

## Syntax checks
- Parse each file as YAML (e.g. `python3 -c 'import sys,yaml; yaml.safe_load(open(sys.argv[1]))'`
  if PyYAML is available). Note that YAML parses `on:` as a boolean key in YAML 1.1 loaders; that is
  expected.
- Run `actionlint` only if it is already installed; otherwise state that it was not run.
- Check `${{ }}` expressions reference real contexts and step ids, and that step `id`s used in
  `steps.<id>.outputs` exist.
- Run `git diff --check`.

## Report
1. Table of checks 1–13 with PASS/FAIL/N/A and evidence.
2. Failures, most severe first, each with a recommended fix.
3. What could not be verified statically and needs a real GitHub Actions run (runner
   availability, cache hit/save behavior, fork PR token scope, end-to-end pass/fail).
