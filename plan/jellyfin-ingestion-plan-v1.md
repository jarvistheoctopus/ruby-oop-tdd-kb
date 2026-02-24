# Jellyfin Ingestion Plan v1 (Token-Hygiene First)

## Scope
Process courses in this order:
1. Diseño a la gorra
2. Heurísticas de diseño de software
3. Introducción a TDD

## Principles
- Keep notes compact and high-signal
- Distill, do not dump transcripts into KB
- One lesson => one structured note
- Preserve source reference (course/module/lesson/time range)

## Execution loop (per video)
1. Watch/parse first video (audio-first transcription + targeted visual checks)
2. Produce `ingestion/processed/<course>/<lesson>.md` with:
   - 5-10 bullet summary
   - core heuristics
   - concrete Ruby/TDD applicability
   - doubts/questions for discussion
3. Send Telegram progress ping after each processed video
4. Queue candidate KB notes for PR-based review

## Visual checkpoints (when "seeing" is required)
Trigger visual pass when:
- there are code snippets or diagrams not explained verbally
- terminology appears ambiguous from audio alone
- references are made to on-screen text/slides without full narration

If visual dependency is detected, send a Telegram notice and continue with frame-level notes before finalizing the lesson digest.

## Pause/Resume
- Maintain checkpoint file: `ingestion/processed/_checkpoint.md`
- At day end, record:
  - last completed lesson
  - next lesson
  - pending questions

## Definition of done (first video)
- processed note created
- checkpoint updated
- Telegram ping sent with concise summary and next step
