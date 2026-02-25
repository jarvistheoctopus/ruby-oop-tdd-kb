# dojo

Private knowledge base for Ruby + OOP + TDD, optimized for both humans and LLM retrieval.

## Project intention
Build a shared team knowledge base that helps us consistently make better OOP/TDD design decisions in real Ruby work.

This repository is not a transcript archive. Transcripts are raw input. The real product is a compact, opinionated, and reviewable set of notes we can rely on while designing, coding, and reviewing together.

## Goals
- Improve team-level OOP/TDD decision quality in day-to-day development.
- Capture reusable production heuristics, not just theory.
- Keep notes concise, structured, and searchable for fast retrieval.
- Turn course/project insights into practical guidance we can apply immediately.

## Current phase
- **Phase 1 (now):** collect and stabilize course transcripts in `ingestion/raw/`.
- **Phase 2 (next):** distill transcripts into high-signal KB notes under `concepts/`, `patterns/`, `katas/`, and `reviews/`.

## Structure
- `concepts/` fundamentals and principles
- `patterns/` tactical patterns with tradeoffs
- `katas/` distilled learnings from practice
- `reviews/` review checklists and heuristics
- `examples/` runnable snippets
- `templates/` note templates
- `plan/` project plans and ingestion strategy
- `ingestion/` raw and processed learning inputs

## External resources
- **Diseño a la Gorra (code repository):** https://github.com/hernanwilkinson/disenioALaGorra
  - Local clone: `~/code/disenioALaGorra`
  - What it is: official repository for the *Diseño a la Gorra* webinar episodes (10Pines Academy), i.e., the code used/discussed across episodes.
  - Why it matters here: it provides concrete, real examples to connect transcript ideas with actual Ruby/OOP/TDD design decisions while distilling KB notes.

## Workflow
1. Capture source insight (course/book/project)
2. Distill into note template
3. Link to related notes
4. Open PR for review/discussion

## Transcription path config (host/VM)
Transcription scripts read optional config from `ingestion/transcribe.env`.

Quick setup:
```bash
cp ingestion/transcribe.env.example ingestion/transcribe.env
```

Then edit:
- `TRANSCRIBE_SOURCE_BASE` → where course videos live (e.g. `/mnt/10PinesCourses`)
- `TRANSCRIBE_OUT_BASE` and `TRANSCRIBE_STATE_DIR` → where transcripts/logs should be written

You can still override any value per command using environment variables.

## Quality bar for notes
Each note should be:
- **Actionable:** includes concrete Ruby/TDD applicability.
- **Opinionated:** states heuristics and tradeoffs explicitly.
- **Traceable:** preserves source reference (course/module/lesson/time range).
- **Small:** optimized for quick human read and LLM retrieval.
