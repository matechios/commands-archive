#!/bin/bash
# Install fb-build on this Mac: write the command into ~/.local/bin and
# check the tools it needs. The tool is embedded at the end of this file, so
# this file is all a dev needs; run a newer copy of it to update.
#   ./fb-build-installer.sh [bin_dir]
#
# Also works piped: curl -s <url> | bash
#
# Do not edit the tool_body heredoc: scripts/build-installer.sh regenerates it
# from bin/fb-build.
set -euo pipefail

# Lark webhooks per Apple team, published next to this installer by the sync
# workflow, encrypted with the team password (secret LARK_WEBHOOKS_PW).
# fb-build reads the decrypted copy from LARK_TARGET after an upload.
LARK_URL="${FB_BUILD_LARK_URL:-https://raw.githubusercontent.com/matechios/commands-archive/main/fb-build-lark-webhooks.json.enc}"
LARK_TARGET="${FB_BUILD_LARK_WEBHOOKS:-$HOME/.config/fb-build/fb-build-lark-webhooks.json}"

main() {
  BIN_DIR="${1:-$HOME/.local/bin}"
  TARGET="$BIN_DIR/fb-build"

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

  VERSION="$(tool_body | sed -n 's/^TOOL_VERSION=//p' | head -1)"
  [[ -n "$VERSION" ]] || die "File cài đặt bị lỗi: không có tool đi kèm. Tải lại file cài đặt."

  echo
  echo "${C_BLU}==>${C_0} ${C_B}Cài đặt fb-build $VERSION${C_0}"
  echo

  previous=
  [[ ! -x "$TARGET" ]] || previous="$("$TARGET" --version 2>/dev/null | sed 's/^fb-build //' || true)"
  mkdir -p "$BIN_DIR" 2>/dev/null || die "Không tạo được thư mục $BIN_DIR"
  tool_body > "$TARGET.tmp" && chmod +x "$TARGET.tmp" && mv -f "$TARGET.tmp" "$TARGET" \
    || die "Không ghi được $TARGET"
  if [[ -n "$previous" && "$previous" != "$VERSION" ]]; then
    ok "fb-build: cập nhật $previous → $VERSION"
  else
    ok "fb-build $VERSION"
  fi

  install_lark_webhooks

  # What the dev still has to do, in order, as "command<TAB>note[<TAB>option]".
  # The note marks the steps done once; the option line is printed below.
  todo=()
  once="chỉ làm 1 lần"
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
      # Add BIN_DIR to the shell's startup file. That cannot reach the
      # Terminal running this installer, so the dev still opens a new one.
      path_dir="${BIN_DIR/#$HOME/\$HOME}"
      case "${SHELL##*/}" in
        zsh)  rc="$HOME/.zshrc" ;;
        bash) rc="$HOME/.bash_profile" ;;
        *)    rc= ;;
      esac
      if [[ -n "$rc" ]] && grep -qsF -e "$BIN_DIR" -e "$path_dir" "$rc"; then
        ok "PATH: ${rc/#$HOME/~} đã có ${BIN_DIR/#$HOME/~}"
        todo+=("Mở Terminal mới (hoặc chạy: exec ${SHELL##*/})"$'\t'"$once")
      elif [[ -n "$rc" ]] && printf '\n# fb-build\nexport PATH="%s:$PATH"\n' "$path_dir" >> "$rc"; then
        ok "PATH: đã thêm ${BIN_DIR/#$HOME/~} vào ${rc/#$HOME/~}"
        todo+=("Mở Terminal mới (hoặc chạy: exec ${SHELL##*/})"$'\t'"$once")
      else
        warn "${BIN_DIR/#$HOME/~} chưa có trong PATH"
        todo+=("Thêm vào file cấu hình shell: export PATH=\"$path_dir:\$PATH\", rồi mở Terminal mới"$'\t'"$once")
      fi
      ;;
  esac

  xcodes="$("$TARGET" xcodes 2>/dev/null | sed -n 's/^  [* ] \([^ ]*\) .*/\1/p' | paste -sd, - | sed 's/,/, /g')"
  if [[ -z "$xcodes" ]]; then
    bad "Chưa cài Xcode"
    todo=("Cài Xcode từ App Store rồi chạy lại lệnh cài đặt này"$'\t'"$once" ${todo[@]+"${todo[@]}"})
  else
    ok "Xcode $xcodes"
  fi

  # Ask on the terminal: under curl | bash, stdin is the script.
  if ! command -v firebase >/dev/null 2>&1 && command -v brew >/dev/null 2>&1 \
    && { exec 3</dev/tty; } 2>/dev/null; then
    answer=
    read -r -p "  ${C_YEL}?${C_0} Chưa có Firebase CLI. Cài bằng Homebrew? [Y/n] " answer <&3 || true
    exec 3<&-
    if [[ ! "$answer" =~ ^[Nn] ]]; then
      log="$(mktemp -t fb-build-brew)"
      if spin "Đang cài Firebase CLI…" "$log" brew install firebase-cli; then
        rm -f "$log"
      else
        bad "Cài Firebase CLI lỗi. Log: $log"
      fi
    fi
  fi
  login="firebase login"$'\t'"$once, đăng nhập tài khoản Google có quyền App Distribution"
  if command -v firebase >/dev/null 2>&1; then
    account="$(firebase login:list --json 2>/dev/null | plutil -extract result.0.user.email raw -o - - 2>/dev/null || true)"
    if [[ -n "$account" ]]; then
      ok "Firebase CLI $(firebase --version 2>/dev/null) · $account"
    else
      warn "Firebase CLI chưa đăng nhập"
      todo+=("$login")
    fi
  else
    bad "Chưa có Firebase CLI"
    if command -v brew >/dev/null 2>&1; then
      todo+=("brew install firebase-cli"$'\t'"$once")
    else
      todo+=("curl -sL https://firebase.tools | bash"$'\t'"$once, cài Firebase CLI")
    fi
    todo+=("$login")
  fi
  xcode_opt="--xcode VERSION   chọn Xcode để build, mặc định bản Xcode đang dùng"
  [[ -z "$xcodes" ]] || xcode_opt+=" (đã cài: $xcodes)"
  todo+=("Trong thư mục repo app: fb-build init"$'\t'"chỉ làm 1 lần cho mỗi repo"$'\t'"$xcode_opt")

  echo
  if (( ${#todo[@]} == 1 )); then
    echo "${C_GRN}${C_B}Cài đặt xong.${C_0}"
  else
    echo "${C_YEL}${C_B}Đã cài fb-build.${C_0}"
  fi
  echo "${C_B}Tiếp theo:${C_0}"
  n=0
  for item in "${todo[@]}"; do
    n=$((n + 1))
    IFS=$'\t' read -r cmd note opt <<< "$item"
    echo "  $n. ${C_B}$cmd${C_0} ${C_DIM}($note)${C_0}"
    [[ -z "$opt" ]] || echo "     $opt"
  done
}

# Downloads the encrypted Lark webhooks and decrypts them into LARK_TARGET with
# the team password: FB_BUILD_LARK_PW, else the one saved by an earlier run,
# else asked on the terminal and saved. Keeps the old copy when anything fails:
# builds still upload then, without a Lark message.
install_lark_webhooks() {
  local dir key enc out pw tries=0 teams
  dir="$(dirname "$LARK_TARGET")"
  key="$dir/lark-webhooks.key"
  enc="$(mktemp -t fb-build-lark)"
  out="$(mktemp -t fb-build-lark)"
  if ! curl -fsSL --max-time 15 "$LARK_URL" -o "$enc" 2>/dev/null; then
    rm -f "$enc" "$out"
    lark_skipped "Không tải được Lark webhooks"
    return 0
  fi
  pw="${FB_BUILD_LARK_PW:-}"
  [[ -n "$pw" || ! -f "$key" ]] || pw="$(cat "$key")"
  while ! decrypt_lark "$pw" "$enc" "$out"; do
    [[ -z "$pw" ]] || warn "Mật khẩu Lark webhooks không đúng"
    pw=
    # Ask on the terminal: under curl | bash, stdin is the script.
    if (( tries++ < 3 )) && { exec 3</dev/tty; } 2>/dev/null; then
      read -rs -p "  ${C_YEL}?${C_0} Mật khẩu Lark webhooks (hỏi team lead): " pw <&3 || true
      exec 3<&-
      echo >&2
    fi
    if [[ -z "$pw" ]]; then
      rm -f "$enc" "$out"
      lark_skipped "Chưa có mật khẩu Lark webhooks. Chạy lại installer trong Terminal"
      return 0
    fi
  done
  rm -f "$enc"
  mkdir -p "$dir"
  (umask 077; printf '%s' "$pw" > "$key")
  # mktemp made it 0600, so the webhooks stay readable by this user only.
  mv -f "$out" "$LARK_TARGET"
  teams="$(plutil -convert xml1 -o - "$LARK_TARGET" | grep -c '<key>webhook</key>' || true)"
  ok "Lark webhooks: $teams team id"
}

# Same cipher as the sync workflow. The password goes through the environment,
# not the command line, so ps does not show it.
decrypt_lark() {
  [[ -n "$1" ]] || return 1
  LARK_PW="$1" /usr/bin/openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -md sha256 -a -A \
    -pass env:LARK_PW -in "$2" -out "$3" 2>/dev/null \
    && plutil -convert xml1 -o /dev/null "$3" 2>/dev/null
}

# Runs a command with its output only in a log file, showing a spinner and the
# elapsed time before the label meanwhile. Returns the command's exit status.
spin() {
  local label="$1" log="$2" pid start=$SECONDS i=0 status=0
  local -a frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  shift 2
  "$@" > "$log" 2>&1 &
  pid=$!
  # A script's background commands ignore Ctrl+C, so pass it on.
  trap 'kill "$pid" 2>/dev/null; exit 130' INT TERM
  if [[ -t 1 ]]; then
    while kill -0 "$pid" 2>/dev/null; do
      printf '\r  %s %s %s' "${C_DIM}${frames[i % 10]}${C_0}" "$label" \
        "${C_DIM}$(( (SECONDS - start) / 60 )):$(printf '%02d' $(( (SECONDS - start) % 60 )))${C_0}"
      i=$((i + 1))
      sleep 0.1
    done
    printf '\r\033[K'
  else
    echo "  $label"
  fi
  wait "$pid" || status=$?
  trap - INT TERM
  return $status
}

lark_skipped() {
  if [[ -f "$LARK_TARGET" ]]; then
    warn "$1. Giữ Lark webhooks cũ ở ${LARK_TARGET/#$HOME/~}"
  else
    warn "$1. Build vẫn chạy nhưng không gửi thông báo Lark"
  fi
}

# The tool is a quoted heredoc inside a function and main runs on the last line,
# so bash parses the whole file before doing anything. That is what makes
# `curl … | bash` work: there is no file on disk to read the tool back from.
tool_body() {
cat <<'__FB_BUILD_TOOL__'
#!/bin/bash
# fb-build: archive the iOS app in the current git repo on this Mac and
# upload it to Firebase App Distribution. The archive is signed the way the
# project is set up in Xcode; the .ipa is exported like Distribute App → Custom
# → Release Testing with manual signing, using the release-testing (ad hoc)
# profiles and Apple Distribution certificate installed on this Mac, so the
# export does not need an Apple account. The upload uses the account from
# `firebase login`, and the build goes to every tester group of the Firebase
# project and to the testers listed in the config. Only committed code is built.
#
#   fb-build [options]          check, build and upload
#   fb-build init [options]     create .team-tools/fb-build.json for this repo
#   fb-build xcodes             list the installed Xcode versions
#   fb-build --version          print the tool version
#
# Settings live in .team-tools/fb-build.json in the app repo, one per Mac
# (.team-tools is usually git-ignored), written by `fb-build init`. Build
# output goes to ~/Library/Developer/fb-build/<owner>/<repo>/<timestamp>/.
# The build itself runs in a git worktree of HEAD next to it (src/) with its
# own DerivedData, so Xcode can keep working on the repo in the meantime.
# After the upload, a Lark Base automation webhook is notified, picked by the
# app's team ID from ~/.config/fb-build/fb-build-lark-webhooks.json
# ({"<team id>": {"name": ..., "webhook": "https://..."}}), which the installer
# downloads encrypted and decrypts with the team password.
# Works with the bash 3.2 that ships with macOS.
set -euo pipefail

# Bump TOOL_VERSION for every release.
TOOL_VERSION=1.0.1
CONFIG_NAME=.team-tools/fb-build.json
OUT_ROOT="${FB_BUILD_HOME:-$HOME/Library/Developer/fb-build}"
KEEP_RUNS=5
FIREBASE="${FIREBASE_BIN:-firebase}"
PLISTBUDDY=/usr/libexec/PlistBuddy
LARK_WEBHOOKS="${FB_BUILD_LARK_WEBHOOKS:-$HOME/.config/fb-build/fb-build-lark-webhooks.json}"
KNOWN_KEYS="scheme workspace project configuration firebase_plist export_options_plist xcode testers"
# Xcode 16 keeps provisioning profiles in the first, older Xcodes in the second.
PROFILE_DIRS=("$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles" "$HOME/Library/MobileDevice/Provisioning Profiles")

if [[ -t 1 ]]; then
  C_RED=$'\033[31m' C_YEL=$'\033[33m' C_GRN=$'\033[32m' C_DIM=$'\033[2m' C_B=$'\033[1m' C_0=$'\033[0m'
else
  C_RED= C_YEL= C_GRN= C_DIM= C_B= C_0=
fi

PROBLEMS=0
fail() { echo "${C_RED}✗ $*${C_0}" >&2; exit 1; }
ok()   { echo "  ${C_GRN}✓${C_0} $*"; }
warn() { echo "  ${C_YEL}!${C_0} $*"; }
bad()  { echo "  ${C_RED}✗${C_0} $*"; PROBLEMS=$((PROBLEMS + 1)); }
hint() { echo "${C_YEL}→ $*${C_0}" >&2; }
step() { echo; echo "${C_B}== $*${C_0}"; }
next_step() { echo; echo "${C_B}Tiếp theo:${C_0} $*"; }

usage() {
  cat <<'EOF'
Build app iOS trong repo hiện tại và upload lên Firebase App Distribution.

  fb-build [tùy chọn]         kiểm tra, build, upload
  fb-build init [tùy chọn]    tạo .team-tools/fb-build.json cho repo
  fb-build xcodes             liệt kê các bản Xcode đã cài
  fb-build --version          in phiên bản của tool

Tùy chọn khi build:
  -m, --message TEXT      ghi chú cho tester trong release notes
  -v, --app-version X     version của bản build (MARKETING_VERSION), vd 1.2.0
  -b, --build-number N    build number (CURRENT_PROJECT_VERSION), vd 42
                          Mặc định: theo project. Không sửa file nào trong repo.
      --dry-run           chỉ kiểm tra và in release notes dự kiến, không build

Tùy chọn của init:
      --scheme X          scheme
      --plist PATH        GoogleService-Info*.plist dùng để upload
      --xcode X           Xcode dùng để build, theo đúng version (16.4; 27 là 27.0)
                          hoặc đường dẫn .app (xem: fb-build xcodes).
                          Mặc định: Xcode đang chọn
  Build luôn dùng Xcode ghi trong config. Chạy lại init sẽ ghi đè config đã có.

Build được gửi cho tất cả nhóm tester của Firebase project và các tester trong
"testers" của config (init ghi vào đó mọi tester của project).
Release notes luôn kèm một dòng branch, commit, author và configuration.
EOF
}

# ---------------------------------------------------------------------------
# Arguments
# ---------------------------------------------------------------------------
CMD=run
case "${1:-}" in
  init) CMD=init; shift ;;
  xcodes) CMD=xcodes; shift ;;
  -V | --version | version) echo "fb-build $TOOL_VERSION"; exit 0 ;;
esac

OPT_MESSAGE= OPT_XCODE= DRY_RUN=false
OPT_APP_VERSION= OPT_BUILD_NUMBER=
OPT_SCHEME= OPT_PLIST=

need_arg() { [[ $# -ge 2 ]] || fail "Thiếu giá trị cho $1"; }
bad_arg() { fail "Tham số không hợp lệ: $1 (xem fb-build --help)"; }
while (($#)); do
  case "$CMD:$1" in
    *:-V | *:--version) echo "fb-build $TOOL_VERSION"; exit 0 ;;
    *:-h | *:--help) usage; exit 0 ;;
    run:-m | run:--message) need_arg "$@"; OPT_MESSAGE="$2"; shift 2 ;;
    run:--dry-run) DRY_RUN=true; shift ;;
    run:-v | run:--app-version) need_arg "$@"; OPT_APP_VERSION="$2"; shift 2 ;;
    run:-b | run:--build-number) need_arg "$@"; OPT_BUILD_NUMBER="$2"; shift 2 ;;
    init:--scheme) need_arg "$@"; OPT_SCHEME="$2"; shift 2 ;;
    init:--plist) need_arg "$@"; OPT_PLIST="$2"; shift 2 ;;
    init:--xcode) need_arg "$@"; OPT_XCODE="$2"; shift 2 ;;
    *) bad_arg "$1" ;;
  esac
done

# App Store Connect rules: up to three period-separated integers.
version_re='^[0-9]+(\.[0-9]+){0,2}$'
[[ -z "$OPT_APP_VERSION" || "$OPT_APP_VERSION" =~ $version_re ]] \
  || fail "--app-version phải là tối đa 3 số cách nhau bởi dấu chấm, vd 1.2.0 (nhận: $OPT_APP_VERSION)"
[[ -z "$OPT_BUILD_NUMBER" || "$OPT_BUILD_NUMBER" =~ $version_re ]] \
  || fail "--build-number phải là số, hoặc tối đa 3 số cách nhau bởi dấu chấm, vd 42 (nhận: $OPT_BUILD_NUMBER)"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
xml_strings() { sed -n 's|^.*<string>\(.*\)</string>.*$|\1|p' | sed 's/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g'; }
strip_ansi() { sed -E $'s/\033\\[[0-9;]*[A-Za-z]//g'; }
plist_get() { "$PLISTBUDDY" -c "Print :$1" "$2" 2>/dev/null; }

goto_repo_root() {
  TOP="$(git rev-parse --show-toplevel 2>/dev/null)" || fail "Thư mục hiện tại không nằm trong git repo. Chạy lệnh từ repo của app."
  cd "$TOP"
  CONFIG="$TOP/$CONFIG_NAME"
}

# Read a string from the config.
cfg_str() {
  local type
  type="$(plutil -type "$1" "$CONFIG" 2>/dev/null)" || return 0
  [[ "$type" == string ]] || fail "$CONFIG_NAME: \"$1\" phải là chuỗi"
  plutil -extract "$1" raw -o - "$CONFIG"
}

load_config() {
  plutil -convert xml1 -o /dev/null "$CONFIG" 2>/dev/null \
    || fail "$CONFIG_NAME không phải JSON hợp lệ (lưu ý: không dùng null)"
  local key
  for key in $(plutil -convert xml1 -o - "$CONFIG" | sed -n $'s|^\t<key>\\(.*\\)</key>$|\\1|p'); do
    [[ " $KNOWN_KEYS " == *" $key "* ]] || warn "$CONFIG_NAME: bỏ qua khóa không biết \"$key\""
  done
  CFG_SCHEME="$(cfg_str scheme)"
  CFG_WORKSPACE="$(cfg_str workspace)"
  CFG_PROJECT="$(cfg_str project)"
  CFG_CONFIGURATION="$(cfg_str configuration)"
  CFG_PLIST="$(cfg_str firebase_plist)"
  CFG_EXPORT_OPTIONS="$(cfg_str export_options_plist)"
  CFG_XCODE="$(cfg_str xcode)"
  CFG_TESTERS="$(cfg_str testers)"
}

# Installed Xcode apps as "<version><TAB><path>", newest first.
list_xcodes() {
  local app v
  { mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" 2>/dev/null; ls -d /Applications/Xcode*.app 2>/dev/null; } \
    | grep -v '/\.Trash/' | awk '!seen[$0]++' \
    | while IFS= read -r app; do
        [[ -x "$app/Contents/Developer/usr/bin/xcodebuild" ]] || continue
        v="$(plist_get CFBundleShortVersionString "$app/Contents/Info.plist")" || continue
        printf '%s\t%s\n' "$v" "$app"
      done | sort -t$'\t' -k1,1rV
}

# Xcode that xcodebuild uses without --xcode: DEVELOPER_DIR, then xcode-select.
default_developer_dir() { echo "${DEVELOPER_DIR:-$(xcode-select -p 2>/dev/null)}"; }

# Sets DEVELOPER_DIR from --xcode of init, or else "xcode" in the config: a
# version picks the installed Xcode with exactly that version ("27" is 27.0,
# not the newest 27.x), anything else is the path of an Xcode app. With
# neither, keeps the default Xcode, or the newest one when the default is the
# Command Line Tools.
select_xcode() {
  local want="${OPT_XCODE:-${CFG_XCODE:-}}" source="--xcode" app installed
  [[ -n "$OPT_XCODE" ]] || source="\"xcode\" trong $CONFIG_NAME; đổi bằng: fb-build init --xcode <version>"
  installed="$(list_xcodes)"
  if [[ -z "$installed" ]] && ! xcodebuild -version >/dev/null 2>&1; then
    bad "Chưa cài Xcode. Cài Xcode từ App Store rồi chạy lại."
    return 1
  fi
  if [[ -z "$want" ]]; then
    xcodebuild -version >/dev/null 2>&1 && return 0
    app="$(cut -f2 <<< "$installed" | sed -n 1p)"
    [[ -n "$app" ]] || return 0
  elif [[ "$want" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
    app="$(awk -F'\t' -v w="$(trim_version "$want")" '
      { v = $1; while (v ~ /\.0$/) v = substr(v, 1, length(v) - 2) }
      v == w { print $2; exit }' <<< "$installed")"
    if [[ -z "$app" ]]; then
      bad "Không có Xcode $want ($source). Các bản đã cài: $(cut -f1 <<< "$installed" | paste -sd, - | sed 's/,/, /g')"
      return 1
    fi
  else
    app="${want%/}"
    if [[ ! -x "$app/Contents/Developer/usr/bin/xcodebuild" ]]; then
      bad "Không tìm thấy Xcode tại $app ($source)"
      return 1
    fi
  fi
  export DEVELOPER_DIR="$app/Contents/Developer"
}

# "27.0.0" -> "27", "16.4.0" -> "16.4": equal versions compare equal.
trim_version() { sed -E 's/(\.0)+$//' <<< "$1"; }

# "16.4" from XCODE_VERSION ("Xcode 16.4").
xcode_version() { sed -n 's/^Xcode \([0-9.]*\).*/\1/p' <<< "$XCODE_VERSION"; }

check_xcode() {
  if XCODE_VERSION="$(xcodebuild -version 2>/dev/null | sed -n 1p)" && [[ -n "$XCODE_VERSION" ]]; then
    ok "$XCODE_VERSION ($(default_developer_dir | sed 's|/Contents/Developer$||'))"
    return 0
  fi
  bad "xcodebuild không chạy được. Chọn Xcode khác: fb-build init --xcode <version>"
  return 1
}

# List *.xcworkspace / *.xcodeproj near the repo root, skipping Pods and the
# project.xcworkspace inside every .xcodeproj.
find_containers() {
  find . -maxdepth 2 -name "*.$1" -not -path "*/Pods/*" -not -path "*.xcodeproj/*" -not -path "./.git/*" \
    | sed 's|^\./||' | sort
}

# Sets WORKSPACE or PROJECT and CONTAINER. Returns 1 with a message when ambiguous.
detect_container() {
  WORKSPACE="${CFG_WORKSPACE:-}" PROJECT="${CFG_PROJECT:-}"
  if [[ -z "$WORKSPACE$PROJECT" ]]; then
    local workspaces projects
    workspaces="$(find_containers xcworkspace)"
    projects="$(find_containers xcodeproj)"
    if [[ -n "$workspaces" && $(wc -l <<< "$workspaces") -eq 1 ]]; then
      WORKSPACE="$workspaces"
    elif [[ -z "$workspaces" && -n "$projects" && $(wc -l <<< "$projects") -eq 1 ]]; then
      PROJECT="$projects"
    else
      bad "Không tự chọn được workspace/project, khai báo \"workspace\" hoặc \"project\" trong $CONFIG_NAME"
      return 1
    fi
  fi
  if [[ -n "$WORKSPACE" ]]; then
    [[ -d "$WORKSPACE" ]] || { bad "Không tìm thấy workspace $WORKSPACE"; return 1; }
    CONTAINER=(-workspace "$WORKSPACE")
  else
    [[ -d "$PROJECT" ]] || { bad "Không tìm thấy project $PROJECT"; return 1; }
    CONTAINER=(-project "$PROJECT")
  fi
}

# Prints the schemes of CONTAINER, without Pods schemes.
list_schemes() {
  local json
  json="$(mktemp -t fb-build-list)"
  xcodebuild -list -json "${CONTAINER[@]}" > "$json" 2>/dev/null || true
  { plutil -extract workspace.schemes xml1 -o - "$json" 2>/dev/null \
      || plutil -extract project.schemes xml1 -o - "$json" 2>/dev/null; } \
    | xml_strings | grep -v '^Pods' | awk '!seen[$0]++' || true
  rm -f "$json"
}

# Scheme named after the workspace/project, or the only scheme.
guess_scheme() {
  local schemes name
  schemes="$(list_schemes)"
  name="$(basename "${WORKSPACE:-$PROJECT}")"
  name="${name%.*}"
  if grep -qxF "$name" <<< "$schemes"; then
    echo "$name"
  elif [[ -n "$schemes" && $(wc -l <<< "$schemes") -eq 1 ]]; then
    echo "$schemes"
  else
    echo "$schemes" >&2
    return 1
  fi
}

# GoogleService-Info*.plist files in the source tree (including git-ignored ones).
find_firebase_plists() {
  find . -name "GoogleService-Info*.plist" -type f \
    -not -path "./.git/*" -not -path "*/Pods/*" -not -path "*/build/*" -not -path "*/DerivedData/*" \
    -not -path "*/.build/*" -not -path "*/Carthage/*" -not -path "*.xcarchive/*" \
    | sed 's|^\./||' | sort
}

# Interactive pick from a list when stdin is a terminal.
choose() {
  local prompt="$1"; shift
  local PS3="$prompt: " item
  select item in "$@"; do
    [[ -n "$item" ]] && { echo "$item"; return 0; }
  done
  return 1
}

repo_key() {
  local origin
  origin="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -n "$origin" ]]; then
    sed -E 's#\.git$##; s#/+$##; s#^.*[:/]([^/:]+/[^/:]+)$#\1#' <<< "$origin"
  else
    echo "local/$(basename "$TOP")"
  fi | tr -c 'A-Za-z0-9._/\n-' '_'
}

# Runs a firebase command with --json; sets FB_RESULT (file) and FB_ERROR.
firebase_json() {
  FB_RESULT="$(mktemp -t fb-build-fb)"
  FB_ERROR=
  if "$FIREBASE" "$@" --json --non-interactive > "$FB_RESULT" 2>/dev/null \
    && [[ "$(plutil -extract status raw -o - "$FB_RESULT" 2>/dev/null)" == success ]]; then
    return 0
  fi
  FB_ERROR="$(plutil -extract error raw -o - "$FB_RESULT" 2>/dev/null || strip_ansi < "$FB_RESULT" | tail -5)"
  return 1
}

# ---------------------------------------------------------------------------
# Signing for export: release-testing (ad hoc) profiles installed on this Mac
# ---------------------------------------------------------------------------
# Valid code signing identities in the keychain as "<SHA-1><TAB><name>".
signing_identities() {
  security find-identity -v -p codesigning 2>/dev/null \
    | awk 'length($2) == 40 { sha = $2; sub(/^[^"]*"/, ""); sub(/"[^"]*$/, ""); print sha "\t" $0 }'
}

# Release-testing profiles that have not expired and include a certificate
# whose private key is in the keychain, newest first, one per line:
# <team> <TAB> <bundle id or wildcard> <TAB> <created> <TAB> <uuid> <TAB> <name> <TAB> <SHA-1,...>
# Development profiles allow get-task-allow; enterprise ones list no devices.
list_release_profiles() {
  local identities now dir f tmp i cert certs appid
  identities="$(signing_identities | cut -f1)"
  [[ -n "$identities" ]] || return 0
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  tmp="$(mktemp -t fb-build-profile)"
  for dir in "${PROFILE_DIRS[@]}"; do
    for f in "$dir"/*.mobileprovision; do
      [[ -f "$f" ]] && security cms -D -i "$f" > "$tmp" 2>/dev/null || continue
      [[ "$(plutil -type ProvisionedDevices "$tmp" 2>/dev/null)" == array ]] || continue
      [[ "$(plutil -extract Entitlements.get-task-allow raw -o - "$tmp" 2>/dev/null)" != true ]] || continue
      [[ "$(plutil -extract ExpirationDate raw -o - "$tmp" 2>/dev/null)" > "$now" ]] || continue
      certs= i=0
      while cert="$(plutil -extract "DeveloperCertificates.$i" raw -o - "$tmp" 2>/dev/null)"; do
        cert="$(base64 -D <<< "$cert" | shasum -a 1 | cut -d' ' -f1 | tr a-f A-F)"
        ! grep -qxF "$cert" <<< "$identities" || certs="${certs:+$certs,}$cert"
        i=$((i + 1))
      done
      [[ -n "$certs" ]] || continue
      appid="$(plutil -extract Entitlements.application-identifier raw -o - "$tmp" 2>/dev/null)" || continue
      printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$(plutil -extract TeamIdentifier.0 raw -o - "$tmp" 2>/dev/null)" "${appid#*.}" \
        "$(plutil -extract CreationDate raw -o - "$tmp" 2>/dev/null)" \
        "$(plutil -extract UUID raw -o - "$tmp" 2>/dev/null)" \
        "$(plutil -extract Name raw -o - "$tmp" 2>/dev/null)" "$certs"
    done
  done | sort -t$'\t' -k3,3r | awk -F'\t' '!seen[$4]++'
  rm -f "$tmp"
}

# The profile line from PROFILES to use for bundle id $1, limited to team $2
# and certificate $3 when given: an explicit App ID before a wildcard one,
# then the newest.
pick_profile() {
  awk -F'\t' -v b="$1" -v t="$2" -v c="$3" '
    (t == "" || $1 == t) && (c == "" || index("," $6 ",", "," c ",")) {
      if ($2 == b) { print; found = 1; exit }
      p = substr($2, 1, length($2) - 1)
      if (wild == "" && substr($2, length($2)) == "*" && substr(b, 1, length(p)) == p) wild = $0
    }
    END { if (!found && wild != "") print wild }' <<< "$PROFILES"
}

check_signing() {
  if [[ -n "$CFG_EXPORT_OPTIONS" ]]; then
    if [[ -f "$CFG_EXPORT_OPTIONS" ]]; then
      ok "Export: theo $CFG_EXPORT_OPTIONS"
    else
      bad "Không tìm thấy $CFG_EXPORT_OPTIONS (\"export_options_plist\" trong $CONFIG_NAME)"
    fi
    return
  fi
  PROFILES="$(list_release_profiles)"
  if [[ -z "$PROFILES" ]]; then
    bad "Không có profile Ad Hoc hợp lệ."
    return
  fi
  # The app's own bundle ids are known only after the archive; the Firebase
  # plist names the main one, which catches the usual missing profile early.
  [[ -n "$PLIST_BUNDLE_ID" ]] || return 0
  local line
  line="$(pick_profile "$PLIST_BUNDLE_ID" "" "")"
  if [[ -z "$line" ]]; then
    bad "Không có profile Ad Hoc."
  else
    ok "Profile: $(cut -f5 <<< "$line") ($(cut -f1 <<< "$line"))"
  fi
}

# Picks one certificate and, for each bundle id in $1 (one per line), a profile
# that includes it. Sets SIGN_TEAM, SIGN_CERT and SIGN_PROFILES
# ("<bundle id><TAB><uuid><TAB><name>" per line).
select_signing() {
  local bundles="$1" team="$2" cert b line missing=
  for cert in $(cut -f6 <<< "$PROFILES" | tr ',' '\n' | awk '!seen[$0]++'); do
    SIGN_PROFILES=
    while IFS= read -r b; do
      line="$(pick_profile "$b" "$team" "$cert")"
      [[ -n "$line" ]] || continue 2
      SIGN_TEAM="$(cut -f1 <<< "$line")"
      SIGN_PROFILES="${SIGN_PROFILES:+$SIGN_PROFILES$'\n'}$b"$'\t'"$(cut -f4,5 <<< "$line")"
    done <<< "$bundles"
    SIGN_CERT="$cert"
    return 0
  done
  while IFS= read -r b; do
    [[ -n "$(pick_profile "$b" "$team" "")" ]] || missing="${missing:+$missing, }$b"
  done <<< "$bundles"
  if [[ -n "$missing" ]]; then
    hint "Không có profile Ad Hoc${team:+ của team $team}."
  else
    hint "Các profile Ad Hoc không dùng chung certificate."
  fi
  fail "Không chọn được provisioning profile để export"
}

# Bundle ids of the app and of every app and extension inside it (watch app,
# app extensions, App Clip): each is signed with its own profile.
archive_bundle_ids() {
  local b
  find "$1" \( -name "*.app" -o -name "*.appex" \) -not -path "*/Frameworks/*" | while IFS= read -r b; do
    plist_get CFBundleIdentifier "$b/Info.plist" || true
  done | awk 'NF && !seen[$0]++'
}

# ---------------------------------------------------------------------------
# init
# ---------------------------------------------------------------------------
cmd_init() {
  goto_repo_root
  CFG_WORKSPACE= CFG_PROJECT=
  step "Đang khởi tạo cấu hình build cho $(basename "$TOP")"
  CFG_XCODE=
  # select_xcode and check_xcode already say what is wrong.
  select_xcode && check_xcode || exit 1
  detect_container || fail "Repo cần có đúng một .xcworkspace, hoặc đúng một .xcodeproj nếu không có workspace."
  ok "${WORKSPACE:-$PROJECT}"

  local scheme="$OPT_SCHEME" schemes
  if [[ -z "$scheme" ]]; then
    if ! scheme="$(guess_scheme 2>/dev/null)"; then
      schemes="$(list_schemes)"
      [[ -n "$schemes" ]] || fail "Không đọc được scheme nào của ${WORKSPACE:-$PROJECT}."
      if [[ -t 0 ]]; then
        local -a list=()
        while IFS= read -r s; do list+=("$s"); done <<< "$schemes"
        scheme="$(choose "Chọn scheme" "${list[@]}")"
      else
        fail "Có nhiều scheme, chạy lại với --scheme <tên>. Các scheme: $(paste -sd, - <<< "$schemes" | sed 's/,/, /g')"
      fi
    fi
  fi
  ok "Scheme: $scheme"

  local plist="$OPT_PLIST" plists dev
  if [[ -z "$plist" ]]; then
    plists="$(find_firebase_plists)"
    [[ -n "$plists" ]] || fail "Không tìm thấy GoogleService-Info*.plist nào trong repo. Truyền --plist <đường dẫn>."
    dev="$(grep -iE '(^|/)[^/]*dev[^/]*$' <<< "$plists" || true)"
    if [[ -n "$dev" && $(wc -l <<< "$dev") -eq 1 ]]; then
      plist="$dev"
    elif [[ -t 0 ]]; then
      local -a list=()
      while IFS= read -r p; do list+=("$p"); done <<< "$plists"
      plist="$(choose "Chọn plist Firebase dùng để upload" "${list[@]}")"
    else
      fail "Không tự chọn được plist Firebase, chạy lại với --plist <đường dẫn>. Các file: $(paste -sd, - <<< "$plists" | sed 's/,/, /g')"
    fi
  fi
  plist="${plist#./}"
  [[ -f "$plist" ]] || fail "Không tìm thấy $plist"
  local app_id project_id
  app_id="$(plist_get GOOGLE_APP_ID "$plist")" || fail "$plist không có GOOGLE_APP_ID"
  project_id="$(plist_get PROJECT_ID "$plist" || true)"
  ok "Firebase plist: $plist"
  if ! git ls-files --error-unmatch -- "$plist" >/dev/null 2>&1; then
    warn "$plist không có trong git"
  fi
  # Builds go to every tester group, and to the project's testers saved in
  # the config. Not being able to read them does not stop init: the build
  # checks Firebase access again.
  local groups= testers=
  if ! command -v "$FIREBASE" >/dev/null 2>&1; then
    warn "Chưa cài Firebase CLI nên không đọc được tester. Cài bằng: brew install firebase-cli"
  elif ! firebase_json appdistribution:groups:list --project "$project_id"; then
    warn "Không đọc được tester của project $project_id${FB_ERROR:+: $FB_ERROR}"
  else
    groups="$(tester_groups)"
    [[ -z "$groups" ]] || ok "Nhóm tester: ${groups//,/, }"
    if firebase_json appdistribution:testers:list --project "$project_id"; then
      testers="$(tester_emails)"
      [[ -z "$testers" ]] || ok "Tester: ${testers//,/, }"
    else
      warn "Không đọc được tester của project $project_id${FB_ERROR:+: $FB_ERROR}"
    fi
    [[ -n "$groups" || -n "$testers" ]] \
      || warn "Project $project_id chưa có tester nào: build chỉ được upload, không gửi cho ai"
  fi

  local tmp
  tmp="$(mktemp -t fb-build-init)"
  plutil -create xml1 "$tmp"
  if [[ -n "$WORKSPACE" ]]; then
    plutil -insert workspace -string "$WORKSPACE" "$tmp"
  else
    plutil -insert project -string "$PROJECT" "$tmp"
  fi
  plutil -insert scheme -string "$scheme" "$tmp"
  plutil -insert configuration -string Debug "$tmp"
  # Builds use the Xcode init used, recorded as a version: it is the same on
  # every machine, a path may not be.
  [[ -z "$(xcode_version)" ]] || plutil -insert xcode -string "$(xcode_version)" "$tmp"
  plutil -insert firebase_plist -string "$plist" "$tmp"
  [[ -z "$testers" ]] || plutil -insert testers -string "$testers" "$tmp"
  # plutil escapes "/" as "\/"; both are valid JSON, the plain form reads better.
  mkdir -p "$(dirname "$CONFIG")"
  plutil -convert json -r -o - "$tmp" | sed 's|\\/|/|g' > "$CONFIG"
  rm -f "$tmp"
  # Only committed code is built, so an untracked config would block it.
  git check-ignore -q "$CONFIG" \
    || warn "$CONFIG_NAME chưa được gitignore. Thêm .team-tools/ vào .gitignore, hoặc commit file này."

  step "Khởi tạo cấu hình build thành công"
  next_step "build và upload, vd: ${C_B}fb-build -v 1.2.0 -b 42${C_0}"
  echo "  -m TEXT      ghi chú cho tester trong release notes"
  echo "  -v VERSION   version, mặc định theo project"
  echo "  -b BUILD     build number, mặc định theo project"
  echo "  --dry-run    chỉ kiểm tra, không build"
  echo "  ${C_DIM}Các tùy chọn đều không bắt buộc.${C_0}"
}

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------
preflight() {
  step "Kiểm tra (fb-build $TOOL_VERSION)"

  # Git: only committed code is built, so the build matches HEAD exactly.
  HEAD_SHA="$(git rev-parse --verify --quiet HEAD)" || fail "Repo chưa có commit nào"
  SHORT_SHA="$(git rev-parse --short HEAD)"
  BRANCH="$(git symbolic-ref --quiet --short HEAD || echo "detached")"
  local dirty
  dirty="$(git status --porcelain)"
  if [[ -n "$dirty" ]]; then
    bad "Có thay đổi chưa commit. Chỉ build code đã commit, hãy commit hoặc stash trước:"
    head -15 <<< "$dirty" | sed 's/^/      /'
    (( $(wc -l <<< "$dirty") <= 15 )) || echo "      …"
  else
    ok "Git: $BRANCH @ $SHORT_SHA, không có thay đổi chưa commit"
  fi

  # Config
  if [[ ! -f "$CONFIG" ]]; then
    bad "Chưa có $CONFIG_NAME. Chạy: fb-build init"
    return
  fi
  load_config
  ok "Cấu hình: $CONFIG_NAME"
  CONFIGURATION="${CFG_CONFIGURATION:-Debug}"

  # Xcode, workspace and scheme
  local have_xcode=false have_container=false
  select_xcode && check_xcode && have_xcode=true
  detect_container && have_container=true
  SCHEME="$CFG_SCHEME"
  if [[ -z "$SCHEME" ]] && $have_xcode && $have_container; then
    if ! SCHEME="$(guess_scheme 2>/dev/null)"; then
      SCHEME=
      bad "Không tự chọn được scheme. Khai báo \"scheme\" trong $CONFIG_NAME"
    fi
  fi
  if $have_container && [[ -n "$SCHEME" ]]; then
    ok "${WORKSPACE:-$PROJECT} | scheme $SCHEME | $CONFIGURATION"
  fi

  # CocoaPods: the Pods sandbox must match Podfile.lock, otherwise the build
  # fails minutes later in the "[CP] Check Pods Manifest.lock" phase.
  local pods_dir
  if $have_container; then
    pods_dir="$(dirname "${WORKSPACE:-$PROJECT}")"
    if [[ -f "$pods_dir/Podfile" ]]; then
      diff -q "$pods_dir/Podfile.lock" "$pods_dir/Pods/Manifest.lock" >/dev/null 2>&1 \
        || bad "Pods chưa đồng bộ với Podfile.lock. Chạy pod install trong repo"
    fi
  fi

  # Firebase config that the build should contain
  local plist="${CFG_PLIST:-GoogleService-Info-Dev.plist}" matches
  plist="${plist#./}"
  if [[ "$plist" != */* ]]; then
    matches="$(find_firebase_plists | grep -E "(^|/)${plist//./\\.}$" || true)"
    if [[ -n "$matches" && $(wc -l <<< "$matches") -eq 1 ]]; then
      plist="$matches"
    else
      bad "Tìm thấy $(grep -c . <<< "$matches") file $plist. Ghi đường dẫn đầy đủ vào \"firebase_plist\" trong $CONFIG_NAME"
      plist=
    fi
  fi
  SRC_PLIST= PLIST_BUNDLE_ID=
  if [[ -n "$plist" && ! -f "$plist" ]]; then
    bad "Không tìm thấy $plist (\"firebase_plist\" trong $CONFIG_NAME)"
  elif [[ -n "$plist" ]]; then
    APP_ID="$(plist_get GOOGLE_APP_ID "$plist" || true)"
    PROJECT_ID="$(plist_get PROJECT_ID "$plist" || true)"
    PLIST_BUNDLE_ID="$(plist_get BUNDLE_ID "$plist" || true)"
    if [[ ! "$APP_ID" =~ ^[0-9]+:[0-9]+:ios:[0-9a-fA-F]+$ ]]; then
      bad "$plist không có GOOGLE_APP_ID hợp lệ của app iOS (đọc được: '${APP_ID}')"
    elif [[ -z "$PROJECT_ID" ]]; then
      bad "$plist không có PROJECT_ID"
    else
      SRC_PLIST="$plist"
    fi
  fi

  PROFILES=
  check_signing

  # Firebase CLI, login and tester groups
  TESTER_GROUPS= TESTERS=
  if ! command -v "$FIREBASE" >/dev/null 2>&1; then
    bad "Chưa cài Firebase CLI: brew install firebase-cli"
  elif [[ -n "$SRC_PLIST" ]]; then
    check_firebase_access
  fi
}

check_firebase_access() {
  local account=
  if firebase_json login:list; then
    account="$(plutil -extract result.0.user.email raw -o - "$FB_RESULT" 2>/dev/null || true)"
  fi
  # Also proves the account can use App Distribution in this project.
  if ! firebase_json appdistribution:groups:list --project "$PROJECT_ID"; then
    if [[ -z "$account" ]] || grep -qiE "authenticat|login|credentials" <<< "$FB_ERROR"; then
      bad "Firebase CLI chưa đăng nhập hoặc phiên đã hết hạn. Chạy: firebase login --reauth"
    elif grep -qiE "403|permission|denied" <<< "$FB_ERROR"; then
      bad "$account không có quyền App Distribution trên $PROJECT_ID"
    else
      bad "Không truy cập được App Distribution của project $PROJECT_ID ($account): $FB_ERROR"
    fi
    return
  fi
  # The build goes to every tester group of the project and to the testers
  # from the config.
  TESTER_GROUPS="$(tester_groups)"
  TESTERS="$(tr -d ' ' <<< "$CFG_TESTERS")"
  ok "Firebase CLI: $account | gửi cho: $(recipients)"
  [[ -n "$TESTER_GROUPS" || -n "$TESTERS" ]] \
    || warn "Project $PROJECT_ID chưa có nhóm tester nào và config không có \"testers\": build chỉ được upload, không gửi cho ai"
}

# Group aliases, comma-separated, from FB_RESULT of appdistribution:groups:list.
tester_groups() {
  plutil -extract result.groups xml1 -o - "$FB_RESULT" 2>/dev/null | xml_strings \
    | sed -n 's|^projects/[^/]*/groups/||p' | paste -sd, - || true
}

# Tester emails, comma-separated, from FB_RESULT of appdistribution:testers:list.
tester_emails() {
  plutil -extract result.testers xml1 -o - "$FB_RESULT" 2>/dev/null | xml_strings \
    | sed -n 's|^projects/[^/]*/testers/||p' | paste -sd, - || true
}

recipients() {
  local -a to=()
  [[ -z "$TESTER_GROUPS" ]] || to+=("nhóm ${TESTER_GROUPS//,/, }")
  [[ -z "$TESTERS" ]] || to+=("${TESTERS//,/, }")
  if (( ${#to[@]} == 0 )); then echo "không ai (chỉ upload)"; return; fi
  local IFS=';'
  echo "${to[*]}" | sed 's/;/; /g'
}

# ---------------------------------------------------------------------------
# Release notes
# ---------------------------------------------------------------------------
write_release_notes() {
  {
    if [[ -n "$OPT_MESSAGE" ]]; then
      printf '%s\n\n' "$OPT_MESSAGE"
    fi
    echo "$BRANCH · $SHORT_SHA · $(git log -1 --format=%an "$HEAD_SHA") · $CONFIGURATION"
  } > "$1"
}

show_release_notes() {
  echo "  Release notes:"
  sed 's/^./    &/' "$1"
}

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
explain_xcode_failure() {
  local log="$1"
  if grep -qE "No Accounts|No account for team|Your session has expired|sign in again|account .* not found" "$log"; then
    hint "Đăng nhập lại Apple account trong Xcode → Settings → Accounts"
  elif grep -qE "has no devices|no devices from which to generate" "$log"; then
    hint "Team chưa đăng ký thiết bị nào"
  elif grep -qE 'No signing certificate "(iOS|Apple) Distribution"|Missing private key|doesn.t include signing certificate' "$log"; then
    hint "Thiếu certificate Apple Distribution trong keychain"
  elif grep -qE "errSecInternalComponent|User interaction is not allowed|unable to unlock keychain" "$log"; then
    hint "Keychain đang khóa: security unlock-keychain"
  elif grep -qE "sandbox is not in sync with the Podfile.lock" "$log"; then
    hint "Pods chưa đồng bộ với Podfile.lock. Chạy pod install trong repo."
  elif grep -qE "does not contain a scheme named|is not currently configured for the" "$log"; then
    hint "Scheme hoặc configuration không tồn tại. Kiểm tra \"scheme\" và \"configuration\" trong $CONFIG_NAME."
  elif grep -qE "No profiles? for|couldn.t find any provisioning profiles|requires a provisioning profile|doesn.t match the entitlements|conflicting provisioning settings|doesn.t include the currently selected device" "$log"; then
    hint "Lỗi provisioning profile. Cần profile Ad Hoc cho app và từng extension."
  fi
  hint "Log đầy đủ: $log"
}

# "4:05" from a number of seconds.
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

run_xcodebuild() {
  local label="$1" log="$2" status=0
  shift 2
  run_logged "$label" "$log" xcodebuild "$@" || status=$?
  if (( status != 0 )); then
    grep -E ': error: |^error: ' "$log" | awk '!seen[$0]++' | head -10 | sed 's/^/    /' >&2 || true
    explain_xcode_failure "$log"
    fail "xcodebuild lỗi (exit $status)"
  fi
}

# release-testing replaced ad-hoc in Xcode 15.3.
export_method() {
  local v major minor
  v="$(xcode_version)"
  major="${v%%.*}"
  minor="$(cut -d. -f2 <<< "$v.0")"
  if (( major < 15 || (major == 15 && minor < 3) )); then echo ad-hoc; else echo release-testing; fi
}

stage_archive() {
  # Build settings on the command line apply to every target, so the app and
  # its extensions get the same version, as App Store Connect requires.
  local -a overrides=()
  [[ -z "$OPT_APP_VERSION" ]] || overrides+=("MARKETING_VERSION=$OPT_APP_VERSION")
  [[ -z "$OPT_BUILD_NUMBER" ]] || overrides+=("CURRENT_PROJECT_VERSION=$OPT_BUILD_NUMBER")
  run_xcodebuild "Đang archive…" "$LOG_DIR/archive.log" \
    "${CONTAINER[@]}" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    -derivedDataPath "$DERIVED_DATA" \
    -allowProvisioningUpdates \
    ${overrides[@]+"${overrides[@]}"} \
    archive

  APP_VERSION="$(plist_get ApplicationProperties:CFBundleShortVersionString "$ARCHIVE_PATH/Info.plist" || echo "?")"
  APP_BUILD="$(plist_get ApplicationProperties:CFBundleVersion "$ARCHIVE_PATH/Info.plist" || echo "?")"
  # The override only reaches Info.plist values written as $(MARKETING_VERSION)
  # and $(CURRENT_PROJECT_VERSION), not hard-coded ones.
  if [[ -n "$OPT_APP_VERSION" && "$APP_VERSION" != "$OPT_APP_VERSION" ]]; then
    hint "--app-version không có tác dụng: Info.plist không dùng \$(MARKETING_VERSION)"
    fail "Archive có version $APP_VERSION, không phải $OPT_APP_VERSION"
  fi
  if [[ -n "$OPT_BUILD_NUMBER" && "$APP_BUILD" != "$OPT_BUILD_NUMBER" ]]; then
    hint "--build-number không có tác dụng: Info.plist không dùng \$(CURRENT_PROJECT_VERSION)"
    fail "Archive có build number $APP_BUILD, không phải $OPT_BUILD_NUMBER"
  fi
  ok "Archive: $APP_VERSION ($APP_BUILD) ${C_DIM}· $ELAPSED${C_0}"

  verify_firebase_config
}

# The upload goes to the Firebase app from firebase_plist, so the build must
# actually contain that config: catches a configuration that bundles only the
# production plist. With both plists bundled, which one the app reads at
# runtime is up to the app's code.
verify_firebase_config() {
  local app found=false listing= p id bundle_id
  app="$(find "$ARCHIVE_PATH/Products/Applications" -maxdepth 1 -name "*.app" | sed -n 1p)"
  [[ -n "$app" ]] || fail "Không tìm thấy .app trong $ARCHIVE_PATH"
  while IFS= read -r p; do
    id="$(plist_get GOOGLE_APP_ID "$p")" || continue
    listing="${listing:+$listing, }${p#"$app"/} ($id)"
    [[ "$id" != "$APP_ID" ]] || found=true
  done < <(find "$app" -name "GoogleService-Info*.plist" -not -path "*/Frameworks/*" -not -path "*/PlugIns/*" -not -path "*/Extensions/*")
  $found || fail "App vừa build không chứa Firebase config của $SRC_PLIST ($APP_ID). Plist có trong app: ${listing:-không có}. Kiểm tra configuration $CONFIGURATION có copy $SRC_PLIST vào app không."
  bundle_id="$(plist_get CFBundleIdentifier "$app/Info.plist" || true)"
  if [[ -n "$PLIST_BUNDLE_ID" && "$bundle_id" != "$PLIST_BUNDLE_ID" ]]; then
    warn "Bundle ID của app ($bundle_id) khác BUNDLE_ID trong $SRC_PLIST ($PLIST_BUNDLE_ID)"
  fi
}

stage_export() {
  local options="$RUN_DIR/ExportOptions.plist" bundle uuid name
  local -a updates=()
  if [[ -n "$CFG_EXPORT_OPTIONS" ]]; then
    [[ -f "$CFG_EXPORT_OPTIONS" ]] || fail "Không tìm thấy $CFG_EXPORT_OPTIONS (\"export_options_plist\" trong $CONFIG_NAME)"
    cp "$CFG_EXPORT_OPTIONS" "$options"
    # The team's own options may use automatic signing.
    updates=(-allowProvisioningUpdates)
  else
    # Distribute App → Custom → Release Testing, signed manually with the
    # profiles installed on this Mac.
    select_signing "$(archive_bundle_ids "$ARCHIVE_PATH/Products/Applications")" \
      "$(plist_get ApplicationProperties:Team "$ARCHIVE_PATH/Info.plist" || true)"
    plutil -create xml1 "$options"
    plutil -insert method -string "$(export_method)" "$options"
    plutil -insert destination -string export "$options"
    plutil -insert signingStyle -string manual "$options"
    plutil -insert teamID -string "$SIGN_TEAM" "$options"
    plutil -insert signingCertificate -string "$SIGN_CERT" "$options"
    # PlistBuddy, since plutil key paths split the bundle ids at their dots.
    "$PLISTBUDDY" -c "Add :provisioningProfiles dict" "$options" >/dev/null
    while IFS=$'\t' read -r bundle uuid name; do
      "$PLISTBUDDY" -c "Add :provisioningProfiles:$bundle string $uuid" "$options" >/dev/null
    done <<< "$SIGN_PROFILES"
  fi
  run_xcodebuild "Đang export…" "$LOG_DIR/export.log" \
    -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$options" \
    ${updates[@]+"${updates[@]}"}
  IPA="$(find "$EXPORT_PATH" -maxdepth 1 -name "*.ipa" | sed -n 1p)"
  [[ -n "$IPA" ]] || fail "Export xong nhưng không thấy file .ipa trong $EXPORT_PATH"
  ok "$IPA ($(du -h "$IPA" | cut -f1 | tr -d ' ')) ${C_DIM}· $ELAPSED${C_0}"
}

stage_upload() {
  local -a args=(appdistribution:distribute "$IPA" --app "$APP_ID" --release-notes-file "$NOTES" --non-interactive)
  [[ -z "$TESTER_GROUPS" ]] || args+=(--groups "$TESTER_GROUPS")
  [[ -z "$TESTERS" ]] || args+=(--testers "$TESTERS")
  local log="$LOG_DIR/upload.log" status=0
  run_logged "Đang upload…" "$log" "$FIREBASE" "${args[@]}" || status=$?
  if (( status != 0 )); then
    strip_ansi < "$log" | grep -iE 'error' | tail -5 | sed 's/^/    /' >&2 || true
    if grep -qiE "authenticat|firebase login" "$log"; then
      hint "Firebase CLI chưa đăng nhập hoặc phiên đã hết hạn. Chạy: firebase login --reauth"
    elif grep -qiE "403|permission|denied" "$log"; then
      hint "Tài khoản Firebase không có quyền App Distribution trên project $PROJECT_ID."
    elif grep -qiE "404|not found" "$log"; then
      hint "Không tìm thấy app $APP_ID hoặc project chưa bật App Distribution"
    fi
    hint "File .ipa vẫn ở $IPA"
    fail "Upload lỗi (exit $status). Log: $log"
  fi
  ok "Đã upload $SCHEME $APP_VERSION ($APP_BUILD) · $CONFIGURATION ${C_DIM}· $ELAPSED${C_0}"
}

# Posts {repo, title, message} to the Lark webhook of the app's team. A failure
# only warns: the build is already uploaded.
notify_lark() {
  local team="$1" short="${LARK_WEBHOOKS/#$HOME/~}" url tmp response code
  if [[ -z "$team" ]]; then
    warn "Không đọc được team ID của app, bỏ qua thông báo Lark"
    return 0
  fi
  if [[ ! -f "$LARK_WEBHOOKS" ]]; then
    warn "Không có $short, bỏ qua thông báo Lark"
    return 0
  fi
  url="$(plutil -extract "$team.webhook" raw -o - "$LARK_WEBHOOKS" 2>/dev/null || true)"
  if [[ -z "$url" ]]; then
    warn "Chưa có webhook Lark cho team $team trong $short, bỏ qua thông báo"
    return 0
  fi
  tmp="$(mktemp -t fb-build-lark)"
  plutil -create xml1 "$tmp"
  plutil -insert repo -string "${REPO_KEY##*/}" "$tmp"
  plutil -insert title -string "Build $APP_VERSION ($APP_BUILD) is now available on Firebase App Distribution" "$tmp"
  plutil -insert message -string "$(cat "$NOTES")" "$tmp"
  plutil -convert json "$tmp"
  if ! response="$(curl -sS --fail-with-body --max-time 15 -H 'Content-Type: application/json' \
    --data-binary @"$tmp" "$url" 2>&1)"; then
    rm -f "$tmp"
    warn "Không gửi được thông báo Lark: $(head -1 <<< "$response")"
    return 0
  fi
  rm -f "$tmp"
  # Lark answers HTTP 200 even on errors, with the reason in code/msg.
  code="$(plutil -extract code raw -o - - <<< "$response" 2>/dev/null || echo 0)"
  if [[ "$code" != 0 ]]; then
    warn "Lark từ chối thông báo: $(plutil -extract msg raw -o - - <<< "$response" 2>/dev/null || echo "$response")"
    return 0
  fi
  ok "Đã gửi thông báo Lark"
}

# ---------------------------------------------------------------------------
# Build checkout
# ---------------------------------------------------------------------------
# Git-ignored paths the build may need (Pods, a Firebase plist kept out of git,
# local xcconfig...), without build output.
list_ignored() {
  git ls-files --others --ignored --exclude-standard --directory \
    | grep -vE '(^|/)(DerivedData|build|\.build)/$|\.(xcarchive|ipa)/?$|(^|/)\.DS_Store$' || true
}

# One build per repo at a time: they share the worktree and DerivedData.
lock_build() {
  local lock="$REPO_OUT/build.lock" pid
  if ! mkdir "$lock" 2>/dev/null; then
    pid="$(cat "$lock/pid" 2>/dev/null || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      fail "Đang có lần build khác (pid $pid)"
    fi
    rm -rf "$lock"
    mkdir "$lock" || fail "Không tạo được $lock"
  fi
  echo $$ > "$lock/pid"
  LOCK="$lock"
}

# Check out HEAD_SHA into a worktree outside the repo and cd into it, so later
# edits, branch switches and Xcode builds in the repo cannot reach this build.
# The worktree and its ignored files are kept between runs so builds stay
# incremental.
stage_checkout() {
  local base p keep
  base="$(cd "$REPO_OUT" && pwd -P)"
  SRC_DIR="$base/src"
  DERIVED_DATA="$base/DerivedData"
  git worktree prune
  if git worktree list --porcelain | grep -qxF "worktree $SRC_DIR"; then
    git -C "$SRC_DIR" checkout --quiet --force --detach "$HEAD_SHA"
    git -C "$SRC_DIR" clean -ffdq
  else
    rm -rf "$SRC_DIR"
    git worktree add --quiet --detach "$SRC_DIR" "$HEAD_SHA"
  fi
  if [[ -f "$SRC_DIR/.gitmodules" ]]; then
    git -C "$SRC_DIR" submodule update --quiet --init --recursive
  fi

  keep="$(list_ignored)"
  (cd "$SRC_DIR" && list_ignored) | while IFS= read -r p; do
    grep -qxF -- "$p" <<< "$keep" || rm -rf "${SRC_DIR:?}/$p"
  done
  while IFS= read -r p; do
    [[ -n "$p" ]] || continue
    mkdir -p "$SRC_DIR/$(dirname "$p")"
    if [[ "$p" == */ ]]; then
      rsync -a --delete "$p" "$SRC_DIR/$p"
    else
      rsync -a "$p" "$SRC_DIR/$p"
    fi
  done <<< "$keep"
  cd "$SRC_DIR"
}

cleanup() {
  prune_runs
  [[ -z "$LOCK" ]] || rm -rf "$LOCK"
}

prune_runs() {
  [[ -d "$REPO_OUT" ]] || return 0
  find "$REPO_OUT" -mindepth 1 -maxdepth 1 -type d -name "20*" | sort -r | tail -n +$((KEEP_RUNS + 1)) \
    | while IFS= read -r d; do rm -rf "$d"; done
}

cmd_run() {
  goto_repo_root
  REPO_KEY="$(repo_key)"
  REPO_OUT="$OUT_ROOT/$REPO_KEY"
  preflight
  if (( PROBLEMS > 0 )); then
    echo
    echo "${C_RED}✗ Có $PROBLEMS lỗi cần xử lý trước khi build.${C_0}" >&2
    next_step "sửa các mục ✗ ở trên rồi chạy lại lệnh này"
    exit 1
  fi

  if [[ "$DRY_RUN" == true ]]; then
    local preview
    preview="$(mktemp -t fb-build-notes)"
    write_release_notes "$preview"
    step "Upload Firebase App Distribution (dự kiến)"
    [[ -z "$OPT_APP_VERSION$OPT_BUILD_NUMBER" ]] \
      || echo "  Version: ${OPT_APP_VERSION:-theo project} (${OPT_BUILD_NUMBER:-theo project})"
    show_release_notes "$preview"
    rm -f "$preview"
    echo
    echo "Dry run: dừng trước khi build."
    next_step "chạy lại lệnh này không có --dry-run để build và upload"
    return
  fi

  RUN_DIR="$REPO_OUT/$(date +%Y%m%d-%H%M%S)"
  LOG_DIR="$RUN_DIR/logs"
  ARCHIVE_PATH="$RUN_DIR/$SCHEME.xcarchive"
  EXPORT_PATH="$RUN_DIR/export"
  NOTES="$RUN_DIR/release-notes.txt"
  mkdir -p "$REPO_OUT"
  LOCK=
  trap cleanup EXIT
  lock_build
  mkdir -p "$LOG_DIR"
  # Keep the Mac awake until this script exits.
  caffeinate -i -w $$ &

  step "Archive $SCHEME ($CONFIGURATION)"
  stage_checkout
  stage_archive
  stage_export
  write_release_notes "$NOTES"
  step "Upload Firebase App Distribution"
  stage_upload
  notify_lark "$(plist_get ApplicationProperties:Team "$ARCHIVE_PATH/Info.plist" || echo "${SIGN_TEAM:-}")"
  show_release_notes "$NOTES"
}

cmd_xcodes() {
  local installed current v app
  installed="$(list_xcodes)"
  [[ -n "$installed" ]] || fail "Chưa cài Xcode nào."
  current="$(default_developer_dir)"
  echo "Xcode đã cài (* là bản mặc định):"
  while IFS=$'\t' read -r v app; do
    if [[ "$current" == "$app/Contents/Developer" ]]; then
      printf '  %s %-8s %s\n' "*" "$v" "$app"
    else
      printf '  %s %-8s %s\n' " " "$v" "$app"
    fi
  done <<< "$installed"
  echo
  echo "Chọn bản để build: fb-build init --xcode <version>"
}

case "$CMD" in
  init) cmd_init ;;
  xcodes) cmd_xcodes ;;
  run) cmd_run ;;
esac
__FB_BUILD_TOOL__
}

main "$@"
