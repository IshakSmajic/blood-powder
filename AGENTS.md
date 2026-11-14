# Project working rules

- Read `docs/mvp_development_guide.md`, `ARCHITECTURE.md`, and `PROGRESS.md` before changing gameplay.
- Maintain `PROGRESS.md` as the ongoing work log: append dated session history, completed work, verification, known limitations, and next steps at every handoff. Keep `ARCHITECTURE.md` aligned with implemented behavior.
- Follow milestone gates. Ishak approved M0; M1 is active. Do not start M2 until Ishak approves M1.
- Do not edit system, shell, desktop, or other application configuration without Ishak's explicit approval. Project configuration is authorized for this project.
- Never add AI authorship, co-authorship, or attribution trailers to commits or GitHub submissions. Preserve Ishak's configured Git identity.
- Use branches for changes. Do not merge or tag a milestone until Ishak approves it.
- Keep simulation timing in integer ticks at 60 Hz. Rendering and effects must not change combat outcomes.
- Keep downloaded raw asset packs outside this repository. Record used assets and licenses in `CREDITS.md`.
- Before handoff run `python tools/verify.py`. Report failures and incomplete dependencies honestly.
- Avoid silently changing the guide. Record proposed deviations in `PROGRESS.md` for approval.
