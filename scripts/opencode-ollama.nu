#!/usr/bin/env nu

# Launch opencode with an Ollama backend, default model qwen3.8:27b-mlx.
# Usage: opencode-ollama.nu [--model <model>] [message ...]
# No message: opens the interactive TUI. Message given: one-shot `opencode run`.

def main [...args: string] {
    mut model = "qwen3.8:27b-mlx"
    mut rest = []
    mut i = 0

    while $i < ($args | length) {
        let arg = $args | get $i
        if $arg == "--model" {
            $model = $args | get ($i + 1)
            $i = $i + 2
        } else if ($arg | str starts-with "--model=") {
            $model = $arg | str replace "--model=" ""
            $i = $i + 1
        } else {
            $rest = $rest ++ [$arg]
            $i = $i + 1
        }
    }

    if ($rest | is-empty) {
        ^opencode --model $"ollama/($model)"
    } else {
        ^opencode run --model $"ollama/($model)" ($rest | str join ' ')
    }
}
