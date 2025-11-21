#!/bin/bash
# ========================================================
# Moodle Permissions Manager - Unified Script
# Supports Moodle 4.x and 5.x
# ========================================================

# SCRIPT RELEASE INFORMATION
SCRIPT_RELEASE="25.11"
SCRIPT_AUTHOR="Daniele Lolli (UncleDan)"
SCRIPT_LICENSE="GPL-3.0"

# Default Moodle version (independent from script release)
DEFAULT_MOODLE_VERSION="5"

set -e  # Exit immediately on error

# Default configurations
MOODLE_DIR="/var/www/moodle"
MOODLEDATA_DIR="/var/moodledata"
WWW_USER="www-data"
WWW_GROUP="www-data"

# Determine Moodle version (use default if not specified)
MOODLE_VERSION="$DEFAULT_MOODLE_VERSION"

# Function to show header
show_header() {
    echo "================================================================================"
    echo "Moodle Permissions Manager v${SCRIPT_RELEASE}"
    echo "================================================================================"
    echo "Author: ${SCRIPT_AUTHOR}"
    echo "Release: ${SCRIPT_RELEASE}"
    echo "License: ${SCRIPT_LICENSE}"
    echo "Default Moodle Version: ${DEFAULT_MOODLE_VERSION}.x"
    echo "Selected Moodle Version: ${MOODLE_VERSION}.x"
    echo "================================================================================"
    echo ""
}

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -v, --version           Show version information"
    echo "  -d, --dry-run           Simulate operations without applying changes"
    echo "  -s, --show-perms        Show current permissions without modifying"
    echo "  -f, --fix               Apply permissions fixes (required for changes)"
    echo "  -mp, --moodlepath PATH  Specify Moodle installation path"
    echo "  -md, --moodledata PATH  Specify moodledata path"
    echo "  -mv, --moodleversion VERSION Specify Moodle version (4|5)"
    echo ""
    echo "Examples:"
    echo "  $0                               # Show current permissions (default)"
    echo "  $0 --fix                         # Apply permissions fixes"
    echo "  $0 -f                            # Apply permissions fixes (short)"
    echo "  $0 --fix -mv 5                   # Fix permissions for Moodle 5"
    echo "  $0 --fix -d                      # Dry-run for fix operations"
    echo "  $0 -mv 5 -s                      # Show permissions for Moodle 5"
    echo "  $0 --fix -mp /opt/moodle -mv 5   # Custom path + version + fix"
    echo ""
    echo "Notes:"
    echo "  Default Moodle version: ${DEFAULT_MOODLE_VERSION}.x"
    echo "  Script version: ${SCRIPT_RELEASE}"
    echo "  ⚠️  Without --fix/-f parameter, only shows permissions (safe mode)"
}

# Function to show version
show_version() {
    echo "Moodle Permissions Manager v${SCRIPT_RELEASE}"
    echo "Author: ${SCRIPT_AUTHOR}"
    echo "License: ${SCRIPT_LICENSE}"
    echo "Default Moodle Version: ${DEFAULT_MOODLE_VERSION}.x"
    echo "Compatible with: Moodle 4.x & 5.x, Debian 11/12, Ubuntu 20.04+"
    exit 0
}

# Function to validate Moodle version
validate_moodle_version() {
    local version=$1
    if [[ "$version" != "4" && "$version" != "5" ]]; then
        echo "❌ ERROR: Invalid Moodle version: '$version'"
        echo "   Use '4' for Moodle 4.x or '5' for Moodle 5.x"
        exit 1
    fi
}

# Function to check main directories existence
check_main_directories() {
    if [ ! -d "$MOODLE_DIR" ]; then
        echo "❌ ERROR: Moodle directory not found: $MOODLE_DIR"
        exit 1
    fi
    
    if [ ! -d "$MOODLEDATA_DIR" ]; then
        echo "❌ ERROR: Moodledata directory not found: $MOODLEDATA_DIR"
        exit 1
    fi
}

# Function to show current permissions for Moodle 4
show_moodle4_permissions() {
    echo "🔍 Current Moodle 4 directory permissions:"
    echo ""
    
    echo "📁 Main directories:"
    for dir in "$MOODLE_DIR" "$MOODLEDATA_DIR"; do
        if [ -d "$dir" ]; then
            perms=$(stat -c "%a %U:%G" "$dir")
            echo "   $dir: $perms"
        else
            echo "   $dir: ❌ NOT FOUND"
        fi
    done
    
    echo ""
    echo "📁 Specific Moodle 4 directories:"
    local moodle4_dirs=("cache" "temp" "sessions" "lang" "h5p" "backup" "restore" "trashdir" "webservice" "filedir" "repository" "log")
    
    for dir in "${moodle4_dirs[@]}"; do
        local full_path="$MOODLEDATA_DIR/$dir"
        if [ -d "$full_path" ]; then
            perms=$(stat -c "%a %U:%G" "$full_path")
            echo "   $full_path: $perms"
        else
            echo "   $full_path: 📁 DOES NOT EXIST"
        fi
    done
    
    echo ""
    echo "📁 config.php file:"
    if [ -f "$MOODLE_DIR/config.php" ]; then
        perms=$(stat -c "%a %U:%G" "$MOODLE_DIR/config.php")
        echo "   $MOODLE_DIR/config.php: $perms"
    else
        echo "   $MOODLE_DIR/config.php: ❌ NOT FOUND"
    fi
    
    echo ""
    echo "📁 CLI scripts:"
    if [ -d "$MOODLE_DIR/admin/cli" ]; then
        local cli_scripts=$(find "$MOODLE_DIR/admin/cli" -name "*.php" | head -3)
        if [ -n "$cli_scripts" ]; then
            echo "   First 3 CLI scripts:"
            while IFS= read -r script; do
                if [ -f "$script" ]; then
                    perms=$(stat -c "%a %U:%G" "$script")
                    echo "   $script: $perms"
                fi
            done <<< "$cli_scripts"
        else
            echo "   No CLI scripts found"
        fi
    else
        echo "   CLI directory not found"
    fi
}

# Function to show current permissions for Moodle 5
show_moodle5_permissions() {
    echo "🔍 Current Moodle 5 directory permissions:"
    echo ""
    
    echo "📁 Main directories:"
    for dir in "$MOODLE_DIR" "$MOODLEDATA_DIR"; do
        if [ -d "$dir" ]; then
            perms=$(stat -c "%a %U:%G" "$dir")
            echo "   $dir: $perms"
        else
            echo "   $dir: ❌ NOT FOUND"
        fi
    done
    
    echo ""
    echo "📁 Specific Moodle 5 directories:"
    local moodle5_dirs=("cache" "temp" "lock" "tasks" "localcache" "sessions" "lang" "h5p" "backup" "restore" "trash" "webservice")
    
    for dir in "${moodle5_dirs[@]}"; do
        local full_path="$MOODLEDATA_DIR/$dir"
        if [ -d "$full_path" ]; then
            perms=$(stat -c "%a %U:%G" "$full_path")
            echo "   $full_path: $perms"
        else
            echo "   $full_path: 📁 DOES NOT EXIST"
        fi
    done
    
    echo ""
    echo "📁 config.php file:"
    if [ -f "$MOODLE_DIR/config.php" ]; then
        perms=$(stat -c "%a %U:%G" "$MOODLE_DIR/config.php")
        echo "   $MOODLE_DIR/config.php: $perms"
    else
        echo "   $MOODLE_DIR/config.php: ❌ NOT FOUND"
    fi
    
    echo ""
    echo "📁 CLI scripts:"
    if [ -d "$MOODLE_DIR/admin/cli" ]; then
        local cli_scripts=$(find "$MOODLE_DIR/admin/cli" -name "*.php" | head -3)
        if [ -n "$cli_scripts" ]; then
            echo "   First 3 CLI scripts:"
            while IFS= read -r script; do
                if [ -f "$script" ]; then
                    perms=$(stat -c "%a %U:%G" "$script")
                    echo "   $script: $perms"
                fi
            done <<< "$cli_scripts"
        else
            echo "   No CLI scripts found"
        fi
    else
        echo "   CLI directory not found"
    fi
}

# Function to show current permissions
show_current_permissions() {
    echo "🔍 [SHOW-PERMS] Displaying current permissions - No changes will be applied"
    echo "🎯 Moodle Version: ${MOODLE_VERSION}.x"
    echo ""
    
    if [ "$MOODLE_VERSION" = "4" ]; then
        show_moodle4_permissions
    else
        show_moodle5_permissions
    fi
    
    echo ""
    echo "📋 Recommended permissions:"
    echo "   - Moodle directory: 755 (dir) / 644 (file)"
    echo "   - Moodledata directory: 770 (dir) / 660 (file)"
    echo "   - config.php: 640"
    echo "   - CLI scripts: 755"
    echo "   - Owner: ${WWW_USER}:${WWW_GROUP}"
    
    exit 0
}

# Function to create directory if missing
create_directory_if_missing() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        echo "📁 Creating directory: $dir"
        mkdir -p "$dir"
        return 0  # Directory created
    else
        return 1  # Directory already exists
    fi
}

# Function to create critical Moodle 4 directories
create_moodle4_directories() {
    echo "📁 Creating critical Moodle 4 directories..."
    
    local moodle4_dirs=("cache" "temp" "sessions" "lang" "h5p" "backup" "restore" "trashdir" "webservice" "filedir" "repository" "log")
    
    for dir in "${moodle4_dirs[@]}"; do
        local full_path="$MOODLEDATA_DIR/$dir"
        if create_directory_if_missing "$full_path"; then
            echo "   ✅ Created: $dir"
        else
            echo "   📁 Existing: $dir"
        fi
    done
}

# Function to create critical Moodle 5 directories
create_moodle5_directories() {
    echo "📁 Creating critical Moodle 5 directories..."
    
    local moodle5_dirs=("cache" "temp" "lock" "tasks" "localcache" "sessions" "lang" "h5p" "backup" "restore" "trash" "webservice")
    
    for dir in "${moodle5_dirs[@]}"; do
        local full_path="$MOODLEDATA_DIR/$dir"
        if create_directory_if_missing "$full_path"; then
            echo "   ✅ Created: $dir"
        else
            echo "   📁 Existing: $dir"
        fi
    done
}

# Function to set Moodle 4 permissions
set_moodle4_permissions() {
    echo "🎯 Setting specific Moodle 4 permissions..."
    
    local moodle4_dirs=("cache" "temp" "sessions" "lang" "h5p" "backup" "restore" "trashdir" "webservice" "filedir" "repository" "log")
    
    for dir in "${moodle4_dirs[@]}"; do
        if [ -d "$MOODLEDATA_DIR/$dir" ]; then
            chmod 770 "$MOODLEDATA_DIR/$dir"
            echo "   ✅ $dir directory set to 770"
        fi
    done
}

# Function to set Moodle 5 permissions
set_moodle5_permissions() {
    echo "🎯 Setting specific Moodle 5 permissions..."
    
    local moodle5_dirs=("cache" "temp" "lock" "tasks" "localcache" "sessions" "lang" "h5p" "backup" "restore" "trash" "webservice")
    
    for dir in "${moodle5_dirs[@]}"; do
        if [ -d "$MOODLEDATA_DIR/$dir" ]; then
            chmod 770 "$MOODLEDATA_DIR/$dir"
            echo "   ✅ $dir directory set to 770"
        fi
    done
}

# Function for Moodle 4 dry-run
dry_run_moodle4() {
    echo "📋 Specific Moodle 4 operations that would be executed:"
    
    local moodle4_dirs=("cache" "temp" "sessions" "lang" "h5p" "backup" "restore" "trashdir" "webservice" "filedir" "repository" "log")
    
    for dir in "${moodle4_dirs[@]}"; do
        if [ -d "$MOODLEDATA_DIR/$dir" ]; then
            echo "   chmod 770 \"$MOODLEDATA_DIR/$dir\""
        else
            echo "   mkdir -p \"$MOODLEDATA_DIR/$dir\" && chmod 770 \"$MOODLEDATA_DIR/$dir\""
        fi
    done
    
    echo ""
    echo "📝 Moodle 4 specific notes:"
    echo "   - 'trashdir' directory instead of 'trash'"
    echo "   - 'filedir' for main file storage"
    echo "   - 'repository' for repository files"
    echo "   - 'log' dedicated directory for logs"
}

# Function for Moodle 5 dry-run
dry_run_moodle5() {
    echo "📋 Specific Moodle 5 operations that would be executed:"
    
    local moodle5_dirs=("cache" "temp" "lock" "tasks" "localcache" "sessions" "lang" "h5p" "backup" "restore" "trash" "webservice")
    
    for dir in "${moodle5_dirs[@]}"; do
        if [ -d "$MOODLEDATA_DIR/$dir" ]; then
            echo "   chmod 770 \"$MOODLEDATA_DIR/$dir\""
        else
            echo "   mkdir -p \"$MOODLEDATA_DIR/$dir\" && chmod 770 \"$MOODLEDATA_DIR/$dir\""
        fi
    done
    
    echo ""
    echo "📝 Moodle 5 specific notes:"
    echo "   - 'lock' directory for improved lock management"
    echo "   - 'tasks' directory for task scheduling"
    echo "   - 'localcache' directory for local cache"
    echo "   - 'trash' directory instead of 'trashdir'"
}

# Function for dry-run
dry_run() {
    echo "🔍 [DRY-RUN] Simulation mode active - No changes will be applied"
    echo "🎯 Moodle Version: ${MOODLE_VERSION}.x"
    echo ""
    
    echo "📋 Common operations that would be executed:"
    echo "   chown -R ${WWW_USER}:${WWW_GROUP} \"$MOODLE_DIR\""
    echo "   chown -R ${WWW_USER}:${WWW_GROUP} \"$MOODLEDATA_DIR\""
    echo "   find \"$MOODLE_DIR\" -type d -exec chmod 755 {} \\;"
    echo "   find \"$MOODLE_DIR\" -type f -exec chmod 644 {} \\;"
    echo "   find \"$MOODLEDATA_DIR\" -type d -exec chmod 770 {} \\;"
    echo "   find \"$MOODLEDATA_DIR\" -type f -exec chmod 660 {} \\;"
    
    if [ -f "$MOODLE_DIR/config.php" ]; then
        echo "   chmod 640 \"$MOODLE_DIR/config.php\""
    else
        echo "   # config.php not found in $MOODLE_DIR (will be skipped)"
    fi
    
    if [ -d "$MOODLE_DIR/admin/cli" ]; then
        echo "   find \"$MOODLE_DIR/admin/cli\" -name \"*.php\" -exec chmod 755 {} \\;"
    else
        echo "   # CLI directory not found in $MOODLE_DIR/admin/cli (will be skipped)"
    fi
    
    echo ""
    
    # Version-specific operations
    if [ "$MOODLE_VERSION" = "4" ]; then
        dry_run_moodle4
    else
        dry_run_moodle5
    fi
    
    echo ""
    echo "🔍 Verifications that would be executed:"
    echo "   stat -c \"%a %U:%G\" \"$MOODLEDATA_DIR\""
    echo "   stat -c \"%a %U:%G\" \"$MOODLE_DIR\""
    
    echo ""
    echo "✅ [DRY-RUN] Simulation completed - No changes applied"
    exit 0
}

# Function to apply fixes
apply_fixes() {
    echo "🛠️  Applying permissions fixes..."
    
    echo "🔍 Verifying main directories..."
    check_main_directories

    echo "📁 Creating critical directories..."
    # Create critical directories based on version
    if [ "$MOODLE_VERSION" = "4" ]; then
        create_moodle4_directories
    else
        create_moodle5_directories
    fi

    echo "👤 Setting ownership..."
    chown -R ${WWW_USER}:${WWW_GROUP} "$MOODLE_DIR"
    chown -R ${WWW_USER}:${WWW_GROUP} "$MOODLEDATA_DIR"

    echo "📁 Setting base Moodle permissions..."
    find "$MOODLE_DIR" -type d -exec chmod 755 {} \;
    find "$MOODLE_DIR" -type f -exec chmod 644 {} \;

    # Check if config.php exists before modifying it
    if [ -f "$MOODLE_DIR/config.php" ]; then
        echo "🔒 Protecting config.php..."
        chmod 640 "$MOODLE_DIR/config.php"
    else
        echo "⚠️  Warning: config.php not found in $MOODLE_DIR"
    fi

    echo "💾 Setting moodledata permissions..."
    find "$MOODLEDATA_DIR" -type d -exec chmod 770 {} \;
    find "$MOODLEDATA_DIR" -type f -exec chmod 660 {} \;

    # CLI scripts (common to both versions)
    if [ -d "$MOODLE_DIR/admin/cli" ]; then
        find "$MOODLE_DIR/admin/cli" -name "*.php" -exec chmod 755 {} \;
        echo "✅ CLI scripts set as executable"
    fi

    # Setting version-specific permissions
    if [ "$MOODLE_VERSION" = "4" ]; then
        set_moodle4_permissions
    else
        set_moodle5_permissions
    fi

    # Verify critical directory permissions
    echo "🔍 Verifying critical directory permissions..."
    for dir in "$MOODLEDATA_DIR" "$MOODLE_DIR"; do
        if [ -d "$dir" ]; then
            perms=$(stat -c "%a %U:%G" "$dir")
            echo "   📁 $dir: $perms"
        fi
    done

    # Verify specific directory permissions
    echo "🔍 Verifying specific Moodle ${MOODLE_VERSION} directory permissions..."
    if [ "$MOODLE_VERSION" = "4" ]; then
        specific_dirs=("cache" "temp" "sessions" "lang" "h5p" "backup" "restore" "trashdir" "filedir" "repository" "log")
    else
        specific_dirs=("cache" "temp" "lock" "tasks" "localcache" "sessions" "lang" "h5p" "backup" "restore" "trash")
    fi

    for dir in "${specific_dirs[@]}"; do
        if [ -d "$MOODLEDATA_DIR/$dir" ]; then
            perms=$(stat -c "%a %U:%G" "$MOODLEDATA_DIR/$dir")
            echo "   📁 $MOODLEDATA_DIR/$dir: $perms"
        fi
    done

    echo ""
    echo "✅ Moodle ${MOODLE_VERSION}.x permissions set correctly!"
    echo ""
    echo "📋 Configuration summary:"
    echo "   - Script version: ${SCRIPT_RELEASE}"
    echo "   - Moodle version: ${MOODLE_VERSION}.x"
    echo "   - Moodle dir: $MOODLE_DIR (755/644)"
    echo "   - Moodledata: $MOODLEDATA_DIR (770/660)" 
    echo "   - Owner: $WWW_USER:$WWW_GROUP"
    echo "   - config.php: 640 (if present)"
    echo "   - CLI scripts: 755"
    echo ""

    # Version-specific notes
    if [ "$MOODLE_VERSION" = "4" ]; then
        echo "⚠️  Important notes for Moodle 4:"
        echo "   - PHP 7.4/8.0 required (8.0+ recommended)"
        echo "   - MySQL 5.7+ or PostgreSQL 9.5+ or MariaDB 10.4+"
        echo "   - Specific directories: trashdir/, filedir/, repository/"
    else
        echo "⚠️  Important notes for Moodle 5:"
        echo "   - PHP 8.1+ required"
        echo "   - MySQL 8.0+ or PostgreSQL 13+ or MariaDB 10.6+ recommended"
        echo "   - Specific directories: trash/, localcache/, lock/, tasks/"
    fi

    echo "   - Check logs in $MOODLEDATA_DIR for errors"
    echo ""
    echo "================================================================================"
    echo "Moodle Permissions Manager v${SCRIPT_RELEASE} - Operation completed"
    echo "Moodle ${MOODLE_VERSION}.x - Configuration applied successfully"
    echo "================================================================================"
}

# Argument parsing
DRY_RUN=false
SHOW_PERMS=false
APPLY_FIXES=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_header
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -s|--show-perms)
            SHOW_PERMS=true
            shift
            ;;
        -f|--fix)
            APPLY_FIXES=true
            shift
            ;;
        -mp|--moodlepath)
            MOODLE_DIR="$2"
            shift 2
            ;;
        -md|--moodledata)
            MOODLEDATA_DIR="$2"
            shift 2
            ;;
        -mv|--moodleversion)
            MOODLE_VERSION="$2"
            validate_moodle_version "$MOODLE_VERSION"
            shift 2
            ;;
        *)
            echo "❌ Unknown argument: $1"
            echo "Use $0 --help to see available options"
            exit 1
            ;;
    esac
done

# Show header
show_header

echo "🎯 Detected configuration:"
echo "   - Moodle Version: ${MOODLE_VERSION}.x"
echo "   - Moodle Directory: $MOODLE_DIR"
echo "   - Moodledata Directory: $MOODLEDATA_DIR"
echo ""

# Default behavior: if no action specified, show permissions
if [ "$DRY_RUN" = false ] && [ "$SHOW_PERMS" = false ] && [ "$APPLY_FIXES" = false ]; then
    echo "ℹ️  No action specified. Defaulting to show permissions mode."
    echo "   Use --fix/-f to apply changes or --dry-run to simulate."
    echo ""
    SHOW_PERMS=true
fi

# Execute show-perms if requested
if [ "$SHOW_PERMS" = true ]; then
    show_current_permissions
fi

# Verify script is run as root for fix operations
if [ "$APPLY_FIXES" = true ] && [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root to apply fixes"
    exit 1
fi

# Execute dry-run if requested
if [ "$DRY_RUN" = true ]; then
    dry_run
fi

# Execute fix if requested
if [ "$APPLY_FIXES" = true ]; then
    apply_fixes
fi
