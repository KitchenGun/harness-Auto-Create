#!/bin/bash
# setup.sh - Harness initial setup
# Installs hooks, checks tools, prepares rules directory

set -euo pipefail

echo "[SETUP] Harness project setup starting..."

# --- 1. Git check ---
if [ ! -d ".git" ]; then
  echo "Running git init..."
  git init
fi

# --- 2. Install pre-commit hook ---
mkdir -p .git/hooks
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
chmod +x scripts/*.sh
echo "[OK] pre-commit hook installed"

# --- 3. Prepare rules directory ---
mkdir -p rules
if [ ! -f "rules/README.md" ]; then
  cat > rules/README.md << 'EOF'
# Rules Directory

Add rules here whenever a failure occurs.

## File format

### .md - Human-readable rule description
Records why this rule was created, what failure triggered it.

### .sh - Automated check script
`./scripts/lint.sh` runs all .sh files in this directory.
First argument "true" enables auto-fix mode.

```bash
#!/bin/bash
# Rule script template
FIX=${1:-false}
# Check logic...
# exit 1 on failure
```
EOF
  echo "[OK] rules/ directory prepared"
fi

# --- 4. Tool check (optional) ---
echo ""
echo "[TOOLS] Recommended tool status:"
for tool in autoflake vulture ruff; do
  if command -v "$tool" &>/dev/null; then
    echo "  [OK] $tool"
  else
    echo "  [--] $tool (not found - pip install $tool)"
  fi
done

echo ""
echo "[DONE] Setup complete! Harness will auto-run on every commit."
echo "   On failure: add a line to AGENTS.md and a rule to rules/"
