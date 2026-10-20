# 🫖 Bule

![Bule teapot icon](assets/app_icon.png)

Bule is an offline-first language-learning and community app built with Flutter. It combines compact lessons, contextual translations, vocabulary review, interactive Situations, and planned community features in a calm Cupertino interface.

## Supported platforms

- Android
- iOS
- Web

Application identifier: `site.cambalhota.bulelang`

## Content languages

- Brazilian Portuguese (`pt-BR`)
- US English (`en-US`)
- Mexican Spanish (`es-MX`)
- France French (`fr-FR`)
- Indonesian (`id-ID`)
- Estonian (`et-EE`)

## Current functionality

- Guest-first onboarding with multiple Know languages and one Learn language.
- Local persistence without requiring an account.
- Offline lessons with flashcards, typed answers, and three-option exercises.
- Contextual full-phrase and word-segment translations.
- Deterministic grading with accepted 80% Levenshtein matches.
- Persistent vocabulary, private notes, attempts, review scheduling, and lesson completion counts.
- Missed vocabulary returns sooner; successful reviews use 1, 3, 7, and 14-day intervals.
- Vocabulary grouped by lesson and prioritized from weaker to stronger answers.
- Ten-item vocabulary review unlocked after three completed lessons.
- Offline authored Situation practice with deterministic replies, help and retry states, completion counts, linked vocabulary, voting, and nested comments.
- Situation feedback unlocks only after completion; linked words enter the learner's vocabulary.
- Speech playback for Learn-language words, phrases, and Situation dialogue with a locally saved voice selection.
- Editable Know and Learn selections without deleting previous-language progress.
- Responsive Cupertino interface for mobile and web.

Community synchronization, user-authored Situation moderation, chats, AI assistance, notifications, and analytics remain planned work.

## Project structure

```text
lib/
  app/                    # Bootstrap, dependency wiring, application state
  domain/                 # Typed models and business rules
  data/                   # Repositories and local services
  ui/
    core/                 # Shared design tokens and responsive layout
    features/             # Onboarding, learning, profile, and shell views
assets/
  language-learning-starter-content.json
  app_icon.png
docs/                     # Product, architecture, data model, and milestones
```

The client follows layered MVVM with constructor injection. Views do not access persistence directly. The bundled content pack is immutable; user progress, notes, and Situation activity are stored separately.

## Requirements

- Flutter 3.44 or newer
- Dart 3.12 or newer
- Xcode for iOS builds
- Android Studio or an Android SDK for Android builds
- A supported browser for web development

## Run locally

```sh
flutter pub get
flutter run
```

Choose a platform explicitly when needed:

```sh
flutter run -d chrome
flutter run -d ios
flutter run -d android
```

## Static analysis

```sh
dart format lib
dart analyze
```

## Content pack

The application loads `assets/language-learning-starter-content.json` at startup. Its schema includes stable IDs, lessons, exercises, Situations, contextual translations, and clickable phrase segments.

When updating it:

- Preserve existing stable IDs and references.
- Include all six locales for every clickable segment.
- Ensure concatenated segments reconstruct the original item text exactly.
- Update the schema version and validation summary.

## Documentation

- [Product decisions](docs/product-decisions.md)
- [Architecture](docs/architecture.md)
- [Data model](docs/data-model.md)
- [Milestones](docs/milestones.md)

## Security and privacy

Guest progress and notes remain on the current device. Notes are private and associated with their vocabulary item. Public learning content is separate from private learning records and future member-only chats. Secrets must never be embedded in the Flutter client.
