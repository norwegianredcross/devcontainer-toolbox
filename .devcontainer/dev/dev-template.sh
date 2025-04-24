#!/bin/bash
# file: dev-template.sh
# Description: This script is a self-updating template initializer for the Urbalurba Developer Platform.
#              It automatically fetches the latest version of itself from the repository before running,
#              ensuring you always have the most up-to-date version.
#
# Purpose: This script helps developers set up new projects using predefined templates from the
#          urbalurba-dev-templates repository. It handles template selection, file copying,
#          and configuration setup.
#
# Usage: ./dev-template.sh [template-name] [options]
#
# Arguments:
#   template-name    : Optional. Name of the template to use. If not provided, a list of
#                     available templates will be shown for selection.
#
# Options:
#   --skip-update    : Skip checking for updates to the script
#   --force-update   : Force update to the latest version of the script
#   --version        : Show current version of the script and exit
#
# Examples:
#   # Show available templates and select one interactively
#   ./dev-template.sh
#
#   # Use a specific template directly
#   ./dev-template.sh typescript-basic-webserver
#
#   # Skip update check and use a specific template
#   ./dev-template.sh typescript-basic-webserver --skip-update
#
#   # Force update the script to latest version
#   ./dev-template.sh --force-update
#
#   # Show current version
#   ./dev-template.sh --version
#
# Update Mechanism:
#   - The script checks for updates every time it runs
#   - It downloads the latest version from the repository
#   - If a newer version is found, it automatically updates itself
#   - After updating, it reruns with the same arguments
#   - The update process includes retry logic for network issues
#
# Template Process:
#   1. Checks for script updates (unless --skip-update is used)
#   2. Updates devcontainer files if needed
#   3. Detects GitHub repository information
#   4. Clones the template repository
#   5. Selects a template (interactively or from argument)
#   6. Verifies template structure
#   7. Copies template files to current directory
#   8. Sets up GitHub workflows
#   9. Merges .gitignore files
#   10. Processes template variables
#
# Exit Codes:
#   0 - Success
#   1 - Error in script execution
#   2 - Template not found
#   3 - Update check failed
#   4 - Devcontainer update failed
#
# Version: 1.0.0
#------------------------------------------------------------------------------
set -e

# Script version - increment this when making changes
SCRIPT_VERSION="1.0.0"

#------------------------------------------------------------------------------
# Fetch and update the script from repository
#------------------------------------------------------------------------------
function update_script() {
  # Check if update should be skipped
  if [[ "$SKIP_UPDATE" == "true" ]]; then
    echo "ℹ️ Update check skipped"
    return 0
  fi

  echo "🔄 Checking for script updates..."
  
  # Template variables
  TEMPLATE_OWNER="terchris"
  TEMPLATE_REPO_NAME="urbalurba-dev-templates"
  TEMPLATE_REPO_URL="https://raw.githubusercontent.com/$TEMPLATE_OWNER/$TEMPLATE_REPO_NAME/main/dev-template.sh"
  
  # Create temporary file
  TEMP_SCRIPT=$(mktemp)
  
  # Download the latest version with retry logic
  MAX_RETRIES=3
  RETRY_COUNT=0
  DOWNLOAD_SUCCESS=false
  
  while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s "$TEMPLATE_REPO_URL" > "$TEMP_SCRIPT"; then
      DOWNLOAD_SUCCESS=true
      break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
      echo "⚠️ Download failed, retrying ($RETRY_COUNT/$MAX_RETRIES)..."
      sleep 2
    fi
  done
  
  if [ "$DOWNLOAD_SUCCESS" = false ]; then
    echo "❌ Failed to check for updates after $MAX_RETRIES attempts"
    rm "$TEMP_SCRIPT"
    return 1
  fi
  
  # Extract version from downloaded script
  NEW_VERSION=$(grep -m 1 "SCRIPT_VERSION=" "$TEMP_SCRIPT" | cut -d'"' -f2)
  
  if [ -z "$NEW_VERSION" ]; then
    echo "⚠️ Could not determine version of downloaded script"
    rm "$TEMP_SCRIPT"
    return 1
  fi
  
  # Compare versions or force update
  if [ "$FORCE_UPDATE" = true ] || [ "$NEW_VERSION" != "$SCRIPT_VERSION" ]; then
    echo "📥 New version available ($NEW_VERSION), updating..."
    # Make the temp file executable
    chmod +x "$TEMP_SCRIPT"
    # Replace the current script
    if mv "$TEMP_SCRIPT" "$0"; then
      echo "✅ Script updated successfully to version $NEW_VERSION"
      # Rerun the updated script with original arguments
      exec "$0" "${ORIGINAL_ARGS[@]}"
    else
      echo "❌ Failed to update script"
      rm "$TEMP_SCRIPT"
      return 1
    fi
  else
    echo "✅ Script is up to date (version $SCRIPT_VERSION)"
    rm "$TEMP_SCRIPT"
  fi
}

#------------------------------------------------------------------------------
# Display version information
#------------------------------------------------------------------------------
function show_version() {
  echo "dev-template.sh version $SCRIPT_VERSION"
  exit 0
}

#------------------------------------------------------------------------------
# Process command line arguments
#------------------------------------------------------------------------------
function process_args() {
  ORIGINAL_ARGS=("$@")
  TEMPLATE_NAME=""
  SKIP_UPDATE=false
  FORCE_UPDATE=false
  
  while [[ $# -gt 0 ]]; do
    case $1 in
      --skip-update)
        SKIP_UPDATE=true
        shift
        ;;
      --force-update)
        FORCE_UPDATE=true
        shift
        ;;
      --version)
        show_version
        ;;
      *)
        if [[ "$1" != --* ]]; then
          TEMPLATE_NAME="$1"
        fi
        shift
        ;;
    esac
  done
}

#------------------------------------------------------------------------------
# Display banner and intro message
#------------------------------------------------------------------------------
function display_intro() {
  echo ""
  echo "🛠️  Urbalurba Developer Platform - Project Initializer"
  echo "This script will set up your project with the necessary files and configurations."
  echo "-----------------------------------------------------"
}

#------------------------------------------------------------------------------
# Detect GitHub user and repository information
#------------------------------------------------------------------------------
function detect_github_info() {
  GITHUB_REMOTE=$(git remote get-url origin)
  GITHUB_USERNAME=$(echo "$GITHUB_REMOTE" | sed -n 's/.*github.com[:/]\(.*\)\/.*/\1/p')
  REPO_NAME=$(basename -s .git "$GITHUB_REMOTE")

  if [[ -z "$GITHUB_USERNAME" || -z "$REPO_NAME" ]]; then
    echo "❌ Could not determine GitHub username or repo name"
    exit 1
  fi

  echo "✅ GitHub user: $GITHUB_USERNAME"
  echo "✅ Repo name: $REPO_NAME"
}

#------------------------------------------------------------------------------
# Clone the templates repository
#------------------------------------------------------------------------------
function clone_template_repo() {
  # Template variables
  TEMPLATE_OWNER="terchris"
  TEMPLATE_REPO_NAME="urbalurba-dev-templates"
  TEMPLATE_REPO_URL="https://github.com/$TEMPLATE_OWNER/$TEMPLATE_REPO_NAME"

  # Create temporary directory
  TEMP_DIR=$(mktemp -d)
  echo "Cloning template repository to temp folder: $TEMP_DIR"
  cd "$TEMP_DIR"

  # Clone the template repository
  echo "Cloning from $TEMPLATE_REPO_URL..."
  git clone $TEMPLATE_REPO_URL

  # Check if the templates directory exists
  if [ ! -d "$TEMPLATE_REPO_NAME/templates" ]; then
    echo "❌ Templates directory not found in repository."
    echo "Removing template repository folder: $TEMP_DIR"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
}

#------------------------------------------------------------------------------
# Get available templates and select one
#------------------------------------------------------------------------------
function select_template() {
  # Get a list of available templates
  TEMPLATES=()
  for dir in "$TEMPLATE_REPO_NAME/templates"/*; do
    if [ -d "$dir" ]; then
      TEMPLATE_NAME=$(basename "$dir")
      TEMPLATES+=("$TEMPLATE_NAME")
    fi
  done

  if [ ${#TEMPLATES[@]} -eq 0 ]; then
    echo "❌ No templates found in repository."
    echo "Removing template repository folder: $TEMP_DIR"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  # If a template name is provided as a parameter, use it
  # Otherwise, list available templates and let the user select one
  if [ -n "$1" ]; then
    TEMPLATE_NAME="$1"
    # Check if the specified template exists
    if [ ! -d "$TEMPLATE_REPO_NAME/templates/$TEMPLATE_NAME" ]; then
      echo "❌ Template '$TEMPLATE_NAME' not found in repository."
      echo "Available templates:"
      for i in "${!TEMPLATES[@]}"; do
        echo "  $(($i + 1)). ${TEMPLATES[$i]}"
      done
      echo "Removing template repository folder: $TEMP_DIR"
      rm -rf "$TEMP_DIR"
      exit 1
    fi
  else
    # No template specified, show list
    echo "Available templates:"
    for i in "${!TEMPLATES[@]}"; do
      echo "  $(($i + 1)). ${TEMPLATES[$i]}"
    done
    
    # Ask user to select a template
    while true; do
      echo ""
      read -p "Select template (1-${#TEMPLATES[@]}): " TEMPLATE_SELECTION
      
      # Check if the input is a number
      if [[ "$TEMPLATE_SELECTION" =~ ^[0-9]+$ ]]; then
        # Check if the number is in range
        if [ "$TEMPLATE_SELECTION" -ge 1 ] && [ "$TEMPLATE_SELECTION" -le ${#TEMPLATES[@]} ]; then
          # Convert selection to array index (0-based)
          TEMPLATE_INDEX=$(($TEMPLATE_SELECTION - 1))
          TEMPLATE_NAME="${TEMPLATES[$TEMPLATE_INDEX]}"
          break
        fi
      fi
      
      echo "❌ Invalid selection. Please enter a number between 1 and ${#TEMPLATES[@]}."
    done
  fi

  echo "Selected template: $TEMPLATE_NAME"
  TEMPLATE_PATH="$TEMPLATE_REPO_NAME/templates/$TEMPLATE_NAME"
}

#------------------------------------------------------------------------------
# Verify template structure and required files
#------------------------------------------------------------------------------
function verify_template() {
  echo "Verifying template structure..."

  # Check for the manifests directory
  if [ ! -d "$TEMPLATE_PATH/manifests" ]; then
    echo "❌ Required directory 'manifests' not found in template."
    echo "Removing template repository folder: $TEMP_DIR"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  # Check for deployment.yaml
  if [ ! -f "$TEMPLATE_PATH/manifests/deployment.yaml" ]; then
    echo "❌ Required file 'manifests/deployment.yaml' not found in template."
    echo "Removing template repository folder: $TEMP_DIR"
    rm -rf "$TEMP_DIR"
    exit 1
  fi

  echo "✅ Required template structure verified"
}

#------------------------------------------------------------------------------
# Copy template files to project directory
#------------------------------------------------------------------------------
function copy_template_files() {
  echo "Extracting template $TEMPLATE_NAME"
  # Copy all visible files and directories
  cp -r "$TEMPLATE_PATH/"* "$OLDPWD/"

  # Copy urbalurba-scripts directory from the repository root
  if [ -d "$TEMPLATE_REPO_NAME/urbalurba-scripts" ]; then
    echo "Setting up urbalurba-scripts for project integration..."
    # Create urbalurba-scripts directory if it doesn't exist
    mkdir -p "$OLDPWD/urbalurba-scripts"
    
    # Copy all files from urbalurba-scripts directory
    cp -r "$TEMPLATE_REPO_NAME/urbalurba-scripts/"* "$OLDPWD/urbalurba-scripts/"
    
    # Make sure script files are executable
    chmod +x "$OLDPWD/urbalurba-scripts/"*.sh 2>/dev/null || true
    echo "✅ Added urbalurba-scripts"
  else
    echo "❌ urbalurba-scripts directory not found in template repository"
    echo "Warning: The project may not function correctly without these scripts"
  fi
}

#------------------------------------------------------------------------------
# Copy and set up GitHub workflow files
#------------------------------------------------------------------------------
function setup_github_workflows() {
  # Handle special directories that might be hidden
  # Create .github directory if needed
  if [ -d "$TEMPLATE_PATH/.github" ]; then
    echo "Setting up .github directory and workflows..."
    
    # Create .github/workflows directory if it doesn't exist
    mkdir -p "$OLDPWD/.github/workflows"
    
    # Copy all files from .github directory preserving structure
    cp -r "$TEMPLATE_PATH/.github"/* "$OLDPWD/.github/"
    echo "✅ Added GitHub files and workflows"
  else
    # Check if there's a common workflows directory in the template repo
    if [ -d "$TEMPLATE_REPO_NAME/.github/workflows" ]; then
      echo "Setting up common GitHub workflows..."
      mkdir -p "$OLDPWD/.github/workflows"
      cp -r "$TEMPLATE_REPO_NAME/.github/workflows"/* "$OLDPWD/.github/workflows/"
      echo "✅ Added common GitHub workflows"
    fi
  fi
}

#------------------------------------------------------------------------------
# Merge gitignore files
#------------------------------------------------------------------------------
function merge_gitignore() {
  # Handle .gitignore merging
  if [ -f "$TEMPLATE_PATH/.gitignore" ]; then
    echo "Merging .gitignore files..."
    
    # Check if destination .gitignore exists
    if [ -f "$OLDPWD/.gitignore" ]; then
      echo "Existing .gitignore found, merging with template .gitignore"
      
      # Create temporary files
      TEMP_MERGED=$(mktemp)
      
      # Copy existing .gitignore entries to temp file
      cat "$OLDPWD/.gitignore" > "$TEMP_MERGED"
      
      # Add a newline to ensure separation
      echo "" >> "$TEMP_MERGED"
      
      # Add template .gitignore entries that don't already exist
      echo "# Added from template $TEMPLATE_NAME" >> "$TEMP_MERGED"
      
      while IFS= read -r line; do
        # Skip empty lines and comments
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
          # Check if this entry already exists in the destination .gitignore
          if ! grep -Fxq "$line" "$OLDPWD/.gitignore"; then
            echo "$line" >> "$TEMP_MERGED"
          fi
        fi
      done < "$TEMPLATE_PATH/.gitignore"
      
      # Replace the existing .gitignore with the merged file
      # Use cat instead of mv to avoid permission issues
      if cat "$TEMP_MERGED" > "$OLDPWD/.gitignore"; then
          echo "✅ Successfully merged .gitignore files"
          # Clean up temp file
          rm -f "$TEMP_MERGED"
      else
          echo "❌ Failed to update .gitignore file: Permission denied"
          rm -f "$TEMP_MERGED"
          exit 1
      fi
    else
      echo "No existing .gitignore, copying template .gitignore"
      cp "$TEMPLATE_PATH/.gitignore" "$OLDPWD/"
    fi
  fi
}

#------------------------------------------------------------------------------
# Replace placeholders in a single file
#------------------------------------------------------------------------------
function replace_placeholders() {
  local file=$1
  local temp_file=$(mktemp)
  
  if [ -f "$file" ]; then
    cat "$file" | \
      sed -e "s|{{GITHUB_USERNAME}}|$GITHUB_USERNAME|g" \
          -e "s|{{REPO_NAME}}|$REPO_NAME|g" > "$temp_file"
    
    if cat "$temp_file" > "$file"; then
      echo "✅ Updated $(basename "$file")"
    else
      echo "❌ Failed to update $(basename "$file")"
      return 1
    fi
    rm "$temp_file"
  else
    echo "⚠️ File not found: $file"
    return 1
  fi
  
  return 0
}

#------------------------------------------------------------------------------
# Process only the essential files that need template variable replacement
#------------------------------------------------------------------------------
function process_essential_files() {
  echo "Processing manifest files..."
  # Process manifest files
  if [ -d "manifests" ]; then
    for manifest_file in manifests/*.yaml manifests/*.yml; do
      if [ -f "$manifest_file" ]; then
        replace_placeholders "$manifest_file"
      fi
    done
  else
    echo "⚠️ No manifests directory found"
  fi
  
  echo "Processing GitHub Actions workflows..."
  # Process GitHub workflow files
  if [ -d ".github/workflows" ]; then
    for workflow_file in .github/workflows/*.yaml .github/workflows/*.yml; do
      if [ -f "$workflow_file" ]; then
        replace_placeholders "$workflow_file"
      fi
    done
  else
    echo "⚠️ No GitHub workflows directory found"
  fi
}

#------------------------------------------------------------------------------
# Clean up temporary files and display completion message
#------------------------------------------------------------------------------
function cleanup_and_complete() {
  echo "Removing template repository folder: $TEMP_DIR"
  rm -rf "$TEMP_DIR"

  echo ""
  echo "✅ Template setup complete! Next steps:"
  echo "1. Review the files that were created"
  echo "2. Run any setup commands specified in the template's README"
  echo "3. Commit and push your project to GitHub"
  echo ""
}

#------------------------------------------------------------------------------
# Update devcontainer files
#------------------------------------------------------------------------------
function update_devcontainer_files() {
  echo "🔄 Checking for devcontainer file updates..."
  
  # Template variables
  TEMPLATE_OWNER="terchris"
  TEMPLATE_REPO_NAME="urbalurba-dev-templates"
  TEMPLATE_REPO_URL="https://github.com/$TEMPLATE_OWNER/$TEMPLATE_REPO_NAME"
  
  # Create temporary directory
  TEMP_DIR=$(mktemp -d)
  
  # Clone the repository to get latest files
  echo "📥 Fetching latest devcontainer files..."
  if ! git clone --depth 1 "$TEMPLATE_REPO_URL" "$TEMP_DIR" > /dev/null 2>&1; then
    echo "❌ Failed to fetch devcontainer files"
    rm -rf "$TEMP_DIR"
    return 1
  fi
  
  # Check if source directory exists
  SRC_DIR="$TEMP_DIR/developer-toolbox/.devcontainer/additions"
  if [ ! -d "$SRC_DIR" ]; then
    echo "❌ Source directory not found"
    rm -rf "$TEMP_DIR"
    return 1
  fi
  
  # Create target directory if it doesn't exist
  TARGET_DIR=".devcontainer/additions"
  mkdir -p "$TARGET_DIR"
  
  # Track if any files were updated
  FILES_UPDATED=false
  
  # Process each file in the source directory
  for SRC_FILE in "$SRC_DIR"/*.sh; do
    if [ -f "$SRC_FILE" ]; then
      FILENAME=$(basename "$SRC_FILE")
      TARGET_FILE="$TARGET_DIR/$FILENAME"
      
      # Check if file needs to be updated
      if [ ! -f "$TARGET_FILE" ] || ! cmp -s "$SRC_FILE" "$TARGET_FILE"; then
        echo "📝 Updating $FILENAME..."
        cp "$SRC_FILE" "$TARGET_FILE"
        chmod +x "$TARGET_FILE"
        FILES_UPDATED=true
      fi
    fi
  done
  
  # Clean up
  rm -rf "$TEMP_DIR"
  
  if [ "$FILES_UPDATED" = true ]; then
    echo "✅ Devcontainer files updated successfully"
  else
    echo "✅ Devcontainer files are up to date"
  fi
}

#------------------------------------------------------------------------------
# Main execution
#------------------------------------------------------------------------------
# Process command line arguments
process_args "$@"

# Check for updates first
update_script

# Update devcontainer files
update_devcontainer_files

display_intro
detect_github_info
clone_template_repo
select_template "$TEMPLATE_NAME"
verify_template
copy_template_files
setup_github_workflows
merge_gitignore

# Navigate back to the project directory
cd "$OLDPWD"

# Process template files - ONLY the essential ones
echo "Processing template files..."
process_essential_files

cleanup_and_complete