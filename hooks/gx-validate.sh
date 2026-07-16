#!/usr/bin/env bash
# Shared validation rules for gx hooks.
# Conventions: Conventional Branch, Conventional Commits, SemVer-style tags.

# shellcheck disable=SC2034
GX_HOOK_TYPES='feat|fix|hotfix|chore|docs|refactor|test|ci|build|perf|style|revert'
GX_HOOK_ZERO='0000000000000000000000000000000000000000'

# Early exit when git is invoked by gx (export GX_SKIP_HOOKS=1).
_gx_hook_skip_if_gx() {
  [ "${GX_SKIP_HOOKS:-0}" = "1" ]
}

# Long-lived / scratch branches — OK to create & checkout; NOT enough for commit.
_gx_hook_is_allowed_branch() {
  local b="$1"
  case "$b" in
    main|master|develop|trunk|dev|staging|production|prod|qa|uat|tmp|test|sandbox|release)
      return 0
      ;;
  esac
  # release/1.2 — long-lived; hotfix/* with a ticket still uses ticket-branch rules below
  if echo "$b" | grep -Eq '^release(/|-)'; then
    return 0
  fi
  local extra="${GX_HOOKS_ALLOW_BRANCHES:-}"
  if [ -n "$extra" ] && echo "$b" | grep -Eq "^(${extra})$"; then
    return 0
  fi
  return 1
}

# Ticket-driven feature branch: type/TICKET-ID
_gx_hook_is_ticket_branch() {
  local b="$1"
  echo "$b" | grep -Eq "^(${GX_HOOK_TYPES})/[A-Za-z0-9._-]+$"
}

# Creating a new branch (git branch / checkout -b): ticket OR allowlist
_gx_hook_branch_create_ok() {
  local b="$1"
  [ -z "$b" ] && return 1
  _gx_hook_is_allowed_branch "$b" && return 0
  _gx_hook_is_ticket_branch "$b" && return 0
  return 1
}

# Committing: must be on a ticket branch (force work on type/TICKET-ID)
_gx_hook_branch_commit_ok() {
  local b="$1"
  [ -z "$b" ] && return 0 # detached HEAD
  _gx_hook_is_ticket_branch "$b"
}

# Pushing an existing branch: ticket OR allowlist (never invent new bad names here)
_gx_hook_branch_push_ok() {
  local b="$1"
  [ -z "$b" ] && return 0
  _gx_hook_is_allowed_branch "$b" && return 0
  _gx_hook_is_ticket_branch "$b" && return 0
  return 1
}

_gx_hook_print_branch_create_error() {
  local b="$1"
  echo "" >&2
  echo -e "\033[0m Cannot create branch — name does not match convention." >&2
  echo "" >&2
  echo -e "  Got:      \033[1;33m${b}\033[0m" >&2
  echo -e "  Expect:  \033[1;32mtype/TICKET-ID\033[0m" >&2
  echo -e "  Example: \033[1;32mfeat/ABC-123\033[0m" >&2
  echo "" >&2
  echo "  Allowed types: feat fix hotfix chore docs refactor test ci build perf style revert" >&2
  echo "  Also allowed:  main develop uat qa staging prod tmp release… (bases / scratch)" >&2
  echo "  Tip:          git checkout -b feat/ABC-123   or   gx co -b feat/ABC-123" >&2
  echo "" >&2
}

_gx_hook_print_branch_commit_error() {
  local b="$1"
  echo "" >&2
  echo -e "\033[0m Commit blocked — current branch is not type/TICKET-ID." >&2
  echo "" >&2
  echo -e "  Branch:  \033[1;33m${b}\033[0m" >&2
  echo -e "  Expect:  \033[1;32mtype/TICKET-ID\033[0m  e.g. \033[1;32mfeat/ABC-123\033[0m" >&2
  echo "" >&2
  echo "  Checkout of develop/uat/qa/tmp/… is fine; commit from a ticket branch." >&2
  echo "  Tip: gx co -b feat/ABC-123 && gx c -m \"your message\"" >&2
  echo "" >&2
}

_gx_hook_print_branch_push_error() {
  local b="$1"
  echo "" >&2
  echo -e "\033[0m Push blocked — branch name does not match convention." >&2
  echo "" >&2
  echo -e "  Got:      \033[1;33m${b}\033[0m" >&2
  echo -e "  Expect:  \033[1;32mtype/TICKET-ID\033[0m or a base branch (develop, uat, qa, …)" >&2
  echo "" >&2
}

# Same normalization as gx (_normalize_commit_msg)
_gx_hook_normalize_msg() {
  local msg="$1"
  msg=$(printf '%s' "$msg" | sed 's/\([a-z0-9]\)\([A-Z]\)/\1_\2/g' | sed 's/\([A-Z]\)\([A-Z][a-z]\)/\1_\2/g' | tr '[:upper:]' '[:lower:]')
  msg=$(printf '%s' "$msg" | sed 's/[[:space:]]\+/ /g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  printf '%s' "$msg"
}

# Same as gx _format_commit_message / _build_commit_msg_from_branch
_gx_hook_build_commit_msg() {
  local raw="$1"
  local branch purpose remainder ticket normalized
  branch="$(git branch --show-current 2>/dev/null || true)"
  if [[ "$branch" == *"/"* ]]; then
    purpose="${branch%%/*}"
    remainder="${branch#*/}"
    ticket=$(printf '%s' "${remainder%%/*}" | tr '[:upper:]' '[:lower:]')
    normalized="$(_gx_hook_normalize_msg "$raw")"
    if [ -n "$ticket" ]; then
      printf '%s: %s (%s)' "$purpose" "$normalized" "$ticket"
    else
      printf '%s: %s' "$purpose" "$normalized"
    fi
  else
    _gx_hook_normalize_msg "$raw"
  fi
}

# If subject is already "type: desc (ticket)", keep only the description as raw input
_gx_hook_extract_raw_subject() {
  local msg="$1"
  local desc
  if echo "$msg" | grep -Eq "^(${GX_HOOK_TYPES}): "; then
    desc=$(printf '%s' "$msg" | sed -E "s/^(${GX_HOOK_TYPES}): //")
    desc=$(printf '%s' "$desc" | sed -E 's/ \([A-Za-z0-9._/-]+\)$//')
    printf '%s' "$desc"
  else
    printf '%s' "$msg"
  fi
}

# Commit subject: type: description (optional ticket)
_gx_hook_commit_ok() {
  local msg="$1"
  case "$msg" in
    Merge\ *|Revert\ *|fixup!\ *|squash!\ *)
      return 0
      ;;
  esac
  echo "$msg" | grep -Eq "^(${GX_HOOK_TYPES}): .+(\ \([A-Za-z0-9._/-]+\))?$"
}

# SemVer-style tags: <env>-vMAJOR.MINOR.PATCH.BUILD[.hotfixN]
_gx_hook_tag_ok() {
  local tag="$1"
  echo "$tag" | grep -Eq '^[A-Za-z0-9][A-Za-z0-9._-]*-v[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(\.hotfix[0-9]+)?$'
}

_gx_hook_print_tag_error() {
  local tag="$1"
  echo "" >&2
  echo -e "\033[0m Tag name does not match Semantic Versioning (gx style)." >&2
  echo "" >&2
  echo -e "  Got:      \033[1;33m${tag}\033[0m" >&2
  echo -e "  Expect:  \033[1;32m<env>-vMAJOR.MINOR.PATCH.BUILD\033[0m" >&2
  echo -e "  Example: \033[1;32mcore-qa-v5.3.7.0\033[0m  or  \033[1;32mcore-qa-v5.3.7.0.hotfix1\033[0m" >&2
  echo "" >&2
  echo "  Tip: use  gx tn <env>  |  gx tver <env>-vX.Y.Z.N" >&2
  echo "" >&2
}
