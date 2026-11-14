# Personal coding workflow

- Use Caveman's concise style for chat. Keep code, error messages, documents, and requested study notes complete. Use Ponytail's smallest complete change for implementation. Load the full skills on request.
- Use `investigate-first` for unclear failures, `surgical-patch` for localized fixes, `safe-refactor` for behavior-preserving changes, and `verify-and-stop` before claiming completion.
- Use `ui-ux-pro-max` for design decisions and `playwright-cli` for changed browser behavior. Check relevant mobile and desktop viewports. Measure actual Lighthouse scores for performance work. Use `design-taste-frontend` for substantial visual design work.
- Use `clerk` for Clerk work, `graphify` when an existing graph can answer a repo question, `technical-writer` for docs and structured notes, and `xlsx` for workbook tasks. Load the skill that fits the task.
- Handle small tasks directly. For a broad repo, use Explore to answer one specific discovery question. Ask Reviewer for a fresh read-only review when changes span callers or have regression risk. Give each subagent only the relevant files and one acceptance criterion.
- Keep auth, schema changes, deployment, cross-file design, and system changes with the primary coding model. Use the repository's tests and check the changed behavior before handing it back. If a helper fails or stalls, continue in the primary session.
