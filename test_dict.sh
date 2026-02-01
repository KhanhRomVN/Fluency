#!/bin/bash

# Dictionary Test Script
# Tests 4 dictionary services with a given word
# Usage: ./test_dict.sh [word]
# Default word: "run"

WORD="${1:-run}"
OUTPUT_DIR="dict-result"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Testing dictionary services for word: $WORD"
echo "Output directory: $OUTPUT_DIR"
echo "----------------------------------------"

# 1. FreeDict API
echo "1. Fetching from FreeDict API..."
curl -s "https://freedictionaryapi.com/api/v1/entries/en/$WORD?translations=true" \
  -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
  -o "$OUTPUT_DIR/freedict.json"

if [ -s "$OUTPUT_DIR/freedict.json" ]; then
  echo "   ✓ FreeDict: Success ($(wc -c < "$OUTPUT_DIR/freedict.json") bytes)"
else
  echo "   ✗ FreeDict: Failed or empty response"
fi

# 2. DictAPI
echo "2. Fetching from DictAPI..."
curl -s "https://api.dictionaryapi.dev/api/v2/entries/en/$WORD" \
  -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
  -o "$OUTPUT_DIR/dictapi.json"

if [ -s "$OUTPUT_DIR/dictapi.json" ]; then
  echo "   ✓ DictAPI: Success ($(wc -c < "$OUTPUT_DIR/dictapi.json") bytes)"
else
  echo "   ✗ DictAPI: Failed or empty response"
fi

# 3. Cambridge Dictionary
echo "3. Fetching from Cambridge Dictionary..."
curl -s "https://dictionary.cambridge.org/dictionary/english/$WORD" \
  -H "authority: dictionary.cambridge.org" \
  -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8" \
  -H "accept-language: en-US,en;q=0.9" \
  -H "cache-control: max-age=0" \
  -H "sec-ch-ua: \"Chromium\";v=\"142\", \"Google Chrome\";v=\"142\", \"Not_A Brand\";v=\"99\"" \
  -H "sec-ch-ua-mobile: ?0" \
  -H "sec-ch-ua-platform: \"Linux\"" \
  -H "sec-fetch-dest: document" \
  -H "sec-fetch-mode: navigate" \
  -H "sec-fetch-site: same-origin" \
  -H "sec-fetch-user: ?1" \
  -H "upgrade-insecure-requests: 1" \
  -H "user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36" \
  -o "$OUTPUT_DIR/cambridge.json"

if [ -s "$OUTPUT_DIR/cambridge.json" ]; then
  echo "   ✓ Cambridge: Success ($(wc -c < "$OUTPUT_DIR/cambridge.json") bytes)"
else
  echo "   ✗ Cambridge: Failed or empty response"
fi

# 4. Laban Dictionary
echo "4. Fetching from Laban Dictionary..."
curl -s "https://dict.laban.vn/find?type=1&query=$WORD" \
  -H "authority: dict.laban.vn" \
  -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8" \
  -H "accept-language: en-US,en;q=0.9" \
  -H "cache-control: max-age=0" \
  -H "referer: https://dict.laban.vn/" \
  -H "sec-ch-ua: \"Chromium\";v=\"142\", \"Google Chrome\";v=\"142\", \"Not_A Brand\";v=\"99\"" \
  -H "sec-ch-ua-mobile: ?0" \
  -H "sec-ch-ua-platform: \"Linux\"" \
  -H "sec-fetch-dest: document" \
  -H "sec-fetch-mode: navigate" \
  -H "sec-fetch-site: same-origin" \
  -H "sec-fetch-user: ?1" \
  -H "upgrade-insecure-requests: 1" \
  -H "user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36" \
  -o "$OUTPUT_DIR/laban.json"

if [ -s "$OUTPUT_DIR/laban.json" ]; then
  echo "   ✓ Laban: Success ($(wc -c < "$OUTPUT_DIR/laban.json") bytes)"
else
  echo "   ✗ Laban: Failed or empty response"
fi

echo "----------------------------------------"
echo "All results saved to: $OUTPUT_DIR/"
echo ""
echo "Files created:"
ls -lh "$OUTPUT_DIR/" | tail -n +2

# Parse HTML to JSON
echo ""
echo "----------------------------------------"
echo "Parsing HTML responses to JSON..."
python3 parse_dict.py "$WORD"

