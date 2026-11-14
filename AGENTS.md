# Project working rules

- Read `docs/mvp_development_guide.md`, `ARCHITECTURE.md`, and `PROGRESS.md` before changing gameplay.
- Follow milestone gates. M0 is setup; do not start M1 until Ishak approves M0.
- Do not edit system, shell, desktop, or other application configuration without Ishak's explicit approval. Project configuration is authorized for this project.
- Never add AI authorship, co-authorship, or attribution trailers to commits or GitHub submissions. Preserve Ishak's configured Git identity.
- Use branches for changes. Do not merge or tag a milestone until Ishak approves it.
- Keep simulation timing in integer ticks at 60 Hz. Rendering and effects must not change combat outcomes.
- Keep downloaded raw asset packs outside this repository. Record used assets and licenses in `CREDITS.md`.
- Before handoff run `python tools/verify.py`. Report failures and incomplete dependencies honestly.
- Avoid silently changing the guide. Record proposed deviations in `PROGRESS.md` for approval.
