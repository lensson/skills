#!/bin/bash
cd /home/zhenac/fiber_code/sw

CURRENT_USER=$(hg config ui.username 2>/dev/null | cut -d'<' -f1 | sed 's/[[:space:]]*$//')
[ -z "$CURRENT_USER" ] && CURRENT_USER=${USER:-zhenac}

echo "=== Find Recent YANG Changes for User: $CURRENT_USER ==="
echo ""

# Get recent yang commits for this user
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

# Header
echo "| # | Changeset | Node | Date | Description | YANG Files | Diff |"
echo "|---|----------|------|------|-------------|------------|-----|"

# Parse and display first 3 revisions with yang files and diff stats
idx=0
while IFS='|' read -r rev node date desc; do
    idx=$((idx + 1))
    [ $idx -gt 3 ] && break
    
    # Get yang files for this revision
    YANG_FILES=$(hg log -r "$rev" -v --template "{file_mods}" 2>/dev/null | tr ' ' '\n' | grep '\.yang$' | head -3)
    YANG_COUNT=$(hg log -r "$rev" -v --template "{file_mods}" 2>/dev/null | tr ' ' '\n' | grep -c '\.yang$' || echo "0")
    YANG_TOTAL=$(hg log -r "$rev" -v --template "{file_mods}" 2>/dev/null | tr ' ' '\n' | grep -c '\.yang$' || echo "0")
    
    # Get diff stats for yang files (basename + lines)
    YANG_DISPLAY=""
    TOTAL_ADD=0
    for yang_file in $YANG_FILES; do
        basename_file=$(basename "$yang_file")
        diff_output=$(hg diff -r $((rev-1)) -r "$rev" -I "$yang_file" 2>/dev/null)
        adds=$(echo "$diff_output" | grep -c '^+' || echo "0")
        adds=$((adds - 1))
        TOTAL_ADD=$((TOTAL_ADD + adds))
        if [ -n "$YANG_DISPLAY" ]; then
            YANG_DISPLAY="$YANG_DISPLAY<br>+${adds} $basename_file"
        else
            YANG_DISPLAY="+${adds} $basename_file"
        fi
    done
    
    # Add ellipsis if more than 3 yang files
    if [ "$YANG_TOTAL" -gt 3 ]; then
        YANG_DISPLAY="$YANG_DISPLAY<br>..."
    fi
    
    # Create clickable diff link (using OSC 8 hyperlink for terminal)
    DIFF_LINK="\033]8;;https://mercurial.example.com/hg/rev/$rev\033\\[${YANG_COUNT} YANG +${TOTAL_ADD} lines]\033]8;;\033\\"
    
    echo "| $idx | $rev | $node | $date | $desc | $YANG_DISPLAY | $DIFF_LINK |"
done <<< "$REVS"

echo ""
echo "---"
echo "Enter number to view diff (1, 2, 3), or 4 to input changeset/revision manually:"
