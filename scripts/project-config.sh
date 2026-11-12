#!/bin/bash

# Project Configuration for Release Scripts
# HassQA — Home Assistant device importer (QuickApp for the Fibaro HC3)
# Same release flow as the Dirigera project: see scripts/README.md

# ============================================================================
# PROJECT IDENTIFICATION
# ============================================================================

# Project name (used in messages and titles)
PROJECT_NAME="HassQA"

# GitHub repository (format: owner/repo)
GITHUB_REPO="jangabrielsson/HassQA"

# Forum thread URL
FORUM_URL="https://forum.fibaro.com/topic/78625-home-assistant-integrator/"

# ============================================================================
# VERSION MANAGEMENT
# ============================================================================

# Version file location (relative to project root)
VERSION_FILE=".version"

# Source files that contain version declarations
# Format: "path:pattern" where pattern is the sed search pattern
# NOTE: keep in sync with qaDist's dist.json entry
#       (versionFile "main", versionPattern 'local VERSION = "..."')
declare -a VERSION_FILES=(
    "HASS.lua:local VERSION"
)

# ============================================================================
# ARTIFACT GENERATION
# ============================================================================

# The .fqa lives in the repo ROOT (not dist/): qaDist's dist.json downloads
# "HassQA.fqa" from the repo root at the release tag:
#   https://raw.githubusercontent.com/jangabrielsson/HassQA/<tag>/HassQA.fqa
DIST_DIR="."

# Artifacts to build
# Format: "source_file:output_file:build_command"
# The build_command can use {SOURCE} and {OUTPUT} placeholders
declare -a ARTIFACTS=(
    "HASS.lua:HassQA.fqa:flua --tool pack {SOURCE} -o {OUTPUT} -f"
)

# Files to include in git commits for releases
# (HASS.lua packs its --%%file extras: qwikchild ($ template), Utils,
#  Classes, Config, User)
declare -a RELEASE_FILES=(
    ".version"
    "CHANGELOG.md"
    "HASS.lua"
    "Utils.lua"
    "Classes.lua"
    "Config.lua"
    "User.lua"
    "HassQA.fqa"
)

# ============================================================================
# DOCUMENTATION
# ============================================================================

# Directory for release notes/forum posts (relative to project root)
NOTES_DIR="doc/notes"

# Main documentation URL (used in generated forum posts)
DOCUMENTATION_URL="$FORUM_URL"

# ============================================================================
# RELEASE CUSTOMIZATION
# ============================================================================

# Commit message template for releases
# Variables: {VERSION}, {NOTES}
RELEASE_COMMIT_TEMPLATE="chore: release v{VERSION}

- Update version to {VERSION} in all files
- Update CHANGELOG.md with release notes
- Generate release artifacts"

# Tag message template
# Variables: {VERSION}, {NOTES}
TAG_MESSAGE_TEMPLATE="Release v{VERSION}

{NOTES}"

# ============================================================================
# OPTIONAL HOOKS
# ============================================================================

# Pre-release hook (optional) - runs before any release operations
# pre_release_hook() {
#     echo "Running pre-release checks..."
#     return 0
# }

# Post-release hook (optional) - runs after successful release
# post_release_hook() {
#     local version=$1
#     echo "Running post-release actions for v$version..."
#     return 0
# }

# Artifact build hook (optional) - custom artifact generation
# custom_artifact_build() {
#     echo "Building custom artifacts..."
#     return 0
# }

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Get artifact file names (for uploading to GitHub releases)
get_artifact_files() {
    local files=()
    for artifact in "${ARTIFACTS[@]}"; do
        IFS=':' read -r source output command <<< "$artifact"
        if [ -f "$output" ]; then
            files+=("$output")
        fi
    done
    echo "${files[@]}"
}

# Get artifact base names (for display)
get_artifact_names() {
    local names=()
    for artifact in "${ARTIFACTS[@]}"; do
        IFS=':' read -r source output command <<< "$artifact"
        names+=("$(basename "$output")")
    done
    echo "${names[@]}"
}

# Validate configuration
validate_config() {
    local errors=0

    if [ -z "$PROJECT_NAME" ]; then
        echo "Error: PROJECT_NAME is not set"
        ((errors++))
    fi

    if [ -z "$GITHUB_REPO" ]; then
        echo "Error: GITHUB_REPO is not set"
        ((errors++))
    fi

    if [ -z "$VERSION_FILE" ]; then
        echo "Error: VERSION_FILE is not set"
        ((errors++))
    fi

    return $errors
}

# ============================================================================
# EXPORT FUNCTIONS
# ============================================================================

# Export functions so they can be used by other scripts
export -f get_artifact_files
export -f get_artifact_names
export -f validate_config
