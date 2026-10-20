# Product decisions

Confirmed 2026-10-15.

- Launch platforms: Android, iOS, and web. Organization identifier: `site.cambalhota.bulelang`.
- Content locales: `pt-BR`, `en-US`, `es-MX`, `fr-FR`, `id-ID`, and `et-EE`.
- Interface locale follows a supported device locale, falls back to `en-US`, and supports a user override.
- Users select one or more Know languages and exactly one Learn language. Learn cannot simultaneously be Know. Changing Learn preserves progress by language.
- Guest mode is default and local-only. Accounts support email/password, verification, recovery, Google, Apple, local-data merging, and deletion.
- Lessons use ten prompts when content permits. Mastery requires repeated successful reviews. Deterministic authored answers remain authoritative.
- Incorrect answers retry later in the lesson and become due after ten minutes. Correct review streaks schedule at 1, 3, 7, and 14 days; four successful scheduled reviews mark an item learned. A miss resets the streak. Self-assessed semantic matches remain ungraded for mastery.
- The first Situation practice flow uses authored text only. AI-generated and hybrid turns remain supported future modes, but AI is disabled until its service is implemented.
- Situation revisions are immutable proposals. Author approval creates a new candidate version; it never edits the published version in place. A separate publication approval promotes that candidate, preserving the previous published version for history and rollback.
- Situation voting and forum-style comments unlock only after completion. Completing a Situation adds its linked entries to vocabulary.
- Situation duration is recalculated from authored content: `ceil(dialogue words / 110 + learner turns × 25 seconds / 60)`, with a one-minute minimum. Editing turns therefore updates the estimate automatically.
- Community supports public read-only guest access, relevance/newest/score sorting, search, one vote per account, two reply levels, language snippets, editing, tombstone deletion, reports, and blocking.
- Chats require accounts, contain text and word/phrase snippets, and have no attachments. Private chats are member-only. End-to-end encryption is out of scope; transport encryption, storage protection, and authorization remain mandatory.
- Offline writes queue for synchronization. Idempotent operations and revision checks prevent duplicates and surface edit conflicts.
- First release provides a working path for each feature. Notifications, analytics, and AI are deferred.
