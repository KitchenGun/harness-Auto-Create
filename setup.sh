#!/bin/bash
# setup.sh — 하네스 초기 설정
# 훅 설치, 도구 확인, rules 디렉토리 준비

set -euo pipefail

echo "⚙️  하네스 프로젝트 설정 중..."

# ── 1. Git 확인 ──
if [ ! -d ".git" ]; then
  echo "git init 실행 중..."
  git init
fi

# ── 2. pre-commit 훅 설치 ──
mkdir -p .git/hooks
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
chmod +x scripts/*.sh
echo "✅ pre-commit 훅 설치 완료"

# ── 3. rules 디렉토리 준비 ──
mkdir -p rules
if [ ! -f "rules/README.md" ]; then
  cat > rules/README.md << 'EOF'
# Rules 디렉토리

실패할 때마다 여기에 규칙을 추가합니다.

## 규칙 파일 형식

### .md — 사람이 읽는 규칙 설명
왜 이 규칙이 생겼는지, 어떤 실패에서 왔는지 기록합니다.

### .sh — 린터가 실행하는 자동 검사
`./scripts/lint.sh`가 이 디렉토리의 모든 .sh를 실행합니다.
첫 번째 인자가 "true"이면 자동 교정 모드입니다.

```bash
#!/bin/bash
# 규칙 스크립트 템플릿
FIX=${1:-false}
# 검사 로직...
# 실패 시 exit 1
```
EOF
  echo "✅ rules/ 디렉토리 준비 완료"
fi

# ── 4. 도구 확인 (선택) ──
echo ""
echo "📦 권장 도구 상태:"
for tool in autoflake vulture ruff; do
  if command -v "$tool" &>/dev/null; then
    echo "  ✅ $tool"
  else
    echo "  ⬜ $tool (없음 — pip install $tool)"
  fi
done

echo ""
echo "🎉 설정 완료! 이제 커밋할 때마다 하네스가 자동 실행됩니다."
echo "   실패하면 AGENTS.md에 한 줄 추가하고, rules/에 규칙을 넣으세요."
