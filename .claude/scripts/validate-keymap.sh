#!/usr/bin/env bash
# ZMK Keymap Syntax and Structure Validation

ERRORS=0
WARNINGS=0

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
    ((ERRORS++)) || true
}

warn() {
    echo -e "${YELLOW}WARNING:${NC} $1" >&2
    ((WARNINGS++)) || true
}

info() {
    echo -e "${GREEN}INFO:${NC} $1"
}

validate_keymap() {
    local file="$1"
    info "Validating $file"

    # Check required headers
    if ! grep -q '#include <behaviors.dtsi>' "$file"; then
        error "$file: Missing required header '#include <behaviors.dtsi>'"
    fi

    if ! grep -q '#include <dt-bindings/zmk/keys.h>' "$file"; then
        error "$file: Missing required header '#include <dt-bindings/zmk/keys.h>'"
    fi

    # Check keymap compatible string
    if ! grep -q 'compatible = "zmk,keymap"' "$file"; then
        error "$file: Missing 'compatible = \"zmk,keymap\"' in keymap node"
    fi

    # Check for combos compatible string if combos exist
    if grep -q 'combos\s*{' "$file" && ! grep -q 'compatible = "zmk,combos"' "$file"; then
        error "$file: Combos node exists but missing 'compatible = \"zmk,combos\"'"
    fi

    # Validate layer labels exist
    local layer_count=0
    local labeled_layers=0

    # Count layers (look for binding blocks within keymap)
    while IFS= read -r line; do
        if echo "$line" | grep -qE '^\s*[a-zA-Z_][a-zA-Z0-9_-]*\s*\{'; then
            if grep -A 20 "$line" "$file" | grep -q 'bindings = <'; then
                ((layer_count++)) || true
            fi
        fi
    done < <(sed -n '/keymap\s*{/,/^}/p' "$file")

    # Count labeled layers
    labeled_layers=$(grep -c 'label = ' "$file" || true)

    if [ "$layer_count" -gt 0 ] && [ "$labeled_layers" -lt "$layer_count" ]; then
        warn "$file: Found $layer_count layers but only $labeled_layers have labels. All layers should have labels for ZMK Studio."
    fi

    # Check for common syntax errors
    if grep -qE '&[a-z]+\s+[A-Z_]+[^;]*$' "$file"; then
        warn "$file: Possible missing semicolon in devicetree syntax"
    fi

    # Validate combo syntax
    local combo_errors=0
    while IFS= read -r line; do
        if echo "$line" | grep -q 'key-positions = <'; then
            # Extract positions
            positions=$(echo "$line" | sed -n 's/.*key-positions = <\([^>]*\)>.*/\1/p')

            # Check for duplicate positions in same combo
            if [ -n "$positions" ]; then
                sorted=$(echo "$positions" | tr ' ' '\n' | sort -n | uniq)
                original_count=$(echo "$positions" | wc -w)
                unique_count=$(echo "$sorted" | wc -l)

                if [ "$original_count" -ne "$unique_count" ]; then
                    error "$file: Combo has duplicate key-positions: $positions"
                    ((combo_errors++)) || true
                fi
            fi
        fi
    done < <(grep -E 'key-positions = <' "$file" || true)

    # Check for balanced braces
    open_braces=$(grep -o '{' "$file" | wc -l)
    close_braces=$(grep -o '}' "$file" | wc -l)

    if [ "$open_braces" -ne "$close_braces" ]; then
        error "$file: Unbalanced braces (${open_braces} open, ${close_braces} close)"
    fi

    # Check for &trans in base layer (common mistake)
    if grep -A 50 'keymap\s*{' "$file" | head -60 | grep -q '&trans'; then
        warn "$file: Found &trans in what appears to be base layer. Base layer should not use transparent keys."
    fi

    # Validate behavior references
    local undefined_behaviors=0
    while IFS= read -r behavior; do
        behavior_name=$(echo "$behavior" | sed 's/^&//')

        # Skip built-in behaviors
        if ! echo "$behavior_name" | grep -qE '^(kp|mo|to|sl|lt|tog|mt|caps_word|bootloader|trans|none|reset|bt|out|ext_power|rgb_ug|bl|gresc|key_repeat|sk|sticky_key|hold_tap)'; then
            # Check if custom behavior is defined
            if ! grep -qE "^\s*${behavior_name}\s*:" "$file" && ! grep -qE "^\s*${behavior_name}\s*\{" "$file"; then
                warn "$file: Reference to undefined custom behavior: &${behavior_name}"
                ((undefined_behaviors++)) || true
            fi
        fi
    done < <(grep -oE '&[a-zA-Z_][a-zA-Z0-9_]*' "$file" | sort -u)
}

# Process all keymap files passed as arguments
if [ $# -eq 0 ]; then
    # No files specified, find all keymap files
    mapfile -t keymap_files < <(find config -name "*.keymap" 2>/dev/null || true)
else
    keymap_files=("$@")
fi

if [ ${#keymap_files[@]} -eq 0 ]; then
    info "No keymap files to validate"
    exit 0
fi

for file in "${keymap_files[@]}"; do
    if [ -f "$file" ]; then
        validate_keymap "$file"
    else
        warn "File not found: $file"
    fi
done

# Summary
echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Validation passed!${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Validation passed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${RED}✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    exit 1
fi
