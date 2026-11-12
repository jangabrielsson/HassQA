# Release Scripts — HassQA

Release automation in the same style as the Dirigera project. One command
bumps the version, packs the .fqa, commits, tags, pushes, creates the GitHub
release with artifacts, and generates a forum post.

## Files

- **`project-config.sh`** - HassQA-specific settings (version, artifact, files)
- **`create-release.sh`** - Main release automation (interactive)
- **`setversion.sh`** - Update the version number in `.version` and `HASS.lua`
- **`forum-post-generator.sh`** - Generate an HTML forum post for a release

## Quick Start

```bash
./scripts/create-release.sh --preview   # Preview release notes, nothing is written
./scripts/create-release.sh             # Interactive release creation
./scripts/setversion.sh 0.76.0          # Update version only
```

The interactive flow asks for the bump type (patch/minor/major/custom) and
release notes (auto-generated from git commits, custom, or default), shows a
summary, and on confirmation:

1. Bumps the version in `.version` and `HASS.lua` (`local VERSION`)
2. Prepends the new entry to `CHANGELOG.md`
3. Packs `HassQA.fqa` with `flua --tool pack` — **into the repo root**, not `dist/`
4. Commits and pushes the release files, creates and pushes the tag `vX.Y.Z`
5. Creates the GitHub release, uploads `HassQA.fqa`, generates the forum post

## qaDist contract (do not break)

The qaDist manifest (`../qaDist/dist.json`) fetches releases for `HassQA`
like this:

- Release list: `https://api.github.com/repos/jangabrielsson/HassQA/releases`
- Download: `https://raw.githubusercontent.com/jangabrielsson/HassQA/<tag>/HassQA.fqa`
  — so **`HassQA.fqa` must be committed in the repo root** at the release tag
  (the `!HassQA.fqa` exception in `.gitignore` keeps it trackable).
- Installed version: read from the fqa's **`main`** file with the pattern
  `local VERSION = "([^"]+)"` — kept in sync by `VERSION_FILES` in
  `project-config.sh`.
- `ignore: ["User", "config"]` — qaDist keeps the installed copies of those
  fqa files on upgrade.

## Requirements

- `git`, `gh` (authenticated: `gh auth login`), `flua` (`pip install flua`)
- bash 4.0+

## Notes

- The packed `.fqa` uses placeholders for secrets: the `url` and `token`
  quickApp variables carry `--%%var` package values (`<HASS url>`,
  `<put you HASS api token here>`), so no real credentials ever travel in
  the committed artifact.
