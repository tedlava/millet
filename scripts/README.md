# Convenience Scripts

Shell helpers layered on top of the `millet` CLI, tuned for a local
NVIDIA + llama-server setup. These are personal workflow scripts, not
part of the `millet` package itself — they call the installed `millet`
binary, they don't replace it.

## Prerequisites

- `millet-pipeline` installed via pipx (editable or from this fork)
- `jq` and `curl` (used for local-model auto-detection)
- Environment variables, typically set in your shell rc:
  - `MILLET_RECORD_DIR` — session storage directory (default: `~/meet-recordings`)
  - `MILLET_OPENAI_BASE_URL` — OpenAI-compatible endpoint for your local
    model server (e.g. `http://localhost:8080/v1`), used by
    `millet-summarize` to auto-detect the currently loaded model

## setup-nvidia-gpu.sh

Run once after `pipx install millet-pipeline[gui,parakeet]` (or after
any `pipx install --force ...` reinstall) on an NVIDIA host, to swap in
CUDA-accelerated Parakeet support.

`onnxruntime-gpu` is deliberately not a declared package dependency —
its correct version is tied to your installed CUDA toolkit, and
`onnxruntime-gpu>=1.27` requires CUDA 13, while this fork's PyTorch pin
(cu128) needs `onnxruntime-gpu<1.27`. Rather than fight that constraint
in `pyproject.toml`, this script uninstalls the CPU-only `onnxruntime`
pulled in by default and installs the correct pinned GPU build directly
into the pipx venv.

```bash
./setup-nvidia-gpu.sh
```

**Re-run this after every `pipx install --force`.** A force-reinstall
rebuilds the venv from `pyproject.toml`'s declared dependencies, which
pulls plain CPU `onnxruntime` back in and silently undoes this fix —
Parakeet will fall back to CPU without any error, just slower runs.
Verify GPU support is active with `millet check`.

## millet-run

Wraps `millet record`, then `millet transcribe`, into one Ctrl+C-driven
step. Exists because `millet run`'s `--asr-backend` doesn't yet include
`parakeet` (only `auto|whisperx|mlx`), even though `millet transcribe`
does — this is a workaround until that's ported upstream, not a
permanent replacement for `millet run`.

Creates a proper per-session directory (`meeting-<timestamp>/`)
matching millet's own layout, since `millet record -o <dir> -f <file>`
doesn't create that subdirectory on its own.

```bash
millet-run                    # Ctrl+C to stop recording; auto-transcribes after
millet-run --mic <source>     # extra flags pass through to `millet record`
```

Transcription is run with `--mixdown mono`, `--asr-backend parakeet`,
`--device cuda`, `--torch-device cuda`, and `--no-summarize` (summary
generation is deliberately deferred to `millet-summarize`, after
speakers are correctly labeled — see below).

## millet-transcribe

Standalone wrapper around `millet transcribe` with the same CUDA/
Parakeet/mono defaults as above. Useful for re-transcribing an existing
recording (e.g. after realizing a session needs `--mixdown mono`
instead of the `dual-diarize` default, or after changing diarization
tuning flags like `--no-channel-correct`).

```bash
millet-transcribe                          # transcribes most recent .wav in $MILLET_RECORD_DIR
millet-transcribe path/to/meeting.wav      # transcribes a specific file
millet-transcribe path/to/meeting.wav --no-channel-correct   # extra flags pass through
```

`--no-channel-correct` is needed for single-source recordings (e.g.
multiple people sharing one physical mic, with no real remote-channel
audio) — `--channel-correct` assumes a real call topology (mic vs.
system audio) and can misfire when both channels carry identical
energy. Leave it on by default for actual calls; add the flag manually
for in-person/single-mic sessions.

## millet-summarize

Wraps `millet label` — the step that assigns real names to detected
speakers (merging any duplicate/over-segmented clusters in the
process) and regenerates the transcript, PDF, and summary from the
corrected result. Named `-summarize` rather than `-label` since name
assignment is really a means to the end of getting an accurate
per-speaker summary, not the main point of the step.

Auto-detects the currently loaded model from `$MILLET_OPENAI_BASE_URL`
so the summary always uses whatever's running on the local server,
without hardcoding a model name that goes stale when you swap models.

```bash
millet-summarize                     # most recent session in $MILLET_RECORD_DIR
millet-summarize .                   # current directory, if you've cd'd into a session dir
millet-summarize path/to/session --auto --no-pdf-transcript   # extra flags pass through
```

## Typical workflow

```bash
millet-run                                                    # record + transcribe
millet-summarize                                               # label speakers + generate summary/PDF
```
