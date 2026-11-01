Audit the codebase against docs/SYLLABUS_MAP.md and docs/DESIGN.md. Never run git commit or git push.

1. For every syllabus row, find where it's actually used (grep the code). Fill in the "Where" column with `File.swift -> symbol`; tick it.
2. For any concept not yet used, implement it where it fits naturally in the existing features (no throwaway demo screens).
3. Check DESIGN.md compliance: hard-coded colours/fonts, missing reduce-motion fallbacks, missing accessibility labels on custom controls. Fix them.
4. Output a short table: concept -> where -> newly added? (y/n), plus a suggested commit message.
