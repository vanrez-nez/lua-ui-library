#!/usr/bin/env zsh

set -euo pipefail
setopt null_glob

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <phase-id>" >&2
  echo "Example: $0 phase-01" >&2
  exit 1
fi

phase_id="$1"
script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
phase_dir="$repo_root/docs/implementation/tasks/$phase_id"
compliance_review="$phase_dir/00-compliance-review.md"
foundation_spec="$repo_root/docs/spec/ui-foundation-spec.md"
controls_spec="$repo_root/docs/spec/ui-controls-spec.md"

if [[ ! -d "$phase_dir" ]]; then
  echo "Phase directory not found: $phase_dir" >&2
  exit 1
fi

if [[ ! -f "$compliance_review" ]]; then
  echo "Compliance review not found: $compliance_review" >&2
  exit 1
fi

if [[ ! -f "$foundation_spec" ]]; then
  echo "Foundation spec not found: $foundation_spec" >&2
  exit 1
fi

if [[ ! -f "$controls_spec" ]]; then
  echo "Controls spec not found: $controls_spec" >&2
  exit 1
fi

task_files=("$phase_dir"/[0-9][0-9]-*.md)

if (( ${#task_files[@]} == 0 )); then
  echo "No task files found in $phase_dir" >&2
  exit 1
fi

for task_file in "${task_files[@]}"; do
  if [[ "$task_file:t" == "00-compliance-review.md" ]]; then
    continue
  fi

  rel_task="${task_file#$repo_root/}"
  rel_review="${compliance_review#$repo_root/}"
  rel_foundation="${foundation_spec#$repo_root/}"
  rel_controls="${controls_spec#$repo_root/}"

  prompt="Implement the library task in ${rel_task} reviewing carefully the ${rel_review} and the ${rel_foundation} and ${rel_controls} to make sure your implementation follows the spec. It is important to not deviate from spec contract to allow having a cohesive design. You must use the lua-love2d skill to make a clean write of required task."

  printf '\n==> %s\n' "$rel_task"
  codex exec --full-auto --cd "$repo_root" "$prompt"
done
