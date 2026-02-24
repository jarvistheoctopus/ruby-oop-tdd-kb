#!/usr/bin/env bash
set -euo pipefail

: "${JELLYFIN_URL:?Missing JELLYFIN_URL}"
: "${JELLYFIN_USER:?Missing JELLYFIN_USER}"
: "${JELLYFIN_PASS:?Missing JELLYFIN_PASS}"

WORKDIR="/root/code/ruby-oop-tdd-kb/ingestion/raw/diseno-a-la-gorra"
mkdir -p "$WORKDIR"

AUTH_JSON=$(node -e '
const https=require("https");
const url=process.env.JELLYFIN_URL.replace(/\/$/,"") + "/Users/AuthenticateByName";
const data=JSON.stringify({Username:process.env.JELLYFIN_USER,Pw:process.env.JELLYFIN_PASS});
const req=https.request(url,{method:"POST",headers:{"Content-Type":"application/json","Content-Length":Buffer.byteLength(data),"X-Emby-Authorization":"MediaBrowser Client=\"JarvisIngest\", Device=\"Jarvis\", DeviceId=\"jarvis-ingest\", Version=\"1.0\""}},res=>{let b="";res.on("data",d=>b+=d);res.on("end",()=>process.stdout.write(b));});
req.on("error",e=>{console.error(e.message);process.exit(1)});
req.write(data);req.end();')

TOKEN=$(printf '%s' "$AUTH_JSON" | jq -r '.AccessToken')
USER_ID=$(printf '%s' "$AUTH_JSON" | jq -r '.User.Id')
ITEM_ID="081eab5e2f925c0aa5679a5be86260c1"

VIDEO_URL="${JELLYFIN_URL%/}/Videos/${ITEM_ID}/stream?static=true&api_key=${TOKEN}"
AUDIO_FILE="$WORKDIR/s01e01.wav"
TRANSCRIPT_FILE="$WORKDIR/s01e01.transcript.txt"

ffmpeg -y -i "$VIDEO_URL" -ac 1 -ar 16000 "$AUDIO_FILE" >/tmp/jarvis_ffmpeg.log 2>&1
python - << PY
from faster_whisper import WhisperModel
model = WhisperModel("small", compute_type="int8")
segments, info = model.transcribe("$AUDIO_FILE", language="es")
with open("$TRANSCRIPT_FILE", "w", encoding="utf-8") as f:
    for s in segments:
        f.write(f"[{s.start:.1f}-{s.end:.1f}] {s.text}\n")
print("language", info.language)
PY

echo "Transcript saved: $TRANSCRIPT_FILE"
