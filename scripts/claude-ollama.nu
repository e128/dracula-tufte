#!/usr/bin/env nu

# Launch claude with an Ollama backend, default model deepseek-v4.1-flash:cloud.
# Usage: claude-ollama.nu [--model <model>] [claude args ...]
# Args after `--model <model>` are passed through to claude unchanged.

def main [--model: string = "deepseek-v4.1-flash:cloud", ...rest: string] {
    with-env {
        ANTHROPIC_BASE_URL: "http://127.0.0.1:11434"
        ANTHROPIC_AUTH_TOKEN: "ollama"
    } {
        hide-env ANTHROPIC_API_KEY
        ^claude --model $model ...$rest
    }
}
