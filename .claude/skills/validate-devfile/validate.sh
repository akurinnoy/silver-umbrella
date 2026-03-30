#!/usr/bin/env bash
# validate-devfile/validate.sh
# Validates devfile.yaml and .che/che-editor.yaml before committing.
# Exit 0 = PASS, Exit 1 = FAIL.

set -euo pipefail

PASS=true
ERRORS=()

fail() {
  PASS=false
  ERRORS+=("  - $1")
}

# ── 1. Check devfile.yaml exists ─────────────────────────────────────────────
if [[ ! -f devfile.yaml ]]; then
  fail "devfile.yaml not found in current directory (run from repo root)"
  echo "FAIL"
  printf '%s\n' "${ERRORS[@]}"
  exit 1
fi

# ── 2. Validate YAML syntax ───────────────────────────────────────────────────
if ! python3 -c "import yaml, sys; yaml.safe_load(open('devfile.yaml'))" 2>/dev/null; then
  fail "devfile.yaml has invalid YAML syntax"
  echo "FAIL"
  printf '%s\n' "${ERRORS[@]}"
  exit 1
fi

# ── 3. Check schemaVersion ────────────────────────────────────────────────────
SCHEMA_VERSION=$(python3 -c "
import yaml, sys
d = yaml.safe_load(open('devfile.yaml'))
print(d.get('schemaVersion', ''))
" 2>/dev/null)

if [[ -z "$SCHEMA_VERSION" ]]; then
  fail "devfile.yaml missing required field: schemaVersion"
fi

# ── 4. Check metadata.name and components ─────────────────────────────────────
python3 -c "
import yaml, sys
d = yaml.safe_load(open('devfile.yaml'))
errors = []
meta = d.get('metadata', {})
if not meta.get('name'):
    errors.append('metadata.name')
if not d.get('components'):
    errors.append('components')
if errors:
    print('MISSING:' + ','.join(errors))
    sys.exit(0)
print('OK')
" 2>/dev/null | while IFS= read -r line; do
  if [[ "$line" == MISSING:* ]]; then
    fields="${line#MISSING:}"
    IFS=',' read -ra missing <<< "$fields"
    for f in "${missing[@]}"; do
      fail "devfile.yaml missing required field: $f"
    done
  fi
done

# Re-check (the subshell above can't write to PASS/ERRORS in the parent)
MISSING_FIELDS=$(python3 -c "
import yaml, sys
d = yaml.safe_load(open('devfile.yaml'))
errors = []
meta = d.get('metadata', {})
if not meta.get('name'):
    errors.append('metadata.name')
if not d.get('components'):
    errors.append('components')
print(','.join(errors))
" 2>/dev/null)

if [[ -n "$MISSING_FIELDS" ]]; then
  IFS=',' read -ra _fields <<< "$MISSING_FIELDS"
  for f in "${_fields[@]}"; do
    fail "devfile.yaml missing required field: $f"
  done
fi

# ── 5. Check zeroclaw component: ttyd in args but --host missing ──────────────
TTYD_CHECK=$(python3 -c "
import yaml, sys
d = yaml.safe_load(open('devfile.yaml'))
components = d.get('components', [])
for comp in components:
    name = comp.get('name', '')
    if name != 'zeroclaw':
        continue
    container = comp.get('container', {})
    args = container.get('args', [])
    args_str = ' '.join(str(a) for a in args)
    has_ttyd = 'ttyd' in args_str
    has_host = '--host' in args_str
    if has_ttyd and not has_host:
        print('MISSING_HOST')
        sys.exit(0)
print('OK')
" 2>/dev/null)

if [[ "$TTYD_CHECK" == "MISSING_HOST" ]]; then
  fail "component 'zeroclaw': ttyd is present in args but --host flag is missing (common mistake — add '--host', '0.0.0.0' or similar)"
fi

# ── 6. Check .che/che-editor.yaml exists and is valid YAML ───────────────────
if [[ ! -f .che/che-editor.yaml ]]; then
  fail ".che/che-editor.yaml not found"
else
  if ! python3 -c "import yaml, sys; yaml.safe_load(open('.che/che-editor.yaml'))" 2>/dev/null; then
    fail ".che/che-editor.yaml has invalid YAML syntax"
  fi
fi

# ── Result ────────────────────────────────────────────────────────────────────
if [[ "$PASS" == true ]]; then
  echo "PASS: devfile.yaml and .che/che-editor.yaml are valid."
  exit 0
else
  echo "FAIL: validation errors found:"
  printf '%s\n' "${ERRORS[@]}"
  exit 1
fi
