---
name: Strategy Learned
description: Documented migration patterns and learnings from historical XSLT commits. Use as reference when generating new XSLT migrations.
---

# Strategy Learned

Documented migration patterns and learnings from analyzing historical XSLT commits.

---

## Pattern Categories

### 1. Constraint Validation Pattern

**YANG Change:**
- `deviate add must "( . >= X)"`
- `deviate add must "( . <= Y)"`
- `deviate add must "( . >= X and . <= Y)"`

**Scenario:**
- New constraint added to YANG model
- Existing configurations may have invalid values
- Need to update values to satisfy constraint

**XSLT Logic:**
```xml
<xsl:template match="target-path">
    <xsl:choose>
        <xsl:when test="not(target-leaf) or number(target-leaf) &lt; MIN_VALUE">
            <xsl:element name="target-leaf">
                <xsl:value-of select="MIN_VALUE"/>
            </xsl:element>
        </xsl:when>
        <xsl:when test="number(target-leaf) &gt; MAX_VALUE">
            <xsl:element name="target-leaf">
                <xsl:value-of select="MAX_VALUE"/>
            </xsl:element>
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

**Decision Rule:**
- If `deviate add must constraint` with comparison operators
- AND existing configs could have out-of-range values
- THEN XSLT Required: validate and update

---

### 2. Mandatory Field Pattern

**YANG Change:**
- `deviate add mandatory`
- New leaf marked as mandatory

**Scenario:**
- New mandatory field added to model
- Existing configurations missing this field
- Need to add default value

**XSLT Logic:**
```xml
<xsl:template match="parent-container">
    <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:apply-templates/>
        <xsl:if test="not(mandatory-leaf)">
            <xsl:element name="mandatory-leaf">
                <xsl:value-of select="DEFAULT_VALUE"/>
            </xsl:element>
        </xsl:if>
    </xsl:copy>
</xsl:template>
```

**Decision Rule:**
- If `mandatory true` added to YANG
- AND no default value provided in YANG
- THEN XSLT Required: add default

---

### 3. Node Removal Pattern

**YANG Change:**
- `deviate not-supported`
- Entire subtree or leaf removed

**Scenario:**
- Feature no longer supported
- Need to remove configuration

**XSLT Logic:**
```xml
<!-- Empty template = implicit deletion -->
<xsl:template match="unsupported-path"/>
```

**Decision Rule:**
- If `deviate not-supported` in YANG
- THEN XSLT Required: remove node
- Pattern: Empty template (don't copy)

---

### 4. Value Normalization Pattern

**YANG Change:**
- Unsupported values need to be normalized
- Some values no longer valid, need transformation

**Scenario:**
- Specific values are no longer supported
- Need to transform to valid default

**XSLT Logic:**
```xml
<xsl:template match="node[unsupported-condition]">
    <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:value-of select="'normalized-value'"/>
    </xsl:copy>
</xsl:template>
```

**Examples:**
- `dscp-range != 'any'` → `'any'`
- `protocol != 'igmp'` → `'igmp'`

**Decision Rule:**
- If specific values are no longer valid
- THEN XSLT Required: transform to default valid value

---

### 5. Type Conversion Pattern

**YANG Change:**
- `deviate replace` type
- Type changed (e.g., string to enumeration)

**Scenario:**
- Type semantics changed
- Need to transform values

**XSLT Logic:**
```xml
<xsl:template match="type-changed-leaf">
    <xsl:choose>
        <xsl:when test=". = 'OLD_VALUE_1'">
            <xsl:element name="type-changed-leaf">
                <xsl:value-of select="'NEW_VALUE_1'"/>
            </xsl:element>
        </xsl:when>
        <xsl:otherwise>
            <xsl:element name="type-changed-leaf">
                <xsl:value-of select="'DEFAULT'"/>
            </xsl:element>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
```

**Decision Rule:**
- If `deviate replace type` in YANG
- THEN XSLT Required: map old values to new type

---

### 6. Classifier Type Computation Pattern

**YANG Change:**
- Add computed `classifier-type` field
- Add computed `policy-type` field

**Scenario:**
- New metadata fields added for classification
- Need to compute based on existing structure

**XSLT Logic:**
```xml
<xsl:template name="getFirstValidClassifierType">
    <xsl:param name="curPolicySec"/>
    <xsl:for-each select="$curPolicySec/classifiers/classifier">
        <xsl:variable name="type" select="classifier-type[1]"/>
        <xsl:if test="$type != 'CLS_TYPE_INVALID'">
            <xsl:value-of select="$type"/>
        </xsl:if>
    </xsl:for-each>
</xsl:template>
```

**Decision Rule:**
- If computed fields added to YANG
- THEN XSLT Required: calculate and populate

---

### 7. Policy Cache Construction Pattern

**YANG Change:**
- Add migration cache structure
- Need to pre-compute data for later stages

**Scenario:**
- Complex policy structure
- Need to extract and store for reference

**XSLT Logic:**
```xml
<xsl:template match="policy[name='...']">
    <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:apply-templates/>
        <xsl:element name="policy-migration-cache">
            <xsl:element name="name">
                <xsl:value-of select="name"/>
            </xsl:element>
            <xsl:element name="classifiers">
                <!-- Extract classifier info -->
            </xsl:element>
        </xsl:element>
    </xsl:copy>
</xsl:template>
```

**Decision Rule:**
- If migration-cache structure added
- THEN XSLT Required: construct cache from existing data

---

### 8. Queue Color Pattern

**YANG Change:**
- Add new `queue-color` field
- Add new `policy-type` for queue coloring

**Scenario:**
- New QoS feature for coloring queues
- Need to set defaults or transform

**XSLT Logic:**
```xml
<xsl:template match="policy[policer-profile='BACKPLQ_RED']">
    <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:apply-templates/>
        <xsl:element name="queue-color">
            <xsl:value-of select="'RED'"/>
        </xsl:element>
    </xsl:copy>
</xsl:template>
```

**Decision Rule:**
- If new coloring fields added
- AND specific profiles/conditions exist
- THEN XSLT Required: set appropriate values

---

### 9. Conditional Node Cleanup Pattern

**YANG Change:**
- Conditional cleanup required based on data state

**Scenario:**
- Invalid data combinations exist
- Need to clean up while preserving valid data

**XSLT Logic:**
```xml
<xsl:template match="container[count(child) > 1]">
    <xsl:copy>
        <xsl:copy-of select="@*"/>
        <!-- Keep only valid child (e.g., second tag) -->
    </xsl:copy>
</xsl:template>
```

**Decision Rule:**
- If invalid data combinations exist
- THEN XSLT Required: conditional cleanup

---

### 10. Duplicate Removal Pattern

**YANG Change:**
- Duplicate elements not allowed

**Scenario:**
- Config has duplicate entries
- Need to remove duplicates

**XSLT Logic:**
```xml
<xsl:template match="container">
    <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:for-each select="child[not(preceding-sibling::*[local-name() = name(current())])]">
            <xsl:copy-of select="."/>
        </xsl:for-each>
    </xsl:copy>
</xsl:template>
```

**Decision Rule:**
- If duplicates exist in config
- THEN XSLT Required: deduplicate

---

## YANG Deviation → XSLT Mapping

| Deviation Statement | XSLT Action | Notes |
|--------------------|------------|-------|
| `deviate not-supported` | Remove node | Empty template |
| `deviate add must "..."` | Validate & update | Check and fix |
| `deviate add mandatory` | Add default | If not present |
| `deviate replace type` | Transform | Map values |
| `deviate add default` | Usually not needed | YANG handles it |

---

## Validation → XSLT Mapping

| Layer | Action | Example |
|-------|--------|---------|
| YANG | Define constraint | `must "( . >= 9600)"` |
| Validation App | Check at commit | Return error if violated |
| XSLT | Migrate existing | Update values to satisfy |

**Example:**
```cpp
// Validation app (C++)
if (bacEntry.maxQueueSize < MIN_QUEUE_SIZE) {
    return VALIDATION_ERROR;
}
```

```xml
<!-- XSLT -->
<xsl:when test="$maxQueueSize &lt; MIN_QUEUE_SIZE">
    <xsl:element name="max-queue-size">
        <xsl:value-of select="MIN_QUEUE_SIZE"/>
    </xsl:element>
</xsl:when>
```

---

## Epic/Story Patterns

### QoS Feature Epic

Under QoS-related epics, typically find:

1. **YANG deviation files** - New constraints, types
2. **Validation app changes** - Constraint validators
3. **XSLT migrations** - Update existing configs
4. **Confluence docs** - Feature specification

### Common Epic Keywords

| Keyword | Likely Pattern |
|---------|---------------|
| `max-queue-size` | Constraint validation |
| `bac-entry` | BAC profile migration |
| `classifier` | Classifier type computation |
| `pbit` | Bit marking logic |
| `policing` | Policer profile changes |
| `unsupported` | Node removal |
| `not-supported` | Node removal |

---

## Documented Cases

### Case 1: QoS Unsupported Leafs Removal (BBN-96114)

| Field | Value |
|-------|-------|
| **EPIC** | BBN-88491 - Lightspan Yang deviations for not supported data |
| **XSLT** | `qos/lsr2212_to_lsr2303_qos_unsupported_list_1.xsl` |
| **JIRA** | BBN-96114 (STORY) |
| **Fix Version** | LSR2303 |
| **Pattern** | Node Removal + Value Normalization |

**YANG Changes:**
- `other-protocol` leaf marked as not-supported
- `filter` under classifier marked as not-supported
- `dscp-marking-cfg` under classifier marked as not-supported
- `hierarchical-policing` marked as not-supported
- `pre-emption` in queues marked as not-supported
- `dscp-range != 'any'` → `'any'`
- `protocol != 'igmp'` → `'igmp'`

**XSLT Logic:**
```xml
<!-- Node Removal -->
<xsl:template match="*[local-name() = 'other-protocol' ...]">
</xsl:template>

<!-- Value Normalization -->
<xsl:template match="*[local-name() = 'dscp-range' and normalize-space(text()) != 'any']">
    <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:value-of select="'any'"/>
    </xsl:copy>
</xsl:template>
```

---

### Case 2: BAC Max Queue Size Floor

| Field | Value |
|-------|-------|
| **XSLT** | `qos/lsr2509_to_lsr2512_qos_update_bac_max_queue_size.xsl` |
| **YANG** | `nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang` |
| **Constraint** | `must "( . >= 9600)"` |
| **Pattern** | Constraint Validation (Floor) |
| **Condition** | Only for `BACNAME_BACKPLQ_RED` profile |

**XSLT Logic:**
1. Match `bac-entry` with name `BACKPLQ_RED`
2. Check if `max-queue-size > 41943040`
3. Cap to 41943040 if exceeded
4. Otherwise pass through

---

### Case 3: BAC Max Buffer Size Cap

| Field | Value |
|-------|-------|
| **XSLT** | `qos/lsr2203_to_lsr2206_update_bac_profile_1.xsl` |
| **YANG** | `nokia-bbf-qos-traffic-mngt-bac-profile-dev.yang` |
| **Constraint** | Cap at 4000000000 |
| **Pattern** | Constraint Validation (Ceiling) |

**XSLT Logic:**
```xml
<xsl:choose>
    <xsl:when test="current()/text() > 4000000000">
        <xsl:call-template name="max_buffersize_replace"/>
    </xsl:when>
    <xsl:otherwise>
        <xsl:copy>...</xsl:copy>
    </xsl:otherwise>
</xsl:choose>
```

---

### Case 4: QoS Simplification Policy Type

| Field | Value |
|-------|-------|
| **XSLT** | `qos/lsr2212_to_lsr2303_qos_simplification_05_calculate_policy_type_1.xsl` |
| **YANG** | `nokia-bbf-qos-policies-dev.yang` |
| **Change** | Add computed `policy-type` field |
| **Pattern** | Classifier Type Computation |

**XSLT Logic:**
1. Analyze classifier entries
2. Determine first valid classifier type
3. Map classifier type to policy type
4. Add `policy-type` and `sequence` fields

---

### Case 5: QoS Policy Cache Construction

| Field | Value |
|-------|-------|
| **XSLT** | `qos/lsr2303_to_lsr2306_qos_8888_01_construct_cache_1.xsl` |
| **YANG** | `nokia-bbf-qos-policies.yang` |
| **Change** | Add `policy-migration-cache` structure |
| **Pattern** | Policy Cache Construction |

**XSLT Logic:**
1. For each policy, create `policy-migration-cache`
2. Extract classifier name references
3. Look up enhanced filter details
4. Compute pbit info from various sources
5. Determine validity based on conditions

---

### Case 6: Unsupported Node Removal (Generic)

| Field | Value |
|-------|-------|
| **XSLT** | `remove/lsr2412_to_lsr2503_remove_unsupported_xpaths_1.xsl` |
| **Pattern** | Node Removal |

**XSLT Logic:**
1. Identify unsupported XPath patterns
2. Use empty templates to remove
3. Or modify parent to not apply-templates

---

### Case 7: Policer Dual VLAN Cleanup

| Field | Value |
|-------|-------|
| **EPIC** | BBN-88491 |
| **XSLT** | `qos/lsr2212_to_lsr2303_qos_simplification_09_clean_cache_and_unused_nodes_1.xsl` |
| **JIRA** | BBN-122791 |
| **Pattern** | Conditional Node Cleanup |

**XSLT Logic:**
```xml
<!-- When dual vlan tags exist, keep only the second one -->
<xsl:when test="count(tag) &gt; 1">
    <!-- Keep only second tag logic -->
</xsl:when>
```

---

### Case 8: Duplicate Policer Action Profiles

| Field | Value |
|-------|-------|
| **EPIC** | BBN-88491 |
| **XSLT** | `qos/lsr2212_to_lsr2303_qos_simplification_09_clean_cache_and_unused_nodes_1.xsl` |
| **JIRA** | BBN-133774 (BUG) |
| **Pattern** | Duplicate Removal |

**Issue:** Duplicate elements in node for `policing-action-profiles`

---

## Epic Index

| EPIC Key | Title | Stories | XSLTs | Date |
|----------|-------|---------|-------|------|
| BBN-88491 | Lightspan Yang deviations for not supported data | BBN-96114, BBN-122791, BBN-133774 | 2 | 2023-01 |

---

---

## Documented EPICs

---

## EPIC: BBN-88491 - Lightspan Yang deviations for not supported data

### Overview
| Field | Value |
|-------|-------|
| **Type** | Epic |
| **Summary** | Lightspan Yang deviations for not supported data |
| **Fix Version** | LSR2303 |
| **Resolution Date** | 2023-01-02 |
| **Description** | Remove unsupported YANG attributes from documentation and hello message |
| **Approval** | Approved for Fiber R&D and SDAN R&D (2022-11-15) |

### JIRA Hierarchy

```
EPIC: BBN-88491 - Lightspan Yang deviations for not supported data
│
├── STORY: BBN-96114 - QoS Modules - Unsupported leafs
│   ├── Type: Story
│   ├── Fix Version: LSR2303
│   ├── XSLT: lsr2212_to_lsr2303_qos_unsupported_list_1.xsl
│   └── Subtask: BBN-121172 - Qos Modules - Unsupported leafs task
│
├── SUBTASK: BBN-122791 - POLICING-PRE-HANDLING CONFIG ISSUE
│   ├── Type: Sub-task
│   ├── Fix Version: LSR2303
│   ├── XSLT: lsr2212_to_lsr2303_qos_simplification_09_clean_cache_and_unused_nodes_1.xsl
│   └── Issue: Dual vlan tags in pre-handling profile
│
├── BUG: BBN-133774 - Duplicate elements in policing-action-profiles
│   ├── Type: Bug
│   ├── XSLT: lsr2212_to_lsr2303_qos_simplification_09_clean_cache_and_unused_nodes_1.xsl
│   └── Issue: Migration data store failed with duplicate elements
│
└── Linked Epics:
    └── BBN-140017 - Lightspan Yang Deviations for not supported data - Shelf NE
```

### Board Support Requirements

This EPIC covers the following boards:
| Board | Category |
|-------|----------|
| CFNT-B, CFNT-D | N/A |
| DFMB-A, DFMB-B, DFMB-C | N/A |
| FELT-B/downlink, FELT-B/uplink | N/A |
| FGLT-B, FGLT-D, FGLT-E | N/A |
| FGUT-A | N/A |
| FWLT-B, FWLT-C | N/A |
| LGLT-D, LGLT-E | N/A |
| LWLT-C | N/A |
| SFDB-A | N/A |

### YANG Deviation Files Affected

#### 1. nokia-qos-filters-ext-qos-fiber-dev.yang

**Revision History:**
- `2025-02-01`: [BBN-9324 LLLT-A] - Clear obsolete classify types
- `2022-11-29`: Removed nodes of other-protocol and augment dependency

**Deviations:**
```yang
// Other-protocol not supported
deviation "/bbf-qos-cls:classifiers/bbf-qos-cls:classifier-entry/.../nokia-qos-filt:other-protocol" {
    deviate not-supported;
}

// IP headers not supported
deviation "/bbf-qos-filt:filters/bbf-qos-filt:filter/bbf-qos-filt:filter-field/nokia-qos-filt:ip4-header" {
    deviate not-supported;
}
deviation "/bbf-qos-filt:filters/bbf-qos-filt:filter/bbf-qos-filt:filter-field/nokia-qos-filt:ip6-header" {
    deviate not-supported;
}

// Unmetered not supported
deviation ".../nokia-qos-filt:unmetered" {
    deviate not-supported;
}
```

#### 2. nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang

**Revision History:**
- `2024-05-08`: Add deviation to check max-queue-size in bac entry
- `2023-08-15`: Remove deviation to support 4Q mode
- `2022-11-29`: Pre-emption of tm queue is not supported

**Deviations:**
```yang
// BAC max-queue-size constraint (MUST >= 9600, MANDATORY)
deviation "/bbf-qos-tm:tm-profiles/bbf-qos-tm:bac-entry/bbf-qos-tm:max-queue-size" {
    deviate add {
       must "( . >= 9600)" {
         error-message "Bac max-queue-size should be explicitly specified, and its value must be no less than 9600.";
       }
      mandatory true;
    }
}

// Queue pre-emption not supported
deviation "/if:interfaces/.../bbf-qos-tm:pre-emption" {
    deviate not-supported;
}

// Min threshold must < Max threshold
deviation ".../min-threshold" {
    deviate add {
       must " . < ../bbf-qos-tm:max-threshold "
    }
}

// Max threshold cannot be zero
deviation ".../max-threshold" {
    deviate add {
       must "( . != 0)"
    }
}
```

#### 3. Other QoS Deviation Files

| File | Pattern | Impact |
|------|---------|--------|
| `nokia-bbf-qos-policing-qos-fiber-dev.yang` | deviate not-supported | Policer params |
| `nokia-bbf-qos-classifiers-qos-fiber-dev.yang` | deviate not-supported | Classifier entries |
| `nokia-bbf-qos-enhanced-filters-qos-fiber-dev.yang` | deviate not-supported | Enhanced filters |
| `nokia-bbf-qos-policies-qos-fiber-dev.yang` | deviate not-supported | Policy profiles |

### XSLT Migration Scripts

#### Group A: QoS Unsupported List (lsr2212_to_lsr2303)

| XSLT File | Purpose | Pattern |
|-----------|---------|---------|
| `lsr2212_to_lsr2303_qos_unsupported_list_1.xsl` | Remove unsupported nodes | Node Removal |

**Key Logic:**
```xml
<!-- Remove unsupported nodes via empty template -->
<xsl:template match="*[local-name() = 'other-protocol' ...]">
</xsl:template>

<!-- Transform invalid values to valid defaults -->
<xsl:template match="*[local-name() = 'dscp-range' and normalize-space(text()) != 'any']">
    <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:value-of select="'any'"/>
    </xsl:copy>
</xsl:template>
```

#### Group B: QoS Simplification (lsr2212_to_lsr2303)

18-step migration for QoS simplification:

| Step | File | Purpose |
|------|------|---------|
| 01 | `qos_simplification_01_construct_cache_1.xsl` | Build policy/classifier cache |
| 02 | `qos_simplification_02_set_enhanced_filter_1.xsl` | Set enhanced filter types |
| 03 | `qos_simplification_03_construct_classifiers_1.xsl` | Construct classifiers |
| 04 | `qos_simplification_04_calculate_classifier_type_1.xsl` | Calculate classifier type |
| 05 | `qos_simplification_05_calculate_policy_type_1.xsl` | Calculate policy type |
| 06 | `qos_simplification_06_resorting_policy_sequence_1.xsl` | Resort policy sequence |
| 07 | `qos_simplification_07_construct_new_section_1.xsl` | Build new section structure |
| 08 | `qos_simplification_08_copy_cache_1.xsl` | Copy cache data |
| 09 | `qos_simplification_09_clean_cache_and_unused_nodes_1.xsl` | **Clean duplicates & unused** |
| 10-17 | `*_insert_*.xsl` | Insert reference names |
| 18 | `qos_simplification_18_dimension_checking_1.xsl` | Final dimension check |

#### Group C: BAC Max Queue Size (lsr2509_to_lsr2512)

| XSLT File | Purpose | Constraint |
|-----------|---------|------------|
| `lsr2509_to_lsr2512_qos_update_bac_max_queue_size.xsl` | Update BAC queue size | `max-queue-size >= 9600` |

**Special Logic for BACKPLQ_RED:**
```xml
<!-- Cap max-queue-size to 41943040 for BACKPLQ_RED -->
<xsl:when test="name = 'BACKPLQ_RED' and max-queue-size > 41943040">
    <xsl:element name="max-queue-size">41943040</xsl:element>
</xsl:when>
```

### YANG → XSLT Mapping Summary

| YANG Deviation | Deviation Type | XSLT Action | XSLT File |
|---------------|----------------|-------------|-----------|
| `other-protocol` | not-supported | Remove node | `qos_unsupported_list_1.xsl` |
| `ip4-header/ip6-header` | not-supported | Remove node | `qos_unsupported_list_1.xsl` |
| `unmetered` | not-supported | Remove node | `qos_unsupported_list_1.xsl` |
| `pre-emption` | not-supported | Remove node | `qos_unsupported_list_1.xsl` |
| `dscp-range != 'any'` | Value transform | Set to 'any' | `qos_unsupported_list_1.xsl` |
| `protocol != 'igmp'` | Value transform | Set to 'igmp' | `qos_unsupported_list_1.xsl` |
| `max-queue-size >= 9600` | must constraint | Validate floor | `*_bac_max_queue_size.xsl` |
| Dual vlan tags | Cleanup | Keep 2nd tag | `qos_simplification_09_...` |
| Duplicate action profiles | Cleanup | Remove duplicates | `qos_simplification_09_...` |

### Validation App Mapping

#### 1. Switch Validator App Structure

**Location:** `/home/zhenac/fiber_code/sw/vobs/dsl/sw/y/build/apps/switch_validator_app/`

**Key Files:**
| File | Purpose |
|------|---------|
| `ValidationRuleCategory.json` | Defines which rules apply to which board/platform |
| `ValidationRuleErrorMsg.json` | Error messages for each validation rule |
| `TranslatorStrategyCategory.json` | Translation strategies |

#### 2. QoS-Related Validation Rule Categories

**Category: `qos-fiber`** (Line 162-199)
```json
"qos-fiber": {
    "items" : [
        "EachTypePolicyOnlyOccurOnce",
        "PolicyType1ActionCheckRule",
        "PolicyType3FilterCheckRule",
        "PolicyTypeMarkerActionCopyCheckRule",
        "VsiPolicyTypeGeneralSequenceRule",
        "PolicingPreHandlingProfileSameInQosPolicyProfileRule",
        ...
    ]
}
```

**Category: `qos-advanced-scheduler`** (Line 201-208)
```json
"qos-advanced-scheduler": {
    "items": [
        "TmRootChildNodeForVsiAttachRule",
        "TwoLayerSchedulerNodeRule",
        "NodeContainQueueForInterfaceAttachRule"
    ]
}
```

**Category: `qos-fiber-xpon`** (Line 211-225)
```json
"qos-fiber-xpon": {
    "items": [
        "DimensionBoardQueueStatsEntryCheckRule",
        "NetworkVsiMustAttachPbit2TCInFlatModeRule",
        ...
    ]
}
```

**Category: `qos-fiber-standalone`** (Line 227-274)
```json
"qos-fiber-standalone": {
    "items": [
        "DimensionPolicingReferredByClsRule",
        "DimensionPolicyWithTcRule",
        "PolicyTypeMarkerPbits2PbitsCheckRule",
        ...
    ]
}
```

#### 3. BAC/Queue-Related Validation Rules

**From ValidationRuleErrorMsg.json:**

| Rule Name | Error Message | YANG Constraint |
|-----------|---------------|-----------------|
| `BacColorActionLimitRule` | "For the policy with flow-color filter... action can only be bac-color" | - |
| `PolicingPreHandlingProfileSameInQosPolicyProfileRule` | "If policing profile has qos policing pre-handling-profile referenced DEI..." | - |
| `BPEthTmBacModeCheck` | "back plane interface supports only taildrop and wtaildrop" | `bac-type` constraint |
| `DimensionBacEntryNumCheckRule` | "maximum number of bac-entry-profile instantiation exceeds 62" | `max bac-entry` limit |
| `QoSSchedulerTypePoliciesLimitRule` | "the limit for qos scheduler type policies has been exceeded" | policy count limit |
| `InterfaceQueueLimitCheckRule` | "interface has exceeded the maximum specified interface type queue limit" | queue limit |
| `QoSPortPolicerPoliciesLimitRule` | "the limit for qos port-policer type policies has been exceeded" | port-policer limit |

#### 4. YANG → XSLT → Validation App Mapping

**Example: max-queue-size constraint**

| Layer | Code | Source |
|-------|------|--------|
| **YANG Deviation** | `deviate add must "( . >= 9600)"` mandatory true | `nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang` |
| **XSLT Migration** | `<xsl:if test="... < 9600"><xsl:element name="max-queue-size">9600</xsl:element></xsl:if>` | `*_bac_max_queue_size.xsl` |
| **Validation Rule** | Rule from `ValidationRuleCategory.json` category `qos-fiber-*` | switch_validator_app |
| **Error Message** | From `ValidationRuleErrorMsg.json` | - |

**Example: pre-emption not-supported**

| Layer | Code | Source |
|-------|------|--------|
| **YANG Deviation** | `deviate not-supported` on `pre-emption` | `nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang` |
| **XSLT Migration** | Empty template match | `qos_unsupported_list_1.xsl` |
| **Validation Rule** | Implicit (node doesn't exist) | switch_validator_app |

#### 5. Key Validation App Patterns for QoS

**Pattern 1: Policy Type Validation**
```json
"EachTypePolicyOnlyOccurOnce": {
    "error-message": [
        "For qos-policy-profile, each type of policy can occur only once."
    ]
}
```

**Pattern 2: Policy Sequence Validation**
```json
"VsiPolicyTypeGeneralSequenceRule": {
    "error-message": [
        "Marker-type, CCL-type, PortPolicer-type, Scheduler-type, QueueColor-type, Count-type"
    ]
}
```

**Pattern 3: BAC Entry Validation**
```json
"DimensionBacEntryNumCheckRule": {
    "error-message": [
        "maximum number of bac-entry-profile instantiation exceeds 62"
    ]
}
```

**Pattern 4: Classifier Action Validation**
```json
"BacColorActionLimitRule": {
    "error-message": [
        "For the policy with flow-color filter... action can only be bac-color"
    ]
}
```

#### 6. C++ Validation App Logic Analysis

**Core Insight**: Deviation YANG and C++ Validation App are two ways to implement the same constraint. Complex logic is often implemented in C++ code. Migration XSLT must understand this validation logic to correctly implement data transformation.

##### 6.1 C++ Validation Rule Structure

**File Location**: `/home/zhenac/fiber_code/sw/vobs/dsl/sw/y/src/switch_validator/`

```
logic/src/validationRules/
├── prepareEnd/           # prepareEnd stage validation
│   ├── qos/fiber/
│   │   ├── TM/
│   │   │   ├── DimensionBacEntryNumCheckRule.cpp
│   │   │   └── DimensionBoardQueueStatsEntryCheckRule.cpp
│   │   └── Policy/
│   │       └── 4Policer/
│   │           └── BacColorActionLimitRule.cpp
│   └── eth/
│       └── BPEthTmBacModeCheck.cpp
├── preTranslation/      # preTranslation stage validation
└── postTranslation/      # postTranslation stage validation
```

##### 6.2 Validation Rule Implementation Examples

**Example 1: BacColorActionLimitRule.cpp**
```cpp
// BacColorActionLimitRule.cpp (Line 11-128)
ValidatorLib::ReturnResult BacColorActionLimitRule::dataExecuteValidate()
{
    // Iterate all modified profiles
    LocalCtxItf::getModifiedProfileIter(proBegin, proEnd);
    for(; proBegin != proEnd; ++proBegin)
    {
        bool trtcmAction = false;  // Whether TRTCM policer exists
        // Iterate policies
        LocalCtxItf::getPolicyIterFromProfile(*proBegin, polBegin, polEnd);
        for(; polBegin != polEnd; ++polBegin)
        {
            // Iterate classifiers
            LocalCtxItf::getClassifierIterFromPolicy(polBegin->second, clsBegin, clsEnd);
            for(; clsBegin != clsEnd; ++clsBegin)
            {
                bool flowFilter = false;
                bool bacColorAction = false;
                std::set<FilterType> filter;
                std::set<ActionType> action;
                LocalCtxItf::getClassifierFilter(clsBegin->second, filter);
                LocalCtxItf::getClassifierAction(clsBegin->second, action);

                // Check if flow-color filter exists
                for(auto fIter : filter) {
                    if(*fIter == F_FLOW_COLOR) {
                        flowFilter = true;
                        break;
                    }
                }

                // Check action
                for(auto aIter : action) {
                    if(*aIter == A_BAC_COLOR) {
                        bacColorAction = true;
                    }
                    else if (*aIter == A_POLICING) {
                        // Check if TRTCM
                        if(type == P_TWO_RATE_THREE_COLOR) {
                            trtcmAction = true;
                        }
                    }
                }

                // Validation: flow-color filter action must be bac-color
                // unless TRTCM policer exists before
                if(!trtcmAction && flowFilter && !bacColorAction) {
                    return ValidatorLib::RetFail;  // Validation failed
                }
            }
        }
    }
    return ValidatorLib::RetSuccess;
}
```

**Key Understanding**:
- If classifier has `flow-color` filter
- And no TRTCM policer exists before
- Then action must be `bac-color`
- Otherwise validation fails

**Migration XSLT Required Logic**:
```xml
<!-- If classifier has flow-color filter but action is not bac-color -->
<!-- And profile has no TRTCM policer -->
<!-- Need to remove this classifier or change its action to bac-color -->
```

**Example 2: BPEthTmBacModeCheck.cpp**
```cpp
// BPEthTmBacModeCheck.cpp (Line 9-31)
ValidatorLib::ReturnResult BPEthTmBacModeCheck::dataExecuteValidate()
{
    // back plane interface supports only taildrop and wtaildrop.
    TmBacProfileInfo tmBacInfo;
    LocalCtxItf::getBpEthIter(begin, end);
    for(; begin != end; ++begin)
    {
        for(auto &tm: begin->second.tmQueues)
        {
            if(!LocalCtxItf::getTmBacProfile(tm.bacProfile, tmBacInfo)) {
                continue;
            }
            // Check if bac mode is TAILDROP or WTAILDROP
            if((TM_BACMODE_TAILDROP != tmBacInfo.getBacMode()) &&
               (TM_BACMODE_WTAILDROP != tmBacInfo.getBacMode()))
            {
                return ValidatorLib::RetFail;  // Validation failed
            }
        }
    }
    return ValidatorLib::RetSuccess;
}
```

**Key Understanding**:
- Backplane interface only supports `taildrop` and `wtaildrop` BAC modes
- Other modes (red, wred) are not supported

**Migration XSLT Required Logic**:
```xml
<!-- If bac-entry is used for backplane interface -->
<!-- And bac-type is not taildrop or wtaildrop -->
<!-- Need to change it to taildrop -->
```

**Example 3: DimensionBacEntryNumCheckRule.cpp**
```cpp
// DimensionBacEntryNumCheckRule.cpp (Line 3-21)
ValidatorLib::ReturnResult DimensionBacEntryNumCheckRule::dataExecuteValidate()
{
    // Maximum BAC entry count limit
    uint32_t maxTmBacProfileNum = SwitchValidation::DimensionManager::instance()->getMaxBacEntryNumber();
    std::set<bacEntryProfile> bacProfiles;

    // Count BAC entry used by Ethernet interfaces
    getEthBacEntryInstance(bacProfiles);
    // Count BAC entry used by LAG interfaces
    getLagBacEntryInstance(bacProfiles);

    // Check if exceeding limit (usually 62)
    if (bacProfiles.size() > maxTmBacProfileNum)
    {
        return ValidatorLib::RetFail;
    }
    return ValidatorLib::RetSuccess;
}
```

##### 6.3 YANG Constraint → C++ Validation Mapping

| YANG Deviation | C++ Validation Rule | Validation Logic |
|----------------|---------------------|------------------|
| `deviate add must "( . >= 9600)"` | Implicit in CQosBacEntry | Check `maxQueueSize >= 9600` |
| `deviate not-supported` on `pre-emption` | Implicit | Node does not exist, no check needed |
| `deviate add must "min < max"` | Implicit in CQosBacEntry | Check `minThreshold < maxThreshold` |
| `bac-type: taildrop/wtaildrop only` | `BPEthTmBacModeCheck` | Backplane only supports taildrop/wtaildrop |
| `max bac-entry: 62` | `DimensionBacEntryNumCheckRule` | Count bac entry numbers |
| `flow-color → bac-color only` | `BacColorActionLimitRule` | Check classifier action |

##### 6.4 Migration XSLT Required Analysis Steps

1. **Identify C++ Validation Rule**
   - Find the corresponding Validation Rule class
   - Read `dataExecuteValidate()` implementation

2. **Understand Validation Conditions**
   - Under what circumstances does validation fail?
   - What configuration items need to be checked?
   - What are the validation thresholds/limits?

3. **Determine Data Transformation Requirements**
   - Which configurations need modification?
   - What is the target value for modification?
   - Does recursive processing need to be performed?

4. **Write XSLT**
   - Match nodes that need modification
   - Condition checks
   - Value modification or deletion

##### 6.5 Common Validation Patterns

**Pattern A: Type/Mode Restriction**
```cpp
// Only supports specific types
if (type != SUPPORTED_TYPE_1 && type != SUPPORTED_TYPE_2) {
    return RetFail;
}
```
→ XSLT: Change unsupported types to supported default types

**Pattern B: Count Limit**
```cpp
// Count instance numbers
for (auto item : items) {
    count++;
}
if (count > MAX_COUNT) {
    return RetFail;
}
```
→ XSLT: Usually no modification needed unless merging instances

**Pattern C: Dependency Check**
```cpp
// If A exists, B must exist
if (hasA && !hasB) {
    return RetFail;
}
```
→ XSLT: If adding A, also add B

**Pattern D: Action Restriction**
```cpp
// filter X action can only be Y
if (hasFilterX && !hasActionY) {
    return RetFail;
}
```
→ XSLT: Change action to Y, or remove filter X

---

#### 7. Validation App → XSLT Back-Mapping

When XSLT removes a node (`deviate not-supported`):
1. The validation app will fail if that node is referenced
2. XSLT must also remove references to removed nodes
3. Example: Remove `other-protocol` filter AND any policy referencing it

When XSLT adds `must` constraints:
1. XSLT must normalize existing values to satisfy constraint
2. Validation app will reject any invalid configurations
3. Example: `max-queue-size >= 9600` requires XSLT to set minimum

---

### Key Learnings from BBN-88491

1. **Node Removal Pattern**: `deviate not-supported` → Empty XSLT template
2. **Value Normalization Pattern**: Invalid values → Default valid values
3. **Constraint Migration Pattern**: `must constraint` → Validate and fix
4. **Multi-step Migration**: Complex changes broken into sequential steps
5. **Board-Specific Scope**: Deviation files per board/platform

### Confluence Documentation

From JIRA comment (2022-09-05), the plan was:
| Module | Owner | Release | Remarks |
|--------|-------|---------|---------|
| xPON PM | Satish | LSR2303 | - |
| xPON function | Li Jian | LSR2303 | - |
| eqptHWA, SWM HWA | Chen Fusheng | LSR2303 | Telemetry deviation in LSR2212 |
| L2Fwd, QOS (Fiber) | Ma Liya | LSR2303 | - |
| Clock | Wang Junli | LSR2212 | - |
| Eqpt, IGMP | Zhang Yi | TBD | - |
| L2Fwd, QOS | Li Chengbing | LSR2303 | - |
| CFM, PM, SSH | Satish | LSR2303 | - |

---

## Pattern Usage Guide

### When to Use This Document

1. **Before generating new XSLT** - Check if similar pattern exists
2. **During development** - Reference for decision logic
3. **Code review** - Verify against established patterns
4. **Debugging** - Compare with historical cases

### How to Add New Patterns

1. Analyze a new XSLT migration case
2. Identify the pattern category
3. Document in appropriate section
4. Add reference example

---

## Related Documents

- `@migration-process-learning/SKILL.md` - Learning process and tools
- `@migration-xslt-generator/SKILL.md` - XSLT generation workflow
- `@jira-tool/SKILL.md` - JIRA integration
- `@confluence-tool/SKILL.md` - Confluence integration

---

---

# Appendix: 2023-2026 Migration Learning Summary

## Recent XSLT Commits Analysis (2023-2026)

### Summary

Based on the comprehensive scan of XSLT files from 2023-2026:

| Metric | Value |
|--------|-------|
| Total XSLT files | 2139 |
| Unique JIRA tickets found | 4 |
| BBN tickets | 3 |
| FNMS tickets | 1 |

---

## Documented Cases (2023-2026)

### Case 9: ONT Board Speed Migration (FNMS-154327)

| Field | Value |
|-------|-------|
| **XSLT** | `eqpt/lsr2306_to_lsr2309_eqpt-onu-board_1.xsl` |
| **JIRA** | FNMS-154327 |
| **Board** | FNMS (StarHub) |
| **Pattern** | Conditional Node Preservation |
| **Issue** | StarHub specific issue with ONT board speed |

**XSLT Logic:**
```xml
<!-- For specific board (board_id=11), keep speed; for others, remove -->
<xsl:template match=".../auto-negotiation/speed">
    <xsl:variable name="var_board_id" select="...hardware/component[class='bbf-hwt:board']/parent-rel-pos"/>
    <xsl:choose>
        <xsl:when test="$var_board_count = 1 and $var_board_id = 11">
            <xsl:copy-of select="."/>
        </xsl:when>
        <xsl:otherwise>
            <!-- Remove speed for other boards -->
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
```

**Key Insight:**
- Board-specific migration logic based on board ID
- Only applies to single-board configurations

---

### Case 10: QoS Filter Node Removal (BBN-96114)

| Field | Value |
|-------|-------|
| **XSLT** | `qos/lsr2212_to_lsr2303_qos_unsupported_list_1.xsl` |
| **JIRA** | BBN-96114 |
| **EPIC** | BBN-88491 |
| **Pattern** | Node Removal + Value Normalization |

**YANG Deviations (nokia-qos-filters-ext-qos-fiber-dev.yang):**
- `other-protocol` - not-supported
- `ip4-header` - not-supported
- `ip6-header` - not-supported
- `ip-header-common` - not-supported
- `unmetered` - not-supported

**XSLT Logic:**
```xml
<!-- Remove other-protocol under classifier match-criteria -->
<xsl:template match="*[
    local-name() = 'other-protocol'
    and namespace-uri() = 'http://www.nokia.com/Fixed-Networks/BBA/yang/nokia-qos-filters-ext'
    and parent::*[local-name() = 'match-criteria']
    and ancestor::*[local-name() = 'classifier-entry']
]"/>

<!-- Remove filter under classifier-entry -->
<xsl:template match="*[
    local-name() = 'filter' and namespace-uri() = 'urn:bbf:yang:bbf-qos-filters'
    and parent::*[local-name() = 'classifier-entry']
]"/>

<!-- Remove dscp-marking-cfg under classifier-action-entry-cfg -->
<xsl:template match="*[
    local-name() = 'classifier-action-entry-cfg'
    and (child::*[local-name() = 'action-type' and current() = 'dscp-marking'])
    and parent::*[local-name() = 'classifier-entry']
]"/>
```

---

### Case 11: QoS Simplification Cache Cleanup (BBN-122791)

| Field | Value |
|-------|-------|
| **XSLT** | `qos/lsr2212_to_lsr2303_qos_simplification_09_clean_cache_and_unused_nodes_1.xsl` |
| **JIRA** | BBN-122791 |
| **EPIC** | BBN-88491 |
| **Pattern** | Conditional Node Cleanup + Cache Management |

**XSLT Logic - Clean Unused Policy:**
```xml
<!-- Delete policy that has 'deleted' label and no active reference -->
<xsl:template match="*[local-name() = 'policy' and parent::*[local-name() = 'policies']]" priority="9">
    <xsl:variable name="anyoneLabelDeleted" select="//*[local-name() = 'policy' and child::*[local-name() = 'deleted'] and parent::*[local-name() = 'policies']]"/>
    <xsl:variable name="anyoneStillUsed" select="//*[local-name() = 'policy' and not(child::*[local-name() = 'deleted']) and parent::*[local-name() = 'policies']]"/>
    <xsl:choose>
        <xsl:when test="$anyoneLabelDeleted and not($anyoneStillUsed)">
            <!-- delete labeled policy -->
        </xsl:when>
        <xsl:otherwise>
            <xsl:copy>...</xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
```

**XSLT Logic - Dual VLAN Tag Cleanup (BBN-122791):**
```xml
<!-- When dual vlan tags exist in pre-handling profile, only keep second -->
<xsl:template match="*[local-name() = 'vlans' and namespace-uri() = '...nokia-sdan-qos-policing-extension']" priority="2">
    <xsl:choose>
        <xsl:when test="count(child::*[local-name() = 'tag']) &gt; 1">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:for-each select="child::*[local-name() = 'tag']">
                    <xsl:if test="position() = 2">
                        <xsl:copy>...</xsl:copy>
                    </xsl:if>
                </xsl:for-each>
            </xsl:copy>
        </xsl:when>
        <xsl:otherwise>
            <xsl:copy>...</xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
```

---

### Case 12: BAC Max Queue Size Validation (2024)

| Field | Value |
|-------|-------|
| **XSLT** | `qos/lsr2509_to_lsr2512_qos_update_bac_max_queue_size.xsl` |
| **YANG** | `nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang` |
| **Constraint** | `must "( . >= 9600)"` mandatory true |
| **Pattern** | Constraint Validation (Floor) |

**YANG Deviation:**
```yang
deviation "/bbf-qos-tm:tm-profiles/bbf-qos-tm:bac-entry/bbf-qos-tm:max-queue-size" {
    deviate add {
       must "( . >= 9600)" {
         error-message "Bac max-queue-size should be explicitly specified, and its value must be no less than 9600.";
       }
      mandatory true;
    }
}
```

**XSLT Logic:**
```xml
<!-- Special handling for BACKPLQ_RED - cap at 41943040 -->
<xsl:template match="/config/bbf-qos-tm:tm-profiles/bbf-qos-tm:bac-entry">
    <xsl:variable name="bacName" select="bbf-qos-tm:name"/>
    <xsl:choose>
        <xsl:when test="$bacName='BACKPLQ_RED'">
            <xsl:choose>
                <xsl:when test="bbf-qos-tm:max-queue-size &gt; 41943040">
                    <!-- Cap to 41943040 -->
                    <xsl:copy>...</xsl:copy>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy>...</xsl:copy>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:copy>...</xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
```

---

## New YANG Deviation Patterns (2023-2026)

### QoS Traffic Management Deviations

#### Threshold Constraints

| XPath | Deviation Type | Constraint | Error Message |
|-------|---------------|------------|---------------|
| `bac-entry/bac-type/*/min-threshold` | `add must` | `. < ../max-threshold` | "Min Threshold value must be less than that of Max threshold" |
| `bac-entry/bac-type/taildrop/max-threshold` | `add must` | `. != 0` | "TailDrop max-threshold cannot be zero" |
| `bac-entry/bac-type/wtaildrop/*/max-threshold` | `add must` | `. != 0` | "WtailDrop max-threshold cannot be zero" |
| `bac-entry/bac-type/red/max-threshold` | `add must` | `. != 0` | "Red max-threshold cannot be zero" |
| `bac-entry/bac-type/wred/*/max-threshold` | `add must` | `. != 0` | "Wred max-threshold cannot be zero" |
| `bac-entry/max-queue-size` | `add must + mandatory` | `. >= 9600` | "Bac max-queue-size should be explicitly specified, and its value must be no less than 9600" |

#### Node Removal

| XPath | Deviation Type | Purpose |
|-------|---------------|---------|
| `interface/tm-root/children-type/queues/queue/pre-emption` | `not-supported` | Pre-emption not supported |
| `classifiers/classifier-entry/.../other-protocol` | `not-supported` | Other protocol not supported |
| `filters/filter/filter-field/ip4-header` | `not-supported` | IPv4 header not supported |
| `filters/filter/filter-field/ip6-header` | `not-supported` | IPv6 header not supported |
| `classifiers/classifier-entry/.../unmetered` | `not-supported` | Unmetered not supported |

---

## Validation Rule Categories (QoS)

### QoS Fiber Categories

| Category | Rules |
|----------|-------|
| `qos-fiber` | EachTypePolicyOnlyOccurOnce, PolicyType1ActionCheckRule, PolicyType3FilterCheckRule, PolicyTypeMarkerActionCopyCheckRule, VsiPolicyTypeGeneralSequenceRule, PolicingPreHandlingProfileSameInQosPolicyProfileRule |
| `qos-advanced-scheduler` | TmRootChildNodeForVsiAttachRule, TwoLayerSchedulerNodeRule, NodeContainQueueForInterfaceAttachRule |
| `qos-fiber-xpon` | DimensionBoardQueueStatsEntryCheckRule, NetworkVsiMustAttachPbit2TCInFlatModeRule |
| `qos-fiber-standalone` | DimensionPolicingReferredByClsRule, DimensionPolicyWithTcRule, PolicyTypeMarkerPbits2PbitsCheckRule |

---

## Epic Index (Updated 2026)

| EPIC Key | Title | Type | Status | Fix Version | Stories |
|----------|-------|------|--------|-------------|---------|
| BBN-88491 | Lightspan Yang deviations for not supported data | Epic | Released | LSR2303 | BBN-96114, BBN-122791, BBN-133774 |
| FNMS-154327 | StarHub ONT Board Speed Issue | Bug | Closed | 23.12 | - |

### BBN EPIC Hierarchy (BBN-88491)

**Epic:** BBN-88491 - Lightspan Yang deviations for not supported data
- **Type:** Epic
- **Status:** Released
- **Fix Version:** LSR2303
- **Priority:** Major

**Stories/Bugs under this Epic:**

| Key | Summary | Type | Status | Priority |
|-----|---------|------|--------|----------|
| BBN-96114 | QoS Modules - Unsupported leafs | Story | Done | Minor |
| BBN-122791 | POLICING-PRE-HANDLING CONFIG ISSUE | Sub-task | Done | Minor |
| BBN-133774 | Duplicate elements in policing-action-profiles | Bug | Closed | Critical |

### FNMS Bug (FNMS-154327)

**Bug:** FNMS-154327 - CLONE 23.12 - [StarHub]If set port speed configurable =yes, 23.9 will create Cage UNI directly, it's not correct for GPON/XGS ONU
- **Type:** Bug
- **Status:** Closed
- **Fix Version:** 23.12
- **Priority:** Major
- **Board:** FNMS (StarHub specific)

---

## New XSLT Pattern: Namespace Prefix Fix

### Pattern: Enhanced Filter Operation Namespace Fix

**Case:** BBN-122791 (QoS Simplification)

**Problem:** Enhanced-filter filter-operation values need correct namespace prefix.

**XSLT Logic:**
```xml
<!-- Fix filter-operation namespace prefix -->
<xsl:template match="*[local-name() = 'filter-operation'
    and namespace-uri()= 'urn:bbf:yang:bbf-qos-enhanced-filters'
    and parent::*[local-name() = 'enhanced-filter']
    and ancestor::*[local-name() = 'filters']]">

    <xsl:variable name="clsNsPrefix">
        <xsl:value-of select="local-name(namespace::*[. = 'urn:bbf:yang:bbf-qos-classifiers'])"/>
    </xsl:variable>

    <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:choose>
            <xsl:when test="$clsNsPrefix and string-length($clsNsPrefix)&gt;0
                and not(starts-with(current(),$clsNsPrefix))">
                <xsl:value-of select="concat($clsNsPrefix,':',current())"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:copy>
</xsl:template>
```

**Key Insight:**
- Use `namespace::*` to get namespace prefix
- Check if value already has prefix before adding

---

## New XSLT Pattern: Duplicate Element Deduplication

### Pattern: Duplicate Action Profile Deduplication (BBN-133774)

**Problem:** Duplicate elements in policing-action-profiles caused migration failure.

**XSLT Logic:**
```xml
<!-- Remove duplicate action profiles by name -->
<xsl:template match="*[local-name() = 'action-profile'
    and namespace-uri() = '...nokia-sdan-qos-policing-extension'
    and parent::*[local-name() = 'policing-action-profiles']]">

    <xsl:variable name="curActionProfileName" select=".../name"/>

    <xsl:variable name="preActionProfileWithSameName"
        select="preceding-sibling::*[local-name() = 'action-profile'
            and child::*[local-name() = 'name'] = $curActionProfileName]"/>

    <xsl:choose>
        <xsl:when test="$preActionProfileWithSameName">
            <!-- Skip duplicate -->
        </xsl:when>
        <xsl:otherwise>
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <!-- Handle action deduplication by flow-color -->
                <xsl:for-each select="child::*[local-name() = 'action']">
                    <xsl:choose>
                        <xsl:when test="preceding-sibling::*[contains(flow-color,$curFlowColor)]">
                            <!-- Skip duplicate flow-color action -->
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy>...</xsl:copy>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
```

---

## New XSLT Pattern: Classifier Entry Transformation

### Pattern: Unmetered to Metered Conversion (BBN-122791)

**Problem:** Classifier entries with unmetered need to be converted.

**XSLT Logic:**
```xml
<!-- Convert unmetered classifier to metered -->
<xsl:template match="*[local-name() = 'classifier-entry'
    and child::*[local-name() = 'match-criteria']/child::*[local-name() = 'unmetered']]">

    <xsl:variable name="inlineTagNumber"
        select="count(child::*[local-name() = 'match-criteria']/node())"/>

    <xsl:choose>
        <!-- If has other match criteria, remove unmetered only -->
        <xsl:when test="$inlineTagNumber &gt; 1">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:for-each select="node()">
                    <xsl:choose>
                        <xsl:when test="local-name() = 'match-criteria'">
                            <xsl:copy>
                                <xsl:for-each select="node()">
                                    <xsl:if test="local-name() != 'unmetered'">
                                        <xsl:copy-of select="."/>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:copy>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:copy-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:copy>
        </xsl:when>
        <!-- If only unmetered, convert to metered=false -->
        <xsl:otherwise>
            <xsl:copy>
                <xsl:copy-of select="child::*[local-name() = 'name']"/>
                <xsl:copy-of select="child::*[local-name() = 'filter-operation']"/>
                <xsl:element name="metered-flow" namespace="...nokia-qos-filters-ext">
                    <xsl:value-of select="false()"/>
                </xsl:element>
                <xsl:for-each select="node()">
                    <xsl:choose>
                        <xsl:when test="local-name() = 'name' or local-name() = 'filter-operation'"/>
                        <xsl:otherwise>
                            <xsl:copy-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
```

---

## New XSLT Pattern: Flow Color Action Cleanup

### Pattern: Remove Flow Color When Enhanced Filter Present (BBN-122791)

**XSLT Logic:**
```xml
<!-- Delete flow-color action when filter includes enhanced-filter or any-frame -->
<xsl:template match="*[local-name() = 'classifier-action-entry-cfg'
    and child::*[local-name() = 'flow-color']
    and parent::*[local-name() = 'classifier-entry']
    and ../child::*[local-name() = 'enhanced-filter-name']
        or ../child::*[local-name() = 'any-frame']]">
    <!-- Delete this element (empty template) -->
</xsl:template>

<!-- Delete bac-color action when both bac-color and scheduling-traffic-class exist -->
<xsl:template match="*[local-name() = 'classifier-action-entry-cfg'
    and child::*[local-name() = 'bac-color']
    and ../child::*[local-name() = 'classifier-action-entry-cfg']
        /child::*[local-name() = 'scheduling-traffic-class']">
    <!-- Delete this element (empty template) -->
</xsl:template>
```

---

## Confluence Reference

Migration issues documented at:
https://confluence-app.ext.net.nokia.com/display/FIBERFWD2/migration+issue

---

## Migration Pattern Decision Tree

When creating a new migration XSLT, follow this decision tree:

```
Is there a YANG deviation?
|
+-- No --> No migration needed (YANG handles defaults)
|
+-- Yes --> What type?
           |
           +-- deviate not-supported --> Node Removal Pattern
           |    (Empty template or modify parent)
           |
           +-- deviate add must --> Constraint Validation Pattern
           |    (Check and update value)
           |
           +-- deviate add mandatory --> Mandatory Field Pattern
           |    (Add default if missing)
           |
           +-- deviate replace type --> Type Conversion Pattern
                (Map old values to new)
```

---

## Files Discovered

### XSLT Files Referenced

| File | JIRA | Pattern |
|------|------|---------|
| `qos/lsr2212_to_lsr2303_qos_unsupported_list_1.xsl` | BBN-96114 | Node Removal |
| `qos/lsr2212_to_lsr2303_qos_simplification_09_clean_cache_and_unused_nodes_1.xsl` | BBN-122791, BBN-133774 | Cache Cleanup, Duplicate Removal |
| `qos/lsr2509_to_lsr2512_qos_update_bac_max_queue_size.xsl` | - | Constraint Validation |
| `eqpt/lsr2306_to_lsr2309_eqpt-onu-board_1.xsl` | FNMS-154327 | Conditional Preservation |

### YANG Deviation Files

| File | Domain | Key Deviations |
|------|--------|---------------|
| `nokia-qos-filters-ext-qos-fiber-dev.yang` | QoS Filters | other-protocol, ip4/ip6-header, unmetered |
| `nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang` | Traffic Mgmt | max-queue-size, pre-emption, thresholds |
| `nokia-bbf-qos-filters-qos-fiber-dev.yang` | QoS Filters | Various filter fields |
| `nokia-bbf-qos-policing-qos-fiber-dev.yang` | QoS Policing | policing profiles |
