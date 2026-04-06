# 하네스 (Harness) 프로젝트

코드 품질을 자동으로 강제하는 셀프-힐링 개발 시스템.

## 핵심 철학

```
처음부터 완벽할 필요 없다.
실패할 때마다 한 줄씩 규칙을 추가한다.
시스템이 스스로 진화한다.
```

## 구조

```
harness-project/
├── AGENTS.md              ← 컨텍스트 파일 (60줄 이하, 항상 적용)
├── hooks/
│   └── pre-commit         ← 커밋 전 자동 실행
├── scripts/
│   ├── setup.sh           ← 최초 설정
│   ├── lint.sh            ← 린터 (자동교정 포함)
│   └── garbage-collect.sh ← 가비지 컬렉션
└── rules/                 ← 실패에서 탄생한 규칙들
    ├── README.md
    ├── no-print-debug.sh  ← 예시: 자동 검사
    └── no-print-debug.md  ← 예시: 규칙 설명
```

## 작동 흐름

```
코드 변경 → git commit
  → pre-commit 훅 실행
    → lint.sh (규칙 검사 + 자동교정 최대 3회)
    → garbage-collect.sh (죽은코드, 문서불일치, 미사용규칙)
    → 실패 시: 에러만 출력 + AGENTS.md에 로그
    → 성공 시: 조용히 커밋
```

## 시작하기

```bash
cd your-project
cp -r harness-project/* .
bash scripts/setup.sh
```

## 새 규칙 추가하기 (실패했을 때)

1. `rules/규칙이름.sh` — 자동 검사 스크립트 작성
2. `rules/규칙이름.md` — 왜 생겼는지, 어떤 실패인지 기록
3. `AGENTS.md` 실패 로그에 한 줄 추가
