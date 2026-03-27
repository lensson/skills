#!/bin/bash
#===============================================================================
# yang_diff.sh - Display YANG file diff for a given changeset/revision
#
# Usage: ./yang_diff.sh <changeset>
#        ./yang_diff.sh <revision>:<node>
#        ./yang_diff.sh <node_hash>
#
# Examples:
#   ./yang_diff.sh 599970
#   ./yang_diff.sh 599970:6af21798fe14
#   ./yang_diff.sh 6af21798fe14
#===============================================================================

WORKSPACE="/home/zhenac/fiber_code/sw"
cd "$WORKSPACE"

# Check if argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <changeset|revision:node|node_hash>"
    echo "Examples:"
    echo "  $0 599970"
    echo "  $0 599970:6af21798fe14"
    echo "  $0 6af21798fe14"
    exit 1
fi

INPUT="$1"

# Parse the input - handle both "rev:node" format and just revision/node
if [[ "$INPUT" == *":"* ]]; then
    # Format: rev:node
    REVISION=$(echo "$INPUT" | cut -d':' -f1)
    NODE=$(echo "$INPUT" | cut -d':' -f2)
else
    # Check if it's a valid revision number or node hash
    if [[ "$INPUT" =~ ^[0-9]+$ ]]; then
        REVISION="$INPUT"
        NODE=$(hg log -r "$REVISION" --template "{node|short}" 2>/dev/null)
    else
        # Assume it's a node hash
        NODE="$INPUT"
        REVISION=$(hg log -r "$NODE" --template "{rev}" 2>/dev/null)
    fi
fi

# Validate revision exists
if ! hg log -r "$REVISION" >/dev/null 2>&1; then
    echo "Error: Revision $REVISION not found"
    exit 1
fi

# Get changeset info
CHANGESET_INFO=$(hg log -r "$REVISION" --template "{rev}|{node|short}|{date|isodate}|{date|rfc822date}|{desc|firstline}|{author|person}\n" 2>/dev/null)

IFS='|' read -r REV NODE_SHORT DATE_ISO DATE_RFC DESC AUTHOR <<< "$CHANGESET_INFO"

# Get full node hash
FULL_NODE=$(hg log -r "$REVISION" --template "{node}" 2>/dev/null)

# Get all YANG files modified in this changeset
YANG_FILES=$(hg log -r "$REVISION" -v --template "{file_mods}" 2>/dev/null | tr ' ' '\n' | grep '\.yang$' || true)

# Check if no YANG files found
if [ -z "$YANG_FILES" ]; then
    echo ""
    echo "============================================================"
    echo "  YANG Diff Viewer"
    echo "============================================================"
    echo ""
    echo "Changeset: $REV"
    echo "Node:       $FULL_NODE"
    echo "Date:       $DATE_RFC"
    echo "Author:     $AUTHOR"
    echo "Description: $DESC"
    echo ""
    echo "============================================================"
    echo ""
    echo "No YANG file updated in changeset $REV."
    echo ""
    echo "Back to last option..."
    echo ""
    exit 3
fi

YANG_COUNT=$(echo "$YANG_FILES" | wc -l | tr -d ' ')
YANG_COUNT=$((YANG_COUNT + 0))

# Store YANG files in an array
declare -a YANG_ARRAY
IDX=0
for yang_file in $YANG_FILES; do
    IDX=$((IDX + 1))
    YANG_ARRAY[$IDX]="$yang_file"
done

# Calculate total changes
TOTAL_ADD=0
TOTAL_DEL=0

echo ""
echo "============================================================"
echo "  YANG Diff Viewer"
echo "============================================================"
echo ""
echo "Changeset: $REV"
echo "Node:       $FULL_NODE"
echo "Date:       $DATE_RFC"
echo "Author:     $AUTHOR"
echo "Description: $DESC"
echo ""
echo "Modified YANG Files ($YANG_COUNT):"
echo "------------------------------------------------------------"

# Display each YANG file with its diff
IDX=1
declare -a FILE_BASENAMES

for yang_file in $YANG_FILES; do
    BASENAME_FILE=$(basename "$yang_file")
    FILE_BASENAMES[$IDX]="$BASENAME_FILE"

    echo ""
    echo "[$IDX] $BASENAME_FILE"
    echo "    Path: $yang_file"

    # Get diff for this specific file
    PREV_REV=$((REVISION - 1))
    DIFF_OUTPUT=$(hg diff -r "$PREV_REV" -r "$REVISION" -I "$yang_file" 2>/dev/null || echo "")

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

echo ""
echo "============================================================"
echo "  Summary"
echo "============================================================"
echo ""
echo "Changeset:    $REV"
echo "Node:         $FULL_NODE"
echo "YANG Files:   $YANG_COUNT files"
echo "Total Add:    +$TOTAL_ADD lines"
echo "Total Delete: -$TOTAL_DEL lines"
echo ""
echo "============================================================"

# Generate migration recommendation
echo ""
echo "  Migration Analysis"
echo "============================================================"
echo ""
IDX=1
for yang_file in $YANG_FILES; do
    BASENAME_FILE=$(basename "$yang_file")
    echo "[$IDX] $BASENAME_FILE"

    PREV_REV=$((REVISION - 1))
    DIFF_OUTPUT=$(hg diff -r "$PREV_REV" -r "$REVISION" -I "$yang_file" 2>/dev/null || echo "")

    if echo "$DIFF_OUTPUT" | grep -q "deviate add"; then
        echo "  -> Contains 'deviate add': May require data transformation for new constraints"
    fi
    if echo "$DIFF_OUTPUT" | grep -q "deviate delete"; then
        echo "  -> Contains 'deviate delete': May require removing old data structures"
    fi
    if echo "$DIFF_OUTPUT" | grep -q "deviate replace"; then
        echo "  -> Contains 'deviate replace': May require type/structure conversion"
    fi
    if echo "$DIFF_OUTPUT" | grep -q "revision"; then
        echo "  -> Contains new revision: Schema versioning detected"
    fi
    if echo "$DIFF_OUTPUT" | grep -q "must "; then
        echo "  -> Contains 'must' constraint': New validation rules added"
    fi
    if echo "$DIFF_OUTPUT" | grep -q "leaf"; then
        echo "  -> Contains 'leaf' changes: Field-level modifications"
    fi
    if echo "$DIFF_OUTPUT" | grep -q "container"; then
        echo "  -> Contains 'container' changes: Structure modifications"
    fi
    if echo "$DIFF_OUTPUT" | grep -q "list "; then
        echo "  -> Contains 'list' changes: List structure modifications"
    fi
    if echo "$DIFF_OUTPUT" | grep -q "identity "; then
        echo "  -> Contains 'identity' changes: New identity definitions"
    fi
    if echo "$DIFF_OUTPUT" | grep -q "typedef"; then
        echo "  -> Contains 'typedef' changes: Type definitions modified"
    fi

    echo ""
    IDX=$((IDX + 1))
done

echo "============================================================"
echo ""
echo "  Select YANG File for XSLT Generation"
echo "============================================================"
echo ""
echo "Please select an option:"
echo ""

# Only show option A if there's more than 1 YANG file
if [ "$YANG_COUNT" -gt 1 ]; then
    for i in $(seq 1 $YANG_COUNT); do
        echo "  $i - Generate XSLT for ${FILE_BASENAMES[$i]}"
    done
    echo "  A - Generate XSLT for ALL $YANG_COUNT YANG files"
else
    echo "  1 - Generate XSLT for ${FILE_BASENAMES[1]}"
fi
echo "  B - Back to changeset list"
echo "  Q - Quit"
echo ""
echo -n "Enter your choice: "

read -r USER_CHOICE

# Output selection result for next step
case "$USER_CHOICE" in
    [1-9]*)
        if [[ "$USER_CHOICE" =~ ^[0-9]+$ ]] && [ "$USER_CHOICE" -ge 1 ] && [ "$USER_CHOICE" -le "$YANG_COUNT" ]; then
            echo ""
            echo "---"
            echo "SELECTED: ${YANG_ARRAY[$USER_CHOICE]}"
            echo "CHANGESET: $REV"
            echo "NODE: $FULL_NODE"
        else
            echo ""
            echo "Error: Invalid selection."
            exit 1
        fi
        ;;
    A|a)
        # Only allow "A" if there's more than 1 YANG file
        if [ "$YANG_COUNT" -gt 1 ]; then
            echo ""
            echo "---"
            echo "SELECTED: ALL"
            echo "CHANGESET: $REV"
            echo "NODE: $FULL_NODE"
            echo "FILE_COUNT: $YANG_COUNT"
            for i in $(seq 1 $YANG_COUNT); do
                echo "FILE_$i: ${YANG_ARRAY[$i]}"
            done
        else
            echo ""
            echo "Error: Only one YANG file, use option 1 instead."
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
