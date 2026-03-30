---
name: validate-devfile
description: Validate devfile.yaml and che-editor.yaml before committing
trigger: before any commit touching devfile.yaml or .che/che-editor.yaml
---

# Skill: validate-devfile

Use this skill before committing or pushing any changes that touch `devfile.yaml` or `.che/che-editor.yaml`.

## What it checks

1. `devfile.yaml` exists in the repo root.
2. `devfile.yaml` has valid YAML syntax.
3. `schemaVersion` field is present.
4. Required fields exist: `metadata.name`, `components`.
5. The `zeroclaw` component does not have `ttyd` in its args while missing `--host` (a known mistake from this project's history — see commits `78416bc` and `dee910f`).
6. `.che/che-editor.yaml` exists and is valid YAML.

## Steps to follow

1. Run the validator from the repo root:

   ```bash
   bash .claude/skills/validate-devfile/validate.sh
   ```

2. If the script exits with **FAIL**, read the printed error messages carefully.

3. Open `devfile.yaml` (or `.che/che-editor.yaml` if indicated) and fix the reported issue.

4. Re-run the validator. Repeat steps 2–3 until the script prints **PASS**.

5. Only after the script prints PASS, proceed to commit and push.

## Notes

- Always run from the repository root (where `devfile.yaml` lives).
- The `--host` check exists because an earlier version of this project launched `ttyd` without binding to `0.0.0.0`, making the terminal unreachable. The fix was to add `--host 0.0.0.0` (or equivalent) to the args.
- `python3` is used for YAML parsing — it is available in all standard environments and requires no extra dependencies.
