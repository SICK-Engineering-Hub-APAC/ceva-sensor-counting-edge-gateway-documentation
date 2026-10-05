#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tools/release-docs.sh [--tag 1.0.0] [--message "Release documentation 1.0.0"] [--skip-build]

Builds the site, creates an annotated version tag, and pushes it to origin.
Without --tag, the version is read from the manual manifest's latest field.
EOF
}

tag=""
message=""
skip_build=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--tag)
      tag="${2:-}"
      shift 2
      ;;
    -m|--message)
      message="${2:-}"
      shift 2
      ;;
    --skip-build)
      skip_build=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"

manifest_path="$repo_root/manuals/sensor-counting-edge-gateway/manifest.json"
if [[ -z "$tag" ]]; then
  if ! command -v node >/dev/null 2>&1; then
    echo "Node.js is required to read the manifest; pass --tag explicitly." >&2
    exit 1
  fi
  tag="$(node -e 'const m=require(process.argv[1]); if(typeof m.latest!=="string") process.exit(1); process.stdout.write(m.latest)' "$manifest_path")"
fi

if [[ ! "$tag" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Tag must use semantic format like 1.0.0 or v1.0.0" >&2
  exit 2
fi

if [[ -z "$message" ]]; then
  message="Release documentation $tag"
fi

if [[ "$skip_build" -eq 0 ]]; then
  if command -v pwsh >/dev/null 2>&1; then
    pwsh -NoProfile -File "$repo_root/tools/Build-Site.ps1"
  elif command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$repo_root/tools/Build-Site.ps1"
  else
    echo "PowerShell is required to build; install PowerShell or pass --skip-build." >&2
    exit 1
  fi
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree has uncommitted changes. Commit them before tagging." >&2
  exit 1
fi

git fetch origin --tags
if [[ -n "$(git tag --list "$tag")" ]]; then
  echo "Tag already exists locally: $tag" >&2
  exit 1
fi
if [[ -n "$(git ls-remote --tags origin "refs/tags/$tag")" ]]; then
  echo "Tag already exists on origin: $tag" >&2
  exit 1
fi

git tag -a "$tag" -m "$message"
git push origin "$tag"
echo "Pushed tag $tag. GitHub Actions will build and deploy GitHub Pages."