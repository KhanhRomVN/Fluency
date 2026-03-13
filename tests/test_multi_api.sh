#!/bin/bash
# tests/test_multi_api.sh

TERM=$1
if [ -z "$TERM" ]; then
  echo "Usage: $0 <term>"
  exit 1
fi

# Chuyển đổi khoảng trắng sang dấu gạch ngang cho URL
SLUG=${TERM// /-}
# Chuyển đổi khoảng trắng sang %20 cho query param
ENCODED_TERM=${TERM// /%20}

RESULTS_DIR="tests/results/$SLUG"
mkdir -p "$RESULTS_DIR"

USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"

echo "--- Testing Term: '$TERM' ---"

# 1. Cambridge (Lấy HTML)
echo "[1/4] Fetching Cambridge (HTML)..."
curl -s -L -A "$USER_AGENT" \
  -H "authority: dictionary.cambridge.org" \
  -H "accept: text/html" \
  -H "referer: https://dictionary.cambridge.org/" \
  "https://dictionary.cambridge.org/dictionary/english/$SLUG" -o "$RESULTS_DIR/cambridge.html"

# 2. Thesaurus (Lấy HTML từ page chi tiết)
echo "[2/4] Fetching Thesaurus (HTML)..."
# Bước 1: Lấy Slug từ API recommend
RECOMMEND_JSON=$(curl -s -L -A "$USER_AGENT" \
  -H "referer: https://www.thesaurus.com/" \
  "https://www.thesaurus.com/api/search/combined?q=$ENCODED_TERM")

THES_SLUG=$(echo "$RECOMMEND_JSON" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    if isinstance(data, list) and len(data) > 0:
        print(data[0].get('slug'))
except:
    pass
")

if [ -z "$THES_SLUG" ]; then
  # Fallback về slug mặc định nếu không lấy được từ API
  THES_SLUG=$SLUG
fi

echo "   Using slug: $THES_SLUG"

# Bước 2: Tải trang chi tiết
curl -s -L -A "$USER_AGENT" \
  -H "referer: https://www.thesaurus.com/" \
  "https://www.thesaurus.com/browse/$THES_SLUG" -o "$RESULTS_DIR/thesaurus.html"

# 3. FreeDict (Lấy JSON)
echo "[3/4] Fetching FreeDict (JSON)..."
curl -s -L "https://freedictionaryapi.com/api/v1/entries/en/$ENCODED_TERM?translations=true" -o "$RESULTS_DIR/freedict.json"

# 4. DictAPI (Lấy JSON)
echo "[4/4] Fetching DictAPI (JSON)..."
curl -s -L "https://api.dictionaryapi.dev/api/v2/entries/en/$ENCODED_TERM" -o "$RESULTS_DIR/dictapi.json"

echo "Done! Data saved in: $RESULTS_DIR"
echo ""

# 5. Parse HTML to JSON
echo "[5/4] Parsing HTML results to JSON..."
dart tests/parse_results.dart "$RESULTS_DIR"

# 6. Merge all JSON results
echo "[6/4] Merging all JSON results into merged.json..."
dart tests/merge_results.dart "$RESULTS_DIR"

ls -lh "$RESULTS_DIR"
