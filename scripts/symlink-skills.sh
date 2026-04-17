#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$ROOT/docs/skills/project"
SOURCE_REL="../docs/skills/project"
AGENT_DIRS=(".claude" ".codex" ".gemini")

if [[ ! -d "$SOURCE" ]]; then
  echo "Missing skills source: $SOURCE" >&2
  exit 1
fi

for agent_dir in "${AGENT_DIRS[@]}"; do
  skills_path="$ROOT/$agent_dir/skills"

  if [[ -L "$skills_path" || ! -e "$skills_path" ]]; then
    continue
  fi

  if [[ ! -d "$skills_path" ]]; then
    echo "Abort: $agent_dir/skills exists but is not a directory or symlink." >&2
    exit 1
  fi

  non_symlink_entry="$(find "$skills_path" -mindepth 1 ! -type l -print -quit)"

  if [[ -n "$non_symlink_entry" ]]; then
    echo "Abort: $agent_dir/skills contains non-symlink content: ${non_symlink_entry#$ROOT/}" >&2
    echo "Move or remove that content before running this command." >&2
    exit 1
  fi
done

for agent_dir in "${AGENT_DIRS[@]}"; do
  agent_path="$ROOT/$agent_dir"
  skills_path="$agent_path/skills"

  mkdir -p "$agent_path"

  if [[ -L "$skills_path" ]]; then
    rm "$skills_path"
  elif [[ -d "$skills_path" ]]; then
    find "$skills_path" -mindepth 1 -type l -exec rm {} +
    rmdir "$skills_path"
  elif [[ -e "$skills_path" ]]; then
    echo "Abort: $agent_dir/skills exists but is not a directory or symlink." >&2
    exit 1
  fi

  ln -s "$SOURCE_REL" "$skills_path"
  echo "$agent_dir/skills -> $SOURCE_REL"
done
