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

# Cache-busting query so raw.githubusercontent.com does not serve stale files right after a push.
cache_bust="v=$(date +%s)"

info "Downloading skill files..."
if ! curl -fLsS --retry 2 "$BASE_URL/VERSION?$cache_bust" -o "$source_dir/VERSION"; then
  error "Could not download the skill version. Check the source URL and network connection."
  exit 1
fi
if ! curl -fLsS --retry 2 "$BASE_URL/SKILL.md?$cache_bust" -o "$source_dir/SKILL.md"; then
  error "Could not download SKILL.md. Check the URL and network connection."
  exit 1
fi
if ! curl -fLsS --retry 2 "$BASE_URL/assets/report-template.html?$cache_bust" -o "$source_dir/assets/report-template.html"; then
  error "Could not download the report template. Check the URL and network connection."
  exit 1
fi
if ! curl -fLsS --retry 2 "$BASE_URL/assets/example-report.html?$cache_bust" -o "$source_dir/assets/example-report.html"; then
  error "Could not download the example report. Check the URL and network connection."
  exit 1
fi
success "Skill files downloaded."

version="$(tr -d '[:space:]' < "$source_dir/VERSION")"
if [[ -z "$version" || ! -f "$source_dir/SKILL.md" || ! -f "$source_dir/assets/report-template.html" || ! -f "$source_dir/assets/example-report.html" ]]; then
  error "The source is incomplete; version, SKILL.md, the report template, or the example report is missing."
  exit 1
fi

install_skill() {
  local target="$1"
  local product="$2"
  local previous=""
  if [[ -f "$target/VERSION" ]]; then
    previous="$(tr -d '[:space:]' < "$target/VERSION")"
  fi
  mkdir -p "$target"
  rm -rf "$target/assets"
  mkdir -p "$target/assets"
  cp "$source_dir/SKILL.md" "$target/SKILL.md"
  cp "$source_dir/assets/report-template.html" "$target/assets/report-template.html"
  cp "$source_dir/assets/example-report.html" "$target/assets/example-report.html"
  cp "$source_dir/VERSION" "$target/VERSION"
  if [[ -n "$previous" && "$previous" != "$version" ]]; then
    success "$product: updated v${previous} → v${version}."
  elif [[ -n "$previous" ]]; then
    success "$product: reinstalled v${version}."
  else
    success "$product: installed v${version}."
  fi
}

installed=0
if [[ -d "$HOME/.codex" ]]; then
  install_skill "$HOME/.codex/skills/task-report" "Codex"
  installed=$((installed + 1))
else
  info "Codex not found (~/.codex is missing); skipped."
fi
if [[ -d "$HOME/.claude" ]]; then
  install_skill "$HOME/.claude/skills/task-report" "Claude Code"
  installed=$((installed + 1))
else
  info "Claude Code not found (~/.claude is missing); skipped."
fi

if (( installed == 0 )); then
  error "Neither Codex (~/.codex) nor Claude Code (~/.claude) was found; nothing was installed."
  exit 1
fi
printf '\n%sInstallation complete.%s\n\n' "$COLOR_GREEN" "$COLOR_RESET"
