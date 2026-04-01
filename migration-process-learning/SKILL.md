---
name: migration-process-learning
description: Learn migration patterns from historical XSLT commits via Workflow 1. Supports 3 input types: (1) All commits within N years, (2) Single XSLT changeset, (3) JIRA ticket. Outputs comprehensive analysis and updates Strategy_Learned.md.
---

# Migration Process Learning - Workflow 1

Comprehensive workflow to learn migration patterns by tracing the complete development lifecycle: from XSLT commits back to EPIC requirements, through YANG changes and validation app code.

---

## Overview

This SKILL supports **3 different input types**. Each input triggers a systematic analysis that traces:
1. **XSLT** → **JIRA Ticket** → **EPIC Hierarchy**
2. **EPIC** → **YANG Deviation Files**
3. **EPIC** → **Validation App Changes**
4. **JIRA** → **Confluence Documentation**

---

## Quick Start

### Command Syntax

```bash
cd /home/zhenac/fiber_code/sw/.cursor/skills/migration-process-learning/scripts
SKILL_DIR="/home/zhenac/fiber_code/sw/.cursor/skills/migration-process-learning"

# Input Type 1: Full scan of all XSLT from past N years
python migration_learner.py --scan-years 3 --output learned_output/

# Input Type 2: Single XSLT file analysis
python migration_learner.py --xslt "qos/lsr2212_to_lsr2303_qos_unsupported_list_1.xsl"

# Input Type 3: Single JIRA ticket analysis
python migration_learner.py --jira BBN-88491 --output learned_output/

# Search XSLT files by pattern
python migration_learner.py --search "qos" --output learned_output/
```

---

## Input Type 1: All XSLT Commits (Past N Years)

### When to Use

When you want to comprehensively scan all migration XSLT commits from the past N years to build a complete knowledge base.

### Workflow

```
+=============================================================================+
|                    COMPREHENSIVE SCAN (Past N Years)                        |
+=============================================================================+

    +-----------------+      +-----------------+      +-----------------+
    |  1. List all    |----->|  2. For each    |----->|  3. Extract     |
    |  XSLT files     |      |  XSLT, find     |      |  JIRA from      |
    |  in directory   |      |  JIRA reference |      |  comments       |
    +-----------------+      +-----------------+      +-----------------+
           |                         |                         |
           v                         v                         v
    +-----------------+      +-----------------+      +-----------------+
    |  4. Group by   |<-----|  5. Deduplicate  |-----|  6. For each   |
    |  EPIC          |      |  JIRAs          |      |  JIRA, fetch    |
    |                |      |                 |      |  full details   |
    +-----------------+      +-----------------+      +-----------------+
           |                         |                         |
           v                         v                         v
    +-----------------+      +-----------------+      +-----------------+
    |  7. For each   |<-----|  8. Find all    |<-----|  9. Get EPIC    |
    |  EPIC, collect |      |  STORIES under  |      |  linked issues  |
    |  all related   |      |  EPIC          |      |                 |
    +-----------------+      +-----------------+      +-----------------+
           |                         |
           v                         v
    +-----------------+      +-----------------+
    |  10. Find YANG |<-----|  11. Search     |
    |  deviation     |      |  validation     |
    |  files        |      |  app changes    |
    +-----------------+      +-----------------+
           |
           v
    +-----------------+
    |  12. Generate   |
    |  summary report |
    +-----------------+

+=============================================================================+
```

### Step-by-Step Process

| Step | Action | Command/Method |
|------|--------|----------------|
| 1 | Find all XSLT files | `find_all_xslt_files()` |
| 2 | Extract JIRA from comments | `extract_jira_from_xslt()` |
| 3 | Group JIRAs by EPIC | `get_parent_epic()` |
| 4 | Fetch JIRA details | `fetch_jira_all()` |
| 5 | Find YANG deviation files | `find_yang_files_for_jira()` |
| 6 | Find validation rules | `find_validation_rules_for_jira()` |
| 7 | Search Confluence | `search_confluence()` |
| 8 | Generate report | `run_full_scan()` |

### Example

```bash
# Scan all XSLT from past 3 years
python migration_learner.py --scan-years 3 --output ~/migration_scan_2026/
```

### Output

```
learned_output/
├── BBN-88491/          # JIRA data (fields, comments)
│   ├── fields
│   └── comments
├── BBN-96114/
│   ├── fields
│   └── comments
├── jira_to_xslt_mapping.json   # JIRA → XSLT file mapping
└── scan_summary_20260331.md      # Summary report
```

---

## Input Type 2: Single XSLT Changeset

### When to Use

When you have a specific XSLT file or changeset to analyze (e.g., changeset number or file path).

### Workflow

```
+=============================================================================+
|                    SINGLE XSLT CHANGESET ANALYSIS                          |
+=============================================================================+

    +-----------------+      +-----------------+      +-----------------+
    |  1. Read XSLT  |----->|  2. Extract     |----->|  3. Identify    |
    |  file content   |      |  JIRA ticket   |      |  JIRA type:    |
    |                |      |  from comments  |      |  EPIC/STORY/BUG|
    +-----------------+      +-----------------+      +-----------------+
           |                         |                         |
           v                         v                         v
    +-----------------+      +-----------------+      +-----------------+
    |  4. If STORY:   |<-----|  5. Fetch JIRA |------>|  6. Find       |
    |  find parent    |      |  details       |       |  EPIC from     |
    |  EPIC          |      |               |       |  JIRA links    |
    +-----------------+      +-----------------+      +-----------------+
           |                         |                         |
           v                         v                         v
    +-----------------+      +-----------------+      +-----------------+
    |  7. Fetch EPIC  |<-----|  8. List all   |<-----|  9. Search      |
    |  details       |       |  STORIES under |       |  related YANG   |
    |                |       |  EPIC          |       |  deviation files|
    +-----------------+      +-----------------+      +-----------------+
           |                         |                         |
           v                         v                         v
    +-----------------+      +-----------------+      +-----------------+
    |  10. Map YANG  |<-----|  11. Find YANG  |<-----|  12. Search     |
    |  changes to    |       |  and Validation|       |  validation     |
    |  XSLT logic   |       |  under EPIC   |       |  app changes    |
    +-----------------+      +-----------------+      +-----------------+
           |
           v
    +-----------------+
    |  13. Update     |
    |  Strategy_       |
    |  Learned.md      |
    +-----------------+

+=============================================================================+
```

### Example

```bash
# Analyze a specific XSLT file
python migration_learner.py --xslt "qos/lsr2212_to_lsr2303_qos_unsupported_list_1.xsl"
```

### Output

```
[ANALYZING SINGLE XSLT: qos/lsr2212_to_lsr2303_qos_unsupported_list_1.xsl]

Found JIRA tickets: ['BBN-96114']
Version: LSR2212 -> LSR2303

[STEP 2] Fetching JIRA: BBN-96114
  Type: Story
  Parent EPIC: BBN-88491

[STEP 3] Fetching Parent EPIC: BBN-88491
  Type: Epic

[STEP 4] Finding YANG deviation files
  Found 2 YANG files for BBN-96114
    - vobs/dsl/yang/deviations/qos-fiber/nokia-qos-filters-ext-qos-fiber-dev.yang

[STEP 5] Finding validation app changes
  Found 1 validation files for BBN-96114
    - ValidationRuleCategory.json
```

---

## Input Type 3: JIRA Ticket Number

### When to Use

When you have a specific JIRA ticket (EPIC, STORY, or BUG) to analyze.

### Workflow

```
+=============================================================================+
|                    JIRA TICKET ANALYSIS                                    |
+=============================================================================+

    +-----------------+      +-----------------+      +-----------------+
    |  1. Fetch JIRA |----->|  2. Determine  |----->|  3. If EPIC:    |
    |  ticket        |      |  ticket type:  |      |  get all STORIES|
    |  details       |      |  EPIC/STORY/BUG|      |  under it       |
    +-----------------+      +-----------------+      +-----------------+
           |                         |                         |
           v                         v                         v
    +-----------------+      +-----------------+      +-----------------+
    |  4. If STORY:   |<-----|  5. Get        |<-----|  6. For each   |
    |  find parent    |       |  STORIES/BUGs  |       |  STORY/BUG,     |
    |  EPIC          |       |  linked to     |       |  find related   |
    |               |       |  EPIC          |       |  XSLT files     |
    +-----------------+      +-----------------+      +-----------------+
           |                         |                         |
           v                         v                         v
    +-----------------+      +-----------------+      +-----------------+
    |  7. For each   |<-----|  8. Search for |------>|  9. Find YANG   |
    |  XSLT, analyze |       |  XSLT files    |       |  deviation      |
    |  the logic     |       |  containing    |       |  files          |
    |               |       |  JIRA key     |       |                 |
    +-----------------+      +-----------------+      +-----------------+
           |                         |                         |
           v                         v                         v
    +-----------------+      +-----------------+      +-----------------+
    |  10. Map YANG  |<-----|  11. Search    |<-----|  12. Get        |
    |  changes to    |       |  validation    |       |  Confluence    |
    |  XSLT logic    |       |  app code     |       |  docs          |
    +-----------------+      +-----------------+      +-----------------+
           |
           v
    +-----------------+
    |  13. Update     |
    |  Strategy_       |
    |  Learned.md      |
    +-----------------+

+=============================================================================+
```

### Example

```bash
# Analyze a specific JIRA ticket
python migration_learner.py --jira BBN-88491 --output learned_output/
```

### Output

```
[ANALYZING SINGLE JIRA: BBN-88491]

  Type: Epic
  Summary: Lightspan Yang deviations for not supported data

[STEP 2] Finding related JIRA tickets
  Linked issues (5):
    - BBN-96114 [Story]: QoS Modules - Unsupported leafs
    - BBN-122791 [Sub-task]: POLICING-PRE-HANDLING CONFIG ISSUE
    - BBN-133774 [Bug]: Duplicate elements in policing-action-profiles

[STEP 3] Searching Confluence documentation
  Searching Confluence: BBN-88491
  Found 2 Confluence links in JIRA
    - https://confluence.ext.net.nokia.com/pages/viewpage.action?pageId=12345

[STEP 4] Finding XSLT migration files
  Found 2 XSLT files:
    - qos/lsr2212_to_lsr2303_qos_unsupported_list_1.xsl
    - qos/lsr2212_to_lsr2303_qos_simplification_09_clean_cache_and_unused_nodes_1.xsl

[STEP 5] Finding YANG deviation files
  Found 3 YANG files:
    - nokia-qos-filters-ext-qos-fiber-dev.yang
    - nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang

[STEP 6] Finding validation app changes
  Found 1 validation files:
    - ValidationRuleCategory.json
```

---

## JIRA Ticket Hierarchy

Understanding JIRA structure is critical for tracing:

| Type | Description | Role in Migration |
|------|-------------|-------------------|
| **EPIC** | Complete feature requirement | Parent container for all related work |
| **STORY** | Individual feature implementation | Contains specific YANG/validation changes |
| **BUG** | Bug fix | May include migration for data fixes |
| **SUBTASK** | Work breakdown item | Often contains actual XSLT work |

### Finding Parent EPIC

For STORY/SUBTASK/BUG tickets:

1. **Check `customfield_12790`** - Often contains parent key
2. **Check `issuelinks`** - Look for inward/outward "Epic Link" relationship
3. **Check JIRA description** - May reference parent EPIC
4. **Check comments** - May contain EPIC references

### Key JIRA Custom Fields

| Field | Purpose |
|-------|---------|
| `customfield_12790` | Parent Epic Key |
| `customfield_37477` | Root Cause Analysis (RCA) |
| `customfield_37440` | Solution Description |

---

## Tools Integration

### jira-tool

```bash
JIRA_TOOL="/home/zhenac/fiber_code/sw/.cursor/skills/jira-tool/scripts/jira_tool.py"

# Fetch all details
python "$JIRA_TOOL" --id BBN-88491 --fetch-all

# Fetch specific fields
python "$JIRA_TOOL" --id BBN-88491 --fetch-fields

# Fetch comments
python "$JIRA_TOOL" --id BBN-88491 --fetch-comments
```

### confluence-tool

```bash
CONFLUENCE_TOOL="/home/zhenac/fiber_code/sw/.cursor/skills/confluence-tool/scripts/confluence_tool.py"

# Search for pages
python "$CONFLUENCE_TOOL" --search "QoS migration" --limit 10

# Fetch a specific page
python "$CONFLUENCE_TOOL" --fetch --url "https://confluence.ext.net.nokia.com/pages/viewpage.action?pageId=12345"
```

### Token Setup

```bash
# JIRA token (required)
echo "your-jira-token" > ~/.jira_token && chmod 600 ~/.jira_token

# Confluence token (required)
echo "your-confluence-token" > ~/.confluence_token && chmod 600 ~/.confluence_token
```

---

## YANG → XSLT Mapping Patterns

### Pattern Reference

| YANG Deviation | XSLT Action | Example |
|---------------|-------------|---------|
| `deviate not-supported` | Remove node | `<xsl:template match="..."/>` |
| `deviate add must "( . >= X)"` | Validate floor | Set minimum if too low |
| `deviate add must "( . <= Y)"` | Validate ceiling | Cap maximum if too high |
| `deviate add must "( . != 0)"` | Validate non-zero | Set default if zero |
| `deviate add mandatory` | Add default | Add leaf if missing |
| `deviate replace type` | Transform | Map old values to new |

### Search YANG Files

```bash
YANG_DEV_DIR="/home/zhenac/fiber_code/sw/vobs/dsl/yang/deviations"

# Find deviation files for a domain
find "$YANG_DEV_DIR" -name "*qos*dev*.yang"

# Search for specific deviation
grep -r "deviate add must" "$YANG_DEV_DIR/qos-fiber/"

# Find target YANG files
grep -r "nokia-bbf-qos-traffic-mngt" "$YANG_DEV_DIR/../"
```

### Search Validation App

```bash
VALIDATION_APP_DIR="/home/zhenac/fiber_code/sw/vobs/dsl/sw/y/build/apps/switch_validator_app"

# Search for constraint validation
grep -r "max-queue-size" "$VALIDATION_APP_DIR/"

# Search for specific validation rule
grep -r "BACKPLQ_RED" "$VALIDATION_APP_DIR/"
```

---

## Common XSLT Directories

```bash
XSLT_BASE_DIR="/home/zhenac/fiber_code/sw/vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl"

# Main XSLT location
ls "$XSLT_BASE_DIR/"

# QoS migrations
ls "$XSLT_BASE_DIR/qos/"

# Board-specific migrations
ls "$XSLT_BASE_DIR/merged/"

# QoS simplification (multi-step)
ls "$XSLT_BASE_DIR/qos/lsr2212_to_lsr2303_qos_simplification_"*
```

---

## Output Files

After running the analysis:

| File | Description |
|------|-------------|
| `{JIRA_KEY}/fields` | JIRA fields JSON |
| `{JIRA_KEY}/comments` | JIRA comments JSON |
| `jira_to_xslt_mapping.json` | Mapping of JIRA to XSLT files |
| `scan_summary_*.md` | Summary report |
| `confluence_search.txt` | Confluence search results |

---

## Next Steps

After running the analysis:

1. **Review JIRA data** - Check `{JIRA_KEY}/fields` for full details
2. **Analyze XSLT logic** - Understand what transformations are applied
3. **Cross-reference YANG** - Verify deviation statements match XSLT logic
4. **Check validation rules** - Understand runtime enforcement
5. **Update Strategy_Learned.md** - Document new patterns discovered

---

## Update Strategy_Learned.md

After analysis, update: `@migration-process-learning/Strategy_Learned.md`

### Sections to Update

1. **Documented EPICs** - Add complete EPIC analysis
2. **Pattern Categories** - Add new patterns discovered
3. **Documented Cases** - Add specific case mappings
4. **Epic Index** - Add to quick reference table

### Update Template

```markdown
## EPIC: [KEY] - [Title]

### Overview
- **Type**: Epic/Story/Bug
- **Fix Version**: e.g., LSR2303
- **Date**: Resolution date

### JIRA Hierarchy
```
EPIC/STORY/BUG relationships
```

### YANG Files Affected
- List deviation files with their changes

### XSLT Scripts
- List all XSLT files with their logic

### YANG → XSLT Mapping
| YANG | XSLT Action |
|------|-------------|
```

---

## Related Documents

- `@migration-process-learning/Strategy_Learned.md` - Documented migration patterns
- `@migration-xslt-generator/SKILL.md` - XSLT generation workflow
- `@jira-tool/SKILL.md` - JIRA integration
- `@confluence-tool/SKILL.md` - Confluence integration
