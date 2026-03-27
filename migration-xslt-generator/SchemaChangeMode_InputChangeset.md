# Mode 2.4: Manual Input Changeset/Revision

This mode allows you to manually input a specific changeset or revision hash that contains YANG file changes.

## How It Works

1. Displays your most recent YANG modification reference
2. Allows you to input a different changeset or revision
3. Supports both changeset number and full node hash

## Input Format

```
=== Manual Input: Changeset/Revision ===

Current reference (your last YANG modification):
- Revision: ${last_revision}
- Changeset: ${last_changeset}

Please enter the changeset number or revision hash:
```

## Supported Input Types

| Input Type | Example | Description |
|------------|---------|-------------|
| Changeset number | `535193` | Mercurial revision number |
| Node hash (full) | `439b05854851...` | Full 12+ character node hash |
| Node hash (short) | `439b058` | Short hash (at least 7 characters) |

## User Options

| Option | Description |
|--------|-------------|
| Enter changeset number | Input like `535193` |
| Enter node hash | Input like `439b05854851` or `439b058` |
| `b` | Back to change list |
| `q` | Quit and return to main menu |

## Workflow

1. User selects option `4` from change list
2. Display this manual input interface
3. User enters changeset or revision
4. System validates the input
5. Proceed to YANG diff extraction

## Validation

- Changeset must exist in repository
- Node hash must be valid and exist
- Will show error message if input is invalid
