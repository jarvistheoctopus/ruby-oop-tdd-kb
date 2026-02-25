#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="${TRANSCRIBE_ENV_FILE:-$REPO_ROOT/ingestion/transcribe.env}"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

BASE="${TRANSCRIBE_SOURCE_BASE:-/mnt/10PinesCourses}"
OUT_BASE="${TRANSCRIBE_OUT_BASE:-$REPO_ROOT/ingestion/raw}"
LOG="${TRANSCRIBE_LOG:-$OUT_BASE/transcribe_all.log}"
CHUNK="${TRANSCRIBE_CHUNK_SECONDS:-600}"
PYTHON_BIN="${TRANSCRIBE_PYTHON:-$REPO_ROOT/.venv/bin/python}"
[[ -x "$PYTHON_BIN" ]] || PYTHON_BIN="python3"

MANIFEST="${TRANSCRIBE_MANIFEST:-$OUT_BASE/transcription_manifest.tsv}"
LOCK_DIR="${TRANSCRIBE_LOCK_DIR:-$OUT_BASE/.transcribe_all.lock}"
mkdir -p "$OUT_BASE"
touch "$MANIFEST"

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  echo "[skip] transcribe_all already running (lock: $LOCK_DIR)" | tee -a "$LOG"
  exit 0
fi
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

video_fingerprint () {
  local f="$1"
  local sz mt
  sz=$(stat -c %s "$f" 2>/dev/null || echo 0)
  mt=$(stat -c %Y "$f" 2>/dev/null || echo 0)
  printf "%s|%s|%s" "$f" "$sz" "$mt"
}

already_processed_video () {
  local f="$1"
  local fp
  fp=$(video_fingerprint "$f")
  grep -Fq "$fp" "$MANIFEST" 2>/dev/null
}

mark_processed_video () {
  local f="$1" out="$2"
  local fp
  fp=$(video_fingerprint "$f")
  printf "%s\t%s\n" "$fp" "$out" >> "$MANIFEST"
}

COURSES=(
  "Diseno-a-la-Gorra-(2020)|diseno-a-la-gorra"
  "Heuristicas de Diseño de Software con Objetos (2024)|heuristicas-diseno-software"
  "Introducción a TDD (2024)|introduccion-a-tdd"
)

COURSE_FILTER="${TRANSCRIBE_COURSES:-}" # comma-separated slugs, e.g. diseno-a-la-gorra,heuristicas-diseno-software
course_enabled () {
  local slug="$1"
  [[ -z "$COURSE_FILTER" ]] && return 0
  IFS=',' read -r -a wanted <<< "$COURSE_FILTER"
  for w in "${wanted[@]}"; do
    [[ "${w// /}" == "$slug" ]] && return 0
  done
  return 1
}

transcribe_file () {
  local video="$1" slug="$2" base safe outdir full dur total
  base="$(basename "$video")"; base="${base%.*}"
  safe="$(echo "$base" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/-\+/-/g; s/^-//; s/-$//')"
  outdir="$OUT_BASE/$slug"; mkdir -p "$outdir"
  full="$outdir/${safe}.full.transcript.txt"

  [[ -s "$full" ]] && { echo "[skip] $video (already full)" | tee -a "$LOG"; mark_processed_video "$video" "$full"; return 0; }
  already_processed_video "$video" && { echo "[skip] $video (manifest)" | tee -a "$LOG"; return 0; }
  [[ -f "$video" ]] || { echo "[error] missing file: $video" | tee -a "$LOG"; return 0; }

  dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$video" 2>/dev/null || echo 0)
  total=$(( (${dur%.*} + CHUNK - 1) / CHUNK )); [[ $total -lt 1 ]] && total=1
  echo "[start] $video chunks=$total" | tee -a "$LOG"

  for ((i=0;i<total;i++)); do
    local start idx wav txt
    start=$((i*CHUNK)); idx=$(printf "%03d" $((i+1)))
    wav="$outdir/${safe}.chunk${idx}.wav"; txt="$outdir/${safe}.chunk${idx}.transcript.txt"
    [[ -s "$txt" ]] && { echo "  [skip chunk] $idx" >> "$LOG"; continue; }

    ffmpeg -nostdin -y -ss "$start" -t "$CHUNK" -i "$video" -ac 1 -ar 16000 "$wav" -loglevel error || { echo "  [error chunk] $idx ffmpeg" | tee -a "$LOG"; rm -f "$wav"; continue; }

    "$PYTHON_BIN" - << PY
from faster_whisper import WhisperModel
m = WhisperModel('small', compute_type='int8')
segs, info = m.transcribe('$wav', language='es')
with open('$txt', 'w', encoding='utf-8') as f:
    for s in segs:
        f.write(f"[{s.start+${start}:.1f}-{s.end+${start}:.1f}] {s.text}\\n")
print('chunk $idx', info.language)
PY

    rc=$?
    [[ $rc -eq 0 ]] && echo "  [done chunk] $idx" | tee -a "$LOG" || echo "  [error chunk] $idx transcribe" | tee -a "$LOG"
    rm -f "$wav"
  done

  shopt -s nullglob
  local parts=("$outdir/${safe}.chunk"*.transcript.txt)
  if (( ${#parts[@]} > 0 )); then
    cat "${parts[@]}" > "$full"
    echo "[done] $video -> $full" | tee -a "$LOG"
    mark_processed_video "$video" "$full"
  else
    echo "[warn] no chunks for $video" | tee -a "$LOG"
  fi
}

echo "==== $(date -Is) transcribe-all resume/start ====" | tee -a "$LOG"

for entry in "${COURSES[@]}"; do
  course="${entry%%|*}"; slug="${entry##*|}"
  course_enabled "$slug" || { echo "[skip course] $slug (filter=$COURSE_FILTER)" | tee -a "$LOG"; continue; }
  [[ -d "$BASE/$course" ]] || { echo "[warn] missing directory: $BASE/$course" | tee -a "$LOG"; continue; }
  find "$BASE/$course" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.mov' -o -iname '*.m4v' \) -print0 | while IFS= read -r -d '' file; do
    transcribe_file "$file" "$slug"
  done
done

echo "==== $(date -Is) transcribe-all end ====" | tee -a "$LOG"
