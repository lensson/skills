# Background.md - XSLT Framework Reference

This document contains background knowledge and reference data for XSLT migration script generation.

---

## XSLT Framework

### Framework Files

The framework provides base templates at `vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/framework/`:

| File | Purpose |
|------|---------|
| `identity-utils.xsl` | Identity and type utilities |
| `node-operations.xsl` | Node manipulation templates |
| `type-converters.xsl` | Type conversion functions |

---

## XSLT File Organization

### Key Principles

1. **No Duplication**: Each file should have only one copy
2. **No Symbolic Links**: Avoid using symbolic links

### Directory Structure

XSLT files are organized by domain in `xsl/<domain>/` directories.

| Domain Directory | Description |
|------------------|-------------|
| `nacm/` | NACM (NETCONF Access Control) |
| `qos/` | QoS policies and scheduling |
| `l2forwarding/` | Layer 2 forwarding |
| `multicast/` | Multicast configuration |
| `ipfix/` | IPFIX traffic monitoring |
| `cfm/` | CFM (Connectivity Fault Management) |
| `erps/` | ERPS ring protection |
| `bbf/` | BBF standard modules |
| `merged/` | Merged migration scripts |
| `default/` | Default migration scripts |
| `remove/` | Remove unsupported nodes |
| `framework/` | Framework base templates |
| `...` | Other functional domains |

### XSLT File Location

XSLT files should be saved to:
```
vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/{domain}/
```

### Example Paths

```
vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/qos/
vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/nacm/
vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/merged/
```

---

## Release Version Information

### Release Version Mapping

Each year has 4 releases, with the following version mapping:

| Release Format | File Name Mapping | Example |
|---------------|-------------------|---------|
| YY.3 | YYMM (M=3) | 26.3 → 2603 |
| YY.6 | YYMM (M=6) | 26.6 → 2606 |
| YY.9 | YYMM (M=9) | 26.9 → 2609 |
| YY.12 | YYMM (M=12) | 26.12 → 2612 |

### Upgrade Path Examples

| Source | Target | Description |
|--------|--------|-------------|
| 2603 | 2606 | 26.3 to 26.6 |
| 2606 | 2609 | 26.6 to 26.9 |
| 2609 | 2612 | 26.9 to 26.12 |
| 2612 | 2603 | 26.12 to next year's 26.3 |

---

## XSLT File Naming Reference

### Standard Naming Format

```
lsr{源版本}_to_lsr{目标版本}_{domain}_{改动标题}_{序号}.xsl
```

### Format Segments

| Segment | Description | Example |
|---------|-------------|---------|
| `lsr{源版本}_to_lsr{目标版本}` | Version upgrade path | `lsr2603_to_lsr2606` |
| `{domain}` | Domain name (repeated, same as directory) | `qos`, `nacm`, `ipfix` |
| `{改动标题}` | Brief description of the change | `delete_pass_case`, `update_max_queue_size` |
| `{序号}` | Sequence number (multiple xsl for same change) | `1`, `2`, `3` |

### Naming Examples

```
# Delete classifier pass case
lsr2603_to_lsr2606_qos_delete_pass_case_classifier_1.xsl

# Update max-queue-size
lsr2609_to_lsr2612_qos_update_max_queue_size_1.xsl

# Multiple files for same change
lsr2603_to_lsr2606_nacm_delete_rules_1.xsl
lsr2603_to_lsr2606_nacm_delete_rules_2.xsl
```

### Naming Rules

- Domain must match the target directory name (qos, nacm, ipfix, etc.)
- Change title uses snake_case format, briefly describing the core change
- Sequence number starts from 1, incrementing when the same change requires multiple XSL files

---

## Migration Script Execution

### Execution Order

XSLT scripts are **NOT executed in order**, so template rules should not depend on each other.

### If Dependencies Exist

1. First, try to decouple the rules
2. If cannot decouple, contact XSLT expert for assistance

---

## ConfD Configuration Management

### NETCONF Namespace

```xml
xmlns:cfg-ns="urn:ietf:params:xml:ns:netconf:base:1.0"
```

### Common Namespace Patterns

| Pattern | Namespace |
|---------|-----------|
| QoS | `urn:bbf:yang:bbf-qos-*` |
| L2 Forwarding | `urn:bbf:yang:bbf-l2-fwd:*` |
| NACM | `urn:ietf:params:xml:ns:netconf:aaa-nacm:1.0` |
| CFM | `urn:bbf:yang:bbf-cfm:*` |
| PON | `urn:bbf:yang:bbf-pon-types:*` |

---

## Common XPath Patterns

### Typical Device Configuration Path

```
/cfg-ns:config/{module}:{container}/{module}:{sub-container}/...
```

### Example: BAC Entry Path

```
/cfg-ns:config/bbf-qos-tm:tm-profiles/bbf-qos-tm:bac-entry
```

### Example: Classifier Entry Path

```
/cfg-ns:config/bbf-qos-cls:classifiers/bbf-qos-cls:classifier-entry
```

---

## Related Documents

- [Generator.md](Generator.md) - User workflow and interaction
- [Strategy.md](Strategy.md) - Input-to-XSLT transformation logic
