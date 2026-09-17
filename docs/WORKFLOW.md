# 에이전트 진행 방식

## 1. 역할

| 역할 | 정체 | 하는 일 | 못 하는 일 |
|---|---|---|---|
| 오케스트레이터 | 메인 Claude Code 세션 (`/stage N`) | 단계 시작/종료, 에이전트 호출 순서, 보고서 전달, STATUS 갱신, 커밋, 사용자에게 확인 요청 | 제품 코드 직접 수정 |
| developer | 서브에이전트 | 제품 코드와 단위 테스트 작성, 빌드 통과, dev 보고서 | 테스트 전용 경로 수정, 설계 임의 변경 |
| tester | 서브에이전트 | 테스트 도구/시나리오 작성, 빌드·테스트·실기기 시나리오 실행, 증거 수집, test 보고서 | 제품 코드 수정, 개발자 코드 보고 기준 맞추기 |
| reviewer | 서브에이전트 (읽기 전용) | 설계 준수, 역할 경계, 코드 품질, 증거 검증, 최종 판정 | 모든 파일 수정 |

핵심 원칙
- 테스트는 **STAGES.md의 AC를 기준으로** 만든다. 개발자 구현을 보고 기준을 맞추지 않는다 (블랙박스 우선)
- 검수는 **보고서를 믿지 않고 증거 파일을 직접 확인**한다
- 서브에이전트는 서로 직접 호출하지 않는다 (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1`). 모든 전달은 오케스트레이터가 한다

## 2. 단계 진행 흐름

```
/stage N
 1. 준비     STATUS에서 N-1 완료 확인, stage-N 브랜치 생성, 환경 점검(기기 연결, 위치: 회사/집)
 2. 테스트 설계  tester: AC별 테스트 계획(test-plan.md) + 필요한 도구/시나리오 먼저 작성
 3. 개발     developer: 범위 구현 + 단위 테스트 + 빌드 → dev.md
 4. 테스트    tester: 빌드/단위/린트/계측/실기기 시나리오 실행 → test.md + evidence/
 5. 검수     reviewer: diff, dev.md, test.md, evidence 대조 → review.md (오케스트레이터가 저장)
 6. 판정
    - APPROVE + 사용자 항목 없음 → 8로
    - APPROVE + 사용자 항목 있음 → 7로
    - CHANGES_REQUESTED → 지적 사항을 developer(또는 tester)에게 전달 → 4부터 반복
    - 3라운드 초과 또는 설계 변경 요청 → 중단, 사용자에게 보고
 7. 사용자 확인  오케스트레이터가 [사용자] 항목 체크리스트 제시 → 사용자 답변을 user-check.md로 저장 → reviewer 재판정
 8. 마무리    STATUS 완료, DECISIONS 반영 확인, 커밋, main 병합은 사용자 승인 후
```

재개: `/stage N`을 다시 실행하면 STATUS와 reports/stage-N 파일을 보고 멈춘 지점부터 이어간다.

## 3. 환경별 가능 작업

| 작업 | 회사 노트북 | 집 PC |
|---|---|---|
| 코드 작성, 빌드, 단위 테스트, 린트 | O | O |
| 에뮬레이터 테스트 | 가상화 허용 시 | O |
| S25 실기기 테스트 (USB/무선 디버깅) | 사내 보안 정책 확인 전 금지 | O |
| 윈도우 전역 훅, SendInput, 화면 캡처 테스트 (8단계 이후) | 금지 (보안 솔루션 탐지 위험) | O |

- 오케스트레이터는 단계 시작 시 사용자에게 현재 위치(회사/집)를 묻고, 불가능한 AC는 `BLOCKED(환경)`으로 표시한 뒤 집에서 `/stage N`으로 이어서 진행한다
- 코드 동기화: GitHub 공개 저장소. 사내망에서 접근이 막히면 집에서만 push/pull

### 기기
- 기본 S25, 성능 하한 S24 FE, 고해상도 S26 울트라 (STAGES.md 기기 매트릭스)
- 기기 보유자는 STATUS.md "기기 보유자" 표에 적는다
- 여러 대를 동시에 연결해도 된다. 스크립트는 `-s 시리얼`로 기기를 지정한다
- 증거는 `evidence/rN/<모델>/` 에 기기별로 저장한다

## 4. 보고서 위치와 형식

```
docs/reports/stage-N/
  test-plan.md       tester (개발 전)
  dev.md             developer (라운드마다 갱신, 라운드 구분)
  test.md            tester (라운드마다 갱신)
  review.md          reviewer 결과를 오케스트레이터가 저장 (라운드별 누적)
  user-check.md      사용자 확인 결과
  evidence/rN/       tester 증거 (로그, csv, png, xml)
```

### 4.1 판정 값
- AC 판정: `PASS` / `FAIL` / `BLOCKED(환경|사용자)` / `N/A(사유)`
- 검수 판정: `APPROVE` / `CHANGES_REQUESTED` / `ESCALATE(사용자 결정 필요)`
- 지적 등급: `치명` (반드시 수정, 1개라도 있으면 반려) / `중요` (반드시 수정) / `권장` (다음 단계까지 수정 가능, 기록)

### 4.2 형식
각 에이전트 파일(.claude/agents/*.md)에 템플릿이 있다.

## 5. 테스트 도구 (tester가 0단계에서 작성)

```
testing/
  scripts/
    device-check.ps1        연결된 모든 기기의 시리얼, 모델, One UI/Android 버전, 현재 해상도 확인 → devices.json
    install.ps1             앱 + 타겟 앱 설치
    grant-permissions.ps1   오버레이/접근성/알림/배터리 예외 부여
    projection-consent.ps1  MediaProjection 동의 자동 처리 (appops 시도 → 실패 시 uiautomator로 버튼 탭)
    run-scenario.ps1        타겟 앱 시나리오 실행 + 매크로 명령 전송 + 로그 수집
    collect.ps1             logcat, 진단 파일, 스크린샷, ui dump를 evidence/rN/ 로 수집
    analyze.py 또는 .kts    로그 → 위치 오차, 시간 오차, 누락률, 지연 통계 csv/요약
  scenarios/                시나리오 정의 (JSON)
```

권한 부여에 쓰는 기본 명령 (정확한 동작은 0단계에서 검증 후 DECISIONS.md 기록)
```
adb shell appops set com.personal.tapmacro SYSTEM_ALERT_WINDOW allow
adb shell settings put secure enabled_accessibility_services com.personal.tapmacro/<서비스 클래스>
adb shell settings put secure accessibility_enabled 1
adb shell pm grant com.personal.tapmacro android.permission.POST_NOTIFICATIONS
adb shell dumpsys deviceidle whitelist +com.personal.tapmacro
```

주의
- 기존 접근성 서비스 설정을 덮어쓰지 않도록 기존 값을 읽어 합친다
- 실기기 테스트 전후로 매크로를 반드시 정지시키고, 스크립트 종료 시 정지 명령을 보낸다 (폭주 방지)

## 6. 사용자 확인 절차
- 오케스트레이터가 [사용자] 항목만 번호 목록으로 제시 (무엇을, 어떻게 확인, 기대 결과)
- 사용자는 "1 OK, 2 안됨: 설명" 형식으로 답하면 된다
- 스크린샷이나 화면 녹화가 있으면 `docs/reports/stage-N/evidence/user/`에 넣으라고 안내

## 7. 커밋 규칙
- 브랜치: `stage-N`
- 커밋: `[stage-N] 요약` (라운드별 1개 이상)
- 라운드가 끝날 때마다 사용자 승인 후 `stage-N` 브랜치를 push (다른 사람이 이어받을 수 있게)
- 단계 완료 시 `gh pr create`로 PR 생성. 병합은 관리자가 GitHub에서만

## 8. 여러 명이 함께할 때
- 한 번에 한 단계만 진행한다. 단계 담당자는 관리자가 STATUS.md(main)에 적는다
- `/stage N` 실행자가 담당자가 아니면 오케스트레이터가 확인을 받는다
- 실기기 테스트가 필요한데 진행자에게 S25가 없으면: 브랜치를 push하고 STATUS를 "보류(환경)"으로 둔 뒤, 실기기 담당자가 같은 `/stage N`으로 이어받는다
- 사용자 확인 항목은 누구나 할 수 있다. 결과는 진행자에게 전달해 user-check.md에 기록한다
- 아이디어, 버그, 질문은 `/request` → GitHub Issue. 관리자가 검토해서 STAGES/DESIGN에 반영하거나 닫는다
- 작업 시작 전 항상 `/sync`
- GitHub 설정(관리자): Classic 브랜치 보호로 main 보호(PR 필수, 승인 1명, Code Owners 승인 필수), 참여자는 Collaborator(Write) 권한
- 공개 저장소이므로 외부인도 Issue, PR을 열 수 있다. 외부인의 PR은 병합하지 않고 닫는다. 스팸이 생기면 관리자가 Settings → Moderation options → Interaction limits로 제한한다
- 커밋 이메일은 GitHub noreply 주소를 쓴다

