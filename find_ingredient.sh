#!/usr/bin/env bash
# Usage: ./find_ingredient.sh -i "<ingredient>" -d /path/to/folder
# Input: products.csv (TSV) must exist inside the folder.
# Output: product_name<TAB>code for matches, then a final count line.

set -euo pipefail
export CSVKIT_FIELD_SIZE_LIMIT=$((1024 * 1024 * 1024)) # allow very large fields

INGREDIENT=""
DATA_DIR=""
CSV=""

usage() {
  echo "Usage: $0 -i \"<ingredient>\" -d /path/to/folder"
  echo "  -i   Ingredient to search (case-insensitive)"
  echo "  -d   Folder containing products.csv (tab-separated)"
  echo "  -h   Show this help"
}

# Parse flags
while getopts ":i:d:h" opt; do
  case "$opt" in
    i) INGREDIENT="$OPTARG" ;;
    d) DATA_DIR="$OPTARG" ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

# Validate inputs
[ -z "${INGREDIENT:-}" ] && { echo "ERROR: -i <ingredient> is required" >&2; usage; exit 1; }
[ -z "${DATA_DIR:-}" ] && { echo "ERROR: -d /path/to/folder is required" >&2; usage; exit 1; }

CSV="$DATA_DIR/products.csv"
[ -s "$CSV" ] || { echo "ERROR: $CSV not found or empty." >&2; exit 1; }

# Check csvkit tools
for cmd in csvcut csvgrep csvformat; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: $cmd not found. Please install csvkit." >&2; exit 1; }
done


# Pipeline: select, filter, reformat
tmp_matches="$(mktemp)"
csvcut -t -c ingredients_text,product_name,code "$tmp_csv" \
  | csvgrep -t -c ingredients_text -r "(?i)${INGREDIENT}" \
  | csvcut -c product_name,code \
  | csvformat -T \
  | tail -n +2 \
  | tee "$tmp_matches"

count="$(wc -l < "$tmp_matches" | tr -d ' ')"
echo "----"
echo "Found ${count} product(s) containing: \"${INGREDIENT}\""

# Cleanup
rm -f "$tmp_csv" "$tmp_matches"

