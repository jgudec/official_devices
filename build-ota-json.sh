#!/bin/bash

# This script automates the generation of update JSON files for PixelOS builds.
# It takes the full path to the built ROM zip file as input.

# --- Configuration ---
# Your GitHub repository details for the API
GITHUB_USER="jgudec" # Replace with your GitHub username
GITHUB_REPO="official_devices" # Replace if your fork has a different name
GITHUB_BRANCH="main" # Or 'master' if that's your default branch

# Base URL for your ROM downloads on SourceForge
SOURCEFORGE_BASE_URL="https://sourceforge.net/projects/pixelos-giulia-builds/files/OTA"

# Relative path within your forked repository where JSON files reside
API_DIR="API"

# --- Functions ---

# Function to generate a unique ID (SHA256 hash of the filename, trimmed)
generate_unique_id() {
    local filename="$1"
    echo "$(sha256sum <<< "$filename" | awk '{print $1}' | head -c 64)"
}

# Function to print usage
usage() {
    echo "Usage: $0 <path_to_rom_zip>"
    echo "Example: $0 out/target/product/giulia/PixelOS_giulia-15.0-20250520-1850.zip"
    exit 1
}

# --- Main Script ---

# Check for correct number of arguments
if [ "$#" -ne 1 ]; then
    usage
fi

ROM_PATH="$1"

# Validate if the ROM file exists
if [ ! -f "$ROM_PATH" ]; then
    echo "Error: ROM file not found at '$ROM_PATH'"
    usage
fi

# 1. Extract information from the ROM filename
ROM_FILENAME=$(basename "$ROM_PATH") # e.g., PixelOS_giulia-15.0-20250520-1923.zip
echo "Processing ROM: $ROM_FILENAME"

# Regex to extract date and time (YYYYMMDD-HHMM)
if [[ "$ROM_FILENAME" =~ -([0-9]{8})-([0-9]{4})\.zip$ ]]; then
    DATE_PART="${BASH_REMATCH[1]}" # e.g., 20250520
    TIME_PART="${BASH_REMATCH[2]}" # e.g., 1923
else
    echo "Error: Could not extract date and time (YYYYMMDD-HHMM) from filename: $ROM_FILENAME"
    echo "Expected filename format: PixelOS_giulia-X.X-YYYYMMDD-HHMM.zip"
    exit 1
fi

# Construct datetime string
DATETIME_STRING="${DATE_PART:0:4}-${DATE_PART:4:2}-${DATE_PART:6:2} ${TIME_PART:0:2}:${TIME_PART:2:2}:00"
echo "Parsed datetime string: $DATETIME_STRING"

# --- Use Python to manually calculate Unix timestamp (TO BYPASS SYSTEM TIME BUG) ---
DATETIME_UNIX=""
PYTHON_CMD="import datetime; from datetime import timezone; dt_target = datetime.datetime.strptime('$DATETIME_STRING', '%Y-%m-%d %H:%M:%S'); epoch_start = datetime.datetime(1970, 1, 1, 0, 0, 0, tzinfo=timezone.utc); dt_target_utc = dt_target.replace(tzinfo=timezone.utc); time_difference = dt_target_utc - epoch_start; print(int(time_difference.total_seconds()))"

if command -v python3 &> /dev/null; then
    DATETIME_UNIX=$(python3 -c "$PYTHON_CMD")
    if [ $? -ne 0 ]; then
        echo "Error: Python3 failed to calculate date manually. Falling back to current timestamp (likely incorrect)."
        DATETIME_UNIX=$(date +%s) # This fallback will still use your problematic 'date'
    fi
elif command -v python &> /dev/null; then # Fallback to 'python' if 'python3' isn't primary
    DATETIME_UNIX=$(python -c "$PYTHON_CMD")
    if [ $? -ne 0 ]; then
        echo "Error: Python failed to calculate date manually. Falling back to current timestamp (likely incorrect)."
        DATETIME_UNIX=$(date +%s) # This fallback will still use your problematic 'date'
    fi
else
    echo "Error: Python not found. Cannot perform manual timestamp calculation. Falling back to current Unix timestamp (likely incorrect)."
    DATETIME_UNIX=$(date +%s) # Fallback if no Python is found
fi

echo "DEBUG: Calculated Unix Datetime for update (from filename, manual UTC calculation): $DATETIME_UNIX" # DEBUG LINE

# 2. Get file size
ROM_SIZE=$(stat -c "%s" "$ROM_PATH")
echo "DEBUG: ROM Size: $ROM_SIZE bytes" # DEBUG LINE

# 3. Generate unique ID (SHA256 of filename, trimmed to 64 chars)
UNIQUE_ID=$(generate_unique_id "$ROM_FILENAME")
echo "DEBUG: Generated ID: $UNIQUE_ID" # DEBUG LINE

# 4. Construct URLs
ROM_URL="${SOURCEFORGE_BASE_URL}/${ROM_FILENAME}"
echo "DEBUG: Generated URL: $ROM_URL" # DEBUG LINE

# 5. Device codename (assuming it's 'giulia' based on your example)
DEVICE_CODENAME="giulia"

# --- Update API/updater/giulia.json ---
UPDATER_JSON_PATH="${API_DIR}/updater/${DEVICE_CODENAME}.json"

# Ensure directory exists
mkdir -p "$(dirname "$UPDATER_JSON_PATH")"

# Create a minimal template if the file doesn't exist
if [ ! -f "$UPDATER_JSON_PATH" ]; then
    echo "Warning: ${UPDATER_JSON_PATH} not found. Creating a minimal version."
    cat << EOF > "$UPDATER_JSON_PATH"
{
    "response": []
}
EOF
fi

echo "DEBUG: Content of ${UPDATER_JSON_PATH} BEFORE update:" # DEBUG LINE
cat "$UPDATER_JSON_PATH" # DEBUG LINE

# Use jq to update the existing JSON
# Explicitly use tonumber for datetime to ensure it's treated as a number
jq \
    --arg datetime "$DATETIME_UNIX" \
    --arg filename "$ROM_FILENAME" \
    --arg id "$UNIQUE_ID" \
    --argjson size "$ROM_SIZE" \
    --arg url "$ROM_URL" \
    --arg version "15" \
    '.response[0] = { "datetime": ($datetime | tonumber), "filename": $filename, "id": $id, "size": $size, "url": $url, "version": $version }' \
    "$UPDATER_JSON_PATH" > "${UPDATER_JSON_PATH}.tmp"

# Check if jq command succeeded
if [ $? -ne 0 ]; then
    echo "Error: jq failed to update ${UPDATER_JSON_PATH}. Check JSON syntax or jq command."
    rm -f "${UPDATER_JSON_PATH}.tmp" # Clean up temp file
    exit 1
fi

mv "${UPDATER_JSON_PATH}.tmp" "$UPDATER_JSON_PATH"
echo "Updated ${UPDATER_JSON_PATH}"
echo "DEBUG: Content of ${UPDATER_JSON_PATH} AFTER update:" # DEBUG LINE
cat "$UPDATER_JSON_PATH" # DEBUG LINE


# --- Update API/devices/giulia.json ---
DEVICES_JSON_PATH="${API_DIR}/devices/${DEVICE_CODENAME}.json"

# Ensure directory exists
mkdir -p "$(dirname "$DEVICES_JSON_PATH")"

# Create a minimal template if the file doesn't exist
if [ ! -f "$DEVICES_JSON_PATH" ]; then
    echo "Warning: ${DEVICES_JSON_PATH} not found. Creating a minimal version."
    echo "Please fill in 'maintainer', 'model', 'vendor', and 'xda' manually later."
    cat << EOF > "$DEVICES_JSON_PATH"
{
    "maintainer": [
        {
            "display_name": "Jeik",
            "telegram": "@JeikIzTaken",
            "github": "jgudec"
        }
    ],
    "model": "Oneplus 13R",
    "vendor": "OnePlus",
    "codename": "giulia",
    "codename_alt": "giulia",
    "active": true,
    "version": "fifteen",
    "release": "monthly",
    "last_updated": "",
    "download_link": "",
    "archive": "https://sourceforge.net/projects/pixelos-giulia-builds/files/",
    "xda": "https://xdaforums.com/t/unofficial-15-pixelos-for-oneplus-13r-ace-5.4737323/"
}
EOF
fi

# Update fields using jq
jq \
    --arg dl_link "$ROM_URL" \
    --arg last_upd "$(date '+%d %b %Y')" \
    '.download_link = $dl_link | .last_updated = $last_upd' \
    "$DEVICES_JSON_PATH" > "${DEVICES_JSON_PATH}.tmp"

# Check if jq command succeeded
if [ $? -ne 0 ]; then
    echo "Error: jq failed to update ${DEVICES_JSON_PATH}. Check JSON syntax or jq command."
    rm -f "${DEVICES_JSON_PATH}.tmp" # Clean up temp file
    exit 1
fi

mv "${DEVICES_JSON_PATH}.tmp" "$DEVICES_JSON_PATH"
echo "Updated ${DEVICES_JSON_PATH}"

echo "Script finished successfully!"
echo "You can now commit and push the changes to your fork:"
echo "git add ${API_DIR}/updater/${DEVICE_CODENAME}.json ${API_DIR}/devices/${DEVICE_CODENAME}.json"
echo "git commit -m \"feat: Update ${DEVICE_CODENAME} ROM info for ${ROM_FILENAME}\""
echo "git push origin $GITHUB_BRANCH"
