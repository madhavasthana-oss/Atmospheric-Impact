#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# search.sh — find every occurrence of a word/phrase across ALL levels
#             of a directory tree
#
# Usage:
#   ./search.sh <word> [directory] [options]
#
# Arguments:
#   word        Word or phrase to search for (required)
#   directory   Root directory to search from (default: current directory)
#
# Options:
#   -i          Case-insensitive search
#   -e EXT      Only search files with this extension, no dot (e.g. -e tex)
#   -w          Match whole word only
#   -l          List matching files only (no line content)
#   -h          Show this help message
#
# Examples:
#   ./search.sh graze .
#   ./search.sh graze ~/Atmospheric-Impact -i
#   ./search.sh graze ~/Atmospheric-Impact -e tex
#   ./search.sh "thread creation" ~/Atmospheric-Impact -i -e tex
#   ./search.sh graze ~/Atmospheric-Impact -w -e tex -l
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Defaults ──────────────────────────────────────────────────────────────────
CASE_FLAG=""
EXT=""
WHOLE_WORD=""
LIST_ONLY=""
SEARCH_DIR="."
WORD=""

# ── Help ──────────────────────────────────────────────────────────────────────
usage() {
  grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \?//'
  exit 0
}

# ── Argument parsing ──────────────────────────────────────────────────────────
if [[ $# -eq 0 ]]; then
  echo -e "${RED}Error:${RESET} No search word provided."
  usage
fi

WORD="$1"
shift

# Second positional arg (if not a flag) is the directory
if [[ $# -gt 0 && "${1:0:1}" != "-" ]]; then
  SEARCH_DIR="$1"
  shift
fi

while getopts ":ie:wlh" opt; do
  case $opt in
    i) CASE_FLAG="-i" ;;
    e) EXT="$OPTARG" ;;
    w) WHOLE_WORD="-w" ;;
    l) LIST_ONLY="-l" ;;
    h) usage ;;
    \?) echo -e "${RED}Unknown option:${RESET} -$OPTARG"; exit 1 ;;
    :)  echo -e "${RED}Option -$OPTARG requires an argument.${RESET}"; exit 1 ;;
  esac
done

# ── Validate directory ────────────────────────────────────────────────────────
if [[ ! -d "$SEARCH_DIR" ]]; then
  echo -e "${RED}Error:${RESET} Directory not found: $SEARCH_DIR"
  exit 1
fi

SEARCH_DIR="$(realpath "$SEARCH_DIR")"

# ── Build include glob ────────────────────────────────────────────────────────
INCLUDE_GLOB="*"
[[ -n "$EXT" ]] && INCLUDE_GLOB="*.$EXT"

# ── Header ────────────────────────────────────────────────────────────────────
echo -e ""
echo -e "${BOLD}Search:${RESET}    ${YELLOW}\"$WORD\"${RESET}"
echo -e "${BOLD}Root:${RESET}      ${CYAN}$SEARCH_DIR${RESET}"
echo -e "${BOLD}Files:${RESET}     ${INCLUDE_GLOB}"
[[ -n "$CASE_FLAG" ]]  && echo -e "${BOLD}Mode:${RESET}      case-insensitive"
[[ -n "$WHOLE_WORD" ]] && echo -e "${BOLD}Mode:${RESET}      whole word only"
echo -e "─────────────────────────────────────────────────────────────────────"

# ── Build grep args ───────────────────────────────────────────────────────────
# -r  = recursive, descends ALL subdirectory levels automatically
# -n  = show line numbers
GREP_ARGS=(-rn --include="$INCLUDE_GLOB")
[[ -n "$CASE_FLAG" ]]  && GREP_ARGS+=(-i)
[[ -n "$WHOLE_WORD" ]] && GREP_ARGS+=(-w)
[[ -n "$LIST_ONLY" ]]  && GREP_ARGS+=(-l)

# ── Run ───────────────────────────────────────────────────────────────────────
RESULTS=$(grep "${GREP_ARGS[@]}" "$WORD" "$SEARCH_DIR" 2>/dev/null || true)

if [[ -z "$RESULTS" ]]; then
  echo -e "${RED}No matches found.${RESET}"
  echo ""
  exit 0
fi

# ── Output ────────────────────────────────────────────────────────────────────
MATCH_COUNT=0

if [[ -n "$LIST_ONLY" ]]; then
  while IFS= read -r filepath; do
    REL="${filepath#$SEARCH_DIR/}"
    echo -e "  ${GREEN}${REL}${RESET}"
    (( MATCH_COUNT++ )) || true
  done <<< "$RESULTS"
  echo -e "─────────────────────────────────────────────────────────────────────"
  echo -e "${BOLD}${MATCH_COUNT} file(s) matched.${RESET}"
else
  CURRENT_FILE=""
  while IFS= read -r line; do
    # grep -rn output format:  /path/to/file:LINENO:content
    FILE=$(echo "$line" | cut -d: -f1)
    LINENO=$(echo "$line" | cut -d: -f2)
    CONTENT=$(echo "$line" | cut -d: -f3-)
    REL_FILE="${FILE#$SEARCH_DIR/}"

    # New file — print header
    if [[ "$FILE" != "$CURRENT_FILE" ]]; then
      [[ -n "$CURRENT_FILE" ]] && echo ""
      echo -e "${GREEN}${BOLD}${REL_FILE}${RESET}"
      CURRENT_FILE="$FILE"
    fi

    # Highlight match in content (basic, no regex in sed replacement)
    HIGHLIGHTED=$(echo "$CONTENT" | sed "s|${WORD}|$(printf "${RED}${BOLD}")&$(printf "${RESET}")|g")
    echo -e "  ${CYAN}L${LINENO}${RESET}  $HIGHLIGHTED"
    (( MATCH_COUNT++ )) || true
  done <<< "$RESULTS"

  echo -e ""
  echo -e "─────────────────────────────────────────────────────────────────────"
  echo -e "${BOLD}${MATCH_COUNT} match(es) found.${RESET}"
fi

echo ""