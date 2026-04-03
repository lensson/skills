#!/bin/bash
cd /home/zhenac/fiber_code/sw

# Get current user
CURRENT_USER=$(hg config ui.username 2>/dev/null | cut -d'<' -f1 | sed 's/[[:space:]]*$//')
[ -z "$CURRENT_USER" ] && CURRENT_USER=${USER:-zhenac}

# Get script directory for calling other scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Global arrays for selected commits
declare -a SELECTED_COMMITS

show_changelist() {
    echo ""
    echo "=== Find Recent Validation App Changes for User: $CURRENT_USER ==="
    echo ""

    # Get commit list WITH file_mods in template (single query)
    ALL_REVS=$(hg log --limit 50 \
        -I "vobs/dsl/sw/y/build/apps/switch_validator_app/**" \
        -I "vobs/dsl/sw/y/build/apps/xpon_validator_app/**" \
        -I "vobs/dsl/sw/y/build/apps/clock_validator_app/**" \
        -I "vobs/dsl/sw/y/src/switch_validator/**" \
        -I "vobs/dsl/sw/y/src/xpon_validator/**" \
        --template "{rev}|{node|short}|{date|isodate}|{desc|firstline}|{author|person}|{file_mods}\n" 2>/dev/null)

    if [ -z "$ALL_REVS" ]; then
        echo "No commits with validation app files found"
        return 1
    fi

    # Parse and filter - file_mods already available
    declare -a USER_COMMITS
    declare -a ALL_COMMITS

    while IFS='|' read -r rev node date desc author file_mods; do
        # Skip if no file_mods
        [ -z "$file_mods" ] && continue

        # Filter for validation app .cpp and .json files only
        VAL_FILES=$(echo "$file_mods" | tr ' ' '\n' | \
            grep -E '\.(cpp|json)$' | \
            grep -E "(switch_validator_app|xpon_validator_app|clock_validator_app|switch_validator/|xpon_validator/)" | \
            grep -v '^$')

        # Count unique files - remove newlines first
        VAL_COUNT=$(echo "$VAL_FILES" | tr '\n' ' ' | tr -s ' ' | xargs -n1 basename 2>/dev/null | sort -u | grep -c '\.cpp$\|\.json$' || echo "0")
        VAL_COUNT=$(echo "$VAL_COUNT" | tr -d ' \n\t')

        if [ -z "$VAL_COUNT" ] || [ "$VAL_COUNT" -eq 0 ] 2>/dev/null; then
            continue
        fi

        # Build file list with basenames (unique, no newlines in storage)
        FILE_LIST=$(echo "$VAL_FILES" | xargs -n1 basename 2>/dev/null | sort -u | grep -v '^$' | tr '\n' '|')

        # Remove timezone from date
        date_clean=$(echo "$date" | sed 's/ [+0-9-]*$//')

        # Check if user's own commit
        if [ "$author" = "$CURRENT_USER" ]; then
            user_marker="(you)"
        else
            user_marker="($author)"
        fi

        # Store: rev|date|desc|user_marker|file_count|file_list (files separated by |)
        entry="${rev}|${date_clean}|${desc}|${user_marker}|${VAL_COUNT}|${FILE_LIST}"

        if [ "$author" = "$CURRENT_USER" ]; then
            USER_COMMITS+=("$entry")
        fi
        ALL_COMMITS+=("$entry")
    done <<< "$ALL_REVS"

    # Determine which commits to display
    # First: user's own commits (up to 3)
    # Then: fill with others' commits if needed
    SELECTED_COMMITS=()
    USER_COUNT=${#USER_COMMITS[@]}

    if [ $USER_COUNT -ge 3 ]; then
        for i in 0 1 2; do
            SELECTED_COMMITS+=("${USER_COMMITS[$i]}")
        done
        SOURCE="your recent commits"
    else
        # Add all user's commits first
        for entry in "${USER_COMMITS[@]}"; do
            SELECTED_COMMITS+=("$entry")
        done

        # Fill up to 3 with other users' commits
        NEED=$((3 - USER_COUNT))
        for entry in "${ALL_COMMITS[@]}"; do
            [ $NEED -eq 0 ] && break
            # Skip if already in selected (user's own commits)
            skip=0
            for sel in "${SELECTED_COMMITS[@]}"; do
                if [ "$sel" = "$entry" ]; then
                    skip=1
                    break
                fi
            done
            if [ $skip -eq 0 ]; then
                SELECTED_COMMITS+=("$entry")
                NEED=$((NEED - 1))
            fi
        done

        if [ $USER_COUNT -gt 0 ]; then
            SOURCE="your recent + others"
        else
            SOURCE="recent commits"
        fi
    fi

    NUM_COMMITS=${#SELECTED_COMMITS[@]}

    if [ $NUM_COMMITS -eq 0 ]; then
        echo "No commits with validation app (.cpp/.json) files found"
        return 1
    fi

    echo "(Showing ${NUM_COMMITS} commits from ${SOURCE})"
    echo ""

    # Column widths for table
    COL1_W=3    # #
    COL2_W=10   # Changeset
    COL3_W=16   # Date
    COL4_W=0    # Description
    COL5_W=14   # File (filename only)

    for entry in "${SELECTED_COMMITS[@]}"; do
        IFS='|' read -r rev date desc user_marker filecount filelist <<< "$entry"
        desc_with_marker="${desc} ${user_marker}"
        [ ${#desc_with_marker} -gt $COL4_W ] && COL4_W=${#desc_with_marker}
        # Parse file list (separated by |)
        OLDIFS="$IFS"
        IFS='|'
        for fname in $filelist; do
            [ -n "$fname" ] && [ ${#fname} -gt $COL5_W ] && COL5_W=${#fname}
        done
        IFS="$OLDIFS"
    done

    [ $COL4_W -gt 65 ] && COL4_W=65
    [ $COL5_W -lt 14 ] && COL5_W=14

    PAD=2
    C1=$((COL1_W + PAD))
    C2=$((COL2_W + PAD))
    C3=$((COL3_W + PAD))
    C4=$((COL4_W + PAD))
    C5=$((COL5_W + PAD))

    # Build table borders
    TOP=$(printf "┌%${C1}s┬%${C2}s┬%${C3}s┬%${C4}s┬%${C5}s┐" \
        "$(printf '%.0s─' $(seq 1 $C1))" \
        "$(printf '%.0s─' $(seq 1 $C2))" \
        "$(printf '%.0s─' $(seq 1 $C3))" \
        "$(printf '%.0s─' $(seq 1 $C4))" \
        "$(printf '%.0s─' $(seq 1 $C5))")

    MID=$(printf "├%${C1}s┼%${C2}s┼%${C3}s┼%${C4}s┼%${C5}s┤" \
        "$(printf '%.0s─' $(seq 1 $C1))" \
        "$(printf '%.0s─' $(seq 1 $C2))" \
        "$(printf '%.0s─' $(seq 1 $C3))" \
        "$(printf '%.0s─' $(seq 1 $C4))" \
        "$(printf '%.0s─' $(seq 1 $C5))")

    BOT=$(printf "└%${C1}s┴%${C2}s┴%${C3}s┴%${C4}s┴%${C5}s┘" \
        "$(printf '%.0s─' $(seq 1 $C1))" \
        "$(printf '%.0s─' $(seq 1 $C2))" \
        "$(printf '%.0s─' $(seq 1 $C3))" \
        "$(printf '%.0s─' $(seq 1 $C4))" \
        "$(printf '%.0s─' $(seq 1 $C5))")

    FMT="│%-${C1}s│%-${C2}s│%-${C3}s│%-${C4}s│%-${C5}s│"

    echo "$TOP"
    printf "$FMT\n" " #" "Changeset" "Date" "Description" "Validation Files"
    echo "$MID"

    idx=1
    first_commit=1
    for entry in "${SELECTED_COMMITS[@]}"; do
        IFS='|' read -r rev date desc user_marker filecount filelist <<< "$entry"

        desc_with_marker="${desc} ${user_marker}"
        if [ ${#desc_with_marker} -gt $COL4_W ]; then
            desc_with_marker="${desc_with_marker:0:$((COL4_W-3))}..."
        fi

        if [ $first_commit -eq 0 ]; then
            echo "$MID"
        fi
        first_commit=0

        # Parse file list into array
        OLDIFS="$IFS"
        IFS='|'
        files=()
        for fname in $filelist; do
            [ -n "$fname" ] && files+=("$fname")
        done
        IFS="$OLDIFS"

        num_files=${#files[@]}

        # First row with commit info + first file
        first_file="${files[0]:-}"
        printf "$FMT\n" " $idx" " $rev" " $date" " $desc_with_marker" " $first_file"

        # Remaining files (one per line), show at most 3
        for ((i=1; i<num_files && i<3; i++)); do
            printf "$FMT\n" "" "" "" "" " ${files[$i]}"
        done

        # More files indicator
        if [ $num_files -gt 3 ]; then
            printf "$FMT\n" "" "" "" "" " ... +$((num_files - 3)) more files"
        fi

        idx=$((idx + 1))
    done

    echo "$BOT"

    echo ""
    echo "Select option:"
    echo "  1, 2, 3       - Select single or multiple (comma-separated) changesets"
    echo "  4             - Input changeset(s) manually"
    echo "  <changeset>   - Direct input (e.g., 518388)"
    echo "  B             - Back to ChooseMode"
    echo "  Q             - Quit and exit"
    echo ""
}

# Function to get changeset from index
get_changeset_from_index() {
    local idx=$1
    local entry="${SELECTED_COMMITS[$((idx-1))]}"
    if [ -n "$entry" ]; then
        IFS='|' read -r rev date desc user_marker filecount filelist <<< "$entry"
        echo "$rev"
    fi
}

# Main loop
while true; do
    # Reset and show changelist
    SELECTED_COMMITS=()
    show_changelist
    SHOW_RESULT=$?

    if [ $SHOW_RESULT -ne 0 ]; then
        exit 1
    fi

    echo -n "Enter your choice: "
    read -r USER_CHOICE

    NUM_COMMITS=${#SELECTED_COMMITS[@]}

    # Parse and validate user choice
    case "$USER_CHOICE" in
        B|b)
            echo ""
            echo "Returning to ChooseMode..."
            exit 2
            ;;
        Q|q)
            echo ""
            echo "Exiting."
            exit 0
            ;;
        4)
            # Manual input mode - call validation_app_diff.sh for manual entry
            echo ""
            echo "Enter changeset number or node hash:"
            echo -n "> "
            read -r MANUAL_INPUT
            if [ -z "$MANUAL_INPUT" ]; then
                echo "No input provided. Returning to change list..."
                continue
            fi
            echo ""
            "$SCRIPT_DIR/validation_app_diff.sh" "$MANUAL_INPUT"
            EXIT_CODE=$?
            case $EXIT_CODE in
                2) continue ;;
                0|1) exit $EXIT_CODE ;;
                3) continue ;;
                *) exit $EXIT_CODE ;;
            esac
            ;;
        A|a)
            # Select ALL changesets
            ALL_REVS_FOR_ALL=""
            for entry in "${SELECTED_COMMITS[@]}"; do
                IFS='|' read -r rev date desc user_marker filecount filelist <<< "$entry"
                if [ -n "$ALL_REVS_FOR_ALL" ]; then
                    ALL_REVS_FOR_ALL="${ALL_REVS_FOR_ALL},${rev}"
                else
                    ALL_REVS_FOR_ALL="${rev}"
                fi
            done
            echo ""
            "$SCRIPT_DIR/validation_app_diff.sh" "$ALL_REVS_FOR_ALL"
            EXIT_CODE=$?
            case $EXIT_CODE in
                2) continue ;;
                0|1) exit $EXIT_CODE ;;
                3) continue ;;
                *) exit $EXIT_CODE ;;
            esac
            ;;
        *)
            # Check if comma-separated (multiple selections like 1,2 or 1,2,3)
            if [[ "$USER_CHOICE" == *","* ]]; then
                # Multiple changeset selection
                TRANSFORMED=""
                IFS=',' read -ra SELECTIONS <<< "$USER_CHOICE"
                for sel in "${SELECTIONS[@]}"; do
                    sel=$(echo "$sel" | tr -d ' ')
                    if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le $NUM_COMMITS ]; then
                        rev=$(get_changeset_from_index "$sel")
                        if [ -n "$TRANSFORMED" ]; then
                            TRANSFORMED="${TRANSFORMED},${rev}"
                        else
                            TRANSFORMED="${rev}"
                        fi
                    fi
                done
                if [ -n "$TRANSFORMED" ]; then
                    echo ""
                    "$SCRIPT_DIR/validation_app_diff.sh" "$TRANSFORMED"
                    EXIT_CODE=$?
                    case $EXIT_CODE in
                        2) continue ;;
                        0|1) exit $EXIT_CODE ;;
                        3) continue ;;
                        *) exit $EXIT_CODE ;;
                    esac
                fi
            fi

            # Single selection (1, 2, or 3)
            if [[ "$USER_CHOICE" =~ ^[0-9]+$ ]] && [ "$USER_CHOICE" -ge 1 ] && [ "$USER_CHOICE" -le $NUM_COMMITS ]; then
                rev=$(get_changeset_from_index "$USER_CHOICE")
                echo ""
                "$SCRIPT_DIR/validation_app_diff.sh" "$rev"
                EXIT_CODE=$?
                case $EXIT_CODE in
                    2) continue ;;
                    0|1) exit $EXIT_CODE ;;
                    3) continue ;;
                    *) exit $EXIT_CODE ;;
                esac
            else
                # Check if it's a direct changeset input (rev:node format or just number)
                # Pattern 1: rev:node format (e.g., 683103:1f571642b132)
                # Pattern 2: Just revision number (e.g., 518388)
                if [[ "$USER_CHOICE" =~ ^[0-9]+:[a-f0-9]+$ ]] || [[ "$USER_CHOICE" =~ ^[0-9]+$ ]]; then
                    echo ""
                    "$SCRIPT_DIR/validation_app_diff.sh" "$USER_CHOICE"
                    DIFF_EXIT_CODE=$?

                    # Check if there were validation app changes (exit code 0 = changes found)
                    if [ $DIFF_EXIT_CODE -eq 0 ]; then
                        echo ""
                        echo "============================================================"
                        echo "  Validation App Changes Detected"
                        echo "============================================================"
                        echo ""
                        echo "Changeset: $USER_CHOICE"
                        echo ""
                        echo "The above code changes may require XSLT migration script generation."
                        echo ""
                        echo "Select option:"
                        echo "  G             - Generate XSLT migration script"
                        echo "  V             - View code diff again"
                        echo "  B             - Back to changeset selection"
                        echo "  Q             - Quit and exit"
                        echo ""
                        echo -n "Enter your choice: "
                        read -r CONFIRM_CHOICE

                        case "$CONFIRM_CHOICE" in
                            G|g)
                                # Exit with code 3 to signal AI agent to continue Mode 3 workflow
                                echo ""
                                echo "============================================================"
                                echo "  XSLT Generation via AI Agent"
                                echo "============================================================"
                                echo ""
                                echo "Changeset: $USER_CHOICE"
                                echo ""
                                echo "Please use the AI agent to continue with XSLT generation."
                                echo ""
                                echo "The AI agent will:"
                                echo "  1. Map code diff → YANG schema (ValidationAppMode_CodeDiff.md)"
                                echo "  2. Analyze code changes and map to TranslatorStrategyCategory.json"
                                echo "  3. Generate XSLT following Mode 3 workflow"
                                echo ""
                                echo "Exiting script. Please use AI agent for XSLT generation."
                                exit 3
                                ;;
                            V|v)
                                # Re-run diff
                                echo ""
                                "$SCRIPT_DIR/validation_app_diff.sh" "$USER_CHOICE"
                                # After viewing, loop back to this confirmation
                                continue
                                ;;
                            B|b)
                                continue
                                ;;
                            Q|q)
                                exit 0
                                ;;
                            *)
                                echo "Invalid choice. Returning to changeset selection..."
                                continue
                                ;;
                        esac
                    fi

                    case $DIFF_EXIT_CODE in
                        2) continue ;;
                        0|1) exit $DIFF_EXIT_CODE ;;
                        3) continue ;;
                        *) exit $DIFF_EXIT_CODE ;;
                    esac
                fi

                echo ""
                echo "Error: Invalid selection '$USER_CHOICE'"
                continue
            fi
            ;;
    esac
done
