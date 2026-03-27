# Schema Change Mode: ChangeList

This mode is used when you have YANG file changes from a specific revision.

## How It Works

1. The script queries Mercurial for recent YANG file changes by the current user
2. Displays up to 3 recent commits in a table format
3. Each commit shows:
   - Revision number
   - Node hash
   - Date
   - Description
   - Modified YANG files (basename + lines added/removed)
   - Total statistics

## Sample Output

```bash
=== Find Recent YANG Changes for User: zhenac ===

| # | Changeset | Node | Date | Description | YANG Files | Diff |
|---|----------|------|------|-------------|------------|-------|
| 1 | 535193 | 439b05854851 | 2023-01-12 12:49 | BBN-122057 2303 Batch of Deviations and Migration Task | +7 nokia-bbf-qos-classifiers-qos-fiber-standalone-dev.yang | [1 YANG +7 lines](?diff=535193) |
| 2 | 535192 | 62cb1c78c375 | 2023-01-12 09:53 | BBN-122057 2303 Batch of Deviations and Migration Task | +7 nokia-bbf-qos-enhanced-filters-qos-fiber-p2p-dev.yang<br>+8 nokia-bbf-qos-enhanced-filters-qos-fiber-standalone-dev.yang<br>+7 nokia-bbf-qos-classifiers-qos-fiber-xpon-dev.yang<br>... | [5 YANG +22 lines](?diff=535192) |
| 3 | 535191 | 5c6071e3bbc5 | 2023-01-11 22:10 | BBN-122057 2303 Batch of Deviations and Migration Task | +0 nokia-bbf-qos-enhanced-filters-qos-fiber-p2p-dev.yang<br>+11 nokia-bbf-qos-classifiers-qos-fiber-standalone-dev.yang<br>+0 nokia-bbf-qos-enhanced-filters-qos-fiber-standalone-dev.yang | [6 YANG +11 lines](?diff=535191) |

---
Enter number to view diff (1, 2, 3), or 4 to input revision manually:
```

## User Options

| Option | Description |
|--------|-------------|
| `1`, `2`, `3` | Click the **Diff** link to view full hg diff for that changeset |
| `4` | Manually input a different changeset/revision number |
| `q` | Quit and return to main menu |

## Key Features

- **Auto-detect user**: Queries `hg config ui.username` and falls back to Linux `$USER`
- **Smart filtering**: Only shows commits that modified YANG files
- **Line statistics**: Shows `+N` for each modified YANG file
- **Multiple files**: If a commit has more than 3 YANG files, shows first 3 with total count

## Workflow

1. User runs the skill
2. Script displays recent YANG changes
3. User selects a revision
4. Script shows full diff of YANG changes
5. User proceeds to XSLT generation
