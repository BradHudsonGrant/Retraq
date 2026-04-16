# Retraq brand history — archive

**Status:** Internal reference · **Task:** 13.7 · **Last updated:** 2026-04-16

This app went through three names during the product-market-fit hunting
phase. The current and final name is **Retraq** (locked 2026-04-05,
re-confirmed 2026-04-16).

## Timeline

| Date | Name | Why | Artifact |
|---|---|---|---|
| Project start | **Lately** | First working name, picked for the "remember what you've been up to lately" evocation. | Outer directory still named `D:\Documents\Projects\Lately\` on filesystem — kept for personal file organization, no user-visible reference. |
| ~Feb 2026 | **SinceThen** | Shift to emphasize "since last time we talked" — slightly more active framing. Never shipped publicly. | Old `scripts/build-ios.sh` header (now replaced in Task 10.5). |
| 2026-04-05 | **Retraq** | Distinctive, protectable, self-explaining via "Lost traq? Retraq." tagline. Web sweep of app stores confirmed no conflicts in journaling category. | `app/docs/brand/retraq-branding-guide.md` (this folder). |

## Current status of old-brand usage

### Filesystem (non-user-facing)

- `D:\Documents\Projects\Lately\` — outer project folder, NOT in git
  repo, NOT user-visible. Kept as-is for personal organization.
  No action needed.
- `app/build/...` — generated Android build artifacts contain the
  outer path in file manifests. Gitignored, regenerated on every
  build, no remediation possible.

### Tracked source

Grep across tracked `.dart`, `.arb`, `.md`, `.yaml`, `.plist`, `.xml`,
`.gradle*`, `.swift`, `.kt` files (run 2026-04-16) returns zero
user-visible "Lately" or "SinceThen" references. Clean.

## Rebrand lock policy

The Retraq name is **locked**. Any future rename would require:
- Written rationale documented here.
- New trademark filings (CIPO + USPTO; see
  [`docs/external-blockers.md#b-15`](../external-blockers.md) and
  `#b-16`).
- Migration plan for: bundle IDs (`com.retraq.app`), secure-storage
  key names (`retraq_db_key`), App Store / Play Console listings,
  domain (`retraq.app`), any published creator outreach material.
- Explicit user-facing migration notice (a renamed app is a visible
  event to existing users; needs a release note at minimum).

**In-principle stance: no more renames pre-launch.** Three names in six
months externally signals product-market-fit hunting and erodes trust.
The current name has survived a 13-agent audit and is locked.

## Policy for archive material

- Old visual assets (logos, icons, screenshots of Lately/SinceThen UI):
  do not commit to the tracked repo. Keep locally in
  `D:\Documents\Projects\Lately\archive\` or similar — out of the git
  repo but available for historical reference.
- Old legal docs (earlier Privacy Policy / Terms drafts mentioning
  Lately/SinceThen): not committed; retained locally as personal
  records if needed.
- Trademark attorney correspondence: retain according to attorney
  guidance; not committed to the repo.

## Related

- [`retraq-branding-guide.md`](retraq-branding-guide.md) — authoritative
  brand voice, copy, palette, typography, usage rules.
- [`taglines.md`](taglines.md) — catalog of taglines for social,
  creator outreach, store listings.
- `../external-blockers.md#b-15` and `#b-16` — trademark filing tracking.
