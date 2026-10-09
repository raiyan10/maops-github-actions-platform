#!/usr/bin/env bash
# Usage: smoke-test.sh IMAGE PORT EXPECTED_BUILD_ID
# Starts the image, checks /healthz and /info, and always removes the container it created.
# On failure, prints container state and logs, then exits with the original failure code.
set -euo pipefail

image="${1:?image required}"
port="${2:?port required}"
expected_build_id="${3:?expected build id required}"
docker="${DOCKER:-docker}"
name="maops-p5-smoke-$$"
cid=""
# docker writes the ID here as soon as the container is created, even if it then fails to start,
# so cleanup targets exactly the container this script created and nothing else.
workdir="$(mktemp -d)"
cidfile="$workdir/cid"

fail() { echo "FAIL: $*" >&2; exit 1; }

# Diagnostics and cleanup may fail on their own; the original exit code is always returned.
on_exit() {
  local rc=$?
  trap - EXIT
  [[ -z "$cid" && -s "$cidfile" ]] && cid="$(<"$cidfile")"
  if [[ -n "$cid" ]]; then
    if [[ $rc -ne 0 ]]; then
      echo "--- container state ($name) ---" >&2
      "$docker" inspect --format \
        'status={{.State.Status}} exit_code={{.State.ExitCode}} oom_killed={{.State.OOMKilled}} error={{printf "%q" .State.Error}} started={{.State.StartedAt}} finished={{.State.FinishedAt}}{{if .State.Health}} health={{.State.Health.Status}}{{end}}' \
        "$cid" >&2 || echo "(docker inspect failed)" >&2
      echo "--- container logs ($name) ---" >&2
      "$docker" logs --tail 200 "$cid" >&2 || echo "(docker logs failed)" >&2
      echo "--- end diagnostics ---" >&2
    fi
    "$docker" rm -f "$cid" >/dev/null 2>&1 || echo "WARN: failed to remove container $name" >&2
  fi
  rm -rf "$workdir"
  exit "$rc"
}
trap on_exit EXIT

"$docker" run -d --cidfile "$cidfile" --name "$name" -p "127.0.0.1:${port}:8080" "$image" >/dev/null
cid="$(<"$cidfile")"

base="http://127.0.0.1:${port}"
probe() { curl -fsS --connect-timeout 1 --max-time 2 "$base$1"; }

health=""
for _ in $(seq 1 30); do
  if [[ "$("$docker" inspect --format '{{.State.Running}}' "$cid")" != "true" ]]; then
    fail "container exited before /healthz succeeded"
  fi
  if health="$(probe /healthz 2>/dev/null)"; then
    break
  fi
  health=""
  sleep 0.5
done
[[ -n "$health" ]] || fail "/healthz did not succeed within the readiness window"
echo "GET /healthz -> $health"
case "$health" in
  *'"status": "ok"'*) ;;
  *) fail "/healthz did not report status ok" ;;
esac

info="$(probe /info)" || fail "GET /info failed"
echo "GET /info    -> $info"
case "$info" in
  *"\"build_id\": \"${expected_build_id}\""*) ;;
  *) fail "/info build_id does not match '${expected_build_id}'" ;;
esac
echo "smoke test passed"
