I pushed and CI ran. Never run git commit or git push.

1. Run `gh run list --limit 1` and `gh run view --log-failed` for the latest run.
2. If it passed, say so and stop.
3. If it failed, read the compiler/test errors, fix the root cause (never disable tests or CI steps), and tell me what you changed plus a commit message. I'll push and run /ci again.
4. If the same error survives 3 rounds, stop and show me the exact log lines with your diagnosis.
