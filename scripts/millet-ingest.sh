#!/usr/bin/env bash
# Auto-detects the currently-loaded model on the local llama-server and
# runs millet ingest against it via the openai-compatible backend.
millet-ingest() {
    local model
    model=$(curl -s "${MILLET_OPENAI_BASE_URL}/models" | jq -r '.data[0].id' 2>/dev/null)
    if [ -z "$model" ] || [ "$model" = "null" ]; then
        echo "Error: no model detected at $MILLET_OPENAI_BASE_URL — is llama-server running?" >&2
        return 1
    fi
    echo "Using model: $model"

    if [ "$#" -eq 0 ]; then
        millet ingest "$(pwd)" --summary-backend openai --summary-model "$model"
    else
        millet ingest "$@" --summary-backend openai --summary-model "$model"
    fi
}
