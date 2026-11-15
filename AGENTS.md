# Project working rules

- Read `docs/mvp_development_guide.md`, `ARCHITECTURE.md`, and `PROGRESS.md` before changing gameplay.
- Maintain `PROGRESS.md` as the ongoing work log: append dated session history, completed work, verification, known limitations, and next steps at every handoff. Keep `ARCHITECTURE.md` aligned with implemented behavior.
- Follow milestone gates. Ishak accepted M1 with animation fine-tuning deferred and instructed continued work. Ishak approved the M2 inspection build and proceeding after the link-visibility fix. Ishak explicitly approved M3 on 2026-11-15 and authorized completing M4. M4 is active; do not start M5 until Ishak approves M4.
- Do not edit system, shell, desktop, or other application configuration without Ishak's explicit approval. Project configuration is authorized for this project.
- Never add AI authorship, co-authorship, or attribution trailers to commits or GitHub submissions. Preserve Ishak's configured Git identity.
- Use branches for changes. Do not merge or tag a milestone until Ishak approves it.
- Keep simulation timing in integer ticks at 60 Hz. Rendering and effects must not change combat outcomes.
- Keep downloaded raw asset packs outside this repository. Record used assets and licenses in `CREDITS.md`.
- Before handoff run `python tools/verify.py`. Report failures and incomplete dependencies honestly.
- Avoid silently changing the guide. Record proposed deviations in `PROGRESS.md` for approval.

- Communication preference (Ishak, 2026-11-15): work autonomously through the current milestone according to the guide. Do not send per-feature completion reports or routine progress updates. Notify Ishak when the milestone implementation is ready for inspection; report any actual blocker or required design decision when necessary. Keep detailed changes and checks in project docs. Explicit milestone approval is still required before starting the next milestone.
