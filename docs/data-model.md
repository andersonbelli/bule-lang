# Data model proposal

- Identity: `profiles`, `user_known_languages`, `user_learning_languages`.
- Learning: `lexical_entries`, `lexical_meanings`, `translations`, `lessons`, `lesson_items`, `attempts`, `notes`, `user_vocabulary`, `review_schedules`.
- Situations: `situations`, immutable `situation_versions`, `situation_turns`, `situation_completions`, votes, nested comments, and `situation_revision_proposals`. Published versions remain unchanged until a separately approved candidate is promoted.
- Community: `posts`, `post_blocks`, `comments`, `votes`, `reports`, `blocks`.
- Chats: `chats`, `chat_members`, `messages`, `message_blocks`, `message_read_receipts`.
- Recognition: `award_definitions`, `award_grants`, and trusted append-only contribution events.

All exposed tables use RLS. Private learning records are owner-only; chats are member-only; public profiles expose approved fields only. Authors approve or reject Situation proposals; publication approval is a separate role and action. Clients cannot grant awards or moderation privileges. Meaning-aware uniqueness uses locale plus stable meaning identity, never spelling alone.
