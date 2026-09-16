# 처음 한 번 하는 준비 (관리자용 기술 문서)

참여자용 쉬운 설명서는 docs/GUIDE.html (브라우저로 열기). 이 문서는 관리자가 저장소를 처음 만들 때 보는 문서다.

## 관리자만: GitHub 저장소 설정
- private 저장소 생성, 참여자를 Collaborator(Write)로 초대
- 저장소 소유자 계정이 GitHub Pro여야 비공개 저장소에 main 잠금이 적용된다
- 첫 업로드(main)는 관리자가 터미널에서 직접 한다 (Claude Code는 main push 차단)
- Settings → Rules → Rulesets → New branch ruleset
  - 이름 `main 보호`, Enforcement status `Active`
  - Bypass list: Repository admin 추가, 옵션 `For pull requests only` (관리자 본인 PR 병합용)
  - Target branches: `Include default branch`
  - 체크: Restrict deletions / Require a pull request before merging (Required approvals 1, Dismiss stale approvals, Require review from Code Owners) / Block force pushes
- `.github/CODEOWNERS`에 관리자가 지정되어 있어 관리자 승인만 유효하다
- Issues 라벨 생성: `아이디어`, `버그`, `질문`
- docs/STATUS.md의 관리자, 담당자 칸 작성 후 main에 커밋

## 모든 참여자

1. **Git for Windows** 설치 (Claude Code의 Bash 도구와 버전 관리에 필요, 기본 편집기는 VS Code 선택)
   - **VS Code** 설치 후 Claude Code 확장(Anthropic) 설치. 참여자 절차는 docs/GUIDE.html 6장과 동일
2. **Android Studio** 최신 안정판 설치 → SDK Manager에서 Android 16 (API 36) SDK, Platform-Tools 설치
   - `adb`가 PATH에 잡히는지 확인: 터미널에서 `adb version`
3. **GitHub CLI(gh)** 설치 후 `gh auth login`으로 로그인 (PR, Issue 등록용)
4. **Claude Code** 설치 (공식 문서의 Windows 설치 방법대로) 후 `claude` 실행해서 로그인
5. **PowerShell 스크립트 실행 허용** (훅 스크립트용)
   ```
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   ```
   회사 노트북에서 정책으로 막혀 있으면 훅이 동작하지 않는다. 이 경우에도 검수 에이전트가 git diff로 경계 위반을 잡으니 진행은 가능하다.
6. **git 이름 설정**: `git config --global user.name "GitHub이름"` (STATUS.md 담당자 칸과 같게)
7. **저장소 받기**: 관리자는 이 폴더의 파일을 저장소 루트에 넣고 커밋. 참여자는 `git clone <저장소 주소>`
   ```
   CLAUDE.md
   README-SETUP.md
   .claude/agents/developer.md
   .claude/agents/tester.md
   .claude/agents/reviewer.md
   .claude/skills/stage/SKILL.md
   .claude/skills/sync/SKILL.md
   .claude/skills/status/SKILL.md
   .claude/skills/request/SKILL.md
   .claude/hooks/guard-paths.ps1
   .claude/settings.json
   docs/DESIGN.md  docs/STAGES.md  docs/WORKFLOW.md  docs/DECISIONS.md  docs/STATUS.md  docs/GUIDE.html
   docs/reports/.gitkeep
   .gitattributes
   .github/CODEOWNERS
   .vscode/extensions.json  .vscode/settings.json
   ```
8. 저장소 폴더에서 `claude` 실행 → 폴더 신뢰 확인 창에서 **신뢰** 선택 (프로젝트 에이전트의 훅은 신뢰한 폴더에서만 동작)
   - "사용 가능한 서브에이전트 알려줘"라고 물어서 developer, tester, reviewer가 보이는지 확인
9. **S25 준비** (실기기 담당자만, 집에서)
   - 설정 → 휴대전화 정보 → 소프트웨어 정보 → 빌드번호 7번 탭
   - 설정 → 개발자 옵션 → USB 디버깅 켜기
   - USB 연결 후 폰에 뜨는 "USB 디버깅 허용" 승인 (이 컴퓨터 항상 허용)
   - 터미널에서 `adb devices`에 기기가 `device`로 보이면 완료
10. 시작: `/sync` → `/status` → 담당이면 `/stage N`

## 진행 중 사용하는 명령
- `/sync` : 최신 받기
- `/status` : 상황과 내 할 일
- `/stage N` : N단계 시작 또는 재개
- `/request 내용` : 아이디어, 버그, 질문 등록
- 진행 상태: docs/STATUS.md
- 단계 결과: docs/reports/stage-N/

## 주의
- 회사 노트북: 폰 USB 연결과 윈도우 입력 자동화(8단계 이후) 테스트는 하지 않는다. 오케스트레이터가 위치를 물으면 "회사"라고 답하면 해당 항목은 보류 처리되고, 집에서 같은 명령으로 이어서 진행된다.
- 서브에이전트 파일을 수정했는데 반영이 안 되면 Claude Code를 재시작한다.
