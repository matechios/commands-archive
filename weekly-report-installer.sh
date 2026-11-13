#!/usr/bin/env bash
# Cài ios-weekly-report vào git repo hiện tại: commit-msg hook, report tool
# trong .team-tools/weekly-report/, skill và slash command cho Claude/Codex.
#   bash weekly-report-installer.sh   (chạy từ thư mục gốc của repo)
#
# Cũng chạy được qua pipe: curl -fsSL <url> | bash
# Khi không có bộ tool cạnh file này, installer tự clone từ TOOLS_REPO_URL.
set -euo pipefail

TOOL_VERSION="1.6"
TOOLS_REPO_URL="${TOOLS_REPO_URL:-git@github.com:matechios/ios-weekly-report.git}"

main() {
  if [[ -t 1 ]]; then
    C_RED=$'\033[31m' C_YEL=$'\033[33m' C_GRN=$'\033[32m' C_BLU=$'\033[34m' C_DIM=$'\033[2m' C_B=$'\033[1m' C_0=$'\033[0m'
  else
    C_RED= C_YEL= C_GRN= C_BLU= C_DIM= C_B= C_0=
  fi
  ok()   { echo "  ${C_GRN}✓${C_0} $*"; }
  warn() { echo "  ${C_YEL}!${C_0} $*"; }
  bad()  { echo "  ${C_RED}✗${C_0} $*"; }
  fix()  { echo "    ${C_DIM}$*${C_0}"; }
  die()  { bad "$*"; exit 1; }

  REPO_DIR="$(pwd)"
  TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" && pwd)"
  GIT_HOOKS_DIR="$REPO_DIR/.git/hooks"
  TEAM_TOOLS_DIR="$REPO_DIR/.team-tools"
  SCRIPTS_TARGET="$TEAM_TOOLS_DIR/weekly-report"
  CODEX_SKILL_TARGET="$REPO_DIR/.codex/skills/weekly-report"
  CLAUDE_SKILL_TARGET="$REPO_DIR/.claude/skills/weekly-report"
  CLAUDE_COMMANDS_TARGET="$REPO_DIR/.claude/commands"

  echo
  echo "${C_BLU}==>${C_0} ${C_B}Cài đặt ios-weekly-report $TOOL_VERSION${C_0}"
  echo "    ${C_DIM}${REPO_DIR/#$HOME/~}${C_0}"
  echo

  [[ -d "$REPO_DIR/.git" ]] \
    || die "Thư mục hiện tại không phải git repo. Chạy lại file cài đặt từ thư mục gốc của project."

  if [[ ! -f "$TOOLS_DIR/scripts/report.py" || ! -f "$TOOLS_DIR/hooks/commit-msg" ||
        ! -f "$TOOLS_DIR/claude-skills/weekly-report/SKILL.md" ||
        ! -f "$TOOLS_DIR/codex-skills/weekly-report/SKILL.md" ||
        ! -f "$TOOLS_DIR/claude-commands/report.md" ]]; then
    command -v git >/dev/null 2>&1 || die "Không tìm thấy git. Cần git để tải bộ tool."
    TMP_TOOLS_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ios-weekly-report.XXXXXX")"
    trap 'rm -rf "$TMP_TOOLS_DIR"' EXIT
    [[ ! -t 1 ]] || printf '    %s' "${C_DIM}Đang tải bộ tool…${C_0}"
    if ! git clone --quiet --depth 1 "$TOOLS_REPO_URL" "$TMP_TOOLS_DIR" >/dev/null 2>&1; then
      [[ ! -t 1 ]] || printf '\n'
      bad "Không tải được bộ tool từ $TOOLS_REPO_URL"
      fix "Kiểm tra kết nối mạng và quyền truy cập repo, hoặc đặt lại TOOLS_REPO_URL."
      exit 1
    fi
    [[ ! -t 1 ]] || printf '\r\033[K'
    TOOLS_DIR="$TMP_TOOLS_DIR"
  fi

  # Report tool. Bản cũ cài thẳng vào .team-tools/, bản mới nằm trong
  # .team-tools/weekly-report/ để chừa chỗ cho các tool khác.
  previous=
  for old in "$SCRIPTS_TARGET/report.py" "$TEAM_TOOLS_DIR/report.py"; do
    [[ -z "$previous" && -f "$old" ]] || continue
    previous="$(sed -n 's/^TOOL_VERSION = "\(.*\)"/\1/p' "$old" | head -1)"
  done
  mkdir -p "$SCRIPTS_TARGET" 2>/dev/null || die "Không tạo được thư mục .team-tools/weekly-report/"
  cp "$TOOLS_DIR/scripts/report.py" "$SCRIPTS_TARGET/report.py" \
    || die "Không ghi được .team-tools/weekly-report/report.py"
  if [[ -n "$previous" && "$previous" != "$TOOL_VERSION" ]]; then
    ok "Report tool: cập nhật $previous → $TOOL_VERSION ${C_DIM}· .team-tools/weekly-report/${C_0}"
  else
    ok "Report tool $TOOL_VERSION ${C_DIM}· .team-tools/weekly-report/${C_0}"
  fi

  env_file="$SCRIPTS_TARGET/.env"
  legacy_env="$TEAM_TOOLS_DIR/.env"
  legacy_env_owned=false
  if [[ -f "$legacy_env" && ! -L "$legacy_env" ]] &&
     grep -Eq '^#.*(ios-weekly-report|git-team-tools) config' "$legacy_env"; then
    legacy_env_owned=true
  elif [[ -e "$legacy_env" || -L "$legacy_env" ]]; then
    warn "Giữ .team-tools/.env vì không xác định được là cấu hình của weekly-report."
    fix "Kiểm tra cấu hình .team-tools/weekly-report/.env trước khi gửi báo cáo."
  fi
  if [[ -f "$env_file" ]]; then
    ok "Cấu hình .team-tools/weekly-report/.env ${C_DIM}· giữ nguyên${C_0}"
  elif [[ "$legacy_env_owned" == true ]]; then
    cp -p "$legacy_env" "$env_file" || die "Không chuyển được .team-tools/.env"
    ok "Cấu hình .team-tools/weekly-report/.env ${C_DIM}· chuyển từ .team-tools/.env${C_0}"
  else
    cat > "$env_file" << 'EOF' || die "Không ghi được .team-tools/weekly-report/.env"
# ── ios-weekly-report config ───────────────────────────────
# Tên của bạn (override git config user.name)
# REPORT_AUTHOR="Nguyen Van A"

# Google Apps Script Web App
SHEETS_WEBHOOK_URL="https://script.google.com/macros/s/AKfycbzIJt8MeIWavTEM_d0oY3ZOQJ7SLldIvJE9Xf87RyGlOIewD_A0S2XUaBOpOv8SvVxY/exec"

# Optional: đặt cùng giá trị với REPORT_SECRET trong Apps Script
# REPORT_SECRET="change-me"

EOF
    ok "Cấu hình .team-tools/weekly-report/.env ${C_DIM}· tạo mới${C_0}"
  fi

  mkdir -p "$GIT_HOOKS_DIR"
  backup=
  if [[ -f "$GIT_HOOKS_DIR/commit-msg" ]] && ! cmp -s "$TOOLS_DIR/hooks/commit-msg" "$GIT_HOOKS_DIR/commit-msg"; then
    backup="$GIT_HOOKS_DIR/commit-msg.backup.$(date +%Y%m%d%H%M%S)"
    cp "$GIT_HOOKS_DIR/commit-msg" "$backup"
  fi
  cp "$TOOLS_DIR/hooks/commit-msg" "$GIT_HOOKS_DIR/commit-msg" && chmod +x "$GIT_HOOKS_DIR/commit-msg" \
    || die "Không ghi được .git/hooks/commit-msg"
  if [[ -n "$backup" ]]; then
    ok "commit-msg hook ${C_DIM}· đã backup hook cũ: ${backup#"$REPO_DIR"/}${C_0}"
  else
    ok "commit-msg hook ${C_DIM}· prefix TASK: / BUG: / UPDATE:${C_0}"
  fi

  mkdir -p "$CLAUDE_SKILL_TARGET" "$CLAUDE_COMMANDS_TARGET" "$CODEX_SKILL_TARGET"
  cp "$TOOLS_DIR/claude-skills/weekly-report/SKILL.md" "$CLAUDE_SKILL_TARGET/SKILL.md" \
    && cp "$TOOLS_DIR/claude-commands/report.md" "$CLAUDE_COMMANDS_TARGET/report.md" \
    || die "Không ghi được skill cho Claude trong .claude/"
  ok "Claude: skill weekly-report, slash command /report"
  cp "$TOOLS_DIR/codex-skills/weekly-report/SKILL.md" "$CODEX_SKILL_TARGET/SKILL.md" \
    || die "Không ghi được skill cho Codex trong .codex/"
  ok "Codex: skill weekly-report"

  touch "$REPO_DIR/.gitignore"
  if ! grep -qxF ".team-tools/" "$REPO_DIR/.gitignore"; then
    printf '\n# ios-weekly-report\n.team-tools/\n' >> "$REPO_DIR/.gitignore"
    ok "Đã thêm .team-tools/ vào .gitignore"
  fi

  # Chỉ dọn bản cũ sau khi tool, cấu hình và skill đã được cài thành công.
  if [[ "$legacy_env_owned" == true ]]; then
    if cmp -s "$legacy_env" "$env_file"; then
      rm -f "$legacy_env" || die "Không xóa được cấu hình cũ .team-tools/.env"
      ok "Đã dọn .team-tools/.env ${C_DIM}· cấu hình đã có ở vị trí mới${C_0}"
    else
      mkdir -p "$SCRIPTS_TARGET/backups"
      env_backup="$(mktemp "$SCRIPTS_TARGET/backups/legacy.env.XXXXXX")"
      mv "$legacy_env" "$env_backup" || die "Không sao lưu được cấu hình cũ .team-tools/.env"
      ok "Đã sao lưu cấu hình cũ ${C_DIM}· ${env_backup#"$REPO_DIR"/}${C_0}"
      fix "Cấu hình đang dùng được giữ nguyên; kiểm tra bản sao lưu nếu cần lấy lại giá trị cũ."
    fi
  fi

  for legacy_name in report.py suggest_commit.py; do
    legacy_script="$TEAM_TOOLS_DIR/$legacy_name"
    case "$legacy_name" in
      report.py) signature="report.py — Tổng hợp commit cá nhân trong tuần → Google Sheets" ;;
      suggest_commit.py) signature="suggest_commit.py — Gợi ý commit message từ git diff dùng Claude AI" ;;
    esac
    if [[ -e "$legacy_script" || -L "$legacy_script" ]]; then
      if [[ -f "$legacy_script" && ! -L "$legacy_script" ]] && grep -qF "$signature" "$legacy_script"; then
        rm -f "$legacy_script" || die "Không xóa được script cũ $legacy_name"
        ok "Đã dọn script cũ ${C_DIM}· .team-tools/$legacy_name${C_0}"
      else
        warn "Giữ .team-tools/$legacy_name vì không xác định được là file của weekly-report."
        continue
      fi
    fi
    # Bản installer trước có thể đã xóa script nhưng vẫn để lại cache.
    cache_dir="$TEAM_TOOLS_DIR/__pycache__"
    if [[ -d "$cache_dir" && ! -L "$cache_dir" ]]; then
      for cache in "$cache_dir/${legacy_name%.py}."*.pyc; do
        [[ -f "$cache" && ! -L "$cache" ]] || continue
        rm -f "$cache" || die "Không xóa được cache cũ của $legacy_name"
      done
      rmdir "$cache_dir" 2>/dev/null || true
    fi
  done

  warnings=0
  if ! command -v python3 >/dev/null 2>&1; then
    bad "Chưa có Python 3. Cài bằng:"
    fix "xcode-select --install"
    warnings=$((warnings + 1))
  elif ! python3 -c 'import sys; sys.exit(sys.version_info < (3, 7))' 2>/dev/null; then
    bad "$(python3 --version 2>&1) quá cũ, report tool cần Python 3.7 trở lên."
    warnings=$((warnings + 1))
  else
    ok "$(python3 --version 2>&1)"
  fi

  author="$(git -C "$REPO_DIR" config user.name 2>/dev/null || true)"
  if [[ -n "$author" ]]; then
    ok "Git author: $author"
  else
    warn "Chưa đặt git author, report sẽ không lọc được commit của bạn. Chạy:"
    fix "git config --global user.name \"Tên của bạn\""
    warnings=$((warnings + 1))
  fi

  echo
  if (( warnings == 0 )); then
    echo "${C_GRN}${C_B}Cài đặt xong.${C_0} Để báo cáo tuần, nhập vào Claude hoặc Codex trong repo này:"
  else
    echo "${C_YEL}${C_B}Đã cài ios-weekly-report.${C_0} Xử lý $warnings mục ở trên. Để báo cáo tuần, nhập vào Claude hoặc Codex:"
  fi
  echo
  echo "    báo cáo tuần [preview] [W24] [của Nguyen Van A]"
  echo "    Vấn đề 1; Vấn đề 2"
  echo "    Plan tuần tới 1; Plan tuần tới 2"
  echo "    [Note thêm 1]"
  echo
  echo "${C_DIM}Phần trong [...] là optional.${C_0}"
  echo
  echo "${C_DIM}Chạy tay: python3 .team-tools/weekly-report/report.py --dry-run${C_0}"
}

# main chạy ở dòng cuối nên bash đọc hết file trước khi làm gì. Nhờ vậy
# `curl … | bash` không chạy dở khi tải file bị ngắt giữa chừng.
main "$@"
