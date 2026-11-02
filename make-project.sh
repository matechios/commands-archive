#!/usr/bin/env bash
if [ -z "${BASH_VERSION:-}" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

if shopt -oq posix; then
  exec /usr/bin/env bash "$0" "$@"
fi

set -euo pipefail

BASE_PROJECT_NAME="ProjMaker"
BASE_PROJECT_INFO_FILE=".base-project-info.json"
TEMPLATE_REPO="git@github.com:matechios/ProjMaker.git"

if [[ -t 1 ]]; then
  C_RED=$'\033[31m' C_YEL=$'\033[33m' C_GRN=$'\033[32m' C_BLU=$'\033[34m' C_DIM=$'\033[2m' C_B=$'\033[1m' C_0=$'\033[0m'
else
  C_RED= C_YEL= C_GRN= C_BLU= C_DIM= C_B= C_0=
fi

ok()    { echo "  ${C_GRN}✓${C_0} $*"; }
warn()  { echo "  ${C_YEL}!${C_0} $*"; }
bad()   { echo "  ${C_RED}✗${C_0} $*"; }
fix()   { echo "    ${C_DIM}$*${C_0}"; }
die()   { bad "$*"; exit 1; }
title() { echo; echo "${C_BLU}==>${C_0} ${C_B}$1${C_0}${2:+ ${C_DIM}· $2${C_0}}"; echo; }
tilde() { printf '%s' "${1/#$HOME/~}"; }

mm_ss() { printf '%d:%02d' $(($1 / 60)) $(($1 % 60)); }

# Runs a command with its output only in a log file. On a terminal it shows a
# spinner with the elapsed time instead. Sets ELAPSED, returns the exit status.
run_logged() {
  local label="$1" log="$2" pid start i=0 status=0
  shift 2
  start=$SECONDS
  "$@" > "$log" 2>&1 &
  pid=$!
  # A script's background commands ignore Ctrl+C, so pass it on.
  trap 'kill "$pid" 2>/dev/null; exit 130' INT TERM
  if [[ -t 1 ]]; then
    local -a frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    while kill -0 "$pid" 2>/dev/null; do
      printf '\r  %s %s %s' "${C_DIM}${frames[i % 10]}${C_0}" "$label" "${C_DIM}$(mm_ss $((SECONDS - start)))${C_0}"
      i=$((i + 1))
      sleep 0.1
    done
    printf '\r\033[K'
  else
    echo "  $label"
  fi
  wait "$pid" || status=$?
  trap - INT TERM
  ELAPSED="$(mm_ss $((SECONDS - start)))"
  return $status
}

prompt_required() {
  local prompt="$1"
  local value=""

  while [[ -z "$value" ]]; do
    read -r -p "  ${C_YEL}?${C_0} $prompt" value < /dev/tty || exit 1
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
  done

  printf '%s' "$value"
}

prompt_optional() {
  local prompt="$1"
  local value=""

  read -r -p "  ${C_YEL}?${C_0} $prompt" value < /dev/tty || exit 1
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"

  printf '%s' "$value"
}

normalize_dropped_path() {
  local path="$1"

  path="${path#\'}"
  path="${path%\'}"
  path="${path#\"}"
  path="${path%\"}"
  PATH_INPUT="$path" perl -CS -e 'my $path = $ENV{"PATH_INPUT"}; $path =~ s/\\(.)/$1/g; print $path;'
}

expand_path() {
  local path="$1"

  path="$(normalize_dropped_path "$path")"

  case "$path" in
    "~") printf '%s' "$HOME" ;;
    "~/"*) printf '%s/%s' "$HOME" "${path#~/}" ;;
    *) printf '%s' "$path" ;;
  esac
}

replace_project_name_in_files() {
  local target_dir="$1"
  local new_project_name="$2"

  while IFS= read -r -d '' file; do
    if LC_ALL=C grep -Iq "$BASE_PROJECT_NAME" "$file"; then
      OLD_PROJECT_NAME="$BASE_PROJECT_NAME" NEW_PROJECT_NAME="$new_project_name" \
        perl -0pi -e 's/\Q$ENV{OLD_PROJECT_NAME}\E/$ENV{NEW_PROJECT_NAME}/g' "$file"
    fi
  done < <(find "$target_dir" -type f \
    -not -path '*/.git/*' \
    -not -path '*/Pods/*' \
    -not -path '*/build/*' \
    -not -path '*/DerivedData/*' \
    -not -path '*/scripts/make-project.sh' \
    -not -name "$BASE_PROJECT_INFO_FILE" \
    -print0)
}

rename_project_paths() {
  local target_dir="$1"
  local new_project_name="$2"

  while IFS= read -r -d '' path; do
    local dir
    local name
    local new_name

    dir="$(dirname "$path")"
    name="$(basename "$path")"
    new_name="${name//$BASE_PROJECT_NAME/$new_project_name}"

    if [[ "$name" != "$new_name" ]]; then
      mv "$path" "$dir/$new_name"
    fi
  done < <(find "$target_dir" -depth -name "*$BASE_PROJECT_NAME*" -print0)
}

clone_project_template() {
  local target_dir="$1"

  # Output goes to a log behind a spinner, so ssh must fail instead of prompting.
  GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes}" git clone --depth 1 "$TEMPLATE_REPO" "$target_dir"
  rm -rf \
    "$target_dir/.git" \
    "$target_dir/.claude" \
    "$target_dir/.github/workflows/command_archive.yml" \
    "$target_dir/Pods" \
    "$target_dir/Podfile.lock" \
    "$target_dir/DerivedData" \
    "$target_dir/build"
  find "$target_dir" \( -name '.DS_Store' -o -name '*.xcuserstate' \) -type f -delete
  find "$target_dir" -type d -name 'xcuserdata' -prune -exec rm -rf {} +
}

rename_project() {
  local target_dir="$1"
  local new_project_name="$2"

  rename_project_paths "$target_dir" "$new_project_name"
  replace_project_name_in_files "$target_dir" "$new_project_name"
  write_base_project_info "$target_dir"
}

install_pods() {
  cd "$1" && pod install
}

write_base_project_info() {
  local target_dir="$1"
  local info_path="$target_dir/$BASE_PROJECT_INFO_FILE"
  local generated_at

  generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  if [[ ! -f "$info_path" ]]; then
    cat > "$info_path" <<EOF
{
  "baseProject": "$BASE_PROJECT_NAME",
  "baseVersion": "unknown",
  "changeLogs": [],
  "generatedAt": "$generated_at"
}
EOF
    return
  fi

  GENERATED_AT="$generated_at" perl -0pi -e 's/"generatedAt"\s*:\s*(null|"[^"]*")/"generatedAt": "$ENV{GENERATED_AT}"/' "$info_path"
}

main() {
  local new_project_name
  local output_parent_input
  local output_parent
  local output_parent_abs
  local target_dir
  local workspace_path
  local base_version
  local log_dir
  local warnings=0

  title "Tạo project iOS từ template $BASE_PROJECT_NAME"

  { : < /dev/tty; } 2>/dev/null || die "Cần chạy script trong Terminal để nhập thông tin project."
  command -v git >/dev/null 2>&1 || die "Chưa có git. Cài Xcode Command Line Tools rồi chạy lại: xcode-select --install"

  new_project_name="$(prompt_required "Tên project: ")"
  [[ "$new_project_name" =~ ^[A-Za-z][A-Za-z0-9]*$ ]] \
    || die "Tên project chỉ gồm chữ/số và bắt đầu bằng chữ (hợp lệ cho Swift module, target, bundle id)."

  output_parent_input="$(prompt_optional "Thư mục chứa project ${C_DIM}(Enter: thư mục hiện tại)${C_0}: ")"
  if [[ -z "$output_parent_input" ]]; then
    output_parent="."
  else
    output_parent="$(expand_path "$output_parent_input")"
  fi

  mkdir -p "$output_parent" 2>/dev/null || die "Không tạo được thư mục $(tilde "$output_parent")"
  output_parent_abs="$(cd "$output_parent" && pwd -P)"
  target_dir="$output_parent_abs/$new_project_name"
  workspace_path="$target_dir/$new_project_name.xcworkspace"
  [[ ! -e "$target_dir" ]] || die "Đã tồn tại: $(tilde "$target_dir")"

  title "Tạo $new_project_name" "$(tilde "$target_dir")"
  log_dir="$(mktemp -d -t make-project)"

  if ! run_logged "Đang clone template…" "$log_dir/clone.log" clone_project_template "$target_dir"; then
    bad "Không clone được $TEMPLATE_REPO. Log: $log_dir/clone.log"
    fix "Kiểm tra quyền truy cập GitHub bằng SSH: ssh -T git@github.com"
    exit 1
  fi
  base_version="$(sed -n 's/.*"baseVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$target_dir/$BASE_PROJECT_INFO_FILE" 2>/dev/null | head -1)"
  ok "Template $BASE_PROJECT_NAME${base_version:+ $base_version} ${C_DIM}· $ELAPSED${C_0}"

  run_logged "Đang đổi tên project…" "$log_dir/rename.log" rename_project "$target_dir" "$new_project_name" \
    || die "Đổi tên project lỗi. Log: $log_dir/rename.log"
  ok "Đổi tên $BASE_PROJECT_NAME → $new_project_name ${C_DIM}· $ELAPSED${C_0}"

  if [[ "${SCAFFOLD_SKIP_POD_INSTALL:-}" == "1" ]]; then
    warn "Bỏ qua pod install ${C_DIM}· SCAFFOLD_SKIP_POD_INSTALL=1${C_0}"
  elif [[ ! -f "$target_dir/Podfile" ]]; then
    :
  elif ! command -v pod >/dev/null 2>&1; then
    warn "Chưa có CocoaPods. Cài CocoaPods rồi chạy:"
    fix "cd \"$(tilde "$target_dir")\" && pod install"
    warnings=$((warnings + 1))
  elif run_logged "Đang chạy pod install…" "$log_dir/pod.log" install_pods "$target_dir"; then
    ok "pod install ${C_DIM}· $ELAPSED${C_0}"
  else
    bad "pod install lỗi. Log: $log_dir/pod.log"
    fix "cd \"$(tilde "$target_dir")\" && pod install"
    warnings=$((warnings + 1))
  fi

  if [[ -d "$workspace_path" ]]; then
    open "$workspace_path"
    ok "Đã mở $new_project_name.xcworkspace"
  else
    warn "Không có $new_project_name.xcworkspace để mở"
    warnings=$((warnings + 1))
  fi

  echo
  if (( warnings == 0 )); then
    rm -rf "$log_dir"
    echo "${C_GRN}${C_B}Tạo project xong.${C_0} Đọc ${C_B}README.md${C_0} trước khi bắt đầu code."
  else
    echo "${C_YEL}${C_B}Đã tạo project.${C_0} Xử lý $warnings mục ở trên, rồi đọc ${C_B}README.md${C_0} trước khi code."
  fi
  echo "  ${C_DIM}$(tilde "$target_dir")${C_0}"
}

main "$@"
