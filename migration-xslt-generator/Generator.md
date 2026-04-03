# Generator.md - XSLT Migration Workflow

This document defines the user interaction workflow for generating XSLT migration scripts.

---

## File Responsibilities

| File | Purpose |
|------|---------|
| **Generator.md** | User workflow, UI templates, interaction flow |
| **Strategy.md** | Input-to-XSLT transformation logic, classification rules, XSLT patterns |
| **Background.md** | Background knowledge: XSLT framework, version info, reference data |

---

## Input Modes

The tool supports three input modes:

| Mode | Description |
|------|-------------|
| **Mode 1 (Intent)** | User provides migration intent + optional sample XML |
| **Mode 2 (YANG)** | YANG files have been modified, need to generate migration XSLT |
| **Mode 3 (Validation)** | Validation app's C++ rules have been modified |

---

## Workflow Overview

```
+-----------------------------------------------------------------------------+
|                     Unified XSLT Generation Workflow                        |
+-----------------------------------------------------------------------------+
|                                                                             |
|  +--------------+     +--------------+     +--------------+                 |
|  |  1. Input    |---->|  2. Read      |---->|  3. Analyze  |                 |
|  |  (Intent or  |     |  YANG Schema  |     |  Changes     |                 |
|  |   YANG Diff) |     |              |     |              |                 |
|  +--------------+     +--------------+     +--------------+                 |
|         |                    |                    |                        |
|         +--------------------+--------------------+                       |
|                              |                                           |
|                              v                                           |
|                     +--------------+                                      |
|                     |  4. Decision |                                      |
|                     |  Generate?   |                                      |
|                     +--------------+                                      |
|                              |                                           |
|                    +---------+---------+                                 |
|                    v                       v                              |
|             +--------------+        +--------------+                     |
|             | Generate     |        | Show No-XSLT |                     |
|             | XSLT         |        | Reason       |                     |
|             +--------------+        +--------------+                     |
|                    |                                                    |
|                    v                                                    |
|  +-----------------------------------------------------------------------+  |
|  |                    5. User Feedback Loop                              |  |
|  +-----------------------------------------------------------------------+  |
|                              |                                           |
|                              v                                           |
|                     +--------------+                                      |
|                     |  6. Save to  |                                      |
|                     |  Domain Dir |                                      |
|                     +--------------+                                      |
|                              |                                           |
|                              v                                           |
|                     +--------------+                                      |
|                     |  7. Board    |                                      |
|                     |  Integration |                                      |
|                     +--------------+                                      |
|                                                                             |
+-----------------------------------------------------------------------------+
```

---

## Step 1: Input Collection

### Mode 1: Intent-Based Input

Display the intent input interface:

```
============================================================
  XSLT Migration - Intent Input
============================================================

Select input mode:
  [1] Intent-based - Describe what transformation is needed
  [2] YANG-based - YANG files have been modified

Enter your choice:
```

**Intent Examples:**

| Example | Intent Description |
|---------|-------------------|
| 1 | Delete the leaf node "vendor-id" under /devices/device/interfaces/interface |
| 2 | Rename leaf "olt-id" to "ont-id" under /services/vlan |
| 3 | If leaf "max-queue-size" value is greater than 9600, set it to 9600 |
| 4 | Add leaf "pbit-mode" with default value "all" if it doesn't exist under /qos/interface-config |
| 5 | For all interface nodes where "admin-status" equals "down", set "operational-mode" to "disabled" |

### Mode 2: YANG-Based Input

When user selects a YANG file from the diff view, capture:
- **Changeset number**: e.g., `599970`
- **Node hash**: e.g., `6af21798fe14`
- **YANG file path**: Full path in vobs
- **YANG file basename**: e.g., `nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang`
- **Diff content**: The actual changes (additions/deletions)

### Mode 3: Validation Rule-Based Input

Reference [ValidationAppMode_ChangeList.md](ValidationAppMode_ChangeList.md) for changeset selection.

**User Input Options:**

| Option | Description |
|--------|-------------|
| `1`, `2`, `3` | Select one changeset to view code diff |
| `1,2`, `2,3` | Select multiple changesets (comma-separated) |
| `4` | Manually input changeset(s) |
| Direct input | Enter changeset number directly (e.g., `535200`) |
| `A` | Select ALL shown changesets |
| `Q` | Quit and return to main menu |

**Input Format (from ValidationAppMode_CodeDiff.md) - Single Changeset:**
```
---
SELECTED: <filepath>
CHANGESET: <revision>
NODE: <node_hash>
TYPE: <cpp_rule|json_config>
```

**Input Format - Multiple Changesets:**
```
---
SELECTED: ALL
CHANGESET_COUNT: <count>
---
[1] CHANGESET: <revision_1>
    NODE: <node_hash_1>
    FILE: <filepath>
    TYPE: <cpp_rule|json_config>
---
[2] CHANGESET: <revision_2>
    NODE: <node_hash_2>
    FILE: <filepath>
    TYPE: <cpp_rule|json_config>
```

**Input Format - Direct Changeset Input:**
```
---
INPUT_MODE: DIRECT
CHANGESET: <user_entered_changeset>
STATUS: RESOLVING
```

**Input Sources:**
- C++ Rule Files: `*.cpp` (e.g., `VsiMaxMacCountCheckRule.cpp`)
- JSON Config Files: `TranslatorStrategyCategory.json`, `ValidationRuleCategory.json`

---

## Step 2A: Mode 3 - Map Code Diff to YANG Schema

When input comes from Validation App Code Diff (Mode 3), map the validation rules to corresponding YANG schemas.

### Translator Strategy → YANG Domain Mapping

Reference [Strategy.md](Strategy.md) for complete mapping rules.

| Translator Strategy | YANG Domain | Example YANG Paths |
|-------------------|-------------|-------------------|
| ForwarderStrategy | l2forwarding | /bbf-l2-fwd:forwarding/... |
| ForwardingDatabaseStrategy | l2forwarding | /bbf-l2-fwd:forwarding/forwarding-database |
| VlanSubInterfaceStrategy | l2forwarding | /bbf-l2-fwd:forwarding/vlan-sub-interfaces |
| FloodProfileStrategy | l2forwarding | /bbf-l2-fwd:forwarding/flood-profiles |
| QoSClassifierStrategy | qos | /bbf-qos-cls:classifiers/... |
| QoSPolicyStrategy | qos | /bbf-qos-pol:policies/... |
| QoSPoliceStrategy | qos | /bbf-qos-tm:tm-profiles/... |
| PonStrategy | pon | /bbf-pon-types:onus/... |
| ClockStrategy | clock | (domain-specific) |
| (Other) | infer from context | - |

### Code Diff → YANG Schema Mapping Output

```
============================================================
  Code Diff to YANG Schema Mapping
============================================================

Input Files:
  [1] VsiMaxMacCountCheckRule.cpp
  [2] TranslatorStrategyCategory.json

Mapping Results:

[1] VsiMaxMacCountCheckRule.cpp
    -> Translator Strategy: ForwarderStrategy, ForwardingDatabaseStrategy
    -> YANG Domain: l2forwarding
    -> Related YANG Files:
       - vobs/dsl/yang/IACM/BBF/L2FWD/bbf-l2-forwarding.yang
       - vobs/dsl/yang/deviations/l2forwarding/...-dev.yang

[2] TranslatorStrategyCategory.json
    -> Modified Strategy Mappings:
       - VsiMaxMacCountCheckRule -> ForwarderStrategy (new)
       - DualTagSharedFdbCheckRule -> ForwardingDatabaseStrategy (modified)
    -> Affected YANG Domains: l2forwarding

============================================================

Detected YANG Files to Process:
  [1] bbf-l2-forwarding.yang
  [2] nokia-bbf-l2-forwarding-l2forwarding-dev.yang

============================================================
```

---

## Step 2B: Read YANG Schema (Common for All Modes)

### YANG Search Locations

| Type | Location |
|------|----------|
| IACM YANG Files | `vobs/dsl/yang/IACM/` |
| Deviation YANG Files | `vobs/dsl/yang/deviations/` |
| Subdirectories | `qos-fiber/`, `pon/`, `l2-forwarding/`, etc. |

### Schema Reading Output Format

```
--------------------------------------------------------
  Reading YANG Schema
--------------------------------------------------------

Reading: vobs/dsl/yang/deviations/qos-fiber/nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang
Reading: vobs/dsl/yang/IACM/bbf-qos-tm.yang
Reading: vobs/dsl/yang/deviations/qos-fiber/nokia-bbf-qos-classifiers-qos-fiber-dev.yang

Schema loaded successfully.

Schema Context:
- Module: bbf-qos-tm (IACM)
- Deviation target: /tm-profiles/bac-entry/max-queue-size
- Related containers: tm-profiles, bac-entry, max-queue-size
```

---

## Step 3: Analyze Changes

Reference [Strategy.md](Strategy.md) for:
- Intent classification rules
- YANG change classification rules
- Intent parsing patterns
- XSLT pattern selection logic

---

## Step 4: Decision Matrix

Reference [Strategy.md](Strategy.md) for:
- When XSLT is required
- When XSLT is NOT required
- Transformation type classification

---

## Step 5: Generate XSLT

Reference [Strategy.md](Strategy.md) for:
- XSLT template structure
- Common XSLT patterns
- Intent-specific patterns
- Framework integration

---

## Step 6: User Feedback Loop

```
============================================================
  Generated XSLT
============================================================

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xxx="namespace">

    <xsl:strip-space elements="*"/>
    <xsl:output method="xml" indent="yes"/>

    <!-- Default identity transform -->
    <xsl:template match="*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <!-- [Generated template content here] -->

</xsl:stylesheet>

============================================================
  Feedback
============================================================

Please review the generated XSLT above.

Options:
  - Enter modification instructions (e.g., "add namespace declaration", "change match path")
  - Enter 'S', 'save', if satisfied with the generated XSLT (will save to file)

Enter your feedback:
```

### Feedback Processing

When user provides feedback:
1. Parse the feedback text
2. Apply modifications to the XSLT
3. Redisplay the modified XSLT
4. Repeat the feedback loop

### Common Feedback and Modifications

| User Input | Action |
|------------|--------|
| "add namespace xxx" | Add xmlns declaration to stylesheet |
| "change path to yyy" | Modify match path in template |
| "add condition" | Add predicate to match expression |
| "remove this template" | Delete the specified template |
| "change target value" | Modify value in template |
| "S" or "save" or "OK" | Proceed to save prompt |

---

## Step 7: Save XSLT to File + Board Integration

### Domain Guessing Logic

Reference [Background.md](Background.md) for domain mapping table.

### Save Prompt Template

```
============================================================
  Save XSLT File
============================================================

Suggested file location:
  Path: vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/{domain}/
  File: lsr{source}_to_lsr{target}_{domain}_{change_title}_{sequence}.xsl

Detected domain: {domain}
  Reason: {explanation based on namespace/match path}

Version mapping reference:
  26.3 → 2603, 26.6 → 2606, 26.9 → 2609, 26.12 → 2612

Do you want to save this XSLT file?

Options:
  [Y] Yes - Save to suggested location
  [V x y] Version - Specify versions (x=source, y=target, e.g., V 2603 2606)
  [N] No - Return without saving
  [C] Custom - Specify custom path/filename
  [D] Domain - Change domain (show available domains)

Enter your choice:
```

### Domain Selection Sub-menu

```
============================================================
  Select Domain
============================================================

Available domains:
  [1] qos        - QoS policies, classifiers, policing
  [2] l2fwd      - Layer 2 forwarding, bridge
  [3] nacm       - NETCONF Access Control
  [4] multicast  - IGMP/MLD, multicast routing
  [5] ipfix      - IPFIX cache configurations
  [6] cfm        - Connectivity Fault Management
  [7] erps       - ERPS ring protection
  [8] pon        - PON/ONT configurations
  [9] remove     - Remove unsupported nodes
  [10] merged    - Combined migration scripts
  [11] default   - Default migration scripts

Enter your choice (1-11) or 'b' to go back:
```

### Save File Flow

```
+-----------------------------------------------------------------+
|                    Save File Flow                                |
+-----------------------------------------------------------------+
|                                                                   |
|  +-------------+                                               |
|  | User chooses |                                               |
|  | to save     |                                               |
|  +------+------+                                               |
|         |                                                      |
|         v                                                      |
|  +-------------------------------------+                        |
|  | Ask: [Y] Save / [N] No / [C] Custom path                |   |
|  +-------------------------------------+                        |
|         |                                                      |
|    +----+----+-----------------------+                         |
|    v         v                       v                         |
| [Y]         [N]                      [C]                       |
|    |         |                        |                        |
|    v         v                        v                         |
| +---------+ +---------+ +-------------+                        |
| |Confirm &| |Return to| |Ask for path |                        |
| |Save     | |Options  | |& filename   |                        |
| +----+----+ +---------+ +------+------+                        |
|      |                          |                               |
|      v                          v                               |
| +--------------------------------------+                        |
| | Save file to: xsl/{domain}/filename.xsl |                    |
| +--------------------------------------+                        |
|                                                                   |
+-----------------------------------------------------------------+
```

---

### Board Integration Flow (Post-Save)

After saving the XSLT file successfully, prompt for board integration:

```
============================================================
  Board Integration
============================================================

XSLT file saved successfully:
  Path: vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/qos/
  File: lsr2603_to_lsr2606_qos_delete_pass_case_classifier_1.xsl

Version: 26.3 → 26.6

Would you like to integrate this XSLT into board-level merged files?

Available boards for lsr2603_to_lsr2606:
  [1] cfnt-b      [2] lllt-a      [3] cfnt-d      [4] cfxr-k
  [5] lmnt-a      [6] lmnt-b      [7] lmnt-c      [8] lmnt-d
  [9] lant-a      [10] lant-z     [11] all        [12] n

Options:
  - Enter board numbers (e.g., 1,2,3 or 1-5)
  - Enter 'all' to add to all boards
  - Enter 'n' to skip board integration

Enter your choice:
```

#### Board Integration Logic

1. **Scan merged directory** for boards matching the version:
   ```
   Pattern: lsr{source}_to_lsr{target}_migration_{boardName}.xsl
   Example: lsr2603_to_lsr2606_migration_*.xsl
   ```

2. **Display available boards** with count

3. **User selects boards** (comma-separated, range, or 'all')

4. **For each selected board**:
   - Read the merged xsl file
   - Check if the new XSLT filename is already included via `<xsl:include>`
   - If not included, add `<xsl:include href="filename.xsl"/>` in the appropriate location
   - Write back the updated merged xsl file

5. **Check migration.xml** for the board's migration entry:
   - Locate the `<migration>` block with matching `<source>` and `<target>`
   - Check if `<script subtree="merged">` entry exists for the board's merged xsl
   - If missing, add: `<script subtree="merged">lsr{source}_to_lsr{target}_migration_{board}.xsl</script>`

#### Board Integration Output

```
============================================================
  Board Integration Results
============================================================

Processing: lsr2603_to_lsr2606_qos_delete_pass_case_classifier_1.xsl

[1] cfnt-b
    - Merged file: lsr2603_to_lsr2606_migration_cfnt-b.xsl
    - Status: Updated (added include)
    - migration.xml: Already has merged entry

[2] lllt-a
    - Merged file: lsr2603_to_lsr2606_migration_lllt-a.xsl
    - Status: Updated (added include)
    - migration.xml: Already has merged entry

[3] cfnt-d
    - Merged file: lsr2603_to_lsr2606_migration_cfnt-d.xsl
    - Status: Already includes this XSLT
    - migration.xml: Already has merged entry

============================================================

Board integration completed.
```

---

## Return Options

After displaying the result (XSLT or reason), present:
- `[B]` - Back to previous view (YANG diff view for Mode 2, intent input for Mode 1, rule selection for Mode 3)
- `[Q]` - Quit and return to main menu

---

## Validation Checklist

Before finalizing XSLT, verify:

- [ ] Root template matches `/` and applies templates
- [ ] All namespace declarations present
- [ ] Framework imports included (if using framework utilities)
- [ ] XPath expressions are valid
- [ ] Logic handles all cases (empty, missing, multiple)
- [ ] File naming follows convention
- [ ] Output path is correct
- [ ] Board integration completed (if applicable)

---

## Error Handling

### Missing Input XML
If user skips sample XML:
1. Generate XSLT based on intent pattern (reference Strategy.md)
2. Add comments explaining the logic
3. Suggest user validates with real data

### Ambiguous Intent
If intent is unclear:
1. Ask clarifying questions
2. Provide examples matching the likely intent
3. Generate XSLT with comments for user to verify

### Complex Transformations
For complex intents that span multiple files or require extensive logic:
1. Break into smaller, composable XSLT
2. Create a merged XSLT that includes them all
3. Document the transformation flow

---

## Important Notes

1. **File Naming Format**: Always use `lsr{source}_to_lsr{target}_{domain}_{change_title}_{sequence}.xsl`
   - Reference Background.md for version mapping
   - Reference Strategy.md for pattern selection

2. **Strategy Reference**: For all classification and pattern logic, always reference [Strategy.md](Strategy.md)

3. **Background Reference**: For framework details, domain mapping, and reference data, always reference [Background.md](Background.md)

---

## Mode 3: Validation Rule-Based Workflow

### Overview

Mode 3 generates XSLT migration scripts based on validation rules from the switch_validator_app. When validation rules are modified, this mode maps them to YANG schemas and generates corresponding XSLT files.

**Key Difference from Mode 2:**
- Mode 2: Input is YANG diff directly
- Mode 3: Input is Code diff (C++ rules/JSON configs) → Map to YANG → Continue as Mode 2

### Input Sources

Mode 3 accepts multiple input formats:

| Input Source | Description |
|--------------|-------------|
| From ChangeList | User selects 1, 2, 3 or A from ValidationAppMode_ChangeList.md |
| Direct Input | User directly enters a changeset number |
| Multiple Changesets | User selects comma-separated options (e.g., `1,2,3`) |
| Manual Input (4) | User enters `4` and then inputs changeset(s) manually |

### Workflow

```
+-----------------------------------------------------------------------------+
|                  Mode 3: Validation Rule Workflow                            |
+-----------------------------------------------------------------------------+
|                                                                             |
|  +----------------+     +------------------+     +------------------+      |
|  | 1. Select     |---->| 2. Code Diff     |---->| 2A. Map          |      |
|  | Changeset(s)  |     | (Code changes)    |     | Code Diff → YANG |      |
|  +----------------+     +------------------+     +------------------+      |
|         |                       |                        |                 |
|         v                       v                        v                 |
|  +------------------+     +------------------+     +------------------+   |
|  | 2B. Read         |---->| 3. Analyze       |---->| 4. Decision      |   |
|  | YANG Schema      |     | Changes          |     | Generate?        |   |
|  +------------------+     +------------------+     +--------+---------+   |
|                                                            |                |
|                                           +----------------+----------------+
|                                           |                                 |
|                                           v                                 v|
|                                  +------------------+        +--------------+|
|                                  | Generate XSLT   |        | Show No-XSLT ||
|                                  |                 |        | Reason       ||
|                                  +------------------+        +--------------+|
|                                           |                                 |
|                                           v                                 |
|                                  +------------------+                       |
|                                  | 5. User         |                      |
|                                  | Feedback Loop   |                      |
|                                  +------------------+                       |
|                                           |                                 |
|                                           v                                 |
|                                  +------------------+                       |
|                                  | 6. Save to      |                      |
|                                  | Domain Dir      |                      |
|                                  +------------------+                       |
|                                           |                                 |
|                                           v                                 |
|                                  +------------------+                       |
|                                  | 7. Board        |                      |
|                                  | Integration     |                      |
|                                  +------------------+                       |
|                                                                             |
+-----------------------------------------------------------------------------+
```

### Step 1: Select Changesets

Reference [ValidationAppMode_ChangeList.md](ValidationAppMode_ChangeList.md) for the changeset selection interface.

**Supported Selections:**
- Single: `1`, `2`, or `3`
- Multiple: `1,2`, `2,3`, `1,2,3`
- All: `A`
- Manual: `4` (prompts for changeset input)
- Direct: Any changeset number (e.g., `535200`)

User selects one or more files from the diff viewer, or "A" for all.

### Step 2: Display Code Diff

Reference [ValidationAppMode_CodeDiff.md](ValidationAppMode_CodeDiff.md) for the code diff format.

**For multiple changesets:**
- Display each changeset sequentially
- Show summary of all files across changesets
- Allow selection of files from any changeset

### Step 2A: Map Code Diff to YANG Schema

Reference [Strategy.md](Strategy.md) for Translator Strategy → YANG Domain mapping.

**Mapping Process:**
1. Parse code diff to identify rule changes
2. Extract rule names from C++ files
3. Look up TranslatorStrategyCategory.json for strategy mappings
4. Map strategies to YANG domains
5. Find corresponding YANG files

**For multiple changesets:**
- Process each changeset separately
- Aggregate mapping results
- Deduplicate YANG files
- Generate combined XSLT if needed

### Step 2B: Read YANG Schema

Same as Mode 2 - read related YANG files based on mapped domains.

### Step 3: Analyze Changes

Same as Mode 2 - analyze YANG changes and determine XSLT requirements.

### Step 4: Decision

Same as Mode 2 - decision matrix for XSLT generation.

### Step 5: Generate XSLT

Reference [Strategy.md](Strategy.md) for XSLT pattern selection.

**For multiple changesets:**
- Generate XSLT for each changeset separately
- Or generate combined XSLT if changes are related
- Track source changeset for each template

### Step 6: Save XSLT

Save to the domain directory based on the mapped YANG domain:
- l2forwarding → `xsl/l2forwarding/`
- qos → `xsl/qos/`
- etc.

**For multiple changesets:**
- Offer to save as separate files
- Or save as combined/merged XSLT

### Step 7: Board Integration

After saving, prompt for board integration (same as Mode 1/2 Step 7).

---

## Related Documents

- [ChooseMode.md](ChooseMode.md) - Mode selection interface
- [ValidationAppMode_ChangeList.md](ValidationAppMode_ChangeList.md) - Mode 3 changeset selection
- [ValidationAppMode_CodeDiff.md](ValidationAppMode_CodeDiff.md) - Mode 3 code diff viewer
- [Strategy.md](Strategy.md) - XSLT patterns and transformation logic
- [Background.md](Background.md) - Framework reference and version info

