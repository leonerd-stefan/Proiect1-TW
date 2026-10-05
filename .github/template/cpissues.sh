#!/usr/bin/env bash
set -euo pipefail

issues_file="$(dirname "$0")/issues.yml"
existing_issues="$(gh issue list --state all --limit 1000 --json title)"

ruby -ryaml -rjson -e '
  issues = YAML.safe_load(File.read(ARGV.fetch(0)))
  abort "Expected a list of issues" unless issues.is_a?(Array)

  issues.each do |issue|
    unless issue.is_a?(Hash) && issue["title"].is_a?(String) && issue["body"].is_a?(String)
      abort "Each issue needs a title and body"
    end
    puts JSON.generate(issue)
  end
' "$issues_file" | while IFS= read -r issue; do
  title="$(jq -r '.title' <<< "$issue")"

  if jq -e --arg title "$title" 'any(.[]; .title == $title)' <<< "$existing_issues" > /dev/null; then
    echo "Issue already exists: $title"
    continue
  fi

  jq -j '.body' <<< "$issue" | gh issue create --title "$title" --body-file -
done
