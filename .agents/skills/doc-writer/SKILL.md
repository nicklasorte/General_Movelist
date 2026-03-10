# SKILL — Doc writer

## When to use this skill

Use when the task involves:
- Updating `README.md`, `AGENTS.md`, or any file in `docs/`.
- Writing architecture notes, decision records, or change summaries.
- Keeping `docs/TODO.md` current after a significant change.

Do **not** modify `.m` source files — use the `matlab` skill for that.

---

## Instructions

1. **Accuracy first** — only document what the code actually does.
   Do not invent project-specific commands or behaviour you have not verified.
2. **Placeholders** — where repository details are unknown, mark clearly:
   `<!-- PLACEHOLDER: describe what should go here -->`.
3. **Conciseness** — prefer short, scannable sections over long prose.
   Use tables, bullet lists, and code blocks where appropriate.
4. **Preserve existing content** — do not overwrite meaningful content.
   Merge new information with existing text; use version-dated entries for
   decision logs and TODO items.
5. **AGENTS.md size limit** — keep `AGENTS.md` under 200 lines.
6. **Dated entries** — all entries in `docs/DECISIONS.md` and
   `docs/TODO.md` must be dated (ISO 8601: `YYYY-MM-DD`).
7. **Lessons Learned** — after any significant code change, add a dated entry
   to `CLAUDE.md` under **Lessons Learned** summarising what changed and why.
8. **Cross-references** — when a document references another, use a relative
   Markdown link (e.g. `[ARCHITECTURE.md](docs/ARCHITECTURE.md)`).

---

## Output format

When completing a documentation task, report:
1. Files created or updated (with one-line summary of change).
2. Placeholders that still need to be filled in by a human.
3. Recommended follow-up documentation tasks, if any.
