#!/bin/bash
#===============================================================================
# validation_app_diff.sh - Display validation app code diff for a changeset
#
# Usage: ./validation_app_diff.sh <changeset>
#        ./validation_app_diff.sh <revision>:<node>
#        ./validation_app_diff.sh <node_hash>
#        ./validation_app_diff.sh <changeset1,changeset2,changeset3>
#
# Examples:
#   ./validation_app_diff.sh 535200
#   ./validation_app_diff.sh 535200:a1b2c3d4e5f6
#   ./validation_app_diff.sh a1b2c3d4e5f6
#   ./validation_app_diff.sh 535200,535195,535190
#===============================================================================

WORKSPACE="/home/zhenac/fiber_code/sw"
cd "$WORKSPACE"

# Check if argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <changeset|revision:node|node_hash|changeset1,changeset2,...>"
    echo "Examples:"
    echo "  $0 535200"
    echo "  $0 535200:a1b2c3d4e5f6"
    echo "  $0 535200,535195,535190"
    exit 1
fi

INPUT="$1"

# Check if input contains comma (multiple changesets)
if [[ "$INPUT" == *","* ]]; then
    # Multiple changesets mode
    IFS=',' read -ra CHANGESETS <<< "$INPUT"
    MODE="MULTI"
else
    # Single changeset mode
    MODE="SINGLE"
fi

display_single_changeset() {
    local REVISION="$1"
    local SOURCE="$2"
    
    # Parse the input - handle both "rev:node" format and just revision/node
    if [[ "$REVISION" == *":"* ]]; then
        # Format: rev:node
        REV=$(echo "$REVISION" | cut -d':' -f1)
        NODE=$(echo "$REVISION" | cut -d':' -f2)
    else
        # Check if it's a valid revision number or node hash
        if [[ "$REVISION" =~ ^[0-9]+$ ]]; then
            REV="$REVISION"
            NODE=$(hg log -r "$REV" --template "{node|short}" 2>/dev/null)
        else
            # Assume it's a node hash
            NODE="$REVISION"
            REV=$(hg log -r "$NODE" --template "{rev}" 2>/dev/null)
        fi
    fi
    
    # Validate revision exists
    if ! hg log -r "$REV" >/dev/null 2>&1; then
        echo "Error: Revision $REV not found"
        return 1
    fi
    
    # Get changeset info
    CHANGESET_INFO=$(hg log -r "$REV" --template "{rev}|{node|short}|{date|isodate}|{date|rfc822date}|{desc|firstline}|{author|person}\n" 2>/dev/null)
    
    IFS='|' read -r REV_NUM NODE_SHORT DATE_ISO DATE_RFC DESC AUTHOR <<< "$CHANGESET_INFO"
    
    # Get full node hash
    FULL_NODE=$(hg log -r "$REV" --template "{node}" 2>/dev/null)
    
    # Header for single changeset
    echo ""
    echo "============================================================"
    echo "  Validation App Code Diff Viewer"
    echo "============================================================"
    echo ""
    if [ "$SOURCE" = "DIRECT" ]; then
        echo "Changeset Input: $REVISION"
        echo "Source: Direct input (not from ChangeList)"
        echo ""
    fi
    echo "Changeset: $REV_NUM"
    echo "Node:       $FULL_NODE"
    echo "Date:       $DATE_RFC"
    echo "Author:     $AUTHOR"
    echo "Description: $DESC"
    echo ""
    
    # Get all validation app files modified in this changeset
    # Look for .cpp and .json files in validator app directories
    VAL_FILES=$(hg log -r "$REV" -v --template "{file_mods}" 2>/dev/null | tr ' ' '\n' | \
        grep -E '\.(cpp|json)$' | \
        grep -E "(switch_validator_app|xpon_validator_app|clock_validator_app|switch_validator|xpon_validator|TranslatorStrategy|ValidationRule)" || true)
    
    # Check if no validation app files found
    if [ -z "$VAL_FILES" ]; then
        echo "============================================================"
        echo ""
        echo "No validation app file updated in changeset $REV."
        echo ""
        echo "Back to last option..."
        echo ""
        return 3
    fi
    
    VAL_COUNT=$(echo "$VAL_FILES" | wc -l | tr -d ' ')
    VAL_COUNT=$((VAL_COUNT + 0))
    
    # Store validation files in an array
    declare -a VAL_ARRAY
    declare -a FILE_BASENAMES
    declare -a FILE_PATHS
    IDX=0
    
    for val_file in $VAL_FILES; do
        IDX=$((IDX + 1))
        VAL_ARRAY[$IDX]="$val_file"
        FILE_PATHS[$IDX]="$val_file"
        FILE_BASENAMES[$IDX]=$(basename "$val_file")
    done
    
    # Calculate total changes
    TOTAL_ADD=0
    TOTAL_DEL=0
    CPP_COUNT=0
    JSON_COUNT=0
    
    echo "Modified Validation App Files ($VAL_COUNT):"
    echo "------------------------------------------------------------"
    
    # Display each file with its diff
    IDX=1
    for val_file in $VAL_FILES; do
        BASENAME_FILE="${FILE_BASENAMES[$IDX]}"
        FILE_TYPE="Unknown"
        
        # Determine file type
        if [[ "$BASENAME_FILE" == *.cpp ]]; then
            FILE_TYPE="Validation Rule (C++)"
            CPP_COUNT=$((CPP_COUNT + 1))
        elif [[ "$BASENAME_FILE" == *.json ]]; then
            FILE_TYPE="Configuration (JSON)"
            JSON_COUNT=$((JSON_COUNT + 1))
        fi
        
        echo ""
        echo "[$IDX] $BASENAME_FILE"
        echo "    Path: $val_file"
        echo "    Type: $FILE_TYPE"
        
        # Get diff for this specific file
        PREV_REV=$((REV - 1))
        DIFF_OUTPUT=$(hg diff -r "$PREV_REV" -r "$REV" -I "$val_file" 2>/dev/null || echo "")
        
        if [ -n "$DIFF_OUTPUT" ]; then
            # Count additions and deletions
            ADDS=$(echo "$DIFF_OUTPUT" | grep -c '^+[^+]' 2>/dev/null || true)
            DELS=$(echo "$DIFF_OUTPUT" | grep -c '^-[^-]' 2>/dev/null || true)
            ADDS=${ADDS:-0}
            DELS=${DELS:-0}
            TOTAL_ADD=$((TOTAL_ADD + ADDS))
            TOTAL_DEL=$((TOTAL_DEL + DELS))
            
            echo "    Changes: +$ADDS / -$DELS"
            echo ""
            echo "------------------------------------------------------------"
            echo "$DIFF_OUTPUT"
            echo "------------------------------------------------------------"
        else
            echo "    Changes: +0 / -0 (binary or non-text file)"
        fi
        echo ""
        IDX=$((IDX + 1))
    done
    
    # Summary
    echo ""
    echo "============================================================"
    echo "  Summary"
    echo "============================================================"
    echo ""
    echo "Changeset:    $REV_NUM"
    echo "Node:         $FULL_NODE"
    echo "Total Files:  $VAL_COUNT files"
    echo "  - C++ Rule Files: $CPP_COUNT"
    echo "  - JSON Configs:   $JSON_COUNT"
    echo ""
    echo "Total Add:    +$TOTAL_ADD lines"
    echo "Total Delete: -$TOTAL_DEL lines"
    echo ""
    echo "============================================================"
    
    # Generate validation rule analysis
    echo ""
    echo "  Validation Rule Analysis"
    echo "============================================================"
    echo ""
    echo "Modified C++ Rules:"
    echo ""
    
    IDX=1
    for val_file in $VAL_FILES; do
        BASENAME_FILE="${FILE_BASENAMES[$IDX]}"
        if [[ "$BASENAME_FILE" == *.cpp ]]; then
            echo "[$IDX] $BASENAME_FILE"
            echo "    -> Rule file modified - may need XSLT mapping"
            echo ""
        fi
        IDX=$((IDX + 1))
    done
    
    echo "Modified JSON Configs:"
    echo ""
    
    IDX=1
    for val_file in $VAL_FILES; do
        BASENAME_FILE="${FILE_BASENAMES[$IDX]}"
        if [[ "$BASENAME_FILE" == *.json ]]; then
            echo "[$IDX] $BASENAME_FILE"
            if [[ "$BASENAME_FILE" == TranslatorStrategyCategory.json ]]; then
                echo "    -> Strategy mapping changed - affects XSLT generation"
            elif [[ "$BASENAME_FILE" == ValidationRuleCategory.json ]]; then
                echo "    -> Rule category mapping changed"
            else
                echo "    -> Configuration file modified"
            fi
            echo ""
        fi
        IDX=$((IDX + 1))
    done
    
    echo "============================================================"
    
    # Return arrays for selection prompt
    echo ""
    echo "  Select Validation App File for XSLT Generation"
    echo "============================================================"
    echo ""
    echo "Please select an option:"
    echo ""
    
    # Only show option A if there's more than 1 file
    if [ "$VAL_COUNT" -gt 1 ]; then
        for i in $(seq 1 $VAL_COUNT); do
            echo "  $i - Analyze ${FILE_BASENAMES[$i]}"
        done
        echo "  A - Analyze ALL $VAL_COUNT files"
    else
        echo "  1 - Analyze ${FILE_BASENAMES[1]}"
    fi
    echo "  B - Back to changeset list"
    echo "  Q - Quit"
    echo ""
    echo -n "Enter your choice: "
    
    read -r USER_CHOICE
    
    # Output selection result for next step
    case "$USER_CHOICE" in
        [1-9]*)
            if [[ "$USER_CHOICE" =~ ^[0-9]+$ ]] && [ "$USER_CHOICE" -ge 1 ] && [ "$USER_CHOICE" -le "$VAL_COUNT" ]; then
                echo ""
                echo "---"
                echo "SELECTED: ${VAL_ARRAY[$USER_CHOICE]}"
                echo "CHANGESET: $REV_NUM"
                echo "NODE: $FULL_NODE"
                echo "TYPE: $([[ "${FILE_BASENAMES[$USER_CHOICE]}" == *.cpp ]] && echo "cpp_rule" || echo "json_config")"
            else
                echo ""
                echo "Error: Invalid selection."
                exit 1
            fi
            ;;
        A|a)
            if [ "$VAL_COUNT" -gt 1 ]; then
                echo ""
                echo "---"
                echo "SELECTED: ALL"
                echo "CHANGESET: $REV_NUM"
                echo "NODE: $FULL_NODE"
                echo "FILE_COUNT: $VAL_COUNT"
                for i in $(seq 1 $VAL_COUNT); do
                    echo "FILE_$i: ${VAL_ARRAY[$i]}"
                    echo "TYPE_$i: $([[ "${FILE_BASENAMES[$i]}" == *.cpp ]] && echo "cpp_rule" || echo "json_config")"
                done
            else
                echo ""
                echo "Error: Only one file, use option 1 instead."
                exit 1
            fi
            ;;
        B|b)
            echo ""
            echo "Returning to changeset list..."
            exit 2
            ;;
        Q|q)
            echo ""
            echo "Exiting."
            exit 0
            ;;
        *)
            echo ""
            echo "Error: Invalid selection."
            exit 1
            ;;
    esac
}

# Main execution
if [ "$MODE" = "MULTI" ]; then
    # Multiple changesets mode
    echo ""
    echo "============================================================"
    echo "  Validation App Code Diff Viewer (Multiple Changesets)"
    echo "============================================================"
    echo ""
    echo "Selected Changesets:"
    IDX=0
    for changeset in "${CHANGESETS[@]}"; do
        IDX=$((IDX + 1))
        DESC=$(hg log -r "$changeset" --template "{desc|firstline}" 2>/dev/null || echo "Unknown")
        echo "  [$IDX] $changeset - $DESC"
    done
    echo ""
    echo "Processing ${#CHANGESETS[@]} changesets..."
    
    # Process each changeset
    ALL_FILES=""
    TOTAL_CHANGESETS=${#CHANGESETS[@]}
    IDX=0
    for changeset in "${CHANGESETS[@]}"; do
        IDX=$((IDX + 1))
        echo ""
        echo "============================================================"
        echo "  Changeset $IDX/$TOTAL_CHANGESETS: $changeset"
        echo "============================================================"
        
        display_single_changeset "$changeset" "MULTI"
        EXIT_CODE=$?
        
        if [ $EXIT_CODE -eq 3 ]; then
            # No validation files in this changeset, skip
            continue
        elif [ $EXIT_CODE -ne 0 ] && [ $EXIT_CODE -ne 2 ]; then
            exit $EXIT_CODE
        fi
    done
else
    # Single changeset mode
    display_single_changeset "$INPUT" "DIRECT"
fi
