# Copilot Guidelines for Dials

## General
- Always prefer modular CLI commands using ArgumentParser.
- All audio commands should go through `AudioManager.swift`.

## CLI UX
- `dials balance` accepts `--left`, `--right`, `--center`.
- Use clear, system-level language in help text.

## Future Notes
- UI concepts use cockpit metaphors.