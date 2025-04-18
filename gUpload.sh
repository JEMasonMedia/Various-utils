#!/bin/bash

# Change to your repo directory if needed
cd "$(dirname "$0")"

# Ensure we're inside a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Error: Not inside a Git repository."
  exit 1
fi

# Optional: update remote URL or branch name logic here
DEFAULT_COMMIT_MSG="Auto-update commit on $(date '+%Y-%m-%d %H:%M:%S')"

read -rp "Enter commit message (or leave blank for default): " MSG
COMMIT_MSG=${MSG:-$DEFAULT_COMMIT_MSG}

# Stage, commit, and push all
git add .
git commit -m "$COMMIT_MSG"
git push

