#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Migration Process Learning Tool - Workflow 1: Comprehensive XSLT Analysis

This script analyzes XSLT migration commits from the past N years,
traces JIRA tickets to their EPIC hierarchy, and finds related YANG
and validation app changes.

Supports 3 input types:
1. --scan-years N: Scan all XSLT from past N years (FULL SCAN)
2. --xslt PATH: Analyze single XSLT file (SINGLE FILE)
3. --jira KEY: Analyze specific JIRA ticket (SINGLE JIRA)

Usage:
    # Full scan - analyze all XSLT commits from past 3 years
    python migration_learner.py --scan-years 3 --output learned_output/

    # Single XSLT - analyze one XSLT file
    python migration_learner.py --xslt "qos/lsr2212_to_lsr2303_qos_unsupported_list_1.xsl"

    # Single JIRA - analyze a specific JIRA ticket
    python migration_learner.py --jira BBN-88491 --output learned_output/

Output:
    - All fetched JIRA data in ./{jira_key}/ directory
    - Found XSLT files mapped to JIRA tickets
    - Related YANG files and validation app changes
    - Confluence documentation (if found)
    - Summary report in markdown format
"""

from __future__ import print_function

import argparse
import json
import os
import re
import sys
import subprocess
import time
from collections import defaultdict
from datetime import datetime, timedelta

# ============================================================================
# Configuration
# ============================================================================

XSLT_BASE_DIR = "/home/zhenac/fiber_code/sw/vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl"
YANG_DEV_DIR = "/home/zhenac/fiber_code/sw/vobs/dsl/yang/deviations"
VALIDATION_APP_DIR = "/home/zhenac/fiber_code/sw/vobs/dsl/sw/y/build/apps/switch_validator_app"

SKILL_DIR = "/home/zhenac/fiber_code/sw/.cursor/skills/migration-process-learning"
JIRA_TOOL = "/home/zhenac/fiber_code/sw/.cursor/skills/jira-tool/scripts/jira_tool.py"
CONFLUENCE_TOOL = "/home/zhenac/fiber_code/sw/.cursor/skills/confluence-tool/scripts/confluence_tool.py"

# Default years for scanning
DEFAULT_SCAN_YEARS = 3

# JIRA prefixes to track
JIRA_PREFIXES = ['BBN', 'FNMS', 'AC']


# ============================================================================
# Utility Functions
# ============================================================================

def print_header(title):
    """Print a formatted header."""
    print("\n" + "=" * 70)
    print(title)
    print("=" * 70)


def print_step(step_num, description):
    """Print a step indicator."""
    print("\n[STEP {0}] {1}".format(step_num, description))


def ensure_output_dir(output_dir):
    """Create output directory if it doesn't exist."""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    return output_dir


def run_command(cmd, timeout=60, capture=True):
    """Run a shell command and return output."""
    try:
        if capture:
            result = subprocess.run(
                cmd, shell=True, capture_output=True,
                text=True, timeout=timeout
            )
            return result.stdout, result.stderr, result.returncode
        else:
            return subprocess.call(cmd, shell=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        print("  WARNING: Command timed out after {0}s".format(timeout))
        return "", "Timeout", -1
    except Exception as e:
        print("  WARNING: Command failed: {0}".format(e))
        return "", str(e), -1


# ============================================================================
# JIRA Integration
# ============================================================================

def fetch_jira_all(jira_key, output_dir=None):
    """Fetch all JIRA data using jira_tool."""
    print("  Fetching JIRA: {0}".format(jira_key))

    # Create directory for this JIRA
    jira_dir = os.path.join(output_dir or ".", jira_key) if output_dir else jira_key
    if not os.path.exists(jira_dir):
        os.makedirs(jira_dir)

    # Run jira_tool to fetch fields
    cmd = 'python "{0}" --id {1} --fetch-fields'.format(JIRA_TOOL, jira_key)
    stdout, stderr, rc = run_command(cmd, timeout=30)

    # Run jira_tool to fetch comments
    cmd = 'python "{0}" --id {1} --fetch-comments'.format(JIRA_TOOL, jira_key)
    stdout, stderr, rc = run_command(cmd, timeout=30)

    return jira_dir


def load_jira_fields(jira_key):
    """Load JIRA fields from cached file."""
    fields_file = "{0}/fields".format(jira_key)
    if os.path.exists(fields_file):
        with open(fields_file) as f:
            return json.load(f)
    return None


def get_jira_type(fields):
    """Determine if JIRA is EPIC, STORY, BUG, or SUBTASK."""
    if not fields:
        return "UNKNOWN"

    issue_type = fields.get('issuetype', {}).get('name', '')
    return issue_type.upper()


def get_parent_epic(fields):
    """Find parent EPIC for a JIRA ticket."""
    if not fields:
        return None

    # Check custom field for parent (common in many JIRA setups)
    parent_key = fields.get('customfield_12790') or fields.get('parent', {}).get('key')

    # Check issuelinks for epic link
    issuelinks = fields.get('issuelinks', [])
    for link in issuelinks:
        if 'inwardIssue' in link:
            inward = link['inwardIssue']
            inward_type = inward.get('fields', {}).get('issuetype', {}).get('name', '')
            if 'epic' in inward_type.lower():
                return inward.get('key')
        if 'outwardIssue' in link:
            outward = link['outwardIssue']
            outward_type = outward.get('fields', {}).get('issuetype', {}).get('name', '')
            if 'epic' in outward_type.lower():
                return outward.get('key')

    return parent_key


def get_linked_issues(fields):
    """Get all linked issues from JIRA fields."""
    linked = []

    issuelinks = fields.get('issuelinks', [])
    for link in issuelinks:
        for key in ['inwardIssue', 'outwardIssue']:
            if key in link:
                issue = link[key]
                linked.append({
                    'key': issue.get('key'),
                    'type': issue.get('fields', {}).get('issuetype', {}).get('name', ''),
                    'summary': issue.get('fields', {}).get('summary', '')[:60]
                })

    return linked


def extract_confluence_links(fields):
    """Extract Confluence page URLs from JIRA description/comments."""
    urls = []

    # Check description
    description = fields.get('description', '') or ''
    urls.extend(re.findall(r'https?://[^\s<>"\'\]]+', description))

    # Check comments
    comments_file = "{0}/comments".format(fields.get('key', ''))
    if os.path.exists(comments_file):
        with open(comments_file) as f:
            comments = json.load(f)
            for comment in comments:
                body = comment.get('body', '')
                urls.extend(re.findall(r'https?://[^\s<>"\'\]]+', body))

    # Filter to Confluence URLs
    confluence_urls = [u for u in urls if 'confluence' in u.lower()]

    # Deduplicate
    seen = set()
    unique = []
    for url in confluence_urls:
        if url not in seen:
            seen.add(url)
            unique.append(url)

    return unique


# ============================================================================
# XSLT Analysis
# ============================================================================

def find_all_xslt_files():
    """Find all XSLT files in the base directory."""
    results = []
    for root, dirs, files in os.walk(XSLT_BASE_DIR):
        for file in files:
            if file.endswith('.xsl'):
                results.append(os.path.join(root, file))
    return sorted(results)


def extract_jira_from_xslt(xslt_path):
    """Extract JIRA ticket numbers from XSLT file content."""
    try:
        with open(xslt_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception:
        return []

    # Find all JIRA-like patterns
    all_jiras = re.findall(r'\b([A-Z]+-\d+)\b', content)

    # Filter to known prefixes
    filtered = [j for j in all_jiras if any(p in j for p in JIRA_PREFIXES)]

    # Deduplicate while preserving order
    seen = set()
    unique = []
    for j in filtered:
        if j not in seen:
            seen.add(j)
            unique.append(j)

    return unique


def extract_version_from_xslt(xslt_path):
    """Extract source and target version from XSLT filename."""
    filename = os.path.basename(xslt_path)
    match = re.search(r'lsr(\d{4})_to_lsr(\d{4})', filename)
    if match:
        return match.group(1), match.group(2)
    return None, None


def find_xslt_files_for_jira(jira_key):
    """Find all XSLT files that reference a JIRA ticket."""
    results = []
    xslt_files = find_all_xslt_files()

    for xslt_path in xslt_files:
        jiras = extract_jira_from_xslt(xslt_path)
        if jira_key in jiras:
            results.append(xslt_path)

    return results


def scan_all_xslt_files(years=3, output_dir=None):
    """Scan all XSLT files and extract JIRA tickets."""
    print_header("SCANNING XSLT FILES (Past {0} years)".format(years))

    output_dir = ensure_output_dir(output_dir or "learned_output")

    # Find all XSLT files
    xslt_files = find_all_xslt_files()
    print("Found {0} XSLT files".format(len(xslt_files)))

    # Extract JIRA tickets
    jira_to_files = defaultdict(list)
    all_jiras = set()

    for i, xslt_path in enumerate(xslt_files):
        if (i + 1) % 100 == 0:
            print("  Processed {0}/{1} files...".format(i + 1, len(xslt_files)))

        jiras = extract_jira_from_xslt(xslt_path)
        for jira in jiras:
            jira_to_files[jira].append(xslt_path)
            all_jiras.add(jira)

    print("\nFound {0} unique JIRA tickets across all XSLT files".format(len(all_jiras)))

    # Group by project
    project_groups = defaultdict(list)
    for jira in sorted(all_jiras):
        project = jira.split('-')[0] if '-' in jira else jira
        project_groups[project].append(jira)

    print("\nJIRA distribution by project:")
    for project, jiras in sorted(project_groups.items()):
        print("  {0}: {1} tickets".format(project, len(jiras)))

    # Save mapping to file
    mapping_file = os.path.join(output_dir, "jira_to_xslt_mapping.json")
    with open(mapping_file, 'w') as f:
        json.dump({k: [os.path.relpath(p, XSLT_BASE_DIR) for p in v]
                   for k, v in jira_to_files.items()}, f, indent=2)
    print("\nMapping saved to: {0}".format(mapping_file))

    return jira_to_files, all_jiras


# ============================================================================
# YANG Analysis
# ============================================================================

def find_yang_files_for_jira(jira_key):
    """Find YANG deviation files related to a JIRA ticket."""
    results = []

    # Search in deviations directory
    for root, dirs, files in os.walk(YANG_DEV_DIR):
        for file in files:
            if file.endswith('.yang'):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        if jira_key in content or jira_key.lower() in content.lower():
                            results.append(filepath)
                except Exception:
                    pass

    # Deduplicate
    return list(set(results))


def extract_deviations_from_yang(yang_path):
    """Extract deviation statements from a YANG file."""
    deviations = []

    try:
        with open(yang_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

        # Find deviation blocks
        pattern = r'deviation\s+"([^"]+)"\s*\{([^}]+)\}'
        matches = re.findall(pattern, content, re.DOTALL)

        for xpath, body in matches:
            deviation_type = None

            # Determine deviation type
            if 'deviate not-supported' in body:
                deviation_type = 'not-supported'
            elif 'deviate add must' in body:
                # Extract must constraint
                must_match = re.search(r'must\s+"([^"]+)"', body)
                deviation_type = 'must' if must_match else 'add'
            elif 'deviate add mandatory' in body:
                deviation_type = 'mandatory'
            elif 'deviate replace' in body:
                deviation_type = 'replace'

            deviations.append({
                'xpath': xpath,
                'type': deviation_type,
                'body': body.strip()[:200]
            })
    except Exception:
        pass

    return deviations


# ============================================================================
# Validation App Analysis
# ============================================================================

def find_validation_rules_for_jira(jira_key):
    """Find validation rules related to a JIRA ticket."""
    results = {}

    # Search in validation app directory
    for root, dirs, files in os.walk(VALIDATION_APP_DIR):
        for file in files:
            if file.endswith(('.json', '.cpp', '.h')):
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        if jira_key in content:
                            relpath = os.path.relpath(filepath, VALIDATION_APP_DIR)
                            results[relpath] = content[:500]  # First 500 chars
                except Exception:
                    pass

    return results


def analyze_validation_json():
    """Analyze validation rule categories from JSON files."""
    categories = {}

    json_files = [
        os.path.join(VALIDATION_APP_DIR, 'ValidationRuleCategory.json'),
        os.path.join(VALIDATION_APP_DIR, 'ValidationRuleErrorMsg.json'),
    ]

    for json_file in json_files:
        if os.path.exists(json_file):
            try:
                with open(json_file) as f:
                    data = json.load(f)
                    categories[os.path.basename(json_file)] = data
            except Exception:
                pass

    return categories


# ============================================================================
# Confluence Integration
# ============================================================================

def search_confluence(query, output_dir=None, limit=10):
    """Search Confluence for pages matching query."""
    print("  Searching Confluence: {0}".format(query))

    output_dir = ensure_output_dir(output_dir or ".")

    cmd = 'python "{0}" --search "{1}" --limit {2} --output "{3}/confluence_search.txt"'.format(
        CONFLUENCE_TOOL, query, limit, output_dir
    )

    stdout, stderr, rc = run_command(cmd, timeout=60)

    results_file = os.path.join(output_dir, "confluence_search.txt")
    if os.path.exists(results_file):
        with open(results_file) as f:
            return f.read()
    return ""


def fetch_confluence_page(url, output_dir=None):
    """Fetch a Confluence page."""
    print("  Fetching Confluence page: {0}".format(url[:80]))

    output_dir = ensure_output_dir(output_dir or ".")

    # Generate output filename from URL
    page_id_match = re.search(r'pageId=(\d+)', url)
    if page_id_match:
        output_file = os.path.join(output_dir, "confluence_page_{0}.txt".format(page_id_match.group(1)))
    else:
        output_file = os.path.join(output_dir, "confluence_page.txt")

    cmd = 'python "{0}" --fetch --url "{1}" --output "{2}"'.format(
        CONFLUENCE_TOOL, url, output_file
    )

    stdout, stderr, rc = run_command(cmd, timeout=60)

    if os.path.exists(output_file):
        with open(output_file) as f:
            return f.read()
    return ""


# ============================================================================
# Single Analysis Functions
# ============================================================================

def analyze_single_xslt(xslt_path, output_dir=None):
    """Analyze a single XSLT file and trace back to JIRA/YANG/validation."""
    print_header("ANALYZING SINGLE XSLT: {0}".format(xslt_path))

    output_dir = ensure_output_dir(output_dir or "learned_output")

    # Resolve path
    if not xslt_path.startswith('/'):
        xslt_path = os.path.join(XSLT_BASE_DIR, xslt_path)

    if not os.path.exists(xslt_path):
        print("ERROR: File not found: {0}".format(xslt_path))
        return

    # Extract JIRA tickets
    jiras = extract_jira_from_xslt(xslt_path)
    print("\nFound JIRA tickets: {0}".format(jiras))

    # Extract version info
    src_ver, tgt_ver = extract_version_from_xslt(xslt_path)
    if src_ver and tgt_ver:
        print("Version: LSR{0} -> LSR{1}".format(src_ver, tgt_ver))

    # For each JIRA, fetch details
    for jira in jiras:
        print_step(2, "Fetching JIRA: {0}".format(jira))
        fetch_jira_all(jira, output_dir)

        # Load fields
        fields = load_jira_fields(jira)
        if fields:
            # Determine type
            issue_type = get_jira_type(fields)
            print("  Type: {0}".format(issue_type))

            # Find parent EPIC if not an EPIC
            if 'EPIC' not in issue_type:
                parent_epic = get_parent_epic(fields)
                if parent_epic:
                    print("  Parent EPIC: {0}".format(parent_epic))

                    # Fetch parent EPIC
                    print_step(3, "Fetching Parent EPIC: {0}".format(parent_epic))
                    fetch_jira_all(parent_epic, output_dir)

            # Find linked issues
            linked = get_linked_issues(fields)
            if linked:
                print("  Linked issues ({0}):".format(len(linked)))
                for l in linked[:5]:
                    print("    - {0} [{1}]: {2}...".format(
                        l['key'], l['type'], l['summary'][:40]))

    # Find YANG files
    print_step(4, "Finding YANG deviation files")
    for jira in jiras:
        yang_files = find_yang_files_for_jira(jira)
        if yang_files:
            print("  Found {0} YANG files for {1}".format(len(yang_files), jira))
            for yf in yang_files[:3]:
                print("    - {0}".format(os.path.relpath(yf, '/home/zhenac/fiber_code/sw')))

    # Find validation app changes
    print_step(5, "Finding validation app changes")
    for jira in jiras:
        validation_changes = find_validation_rules_for_jira(jira)
        if validation_changes:
            print("  Found {0} validation files for {1}".format(len(validation_changes), jira))
            for vf in list(validation_changes.keys())[:3]:
                print("    - {0}".format(vf))

    print("\nAnalysis complete. Data saved to: {0}".format(output_dir))


def analyze_single_jira(jira_key, output_dir=None):
    """Analyze a single JIRA ticket and trace to XSLT/YANG/validation."""
    print_header("ANALYZING SINGLE JIRA: {0}".format(jira_key))

    output_dir = ensure_output_dir(output_dir or "learned_output")

    # Step 1: Fetch JIRA
    print_step(1, "Fetching JIRA: {0}".format(jira_key))
    fetch_jira_all(jira_key, output_dir)

    # Load fields
    fields = load_jira_fields(jira_key)
    if not fields:
        print("ERROR: Could not load JIRA fields for {0}".format(jira_key))
        return

    # Determine type
    issue_type = get_jira_type(fields)
    print("  Type: {0}".format(issue_type))
    print("  Summary: {0}".format(fields.get('summary', 'N/A')[:60]))

    # Step 2: Find related JIRAs
    print_step(2, "Finding related JIRA tickets")

    linked = get_linked_issues(fields)
    if linked:
        print("  Linked issues ({0}):".format(len(linked)))
        for l in linked[:10]:
            print("    - {0} [{1}]: {2}".format(l['key'], l['type'], l['summary'][:50]))

    # If not an EPIC, find parent
    if 'EPIC' not in issue_type:
        parent_epic = get_parent_epic(fields)
        if parent_epic:
            print("\n  Parent EPIC: {0}".format(parent_epic))
            print_step(2, "Fetching Parent EPIC: {0}".format(parent_epic))
            fetch_jira_all(parent_epic, output_dir)

            # Load parent fields for additional linked issues
            parent_fields = load_jira_fields(parent_epic)
            if parent_fields:
                parent_linked = get_linked_issues(parent_fields)
                if parent_linked:
                    print("  EPIC linked issues ({0}):".format(len(parent_linked)))
                    for l in parent_linked[:10]:
                        print("    - {0} [{1}]: {2}".format(
                            l['key'], l['type'], l['summary'][:50]))

    # Step 3: Find Confluence docs
    print_step(3, "Searching Confluence documentation")
    confluence_urls = extract_confluence_links(fields)
    if confluence_urls:
        print("  Found {0} Confluence links in JIRA".format(len(confluence_urls)))
        for url in confluence_urls[:3]:
            print("    - {0}".format(url[:80]))
            fetch_confluence_page(url, output_dir)
    else:
        # Search by JIRA key
        search_confluence(jira_key, output_dir)

    # Step 4: Find XSLT files
    print_step(4, "Finding XSLT migration files")
    xslt_files = find_xslt_files_for_jira(jira_key)
    if xslt_files:
        print("  Found {0} XSLT files:".format(len(xslt_files)))
        for xf in xslt_files[:5]:
            print("    - {0}".format(os.path.relpath(xf, XSLT_BASE_DIR)))
    else:
        # Search for partial match
        print("  No XSLT files found with exact match")

    # Step 5: Find YANG deviation files
    print_step(5, "Finding YANG deviation files")
    yang_files = find_yang_files_for_jira(jira_key)
    if yang_files:
        print("  Found {0} YANG files:".format(len(yang_files)))
        for yf in yang_files[:5]:
            print("    - {0}".format(os.path.relpath(yf, '/home/zhenac/fiber_code/sw')))

            # Extract deviations
            deviations = extract_deviations_from_yang(yf)
            if deviations:
                print("      Deviations found:")
                for d in deviations[:3]:
                    print("        - {0}: {1}".format(d['type'], d['xpath'][:50]))

    # Step 6: Find validation app changes
    print_step(6, "Finding validation app changes")
    validation_changes = find_validation_rules_for_jira(jira_key)
    if validation_changes:
        print("  Found {0} validation files:".format(len(validation_changes)))
        for vf in list(validation_changes.keys())[:5]:
            print("    - {0}".format(vf))

    print("\nAnalysis complete. Data saved to: {0}".format(output_dir))


# ============================================================================
# Full Scan Workflow
# ============================================================================

def run_full_scan(years=3, output_dir=None):
    """Run comprehensive scan of all XSLT files from past N years."""
    print_header("FULL SCAN: XSLT FILES FROM PAST {0} YEARS".format(years))

    output_dir = ensure_output_dir(output_dir or "learned_output")

    # Step 1: Scan all XSLT files
    print_step(1, "Scanning all XSLT files")
    jira_to_files, all_jiras = scan_all_xslt_files(years, output_dir)

    if not all_jiras:
        print("No JIRA tickets found in XSLT files.")
        return

    # Step 2: Fetch all unique JIRAs
    print_step(2, "Fetching JIRA data for all tickets")
    epic_groups = defaultdict(list)  # group JIRAs by EPIC

    for jira in sorted(all_jiras):
        print("  Fetching: {0}".format(jira))

        # Rate limiting
        time.sleep(0.5)

        fetch_jira_all(jira, output_dir)

        # Load and categorize
        fields = load_jira_fields(jira)
        if fields:
            issue_type = get_jira_type(fields)
            parent_epic = get_parent_epic(fields)

            if parent_epic:
                epic_groups[parent_epic].append(jira)
            elif 'EPIC' in issue_type:
                epic_groups[jira].append(jira)

    # Step 3: For each EPIC, trace down to find YANG and validation
    print_step(3, "Tracing EPIC hierarchy and finding related files")

    all_epics = list(epic_groups.keys())
    print("  Found {0} EPICs".format(len(all_epics)))

    epic_summary = []

    for epic in sorted(all_epics):
        print("\n  Processing EPIC: {0}".format(epic))

        # Get EPIC details
        epic_fields = load_jira_fields(epic)
        if not epic_fields:
            continue

        epic_summary.append({
            'epic': epic,
            'summary': epic_fields.get('summary', '')[:60],
            'type': get_jira_type(epic_fields),
            'linked_jiras': epic_groups[epic]
        })

        # For each related JIRA under this EPIC
        for jira in epic_groups[epic]:
            # Find YANG files
            yang_files = find_yang_files_for_jira(jira)
            for yf in yang_files:
                print("    YANG: {0}".format(os.path.basename(yf)))

            # Find validation files
            validation_files = find_validation_rules_for_jira(jira)
            for vf in validation_files.keys():
                print("    Validation: {0}".format(vf))

    # Step 4: Search Confluence for documentation
    print_step(4, "Searching Confluence for documentation")

    # Search for each major epic
    for epic_data in epic_summary[:5]:
        epic_key = epic_data['epic']
        search_confluence(epic_key, output_dir)

    # Step 5: Generate summary report
    print_step(5, "Generating summary report")

    report_file = os.path.join(output_dir, "scan_summary_{0}.md".format(
        datetime.now().strftime("%Y%m%d_%H%M%S")))

    report_content = """# Migration Learning Scan Summary

Generated: {date}
Scan Period: Past {years} years

## Overview

- Total XSLT files scanned: {total_xslt}
- Unique JIRA tickets found: {total_jiras}
- EPICs identified: {total_epics}

## EPIC Summary

| EPIC Key | Summary | Type | Related JIRAs |
|----------|---------|------|---------------|
{epic_table}

## Next Steps

1. Review the EPIC summary above
2. For each EPIC, analyze the linked JIRAs for pattern identification
3. Cross-reference YANG deviation files with XSLT logic
4. Check validation app rules for enforcement logic
5. Update Strategy_Learned.md with discovered patterns
""".format(
        date=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        years=years,
        total_xslt=len(find_all_xslt_files()),
        total_jiras=len(all_jiras),
        total_epics=len(epic_summary),
        epic_table="\n".join([
            "| {0} | {1} | {2} | {3} |".format(
                e['epic'], e['summary'][:40], e['type'], len(e['linked_jiras']))
            for e in epic_summary
        ])
    )

    with open(report_file, 'w') as f:
        f.write(report_content)

    print("\nSummary report saved to: {0}".format(report_file))

    print("\n" + "=" * 70)
    print("FULL SCAN COMPLETE")
    print("=" * 70)
    print("\nOutput directory: {0}".format(output_dir))
    print("Next step: Update Strategy_Learned.md with discovered patterns")


# ============================================================================
# Main Entry Point
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description="Migration Process Learning Tool - Workflow 1",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Full scan - analyze all XSLT from past 3 years
  python migration_learner.py --scan-years 3 --output learned_output/

  # Single XSLT - analyze one file
  python migration_learner.py --xslt "qos/lsr2212_to_lsr2303_qos_unsupported_list_1.xsl"

  # Single JIRA - analyze a ticket
  python migration_learner.py --jira BBN-88491 --output learned_output/

  # Search XSLT files
  python migration_learner.py --search "qos" --output learned_output/
        """
    )

    # Input type selection
    input_group = parser.add_argument_group("Input Types (choose one)")
    input_group.add_argument('--scan-years', type=int,
                              help='Scan all XSLT from past N years')
    input_group.add_argument('--xslt', type=str,
                              help='Analyze a single XSLT file (relative or absolute path)')
    input_group.add_argument('--jira', type=str,
                              help='Analyze a single JIRA ticket')
    input_group.add_argument('--search', type=str,
                              help='Search XSLT files by name pattern')

    # Output options
    output_group = parser.add_argument_group("Output Options")
    output_group.add_argument('--output', '-o', type=str, default='learned_output',
                              help='Output directory (default: learned_output/)')

    args = parser.parse_args()

    # Count input types
    input_count = sum([
        bool(args.scan_years),
        bool(args.xslt),
        bool(args.jira),
        bool(args.search)
    ])

    if input_count == 0:
        parser.print_help()
        print("\n" + "=" * 70)
        print("3 INPUT TYPES AVAILABLE:")
        print("=" * 70)
        print("  --scan-years N  : Full scan of all XSLT from past N years")
        print("  --xslt PATH     : Single XSLT file analysis")
        print("  --jira KEY      : Single JIRA ticket analysis")
        print("  --search PATTERN: Search XSLT files by name")
        print("=" * 70)
        sys.exit(1)

    if input_count > 1:
        print("ERROR: Please specify only one input type at a time.")
        sys.exit(1)

    # Execute based on input type
    if args.scan_years:
        run_full_scan(args.scan_years, args.output)

    elif args.xslt:
        analyze_single_xslt(args.xslt, args.output)

    elif args.jira:
        analyze_single_jira(args.jira, args.output)

    elif args.search:
        print_header("SEARCHING XSLT FILES: {0}".format(args.search))
        xslt_files = find_all_xslt_files()
        results = [f for f in xslt_files if args.search.lower() in f.lower()]
        print("Found {0} matching files:".format(len(results)))
        for r in results[:20]:
            print("  {0}".format(os.path.relpath(r, XSLT_BASE_DIR)))
        if len(results) > 20:
            print("  ... and {0} more".format(len(results) - 20))


if __name__ == "__main__":
    main()
