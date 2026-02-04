# Repo Improvements Plan (No Backward Compatibility)

## 1) Doc Update Proposal (README + docs)
- Make README authoritative and aligned to `lib/components.sh` and actual commands.
- Remove any mentions of historical plans from the README (keep plans in `docs/plans/` as archival only).

Proposed README changes:
1. Update component count to match `lib/components.sh`.
2. Replace the current component lists with an auto-generated list or clearly indicate “source of truth is `ctdev list`”.
3. Update CLI usage if any commands differ from README (e.g., `configure macos` versus `macos` if you later add it).
4. Add a short “Component registry” note: “Components are defined in `lib/components.sh`.”

Optional small doc note (if desired):
- Add a one-line clarification in `docs/plans/2026-02-02-ctdev-reorganization.md` that it’s historical. This is purely archival.

## 2) UX Spec for `ctdev list` and `ctdev upgrade`

### `ctdev list` (proposed behavior)
- Default: show **all** components in the registry, regardless of OS support.
- Status states:
  - `installed`
  - `not installed`
  - `not supported` (grey)
  - `installed (update available)` (yellow)
- If a component is unsupported, show `not supported` rather than hiding it.
- Update detection:
  - Keep existing checks for `zsh`, `node`, `ruby`.
  - Optional: add system update detection with a label like `system updates available` for pkg-manager installs (future enhancement).

### `ctdev upgrade` (proposed behavior)
- Only upgrades what is detected as upgradable.
- Remove Bun auto-upgrade unless an update can be detected or user opts in with a flag.
- Proposed flags:
  - `--yes` (already exists)
  - Optional: `--include-bun` or `--force-bun` if an escape hatch is desired (or remove Bun upgrade entirely).

## 3) Migration Plan: Per-Component `uninstall.sh`

Goal: enforce component modularity, no backward compatibility required.

Plan steps:
1. Create `components/<name>/uninstall.sh` for each component in `lib/components.sh`.
2. Move logic from `cmds/uninstall.sh` into each component’s uninstall script.
3. Rewrite `cmds/uninstall.sh` to:
   - Parse component args
   - Validate components
   - Dispatch to each component’s uninstall script
   - Track `installed`, `skipped`, `failed` with exit codes like install does
4. Define uninstall exit codes:
   - `0`: success
   - `2`: unsupported on this OS (skip)
   - other: failure
5. Remove legacy functions in `cmds/uninstall.sh` after migration.

OS behavior guidelines:
- macOS-only apps: exit `2` on Linux.
- Linux-only apps: exit `2` on macOS.
- CLI tools: attempt remove via pkg manager or known install path; if nothing present, return success (idempotent uninstall).

## 4) Acceptance Criteria Checklist
- `ctdev list` shows all components, including unsupported ones, with explicit `not supported` status.
- `ctdev list` status colors are consistent and documented.
- `ctdev upgrade` does not upgrade Bun unless explicitly requested or an update check exists.
- Each component directory has `install.sh` and `uninstall.sh`.
- `ctdev uninstall <component...>` delegates to component scripts and handles `skipped`/`failed`/`installed` results.
- README lists components consistent with `lib/components.sh` or states `ctdev list` is source of truth.
