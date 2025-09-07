#!/bin/bash

# This script updates the addon on workshop with gmpublish.
# This script is only intended to be run on Windows, with GitBash, by someone with contributor access to the workshop.
#
# 1.    Ensure you have the path to the garrysmod bin directory setup in the .env file.
#
# 2.    Make this script executable:
#       chmod +x ./update-workshop.sh
#
# 3.    Run this script with the update message as the first argument, e.g:
#       ./update-workshop.sh "Updated materials and models"
#
# Add --dry-run flag to see what commands would be executed without running them:
#       ./update-workshop.sh "Updated materials and models" --dry-run

SCRIPT_BASEDIR=$(dirname "$0")
CONFIG_FILE="$SCRIPT_BASEDIR/.env"

# Check for dry-run flag
DRY_RUN=false
if [[ "$*" == *"--dry-run"* ]]; then
    DRY_RUN=true
    echo "DRY RUN MODE - Publish command will not be executed"
    echo "==================================================="
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found at $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

if [ -z "$GM_BIN_PATH" ]; then
    echo "Error: Garry's Mod bin path (GM_BIN_PATH) not found in $CONFIG_FILE"
    exit 1
fi

WORKSHOP_ID="2313854259"
SOURCE_CONTENT_DIR="$SCRIPT_BASEDIR/.."

# Remove --dry-run from arguments to get the actual message
ARGS=("$@")
FILTERED_ARGS=()
for arg in "${ARGS[@]}"; do
    if [[ "$arg" != "--dry-run" ]]; then
        FILTERED_ARGS+=("$arg")
    fi
done

if [ ${#FILTERED_ARGS[@]} -eq 0 ]; then
    echo "Error: Update message required as first argument"
    exit 1
fi

UPDATE_MESSAGE="${FILTERED_ARGS[0]}"

# Check if source content directory exists
if [ ! -d "$SOURCE_CONTENT_DIR" ]; then
    echo "Error: Source content directory not found at $SOURCE_CONTENT_DIR"
    exit 1
fi

# Create the GMA file
echo ""
echo "Creating GMA file..."
"$GM_BIN_PATH/gmad.exe" create -folder "$SOURCE_CONTENT_DIR" -out "$SOURCE_CONTENT_DIR/minigolf.gma"

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "DRY RUN MODE - The following publish command would be executed:"
    echo "============================================================="
    echo "Publish to workshop:"
    echo "   \"$GM_BIN_PATH/gmpublish.exe\" update -id \"$WORKSHOP_ID\" -addon \"$SOURCE_CONTENT_DIR/minigolf.gma\" -changes \"$UPDATE_MESSAGE\""
    echo ""
    echo "DRY RUN COMPLETE - GMA file created but not published"
else
    # Publish the GMA file to the workshop
    echo "Publishing to workshop..."
    "$GM_BIN_PATH/gmpublish.exe" update -id "$WORKSHOP_ID" -addon "$SOURCE_CONTENT_DIR/minigolf.gma" -changes "$UPDATE_MESSAGE"
    echo "Workshop content update completed!"
fi
