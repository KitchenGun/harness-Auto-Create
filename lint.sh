#!/bin/bash
# lint.sh — 규칙 기반 린터
# rules/ 디렉토리의 .rule 파일을 순서대로 실행
# 사용법: ./scripts/lint.sh [--fix] [--quiet]

set -uo pipefail

FIX=false
QUIET=false
ERRORS=0
FIXED=0

for arg in "$@"; do
  case $arg in
    --fix) FIX=true ;;
    --quiet) QUIET=true ;;
  esac
done

RULES_DIR="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")/rules"

if [ ! -d "$RULES_DIR" ]; then
  echo "rules/ 디렉토리가 없습니다. 빈 규칙셋으로 통과."
  exit 0
fi

# ── 내장 검사들 ──

# 1. 사용하지 않는 import 검사 (Python)
check_unused_imports() {
  local file="$1"
  if command -v autoflake &>/dev/null; then
    result=$(autoflake --check --remove-all-unused-imports "$file" 2>&1) || {
      if [ "$FIX" = true ]; then
        autoflake --in-place --remove-all-unused-imports "$file"
        FIXED=$((FIXED + 1))
        return 0
      fi
      echo "ERROR unused-import: $file"
      ERRORS=$((ERRORS + 1))
    }
  fi
}

# 2. 사용하지 않는 변수 검사 (Python)
check_unused_vars() {
  local file="$1"
  if command -v vulture &>/dev/null; then
    vulture "$file" --min-confidence 80 2>/dev/null | while read -r line; do
      echo "WARN dead-code: $line"
    done
  fi
}

# 3. 문서 ↔ 코드 동기화 검사
check_doc_sync() {
  local agents_md="AGENTS.md"
  if [ -f "$agents_md" ]; then
    # AGENTS.md 60줄 제한
    lines=$(wc -l < "$agents_md")
    if [ "$lines" -gt 60 ]; then
      echo "ERROR doc-overflow: AGENTS.md가 ${lines}줄 (제한: 60줄)"
      ERRORS=$((ERRORS + 1))
    fi
  fi
}

# ── 실행 ──

# 내장 검사
check_doc_sync

# 변경된 파일만 검사
changed_files=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || find . -name "*.py" -o -name "*.js" -o -name "*.ts" | head -50)

for file in $changed_files; do
  case "$file" in
    *.py)
      check_unused_imports "$file"
      check_unused_vars "$file"
      ;;
  esac
done

# rules/ 의 커스텀 규칙 실행
for rule_file in "$RULES_DIR"/*.sh 2>/dev/null; do
  [ -f "$rule_file" ] || continue
  if ! bash "$rule_file" "$FIX" 2>&1; then
    rule_name=$(basename "$rule_file" .sh)
    echo "ERROR rule-fail: $rule_name"
    ERRORS=$((ERRORS + 1))
  fi
done

# ── 결과 ──
if [ "$QUIET" = true ] && [ $ERRORS -eq 0 ]; then
  exit 0  # 성공은 조용히
fi

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "✗ 린트 실패: 에러 ${ERRORS}건"
  [ $FIXED -gt 0 ] && echo "  자동 교정: ${FIXED}건"
  exit 1
fi

exit 0
