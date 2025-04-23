#!/bin/bash

# If running as root, re-run as regular user with environment
if [ "$EUID" -eq 0 ] && [ -n "$SUDO_USER" ]; then
  echo "[*] Re-running script as $SUDO_USER with preserved environment..."
  exec sudo -u "$SUDO_USER" -E "$0" "$@"
fi

cd "$(dirname "$0")"

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Error: Not inside a Git repository."
  exit 1
fi

DEFAULT_COMMIT_MSG="Auto-update commit on $(date '+%Y-%m-%d %H:%M:%S')"
read -rp "Enter commit message (or press Enter for default): " MSG
COMMIT_MSG=${MSG:-$DEFAULT_COMMIT_MSG}

# Stage all changes
git add .

# Show staged files
echo
echo "[*] Files staged for commit:"
git diff --cached --name-status
echo

# Confirm before committing
read -rp "Proceed with commit? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Commit cancelled."
  exit 0
fi

git commit -m "$COMMIT_MSG"
git push
