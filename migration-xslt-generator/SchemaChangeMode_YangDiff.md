# Schema Change Mode: YANG Diff

This document defines the fixed format for displaying YANG file diffs when a user selects a changeset in Mode 2.

## YANG Diff Viewer - Fixed Output Format

### Header Section

```
============================================================
  YANG Diff Viewer
============================================================

Changeset: <revision_number>
Node:       <full_40_char_node_hash>
Date:       <RFC822_date_format>
Author:     <author_name>
Description: <first_line_of_commit_message>

Modified YANG Files (<count>):
------------------------------------------------------------
```

### Per-File Section

Each YANG file is numbered sequentially [1], [2], [3]...:

```
[<index>] <filename>.yang
    Path: <full_relative_path>

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
YANG Files:   <count> files
Total Add:    +<total_added_lines> lines
Total Delete: -<total_deleted_lines> lines

============================================================
```

### Migration Analysis Section

```
============================================================
  Migration Analysis
============================================================

[<index>] <filename>.yang
  -> <migration_hint_1>
  -> <migration_hint_2>
  ...

[<index>] <filename>.yang
  -> <migration_hint>
  ...

============================================================
```

### File Selection Prompt

After displaying all diffs, prompt user for selection:

**When YANG_COUNT > 1:**
```
============================================================
  Select YANG File for XSLT Generation
============================================================

Please select an option:

  1 - Generate XSLT for <filename>.yang
  2 - Generate XSLT for <filename>.yang
  ...
  A - Generate XSLT for ALL <count> YANG files
  B - Back to changeset list
  Q - Quit

Enter your choice:
```

**When YANG_COUNT == 1:**
```
============================================================
  Select YANG File for XSLT Generation
============================================================

Please select an option:

  1 - Generate XSLT for <filename>.yang
  B - Back to changeset list
  Q - Quit

Enter your choice:
```

**When YANG_COUNT == 0:**
```
============================================================
  YANG Diff Viewer
============================================================

Changeset: <revision_number>
Node:       <full_node_hash>
Date:       <RFC822_date_format>
Author:     <author_name>
Description: <description>

============================================================

No YANG file updated in changeset <revision>.

Back to last option...
```

Exit code: 3 (back to changeset list)

## Migration Hints Detection

The script analyzes diffs and generates hints based on content:

| Pattern Found | Migration Hint |
|---------------|----------------|
| `deviate add` | May require data transformation for new constraints |
| `deviate delete` | May require removing old data structures |
| `deviate replace` | May require type/structure conversion |
| `revision` | Schema versioning detected |
| `must ` | New validation rules added |
| `leaf` | Field-level modifications |
| `container` | Structure modifications |
| `list ` | List structure modifications |
| `identity` | New identity definitions added |
| `typedef` | Type definitions modified |

## Example Output

### Single File Example

```bash
============================================================
  YANG Diff Viewer
============================================================

Changeset: 599970
Node:       6af21798fe1482e0e82e9b6b90a8d0c1e2f3d4a5
Date:       Sat, 15 Jun 2024 11:05:24 +0800
Author:     zhenac
Description: BBN-123456 Add deviation for max-queue-size validation

Modified YANG Files (1):
------------------------------------------------------------

[1] nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang
    Path: vobs/dsl/yang/deviations/qos-fiber/nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang

    Changes: +15 / -0

------------------------------------------------------------
<diff_output>
------------------------------------------------------------

============================================================
  Summary
============================================================

Changeset:    599970
Node:         6af21798fe1482e0e82e9b6b90a8d0c1e2f3d4a5
YANG Files:   1 files
Total Add:    +15 lines
Total Delete: -0 lines

============================================================

  Migration Analysis
============================================================

[1] nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang
  -> Contains new revision: Schema versioning detected
  -> Contains 'deviate add': May require data transformation for new constraints
  -> Contains 'must' constraint: New validation rules added

============================================================

  Select YANG File for XSLT Generation
============================================================

Please select an option:

  1 - Generate XSLT for nokia-bbf-qos-traffic-mngt-qos-fiber-dev.yang
  B - Back to changeset list
  Q - Quit

Enter your choice:
```

### Multi-File Example

```bash
============================================================
  YANG Diff Viewer
============================================================

Changeset: 535192
Node:       62cb1c78c3759a1b2c3d4e5f6a7b8c9d0e1f2a3b
Date:       Thu, 12 Jan 2023 09:53:00 +0800
Author:     zhenac
Description: BBN-122057 2303 Batch of Deviations and Migration Task

Modified YANG Files (3):
------------------------------------------------------------

[1] nokia-bbf-qos-enhanced-filters-qos-fiber-p2p-dev.yang
    Path: vobs/dsl/yang/deviations/qos-fiber/nokia-bbf-qos-enhanced-filters-qos-fiber-p2p-dev.yang

    Changes: +8 / -0

------------------------------------------------------------
<diff_output for file 1>
------------------------------------------------------------

[2] nokia-bbf-qos-enhanced-filters-qos-fiber-standalone-dev.yang
    Path: vobs/dsl/yang/deviations/qos-fiber/nokia-bbf-qos-enhanced-filters-qos-fiber-standalone-dev.yang

    Changes: +12 / -3

------------------------------------------------------------
<diff_output for file 2>
------------------------------------------------------------

[3] nokia-bbf-qos-classifiers-qos-fiber-xpon-dev.yang
    Path: vobs/dsl/yang/deviations/qos-fiber/nokia-bbf-qos-classifiers-qos-fiber-xpon-dev.yang

    Changes: +7 / -0

------------------------------------------------------------
<diff_output for file 3>
------------------------------------------------------------

============================================================
  Summary
============================================================

Changeset:    535192
Node:         62cb1c78c3759a1b2c3d4e5f6a7b8c9d0e1f2a3b
YANG Files:   3 files
Total Add:    +27 lines
Total Delete: -3 lines

============================================================

  Migration Analysis
============================================================

[1] nokia-bbf-qos-enhanced-filters-qos-fiber-p2p-dev.yang
  -> Contains 'deviate add': May require data transformation for new constraints
  -> Contains 'leaf' changes: Field-level modifications

[2] nokia-bbf-qos-enhanced-filters-qos-fiber-standalone-dev.yang
  -> Contains 'deviate replace': May require type/structure conversion
  -> Contains 'deviate delete': May require removing old data structures

[3] nokia-bbf-qos-classifiers-qos-fiber-xpon-dev.yang
  -> Contains 'deviate add': May require data transformation for new constraints

============================================================

  Select YANG File for XSLT Generation
============================================================

Please select an option:

  1 - Generate XSLT for nokia-bbf-qos-enhanced-filters-qos-fiber-p2p-dev.yang
  2 - Generate XSLT for nokia-bbf-qos-enhanced-filters-qos-fiber-standalone-dev.yang
  3 - Generate XSLT for nokia-bbf-qos-classifiers-qos-fiber-xpon-dev.yang
  A - Generate XSLT for ALL 3 YANG files
  B - Back to changeset list
  Q - Quit

Enter your choice:
```

### No YANG Files Example

```bash
============================================================
  YANG Diff Viewer
============================================================

Changeset: 535190
Node:       a1b2c3d4e5f6...
Date:       Thu, 12 Jan 2023 09:30:00 +0800
Author:     otherdev
Description: Fix typo in README file

============================================================

No YANG file updated in changeset 535190.

Back to last option...
```

## User Selection Options

| Input | Action | Condition |
|-------|--------|-----------|
| `1`, `2`, `3`, ... | Select the specified YANG file for XSLT generation | Always |
| `A` | Select ALL modified YANG files for XSLT generation | Only when YANG_COUNT > 1 |
| `B` | Back to changeset list (SchemaChangeMode_ChangeList.md) | Always |
| `Q` | Quit and return to main menu (ChooseMode.md) | Always |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | User selected a file or quit |
| `1` | Error (invalid input) |
| `2` | User selected "B" - back to changeset list |
| `3` | No YANG files in changeset - back to changeset list |

## Selection Output

After user makes a selection, the script outputs:

```
---
SELECTED: <filepath>
CHANGESET: <revision>
NODE: <node_hash>
```

Or for ALL:

```
---
SELECTED: ALL
CHANGESET: <revision>
NODE: <node_hash>
FILE_COUNT: <count>
FILE_1: <filepath>
FILE_2: <filepath>
FILE_3: <filepath>
```

## Workflow Integration

```
┌─────────────────────────────────────────────────────────────┐
│                    Mode 2: Schema Change                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│         SchemaChangeMode_ChangeList.md                       │
│    (Displays 3 recent commits with YANG changes)             │
└─────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
            ▼                 ▼                 ▼
         [1]               [2]               [3]
      (Commit 1)        (Commit 2)        (Commit 3)
            │                 │                 │
            │                 │                 │
            └─────────────────┼─────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│         SchemaChangeMode_InputChangeset.md                   │
│    (User inputs: 599970:6af21798fe14)                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 scripts/yang_diff.sh                         │
│    (Shows YANG diff with numbered files)                     │
│                                                             │
│    [1] file1.yang                                           │
│    [2] file2.yang                                           │
│    [3] file3.yang                                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│        User Selection Prompt (in yang_diff.sh)               │
│                                                             │
│    If 1 file:                                               │
│      1 - Generate XSLT for file1.yang                      │
│      (No "A" option - only one file)                        │
│      B - Back to changeset list                             │
│      Q - Quit                                               │
│                                                             │
│    If multiple files:                                       │
│      1 - Generate XSLT for file1.yang                       │
│      2 - Generate XSLT for file2.yang                       │
│      A - Generate XSLT for ALL files                        │
│      B - Back to changeset list                             │
│      Q - Quit                                               │
│                                                             │
│    If no YANG files:                                        │
│      No YANG file updated in changeset.                     │
│      Back to last option...                                  │
│      (exit code 3)                                          │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌──────────┬──────────┼──────────┐
        │          │          │          │
        ▼          ▼          ▼          ▼
       [1]        [2]        [3]        [A]
        │          │          │          │
        │          │          │          │
        ▼          ▼          ▼          ▼
┌─────────────────────────────────────────────────────────────┐
│              Next Step: XSLT Generation                      │
│    (Based on SchemaChangeMode_XsltGeneration.md)             │
└─────────────────────────────────────────────────────────────┘
```

## Script Usage

```bash
# Show YANG diff for a changeset
./scripts/yang_diff.sh 599970

# Show YANG diff with full revision:node format
./scripts/yang_diff.sh 599970:6af21798fe14

# Show YANG diff using node hash only
./scripts/yang_diff.sh 6af21798fe14
```
