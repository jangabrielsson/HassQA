# Changelog

## [v0.75.1] - 2026-11-12

## Changes in v0.75.1

- ✨ **Feature**: add Dirigera-style release automation
  - scripts/: create-release.sh, setversion.sh, forum-post-generator.sh
  - (copied from Dirigera) plus a HassQA project-config.sh - version in
  - .version and local VERSION in HASS.lua, artifact packed to the repo
  - root as HassQA.fqa
  - Seed .version (0.75.0) and CHANGELOG.md
  - Document the release flow and qaDist contract in AGENTS.md
- 🐛 **Fix**: make HASS.lua packable with flua and rebuild the .fqa artifact
  - Rename the QwikAppChild extra file QC -> QChild (flua enforces the
  - HC3 editor's 3-character minimum for declared file names)
  - Give --%%var:url a package value placeholder so the distribution
  - pack keeps the variable without baking in a real address
  - Move to full semver: local VERSION = "0.75.0"
  - Replace the stale plua-built HASS.fqa with a fresh HassQA.fqa in the
  - repo root (matches the qaDist dist.json entry); add the !HassQA.fqa
  - exception to .gitignore
- ✨ **Feature**: Add networking capabilities with HTTP, TCP, UDP, and WebSocket clients
  - Introduced a new Lua module for networking (`.luals/net.lua`) that includes:
  - Asynchronous HTTP client with request handling.
  - TCP and UDP socket clients for communication.
  - WebSocket client for real-time data exchange.
  - chore: Configure Lua language server settings
  - Created `.luarc.json` for Lua language server configuration, enabling diagnostics and specifying global variables.
  - Added workspace library paths and ignored directories for better development experience.
  - chore: Update VSCode settings for Lua development
  - Added `.vscode/extensions.json` to recommend essential extensions for Lua development.
  - Created code snippets in `.vscode/flua.code-snippets` for QuickApp development.
  - Updated `.vscode/launch.json` to include multiple configurations for running and debugging Lua files.
  - Removed outdated `.vscode/settings.json` to streamline configuration.
  - Added `.vscode/tasks.json` for uploading files to HC3.
- 📚 **Docs**: Create AGENTS.md for QuickApp development guidance
  - Added documentation for AI agents working on QuickApp code, detailing project structure, directives, tools, and best practices.
- 🐛 **Fix**: Enhance HASS integration and connection handling
  - Updated `HASS.lua` to improve variable handling and connection setup.
  - Introduced `HASSConnector.lua` for managing WebSocket connections to Home Assistant.
  - Refactored utility functions in `Utils.lua` for better error handling and code clarity.
- ♻️ **Refactor**: General code cleanup and improvements
  - Added a rounding function to `Classes.lua`.
  - Improved error handling and callback management in WebSocket connections.
- ✨ **Feature**: Refactor HASS.lua variable definitions for consistency and update Utils.lua ping function for clarity
- ✨ **Feature**: Update .gitignore, HASS.lua, and settings for improved configuration; remove hc3emu_cfg.lua
- ✨ **Feature**: Update HASS.releases with version 0.75 and updated description


*Generated automatically from git commits*

## [v0.75] - 2025-03-23

- Release v0.75 (tag Rel1): Home Assistant device importer, first tracked release.
