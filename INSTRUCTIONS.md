# 하네스(Harness) 자동 생성 시스템 — 사용 지침서

## 1. 개요

하네스는 **코드 품질을 자동으로 강제하는 셀프 진화 시스템**이다.
핵심 원리: 실패할 때마다 규칙을 한 줄씩 추가하여 시스템이 스스로 진화한다.

---

## 2. ⚠️ 하네스 생성 격리 규칙 (CRITICAL)

**하네스 생성 요청이 들어오면 반드시 아래 규칙을 따른다.**

### 2.1 핵심 원칙
> 루트의 기본 파일은 절대 건드리지 않는다.
> 요청한 하네스 이름으로 독립 폴더를 만들고, 모든 작업은 그 안에서만 한다.

### 2.2 금지 사항
| 금지 행위 | 이유 |
|-----------|------|
| 루트 `AGENTS.md` 수정 | 하네스 시스템 전체 컨텍스트 오염 |
| 루트 `rules/` 에 하네스 규칙 추가 | 프로젝트 자체 규칙과 혼용 금지 |
| 루트 `INSTRUCTIONS.md` 수정 | 이 지침서는 시스템 공통 문서 |
| 루트 스크립트(`lint.sh` 등) 수정 | 모든 하네스가 공유하는 기반 도구 |

### 2.3 올바른 하네스 생성 절차

```
요청: "{이름} 하네스 만들어줘"
  │
  └─→ 루트에 {이름}/ 폴더 생성
        │
        ├── {이름}/AGENTS.md           ← 하네스 전용 컨텍스트
        ├── {이름}/README.md           ← 설치 방법 및 개요
        ├── {이름}/hooks/
        │   └── pre-commit             ← 루트 hooks/pre-commit 복사
        ├── {이름}/scripts/
        │   ├── setup.sh               ← 루트 scripts/setup.sh 기반 커스터마이징
        │   ├── lint.sh                ← 루트 scripts/lint.sh 복사
        │   └── garbage-collect.sh     ← 루트 scripts/garbage-collect.sh 복사
        └── {이름}/rules/
            ├── *.md                   ← 하네스 전용 규칙 문서
            └── *.sh                   ← 하네스 전용 검사 스크립트
```

### 2.4 기존 하네스 폴더 목록
| 폴더명 | 용도 | 생성일 |
|--------|------|--------|
| `game-hiring-harness/` | 게임 프로그래머 채용 3인격 합의 시스템 | 2026-04-07 |
| `unreal-mcp-harness/` | Unreal Engine MCP 서버 + C++ 플러그인 개발 하네스 | 2026-04-08 |

> 새 하네스 생성 시 위 표에 항목을 추가한다.

---

## 3. 프로젝트 구조

```
harness-Auto-Create/          ← 루트 (절대 수정 금지 영역)
├── AGENTS.md                 ← 시스템 공통 컨텍스트 (60줄 이하)
├── INSTRUCTIONS.md           ← 이 지침서
├── hooks/
│   └── pre-commit            ← 공통 커밋 훅 (원본)
├── scripts/
│   ├── setup.sh              ← 공통 설정 스크립트 (원본)
│   ├── lint.sh               ← 공통 린터 (원본)
│   └── garbage-collect.sh    ← 공통 가비지 컬렉터 (원본)
├── rules/                    ← 이 시스템 자체의 규칙만 관리
│   ├── no-print-debug.sh
│   └── no-print-debug.md
│
└── {하네스이름}/             ← 하네스별 독립 폴더 (여기서만 작업)
    ├── AGENTS.md
    ├── README.md
    ├── hooks/
    ├── scripts/
    └── rules/
```

---

## 4. 초기 설정

### 4.1 대상 프로젝트에 하네스 적용

```bash
# 1. 원하는 하네스 폴더를 대상 프로젝트로 복사
cd your-project
cp -r harness-Auto-Create/{하네스이름}/* .

# 2. 설정 스크립트 실행
bash scripts/setup.sh
```

### 4.2 setup.sh가 수행하는 작업

| 단계 | 내용 |
|------|------|
| Git 확인 | `.git` 없으면 `git init` 실행 |
| 훅 설치 | `pre-commit` 훅을 `.git/hooks/`에 복사 + 실행 권한 부여 |
| rules 준비 | `rules/` 디렉토리 및 `README.md` 생성 |
| 도구 확인 | `autoflake`, `vulture`, `ruff` 설치 여부 표시 |

### 4.3 권장 도구 설치

```bash
pip install autoflake vulture ruff --break-system-packages
```

---

## 5. 작동 흐름

```
코드 변경 → git commit 실행
  │
  ├─ pre-commit 훅 자동 실행
  │   │
  │   ├─ [1단계] lint.sh --fix --quiet
  │   │   ├─ 성공 → 다음 단계로
  │   │   └─ 실패 → 자동 교정 재시도 (최대 3회)
  │   │       └─ 3회 모두 실패 → 에러 출력 + AGENTS.md에 실패 로그 기록 → 커밋 중단
  │   │
  │   ├─ [2단계] garbage-collect.sh
  │   │   ├─ 문서/코드 불일치 탐지
  │   │   ├─ 죽은 코드 탐지
  │   │   ├─ 미사용 import 탐지
  │   │   └─ 안 쓰는 규칙 파일 탐지
  │   │
  │   └─ [3단계] 교정된 파일 자동 스테이징
  │
  └─ 커밋 완료 (성공은 조용히)
```

---

## 6. 린터 (lint.sh) 상세

### 6.1 실행 옵션

```bash
./scripts/lint.sh           # 검사만 수행
./scripts/lint.sh --fix     # 자동 교정 모드
./scripts/lint.sh --quiet   # 성공 시 출력 없음
./scripts/lint.sh --fix --quiet  # pre-commit에서 사용하는 기본 조합
```

### 6.2 내장 검사 항목

| 검사 | 대상 | 도구 | 자동 교정 |
|------|------|------|-----------|
| 미사용 import | `*.py` | autoflake | O |
| 죽은 코드 (함수/변수) | `*.py` | vulture (신뢰도 80%+) | X (경고만) |
| AGENTS.md 60줄 제한 | `AGENTS.md` | wc | X |

### 6.3 커스텀 규칙 실행

`rules/` 디렉토리의 모든 `.sh` 파일을 순서대로 실행한다.
각 규칙 스크립트는 첫 번째 인자로 `true/false` (자동교정 모드)를 받는다.

---

## 7. 가비지 컬렉션 (garbage-collect.sh) 상세

| 검사 | 설명 |
|------|------|
| 문서 참조 유효성 | `rules/*.md`에서 참조하는 소스 파일이 실제 존재하는지 확인 |
| 죽은 코드 | vulture (신뢰도 90%+)로 미사용 함수/클래스 탐지 |
| 미사용 import | autoflake로 불필요한 import 탐지 |
| 미사용 규칙 | `rules/*.sh` 중 AGENTS.md나 규칙 문서에서 언급되지 않는 파일 탐지 |

---

## 8. 새 규칙 추가 지침 (핵심)

**규칙은 반드시 실제 실패 경험에서만 생성한다.**

### 8.1 규칙 추가 절차

1. **실패 발생** — 버그, CI 실패, 프로덕션 장애 등
2. **규칙 스크립트 작성** — `{하네스폴더}/rules/{규칙이름}.sh`
3. **규칙 문서 작성** — `{하네스폴더}/rules/{규칙이름}.md`
4. **실패 로그 기록** — `{하네스폴더}/AGENTS.md` 하단에 한 줄 추가

### 8.2 규칙 스크립트 템플릿

```bash
#!/bin/bash
# {규칙이름}.sh — {한 줄 설명}
# 생성 배경: {날짜} | {무슨 실패가 있었는지}
# 자동 교정: 가능/불가능

FIX=${1:-false}
FOUND=0

while IFS= read -r file; do
  matches=$(grep -n '{탐지할 패턴}' "$file" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    if [ "$FIX" = "true" ]; then
      echo "FIXED {규칙이름}: $file"
    else
      echo "ERROR {규칙이름}: $file"
      echo "$matches" | sed 's/^/  /'
      FOUND=$((FOUND + 1))
    fi
  fi
done < <(find . -name "*.py" -not -path "./.venv/*" -not -path "./node_modules/*")

[ $FOUND -gt 0 ] && exit 1
exit 0
```

---

## 9. AGENTS.md 관리 규칙

| 규칙 | 설명 |
|------|------|
| 60줄 이하 유지 | 린터가 자동 검사. 초과 시 커밋 차단 |
| 세부사항 분리 | 상세 내용은 `rules/`에 기록 |
| 실패 로그 누적 | 하단에 한 줄씩 추가 (HTML 주석 형식) |
| 코드-문서 동기화 | 코드 변경 시 반드시 문서도 갱신 |

---

## 10. 출력 원칙

- **성공은 조용히** — 통과한 4000줄의 결과는 출력하지 않는다
- **실패만 시끄럽게** — 에러/경고가 있는 줄만 표시한다
- 출력 접두어 규칙:
  - `ERROR` — 커밋 차단 수준
  - `WARN` — 경고 (커밋은 가능)
  - `FIXED` — 자동 교정 완료
  - `STALE` — 문서 참조 불일치
  - `DEAD` — 죽은 코드
  - `UNUSED` — 미사용 항목

---

## 11. 인코딩 안전 규칙 (CRITICAL)

**하네스 생성 시 모든 파일에서 아래 문자를 사용하지 않는다.**

### 11.1 금지 문자
| 종류 | 예시 | 대체 |
|------|------|------|
| 이모지 | `⚙️ ✅ ❌ ⚠️ 🔍 📂 📦 🎉 🗑️` | `[SETUP] [OK] [FAIL] [WARN] [CHECK] [DIR] [TOOLS] [DONE] [GC]` |
| 특수 화살표 | `──▶ ← → ↔ ──` | `--> <- -> <-> ---` |
| 특수 기호 | `✗ ✓ ℹ️ ⬜` | `FAIL OK [INFO] [--]` |
| Box Drawing | `── │ ├── └──` | `--- \| +-- +--` |

### 11.2 허용 문자
- ASCII 영문자, 숫자, 기본 구두점 (`-`, `_`, `.`, `:`, `|`, `+`, `#`, `*`)
- 한국어 (한글) 텍스트 (문서 본문에 한정, 셸 스크립트 echo 메시지에는 영어 사용)
- 마크다운 표준 문법 (`#`, `**`, `` ` ``, `|`)

### 11.3 셸 스크립트 출력 규칙
```bash
# 금지
echo "⚙️  하네스 설정 중..."
echo "✅ 완료"
echo "❌ 실패"

# 올바른 방식
echo "[SETUP] Harness setup starting..."
echo "[OK] Complete"
echo "[FAIL] Failed"
```

### 11.4 섹션 구분자
```bash
# 금지 (Box Drawing 문자)
# ── 1. Git 확인 ──

# 올바른 방식 (ASCII only)
# --- 1. Git check ---
```

### 11.5 이유
- Windows 환경에서 bash가 UTF-8 특수문자를 파싱하지 못해 syntax error 발생
- 외부에서 복사한 문서에 숨겨진 유니코드(Zero-width space 등) 혼입 가능
- CI/CD 환경마다 locale 설정이 달라 깨질 수 있음

---

## 12. 핵심 요약

```
1. 처음부터 완벽할 필요 없다
2. 실패할 때마다 규칙 한 줄 추가
3. 시스템이 스스로 진화한다
4. 성공은 조용히, 실패만 시끄럽게
5. 하네스 생성 = 독립 폴더 생성. 루트는 건드리지 않는다
6. 이모지/특수 유니코드 금지. ASCII + 한글만 허용
```
