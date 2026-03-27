#!/bin/bash
# Interactive XSLT Generator for Lightspan release upgrades
# Provides guided workflow for generating migration scripts

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd /home/zhenac/fiber_code/sw

# Get hg username
CURRENT_USER=$(hg config ui.username 2>/dev/null | cut -d'<' -f1 | sed 's/[[:space:]]*$//')
if [ -z "$CURRENT_USER" ]; then
    CURRENT_USER=${USER:-zhenac}
fi

show_menu() {
    clear
    echo "═══════════════════════════════════════════════════════════════════"
    echo "                    XSLT Migration Script Generator               "
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    echo "Please choose Mode 1 or 2:"
    echo ""
    echo "Mode 1: Intent-Based Generation"
    echo "Use this when you know exactly what changes you want to make."
    echo ""
    echo "  Migration Intent: Describe what you want to do"
    echo "                    (e.g., rename node, delete field, change type)"
    echo "  Input XML: Example configuration before migration"
    echo "  Output XML: Expected configuration after migration"
    echo ""
    echo "Mode 2: YANG Change-Based Generation"
    echo "Use this when YANG files have been modified and you need to"
    echo "automatically generate migration scripts."
    echo ""
    echo "  I will help you generate XSLT based on your recent YANG changes"
    echo "  or specified commit records."
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo -n "Enter option (1 or 2): "
}

show_mode2_options() {
    clear
    echo "═══════════════════════════════════════════════════════════════════"
    echo "            Mode 2: YANG Change-Based Generation                  "
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    echo "Finding recent YANG changes for user: $CURRENT_USER"
    echo ""

    # Run the find script with correct path
    RESULTS=$(bash "$SCRIPT_DIR/find-yang-changes.sh" 2>/dev/null)
    
    if [ -z "$RESULTS" ]; then
        echo "No recent commits containing YANG files found for this user."
        echo ""
        echo "═══════════════════════════════════════════════════════════════════"
        echo -n "Enter hg revision number to generate (or 'q' to return): "
        return
    fi

    echo "Please select an option:"
    echo ""
    echo "  1) Use one of the following commits"
    echo ""
    
    local count=0
    while IFS='|' read -r rev node date desc files; do
        count=$((count + 1))
        desc_trunc=$(echo "$desc" | cut -c1-60)
        echo "     [$count] Revision $rev ($node) - $date"
        echo "          $desc_trunc"
        echo "          YANG: $files"
        echo ""
    done <<< "$RESULTS"
    
    echo "  4) Enter hg revision number manually"
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo -n "Enter option (1-$count or 4): "
}

# Main interaction loop
while true; do
    show_menu
    read choice
    
    case $choice in
        1)
            echo ""
            echo ">>> Mode 1: Intent-Based Generation"
            echo ""
            echo "Please provide the following to generate XSLT:"
            echo ""
            echo "  1. Migration Intent: What do you want to do?"
            echo "     Example: Rename node 'old-name' to 'new-name'"
            echo ""
            echo "  2. Input XML: Configuration before migration"
            echo ""
            echo "  3. Output XML: Expected configuration after migration"
            echo ""
            echo "Mode 1 requires detailed interaction. Please describe your needs"
            echo "directly and I will help you generate the XSLT."
            echo ""
            echo "Press Enter to continue..."
            read dummy
            ;;
        2)
            echo ""
            echo ">>> Mode 2: YANG Change-Based Generation"
            show_mode2_options
            read choice2
            
            if [ "$choice2" = "q" ] || [ -z "$choice2" ]; then
                continue
            fi
            
            echo ""
            echo ">>> You selected option: $choice2"
            echo ">>> Extracting YANG changes and generating XSLT..."
            echo ""
            echo ">>> This feature is under development."
            echo ""
            echo "Press Enter to continue..."
            read dummy
            ;;
        q|Q)
            echo "Exit"
            exit 0
            ;;
        *)
            echo ""
            echo "Invalid option. Please enter 1 or 2."
            sleep 1
            ;;
    esac
done
