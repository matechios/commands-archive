#!/usr/bin/env bash
set -euo pipefail

# Install task-report for Codex and Claude Code from files in the Git repository.
# Set TASK_REPORT_BASE_URL when using a different directory of source files.

BASE_URL="${TASK_REPORT_BASE_URL:-https://raw.githubusercontent.com/matechios/commands-archive/main/skills/task-report}"
BASE_URL="${BASE_URL%/}"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  COLOR_BLUE=$'\033[1;34m'
  COLOR_GREEN=$'\033[1;32m'
  COLOR_RED=$'\033[1;31m'
  COLOR_RESET=$'\033[0m'
else
  COLOR_BLUE=""
  COLOR_GREEN=""
  COLOR_RED=""
  COLOR_RESET=""
fi

info() {
  printf '%s›%s %s\n' "$COLOR_BLUE" "$COLOR_RESET" "$1"
}

success() {
  printf '%s✓%s %s\n' "$COLOR_GREEN" "$COLOR_RESET" "$1"
}

error() {
  printf '%s✗%s %s\n' "$COLOR_RED" "$COLOR_RESET" "$1" >&2
}

printf '\n%sTask Report installer%s\n\n' "$COLOR_BLUE" "$COLOR_RESET"

if ! command -v curl >/dev/null; then
  error "curl is required but was not found."
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
source_dir="$tmp_dir/source"
mkdir -p "$source_dir/assets"

info "Downloading skill files..."
if ! curl -fLsS --retry 2 "$BASE_URL/VERSION" -o "$source_dir/VERSION"; then
  error "Could not download the skill version. Check the source URL and network connection."
  exit 1
fi
if ! curl -fLsS --retry 2 "$BASE_URL/SKILL.md" -o "$source_dir/SKILL.md"; then
  error "Could not download SKILL.md. Check the URL and network connection."
  exit 1
fi
if ! curl -fLsS --retry 2 "$BASE_URL/assets/report-template.html" -o "$source_dir/assets/report-template.html"; then
  error "Could not download the report template. Check the URL and network connection."
  exit 1
fi
success "Skill files downloaded."

version="$(tr -d '[:space:]' < "$source_dir/VERSION")"
if [[ -z "$version" || ! -f "$source_dir/SKILL.md" || ! -f "$source_dir/assets/report-template.html" ]]; then
  error "The source is incomplete; version, SKILL.md, or the report template is missing."
  exit 1
fi

install_skill() {
  local target="$1"
  local product="$2"
  mkdir -p "$target"
  rm -rf "$target/assets"
  mkdir -p "$target/assets"
  cp "$source_dir/SKILL.md" "$target/SKILL.md"
  cp "$source_dir/assets/report-template.html" "$target/assets/report-template.html"
  success "$product installation complete."
}

info "Installing v${version} for Codex and Claude Code..."
install_skill "$HOME/.codex/skills/task-report" "Codex"
install_skill "$HOME/.claude/skills/task-report" "Claude Code"
printf '\n%sInstallation complete.%s\n\n' "$COLOR_GREEN" "$COLOR_RESET"
