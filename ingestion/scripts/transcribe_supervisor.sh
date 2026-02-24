#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

BASE="${TRANSCRIBE_SOURCE_BASE:-/mnt/10PinesCourses}"
SCRIPT="${TRANSCRIBE_RUN_SCRIPT:-$SCRIPT_DIR/transcribe_all_courses.sh}"
STATE_DIR="${TRANSCRIBE_STATE_DIR:-$REPO_ROOT/ingestion/raw}"
PID_FILE="$STATE_DIR/transcribe_supervisor.pid"
LOG="$STATE_DIR/transcribe_supervisor.log"
CHECKIN_LOG="$STATE_DIR/transcribe_checkins.log"
CHECKIN_EVERY_SECS="${TRANSCRIBE_CHECKIN_EVERY_SECS:-3600}"
SLEEP_SECS="${TRANSCRIBE_LOOP_SLEEP_SECS:-20}"

mkdir -p "$STATE_DIR"

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "Supervisor already running (pid $(cat "$PID_FILE"))"
  exit 0
fi

echo $$ > "$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT

last_checkin_epoch=0

echo "==== $(date -Is) supervisor start ====" >> "$LOG"

while true; do
  now_epoch=$(date +%s)

  if (( now_epoch - last_checkin_epoch >= CHECKIN_EVERY_SECS )); then
    running=$(pgrep -af 'transcribe_supervisor.sh|transcribe_all_courses.sh' | wc -l || true)
    full=$(find "$STATE_DIR" -type f -name '*.full.transcript.txt' 2>/dev/null | wc -l)
    chunks=$(find "$STATE_DIR" -type f -name '*.chunk*.transcript.txt' 2>/dev/null | wc -l)
    echo "[$(date -Is)] check-in: base=$BASE mounted=$(mountpoint -q "$BASE" && echo yes || echo no) procs=$running full=$full chunks=$chunks" | tee -a "$CHECKIN_LOG" >> "$LOG"
    last_checkin_epoch=$now_epoch
  fi

  if [[ -d "$BASE" ]]; then
    echo "[$(date -Is)] run transcribe_all_courses.sh" >> "$LOG"
    bash "$SCRIPT" >> "$LOG" 2>&1 || true
  else
    echo "[$(date -Is)] source unavailable: $BASE ; retrying" >> "$LOG"
  fi

  sleep "$SLEEP_SECS"
done
