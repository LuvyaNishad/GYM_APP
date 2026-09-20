# Archived Documents

**Nothing in this folder is a live specification. Do not build from these files.**

LEON accumulated four competing design systems. In September 2026 they were consolidated onto
**Liquid Glass Tactical** (keeping cyan `#00E5FF`), and [`/DESIGN.md`](../../DESIGN.md) became the
single source of truth for every visual decision. These three documents are kept only so the
history of that decision — and the original screen briefs — isn't lost.

| File | What it was | Why it's archived |
|---|---|---|
| `context.md` | Design system draft — purple `#7B61FF` on `#0B0F14` | Palette superseded. `#7B61FF` survives as `AppColors.purple`, the Pull/analytics-secondary token. |
| `brandGuidelines.md` | Brand sheet — blue `#3B82F6`, "R.P.D. Navy" | Palette superseded entirely. Nothing from it is in the code. |
| `LEON_STITCH_MASTER_PROMPT.md` | Long-form generation prompts for all 27 screens | Folded into `DESIGN.md` § 12 (Per-Screen Briefs). This is the original long-form source; § 12 is the working reference. |

If you need per-screen layout or copy, read `DESIGN.md` § 12 first. Reach for
`LEON_STITCH_MASTER_PROMPT.md` only when you need the full unabridged prompt for a screen — and
treat any colour, radius, or blur value in it as superseded by `DESIGN.md`.
