# TapMacro (가칭) — 프로젝트 공통 규칙

개인용 자동 클릭 매크로. 안드로이드(기본 갤럭시 S25, 호환 S24 FE·S26 울트라)와 윈도우 PC를 지원한다.
루팅 없음. 개인 APK / 개인 PC 전용. 싱글 플레이 게임과 일반 앱 대상.

이 파일은 모든 에이전트(개발/테스트/검수)가 읽는다. 세부 내용은 아래 문서를 따른다.

| 문서 | 내용 | 수정 권한 |
|---|---|---|
| docs/DESIGN.md | 확정 설계. 여기 없는 결정은 임의로 하지 않는다 | 사용자 승인 후 오케스트레이터만 |
| docs/STAGES.md | 단계별 범위와 수용 기준(AC) | 사용자 승인 후 오케스트레이터만 |
| docs/WORKFLOW.md | 에이전트 역할, 진행 절차, 보고서 형식 | 사용자 승인 후 오케스트레이터만 |
| docs/DECISIONS.md | 구현 중 생긴 세부 결정 기록 (실측값 포함) | 개발 에이전트 추가, 오케스트레이터 |
| docs/STATUS.md | 단계별 진행 상태, 담당자 | 담당자 지정은 관리자, 진행 상태는 오케스트레이터 |
| docs/reports/stage-N/ | 단계별 dev / test / review 보고서와 증거 | 각 담당 에이전트 |

## 모듈 구조

```
shared/              공통 코어 (Kotlin Multiplatform)
  src/commonMain     프로필, 규칙 엔진, 시퀀스, 타이밍 로직, 색 비교, 매칭 인터페이스
  src/commonTest     개발 에이전트의 단위 테스트
  src/androidMain    OpenCV Android 연결 등 안드로이드 전용 구현
  src/desktopMain    OpenCV Java, JNA 연결 등 윈도우 전용 구현
androidApp/          접근성 클릭, MediaProjection, 오버레이, 설정 화면
  src/androidTest    테스트 에이전트 전용 계측 테스트
desktopApp/          윈도우 클릭(SendInput), 키맵 훅, 투명 오버레이, 설정 화면
native/win-capture/  DXGI 캡처 DLL (C++)
testTargetApp/       테스트 에이전트 전용: 안드로이드 검증용 타겟 앱
desktopTestTarget/   테스트 에이전트 전용: 윈도우 검증용 타겟 창
testing/             테스트 에이전트 전용: 스크립트, 시나리오, 분석 도구
```

패키지: `com.personal.tapmacro` (타겟 앱은 `com.personal.tapmacro.target`)

## 명령어 (Windows 기준)

```
.\gradlew.bat assembleDebug                 안드로이드 디버그 빌드
.\gradlew.bat :shared:allTests              공통 단위 테스트
.\gradlew.bat :androidApp:lintDebug         린트
.\gradlew.bat :androidApp:connectedDebugAndroidTest   계측 테스트 (기기 연결 필요)
.\gradlew.bat :desktopApp:run               윈도우 앱 실행
.\gradlew.bat :desktopApp:packageMsi        설치 파일
adb devices                                  연결 기기 확인
```
Git Bash에서는 `./gradlew` 사용.

## 개발 환경
- 편집기: VS Code + Claude Code 확장. 터미널은 VS Code 통합 터미널(PowerShell)
- 저장소: GitHub private. 로컬 경로는 `C:\dev\` 아래 (OneDrive 동기화 폴더 금지)
- 줄바꿈 규칙은 .gitattributes를 따른다

## 절대 규칙

1. 역할 경계: 개발 에이전트는 테스트 전용 경로를 수정하지 않는다. 테스트 에이전트는 제품 코드를 수정하지 않는다. 검수 에이전트는 아무 파일도 수정하지 않는다. 경계 위반은 검수에서 즉시 반려된다.
2. 설계 준수: DESIGN.md와 다른 방식이 필요하면 구현하지 말고 보고서에 "설계 변경 요청"으로 올린다.
3. 좌표계: 오버레이, 캡처, 클릭은 모두 "실제 전체 화면(상태바/내비게이션바/컷아웃 포함) 픽셀" 기준. 저장은 비율(0~1) + 등록 해상도.
4. 네트워크 권한 금지: 안드로이드 매니페스트에 INTERNET 권한을 넣지 않는다. 앱은 외부로 아무것도 보내지 않는다.
5. 증거 없는 PASS 금지: 모든 PASS 판정은 로그, 수치, 스크린샷 등 파일로 남은 증거를 가리켜야 한다.
6. 모르는 API 동작은 추측하지 말고 공식 문서를 확인하고, 확인 못 했으면 보고서에 "미확인"으로 적는다.
7. 보고서, 커밋 메시지, 코드 주석은 한국어. 식별자는 영어.
8. 비밀값, 개인 정보, 회사 관련 정보를 코드나 로그에 넣지 않는다.

## 협업 규칙 (여러 명, 대부분 비개발자)

참여자 대부분은 개발 경험이 없다. 메인 세션에서 사람과 대화할 때 다음을 지킨다.

1. 쉬운 한국어로 말한다. 전문용어는 처음 나올 때 괄호로 풀어쓴다. 예: 커밋(작업 내용 저장 기록)
2. 권한 승인이 필요한 명령을 실행하기 전에 "무엇을 하려는지, 왜 필요한지"를 한 줄로 먼저 설명한다.
3. 제품 코드, 테스트 코드, 설계 문서는 `/stage` 절차로만 바꾼다. 대화 중 "이거 고쳐줘", "이 기능 추가해줘" 같은 요청을 받으면 직접 수정하지 말고 `/request`로 요청을 등록하도록 안내한다.
4. main 브랜치(공식 본선)에는 직접 커밋, 병합, push 하지 않는다. 병합은 관리자가 GitHub에서 PR(병합 요청)을 승인해서만 한다.
5. git 충돌(conflict)이 나면 자동으로 해결하지 않는다. 작업을 멈추고 "관리자에게 연락하세요"라고 안내한다.
6. 파일 삭제, 기록 되돌리기, 강제 덮어쓰기처럼 되돌리기 어려운 작업은 하지 않는다. 꼭 필요하면 관리자에게 넘긴다.
7. 사람이 무엇을 해야 할지 모르는 것 같으면 `/status`를 안내한다.
8. 관리자: docs/STATUS.md의 "관리자" 칸에 적힌 사람. 설계 변경 승인, 단계 담당자 지정, PR 병합 권한을 가진다.

## 완료 기준 (Definition of Done)

- 해당 단계 STAGES.md의 모든 AC가 PASS 또는 사용자 확인 완료
- 빌드, 단위 테스트, 린트 경고 0 (새로 추가된 코드 기준)
- 검수 에이전트 판정 APPROVE
- STATUS.md 갱신, stage-N 브랜치 커밋과 push, PR 생성 완료 (병합은 관리자)
