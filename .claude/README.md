# Claude Code Setup for ZMK Config

This directory contains Claude Code skills and validation tools for maintaining ZMK keyboard configurations.

## Directory Structure

```
.claude/
├── README.md                          # This file
├── skills/
│   └── zmk-keymap.md                  # ZMK keymap editing skill with best practices
└── scripts/
    ├── validate-keymap.sh             # Keymap syntax and structure validation
    └── validate-studio.sh             # ZMK Studio compliance checking
```

## Skills

### ZMK Keymap Skill (`skills/zmk-keymap.md`)

This skill provides expert guidance for creating and modifying ZMK keymaps with best practices, especially for ZMK Studio compatibility.

**Key Topics Covered:**
- ZMK Studio compliance requirements
- Build configuration (build.yaml) best practices
- Layer structure and organization
- Combo definitions and validation
- Custom behavior creation
- Testing workflow
- Common issues and solutions

**When to Use:**
- Adding or modifying keymaps
- Creating new layers
- Defining combos
- Setting up custom behaviors
- Ensuring Studio compatibility

Claude Code will automatically load this skill when working on ZMK-related tasks.

## Validation Scripts

### Pre-commit Hooks with Prek

This repository uses [prek](https://github.com/spenserblack/prek) - a fast, Rust-based pre-commit hook manager - to automatically validate ZMK configurations before committing.

**Setup:**
1. Install prek: `mise install prek` (already done)
2. Install git hooks: `prek install` (already done)
3. Hooks will run automatically on `git commit`

**Manual Validation:**
```bash
# Run all hooks
prek run --all-files

# Run specific hooks
prek run zmk-keymap-validation --all-files
prek run zmk-studio-check --all-files
```

### Keymap Validation (`validate-keymap.sh`)

Checks ZMK keymap files for:
- Required headers (#include statements)
- Compatible strings for keymap and combos
- Layer label presence (for Studio)
- Balanced braces and syntax
- Combo key-position duplicates
- Undefined behavior references
- Base layer using &trans (anti-pattern)

**Usage:**
```bash
.claude/scripts/validate-keymap.sh config/forager.keymap
```

### Studio Compliance (`validate-studio.sh`)

Validates ZMK Studio compatibility:
- Checks for `studio-rpc-usb-uart` snippet in build.yaml
- Verifies all layers have labels
- Validates label lengths (< 10 chars recommended)
- Warns about Studio-incompatible features
- Provides connectivity checklist

**Usage:**
```bash
.claude/scripts/validate-studio.sh
```

## Best Practices Enforced

### Build Configuration
- ✓ All board configs include `snippet: studio-rpc-usb-uart`
- ✓ Consistent artifact naming

### Keymap Structure
- ✓ All layers have descriptive labels
- ✓ Labels are concise (≤ 10 characters)
- ✓ Required headers present
- ✓ Proper compatible strings
- ✓ No syntax errors (balanced braces, etc.)

### Combos
- ✓ Valid key-positions for layout
- ✓ No duplicate positions in same combo
- ✓ Layer-specific combos when appropriate

### Behaviors
- ✓ All referenced behaviors are defined
- ✓ Custom behaviors have proper devicetree syntax
- ✓ Timing parameters documented

## Hook Configuration

The pre-commit configuration (`.pre-commit-config.yaml`) includes:

1. **General file checks:**
   - Trailing whitespace removal
   - End-of-file fixer
   - YAML syntax validation
   - Large file detection
   - Merge conflict detection

2. **ZMK-specific validation:**
   - Keymap syntax validation
   - Studio compliance checking

## Bypassing Hooks (Emergency Use Only)

If you need to commit without running hooks:
```bash
git commit --no-verify -m "message"
```

**Note:** Only use this when absolutely necessary. The hooks are designed to catch issues before they cause build failures.

## Troubleshooting

### Hook fails but I don't understand why
Run the validation script directly to see full output:
```bash
.claude/scripts/validate-keymap.sh config/your-keymap.keymap
.claude/scripts/validate-studio.sh
```

### Prek not found
Make sure mise is activated:
```bash
eval "$(mise activate bash)"
```

Or add to your shell profile:
```bash
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
```

### Want to update hook configuration
Edit `.pre-commit-config.yaml` and run:
```bash
prek install-hooks --refresh
```

## Contributing

When adding new validation rules:
1. Update the appropriate script in `.claude/scripts/`
2. Make scripts executable: `chmod +x .claude/scripts/*.sh`
3. Test manually before committing
4. Update this README with new checks

## Resources

- [ZMK Documentation](https://zmk.dev/docs)
- [ZMK Studio Docs](https://zmk.dev/docs/features/studio)
- [Prek Documentation](https://github.com/spenserblack/prek)
- [Pre-commit Framework](https://pre-commit.com/)
