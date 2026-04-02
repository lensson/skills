#!/bin/bash
cd /home/zhenac/fiber_code/sw

format_short_date() {
    echo "$1" | cut -c1-16
}

CURRENT_USER=$(hg config ui.username 2>/dev/null | cut -d'<' -f1 | sed 's/[[:space:]]*$//')
[ -z "$CURRENT_USER" ] && CURRENT_USER=${USER:-zhenac}

echo ""
echo "=== Find Recent YANG Changes for User: $CURRENT_USER ==="
echo ""

if [ -n "$CURRENT_USER" ]; then
    REVS=$(hg log --limit 10 -I "vobs/dsl/yang/**/*.yang" -u "$CURRENT_USER" --template "{rev}|{node|short}|{date|isodate}|{desc|firstline}\n" 2>/dev/null)
fi

if [ -z "$REVS" ]; then
    REVS=$(hg log --limit 10 -I "vobs/dsl/yang/**/*.yang" --template "{rev}|{node|short}|{date|isodate}|{desc|firstline}\n" 2>/dev/null)
fi

if [ -z "$REVS" ]; then
    echo "No commits with YANG files found"
    exit 1
fi

idx=0
declare -a COMMITS

while IFS='|' read -r rev node date desc; do
    idx=$((idx + 1))
    [ $idx -gt 3 ] && break

    date=$(format_short_date "$date")

    ALL_YANG_FILES=$(hg log -r "$rev" -v --template "{file_mods}" 2>/dev/null | tr ' ' '\n' | grep '\.yang$' | sort -u)

    FILE_ENTRIES=()
    TOTAL_ADD=0
    TOTAL_DEL=0
    FILE_COUNT=0
    while IFS= read -r yang_file; do
        [ -z "$yang_file" ] && continue
        diff_output=$(hg diff -r $((rev-1)) -r "$rev" -I "$yang_file" 2>/dev/null)
        adds=$(echo "$diff_output" | grep -c '^+' || echo "0")
        dels=$(echo "$diff_output" | grep -c '^-' || echo "0")
        adds=$((adds - 1))
        TOTAL_ADD=$((TOTAL_ADD + adds))
        TOTAL_DEL=$((TOTAL_DEL + dels))
        FILE_COUNT=$((FILE_COUNT + 1))
        basename_file=$(basename "$yang_file")
        FILE_ENTRIES+=("${basename_file}|+${adds}/-${dels}")
    done <<< "$ALL_YANG_FILES"

    # Store entries as joined by TAB (since filenames can have dashes)
    ENTRIES_STR=$(IFS=$'\t'; echo "${FILE_ENTRIES[*]}")
    COMMITS+=("$idx|$rev|$node|$date|$desc|${TOTAL_ADD}|${TOTAL_DEL}|${FILE_COUNT}|${ENTRIES_STR}")
done <<< "$REVS"

NUM_COMMITS=$idx

# Column widths: content-only (no padding)
COL1_W=3    # #
COL2_W=10   # Changeset
COL3_W=12   # Node
COL4_W=16   # Date
COL5_W=0    # Description
COL6_W=0    # YANG Files (file|+add/-del)

for entry in "${COMMITS[@]}"; do
    IFS='|' read -r i rev node date desc adds dels filecount entries <<< "$entry"
    [ ${#desc} -gt $COL5_W ] && COL5_W=${#desc}
    # Find max file entry width (filename + "+N/-N")
    IFS=$'\t' read -ra FE <<< "$entries"
    for fe in "${FE[@]}"; do
        [ ${#fe} -gt $COL6_W ] && COL6_W=${#fe}
    done
done

[ $COL5_W -gt 65 ] && COL5_W=65
[ $COL6_W -lt 14 ] && COL6_W=14

PAD=2
C1=$((COL1_W + PAD))
C2=$((COL2_W + PAD))
C3=$((COL3_W + PAD))
C4=$((COL4_W + PAD))
C5=$((COL5_W + PAD))
C6=$((COL6_W + PAD))

# Build borders using printf so alignment is guaranteed with data rows
# printf "%s" uses raw chars, so BOX DASH and │ align pixel-perfectly
# Format: ┌<C1─>┼<C2─>┼<C3─>┼<C4─>┼<C5─>┼<C6─>┐
TOP=$(printf "┌%${C1}s┬%${C2}s┬%${C3}s┬%${C4}s┬%${C5}s┬%${C6}s┐" \
    "$(printf '%.0s─' $(seq 1 $C1))" \
    "$(printf '%.0s─' $(seq 1 $C2))" \
    "$(printf '%.0s─' $(seq 1 $C3))" \
    "$(printf '%.0s─' $(seq 1 $C4))" \
    "$(printf '%.0s─' $(seq 1 $C5))" \
    "$(printf '%.0s─' $(seq 1 $C6))")

MID=$(printf "├%${C1}s┼%${C2}s┼%${C3}s┼%${C4}s┼%${C5}s┼%${C6}s┤" \
    "$(printf '%.0s─' $(seq 1 $C1))" \
    "$(printf '%.0s─' $(seq 1 $C2))" \
    "$(printf '%.0s─' $(seq 1 $C3))" \
    "$(printf '%.0s─' $(seq 1 $C4))" \
    "$(printf '%.0s─' $(seq 1 $C5))" \
    "$(printf '%.0s─' $(seq 1 $C6))")

BOT=$(printf "└%${C1}s┴%${C2}s┴%${C3}s┴%${C4}s┴%${C5}s┴%${C6}s┘" \
    "$(printf '%.0s─' $(seq 1 $C1))" \
    "$(printf '%.0s─' $(seq 1 $C2))" \
    "$(printf '%.0s─' $(seq 1 $C3))" \
    "$(printf '%.0s─' $(seq 1 $C4))" \
    "$(printf '%.0s─' $(seq 1 $C5))" \
    "$(printf '%.0s─' $(seq 1 $C6))")

# Data printf format: left-justify each cell with exact width
FMT="│%-${C1}s│%-${C2}s│%-${C3}s│%-${C4}s│%-${C5}s│%-${C6}s│"

echo "$TOP"
printf "$FMT\n" " #" "Changeset" "Node" "Date" "Description" "YANG Files"
echo "$MID"

first_commit=1
for entry in "${COMMITS[@]}"; do
    IFS='|' read -r i rev node date desc adds dels filecount entries <<< "$entry"

    if [ ${#desc} -gt $COL5_W ]; then
        desc="${desc:0:$((COL5_W-3))}..."
    fi

    IFS=$'\t' read -ra FE <<< "$entries"
    num_files=$filecount

    # Print separator before commit (except first)
    if [ $first_commit -eq 0 ]; then
        echo "$MID"
    fi
    first_commit=0

    # First row: commit info + first file entry
    first_file="${FE[0]}"
    printf "$FMT\n" " $i" " $rev" " $node" " $date" " $desc" " $first_file"

    # Remaining file entries (one per line)
    for ((j=1; j<num_files; j++)); do
        printf "$FMT\n" "" "" "" "" "" " ${FE[$j]}"
    done

    # More files indicator
    if [ $num_files -gt 3 ]; then
        printf "$FMT\n" "" "" "" "" "" " ... +$((num_files - 3)) more files"
    fi
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
