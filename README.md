# Assignment 3: CI/CD with GitHub Actions

## Purpose
This project packages a Bash diagnostic CLI in Docker and uses GitHub Actions to validate Bash syntax, run tests, and build/smoke-test the Docker image. It does not deploy to the cloud.

## Requirements
- Docker
- Bash
- Git and a GitHub repository

## Commands
Run locally:
```bash
chmod +x app/*.sh scripts/*.sh tests/*.sh
./app/app.sh help
./app/app.sh system-info
./app/app.sh check-host localhost
./app/app.sh check-port localhost 443
```

Run linting and tests:
```bash
./scripts/lint.sh
./tests/test.sh
```

Build and smoke-test the Docker image:
```bash
./scripts/build.sh
docker run --rm devops-tool help
```

Run with Compose:
```bash
docker compose run --rm devops-tool help
docker compose run --rm devops-tool system-info
```

## Exit codes
- `0`: command succeeded.
- `1`: operational check failed.
- `2`: invalid command or input.

## GitHub Actions
The workflow in `.github/workflows/ci.yml` runs on both `push` and `pull_request`. Its jobs run in order: `validate`, then `test`, then `docker`. The `needs` setting enforces the dependencies.

## Demonstrating a CI failure
1. Create and switch to a feature branch.
2. Introduce a temporary Bash syntax error in `app/app.sh`.
3. Commit and push the branch.
4. Open a pull request or inspect the Actions run and confirm that `validate` fails.
5. Remove the syntax error, commit, and push again.
6. Confirm that the workflow passes.

## Notes
- Host resolution can succeed even when ping is blocked; in that case, `check-host` reports that ping failed or was blocked but exits successfully because DNS resolution worked.
- A TCP port check can fail if the remote service is not listening or network rules block the connection.
- Add the instructor-provided `grade.sh` to the repository before final submission, then run it as specified in the assignment brief.
