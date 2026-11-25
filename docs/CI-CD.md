# CI/CD

GitHub Actions replaces the former Azure pipeline. The model follows the maintainer's PowerShell module repositories: comment-triggered PR validation, a draft release with editable notes, and an approval gate before publication.

## Flow

```text
PR opened ──► maintainer comments /validate ──► PR Validation ──► commit status "PR Validation"
                                                         │
                                       ruleset: required + Dependency Review ──► squash merge

Run "Release" (version x.y.z) on master
   └─► validate + build signed .iq ──► push tag x.y.z ──► DRAFT release (generated notes, .iq, .sha256)
          edit release notes on the Releases page
Run "Publish Release" (tag x.y.z)
   └─► waits for approval on environment "release" ──► verify package ──► publish (latest)
          manual: upload the .iq to the Connect IQ store
```

| Workflow | Trigger | Purpose |
|---|---|---|
| `pr-validation.yml` | `/validate` comment on a PR (owner/member/collaborator), or dispatch with `pr_number` | Action-pin check, full `.iq` export for all manifest products, per-tier `.prg` builds with sizes, unit tests. Reports the commit status `PR Validation`. |
| `dependency-review.yml` | every `pull_request` | Vulnerability/licence gate on the action dependencies. |
| `release.yml` | manual dispatch on master, input `version` | Version check, signed build, tag, draft release. |
| `publish-release.yml` | manual dispatch on master, input `tag` | Environment `release` approval, package verification, publish. |

## Toolchain: private image instead of a Garmin login in CI

Garmin requires a login to download device files. On this account the login uses 2FA. The community SDK-manager CLI cannot do MFA: its SSO flow sets `mfaRequired=false`. CI therefore never logs in to Garmin.

- **Building the image.** The maintainer downloads the SDK and devices locally with the SDK Manager, entering the 2FA code interactively, and runs `tools/toolchain/Publish-CiqToolchainImage.ps1`. The script:
  1. Checks that device files exist for every product in `manifest.xml`.
  2. Resolves the **Linux** SDK for `.ciq-sdk-version` from Garmin's public SDK index (no login needed) and records its SHA-256.
  3. Builds `tools/toolchain/Dockerfile`: Temurin 17, the SDK, the device files of the manifest products, simulator fonts and Xvfb. The image contains no credentials and no keys.
  4. Pushes the image to `ghcr.io/mvaneijken/ciq-toolchain` as a **private** package and writes the digest-pinned reference to `.ciq-toolchain-image`.
- **Using the image.** CI logs in to ghcr.io with `GITHUB_TOKEN` (`packages: read`). It runs every SDK command through `tools/ci/ciq-run.sh`, which:
  - accepts only `ghcr.io/mvaneijken/ciq-toolchain@sha256:…`;
  - checks the image's SDK label against `.ciq-sdk-version`;
  - runs as the runner's uid, so no files are owned by root.
- **When to rebuild.** Rebuild after an SDK update or when `manifest.xml` gains products. `tools/ci/build.sh` fails with the list of missing devices if the image is out of date.

Licence note: the image holds Garmin SDK and device files in a private package, for the maintainer's own builds. That this is allowed under the Connect IQ SDK licence agreement is an assumption, not a verified fact; check the agreement.

## Security design

- **Garmin credentials**
  - No Garmin credentials exist anywhere in GitHub.
- **Store signing key**
  - Only `release.yml` reads it, only on master.
  - It is decoded into a `700` directory as a `600` file and bind-mounted read-only into the container.
  - It is deleted right after the build.
  - PR builds use a throwaway key generated in the job.
- **Why `/validate` instead of a plain `pull_request` trigger**
  - Pull requests from Dependabot or forks get a read-only token without access to the private package.
  - Validation runs PR code, which a maintainer should have read first.
- **Permissions**
  - The workflow-level `permissions` block is empty.
  - Every job declares the minimum it needs.
  - Every job runs `step-security/harden-runner` in audit mode.
  - Every third-party action is pinned to a commit SHA; `tools/ci/check-action-pins.sh` enforces this and Dependabot moves the pins.
- **Release integrity**
  - Publishing does not rebuild anything.
  - It verifies the uploader, the GitHub-recorded asset digest and the `.sha256` file before un-drafting the release.

## One-time setup

| # | Where | What |
|---|---|---|
| 1 | Local machine | Install the SDK `.ciq-sdk-version` and all devices with the SDK Manager. Install Docker. Run `gh auth refresh -h github.com -s write:packages`. |
| 2 | Local machine | `./tools/toolchain/Publish-CiqToolchainImage.ps1`, then commit `.ciq-toolchain-image` via a PR. |
| 3 | GitHub → your profile → Packages → `ciq-toolchain` → Package settings | Keep it **private**. Under *Manage Actions access*, add this repository with role *Read*. |
| 4 | Repository secrets | `CIQ_DEVELOPER_KEY` = base64 of the store signing key. PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes('developer_key.der')) \| gh secret set CIQ_DEVELOPER_KEY`. It must be the **same key as the store app**, or the store rejects the update. |
| 5 | Settings → Environments | Create `release`. Add yourself as required reviewer. Turn *Prevent self-review* off while you are the only maintainer. Deployment branches: `master`. |
| 6 | Local machine (admin) | `./tools/Set-RepositoryRuleset.ps1` applies `.github/rulesets/protect-master.json`. Do this only after the first green `/validate`, because the ruleset requires that check. |

Plan limits:

- Required reviewers on environments, rulesets and the dependency review work on GitHub Free only in **public** repositories.
- Secrets, environments and rulesets belong to the repository. Configure them on the final, public repository.

## Verification status

Status as of 2026-11-24, from the `/validate` runs on pull requests (for example run 45419081211).

Verified:

| Item | Evidence |
|---|---|
| SDK zip layout (`bin/monkeyc` at the zip root) | The toolchain image was built and pushed, and `/validate` runs inside it. |
| Device lookup via `$HOME/.Garmin/ConnectIQ/Devices` inside the container | The "Build" step compiles every product of `manifest.xml`. |
| `GITHUB_TOKEN` pull of the private package | The step "Log in to ghcr.io (read the private toolchain image)" succeeds and the image runs. |
| Compiler warning detection (`grep WARNING`) | The build log contains the compiler's `WARNING:` lines (64 in that run); `tools/ci/build.sh` surfaces them as annotations. |
| "Release" workflow (`release.yml`) | Dry run with version 2.3.6 on 2026-11-24 (run 45455158137): version check, signing key, signed build, tag and draft release all succeeded; the draft held the `.iq` and `.sha256` plus generated notes. |
| Simulator and unit tests in the toolchain image | `tools/ci/run-unit-tests.sh` ran inside the pinned image on the maintainer's machine (Docker Desktop, `xvfb-run`, device `fenix847mm`): the simulator starts, 16 tests pass, and a deliberately failing test makes the script exit 1. The library set in the Dockerfile is sufficient. `monkeydo -t` exits with status 1 even when all tests pass (SDK 9.3.0, Linux), so the script judges the printed `PASSED (...)` line. |
| Download of draft-release assets with `gh api` | The two assets of the dry-run draft were downloaded with the octet-stream header and the SHA-256 matched. |

The dry run was discarded afterwards. The workflow pushes the tag before it creates the draft, so discarding a dry run means deleting the draft release and the remote tag (`git push origin :refs/tags/<version>`); otherwise the version stays tied to the dry-run commit.

Not verified yet:

| Item | Risk | How to confirm |
|---|---|---|
| Unit tests in the GitHub Actions run | Locally the image runs the tests (see above), but the CI run has not happened yet. | The first `/validate` run of a PR that contains `(:test)` functions (roadmap 1.3). |
| "Publish Release" (`publish-release.yml`) | The approval gate on the `release` environment and the package checks have never run. | The first real release. |
| That `CIQ_DEVELOPER_KEY` is the same key as the store app | The store rejects an update signed with another key. | The first upload to the Connect IQ store. |
