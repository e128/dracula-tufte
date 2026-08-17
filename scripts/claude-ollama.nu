#!/usr/bin/env nu

# Launch claude with an Ollama backend, default model qwen3.8:27b-mlx.
# Usage: claude-ollama.nu [--model <model>] [...claude args]

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

    let final_model = $model
    let final_args = $rest

    with-env {
        ANTHROPIC_BASE_URL: "http://127.0.0.1:11434"
        ANTHROPIC_AUTH_TOKEN: "ollama"
    } {
        hide-env ANTHROPIC_API_KEY
        ^claude --model $final_model ...$final_args
    }
}
