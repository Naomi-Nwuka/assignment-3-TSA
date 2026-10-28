#!/usr/bin/env bash
set -u
PASS=0; FAIL=0
pass(){ echo "PASS: $1"; PASS=$((PASS+1)); }
fail(){ echo "FAIL: $1"; FAIL=$((FAIL+1)); }
echo "=== Assignment 3 - GitHub Actions / Docker / Bash ==="
for f in README.md app/app.sh scripts/lint.sh scripts/build.sh tests/test.sh Dockerfile compose.yaml .dockerignore .github/workflows/ci.yml; do
  [[ -f "$f" ]] && pass "Required file exists: $f" || fail "Missing required file: $f"
done
for f in app/*.sh scripts/*.sh tests/*.sh; do
  [[ -f "$f" ]] || continue
  bash -n "$f" >/dev/null 2>&1 && pass "Bash syntax: $f" || fail "Bash syntax error: $f"
done
for f in app/app.sh scripts/lint.sh scripts/build.sh tests/test.sh; do
  [[ -x "$f" ]] && pass "Executable: $f" || fail "Not executable: $f"
done
WORKFLOW=.github/workflows/ci.yml
if [[ -f "$WORKFLOW" ]]; then
  grep -Eq 'push:' "$WORKFLOW" && pass "Workflow triggers on push" || fail "Workflow missing push trigger"
  grep -Eq 'pull_request:' "$WORKFLOW" && pass "Workflow triggers on pull_request" || fail "Workflow missing pull_request trigger"
  grep -Eq 'validate:' "$WORKFLOW" && pass "Workflow has validate job" || fail "Workflow missing validate job"
  grep -Eq 'test:' "$WORKFLOW" && pass "Workflow has test job" || fail "Workflow missing test job"
  grep -Eq 'docker:' "$WORKFLOW" && pass "Workflow has docker job" || fail "Workflow missing docker job"
  grep -A12 -E '^[[:space:]]*test:' "$WORKFLOW" | grep -Eq 'needs:[[:space:]]*validate' && pass "Test job depends on validate" || fail "Test job should use needs: validate"
  grep -A12 -E '^[[:space:]]*docker:' "$WORKFLOW" | grep -Eq 'needs:[[:space:]]*test' && pass "Docker job depends on test" || fail "Docker job should use needs: test"
fi
if [[ -x ./app/app.sh ]]; then
  ./app/app.sh help >/dev/null 2>&1; rc=$?; [[ $rc -eq 0 ]] && pass "app.sh help succeeds" || fail "app.sh help failed"
  ./app/app.sh system-info >/dev/null 2>&1; rc=$?; [[ $rc -eq 0 ]] && pass "app.sh system-info succeeds" || fail "app.sh system-info failed"
  ./app/app.sh >/dev/null 2>&1; rc=$?; [[ $rc -eq 2 ]] && pass "app.sh rejects missing command" || fail "app.sh should return 2 for missing command"
  for port in abc 0 65536; do
    ./app/app.sh check-port localhost "$port" >/dev/null 2>&1; rc=$?
    [[ $rc -eq 2 ]] && pass "app.sh rejects invalid port '$port'" || fail "app.sh should reject port '$port' with code 2"
  done
fi
if [[ -x ./scripts/lint.sh ]]; then
  if ./scripts/lint.sh >/tmp/assignment3-lint.log 2>&1; then pass "scripts/lint.sh passes"; else fail "scripts/lint.sh fails"; cat /tmp/assignment3-lint.log; fi
fi
if command -v docker >/dev/null 2>&1; then
  IMAGE=student-devops-ci-grader
  if docker build -t "$IMAGE" . >/tmp/assignment3-build.log 2>&1; then
    pass "Docker image builds successfully"
    for cmd in help system-info; do
      if docker run --rm "$IMAGE" "$cmd" >/tmp/assignment3-docker.log 2>&1; then pass "Docker '$cmd' smoke test passes"; else fail "Docker '$cmd' smoke test failed"; cat /tmp/assignment3-docker.log; fi
    done
    docker run --rm "$IMAGE" invalid-command >/tmp/assignment3-docker.log 2>&1; rc=$?
    [[ $rc -ne 0 ]] && pass "Docker invalid command returns non-zero" || fail "Docker invalid command should fail"
    docker image rm "$IMAGE" >/dev/null 2>&1 || true
  else
    fail "Docker image failed to build"; cat /tmp/assignment3-build.log
  fi
else
  echo "ERROR: Docker is required for Assignment 3 Docker checks."; FAIL=$((FAIL+1))
fi
if [[ -x ./tests/test.sh ]]; then
  if ./tests/test.sh >/tmp/assignment3-tests.log 2>&1; then pass "Student test suite passes"; else fail "Student test suite fails"; cat /tmp/assignment3-tests.log; fi
else
  if bash ./tests/test.sh >/tmp/assignment3-tests.log 2>&1; then pass "Student test suite passes"; else fail "Student test suite fails"; cat /tmp/assignment3-tests.log; fi
fi
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commits=$(git rev-list --count HEAD 2>/dev/null || echo 0)
  [[ "$commits" -ge 5 ]] && pass "Git has at least 5 commits" || echo "WARN: fewer than 5 commits; inspect manually"
  branches=$(git for-each-ref --format='%(refname:short)' refs/heads | grep -vE '^(main|master)$' | wc -l | tr -d ' ')
  [[ "$branches" -ge 1 ]] && pass "Feature/non-main branch exists" || echo "WARN: no local feature branch found"
else
  echo "WARN: Git checks skipped"
fi
echo "======================================"; echo "Passed: $PASS"; echo "Failed: $FAIL"
[[ $FAIL -eq 0 ]]
