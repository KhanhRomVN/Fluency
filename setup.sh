#!/bin/bash

# setup.sh
# Script to setup a new Flutter project from Fluency
# Usage: curl -sL <url> | bash

set -e

# Default Configuration
DEFAULT_REPO_URL="https://github.com/KhanhRomVN/Fluency.git"
DEFAULT_BRANCH="main"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=================================================================${NC}"
echo -e "${BLUE}       Fluency Setup - Initialize New Project            ${NC}"
echo -e "${BLUE}=================================================================${NC}"

# Check dependencies
for cmd in git sed curl; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}Error: $cmd is required but not installed.${NC}"
        exit 1
    fi
done

# --- Step 1: User Inputs ---

# 1. App Display Name
echo -e "\n${GREEN}[1/4] Enter App Display Name${NC} (e.g., 'My Super App')"
read -p "Display Name: " APP_DISPLAY_NAME < /dev/tty
if [ -z "$APP_DISPLAY_NAME" ]; then
    echo -e "${RED}Display Name cannot be empty.${NC}"
    exit 1
fi

# 2. App Name (internal, snake_case)
# Helper to convert to snake_case simple version
DEFAULT_APP_NAME=$(echo "$APP_DISPLAY_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
echo -e "\n${GREEN}[2/4] Enter App Name${NC} (snake_case, no special chars) [default: $DEFAULT_APP_NAME]"
read -p "App Name: " INPUT_APP_NAME < /dev/tty
APP_NAME="${INPUT_APP_NAME:-$DEFAULT_APP_NAME}"

# Validate App Name (simple check)
if [[ ! "$APP_NAME" =~ ^[a-z0-9_]+$ ]]; then
    echo -e "${RED}Invalid App Name. Must be lowercase, numbers, and underscores only.${NC}"
    exit 1
fi

# 3. Author / Organization
echo -e "\n${GREEN}[3/4] Enter Author Name${NC}"
read -p "Author: " AUTHOR_NAME < /dev/tty

# 4. Package Name
DEFAULT_PACKAGE_NAME="com.example.${APP_NAME}"
echo -e "\n${GREEN}[4/4] Enter Package Name${NC} [default: $DEFAULT_PACKAGE_NAME]"
read -p "Package Name: " INPUT_PACKAGE_NAME < /dev/tty
PACKAGE_NAME="${INPUT_PACKAGE_NAME:-$DEFAULT_PACKAGE_NAME}"

# 5. Repo URL (Fixed)
REPO_URL="$DEFAULT_REPO_URL"

# --- Confirm & Folder Selection ---

echo -e "\n${BLUE}Summary:${NC}"
echo "Display Name: $APP_DISPLAY_NAME"
echo "App Name:     $APP_NAME"
echo "Author:       $AUTHOR_NAME"
echo "Package Name: $PACKAGE_NAME"
echo "Repo URL:     $REPO_URL"

echo -e "\n${GREEN}Select installation mode:${NC}"
echo "1) Create new folder '$APP_NAME'"
echo "2) Overwrite current folder content (WARNING possible data loss)"
read -p "Choice [1/2]: " INSTALL_MODE < /dev/tty

TARGET_DIR="."

if [ "$INSTALL_MODE" = "1" ] || [ -z "$INSTALL_MODE" ]; then
    TARGET_DIR="$APP_NAME"
    if [ -d "$TARGET_DIR" ]; then
        echo -e "${RED}Directory '$TARGET_DIR' already exists.${NC}"
        read -p "Overwrite? (y/n): " OVERWRITE_CONFIRM < /dev/tty
        if [ "$OVERWRITE_CONFIRM" != "y" ]; then
            echo "Aborted."
            exit 1
        fi
        rm -rf "$TARGET_DIR"
    fi
    mkdir -p "$TARGET_DIR"
elif [ "$INSTALL_MODE" = "2" ]; then
    echo -e "${RED}Warning: Installing in current directory.${NC}"
    TARGET_DIR="."
else
    echo "Invalid choice."
    exit 1
fi

# --- Step 2: Clone Repository ---

echo -e "\n${BLUE}Cloning repository...${NC}"
# Use a temporary directory for cloning to avoid clutter if using current dir
TEMP_CLONE_DIR=$(mktemp -d)
git clone --depth 1 "$REPO_URL" "$TEMP_CLONE_DIR"

# Validate template
if [ ! -f "$TEMP_CLONE_DIR/pubspec.yaml" ] || [ ! -d "$TEMP_CLONE_DIR/lib" ]; then
    echo -e "${RED}Error: The repository at '$REPO_URL' does not appear to be a valid Flutter project template.${NC}"
    echo "Missing 'pubspec.yaml' or 'lib' directory."
    rm -rf "$TEMP_CLONE_DIR"
    exit 1
fi

echo -e "${BLUE}Copying files...${NC}"
# Copy files including hidden ones, excluding .git
rsync -a --exclude='.git' "$TEMP_CLONE_DIR/" "$TARGET_DIR/"
rm -rf "$TEMP_CLONE_DIR"

cd "$TARGET_DIR"

# --- Step 3: Renaming & Replacements ---

echo -e "\n${BLUE}Applying customizations...${NC}"

# Detect OS for sed
SED_CMD="sed -i"
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_CMD="sed -i ''"
fi

# Variables for replacement
OLD_APP_NAME="fluency"
OLD_DISPLAY_NAME="Fluency"
OLD_PACKAGE_NAME="com.khanhromvn.fluency"
OLD_PACKAGE_PATH="com/example/fluency"

# Convert PACKAGE_NAME to PATH (replace . with /)
NEW_PACKAGE_PATH="${PACKAGE_NAME//.//}"

# 1. Content Replacement
# Strategy: Find files excluding binary/git/build dirs and run sed

echo "Updating content in files..."

# Helper to escape sed strings
escape_sed() {
    echo "$1" | sed -e 's/[]\/$*.^[]/\\&/g'
}

ESC_OLD_APP_NAME=$(escape_sed "$OLD_APP_NAME")
ESC_NEW_APP_NAME=$(escape_sed "$APP_NAME")

ESC_OLD_DISPLAY_NAME=$(escape_sed "$OLD_DISPLAY_NAME")
# For PascalCase AppName used in classes (e.g. FluencyApp -> MyAppApp)
# Construct PascalCase from app_name
IFS='_' read -ra ADDR <<< "$APP_NAME"
PASCAL_CASE_APP_NAME=""
for i in "${ADDR[@]}"; do
    PASCAL_CASE_APP_NAME="${PASCAL_CASE_APP_NAME}$(tr '[:lower:]' '[:upper:]' <<< ${i:0:1})${i:1}"
done
ESC_PASCAL_APP_NAME=$(escape_sed "$PASCAL_CASE_APP_NAME")

ESC_APP_DISPLAY_NAME=$(escape_sed "$APP_DISPLAY_NAME")
ESC_AUTHOR=$(escape_sed "$AUTHOR_NAME")
ESC_OLD_PACKAGE_NAME=$(escape_sed "$OLD_PACKAGE_NAME")
ESC_NEW_PACKAGE_NAME=$(escape_sed "$PACKAGE_NAME")

# List of file extensions to process
EXTENSIONS="dart|yaml|xml|gradle|plist|json|html|kt|java|cc|cpp|h|xcconfig|pbxproj|rb|sh|md"

# Replace Package Name First (most specific)
find . -type f -not -path '*/.*' -regextype posix-extended -regex ".*\.($EXTENSIONS)" -exec grep -l "$OLD_PACKAGE_NAME" {} + | xargs -I {} $SED_CMD "s/$ESC_OLD_PACKAGE_NAME/$ESC_NEW_PACKAGE_NAME/g" {}

# Replace Fluency (Display Name / Class Prefix)
# Note: In pubspec description, Android label, etc.
# We might want to be careful. 'Fluency' in text -> Display Name. 'Fluency' in code class -> PascalCase.
# For simplicity in this script, we'll try to handle the obvious ones.
# 1. Renaming 'Fluency' to User's Display Name in UI facing fields (often hard to distinguish without context)
# 2. Renaming 'Fluency' to PascalCase in code.

# Let's replace 'Fluency' with PascalCaseAppName in Dart/Kotlin/Swift/etc files first
find . -type f -not -path '*/.*' -regextype posix-extended -regex ".*\.($EXTENSIONS)" -exec grep -l "$OLD_DISPLAY_NAME" {} + | xargs -I {} $SED_CMD "s/$ESC_OLD_DISPLAY_NAME/$ESC_PASCAL_APP_NAME/g" {}

# Replace 'fluency' (snake_case) with new app_name
find . -type f -not -path '*/.*' -regextype posix-extended -regex ".*\.($EXTENSIONS)" -exec grep -l "$OLD_APP_NAME" {} + | xargs -I {} $SED_CMD "s/$ESC_OLD_APP_NAME/$ESC_NEW_APP_NAME/g" {}

# --- Fix Display Name in UI Configs ---
echo "Updating App Display Name..."

# Android Manifest
# At this point, 'Fluency' has been replaced by PASCAL_CASE_APP_NAME (e.g. TestApp)
# We want 'android:label="TestApp"' -> 'android:label="Test App"'
# Because we replaced the file content, the label is now: android:label="TestApp"
# pattern: android:label="TestApp"
MANIF_FILE="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIF_FILE" ]; then
    $SED_CMD "s/android:label=\"$ESC_PASCAL_APP_NAME\"/android:label=\"$ESC_APP_DISPLAY_NAME\"/g" "$MANIF_FILE"
fi

# iOS Info.plist
# Pattern: <key>CFBundleDisplayName</key>
# 	<string>TestApp</string> (was Fluency)
# We replace TestApp with Display Name inside the string tag *if* followed by CFBundleDisplayName?
# Easier: Just replace the specific string in Info.plist if unique enough or use precise match.
# But 'TestApp' might be used for CFBundleName (bundle binary name) which should probably NOT have spaces?
# Let's try to target CFBundleDisplayName specifically.
IOS_PLIST="ios/Runner/Info.plist"
if [ -f "$IOS_PLIST" ]; then
    # Use perl/python or multiline sed if needed, or simple sed if on same line (it's usually not)
    # <key>CFBundleDisplayName</key>
    # <string>Fluency</string>
    #
    # After our global replace, it is:
    # <key>CFBundleDisplayName</key>
    # <string>TestApp</string>
    #
    # We want to change the value next to CFBundleDisplayName.
    # This is tricky with simple sed.
    # Alternative: Use 'plutil' on mac, but this script runs on linux too.
    # Simple workaround: The global replace made it TestApp.
    # If we assume CFBundleDisplayName is followed by string, we can look for that block.
    # But checking line mapping is hard.
    # 
    # Let's assume the user might edit Info.plist manually for spaces if this is too complex for bash/sed.
    # OR, we blindly replace <string>TestApp</string> with <string>Test App</string> in Info.plist?
    # Risk: CFBundleName (executable) might strip spaces or cause issues if it has spaces?
    # CFBundleName usually matches the executable. Executable should be PascalCase or snake_case with no spaces.
    # Checked Flutter default: CFBundleName is usually the project name (runner).
    #
    # Let's just fix AndroidManifest Label for now as it's a single line property.
    true
fi

# Dart Title (MaterialApp title)
# In lib/app.dart or similar: title: 'TestApp'
# We can try to replace title: 'TestApp' -> title: 'Test App'
find lib -name "*.dart" -exec grep -l "title: '$ESC_PASCAL_APP_NAME'" {} + | xargs -I {} $SED_CMD "s/title: '$ESC_PASCAL_APP_NAME'/title: '$ESC_APP_DISPLAY_NAME'/g" {}


# Fix App Display Name in specific locations if they were blindly replaced by PascalCase or need specific handling
# e.g. pubspec.yaml description: "A new Flutter project."
# Android manifest label="MySuperApp" (from PascalCase replacement above) - This is usually fine.
# If user wants spaces in label:
# We might need to manually set the label in AndroidManifest.xml and Info.plist if we want the Spaced Name.
# Since we replaced Fluency -> PascalCase, the label is now 'MySuperApp' (No Spaces).
# Let's target the label specifically?
# AndroidLabel="android:label=\"$ESC_PASCAL_APP_NAME\""
# NewLabel="android:label=\"$ESC_APP_DISPLAY_NAME\""
# find android -name "AndroidManifest.xml" -exec $SED_CMD "s/$AndroidLabel/$NewLabel/g" {} \;
# Actually, let's just do a specific replacement for the display name if possible.
# But generic replacement is safer for code consistency. User can tweak Display Name in Manifest/Info.plist later easily.

# 2. Directory Renaming

# Android Package struct
echo "Moving Android package files..."
ANDROID_MAIN_SRC="android/app/src/main/kotlin"
OLD_PATH_FULL="$ANDROID_MAIN_SRC/$OLD_PACKAGE_PATH"
NEW_PATH_FULL="$ANDROID_MAIN_SRC/$NEW_PACKAGE_PATH"

if [ -d "$OLD_PATH_FULL" ]; then
    mkdir -p "$NEW_PATH_FULL"
    mv "$OLD_PATH_FULL"/* "$NEW_PATH_FULL/"
    # cleanup empty dirs
    rmdir -p "$OLD_PATH_FULL" 2>/dev/null || true
fi

# 3. File Renaming
# Rename any file containing fluency
find . -depth -name "*$OLD_APP_NAME*" | while read -r FILE; do
    NEW_FILE="$(echo "$FILE" | sed "s/$OLD_APP_NAME/$APP_NAME/g")"
    mv "$FILE" "$NEW_FILE"
done

# Cleanup
echo -e "\n${BLUE}Finalizing...${NC}"
rm -rf .git
git init
git add .
git commit -m "Initial commit: Setup $APP_DISPLAY_NAME ($PACKAGE_NAME)"

echo -e "\n${GREEN}Success! Project setup complete in $(pwd)${NC}"
echo -e "Next steps:"
echo -e "  1. flutter pub get"
echo -e "  2. flutter run"

