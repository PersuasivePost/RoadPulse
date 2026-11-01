---
description: Implement the next unticked feature task (F*) from docs/PROGRESS.md
model: sonnet
---

Do the next task. Never run git commit or git push. CLAUDE.md is already in context: don't re-read it.

1. Read docs/PROGRESS.md. Pick the first feature task (F*) that is still ☐ (skip Mac visit rows; tell me if one is due). If an earlier F* is ◐, check its CI with `gh run list --limit 1` and tick it if green.
2. Read only what the task needs: its section of docs/PRD.md (`grep -n "^## F" docs/PRD.md`, then read that range), the matching parts of docs/ARCHITECTURE.md, and docs/DESIGN.md for anything visual. Don't re-read files already in context.
3. Restate its acceptance criteria in two or three lines and give a short file-level plan.
4. Implement it fully, following DESIGN.md for every visual and motion decision, with XCTests for the logic. Read neighbouring files with `grep`/`sed -n` ranges, not whole-file reads. No Docker or other local verification unless I ask: CI is the compiler.
5. Update docs/PROGRESS.md (tick the task, add a log entry of at most three lines) and the matching rows in docs/SYLLABUS_MAP.md (edit rows in place; don't rewrite the file).
6. Stop and give me: a suggested conventional commit message, what to test on the Mac (1-2 sentences), and the next task. Keep the report short.

$ARGUMENTS
