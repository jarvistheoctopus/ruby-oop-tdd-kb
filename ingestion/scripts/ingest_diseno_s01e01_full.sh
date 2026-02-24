#!/usr/bin/env bash
set -euo pipefail
VIDEO="/mnt/10PinesCourses/Diseno-a-la-Gorra-(2020)/Season01/Diseño a la Gorra (2020) - s01e01 - Qué es Diseñar y Cómo hacer que un diseño nos 'Enseñe' - Diseño a la Gorra-5m2_YPho_D4.mkv"
OUTDIR="/root/code/ruby-oop-tdd-kb/ingestion/raw/diseno-a-la-gorra"
mkdir -p "$OUTDIR"
DUR=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$VIDEO")
CHUNK=600
TOTAL=$(( (${DUR%.*} + CHUNK - 1) / CHUNK ))

for ((i=0;i<TOTAL;i++)); do
  START=$((i*CHUNK))
  IDX=$(printf "%02d" $((i+1)))
  WAV="$OUTDIR/s01e01_chunk${IDX}.wav"
  TXT="$OUTDIR/s01e01_chunk${IDX}.transcript.txt"
  if [[ -f "$TXT" ]]; then
    echo "skip chunk $IDX (already transcribed)"
    continue
  fi
  ffmpeg -y -ss "$START" -t "$CHUNK" -i "$VIDEO" -ac 1 -ar 16000 "$WAV" -loglevel error
  python - << PY
from faster_whisper import WhisperModel
model=WhisperModel('small', compute_type='int8')
segments, info = model.transcribe('$WAV', language='es')
with open('$TXT','w',encoding='utf-8') as f:
    for s in segments:
        f.write(f"[{s.start+${START}:.1f}-{s.end+${START}:.1f}] {s.text}\\n")
print('done chunk', '$IDX', info.language)
PY
  rm -f "$WAV"
done

cat $OUTDIR/s01e01_chunk*.transcript.txt > $OUTDIR/s01e01_full.transcript.txt
wc -l $OUTDIR/s01e01_full.transcript.txt
