#!/usr/bin/env bash

gate_root_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}

gate_load_changed_files() {
  local scope_file=$1

  if [ -n "$scope_file" ]; then
    if [ ! -f "$scope_file" ]; then
      printf '[UNCLASSIFIED] scope 파일을 찾을 수 없습니다: %s\n' "$scope_file" >&2
      return 2
    fi
    grep -v '^[[:space:]]*$' "$scope_file" | sed 's#^\./##' | sort -u
    return
  fi

  printf '[INFO] scope-file 없이 git status 전체를 마지막 fallback으로 사용합니다.\n' >&2
  git status --short --untracked-files=all | awk '{print $2}' | sort -u
}

gate_hash_path() {
  local path=$1

  if [ -f "$path" ]; then
    sha256sum "$path" | awk '{print $1}'
  elif [ -d "$path" ]; then
    find "$path" -type f -print0 \
      | sort -z \
      | xargs -0 -r sha256sum \
      | sha256sum \
      | awk '{print $1}'
  else
    printf 'MISSING'
  fi
}

gate_fingerprint_lines() {
  if [ $# -eq 0 ]; then
    printf 'EMPTY'
    return
  fi

  local path
  for path in "$@"; do
    printf '%s\t%s\n' "$path" "$(gate_hash_path "$path")"
  done | sha256sum | awk '{print $1}'
}

gate_write_result() {
  local result_file=$1
  local gate_id=$2
  local state=$3
  local change_kind=$4
  local scope_fingerprint=$5
  local dependency_fingerprint=$6
  local retry_from=$7
  local summary=$8
  shift 8

  if [ -z "$result_file" ]; then
    return
  fi

  mkdir -p "$(dirname "$result_file")"
  {
    printf 'version=1\n'
    printf 'gate_id=%s\n' "$gate_id"
    printf 'state=%s\n' "$state"
    printf 'change_kind=%s\n' "$change_kind"
    printf 'scope_fingerprint=%s\n' "$scope_fingerprint"
    printf 'dependency_fingerprint=%s\n' "$dependency_fingerprint"
    printf 'retry_from=%s\n' "$retry_from"
    printf 'summary=%s\n' "$summary"
    local dependency
    for dependency in "$@"; do
      printf 'dependency\t%s\t%s\n' "$dependency" "$(gate_hash_path "$dependency")"
    done
  } > "$result_file"
}

gate_append_dependency_patterns() {
  local result_file=$1
  shift

  if [ -z "$result_file" ]; then
    return
  fi

  local pattern
  for pattern in "$@"; do
    printf 'dependency_pattern\t%s\n' "$pattern" >> "$result_file"
  done
}

gate_read_result_value() {
  local result_file=$1
  local key=$2
  sed -n "s/^${key}=//p" "$result_file" | head -n 1
}

gate_result_dependencies_changed() {
  local result_file=$1
  local current_changed_files=$2

  local marker path stored_hash
  while IFS=$'\t' read -r marker path stored_hash; do
    if [ "$marker" != 'dependency' ]; then
      continue
    fi
    if [ "$(gate_hash_path "$path")" != "$stored_hash" ]; then
      return 0
    fi
  done < "$result_file"

  local pattern current_path
  while IFS=$'\t' read -r marker pattern; do
    if [ "$marker" != 'dependency_pattern' ]; then
      continue
    fi
    while IFS= read -r current_path; do
      if [ -z "$current_path" ] || ! printf '%s\n' "$current_path" | grep -E -q "$pattern"; then
        continue
      fi
      if ! awk -F '\t' -v path="$current_path" '$1 == "dependency" && $2 == path { found = 1 } END { exit !found }' "$result_file"; then
        return 0
      fi
    done <<< "$current_changed_files"
  done < "$result_file"

  return 1
}

gate_print_unclassified() {
  local target=$1
  local reason=$2
  local candidates=$3
  local minimum_check=$4
  local retry_from=$5

  printf '[UNCLASSIFIED] %s\n' "$target" >&2
  printf '근거: %s\n' "$reason" >&2
  printf '후보: %s\n' "$candidates" >&2
  printf '최소 추가 확인: %s\n' "$minimum_check" >&2
  printf '재개 지점: %s\n' "$retry_from" >&2
}
