#!/bin/bash
set -e

MAIN="Atmospheric Impact.tex"

backup() {
  cp "$1" "$1.bak"
  echo "Backup created: $1.bak"
}

# ---------- CHECK EXISTS ----------
exists() {
  local regex="$1"
  local file="$2"
  perl -0777 -ne "exit 0 if /$regex/; exit 1" "$file"
}

# ---------- REPLACE SELECTION ----------
replace_selection() {
  echo "→ Checking Selection section"

  old='Selection\s+does\s+not\s+search\s+for\s+.*?what\s+to\s+say\.'
  new='Selection\s+does\s+not\s+construct\s+what\s+to\s+say\.'

  if exists "$new" "$MAIN"; then
    echo "✔ Selection already patched, skipping"
    return
  fi

  if exists "$old" "$MAIN"; then
    echo "✔ Applying Selection fix"

    perl -0777 -i -pe '
      s/Selection\s+does\s+not\s+search\s+for\s+.*?what\s+to\s+say\./Selection does not construct what to say. It either recognises what has already formed, or stays with the moment until something true becomes clear./s
    ' "$MAIN"
  else
    echo "❌ Could not find Selection pattern"
    exit 1
  fi
}

# ---------- INSERT IRREDUCIBLE ----------
insert_irreducible() {
  echo "→ Checking Irreducible Core (final fix)"

  already='Not every moment calls for openness'

  if exists "$already" "$MAIN"; then
    echo "✔ Already patched, skipping"
    return
  fi

  perl -0777 -i -pe '
    s/(\\subsection\*\{Irreducible Core\})/$1\n\nNot every moment calls for openness.\\\\\nWhen something real is asked of you, meet it fully.\n/
  ' "$MAIN"

  echo "✔ Inserted successfully"
}

# ---------- RUN ----------

backup "$MAIN"

replace_selection
insert_irreducible

echo "✅ Patch complete (safe re-run version)."