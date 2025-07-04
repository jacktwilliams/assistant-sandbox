# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Structure

Development workspace containing AI assistant tools and configurations:

- **`assistant-sandbox/`** - Docker-based sandbox environments for AI assistants
- **`cursor-rules/`** - AI-rules / prompts. The user may tag these manually into the conversation if they are needed for this assistant.
- **`talon/`** - Talon voice control configurations for various applications
- **`ai-notes/sandbox/`** - Scratch space for AI notes and temporary files

## Development Guidelines

- Use `ai-notes/sandbox/` for temporary files and notes that can be safely accessed by AI assistants
- Each subdirectory contains its own CLAUDE.md with specific guidance
