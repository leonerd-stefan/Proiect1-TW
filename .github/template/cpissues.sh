#!/usr/bin/env bash
set -euo pipefail

issues_file="$(dirname "$0")/issues.json"
existing_issues="$(gh issue list --state all --limit 1000 --json title)"

jq -c '.[]' "$issues_file" | while IFS= read -r issue; do
  title="$(jq -r '.title' <<< "$issue")"

  if jq -e --arg title "$title" 'any(.[]; .title == $title)' <<< "$existing_issues" > /dev/null; then
    echo "Issue already exists: $title"
    continue
  fi

  jq -j '.body' <<< "$issue" | gh issue create --title "$title" --body-file -
done
