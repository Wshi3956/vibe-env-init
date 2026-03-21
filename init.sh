#!/usr/bin/env bash
# shellcheck disable=SC2059
set -euo pipefail

REPO="${VIBE_ENV_INIT_REPO:-Miskamyasa/vibe-env-init}"
BRANCH="${VIBE_ENV_INIT_BRANCH:-main}"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/templates"

# ── Colors ──────────────────────────────────────────────────────────
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' C='\033[0;36m' DIM='\033[2m' NC='\033[0m'

info()  { printf "${B}i${NC}  %s\n" "$1"; }
ok()    { printf "${G}+${NC}  %s\n" "$1"; }
warn()  { printf "${Y}!${NC}  %s\n" "$1"; }
err()   { printf "${R}x${NC}  %s\n" "$1" >&2; }

# ── Cleanup trap ────────────────────────────────────────────────────
TMPDIR_INIT=""
cleanup() {
  if [[ -n "$TMPDIR_INIT" && -d "$TMPDIR_INIT" ]]; then
    rm -rf "$TMPDIR_INIT"
  fi
}
trap cleanup EXIT

# -- Arguments --------------------------------------------------------
RAW_PROJECT_NAME="${1:-$(basename "$PWD")}" 

sanitize_project_name() {
  local input="$1"
  local sanitized
  sanitized=$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9_.-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')
  if [[ -z "$sanitized" ]]; then
    sanitized="project"
  fi
  printf '%s' "$sanitized"
}

PROJECT_NAME="$(sanitize_project_name "$RAW_PROJECT_NAME")"
if [[ "$RAW_PROJECT_NAME" != "$PROJECT_NAME" ]]; then
  warn "Project name normalized for container compatibility: '${RAW_PROJECT_NAME}' -> '${PROJECT_NAME}'"
fi

# ── Helpers ─────────────────────────────────────────────────────────

fetch() {
  local url="$1" dest="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget &>/dev/null; then
    wget -qO "$dest" "$url"
  else
    err "Neither curl nor wget found"
    exit 1
  fi
}

prompt_mode() {
  echo ""
  printf "${C}Select opencode session mode:${NC}\n"
  echo ""
  printf "  ${B}1)${NC} shared  - Share opencode sessions between containers\n"
  printf "             Uses opencode v1.1.63 (pre-SQLite, session sharing compatible)\n"
  echo ""
  printf "  ${B}2)${NC} sqlite  - Isolated opencode data per project\n"
  printf "             Uses latest opencode (SQLite-based, no cross-container sessions)\n"
  echo ""

  while true; do
    printf "${C}Choose [1/2]:${NC} "
    read -r choice
    case "$choice" in
      1|shared)  MODE="shared"; break ;;
      2|sqlite)  MODE="sqlite"; break ;;
      *)         warn "Please enter 1 or 2" ;;
    esac
  done

  ok "Mode: ${MODE}"
  echo ""
}

escape_sed_replacement() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//&/\\&}"
  value="${value//|/\\|}"
  printf '%s' "$value"
}

create_tmpdir() {
  local tmp
  if tmp=$(mktemp -d 2>/dev/null); then
    printf '%s' "$tmp"
    return
  fi
  mktemp -d -t vibe-env-init
}

supports_diff_color() {
  diff --color=auto -u /dev/null /dev/null >/dev/null 2>&1
}

show_conflict() {
  local rel_path="$1" dest="$2" remote_url="$3"
  local escaped_project_name
  escaped_project_name="$(escape_sed_replacement "$PROJECT_NAME")"

  TMPDIR_INIT="${TMPDIR_INIT:-$(create_tmpdir)}"
  local tmp_file
  tmp_file="${TMPDIR_INIT}/$(basename "$rel_path")"

  if fetch "$remote_url" "$tmp_file" 2>/dev/null; then
    # Apply template substitution to temp file for accurate diff
    if command -v sed &>/dev/null; then
      sed -i.bak "s|{{PROJECT_NAME}}|${escaped_project_name}|g" "$tmp_file" && rm -f "${tmp_file}.bak"
    fi

    if command -v diff &>/dev/null; then
      printf "\n${DIM}--- existing: %s${NC}\n" "$rel_path"
      printf "${DIM}+++ template: %s${NC}\n\n" "$remote_url"
      if supports_diff_color; then
        diff --color=auto -u "$dest" "$tmp_file" || true
      else
        diff -u "$dest" "$tmp_file" || true
      fi
      echo ""
    fi
  fi

  printf "  ${DIM}Template: %s${NC}\n" "$remote_url"
  info "Merge changes from the template manually if needed."
}

place_file() {
  local rel_path="$1" remote_name="${2:-$1}"
  local dest="./${rel_path}"
  local dir
  dir=$(dirname "$dest")
  local remote_url="${BASE_URL}/${remote_name}"

  mkdir -p "$dir"

  if [[ -f "$dest" ]]; then
    warn "Exists, skipping: ${rel_path}"
    show_conflict "$rel_path" "$dest" "$remote_url"
    return
  fi

  fetch "$remote_url" "$dest"
  ok "Created ${rel_path}"
}

apply_template() {
  local file="$1"
  local escaped_project_name
  escaped_project_name="$(escape_sed_replacement "$PROJECT_NAME")"
  if [[ -f "$file" ]]; then
    if command -v sed &>/dev/null; then
      sed -i.bak "s|{{PROJECT_NAME}}|${escaped_project_name}|g" "$file" && rm -f "${file}.bak"
    fi
  fi
}

# ── File manifest ───────────────────────────────────────────────────

OPENCODE_FILES=(
  ".opencode/opencode.json"
  ".opencode/agents/investigate.md"
  ".opencode/agents/review.md"
  ".opencode/commands/execute.md"
  ".opencode/commands/plan.md"
  ".opencode/commands/review.md"
)

# ── Main ────────────────────────────────────────────────────────────

echo ""
printf "${B}+-----------------------------------------+${NC}\n"
printf "${B}|${NC}      vibe-env-init project scaffolder     ${B}|${NC}\n"
printf "${B}+-----------------------------------------+${NC}\n"
echo ""
info "Project name: ${PROJECT_NAME}"
info "Target dir:   $(pwd)"

# Prompt for mode
prompt_mode

# .devcontainer - pick variant based on mode
place_file ".devcontainer/devcontainer.json" ".devcontainer/devcontainer.${MODE}.json"

# mise.toml - pick variant based on mode
place_file "mise.toml" "mise.${MODE}.toml"

# .opencode - all files
for f in "${OPENCODE_FILES[@]}"; do
  place_file "$f"
done

# Template substitution - replace {{PROJECT_NAME}} in placed files
apply_template ".devcontainer/devcontainer.json"
apply_template "mise.toml"
apply_template ".opencode/opencode.json"

echo ""
ok "Done! Your dev environment is ready."
echo ""
info "Next steps:"
echo "   1. devcontainer up --workspace-folder .    # build & start the container"
echo "   2. devcontainer exec --workspace-folder . opencode   # run opencode inside it"
echo ""
info "Or use a wrapper script - see the README for details."
echo ""
