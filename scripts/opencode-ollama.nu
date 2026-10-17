#!/usr/bin/env nu

# Launch opencode with an Ollama backend, default model qwen3.8:27b-mlx.
# Usage: opencode-ollama.nu [--model <model>] [opencode args ...]
# No args: opens the interactive TUI. Its model comes from the opencode config
# (~/.config/opencode/opencode.json): v2.0.31 has no top-level model flag, and an
# unknown `--model` only prints help. `--model` applies to `opencode run` only.
# Args given: one-shot `opencode run`. Pass opencode's own flags after `--`,
# e.g. `opencode-ollama.nu -- --agent build`.

def main [--model: string = "qwen3.8:27b-mlx", ...rest: string] {
    if ($rest | is-empty) {
        ^opencode
    } else {
        ^opencode run --model $"ollama/($model)" ...$rest
    }
}
