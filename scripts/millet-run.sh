#!/usr/bin/env bash
# ~/Setup/bashrc.d/millet-run.sh
# Workaround for `millet run` not yet supporting --asr-backend parakeet
# (transcribe has it, run doesn't — likely just unported upstream).
# Records into a per-session subdirectory (meeting-<ts>/), then
# automatically transcribes (mono mixdown, Parakeet, CUDA) once you
# Ctrl+C to stop. Labeling/summary stays a separate deliberate step
# via millet-summarize.
millet-run() {
    local basedir ts session_dir filename filepath
    basedir="${MILLET_RECORD_DIR:-$HOME/meet-recordings}"
    ts=$(date +%Y%m%d-%H%M%S)
    session_dir="$basedir/meeting-${ts}"
    filename="meeting-${ts}.wav"
    filepath="$session_dir/$filename"
    mkdir -p "$session_dir"
    echo "Recording to: $filepath"
    echo "Press Ctrl+C to stop."

    millet record -o "$session_dir" -f "$filename" "$@"
    local record_status=$?

    if [ $record_status -ne 0 ]; then
        echo "millet record exited with an error (status $record_status) — skipping transcription." >&2
        return $record_status
    fi

    echo "Recording finished. Starting transcription..."
    millet-transcribe "$filepath"
}
