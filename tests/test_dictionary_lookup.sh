#!/bin/bash

# Collins Dictionary Reverse HTTPS Lookup Script
# Bypasses Cloudflare using captured session cookies

COOKIE_FILE="session_cookies.txt"
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36"

if [ ! -f "$COOKIE_FILE" ]; then
    echo "Error: $COOKIE_FILE not found. Please provide valid session cookies."
    exit 1
fi

lookup_autocomplete() {
    local query=$1
    echo "--- Fetching Autocomplete for: $query ---"
    curl -s -A "$USER_AGENT" \
        -b "$COOKIE_FILE" \
        -H "accept: */*" \
        -H "referer: https://www.collinsdictionary.com/" \
        "https://www.collinsdictionary.com/autocomplete/?dictCode=english&q=$query" | python3 -m json.tool | grep "title" | head -n 10
}

lookup_definition() {
    local phrase=$1
    # Convert phrase to URL format (e.g., "play a banjo" -> "play-a-banjo")
    local url_phrase=$(echo "$phrase" | sed 's/ /-/g')
    echo "--- Fetching Definition for: $phrase ---"
    
    local output_file="definition_${url_phrase}.html"
    
    curl -s -A "$USER_AGENT" \
      -b "$COOKIE_FILE" \
      -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7" \
      -H "sec-fetch-site: same-origin" \
      -H "sec-fetch-mode: navigate" \
      -H "sec-fetch-user: ?1" \
      -H "sec-fetch-dest: document" \
      -H "referer: https://www.collinsdictionary.com/" \
      --compressed \
      "https://www.collinsdictionary.com/dictionary/english/${url_phrase}" -o "$output_file"

    if [ -f "$output_file" ]; then
        echo "Saved to $output_file"
        echo "Extracting Page Title:"
        grep -oP '<title>\K[^<]+' "$output_file"
        echo "Extracting Description:"
        grep -oP '<meta name="description" content="\K[^"]+' "$output_file"
    else
        echo "Failed to fetch definition."
    fi
}

# Usage
if [ "$1" == "auto" ]; then
    lookup_autocomplete "$2"
elif [ "$1" == "def" ]; then
    lookup_definition "$2"
else
    echo "Usage: $0 [auto|def] \"phrase\""
    echo "Example: $0 auto \"play\""
    echo "Example: $0 def \"play a banjo\""
fi
