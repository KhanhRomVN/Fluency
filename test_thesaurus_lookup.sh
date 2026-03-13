#!/bin/bash

# Thesaurus.com Fully Automated Reverse HTTPS Lookup
# No manual browser session required

COOKIE_FILE="thesaurus_session_cookies.txt"
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36"

# Clear old cookies to ensure fresh session
rm -f "$COOKIE_FILE"

echo "=== Phase 1: Initializing Session ==="
# Fetch homepage to get initial cookies (__cf_bm, etc)
curl -s -L -c "$COOKIE_FILE" -A "$USER_AGENT" \
  "https://www.thesaurus.com/" > /dev/null

if [ ! -s "$COOKIE_FILE" ]; then
    echo "Error: Failed to initialize session cookies."
    exit 1
fi
echo "Session initialized. Cookies saved to $COOKIE_FILE."

echo ""
echo "=== Phase 2: Fetching Recommend List for 'play' ==="
RECOMMEND_FILE="thesaurus_play_recommend.json"
curl -s -b "$COOKIE_FILE" -A "$USER_AGENT" \
  -H "referer: https://www.thesaurus.com/" \
  "https://www.thesaurus.com/api/search/combined?q=play" -o "$RECOMMEND_FILE"

# Extract the first slug using Python
FIRST_SLUG=$(python3 -c "
import json, sys
try:
    with open('$RECOMMEND_FILE', 'r') as f:
        data = json.load(f)
    if isinstance(data, list) and len(data) > 0:
        print(data[0].get('slug'))
except Exception as e:
    sys.exit(1)
")

if [ -z "$FIRST_SLUG" ]; then
    echo "Error: No recommendations found or failed to parse JSON."
    exit 1
fi

echo "First recommendation found: $FIRST_SLUG"

echo ""
echo "=== Phase 3: Fetching Details for '$FIRST_SLUG' ==="
DETAIL_FILE="thesaurus_detail_${FIRST_SLUG}.html"
curl -s -L -b "$COOKIE_FILE" -A "$USER_AGENT" \
  -H "referer: https://www.thesaurus.com/" \
  --compressed \
  "https://www.thesaurus.com/browse/$FIRST_SLUG" -o "$DETAIL_FILE"

if [ -s "$DETAIL_FILE" ]; then
    echo "Success! Detail page saved to $DETAIL_FILE."
    echo "Extracting Page Title:"
    grep -z -oP '<title>\s*\K(.*?)(?=\s*</title>)' "$DETAIL_FILE" | tr -d '\0'
    echo ""
    echo "Extracting Meta Description:"
    grep -oP '<meta name="description" content=['"'"']\K[^'"'"']+' "$DETAIL_FILE"
else
    echo "Error: Failed to fetch detail page."
    exit 1
fi
