# Design: `ctdev update --refresh-keys`

## Problem

APT repository GPG signing keys expire periodically. When they do, `ctdev update` (which runs `apt update`) fails with `EXPKEYSIG` errors. There's no way to refresh these keys without manually re-running the download commands from each component's install script.

## Solution

Add a `--refresh-keys` flag to `ctdev update` that re-downloads GPG keys for installed components. A central registry in `lib/keys.sh` maps components to their key URLs and keyring paths.

## GPG Key Registry

| Component | Key URL | Keyring Path | Method |
|-----------|---------|-------------|--------|
| docker | `https://download.docker.com/linux/ubuntu/gpg` | `/etc/apt/keyrings/docker.asc` | raw |
| gh | `https://cli.github.com/packages/githubcli-archive-keyring.gpg` | `/usr/share/keyrings/githubcli-archive-keyring.gpg` | dearmor |
| 1password | `https://downloads.1password.com/linux/keys/1password.asc` | `/usr/share/keyrings/1password-archive-keyring.gpg` | dearmor |
| 1password | `https://downloads.1password.com/linux/keys/1password.asc` | `/usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg` | dearmor |
| terraform | `https://apt.releases.hashicorp.com/gpg` | `/usr/share/keyrings/hashicorp-archive-keyring.gpg` | dearmor |
| vscode | `https://packages.microsoft.com/keys/microsoft.asc` | `/etc/apt/trusted.gpg.d/packages.microsoft.gpg` | dearmor |
| dbeaver | `https://dbeaver.io/debs/dbeaver.gpg.key` | `/etc/apt/trusted.gpg.d/dbeaver.gpg` | dearmor |

Methods:
- `raw`: download directly to keyring path (docker stores ASCII-armored .asc as-is)
- `dearmor`: pipe through `gpg --dearmor` to produce binary keyring

## Usage

```bash
ctdev update --refresh-keys              # refresh all installed components' keys, then update
ctdev update --refresh-keys docker gh    # refresh only docker and gh keys, then update
```

## Files

- **New: `lib/keys.sh`** — key registry and refresh functions
- **Modify: `cmds/update.sh`** — parse `--refresh-keys`, call refresh before apt update
- **Modify: `lib/cli.sh`** — update help text for update command

## Flow

1. Parse `--refresh-keys` flag and optional component names from args
2. For each registry entry: skip if not installed, skip if filtered out
3. Download key URL to keyring path using the appropriate method
4. Log success/failure per component
5. Proceed with normal package update

## Constraints

- Only runs on apt-based systems (GPG keys are an apt/deb concept)
- Install scripts keep their inline key setup unchanged
- Respects `--dry-run` flag
