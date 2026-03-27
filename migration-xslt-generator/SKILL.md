---
name: migration-xslt-generator
description: Automatically generate XSLT migration scripts for Lightspan release upgrades, transforming ConfD configuration data. Use when creating XSLT migration files, upgrading board versions (e.g., LLLT-A from 26.3 to 26.6), or when YANG files are modified.
---

# Migration XSLT Generator

Generate XSLT migration scripts for Lightspan release upgrades to transform ConfD configuration data.

## Quick Start - Choose Mode

See [ChooseMode.md](ChooseMode.md) for the interactive mode selection interface.

When user selects Mode 2:
1. **Display interface**: Show [SchemaChangeMode_ChangeList.md](SchemaChangeMode_ChangeList.md) as the user interface template
   - Table shows up to 3 recent commits with YANG file changes by current user
   - Column 4 is reserved for manual changeset input
2. **Run script**: `scripts/find-yang-changes.sh`
   - Script auto-detects current user from `hg config ui.username`
   - Falls back to Linux `USER` env var if not set
3. **Show results**: Table format with columns:
   - `#` - Option number (1, 2, 3 for commits, 4 for manual)
   - `Changeset` - Mercurial revision number
   - `Node` - Commit node hash
   - `Date` - Commit date
   - `Description` - Commit message
   - `YANG Files` - First 3 modified YANG files with `+N` line stats, `...` if more than 3
   - `Diff` - Clickable link showing "N YANG +M lines", opens full hg diff when clicked
4. **User selects**: Click Diff link to view full changeset diff, or input number 1/2/3/4
5. **Mode 2.4**: When user inputs `4`, display [SchemaChangeMode_InputChangeset.md](SchemaChangeMode_InputChangeset.md)
   - Shows current reference (last revision/changeset from previous selection)
   - Prompts user to input a changeset number or revision hash
   - Supports changeset numbers (e.g., `535193`), full node hash, or short hash
   - Options: `b` to back to change list, `q` to quit
6. **Extract diff**: When user selects 1/2/3 or enters a changeset in Mode 2.4, run `scripts/yang_diff.sh`
   - See [SchemaChangeMode_YangDiff.md](SchemaChangeMode_YangDiff.md) for output format specification
   - Displays formatted diff with migration analysis hints
   - Supports multiple input formats: revision number, `rev:node`, or node hash
7. **Generate XSLT**: When user selects a YANG file from the diff, follow [SchemaChangeMode_XSLTGenerator.md](SchemaChangeMode_XSLTGenerator.md)
   - Step 1: Read related YANG schema files (IACM and deviation files)
   - Step 2: Analyze the YANG changes in context
   - Step 3: Decision - Generate XSLT or explain why not needed
   - Step 4: Display XSLT or no-XSLT reason
   - Return options: Back to diff view or Quit

---

## Workspace Structure

- **YANG schema**: `vobs/dsl/yang/`
- **XSLT scripts**: `vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/`
- **Merged scripts**: `vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/merged/`
- **Domain scripts**: `vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/<domain>/`

## Two Generation Modes

### Mode 1: Intent-Based Generation

Use when user provides:
- Migration intent (what changes are needed)
- Input XML (before migration)
- Output XML (expected after migration)

**Process:**

1. Analyze the differences between input and output XML
2. Identify transformation patterns:
   - Node renames
   - Field additions/removals
   - Type changes
   - Structural changes (list to leaf-list, etc.)
3. Generate appropriate XSLT template from patterns
4. Validate the generated XSLT against input/output examples

### Mode 2: YANG Change-Based Generation

Use when YANG files have been modified between releases.

**Process:**

1. Identify the YANG changes (additions, deletions, modifications)
2. Map YANG changes to required XSLT transformations:
   - New optional nodes → copy unchanged, no action needed
   - Removed nodes → add template to remove them
   - Type changes → add conversion logic
   - Mandatory status changes → handle defaults
3. Generate XSLT for each affected YANG file
4. Create merged XSLT if multiple domain-specific scripts exist

## XSLT Framework

### Framework Reference

See [Background.md](Background.md) for detailed XSLT framework reference including:
- XSLT file organization principles
- Naming conventions
- Standard template structure
- Common transformation patterns
- Optimization guidelines

**Key framework files:**
- `framework/identity-utils.xsl` - Identity and type utilities
- `framework/node-operations.xsl` - Node manipulation templates
- `framework/type-converters.xsl` - Type conversion functions

### Standard Template Structure

```xslt
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:confd="http://www.tail-f.com/ns/confd/1.0">

    <!-- Description -->
    <xsl:comment>
        YANG Migration: filename.yang
        Change: description of change
        Date: YYYY-MM-DD
    </xsl:comment>

    <!-- Import framework -->
    <xsl:import href="../../framework/identity-utils.xsl"/>

    <!-- Root template -->
    <xsl:template match="/">
        <xsl:apply-templates select="*"/>
    </xsl:template>

    <!-- Templates for specific transformations -->

</xsl:stylesheet>
```

### Common Transformation Patterns

1. **Rename node**: Use `xsl:template match="old-name"` with `xsl:element name="new-name"`
2. **Delete node**: Don't match the node (implicit deletion)
3. **Change type**: Use type converter from framework
4. **Move node**: Match parent, create new structure, apply templates

## Common YANG Changes and XSLT Mappings

| YANG Change | XSLT Required |
|-------------|---------------|
| leaf → leaf-list | Wrap values in new element, iterate |
| leaf-list → leaf | Use `xsl:value-of` instead of `xsl:apply-templates` |
| Add new optional leaf | Copy through unchanged |
| Remove leaf | Don't match template (will be removed) |
| Change default value | Add explicit element with default |
| Rename container | Use `xsl:element name="new-name"` |

## Workflow Integration

### Version Upgrade Flow

1. Get source and target versions (e.g., 26.3 → 26.6)
2. Find YANG files that changed between versions
3. Generate migration XSLT for each changed YANG
4. Create or update merged XSLT
5. Place in appropriate directory

### Testing

1. Create test XML files representing old configuration
2. Apply XSLT transformation
3. Verify output matches expected new configuration
4. Check for data loss or unexpected changes

## Tools

See [dmsupgrader_app/tools.md](dmsupgrader_app/tools.md) for available scripts and utilities.

Key scripts:
- `scripts/find-yang-changes.sh` - Find YANG changes in hg commits
- `scripts/generate-migration.sh` - Generate migration XSLT from YANG diff
- `scripts/validate-xslt.sh` - Validate generated XSLT syntax

## Documentation

- [Background](Background.md) - XSLT framework reference, naming conventions, patterns
- [Overview](overview.md) - System overview (from dmsupgrader_app)
- [Workflow](workflow.md) - Detailed workflow guide (from dmsupgrader_app)
- [Tools Reference](tools.md) - Available tools (from dmsupgrader_app)
