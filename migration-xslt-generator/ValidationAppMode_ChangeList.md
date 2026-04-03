# Validation App Mode: ChangeList

>This document defines the user interface for Mode 3 (Validation Rule-Based Generation).
>Reference: [SKILL.md](SKILL.md) for skill overview, [ValidationAppMode_CodeDiff.md](ValidationAppMode_CodeDiff.md) for code diff format.

## Supported Validation Apps

| App Directory | Location |
|---------------|----------|
| `switch_validator_app` | `vobs/dsl/sw/y/build/apps/switch_validator_app/` |
| `xpon_validator_app` | `vobs/dsl/sw/y/build/apps/xpon_validator_app/` |
| `clock_validator_app` | `vobs/dsl/sw/y/build/apps/clock_validator_app/` |
| `switch_validator` | `vobs/dsl/sw/y/src/switch_validator/` |
| `xpon_validator` | `vobs/dsl/sw/y/src/xpon_validator/` |

---

## User Interface - ChangeList

### Script to Run

```bash
# Find validation app changes for current user (user-first logic)
scripts/find-validation-app-changes.sh

# Show validation app diff for a changeset
scripts/validation_app_diff.sh <changeset>
```

### Sample Output - ChangeList

```
=== Find Recent Validation App Changes for User: zhenac ===

(Showing 3 commits from recent commits)

┌─────┬────────────┬──────────────────┬─────────────────────────────────────────────────────────────────────────────────┬──────────────────────────────────────────────────────────────┐
│  #  │ Changeset  │ Date             │ Description                                                               │ Validation Files                                              │
├─────┼────────────┼──────────────────┼─────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│  1  │  698235    │  2026-03-19 09:47│ [BBN-353908]Adjust the rule to get the chip form cage entry. (you)   │ CSstBoardWorkModeStrategy.cpp                                  │
│     │            │                  │                                                                       │ CSstDimensionIntermediateSchedulerNodePerChipCheckRule.cpp      │
│     │            │                  │                                                                       │ CSwitchDebug.cpp                                                 │
│     │            │                  │                                                                       │ ... +5 more files                                                │
├─────┼────────────┼──────────────────┼─────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│  2  │  697562    │  2026-03-17 13:44│ [BBN-352898]Adjust TranslatorStrategyCategory.json. (cudi)        │ TranslatorStrategyCategory.json                                │
├─────┼────────────┼──────────────────┼─────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────┤
│  3  │  697552    │  2026-03-17 10:27│ [BBN-352898]Adjust TranslatorStrategyCategory.json. (cudi)        │ TranslatorStrategyCategory.json                                │
└─────┴────────────┴──────────────────┴─────────────────────────────────────────────────────────────────────────────────┴──────────────────────────────────────────────────────────────┘

Select option:
  1, 2, 3       - Select single or multiple (comma-separated) changesets
  A             - Select ALL shown changesets
  4             - Input changeset(s) manually
  <changeset>   - Direct input (e.g., 535200 or 683103:1f571642b132)
  B             - Back to ChooseMode
  Q             - Quit and exit

Enter your choice:
```

### Display Logic

- **User-first**: Shows current user's commits first (up to 3), then fills with others if needed
- **Source indicator**: Displays "(Showing N commits from your recent commits)" or "(Showing N commits from your recent + others)"
- **Files per line**: Each validation file appears on a separate line for readability

### Validation Files Column Format

- Shows file basenames only (full path not displayed)
- When more than 3 files exist, displays `... +N more files` at the end
- File entries are shown one per line for readability

---

## User Input Options

Select option:
  1, 2, 3       - Select single or multiple (comma-separated) changesets
  A             - Select ALL shown changesets
  4             - Input changeset(s) manually
  <changeset>   - Direct input (e.g., 535200 or 683103:1f571642b132)
  B             - Back to ChooseMode
  Q             - Quit and exit

### Option 4: Manual Changeset Input

When user enters `4`, display [ValidationAppMode_InputChangeset.md](ValidationAppMode_InputChangeset.md):

```
┌────────────────────────────────────────────────────────────────────────┐
│           Manual Input: Validation App Changeset                       │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  Current reference (your last validation app modification):           │
│    - Revision: 518388                                                 │
│    - Changeset: 0ea50a483b99                                         │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  Supported input formats:                                             │
│    - Changeset number: 535200                                         │
│    - Node hash: 439b05854851 or 439b058                               │
│                                                                        │
│  Enter changeset number or node hash:                                 │
│    _                                                                  │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│  Options: [B] Back to change list | [Q] Quit                          │
└────────────────────────────────────────────────────────────────────────┘
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
│        User-first logic: user's commits shown first, then others          │
│                                                                             │
│        ┌─────┬────────────┬─────────────────┬───────────────────────┐     │
│        │  #  │ Changeset  │ Date            │ Description            │     │
│        ├─────┼────────────┼─────────────────┼───────────────────────┤     │
│        │  1  │  698235    │  2026-03-19... │ [BBN-353908]... (cudi)│     │
│        │  2  │  697562    │  2026-03-17... │ [BBN-352898]... (you)│     │
│        │  3  │  697552    │  2026-03-17... │ [BBN-352898]... (you)│     │
│        └─────┴────────────┴─────────────────┴───────────────────────┘     │
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
│                      Confirm XSLT Generation                                │
│                                                                             │
│    ================================================================        │
│      Validation App Changes Detected                                      │
│    ================================================================        │
│                                                                             │
│    Select option:                                                          │
│      G             - Generate XSLT migration script                         │
│      V             - View code diff again                                   │
│      B             - Back to changeset selection                           │
│      Q             - Quit and exit                                          │
└─────────────────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
       [G]                 [V]                 [B/Q]
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

## Direct Changeset Input

When user directly enters a changeset (e.g., `683103:1f571642b132` or `683103`):

1. Display code diff directly
2. Show confirmation prompt
3. If confirmed, proceed to Generator.md

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
