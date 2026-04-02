# Mode 3.4: Manual Input Changeset

>This mode allows you to manually input a specific changeset or revision hash that contains validation app changes.

## How It Works

1. Displays your most recent validation app modification reference
2. Allows you to input a different changeset or revision
3. Supports both changeset number and full node hash

## Input Format

```
+------------------------------------------------------------+
|           Manual Input: Validation App Changeset            |
+------------------------------------------------------------+
|                                                            |
|  Current reference (your last validation app modification): |
|    - Revision: ${last_revision}                             |
|    - Changeset: ${last_changeset}                          |
|    - Node: ${last_node}                                    |
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
```

## Supported Input Types

| Input Type | Example | Description |
|------------|---------|-------------|
| Changeset number | `535200` | Mercurial revision number |
| Node hash (full) | `439b05854851...` | Full 12+ character node hash |
| Node hash (short) | `439b058` | Short hash (at least 7 characters) |
| Changeset:Node | `535200:439b05854851` | Combined format |

## User Options

| Option | Description |
|--------|-------------|
| Enter changeset number | Input like `535200` |
| Enter node hash | Input like `439b05854851` or `439b058` |
| `b` | Back to change list |
| `q` | Quit and return to main menu |

## Workflow

```
+----------------------------------------------------------+
|                    Change List (Mode 3)                   |
|                                                            |
|  [4] - Input changeset(s) manually                         |
|                                                            |
+----------------------------------------------------------+
                           │
                           ▼
+----------------------------------------------------------+
|           ValidationAppMode_InputChangeset.md              |
|                                                            |
|  User enters changeset: 535200                             |
|                                                            |
+----------------------------------------------------------+
                           │
                           ▼
+----------------------------------------------------------+
|              ValidationAppMode_CodeDiff.md                |
|                                                            |
|  Display code diff for changeset 535200                   |
|                                                            |
+----------------------------------------------------------+
```

## Validation

- Changeset must exist in repository
- Node hash must be valid and exist
- Must contain validation app files
- Will show error message if input is invalid

## Error Messages

```
+------------------------------------------------------------+
|                     Error: Invalid Input                    |
+------------------------------------------------------------+
|                                                            |
|  Changeset "535200" not found.                              |
|                                                            |
|  Please enter a valid changeset number or node hash.        |
|                                                            |
+------------------------------------------------------------+
|  Press any key to continue...                               |
+------------------------------------------------------------+
```

```
+------------------------------------------------------------+
|                     Error: No Validation Files               |
+------------------------------------------------------------+
|                                                            |
|  Changeset "535200" does not contain any validation app     |
|  files.                                                     |
|                                                            |
|  This mode only supports changesets that modify files in:  |
|    - switch_validator_app                                  |
|    - xpon_validator_app                                     |
|    - clock_validator_app                                   |
|                                                            |
+------------------------------------------------------------+
|  Press any key to continue...                               |
+------------------------------------------------------------+
```
