#!/usr/bin/env bash
# ~/Setup/bashrc.d/millet-transcribe.sh
millet-transcribe() {
    local args=("$@")
    if [ $# -eq 0 ]; then
        local latest
        latest=$(ls -t "${MILLET_RECORD_DIR:-$HOME/meet-recordings}"/*.wav 2>/dev/null | head -1)
        if [ -z "$latest" ]; then
            echo "No audio file given and no recent recording found in ${MILLET_RECORD_DIR:-$HOME/meet-recordings}." >&2
            return 1
        fi
        echo "No file specified — using most recent recording: $latest"
        args=("$latest")
    fi
    millet transcribe \
        --mixdown mono \
        --asr-backend parakeet \
        --device cuda \
        --torch-device cuda \
        --no-summarize \
        "${args[@]}"
}
