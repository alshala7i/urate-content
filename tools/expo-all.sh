#!/usr/bin/env bash
# tools/expo-all.sh [out_dir] — the 26 Urate videos (voice-free exhibit versions) joined into one file for offline playback.
# Order: fixed shuffle, never two from the same series (V · R · S) back to back, nor at the loop seam. V1–V4 have no voice-over ⇒ originals; the rest from expo/.
# Output: urate-expo-all.mp4 (1080×1920 · 60 fps · H.264 crf 20 · AAC 192k) + urate-expo-all-720.mp4 (720×1280 · crf 23 · AAC 160k).
# Audio: one limiter at −4.5 dBFS after the join + the encoder's «fast» coder — the default coder left single-sample overshoots above 0 dBFS on this material.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=${1:-dist}; mkdir -p "$OUT"
ORDER="V3 S4 V7 S5 R3 V11 R4 V4 S7 V10 S6 V1 R1 V8 S1 V5 R2 V2 S8 V12 S2 V6 S3 R6 V9 R5"
src() { case $1 in V1|V2|V3|V4) echo "dl/vid/$1_tiktok_9x16.mp4";; *) echo "expo/$1.mp4";; esac; }
args=(); fc=""; n=0; cat=""
for id in $ORDER; do
  f=$(src "$id"); d=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of csv=p=0 "$f")
  args+=(-i "$f")
  fc+="[$n:v]fps=60,scale=1080:1920:flags=lanczos,setsar=1,format=yuv420p[v$n];[$n:a]aresample=48000,aformat=channel_layouts=stereo,apad,atrim=0:$d,asetpts=PTS-STARTPTS[a$n];"
  cat+="[v$n][a$n]"; n=$((n+1))
done
fc+="${cat}concat=n=$n:v=1:a=1[v][a];[v]split=2[vh][vl];[vl]scale=720:1280:flags=lanczos[vs];[a]alimiter=limit=0.5957:attack=5:release=80:level=false,asplit=2[ah][al]"
ffmpeg -nostdin -v error -stats -y "${args[@]}" -filter_complex "$fc" \
  -map "[vh]" -map "[ah]" -c:v libx264 -preset medium -crf 20 -g 120 -pix_fmt yuv420p -c:a aac -aac_coder fast -b:a 192k -movflags +faststart "$OUT/urate-expo-all.mp4" \
  -map "[vs]" -map "[al]" -c:v libx264 -preset medium -crf 23 -g 120 -pix_fmt yuv420p -c:a aac -aac_coder fast -b:a 160k -movflags +faststart "$OUT/urate-expo-all-720.mp4"
for f in "$OUT"/urate-expo-all*.mp4; do echo "$(basename "$f") $(ffprobe -v error -show_entries format=duration,size -of csv=p=0 "$f")"; done
