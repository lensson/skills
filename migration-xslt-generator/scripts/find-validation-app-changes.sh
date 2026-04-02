#!/bin/bash
cd /home/zhenac/fiber_code/sw

# Get current user
CURRENT_USER=$(hg config ui.username 2>/dev/null | cut -d'<' -f1 | sed 's/[[:space:]]*$//')
[ -z "$CURRENT_USER" ] && CURRENT_USER=${USER:-zhenac}

echo "=== Find Recent Validation App Changes for User: $CURRENT_USER ==="
echo ""

# Find commits by current user
USER_REVS=$(hg log --limit 50 \
    -I "vobs/dsl/sw/y/build/apps/switch_validator_app/**" \
    -I "vobs/dsl/sw/y/build/apps/xpon_validator_app/**" \
    -I "vobs/dsl/sw/y/build/apps/clock_validator_app/**" \
    -u "$CURRENT_USER" \
    --template "{rev}|{node|short}|{date|isodate}|{desc|firstline}|{author|person}\n" 2>/dev/null)

# Find commits by all users (for filling if needed)
ALL_REVS=$(hg log --limit 200 \
    -I "vobs/dsl/sw/y/build/apps/switch_validator_app/**" \
    -I "vobs/dsl/sw/y/build/apps/xpon_validator_app/**" \
    -I "vobs/dsl/sw/y/build/apps/clock_validator_app/**" \
    --template "{rev}|{node|short}|{date|isodate}|{desc|firstline}|{author|person}\n" 2>/dev/null)

if [ -z "$ALL_REVS" ]; then
    echo "No commits with validation app files found"
    exit 1
fi

# Count user's commits
USER_COUNT=0
if [ -n "$USER_REVS" ]; then
    USER_COUNT=$(echo "$USER_REVS" | wc -l)
fi

# Fill remaining slots with other users' commits
FILL_COUNT=$((3 - USER_COUNT))

# If we need to fill, get other users' commits (exclude current user)
if [ $FILL_COUNT -gt 0 ] && [ -n "$ALL_REVS" ]; then
    FILL_REVS=$(echo "$ALL_REVS" | grep -v "|${CURRENT_USER}$" | grep -v "|${CURRENT_USER}|" | head -$FILL_COUNT)
fi

# Combine user's commits and fill commits
if [ -n "$USER_REVS" ]; then
    COMBINED_REVS="$USER_REVS"
fi
if [ -n "$FILL_REVS" ]; then
    COMBINED_REVS="${COMBINED_REVS}${FILL_REVS}"
fi

# Take only first 3
FINAL_REVS=$(echo "$COMBINED_REVS" | head -3)

if [ -z "$FINAL_REVS" ]; then
    echo "No commits with validation app files found"
    exit 1
fi

# Display table header with Unicode box drawing (without Node column)
# Date column: "2022-09-01 10:05" is 16 chars, so use %-16s
echo "┌────┬───────────┬────────────────┬─────────────────────────────────────────────────────────────────────────┬──────────────────────────────┐"
echo "│ #  │ Changeset │ Date            │ Description                                                                   │ Validation Files              │"
echo "├────┼───────────┼────────────────┼─────────────────────────────────────────────────────────────────────────┼──────────────────────────────┤"

# Parse and display first 3 revisions with validation app files and diff stats
idx=0
while IFS='|' read -r rev node date desc author; do
    idx=$((idx + 1))
    [ $idx -gt 3 ] && break
    
    # Check if this is user's own commit
    if [ "$author" = "$CURRENT_USER" ]; then
        user_marker="(you)"
    else
        user_marker="($author)"
    fi
    
    # Get validation app files for this revision
    VAL_FILES=$(hg log -r "$rev" -v --template "{file_mods}" 2>/dev/null | tr ' ' '\n' | grep -E '\.(cpp|json)$' | grep -E "(validator_app/|TranslatorStrategy|ValidationRule)" | head -5)
    VAL_COUNT=$(echo "$VAL_FILES" | grep -c . || echo "0")
    
    # Get diff stats for first 3 validation files (basename + lines)
    TOTAL_ADD=0
    FILE_IDX=0
    FILE_LIST=""
    for val_file in $VAL_FILES; do
        FILE_IDX=$((FILE_IDX + 1))
        # Only show first 3 files
        if [ $FILE_IDX -le 3 ]; then
            basename_file=$(basename "$val_file")
            diff_output=$(hg diff -r $((rev-1)) -r "$rev" -I "$val_file" 2>/dev/null)
            adds=$(echo "$diff_output" | grep -c '^+' || echo "0")
            adds=$((adds - 1))
            TOTAL_ADD=$((TOTAL_ADD + adds))
            
            if [ -n "$FILE_LIST" ]; then
                FILE_LIST="$FILE_LIST; $basename_file"
            else
                FILE_LIST="$basename_file"
            fi
        fi
    done
    
    # Add ellipsis if more than 3 files
    if [ "$VAL_COUNT" -gt 3 ] 2>/dev/null; then
        FILE_LIST="$FILE_LIST; ..."
    fi
    
    # Truncate description if too long
    if [ ${#desc} -gt 100 ]; then
        desc="${desc:0:97}..."
    fi
    
    # Handle validation files display
    if [ -z "$VAL_COUNT" ] || [ "$VAL_COUNT" -eq 0 ] 2>/dev/null || [ -z "$FILE_LIST" ]; then
        VAL_FILES_DISPLAY="0 file(s)"
    else
        # Truncate file list if too long
        if [ ${#FILE_LIST} -gt 28 ]; then
            FILE_LIST="${FILE_LIST:0:25}..."
        fi
        VAL_FILES_DISPLAY="$FILE_LIST (+$TOTAL_ADD)"
    fi
    
    # Remove timezone from date (e.g., "2022-09-01 10:05 +0800" -> "2022-09-01 10:05")
    date_clean=$(echo "$date" | sed 's/ [+0-9-]*$//')
    
    # Print table row with Unicode box drawing (without Node column)
    # Date column: %-16s (16 chars: "2022-09-01 10:05")
    printf "│ %-2d │ %-9s │ %-16s │ %-107s │ %-28s │\n" "$idx" "$rev" "$date_clean" "${desc} ${user_marker}" "$VAL_FILES_DISPLAY"
    echo "├────┼───────────┼────────────────┼─────────────────────────────────────────────────────────────────────────┼──────────────────────────────┤"
done <<< "$FINAL_REVS"

echo ""
echo "┌────────────────────────────────────────────────────────────────────────────────────────┐"
echo "│ Select option:                                                                        │"
echo "│   1, 2, 3       - Select single or multiple (comma-separated) changesets              │"
echo "│   4             - Input changeset(s) manually                                       │"
echo "│   <changeset>  - Direct input (e.g., 518388)                                        │"
echo "│   B             - Back to ChooseMode                                                  │"
echo "│   Q             - Quit and exit                                                        │"
echo "└────────────────────────────────────────────────────────────────────────────────────────┘"
echo ""
echo -n "Enter your choice: "
