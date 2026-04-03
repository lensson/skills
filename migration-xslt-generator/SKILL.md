---
name: migration-xslt-generator
description: Automatically generate XSLT migration scripts for Lightspan release upgrades, transforming ConfD configuration data. Use when creating XSLT migration files, upgrading board versions (e.g., LLLT-A from 26.3 to 26.6), or when YANG files are modified.
---

# Migration XSLT Generator

Generate XSLT migration scripts for Lightspan release upgrades to transform ConfD configuration data.

---

## File Responsibilities

| File | Purpose |
|------|---------|
| **Generator.md** | User workflow, UI templates, interaction flow |
| **Strategy.md** | Input-to-XSLT transformation logic, classification rules, XSLT patterns, documented cases |
| **Background.md** | Background knowledge: XSLT framework, version info, domain mapping, reference data |

---

## Quick Start - Choose Mode

When user says "I want to create XSLT" (or similar intent to create XSLT), **always display the full content of `ChooseMode.md` below**, then wait for the user to select a mode. Do NOT use AskQuestion — show the markdown content directly.

---

# Choose Mode

Please choose a mode:

## Mode 1: Intent-Based Generation
Use this when you know exactly what changes you want to make.

- **Migration Intent**: Describe what you want to do (e.g., rename node, delete field, change type, merge nodes)
- **Input XML**: Example configuration before migration
- **Output XML**: Expected configuration after migration

## Mode 2: YANG Change-Based Generation
Use this when YANG files have been modified and you need to automatically generate migration scripts.

I will help you generate the corresponding XSLT based on your recent YANG changes or specified commit records.

**Flow:**
1. Runs `scripts/find-yang-changes.sh` to query Mercurial
2. Displays up to 3 recent YANG-related commits in ChangeList format
3. User selects changeset(s) to view YANG diff
4. Proceeds to XSLT generation

## Mode 3: Validation Rule-Based Generation
Use when C++ code (Validation Rules) have been modified in validation applications to generate migration scripts.

**Supported validation apps:**
- `switch_validator_app` - Switch validator application
- `xpon_validator_app` - XPON validator application
- `clock_validator_app` - Clock validator application
- `switch_validator` - Switch validator (Configuration)
- `xpon_validator` - XPON validator (Configuration)

---

When user selects Mode 1:
1. **Display interface**: Show [IntentMode_Input.md](IntentMode_Input.md) as user interface
2. **Follow workflow**: Reference [Generator.md](Generator.md) for detailed generation process

When user selects Mode 2:
1. **Display interface**: Show [SchemaChangeMode_ChangeList.md](SchemaChangeMode_ChangeList.md) as the user interface template
2. **Run script**: `scripts/find-yang-changes.sh`
3. **Show results**: Table format with changeset information
4. **Extract diff**: When user selects, run `scripts/yang_diff.sh`
5. **Generate XSLT**: Follow [Generator.md](Generator.md)

When user selects Mode 3:
1. **Display interface**: Show [ValidationAppMode_ChangeList.md](ValidationAppMode_ChangeList.md) with up to 3 recent commits
2. **User options**: Select `1`, `2`, `3`, multiple (`1,2`), manual input (`4`), or direct changeset
3. **Show code diff**: Display [ValidationAppMode_CodeDiff.md](ValidationAppMode_CodeDiff.md) format
4. **Map to YANG**: Analyze code diff, map rules to TranslatorStrategyCategory.json → YANG Domain
5. **Generate XSLT**: Follow [Generator.md](Generator.md) for Mode 3 workflow

---

## Workspace Structure

- **YANG schema**: `vobs/dsl/yang/`
- **XSLT scripts**: `vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/`
- **Merged scripts**: `vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/merged/`
- **Domain scripts**: `vobs/dsl/sw/y/build/apps/dmsupgrader_app/xsl/<domain>/`

---

## Three Generation Modes

### Mode 1: Intent-Based Generation

Use when user provides:
- Migration intent (what changes are needed)
- Input XML (before migration) - optional
- Output XML (expected after migration) - optional

**Process:**
1. Display [IntentMode_Input.md](IntentMode_Input.md) as user interface
2. Follow [Generator.md](Generator.md) for workflow
3. Reference [Strategy.md](Strategy.md) for classification and patterns
4. User Feedback Loop (modify XSLT until satisfied)
5. Save to domain directory

### Mode 2: YANG Change-Based Generation

Use when YANG files have been modified between releases.

**Process:**
1. Identify the YANG changes (additions, deletions, modifications)
2. Reference [Strategy.md](Strategy.md) for YANG-to-XSLT mapping
3. Generate XSLT for each affected YANG file
4. Create merged XSLT if multiple domain-specific scripts exist

### Mode 3: Validation Rule-Based Generation

Use when validation app's C++ code (Validation Rules) have been modified.

**Supported Validation Apps:**
- `switch_validator_app` - Switch validator application
- `xpon_validator_app` - XPON validator application
- `clock_validator_app` - Clock validator application
- `switch_validator` - Switch validator (legacy)
- `xpon_validator` - XPON validator (legacy)

**Process:**
1. **List Changesets**: Display [ValidationAppMode_ChangeList.md](ValidationAppMode_ChangeList.md) showing up to 3 recent commits
2. **User Selection Options**:
   - `1`, `2`, `3` - Select single changeset
   - `1,2` or `1,2,3` - Select multiple changesets (comma-separated)
   - `4` - Manually input changeset(s)
   - Direct input - Enter changeset number directly (e.g., `535200`)
   - `Q` - Quit and return to main menu
3. **Display Code Diff**: Show [ValidationAppMode_CodeDiff.md](ValidationAppMode_CodeDiff.md) format
4. **Map to YANG**: Analyze code changes and map to TranslatorStrategyCategory.json → YANG Domain
5. **Generate XSLT**: Reference [Generator.md](Generator.md) for workflow
6. **User Feedback Loop**: Modify XSLT until satisfied
7. **Save**: Place in appropriate domain directory

---

## Reference Documentation

### Generator.md - Workflow
- Step-by-step user interaction flow
- UI templates for input collection
- Feedback loop handling
- Save file flow

### Strategy.md - Transformation Logic
- Intent type classification (DELETE_NODE, RENAME_NODE, CHANGE_VALUE, etc.)
- YANG change classification
- XSLT pattern library
- Domain detection logic
- Optimization strategies

### Background.md - Reference Data
- XSLT framework files
- Release version mapping (26.3→2603, 26.6→2606, etc.)
- XSLT file naming conventions
- Domain directory structure
- Common namespace patterns
- Framework files reference

---

## YANG Change Decision Matrix

See [Strategy.md](Strategy.md) for complete decision rules.

### Quick Reference

| YANG Change | XSLT Required |
|-------------|---------------|
| `deviate not-supported` | **Yes** |
| `deviate replace` type | **Yes** |
| `deviate add` with `default` | **Yes** |
| `deviate add` with `must constraint` | **Yes** |
| `deviate add` with `mandatory true` | **Yes** |
| `deviate add` with `must` + `mandatory` | **Yes** |
| `deviate add` optional leaf | **No** |
| `deviate add` with `unique` | **No** |
| `revision` only change | **No** |
| `deviate delete` constraint | **No** |

### Critical: `must` and `mandatory` Rules

**IMPORTANT**: When YANG adds `must` constraint or `mandatory true`, XSLT is **REQUIRED**:

- `must "( . >= X)"` → Update existing values that don't satisfy the constraint
- `mandatory true` → Add missing values with appropriate defaults
- Combined `must` + `mandatory` → Handle both cases in single XSLT

**Reference XSLT**:
- `xsl/qos/lsr2509_to_lsr2512_qos_update_bac_max_queue_size.xsl`
- `xsl/qos/lsr2203_to_lsr2206_update_bac_profile_1.xsl`

---

## Workflow Integration

### Version Upgrade Flow

1. Get source and target versions (e.g., 26.3 → 26.6)
2. Map to file version format (2603 → 2606)
3. Find YANG files that changed between versions
4. Generate migration XSLT for each changed YANG
5. Create or update merged XSLT
6. Place in appropriate directory

### Testing

1. Create test XML files representing old configuration
2. Apply XSLT transformation
3. Verify output matches expected new configuration
4. Check for data loss or unexpected changes

---

## Tools

Key scripts (in project repository):
- `scripts/find-yang-changes.sh` - Find YANG changes in hg commits
- `scripts/generate-migration.sh` - Generate migration XSLT from YANG diff
- `scripts/validate-xslt.sh` - Validate generated XSLT syntax

---

## Documentation Map

| Document | Purpose |
|----------|---------|
| [SKILL.md](SKILL.md) | This file - skill overview and quick reference |
| [ChooseMode.md](ChooseMode.md) | Mode selection interface |
| [IntentMode_Input.md](IntentMode_Input.md) | Mode 1 user interface |
| [SchemaChangeMode_ChangeList.md](SchemaChangeMode_ChangeList.md) | Mode 2 changeset selection |
| [SchemaChangeMode_YangDiff.md](SchemaChangeMode_YangDiff.md) | Mode 2 diff viewer |
| [ValidationAppMode_ChangeList.md](ValidationAppMode_ChangeList.md) | Mode 3 changeset selection |
| [ValidationAppMode_InputChangeset.md](ValidationAppMode_InputChangeset.md) | Mode 3 manual changeset input |
| [ValidationAppMode_CodeDiff.md](ValidationAppMode_CodeDiff.md) | Mode 3 code diff viewer |
| [Generator.md](Generator.md) | User workflow and interaction |
| [Strategy.md](Strategy.md) | Transformation logic and patterns (including all XSLT patterns and documented cases) |
| [Background.md](Background.md) | Framework reference and version info |
