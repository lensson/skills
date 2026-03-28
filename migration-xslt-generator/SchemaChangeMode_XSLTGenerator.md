# Mode 2.5: XSLT Generation

This mode generates XSLT migration scripts based on YANG file changes, with full context from the YANG schema, user feedback loop, and file generation.

## Workflow

```
+-----------------------------------------------------------------------------+
|                     XSLT Generation Workflow                                |
+-----------------------------------------------------------------------------+
|                                                                             |
|  +--------------+     +--------------+     +--------------+                 |
|  |  1. Get      |---->|  2. Read      |---->|  3. Analyze  |                 |
|  |  YANG Diff   |     |  YANG Schema  |     |  YANG Changes |                 |
|  +--------------+     +--------------+     +--------------+                 |
|         |                    |                    |                        |
|         |                    |                    +------------------------+
|         |                    |                              |              |
|         |                    |                     +--------------+          |
|         |                    |                     |  4. Decision |          |
|         |                    |                     +--------------+          |
|         |                    |                              |              |
|         |            +-------+-------+                      |              |
|         |            |               |                      |              |
|         |            v               v                      v              |
|         |     +--------------+  +--------------+                           |
|         |     | Generate     |  | Show No-XSLT |                           |
|         |     | XSLT         |  | Reason       |                           |
|         |     +--------------+  +--------------+                           |
|         |            |                    |                                |
|         +------------+--------------------+                                |
|                          |                                                  |
|                          v                                                  |
|  +-----------------------------------------------------------------------+  |
|  |                    5. User Feedback Loop                              |  |
|  |  +-----------------+    +-----------------+    +-----------------+     |  |
|  |  | Show XSLT to   |---->| User Reviews & |---->| Modify XSLT     |     |  |
|  |  | User           |    | Provides Feedback|    | Based on Input |     |  |
|  |  +-----------------+    +-----------------+    +-----------------+     |  |
|  |         |                       |                      |              |  |
|  |         |                       |                      |              |  |
|  |         |           +-----------+-----------+          |              |  |
|  |         |           v                       v          |              |  |
|  |         |    +-------------+         +-------------+   |              |  |
|  |         |    | User says   |         | User says   |   |              |  |
|  |         |    | "N - OK"    |         | "Y - OK"    |   |              |  |
|  |         |    +------+------+         +------+------+   |              |  |
|  |         |           |                       |          |              |  |
|  |         |           v                       v          |              |  |
|  |         |    +------------------------+              |              |  |
|  |         |    | 6. Ask to Save File    |              |              |  |
|  |         |    +------------------------+              |              |  |
|  |         |                       |                     |              |  |
|  |         |           +-----------+-----------+        |              |  |
|  |         |           v                       v        |              |  |
|  |         |    +-------------+         +-------------+ |              |  |
|  |         |    | User says   |         | User says   | |              |  |
|  |         |    | "No"       |         | "Yes"      | |              |  |
|  |         |    +------+------+         +------+------+ |              |  |
|  |         |           |                       |        |              |  |
|  |         |           v                       v        v              |  |
|  |         |    +-------------+         +-------------+              |  |
|  |         |    | Return to   |         | Save XSLT   |              |  |
|  |         |    | Options     |         | to File     |              |  |
|  |         |    +-------------+         +-------------+              |  |
|  +---------+-------------------------------------------------------------+  |
|                          |                                                  |
|                          v                                                  |
|                   +--------------+                                          |
|                   |  7. Return   |                                          |
|                   |  to Options  |                                          |
|                   +--------------+                                          |
|                                                                             |
+-----------------------------------------------------------------------------+
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
| **Must Constraint** | `deviate add` with `must` constraint | **Yes** (to update invalid values) |
| **Mandatory Status** | `deviate add` with `mandatory true` | **Yes** (to add missing values) |
| **Must + Mandatory** | `deviate add` with both | **Yes** (combined handling) |
| **Optional Addition** | `deviate add` optional leaf | **No** |
| **Unique Constraint** | `deviate add` with `unique` | **No** |
| **Revision Only** | Add revision statement | **No** |
| **Constraint Removal** | `deviate delete` constraint | **No** |

### Critical Decision Rules

#### When `must` constraint is added:
```yang
deviation "/path/to/leaf" {
  deviate add {
    must "( . >= 9600)";
  }
}
```
-> **XSLT Required**: Existing values may not satisfy the new constraint. Generate XSLT to:
- Check if value satisfies the constraint
- If not, update to the minimum valid value (9600 in this example)

**Reference XSLT**: `xsl/qos/lsr2509_to_lsr2512_qos_update_bac_max_queue_size.xsl`

#### When `mandatory true` is added:
```yang
deviation "/path/to/leaf" {
  deviate add {
    mandatory true;
  }
}
```
-> **XSLT Required**: Existing configs may be missing this leaf. Generate XSLT to:
- Check if leaf exists in configs
- If missing, add with appropriate default value

#### Combined `must` + `mandatory`:
```yang
deviation "/path/to/leaf" {
  deviate add {
    must "( . >= 9600)";
    mandatory true;
  }
}
```
-> **XSLT Required**: Generate XSLT to handle both cases:
1. Add leaf if missing (with minimum valid value)
2. Update values that don't satisfy the `must` constraint

### Analysis Questions

1. **What type of deviation is it?**
   - `deviate add` with `must` -> **XSLT needed** to update invalid values
   - `deviate add` with `mandatory true` -> **XSLT needed** to add missing values
   - `deviate add` with `default` -> **XSLT needed** to add default values
   - `deviate replace` -> **XSLT needed** for data transformation
   - `deviate not-supported` -> **XSLT needed** to remove nodes
   - `deviate delete` -> No data migration needed

2. **Does it affect existing data?**
   - New optional nodes -> No migration needed
   - Removed nodes -> Need XSLT to remove from config
   - Type changes -> Need XSLT for conversion
   - New constraints -> Need XSLT to fix invalid/missing values

3. **Is it backward compatible?**
   - Adding optional elements -> Compatible
   - Adding mandatory elements -> **NOT compatible**, need XSLT
   - Adding `must` constraints -> **NOT compatible**, need XSLT to update values
   - Removing elements -> **NOT compatible**, need XSLT

## Step 4: Decision Matrix

```
                           +-------------------------------------+
                           |         YANG Deviation Type         |
                           +-------------------------------------+
                                          |
           +------------------------------+------------------------------+
           |                              |                              |
           v                              v                              v
    +-------------+               +-------------+               +-------------+
    | Data Transform |           | Must/Mandatory |           | Not-Supported |
    | (type change, |           | (constraint    |           | (node        |
    |  rename, etc) |           |  changes)      |           |  removal)    |
    +-------------+               +-------------+               +-------------+
           |                              |                              |
           v                              v                              v
    +-------------+               +-------------+               +-------------+
    | Generate    |               | Generate    |               | Generate    |
    | XSLT        |               | XSLT        |               | XSLT        |
    |             |               |             |               | (remove     |
    |             |               | - Add missing |              |  nodes)     |
    |             |               |   values     |               |             |
    |             |               | - Update     |               |             |
    |             |               |   invalid    |               |             |
    |             |               |   values    |               |             |
    +-------------+               +-------------+               +-------------+
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

**Pattern 7: Update Invalid Values (Must Constraint)**
```xml
<!-- Update values that don't satisfy must constraint -->
<xsl:template match="/cfg-ns:config/bbf-qos-tm:tm-profiles/bbf-qos-tm:bac-entry">
    <xsl:choose>
        <!-- If max-queue-size is missing or < 9600, set to 9600 -->
        <xsl:when test="not(bbf-qos-tm:max-queue-size) or number(bbf-qos-tm:max-queue-size) &lt; 9600">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:for-each select="node()">
                    <xsl:choose>
                        <xsl:when test="local-name() = 'max-queue-size'">
                            <xsl:element name="max-queue-size" namespace="urn:bbf:yang:bbf-qos-traffic-mngt">
                                <xsl:value-of select="9600"/>
                            </xsl:element>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:copy>
        </xsl:when>
        <xsl:otherwise>
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:apply-templates/>
            </xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
```

### Option B: No XSLT Needed

For changes that don't require data transformation:

| Change Type | Reason |
|-------------|--------|
| Optional leaf addition | No impact on existing configs |
| `unique` constraint | Schema validation only |
| Revision statement | Metadata change |
| Constraint removal | Removing restrictions |

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
| "N" or "no" or "OK" | Proceed to save prompt |

### When User is Satisfied

When user enters 'N', 'no', or 'OK', proceed to save prompt.

#### Domain Guessing Logic

Before suggesting the save location, analyze the XSLT to guess the appropriate domain:

**Step 1: Analyze XSLT Content**
- Check namespace declarations (e.g., `urn:bbf:yang:bbf-qos-*` -> `qos`)
- Check template match paths for domain hints
- Check file naming patterns in comments

**Step 2: Domain Mapping Table**

| Namespace Pattern | Match Path Pattern | Domain |
|------------------|-------------------|--------|
| `bbf-qos-*` | `tm-profiles`, `bac-entry`, `classifiers`, `policies` | `qos` |
| `bbf-l2-fwd:*` | `forwarding`, `bridge*` | `l2fwd` / `l2forwarding` |
| `bbf-dot1q:*` | `vlan*` | `vlan` |
| `nacm:*` | `nacm` | `nacm` |
| `bbf-mcast:*` | `multicast`, `igmp`, `mld` | `multicast` |
| `bbf-ipfix:*` | `ipfix`, `cache*` | `ipfix` |
| `bbf-cfm:*` | `cfm`, `mep`, `mah` | `cfm` |
| `bbf-erps:*` | `erps`, `ring*` | `erps` |
| `onu:*`, `gpon:*` | `onus`, `ont*`, `pon*` | `pon` |
| (not matched) | | infer from YANG file path |

**Step 3: Version Detection**
- Try to extract from comment header (e.g., `lsr2509_to_lsr2512`)
- Fall back to user input if unknown
- Use descriptive placeholder if completely unknown

#### Save Prompt Template

```
============================================================
  Save XSLT File
============================================================

Suggested file location:
  Path: vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/{guessed_domain}/
  File: lsr{from}_to_lsr{to}_{description}_{N}.xsl

Detected domain: {guessed_domain}
  Reason: {explanation based on namespace/match path}

Do you want to save this XSLT file?

Options:
  [Y] Yes - Save to suggested location
  [N] No - Return without saving
  [C] Custom - Specify custom path/filename
  [D] Domain - Change domain (show available domains)

Enter your choice:
```

#### Domain Selection Sub-menu

If user selects `[D]`:

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
|                                                                 |
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
|    v         v                        v                        |
| +---------+ +---------+ +-------------+                        |
| |Confirm &| |Return to| |Ask for path |                        |
| |Save     | |Options  | |& filename   |                        |
| +----+----+ +---------+ +------+------+                        |
|      |                          |                               |
|      v                          v                               |
| +--------------------------------------+                        |
| | Save file to: xsl/{domain}/filename.xsl |                    |
| |                                             |                |
| | [B] Back to diff view                      |                |
| | [Q] Quit                                   |                |
| +--------------------------------------+                        |
|                                                                 |
+-----------------------------------------------------------------+
```

## Full User Interface Examples

### Example 1: XSLT Required for Must + Mandatory Constraint

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
Reading: vobs/dsl/yang/IACM/BBF/ONU/bbf-qos-traffic-mngt-mounted.yang

Schema loaded successfully.

Schema Context:
- Module: bbf-qos-tm (IACM)
- Deviation target: /tm-profiles/bac-entry/max-queue-size
- Leaf type: uint32 (bytes)
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

Classification: Must Constraint + Mandatory Status

--------------------------------------------------------
  Step 3: Decision
--------------------------------------------------------

[XSLT Required]

Reason: This deviation adds both a 'must' constraint (values >= 9600)
and marks the leaf as mandatory. Existing configurations may:
1. Lack the max-queue-size value (must be added)
2. Have max-queue-size values < 9600 (must be updated)

XSLT is needed to migrate existing configurations to be valid
under the new schema.

============================================================
  Generated XSLT
============================================================

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:bbf-qos-tm="urn:bbf:yang:bbf-qos-traffic-mngt"
    xmlns:cfg-ns="urn:ietf:params:xml:ns:netconf:base:1.0">

    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>

    <!--
        YANG Migration: nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang
        Changeset: 599970
        Node: 6af21798fe14
        Change: Add mandatory constraint and must constraint for max-queue-size
    -->

    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/cfg-ns:config/bbf-qos-tm:tm-profiles/bbf-qos-tm:bac-entry">
        <xsl:choose>
            <xsl:when test="not(bbf-qos-tm:max-queue-size)">
                <!-- Add max-queue-size with default value 9600 -->
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:for-each select="node()">
                        <xsl:choose>
                            <xsl:when test="local-name() = 'bac-type' and not(preceding-sibling::bbf-qos-tm:max-queue-size)">
                                <xsl:element name="max-queue-size" namespace="urn:bbf:yang:bbf-qos-traffic-mngt">
                                    <xsl:value-of select="9600"/>
                                </xsl:element>
                                <xsl:copy-of select="."/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:copy-of select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="number(bbf-qos-tm:max-queue-size) &lt; 9600">
                <!-- Update invalid values to 9600 -->
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:for-each select="node()">
                        <xsl:choose>
                            <xsl:when test="local-name() = 'max-queue-size'">
                                <xsl:element name="max-queue-size" namespace="urn:bbf:yang:bbf-qos-traffic-mngt">
                                    <xsl:value-of select="9600"/>
                                </xsl:element>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:copy-of select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>

============================================================
  Feedback
============================================================

Please review the generated XSLT above.

Options:
  - Enter modification instructions
  - Enter 'N' or 'no' if satisfied with the generated XSLT

Enter your feedback: N

============================================================
  Save XSLT File
============================================================

Analyzing XSLT to detect domain...
  - Namespace: urn:bbf:yang:bbf-qos-traffic-mngt -> qos
  - Match path: /cfg-ns:config/bbf-qos-tm:tm-profiles/bbf-qos-tm:bac-entry
  - Match path contains: tm-profiles, bac-entry -> qos

Suggested file location:
  Path: vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/qos/
  File: lsr2406_to_lsr2409_update_bac_max_queue_size_1.xsl

Detected domain: qos
  Reason: Namespace matches bbf-qos-*, match path contains tm-profiles/bac-entry

Do you want to save this XSLT file?

Options:
  [Y] Yes - Save to suggested location
  [N] No - Return without saving
  [C] Custom - Specify custom path/filename
  [D] Domain - Change domain (show available domains)

Enter your choice:
```

### Example 2: XSLT Generated for Node Removal

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

[XSLT Required]

This deviation removes support for max-queue-size.
XSLT is needed to remove this node from existing
configurations during upgrade.

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

Enter your feedback: N

============================================================
  Save XSLT File
============================================================

Analyzing XSLT to detect domain...
  - Namespace: urn:bbf:yang:bbf-qos-tm -> qos
  - Match path: bbf-qos-tm:bac-entry/bbf-qos-tm:max-queue-size
  - Match path contains: bac-entry -> qos

Suggested file location:
  Path: vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/qos/
  File: lsr2603_to_lsr2606_remove_bac_entry_max_queue_size_1.xsl

Detected domain: qos
  Reason: Namespace matches bbf-qos-*, match path contains bac-entry

Do you want to save this XSLT file?

Options:
  [Y] Yes - Save to suggested location
  [N] No - Return without saving
  [C] Custom - Specify custom path/filename
  [D] Domain - Change domain (show available domains)

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

## Reference XSLT Examples

When generating XSLT for BAC entry `max-queue-size` constraint handling, refer to:

| File | Purpose |
|------|---------|
| `xsl/qos/lsr2509_to_lsr2512_qos_update_bac_max_queue_size.xsl` | Handle max-queue-size constraints (BACNAME_BACKPLQ_RED case) |
| `xsl/qos/lsr2203_to_lsr2206_update_bac_profile_1.xsl` | Handle max-queue-size value limits |

These demonstrate proper patterns for handling:
1. Missing values -> Add with default minimum value
2. Invalid values -> Update to minimum valid value

## Important Notes

1. **File Naming**: Always use the format `lsr{from}_to_lsr{to}_{description}_{N}.xsl`
   - If source/target versions are unknown, use descriptive placeholders
   - The suffix `_1`, `_2` indicates variant number for same changeset

2. **Namespace Declaration**: Always declare all namespaces used in match expressions

3. **Identity Transform**: Most XSLT files should include a default identity transform template

4. **Merged Scripts**: After creating domain-specific XSLT, remember to update merged migration scripts in `xsl/merged/` directory

5. **Comments**: Add descriptive comments explaining the migration purpose and any non-obvious logic

6. **Must + Mandatory**: When both constraints are added, handle both cases in a single XSLT template
