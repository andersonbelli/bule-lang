# Architecture

The client uses layered MVVM and constructor injection.

- `ui`: Cupertino views render domain data and send commands to view models.
- `app`: bootstrap, dependency wiring, and application-level state.
- `domain`: framework-independent models and shared workflows such as review scheduling.
- `data`: repositories coordinate local and remote services. Raw Supabase shapes never reach widgets.

Guest learning is local-first. Bundled JSON is immutable global content. Selections, attempts, notes, vocabulary, and review schedules are separate user-owned records. Account upgrades upsert queued local records using stable client IDs and idempotency keys.

The offline learning repository persists encountered vocabulary, attempt counters, private notes, mastery streaks, and UTC review timestamps in versioned local JSON. Views never write storage directly. Authored answer grading trims and case-folds input, collapses whitespace, normalizes apostrophe variants, and ignores terminal sentence punctuation.

Mobile navigation exposes Learn, Situations, Community, and More; More contains Chats, Vocabulary, and Profile. Wide layouts use a six-item sidebar.

Errors are recoverable states. Secrets belong only in backend functions. AI remains behind a future authenticated backend adapter.
