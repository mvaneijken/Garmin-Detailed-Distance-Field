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

Shared pieces:

- `.github/actions/setup-connectiq`: SDK and device files via the community [connect-iq-sdk-manager CLI](https://github.com/lindell/connect-iq-sdk-manager-cli) (Apache-2.0, pinned to v0.8.4 with a SHA-256), cached per SDK version and manifest product list.
- `tools/ci/build.sh`: export and per-tier builds; `tools/ci/tier-devices.txt` lists the tier devices.
- `tools/ci/run-unit-tests.sh`: simulator unit tests; it skips while no `(:test)` functions exist.
- `tools/ci/check-action-pins.sh`: requires every action to be pinned to a full commit SHA with a `# vX.Y.Z` comment. Dependabot moves the pins.
- `.ciq-sdk-version`: the exact SDK version CI uses. Bump it together with `manifest.xml`.

## Security design

- **Garmin login (needed only on a cache miss)**
  - PR validation loads the setup action from **master**, never from the PR.
  - The login token (`~/.Garmin/ConnectIQ/token.json`) is deleted, and the cache is saved, before any PR code runs.
- **Store signing key**
  - Only `release.yml` reads it, only on master.
  - It is written with `umask 077` and removed right after the build.
  - PR builds use a throwaway key generated in the job.
- **Permissions**
  - The workflow-level `permissions` block is empty.
  - Every job declares the minimum it needs.
  - Every job runs `step-security/harden-runner` in audit mode.
- **Release integrity**
  - Publishing does not rebuild anything.
  - It verifies the uploader, the GitHub-recorded asset digest and the `.sha256` file before un-drafting the release.

## One-time setup

| # | Where | What |
|---|---|---|
| 1 | Local machine | `connect-iq-sdk-manager agreement view`, read the agreement, note the hash. |
| 2 | Settings → Secrets and variables → Actions → **Variables** | `CIQ_AGREEMENT_HASH` = that hash. |
| 3 | … → **Secrets** | `GARMIN_USERNAME`, `GARMIN_PASSWORD` (Garmin developer account). |
| 4 | … → **Secrets** | `CIQ_DEVELOPER_KEY` = base64 of the store signing key: `base64 -w0 developer_key.der` (PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes('developer_key.der'))`). Use the **same key as the store app**, or the store rejects the update. |
| 5 | Settings → Environments | Create `release`. Add yourself as required reviewer. Leave *Prevent self-review* off as long as you are the only maintainer. Deployment branches: `master`. |
| 6 | Local machine (admin) | `./tools/Set-RepositoryRuleset.ps1` applies `.github/rulesets/protect-master.json`. |
| 7 | Repository | Create the missing tags for released versions 2.3.2–2.3.5. This lets the version check and the generated release notes start from the right baseline; today the newest tag is 2.3.1. |

Plan limits:

- Required reviewers on environments, rulesets and the dependency review work on GitHub Free only in **public** repositories.
- In a private repository, the `release` environment cannot hold required reviewers unless you have GitHub Enterprise.

## Not verified yet

Nothing here has run against the real Garmin services yet: this repository had no workflow runs, and the authoring environment could not reach Garmin. The first runs need to confirm the following:

| Item | Risk | How to confirm |
|---|---|---|
| Headless Garmin login with username/password | Fails if the Garmin account uses MFA or Garmin changes its SSO. | First `/validate` on a cache miss. |
| Java 17 for SDK 9.3.0 | Wrong JDK version. | First build. |
| Simulator under Xvfb for unit tests | Missing system libraries on `ubuntu-latest`. | First PR that adds `(:test)` functions (roadmap phase 1). |
| Compiler warning detection (`grep WARNING`) | Format may differ per SDK. | Build log of the first run. |
| `gh api` download of draft-release assets | Redirect/permission behaviour. | First "Publish Release" run. |
