---
name: status
description: 프로젝트 진행 상황과 내가 할 일을 쉬운 말로 알려준다.
disable-model-invocation: true
---

사용자는 비개발자일 수 있다. 전문용어 없이 설명한다. 파일은 수정하지 않는다.

1. `git fetch --prune` 후 docs/STATUS.md를 origin/main 기준으로 읽는다 (`git show origin/main:docs/STATUS.md`). 현재 브랜치의 STATUS.md가 더 최신이면 그것도 함께 본다.
2. `git config user.name`으로 사용자 이름을 확인한다.
3. 진행 중이거나 보류된 단계가 있으면 docs/reports/stage-N/의 최신 test.md, review.md, user-check.md를 훑는다.
4. `gh issue list --limit 10`이 가능하면 열린 요청을 확인한다.
5. 아래 형식으로 답한다.

```
📍 지금 상황: (몇 단계가 어떤 상태인지 1~2줄)
🙋 내 차례: (이 사용자가 담당인 단계, 실기기 담당인 보류 단계, 대기 중인 사용자 확인 항목. 없으면 "지금은 없어요")
👉 다음 행동: (구체적인 명령 1개. 예: `/stage 2` 실행, 관리자에게 PR 승인 요청, 할 일 없음)
📝 열린 요청: (개수와 제목 3개까지)
```
