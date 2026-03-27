# Mode 2.5: XSLT Generation

This mode generates XSLT migration scripts based on YANG file changes, with full context from the YANG schema, user feedback loop, and file generation.

## Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     XSLT Generation Workflow                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐                 │
│  │  1. Get      │────▶│  2. Read      │────▶│  3. Analyze  │                 │
│  │  YANG Diff   │     │  YANG Schema  │     │  YANG Changes │                 │
│  └──────────────┘     └──────────────┘     └──────────────┘                 │
│         │                    │                    │                        │
│         │                    │                    ▼                        │
│         │                    │             ┌──────────────┐                 │
│         │                    │             │  4. Decision │                 │
│         │                    │             └──────────────┘                 │
│         │                    │                    │                        │
│         │            ┌───────┴───────┐            │                        │
│         │            ▼               ▼            ▼                        │
│         │     ┌──────────────┐  ┌──────────────┐                           │
│         │     │ Generate     │  │ Show No-XSLT │                           │
│         │     │ XSLT         │  │ Reason       │                           │
│         │     └──────────────┘  └──────────────┘                           │
│         │            │                    │                                │
│         └────────────┴────────────────────┘                                │
│                          │                                                  │
│                          ▼                                                  │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    5. User Feedback Loop                              │  │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │  │
│  │  │ Show XSLT to   │───▶│ User Reviews & │───▶│ Modify XSLT     │     │  │
│  │  │ User           │    │ Provides Feedback│    │ Based on Input │     │  │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘     │  │
│  │         │                       │                      │              │  │
│  │         │                       │                      │              │  │
│  │         │           ┌───────────┴───────────┐          │              │  │
│  │         │           ▼                       ▼          │              │  │
│  │         │    ┌─────────────┐         ┌─────────────┐   │              │  │
│  │         │    │ User says   │         │ User says   │   │              │  │
│  │         │    │ "N - OK"    │         │ "Y -满意"   │   │              │  │
│  │         │    └──────┬──────┘         └──────┬──────┘   │              │  │
│  │         │           │                       │          │              │  │
│  │         │           ▼                       ▼          │              │  │
│  │         │    ┌──────────────────────────────┐         │              │  │
│  │         │    │ 6. Ask to Save File          │         │              │  │
│  │         │    └──────────────────────────────┘         │              │  │
│  │         │                       │                     │              │  │
│  │         │           ┌───────────┴───────────┐          │              │  │
│  │         │           ▼                       ▼          │              │  │
│  │         │    ┌─────────────┐         ┌─────────────┐   │              │  │
│  │         │    │ User says   │         │ User says   │   │              │  │
│  │         │    │ "No"        │         │ "Yes"       │   │              │  │
│  │         │    └──────┬──────┘         └──────┬──────┘   │              │  │
│  │         │           │                       │          │              │  │
│  │         │           ▼                       ▼          │              │  │
│  │         │    ┌─────────────┐         ┌─────────────┐   │              │  │
│  │         │    │ Return to   │         │ Save XSLT   │───┘              │  │
│  │         │    │ Options     │         │ to File     │                  │  │
│  │         │    └─────────────┘         └─────────────┘                   │  │
│  └─────────┴──────────────────────────────────────────────────────────────┘  │
│                          │                                                  │
│                          ▼                                                  │
│                   ┌──────────────┐                                          │
│                   │  7. Return   │                                          │
│                   │  to Options  │                                          │
│                   └──────────────┘                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Step 1: Get YANG Diff

When user selects a YANG file from the diff view, capture:
- **Changeset number**: e.g., `599970`
- **Node hash**: e.g., `6af21798fe14`
- **YANG file path**: Full path in vobs
- **YANG file basename**: e.g., `nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang`
- **Diff content**: The actual changes (additions/deletions)

## Step 2: Read YANG Schema

Read the relevant YANG schema files to understand the context.

### YANG Search Locations

| Type | Location |
|------|----------|
| IACM YANG Files | `vobs/dsl/yang/IACM/` |
| Deviation YANG Files | `vobs/dsl/yang/deviations/` |
| Subdirectories | `qos-fiber/`, `pon/`, `l2-forwarding/`, etc. |

### Schema Files to Read

1. **Primary deviation file**: The file that was modified (from diff)
2. **Related IACM files**: Based on deviation path, find related IACM YANG files
   - Extract the target path from deviation (e.g., `/bbf-qos-tm:tm-profiles/...`)
   - Find the base YANG file for the namespace (e.g., `bbf-qos-tm.yang`)
3. **Related deviation files**: Other deviation files for the same module

### Example Search

For deviation:
```
deviation "/bbf-qos-tm:tm-profiles/bbf-qos-tm:bac-entry/bbf-qos-tm:max-queue-size"
```

Search for:
1. `vobs/dsl/yang/deviations/qos-fiber/nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang` (the changed file)
2. `vobs/dsl/yang/IACM/bbf-qos-tm.yang` (IACM file containing `tm-profiles` container)
3. Other `*qos-fiber-dev.yang` files in the same directory

### Output Format for Step 2

```
--------------------------------------------------------
  Step 1: Reading YANG Schema
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

## Step 3: Analyze YANG Changes

### Classification of YANG Changes

| Change Type | Example | XSLT Required |
|-------------|---------|---------------|
| **Data Transform** | `deviate replace` type, rename node | **Yes** |
| **Node Removal** | `deviate not-supported` | **Yes** (to remove nodes) |
| **Add Default** | `deviate add` with `default` value | **Yes** (to add defaults) |
| **Validation** | `deviate add` with `must` constraint | **No** |
| **Mandatory Status** | `deviate add` with `mandatory true` | **No** (manual action) |
| **Optional Addition** | `deviate add` optional leaf | **No** |
| **Revision Only** | Add revision statement | **No** |
| **Constraint Removal** | `deviate delete` constraint | **No** |

### Detailed Decision Rules

#### ✅ XSLT Needed: Data Transformation

```yang
// Example 1: Type change
deviation "/path/to/leaf" {
  deviate replace {
    type uint8;  // Changed from uint16
  }
}
// -> XSLT needed to convert values
```

```yang
// Example 2: Node renamed
deviation "/path/to/old-name" {
  deviate not-supported;
}
deviation "/path/to/new-name" {
  deviate add {
    // New node
  }
}
// -> XSLT needed to rename nodes
```

```yang
// Example 3: Default value added
deviation "/path/to/leaf" {
  deviate add {
    default "some-value";
  }
}
// -> XSLT needed to add default to existing configs
```

#### ❌ XSLT Not Needed: Schema Validation

```yang
// Example 1: Must constraint (validation only)
deviation "/path/to/leaf" {
  deviate add {
    must "( . >= 9600)";
  }
}
// -> No XSLT needed, enforced at load time
```

```yang
// Example 2: Mandatory status
deviation "/path/to/leaf" {
  deviate add {
    mandatory true;
  }
}
// -> No XSLT needed, manual data fix required
```

#### ✅ XSLT Needed: Node Removal

```yang
// Example: Node no longer supported
deviation "/path/to/unsupported-node" {
  deviate not-supported;
}
// -> XSLT needed to remove the node from configs
```

### Analysis Questions

1. **What type of deviation is it?**
   - `deviate add` with `must` → Schema validation only
   - `deviate add` with `default` → May need XSLT to add default values
   - `deviate replace` → Usually needs XSLT for data transformation
   - `deviate not-supported` → May need XSLT to remove nodes
   - `deviate delete` → Remove constraints, no data migration needed

2. **Does it affect existing data?**
   - New optional nodes → No migration needed
   - Removed nodes → Need XSLT to remove from config
   - Type changes → Need XSLT for conversion

3. **Is it backward compatible?**
   - Adding optional elements → Compatible
   - Adding mandatory elements → May need default value XSLT
   - Removing elements → Incompatible, needs XSLT

## Step 4: Decision Matrix

```
                           ┌─────────────────────────────────────┐
                           │         YANG Deviation Type         │
                           └─────────────────────────────────────┘
                                          │
           ┌──────────────────────────────┼──────────────────────────────┐
           │                              │                              │
           ▼                              ▼                              ▼
    ┌─────────────┐               ┌─────────────┐               ┌─────────────┐
    │ Data Transform │           │ Validation  │               │ Not-Supported │
    │ (type change, │           │ (must,      │               │ (node        │
    │  rename, etc) │           │  mandatory) │               │  removal)    │
    └─────────────┘               └─────────────┘               └─────────────┘
           │                              │                              │
           ▼                              ▼                              ▼
    ┌─────────────┐               ┌─────────────┐               ┌─────────────┐
    │ Generate    │               │ No XSLT     │               │ Generate    │
    │ XSLT        │               │ Needed      │               │ XSLT        │
    │             │               │             │               │ (remove     │
    │             │               │ Reason:     │               │  nodes)     │
    │             │               │ Schema      │               │             │
    │             │               │ validation  │               │             │
    │             │               │ enforced    │               │             │
    │             │               │ at load time │              │             │
    └─────────────┘               └─────────────┘               └─────────────┘
```

## Step 5: Output Formats

### Option A: Generate XSLT

#### XSLT File Location

XSLT files should be saved to:
```
vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/{domain}/
```

#### XSLT Naming Conventions

Based on existing files in the repository:

| Type | Format | Example |
|------|--------|---------|
| Generic (cross-board) | `lsr{from}_to_lsr{to}_{domain}_{N}.xsl` | `lsr2009_to_lsr2012_nacm_1.xsl` |
| Board-specific | `lsr{from}_to_lsr{to}_{name}_{board}.xsl` | `lsr2303_to_lsr2306_migration_cfnt-b.xsl` |
| Remove XSL | `lsr{from}_to_lsr{to}_remove_{description}_{N}.xsl` | `lsr2412_to_lsr2503_remove_unsupported_xpaths_1.xsl` |
| Feature-specific | `lsr{from}_to_lsr{to}_{feature}_{N}.xsl` | `lsr2303_to_lsr2306_qos_8888_01_construct_cache_1.xsl` |

**Note**: The `{from}` and `{to}` versions should match the upgrade path. If unknown, use a descriptive placeholder or ask the user.

#### XSLT Template Structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xxx="namespace-uri">

    <xsl:strip-space elements="*"/>
    <xsl:output method="xml" indent="yes"/>

    <!-- Default identity transform -->
    <xsl:template match="*">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <!-- Templates for specific transformations -->

</xsl:stylesheet>
```

#### Common XSLT Patterns

**Pattern 1: Remove Node (Empty Template)**
```xml
<!-- Remove unsupported node -->
<xsl:template match="namespace:unsupported-node"/>
```

**Pattern 2: Remove Node with Path**
```xml
<!-- Remove specific path -->
<xsl:template match="namespace:parent/namespace:child"/>
```

**Pattern 3: Conditional Remove**
```xml
<!-- Remove node based on condition -->
<xsl:template match="namespace:node[namespace:condition='value']"/>
```

**Pattern 4: Rename/Transform Node**
```xml
<!-- Rename node: match old, create new -->
<xsl:template match="old-name">
    <new-name>
        <xsl:apply-templates select="@* | node()"/>
    </new-name>
</xsl:template>
```

**Pattern 5: Add Default Value**
```xml
<!-- Add default value to container if missing -->
<xsl:template match="namespace:container">
    <xsl:copy>
        <xsl:apply-templates select="@* | node()"/>
        <xsl:if test="not(namespace:leaf)">
            <namespace:leaf>default-value</namespace:leaf>
        </xsl:if>
    </xsl:copy>
</xsl:template>
```

**Pattern 6: Type Conversion**
```xml
<!-- Convert value from old type to new type -->
<xsl:template match="namespace:leaf[@type='old']">
    <xsl:element name="{local-name()}">
        <xsl:attribute name="type">new</xsl:attribute>
        <xsl:value-of select="number(.) * conversion-factor"/>
    </xsl:element>
</xsl:template>
```

### Option B: No XSLT Needed

```markdown
============================================================
  XSLT Generation Analysis
============================================================

Changeset: {changeset_number}
Node: {node_hash}
YANG File: {yang_filename}

--------------------------------------------------------
  Schema Changes Summary
--------------------------------------------------------

{summary of changes from diff}

--------------------------------------------------------
  Analysis Result: No XSLT Required
--------------------------------------------------------

Reason: {detailed explanation}

Examples:
1. "This is a schema validation rule (must constraint) that
   is enforced at data load time. No data transformation
   is needed."

2. "This adds an optional leaf with no default value.
   Existing configurations will remain unchanged."

3. "This adds a mandatory constraint. Existing configurations
   that lack this field must be manually updated."

--------------------------------------------------------
  Recommendation
--------------------------------------------------------

{action items if any}

============================================================
```

## Step 6: User Feedback Loop

After generating XSLT, enter the user feedback loop.

### User Interface Template

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
  - Enter 'N' or 'no' if satisfied with the generated XSLT

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
| "N" or "no" or "满意" | Proceed to save prompt |

### When User is Satisfied

```
============================================================
  Save XSLT File
============================================================

Suggested file location:
  Path: vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/qos/
  File: lsr2603_to_lsr2606_bac_entry_1.xsl

Do you want to save this XSLT file?

Options:
  [Y] Yes - Save to suggested location
  [N] No - Return without saving
  [C] Custom - Specify custom path/filename

Enter your choice:
```

### Save File Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Save File Flow                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐                                               │
│  │ User chooses │                                               │
│  │ to save     │                                               │
│  └──────┬──────┘                                               │
│         │                                                      │
│         ▼                                                      │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Ask: [Y] Save / [N] No / [C] Custom path                │   │
│  └─────────────────────────────────────────────────────────┘   │
│         │                                                      │
│    ┌────┴────┬────────────────┐                               │
│    ▼         ▼                ▼                               │
│ [Y]         [N]               [C]                               │
│    │         │                │                                │
│    ▼         ▼                ▼                                │
│ ┌─────────┐ ┌─────────┐ ┌─────────────┐                        │
│ │Confirm &│ │Return to│ │Ask for path │                        │
│ │Save     │ │Options  │ │& filename   │                        │
│ └────┬────┘ └─────────┘ └──────┬──────┘                        │
│      │                          │                               │
│      ▼                          ▼                               │
│ ┌─────────────────────────────────────────┐                    │
│ │ Save file to: xsl/{domain}/filename.xsl │                    │
│ │                                             │                │
│ │ [B] Back to diff view                      │                │
│ │ [Q] Quit                                   │                │
│ └─────────────────────────────────────────┘                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Full User Interface Examples

### Example 1: No XSLT Needed

```
============================================================
  XSLT Generation
============================================================

Changeset: 599970
Node: 6af21798fe14
YANG File: nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang

--------------------------------------------------------
  Step 1: Reading YANG Schema
--------------------------------------------------------

Reading: vobs/dsl/yang/deviations/qos-fiber/nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang
Reading: vobs/dsl/yang/IACM/bbf-qos-tm.yang

Schema loaded successfully.

Schema Context:
- Module: bbf-qos-tm (IACM)
- Deviation target: /tm-profiles/bac-entry/max-queue-size
- Leaf type: uint32
- Related containers: tm-profiles, bac-entry

--------------------------------------------------------
  Step 2: Analyzing YANG Changes
--------------------------------------------------------

Detected deviation:
  - Target: /bbf-qos-tm:tm-profiles/bbf-qos-tm:bac-entry/bbf-qos-tm:max-queue-size
  - Action: deviate add
  - Changes:
    * Added 'must' constraint: ( . >= 9600)
    * Set 'mandatory' to true
    * Added revision: 2024-05-08

Classification: Schema Validation Rule

--------------------------------------------------------
  Step 3: Decision
--------------------------------------------------------

┌─────────────────────────────────────────────────────────┐
│  [XSLT Not Required]                                   │
│                                                         │
│  Reason: This deviation adds validation constraints    │
│  (must) and marks the leaf as mandatory. These are     │
│  schema-level rules enforced during data loading -     │
│  no data transformation XSLT is needed.                │
│                                                         │
│  Action Required: If existing configurations lack       │
│  max-queue-size values, they must be manually updated   │
│  to include values >= 9600.                             │
└─────────────────────────────────────────────────────────┘

============================================================

[B] Back to YANG diff view
[Q] Quit

Enter your choice:
```

### Example 2: XSLT Generated with Feedback Loop

```
============================================================
  XSLT Generation
============================================================

Changeset: 608888
Node: abc123def456
YANG File: nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang

--------------------------------------------------------
  Step 1: Reading YANG Schema
--------------------------------------------------------

Reading: vobs/dsl/yang/deviations/qos-fiber/nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang
Reading: vobs/dsl/yang/IACM/bbf-qos-tm.yang

Schema loaded successfully.

Schema Context:
- Module: bbf-qos-tm (IACM)
- Deviation target: /tm-profiles/bac-entry/max-queue-size
- Change: deviate not-supported (node removal)

--------------------------------------------------------
  Step 2: Analyzing YANG Changes
--------------------------------------------------------

Detected deviation:
  - Target: /bbf-qos-tm:tm-profiles/bbf-qos-tm:bac-entry/bbf-qos-tm:max-queue-size
  - Action: deviate not-supported

Classification: Node Removal

--------------------------------------------------------
  Step 3: Decision
--------------------------------------------------------

┌─────────────────────────────────────────────────────────┐
│  [XSLT Required]                                        │
│                                                         │
│  This deviation removes support for max-queue-size.     │
│  XSLT is needed to remove this node from existing       │
│  configurations during upgrade.                         │
└─────────────────────────────────────────────────────────┘

============================================================
  Generated XSLT
============================================================

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:bbf-qos-tm="urn:bbf:yang:bbf-qos-tm">

    <xsl:strip-space elements="*"/>
    <xsl:output method="xml" indent="yes"/>

    <!-- Identity transform -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Remove max-queue-size from bac-entry -->
    <xsl:template match="bbf-qos-tm:bac-entry/bbf-qos-tm:max-queue-size"/>

</xsl:stylesheet>

============================================================
  Feedback
============================================================

Please review the generated XSLT above.

Options:
  - Enter modification instructions
  - Enter 'N' or 'no' if satisfied with the generated XSLT

Enter your feedback: add description comment

============================================================
  Generated XSLT (Modified)
============================================================

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:bbf-qos-tm="urn:bbf:yang:bbf-qos-tm">

    <xsl:strip-space elements="*"/>
    <xsl:output method="xml" indent="yes"/>

    <!--
        YANG Migration: nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang
        Changeset: 608888
        Node: abc123def456
        Change: Remove max-queue-size from bac-entry (not-supported)
        Description: User requested - add description comment
    -->

    <!-- Identity transform -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- Remove max-queue-size from bac-entry -->
    <xsl:template match="bbf-qos-tm:bac-entry/bbf-qos-tm:max-queue-size"/>

</xsl:stylesheet>

============================================================
  Feedback
============================================================

Enter your feedback: N

============================================================
  Save XSLT File
============================================================

Suggested file location:
  Path: vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/qos/
  File: lsr2603_to_lsr2606_remove_bac_entry_max_queue_size_1.xsl

Do you want to save this XSLT file?

Options:
  [Y] Yes - Save to suggested location
  [N] No - Return without saving
  [C] Custom - Specify custom path/filename

Enter your choice: Y

============================================================
  File Saved Successfully
============================================================

File: vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/qos/
       lsr2603_to_lsr2606_remove_bac_entry_max_queue_size_1.xsl

Note: Remember to update the merged migration script to include this XSL.

============================================================

[B] Back to YANG diff view
[Q] Quit

Enter your choice:
```

## Return Options

After displaying the result (XSLT or reason), present:
- `[B]` - Back to YANG diff view (change list)
- `[Q]` - Quit and return to main menu

## Key Files to Reference

| File | Purpose |
|------|---------|
| `Background.md` | XSLT template structure, naming conventions, patterns, optimization guidelines |
| `dmsupgrader_app/overview.md` | System architecture overview |
| `dmsupgrader_app/workflow.md` | Detailed workflow guide |

## XSLT Domain Directories

Based on existing directory structure in `vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/`:

| Domain | Directory | Usage |
|--------|----------|-------|
| QoS | `qos/` | QoS policies, classifiers, policing |
| NACM | `nacm/` | Access control rules |
| IPFIX | `ipfix/` | IPFIX cache configurations |
| Multicast | `multicast/` | IGMP/MLD, multicast routing |
| L2 Forwarding | `l2forwarding/` / `l2fwd/` | Bridge, forwarding |
| ERPS | `erps/` | ERPS ring protection |
| CFM | `cfm/` | Connectivity Fault Management |
| Remove | `remove/` | Remove unsupported nodes |
| Merged | `merged/` | Combined migration scripts |
| Default | `default/` | Default migration scripts |

## Important Notes

1. **File Naming**: Always use the format `lsr{from}_to_lsr{to}_{description}_{N}.xsl`
   - If source/target versions are unknown, use descriptive placeholders
   - The suffix `_1`, `_2` indicates variant number for same changeset

2. **Namespace Declaration**: Always declare all namespaces used in match expressions

3. **Identity Transform**: Most XSLT files should include a default identity transform template

4. **Merged Scripts**: After creating domain-specific XSLT, remember to update merged migration scripts in `xsl/merged/` directory

5. **Comments**: Add descriptive comments explaining the migration purpose and any non-obvious logic
