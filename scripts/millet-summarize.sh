#!/usr/bin/env bash
# ~/Setup/bashrc.d/millet-summarize.sh
# Labels speakers (interactive: name/merge placeholders like YOU,
# REMOTE_1, REMOTE_2) and generates the real summary from the
# corrected transcript, routed to whatever model is currently loaded
# on the local llama-server.
#
# Session dir resolution:
#   millet-summarize                → most recent session in $MILLET_RECORD_DIR
#   millet-summarize .              → current directory (expanded to absolute path)
#   millet-summarize ./             → same
#   millet-summarize <path> [flags] → path used as-is, any extra flags passed through
millet-summarize() {
    local recdir session_dir
    recdir="${MILLET_RECORD_DIR:-$HOME/meet-recordings}"

    if [ $# -eq 0 ]; then
        session_dir=$(ls -td "$recdir"/meeting-*/ 2>/dev/null | head -1)
        if [ -z "$session_dir" ]; then
            echo "No session directory given and no recent session found in $recdir." >&2
            return 1
        fi
        session_dir="${session_dir%/}"
        echo "No directory specified — using most recent session: $session_dir"
        set -- "$session_dir"
    elif [ "$1" = "." ] || [ "$1" = "./" ]; then
        session_dir="$(pwd)"
        echo "Using current directory: $session_dir"
        shift
        set -- "$session_dir" "$@"
    fi

    local model
    model=$(curl -s "${MILLET_OPENAI_BASE_URL}/models" | jq -r '.data[0].id' 2>/dev/null)
    if [ -z "$model" ] || [ "$model" = "null" ]; then
        echo "Error: no model detected at $MILLET_OPENAI_BASE_URL — is llama-server running?" >&2
        return 1
    fi
    echo "Using model: $model"
    millet label --summary-backend openai --summary-model "$model" --no-pdf-transcript "$@"
}
