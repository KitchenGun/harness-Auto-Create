#!/bin/bash
# gen-ignore.sh — .gitignore & AI 컨텍스트 ignore 파일 자동 생성 스크립트
# 생성 배경: 프로젝트 파일 타입을 스캔하여 토큰 낭비 방지
# 사용법:
#   bash scripts/gen-ignore.sh            # 일반 실행 (없을 때만 생성)
#   bash scripts/gen-ignore.sh --force    # 강제 재생성 (기존 파일 덮어쓰기)
#   bash scripts/gen-ignore.sh --dry-run  # 출력만, 파일 미생성

set -euo pipefail

FORCE=false
DRY_RUN=false
for arg in "$@"; do
  case "$arg" in
    --force)   FORCE=true ;;
    --dry-run) DRY_RUN=true ;;
  esac
done

# ── 프로젝트 타입 감지 ──────────────────────────────────────────────────────
detect_project_type() {
  local types=()

  [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ] \
    && types+=("python")

  [ -f "package.json" ] \
    && types+=("node")

  ls *.uproject 2>/dev/null | grep -q . \
    && types+=("ue5")

  [ -f "go.mod" ] \
    && types+=("go")

  [ -f "Cargo.toml" ] \
    && types+=("rust")

  [ -f "pom.xml" ] || [ -f "build.gradle" ] \
    && types+=("java")

  echo "${types[*]:-generic}"
}

# ── .gitignore 블록 생성 ────────────────────────────────────────────────────
make_gitignore() {
  local types=("$@")

  cat << 'BASE'
# ── 공통 ────────────────────────────────────────────────────────────────────
.DS_Store
Thumbs.db
*.swp
*.swo
*~
.env
.env.*
!.env.example
*.log
*.tmp
*.bak
*.orig

# ── 하네스 시스템 ────────────────────────────────────────────────────────────
# (하네스 파일 자체는 커밋 대상)
BASE

  for t in "${types[@]}"; do
    case "$t" in
      python)
        cat << 'PYTHON'
# ── Python ──────────────────────────────────────────────────────────────────
__pycache__/
*.py[cod]
*.pyo
*.pyd
.Python
.venv/
venv/
env/
ENV/
pip-log.txt
.eggs/
*.egg-info/
dist/
build/
.pytest_cache/
.mypy_cache/
.ruff_cache/
htmlcov/
.coverage
PYTHON
        ;;
      node)
        cat << 'NODE'
# ── Node.js ──────────────────────────────────────────────────────────────────
node_modules/
dist/
build/
.next/
.nuxt/
.cache/
*.tsbuildinfo
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
.pnpm-store/
NODE
        ;;
      ue5)
        cat << 'UE5'
# ── Unreal Engine 5 ──────────────────────────────────────────────────────────
Binaries/
Build/
DerivedDataCache/
Intermediate/
Saved/
*.VC.db
*.opensdf
*.opendb
*.sdf
*.suo
*.xcworkspacedata
*.xcuserstate
.vs/
UE5
        ;;
      go)
        cat << 'GO'
# ── Go ───────────────────────────────────────────────────────────────────────
bin/
vendor/
*.exe
*.out
GO
        ;;
      rust)
        cat << 'RUST'
# ── Rust ─────────────────────────────────────────────────────────────────────
target/
Cargo.lock
RUST
        ;;
      java)
        cat << 'JAVA'
# ── Java ─────────────────────────────────────────────────────────────────────
*.class
*.jar
*.war
target/
build/
.gradle/
JAVA
        ;;
    esac
  done
}

# ── AI 컨텍스트 ignore 블록 생성 ───────────────────────────────────────────
# AI 도구가 읽지 않아도 되는 파일 → 토큰 절약
make_aiignore() {
  local types=("$@")

  cat << 'BASE'
# ── AI context ignore ────────────────────────────────────────────────────────
# AI 클라이언트가 컨텍스트로 읽지 않을 파일 목록 (토큰 절약)
# 규칙: 빌드 산출물·바이너리·대용량 자동생성 파일은 제외

# ── Git 내부 ─────────────────────────────────────────────────────────────────
.git/

# ── 바이너리·미디어 ───────────────────────────────────────────────────────────
*.png
*.jpg
*.jpeg
*.gif
*.ico
*.svg
*.woff
*.woff2
*.ttf
*.eot
*.mp3
*.mp4
*.wav
*.ogg
*.zip
*.tar.gz
*.7z
*.rar
*.pdf
*.exe
*.dll
*.so
*.dylib
*.bin
*.dat

# ── 로그·임시파일 ─────────────────────────────────────────────────────────────
*.log
*.tmp
*.bak
*.orig
*.swp

BASE

  for t in "${types[@]}"; do
    case "$t" in
      python)
        cat << 'PYTHON'
# ── Python 빌드 산출물 ────────────────────────────────────────────────────────
__pycache__/
*.pyc
*.pyd
*.pyo
.venv/
venv/
env/
*.egg-info/
dist/
build/
.pytest_cache/
.mypy_cache/
.ruff_cache/
htmlcov/
.coverage
PYTHON
        ;;
      node)
        cat << 'NODE'
# ── Node.js 의존성·빌드 ───────────────────────────────────────────────────────
node_modules/
dist/
build/
.next/
.nuxt/
.cache/
*.tsbuildinfo
NODE
        ;;
      ue5)
        cat << 'UE5'
# ── UE5 빌드·캐시 ────────────────────────────────────────────────────────────
Binaries/
Build/
DerivedDataCache/
Intermediate/
Saved/
Content/
# (Content/는 대용량 에셋 포함 — 제거하려면 이 줄 제거)
UE5
        ;;
      go)
        cat << 'GO'
# ── Go 빌드 ──────────────────────────────────────────────────────────────────
bin/
vendor/
*.exe
*.out
GO
        ;;
      rust)
        cat << 'RUST'
# ── Rust 빌드 ────────────────────────────────────────────────────────────────
target/
RUST
        ;;
      java)
        cat << 'JAVA'
# ── Java 빌드 ────────────────────────────────────────────────────────────────
*.class
*.jar
*.war
target/
build/
.gradle/
JAVA
        ;;
    esac
  done

  # 공통 마무리
  cat << 'FOOTER'
# ── 환경변수·비밀키 ───────────────────────────────────────────────────────────
.env
.env.*
*.pem
*.key
*.cert
FOOTER
}

# ── 파일 쓰기 (기존 커스텀 섹션 보존) ──────────────────────────────────────
write_ignore_file() {
  local filepath="$1"
  local content="$2"
  local label="$3"

  if [ "$DRY_RUN" = "true" ]; then
    echo ""
    echo "────────────── [DRY-RUN] $filepath ──────────────"
    echo "$content"
    return
  fi

  if [ -f "$filepath" ] && [ "$FORCE" = "false" ]; then
    # 기존 파일이 있으면 자동생성 섹션만 교체, 커스텀 섹션은 보존
    local custom_marker="# ── 커스텀 (아래는 자동 생성에서 제외) ────"

    if grep -q "$custom_marker" "$filepath" 2>/dev/null; then
      # 커스텀 섹션 아래 내용 추출
      local custom_section
      custom_section=$(awk "/$custom_marker/,0" "$filepath")
      printf '%s\n\n%s\n' "$content" "$custom_section" > "$filepath"
      echo "  [OK] $filepath 업데이트 (커스텀 섹션 보존)"
    else
      # 커스텀 섹션 없음: 안전하게 뒤에 덧붙이지 않고 알림만
      echo "  [SKIP] $filepath 이미 존재 (--force 로 덮어쓰기 가능)"
      return
    fi
  else
    printf '%s\n' "$content" > "$filepath"
    # 커스텀 섹션 안내 추가
    cat >> "$filepath" << 'CUSTOM'

# ── 커스텀 (아래는 자동 생성에서 제외) ────────────────────────────────────────
# 이 줄 아래에 수동으로 추가한 패턴을 작성하세요.
# gen-ignore.sh --force 실행 시에도 이 섹션은 보존됩니다.
CUSTOM
    echo "  [OK] $filepath 생성 완료"
  fi
}

# ── 메인 ────────────────────────────────────────────────────────────────────
main() {
  echo "[gen-ignore] 프로젝트 타입 감지 중..."

  # 배열로 변환
  read -ra detected_types <<< "$(detect_project_type)"

  if [ "${detected_types[0]}" = "generic" ]; then
    echo "  감지된 타입: 범용 (generic)"
  else
    echo "  감지된 타입: ${detected_types[*]}"
  fi

  # 컨텐츠 생성
  gitignore_content=$(make_gitignore "${detected_types[@]}")
  aiignore_content=$(make_aiignore "${detected_types[@]}")

  # 파일 쓰기
  write_ignore_file ".gitignore"      "$gitignore_content" ".gitignore"
  write_ignore_file ".aiignore"       "$aiignore_content"  ".aiignore"
  write_ignore_file ".claudeignore"   "$aiignore_content"  ".claudeignore"
  write_ignore_file ".cursorignore"   "$aiignore_content"  ".cursorignore"
  write_ignore_file ".codexignore"    "$aiignore_content"  ".codexignore"
  write_ignore_file ".geminiignore"   "$aiignore_content"  ".geminiignore"

  if [ "$DRY_RUN" = "false" ]; then
    echo "[gen-ignore] 완료 ✓"
    echo "   토큰 절약 팁: .aiignore 또는 사용하는 클라이언트 ignore 파일에 불필요한 디렉토리를 추가하세요"
  fi
}

main
