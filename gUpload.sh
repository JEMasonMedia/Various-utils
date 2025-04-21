#!/bin/bash

# Navigate to the script's directory
cd "$(dirname "$0")"

# Ensure this is a Git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Error: Not inside a Git repository."
  exit 1
fi

# Show current git status and branch
echo "Current branch: $(git branch --show-current)"
git status

# Get commit message
DEFAULT_MSG="Auto-update commit on $(date '+%Y-%m-%d %H:%M:%S')"
read -rp "Enter commit message (or press Enter for default): " MSG
COMMIT_MSG=${MSG:-$DEFAULT_MSG}

# Stage all changes
git add .

# Commit only if there are staged changes
if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "$COMMIT_MSG"
  git push
fi
