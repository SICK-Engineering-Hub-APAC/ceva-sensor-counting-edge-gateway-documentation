# Sensor Counting Edge Gateway Documentation

Public GitHub Pages documentation for the SICK Sensor Counting Edge Gateway.

## Published pages

- `/` is the documentation home page.
- `/usage-manual/` opens the latest end-user manual.
- `/manuals/sensor-counting-edge-gateway/versions.html` lists published versions.

## Repository layout

```text
.github/workflows/deploy-pages.yml
assets/site/site.css
manuals/sensor-counting-edge-gateway/manifest.json
manuals/sensor-counting-edge-gateway/versions/v1.0.0/
tools/Build-Site.ps1
tools/release-docs.sh
```

The versioned directory contains the source HTML manual and its assets. Update the manifest's `latest` field and add the new version directory when preparing a release.

## Build locally

Run in PowerShell:

```powershell
.\tools\Build-Site.ps1
```

Open `_site/index.html` to inspect the generated site.

## Publish a documentation release

Commit the updated manifest and manual first, then run:

```bash
./tools/release-docs.sh
```

The helper creates and pushes an annotated semantic-version tag based on the manifest's `latest` version; pass `--tag 1.0.0` to create a tag without the `v` prefix. The GitHub Actions workflow builds the static site and deploys it to GitHub Pages when a semantic-version, `v*`, or `manual-*` tag is pushed. A workflow-dispatch run is also available.