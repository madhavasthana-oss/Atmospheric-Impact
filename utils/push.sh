#!/bin/bash
set -e

# -------- CONFIG --------
BRANCH="main"

COMMIT_MSG="added search utility bash script"

# -------- STATUS CHECK --------
echo "→ Checking git status..."
git status

# -------- ADD CHANGES --------
echo "→ Staging all changes..."
git add .

# -------- COMMIT --------
echo "→ Committing..."
git commit -m "$COMMIT_MSG" || {
  echo "⚠️ Nothing to commit (maybe already committed)"
}

# -------- PUSH --------
echo "→ Pushing to origin/$BRANCH..."
git push origin "$BRANCH"

echo "✅ Done."