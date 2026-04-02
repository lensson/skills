# Schema Change Mode: ChangeList

This mode displays recent YANG file changes from Mercurial commits.

## How It Works

1. The script queries Mercurial for recent YANG file changes by the current user
2. Displays up to 3 recent commits in a unified table format
3. Each commit shows:
   - Revision number, Node hash, Date, Description
   - All modified YANG files listed individually with their `+adds/-dels` diff stats
   - `├────┼...` separator between each changeset group

## Sample Output

```
=== Find Recent YANG Changes for User: zhenac ===

┌─────┬────────────┬──────────────┬──────────────────┬────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────────────────┐
│ #   │Changeset   │Node          │Date              │Description                                             │YANG Files                                                           │
├─────┼────────────┼──────────────┼──────────────────┼────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ 1   │ 535193     │ 439b05854851 │ 2023-01-12 12:49 │ BBN-122057 2303 Batch of Deviations and Migration Task │ nokia-bbf-qos-classifiers-qos-fiber-standalone-dev.yang|+7/-1       │
├─────┼────────────┼──────────────┼──────────────────┼────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ 2   │ 535192     │ 62cb1c78c375 │ 2023-01-12 09:53 │ BBN-122057 2303 Batch of Deviations and Migration Task │ nokia-bbf-qos-classifiers-qos-fiber-dev.yang|+7/-1                  │
│     │            │              │                  │                                                        │ nokia-bbf-qos-enhanced-filters-qos-fiber-p2p-dev.yang|+7/-1         │
│     │            │              │                  │                                                        │ nokia-bbf-qos-enhanced-filters-qos-fiber-standalone-dev.yang|+8/-1  │
│     │            │              │                  │                                                        │ nokia-bbf-qos-classifiers-qos-fiber-xpon-dev.yang|+7/-1             │
│     │            │              │                  │                                                        │ nokia-bbf-qos-enhanced-filters-qos-fiber-xpon-dev.yang|+7/-1        │
│     │            │              │                  │                                                        │ ... +2 more files                                                   │
├─────┼────────────┼──────────────┼──────────────────┼────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────┤
│ 3   │ 535191     │ 5c6071e3bbc5 │ 2023-01-11 22:10 │ BBN-122057 2303 Batch of Deviations and Migration Task │ nokia-bbf-qos-classifiers-qos-fiber-dev.yang|+0/-11                 │
│     │            │              │                  │                                                        │ nokia-bbf-qos-enhanced-filters-qos-fiber-p2p-dev.yang|+0/-10        │
│     │            │              │                  │                                                        │ nokia-bbf-qos-classifiers-qos-fiber-standalone-dev.yang|+11/-4      │
│     │            │              │                  │                                                        │ ... +3 more files                                                   │
└─────┴────────────┴──────────────┴──────────────────┴────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────────────────┘

Select option:
  1, 2, 3       - Select single or multiple (comma-separated) changesets
  4             - Input changeset(s) manually
  <changeset>   - Direct input (e.g., 518388)
  B             - Back to ChooseMode
  Q             - Quit and exit
```

## Key Features

- **Auto-detect user**: Queries `hg config ui.username` and falls back to Linux `$USER`
- **Smart filtering**: Only shows commits that modified YANG files
- **Per-file stats**: Shows each YANG file with its `+adds/-dels` diff statistics
- **Multi-file expansion**: Files listed per row, up to 3 visible with `... +N more files`
- **Commit separators**: `├────┼────┼...` separators between each changeset group
- **Dynamic column widths**: All columns auto-sized to content, border `┌┬┐` perfectly aligned with data `│`

## Workflow

1. User selects Mode 2 in ChooseMode
2. Script automatically runs `scripts/find-yang-changes.sh`
3. User selects a revision
4. Script shows full diff of YANG changes
5. User proceeds to XSLT generation
