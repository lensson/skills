# Validation App Mode: ChangeList

>This document defines the user interface for Mode 3 (Validation Rule-Based Generation).
>Reference: [SKILL.md](SKILL.md) for skill overview, [ValidationAppMode_CodeDiff.md](ValidationAppMode_CodeDiff.md) for code diff format.

## Supported Validation Apps

| App Directory | Location |
|---------------|----------|
| `switch_validator_app` | `vobs/dsl/sw/y/build/apps/switch_validator_app/` |
| `xpon_validator_app` | `vobs/dsl/sw/y/build/apps/xpon_validator_app/` |
| `clock_validator_app` | `vobs/dsl/sw/y/build/apps/clock_validator_app/` |
| `switch_validator` | `vobs/dsl/sw/y/build/apps/switch_validator/` |
| `xpon_validator` | `vobs/dsl/sw/y/build/apps/xpon_validator/` |

---

## User Interface - ChangeList

### Script to Run

```bash
# Find validation app changes for current user
scripts/find-validation-app-changes.sh

# Show validation app diff for a changeset
scripts/validation_app_diff.sh <changeset>
```

### Sample Output - ChangeList

```bash
=== Find Recent Validation App Changes for User: zhenac ===

+----+-------------+-------------+--------------------+---------------------------------------------------------------------------+------------------+
| #  | Changeset   | Node        | Date               | Description                                                               | Validation Files |
+----+-------------+-------------+--------------------+---------------------------------------------------------------------------+------------------+
| 1  | 535200      | a1b2c3d4e5f | 2023-01-15 14:30   | BBN-123456 Add VsiMaxMacCountCheckRule validation                       | 2 files         |
+----+-------------+-------------+--------------------+---------------------------------------------------------------------------+------------------+
| 2  | 535195      | b2c3d4e5f6a | 2023-01-14 10:15   | BBN-123789 Update DualTagSharedFdbCheckRule logic                       | 1 files         |
+----+-------------+-------------+--------------------+---------------------------------------------------------------------------+------------------+
| 3  | 535190      | c3d4e5f6a1b | 2023-01-13 16:45   | BBN-123456 Add ForwarderStrategy translator                            | 3 files; ...    |
+----+-------------+-------------+--------------------+---------------------------------------------------------------------------+------------------+

+-------------------------------------------+
| Select option:                           |
|   1, 2, 3          - Select changeset(s) |
|   1,2              - Select multiple       |
|   4                - Input changeset(s)  |
|   <changeset>      - Direct input         |
|   Q                - Quit and return to   |
|                      main menu            |
+-------------------------------------------+

Enter your choice:
```

### Validation Files Column Format

- Shows file count (e.g., `2 files`, `3 files`)
- When more than 3 files exist, displays `...` at the end
- File details shown inline: `+15/-3 VsiMaxMacCountCheckRule.cpp` (additions/deletions)

---

## User Input Options

| Option | Description | Example |
|--------|-------------|---------|
| `1`, `2`, `3` | Select one changeset to view code diff | `1` |
| `1,2`, `2,3` | Select multiple changesets (comma-separated) | `1,2,3` |
| `4` | Manually input changeset(s) | See Option 4 below |
| Direct input | Enter changeset number directly | `535200` |
| `Q` | Quit and return to main menu | - |

### Option 4: Manual Changeset Input

When user enters `4`, display [ValidationAppMode_InputChangeset.md](ValidationAppMode_InputChangeset.md):

```
+------------------------------------------------------------+
|           Manual Input: Validation App Changeset            |
+------------------------------------------------------------+
|                                                            |
|  Current reference (your last validation app modification): |
|    - Revision: 518388                                      |
|    - Changeset: 0ea50a483b99                              |
|                                                            |
+------------------------------------------------------------+
|                                                            |
|  Supported input formats:                                   |
|    - Changeset number: 535200                               |
|    - Node hash: 439b05854851 or 439b058                      |
|                                                            |
|  Enter changeset number or node hash:                       |
|    _                                                       |
|                                                            |
+------------------------------------------------------------+

Options: [B] Back to change list | [Q] Quit
```

---

## Workflow Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      Mode 3: Validation App Mode                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   ValidationAppMode_ChangeList.md                          │
│        (Displays up to 3 recent commits in validation apps)               │
│                                                                             │
│        +----+-------------+-------------+--------------------+            │
│        | #  | Changeset   | Date        | Description        |            │
│        +----+-------------+-------------+--------------------+            │
│        | 1  | 535200      | ...         | BBN-123456         |            │
│        | 2  | 535195      | ...         | BBN-123789         |            │
│        | 3  | 535190      | ...         | BBN-123456         |            │
│        +----+-------------+-------------+--------------------+            │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
              ┌─────────────────────┼─────────────────────┐
              │                     │                     │
              ▼                     ▼                     ▼
           [1], [2], [3]           [4]              Direct input
              │                     │                     │
              │         ┌───────────┴───────────┐        │
              │         ▼                       ▼        │
              │   Enter changeset manually   Cancel     │
              │         │                                   │
              └────►Display Code Diff◄────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                   ValidationAppMode_CodeDiff.md                             │
│         (Displays code diff with numbered files)                          │
│                                                                             │
│    [1] VsiMaxMacCountCheckRule.cpp      (switch_validator_app)            │
│    [2] TranslatorStrategyCategory.json  (switch_validator_app)            │
└─────────────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      User Selection Prompt                                │
│                                                                             │
│    1 - Analyze VsiMaxMacCountCheckRule.cpp                                │
│    2 - Analyze TranslatorStrategyCategory.json                            │
│    B - Back to changeset list                                             │
│    Q - Quit                                                                │
└─────────────────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
       [1]                 [2]                 [Q]
        │                   │                   │
        │                   │                   │
        ▼                   ▼                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                Proceed to Generator.md (XSLT Generation)                   │
│                                                                             │
│  1. Map Code Diff → YANG Schema (TranslatorStrategyCategory.json)        │
│  2. Read YANG Schema files                                                │
│  3. Analyze changes                                                       │
│  4. Generate XSLT                                                        │
│  5. User Feedback Loop                                                    │
│  6. Save to Domain Directory                                              │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Code Diff to YANG Schema Mapping

When user selects file(s) and proceeds, the system maps the validation rules to YANG schemas:

### Mapping Flow

```
Validation App Code (C++/JSON)
         │
         ▼
┌─────────────────────────┐
│ TranslatorStrategyCategory.json │
│   RuleName → Strategy   │
└─────────────────────────┘
         │
         ▼
┌─────────────────────────┐
│ Strategy → YANG Domain   │
│ (from Strategy.md)      │
└─────────────────────────┘
         │
         ▼
┌─────────────────────────┐
│ YANG Domain → YANG Files│
│ (from Background.md)    │
└─────────────────────────┘
```

### Strategy → YANG Domain Mapping

| Translator Strategy | YANG Domain | Example YANG Paths |
|---------------------|-------------|--------------------|
| `ForwarderStrategy` | `l2forwarding` | `/bbf-l2-fwd:forwarding/...` |
| `ForwardingDatabaseStrategy` | `l2forwarding` | `/bbf-l2-fwd:forwarding/forwarding-database` |
| `VlanSubInterfaceStrategy` | `l2forwarding` | `/bbf-l2-fwd:forwarding/vlan-sub-interfaces` |
| `FloodProfileStrategy` | `l2forwarding` | `/bbf-l2-fwd:forwarding/flood-profiles` |
| `QoSClassifierStrategy` | `qos` | `/bbf-qos-cls:classifiers/...` |
| `QoSPolicyStrategy` | `qos` | `/bbf-qos-pol:policies/...` |
| `QoSPoliceStrategy` | `qos` | `/bbf-qos-tm:tm-profiles/...` |
| `PonStrategy` | `pon` | `/bbf-pon-types:onus/...` |
| `ClockStrategy` | `clock` | (domain-specific) |
| (Other) | infer from context | - |

---

## Code Diff → YANG Schema Mapping Output

When proceeding to Generator.md, display the mapping results:

```
============================================================
  Code Diff to YANG Schema Mapping
============================================================

Selected Files:
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

Proceeding to XSLT Generation...
```

---

## Related Documents

| Document | Purpose |
|----------|---------|
| [SKILL.md](SKILL.md) | Skill overview and quick reference |
| [ChooseMode.md](ChooseMode.md) | Mode selection interface |
| [ValidationAppMode_InputChangeset.md](ValidationAppMode_InputChangeset.md) | Manual changeset input interface |
| [ValidationAppMode_CodeDiff.md](ValidationAppMode_CodeDiff.md) | Code diff viewer format |
| [Generator.md](Generator.md) | XSLT generation workflow |
| [Strategy.md](Strategy.md) | Transformation logic and patterns |
| [Background.md](Background.md) | Framework reference and version info |
