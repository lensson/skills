# Validation App Mode: Code Diff

This document defines the fixed format for displaying validation app code diffs when a user selects a changeset in Mode 3.

## Supported Validation Apps

| App Directory | Location |
|---------------|----------|
| `switch_validator_app` | `vobs/dsl/sw/y/build/apps/switch_validator_app/` |
| `xpon_validator_app` | `vobs/dsl/sw/y/build/apps/xpon_validator_app/` |
| `clock_validator_app` | `vobs/dsl/sw/y/build/apps/clock_validator_app/` |
| `switch_validator` | `vobs/dsl/sw/y/build/apps/switch_validator/` |
| `xpon_validator` | `vobs/dsl/sw/y/build/apps/xpon_validator/` |

---

## Code Diff Viewer - Fixed Output Format

### Header Section

```
============================================================
  Validation App Code Diff Viewer
============================================================

Changeset: <revision_number>
Node:       <full_40_char_node_hash>
Date:       <RFC822_date_format>
Author:     <author_name>
Description: <first_line_of_commit_message>

Modified Validation App Files (<count>):
------------------------------------------------------------
```

### Per-File Section

Each file is numbered sequentially [1], [2], [3]...:

#### C++ Rule Files

```
[<index>] <RuleName>.cpp
    Path: <app_dir>/rules/<Category>/<RuleName>.cpp
    App:  <app_name>
    Type: Validation Rule (C++)

    Changes: +<added_lines> / -<deleted_lines>

------------------------------------------------------------
<diff_output>
------------------------------------------------------------
```

#### JSON Configuration Files

```
[<index>] <config_file>.json
    Path: <app_dir>/<config_file>.json
    App:  <app_name>
    Type: Configuration (JSON)

    Changes: +<added_lines> / -<deleted_lines>

------------------------------------------------------------
<diff_output>
------------------------------------------------------------
```

### Summary Section

```
============================================================
  Summary
============================================================

Changeset:    <revision_number>
Node:         <full_node_hash>
Total Files:  <count> files
  - C++ Rule Files: <cpp_count>
  - JSON Configs:   <json_count>

Total Add:    +<total_added_lines> lines
Total Delete: -<total_deleted_lines> lines

============================================================
```

### Validation Rule Analysis Section

```
============================================================
  Validation Rule Analysis
============================================================

Modified C++ Rules:

[<index>] <RuleName>.cpp
    App:      <app_name>
    Category: <category>
    -> <analysis_hint_1>
    -> <analysis_hint_2>

[<index>] <RuleName>.cpp
    App:      <app_name>
    Category: <category>
    -> <analysis_hint>

Modified JSON Configs:

[<index>] <config_file>.json
    App:  <app_name>
    Type: <config_type>
    -> <analysis_hint>

============================================================
```

### File Selection Prompt

After displaying all diffs, prompt user for selection:

**When FILE_COUNT > 1:**
```
============================================================
  Select Validation App File for XSLT Generation
============================================================

Please select an option:

  1 - Analyze <RuleName>.cpp (<app_name>)
  2 - Analyze <RuleName>.cpp (<app_name>)
  3 - Analyze <config_file>.json (<app_name>)
  ...
  A - Analyze ALL <count> files
  B - Back to changeset list
  Q - Quit

Enter your choice:
```

**When FILE_COUNT == 1:**
```
============================================================
  Select Validation App File for XSLT Generation
============================================================

Please select an option:

  1 - Analyze <RuleName>.cpp (<app_name>)
  B - Back to changeset list
  Q - Quit

Enter your choice:
```

**When FILE_COUNT == 0:**
```
============================================================
  Validation App Code Diff Viewer
============================================================

Changeset: <revision_number>
Node:       <full_node_hash>
Date:       <RFC822_date_format>
Author:     <author_name>
Description: <description>

============================================================

No validation app file updated in changeset <revision>.

Back to last option...
```

Exit code: 3 (back to changeset list)

---

## Code Analysis Hints

The script analyzes diffs and generates hints based on content:

### C++ Rule Analysis

| Pattern Found | Analysis Hint |
|---------------|---------------|
| New rule class | New validation rule added - may need migration logic |
| Modified validate() | Rule logic changed - may affect config validation |
| New YANG path | New configuration path referenced |
| Removed rule | Rule removed - cleanup may be needed |
| Changed constraint | Validation constraint modified - may need XSLT |
| Added/removed includes | Dependency changes |

### JSON Config Analysis

| Pattern Found | Analysis Hint |
|---------------|---------------|
| ValidationRuleCategory | Rule category mapping changed |
| TranslatorStrategyCategory | Strategy mapping changed - affects XSLT generation |
| New rule in items[] | New rule registered - needs XSLT mapping |
| Removed rule from items[] | Rule removed from category |
| Changed strategy mapping | XSLT generation strategy changed |

---

## Example Output

### Single Rule File Example

```bash
============================================================
  Validation App Code Diff Viewer
============================================================

Changeset: 535200
Node:       a1b2c3d4e5f6789012345678901234567890abcd
Date:       Sat, 15 Jun 2024 14:30:00 +0800
Author:     zhenac
Description: BBN-123456 Add VsiMaxMacCountCheckRule validation

Modified Validation App Files (1):
------------------------------------------------------------

[1] VsiMaxMacCountCheckRule.cpp
    Path: switch_validator_app/rules/validator-l2fwd-common/VsiMaxMacCountCheckRule.cpp
    App:  switch_validator_app
    Type: Validation Rule (C++)

    Changes: +15 / -0

------------------------------------------------------------
@@ -0,0 +1,15 @@
+class VsiMaxMacCountCheckRule : public ValidationRule {
+public:
+    VsiMaxMacCountCheckRule() { ... }
+    bool validate(const Config& config) override {
+        // Check VSI max MAC count
+        ...
+    }
+};
------------------------------------------------------------

============================================================
  Summary
============================================================

Changeset:    535200
Node:         a1b2c3d4e5f6789012345678901234567890abcd
Total Files:  1 files
  - C++ Rule Files: 1
  - JSON Configs:   0

Total Add:    +15 lines
Total Delete: -0 lines

============================================================

  Validation Rule Analysis
============================================================

Modified C++ Rules:

[1] VsiMaxMacCountCheckRule.cpp
    App:      switch_validator_app
    Category: validator-l2fwd-common
    -> New validation rule added - may need migration logic
    -> New rule registered - needs XSLT mapping

============================================================

  Select Validation App File for XSLT Generation
============================================================

Please select an option:

  1 - Analyze VsiMaxMacCountCheckRule.cpp (switch_validator_app)
  B - Back to changeset list
  Q - Quit

Enter your choice:
```

### Multiple Files Example

```bash
============================================================
  Validation App Code Diff Viewer
============================================================

Changeset: 535205
Node:       b2c3d4e5f6a7890123456789012345678901bcde
Date:       Sun, 16 Jun 2024 10:15:00 +0800
Author:     zhenac
Description: BBN-123789 Update DualTagSharedFdbCheckRule and mapping

Modified Validation App Files (3):
------------------------------------------------------------

[1] DualTagSharedFdbCheckRule.cpp
    Path: switch_validator_app/rules/validator-l2fwd-fiber-pon/DualTagSharedFdbCheckRule.cpp
    App:  switch_validator_app
    Type: Validation Rule (C++)

    Changes: +12 / -3

------------------------------------------------------------
<diff_output for file 1>
------------------------------------------------------------

[2] FwderCheckVsiAddrSpoof.cpp
    Path: switch_validator_app/rules/validator-l2fwd-fiber/FwderCheckVsiAddrSpoof.cpp
    App:  switch_validator_app
    Type: Validation Rule (C++)

    Changes: +8 / -2

------------------------------------------------------------
<diff_output for file 2>
------------------------------------------------------------

[3] TranslatorStrategyCategory.json
    Path: switch_validator_app/TranslatorStrategyCategory.json
    App:  switch_validator_app
    Type: Configuration (JSON)

    Changes: +5 / -1

------------------------------------------------------------
<diff_output for file 3>
------------------------------------------------------------

============================================================
  Summary
============================================================

Changeset:    535205
Node:         b2c3d4e5f6a7890123456789012345678901bcde
Total Files:  3 files
  - C++ Rule Files: 2
  - JSON Configs:   1

Total Add:    +25 lines
Total Delete: -6 lines

============================================================

  Validation Rule Analysis
============================================================

Modified C++ Rules:

[1] DualTagSharedFdbCheckRule.cpp
    App:      switch_validator_app
    Category: validator-l2fwd-fiber-pon
    -> Rule logic changed - may affect config validation
    -> Validation constraint modified - may need XSLT

[2] FwderCheckVsiAddrSpoof.cpp
    App:      switch_validator_app
    Category: validator-l2fwd-fiber
    -> Rule logic changed - may affect config validation

Modified JSON Configs:

[3] TranslatorStrategyCategory.json
    App:  switch_validator_app
    Type: Strategy Mapping
    -> Strategy mapping changed - affects XSLT generation

============================================================

  Select Validation App File for XSLT Generation
============================================================

Please select an option:

  1 - Analyze DualTagSharedFdbCheckRule.cpp (switch_validator_app)
  2 - Analyze FwderCheckVsiAddrSpoof.cpp (switch_validator_app)
  3 - Analyze TranslatorStrategyCategory.json (switch_validator_app)
  A - Analyze ALL 3 files
  B - Back to changeset list
  Q - Quit

Enter your choice:
```

---

## Direct Changeset Input Interface

When user directly enters a changeset number (bypassing the ChangeList), display the same code diff format:

```
============================================================
  Validation App Code Diff Viewer
============================================================

Changeset Input: <user_entered_changeset>
Source: Direct input (not from ChangeList)

Changeset: <resolved_changeset>
Node:       <full_40_char_node_hash>
Date:       <RFC822_date_format>
Author:     <author_name>
Description: <first_line_of_commit_message>

Modified Validation App Files (<count>):
------------------------------------------------------------
```

**All subsequent sections (Per-File, Summary, Selection) remain the same as the standard Code Diff format.**

### Direct Input vs ChangeList Selection

| Source | Header Difference |
|--------|-------------------|
| From ChangeList | Shows "Changeset: #N" with clickable link |
| Direct Input | Shows "Changeset Input: <user_input>" then resolves to actual changeset |

---

## Multiple Changesets Display

When user selects multiple changesets (comma-separated like `1,2,3` or `A`), display each changeset sequentially:

### Multi-Changeset Header

```
============================================================
  Validation App Code Diff Viewer
============================================================

Selected Changesets:
  [1] 535200 - BBN-123456 Add VsiMaxMacCountCheckRule validation
  [2] 535195 - BBN-123789 Update DualTagSharedFdbCheckRule logic

Processing 2 changesets...
```

### Per-Changeset Section

For each changeset, display the full diff:

```
============================================================
  Changeset 1/2: 535200
============================================================

Changeset: 535200
Node:       a1b2c3d4e5f6789012345678901234567890abcd
Date:       Sat, 15 Jun 2024 14:30:00 +0800
Author:     zhenac
Description: BBN-123456 Add VsiMaxMacCountCheckRule validation

Modified Validation App Files (1):
------------------------------------------------------------

[1] VsiMaxMacCountCheckRule.cpp
    Path: switch_validator_app/rules/validator-l2fwd-common/VsiMaxMacCountCheckRule.cpp
    App:  switch_validator_app
    Type: Validation Rule (C++)

    Changes: +15 / -0

------------------------------------------------------------
@@ -0,0 +1,15 @@
+class VsiMaxMacCountCheckRule : public ValidationRule {
+    ...
+};
------------------------------------------------------------

============================================================
  Changeset 2/2: 535195
============================================================

Changeset: 535195
Node:       b2c3d4e5f6a7890123456789012345678901bcde
Date:       Sun, 16 Jun 2024 10:15:00 +0800
Author:     zhenac
Description: BBN-123789 Update DualTagSharedFdbCheckRule logic

Modified Validation App Files (1):
------------------------------------------------------------

[1] DualTagSharedFdbCheckRule.cpp
    Path: switch_validator_app/rules/validator-l2fwd-fiber-pon/DualTagSharedFdbCheckRule.cpp
    App:  switch_validator_app
    Type: Validation Rule (C++)

    Changes: +12 / -3

------------------------------------------------------------
<diff_output>
------------------------------------------------------------
```

### Multi-Changeset Summary

```
============================================================
  Summary (Multiple Changesets)
============================================================

Total Changesets: 2
Total Files: 2 files
  - C++ Rule Files: 2
  - JSON Configs:   0

Total Add:    +27 lines
Total Delete: -3 lines

Changesets:
  [1] 535200: VsiMaxMacCountCheckRule.cpp (+15)
  [2] 535195: DualTagSharedFdbCheckRule.cpp (+12/-3)

============================================================
```

### Multi-Changeset Selection Prompt

```
============================================================
  Select Validation App File for XSLT Generation
============================================================

Changeset 1 - VsiMaxMacCountCheckRule.cpp:
  1 - Analyze VsiMaxMacCountCheckRule.cpp (535200, switch_validator_app)

Changeset 2 - DualTagSharedFdbCheckRule.cpp:
  2 - Analyze DualTagSharedFdbCheckRule.cpp (535195, switch_validator_app)

  A - Analyze ALL files from ALL changesets
  B - Back to changeset list
  Q - Quit

Enter your choice:
```

---

## User Selection Options

### Single Changeset Mode

| Input | Action | Condition |
|-------|--------|-----------|
| `1`, `2`, `3`, ... | Select the specified file for XSLT generation | Always |
| `A` | Select ALL modified files for XSLT generation | Only when FILE_COUNT > 1 |
| `B` | Back to changeset list | Always |
| `Q` | Quit and return to main menu | Always |

### Multiple Changesets Mode

| Input | Action | Condition |
|-------|--------|-----------|
| `1`, `2`, `3`, ... | Select the file for XSLT generation | Always (uses changeset prefix if needed) |
| `A` | Select ALL files from ALL changesets | Always |
| `B` | Back to changeset list | Always |
| `Q` | Quit and return to main menu | Always |

---

## Exit Codes

### Single Changeset Mode

| Code | Meaning |
|------|---------|
| `0` | User selected a file or quit |
| `1` | Error (invalid input) |
| `2` | User selected "B" - back to changeset list |
| `3` | No validation app files in changeset - back to changeset list |

### Multiple Changesets Mode

| Code | Meaning |
|------|---------|
| `0` | User selected file(s) from any changeset or quit |
| `1` | Error (invalid input) |
| `2` | User selected "B" - back to changeset list |
| `3` | No validation app files in any changeset - back to changeset list |

---

## Selection Output

### Single Changeset Selection

```
---
SELECTED: <filepath>
CHANGESET: <revision>
NODE: <node_hash>
TYPE: <cpp_rule|json_config>
```

### Multiple Changesets Selection

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

### Specific File from Multiple Changesets

```
---
CHANGESET: <revision>
NODE: <node_hash>
SELECTED: <filepath>
TYPE: <cpp_rule|json_config>
FROM_MULTI: true
```

---

## Workflow Integration

### Standard Flow (Single Changeset)

```
┌─────────────────────────────────────────────────────────────┐
│                    Mode 3: Validation App                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│      ValidationAppMode_ChangeList.md                          │
│   (Displays 3 recent commits with validation app changes)       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│      User selects: 1                                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│      ValidationAppMode_CodeDiff.md                            │
│   (Single changeset code diff)                                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│      User selects: 1 or A                                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Next Step: Generator.md                           │
│   (Map rule → Translator Strategy → YANG Domain → XSLT)      │
└─────────────────────────────────────────────────────────────┘
```

### Multi-Changeset Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Mode 3: Validation App                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│      ValidationAppMode_ChangeList.md                          │
│   (Displays 3 recent commits with validation app changes)       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│      User selects: 1,2 or A (multiple/all)                    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│      ValidationAppMode_CodeDiff.md                            │
│   (Displays all selected changesets sequentially)             │
│                                                               │
│   =========================================================   │
│   Changeset 1/2: 535200                                        │
│   =========================================================   │
│   [1] VsiMaxMacCountCheckRule.cpp                            │
│                                                               │
│   =========================================================   │
│   Changeset 2/2: 535195                                        │
│   =========================================================   │
│   [2] DualTagSharedFdbCheckRule.cpp                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│      User selects: 1 or A                                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Next Step: Generator.md                           │
│   (Map rules from all changesets → YANG → XSLT)               │
└─────────────────────────────────────────────────────────────┘
```

### Direct Input Flow (Bypass ChangeList)

```
┌─────────────────────────────────────────────────────────────┐
│                    Mode 3: Validation App                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│      User directly enters changeset number: 535200           │
│      (Bypasses ValidationAppMode_ChangeList.md)              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│      ValidationAppMode_CodeDiff.md                            │
│   (Direct input mode - shows "Changeset Input: 535200")       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Next Step: Generator.md                           │
│   (Map rule → Translator Strategy → YANG Domain → XSLT)      │
└─────────────────────────────────────────────────────────────┘
```

---

## Script Usage

```bash
# Show validation app diff for a changeset
./scripts/validation_app_diff.sh 535200

# Show diff with full revision:node format
./scripts/validation_app_diff.sh 535200:a1b2c3d4e5f6

# Show diff using node hash only
./scripts/validation_app_diff.sh a1b2c3d4e5f6

# Scan specific validation app
./scripts/validation_app_diff.sh 535200 --app switch_validator_app

# Scan specific file type
./scripts/validation_app_diff.sh 535200 --type cpp
./scripts/validation_app_diff.sh 535200 --type json
```

---

## Related Documents

| Document | Purpose |
|----------|---------|
| [ValidationAppMode_ChangeList.md](ValidationAppMode_ChangeList.md) | Changeset selection interface |
| [ChooseMode.md](ChooseMode.md) | Mode selection interface |
| [Generator.md](Generator.md) | Mode 3 workflow integration |
| [Strategy.md](Strategy.md) | Translator Strategy → YANG Domain mapping |
| [Background.md](Background.md) | Framework reference and version info |
