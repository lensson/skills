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
3. User selects changeset(s):
   - Options `1`, `2`, `3` - Select displayed commits
   - Option `4` - **Manual Input**: Display `SchemaChangeMode_InputChangeset.md`, user enters changeset number(s), then runs `yang_diff.sh` to show diff
   - Direct input - Enter changeset number directly (e.g., `599970`)
4. `scripts/yang_diff.sh` shows detailed YANG diff with Migration Analysis
5. User selects YANG file(s) for XSLT generation
6. Proceeds to XSLT generation

## Mode 3: Validation Rule-Based Generation
Use C++ code (Validation Rules) have been modified in validation applications to generate migration scripts.

**Supported validation apps:**
- `switch_validator_app` - Switch validator application
- `xpon_validator_app` - XPON validator application
- `clock_validator_app` - Clock validator application
- `switch_validator` - Switch validator (Configuration)
- `xpon_validator` - XPON validator (Configuration)
