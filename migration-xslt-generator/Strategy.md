# Strategy.md - XSLT Generation Strategy

This document defines the transformation logic for converting various inputs (Intent, YANG changes, Validation rules) into final XSLT migration scripts.

---

## Part 1: Intent Classification

### Intent Type Definitions

| Type | Description | XSLT Pattern |
|------|-------------|--------------|
| `DELETE_NODE` | Remove a specific node(s) | Don't match the node (implicit deletion) |
| `RENAME_NODE` | Rename a node to a new name | Match old name, create element with new name |
| `CHANGE_VALUE` | Modify values based on condition | Match node, apply value transformation |
| `ADD_DEFAULT` | Add node with default value if missing | Check existence, create if not present |
| `CHANGE_TYPE` | Change data type | Use type converter from framework |
| `MERGE_NODES` | Move children from one container to another | Match parent, restructure children |
| `SPLIT_NODES` | Distribute children to multiple containers | Match source, create multiple targets |
| `CONDITIONAL_UPDATE` | Update node based on another node's value | XPath condition, apply templates |

---

## Part 2: YANG Change Classification

### YANG Change → XSLT Requirement Mapping

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

### YANG Deviation → XSLT Action Mapping

| Deviation Statement | XSLT Action | Notes |
|--------------------|------------|-------|
| `deviate not-supported` | Remove node | Empty template |
| `deviate add must "..."` | Validate & update | Check and fix |
| `deviate add mandatory` | Add default | If not present |
| `deviate replace type` | Transform | Map values |
| `deviate add default` | Usually not needed | YANG handles it |

---

## Part 3: XSLT Pattern Library

### Standard XSLT Template Structure

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

</xsl:stylesheet>
```

---

## Part 4: Core XSLT Patterns

### Pattern 1: Node Removal (deviate not-supported)

**YANG Change:**
```yang
deviation "/path/to/node" {
    deviate not-supported;
}
```

**XSLT Logic:**
```xml
<!-- Empty template = implicit deletion -->
<xsl:template match="namespace:unsupported-node"/>
```

**With Path:**
```xml
<xsl:template match="namespace:parent/namespace:child"/>
```

**Conditional Remove:**
```xml
<xsl:template match="namespace:node[namespace:condition='value']"/>
```

---

### Pattern 2: Constraint Validation (must constraint)

**YANG Change:**
```yang
deviation "/path/to/leaf" {
    deviate add {
        must "( . >= MIN_VALUE)";
        must "( . <= MAX_VALUE)";
    }
}
```

**XSLT Logic - Floor (minimum value):**
```xml
<xsl:template match="target-path">
    <xsl:choose>
        <xsl:when test="not(target-leaf) or number(target-leaf) &lt; MIN_VALUE">
            <xsl:element name="target-leaf">
                <xsl:value-of select="MIN_VALUE"/>
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

**XSLT Logic - Ceiling (maximum value):**
```xml
<xsl:template match="target-leaf">
    <xsl:choose>
        <xsl:when test="number(.) &gt; MAX_VALUE">
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

**Real Example (BAC Max Queue Size):**
```xml
<!-- From lsr2509_to_lsr2512_qos_update_bac_max_queue_size.xsl -->
<xsl:template match="/cfg-ns:config/bbf-qos-tm:tm-profiles/bbf-qos-tm:bac-entry">
    <xsl:variable name="maxQueueSize">
        <xsl:value-of select="current()/bbf-qos-tm:max-queue-size"/>
    </xsl:variable>
    <xsl:variable name="bacName">
        <xsl:value-of select="current()/bbf-qos-tm:name"/>
    </xsl:variable>
    <xsl:choose>
        <xsl:when test="$bacName=$BACNAME_BACKPLQ_RED">
            <xsl:choose>
                <xsl:when test="$maxQueueSize &gt; 41943040">
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:for-each select="current()/node()">
                            <xsl:choose>
                                <xsl:when test="local-name() = 'max-queue-size'">
                                    <xsl:element name="max-queue-size" namespace="urn:bbf:yang:bbf-qos-traffic-mngt">
                                        <xsl:value-of select="41943040"/>
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

---

### Pattern 3: Mandatory Field (mandatory true)

**YANG Change:**
```yang
deviation "/path/to/leaf" {
    deviate add {
        mandatory true;
    }
}
```

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

---

### Pattern 4: Value Normalization

**YANG Change:** Unsupported values need to be normalized.

**XSLT Logic:**
```xml
<!-- Transform invalid values to valid defaults -->
<xsl:template match="*[local-name() = 'dscp-range' and normalize-space(text()) != 'any']">
    <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:value-of select="'any'"/>
    </xsl:copy>
</xsl:template>

<!-- Transform protocol to igmp only -->
<xsl:template match="*[local-name() = 'protocol' and normalize-space(text()) != 'igmp']">
    <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:value-of select="'igmp'"/>
    </xsl:copy>
</xsl:template>
```

---

### Pattern 5: Type Conversion

**YANG Change:**
```yang
deviation "/path/to/leaf" {
    deviate replace {
        type identityref { ... }
    }
}
```

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

---

### Pattern 6: Classifier Type Computation

**YANG Change:** Add computed `classifier-type` field.

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

---

### Pattern 7: Policy Cache Construction

**YANG Change:** Add migration cache structure.

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

---

### Pattern 8: Queue Color

**YANG Change:** Add new `queue-color` field.

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

---

### Pattern 9: Conditional Node Cleanup

**YANG Change:** Conditional cleanup required based on data state.

**XSLT Logic - Dual VLAN Tag Cleanup:**
```xml
<xsl:template match="*[local-name() = 'vlans' ...]" priority="2">
    <xsl:choose>
        <xsl:when test="count(child::*[local-name() = 'tag']) &gt; 1">
            <xsl:copy>
                <xsl:copy-of select="@*"/>
                <xsl:for-each select="child::*[local-name() = 'tag']">
                    <xsl:if test="position() = 2">
                        <xsl:copy-of select="."/>
                    </xsl:if>
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

---

### Pattern 10: Duplicate Removal

**YANG Change:** Duplicate elements not allowed.

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

---

### Pattern 11: Unmetered to Metered Conversion

**XSLT Logic:**
```xml
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
                <!-- ... rest of transformation -->
            </xsl:copy>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>
```

---

### Pattern 12: Flow Color Action Cleanup

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

### Pattern 13: Namespace Prefix Fix

**XSLT Logic:**
```xml
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

---

### Pattern 14: Relative Path Comparison (must with ../)

**YANG Change:**
```yang
deviation ".../min-threshold" {
    deviate add {
       must " . &lt; ../bbf-qos-tm:max-threshold "
    }
}
```

**XSLT Logic:**
```xml
<xsl:template match="/cfg-ns:config/bbf-qos-tm:tm-profiles/bbf-qos-tm:bac-entry
                     [bbf-qos-tm:bac-type/bbf-qos-tm:red/bbf-qos-tm:red/bbf-qos-tm:min-threshold
                      &gt;= bbf-qos-tm:bac-type/bbf-qos-tm:red/bbf-qos-tm:red/bbf-qos-tm:max-threshold]">
    <xsl:copy>
        <xsl:copy-of select="@*"/>
        <xsl:for-each select="*">
            <xsl:choose>
                <xsl:when test="self::bbf-qos-tm:bac-type/bbf-qos-tm:red/bbf-qos-tm:red/bbf-qos-tm:min-threshold">
                    <xsl:copy>
                        <xsl:copy-of select="@*"/>
                        <xsl:value-of select="number(../bbf-qos-tm:max-threshold) - 1"/>
                    </xsl:copy>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="."/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:copy>
</xsl:template>
```

---

## Part 5: Intent-Specific Patterns

### DELETE_NODE

```xslt
<!-- Delete node: simply don't match it -->
<!-- Original: <node_to_delete/> will be removed -->

<!-- Special Case - Delete with condition -->
<xsl:template match="interface[max-queue-size > 9600]">
    <xsl:copy>
        <xsl:apply-templates select="@*"/>
        <xsl:apply-templates select="*[not(self::max-queue-size)]"/>
        <max-queue-size>9600</max-queue-size>
    </xsl:copy>
</xsl:template>
```

### RENAME_NODE

```xslt
<!-- Rename node: match old name, output new name -->
<xsl:template match="olt-id">
    <xsl:element name="ont-id">
        <xsl:value-of select="."/>
    </xsl:element>
</xsl:template>
```

### CHANGE_VALUE (Cap/Floor)

```xslt
<!-- Cap values (max threshold) -->
<xsl:template match="max-queue-size[. > 9600]">
    <max-queue-size>9600</max-queue-size>
</xsl:template>

<!-- Floor values (min threshold) -->
<xsl:template match="rate-limit[. &lt; 100]">
    <rate-limit>100</rate-limit>
</xsl:template>

<!-- Exact replacement -->
<xsl:template match="operational-mode[. = 'down']">
    <operational-mode>disabled</operational-mode>
</xsl:template>
```

### CONDITIONAL_UPDATE

```xslt
<xsl:template match="interface">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()"/>
        <xsl:if test="admin-status = 'down'">
            <xsl:if test="not(operational-mode) or operational-mode != 'disabled'">
                <operational-mode>disabled</operational-mode>
            </xsl:if>
        </xsl:if>
    </xsl:copy>
</xsl:template>
```

---

## Part 6: Domain Detection

### Domain Mapping Table

| Namespace Pattern | Match Path Pattern | Domain |
|-------------------|-------------------|--------|
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

---

## Part 7: XSLT Optimization Strategies

### 1. Use xsl:apply-templates Instead of xsl:for-each

```xml
<!-- Recommended: Recursive processing -->
<xsl:template match="container">
    <xsl:apply-templates select="child"/>
</xsl:template>
```

### 2. Describe Conditions in Match Expressions

```xml
<!-- Recommended: Condition in match -->
<xsl:template match="onu:onus/onu:onu/ifNs:interfaces/ifNs:interface[ifNs:type='ianaift-mounted:ethernetCsmacd']/ptp:ptp-port"/>
```

### 3. Avoid Using //

```xml
<!-- Recommended: Match exact path -->
<xsl:template match="onu:onus/onu:onu/ifNs:interfaces"/>
```

### 4. Avoid Wildcard Matching

```xml
<!-- Recommended: Explicit specification -->
<xsl:template match="fwding:forwarding/fwding:forwarders/fwding:forwarder/fwding:port-groups"/>
```

### 5. Use OR Expressions for Same XPath Tree

```xml
<xsl:template match="tcont:additional-bw-eligibility-indicator |
                     tcont:weight |
                     tcont:priority"/>
```

### 6. Remove Unused Namespaces

Only declare namespaces that are actually used in match conditions.

---

## Part 8: Validation → XSLT Mapping

### Layer Mapping

| Layer | Action | Example |
|-------|--------|---------|
| YANG | Define constraint | `must "( . >= 9600)"` |
| Validation App | Check at commit | Return error if violated |
| XSLT | Migrate existing | Update values to satisfy |

### YANG Constraint → C++ Validation Mapping

| YANG Deviation | C++ Validation Rule | Validation Logic |
|----------------|---------------------|------------------|
| `deviate add must "( . >= 9600)"` | Implicit in CQosBacEntry | Check `maxQueueSize >= 9600` |
| `deviate not-supported` on `pre-emption` | Implicit | Node does not exist |
| `deviate add must "min < max"` | Implicit in CQosBacEntry | Check `minThreshold < maxThreshold` |
| `bac-type: taildrop/wtaildrop only` | `BPEthTmBacModeCheck` | Backplane only supports taildrop/wtaildrop |
| `max bac-entry: 62` | `DimensionBacEntryNumCheckRule` | Count bac entry numbers |
| `flow-color → bac-color only` | `BacColorActionLimitRule` | Check classifier action |

### Common Validation Patterns

**Pattern A: Type/Mode Restriction**
```cpp
if (type != SUPPORTED_TYPE_1 && type != SUPPORTED_TYPE_2) {
    return RetFail;
}
```
→ XSLT: Change unsupported types to supported default types

**Pattern B: Count Limit**
```cpp
for (auto item : items) { count++; }
if (count > MAX_COUNT) { return RetFail; }
```
→ XSLT: Usually no modification needed unless merging instances

**Pattern C: Dependency Check**
```cpp
if (hasA && !hasB) { return RetFail; }
```
→ XSLT: If adding A, also add B

**Pattern D: Action Restriction**
```cpp
if (hasFilterX && !hasActionY) { return RetFail; }
```
→ XSLT: Change action to Y, or remove filter X

### Validation App → XSLT Back-Mapping

When XSLT removes a node (`deviate not-supported`):
1. The validation app will fail if that node is referenced
2. XSLT must also remove references to removed nodes
3. Example: Remove `other-protocol` filter AND any policy referencing it

When XSLT adds `must` constraints:
1. XSLT must normalize existing values to satisfy constraint
2. Validation app will reject any invalid configurations
3. Example: `max-queue-size >= 9600` requires XSLT to set minimum

---

## Part 9: Documented Cases

### Case 1: QoS Unsupported Leafs Removal

| Field | Value |
|-------|-------|
| **XSLT** | `qos/lsr2212_to_lsr2303_qos_unsupported_list_1.xsl` |
| **JIRA** | BBN-96114 |
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
| **Constraint** | Cap at 4000000000 |
| **Pattern** | Constraint Validation (Ceiling) |

**XSLT Logic:**
```xml
<xsl:choose>
    <xsl:when test="current()/text() &gt; 4000000000">
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

### Case 8: ONT Board Speed Migration (Board-Specific)

| Field | Value |
|-------|-------|
| **XSLT** | `eqpt/lsr2306_to_lsr2309_eqpt-onu-board_1.xsl` |
| **JIRA** | FNMS-154327 |
| **Pattern** | Conditional Node Preservation |

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

**Key Insight:** Board-specific migration logic based on board ID.

---

## Part 10: QoS YANG Deviation Reference

### Threshold Constraints

| XPath | Deviation Type | Constraint | Error Message |
|-------|---------------|------------|---------------|
| `bac-entry/bac-type/*/min-threshold` | `add must` | `. < ../max-threshold` | "Min Threshold value must be less than that of Max threshold" |
| `bac-entry/bac-type/taildrop/max-threshold` | `add must` | `. != 0` | "TailDrop max-threshold cannot be zero" |
| `bac-entry/bac-type/wtaildrop/*/max-threshold` | `add must` | `. != 0` | "WtailDrop max-threshold cannot be zero" |
| `bac-entry/bac-type/red/max-threshold` | `add must` | `. != 0` | "Red max-threshold cannot be zero" |
| `bac-entry/bac-type/wred/*/max-threshold` | `add must` | `. != 0` | "Wred max-threshold cannot be zero" |
| `bac-entry/max-queue-size` | `add must + mandatory` | `. >= 9600` | "Bac max-queue-size should be explicitly specified, and its value must be no less than 9600" |

### Node Removal

| XPath | Deviation Type | Purpose |
|-------|---------------|---------|
| `interface/tm-root/children-type/queues/queue/pre-emption` | `not-supported` | Pre-emption not supported |
| `classifiers/classifier-entry/.../other-protocol` | `not-supported` | Other protocol not supported |
| `filters/filter/filter-field/ip4-header` | `not-supported` | IPv4 header not supported |
| `filters/filter/filter-field/ip6-header` | `not-supported` | IPv6 header not supported |
| `classifiers/classifier-entry/.../unmetered` | `not-supported` | Unmetered not supported |
| `classifiers/classifier-entry/.../dscp-marking-cfg` | `not-supported` | DSCP marking not supported |

---

## Part 11: Migration Pattern Decision Tree

When creating a new migration XSLT, follow this decision tree:

```
Is there a YANG deviation?

+-- No --> No migration needed (YANG handles defaults)

+-- Yes --> What type?

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

## Part 12: Epic Index

| EPIC Key | Title | Type | Stories | XSLTs | Date |
|----------|-------|------|---------|-------|------|
| BBN-88491 | Lightspan Yang deviations for not supported data | Epic | BBN-96114, BBN-122791, BBN-133774 | Multiple | 2023-01 |
| FNMS-154327 | StarHub ONT Board Speed Issue | Bug | - | 1 | 2023-12 |

### BBN-88491 JIRA Hierarchy

```
EPIC: BBN-88491 - Lightspan Yang deviations for not supported data
├── STORY: BBN-96114 - QoS Modules - Unsupported leafs
│   └── XSLT: lsr2212_to_lsr2303_qos_unsupported_list_1.xsl
├── SUBTASK: BBN-122791 - POLICING-PRE-HANDLING CONFIG ISSUE
│   └── XSLT: lsr2212_to_lsr2303_qos_simplification_09_clean_cache_and_unused_nodes_1.xsl
└── BUG: BBN-133774 - Duplicate elements in policing-action-profiles
    └── XSLT: lsr2212_to_lsr2303_qos_simplification_09_clean_cache_and_unused_nodes_1.xsl
```

---

## Part 13: Reference XSLT Examples

When generating XSLT for BAC entry `max-queue-size` constraint handling, refer to:

| File | Purpose |
|------|---------|
| `xsl/qos/lsr2509_to_lsr2512_qos_update_bac_max_queue_size.xsl` | Handle max-queue-size constraints (BACNAME_BACKPLQ_RED case) |
| `xsl/qos/lsr2203_to_lsr2206_update_bac_profile_1.xsl` | Handle max-queue-size value limits |
| `xsl/qos/lsr2212_to_lsr2303_qos_unsupported_list_1.xsl` | Remove unsupported QoS nodes |
| `xsl/qos/lsr2212_to_lsr2303_qos_simplification_09_clean_cache_and_unused_nodes_1.xsl` | QoS simplification cleanup |
| `xsl/remove/lsr2412_to_lsr2503_remove_unsupported_xpaths_1.xsl` | Generic unsupported node removal |

---

## Related Documents

- [Generator.md](Generator.md) - User workflow and interaction
- [Background.md](Background.md) - XSLT framework and background knowledge
