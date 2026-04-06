# game-hiring-harness

> 🎮 게임 업계 채용 전문 하네스 — 3인격 합의 시스템

15년차 게임회사 인사담당(P1) + 15년차 시니어 게임 프로그래머(P2) + 통합심사관(P3)의
세 페르소나가 합의를 통해 게임 프로그래머 채용을 검토하는 자동화 하네스입니다.

---

## 📁 폴더 구조

```
game-hiring-harness/
├── AGENTS.md                    ← 3인격 정의 + 합의 프로토콜 + 하네스 원칙
├── README.md                    ← 이 파일
├── hooks/
│   └── pre-commit               ← Git 커밋 전 자동 실행 훅
├── scripts/
│   ├── setup.sh                 ← 최초 설치 스크립트 (다른 프로젝트에 적용 시 실행)
│   ├── lint.sh                  ← 규칙 기반 린터 (자동교정 포함)
│   └── garbage-collect.sh       ← 죽은 코드/문서 불일치/미사용 규칙 탐지
└── rules/
    ├── README.md                ← 규칙 작성 가이드
    ├── hiring-criteria.md       ← P1/P2/P3 평가 기준 (100점 만점, 합의 공식)
    ├── interview-protocol.md    ← 면접 질문 생성 및 진행 규칙
    ├── resume-review.md         ← 이력서/포트폴리오 검토 체크리스트
    ├── no-print-debug.sh        ← 디버그 print 자동 탐지·제거
    └── no-print-debug.md        ← no-print-debug 규칙 문서
```

---

## 🚀 다른 프로젝트에 적용하기

### 방법 1 — 폴더째 복사 후 setup 실행

```bash
# 1. 이 폴더 전체를 대상 프로젝트로 복사
cp -r game-hiring-harness/ /path/to/your-project/

# 2. 대상 프로젝트 루트로 이동
cd /path/to/your-project/game-hiring-harness

# 3. 설치 스크립트 실행
bash scripts/setup.sh
```

### 방법 2 — 파일만 추출하여 적용

```bash
# 대상 프로젝트 루트에서 실행
TARGET=/path/to/your-project

mkdir -p $TARGET/{scripts,hooks,rules}
cp scripts/*.sh $TARGET/scripts/
cp hooks/pre-commit $TARGET/hooks/
cp rules/*.md $TARGET/rules/
cp rules/*.sh $TARGET/rules/
cp AGENTS.md $TARGET/AGENTS.md   # 이미 있으면 생략

cd $TARGET && bash scripts/setup.sh
```

---

## 🧠 3인격 합의 시스템

| 페르소나 | 역할 | 평가 비중 |
|----------|------|-----------|
| **P1** HR전문가 | 조직 적합성, 성장 가능성, 커뮤니케이션 | 40% |
| **P2** 개발전문가 | 코드 품질, 아키텍처, 문제 해결력 | 60% |
| **P3** 통합심사관 | P1+P2 합의 도출, 불일치 중재, 최종 판정 | — |

**종합 점수** = `P1총점 × 0.4 + P2총점 × 0.6`

| 점수 | 판정 |
|------|------|
| 80+ | 강력추천 |
| 65-79 | 추천 |
| 50-64 | 보류 (추가 검증) |
| ~49 | 불합격 |

---

## 📋 평가 흐름

```
이력서/포트폴리오/면접 답변 입력
  │
  ├─→ [P1 HR전문가] 독립 평가 (인성·조직적합성·처우)
  ├─→ [P2 개발전문가] 독립 평가 (기술·코드·아키텍처)
  └─→ [P3 통합심사관] 합의 도출 → 최종 판정 출력
```

---

## 🔧 권장 도구

```bash
pip install autoflake vulture ruff --break-system-packages
```

---

## ➕ 새 규칙 추가

실패가 발생할 때마다 규칙을 추가하여 하네스를 진화시킵니다.

1. `rules/{규칙이름}.sh` — 자동 검사 스크립트 작성
2. `rules/{규칙이름}.md` — 규칙 배경 및 설명 작성
3. `AGENTS.md` 하단 실패 로그에 한 줄 추가

```
<!-- YYYY-MM-DD | 실패 요약 | rules/{규칙이름}.md 추가 -->
```
